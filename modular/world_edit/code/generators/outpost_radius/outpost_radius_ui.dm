/datum/world_edit_generator/outpost_radius/get_ui_fields(list/current_params)
	var/place_sentries = GLOB.world_edit_helpers.parse_bool(current_params["place_sentries"])
	var/family_id = resolve_outpost_family_id(current_params["family"])
	if(!family_id)
		family_id = get_default_outpost_family_id()
	var/layout_id = resolve_outpost_layout_id(current_params["layout_variant"])
	if(!layout_id)
		layout_id = get_default_outpost_layout_id()
	var/list/family_profile = get_outpost_family_profile(family_id)
	var/list/family_mix = islist(family_profile["barricade_mix"]) ? family_profile["barricade_mix"] : list()
	var/default_barricade_path = family_profile["default_barricade_path"] || /datum/human_ai_defense/barricade/metal
	var/default_sentry_path = family_profile["default_sentry_path"] || /datum/human_ai_defense/defense/sentry/uscm
	var/list/faction_options = list()
	for(var/faction in valid_factions)
		faction_options += list(list(
			"label" = "[faction]",
			"value" = faction,
		))

	return list(
		list(
			"id" = "family",
			"label" = "Профиль форпоста",
			"kind" = "select",
			"group" = "Компоновка",
			"description" = "Определяет базовые материалы, турели и схему проходов.",
			"value" = current_params["family"] || family_id,
			"options" = build_family_options(),
		),
		list(
			"id" = "layout_variant",
			"label" = "Вариант схемы",
			"kind" = "select",
			"group" = "Компоновка",
			"description" = "Задаёт, где останутся проходы и как форпост встречает подход к нему.",
			"value" = current_params["layout_variant"] || layout_id,
			"options" = build_layout_options(),
		),
		list(
			"id" = "opening_width",
			"label" = "Ширина проходов",
			"kind" = "select",
			"group" = "Компоновка",
			"description" = "Переопределяет ширину каждого запланированного прохода.",
			"value" = current_params["opening_width"] || "profile",
			"options" = build_opening_width_options(),
		),
		list(
			"id" = "radius",
			"label" = "Отступ периметра",
			"kind" = "number",
			"group" = "Компоновка",
			"description" = "Толщина отступа вокруг выбранного контура перед построением периметра.",
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
			"group" = "Компоновка",
			"description" = "Отступ периметра пропускает плотные клетки. Выбранный контур при этом остаётся допустимым.",
			"value" = isnull(current_params[WORLD_EDIT_RADIUS_POLICY_ONLY_CLEAR_TILES]) ? TRUE : GLOB.world_edit_helpers.parse_bool(current_params[WORLD_EDIT_RADIUS_POLICY_ONLY_CLEAR_TILES]),
		),
		list(
			"id" = WORLD_EDIT_RADIUS_POLICY_ONLY_REACHABLE_TILES,
			"label" = "Только достижимые клетки",
			"kind" = "boolean",
			"group" = "Компоновка",
			"description" = "Периметр и кандидаты для турелей остаются только на клетках, достижимых по соседним свободным тайлам от выбранного контура.",
			"value" = isnull(current_params[WORLD_EDIT_RADIUS_POLICY_ONLY_REACHABLE_TILES]) ? FALSE : GLOB.world_edit_helpers.parse_bool(current_params[WORLD_EDIT_RADIUS_POLICY_ONLY_REACHABLE_TILES]),
		),
		list(
			"id" = WORLD_EDIT_RADIUS_POLICY_WINDOWS_BLOCKERS,
			"label" = "Окна как блокираторы",
			"kind" = "boolean",
			"group" = "Компоновка",
			"description" = "Считает окна препятствиями при проверке чистого и достижимого расширения периметра.",
			"value" = isnull(current_params[WORLD_EDIT_RADIUS_POLICY_WINDOWS_BLOCKERS]) ? TRUE : GLOB.world_edit_helpers.parse_bool(current_params[WORLD_EDIT_RADIUS_POLICY_WINDOWS_BLOCKERS]),
		),
		list(
			"id" = "barricade_path",
			"label" = "Тип баррикады",
			"kind" = "select",
			"group" = "Баррикады",
			"description" = "Разрешённый тип баррикады из human_ai_defense. Профиль использует его как основной материал в смеси.",
			"value" = "[current_params["barricade_path"] || default_barricade_path]",
			"options" = build_type_options(allowed_barricade_types),
			"visible" = FALSE,
		),
		list(
			"id" = "barricade_pattern",
			"label" = "Схема баррикад",
			"kind" = "select",
			"group" = "Баррикады",
			"description" = "Управляет чередованием материалов по периметру.",
			"value" = current_params["barricade_pattern"] || "profile",
			"options" = build_barricade_pattern_options(),
			"visible" = length(family_mix) > 1,
		),
		list(
			"id" = "place_sentries",
			"label" = "Ставить турели у проходов",
			"kind" = "boolean",
			"group" = "Турели",
			"description" = "Добавляет турели с внутренней стороны каждого запланированного прохода.",
			"value" = place_sentries,
		),
		list(
			"id" = "guard_mode",
			"label" = "Охват турелей",
			"kind" = "select",
			"group" = "Турели",
			"description" = "Определяет, охраняют ли турели только проходы, все стороны или следуют варианту схемы.",
			"value" = current_params["guard_mode"] || "layout",
			"options" = build_guard_mode_options(),
			"visible" = place_sentries,
			"disabled" = !place_sentries,
		),
		list(
			"id" = "sentry_path",
			"label" = "Тип турели",
			"kind" = "select",
			"group" = "Турели",
			"description" = "Разрешённый тип турели для внутренних охранных позиций.",
			"value" = "[current_params["sentry_path"] || default_sentry_path]",
			"options" = build_type_options(allowed_sentry_types),
			"visible" = place_sentries,
			"disabled" = !place_sentries,
		),
		list(
			"id" = "faction",
			"label" = "Фракция IFF",
			"kind" = "select",
			"group" = "Турели",
			"description" = "Фракция, которая будет передана турелям human_ai_defense.",
			"value" = current_params["faction"] || FACTION_MARINE,
			"options" = faction_options,
			"visible" = place_sentries,
			"disabled" = !place_sentries,
		),
		list(
			"id" = "turned_on",
			"label" = "Включить турели сразу",
			"kind" = "boolean",
			"group" = "Турели",
			"description" = "Включает турели сразу после установки.",
			"value" = current_params["turned_on"] ? TRUE : FALSE,
			"visible" = place_sentries,
			"disabled" = !place_sentries,
		),
	)

