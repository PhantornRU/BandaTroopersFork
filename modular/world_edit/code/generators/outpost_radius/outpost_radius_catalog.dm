/datum/world_edit_generator/outpost_radius/proc/build_type_options(list/type_list)
	var/list/options = list()
	for(var/datum/human_ai_defense/type_path as anything in type_list)
		options += list(list(
			"label" = type_path::name || "[type_path]",
			"value" = "[type_path]",
			"description" = type_path::desc || "",
		))
	return options

/datum/world_edit_generator/outpost_radius/proc/get_default_outpost_family_id()
	return "metal_perimeter"

/datum/world_edit_generator/outpost_radius/proc/get_default_outpost_layout_id()
	return "crossroads"

/datum/world_edit_generator/outpost_radius/proc/get_outpost_effective_placement_dir(list/placement_context = null)
	var/dir_to_use = islist(placement_context) ? placement_context["direction"] : null
	if(!GLOB.world_edit_helpers.is_cardinal_dir(dir_to_use))
		dir_to_use = manager?.get_effective_placement_dir()
	if(!GLOB.world_edit_helpers.is_cardinal_dir(dir_to_use))
		dir_to_use = get_default_placement_direction()
	return dir_to_use

/datum/world_edit_generator/outpost_radius/proc/resolve_relative_outpost_dir(dir_value, placement_dir)
	if(GLOB.world_edit_helpers.is_cardinal_dir(dir_value))
		return dir_value

	switch(lowertext("[dir_value]"))
		if("forward")
			return placement_dir
		if("back")
			return get_cardinal_opposite_dir(placement_dir)
		if("left")
			return turn(placement_dir, 90)
		if("right")
			return turn(placement_dir, -90)

	return null

/datum/world_edit_generator/outpost_radius/proc/resolve_outpost_dir_list(raw_dir_list, placement_dir)
	var/list/resolved_dirs = list()
	var/list/seen_lookup = list()
	if(!islist(raw_dir_list) || !length(raw_dir_list))
		return resolved_dirs

	for(var/dir_value as anything in raw_dir_list)
		var/resolved_dir = resolve_relative_outpost_dir(dir_value, placement_dir)
		if(!GLOB.world_edit_helpers.is_cardinal_dir(resolved_dir) || seen_lookup["[resolved_dir]"])
			continue
		seen_lookup["[resolved_dir]"] = TRUE
		resolved_dirs += resolved_dir

	return resolved_dirs

/datum/world_edit_generator/outpost_radius/proc/resolve_outpost_family_id(value)
	if(isnull(value) || !length("[value]") || "[value]" == "null")
		return get_default_outpost_family_id()

	var/family_id = "[value]"
	if(family_id in outpost_family_profiles)
		return family_id
	return null

/datum/world_edit_generator/outpost_radius/proc/get_outpost_family_profile(family_id)
	if(!(family_id in outpost_family_profiles))
		return null
	return outpost_family_profiles[family_id]

/datum/world_edit_generator/outpost_radius/proc/resolve_outpost_layout_id(value)
	if(isnull(value) || !length("[value]") || "[value]" == "null")
		return get_default_outpost_layout_id()

	var/layout_id = "[value]"
	if(layout_id in outpost_layout_aliases)
		layout_id = outpost_layout_aliases[layout_id]
	if(layout_id in outpost_layout_profiles)
		return layout_id
	return null

/datum/world_edit_generator/outpost_radius/proc/get_outpost_layout_profile(layout_id)
	if(!(layout_id in outpost_layout_profiles))
		return null
	return outpost_layout_profiles[layout_id]

/datum/world_edit_generator/outpost_radius/proc/build_family_options()
	var/list/options = list()
	for(var/family_id in outpost_family_profiles)
		var/list/profile = outpost_family_profiles[family_id]
		options += list(list(
			"label" = profile["label"] || family_id,
			"value" = family_id,
			"description" = profile["description"] || "",
		))
	return options

/datum/world_edit_generator/outpost_radius/proc/build_layout_options()
	var/list/options = list()
	for(var/layout_id in outpost_layout_profiles)
		var/list/profile = outpost_layout_profiles[layout_id]
		options += list(list(
			"label" = profile["label"] || layout_id,
			"value" = layout_id,
			"description" = profile["description"] || "",
		))
	return options

/datum/world_edit_generator/outpost_radius/proc/build_opening_width_options()
	return list(
		list(
			"label" = "По схеме",
			"value" = "profile",
			"description" = "Использовать ширину проходов, рекомендованную выбранной схемой.",
		),
		list(
			"label" = "1 клетка",
			"value" = "narrow",
			"description" = "Каждый проход шириной в одну клетку.",
		),
		list(
			"label" = "2 клетки",
			"value" = "double",
			"description" = "Каждый проход шириной в две клетки.",
		),
		list(
			"label" = "3 клетки",
			"value" = "wide",
			"description" = "Каждый проход шириной в три клетки.",
		),
		list(
			"label" = "4 клетки",
			"value" = "quad",
			"description" = "Каждый проход шириной в четыре клетки.",
		),
		list(
			"label" = "5 клеток",
			"value" = "broad",
			"description" = "Каждый проход шириной в пять клеток.",
		),
	)

