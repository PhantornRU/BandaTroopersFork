/datum/world_edit_generator/destruction_pack
	requires_preview_before_apply = TRUE

/datum/world_edit_generator/destruction_pack/get_supported_placement_modes()
	return list("single", "repeat")

/datum/world_edit_generator/destruction_pack/get_supported_placement_shapes()
	return GLOB.world_edit_placement_shapes.world_edit_get_supported_shape_ids().Copy()

/datum/world_edit_generator/destruction_pack/supports_placement_direction()
	return TRUE
