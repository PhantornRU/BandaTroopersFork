/datum/world_edit_generator/defense_grid
	var/static/list/valid_factions = list(FACTION_MARINE, FACTION_UA_REBEL, FACTION_UPP, FACTION_CANC, FACTION_WY, FACTION_FREELANCER, FACTION_TWE, FACTION_TWE_REBEL, FACTION_MERCENARY)
	var/static/list/defense_catalog

/datum/world_edit_generator/defense_grid/proc/get_defense_catalog(force_refresh = FALSE)
	if(force_refresh || !defense_catalog)
		defense_catalog = GLOB.world_edit_legacy.world_edit_build_defense_catalog()
	return defense_catalog

/datum/world_edit_generator/defense_grid/refresh_ui_state(mob/user, list/current_params)
	defense_catalog = null

/datum/world_edit_generator/defense_grid/proc/find_category_for_path(list/catalog, defense_path, default_category)
	if(!defense_path)
		return default_category

	if(istext(defense_path))
		defense_path = text2path(defense_path)

	for(var/category in catalog)
		for(var/list/entry as anything in catalog[category])
			if(entry["path"] == defense_path)
				return category

	return default_category

/datum/world_edit_generator/defense_grid/proc/find_entry_for_path(list/catalog, defense_path)
	if(istext(defense_path))
		defense_path = text2path(defense_path)
	if(!ispath(defense_path, /datum/human_ai_defense))
		return null

	for(var/category in catalog)
		for(var/list/entry as anything in catalog[category])
			if(entry["path"] == defense_path)
				return entry

	return null

/datum/world_edit_generator/defense_grid/proc/build_entry_choices(list/entries)
	var/list/choice_map = list()
	var/list/choice_names = list()

	for(var/list/entry as anything in entries)
		var/base_name = entry["name"]
		var/label = base_name
		if(choice_map[label])
			label = "[base_name] ([entry["path"]])"
		choice_map[label] = entry
		choice_names += label

	return list(
		"choice_map" = choice_map,
		"choice_names" = sortList(choice_names)
	)

/datum/world_edit_generator/defense_grid/proc/build_flat_options(list/catalog)
	var/list/options = list()
	var/list/base_label_counts = list()
	var/list/categories = list()
	for(var/category in catalog)
		categories += category
	categories = sortList(categories)

	for(var/category in categories)
		var/list/entries = catalog[category]
		for(var/list/entry as anything in entries)
			var/path_value = "[entry["path"]]"
			var/base_label = "[entry["name"]] ([category])"
			var/next_count = (base_label_counts[base_label] || 0) + 1
			base_label_counts[base_label] = next_count
			var/label = base_label
			if(next_count > 1)
				label = "[base_label] ([entry["path"]])"

			options += list(list(
				"label" = label,
				"value" = path_value,
				"description" = entry["description"] || "",
			))

	return options

/datum/world_edit_generator/defense_grid/proc/get_selected_entry(list/current_params)
	var/list/catalog = get_defense_catalog()
	var/defense_path = current_params["defense_path"]
	return find_entry_for_path(catalog, defense_path)

/datum/world_edit_generator/defense_grid/configure_params(mob/user, list/current_params)
	var/list/new_params = current_params.Copy()
	var/list/catalog = get_defense_catalog()

	if(!length(catalog))
		to_chat(user, SPAN_WARNING("Каталог обороны пуст, настройка невозможна."))
		return null

	var/list/categories = list()
	for(var/category in catalog)
		categories += category
	categories = sortList(categories)
	if(!length(categories))
		to_chat(user, SPAN_WARNING("Категории обороны не найдены."))
		return null

	var/current_path = new_params["defense_path"]
	var/default_category = categories[1]
	var/current_category = find_category_for_path(catalog, current_path, default_category)
	var/chosen_category = tgui_input_list(user, "Выберите категорию обороны.", "World Edit: Оборона", categories, current_category)
	if(!chosen_category)
		return null

	var/list/entries = catalog[chosen_category]
	var/list/choice_data = build_entry_choices(entries)
	var/list/choice_map = choice_data["choice_map"]
	var/list/choice_names = choice_data["choice_names"]
	if(!length(choice_names))
		to_chat(user, SPAN_WARNING("В выбранной категории нет объектов обороны."))
		return null

	var/default_choice = choice_names[1]
	if(current_path)
		for(var/label in choice_map)
			var/list/entry = choice_map[label]
			if(entry["path"] == current_path)
				default_choice = label
				break

	var/chosen_label = tgui_input_list(user, "Выберите объект обороны.", "World Edit: Оборона", choice_names, default_choice)
	if(!chosen_label)
		return null

	var/list/chosen_entry = choice_map[chosen_label]
	new_params["defense_path"] = chosen_entry["path"]
	new_params["defense_name"] = chosen_entry["name"]

	if(chosen_entry["uses_faction"])
		var/current_faction = new_params["faction"] || FACTION_MARINE
		var/chosen_faction = tgui_input_list(user, "Выберите фракцию IFF.", "World Edit: Фракция", valid_factions, current_faction)
		if(!chosen_faction)
			return null
		new_params["faction"] = chosen_faction
	else
		new_params["faction"] = null

	if(chosen_entry["uses_turned_on"])
		var/power_choice = tgui_alert(user, "Включать объект сразу после установки?", "World Edit: Питание", list("Да", "Нет"))
		if(!power_choice)
			return null
		new_params["turned_on"] = power_choice == "Да"
	else
		new_params["turned_on"] = FALSE

	var/list/dir_options = list("Default", "North", "East", "South", "West")
	var/current_direction = new_params["placement_direction"] || "Default"
	var/chosen_direction = tgui_input_list(user, "Выберите направление установки.", "World Edit: Направление", dir_options, current_direction)
	if(!chosen_direction)
		return null
	new_params["placement_direction"] = chosen_direction

	var/current_batch_count = text2num("[new_params["batch_count"]]") || 1
	var/new_batch_count = tgui_input_number(user, "Количество объектов для пакетной установки.", "World Edit: Batch Count", current_batch_count, 50, 1)
	if(isnull(new_batch_count))
		return null
	new_params["batch_count"] = clamp(new_batch_count, 1, 50)

	var/current_batch_step = text2num("[new_params["batch_step"]]") || 1
	var/new_batch_step = tgui_input_number(user, "Шаг между объектами (в тайлах).", "World Edit: Batch Step", current_batch_step, 7, 1)
	if(isnull(new_batch_step))
		return null
	new_params["batch_step"] = clamp(new_batch_step, 1, 7)

	return new_params