/datum/world_edit_generator/outpost_radius/proc/build_guard_mode_options()
	return list(
		list(
			"label" = "По схеме",
			"value" = "layout",
			"description" = "Использовать направления охраны, заданные схемой.",
		),
		list(
			"label" = "Только проходы",
			"value" = "openings",
			"description" = "Охранять только открытые направления входа.",
		),
		list(
			"label" = "Все стороны",
			"value" = "all_sides",
			"description" = "Пытаться покрыть все четыре стороны.",
		),
	)

/datum/world_edit_generator/outpost_radius/proc/build_sentry_profile_options()
	return list(
		list(
			"label" = "По профилю",
			"value" = "profile",
			"description" = "Использовать стиль турелей, рекомендованный выбранным профилем.",
		),
		list(
			"label" = "Без турелей",
			"value" = "none",
			"description" = "Не ставить турели даже при включенном турельном слое.",
		),
		list(
			"label" = "Легкое прикрытие",
			"value" = "light_cover",
			"description" = "Ставить не больше одной-двух турелей на самые важные дуги.",
		),
		list(
			"label" = "Охрана входа",
			"value" = "entry_guard",
			"description" = "Предпочитать турели рядом с самим проходом.",
		),
		list(
			"label" = "Внутренняя охрана",
			"value" = "inner_guard",
			"description" = "Предпочитать более глубокие внутренние позиции турелей.",
		),
		list(
			"label" = "Перекрестный огонь",
			"value" = "crossfire",
			"description" = "Предпочитать меньшее число внутренних осей с перекрывающимся огнем.",
		),
	)

/datum/world_edit_generator/outpost_radius/proc/build_barricade_pattern_options()
	return list(
		list(
			"label" = "По профилю",
			"value" = "profile",
			"description" = "Использовать раскладку баррикад, рекомендованную выбранным профилем.",
		),
		list(
			"label" = "Равномерно",
			"value" = "uniform",
			"description" = "Использовать один материал баррикад по всему контуру.",
		),
		list(
			"label" = "Чередование",
			"value" = "cycle",
			"description" = "Чередовать материалы из выбранного профиля по каждому слоту.",
		),
		list(
			"label" = "Парные секции",
			"value" = "paired",
			"description" = "Чередовать материалы профиля более широкими парными секциями.",
		),
	)

/datum/world_edit_generator/outpost_radius/proc/get_layout_opening_dirs(list/layout_profile, placement_dir = NORTH)
	var/list/opening_dirs = islist(layout_profile) ? layout_profile["opening_dirs"] : null
	return resolve_outpost_dir_list(opening_dirs, placement_dir)

/datum/world_edit_generator/outpost_radius/proc/get_layout_guard_dirs(list/layout_profile, placement_dir = NORTH)
	var/list/guard_dirs = islist(layout_profile) ? layout_profile["guard_dirs"] : null
	if(!islist(guard_dirs) || !length(guard_dirs))
		return get_layout_opening_dirs(layout_profile, placement_dir)
	return resolve_outpost_dir_list(guard_dirs, placement_dir)

/datum/world_edit_generator/outpost_radius/proc/get_layout_opening_width(list/layout_profile)
	var/opening_width = 0
	if(islist(layout_profile))
		opening_width = text2num("[layout_profile["opening_width"]]")
	if(isnum(opening_width) && opening_width >= 1)
		return clamp(round(opening_width), 1, 5)

	var/opening_half_width = 0
	if(islist(layout_profile))
		opening_half_width = text2num("[layout_profile["opening_half_width"]]")
	if(!isnum(opening_half_width))
		return 1
	return clamp((round(opening_half_width) * 2) + 1, 1, 5)

/datum/world_edit_generator/outpost_radius/proc/get_layout_opening_half_width(list/layout_profile)
	return max(round((get_layout_opening_width(layout_profile) - 1) / 2), 0)

/datum/world_edit_generator/outpost_radius/proc/get_layout_opening_slots_per_dir(list/layout_profile)
	var/slots_per_dir = islist(layout_profile) ? text2num("[layout_profile["opening_slots_per_dir"]]") : null
	if(isnum(slots_per_dir) && slots_per_dir >= 1)
		return clamp(round(slots_per_dir), 1, 2)
	return 1

/datum/world_edit_generator/outpost_radius/proc/get_layout_opening_slot_mode(list/layout_profile)
	var/slot_mode = lowertext("[islist(layout_profile) ? (layout_profile["opening_slot_mode"] || "centered") : "centered"]")
	switch(slot_mode)
		if("centered", "split_pair")
			return slot_mode
	return "centered"

/datum/world_edit_generator/outpost_radius/proc/get_layout_total_opening_tiles_per_dir(list/layout_profile)
	return get_layout_opening_slots_per_dir(layout_profile) * get_layout_opening_width(layout_profile)

