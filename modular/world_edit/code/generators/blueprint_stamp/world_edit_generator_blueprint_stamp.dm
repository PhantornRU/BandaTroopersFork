#define WORLD_EDIT_BLUEPRINT_STAMP_MAX_HOVER_PREVIEW_OBJECT_SPECS 96
#define WORLD_EDIT_BLUEPRINT_STAMP_HOVER_OBJECT_PREVIEW_MAX_ANCHORS 2

/datum/world_edit_generator/blueprint_stamp
	requires_preview_before_apply = TRUE

/datum/world_edit_generator/blueprint_stamp/get_supported_placement_modes()
	return list("single", "repeat")

/datum/world_edit_generator/blueprint_stamp/get_supported_placement_shapes()
	return list(
		WORLD_EDIT_SHAPE_POINT,
		WORLD_EDIT_SHAPE_LINE,
		WORLD_EDIT_SHAPE_RECTANGLE,
		WORLD_EDIT_SHAPE_FILLED_RECTANGLE,
		WORLD_EDIT_SHAPE_CIRCLE,
		WORLD_EDIT_SHAPE_RING,
		WORLD_EDIT_SHAPE_ELLIPSE,
		WORLD_EDIT_SHAPE_DIAMOND,
		WORLD_EDIT_SHAPE_TRIANGLE,
		WORLD_EDIT_SHAPE_SECTOR,
		WORLD_EDIT_SHAPE_POLYGON,
		WORLD_EDIT_SHAPE_POLYLINE,
		WORLD_EDIT_SHAPE_CUSTOM_MASK,
		WORLD_EDIT_SHAPE_BRUSH_PATH,
		WORLD_EDIT_SHAPE_SCATTER_CLUSTER,
	)

/datum/world_edit_generator/blueprint_stamp/supports_placement_direction()
	return TRUE

/datum/world_edit_generator/blueprint_stamp/get_default_placement_direction()
	return NORTH
