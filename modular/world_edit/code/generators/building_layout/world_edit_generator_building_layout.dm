#define WORLD_EDIT_BUILDING_MAX_FOOTPRINT_TURFS 512
#define WORLD_EDIT_BUILDING_MAX_PREVIEW_OBJECT_SPECS 700
#define WORLD_EDIT_BUILDING_MAX_HOVER_PREVIEW_OBJECT_SPECS 120
#define WORLD_EDIT_BUILDING_MAX_INTERIOR_OBJECTS 16
#define WORLD_EDIT_BUILDING_MAX_WINDOWS 12

/datum/world_edit_generator/building_layout
	requires_preview_before_apply = TRUE

/datum/world_edit_generator/building_layout/get_supported_placement_modes()
	return list("single", "repeat")

/datum/world_edit_generator/building_layout/get_supported_placement_shapes()
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

/datum/world_edit_generator/building_layout/supports_placement_direction()
	return TRUE

/datum/world_edit_generator/building_layout/get_default_placement_direction()
	return NORTH

/datum/world_edit_generator/building_layout/proc/get_building_faction_options()
	return list("colony", "uscm", "unsc", "neutral", "covenant")

/datum/world_edit_generator/building_layout/proc/get_building_layout_options()
	return list("living", "workshop", "office", "storage", "checkpoint", "courtyard", "pillar", "monument", "platform")

/datum/world_edit_generator/building_layout/proc/is_open_structure_layout(layout_variant)
	return "[layout_variant]" in list("pillar", "monument", "platform")

/datum/world_edit_generator/building_layout/proc/get_building_faction_catalog()
	return list(
		"colony" = list(
			"label" = "Колония",
			"wall_path" = "/turf/closed/wall/kutjevo/colony",
			"floor_path" = "/turf/open/floor/interior/wood",
			"door_path" = "/obj/structure/machinery/door/airlock/almayer/generic",
			"window_path" = "/obj/structure/window/framed/colony/reinforced",
			"interior_paths" = list(
				"table" = "/obj/structure/surface/table/woodentable",
				"chair" = "/obj/structure/bed/chair/wood/normal",
				"cabinet" = "/obj/structure/closet/cabinet",
				"bed" = "/obj/structure/bed",
				"rack" = "/obj/structure/surface/rack",
			),
		),
		"uscm" = list(
			"label" = "USCM",
			"wall_path" = "/turf/closed/wall/almayer",
			"floor_path" = "/turf/open/floor/plating",
			"door_path" = "/obj/structure/machinery/door/airlock/almayer/marine",
			"window_path" = "/obj/structure/window/framed/almayer",
			"interior_paths" = list(
				"table" = "/obj/structure/surface/table/reinforced",
				"chair" = "/obj/structure/bed/chair/office/dark",
				"cabinet" = "/obj/structure/closet/secure_closet",
				"bed" = "/obj/structure/bed",
				"rack" = "/obj/structure/surface/rack",
			),
		),
		"unsc" = list(
			"label" = "UNSC",
			"wall_path" = "/turf/closed/wall/unsc",
			"floor_path" = "/turf/open/floor/plating",
			"door_path" = "/obj/structure/machinery/door/airlock/unsc",
			"window_path" = "/obj/structure/window/framed/unsc",
			"interior_paths" = list(
				"table" = "/obj/structure/surface/table/reinforced",
				"chair" = "/obj/structure/bed/chair/vehicle",
				"cabinet" = "/obj/structure/closet/secure_closet",
				"bed" = "/obj/structure/bed",
				"rack" = "/obj/structure/gun_rack/halo",
			),
		),
		"neutral" = list(
			"label" = "Нейтральный",
			"wall_path" = "/turf/closed/wall/wood",
			"floor_path" = "/turf/open/floor/wood",
			"door_path" = "/obj/structure/machinery/door/airlock/hybrisa/generic",
			"window_path" = "/obj/structure/window/framed/hybrisa/colony",
			"interior_paths" = list(
				"table" = "/obj/structure/surface/table/woodentable",
				"chair" = "/obj/structure/bed/chair/wood/normal",
				"cabinet" = "/obj/structure/closet/cabinet/hybrisa/metal",
				"bed" = "/obj/structure/bed",
				"rack" = "/obj/structure/surface/rack",
			),
		),
		"covenant" = list(
			"label" = "Covenant",
			"wall_path" = "/turf/closed/wall/covenant/lights/hull",
			"floor_path" = "/turf/open/floor/covenant/smooth_plating",
			"door_path" = "/obj/structure/machinery/door/airlock/voi",
			"window_path" = "/obj/structure/covenant_barricade",
			"interior_paths" = list(
				"table" = "/obj/structure/machinery/recharger/covenant",
				"chair" = "/obj/structure/covenant_barricade",
				"cabinet" = "/obj/structure/covenant_barricade",
				"bed" = "/obj/structure/covenant_barricade",
				"rack" = "/obj/structure/covenant_barricade",
				"tech" = "/obj/structure/machinery/recharger/covenant",
				"barrier" = "/obj/structure/covenant_barricade",
			),
		),
	)

/datum/world_edit_generator/building_layout/proc/resolve_building_option(value, list/options, fallback)
	var/value_text = "[value]"
	if(value_text in options)
		return value_text
	return fallback

/datum/world_edit_generator/building_layout/proc/num_param(list/params, param_id, default_value, min_value, max_value)
	var/value = text2num("[islist(params) ? params[param_id] : null]")
	if(!isnum(value))
		value = default_value
	return clamp(round(value), min_value, max_value)

/datum/world_edit_generator/building_layout/proc/ui_num_param(value, default_value, min_value, max_value)
	var/num_value = text2num("[value]")
	if(!isnum(num_value))
		num_value = default_value
	return clamp(round(num_value), min_value, max_value)

/datum/world_edit_generator/building_layout/proc/resolve_building_type_path(path_text, expected_root)
	var/resolved_path = text2path("[path_text]")
	if(!ispath(resolved_path, expected_root))
		return null
	return resolved_path

/datum/world_edit_generator/building_layout/proc/normalize_building_params(list/params)
	var/list/config = list()
	config["faction_preset"] = resolve_building_option(islist(params) ? params["faction_preset"] : null, get_building_faction_options(), "colony")
	config["layout_variant"] = resolve_building_option(islist(params) ? params["layout_variant"] : null, get_building_layout_options(), "living")
	config["half_width"] = num_param(params, "half_width", 4, 2, 8)
	config["half_depth"] = num_param(params, "half_depth", 4, 2, 8)
	var/default_core_radius = config["layout_variant"] == "monument" ? 1 : 0
	config["core_radius"] = num_param(params, "core_radius", default_core_radius, 0, 3)
	config["window_density"] = num_param(params, "window_density", 40, 0, 100)
	config["interior_density"] = num_param(params, "interior_density", 60, 0, 100)
	config["back_exit"] = GLOB.world_edit_helpers.parse_bool(islist(params) ? params["back_exit"] : null) ? TRUE : FALSE
	config["respect_blockers"] = isnull(islist(params) ? params["respect_blockers"] : null) ? TRUE : GLOB.world_edit_helpers.parse_bool(params["respect_blockers"])
	config["replace_blocked_turfs"] = GLOB.world_edit_helpers.parse_bool(islist(params) ? params["replace_blocked_turfs"] : null) ? TRUE : FALSE

	var/list/catalog = get_building_faction_catalog()
	var/list/preset = catalog[config["faction_preset"]] || catalog["colony"]
	config["preset"] = preset
	config["wall_type"] = resolve_building_type_path(preset["wall_path"], /turf)
	config["floor_type"] = resolve_building_type_path(preset["floor_path"], /turf)
	config["door_type"] = resolve_building_type_path(preset["door_path"], /obj)
	config["window_type"] = resolve_building_type_path(preset["window_path"], /obj)
	config["interior_paths"] = islist(preset["interior_paths"]) ? preset["interior_paths"].Copy() : list()
	if(!config["wall_type"] || !config["floor_type"] || !config["door_type"] || !config["window_type"])
		config["error"] = "Не удалось разрешить один из type path пресета '[config["faction_preset"]]'."
	return config

