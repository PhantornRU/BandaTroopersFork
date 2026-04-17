/datum/world_edit_manager/proc/build_safe_placement_anchor_turfs(shape_id, turf/start_turf, turf/end_turf)
	return GLOB.world_edit_placement_shapes.world_edit_build_shape_turfs(shape_id, start_turf, end_turf, build_effective_generator_params(null, shape_id), supports_current_placement_direction() ? get_effective_placement_dir() : NORTH)

/datum/world_edit_manager/proc/build_safe_placement_anchor_turfs_with_params(shape_id, turf/start_turf, turf/end_turf, list/source_params)
	return GLOB.world_edit_placement_shapes.world_edit_build_shape_turfs(shape_id, start_turf, end_turf, source_params, supports_current_placement_direction() ? get_effective_placement_dir() : NORTH)

/datum/world_edit_manager/proc/get_safe_placement_shape_support_error(shape_id, list/anchor_turfs, turf/start_turf, turf/end_turf, list/shape_metadata = null)
	if(!current_generator || !length("[shape_id]"))
		return null
	if(!islist(anchor_turfs) || !length(anchor_turfs))
		return null

	var/list/effective_shape_metadata = islist(shape_metadata) ? shape_metadata.Copy() : list()
	var/datum/world_edit_shape_contract/shape_contract = current_generator.build_shape_contract_from_placement_context(shape_id, anchor_turfs, list("shape_metadata" = effective_shape_metadata))
	var/list/support_result = current_generator.evaluate_shape_contract(shape_contract, build_effective_generator_params(null, shape_id), list(
		"mode" = get_effective_placement_mode() || "single",
		"shape" = "[shape_id]",
		"shape_contract" = shape_contract,
		"shape_metadata" = effective_shape_metadata,
		"anchor_turfs" = anchor_turfs,
		"start_turf" = start_turf,
		"end_turf" = end_turf,
		"direction" = get_effective_placement_dir(),
	))
	return islist(support_result) ? support_result["error"] : support_result

/datum/world_edit_manager/proc/get_placement_collector_absolute_turfs(turf/origin_turf)
	var/list/turfs = list()
	if(!istype(origin_turf))
		return turfs

	for(var/list/point as anything in get_placement_collector_points())
		var/target_x = origin_turf.x + text2num("[point["x"]]")
		var/target_y = origin_turf.y + text2num("[point["y"]]")
		var/turf/target_turf = locate(target_x, target_y, origin_turf.z)
		if(istype(target_turf))
			turfs += target_turf
	return turfs

/datum/world_edit_manager/proc/update_placement_collector_runtime_state(mob/user, turf/preview_turf, message_prefix = "")
	return update_placement_collector_runtime_state_v2(user, preview_turf, message_prefix, FALSE, FALSE)

/datum/world_edit_manager/proc/finish_placement_collection(mob/user, turf/preview_turf = null)
	return finish_placement_collection_v2(user, preview_turf)
