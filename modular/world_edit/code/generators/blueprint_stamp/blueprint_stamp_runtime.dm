/datum/world_edit_generator/blueprint_stamp/proc/build_blueprint_preview_spec_from_placement(list/placement)
	if(!islist(placement))
		return null

	var/turf/target_turf = placement["turf"]
	var/obj_path = placement["obj_path"]
	if(!istype(target_turf) || !ispath(obj_path, /obj))
		return null

	var/list/entry_vars = islist(placement["vars"]) ? placement["vars"] : list()
	return GLOB.world_edit_helpers.build_world_edit_atom_preview_spec(obj_path, target_turf, placement["dir"], entry_vars)

/datum/world_edit_generator/blueprint_stamp/build_plan_preview_object_specs(datum/world_edit_plan/plan, list/runtime_params = null, list/placement_context = null, hover_only = FALSE)
	var/list/specs = list()
	if(!istype(plan))
		return specs

	var/spec_limit = hover_only ? WORLD_EDIT_BLUEPRINT_STAMP_MAX_HOVER_PREVIEW_OBJECT_SPECS : length(plan.placements)
	var/total_specs = length(plan.placements)
	for(var/list/placement as anything in plan.placements)
		if(length(specs) >= spec_limit)
			break
		var/list/spec = build_blueprint_preview_spec_from_placement(placement)
		if(islist(spec))
			specs += list(spec)

	plan.metadata["preview_object_specs_total"] = total_specs
	plan.metadata["preview_object_specs_truncated"] = total_specs > length(specs)
	plan.metadata["preview_object_specs_hover"] = hover_only ? TRUE : FALSE
	return specs

/datum/world_edit_generator/blueprint_stamp/preview(mob/user, list/params)
	var/datum/world_edit_preview_result/result = new
	clear_built_plan()

	var/datum/world_edit_plan/plan = build_plan(params)
	if(!istype(plan))
		result.message = "Не удалось построить план шаблона."
		return result
	if(plan.metadata["error"])
		result.message = "[plan.metadata["error"]]"
		return result
	if(!length(plan.placements))
		result.message = "В шаблоне нет допустимых размещений."
		return result

	current_plan = plan
	result.success = TRUE
	if(!manager?.should_use_placement_layer_preview(plan))
		result.preview_images = GLOB.world_edit_helpers.build_turf_preview_images(plan.affected_turfs)
		result.preview_images += GLOB.world_edit_helpers.build_preview_images_from_specs(build_plan_preview_object_specs(plan, params))
	result.meta = plan.metadata.Copy()
	result.message = "Предпросмотр шаблона готов: опор=[plan.metadata["anchor_count"]], элементов=[plan.metadata["entry_count"]], пропущено=[plan.metadata["skipped_entry_count"] || 0], направление=[plan.metadata["placement_dir_label"]]."
	return result

/datum/world_edit_generator/blueprint_stamp/should_render_preview_via_placement_layers(datum/world_edit_plan/plan)
	return istype(plan) ? TRUE : FALSE

/datum/world_edit_generator/blueprint_stamp/should_skip_plan_build_for_hover_only_placement(datum/world_edit_shape_contract/shape_contract, list/runtime_params = null, list/placement_context = null)
	// Manager-side hover object preview budgets can opt into a bounded visual plan.
	// Otherwise cursor motion stays shape-only and the real plan is built on click.
	return TRUE

/datum/world_edit_generator/blueprint_stamp/should_build_hover_object_preview_plan(datum/world_edit_shape_contract/shape_contract, list/runtime_params = null, list/placement_context = null)
	if(!istype(shape_contract) || length("[shape_contract.error]"))
		return FALSE
	if(!length(shape_contract.anchor_turfs))
		return FALSE
	var/blueprint_id = islist(runtime_params) ? runtime_params["blueprint_id"] : null
	if(!length("[blueprint_id]"))
		return FALSE
	return TRUE

/datum/world_edit_generator/blueprint_stamp/get_hover_object_preview_anchor_limit()
	return WORLD_EDIT_BLUEPRINT_STAMP_HOVER_OBJECT_PREVIEW_MAX_ANCHORS

/datum/world_edit_generator/blueprint_stamp/get_hover_object_preview_min_interval_ds()
	return WORLD_EDIT_HOVER_OBJECT_PREVIEW_MIN_INTERVAL_DS

/datum/world_edit_generator/blueprint_stamp/apply(mob/user, list/params)
	return apply_plan(user, params, current_plan)

/datum/world_edit_generator/blueprint_stamp/apply_plan(mob/user, list/params, datum/world_edit_plan/plan)
	var/datum/world_edit_apply_result/result = new
	if(!istype(plan))
		result.message = "Сначала выполните предпросмотр, чтобы построить план шаблона."
		return result
	if(plan.metadata["error"])
		result.message = "[plan.metadata["error"]]"
		return result
	if(!length(plan.placements))
		result.message = "Применение шаблона завершилось без допустимых размещений."
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
		result.message = "Применение шаблона завершилось без создания структур."
		return result

	result.success = TRUE
	result.changeset = changeset
	result.message = "Шаблон '[plan.metadata["blueprint_name"]]' успешно отпечатан: опор=[plan.metadata["anchor_count"]], создано=[created_count], пропущено=[skipped_runtime], направление=[plan.metadata["placement_dir_label"]]."
	return result
