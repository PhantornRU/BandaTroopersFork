#define WORLD_EDIT_FORTIFY_ROOM_TILE_CAP_DEFAULT 195
#define WORLD_EDIT_FORTIFY_ROOM_TILE_CAP_MIN 25
#define WORLD_EDIT_FORTIFY_ROOM_TILE_CAP_MAX 600

/datum/world_edit_generator/fortify_room
	requires_preview_before_apply = TRUE

/datum/world_edit_generator/fortify_room/get_supported_placement_modes()
	return list("single", "repeat")

/datum/world_edit_generator/fortify_room/get_supported_placement_shapes()
	return list(WORLD_EDIT_SHAPE_POINT)

/datum/world_edit_generator/fortify_room/supports_placement_direction()
	return FALSE

/datum/world_edit_generator/fortify_room/get_shape_support_error(shape_id, list/anchor_turfs, list/params, list/placement_context)
	return "[shape_id]" == WORLD_EDIT_SHAPE_POINT ? null : "Fortify Room supports only point placement."
