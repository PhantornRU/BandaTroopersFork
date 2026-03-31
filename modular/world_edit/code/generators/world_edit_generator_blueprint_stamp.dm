/datum/world_edit_generator/blueprint_stamp
	requires_preview_before_apply = TRUE

/datum/world_edit_generator/blueprint_stamp/validate_params(mob/user, list/params)
	var/blueprint_id = sanitize_filename("[params["blueprint_id"]]")
	if(!length(blueprint_id))
		return "РЎРЅР°С‡Р°Р»Р° Р·Р°РіСЂСѓР·РёС‚Рµ blueprint РёР· server-side Р±РёР±Р»РёРѕС‚РµРєРё."
	if(!get_turf(user))
		return "Unable to resolve the anchor turf."

	var/list/load_result = manager?.load_blueprint_definition_by_id(blueprint_id)
	if(load_result["error"])
		return "[load_result["error"]]"

	return null

/datum/world_edit_generator/blueprint_stamp/get_supported_placement_modes()
	return list("single", "repeat", "line", "rectangle")

/datum/world_edit_generator/blueprint_stamp/supports_placement_direction()
	return TRUE

/datum/world_edit_generator/blueprint_stamp/get_default_placement_direction()
	return NORTH

/datum/world_edit_generator/blueprint_stamp/proc/load_active_blueprint(list/params)
	var/blueprint_id = sanitize_filename("[params["blueprint_id"]]")
	if(!length(blueprint_id))
		return list("error" = "Сначала загрузите blueprint из server-side библиотеки.")
	return manager?.load_blueprint_definition_by_id(blueprint_id) || list("error" = "Blueprint payload is unavailable.")

/datum/world_edit_generator/blueprint_stamp/proc/normalize_anchor_turfs(list/raw_anchor_turfs)
	var/list/anchor_turfs = list()
	var/list/anchor_lookup = list()
	if(!islist(raw_anchor_turfs))
		return anchor_turfs

	for(var/turf/anchor_turf as anything in raw_anchor_turfs)
		if(!istype(anchor_turf))
			continue
		if(anchor_lookup[anchor_turf])
			continue
		anchor_lookup[anchor_turf] = TRUE
		anchor_turfs += anchor_turf

	return anchor_turfs

/datum/world_edit_generator/blueprint_stamp/build_placement_plan(mob/user, list/params, list/placement_context)
	var/datum/world_edit_plan/plan = new
	var/list/load_result = load_active_blueprint(params)
	if(load_result["error"])
		plan.metadata["error"] = "[load_result["error"]]"
		return plan

	var/list/anchor_turfs = normalize_anchor_turfs(placement_context["anchor_turfs"])
	if(!length(anchor_turfs))
		plan.metadata["error"] = "Unable to resolve the blueprint anchor turf."
		return plan
	if(length(anchor_turfs) > WORLD_EDIT_PLACEMENT_MAX_ANCHORS)
		plan.metadata["error"] = "Requested footprint exceeds the safe anchor cap ([WORLD_EDIT_PLACEMENT_MAX_ANCHORS])."
		return plan

	var/placement_dir = text2num("[placement_context["direction"]]")
	if(!(placement_dir in GLOB.cardinals))
		placement_dir = manager?.get_effective_placement_dir() || NORTH

	var/list/affected_lookup = list()
	var/list/occupied_lookup = list()
	var/list/blueprint = load_result["blueprint"]
	for(var/turf/anchor_turf as anything in anchor_turfs)
		var/datum/world_edit_plan/anchor_plan = world_edit_build_plan_from_blueprint(blueprint, anchor_turf, placement_dir)
		if(!istype(anchor_plan))
			plan.metadata["error"] = "Unable to build the blueprint plan."
			return plan
		if(anchor_plan.metadata["error"])
			plan.metadata = anchor_plan.metadata.Copy()
			plan.metadata["anchor_turf"] = "[anchor_turf.x],[anchor_turf.y],[anchor_turf.z]"
			return plan

		for(var/list/placement as anything in anchor_plan.placements)
			var/turf/target_turf = placement["turf"]
			if(occupied_lookup[target_turf])
				plan.metadata["error"] = "Requested placement footprint overlaps itself."
				plan.metadata["blocked_turf"] = "[target_turf.x],[target_turf.y],[target_turf.z]"
				return plan

			occupied_lookup[target_turf] = TRUE
			affected_lookup[target_turf] = TRUE
			plan.placements += list(placement.Copy())

		if(length(plan.placements) > WORLD_EDIT_PLACEMENT_MAX_TOTAL_PLACEMENTS)
			plan.metadata["error"] = "Requested placement exceeds the safe placement cap ([WORLD_EDIT_PLACEMENT_MAX_TOTAL_PLACEMENTS])."
			return plan

	for(var/turf/affected_turf as anything in affected_lookup)
		plan.affected_turfs += affected_turf

	var/turf/center_turf = placement_context["end_turf"]
	if(!istype(center_turf))
		center_turf = anchor_turfs[clamp(round((length(anchor_turfs) + 1) / 2), 1, length(anchor_turfs))]

	plan.metadata["center_turf"] = center_turf
	plan.metadata["blueprint_id"] = blueprint["id"]
	plan.metadata["blueprint_name"] = blueprint["name"]
	plan.metadata["entry_count"] = length(plan.placements)
	plan.metadata["blueprint_entry_count"] = length(blueprint["entries"])
	plan.metadata["radius"] = blueprint["bounds"] ? blueprint["bounds"]["radius"] : 0
	plan.metadata["anchor_count"] = length(anchor_turfs)
	plan.metadata["placement_mode"] = "[placement_context["mode"] || "single"]"
	plan.metadata["placement_dir"] = placement_dir
	plan.metadata["placement_dir_label"] = world_edit_dir_to_label(placement_dir)
	return plan

