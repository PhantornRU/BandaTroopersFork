/datum/world_edit_generator/destruction_pack
	requires_preview_before_apply = TRUE

/datum/world_edit_generator/destruction_pack/get_supported_placement_modes()
	return list("single", "repeat")

/datum/world_edit_generator/destruction_pack/get_supported_placement_shapes()
	return list(WORLD_EDIT_SHAPE_POINT)