/datum/world_edit_generator/building_layout/get_ui_fields(list/current_params)
	var/list/config = normalize_building_params(current_params)
	var/current_shape = manager?.get_effective_placement_shape() || WORLD_EDIT_SHAPE_POINT
	return list(
		list(
			"id" = "faction_preset",
			"label" = "Фракционный пресет",
			"kind" = "select",
			"group" = "Основное",
			"value" = config["faction_preset"],
			"options" = list(
				list("label" = "Колония", "value" = "colony"),
				list("label" = "USCM", "value" = "uscm"),
				list("label" = "UNSC", "value" = "unsc"),
				list("label" = "Нейтральный", "value" = "neutral"),
				list("label" = "Covenant", "value" = "covenant"),
			),
		),
		list(
			"id" = "layout_variant",
			"label" = "Компоновка",
			"kind" = "select",
			"group" = "Основное",
			"value" = config["layout_variant"],
			"options" = list(
				list("label" = "Жилая", "value" = "living"),
				list("label" = "Мастерская", "value" = "workshop"),
				list("label" = "Офис", "value" = "office"),
				list("label" = "Склад", "value" = "storage"),
				list("label" = "КПП", "value" = "checkpoint"),
				list("label" = "Двор", "value" = "courtyard"),
				list("label" = "Pillar", "value" = "pillar"),
				list("label" = "Monument", "value" = "monument"),
				list("label" = "Platform", "value" = "platform"),
			),
		),
		list(
			"id" = "half_width",
			"label" = "Радиус ширины",
			"kind" = "number",
			"group" = "Размер",
			"value" = config["half_width"],
			"min" = 2,
			"max" = 8,
			"step" = 1,
			"visible" = current_shape == WORLD_EDIT_SHAPE_POINT,
		),
		list(
			"id" = "half_depth",
			"label" = "Радиус глубины",
			"kind" = "number",
			"group" = "Размер",
			"value" = config["half_depth"],
			"min" = 2,
			"max" = 8,
			"step" = 1,
			"visible" = current_shape == WORLD_EDIT_SHAPE_POINT,
		),
		list(
			"id" = "core_radius",
			"label" = "Core radius",
			"kind" = "number",
			"group" = "Core",
			"value" = config["core_radius"],
			"min" = 0,
			"max" = 3,
			"step" = 1,
			"visible" = is_open_structure_layout(config["layout_variant"]),
		),
		list(
			"id" = "window_density",
			"label" = "Окна",
			"kind" = "number",
			"group" = "Оболочка",
			"value" = config["window_density"],
			"min" = 0,
			"max" = 100,
			"step" = 10,
		),
		list(
			"id" = "interior_density",
			"label" = "Интерьер",
			"kind" = "number",
			"group" = "Интерьер",
			"value" = config["interior_density"],
			"min" = 0,
			"max" = 100,
			"step" = 10,
		),
		list(
			"id" = "back_exit",
			"label" = "Задний выход",
			"kind" = "boolean",
			"group" = "Оболочка",
			"value" = config["back_exit"],
		),
		list(
			"id" = "respect_blockers",
			"label" = "Проверять препятствия",
			"kind" = "boolean",
			"group" = "Безопасность",
			"value" = config["respect_blockers"],
		),
		list(
			"id" = "replace_blocked_turfs",
			"label" = "Заменять занятые клетки",
			"kind" = "boolean",
			"group" = "Безопасность",
			"value" = config["replace_blocked_turfs"],
		),
	)

/datum/world_edit_generator/building_layout/set_ui_param(mob/user, list/current_params, param_id, value)
	if(!islist(current_params))
		current_params = list()
	var/list/new_params = current_params.Copy()
	switch("[param_id]")
		if("faction_preset")
			new_params[param_id] = resolve_building_option(value, get_building_faction_options(), "colony")
		if("layout_variant")
			new_params[param_id] = resolve_building_option(value, get_building_layout_options(), "living")
		if("half_width")
			new_params[param_id] = ui_num_param(value, 4, 2, 8)
		if("half_depth")
			new_params[param_id] = ui_num_param(value, 4, 2, 8)
		if("core_radius")
			new_params[param_id] = ui_num_param(value, 0, 0, 3)
		if("window_density")
			new_params[param_id] = ui_num_param(value, 40, 0, 100)
		if("interior_density")
			new_params[param_id] = ui_num_param(value, 60, 0, 100)
		if("back_exit", "respect_blockers", "replace_blocked_turfs")
			new_params[param_id] = GLOB.world_edit_helpers.parse_bool(value) ? TRUE : FALSE
		else
			new_params[param_id] = value
	return new_params

/datum/world_edit_generator/building_layout/get_params_short(list/params)
	var/list/config = normalize_building_params(params)
	return "faction=[config["faction_preset"]] layout=[config["layout_variant"]] width=[config["half_width"]] depth=[config["half_depth"]] core=[config["core_radius"]] windows=[config["window_density"]] interior=[config["interior_density"]] back=[config["back_exit"]] strict_blockers=[config["respect_blockers"]] replace_blocked=[config["replace_blocked_turfs"]] shape=[manager?.get_effective_placement_shape() || WORLD_EDIT_SHAPE_POINT] dir=[GLOB.world_edit_helpers.dir_to_label(manager?.get_effective_placement_dir() || NORTH)]"

/datum/world_edit_generator/building_layout/proc/get_building_shape_error(shape_id, list/config)
	switch("[shape_id]")
		if(WORLD_EDIT_SHAPE_SCATTER_CLUSTER)
			return "Для построек используйте кистевой путь или пользовательскую маску вместо этой формы."
		if(WORLD_EDIT_SHAPE_RING)
			if(config["layout_variant"] != "courtyard")
				return "Кольцо доступно только для компоновки 'Двор'."
			return null
		if(
			WORLD_EDIT_SHAPE_POINT,
			WORLD_EDIT_SHAPE_LINE,
			WORLD_EDIT_SHAPE_RECTANGLE,
			WORLD_EDIT_SHAPE_FILLED_RECTANGLE,
			WORLD_EDIT_SHAPE_CIRCLE,
			WORLD_EDIT_SHAPE_ELLIPSE,
			WORLD_EDIT_SHAPE_DIAMOND,
			WORLD_EDIT_SHAPE_TRIANGLE,
			WORLD_EDIT_SHAPE_SECTOR,
			WORLD_EDIT_SHAPE_POLYGON,
			WORLD_EDIT_SHAPE_POLYLINE,
			WORLD_EDIT_SHAPE_CUSTOM_MASK,
			WORLD_EDIT_SHAPE_BRUSH_PATH
		)
			return null
	return "Форма '[shape_id]' не поддерживается генератором построек."

/datum/world_edit_generator/building_layout/validate_params(mob/user, list/params)
	var/list/config = normalize_building_params(params)
	if(config["error"])
		return "[config["error"]]"
	var/shape_id = manager?.get_effective_placement_shape() || WORLD_EDIT_SHAPE_POINT
	var/shape_error = get_building_shape_error(shape_id, config)
	if(length("[shape_error]"))
		return shape_error
	return null

/datum/world_edit_generator/building_layout/get_shape_support_error(shape_id, list/anchor_turfs, list/params, list/placement_context)
	var/list/config = normalize_building_params(params)
	if(config["error"])
		return "[config["error"]]"
	return get_building_shape_error(shape_id, config)

/datum/world_edit_generator/building_layout/proc/turf_coord_key(turf/target_turf)
	if(!istype(target_turf))
		return ""
	return "[target_turf.x],[target_turf.y],[target_turf.z]"

/datum/world_edit_generator/building_layout/proc/fill_turf_bounds(list/raw_turfs)
	var/list/result = list()
	var/list/result_lookup = list()
	if(!islist(raw_turfs) || !length(raw_turfs))
		return result

	var/min_x = null
	var/max_x = null
	var/min_y = null
	var/max_y = null
	var/z_level = null
	for(var/turf/source_turf as anything in raw_turfs)
		if(!istype(source_turf))
			continue
		if(isnull(z_level))
			z_level = source_turf.z
		if(source_turf.z != z_level)
			continue
		if(isnull(min_x) || source_turf.x < min_x)
			min_x = source_turf.x
		if(isnull(max_x) || source_turf.x > max_x)
			max_x = source_turf.x
		if(isnull(min_y) || source_turf.y < min_y)
			min_y = source_turf.y
		if(isnull(max_y) || source_turf.y > max_y)
			max_y = source_turf.y

	if(isnull(min_x) || isnull(min_y) || isnull(z_level))
		return result

	for(var/y in min_y to max_y)
		for(var/x in min_x to max_x)
			var/turf/target_turf = locate(x, y, z_level)
			GLOB.world_edit_placement_shapes.world_edit_add_turf_unique(result, result_lookup, target_turf, z_level)
	return result

/datum/world_edit_generator/building_layout/proc/inflate_turf_footprint(list/raw_turfs, radius = 1)
	var/list/result = list()
	var/list/result_lookup = list()
	if(!islist(raw_turfs) || !length(raw_turfs))
		return result
	radius = max(round(radius), 0)
	var/z_level = null
	for(var/turf/source_turf as anything in raw_turfs)
		if(!istype(source_turf))
			continue
		if(isnull(z_level))
			z_level = source_turf.z
		if(source_turf.z != z_level)
			continue
		for(var/dx in -radius to radius)
			for(var/dy in -radius to radius)
				var/turf/target_turf = locate(source_turf.x + dx, source_turf.y + dy, source_turf.z)
				GLOB.world_edit_placement_shapes.world_edit_add_turf_unique(result, result_lookup, target_turf, z_level)
	return result

