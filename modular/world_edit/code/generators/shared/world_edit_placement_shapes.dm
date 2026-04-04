#define WORLD_EDIT_SHAPE_POINT "point"
#define WORLD_EDIT_SHAPE_LINE "line"
#define WORLD_EDIT_SHAPE_RECTANGLE "rectangle"
#define WORLD_EDIT_SHAPE_FILLED_RECTANGLE "filled_rectangle"
#define WORLD_EDIT_SHAPE_CIRCLE "circle"
#define WORLD_EDIT_SHAPE_RING "ring"
#define WORLD_EDIT_SHAPE_ELLIPSE "ellipse"
#define WORLD_EDIT_SHAPE_DIAMOND "diamond"
#define WORLD_EDIT_SHAPE_TRIANGLE "triangle"
#define WORLD_EDIT_SHAPE_SECTOR "sector"
#define WORLD_EDIT_SHAPE_POLYGON "polygon"
#define WORLD_EDIT_SHAPE_POLYLINE "polyline"
#define WORLD_EDIT_SHAPE_CUSTOM_MASK "custom_mask"
#define WORLD_EDIT_SHAPE_BRUSH_PATH "brush_path"
#define WORLD_EDIT_SHAPE_SCATTER_CLUSTER "scatter_cluster"

#define WORLD_EDIT_PLACEMENT_MAX_CUSTOM_POINTS 24
#define WORLD_EDIT_PLACEMENT_MAX_SCATTER_POINTS 24

GLOBAL_DATUM_INIT(world_edit_placement_shapes, /datum/world_edit_placement_shape_service, new)

/datum/world_edit_placement_shape_service

/datum/world_edit_placement_shape_service/proc/world_edit_get_supported_shape_ids()
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

/datum/world_edit_placement_shape_service/proc/world_edit_get_placement_shape_label(shape_id)
	switch("[shape_id]")
		if(WORLD_EDIT_SHAPE_POINT)
			return "Point"
		if(WORLD_EDIT_SHAPE_LINE)
			return "Line"
		if(WORLD_EDIT_SHAPE_RECTANGLE)
			return "Rectangle"
		if(WORLD_EDIT_SHAPE_FILLED_RECTANGLE)
			return "Filled Rectangle"
		if(WORLD_EDIT_SHAPE_CIRCLE)
			return "Circle"
		if(WORLD_EDIT_SHAPE_RING)
			return "Ring"
		if(WORLD_EDIT_SHAPE_ELLIPSE)
			return "Ellipse"
		if(WORLD_EDIT_SHAPE_DIAMOND)
			return "Diamond"
		if(WORLD_EDIT_SHAPE_TRIANGLE)
			return "Triangle"
		if(WORLD_EDIT_SHAPE_SECTOR)
			return "Arc / Sector"
		if(WORLD_EDIT_SHAPE_POLYGON)
			return "Polygon"
		if(WORLD_EDIT_SHAPE_POLYLINE)
			return "Freeform Path"
		if(WORLD_EDIT_SHAPE_CUSTOM_MASK)
			return "Custom Footprint"
		if(WORLD_EDIT_SHAPE_BRUSH_PATH)
			return "Brush Path Stamp"
		if(WORLD_EDIT_SHAPE_SCATTER_CLUSTER)
			return "Scatter Cluster"
	return "[shape_id]"

/datum/world_edit_placement_shape_service/proc/world_edit_get_placement_shape_description(shape_id)
	switch("[shape_id]")
		if(WORLD_EDIT_SHAPE_POINT)
			return "Single anchor at the selected turf."
		if(WORLD_EDIT_SHAPE_LINE)
			return "Line of anchors. Click placement uses two points; ordinary preview uses length and spacing."
		if(WORLD_EDIT_SHAPE_RECTANGLE)
			return "Rectangle border. Click placement uses two corners; ordinary preview uses width and height."
		if(WORLD_EDIT_SHAPE_FILLED_RECTANGLE)
			return "Filled rectangle. Click placement uses two corners; ordinary preview uses width and height."
		if(WORLD_EDIT_SHAPE_CIRCLE)
			return "Filled circular footprint around the anchor turf."
		if(WORLD_EDIT_SHAPE_RING)
			return "Circular ring with configurable thickness."
		if(WORLD_EDIT_SHAPE_ELLIPSE)
			return "Filled ellipse footprint."
		if(WORLD_EDIT_SHAPE_DIAMOND)
			return "Diamond footprint using Manhattan distance."
		if(WORLD_EDIT_SHAPE_TRIANGLE)
			return "Directional triangle footprint."
		if(WORLD_EDIT_SHAPE_SECTOR)
			return "Directional arc / sector footprint."
		if(WORLD_EDIT_SHAPE_POLYGON)
			return "Polygon from an interactive relative point list collector."
		if(WORLD_EDIT_SHAPE_POLYLINE)
			return "Polyline / path from an interactive relative point list collector."
		if(WORLD_EDIT_SHAPE_CUSTOM_MASK)
			return "Exact relative point mask collected interactively or entered manually."
		if(WORLD_EDIT_SHAPE_BRUSH_PATH)
			return "Brush-stamped path from an interactive relative point list collector."
		if(WORLD_EDIT_SHAPE_SCATTER_CLUSTER)
			return "Deterministic scatter cluster around the anchor."
	return ""

