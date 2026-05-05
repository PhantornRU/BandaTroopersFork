/datum/world_edit_generator/outpost_radius/get_ui_fields(list/current_params)
	var/defense_profile_id = resolve_outpost_defense_profile_id(current_params["defense_profile"])
	if(!defense_profile_id)
		defense_profile_id = get_default_outpost_defense_profile_id()

	var/layout_id = resolve_outpost_layout_id(current_params["layout_variant"])
	if(!layout_id)
		layout_id = get_default_outpost_layout_id()

	var/barricade_pattern = resolve_barricade_pattern(current_params["barricade_pattern"]) || "uniform"
	var/place_barricade_doors = GLOB.world_edit_helpers.parse_bool(current_params["place_barricade_doors"])
	var/raw_primary_material_share_percent = text2num("[current_params["primary_material_share_percent"]]")
	var/primary_material_share_percent = clamp(round(isnum(raw_primary_material_share_percent) ? raw_primary_material_share_percent : 100), 0, 100)

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

	var/list/profile_layer_defaults = get_outpost_profile_layer_defaults(defense_profile_id)
	var/faction = resolve_outpost_faction(get_outpost_param_or_default(current_params, profile_layer_defaults, "faction"), FACTION_MARINE) || FACTION_MARINE
	var/turned_on = GLOB.world_edit_helpers.parse_bool(get_outpost_param_or_default(current_params, profile_layer_defaults, "turned_on"))
	var/sentry_layer_profile = resolve_id_option(get_outpost_param_or_default(current_params, profile_layer_defaults, "sentry_layer_profile"), list("none", "guard", "rear", "corners", "guard_corners"), "none") || "none"
	var/sentry_type = resolve_whitelisted_type(get_outpost_param_or_default(current_params, profile_layer_defaults, "sentry_type"), allowed_sentry_types, /datum/human_ai_defense/defense/sentry, /datum/human_ai_defense/defense/sentry/uscm) || /datum/human_ai_defense/defense/sentry/uscm
	var/extra_defense_layer_profile = resolve_id_option(get_outpost_param_or_default(current_params, profile_layer_defaults, "extra_defense_layer_profile"), list("none", "rear", "corners"), "none") || "none"
	var/extra_defense_type = resolve_whitelisted_type(get_outpost_param_or_default(current_params, profile_layer_defaults, "extra_defense_type"), allowed_extra_defense_types, /datum/human_ai_defense/defense, /datum/human_ai_defense/defense/tesla) || /datum/human_ai_defense/defense/tesla
	var/flag_type = resolve_optional_whitelisted_type(get_outpost_param_or_default(current_params, profile_layer_defaults, "flag_type"), allowed_flag_types, /datum/human_ai_defense/defense/flag, profile_layer_defaults["flag_type"])
	if(isnull(flag_type))
		flag_type = "none"
	var/wire_layer_profile = resolve_id_option(get_outpost_param_or_default(current_params, profile_layer_defaults, "wire_layer_profile"), list("none", "openings", "perimeter"), "none") || "none"
	var/wire_offset = resolve_bounded_outpost_number(get_outpost_param_or_default(current_params, profile_layer_defaults, "wire_offset"), 3, 1, 12)
	var/wire_rows = resolve_bounded_outpost_number(get_outpost_param_or_default(current_params, profile_layer_defaults, "wire_rows"), 1, 0, 8)
	var/wire_row_step = resolve_bounded_outpost_number(get_outpost_param_or_default(current_params, profile_layer_defaults, "wire_row_step"), 1, 1, 6)
	var/wire_spacing = resolve_bounded_outpost_number(get_outpost_param_or_default(current_params, profile_layer_defaults, "wire_spacing"), 2, 1, 12)
	var/wire_concentration_percent = resolve_bounded_outpost_number(get_outpost_param_or_default(current_params, profile_layer_defaults, "wire_concentration_percent"), 70, 0, 100)
	var/minefield_profile = resolve_id_option(get_outpost_param_or_default(current_params, profile_layer_defaults, "minefield_profile"), list("none", "light", "medium", "dense"), "none") || "none"
	var/mine_type = resolve_whitelisted_type(get_outpost_param_or_default(current_params, profile_layer_defaults, "mine_type"), allowed_mine_types, /datum/human_ai_defense/mine, /datum/human_ai_defense/mine/claymore) || /datum/human_ai_defense/mine/claymore
	var/minefield_offset = resolve_bounded_outpost_number(get_outpost_param_or_default(current_params, profile_layer_defaults, "minefield_offset"), 3, 1, 12)
	var/minefield_depth = resolve_bounded_outpost_number(get_outpost_param_or_default(current_params, profile_layer_defaults, "minefield_depth"), 3, 0, 8)
	var/minefield_density_percent = resolve_bounded_outpost_number(get_outpost_param_or_default(current_params, profile_layer_defaults, "minefield_density_percent"), 35, 0, 100)
	var/minefield_seed = resolve_bounded_outpost_number(get_outpost_param_or_default(current_params, profile_layer_defaults, "minefield_seed"), 0, 0, 999999)

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
			"id" = "faction",
			"label" = "IFF / faction",
			"kind" = "select",
			"group" = "IFF",
			"description" = "Common IFF faction for sentries, teslas, flags, and mines.",
			"value" = faction,
			"options" = build_faction_options(),
		),
		list(
			"id" = "turned_on",
			"label" = "Powered",
			"kind" = "boolean",
			"group" = "IFF",
			"description" = "Spawn powered support defenses when the selected type supports it.",
			"value" = turned_on,
		),
		list(
			"id" = "sentry_layer_profile",
			"label" = "Sentry layer",
			"kind" = "select",
			"group" = "Defense",
			"value" = sentry_layer_profile,
			"options" = build_sentry_layer_profile_options(),
		),
		list(
			"id" = "sentry_type",
			"label" = "Sentry type",
			"kind" = "select",
			"group" = "Defense",
			"value" = "[sentry_type]",
			"options" = build_type_options(allowed_sentry_types),
			"visible" = sentry_layer_profile != "none",
		),
		list(
			"id" = "extra_defense_layer_profile",
			"label" = "Support layer",
			"kind" = "select",
			"group" = "Defense",
			"value" = extra_defense_layer_profile,
			"options" = build_extra_defense_layer_profile_options(),
		),
		list(
			"id" = "extra_defense_type",
			"label" = "Support type",
			"kind" = "select",
			"group" = "Defense",
			"value" = "[extra_defense_type]",
			"options" = build_type_options(allowed_extra_defense_types),
			"visible" = extra_defense_layer_profile != "none",
		),
		list(
			"id" = "flag_type",
			"label" = "Flag",
			"kind" = "select",
			"group" = "Defense",
			"value" = ispath(flag_type, /datum/human_ai_defense/defense/flag) ? "[flag_type]" : "none",
			"options" = build_type_options_with_none(allowed_flag_types),
		),
		list(
			"id" = "wire_layer_profile",
			"label" = "Wire layer",
			"kind" = "select",
			"group" = "Wire",
			"value" = wire_layer_profile,
			"options" = build_wire_layer_profile_options(),
		),
		list(
			"id" = "wire_offset",
			"label" = "Wire offset",
			"kind" = "number",
			"group" = "Wire",
			"value" = wire_offset,
			"min" = 1,
			"max" = 12,
			"step" = 1,
			"visible" = wire_layer_profile != "none",
		),
		list(
			"id" = "wire_rows",
			"label" = "Wire rows",
			"kind" = "number",
			"group" = "Wire",
			"value" = wire_rows,
			"min" = 0,
			"max" = 8,
			"step" = 1,
			"visible" = wire_layer_profile != "none",
		),
		list(
			"id" = "wire_row_step",
			"label" = "Wire row step",
			"kind" = "number",
			"group" = "Wire",
			"value" = wire_row_step,
			"min" = 1,
			"max" = 6,
			"step" = 1,
			"visible" = wire_layer_profile != "none",
		),
		list(
			"id" = "wire_spacing",
			"label" = "Wire spacing",
			"kind" = "number",
			"group" = "Wire",
			"value" = wire_spacing,
			"min" = 1,
			"max" = 12,
			"step" = 1,
			"visible" = wire_layer_profile != "none",
		),
		list(
			"id" = "wire_concentration_percent",
			"label" = "Wire concentration",
			"kind" = "number",
			"group" = "Wire",
			"value" = wire_concentration_percent,
			"min" = 0,
			"max" = 100,
			"step" = 5,
			"visible" = wire_layer_profile != "none",
		),
		list(
			"id" = "minefield_profile",
			"label" = "Minefield",
			"kind" = "select",
			"group" = "Minefields",
			"value" = minefield_profile,
			"options" = build_minefield_profile_options(),
		),
		list(
			"id" = "mine_type",
			"label" = "Mine type",
			"kind" = "select",
			"group" = "Minefields",
			"value" = "[mine_type]",
			"options" = build_type_options(allowed_mine_types),
			"visible" = minefield_profile != "none",
		),
		list(
			"id" = "minefield_offset",
			"label" = "Mine offset",
			"kind" = "number",
			"group" = "Minefields",
			"value" = minefield_offset,
			"min" = 1,
			"max" = 12,
			"step" = 1,
			"visible" = minefield_profile != "none",
		),
		list(
			"id" = "minefield_depth",
			"label" = "Mine depth",
			"kind" = "number",
			"group" = "Minefields",
			"value" = minefield_depth,
			"min" = 0,
			"max" = 8,
			"step" = 1,
			"visible" = minefield_profile != "none",
		),
		list(
			"id" = "minefield_density_percent",
			"label" = "Mine density",
			"kind" = "number",
			"group" = "Minefields",
			"value" = minefield_density_percent,
			"min" = 0,
			"max" = 100,
			"step" = 5,
			"visible" = minefield_profile != "none",
		),
		list(
			"id" = "minefield_seed",
			"label" = "Mine seed",
			"kind" = "number",
			"group" = "Minefields",
			"value" = minefield_seed,
			"min" = 0,
			"max" = 999999,
			"step" = 1,
			"visible" = minefield_profile != "none",
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
			var/list/profile_defaults = get_outpost_profile_layer_defaults(defense_profile_id)
			for(var/default_param_id in list("faction", "turned_on", "sentry_layer_profile", "sentry_type", "sentry_guard_limit", "sentry_rear_limit", "sentry_corner_limit", "extra_defense_layer_profile", "extra_defense_type", "extra_defense_limit", "flag_type", "wire_layer_profile", "wire_offset", "wire_rows", "wire_row_step", "wire_spacing", "wire_concentration_percent", "wire_limit", "minefield_profile", "mine_type", "minefield_offset", "minefield_depth", "minefield_density_percent", "minefield_seed", "mine_limit"))
				new_params[default_param_id] = profile_defaults[default_param_id]

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

		if("faction")
			var/faction_value = resolve_outpost_faction(value, null)
			if(isnull(faction_value))
				return "Selected outpost faction is not allowed."
			new_params[param_id] = faction_value

		if("turned_on")
			new_params[param_id] = GLOB.world_edit_helpers.parse_bool(value)

		if("sentry_layer_profile")
			var/profile_value = resolve_id_option(value, list("none", "guard", "rear", "corners", "guard_corners"), "none")
			if(isnull(profile_value))
				return "Selected sentry layer profile is not allowed."
			new_params[param_id] = profile_value

		if("sentry_type")
			var/path_value = resolve_whitelisted_type(value, allowed_sentry_types, /datum/human_ai_defense/defense/sentry, /datum/human_ai_defense/defense/sentry/uscm)
			if(!path_value)
				return "Selected sentry type is not allowed."
			new_params[param_id] = path_value

		if("extra_defense_layer_profile")
			var/profile_value = resolve_id_option(value, list("none", "rear", "corners"), "none")
			if(isnull(profile_value))
				return "Selected support layer profile is not allowed."
			new_params[param_id] = profile_value

		if("extra_defense_type")
			var/path_value = resolve_whitelisted_type(value, allowed_extra_defense_types, /datum/human_ai_defense/defense, /datum/human_ai_defense/defense/tesla)
			if(!path_value)
				return "Selected support type is not allowed."
			new_params[param_id] = path_value

		if("flag_type")
			var/path_value = resolve_optional_whitelisted_type(value, allowed_flag_types, /datum/human_ai_defense/defense/flag, "none")
			if(isnull(path_value))
				return "Selected flag type is not allowed."
			new_params[param_id] = path_value

		if("wire_layer_profile")
			var/profile_value = resolve_id_option(value, list("none", "openings", "perimeter"), "none")
			if(isnull(profile_value))
				return "Selected wire layer profile is not allowed."
			new_params[param_id] = profile_value

		if("wire_offset")
			new_params[param_id] = resolve_bounded_outpost_number(value, 3, 1, 12)

		if("wire_rows")
			new_params[param_id] = resolve_bounded_outpost_number(value, 1, 0, 8)

		if("wire_row_step")
			new_params[param_id] = resolve_bounded_outpost_number(value, 1, 1, 6)

		if("wire_spacing")
			new_params[param_id] = resolve_bounded_outpost_number(value, 2, 1, 12)

		if("wire_concentration_percent")
			new_params[param_id] = resolve_bounded_outpost_number(value, 70, 0, 100)

		if("minefield_profile")
			var/profile_value = resolve_id_option(value, list("none", "light", "medium", "dense"), "none")
			if(isnull(profile_value))
				return "Selected minefield profile is not allowed."
			new_params[param_id] = profile_value
			switch(profile_value)
				if("light")
					new_params["minefield_density_percent"] = 25
				if("medium")
					new_params["minefield_density_percent"] = 35
				if("dense")
					new_params["minefield_density_percent"] = 50

		if("mine_type")
			var/path_value = resolve_whitelisted_type(value, allowed_mine_types, /datum/human_ai_defense/mine, /datum/human_ai_defense/mine/claymore)
			if(!path_value)
				return "Selected mine type is not allowed."
			new_params[param_id] = path_value

		if("minefield_offset")
			new_params[param_id] = resolve_bounded_outpost_number(value, 3, 1, 12)

		if("minefield_depth")
			new_params[param_id] = resolve_bounded_outpost_number(value, 3, 0, 8)

		if("minefield_density_percent")
			new_params[param_id] = resolve_bounded_outpost_number(value, 35, 0, 100)

		if("minefield_seed")
			new_params[param_id] = resolve_bounded_outpost_number(value, 0, 0, 999999)

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

		if("primary_material_share_percent")
			var/share_percent = clamp(round(text2num("[value]")), 0, 100)
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
	var/raw_primary_share = text2num("[params["primary_material_share_percent"]]")
	var/primary_share = isnum(raw_primary_share) ? clamp(round(raw_primary_share), 0, 100) : 100
	return "defense=[resolve_outpost_defense_profile_id(params["defense_profile"]) || get_default_outpost_defense_profile_id()] layout=[resolve_outpost_layout_id(params["layout_variant"]) || get_default_outpost_layout_id()] width=[get_outpost_opening_width_option_id(params["opening_width"]) || "layout"] perimeter_offset=[params["radius"]] clear=[radius_policy["only_clear_tiles"]] reachable=[radius_policy["only_reachable_tiles"]] windows=[radius_policy["treat_windows_as_blockers"]] shape=[manager?.get_effective_placement_shape() || WORLD_EDIT_SHAPE_POINT] mode=[manager?.get_effective_placement_mode() || "single"] dir=[GLOB.world_edit_helpers.dir_to_label(manager?.get_effective_placement_dir() || NORTH)] primary_material=[params["primary_material_path"]] secondary_material=[params["secondary_material_path"]] primary_share=[primary_share] doors=[GLOB.world_edit_helpers.parse_bool(params["place_barricade_doors"])] primary_door=[params["primary_door_path"] || "follow_material"] secondary_door=[params["secondary_door_path"] || "follow_material"] pattern=[params["barricade_pattern"] || "uniform"]"