/datum/world_edit_generator/building_layout/proc/resolve_shape_footprint(datum/world_edit_shape_contract/shape_contract, list/config, list/params, list/placement_context)
	var/list/result = list("footprint" = list())
	var/shape_id = "[shape_contract?.shape_id || placement_context["shape"] || WORLD_EDIT_SHAPE_POINT]"
	var/shape_error = get_building_shape_error(shape_id, config)
	if(length("[shape_error]"))
		result["error"] = shape_error
		return result

	var/list/raw_turfs = shape_contract?.copy_anchor_turfs() || placement_context["anchor_turfs"]
	var/turf/seed_turf = get_shape_placement_seed_turf(shape_contract, placement_context)
	if(shape_id == WORLD_EDIT_SHAPE_POINT)
		if(!istype(seed_turf))
			result["error"] = "Не удалось определить центр постройки."
			return result
		var/width = (config["half_width"] * 2) + 1
		var/height = (config["half_depth"] * 2) + 1
		result["footprint"] = GLOB.world_edit_placement_shapes.world_edit_collect_centered_rectangle_turfs(seed_turf, width, height, TRUE)
		return result

	if(!islist(raw_turfs) || !length(raw_turfs))
		result["error"] = "Форма не дала тайлов для постройки."
		return result

	switch(shape_id)
		if(WORLD_EDIT_SHAPE_LINE, WORLD_EDIT_SHAPE_POLYLINE)
			var/list/metadata = shape_contract?.metadata
			var/list/preview_layers = islist(metadata) ? metadata["preview_layers"] : null
			var/list/line_turfs = islist(preview_layers) && length(preview_layers["edge_turfs"]) ? preview_layers["edge_turfs"] : raw_turfs
			result["footprint"] = inflate_turf_footprint(line_turfs, 1)
		if(WORLD_EDIT_SHAPE_RECTANGLE, WORLD_EDIT_SHAPE_FILLED_RECTANGLE)
			result["footprint"] = fill_turf_bounds(raw_turfs)
		if(WORLD_EDIT_SHAPE_POLYGON)
			var/list/metadata = shape_contract?.metadata
			var/list/points = islist(metadata) ? metadata["normalized_points"] : null
			if(istype(seed_turf) && islist(points) && length(points) >= 3)
				result["footprint"] = GLOB.world_edit_placement_shapes.world_edit_collect_polygon_turfs(seed_turf, points, TRUE)
			else
				result["footprint"] = fill_turf_bounds(raw_turfs)
		else
			result["footprint"] = GLOB.world_edit_placement_shapes.world_edit_unique_turf_list(raw_turfs)
	return result

/datum/world_edit_generator/building_layout/proc/validate_footprint(list/footprint, list/config)
	var/list/result = list()
	footprint = GLOB.world_edit_placement_shapes.world_edit_unique_turf_list(footprint)
	result["footprint"] = footprint
	if(!length(footprint))
		result["error"] = "Постройка не получила footprint."
		return result
	if(length(footprint) > WORLD_EDIT_BUILDING_MAX_FOOTPRINT_TURFS)
		result["error"] = "Footprint постройки превышает лимит ([WORLD_EDIT_BUILDING_MAX_FOOTPRINT_TURFS])."
		return result

	var/z_level = null
	var/min_x = null
	var/max_x = null
	var/min_y = null
	var/max_y = null
	for(var/turf/target_turf as anything in footprint)
		if(!istype(target_turf))
			result["error"] = "Footprint содержит некорректный тайл."
			return result
		if(isnull(z_level))
			z_level = target_turf.z
		if(target_turf.z != z_level)
			result["error"] = "Footprint постройки должен быть на одном z-level."
			return result
		if(isnull(min_x) || target_turf.x < min_x)
			min_x = target_turf.x
		if(isnull(max_x) || target_turf.x > max_x)
			max_x = target_turf.x
		if(isnull(min_y) || target_turf.y < min_y)
			min_y = target_turf.y
		if(isnull(max_y) || target_turf.y > max_y)
			max_y = target_turf.y

	var/width = max_x - min_x + 1
	var/height = max_y - min_y + 1
	if(width < 3 || height < 3)
		result["error"] = "Постройка требует минимум 3x3 полезной области."
		return result

	var/list/footprint_lookup = GLOB.world_edit_placement_shapes.world_edit_build_turf_lookup(footprint)
	var/list/visited_lookup = list()
	var/list/queue = list(footprint[1])
	visited_lookup[footprint[1]] = TRUE
	var/index = 1
	while(index <= length(queue))
		var/turf/current_turf = queue[index++]
		for(var/check_dir in GLOB.cardinals)
			var/turf/nearby_turf = get_step(current_turf, check_dir)
			if(!footprint_lookup[nearby_turf] || visited_lookup[nearby_turf])
				continue
			visited_lookup[nearby_turf] = TRUE
			queue += nearby_turf
	if(length(queue) != length(footprint))
		result["error"] = "Footprint постройки должен быть связным; для разрозненных точек используйте отдельные применения."
		return result

	if(config["respect_blockers"])
		for(var/turf/check_turf as anything in footprint)
			var/blocker_error = get_footprint_blocker_error(check_turf)
			if(length("[blocker_error]"))
				result["error"] = blocker_error
				return result

	var/list/boundary = GLOB.world_edit_placement_shapes.world_edit_collect_boundary_turfs(footprint)
	if(length(boundary) < 3)
		result["error"] = "Не удалось найти внешнюю границу постройки."
		return result

	var/list/boundary_lookup = GLOB.world_edit_placement_shapes.world_edit_build_turf_lookup(boundary)
	var/list/interior = list()
	for(var/turf/interior_turf as anything in footprint)
		if(boundary_lookup[interior_turf])
			continue
		interior += interior_turf

	result["bounds"] = list("min_x" = min_x, "max_x" = max_x, "min_y" = min_y, "max_y" = max_y, "width" = width, "height" = height, "z" = z_level)
	result["boundary"] = boundary
	result["interior"] = interior
	result["footprint_lookup"] = footprint_lookup
	return result

/datum/world_edit_generator/building_layout/proc/get_footprint_blocker_error(turf/target_turf)
	if(!istype(target_turf))
		return "Footprint содержит некорректный тайл."
	if(target_turf.density)
		return "Footprint пересекает плотный turf [GLOB.world_edit_helpers.turf_to_text(target_turf)]."
	for(var/atom/movable/blocker as anything in target_turf)
		if(ismob(blocker))
			continue
		if(blocker.density)
			return "Footprint пересекает плотный объект на [GLOB.world_edit_helpers.turf_to_text(target_turf)]."
	return null

/datum/world_edit_generator/building_layout/proc/get_dir_component_x(direction)
	switch(direction)
		if(EAST)
			return 1
		if(WEST)
			return -1
	return 0

/datum/world_edit_generator/building_layout/proc/get_dir_component_y(direction)
	switch(direction)
		if(NORTH)
			return 1
		if(SOUTH)
			return -1
	return 0

/datum/world_edit_generator/building_layout/proc/get_projection_for_dir(turf/target_turf, center_x, center_y, direction)
	if(!istype(target_turf))
		return -999999
	return ((target_turf.x - center_x) * get_dir_component_x(direction)) + ((target_turf.y - center_y) * get_dir_component_y(direction))

/datum/world_edit_generator/building_layout/proc/get_lateral_distance_for_dir(turf/target_turf, center_x, center_y, direction)
	if(direction in list(NORTH, SOUTH))
		return abs(target_turf.x - center_x)
	return abs(target_turf.y - center_y)

/datum/world_edit_generator/building_layout/proc/get_side_axis_positive_dir(direction)
	if(direction in list(NORTH, SOUTH))
		return EAST
	return NORTH

/datum/world_edit_generator/building_layout/proc/get_side_axis_negative_dir(direction)
	if(direction in list(NORTH, SOUTH))
		return WEST
	return SOUTH

/datum/world_edit_generator/building_layout/proc/boundary_turf_has_outside_dir(turf/target_turf, list/footprint_lookup, direction)
	if(!istype(target_turf) || !islist(footprint_lookup))
		return FALSE
	var/turf/nearby_turf = get_step(target_turf, direction)
	return !footprint_lookup[nearby_turf]

/datum/world_edit_generator/building_layout/proc/get_side_run_length(turf/target_turf, list/side_lookup, direction)
	if(!istype(target_turf) || !islist(side_lookup) || !side_lookup[target_turf])
		return 0
	var/run_length = 1
	var/positive_dir = get_side_axis_positive_dir(direction)
	var/negative_dir = get_side_axis_negative_dir(direction)
	var/turf/check_turf = get_step(target_turf, positive_dir)
	while(side_lookup[check_turf])
		run_length++
		check_turf = get_step(check_turf, positive_dir)
	check_turf = get_step(target_turf, negative_dir)
	while(side_lookup[check_turf])
		run_length++
		check_turf = get_step(check_turf, negative_dir)
	return run_length

/datum/world_edit_generator/building_layout/proc/select_boundary_turf_for_dir(list/boundary, center_x, center_y, direction, list/excluded_lookup = null, list/footprint_lookup = null)
	var/list/side_lookup = list()
	if(islist(footprint_lookup))
		for(var/turf/boundary_turf as anything in boundary)
			if(!istype(boundary_turf) || (islist(excluded_lookup) && excluded_lookup[boundary_turf]))
				continue
			if(boundary_turf_has_outside_dir(boundary_turf, footprint_lookup, direction))
				side_lookup[boundary_turf] = TRUE

	var/turf/best_turf = null
	var/best_score = -999999999
	for(var/turf/boundary_turf as anything in boundary)
		if(!istype(boundary_turf) || (islist(excluded_lookup) && excluded_lookup[boundary_turf]))
			continue
		var/projection = get_projection_for_dir(boundary_turf, center_x, center_y, direction)
		var/lateral = get_lateral_distance_for_dir(boundary_turf, center_x, center_y, direction)
		var/exact_side = side_lookup[boundary_turf]
		var/run_length = exact_side ? get_side_run_length(boundary_turf, side_lookup, direction) : 0
		var/score = (projection * 100) - (lateral * 10)
		if(exact_side)
			score += 100000
		if(run_length >= 3)
			score += 30000 + (min(run_length, 8) * 1000)
		else if(run_length)
			score += run_length * 500
		if(islist(footprint_lookup) && is_corner_boundary_turf(boundary_turf, footprint_lookup))
			score -= 20000
		if(!istype(best_turf) || score > best_score)
			best_turf = boundary_turf
			best_score = score
	return best_turf