/datum/world_edit_placement_shape_service/proc/world_edit_shape_uses_anchor_pair(shape_id)
	return ("[shape_id]" in list(
		WORLD_EDIT_SHAPE_LINE,
		WORLD_EDIT_SHAPE_RECTANGLE,
		WORLD_EDIT_SHAPE_FILLED_RECTANGLE,
	)) ? TRUE : FALSE

/datum/world_edit_placement_shape_service/proc/world_edit_get_shape_interaction_kind(shape_id)
	switch("[shape_id]")
		if(
			WORLD_EDIT_SHAPE_LINE,
			WORLD_EDIT_SHAPE_RECTANGLE,
			WORLD_EDIT_SHAPE_FILLED_RECTANGLE
		)
			return "anchor_pair"
		if(
			WORLD_EDIT_SHAPE_POLYGON,
			WORLD_EDIT_SHAPE_POLYLINE,
			WORLD_EDIT_SHAPE_CUSTOM_MASK,
			WORLD_EDIT_SHAPE_BRUSH_PATH
		)
			return "collector"
		if(WORLD_EDIT_SHAPE_SCATTER_CLUSTER)
			return "param_only"
	return "single"

/datum/world_edit_placement_shape_service/proc/world_edit_get_shape_interaction_label(shape_id)
	switch(world_edit_get_shape_interaction_kind(shape_id))
		if("anchor_pair")
			return "Anchor Pair"
		if("collector")
			return "Multi-Point Collector"
		if("param_only")
			return "Param-Driven"
	return "Single Click"

/datum/world_edit_placement_shape_service/proc/world_edit_get_shape_rollout_stage(shape_id)
	switch(world_edit_get_shape_interaction_kind(shape_id))
		if("collector")
			return "v2_collector"
		if("param_only")
			return "v2_param"
	return "v1"

/datum/world_edit_placement_shape_service/proc/world_edit_format_shape_points(list/points)
	if(!islist(points) || !length(points))
		return ""

	var/list/chunks = list()
	for(var/list/point as anything in points)
		chunks += "[text2num("[point["x"]]")],[text2num("[point["y"]]")]"
	return jointext(chunks, "; ")

/datum/world_edit_placement_shape_service/proc/world_edit_get_shape_collector_min_points(shape_id)
	switch("[shape_id]")
		if(WORLD_EDIT_SHAPE_POLYGON)
			return 3
		if(WORLD_EDIT_SHAPE_POLYLINE, WORLD_EDIT_SHAPE_BRUSH_PATH)
			return 2
		if(WORLD_EDIT_SHAPE_CUSTOM_MASK)
			return 1
	return 1

/datum/world_edit_placement_shape_service/proc/world_edit_get_shape_collector_max_points(shape_id)
	switch("[shape_id]")
		if(
			WORLD_EDIT_SHAPE_POLYGON,
			WORLD_EDIT_SHAPE_POLYLINE,
			WORLD_EDIT_SHAPE_CUSTOM_MASK,
			WORLD_EDIT_SHAPE_BRUSH_PATH
		)
			return WORLD_EDIT_PLACEMENT_MAX_CUSTOM_POINTS
	return WORLD_EDIT_PLACEMENT_MAX_CUSTOM_POINTS

/datum/world_edit_placement_shape_service/proc/world_edit_build_placement_shape_option(shape_id)
	return list(
		"value" = "[shape_id]",
		"label" = world_edit_get_placement_shape_label(shape_id),
		"description" = world_edit_get_placement_shape_description(shape_id),
		"interaction_kind" = world_edit_get_shape_interaction_kind(shape_id),
		"interaction_label" = world_edit_get_shape_interaction_label(shape_id),
		"rollout_stage" = world_edit_get_shape_rollout_stage(shape_id),
	)

/datum/world_edit_placement_shape_service/proc/world_edit_shape_num_param(list/current_params, param_id, default_value, min_value = null, max_value = null)
	var/raw_value = islist(current_params) ? current_params[param_id] : null
	var/value = text2num("[raw_value]")
	if(!isnum(value))
		value = default_value
	if(isnum(min_value) && value < min_value)
		value = min_value
	if(isnum(max_value) && value > max_value)
		value = max_value
	return value

