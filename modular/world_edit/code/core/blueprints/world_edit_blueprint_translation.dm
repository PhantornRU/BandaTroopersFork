/datum/world_edit_blueprint_service/proc/world_edit_build_plan_from_blueprint(list/blueprint, turf/anchor_turf, placement_dir = NORTH)
	var/datum/world_edit_plan/plan = new
	if(!anchor_turf)
		plan.metadata["error"] = "Unable to resolve the blueprint anchor turf."
		return plan

	if(!islist(blueprint))
		plan.metadata["error"] = "Blueprint payload is missing."
		return plan

	var/list/entries = blueprint["entries"]
	if(!islist(entries) || !length(entries))
		plan.metadata["error"] = "Blueprint contains no entries."
		return plan

	var/list/affected_lookup = list()
	var/list/placement_lookup = list()
	var/blocked_entry_count = 0
	var/duplicate_entry_count = 0
	for(var/list/entry as anything in entries)
		var/obj_path = text2path("[entry["type"]]")
		var/list/rotated_offset = world_edit_rotate_blueprint_offset(text2num("[entry["dx"]]"), text2num("[entry["dy"]]"), placement_dir)
		var/turf/target_turf = locate(anchor_turf.x + rotated_offset["dx"], anchor_turf.y + rotated_offset["dy"], anchor_turf.z)
		if(!istype(target_turf))
			plan.metadata["error"] = "Blueprint points outside the current z-level bounds."
			return plan

		var/dir_value = world_edit_rotate_blueprint_dir(text2num("[entry["dir"]]"), placement_dir)
		var/placement_key = world_edit_build_blueprint_target_slot_key(target_turf, obj_path, dir_value)
		if(!length(placement_key))
			plan.metadata["error"] = "Blueprint contains an invalid directional placement slot."
			return plan
		if(placement_lookup[placement_key])
			duplicate_entry_count++
			continue

		var/error_text = world_edit_validate_blueprint_target_turf(target_turf, obj_path, dir_value)
		if(error_text)
			if(error_text == "Blueprint contains an unsupported placement type.")
				plan.metadata["error"] = error_text
				return plan
			if(isnull(plan.metadata["first_blocked_turf"]))
				plan.metadata["first_blocked_turf"] = "[target_turf.x],[target_turf.y],[target_turf.z]"
			blocked_entry_count++
			continue

		placement_lookup[placement_key] = TRUE
		affected_lookup[target_turf] = TRUE
		plan.placements += list(list(
			"kind" = "blueprint_spawn",
			"obj_path" = obj_path,
			"turf" = target_turf,
			"dir" = dir_value,
			"vars" = entry["vars"] || list(),
		))

	for(var/turf/affected_turf as anything in affected_lookup)
		plan.affected_turfs += affected_turf

	plan.metadata["center_turf"] = anchor_turf
	plan.metadata["blueprint_id"] = blueprint["id"]
	plan.metadata["blueprint_name"] = blueprint["name"]
	plan.metadata["entry_count"] = length(plan.placements)
	plan.metadata["blocked_entry_count"] = blocked_entry_count
	plan.metadata["duplicate_entry_count"] = duplicate_entry_count
	plan.metadata["skipped_entry_count"] = blocked_entry_count + duplicate_entry_count
	plan.metadata["radius"] = blueprint["bounds"] ? blueprint["bounds"]["radius"] : 0
	plan.metadata["placement_dir"] = placement_dir
	plan.metadata["placement_dir_label"] = GLOB.world_edit_helpers.dir_to_label(placement_dir)
	if(islist(blueprint["outpost_recipe"]))
		plan.metadata["outpost_recipe"] = blueprint["outpost_recipe"]
	return plan