/datum/world_edit_generator/building_layout/proc/get_outward_dir(turf/target_turf, list/footprint_lookup, center_x, center_y, preferred_dir = NORTH)
	if(!istype(target_turf))
		return preferred_dir
	var/list/outside_dirs = list()
	for(var/check_dir in GLOB.cardinals)
		var/turf/nearby_turf = get_step(target_turf, check_dir)
		if(footprint_lookup[nearby_turf])
			continue
		outside_dirs += check_dir
	if(!length(outside_dirs))
		return preferred_dir
	if(preferred_dir in outside_dirs)
		return preferred_dir

	var/best_dir = outside_dirs[1]
	var/best_score = -999999
	for(var/outside_dir in outside_dirs)
		var/score = (get_dir_component_x(outside_dir) * (target_turf.x - center_x)) + (get_dir_component_y(outside_dir) * (target_turf.y - center_y))
		if(score > best_score)
			best_score = score
			best_dir = outside_dir
	return best_dir

/datum/world_edit_generator/building_layout/proc/is_corner_boundary_turf(turf/target_turf, list/footprint_lookup)
	var/outside_count = 0
	for(var/check_dir in GLOB.cardinals)
		var/turf/nearby_turf = get_step(target_turf, check_dir)
		if(!footprint_lookup[nearby_turf])
			outside_count++
	return outside_count >= 2

/datum/world_edit_generator/building_layout/proc/is_within_distance_of_any_turf(turf/target_turf, list/other_turfs, max_distance = 1)
	if(!istype(target_turf) || !islist(other_turfs))
		return FALSE
	for(var/turf/other_turf as anything in other_turfs)
		if(!istype(other_turf))
			continue
		if(abs(target_turf.x - other_turf.x) + abs(target_turf.y - other_turf.y) <= max_distance)
			return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/is_near_any_turf(turf/target_turf, list/other_turfs)
	return is_within_distance_of_any_turf(target_turf, other_turfs, 1)

/datum/world_edit_generator/building_layout/proc/count_side_turf_candidates(list/candidates_by_key, list/side_dirs)
	var/total = 0
	if(!islist(candidates_by_key))
		return total
	for(var/side_dir in side_dirs)
		var/list/side_candidates = candidates_by_key["[side_dir]"]
		total += length(side_candidates)
	return total

/datum/world_edit_generator/building_layout/proc/append_unique_turf(list/target_list, list/target_lookup, turf/target_turf)
	if(!istype(target_turf) || target_lookup[target_turf])
		return FALSE
	target_list += target_turf
	target_lookup[target_turf] = TRUE
	return TRUE

/datum/world_edit_generator/building_layout/proc/select_window_seed_candidate(list/side_candidates, list/side_lookup, direction, center_x, center_y, list/used_lookup, list/existing_windows)
	var/turf/best_turf = null
	var/best_score = -999999999
	for(var/turf/window_candidate as anything in side_candidates)
		if(!istype(window_candidate) || used_lookup[window_candidate])
			continue
		if(is_within_distance_of_any_turf(window_candidate, existing_windows, 2))
			continue
		var/run_length = get_side_run_length(window_candidate, side_lookup, direction)
		var/lateral = get_lateral_distance_for_dir(window_candidate, center_x, center_y, direction)
		var/score = (run_length * 1000) - (lateral * 25)
		if(!istype(best_turf) || score > best_score)
			best_turf = window_candidate
			best_score = score
	if(istype(best_turf))
		return best_turf

	for(var/turf/window_candidate as anything in side_candidates)
		if(!istype(window_candidate) || used_lookup[window_candidate])
			continue
		var/run_length = get_side_run_length(window_candidate, side_lookup, direction)
		var/lateral = get_lateral_distance_for_dir(window_candidate, center_x, center_y, direction)
		var/score = (run_length * 1000) - (lateral * 25)
		if(!istype(best_turf) || score > best_score)
			best_turf = window_candidate
			best_score = score
	return best_turf

/datum/world_edit_generator/building_layout/proc/append_window_group_for_side(list/windows, list/side_candidates, direction, center_x, center_y, target_count, list/used_lookup)
	if(target_count <= 0 || !length(side_candidates))
		return 0
	var/list/side_lookup = GLOB.world_edit_placement_shapes.world_edit_build_turf_lookup(side_candidates)
	var/added_count = 0
	while(added_count < target_count)
		var/turf/seed_turf = select_window_seed_candidate(side_candidates, side_lookup, direction, center_x, center_y, used_lookup, windows)
		if(!istype(seed_turf))
			break
		var/group_limit = min(target_count - added_count, 2)
		var/group_added = 0
		if(append_unique_turf(windows, used_lookup, seed_turf))
			added_count++
			group_added++
		var/list/axis_dirs = list(get_side_axis_positive_dir(direction), get_side_axis_negative_dir(direction))
		for(var/axis_dir in axis_dirs)
			if(group_added >= group_limit)
				break
			var/turf/nearby_turf = get_step(seed_turf, axis_dir)
			if(!side_lookup[nearby_turf] || used_lookup[nearby_turf])
				continue
			if(append_unique_turf(windows, used_lookup, nearby_turf))
				added_count++
				group_added++
		if(!group_added)
			break
	return added_count

/datum/world_edit_generator/building_layout/proc/select_window_turfs(list/boundary, list/door_turfs, list/footprint_lookup, center_x, center_y, window_density)
	window_density = clamp(round(window_density), 0, 100)
	if(window_density <= 0)
		return list()

	var/list/side_dirs = list(NORTH, EAST, SOUTH, WEST)
	var/list/side_candidates_by_key = list()
	var/list/fallback_candidates_by_key = list()
	for(var/side_dir in side_dirs)
		side_candidates_by_key["[side_dir]"] = list()
		fallback_candidates_by_key["[side_dir]"] = list()
	var/list/door_lookup = GLOB.world_edit_placement_shapes.world_edit_build_turf_lookup(door_turfs)
	for(var/turf/boundary_turf as anything in boundary)
		if(!istype(boundary_turf) || door_lookup[boundary_turf] || is_within_distance_of_any_turf(boundary_turf, door_turfs, 2))
			continue
		var/side_dir = get_outward_dir(boundary_turf, footprint_lookup, center_x, center_y, NORTH)
		if(!(side_dir in side_dirs))
			continue
		if(is_corner_boundary_turf(boundary_turf, footprint_lookup))
			var/list/fallback_side_candidates = fallback_candidates_by_key["[side_dir]"]
			fallback_side_candidates += boundary_turf
			continue
		var/list/side_candidates = side_candidates_by_key["[side_dir]"]
		side_candidates += boundary_turf

	var/total_candidates = count_side_turf_candidates(side_candidates_by_key, side_dirs)
	var/list/active_candidates_by_key = side_candidates_by_key
	if(!total_candidates)
		active_candidates_by_key = fallback_candidates_by_key
		total_candidates = count_side_turf_candidates(active_candidates_by_key, side_dirs)
	if(!total_candidates)
		return list()

	var/desired_count = max(round(total_candidates * window_density / 300), 1)
	desired_count = min(desired_count, total_candidates, WORLD_EDIT_BUILDING_MAX_WINDOWS)
	var/list/windows = list()
	var/list/used_lookup = list()
	var/remaining_count = desired_count
	for(var/side_dir in side_dirs)
		if(remaining_count <= 0)
			break
		var/list/side_candidates = active_candidates_by_key["[side_dir]"]
		if(!length(side_candidates))
			continue
		var/target_count = round(desired_count * length(side_candidates) / total_candidates)
		if(target_count <= 0 && remaining_count > 0 && length(side_candidates) >= 2)
			target_count = 1
		target_count = min(target_count, remaining_count, length(side_candidates))
		remaining_count -= append_window_group_for_side(windows, side_candidates, side_dir, center_x, center_y, target_count, used_lookup)

	while(remaining_count > 0)
		var/added_this_pass = 0
		for(var/side_dir in side_dirs)
			if(remaining_count <= 0)
				break
			var/list/side_candidates = active_candidates_by_key["[side_dir]"]
			if(!length(side_candidates))
				continue
			var/added = append_window_group_for_side(windows, side_candidates, side_dir, center_x, center_y, 1, used_lookup)
			added_this_pass += added
			remaining_count -= added
		if(!added_this_pass)
			break
	return windows

/datum/world_edit_generator/building_layout/proc/build_turf_placement(kind, turf/target_turf, turf_path)
	return list(
		"kind" = kind,
		"turf" = target_turf,
		"x" = target_turf.x,
		"y" = target_turf.y,
		"z" = target_turf.z,
		"turf_path" = turf_path,
	)

/datum/world_edit_generator/building_layout/proc/build_object_placement(kind, turf/target_turf, obj_path, dir_to_use)
	return list(
		"kind" = kind,
		"turf" = target_turf,
		"x" = target_turf.x,
		"y" = target_turf.y,
		"z" = target_turf.z,
		"obj_path" = obj_path,
		"dir" = dir_to_use,
	)

/datum/world_edit_generator/building_layout/proc/get_cardinal_dir_toward(turf/source_turf, turf/target_turf, fallback_dir = SOUTH)
	if(!istype(source_turf) || !istype(target_turf))
		return fallback_dir
	var/dx = target_turf.x - source_turf.x
	var/dy = target_turf.y - source_turf.y
	if(abs(dx) >= abs(dy) && dx)
		return dx > 0 ? EAST : WEST
	if(dy)
		return dy > 0 ? NORTH : SOUTH
	return fallback_dir