/datum/world_edit_generator/blueprint_stamp/build_plan(list/params)
	var/turf/anchor_turf = get_turf(manager?.holder?.mob)
	return build_placement_plan(manager?.holder?.mob, params, list(
		"mode" = "single",
		"anchor_turfs" = list(anchor_turf),
		"direction" = manager?.get_effective_placement_dir(),
		"end_turf" = anchor_turf,
	))

/datum/world_edit_generator/blueprint_stamp/preview(mob/user, list/params)
	var/datum/world_edit_preview_result/result = new
	clear_built_plan()

	var/datum/world_edit_plan/plan = build_plan(params)
	if(!istype(plan))
		result.message = "Unable to build the blueprint plan."
		return result
	if(plan.metadata["error"])
		result.message = "[plan.metadata["error"]]"
		return result
	if(!length(plan.placements))
		result.message = "Blueprint contains no valid placements."
		return result

	current_plan = plan
	result.success = TRUE
	result.preview_images = world_edit_build_turf_preview_images(plan.affected_turfs)
	result.meta = plan.metadata.Copy()
	result.message = "Blueprint preview ready: anchors=[plan.metadata["anchor_count"]], entries=[plan.metadata["entry_count"]], dir=[plan.metadata["placement_dir_label"]]."
	return result

/datum/world_edit_generator/blueprint_stamp/apply(mob/user, list/params)
	var/datum/world_edit_apply_result/result = new
	var/datum/world_edit_plan/plan = current_plan
	if(!istype(plan))
		result.message = "Run preview first to build the blueprint plan."
		return result
	if(plan.metadata["error"])
		result.message = "[plan.metadata["error"]]"
		return result
	if(!length(plan.placements))
		result.message = "Blueprint apply finished with no valid placements."
		return result

	for(var/list/placement as anything in plan.placements)
		var/turf/target_turf = placement["turf"]
		var/obj_path = placement["obj_path"]
		var/error_text = world_edit_validate_blueprint_target_turf(target_turf, obj_path)
		if(error_text)
			result.message = "Blueprint apply aborted: [error_text]"
			return result

	var/created_count = 0
	var/datum/world_edit_changeset/changeset = new /datum/world_edit_changeset(definition?.id || "blueprint_stamp", WORLD_EDIT_UNDO_FULL, list(
		"center_turf" = plan.metadata["center_turf"],
		"blueprint_id" = plan.metadata["blueprint_id"],
		"blueprint_name" = plan.metadata["blueprint_name"],
		"placement_mode" = plan.metadata["placement_mode"],
		"placement_dir" = plan.metadata["placement_dir"],
		"anchor_count" = plan.metadata["anchor_count"],
	))
	for(var/list/placement as anything in plan.placements)
		var/obj/created_object = world_edit_spawn_blueprint_entry(placement)
		if(created_object)
			created_count++
			changeset.add_created(created_object, placement["turf"], list(
				"kind" = placement["kind"],
				"obj_path" = placement["obj_path"],
			))

	result.center_turf = plan.metadata["center_turf"]
	result.created_count = created_count
	result.meta = plan.metadata.Copy()

	if(created_count <= 0)
		result.message = "Blueprint apply finished without creating any structures."
		return result

	result.success = TRUE
	result.changeset = changeset
	result.message = "Blueprint '[plan.metadata["blueprint_name"]]' stamped successfully: anchors=[plan.metadata["anchor_count"]], created=[created_count], dir=[plan.metadata["placement_dir_label"]]."
	return result

/datum/world_edit_generator/blueprint_stamp/get_apply_confirmation_text(list/params)
	return "РџРѕРґС‚РІРµСЂРґРёС‚СЊ stamp РІС‹Р±СЂР°РЅРЅРѕРіРѕ blueprint РЅР° С‚РµРєСѓС‰РµРј С‚Р°Р№Р»Рµ?"

/datum/world_edit_generator/blueprint_stamp/get_params_short(list/params)
	return "blueprint_id=[params["blueprint_id"]] dir=[world_edit_dir_to_label(manager?.get_effective_placement_dir() || NORTH)]"
