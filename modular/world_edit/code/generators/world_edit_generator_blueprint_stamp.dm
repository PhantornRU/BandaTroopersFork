/datum/world_edit_generator/blueprint_stamp
	requires_preview_before_apply = TRUE

/datum/world_edit_generator/blueprint_stamp/validate_params(mob/user, list/params)
	var/blueprint_id = sanitize_filename("[params["blueprint_id"]]")
	if(!length(blueprint_id))
		return "Сначала загрузите blueprint из server-side библиотеки."
	if(!get_turf(user))
		return "Unable to resolve the anchor turf."

	var/list/load_result = manager?.load_blueprint_definition_by_id(blueprint_id)
	if(load_result["error"])
		return "[load_result["error"]]"

	return null

/datum/world_edit_generator/blueprint_stamp/build_plan(list/params)
	var/turf/anchor_turf = get_turf(manager?.holder?.mob)
	var/datum/world_edit_plan/plan = new
	if(!anchor_turf)
		plan.metadata["error"] = "Unable to resolve the anchor turf."
		return plan

	var/blueprint_id = sanitize_filename("[params["blueprint_id"]]")
	var/list/load_result = manager?.load_blueprint_definition_by_id(blueprint_id)
	if(load_result["error"])
		plan.metadata["error"] = "[load_result["error"]]"
		return plan

	return world_edit_build_plan_from_blueprint(load_result["blueprint"], anchor_turf)

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
	result.message = "Blueprint preview ready: entries=[plan.metadata["entry_count"]], radius=[plan.metadata["radius"]]."
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
	result.message = "Blueprint '[plan.metadata["blueprint_name"]]' stamped successfully: created=[created_count]."
	return result

/datum/world_edit_generator/blueprint_stamp/get_apply_confirmation_text(list/params)
	return "Подтвердить stamp выбранного blueprint на текущем тайле?"

/datum/world_edit_generator/blueprint_stamp/get_params_short(list/params)
	return "blueprint_id=[params["blueprint_id"]]"