/datum/world_edit_placement_shape_service/proc/world_edit_build_shape_ui_fields(shape_id, list/current_params)
	var/list/fields = list()
	var/points_text = islist(current_params) ? "[current_params["shape_points_text"]]" : ""
	var/polygon_filled = islist(current_params) ? GLOB.world_edit_helpers.parse_bool(current_params["shape_polygon_filled"]) : FALSE
	var/close_loop = islist(current_params) ? !("[current_params["shape_close_loop"]]" == "FALSE") : TRUE
	switch("[shape_id]")
		if(WORLD_EDIT_SHAPE_LINE)
			fields += list(
				list(
					"id" = "shape_line_length",
					"label" = "Length",
					"kind" = "number",
					"description" = "Fallback line length for ordinary preview/apply.",
					"value" = world_edit_shape_num_param(current_params, "shape_line_length", 5, 1, WORLD_EDIT_PLACEMENT_MAX_ANCHORS),
					"min" = 1,
					"max" = WORLD_EDIT_PLACEMENT_MAX_ANCHORS,
					"step" = 1,
				),
				list(
					"id" = "shape_line_spacing",
					"label" = "Spacing",
					"kind" = "number",
					"description" = "Anchor spacing along the line.",
					"value" = world_edit_shape_num_param(current_params, "shape_line_spacing", 1, 1, 8),
					"min" = 1,
					"max" = 8,
					"step" = 1,
				),
			)
		if(WORLD_EDIT_SHAPE_RECTANGLE, WORLD_EDIT_SHAPE_FILLED_RECTANGLE)
			fields += list(
				list(
					"id" = "shape_rect_width",
					"label" = "Width",
					"kind" = "number",
					"description" = "Fallback width for ordinary preview/apply.",
					"value" = world_edit_shape_num_param(current_params, "shape_rect_width", 5, 1, WORLD_EDIT_PLACEMENT_MAX_ANCHORS),
					"min" = 1,
					"max" = WORLD_EDIT_PLACEMENT_MAX_ANCHORS,
					"step" = 1,
				),
				list(
					"id" = "shape_rect_height",
					"label" = "Height",
					"kind" = "number",
					"description" = "Fallback height for ordinary preview/apply.",
					"value" = world_edit_shape_num_param(current_params, "shape_rect_height", 5, 1, WORLD_EDIT_PLACEMENT_MAX_ANCHORS),
					"min" = 1,
					"max" = WORLD_EDIT_PLACEMENT_MAX_ANCHORS,
					"step" = 1,
				),
			)
		if(WORLD_EDIT_SHAPE_CIRCLE, WORLD_EDIT_SHAPE_RING, WORLD_EDIT_SHAPE_DIAMOND, WORLD_EDIT_SHAPE_SECTOR)
			fields += list(
				list(
					"id" = "shape_radius",
					"label" = "Radius",
					"kind" = "number",
					"description" = "Shape radius around the anchor turf.",
					"value" = world_edit_shape_num_param(current_params, "shape_radius", 3, 1, 12),
					"min" = 1,
					"max" = 12,
					"step" = 1,
				),
			)
			if("[shape_id]" == WORLD_EDIT_SHAPE_RING || "[shape_id]" == WORLD_EDIT_SHAPE_SECTOR)
				fields += list(list(
					"id" = "shape_thickness",
					"label" = "Thickness",
					"kind" = "number",
					"description" = "Ring / arc thickness in tiles.",
					"value" = world_edit_shape_num_param(current_params, "shape_thickness", 1, 1, 12),
					"min" = 1,
					"max" = 12,
					"step" = 1,
				))
			if("[shape_id]" == WORLD_EDIT_SHAPE_SECTOR)
				fields += list(list(
					"id" = "shape_sector_angle",
					"label" = "Angle",
					"kind" = "number",
					"description" = "Sector angle in degrees.",
					"value" = world_edit_shape_num_param(current_params, "shape_sector_angle", 90, 15, 360),
					"min" = 15,
					"max" = 360,
					"step" = 15,
				))
		if(WORLD_EDIT_SHAPE_ELLIPSE)
			fields += list(
				list(
					"id" = "shape_radius_x",
					"label" = "Radius X",
					"kind" = "number",
					"description" = "Horizontal ellipse radius.",
					"value" = world_edit_shape_num_param(current_params, "shape_radius_x", 4, 1, 12),
					"min" = 1,
					"max" = 12,
					"step" = 1,
				),
				list(
					"id" = "shape_radius_y",
					"label" = "Radius Y",
					"kind" = "number",
					"description" = "Vertical ellipse radius.",
					"value" = world_edit_shape_num_param(current_params, "shape_radius_y", 2, 1, 12),
					"min" = 1,
					"max" = 12,
					"step" = 1,
				),
			)
		if(WORLD_EDIT_SHAPE_TRIANGLE)
			fields += list(list(
				"id" = "shape_triangle_size",
				"label" = "Size",
				"kind" = "number",
				"description" = "Triangle depth in tiles.",
				"value" = world_edit_shape_num_param(current_params, "shape_triangle_size", 4, 1, 12),
				"min" = 1,
				"max" = 12,
				"step" = 1,
			))
		if(WORLD_EDIT_SHAPE_POLYGON)
			fields += list(
				list(
					"id" = "shape_points_text",
					"label" = "Points",
					"kind" = "text",
					"description" = "Relative points: x,y; x,y; x,y",
					"placeholder" = "0,0; 4,0; 3,2; 0,3",
					"value" = length(points_text) ? points_text : "0,0; 4,0; 3,2; 0,3",
				),
				list(
					"id" = "shape_polygon_filled",
					"label" = "Filled",
					"kind" = "boolean",
					"description" = "Fill the polygon interior.",
					"value" = polygon_filled,
				),
				list(
					"id" = "shape_close_loop",
					"label" = "Close Loop",
					"kind" = "boolean",
					"description" = "Connect the last point back to the first one.",
					"value" = close_loop,
				),
			)
		if(WORLD_EDIT_SHAPE_POLYLINE)
			fields += list(list(
				"id" = "shape_points_text",
				"label" = "Points",
				"kind" = "text",
				"description" = "Relative points: x,y; x,y; x,y",
				"placeholder" = "0,0; 2,1; 4,1; 5,3",
				"value" = length(points_text) ? points_text : "0,0; 2,1; 4,1; 5,3",
			))
		if(WORLD_EDIT_SHAPE_CUSTOM_MASK)
			fields += list(list(
				"id" = "shape_points_text",
				"label" = "Points",
				"kind" = "text",
				"description" = "Exact relative mask points: x,y; x,y; x,y",
				"placeholder" = "0,0; 1,0; 1,1; 2,1",
				"value" = length(points_text) ? points_text : "0,0; 1,0; 1,1; 2,1",
			))
		if(WORLD_EDIT_SHAPE_BRUSH_PATH)
			fields += list(
				list(
					"id" = "shape_points_text",
					"label" = "Points",
					"kind" = "text",
					"description" = "Relative path points: x,y; x,y; x,y",
					"placeholder" = "0,0; 2,1; 4,2; 6,2",
					"value" = length(points_text) ? points_text : "0,0; 2,1; 4,2; 6,2",
				),
				list(
					"id" = "shape_brush_radius",
					"label" = "Brush Radius",
					"kind" = "number",
					"description" = "Brush radius stamped along the path.",
					"value" = world_edit_shape_num_param(current_params, "shape_brush_radius", 1, 1, 6),
					"min" = 1,
					"max" = 6,
					"step" = 1,
				),
			)
		if(WORLD_EDIT_SHAPE_SCATTER_CLUSTER)
			fields += list(
				list(
					"id" = "shape_scatter_radius",
					"label" = "Radius",
					"kind" = "number",
					"description" = "Scatter radius around the anchor turf.",
					"value" = world_edit_shape_num_param(current_params, "shape_scatter_radius", 4, 1, 12),
					"min" = 1,
					"max" = 12,
					"step" = 1,
				),
				list(
					"id" = "shape_scatter_count",
					"label" = "Count",
					"kind" = "number",
					"description" = "Number of anchors to pick.",
					"value" = world_edit_shape_num_param(current_params, "shape_scatter_count", 8, 1, WORLD_EDIT_PLACEMENT_MAX_SCATTER_POINTS),
					"min" = 1,
					"max" = WORLD_EDIT_PLACEMENT_MAX_SCATTER_POINTS,
					"step" = 1,
				),
				list(
					"id" = "shape_scatter_seed",
					"label" = "Seed",
					"kind" = "number",
					"description" = "Optional deterministic seed. 0 means auto.",
					"value" = world_edit_shape_num_param(current_params, "shape_scatter_seed", 0, 0, 999999),
					"min" = 0,
					"max" = 999999,
					"step" = 1,
				),
			)
	return fields

