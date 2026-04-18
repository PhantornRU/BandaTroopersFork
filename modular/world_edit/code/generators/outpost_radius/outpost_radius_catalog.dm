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
			"label" = "По профилю",
			"value" = "profile",
			"description" = "Использовать ширину, заданную выбранным вариантом схемы.",
		),
		list(
			"label" = "1 клетка",
			"value" = "narrow",
			"description" = "Оставлять каждый проход шириной в одну клетку.",
		),
		list(
			"label" = "2 клетки",
			"value" = "double",
			"description" = "Оставлять проход шириной в две клетки на каждой выбранной стороне.",
		),
		list(
			"label" = "3 клетки",
			"value" = "wide",
			"description" = "Оставлять проход шириной в три клетки на каждой выбранной стороне.",
		),
		list(
			"label" = "4 клетки",
			"value" = "quad",
			"description" = "Оставлять проход шириной в четыре клетки на каждой выбранной стороне.",
		),
		list(
			"label" = "5 клеток",
			"value" = "broad",
			"description" = "Оставлять проход шириной в пять клеток для более широкого движения.",
		),
	)

/datum/world_edit_generator/outpost_radius/proc/build_guard_mode_options()
	return list(
		list(
			"label" = "По схеме",
			"value" = "layout",
			"description" = "Использовать направления охраны, заданные вариантом схемы.",
		),
		list(
			"label" = "По проходам",
			"value" = "openings",
			"description" = "Охранять только текущие открытые проходы.",
		),
		list(
			"label" = "Все стороны",
			"value" = "all_sides",
			"description" = "Пытаться поставить охрану на все четыре стороны света.",
		),
	)

/datum/world_edit_generator/outpost_radius/proc/build_barricade_pattern_options()
	return list(
		list(
			"label" = "По профилю",
			"value" = "profile",
			"description" = "Использовать схему баррикад, рекомендованную выбранным профилем.",
		),
		list(
			"label" = "Единый",
			"value" = "uniform",
			"description" = "Использовать один тип баррикад по всему периметру.",
		),
		list(
			"label" = "Чередование",
			"value" = "cycle",
			"description" = "Чередовать материалы профиля в каждом слоте.",
		),
		list(
			"label" = "Парами",
			"value" = "paired",
			"description" = "Использовать материалы профиля более широкими парными сегментами.",
		),
	)

/datum/world_edit_generator/outpost_radius/proc/get_layout_opening_dirs(list/layout_profile)
	var/list/opening_dirs = islist(layout_profile) ? layout_profile["opening_dirs"] : null
	if(!islist(opening_dirs))
		return list()
	return opening_dirs.Copy()

/datum/world_edit_generator/outpost_radius/proc/get_layout_guard_dirs(list/layout_profile)
	var/list/guard_dirs = islist(layout_profile) ? layout_profile["guard_dirs"] : null
	if(!islist(guard_dirs) || !length(guard_dirs))
		return get_layout_opening_dirs(layout_profile)
	return guard_dirs.Copy()

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
	return get_layout_opening_width(layout_profile)

/datum/world_edit_generator/outpost_radius/proc/get_layout_expected_opening_count(list/layout_profile)
	var/list/opening_dirs = get_layout_opening_dirs(layout_profile)
	if(!length(opening_dirs))
		return 0
	return length(opening_dirs) * get_layout_opening_slots_per_dir(layout_profile)

/datum/world_edit_generator/outpost_radius/proc/get_default_barricade_pattern(list/family_profile)
	var/pattern = islist(family_profile) ? "[family_profile["default_barricade_pattern"] || "uniform"]" : "uniform"
	switch(pattern)
		if("uniform", "cycle", "paired")
			return pattern
	return "uniform"

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

/datum/world_edit_generator/outpost_radius/proc/get_guard_dirs_for_mode(guard_mode, list/layout_profile)
	switch("[guard_mode]")
		if("openings")
			return get_layout_opening_dirs(layout_profile)
		if("all_sides")
			return list(NORTH, EAST, SOUTH, WEST)
	return get_layout_guard_dirs(layout_profile)

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
		return "нет"

	var/list/labels = list()
	for(var/dir_value as anything in opening_dirs)
		labels += GLOB.world_edit_helpers.dir_to_label(dir_value)
	return jointext(labels, ", ")
