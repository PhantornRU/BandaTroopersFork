/datum/world_edit_generator/outpost_radius/get_ui_fields(list/current_params)
	var/defense_profile_id = resolve_outpost_defense_profile_id(current_params["defense_profile"])
	if(!defense_profile_id)
		defense_profile_id = get_default_outpost_defense_profile_id()

	var/layout_id = resolve_outpost_layout_id(current_params["layout_variant"])
	if(!layout_id)
		layout_id = get_default_outpost_layout_id()

	var/barricade_pattern = resolve_barricade_pattern(current_params["barricade_pattern"]) || "uniform"
	var/place_barricade_doors = GLOB.world_edit_helpers.parse_bool(current_params["place_barricade_doors"])
	var/primary_material_share_percent = clamp(round(text2num("[current_params["primary_material_share_percent"] || 100]")), 0, 100)
	if(barricade_pattern == "uniform")
		primary_material_share_percent = 100

	var/primary_material_path = resolve_whitelisted_type(
		current_params["primary_material_path"],
		allowed_barricade_types,
		/datum/human_ai_defense/barricade,
		/datum/human_ai_defense/barricade/metal,
	)
	if(!primary_material_path)
		primary_material_path = /datum/human_ai_defense/barricade/metal

	var/secondary_material_path = resolve_whitelisted_type(
		current_params["secondary_material_path"],
		allowed_barricade_types,
		/datum/human_ai_defense/barricade,
		primary_material_path,
	)
	if(!secondary_material_path)
		secondary_material_path = primary_material_path
	if(barricade_pattern == "uniform")
		secondary_material_path = primary_material_path

	var/primary_door_selection = resolve_outpost_door_selection(current_params["primary_door_path"])
	if(isnull(primary_door_selection))
		primary_door_selection = "follow_material"
	var/secondary_door_selection = resolve_outpost_door_selection(current_params["secondary_door_path"])
	if(isnull(secondary_door_selection))
		secondary_door_selection = "follow_material"
	if(barricade_pattern == "uniform")
		secondary_door_selection = primary_door_selection

	return list(
		list(
			"id" = "defense_profile",
			"label" = "Тактический профиль",
			"kind" = "select",
			"group" = "Схема",
			"description" = "Определяет оборонительные объекты, проволоку, мины и дополнительные защитные узлы без привязки к материалу периметра.",
			"value" = defense_profile_id,
			"options" = build_defense_profile_options(),
		),
		list(
			"id" = "layout_variant",
			"label" = "Схема",
			"kind" = "select",
			"group" = "Схема",
			"description" = "Определяет, где находятся проходы и как вращается раскладка относительно текущего направления размещения.",
			"value" = layout_id,
			"options" = build_layout_options(),
		),
		list(
			"id" = "opening_width",
			"label" = "Ширина проходов",
			"kind" = "select",
			"group" = "Схема",
			"description" = "Переопределяет ширину каждого планируемого прохода.",
			"value" = get_outpost_opening_width_option_id(current_params["opening_width"]) || "layout",
			"options" = build_opening_width_options(),
		),
		list(
			"id" = "radius",
			"label" = "Смещение периметра",
			"kind" = "number",
			"group" = "Схема",
			"description" = "Насколько далеко сгенерированный контур отстоит от выбранного отпечатка размещения.",
			"validate_hint" = "Допустимый диапазон: 1..[WORLD_EDIT_OUTPOST_RADIUS_MAX]",
			"value" = text2num("[current_params["radius"]]") || 4,
			"min" = 1,
			"max" = WORLD_EDIT_OUTPOST_RADIUS_MAX,
			"step" = 1,
		),
		list(
			"id" = WORLD_EDIT_RADIUS_POLICY_ONLY_CLEAR_TILES,
			"label" = "Только чистые клетки",
			"kind" = "boolean",
			"group" = "Схема",
			"description" = "Останавливает расширение радиуса у блокеров, но не делает недействительной кликнутую клетку или выбранный контур.",
			"value" = isnull(current_params[WORLD_EDIT_RADIUS_POLICY_ONLY_CLEAR_TILES]) ? TRUE : GLOB.world_edit_helpers.parse_bool(current_params[WORLD_EDIT_RADIUS_POLICY_ONLY_CLEAR_TILES]),
		),
		list(
			"id" = WORLD_EDIT_RADIUS_POLICY_ONLY_REACHABLE_TILES,
			"label" = "Только достижимые клетки",
			"kind" = "boolean",
			"group" = "Схема",
			"description" = "Оставляет только клетки, до которых можно добраться от начала рисования через соседние незаблокированные клетки. Этот режим всегда включает фильтрацию чистого пути.",
			"value" = isnull(current_params[WORLD_EDIT_RADIUS_POLICY_ONLY_REACHABLE_TILES]) ? FALSE : GLOB.world_edit_helpers.parse_bool(current_params[WORLD_EDIT_RADIUS_POLICY_ONLY_REACHABLE_TILES]),
		),
		list(
			"id" = WORLD_EDIT_RADIUS_POLICY_WINDOWS_BLOCKERS,
			"label" = "Окна блокируют путь",
			"kind" = "boolean",
			"group" = "Схема",
			"description" = "Считает окна блокерами при проверке чистого пути и достижимости расширения.",
			"value" = isnull(current_params[WORLD_EDIT_RADIUS_POLICY_WINDOWS_BLOCKERS]) ? TRUE : GLOB.world_edit_helpers.parse_bool(current_params[WORLD_EDIT_RADIUS_POLICY_WINDOWS_BLOCKERS]),
		),
		list(
			"id" = "primary_material_path",
			"label" = "Основной материал",
			"kind" = "select",
			"group" = "Периметр",
			"description" = "Базовый материал для периметра форпоста.",
			"value" = "[primary_material_path]",
			"options" = build_type_options(allowed_barricade_types),
		),
		list(
			"id" = "secondary_material_path",
			"label" = "Вспомогательный материал",
			"kind" = "select",
			"group" = "Периметр",
			"description" = "Материал для чередования или парных секций.",
			"value" = "[secondary_material_path]",
			"options" = build_type_options(allowed_barricade_types),
			"visible" = barricade_pattern != "uniform",
		),
		list(
			"id" = "barricade_pattern",
			"label" = "Раскладка баррикад",
			"kind" = "select",
			"group" = "Периметр",
			"description" = "Определяет, как основной и вспомогательный материалы распределяются по каноническому порядку периметра.",
			"value" = barricade_pattern,
			"options" = build_barricade_pattern_options(),
		),
		list(
			"id" = "primary_material_share_percent",
			"label" = "Доля основного материала",
			"kind" = "number",
			"group" = "Периметр",
			"description" = "Точная доля секций периметра вне проходов, которая должна использовать основной материал. Ближайшие к проходам слоты получают приоритет.",
			"validate_hint" = "Допустимый диапазон: 0..100",
			"value" = primary_material_share_percent,
			"min" = 0,
			"max" = 100,
			"step" = 1,
			"visible" = barricade_pattern != "uniform",
		),
		list(
			"id" = "place_barricade_doors",
			"label" = "Ставить двери в проходы",
			"kind" = "boolean",
			"group" = "Периметр",
			"description" = "Пытается заменить проходы складными дверями по материалу секции или явному переопределению.",
			"value" = place_barricade_doors,
		),
		list(
			"id" = "primary_door_path",
			"label" = "Основные двери",
			"kind" = "select",
			"group" = "Периметр",
			"description" = "Тип складной двери для секций основного материала.",
			"value" = ispath(primary_door_selection, /datum/human_ai_defense/barricade) ? "[primary_door_selection]" : "[primary_door_selection]",
			"options" = build_outpost_door_type_options(),
			"visible" = place_barricade_doors,
		),
		list(
			"id" = "secondary_door_path",
			"label" = "Вспомогательные двери",
			"kind" = "select",
			"group" = "Периметр",
			"description" = "Тип складной двери для секций вспомогательного материала.",
			"value" = ispath(secondary_door_selection, /datum/human_ai_defense/barricade) ? "[secondary_door_selection]" : "[secondary_door_selection]",
			"options" = build_outpost_door_type_options(),
			"visible" = place_barricade_doors && barricade_pattern != "uniform",
		),
	)