/datum/world_edit_generator/defense_grid/get_ui_fields(list/current_params)
	var/list/catalog = get_defense_catalog()
	var/list/defense_options = build_flat_options(catalog)
	var/list/selected_entry = get_selected_entry(current_params)
	var/uses_faction = selected_entry ? (selected_entry["uses_faction"] ? TRUE : FALSE) : FALSE
	var/uses_turned_on = selected_entry ? (selected_entry["uses_turned_on"] ? TRUE : FALSE) : FALSE
	var/selected_path_value = selected_entry ? "[selected_entry["path"]]" : "[current_params["defense_path"] || ""]"

	var/list/faction_options = list()
	for(var/faction in valid_factions)
		faction_options += list(list(
			"label" = "[faction]",
			"value" = faction,
		))

	var/list/direction_options = list(
		list("label" = "Default", "value" = "Default"),
		list("label" = "North", "value" = "North"),
		list("label" = "East", "value" = "East"),
		list("label" = "South", "value" = "South"),
		list("label" = "West", "value" = "West"),
	)

	return list(
		list(
			"id" = "defense_path",
			"label" = "Тип объекта обороны",
			"kind" = "select",
			"group" = "Основные",
			"description" = "Каталог объектов строится через subtypesof(/datum/human_ai_defense).",
			"value" = selected_path_value,
			"options" = defense_options,
		),
		list(
			"id" = "faction",
			"label" = "Фракция IFF",
			"kind" = "select",
			"group" = "Параметры объекта",
			"description" = "Используется только для объектов с поддержкой faction.",
			"value" = current_params["faction"] || FACTION_MARINE,
			"options" = faction_options,
			"visible" = uses_faction,
			"disabled" = !uses_faction,
		),
		list(
			"id" = "turned_on",
			"label" = "Включать после установки",
			"kind" = "boolean",
			"group" = "Параметры объекта",
			"description" = "Используется только для объектов с управляемым питанием.",
			"value" = current_params["turned_on"] ? TRUE : FALSE,
			"visible" = uses_turned_on,
			"disabled" = !uses_turned_on,
		),
		list(
			"id" = "placement_direction",
			"label" = "Направление размещения",
			"kind" = "select",
			"group" = "Размещение",
			"description" = "Направление пакетной установки от текущего тайла.",
			"value" = current_params["placement_direction"] || "Default",
			"options" = direction_options,
		),
		list(
			"id" = "batch_count",
			"label" = "Количество",
			"kind" = "number",
			"group" = "Размещение",
			"validate_hint" = "Допустимый диапазон: 1..50",
			"value" = text2num("[current_params["batch_count"]]") || 1,
			"min" = 1,
			"max" = 50,
			"step" = 1,
		),
		list(
			"id" = "batch_step",
			"label" = "Шаг",
			"kind" = "number",
			"group" = "Размещение",
			"validate_hint" = "Допустимый диапазон: 1..7",
			"value" = text2num("[current_params["batch_step"]]") || 1,
			"min" = 1,
			"max" = 7,
			"step" = 1,
		),
	)