/datum/world_edit_generator/building_layout/proc/select_center_floor_turf(list/floor_turfs, center_x, center_y)
	var/turf/best_turf = null
	var/best_distance = 999999
	for(var/turf/floor_turf as anything in floor_turfs)
		if(!istype(floor_turf))
			continue
		var/distance = abs(floor_turf.x - center_x) + abs(floor_turf.y - center_y)
		if(!istype(best_turf) || distance < best_distance)
			best_turf = floor_turf
			best_distance = distance
	return best_turf

/datum/world_edit_generator/building_layout/proc/build_reserved_path(turf/start_turf, turf/end_turf, list/floor_lookup)
	var/list/reserved = list()
	if(!istype(start_turf) || !istype(end_turf) || !islist(floor_lookup))
		return reserved

	var/list/queue = list(start_turf)
	var/list/visited = list()
	var/list/previous = list()
	visited[start_turf] = TRUE
	var/index = 1
	while(index <= length(queue))
		var/turf/current_turf = queue[index++]
		if(current_turf == end_turf)
			break
		for(var/check_dir in GLOB.cardinals)
			var/turf/nearby_turf = get_step(current_turf, check_dir)
			if(!floor_lookup[nearby_turf] || visited[nearby_turf])
				continue
			visited[nearby_turf] = TRUE
			previous[nearby_turf] = current_turf
			queue += nearby_turf

	if(!visited[end_turf])
		return list(start_turf, end_turf)

	var/turf/path_turf = end_turf
	while(istype(path_turf))
		reserved.Insert(1, path_turf)
		if(path_turf == start_turf)
			break
		path_turf = previous[path_turf]
	return reserved

/datum/world_edit_generator/building_layout/proc/build_reserved_paths(list/door_turfs, turf/center_turf, list/floor_lookup)
	var/list/reserved = list()
	var/list/reserved_lookup = list()
	if(!islist(door_turfs) || !istype(center_turf) || !islist(floor_lookup))
		return reserved
	for(var/turf/door_turf as anything in door_turfs)
		if(!istype(door_turf))
			continue
		var/list/door_path = build_reserved_path(door_turf, center_turf, floor_lookup)
		for(var/turf/path_turf as anything in door_path)
			append_unique_turf(reserved, reserved_lookup, path_turf)
		for(var/check_dir in GLOB.cardinals)
			var/turf/nearby_turf = get_step(door_turf, check_dir)
			if(floor_lookup[nearby_turf])
				append_unique_turf(reserved, reserved_lookup, nearby_turf)
	return reserved

/datum/world_edit_generator/building_layout/proc/get_interior_slots(layout_variant, faction_preset = null)
	if("[faction_preset]" == "covenant")
		switch("[layout_variant]")
			if("storage")
				return list("barrier", "barrier", "tech", "barrier", "barrier", "tech", "barrier", "barrier", "tech", "barrier")
			if("workshop", "checkpoint")
				return list("tech", "barrier", "barrier", "tech", "barrier", "barrier", "tech", "barrier")
			if("courtyard")
				return list("barrier", "tech", "barrier", "barrier", "tech")
			if("pillar", "monument", "platform")
				return list("barrier", "tech", "barrier")
		return list("tech", "barrier", "barrier", "tech", "barrier", "barrier", "tech", "barrier")
	switch("[layout_variant]")
		if("living")
			return list("bed", "cabinet", "bed", "cabinet", "table", "chair", "chair", "rack", "bed", "cabinet", "table", "chair")
		if("workshop")
			return list("rack", "rack", "cabinet", "table", "chair", "rack", "table", "chair", "cabinet", "rack", "table", "chair")
		if("office")
			return list("table", "chair", "cabinet", "table", "chair", "chair", "cabinet", "table", "chair", "rack")
		if("storage")
			return list("rack", "cabinet", "rack", "cabinet", "rack", "rack", "cabinet", "rack", "table", "chair", "rack", "cabinet", "rack", "rack")
		if("checkpoint")
			return list("table", "chair", "rack", "cabinet", "table", "chair", "rack", "cabinet")
		if("courtyard")
			return list("cabinet", "rack", "table", "chair", "cabinet", "rack")
		if("pillar")
			return list("cabinet", "rack")
		if("monument")
			return list("cabinet", "rack", "table")
		if("platform")
			return list("table", "chair", "cabinet")
	return list("table", "chair", "cabinet")

/datum/world_edit_generator/building_layout/proc/get_interior_motif_cap(layout_variant, faction_preset = null)
	if("[faction_preset]" == "covenant")
		switch("[layout_variant]")
			if("storage", "workshop")
				return 10
			if("checkpoint")
				return 8
			if("courtyard")
				return 5
			if("pillar", "platform")
				return 4
			if("monument")
				return 5
		return 8
	switch("[layout_variant]")
		if("living")
			return 12
		if("workshop")
			return 12
		if("office")
			return 10
		if("storage")
			return 14
		if("checkpoint")
			return 8
		if("courtyard")
			return 6
		if("pillar", "platform")
			return 4
		if("monument")
			return 5
	return 8

/datum/world_edit_generator/building_layout/proc/resolve_interior_obj_path(list/config, slot)
	var/list/interior_paths = config["interior_paths"]
	var/path_text = islist(interior_paths) ? (interior_paths[slot] || interior_paths["table"]) : null
	var/obj_path = resolve_building_type_path(path_text, /obj)
	if(!obj_path && slot != "table")
		obj_path = resolve_building_type_path(islist(interior_paths) ? interior_paths["table"] : null, /obj)
	return obj_path

/datum/world_edit_generator/building_layout/proc/get_wall_adjacency_count(turf/target_turf, list/wall_lookup)
	if(!istype(target_turf) || !islist(wall_lookup))
		return 0
	var/wall_count = 0
	for(var/check_dir in GLOB.cardinals)
		if(wall_lookup[get_step(target_turf, check_dir)])
			wall_count++
	return wall_count

/datum/world_edit_generator/building_layout/proc/select_interior_candidate(list/candidates, slot, turf/center_turf, list/wall_lookup, list/object_lookup, list/reserved_lookup, prefer_wall = FALSE, prefer_open = FALSE)
	var/turf/best_turf = null
	var/best_score = -999999999
	for(var/turf/interior_candidate as anything in candidates)
		if(!istype(interior_candidate) || object_lookup[interior_candidate] || reserved_lookup[interior_candidate])
			continue
		var/wall_count = get_wall_adjacency_count(interior_candidate, wall_lookup)
		var/center_distance = istype(center_turf) ? (abs(interior_candidate.x - center_turf.x) + abs(interior_candidate.y - center_turf.y)) : 0
		var/score = -center_distance
		if(prefer_wall)
			score += wall_count * 120
			if(wall_count >= 2)
				score += 80
		else if(prefer_open)
			score += (4 - wall_count) * 90
			score -= center_distance * 8
		else
			score += wall_count * 35
			score -= center_distance * 3
		if(slot in list("bed", "cabinet", "rack", "barrier", "tech"))
			score += wall_count * 55
		if(slot == "table" && prefer_open)
			score -= wall_count * 20
		if(!istype(best_turf) || score > best_score)
			best_turf = interior_candidate
			best_score = score
	return best_turf

/datum/world_edit_generator/building_layout/proc/find_adjacent_interior_candidate(turf/source_turf, list/candidate_lookup, list/object_lookup, list/reserved_lookup, turf/center_turf, list/wall_lookup)
	if(!istype(source_turf) || !islist(candidate_lookup))
		return null
	var/turf/best_turf = null
	var/best_score = -999999999
	for(var/check_dir in GLOB.cardinals)
		var/turf/nearby_turf = get_step(source_turf, check_dir)
		if(!candidate_lookup[nearby_turf] || object_lookup[nearby_turf] || reserved_lookup[nearby_turf])
			continue
		var/wall_count = get_wall_adjacency_count(nearby_turf, wall_lookup)
		var/center_distance = istype(center_turf) ? (abs(nearby_turf.x - center_turf.x) + abs(nearby_turf.y - center_turf.y)) : 0
		var/score = ((4 - wall_count) * 80) - (center_distance * 4)
		if(!istype(best_turf) || score > best_score)
			best_turf = nearby_turf
			best_score = score
	return best_turf