/datum/world_edit_placement_shape_service/proc/world_edit_add_turf_unique(list/turfs, list/turf_lookup, turf/target_turf, expected_z = null)
	if(!istype(target_turf))
		return
	if(isnum(expected_z) && target_turf.z != expected_z)
		return
	if(turf_lookup[target_turf])
		return
	turf_lookup[target_turf] = TRUE
	turfs += target_turf

/datum/world_edit_placement_shape_service/proc/world_edit_add_coord_unique(list/coords, list/coord_lookup, x_value, y_value)
	var/key = "[x_value],[y_value]"
	if(coord_lookup[key])
		return
	coord_lookup[key] = TRUE
	coords += list(list("x" = x_value, "y" = y_value))

/datum/world_edit_placement_shape_service/proc/world_edit_collect_line_coords(x0, y0, x1, y1)
	var/list/coords = list()
	var/list/coord_lookup = list()
	var/dx = abs(x1 - x0)
	var/dy = abs(y1 - y0)
	var/sx = x0 < x1 ? 1 : -1
	var/sy = y0 < y1 ? 1 : -1
	var/err = dx - dy

	while(TRUE)
		world_edit_add_coord_unique(coords, coord_lookup, x0, y0)
		if(x0 == x1 && y0 == y1)
			break

		var/e2 = err * 2
		if(e2 > -dy)
			err -= dy
			x0 += sx
		if(e2 < dx)
			err += dx
			y0 += sy

	return coords

/datum/world_edit_placement_shape_service/proc/world_edit_offsets_to_turfs(turf/anchor_turf, list/offsets)
	var/list/turfs = list()
	var/list/turf_lookup = list()
	if(!istype(anchor_turf) || !islist(offsets))
		return turfs

	for(var/list/offset as anything in offsets)
		var/turf/target_turf = locate(anchor_turf.x + text2num("[offset["x"]]"), anchor_turf.y + text2num("[offset["y"]]"), anchor_turf.z)
		world_edit_add_turf_unique(turfs, turf_lookup, target_turf, anchor_turf.z)

	return turfs

/datum/world_edit_placement_shape_service/proc/world_edit_collect_centered_rectangle_turfs(turf/anchor_turf, width, height, filled = TRUE)
	var/list/turfs = list()
	var/list/turf_lookup = list()
	if(!istype(anchor_turf))
		return turfs

	width = max(round(width), 1)
	height = max(round(height), 1)
	var/half_left = max(round((width - 1) / 2), 0)
	var/half_right = max(width - half_left - 1, 0)
	var/half_bottom = max(round((height - 1) / 2), 0)
	var/half_top = max(height - half_bottom - 1, 0)
	var/min_x = anchor_turf.x - half_left
	var/max_x = anchor_turf.x + half_right
	var/min_y = anchor_turf.y - half_bottom
	var/max_y = anchor_turf.y + half_top

	for(var/y in min_y to max_y)
		for(var/x in min_x to max_x)
			if(!filled && x != min_x && x != max_x && y != min_y && y != max_y)
				continue
			var/turf/target_turf = locate(x, y, anchor_turf.z)
			world_edit_add_turf_unique(turfs, turf_lookup, target_turf, anchor_turf.z)

	return turfs