/datum/world_edit_generator/defense_grid/set_ui_param(mob/user, list/current_params, param_id, value)
	var/list/new_params = current_params.Copy()
	var/list/catalog = get_defense_catalog()

	switch(param_id)
		if("defense_path")
			var/path_value = ispath(value) ? value : text2path("[value]")
			if(!ispath(path_value, /datum/human_ai_defense))
				return "Выбран неверный путь оборонительного объекта."

			var/list/entry = find_entry_for_path(catalog, path_value)
			if(!entry)
				return "Выбранный объект обороны отсутствует в каталоге."

			new_params["defense_path"] = path_value
			new_params["defense_name"] = entry["name"]
			if(!(entry["uses_faction"] ? TRUE : FALSE))
				new_params["faction"] = null
			else if(!new_params["faction"])
				new_params["faction"] = FACTION_MARINE

			if(!(entry["uses_turned_on"] ? TRUE : FALSE))
				new_params["turned_on"] = FALSE

		if("faction")
			if(!("[value]" in valid_factions))
				return "Выбрана неверная фракция IFF."
			new_params["faction"] = "[value]"

		if("turned_on")
			new_params["turned_on"] = GLOB.world_edit_helpers.parse_bool(value)

		if("placement_direction")
			var/direction_text = "[value]"
			if(!(direction_text in list("Default", "North", "East", "South", "West")))
				return "Неверное направление установки."
			new_params["placement_direction"] = direction_text

		if("batch_count")
			new_params["batch_count"] = clamp(text2num("[value]"), 1, 50)

		if("batch_step")
			new_params["batch_step"] = clamp(text2num("[value]"), 1, 7)

		else
			return ..()

	return new_params

/datum/world_edit_generator/defense_grid/validate_params(mob/user, list/params)
	if(!get_turf(user))
		return "Не удалось определить стартовый тайл."

	var/defense_path = params["defense_path"]
	if(!ispath(defense_path, /datum/human_ai_defense))
		return "Выбран неверный путь оборонительного объекта."

	var/batch_count = text2num("[params["batch_count"]]")
	if(!isnum(batch_count) || batch_count < 1 || batch_count > 50)
		return "batch_count должен быть в диапазоне 1..50."

	var/batch_step = text2num("[params["batch_step"]]")
	if(!isnum(batch_step) || batch_step < 1 || batch_step > 7)
		return "batch_step должен быть в диапазоне 1..7."

	return null

/datum/world_edit_generator/defense_grid/proc/collect_target_turfs(mob/user, list/params)
	var/list/targets = list()
	var/turf/start_turf = get_turf(user)
	if(!start_turf)
		return targets

	var/batch_count = text2num("[params["batch_count"]]") || 1
	var/batch_step = text2num("[params["batch_step"]]") || 1
	var/placement_dir = GLOB.world_edit_helpers.dir_from_label(params["placement_direction"], user.dir)

	var/turf/current_turf = start_turf
	targets += current_turf
	for(var/i = 2, i <= batch_count, i++)
		current_turf = GLOB.world_edit_helpers.step_turf(current_turf, placement_dir, batch_step)
		if(!current_turf)
			break
		targets += current_turf

	return targets

/datum/world_edit_generator/defense_grid/preview(mob/user, list/params)
	var/datum/world_edit_preview_result/result = new
	var/list/target_turfs = collect_target_turfs(user, params)
	if(!length(target_turfs))
		result.message = "Не найдено ни одного тайла для установки."
		return result

	result.preview_images = GLOB.world_edit_helpers.build_turf_preview_images(target_turfs)
	result.success = TRUE
	result.meta["target_count"] = length(target_turfs)
	result.message = "Предпросмотр готов: планируется установка [length(target_turfs)] объектов."
	return result

/datum/world_edit_generator/defense_grid/apply(mob/user, list/params)
	var/datum/world_edit_apply_result/result = new
	var/list/target_turfs = collect_target_turfs(user, params)
	if(!length(target_turfs))
		result.message = "Не найдено ни одного тайла для установки."
		return result

	var/placement_dir = GLOB.world_edit_helpers.dir_from_label(params["placement_direction"], user.dir)
	var/defense_path = params["defense_path"]
	var/faction = params["faction"]
	var/turned_on = params["turned_on"] ? TRUE : FALSE
	var/created_count = 0

	for(var/turf/target_turf as anything in target_turfs)
		if(GLOB.world_edit_legacy.world_edit_spawn_defense_by_path(target_turf, placement_dir, defense_path, faction, turned_on))
			created_count++

	result.success = created_count > 0
	result.created_count = created_count
	result.center_turf = get_turf(user)
	result.meta["target_count"] = length(target_turfs)
	if(result.success)
		result.message = "Установлено объектов обороны: [created_count]."
	else
		result.message = "Не удалось установить объекты обороны."
	return result

/datum/world_edit_generator/defense_grid/get_apply_confirmation_text(list/params)
	return "Применить пакетную установку '[params["defense_name"] || params["defense_path"]]'?"