/datum/world_edit_generator/outpost_radius/set_ui_param(mob/user, list/current_params, param_id, value)
	var/list/new_params = current_params.Copy()

	switch(param_id)
		if("defense_profile")
			var/defense_profile_id = resolve_outpost_defense_profile_id(value)
			if(!defense_profile_id)
				return "Выбран недопустимый тактический профиль."
			new_params[param_id] = defense_profile_id

		if("layout_variant")
			var/layout_id = resolve_outpost_layout_id(value)
			if(!layout_id)
				return "Выбрана недопустимая схема форпоста."
			new_params[param_id] = layout_id

		if("opening_width")
			var/option_id = get_outpost_opening_width_option_id(value)
			if(isnull(option_id))
				return "Выбрана недопустимая ширина проходов."
			var/opening_width = resolve_opening_width(option_id, get_outpost_layout_profile(resolve_outpost_layout_id(new_params["layout_variant"]) || get_default_outpost_layout_id()))
			if(isnull(opening_width))
				return "Выбрана недопустимая ширина проходов."
			new_params[param_id] = option_id

		if("radius")
			new_params[param_id] = clamp(text2num("[value]"), 1, WORLD_EDIT_OUTPOST_RADIUS_MAX)

		if(WORLD_EDIT_RADIUS_POLICY_ONLY_CLEAR_TILES)
			new_params[param_id] = GLOB.world_edit_helpers.parse_bool(value)
			if(!new_params[param_id] && GLOB.world_edit_helpers.parse_bool(new_params[WORLD_EDIT_RADIUS_POLICY_ONLY_REACHABLE_TILES]))
				new_params[WORLD_EDIT_RADIUS_POLICY_ONLY_REACHABLE_TILES] = FALSE

		if(WORLD_EDIT_RADIUS_POLICY_ONLY_REACHABLE_TILES)
			new_params[param_id] = GLOB.world_edit_helpers.parse_bool(value)
			if(new_params[param_id])
				new_params[WORLD_EDIT_RADIUS_POLICY_ONLY_CLEAR_TILES] = TRUE

		if(WORLD_EDIT_RADIUS_POLICY_WINDOWS_BLOCKERS)
			new_params[param_id] = GLOB.world_edit_helpers.parse_bool(value)

		if("primary_material_path")
			var/path_value = resolve_whitelisted_type(value, allowed_barricade_types, /datum/human_ai_defense/barricade, /datum/human_ai_defense/barricade/metal)
			if(!path_value)
				return "Выбран недопустимый основной материал периметра."
			new_params[param_id] = path_value
			if(isnull(new_params["secondary_material_path"]))
				new_params["secondary_material_path"] = path_value

		if("secondary_material_path")
			var/path_value = resolve_whitelisted_type(value, allowed_barricade_types, /datum/human_ai_defense/barricade, new_params["primary_material_path"] || /datum/human_ai_defense/barricade/metal)
			if(!path_value)
				return "Выбран недопустимый вспомогательный материал периметра."
			new_params[param_id] = path_value

		if("barricade_pattern")
			var/pattern_value = resolve_barricade_pattern(value)
			if(isnull(pattern_value))
				return "Выбрана недопустимая раскладка баррикад."
			new_params[param_id] = pattern_value
			if(pattern_value == "uniform")
				new_params["primary_material_share_percent"] = 100

		if("primary_material_share_percent")
			var/share_percent = clamp(round(text2num("[value]")), 0, 100)
			if("[new_params["barricade_pattern"] || "uniform"]" == "uniform")
				share_percent = 100
			new_params["primary_material_share_percent"] = share_percent

		if("place_barricade_doors")
			new_params[param_id] = GLOB.world_edit_helpers.parse_bool(value)

		if("primary_door_path")
			var/door_selection = resolve_outpost_door_selection(value)
			if(isnull(door_selection))
				return "Выбран недопустимый тип основных дверей."
			new_params[param_id] = door_selection

		if("secondary_door_path")
			var/door_selection = resolve_outpost_door_selection(value)
			if(isnull(door_selection))
				return "Выбран недопустимый тип вспомогательных дверей."
			new_params[param_id] = door_selection

		else
			return ..()

	return new_params