/datum/world_edit_generator/outpost_radius/set_ui_param(mob/user, list/current_params, param_id, value)
	var/list/new_params = current_params.Copy()

	switch(param_id)
		if("family")
			var/family_id = resolve_outpost_family_id(value)
			if(!family_id)
				return "Выбран недопустимый профиль форпоста."
			new_params[param_id] = family_id
			var/list/family_profile = get_outpost_family_profile(family_id)
			new_params["barricade_path"] = family_profile["default_barricade_path"] || /datum/human_ai_defense/barricade/metal
			var/current_sentry_path = resolve_whitelisted_type(new_params["sentry_path"], allowed_sentry_types, /datum/human_ai_defense/defense/sentry)
			if(!current_sentry_path)
				new_params["sentry_path"] = family_profile["default_sentry_path"] || /datum/human_ai_defense/defense/sentry/uscm

		if("layout_variant")
			var/layout_id = resolve_outpost_layout_id(value)
			if(!layout_id)
				return "Выбран недопустимый вариант схемы форпоста."
			new_params[param_id] = layout_id

		if("opening_width")
			var/opening_width = resolve_opening_width(value, get_outpost_layout_profile(resolve_outpost_layout_id(new_params["layout_variant"]) || get_default_outpost_layout_id()))
			if(isnull(opening_width))
				return "Выбрана недопустимая ширина проходов."
			new_params[param_id] = "[value]"

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

		if("barricade_path")
			var/path_value = resolve_whitelisted_type(value, allowed_barricade_types, /datum/human_ai_defense/barricade, get_outpost_family_profile(resolve_outpost_family_id(new_params["family"]) || get_default_outpost_family_id())["default_barricade_path"])
			if(!path_value)
				return "Выбран недопустимый тип баррикады."
			new_params[param_id] = path_value

		if("barricade_pattern")
			var/pattern_value = resolve_barricade_pattern(value, get_outpost_family_profile(resolve_outpost_family_id(new_params["family"]) || get_default_outpost_family_id()))
			if(isnull(pattern_value))
				return "Выбрана недопустимая схема баррикад."
			new_params[param_id] = "[value]"

		if("place_sentries")
			new_params[param_id] = GLOB.world_edit_helpers.parse_bool(value)

		if("guard_mode")
			var/guard_mode = resolve_guard_mode(value)
			if(isnull(guard_mode))
				return "Выбран недопустимый режим охвата турелей."
			new_params[param_id] = "[value]"

		if("sentry_path")
			var/path_value = resolve_whitelisted_type(value, allowed_sentry_types, /datum/human_ai_defense/defense/sentry, get_outpost_family_profile(resolve_outpost_family_id(new_params["family"]) || get_default_outpost_family_id())["default_sentry_path"])
			if(!path_value)
				return "Выбран недопустимый тип турели."
			new_params[param_id] = path_value

		if("faction")
			if(!("[value]" in valid_factions))
				return "Выбрана недопустимая фракция для турели."
			new_params[param_id] = "[value]"

		if("turned_on")
			new_params[param_id] = GLOB.world_edit_helpers.parse_bool(value)

		else
			return ..()

	return new_params

/datum/world_edit_generator/outpost_radius/get_apply_confirmation_text(list/params)
	var/family_id = resolve_outpost_family_id(params["family"])
	if(!family_id)
		family_id = get_default_outpost_family_id()
	var/layout_id = resolve_outpost_layout_id(params["layout_variant"])
	if(!layout_id)
		layout_id = get_default_outpost_layout_id()
	var/list/family_profile = get_outpost_family_profile(family_id)
	var/list/layout_profile = get_outpost_layout_profile(layout_id)
	return "Применить профиль '[family_profile["label"] || "Форпост"] / [layout_profile["label"] || "Крест"]' с отступом периметра [params["radius"]]?"

/datum/world_edit_generator/outpost_radius/get_params_short(list/params)
	var/list/radius_policy = GLOB.world_edit_helpers.get_world_edit_radius_policy(params)
	return "family=[params["family"] || get_default_outpost_family_id()] layout=[params["layout_variant"] || get_default_outpost_layout_id()] width=[params["opening_width"] || "profile"] perimeter_offset=[params["radius"]] clear=[radius_policy["only_clear_tiles"]] reachable=[radius_policy["only_reachable_tiles"]] windows=[radius_policy["treat_windows_as_blockers"]] shape=[manager?.get_effective_placement_shape() || WORLD_EDIT_SHAPE_POINT] mode=[manager?.get_effective_placement_mode() || "single"] dir=[GLOB.world_edit_helpers.dir_to_label(manager?.get_effective_placement_dir() || NORTH)] barricade=[params["barricade_path"]] barricade_pattern=[params["barricade_pattern"] || "profile"] sentries=[params["place_sentries"]] guard_mode=[params["guard_mode"] || "layout"] sentry_type=[params["sentry_path"]]"
