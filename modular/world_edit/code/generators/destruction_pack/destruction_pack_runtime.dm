/datum/world_edit_generator/destruction_pack/preview(mob/user, list/params)
	var/datum/world_edit_preview_result/result = new
	clear_built_plan()
	var/datum/world_edit_plan/plan = build_plan(params)
	if(!istype(plan))
		result.message = "Не удалось построить план разрушения."
		return result
	if(!length(plan.placements) && !length(plan.deletions))
		result.message = plan.metadata["error"] || "В выбранной зоне не найдено подвижных целей, тайлов огня, взрывных действий или целей для урона."
		return result

	current_plan = plan
	result.success = TRUE
	result.preview_images = build_plan_preview_images(plan)
	result.meta = plan.metadata.Copy()
	result.message = "Предпросмотр готов: тайлов=[plan.metadata["area_tiles"]], подвижных целей=[plan.metadata["target_count"]], запланированных перемещений=[plan.metadata["moved_count"]], тайлов огня=[plan.metadata["fire_count"]], взрывов=[plan.metadata["blast_count"]], профиль урона=[plan.metadata["damage_profile_label"] || "Нет"], откат=[plan.metadata["undo_policy"] || WORLD_EDIT_UNDO_NONE]."
	return result

/datum/world_edit_generator/destruction_pack/should_skip_plan_build_for_hover_only_placement(datum/world_edit_shape_contract/shape_contract, list/runtime_params = null, list/placement_context = null)
	// Hover motion should not rebuild the full destruction plan every frame.
	return TRUE

/datum/world_edit_generator/destruction_pack/apply(mob/user, list/params)
	return apply_plan(user, params, current_plan)

/datum/world_edit_generator/destruction_pack/apply_plan(mob/user, list/params, datum/world_edit_plan/plan)
	var/datum/world_edit_apply_result/result = new
	if(!istype(plan))
		result.message = "Сначала выполните предпросмотр, чтобы построить план разрушения."
		return result
	if(!length(plan.placements) && !length(plan.deletions))
		result.message = plan.metadata["error"] || "В выбранной зоне не найдено подвижных целей, тайлов огня, взрывных действий или целей для урона."
		return result

	var/moved_count = 0
	var/fire_count = 0
	var/blast_count = 0
	var/damage_count = 0
	var/skipped_runtime = 0
	var/datum/world_edit_changeset/changeset = new /datum/world_edit_changeset(definition?.id || "destruction_pack", WORLD_EDIT_UNDO_PARTIAL, list(
		"center_turf" = plan.metadata["center_turf"],
		"shuffle" = plan.metadata["shuffle"],
		"scatter" = plan.metadata["scatter"],
		"persistent_fire" = plan.metadata["persistent_fire"],
		"blast" = plan.metadata["blast"],
		"damage_profile" = plan.metadata["damage_profile"],
	))
	changeset.undo_policy = plan.metadata["undo_policy"] || WORLD_EDIT_UNDO_NONE
	var/datum/cause_data/cause_data = create_cause_data("world edit destruction pack", manager?.holder)
	for(var/list/placement as anything in plan.placements)
		if(placement["kind"] == "fire")
			var/turf/target_turf = placement["turf"]
			if(!can_place_persistent_fire_on_turf(target_turf))
				skipped_runtime++
				continue

			var/fire_color = sanitize_hexcolor(placement["fire_color"], plan.metadata["persistent_fire_color"])
			var/fire_mode = resolve_persistent_fire_mode(placement["fire_mode"]) || plan.metadata["persistent_fire_mode"] || get_default_persistent_fire_mode()
			var/obj/effect/world_edit_persistent_fire/fire = new /obj/effect/world_edit_persistent_fire(target_turf)
			if(!istype(fire))
				skipped_runtime++
				continue
			fire.configure_persistent_fire(fire_color, fire_mode)
			fire.set_world_edit_owner(changeset.operation_id, definition?.id)
			changeset.add_owned_effect(fire, changeset.operation_id, target_turf, list(
				"kind" = "persistent_fire",
				"fire_color" = fire.fire_color,
				"fire_mode" = fire.fire_mode,
			))
			fire_count++
			continue

		if(placement["kind"] != "move")
			continue

		var/datum/weakref/target_ref = placement["target_ref"]
		var/atom/movable/target = target_ref?.resolve()
		if(!istype(target, /atom/movable) || QDELETED(target))
			skipped_runtime++
			continue
		if(should_skip_target(target, GLOB.world_edit_helpers.parse_bool(plan.metadata["affect_anchored"])))
			skipped_runtime++
			continue

		var/turf/source_turf = placement["source_turf"]
		if(get_turf(target) != source_turf)
			skipped_runtime++
			continue

		var/list/path_turfs = placement["path_turfs"]
		if(!length(path_turfs))
			skipped_runtime++
			continue

		var/moved_this_target = FALSE
		for(var/turf/next_turf as anything in path_turfs)
			if(!next_turf || next_turf == get_turf(target))
				continue
			if(!can_relocate_target_to_turf(target, next_turf))
				continue
			target.forceMove(next_turf)
			moved_this_target = TRUE

		if(moved_this_target)
			moved_count++
			changeset.add_moved(target, source_turf, get_turf(target), list(
				"shuffle" = plan.metadata["shuffle"],
				"scatter" = plan.metadata["scatter"],
			))
		else
			skipped_runtime++

	for(var/list/deletion as anything in plan.deletions)
		if(deletion["kind"] == "blast")
			var/turf/blast_turf = deletion["center_turf"]
			if(!istype(blast_turf))
				skipped_runtime++
				continue
			cell_explosion(blast_turf, deletion["power"], deletion["falloff"], EXPLOSION_FALLOFF_SHAPE_LINEAR, null, cause_data)
			blast_count++
			continue

		if(deletion["kind"] == "damage")
			var/list/damage_area_turfs = deletion["area_turfs"]
			var/severity = text2num("[deletion["severity"]]") || 0
			var/damage_profile = resolve_damage_profile(deletion["damage_profile"]) || "collapse"
			if(!islist(damage_area_turfs) || !length(damage_area_turfs) || severity <= 0)
				skipped_runtime++
				continue
			damage_count += apply_structural_damage_profile(damage_area_turfs, severity, cause_data, damage_profile)
			continue

		skipped_runtime++

	var/total_actions = moved_count + fire_count + blast_count + damage_count

	result.center_turf = plan.metadata["center_turf"]
	result.created_count = total_actions
	result.deleted_count = blast_count + damage_count
	result.meta = plan.metadata.Copy()
	result.meta["moved_count"] = moved_count
	result.meta["fire_count"] = fire_count
	result.meta["blast_count"] = blast_count
	result.meta["damage_count"] = damage_count
	result.meta["action_count"] = total_actions
	result.meta["skipped_runtime"] = skipped_runtime

	if(total_actions <= 0)
		result.message = plan.metadata["error"] || "Пакет разрушения завершился без применения перемещений, тайлов огня, взрывов или профилей урона."
		return result

	result.success = TRUE
	result.changeset = changeset
	var/list/summaries = list()
	if(moved_count > 0)
		summaries += "[moved_count] перемещённых целей"
	if(fire_count > 0)
		summaries += "[fire_count] тайлов управляемого огня"
	if(blast_count > 0)
		summaries += "[blast_count] взрывов"
	if(damage_count > 0)
		summaries += "[damage_count] повреждённых тайлов"
	var/summary_text = jointext(summaries, ", ")
	if(!length(summary_text))
		summary_text = "без изменений"
	result.message = "Пакет разрушения применён: [summary_text]. Откат=[changeset.undo_policy]."
	return result