/datum/world_edit_generator/outpost_radius/proc/get_layout_expected_opening_count(list/layout_profile, placement_dir = NORTH)
	var/list/opening_dirs = get_layout_opening_dirs(layout_profile, placement_dir)
	if(!length(opening_dirs))
		return 0
	return length(opening_dirs) * get_layout_total_opening_tiles_per_dir(layout_profile)

/datum/world_edit_generator/outpost_radius/proc/get_default_barricade_pattern(list/family_profile)
	var/pattern = islist(family_profile) ? "[family_profile["default_barricade_pattern"] || "uniform"]" : "uniform"
	switch(pattern)
		if("uniform", "cycle", "paired")
			return pattern
	return "uniform"

/datum/world_edit_generator/outpost_radius/proc/get_default_sentry_profile(list/family_profile)
	var/sentry_profile = lowertext("[islist(family_profile) ? (family_profile["default_sentry_profile"] || "entry_guard") : "entry_guard"]")
	switch(sentry_profile)
		if("none", "light_cover", "entry_guard", "inner_guard", "crossfire")
			return sentry_profile
	return "entry_guard"

/datum/world_edit_generator/outpost_radius/proc/resolve_barricade_pattern(value, list/family_profile)
	if(isnull(value) || !length("[value]") || "[value]" == "null")
		return get_default_barricade_pattern(family_profile)

	var/pattern_id = "[value]"
	if(pattern_id == "profile")
		return get_default_barricade_pattern(family_profile)

	switch(pattern_id)
		if("uniform", "cycle", "paired")
			return pattern_id
	return null

/datum/world_edit_generator/outpost_radius/proc/resolve_guard_mode(value)
	if(isnull(value) || !length("[value]") || "[value]" == "null")
		return "layout"

	var/guard_mode = "[value]"
	if(guard_mode == "profile")
		return "layout"

	switch(guard_mode)
		if("layout", "openings", "all_sides")
			return guard_mode
	return null

/datum/world_edit_generator/outpost_radius/proc/resolve_sentry_profile(value, list/family_profile)
	if(isnull(value) || !length("[value]") || "[value]" == "null")
		return get_default_sentry_profile(family_profile)

	var/sentry_profile = lowertext("[value]")
	if(sentry_profile == "profile")
		return get_default_sentry_profile(family_profile)

	switch(sentry_profile)
		if("none", "light_cover", "entry_guard", "inner_guard", "crossfire")
			return sentry_profile
	return null

/datum/world_edit_generator/outpost_radius/proc/get_guard_dirs_for_mode(guard_mode, list/layout_profile, placement_dir = NORTH)
	switch("[guard_mode]")
		if("openings")
			return get_layout_opening_dirs(layout_profile, placement_dir)
		if("all_sides")
			return list(NORTH, EAST, SOUTH, WEST)
	return get_layout_guard_dirs(layout_profile, placement_dir)

/datum/world_edit_generator/outpost_radius/proc/resolve_opening_width(value, list/layout_profile)
	var/default_width = get_layout_opening_width(layout_profile)
	if(isnull(value) || !length("[value]") || "[value]" == "null")
		return default_width

	switch("[value]")
		if("profile")
			return default_width
		if("narrow")
			return 1
		if("double")
			return 2
		if("wide")
			return 3
		if("quad")
			return 4
		if("broad")
			return 5
	return null

/datum/world_edit_generator/outpost_radius/proc/resolve_whitelisted_type(value, list/type_list, expected_root, default_value = null)
	if(isnull(value) || !length("[value]") || "[value]" == "null")
		if(ispath(default_value, expected_root) && (default_value in type_list))
			return default_value
		return null

	var/path_value = ispath(value) ? value : text2path("[value]")
	if(!ispath(path_value, expected_root))
		return null
	if(!(path_value in type_list))
		return null
	return path_value

/datum/world_edit_generator/outpost_radius/proc/build_barricade_cycle(list/family_profile, selected_barricade_path)
	var/list/cycle = list()
	if(ispath(selected_barricade_path, /datum/human_ai_defense/barricade))
		cycle += selected_barricade_path

	var/list/family_mix = islist(family_profile) ? family_profile["barricade_mix"] : null
	if(islist(family_mix))
		for(var/datum/human_ai_defense/barricade/type_path as anything in family_mix)
			if(type_path in cycle)
				continue
			cycle += type_path

	if(!length(cycle))
		var/default_barricade_path = islist(family_profile) ? family_profile["default_barricade_path"] : null
		if(ispath(default_barricade_path, /datum/human_ai_defense/barricade))
			cycle += default_barricade_path

	return cycle

/datum/world_edit_generator/outpost_radius/proc/format_opening_dirs(list/opening_dirs)
	if(!islist(opening_dirs) || !length(opening_dirs))
		return "none"

	var/list/labels = list()
	for(var/dir_value as anything in opening_dirs)
		labels += GLOB.world_edit_helpers.dir_to_label(dir_value)
	return jointext(labels, ", ")
