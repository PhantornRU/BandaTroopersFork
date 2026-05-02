#define WORLD_EDIT_PLACEMENT_MAX_CUSTOM_POINTS 480
#define WORLD_EDIT_PLACEMENT_MAX_SCATTER_POINTS 480
#define WORLD_EDIT_PLACEMENT_MAX_COLLECTOR_SPAN 160
#define WORLD_EDIT_PLACEMENT_MAX_SHAPE_RADIUS 24
#define WORLD_EDIT_PLACEMENT_MAX_BRUSH_RADIUS 12
#define WORLD_EDIT_PLACEMENT_MAX_SCATTER_RADIUS 24

GLOBAL_DATUM_INIT(world_edit_placement_shapes, /datum/world_edit_placement_shape_service, new)

/datum/world_edit_placement_shape_service

/datum/world_edit_placement_shape_service/proc/world_edit_get_supported_shape_ids() as /list
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
			return "Точка"
		if(WORLD_EDIT_SHAPE_LINE)
			return "Линия"
		if(WORLD_EDIT_SHAPE_RECTANGLE)
			return "Прямоугольник"
		if(WORLD_EDIT_SHAPE_FILLED_RECTANGLE)
			return "Заполненный прямоугольник"
		if(WORLD_EDIT_SHAPE_CIRCLE)
			return "Круг"
		if(WORLD_EDIT_SHAPE_RING)
			return "Кольцо"
		if(WORLD_EDIT_SHAPE_ELLIPSE)
			return "Эллипс"
		if(WORLD_EDIT_SHAPE_DIAMOND)
			return "Ромб"
		if(WORLD_EDIT_SHAPE_TRIANGLE)
			return "Треугольник"
		if(WORLD_EDIT_SHAPE_SECTOR)
			return "Дуга / сектор"
		if(WORLD_EDIT_SHAPE_POLYGON)
			return "Полигон"
		if(WORLD_EDIT_SHAPE_POLYLINE)
			return "Открытая полилиния"
		if(WORLD_EDIT_SHAPE_CUSTOM_MASK)
			return "Точная маска точек"
		if(WORLD_EDIT_SHAPE_BRUSH_PATH)
			return "Кистевой путь"
		if(WORLD_EDIT_SHAPE_SCATTER_CLUSTER)
			return "Кластер разброса"
	return "[shape_id]"

/datum/world_edit_placement_shape_service/proc/world_edit_get_placement_shape_description(shape_id)
	switch("[shape_id]")
		if(WORLD_EDIT_SHAPE_POINT)
			return "Одна опора на выбранном тайле."
		if(WORLD_EDIT_SHAPE_LINE)
			return "Линия опор. При размещении кликами использует две точки; обычный предпросмотр использует длину и шаг."
		if(WORLD_EDIT_SHAPE_RECTANGLE)
			return "Замкнутая граница прямоугольника. При размещении кликами использует два угла; обычный предпросмотр использует ширину и высоту."
		if(WORLD_EDIT_SHAPE_FILLED_RECTANGLE)
			return "Замкнутый заполненный прямоугольник. При размещении кликами использует два угла; обычный предпросмотр использует ширину и высоту."
		if(WORLD_EDIT_SHAPE_CIRCLE)
			return "Заполненный круговой отпечаток вокруг опорного тайла."
		if(WORLD_EDIT_SHAPE_RING)
			return "Круговое кольцо вокруг опорного тайла."
		if(WORLD_EDIT_SHAPE_ELLIPSE)
			return "Заполненный эллиптический отпечаток. При размещении кликами может выводить радиусы из пары опор."
		if(WORLD_EDIT_SHAPE_DIAMOND)
			return "Ромбовидный отпечаток по манхэттенскому расстоянию."
		if(WORLD_EDIT_SHAPE_TRIANGLE)
			return "Направленный клин / треугольный отпечаток."
		if(WORLD_EDIT_SHAPE_SECTOR)
			return "Направленный сектор с настраиваемым углом и толщиной."
		if(WORLD_EDIT_SHAPE_POLYGON)
			return "Замкнутый произвольный контур из интерактивного сборщика точек."
		if(WORLD_EDIT_SHAPE_POLYLINE)
			return "Открытый произвольный путь из интерактивного сборщика точек."
		if(WORLD_EDIT_SHAPE_CUSTOM_MASK)
			return "Точная маска собранных точек без рёбер и замыкания."
		if(WORLD_EDIT_SHAPE_BRUSH_PATH)
			return "Путь с отпечатками кисти из интерактивного сборщика точек."
		if(WORLD_EDIT_SHAPE_SCATTER_CLUSTER)
			return "Детерминированный кластер разброса вокруг опоры."
	return ""

/datum/world_edit_placement_shape_service/proc/world_edit_shape_uses_anchor_pair(shape_id)
	return ("[shape_id]" in list(
		WORLD_EDIT_SHAPE_LINE,
		WORLD_EDIT_SHAPE_RECTANGLE,
		WORLD_EDIT_SHAPE_FILLED_RECTANGLE,
		WORLD_EDIT_SHAPE_ELLIPSE,
		WORLD_EDIT_SHAPE_DIAMOND,
		WORLD_EDIT_SHAPE_TRIANGLE,
		WORLD_EDIT_SHAPE_SECTOR
	)) ? TRUE : FALSE