/datum/world_edit_placement_shape_service/proc/world_edit_collect_circle_turfs(turf/anchor_turf, radius, inner_radius = 0)
	var/list/turfs = list()
	var/list/turf_lookup = list()
	if(!istype(anchor_turf))
		return turfs

	radius = max(round(radius), 0)
	inner_radius = max(round(inner_radius), 0)
	for(var/dy in -radius to radius)
		for(var/dx in -radius to radius)
			var/distance_sq = (dx * dx) + (dy * dy)
			if(distance_sq > (radius * radius))
				continue
			if(inner_radius > 0 && distance_sq < (inner_radius * inner_radius))
				continue
			var/turf/target_turf = locate(anchor_turf.x + dx, anchor_turf.y + dy, anchor_turf.z)
			world_edit_add_turf_unique(turfs, turf_lookup, target_turf, anchor_turf.z)

	return turfs

/datum/world_edit_placement_shape_service/proc/world_edit_collect_ellipse_turfs(turf/anchor_turf, radius_x, radius_y)
	var/list/turfs = list()
	var/list/turf_lookup = list()
	if(!istype(anchor_turf))
		return turfs

	radius_x = max(round(radius_x), 1)
	radius_y = max(round(radius_y), 1)
	for(var/dy in -radius_y to radius_y)
		for(var/dx in -radius_x to radius_x)
			var/norm_x = (dx * dx) / (radius_x * radius_x)
			var/norm_y = (dy * dy) / (radius_y * radius_y)
			if((norm_x + norm_y) > 1)
				continue
			var/turf/target_turf = locate(anchor_turf.x + dx, anchor_turf.y + dy, anchor_turf.z)
			world_edit_add_turf_unique(turfs, turf_lookup, target_turf, anchor_turf.z)

	return turfs

/datum/world_edit_placement_shape_service/proc/world_edit_collect_diamond_turfs(turf/anchor_turf, radius)
	var/list/turfs = list()
	var/list/turf_lookup = list()
	if(!istype(anchor_turf))
		return turfs

	radius = max(round(radius), 0)
	for(var/dy in -radius to radius)
		for(var/dx in -radius to radius)
			if(abs(dx) + abs(dy) > radius)
				continue
			var/turf/target_turf = locate(anchor_turf.x + dx, anchor_turf.y + dy, anchor_turf.z)
			world_edit_add_turf_unique(turfs, turf_lookup, target_turf, anchor_turf.z)

	return turfs

/datum/world_edit_placement_shape_service/proc/world_edit_collect_triangle_turfs(turf/anchor_turf, size, direction = NORTH)
	var/list/turfs = list()
	var/list/turf_lookup = list()
	if(!istype(anchor_turf))
		return turfs

	size = max(round(size), 1)
	for(var/step in 0 to (size - 1))
		var/half_width = step
		for(var/lateral in -half_width to half_width)
			var/x = anchor_turf.x
			var/y = anchor_turf.y
			switch(direction)
				if(NORTH)
					x += lateral
					y += step
				if(SOUTH)
					x += lateral
					y -= step
				if(EAST)
					x += step
					y += lateral
				if(WEST)
					x -= step
					y += lateral
			var/turf/target_turf = locate(x, y, anchor_turf.z)
			world_edit_add_turf_unique(turfs, turf_lookup, target_turf, anchor_turf.z)

	return turfs

/datum/world_edit_placement_shape_service/proc/world_edit_collect_sector_turfs(turf/anchor_turf, radius, sector_angle, thickness = 0, direction = NORTH)
	var/list/turfs = list()
	var/list/turf_lookup = list()
	if(!istype(anchor_turf))
		return turfs

	radius = max(round(radius), 1)
	sector_angle = clamp(round(sector_angle), 1, 360)
	thickness = max(round(thickness), 0)
	var/inner_radius = max(radius - thickness, 0)
	var/forward_x = 0
	var/forward_y = 1
	switch(direction)
		if(SOUTH)
			forward_y = -1
		if(EAST)
			forward_x = 1
			forward_y = 0
		if(WEST)
			forward_x = -1
			forward_y = 0

	var/min_cos = cos(sector_angle / 2)
	for(var/dy in -radius to radius)
		for(var/dx in -radius to radius)
			var/distance_sq = (dx * dx) + (dy * dy)
			if(distance_sq > (radius * radius))
				continue
			if(inner_radius > 0 && distance_sq < (inner_radius * inner_radius))
				continue
			if(dx == 0 && dy == 0)
				var/turf/center_turf = locate(anchor_turf.x, anchor_turf.y, anchor_turf.z)
				world_edit_add_turf_unique(turfs, turf_lookup, center_turf, anchor_turf.z)
				continue
			var/distance = sqrt(distance_sq)
			var/cosine = ((dx * forward_x) + (dy * forward_y)) / distance
			if(cosine < min_cos)
				continue
			var/turf/target_turf = locate(anchor_turf.x + dx, anchor_turf.y + dy, anchor_turf.z)
			world_edit_add_turf_unique(turfs, turf_lookup, target_turf, anchor_turf.z)

	return turfs

