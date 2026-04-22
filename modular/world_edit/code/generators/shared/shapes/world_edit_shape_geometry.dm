GLOBAL_DATUM_INIT(world_edit_shape_geometry, /datum/world_edit_shape_geometry_service, new)

/datum/world_edit_shape_geometry_service

/datum/world_edit_shape_geometry_service/proc/build_shape_contract(shape_id, turf/start_turf, turf/end_turf, list/params, direction = NORTH)
	var/list/shape_result = GLOB.world_edit_placement_shapes.world_edit_build_shape_turfs(shape_id, start_turf, end_turf, params, direction)
	return build_shape_contract_from_result(shape_id, shape_result)

/datum/world_edit_shape_geometry_service/proc/build_shape_contract_from_result(shape_id, list/shape_result)
	var/datum/world_edit_shape_contract/shape_contract = new
	shape_contract.shape_id = "[shape_id || shape_result["shape_id"] || WORLD_EDIT_SHAPE_POINT]"
	shape_contract.shape_label = GLOB.world_edit_shape_catalog.get_placement_shape_label(shape_contract.shape_id)
	shape_contract.interaction_kind = GLOB.world_edit_shape_catalog.get_shape_interaction_kind(shape_contract.shape_id)
	shape_contract.preview_kind = GLOB.world_edit_shape_catalog.get_shape_preview_kind(shape_contract.shape_id)
	if(!islist(shape_result))
		shape_contract.error = "Не удалось определить форму размещения."
		return shape_contract

	shape_contract.raw_result = shape_result.Copy()
	shape_contract.error = shape_result["error"]
	shape_contract.is_closed = GLOB.world_edit_helpers.parse_bool(shape_result["is_closed"])
	shape_contract.is_filled = GLOB.world_edit_helpers.parse_bool(shape_result["is_filled"])
	shape_contract.degenerate_kind = shape_result["degenerate_kind"]
	var/list/source_metadata = shape_result["metadata"]
	shape_contract.metadata = islist(source_metadata) ? source_metadata.Copy() : list()
	shape_contract.anchor_turfs = GLOB.world_edit_placement_shapes.world_edit_unique_turf_list(shape_result["turfs"])
	shape_contract.metadata["is_closed"] = shape_contract.is_closed ? TRUE : FALSE
	shape_contract.metadata["is_filled"] = shape_contract.is_filled ? TRUE : FALSE
	shape_contract.metadata["degenerate_kind"] = shape_contract.degenerate_kind
	return shape_contract