/datum/world_edit_generator/building_layout/proc/append_interior_placements(datum/world_edit_plan/plan, list/interior_turfs, list/wall_lookup, list/reserved_turfs, turf/center_turf, list/config, list/object_lookup)
	if(!istype(plan) || !length(interior_turfs) || config["interior_density"] <= 0)
		return 0

	var/list/reserved_lookup = GLOB.world_edit_placement_shapes.world_edit_build_turf_lookup(reserved_turfs)
	var/list/near_wall = list()
	var/list/open_floor = list()
	var/list/candidates = list()
	for(var/turf/interior_turf as anything in interior_turfs)
		if(!istype(interior_turf) || reserved_lookup[interior_turf] || object_lookup[interior_turf])
			continue
		candidates += interior_turf
		if(get_wall_adjacency_count(interior_turf, wall_lookup))
			near_wall += interior_turf
		else
			open_floor += interior_turf

	if(!length(candidates))
		return 0
	var/list/candidate_lookup = GLOB.world_edit_placement_shapes.world_edit_build_turf_lookup(candidates)
	var/layout_variant = "[config["layout_variant"]]"
	var/layout_cap = get_interior_motif_cap(layout_variant, config["faction_preset"])
	var/desired_count = round(layout_cap * config["interior_density"] / 100)
	if(config["interior_density"] > 0)
		desired_count = max(desired_count, 1)
	desired_count = min(desired_count, length(candidates), layout_cap, WORLD_EDIT_BUILDING_MAX_INTERIOR_OBJECTS)
	var/list/slots = get_interior_slots(config["layout_variant"], config["faction_preset"])
	var/created_plan_count = 0
	var/slot_index = 1
	var/turf/last_table_turf = null
	var/attempts = 0
	var/max_attempts = max(length(candidates) * 3, desired_count * max(length(slots), 1) * 3)
	while(created_plan_count < desired_count && attempts < max_attempts)
		attempts++
		var/slot = slots[slot_index]
		var/obj_path = resolve_interior_obj_path(config, slot)
		if(obj_path)
			var/turf/target_turf = null
			if(slot == "chair" && istype(last_table_turf))
				target_turf = find_adjacent_interior_candidate(last_table_turf, candidate_lookup, object_lookup, reserved_lookup, center_turf, wall_lookup)
			if(!istype(target_turf))
				var/prefer_wall = (slot in list("bed", "cabinet", "rack", "barrier", "tech")) || layout_variant == "courtyard" || (layout_variant == "storage" && slot != "chair")
				var/prefer_open = (slot == "table" && !(layout_variant in list("storage", "workshop", "courtyard")))
				var/list/selection_pool = prefer_wall ? (near_wall + open_floor) : (open_floor + near_wall)
				target_turf = select_interior_candidate(selection_pool, slot, center_turf, wall_lookup, object_lookup, reserved_lookup, prefer_wall, prefer_open)
			if(istype(target_turf))
				var/dir_to_use = (slot == "chair" && istype(last_table_turf)) ? get_cardinal_dir_toward(target_turf, last_table_turf, SOUTH) : get_cardinal_dir_toward(target_turf, center_turf, SOUTH)
				plan.placements += list(build_object_placement("interior", target_turf, obj_path, dir_to_use))
				object_lookup[target_turf] = TRUE
				if(slot == "table")
					last_table_turf = target_turf
				created_plan_count++
		slot_index++
		if(slot_index > length(slots))
			slot_index = 1
	return created_plan_count

/datum/world_edit_generator/building_layout/proc/collect_open_structure_core_turfs(list/footprint, turf/center_turf, list/config)
	var/list/core_turfs = list()
	var/list/core_lookup = list()
	if(!is_open_structure_layout(config["layout_variant"]) || config["layout_variant"] == "platform" || !istype(center_turf))
		return core_turfs
	var/core_radius = round(config["core_radius"])
	if(config["layout_variant"] == "monument")
		core_radius = max(core_radius, 1)
	for(var/turf/footprint_turf as anything in footprint)
		if(!istype(footprint_turf))
			continue
		if(max(abs(footprint_turf.x - center_turf.x), abs(footprint_turf.y - center_turf.y)) > core_radius)
			continue
		append_unique_turf(core_turfs, core_lookup, footprint_turf)
	if(!length(core_turfs))
		append_unique_turf(core_turfs, core_lookup, center_turf)
	return core_turfs

/datum/world_edit_generator/building_layout/proc/build_open_structure_reserved_turfs(list/core_turfs, turf/center_turf, list/floor_lookup)
	var/list/reserved = list()
	var/list/reserved_lookup = list()
	for(var/turf/core_turf as anything in core_turfs)
		append_unique_turf(reserved, reserved_lookup, core_turf)
	append_unique_turf(reserved, reserved_lookup, center_turf)
	for(var/check_dir in GLOB.cardinals)
		var/turf/nearby_turf = get_step(center_turf, check_dir)
		if(floor_lookup[nearby_turf])
			append_unique_turf(reserved, reserved_lookup, nearby_turf)
	return reserved

/datum/world_edit_generator/building_layout/proc/select_open_structure_candidate(list/candidates, turf/center_turf, target_dir, target_radius, list/object_lookup, list/reserved_lookup, list/used_lookup)
	var/turf/best_turf = null
	var/best_score = -999999999
	if(!istype(center_turf))
		return null
	for(var/turf/candidate_turf as anything in candidates)
		if(!istype(candidate_turf) || object_lookup[candidate_turf] || reserved_lookup[candidate_turf] || used_lookup[candidate_turf])
			continue
		var/radius_distance = max(abs(candidate_turf.x - center_turf.x), abs(candidate_turf.y - center_turf.y))
		var/score = -abs(radius_distance - target_radius) * 140
		score += get_projection_for_dir(candidate_turf, center_turf.x, center_turf.y, target_dir) * 30
		score -= get_lateral_distance_for_dir(candidate_turf, center_turf.x, center_turf.y, target_dir) * 8
		if(!istype(best_turf) || score > best_score)
			best_turf = candidate_turf
			best_score = score
	return best_turf

/datum/world_edit_generator/building_layout/proc/append_open_structure_focus(datum/world_edit_plan/plan, turf/center_turf, list/config, list/object_lookup)
	if(config["layout_variant"] != "platform" || !istype(center_turf))
		return 0
	var/focus_slot = config["faction_preset"] == "covenant" ? "tech" : "table"
	var/obj_path = resolve_interior_obj_path(config, focus_slot)
	if(!obj_path || object_lookup[center_turf])
		return 0
	plan.placements += list(build_object_placement("interior", center_turf, obj_path, SOUTH))
	object_lookup[center_turf] = TRUE
	return 1

/datum/world_edit_generator/building_layout/proc/append_open_structure_accents(datum/world_edit_plan/plan, list/floor_turfs, turf/center_turf, list/reserved_turfs, list/config, list/object_lookup, placement_dir)
	if(!istype(plan) || !length(floor_turfs) || config["interior_density"] <= 0)
		return 0
	var/list/reserved_lookup = GLOB.world_edit_placement_shapes.world_edit_build_turf_lookup(reserved_turfs)
	var/list/candidates = list()
	for(var/turf/floor_turf as anything in floor_turfs)
		if(!istype(floor_turf) || reserved_lookup[floor_turf] || object_lookup[floor_turf])
			continue
		candidates += floor_turf
	if(!length(candidates))
		return 0

	var/accent_cap = get_interior_motif_cap(config["layout_variant"], config["faction_preset"])
	var/desired_count = round(accent_cap * config["interior_density"] / 100)
	if(config["interior_density"] > 0)
		desired_count = max(desired_count, 1)
	desired_count = min(desired_count, length(candidates), accent_cap)
	var/list/slots = get_interior_slots(config["layout_variant"], config["faction_preset"])
	var/list/direction_sequence = list(placement_dir, turn(placement_dir, 90), turn(placement_dir, -90), turn(placement_dir, 180))
	var/list/used_lookup = list()
	var/core_radius = config["layout_variant"] == "monument" ? max(config["core_radius"], 1) : config["core_radius"]
	var/target_radius = max(core_radius + 2, 2)
	var/created_count = 0
	while(created_count < desired_count)
		var/slot = slots[(created_count % length(slots)) + 1]
		var/obj_path = resolve_interior_obj_path(config, slot)
		if(!obj_path)
			break
		var/target_dir = direction_sequence[(created_count % length(direction_sequence)) + 1]
		var/turf/target_turf = select_open_structure_candidate(candidates, center_turf, target_dir, target_radius, object_lookup, reserved_lookup, used_lookup)
		if(!istype(target_turf))
			break
		var/dir_to_use = get_cardinal_dir_toward(target_turf, center_turf, SOUTH)
		plan.placements += list(build_object_placement("interior", target_turf, obj_path, dir_to_use))
		object_lookup[target_turf] = TRUE
		used_lookup[target_turf] = TRUE
		created_count++
	return created_count

/datum/world_edit_generator/building_layout/proc/finalize_open_structure_plan(datum/world_edit_plan/plan, datum/world_edit_shape_contract/shape_contract, list/placement_context, list/config, list/footprint, list/boundary, list/floor_turfs, list/core_turfs, turf/center_turf, interior_object_count)
	plan.metadata["center_turf"] = center_turf
	plan.metadata["entry_count"] = length(plan.placements)
	plan.metadata["footprint_count"] = length(footprint)
	plan.metadata["boundary_count"] = length(boundary)
	plan.metadata["wall_count"] = length(core_turfs)
	plan.metadata["floor_count"] = length(floor_turfs)
	plan.metadata["door_count"] = 0
	plan.metadata["window_count"] = 0
	plan.metadata["interior_object_count"] = interior_object_count
	plan.metadata["patterned_layout"] = TRUE
	plan.metadata["open_structure"] = TRUE
	plan.metadata["core_radius"] = config["core_radius"]
	plan.metadata["faction_preset"] = config["faction_preset"]
	plan.metadata["layout_variant"] = config["layout_variant"]
	plan.metadata["generator_effect_turfs"] = footprint.Copy()
	finalize_shared_placement_plan_metadata(plan, shape_contract, placement_context)
	return plan