/datum/world_edit_placement_shape_service/proc/world_edit_parse_shape_points(raw_text)
	var/list/points = list()
	if(isnull(raw_text))
		return points

	var/text_value = trim("[raw_text]")
	if(!length(text_value))
		return points

	text_value = replacetext(text_value, ascii2text(13), "")
	text_value = replacetext(text_value, ascii2text(10), ";")
	text_value = replacetext(text_value, "|", ";")
	var/list/chunks = splittext(text_value, ";")
	var/list/point_lookup = list()
	for(var/chunk in chunks)
		var/entry_text = trim("[chunk]")
		if(!length(entry_text))
			continue
		var/list/pair = splittext(entry_text, ",")
		if(length(pair) < 2)
			continue
		var/dx = text2num(trim("[pair[1]]"))
		var/dy = text2num(trim("[pair[2]]"))
		if(!isnum(dx) || !isnum(dy))
			continue
		var/key = "[dx],[dy]"
		if(point_lookup[key])
			continue
		point_lookup[key] = TRUE
		points += list(list("x" = dx, "y" = dy))
		if(length(points) >= WORLD_EDIT_PLACEMENT_MAX_CUSTOM_POINTS)
			break

	return points

/datum/world_edit_placement_shape_service/proc/world_edit_collect_polyline_offsets(list/points, close_loop = FALSE)
	var/list/coords = list()
	var/list/coord_lookup = list()
	if(!islist(points) || length(points) < 2)
		return coords

	for(var/i in 1 to (length(points) - 1))
		var/list/start_point = points[i]
		var/list/end_point = points[i + 1]
		var/list/segment = world_edit_collect_line_coords(text2num("[start_point["x"]]"), text2num("[start_point["y"]]"), text2num("[end_point["x"]]"), text2num("[end_point["y"]]"))
		for(var/list/coord as anything in segment)
			world_edit_add_coord_unique(coords, coord_lookup, coord["x"], coord["y"])

	if(close_loop && length(points) >= 3)
		var/list/start_point = points[length(points)]
		var/list/end_point = points[1]
		var/list/segment = world_edit_collect_line_coords(text2num("[start_point["x"]]"), text2num("[start_point["y"]]"), text2num("[end_point["x"]]"), text2num("[end_point["y"]]"))
		for(var/list/coord as anything in segment)
			world_edit_add_coord_unique(coords, coord_lookup, coord["x"], coord["y"])

	return coords

/datum/world_edit_placement_shape_service/proc/world_edit_point_in_polygon(x_value, y_value, list/points)
	if(!islist(points) || length(points) < 3)
		return FALSE

	var/inside = FALSE
	var/j = length(points)
	for(var/i in 1 to length(points))
		var/list/point_i = points[i]
		var/list/point_j = points[j]
		var/xi = text2num("[point_i["x"]]")
		var/yi = text2num("[point_i["y"]]")
		var/xj = text2num("[point_j["x"]]")
		var/yj = text2num("[point_j["y"]]")

		var/intersects = ((yi > y_value) != (yj > y_value))
		if(intersects)
			var/denominator = (yj - yi)
			if(!denominator)
				j = i
				continue
			var/cross_x = ((xj - xi) * (y_value - yi) / denominator) + xi
			if(x_value <= cross_x)
				inside = !inside
		j = i

	return inside

/datum/world_edit_placement_shape_service/proc/world_edit_collect_polygon_turfs(turf/anchor_turf, list/points, filled = FALSE, close_loop = TRUE)
	var/list/turfs = list()
	if(!istype(anchor_turf))
		return turfs

	var/list/border_coords = world_edit_collect_polyline_offsets(points, close_loop)
	turfs = world_edit_offsets_to_turfs(anchor_turf, border_coords)
	if(!filled || !islist(points) || length(points) < 3)
		return turfs

	var/min_x = null
	var/max_x = null
	var/min_y = null
	var/max_y = null
	for(var/list/point as anything in points)
		var/x_value = text2num("[point["x"]]")
		var/y_value = text2num("[point["y"]]")
		if(isnull(min_x) || x_value < min_x)
			min_x = x_value
		if(isnull(max_x) || x_value > max_x)
			max_x = x_value
		if(isnull(min_y) || y_value < min_y)
			min_y = y_value
		if(isnull(max_y) || y_value > max_y)
			max_y = y_value

	var/list/turf_lookup = list()
	for(var/turf/existing as anything in turfs)
		turf_lookup[existing] = TRUE

	for(var/y in min_y to max_y)
		for(var/x in min_x to max_x)
			if(!world_edit_point_in_polygon(x, y, points))
				continue
			var/turf/target_turf = locate(anchor_turf.x + x, anchor_turf.y + y, anchor_turf.z)
			world_edit_add_turf_unique(turfs, turf_lookup, target_turf, anchor_turf.z)

	return turfs

/datum/world_edit_placement_shape_service/proc/world_edit_collect_brush_path_turfs(turf/anchor_turf, list/points, brush_radius)
	var/list/turfs = list()
	var/list/turf_lookup = list()
	if(!istype(anchor_turf))
		return turfs

	brush_radius = max(round(brush_radius), 1)
	var/list/path_offsets = world_edit_collect_polyline_offsets(points, FALSE)
	for(var/list/offset as anything in path_offsets)
		var/turf/brush_center = locate(anchor_turf.x + text2num("[offset["x"]]"), anchor_turf.y + text2num("[offset["y"]]"), anchor_turf.z)
		var/list/brush_turfs = world_edit_collect_circle_turfs(brush_center, brush_radius, max(brush_radius - 1, 0))
		for(var/turf/target_turf as anything in brush_turfs)
			world_edit_add_turf_unique(turfs, turf_lookup, target_turf, anchor_turf.z)

	return turfs