/datum/world_edit_generator/outpost_radius/get_apply_confirmation_text(list/params)
	var/defense_profile_id = resolve_outpost_defense_profile_id(params["defense_profile"])
	if(!defense_profile_id)
		defense_profile_id = get_default_outpost_defense_profile_id()

	var/layout_id = resolve_outpost_layout_id(params["layout_variant"])
	if(!layout_id)
		layout_id = get_default_outpost_layout_id()

	var/list/defense_profile = get_outpost_defense_profile(defense_profile_id)
	var/list/layout_profile = get_outpost_layout_profile(layout_id)
	return "Применить '[defense_profile["label"] || "Форпост"] / [layout_profile["label"] || "Крест"]' со смещением периметра [params["radius"]]?"

/datum/world_edit_generator/outpost_radius/get_params_short(list/params)
	var/list/radius_policy = GLOB.world_edit_helpers.get_world_edit_radius_policy(params)
	return "defense=[resolve_outpost_defense_profile_id(params["defense_profile"]) || get_default_outpost_defense_profile_id()] layout=[resolve_outpost_layout_id(params["layout_variant"]) || get_default_outpost_layout_id()] width=[get_outpost_opening_width_option_id(params["opening_width"]) || "layout"] perimeter_offset=[params["radius"]] clear=[radius_policy["only_clear_tiles"]] reachable=[radius_policy["only_reachable_tiles"]] windows=[radius_policy["treat_windows_as_blockers"]] shape=[manager?.get_effective_placement_shape() || WORLD_EDIT_SHAPE_POINT] mode=[manager?.get_effective_placement_mode() || "single"] dir=[GLOB.world_edit_helpers.dir_to_label(manager?.get_effective_placement_dir() || NORTH)] primary_material=[params["primary_material_path"]] secondary_material=[params["secondary_material_path"]] primary_share=[params["primary_material_share_percent"] || 100] doors=[GLOB.world_edit_helpers.parse_bool(params["place_barricade_doors"])] primary_door=[params["primary_door_path"] || "follow_material"] secondary_door=[params["secondary_door_path"] || "follow_material"] pattern=[params["barricade_pattern"] || "uniform"]"