/datum/world_edit_generator/building_layout/proc/build_open_structure_plan(datum/world_edit_plan/plan, datum/world_edit_shape_contract/shape_contract, list/placement_context, list/config, list/footprint, list/boundary, center_x, center_y, placement_dir)
	var/turf/center_turf = select_center_floor_turf(footprint, center_x, center_y)
	if(!istype(center_turf))
		plan.metadata["error"] = "Could not select an open-structure center turf."
		return plan

	var/list/core_turfs = collect_open_structure_core_turfs(footprint, center_turf, config)
	var/list/core_lookup = GLOB.world_edit_placement_shapes.world_edit_build_turf_lookup(core_turfs)
	var/list/floor_turfs = list()
	for(var/turf/footprint_turf as anything in footprint)
		if(core_lookup[footprint_turf])
			plan.placements += list(build_turf_placement("wall", footprint_turf, config["wall_type"]))
		else
			plan.placements += list(build_turf_placement("floor", footprint_turf, config["floor_type"]))
			floor_turfs += footprint_turf
		plan.affected_turfs += footprint_turf

	var/list/floor_lookup = GLOB.world_edit_placement_shapes.world_edit_build_turf_lookup(floor_turfs)
	var/list/reserved_turfs = build_open_structure_reserved_turfs(core_turfs, center_turf, floor_lookup)
	var/list/object_lookup = list()
	var/interior_object_count = append_open_structure_focus(plan, center_turf, config, object_lookup)
	interior_object_count += append_open_structure_accents(plan, floor_turfs, center_turf, reserved_turfs, config, object_lookup, placement_dir)
	return finalize_open_structure_plan(plan, shape_contract, placement_context, config, footprint, boundary, floor_turfs, core_turfs, center_turf, interior_object_count)

/datum/world_edit_generator/building_layout/build_plan_from_shape_contract(mob/user, datum/world_edit_shape_contract/shape_contract, list/params, list/placement_context)
	var/datum/world_edit_plan/plan = new
	var/list/config = normalize_building_params(params)
	if(config["error"])
		plan.metadata["error"] = "[config["error"]]"
		return plan
	if(shape_contract?.error)
		plan.metadata["error"] = "[shape_contract.error]"
		return plan

	var/list/footprint_result = resolve_shape_footprint(shape_contract, config, params, placement_context)
	if(footprint_result["error"])
		plan.metadata["error"] = "[footprint_result["error"]]"
		return plan
	var/list/validated = validate_footprint(footprint_result["footprint"], config)
	if(validated["error"])
		plan.metadata["error"] = "[validated["error"]]"
		return plan

	var/list/footprint = validated["footprint"]
	var/list/boundary = validated["boundary"]
	var/list/interior = validated["interior"]
	var/list/footprint_lookup = validated["footprint_lookup"]
	var/list/bounds = validated["bounds"]
	var/center_x = (bounds["min_x"] + bounds["max_x"]) / 2
	var/center_y = (bounds["min_y"] + bounds["max_y"]) / 2
	var/placement_dir = text2num("[placement_context["direction"]]")
	if(!(placement_dir in GLOB.cardinals))
		placement_dir = manager?.get_effective_placement_dir() || NORTH
	if(is_open_structure_layout(config["layout_variant"]))
		return build_open_structure_plan(plan, shape_contract, placement_context, config, footprint, boundary, center_x, center_y, placement_dir)

	var/list/door_turfs = list()
	var/turf/front_door_turf = select_boundary_turf_for_dir(boundary, center_x, center_y, placement_dir, null, footprint_lookup)
	if(!istype(front_door_turf))
		plan.metadata["error"] = "Не удалось выбрать место для двери."
		return plan
	door_turfs += front_door_turf
	if(config["back_exit"])
		var/list/front_door_lookup = list()
		front_door_lookup[front_door_turf] = TRUE
		var/turf/back_door_turf = select_boundary_turf_for_dir(boundary, center_x, center_y, turn(placement_dir, 180), front_door_lookup, footprint_lookup)
		if(istype(back_door_turf))
			door_turfs += back_door_turf

	var/list/window_turfs = select_window_turfs(boundary, door_turfs, footprint_lookup, center_x, center_y, config["window_density"])
	var/list/door_lookup = GLOB.world_edit_placement_shapes.world_edit_build_turf_lookup(door_turfs)
	var/list/window_lookup = GLOB.world_edit_placement_shapes.world_edit_build_turf_lookup(window_turfs)
	var/list/wall_lookup = list()
	for(var/turf/boundary_turf as anything in boundary)
		if(door_lookup[boundary_turf] || window_lookup[boundary_turf])
			continue
		wall_lookup[boundary_turf] = TRUE

	for(var/turf/footprint_turf as anything in footprint)
		if(wall_lookup[footprint_turf])
			plan.placements += list(build_turf_placement("wall", footprint_turf, config["wall_type"]))
		else
			plan.placements += list(build_turf_placement("floor", footprint_turf, config["floor_type"]))
		plan.affected_turfs += footprint_turf

	for(var/turf/door_turf as anything in door_turfs)
		var/door_dir = get_outward_dir(door_turf, footprint_lookup, center_x, center_y, placement_dir)
		plan.placements += list(build_object_placement("door", door_turf, config["door_type"], door_dir))
	for(var/turf/window_turf as anything in window_turfs)
		var/window_dir = get_outward_dir(window_turf, footprint_lookup, center_x, center_y, placement_dir)
		plan.placements += list(build_object_placement("window", window_turf, config["window_type"], window_dir))

	var/list/floor_turfs = list()
	for(var/turf/floor_turf as anything in footprint)
		if(wall_lookup[floor_turf])
			continue
		floor_turfs += floor_turf
	var/turf/center_turf = select_center_floor_turf(floor_turfs, center_x, center_y) || front_door_turf
	var/list/floor_lookup = GLOB.world_edit_placement_shapes.world_edit_build_turf_lookup(floor_turfs)
	var/list/reserved_path = build_reserved_paths(door_turfs, center_turf, floor_lookup)
	var/list/object_lookup = list()
	for(var/turf/object_turf as anything in door_turfs)
		object_lookup[object_turf] = TRUE
	for(var/turf/object_turf as anything in window_turfs)
		object_lookup[object_turf] = TRUE
	var/interior_object_count = append_interior_placements(plan, interior, wall_lookup, reserved_path, center_turf, config, object_lookup)

	plan.metadata["center_turf"] = center_turf
	plan.metadata["entry_count"] = length(plan.placements)
	plan.metadata["footprint_count"] = length(footprint)
	plan.metadata["boundary_count"] = length(boundary)
	plan.metadata["wall_count"] = length(wall_lookup)
	plan.metadata["floor_count"] = length(floor_turfs)
	plan.metadata["door_count"] = length(door_turfs)
	plan.metadata["window_count"] = length(window_turfs)
	plan.metadata["interior_object_count"] = interior_object_count
	plan.metadata["patterned_layout"] = TRUE
	plan.metadata["faction_preset"] = config["faction_preset"]
	plan.metadata["layout_variant"] = config["layout_variant"]
	plan.metadata["generator_effect_turfs"] = footprint.Copy()
	finalize_shared_placement_plan_metadata(plan, shape_contract, placement_context)
	return plan

/datum/world_edit_generator/building_layout/build_placement_plan(mob/user, list/params, list/placement_context)
	var/datum/world_edit_shape_contract/shape_contract = build_shape_contract_from_placement_context(placement_context["shape"], placement_context["anchor_turfs"], placement_context)
	return build_plan_from_shape_contract(user, shape_contract, params, placement_context)

/datum/world_edit_generator/building_layout/build_plan(list/params)
	var/turf/anchor_turf = manager?.placement_anchor_turf
	if(!istype(anchor_turf))
		anchor_turf = get_turf(manager?.holder?.mob)
	var/datum/world_edit_plan/error_plan
	if(!istype(anchor_turf))
		error_plan = new
		error_plan.metadata["error"] = "Не удалось определить опорный тайл постройки."
		return error_plan

	var/shape_id = manager?.get_effective_placement_shape() || WORLD_EDIT_SHAPE_POINT
	var/placement_dir = manager?.get_effective_placement_dir() || NORTH
	var/list/shape_result = GLOB.world_edit_placement_shapes.world_edit_build_shape_turfs(shape_id, anchor_turf, null, params, placement_dir)
	if(shape_result["error"])
		error_plan = new
		error_plan.metadata["error"] = "[shape_result["error"]]"
		return error_plan
	return build_placement_plan(manager?.holder?.mob, params, list(
		"mode" = manager?.get_effective_placement_mode() || "single",
		"shape" = shape_id,
		"shape_metadata" = shape_result["metadata"] || list(),
		"anchor_turfs" = shape_result["turfs"] || list(anchor_turf),
		"start_turf" = anchor_turf,
		"end_turf" = anchor_turf,
		"shape_origin_turf" = anchor_turf,
		"seed_turf" = anchor_turf,
		"requested_end_turf" = anchor_turf,
		"resolved_end_turf" = anchor_turf,
		"direction" = placement_dir,
	))

/datum/world_edit_generator/building_layout/proc/build_building_preview_spec_from_placement(list/placement)
	if(!islist(placement))
		return null
	var/kind = "[placement["kind"]]"
	var/turf/target_turf = placement["turf"]
	if(!istype(target_turf))
		return null
	if(kind in list("floor", "wall"))
		var/turf_path = placement["turf_path"]
		if(!ispath(turf_path, /turf))
			return null
		var/turf/preview_turf = turf_path
		var/list/turf_spec = GLOB.world_edit_helpers.build_world_edit_preview_object_spec(
			target_turf,
			initial(preview_turf.icon),
			initial(preview_turf.icon_state),
			SOUTH,
			initial(preview_turf.layer),
			initial(preview_turf.plane),
			0,
			0,
			kind == "floor" ? 210 : 235
		)
		if(islist(turf_spec))
			turf_spec["kind"] = kind
		return turf_spec
	if(kind in list("door", "window", "interior"))
		var/obj_path = placement["obj_path"]
		if(!ispath(obj_path, /obj))
			return null
		var/list/object_spec = GLOB.world_edit_helpers.build_world_edit_atom_preview_spec(obj_path, target_turf, placement["dir"])
		if(islist(object_spec))
			object_spec["kind"] = kind
		return object_spec
	return null