/datum/world_edit_placement_shape_service/proc/world_edit_collect_scatter_cluster_turfs(turf/anchor_turf, radius, count, seed_value = 0)
	var/list/turfs = list()
	if(!istype(anchor_turf))
		return turfs

	radius = max(round(radius), 1)
	count = clamp(round(count), 1, WORLD_EDIT_PLACEMENT_MAX_SCATTER_POINTS)
	var/list/candidates = world_edit_collect_circle_turfs(anchor_turf, radius, 0)
	if(!length(candidates))
		return turfs

	var/list/selected_lookup = list()
	if(seed_value <= 0)
		seed_value = rand(1, 1000000)

	for(var/i in 1 to min(count, length(candidates)))
		var/index = 1 + ((seed_value + (i * 73)) % length(candidates))
		var/turf/candidate_turf = candidates[index]
		var/safety_counter = 0
		while(selected_lookup[candidate_turf] && safety_counter < length(candidates))
			index++
			if(index > length(candidates))
				index = 1
			candidate_turf = candidates[index]
			safety_counter++
		if(selected_lookup[candidate_turf])
			break
		selected_lookup[candidate_turf] = TRUE
		turfs += candidate_turf

	return turfs

/datum/world_edit_placement_shape_service/proc/world_edit_apply_spacing_to_turfs(list/turfs, spacing = 1)
	if(!islist(turfs) || !length(turfs))
		return list()
	spacing = max(round(spacing), 1)
	if(spacing <= 1)
		return turfs.Copy()

	var/list/result = list()
	var/index = 1
	while(index <= length(turfs))
		result += turfs[index]
		index += spacing
	return result

