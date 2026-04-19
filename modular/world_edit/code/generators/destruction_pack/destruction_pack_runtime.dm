/datum/world_edit_generator/destruction_pack/preview(mob/user, list/params)
	var/datum/world_edit_preview_result/result = new
	clear_built_plan()
	var/datum/world_edit_plan/plan = build_plan(params)
	if(!istype(plan))
		result.message = "Unable to build the destruction plan."
		return result
	if(!length(plan.placements) && !length(plan.deletions))
		result.message = plan.metadata["error"] || "No movable targets, fire tiles, blast actions, or damage targets matched the selected area."
		return result

	current_plan = plan
	result.success = TRUE
	result.preview_images = build_plan_preview_images(plan)
	result.meta = plan.metadata.Copy()
	result.message = "Preview ready: tiles=[plan.metadata["area_tiles"]], movable_targets=[plan.metadata["target_count"]], planned_moves=[plan.metadata["moved_count"]], fire_tiles=[plan.metadata["fire_count"]], blasts=[plan.metadata["blast_count"]], damage=[plan.metadata["damage_profile_label"] || "None"], undo=[plan.metadata["undo_policy"] || WORLD_EDIT_UNDO_NONE]."
	return result

/datum/world_edit_generator/destruction_pack/apply(mob/user, list/params)
	return apply_plan(user, params, current_plan)

/datum/world_edit_generator/destruction_pack/apply_plan(mob/user, list/params, datum/world_edit_plan/plan)
	var/datum/world_edit_apply_result/result = new
	if(!istype(plan))
		result.message = "Run preview first to build the destruction plan."
		return result
	if(!length(plan.placements) && !length(plan.deletions))
		result.message = plan.metadata["error"] || "No movable targets, fire tiles, blast actions, or damage targets matched the selected area."
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

			var/obj/effect/world_edit_persistent_fire/fire = new /obj/effect/world_edit_persistent_fire(target_turf)
			if(!istype(fire))
				skipped_runtime++
				continue
			fire.set_world_edit_owner(changeset.operation_id, definition?.id)
			changeset.add_owned_effect(fire, changeset.operation_id, target_turf, list(
				"kind" = "persistent_fire",
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
		if(should_skip_target(target, FALSE))
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
			if(!islist(damage_area_turfs) || !length(damage_area_turfs) || severity <= 0)
				skipped_runtime++
				continue
			damage_count += apply_structural_damage_profile(damage_area_turfs, severity, cause_data)
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
		result.message = plan.metadata["error"] || "Destruction pack finished without applying any moves, fire tiles, blasts, or damage profiles."
		return result

	result.success = TRUE
	result.changeset = changeset
	var/list/summaries = list()
	if(moved_count > 0)
		summaries += "[moved_count] moved targets"
	if(fire_count > 0)
		summaries += "[fire_count] owned fire tiles"
	if(blast_count > 0)
		summaries += "[blast_count] blasts"
	if(damage_count > 0)
		summaries += "[damage_count] damaged turfs"
	var/summary_text = jointext(summaries, ", ")
	if(!length(summary_text))
		summary_text = "no-op"
	result.message = "Destruction pack applied: [summary_text]. Undo=[changeset.undo_policy]."
	return result

/datum/world_edit_generator/destruction_pack/get_runtime_status()
	var/list/params = manager?.current_params || list()
	var/shuffle_enabled = GLOB.world_edit_helpers.parse_bool(params["shuffle_enabled"])
	var/scatter_enabled = GLOB.world_edit_helpers.parse_bool(params["scatter_enabled"])
	var/persistent_fire_enabled = GLOB.world_edit_helpers.parse_bool(params["persistent_fire_enabled"])
	var/blast_enabled = GLOB.world_edit_helpers.parse_bool(params["blast_enabled"])
	var/damage_profile = resolve_damage_profile(params["damage_profile"])

	return list(
		list("label" = "Move mode", "value" = (shuffle_enabled || scatter_enabled) ? "active" : "off"),
		list("label" = "Persistent fire", "value" = persistent_fire_enabled ? "active" : "off"),
		list("label" = "Blast", "value" = blast_enabled ? "active" : "off"),
		list("label" = "Damage profile", "value" = get_damage_profile_label(damage_profile)),
		list("label" = "Fire cap", "value" = "[get_persistent_fire_cap()] tiles"),
	)