/datum/world_edit_placement_shape_service/proc/world_edit_get_shape_interaction_kind(shape_id)
	switch("[shape_id]")
		if(
			WORLD_EDIT_SHAPE_LINE,
			WORLD_EDIT_SHAPE_RECTANGLE,
			WORLD_EDIT_SHAPE_FILLED_RECTANGLE,
			WORLD_EDIT_SHAPE_ELLIPSE,
			WORLD_EDIT_SHAPE_DIAMOND,
			WORLD_EDIT_SHAPE_TRIANGLE,
			WORLD_EDIT_SHAPE_SECTOR
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
			return "Пара опор"
		if("collector")
			return "Сборщик точек"
		if("param_only")
			return "Параметрическая"
	return "Один клик"

/datum/world_edit_placement_shape_service/proc/world_edit_get_shape_preview_kind(shape_id)
	switch("[shape_id]")
		if(WORLD_EDIT_SHAPE_POINT)
			return "point"
		if(
			WORLD_EDIT_SHAPE_LINE,
			WORLD_EDIT_SHAPE_RECTANGLE,
			WORLD_EDIT_SHAPE_FILLED_RECTANGLE,
			WORLD_EDIT_SHAPE_ELLIPSE,
			WORLD_EDIT_SHAPE_DIAMOND,
			WORLD_EDIT_SHAPE_TRIANGLE,
			WORLD_EDIT_SHAPE_SECTOR
		)
			return "anchor_pair"
		if(WORLD_EDIT_SHAPE_CIRCLE, WORLD_EDIT_SHAPE_RING)
			return "centered_area"
		if(WORLD_EDIT_SHAPE_POLYGON)
			return "collector_polygon"
		if(WORLD_EDIT_SHAPE_POLYLINE)
			return "collector_polyline"
		if(WORLD_EDIT_SHAPE_CUSTOM_MASK)
			return "collector_mask"
		if(WORLD_EDIT_SHAPE_BRUSH_PATH)
			return "collector_brush"
		if(WORLD_EDIT_SHAPE_SCATTER_CLUSTER)
			return "scatter_cluster"
	return "shape"

/datum/world_edit_placement_shape_service/proc/world_edit_format_shape_points(list/points)
	if(!islist(points) || !length(points))
		return ""

	var/list/chunks = list()
	for(var/list/point as anything in points)
		var/raw_x = point["x"]
		var/raw_y = point["y"]
		var/x_value = text2num("[raw_x]")
		var/y_value = text2num("[raw_y]")
		chunks += "[x_value],[y_value]"
	return jointext(chunks, "; ")

/datum/world_edit_placement_shape_service/proc/world_edit_get_shape_collector_min_points(shape_id)
	switch("[shape_id]")
		if(WORLD_EDIT_SHAPE_POLYGON)
			return 3
		if(WORLD_EDIT_SHAPE_POLYLINE)
			return 2
		if(WORLD_EDIT_SHAPE_CUSTOM_MASK, WORLD_EDIT_SHAPE_BRUSH_PATH)
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
	var/raw_points_text = islist(current_params) ? current_params["shape_points_text"] : null
	var/points_text = isnull(raw_points_text) ? "" : "[raw_points_text]"
	var/polygon_filled = islist(current_params) ? GLOB.world_edit_helpers.parse_bool(current_params["shape_polygon_filled"]) : FALSE
	switch("[shape_id]")
		if(WORLD_EDIT_SHAPE_LINE)
			fields += list(
				list(
					"id" = "shape_line_length",
					"label" = "Длина",
					"kind" = "number",
					"description" = "Резервная длина линии для обычного предпросмотра и применения.",
					"value" = world_edit_shape_num_param(current_params, "shape_line_length", 5, 1, WORLD_EDIT_PLACEMENT_MAX_ANCHORS),
					"min" = 1,
					"max" = WORLD_EDIT_PLACEMENT_MAX_ANCHORS,
					"step" = 1,
				),
				list(
					"id" = "shape_line_spacing",
					"label" = "Шаг",
					"kind" = "number",
					"description" = "Шаг опор вдоль рассчитанной линии.",
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
					"label" = "Ширина",
					"kind" = "number",
					"description" = "Резервная ширина для обычного предпросмотра и применения.",
					"value" = world_edit_shape_num_param(current_params, "shape_rect_width", 5, 1, WORLD_EDIT_PLACEMENT_MAX_ANCHORS),
					"min" = 1,
					"max" = WORLD_EDIT_PLACEMENT_MAX_ANCHORS,
					"step" = 1,
				),
				list(
					"id" = "shape_rect_height",
					"label" = "Высота",
					"kind" = "number",
					"description" = "Резервная высота для обычного предпросмотра и применения.",
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
					"label" = "Радиус",
					"kind" = "number",
					"description" = "Радиус формы вокруг опорного тайла. Для вырожденных предпросмотров допускается 0.",
					"value" = world_edit_shape_num_param(current_params, "shape_radius", 3, 0, WORLD_EDIT_PLACEMENT_MAX_SHAPE_RADIUS),
					"min" = 0,
					"max" = WORLD_EDIT_PLACEMENT_MAX_SHAPE_RADIUS,
					"step" = 1,
				),
			)
			if("[shape_id]" == WORLD_EDIT_SHAPE_RING || "[shape_id]" == WORLD_EDIT_SHAPE_SECTOR)
				fields += list(list(
					"id" = "shape_thickness",
					"label" = "Толщина",
					"kind" = "number",
					"description" = "Толщина кольца / дуги в тайлах. 0 оставляет тонкий контур для колец и заполненный клин для секторов.",
					"value" = world_edit_shape_num_param(current_params, "shape_thickness", 1, 0, WORLD_EDIT_PLACEMENT_MAX_SHAPE_RADIUS),
					"min" = 0,
					"max" = WORLD_EDIT_PLACEMENT_MAX_SHAPE_RADIUS,
					"step" = 1,
				))
			if("[shape_id]" == WORLD_EDIT_SHAPE_SECTOR)
				fields += list(list(
					"id" = "shape_sector_angle",
					"label" = "Угол",
					"kind" = "number",
					"description" = "Угол сектора в градусах.",
					"value" = world_edit_shape_num_param(current_params, "shape_sector_angle", 90, 1, 360),
					"min" = 1,
					"max" = 360,
					"step" = 1,
				))
		if(WORLD_EDIT_SHAPE_ELLIPSE)
			fields += list(
				list(
					"id" = "shape_radius_x",
					"label" = "Радиус X",
					"kind" = "number",
					"description" = "Горизонтальный радиус эллипса. 0 сворачивает отпечаток в вертикальную линию / точку.",
					"value" = world_edit_shape_num_param(current_params, "shape_radius_x", 4, 0, WORLD_EDIT_PLACEMENT_MAX_SHAPE_RADIUS),
					"min" = 0,
					"max" = WORLD_EDIT_PLACEMENT_MAX_SHAPE_RADIUS,
					"step" = 1,
				),
				list(
					"id" = "shape_radius_y",
					"label" = "Радиус Y",
					"kind" = "number",
					"description" = "Вертикальный радиус эллипса. 0 сворачивает отпечаток в горизонтальную линию / точку.",
					"value" = world_edit_shape_num_param(current_params, "shape_radius_y", 2, 0, WORLD_EDIT_PLACEMENT_MAX_SHAPE_RADIUS),
					"min" = 0,
					"max" = WORLD_EDIT_PLACEMENT_MAX_SHAPE_RADIUS,
					"step" = 1,
				),
			)
		if(WORLD_EDIT_SHAPE_TRIANGLE)
			fields += list(list(
				"id" = "shape_triangle_size",
				"label" = "Размер",
				"kind" = "number",
				"description" = "Глубина треугольника в тайлах. 0 сворачивает форму в точку.",
				"value" = world_edit_shape_num_param(current_params, "shape_triangle_size", 4, 0, WORLD_EDIT_PLACEMENT_MAX_SHAPE_RADIUS),
				"min" = 0,
				"max" = WORLD_EDIT_PLACEMENT_MAX_SHAPE_RADIUS,
				"step" = 1,
			))
		if(WORLD_EDIT_SHAPE_POLYGON)
			fields += list(
				list(
					"id" = "shape_points_text",
					"label" = "Точки",
					"kind" = "text",
					"description" = "Точки замкнутого контура: x,y; x,y; x,y",
					"placeholder" = "0,0; 4,0; 3,2; 0,3",
					"value" = length(points_text) ? points_text : "0,0; 4,0; 3,2; 0,3",
				),
				list(
					"id" = "shape_polygon_filled",
					"label" = "Заполнение",
					"kind" = "boolean",
					"description" = "Заполнять внутреннюю область полигона.",
					"value" = polygon_filled,
				),
			)
		if(WORLD_EDIT_SHAPE_POLYLINE)
			fields += list(list(
				"id" = "shape_points_text",
				"label" = "Точки",
				"kind" = "text",
				"description" = "Точки открытого пути: x,y; x,y; x,y",
				"placeholder" = "0,0; 2,1; 4,1; 5,3",
				"value" = length(points_text) ? points_text : "0,0; 2,1; 4,1; 5,3",
			))
		if(WORLD_EDIT_SHAPE_CUSTOM_MASK)
			fields += list(list(
				"id" = "shape_points_text",
				"label" = "Точки",
				"kind" = "text",
				"description" = "Точная маска точек: x,y; x,y; x,y",
				"placeholder" = "0,0; 1,0; 1,1; 2,1",
				"value" = length(points_text) ? points_text : "0,0; 1,0; 1,1; 2,1",
			))
		if(WORLD_EDIT_SHAPE_BRUSH_PATH)
			fields += list(
				list(
					"id" = "shape_points_text",
					"label" = "Точки",
					"kind" = "text",
					"description" = "Точки открытого кистевого пути: x,y; x,y; x,y",
					"placeholder" = "0,0; 2,1; 4,2; 6,2",
					"value" = length(points_text) ? points_text : "0,0; 2,1; 4,2; 6,2",
				),
				list(
					"id" = "shape_brush_radius",
					"label" = "Радиус кисти",
					"kind" = "number",
					"description" = "Радиус кисти, отпечатываемый вдоль пути. 0 оставляет только контур пути.",
					"value" = world_edit_shape_num_param(current_params, "shape_brush_radius", 1, 0, WORLD_EDIT_PLACEMENT_MAX_BRUSH_RADIUS),
					"min" = 0,
					"max" = WORLD_EDIT_PLACEMENT_MAX_BRUSH_RADIUS,
					"step" = 1,
				),
			)
		if(WORLD_EDIT_SHAPE_SCATTER_CLUSTER)
			fields += list(
				list(
					"id" = "shape_scatter_radius",
					"label" = "Радиус",
					"kind" = "number",
					"description" = "Радиус разброса вокруг опорного тайла. 0 оставляет кластер на опоре.",
					"value" = world_edit_shape_num_param(current_params, "shape_scatter_radius", 4, 0, WORLD_EDIT_PLACEMENT_MAX_SCATTER_RADIUS),
					"min" = 0,
					"max" = WORLD_EDIT_PLACEMENT_MAX_SCATTER_RADIUS,
					"step" = 1,
				),
				list(
					"id" = "shape_scatter_count",
					"label" = "Количество",
					"kind" = "number",
					"description" = "Количество выбираемых опор.",
					"value" = world_edit_shape_num_param(current_params, "shape_scatter_count", 8, 1, WORLD_EDIT_PLACEMENT_MAX_SCATTER_POINTS),
					"min" = 1,
					"max" = WORLD_EDIT_PLACEMENT_MAX_SCATTER_POINTS,
					"step" = 1,
				),
				list(
					"id" = "shape_scatter_seed",
					"label" = "Сид",
					"kind" = "number",
					"description" = "Необязательный детерминированный сид. 0 выводит стабильный сид из опоры.",
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

/datum/world_edit_placement_shape_service/proc/world_edit_build_turf_lookup(list/turfs)
	var/list/lookup = list()
	if(!islist(turfs))
		return lookup

	for(var/turf/target_turf as anything in turfs)
		if(istype(target_turf))
			lookup[target_turf] = TRUE
	return lookup

/datum/world_edit_placement_shape_service/proc/world_edit_unique_turf_list(list/raw_turfs, expected_z = null)
	var/list/turfs = list()
	var/list/turf_lookup = list()
	if(!islist(raw_turfs))
		return turfs

	for(var/turf/target_turf as anything in raw_turfs)
		world_edit_add_turf_unique(turfs, turf_lookup, target_turf, expected_z)
	return turfs

/datum/world_edit_placement_shape_service/proc/world_edit_copy_point(list/point)
	if(!islist(point))
		return null
	var/raw_x = point["x"]
	var/raw_y = point["y"]
	return list(
		"x" = text2num("[raw_x]"),
		"y" = text2num("[raw_y]"),
	)

/datum/world_edit_placement_shape_service/proc/world_edit_copy_points(list/points)
	var/list/copied = list()
	if(!islist(points))
		return copied

	for(var/list/point as anything in points)
		var/list/copied_point = world_edit_copy_point(point)
		if(islist(copied_point))
			copied += list(copied_point)
	return copied

/datum/world_edit_placement_shape_service/proc/world_edit_get_points_span_error(list/points)
	if(!islist(points) || !length(points))
		return null

	var/min_x = null
	var/max_x = null
	var/min_y = null
	var/max_y = null
	for(var/list/point as anything in points)
		if(!islist(point))
			continue
		var/x_value = text2num("[point["x"]]")
		var/y_value = text2num("[point["y"]]")
		if(!isnum(x_value) || !isnum(y_value))
			continue
		if(isnull(min_x) || x_value < min_x)
			min_x = x_value
		if(isnull(max_x) || x_value > max_x)
			max_x = x_value
		if(isnull(min_y) || y_value < min_y)
			min_y = y_value
		if(isnull(max_y) || y_value > max_y)
			max_y = y_value

	if(isnull(min_x) || isnull(max_x) || isnull(min_y) || isnull(max_y))
		return null
	if((max_x - min_x) > WORLD_EDIT_PLACEMENT_MAX_COLLECTOR_SPAN || (max_y - min_y) > WORLD_EDIT_PLACEMENT_MAX_COLLECTOR_SPAN)
		return "Collector shape coordinate span exceeds the safe cap ([WORLD_EDIT_PLACEMENT_MAX_COLLECTOR_SPAN] tiles)."
	return null

/datum/world_edit_placement_shape_service/proc/world_edit_points_match(list/a, list/b)
	if(!islist(a) || !islist(b))
		return FALSE
	var/a_raw_x = a["x"]
	var/a_raw_y = a["y"]
	var/b_raw_x = b["x"]
	var/b_raw_y = b["y"]
	var/a_x = text2num("[a_raw_x]")
	var/a_y = text2num("[a_raw_y]")
	var/b_x = text2num("[b_raw_x]")
	var/b_y = text2num("[b_raw_y]")
	return a_x == b_x && a_y == b_y

/datum/world_edit_placement_shape_service/proc/world_edit_dedupe_consecutive_points(list/points)
	var/list/result = list()
	if(!islist(points))
		return result

	var/list/last_point = null
	for(var/list/point as anything in points)
		var/list/copied_point = world_edit_copy_point(point)
		if(!islist(copied_point))
			continue
		if(islist(last_point) && world_edit_points_match(last_point, copied_point))
			continue
		result += list(copied_point)
		last_point = copied_point
	return result

/datum/world_edit_placement_shape_service/proc/world_edit_dedupe_points_preserve_order(list/points)
	var/list/result = list()
	var/list/point_lookup = list()
	if(!islist(points))
		return result

	for(var/list/point as anything in points)
		var/list/copied_point = world_edit_copy_point(point)
		if(!islist(copied_point))
			continue
		var/copied_x = copied_point["x"]
		var/copied_y = copied_point["y"]
		var/key = "[copied_x],[copied_y]"
		if(point_lookup[key])
			continue
		point_lookup[key] = TRUE
		result += list(copied_point)
	return result

/datum/world_edit_placement_shape_service/proc/world_edit_normalize_polygon_points(list/raw_points)
	var/list/points = world_edit_dedupe_consecutive_points(raw_points)
	if(length(points) >= 2 && world_edit_points_match(points[1], points[length(points)]))
		points.Cut(length(points), length(points) + 1)
	return points

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
		var/raw_offset_x = offset["x"]
		var/raw_offset_y = offset["y"]
		var/offset_x = text2num("[raw_offset_x]")
		var/offset_y = text2num("[raw_offset_y]")
		var/turf/target_turf = locate(anchor_turf.x + offset_x, anchor_turf.y + offset_y, anchor_turf.z)
		world_edit_add_turf_unique(turfs, turf_lookup, target_turf, anchor_turf.z)
	return turfs

/datum/world_edit_placement_shape_service/proc/world_edit_points_to_turfs(turf/anchor_turf, list/points)
	return world_edit_offsets_to_turfs(anchor_turf, points)

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

/datum/world_edit_placement_shape_service/proc/world_edit_collect_line_turfs_between(turf/start_turf, turf/end_turf)
	var/list/turfs = list()
	var/list/turf_lookup = list()
	if(!istype(start_turf) || !istype(end_turf) || start_turf.z != end_turf.z)
		return turfs

	var/list/coords = world_edit_collect_line_coords(start_turf.x, start_turf.y, end_turf.x, end_turf.y)
	for(var/list/coord as anything in coords)
		var/raw_coord_x = coord["x"]
		var/raw_coord_y = coord["y"]
		var/coord_x = text2num("[raw_coord_x]")
		var/coord_y = text2num("[raw_coord_y]")
		var/turf/target_turf = locate(coord_x, coord_y, start_turf.z)
		world_edit_add_turf_unique(turfs, turf_lookup, target_turf, start_turf.z)
	return turfs

/datum/world_edit_placement_shape_service/proc/world_edit_collect_axis_line_turfs(turf/anchor_turf, start_dx, start_dy, end_dx, end_dy)
	if(!istype(anchor_turf))
		return list()

	var/turf/start_turf = locate(anchor_turf.x + round(start_dx), anchor_turf.y + round(start_dy), anchor_turf.z)
	var/turf/end_turf = locate(anchor_turf.x + round(end_dx), anchor_turf.y + round(end_dy), anchor_turf.z)
	return world_edit_collect_line_turfs_between(start_turf, end_turf)

/datum/world_edit_placement_shape_service/proc/world_edit_collect_ellipse_turfs(turf/anchor_turf, radius_x, radius_y)
	var/list/turfs = list()
	var/list/turf_lookup = list()
	if(!istype(anchor_turf))
		return turfs

	radius_x = max(round(radius_x), 0)
	radius_y = max(round(radius_y), 0)
	if(!radius_x && !radius_y)
		world_edit_add_turf_unique(turfs, turf_lookup, anchor_turf, anchor_turf.z)
		return turfs
	if(!radius_x)
		return world_edit_collect_axis_line_turfs(anchor_turf, 0, -radius_y, 0, radius_y)
	if(!radius_y)
		return world_edit_collect_axis_line_turfs(anchor_turf, -radius_x, 0, radius_x, 0)

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

	size = max(round(size), 0)
	if(!size)
		world_edit_add_turf_unique(turfs, turf_lookup, anchor_turf, anchor_turf.z)
		return turfs

	for(var/step in 0 to size)
		var/half_width = step
		for(var/lateral in -half_width to half_width)
			var/x_value = anchor_turf.x
			var/y_value = anchor_turf.y
			switch(direction)
				if(NORTH)
					x_value += lateral
					y_value += step
				if(SOUTH)
					x_value += lateral
					y_value -= step
				if(EAST)
					x_value += step
					y_value += lateral
				if(WEST)
					x_value -= step
					y_value += lateral
			var/turf/target_turf = locate(x_value, y_value, anchor_turf.z)
			world_edit_add_turf_unique(turfs, turf_lookup, target_turf, anchor_turf.z)
	return turfs

/datum/world_edit_placement_shape_service/proc/world_edit_collect_sector_turfs(turf/anchor_turf, radius, sector_angle, thickness = 0, direction = NORTH)
	var/list/turfs = list()
	var/list/turf_lookup = list()
	if(!istype(anchor_turf))
		return turfs

	radius = max(round(radius), 0)
	sector_angle = clamp(round(sector_angle), 1, 360)
	thickness = max(round(thickness), 0)
	if(!radius)
		world_edit_add_turf_unique(turfs, turf_lookup, anchor_turf, anchor_turf.z)
		return turfs

	var/inner_radius = (thickness > 0) ? max(radius - thickness, 0) : 0
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
				world_edit_add_turf_unique(turfs, turf_lookup, anchor_turf, anchor_turf.z)
				continue
			var/distance = sqrt(distance_sq)
			if(distance <= 0)
				continue
			var/cosine = ((dx * forward_x) + (dy * forward_y)) / distance
			if(cosine < min_cos)
				continue
			var/turf/target_turf = locate(anchor_turf.x + dx, anchor_turf.y + dy, anchor_turf.z)
			world_edit_add_turf_unique(turfs, turf_lookup, target_turf, anchor_turf.z)

	if(length(turfs) <= 1)
		var/turf/forward_turf = GLOB.world_edit_helpers.step_turf(anchor_turf, direction, 1)
		world_edit_add_turf_unique(turfs, turf_lookup, forward_turf, anchor_turf.z)
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
		var/start_raw_x = start_point["x"]
		var/start_raw_y = start_point["y"]
		var/end_raw_x = end_point["x"]
		var/end_raw_y = end_point["y"]
		var/start_x = text2num("[start_raw_x]")
		var/start_y = text2num("[start_raw_y]")
		var/end_x = text2num("[end_raw_x]")
		var/end_y = text2num("[end_raw_y]")
		var/list/segment = world_edit_collect_line_coords(start_x, start_y, end_x, end_y)
		for(var/list/coord as anything in segment)
			world_edit_add_coord_unique(coords, coord_lookup, coord["x"], coord["y"])

	if(close_loop && length(points) >= 3)
		var/list/closure_start = points[length(points)]
		var/list/closure_end = points[1]
		var/closure_start_raw_x = closure_start["x"]
		var/closure_start_raw_y = closure_start["y"]
		var/closure_end_raw_x = closure_end["x"]
		var/closure_end_raw_y = closure_end["y"]
		var/closure_start_x = text2num("[closure_start_raw_x]")
		var/closure_start_y = text2num("[closure_start_raw_y]")
		var/closure_end_x = text2num("[closure_end_raw_x]")
		var/closure_end_y = text2num("[closure_end_raw_y]")
		var/list/closure_segment = world_edit_collect_line_coords(closure_start_x, closure_start_y, closure_end_x, closure_end_y)
		for(var/list/coord as anything in closure_segment)
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
		var/point_i_raw_x = point_i["x"]
		var/point_i_raw_y = point_i["y"]
		var/point_j_raw_x = point_j["x"]
		var/point_j_raw_y = point_j["y"]
		var/xi = text2num("[point_i_raw_x]")
		var/yi = text2num("[point_i_raw_y]")
		var/xj = text2num("[point_j_raw_x]")
		var/yj = text2num("[point_j_raw_y]")
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

/datum/world_edit_placement_shape_service/proc/world_edit_collect_polygon_turfs(turf/anchor_turf, list/points, filled = FALSE)
	var/list/turfs = list()
	if(!istype(anchor_turf))
		return turfs

	var/list/border_coords = world_edit_collect_polyline_offsets(points, TRUE)
	turfs = world_edit_offsets_to_turfs(anchor_turf, border_coords)
	if(!filled || !islist(points) || length(points) < 3)
		return turfs

	var/min_x = null
	var/max_x = null
	var/min_y = null
	var/max_y = null
	for(var/list/point as anything in points)
		var/point_x = point["x"]
		var/point_y = point["y"]
		var/x_value = text2num("[point_x]")
		var/y_value = text2num("[point_y]")
		if(isnull(min_x) || x_value < min_x)
			min_x = x_value
		if(isnull(max_x) || x_value > max_x)
			max_x = x_value
		if(isnull(min_y) || y_value < min_y)
			min_y = y_value
		if(isnull(max_y) || y_value > max_y)
			max_y = y_value

	var/list/turf_lookup = world_edit_build_turf_lookup(turfs)
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

	brush_radius = max(round(brush_radius), 0)
	if(!islist(points) || !length(points))
		return turfs
	if(brush_radius <= 0)
		return world_edit_offsets_to_turfs(anchor_turf, world_edit_collect_polyline_offsets(points, FALSE))

	var/list/path_offsets = world_edit_collect_polyline_offsets(points, FALSE)
	if(length(points) == 1)
		path_offsets = list(world_edit_copy_point(points[1]))
	for(var/list/offset as anything in path_offsets)
		var/raw_offset_x = offset["x"]
		var/raw_offset_y = offset["y"]
		var/offset_x = text2num("[raw_offset_x]")
		var/offset_y = text2num("[raw_offset_y]")
		var/turf/brush_center = locate(anchor_turf.x + offset_x, anchor_turf.y + offset_y, anchor_turf.z)
		var/list/brush_turfs = world_edit_collect_circle_turfs(brush_center, brush_radius, 0)
		for(var/turf/target_turf as anything in brush_turfs)
			world_edit_add_turf_unique(turfs, turf_lookup, target_turf, anchor_turf.z)
	return turfs

/datum/world_edit_placement_shape_service/proc/world_edit_resolve_scatter_seed(turf/anchor_turf, radius, count, requested_seed = 0)
	requested_seed = max(round(requested_seed), 0)
	if(requested_seed > 0)
		return requested_seed
	if(!istype(anchor_turf))
		return 1
	return abs((anchor_turf.x * 131) + (anchor_turf.y * 173) + (anchor_turf.z * 197) + (max(round(radius), 0) * 211) + (max(round(count), 1) * 239))

/datum/world_edit_placement_shape_service/proc/world_edit_collect_scatter_cluster_turfs(turf/anchor_turf, radius, count, seed_value = 0)
	var/list/turfs = list()
	if(!istype(anchor_turf))
		return turfs

	radius = max(round(radius), 0)
	count = clamp(round(count), 1, WORLD_EDIT_PLACEMENT_MAX_SCATTER_POINTS)
	if(!radius)
		turfs += anchor_turf
		return turfs

	var/list/candidates = world_edit_collect_circle_turfs(anchor_turf, radius, 0)
	if(!length(candidates))
		turfs += anchor_turf
		return turfs

	seed_value = world_edit_resolve_scatter_seed(anchor_turf, radius, count, seed_value)
	var/target_count = min(count, length(candidates))
	var/list/candidate_lookup = world_edit_build_turf_lookup(candidates)
	var/list/selected_lookup = list()
	var/list/growth_frontier = list()
	world_edit_add_turf_unique(turfs, selected_lookup, anchor_turf, anchor_turf.z)
	growth_frontier += anchor_turf
	while(length(turfs) < target_count)
		var/list/frontier_candidates = list()
		var/list/frontier_lookup = list()
		for(var/turf/frontier_turf as anything in growth_frontier)
			if(!istype(frontier_turf))
				continue
			for(var/cardinal_dir in GLOB.cardinals)
				var/turf/neighbor_turf = get_step(frontier_turf, cardinal_dir)
				if(!candidate_lookup[neighbor_turf] || selected_lookup[neighbor_turf])
					continue
				world_edit_add_turf_unique(frontier_candidates, frontier_lookup, neighbor_turf, anchor_turf.z)
		if(!length(frontier_candidates))
			break
		var/index = 1 + ((seed_value + (length(turfs) * 73)) % length(frontier_candidates))
		var/turf/next_turf = frontier_candidates[index]
		if(!istype(next_turf))
			break
		world_edit_add_turf_unique(turfs, selected_lookup, next_turf, anchor_turf.z)
		growth_frontier += next_turf
	return turfs

/datum/world_edit_placement_shape_service/proc/world_edit_collect_boundary_turfs(list/turfs)
	var/list/boundary = list()
	var/list/boundary_lookup = list()
	var/list/turf_lookup = world_edit_build_turf_lookup(turfs)
	if(!length(turf_lookup))
		return boundary

	for(var/turf/target_turf as anything in turfs)
		if(!istype(target_turf))
			continue
		for(var/check_dir in list(NORTH, SOUTH, EAST, WEST))
			var/turf/neighbor_turf = get_step(target_turf, check_dir)
			if(turf_lookup[neighbor_turf])
				continue
			world_edit_add_turf_unique(boundary, boundary_lookup, target_turf, target_turf.z)
			break
	if(!length(boundary))
		return world_edit_unique_turf_list(turfs)
	return boundary

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

/datum/world_edit_placement_shape_service/proc/world_edit_get_anchor_pair_direction(turf/start_turf, turf/end_turf, fallback_direction = NORTH)
	if(!istype(start_turf) || !istype(end_turf))
		return fallback_direction

	var/dx = end_turf.x - start_turf.x
	var/dy = end_turf.y - start_turf.y
	if(!dx && !dy)
		return fallback_direction
	if(abs(dx) >= abs(dy))
		return (dx >= 0) ? EAST : WEST
	return (dy >= 0) ? NORTH : SOUTH

/datum/world_edit_placement_shape_service/proc/world_edit_collect_pair_turf_vertices(turf/start_turf, turf/end_turf)
	if(!istype(start_turf) && !istype(end_turf))
		return list()
	if(!istype(start_turf))
		return list(end_turf)
	if(!istype(end_turf))
		return list(start_turf)
	return world_edit_unique_turf_list(list(start_turf, end_turf), start_turf.z)

/datum/world_edit_placement_shape_service/proc/world_edit_merge_assoc_list(list/target, list/source)
	if(!islist(target) || !islist(source))
		return target
	for(var/key in source)
		target[key] = source[key]
	return target

/datum/world_edit_placement_shape_service/proc/world_edit_build_preview_layers(list/anchor_turfs = null, list/vertex_turfs = null, list/edge_turfs = null, list/closure_turfs = null, list/final_turfs = null, list/guide_turfs = null)
	return list(
		"anchor_turfs" = world_edit_unique_turf_list(anchor_turfs),
		"vertex_turfs" = world_edit_unique_turf_list(vertex_turfs),
		"edge_turfs" = world_edit_unique_turf_list(edge_turfs),
		"closure_turfs" = world_edit_unique_turf_list(closure_turfs),
		"final_turfs" = world_edit_unique_turf_list(final_turfs),
		"guide_turfs" = world_edit_unique_turf_list(guide_turfs),
	)

/datum/world_edit_placement_shape_service/proc/world_edit_build_shape_result(shape_id)
	var/shape_label = world_edit_get_placement_shape_label(shape_id)
	var/interaction_kind = world_edit_get_shape_interaction_kind(shape_id)
	var/preview_kind = world_edit_get_shape_preview_kind(shape_id)
	return list(
		"turfs" = list(),
		"shape_id" = "[shape_id]",
		"shape_label" = shape_label,
		"interaction_kind" = interaction_kind,
		"is_closed" = FALSE,
		"is_filled" = FALSE,
		"degenerate_kind" = "",
		"preview_kind" = preview_kind,
		"metadata" = list(
			"shape" = "[shape_id]",
			"shape_label" = shape_label,
			"interaction_kind" = interaction_kind,
			"interaction_label" = world_edit_get_shape_interaction_label(shape_id),
			"preview_kind" = preview_kind,
			"uses_anchor_pair" = world_edit_shape_uses_anchor_pair(shape_id) ? TRUE : FALSE,
			"preview_layers" = world_edit_build_preview_layers(),
		),
	)

/datum/world_edit_placement_shape_service/proc/world_edit_set_shape_preview_layers(list/result, list/anchor_turfs = null, list/vertex_turfs = null, list/edge_turfs = null, list/closure_turfs = null, list/final_turfs = null, list/guide_turfs = null)
	if(!islist(result))
		return
	var/list/metadata = result["metadata"]
	if(!islist(metadata))
		metadata = list()
		result["metadata"] = metadata
	metadata["preview_layers"] = world_edit_build_preview_layers(anchor_turfs, vertex_turfs, edge_turfs, closure_turfs, final_turfs, guide_turfs)

/datum/world_edit_placement_shape_service/proc/world_edit_finalize_shape_result(list/result, list/raw_turfs, degenerate_kind = null, list/extra_metadata = null, expected_z = null)
	if(!islist(result))
		return result

	var/list/metadata = result["metadata"]
	if(!islist(metadata))
		metadata = list()
		result["metadata"] = metadata

	var/list/turfs = world_edit_unique_turf_list(raw_turfs, expected_z)
	result["turfs"] = turfs
	result["degenerate_kind"] = isnull(degenerate_kind) ? "" : "[degenerate_kind]"
	metadata["degenerate_kind"] = result["degenerate_kind"]
	if(islist(extra_metadata))
		world_edit_merge_assoc_list(metadata, extra_metadata)

	var/list/preview_layers = metadata["preview_layers"]
	if(!islist(preview_layers))
		preview_layers = world_edit_build_preview_layers()
		metadata["preview_layers"] = preview_layers
	if(!length(preview_layers["final_turfs"]))
		preview_layers["final_turfs"] = turfs.Copy()

	if(length(turfs) > WORLD_EDIT_PLACEMENT_MAX_ANCHORS)
		result["error"] = "Requested footprint exceeds the safe anchor cap ([WORLD_EDIT_PLACEMENT_MAX_ANCHORS])."
		return result
	var/raw_error = result["error"]
	var/existing_error = isnull(raw_error) ? "" : "[raw_error]"
	if(!length(turfs) && !length(existing_error))
		var/shape_label = result["shape_label"]
		result["error"] = "Shape '[shape_label]' resolved to no valid turfs."
		return result

	metadata["anchor_count"] = length(turfs)
	return result

/datum/world_edit_placement_shape_service/proc/world_edit_build_shape_turfs(shape_id, turf/start_turf, turf/end_turf, list/current_params, direction = NORTH)
	var/list/result = world_edit_build_shape_result(shape_id)
	if(!istype(start_turf))
		result["error"] = "Не удалось определить опорный тайл формы."
		return result

	var/has_pair_end = istype(end_turf) && end_turf.z == start_turf.z
	var/effective_direction = has_pair_end ? world_edit_get_anchor_pair_direction(start_turf, end_turf, direction) : direction
	var/list/anchor_turfs = has_pair_end ? world_edit_collect_pair_turf_vertices(start_turf, end_turf) : list(start_turf)
	var/list/vertex_turfs = anchor_turfs.Copy()
	var/list/edge_turfs = list()
	var/list/closure_turfs = list()
	var/list/guide_turfs = list()
	var/list/final_turfs = list()
	var/list/extra_metadata = list(
		"placement_direction" = effective_direction,
		"placement_dir_label" = GLOB.world_edit_helpers.dir_to_label(effective_direction),
	)
	var/degenerate_kind = null
	var/shape_is_closed = FALSE
	var/shape_is_filled = FALSE

	switch("[shape_id]")
		if(WORLD_EDIT_SHAPE_POINT)
			final_turfs = list(start_turf)
			vertex_turfs = list(start_turf)

		if(WORLD_EDIT_SHAPE_LINE)
			var/list/base_line = list()
			if(has_pair_end)
				base_line = world_edit_collect_line_turfs_between(start_turf, end_turf)
			else
				var/line_length = world_edit_shape_num_param(current_params, "shape_line_length", 5, 1, WORLD_EDIT_PLACEMENT_MAX_ANCHORS)
				var/turf/line_end = GLOB.world_edit_helpers.step_turf(start_turf, effective_direction, max(line_length - 1, 0))
				base_line = world_edit_collect_line_turfs_between(start_turf, line_end)
			var/line_spacing = world_edit_shape_num_param(current_params, "shape_line_spacing", 1, 1, 8)
			final_turfs = world_edit_apply_spacing_to_turfs(base_line, line_spacing)
			edge_turfs = base_line
			guide_turfs = base_line
			extra_metadata["line_spacing"] = line_spacing
			extra_metadata["line_base_count"] = length(base_line)
			if(length(final_turfs) <= 1)
				degenerate_kind = "point"

		if(WORLD_EDIT_SHAPE_RECTANGLE, WORLD_EDIT_SHAPE_FILLED_RECTANGLE)
			var/filled_rectangle = ("[shape_id]" == WORLD_EDIT_SHAPE_FILLED_RECTANGLE)
			var/width = 1
			var/height = 1
			var/list/filled_turfs = list()
			if(has_pair_end)
				var/min_x = min(start_turf.x, end_turf.x)
				var/max_x = max(start_turf.x, end_turf.x)
				var/min_y = min(start_turf.y, end_turf.y)
				var/max_y = max(start_turf.y, end_turf.y)
				width = max_x - min_x + 1
				height = max_y - min_y + 1
				for(var/y in min_y to max_y)
					for(var/x in min_x to max_x)
						var/turf/target_turf = locate(x, y, start_turf.z)
						if(istype(target_turf))
							filled_turfs += target_turf
			else
				width = world_edit_shape_num_param(current_params, "shape_rect_width", 5, 1, WORLD_EDIT_PLACEMENT_MAX_ANCHORS)
				height = world_edit_shape_num_param(current_params, "shape_rect_height", 5, 1, WORLD_EDIT_PLACEMENT_MAX_ANCHORS)
				filled_turfs = world_edit_collect_centered_rectangle_turfs(start_turf, width, height, TRUE)
			edge_turfs = world_edit_collect_boundary_turfs(filled_turfs)
			final_turfs = filled_rectangle ? filled_turfs : edge_turfs
			shape_is_closed = (width > 1 && height > 1) ? TRUE : FALSE
			shape_is_filled = filled_rectangle && shape_is_closed
			extra_metadata["width"] = width
			extra_metadata["height"] = height
			if(width == 1 && height == 1)
				degenerate_kind = "point"
				shape_is_closed = FALSE
				shape_is_filled = FALSE
			else if(width == 1 || height == 1)
				degenerate_kind = "line"
				shape_is_closed = FALSE
				shape_is_filled = FALSE

		if(WORLD_EDIT_SHAPE_CIRCLE)
			var/circle_radius = world_edit_shape_num_param(current_params, "shape_radius", 3, 0, WORLD_EDIT_PLACEMENT_MAX_SHAPE_RADIUS)
			final_turfs = world_edit_collect_circle_turfs(start_turf, circle_radius, 0)
			edge_turfs = world_edit_collect_circle_turfs(start_turf, circle_radius, max(circle_radius - 1, 0))
			shape_is_closed = circle_radius > 0
			shape_is_filled = circle_radius > 0
			extra_metadata["radius"] = circle_radius
			if(!circle_radius)
				degenerate_kind = "point"

		if(WORLD_EDIT_SHAPE_RING)
			var/ring_radius = world_edit_shape_num_param(current_params, "shape_radius", 4, 0, WORLD_EDIT_PLACEMENT_MAX_SHAPE_RADIUS)
			var/ring_thickness = world_edit_shape_num_param(current_params, "shape_thickness", 1, 0, WORLD_EDIT_PLACEMENT_MAX_SHAPE_RADIUS)
			var/inner_radius = (ring_thickness > 0) ? max(ring_radius - ring_thickness, 0) : max(ring_radius - 1, 0)
			final_turfs = world_edit_collect_circle_turfs(start_turf, ring_radius, inner_radius)
			edge_turfs = world_edit_collect_circle_turfs(start_turf, ring_radius, max(ring_radius - 1, 0))
			shape_is_closed = ring_radius > 0
			shape_is_filled = ring_radius > 0
			extra_metadata["radius"] = ring_radius
			extra_metadata["thickness"] = ring_thickness
			extra_metadata["inner_radius"] = inner_radius
			if(!ring_radius)
				degenerate_kind = "point"
			else if(inner_radius <= 0)
				degenerate_kind = "filled_area"

		if(WORLD_EDIT_SHAPE_ELLIPSE)
			var/radius_x = has_pair_end ? abs(end_turf.x - start_turf.x) : world_edit_shape_num_param(current_params, "shape_radius_x", 4, 0, WORLD_EDIT_PLACEMENT_MAX_SHAPE_RADIUS)
			var/radius_y = has_pair_end ? abs(end_turf.y - start_turf.y) : world_edit_shape_num_param(current_params, "shape_radius_y", 2, 0, WORLD_EDIT_PLACEMENT_MAX_SHAPE_RADIUS)
			final_turfs = world_edit_collect_ellipse_turfs(start_turf, radius_x, radius_y)
			edge_turfs = world_edit_collect_boundary_turfs(final_turfs)
			extra_metadata["radius_x"] = radius_x
			extra_metadata["radius_y"] = radius_y
			if(!radius_x && !radius_y)
				degenerate_kind = "point"
			else if(!radius_x || !radius_y)
				degenerate_kind = "line"
			else
				shape_is_closed = TRUE
				shape_is_filled = TRUE

		if(WORLD_EDIT_SHAPE_DIAMOND)
			var/diamond_radius = has_pair_end ? (abs(end_turf.x - start_turf.x) + abs(end_turf.y - start_turf.y)) : world_edit_shape_num_param(current_params, "shape_radius", 4, 0, WORLD_EDIT_PLACEMENT_MAX_SHAPE_RADIUS)
			final_turfs = world_edit_collect_diamond_turfs(start_turf, diamond_radius)
			edge_turfs = world_edit_collect_boundary_turfs(final_turfs)
			shape_is_closed = diamond_radius > 0
			shape_is_filled = diamond_radius > 0
			extra_metadata["radius"] = diamond_radius
			if(!diamond_radius)
				degenerate_kind = "point"

		if(WORLD_EDIT_SHAPE_TRIANGLE)
			var/triangle_size = has_pair_end ? max(abs(end_turf.x - start_turf.x), abs(end_turf.y - start_turf.y)) : world_edit_shape_num_param(current_params, "shape_triangle_size", 4, 0, WORLD_EDIT_PLACEMENT_MAX_SHAPE_RADIUS)
			final_turfs = world_edit_collect_triangle_turfs(start_turf, triangle_size, effective_direction)
			edge_turfs = world_edit_collect_boundary_turfs(final_turfs)
			guide_turfs = world_edit_collect_line_turfs_between(start_turf, GLOB.world_edit_helpers.step_turf(start_turf, effective_direction, max(triangle_size, 1)))
			shape_is_closed = triangle_size > 0
			shape_is_filled = triangle_size > 0
			extra_metadata["size"] = triangle_size
			if(!triangle_size)
				degenerate_kind = "point"

		if(WORLD_EDIT_SHAPE_SECTOR)
			var/sector_radius = has_pair_end ? max(abs(end_turf.x - start_turf.x), abs(end_turf.y - start_turf.y)) : world_edit_shape_num_param(current_params, "shape_radius", 4, 0, WORLD_EDIT_PLACEMENT_MAX_SHAPE_RADIUS)
			var/sector_angle = world_edit_shape_num_param(current_params, "shape_sector_angle", 90, 1, 360)
			var/sector_thickness = world_edit_shape_num_param(current_params, "shape_thickness", 0, 0, WORLD_EDIT_PLACEMENT_MAX_SHAPE_RADIUS)
			final_turfs = world_edit_collect_sector_turfs(start_turf, sector_radius, sector_angle, sector_thickness, effective_direction)
			edge_turfs = world_edit_collect_boundary_turfs(final_turfs)
			guide_turfs = world_edit_collect_line_turfs_between(start_turf, GLOB.world_edit_helpers.step_turf(start_turf, effective_direction, max(sector_radius, 1)))
			shape_is_closed = sector_radius > 0
			shape_is_filled = sector_radius > 0
			extra_metadata["radius"] = sector_radius
			extra_metadata["angle"] = sector_angle
			extra_metadata["thickness"] = sector_thickness
			if(!sector_radius)
				degenerate_kind = "point"

		if(WORLD_EDIT_SHAPE_POLYGON)
			var/list/polygon_points = world_edit_normalize_polygon_points(world_edit_parse_shape_points(current_params ? current_params["shape_points_text"] : null))
			var/polygon_filled = current_params ? GLOB.world_edit_helpers.parse_bool(current_params["shape_polygon_filled"]) : FALSE
			vertex_turfs = world_edit_points_to_turfs(start_turf, polygon_points)
			if(!length(polygon_points))
				result["error"] = "Для формы-полигона нужна хотя бы одна корректная относительная точка."
				return result
			var/polygon_span_error = world_edit_get_points_span_error(polygon_points)
			if(length("[polygon_span_error]"))
				result["error"] = polygon_span_error
				return result
			if(length(polygon_points) == 1)
				final_turfs = world_edit_points_to_turfs(start_turf, polygon_points)
				degenerate_kind = "point"
			else
				var/list/path_offsets = world_edit_collect_polyline_offsets(polygon_points, FALSE)
				edge_turfs = world_edit_offsets_to_turfs(start_turf, path_offsets)
				var/list/last_polygon_point = polygon_points[length(polygon_points)]
				var/list/first_polygon_point = polygon_points[1]
				var/last_polygon_raw_x = last_polygon_point["x"]
				var/last_polygon_raw_y = last_polygon_point["y"]
				var/first_polygon_raw_x = first_polygon_point["x"]
				var/first_polygon_raw_y = first_polygon_point["y"]
				var/last_polygon_x = text2num("[last_polygon_raw_x]")
				var/last_polygon_y = text2num("[last_polygon_raw_y]")
				var/first_polygon_x = text2num("[first_polygon_raw_x]")
				var/first_polygon_y = text2num("[first_polygon_raw_y]")
				closure_turfs = world_edit_offsets_to_turfs(start_turf, world_edit_collect_line_coords(last_polygon_x, last_polygon_y, first_polygon_x, first_polygon_y))
				if(length(polygon_points) == 2)
					final_turfs = edge_turfs.Copy()
					degenerate_kind = "line"
				else
					final_turfs = world_edit_collect_polygon_turfs(start_turf, polygon_points, polygon_filled)
					shape_is_closed = TRUE
					shape_is_filled = polygon_filled ? TRUE : FALSE
			extra_metadata["custom_point_count"] = length(polygon_points)
			extra_metadata["normalized_points"] = world_edit_copy_points(polygon_points)

		if(WORLD_EDIT_SHAPE_POLYLINE)
			var/list/polyline_points = world_edit_dedupe_consecutive_points(world_edit_parse_shape_points(current_params ? current_params["shape_points_text"] : null))
			vertex_turfs = world_edit_points_to_turfs(start_turf, polyline_points)
			if(!length(polyline_points))
				result["error"] = "Для полилинии нужна хотя бы одна корректная относительная точка."
				return result
			var/polyline_span_error = world_edit_get_points_span_error(polyline_points)
			if(length("[polyline_span_error]"))
				result["error"] = polyline_span_error
				return result
			if(length(polyline_points) == 1)
				final_turfs = world_edit_points_to_turfs(start_turf, polyline_points)
				degenerate_kind = "point"
			else
				final_turfs = world_edit_offsets_to_turfs(start_turf, world_edit_collect_polyline_offsets(polyline_points, FALSE))
				edge_turfs = final_turfs.Copy()
			extra_metadata["custom_point_count"] = length(polyline_points)
			extra_metadata["normalized_points"] = world_edit_copy_points(polyline_points)

		if(WORLD_EDIT_SHAPE_CUSTOM_MASK)
			var/list/mask_points = world_edit_dedupe_points_preserve_order(world_edit_parse_shape_points(current_params ? current_params["shape_points_text"] : null))
			if(!length(mask_points))
				result["error"] = "Для пользовательской маски нужна хотя бы одна корректная относительная точка."
				return result
			var/mask_span_error = world_edit_get_points_span_error(mask_points)
			if(length("[mask_span_error]"))
				result["error"] = mask_span_error
				return result
			final_turfs = world_edit_points_to_turfs(start_turf, mask_points)
			vertex_turfs = final_turfs.Copy()
			if(length(mask_points) == 1)
				degenerate_kind = "point"
			extra_metadata["custom_point_count"] = length(mask_points)
			extra_metadata["normalized_points"] = world_edit_copy_points(mask_points)

		if(WORLD_EDIT_SHAPE_BRUSH_PATH)
			var/list/brush_points = world_edit_dedupe_consecutive_points(world_edit_parse_shape_points(current_params ? current_params["shape_points_text"] : null))
			var/brush_radius = world_edit_shape_num_param(current_params, "shape_brush_radius", 1, 0, WORLD_EDIT_PLACEMENT_MAX_BRUSH_RADIUS)
			vertex_turfs = world_edit_points_to_turfs(start_turf, brush_points)
			if(!length(brush_points))
				result["error"] = "Для кистевого пути нужна хотя бы одна корректная относительная точка."
				return result
			var/brush_span_error = world_edit_get_points_span_error(brush_points)
			if(length("[brush_span_error]"))
				result["error"] = brush_span_error
				return result
			if(length(brush_points) == 1 && brush_radius <= 0)
				final_turfs = world_edit_points_to_turfs(start_turf, brush_points)
				degenerate_kind = "point"
			else
				edge_turfs = world_edit_offsets_to_turfs(start_turf, world_edit_collect_polyline_offsets(brush_points, FALSE))
				final_turfs = world_edit_collect_brush_path_turfs(start_turf, brush_points, brush_radius)
				shape_is_filled = brush_radius > 0
			guide_turfs = (brush_radius > 0) ? world_edit_collect_boundary_turfs(final_turfs) : edge_turfs.Copy()
			extra_metadata["custom_point_count"] = length(brush_points)
			extra_metadata["normalized_points"] = world_edit_copy_points(brush_points)
			extra_metadata["brush_radius"] = brush_radius

		if(WORLD_EDIT_SHAPE_SCATTER_CLUSTER)
			var/scatter_radius = world_edit_shape_num_param(current_params, "shape_scatter_radius", 4, 0, WORLD_EDIT_PLACEMENT_MAX_SCATTER_RADIUS)
			var/scatter_count = world_edit_shape_num_param(current_params, "shape_scatter_count", 8, 1, WORLD_EDIT_PLACEMENT_MAX_SCATTER_POINTS)
			var/requested_seed = world_edit_shape_num_param(current_params, "shape_scatter_seed", 0, 0, 999999)
			var/scatter_seed = world_edit_resolve_scatter_seed(start_turf, scatter_radius, scatter_count, requested_seed)
			final_turfs = world_edit_collect_scatter_cluster_turfs(start_turf, scatter_radius, scatter_count, scatter_seed)
			vertex_turfs = final_turfs.Copy()
			guide_turfs = (scatter_radius > 0) ? world_edit_collect_circle_turfs(start_turf, scatter_radius, max(scatter_radius - 1, 0)) : list(start_turf)
			extra_metadata["radius"] = scatter_radius
			extra_metadata["count"] = scatter_count
			extra_metadata["requested_seed"] = requested_seed
			extra_metadata["seed"] = scatter_seed
			if(length(final_turfs) <= 1)
				degenerate_kind = "point"

		else
			result["error"] = "Unsupported placement shape '[shape_id]'."
			return result

	result["is_closed"] = shape_is_closed
	result["is_filled"] = shape_is_filled
	world_edit_set_shape_preview_layers(result, anchor_turfs, vertex_turfs, edge_turfs, closure_turfs, final_turfs, guide_turfs)
	return world_edit_finalize_shape_result(result, final_turfs, degenerate_kind, extra_metadata, start_turf.z)