/datum/world_edit_placement_shape_service/proc/world_edit_build_shape_turfs(shape_id, turf/start_turf, turf/end_turf, list/current_params, direction = NORTH)
	var/list/result = list(
		"turfs" = list(),
		"metadata" = list(
			"shape" = "[shape_id]",
			"shape_label" = world_edit_get_placement_shape_label(shape_id),
			"interaction_kind" = world_edit_get_shape_interaction_kind(shape_id),
			"interaction_label" = world_edit_get_shape_interaction_label(shape_id),
			"rollout_stage" = world_edit_get_shape_rollout_stage(shape_id),
			"uses_anchor_pair" = world_edit_shape_uses_anchor_pair(shape_id) ? TRUE : FALSE,
		),
	)
	if(!istype(start_turf))
		result["error"] = "Unable to resolve the shape anchor turf."
		return result

	var/list/turfs = result["turfs"]
	switch("[shape_id]")
		if(WORLD_EDIT_SHAPE_POINT)
			turfs += start_turf
		if(WORLD_EDIT_SHAPE_LINE)
			var/list/source_line = list()
			if(istype(end_turf) && end_turf.z == start_turf.z && end_turf != start_turf)
				source_line = GLOB.world_edit_helpers.collect_line_turfs(start_turf, end_turf)
			else
				var/length = world_edit_shape_num_param(current_params, "shape_line_length", 5, 1, WORLD_EDIT_PLACEMENT_MAX_ANCHORS)
				var/turf/line_end = GLOB.world_edit_helpers.step_turf(start_turf, direction, max(length - 1, 0))
				source_line = GLOB.world_edit_helpers.collect_line_turfs(start_turf, line_end)
			turfs = world_edit_apply_spacing_to_turfs(source_line, world_edit_shape_num_param(current_params, "shape_line_spacing", 1, 1, 8))
			result["turfs"] = turfs
		if(WORLD_EDIT_SHAPE_RECTANGLE)
			if(istype(end_turf) && end_turf.z == start_turf.z && end_turf != start_turf)
				var/list/filled_turfs = GLOB.world_edit_helpers.collect_rectangle_turfs(start_turf, end_turf)
				var/list/border_turfs = list()
				var/list/border_lookup = list()
				var/min_x = min(start_turf.x, end_turf.x)
				var/max_x = max(start_turf.x, end_turf.x)
				var/min_y = min(start_turf.y, end_turf.y)
				var/max_y = max(start_turf.y, end_turf.y)
				for(var/turf/target_turf as anything in filled_turfs)
					if(target_turf.x != min_x && target_turf.x != max_x && target_turf.y != min_y && target_turf.y != max_y)
						continue
					world_edit_add_turf_unique(border_turfs, border_lookup, target_turf, start_turf.z)
				turfs = border_turfs
				result["turfs"] = turfs
			else
				turfs = world_edit_collect_centered_rectangle_turfs(start_turf, world_edit_shape_num_param(current_params, "shape_rect_width", 5, 1, WORLD_EDIT_PLACEMENT_MAX_ANCHORS), world_edit_shape_num_param(current_params, "shape_rect_height", 5, 1, WORLD_EDIT_PLACEMENT_MAX_ANCHORS), FALSE)
				result["turfs"] = turfs
		if(WORLD_EDIT_SHAPE_FILLED_RECTANGLE)
			if(istype(end_turf) && end_turf.z == start_turf.z && end_turf != start_turf)
				turfs = GLOB.world_edit_helpers.collect_rectangle_turfs(start_turf, end_turf)
				result["turfs"] = turfs
			else
				turfs = world_edit_collect_centered_rectangle_turfs(start_turf, world_edit_shape_num_param(current_params, "shape_rect_width", 5, 1, WORLD_EDIT_PLACEMENT_MAX_ANCHORS), world_edit_shape_num_param(current_params, "shape_rect_height", 5, 1, WORLD_EDIT_PLACEMENT_MAX_ANCHORS), TRUE)
				result["turfs"] = turfs
		if(WORLD_EDIT_SHAPE_CIRCLE)
			turfs = world_edit_collect_circle_turfs(start_turf, world_edit_shape_num_param(current_params, "shape_radius", 3, 1, 12), 0)
			result["turfs"] = turfs
		if(WORLD_EDIT_SHAPE_RING)
			var/radius = world_edit_shape_num_param(current_params, "shape_radius", 4, 1, 12)
			var/thickness = world_edit_shape_num_param(current_params, "shape_thickness", 1, 1, 12)
			turfs = world_edit_collect_circle_turfs(start_turf, radius, max(radius - thickness, 0))
			result["turfs"] = turfs
		if(WORLD_EDIT_SHAPE_ELLIPSE)
			turfs = world_edit_collect_ellipse_turfs(start_turf, world_edit_shape_num_param(current_params, "shape_radius_x", 4, 1, 12), world_edit_shape_num_param(current_params, "shape_radius_y", 2, 1, 12))
			result["turfs"] = turfs
		if(WORLD_EDIT_SHAPE_DIAMOND)
			turfs = world_edit_collect_diamond_turfs(start_turf, world_edit_shape_num_param(current_params, "shape_radius", 4, 1, 12))
			result["turfs"] = turfs
		if(WORLD_EDIT_SHAPE_TRIANGLE)
			turfs = world_edit_collect_triangle_turfs(start_turf, world_edit_shape_num_param(current_params, "shape_triangle_size", 4, 1, 12), direction)
			result["turfs"] = turfs
		if(WORLD_EDIT_SHAPE_SECTOR)
			turfs = world_edit_collect_sector_turfs(start_turf, world_edit_shape_num_param(current_params, "shape_radius", 4, 1, 12), world_edit_shape_num_param(current_params, "shape_sector_angle", 90, 15, 360), world_edit_shape_num_param(current_params, "shape_thickness", 0, 0, 12), direction)
			result["turfs"] = turfs
		if(WORLD_EDIT_SHAPE_POLYGON)
			var/list/points = world_edit_parse_shape_points(current_params["shape_points_text"])
			if(length(points) < 3)
				result["error"] = "Polygon shape requires at least three valid relative points."
				return result
			turfs = world_edit_collect_polygon_turfs(start_turf, points, GLOB.world_edit_helpers.parse_bool(current_params["shape_polygon_filled"]), !("[current_params["shape_close_loop"]]" == "FALSE"))
			result["turfs"] = turfs
			result["metadata"]["custom_point_count"] = length(points)
		if(WORLD_EDIT_SHAPE_POLYLINE)
			var/list/points = world_edit_parse_shape_points(current_params["shape_points_text"])
			if(length(points) < 2)
				result["error"] = "Freeform path requires at least two valid relative points."
				return result
			turfs = world_edit_offsets_to_turfs(start_turf, world_edit_collect_polyline_offsets(points, FALSE))
			result["turfs"] = turfs
			result["metadata"]["custom_point_count"] = length(points)
		if(WORLD_EDIT_SHAPE_CUSTOM_MASK)
			var/list/points = world_edit_parse_shape_points(current_params["shape_points_text"])
			if(!length(points))
				result["error"] = "Custom footprint requires at least one valid relative point."
				return result
			turfs = world_edit_offsets_to_turfs(start_turf, points)
			result["turfs"] = turfs
			result["metadata"]["custom_point_count"] = length(points)
		if(WORLD_EDIT_SHAPE_BRUSH_PATH)
			var/list/points = world_edit_parse_shape_points(current_params["shape_points_text"])
			if(length(points) < 2)
				result["error"] = "Brush path requires at least two valid relative points."
				return result
			turfs = world_edit_collect_brush_path_turfs(start_turf, points, world_edit_shape_num_param(current_params, "shape_brush_radius", 1, 1, 6))
			result["turfs"] = turfs
			result["metadata"]["custom_point_count"] = length(points)
		if(WORLD_EDIT_SHAPE_SCATTER_CLUSTER)
			var/seed_value = world_edit_shape_num_param(current_params, "shape_scatter_seed", 0, 0, 999999)
			turfs = world_edit_collect_scatter_cluster_turfs(start_turf, world_edit_shape_num_param(current_params, "shape_scatter_radius", 4, 1, 12), world_edit_shape_num_param(current_params, "shape_scatter_count", 8, 1, WORLD_EDIT_PLACEMENT_MAX_SCATTER_POINTS), seed_value)
			result["turfs"] = turfs
			result["metadata"]["seed"] = seed_value
		else
			result["error"] = "Unsupported placement shape '[shape_id]'."
			return result

	if(length(result["turfs"]) > WORLD_EDIT_PLACEMENT_MAX_ANCHORS)
		result["error"] = "Requested footprint exceeds the safe anchor cap ([WORLD_EDIT_PLACEMENT_MAX_ANCHORS])."
		return result
	if(!length(result["turfs"]))
		result["error"] = "Shape '[world_edit_get_placement_shape_label(shape_id)]' resolved to no valid turfs."
		return result

	result["metadata"]["anchor_count"] = length(result["turfs"])
	return result
