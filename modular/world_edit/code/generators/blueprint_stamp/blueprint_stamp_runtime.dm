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
	result.preview_images = GLOB.world_edit_helpers.build_turf_preview_images(plan.affected_turfs)
	result.meta = plan.metadata.Copy()
	result.message = "Blueprint preview ready: anchors=[plan.metadata["anchor_count"]], entries=[plan.metadata["entry_count"]], skipped=[plan.metadata["skipped_entry_count"] || 0], dir=[plan.metadata["placement_dir_label"]]."
	return result

/datum/world_edit_generator/blueprint_stamp/apply(mob/user, list/params)
	return apply_plan(user, params, current_plan)

/datum/world_edit_generator/blueprint_stamp/apply_plan(mob/user, list/params, datum/world_edit_plan/plan)
	var/datum/world_edit_apply_result/result = new
	if(!istype(plan))
		result.message = "Run preview first to build the blueprint plan."
		return result
	if(plan.metadata["error"])
		result.message = "[plan.metadata["error"]]"
		return result
	if(!length(plan.placements))
		result.message = "Blueprint apply finished with no valid placements."
		return result

	var/created_count = 0
	var/skipped_runtime = 0
	var/datum/world_edit_changeset/changeset = new /datum/world_edit_changeset(definition?.id || "blueprint_stamp", WORLD_EDIT_UNDO_FULL, list(
		"center_turf" = plan.metadata["center_turf"],
		"blueprint_id" = plan.metadata["blueprint_id"],
		"blueprint_name" = plan.metadata["blueprint_name"],
		"placement_mode" = plan.metadata["placement_mode"],
		"placement_dir" = plan.metadata["placement_dir"],
		"anchor_count" = plan.metadata["anchor_count"],
	))
	for(var/list/placement as anything in plan.placements)
		var/turf/target_turf = placement["turf"]
		var/obj_path = placement["obj_path"]
		var/error_text = GLOB.world_edit_blueprints.world_edit_validate_blueprint_target_turf(target_turf, obj_path, placement["dir"])
		if(error_text)
			skipped_runtime++
			continue

		var/obj/created_object = GLOB.world_edit_blueprints.world_edit_spawn_blueprint_entry(placement)
		if(created_object)
			created_count++
			changeset.add_created(created_object, placement["turf"], list(
				"kind" = placement["kind"],
				"obj_path" = placement["obj_path"],
			))
		else
			skipped_runtime++

	result.center_turf = plan.metadata["center_turf"]
	result.created_count = created_count
	result.meta = plan.metadata.Copy()
	result.meta["skipped_runtime"] = skipped_runtime

	if(created_count <= 0)
		result.message = "Blueprint apply finished without creating any structures."
		return result

	result.success = TRUE
	result.changeset = changeset
	result.message = "Blueprint '[plan.metadata["blueprint_name"]]' stamped successfully: anchors=[plan.metadata["anchor_count"]], created=[created_count], skipped=[skipped_runtime], dir=[plan.metadata["placement_dir_label"]]."
	return result