/datum/world_edit_generator/building_layout/build_plan_preview_object_specs(datum/world_edit_plan/plan, list/runtime_params = null, list/placement_context = null, hover_only = FALSE)
	var/list/specs = list()
	if(!istype(plan))
		return specs
	var/spec_limit = hover_only ? WORLD_EDIT_BUILDING_MAX_HOVER_PREVIEW_OBJECT_SPECS : WORLD_EDIT_BUILDING_MAX_PREVIEW_OBJECT_SPECS
	for(var/list/placement as anything in plan.placements)
		if(length(specs) >= spec_limit)
			break
		var/list/spec = build_building_preview_spec_from_placement(placement)
		if(islist(spec))
			specs += list(spec)
	return specs

/datum/world_edit_generator/building_layout/should_render_preview_via_placement_layers(datum/world_edit_plan/plan)
	return istype(plan) ? TRUE : FALSE

/datum/world_edit_generator/building_layout/should_skip_plan_build_for_hover_only_placement(datum/world_edit_shape_contract/shape_contract, list/runtime_params = null, list/placement_context = null)
	return TRUE

/datum/world_edit_generator/building_layout/should_build_hover_object_preview_plan(datum/world_edit_shape_contract/shape_contract, list/runtime_params = null, list/placement_context = null)
	if(!istype(shape_contract) || length("[shape_contract.error]"))
		return FALSE
	if(!length(shape_contract.anchor_turfs))
		return FALSE
	return TRUE

/datum/world_edit_generator/building_layout/get_hover_object_preview_anchor_limit()
	return 2

/datum/world_edit_generator/building_layout/preview(mob/user, list/params)
	var/datum/world_edit_preview_result/result = new
	clear_built_plan()

	var/datum/world_edit_plan/plan = build_plan(params)
	if(!istype(plan))
		result.message = "Не удалось построить план постройки."
		return result
	if(plan.metadata["error"])
		result.message = "[plan.metadata["error"]]"
		return result
	if(!length(plan.placements))
		result.message = "План постройки пуст."
		return result

	current_plan = plan
	result.success = TRUE
	if(!manager?.should_use_placement_layer_preview(plan))
		result.preview_images = GLOB.world_edit_helpers.build_turf_preview_images(plan.affected_turfs)
		result.preview_images += GLOB.world_edit_helpers.build_preview_images_from_specs(build_plan_preview_object_specs(plan, params))
	result.meta = plan.metadata.Copy()
	result.message = "Предпросмотр постройки готов: footprint=[plan.metadata["footprint_count"]], стены=[plan.metadata["wall_count"]], двери=[plan.metadata["door_count"]], окна=[plan.metadata["window_count"]], интерьер=[plan.metadata["interior_object_count"]]."
	return result

/datum/world_edit_generator/building_layout/apply(mob/user, list/params)
	return apply_plan(user, params, current_plan)

/datum/world_edit_generator/building_layout/proc/runtime_target_turf(list/placement)
	var/x_value = text2num("[placement["x"]]")
	var/y_value = text2num("[placement["y"]]")
	var/z_value = text2num("[placement["z"]]")
	return locate(x_value, y_value, z_value)

/datum/world_edit_generator/building_layout/proc/placement_coord_key(list/placement)
	if(!islist(placement))
		return null
	return "[placement["x"]],[placement["y"]],[placement["z"]]"

/datum/world_edit_generator/building_layout/proc/has_runtime_object_blocker(turf/target_turf)
	if(!istype(target_turf) || target_turf.density)
		return TRUE
	for(var/atom/movable/blocker as anything in target_turf)
		if(ismob(blocker))
			continue
		if(blocker.density)
			return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/get_runtime_footprint_blocker_error(datum/world_edit_plan/plan)
	if(!istype(plan))
		return "Building plan is unavailable."
	var/list/checked_lookup = list()
	for(var/list/placement as anything in plan.placements)
		var/kind = "[placement["kind"]]"
		if(!(kind in list("floor", "wall", "door", "window", "interior")))
			continue
		var/key = placement_coord_key(placement)
		if(checked_lookup[key])
			continue
		checked_lookup[key] = TRUE
		var/turf/check_turf = runtime_target_turf(placement)
		var/blocker_error = get_footprint_blocker_error(check_turf)
		if(length("[blocker_error]"))
			return blocker_error
	return null

/datum/world_edit_generator/building_layout/apply_plan(mob/user, list/params, datum/world_edit_plan/plan)
	var/datum/world_edit_apply_result/result = new
	if(!istype(plan))
		result.message = "Сначала выполните предпросмотр, чтобы построить план постройки."
		return result
	if(plan.metadata["error"])
		result.message = "[plan.metadata["error"]]"
		return result

	var/list/config = normalize_building_params(params)
	if(config["respect_blockers"])
		var/runtime_blocker_error = get_runtime_footprint_blocker_error(plan)
		if(length("[runtime_blocker_error]"))
			result.message = "[runtime_blocker_error]"
			return result

	var/datum/world_edit_changeset/changeset = new /datum/world_edit_changeset(definition?.id || "building_layout", WORLD_EDIT_UNDO_FULL, list(
		"center_turf" = plan.metadata["center_turf"],
		"faction_preset" = plan.metadata["faction_preset"],
		"layout_variant" = plan.metadata["layout_variant"],
		"placement_mode" = plan.metadata["placement_mode"],
		"placement_dir" = plan.metadata["placement_dir"],
	))

	var/changed_turf_count = 0
	var/created_object_count = 0
	var/skipped_runtime = 0
	var/list/skipped_turf_lookup = list()
	var/replace_blocked_turfs = config["replace_blocked_turfs"]
	for(var/list/placement as anything in plan.placements)
		var/kind = "[placement["kind"]]"
		if(!(kind in list("floor", "wall")))
			continue
		var/turf/target_turf = runtime_target_turf(placement)
		var/coord_key = placement_coord_key(placement)
		var/turf_path = placement["turf_path"]
		if(!istype(target_turf) || !ispath(turf_path, /turf))
			skipped_runtime++
			if(length("[coord_key]"))
				skipped_turf_lookup[coord_key] = TRUE
			continue
		if(!replace_blocked_turfs && get_footprint_blocker_error(target_turf))
			skipped_runtime++
			if(length("[coord_key]"))
				skipped_turf_lookup[coord_key] = TRUE
			continue
		if(target_turf.type == turf_path)
			continue
		var/old_type = target_turf.type
		var/old_baseturfs = islist(target_turf.baseturfs) ? target_turf.baseturfs.Copy() : target_turf.baseturfs
		var/turf/new_turf = target_turf.ChangeTurf(turf_path)
		if(!istype(new_turf) || new_turf.type != turf_path)
			skipped_runtime++
			continue
		changed_turf_count++
		changeset.add_changed_turf(new_turf, old_type, turf_path, old_baseturfs, list("kind" = kind))

	for(var/list/placement as anything in plan.placements)
		var/kind = "[placement["kind"]]"
		if(!(kind in list("door", "window", "interior")))
			continue
		var/turf/target_turf = runtime_target_turf(placement)
		var/coord_key = placement_coord_key(placement)
		var/obj_path = placement["obj_path"]
		if(!istype(target_turf) || !ispath(obj_path, /obj))
			skipped_runtime++
			continue
		if(skipped_turf_lookup[coord_key])
			skipped_runtime++
			continue
		if(has_runtime_object_blocker(target_turf))
			skipped_runtime++
			continue
		var/obj/created_object = new obj_path(target_turf)
		if(!created_object)
			skipped_runtime++
			continue
		var/dir_to_use = text2num("[placement["dir"]]")
		if(dir_to_use in GLOB.cardinals)
			created_object.setDir(dir_to_use)
		created_object_count++
		changeset.add_created(created_object, target_turf, list(
			"kind" = kind,
			"obj_path" = obj_path,
			"dir" = dir_to_use,
		))

	result.center_turf = plan.metadata["center_turf"]
	result.created_count = created_object_count
	result.meta = islist(plan.metadata) ? plan.metadata.Copy() : list()
	result.meta["changed_turf_count"] = changed_turf_count
	result.meta["created_object_count"] = created_object_count
	result.meta["skipped_runtime"] = skipped_runtime
	if(changed_turf_count <= 0 && created_object_count <= 0)
		result.message = "Постройка не внесла изменений: runtime-пропущено=[skipped_runtime]."
		return result

	result.success = TRUE
	result.changeset = changeset
	result.message = "Постройка применена: turfs=[changed_turf_count], objects=[created_object_count], пропущено=[skipped_runtime]."
	return result

#undef WORLD_EDIT_BUILDING_MAX_FOOTPRINT_TURFS
#undef WORLD_EDIT_BUILDING_MAX_PREVIEW_OBJECT_SPECS
#undef WORLD_EDIT_BUILDING_MAX_HOVER_PREVIEW_OBJECT_SPECS
#undef WORLD_EDIT_BUILDING_MAX_INTERIOR_OBJECTS
#undef WORLD_EDIT_BUILDING_MAX_WINDOWS
