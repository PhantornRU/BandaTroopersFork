/// Генератор постановки баррикад формами point/line/rectangle.
/datum/world_edit_generator/barricade_builder
	var/static/list/barricade_catalog
	var/click_mode_active = FALSE
	var/turf/anchor_turf

/datum/world_edit_generator/barricade_builder/proc/build_catalog()
	var/list/catalog = list()
	for(var/datum/human_ai_defense/barricade/defense_type as anything in subtypesof(/datum/human_ai_defense/barricade))
		if(!defense_type::name)
			continue

		catalog += list(list(
			"name" = defense_type::name,
			"path" = defense_type,
			"description" = defense_type::desc || ""
		))

	var/list/sort_map = list()
	var/list/sort_keys = list()
	for(var/list/entry as anything in catalog)
		var/sort_key = "[entry["name"]]#[entry["path"]]"
		sort_keys += sort_key
		sort_map[sort_key] = entry
	sort_keys = sortList(sort_keys)

	var/list/sorted_catalog = list()
	for(var/sort_key in sort_keys)
		sorted_catalog += list(sort_map[sort_key])
	return sorted_catalog

/datum/world_edit_generator/barricade_builder/proc/get_catalog()
	if(!barricade_catalog)
		barricade_catalog = build_catalog()
	return barricade_catalog

/datum/world_edit_generator/barricade_builder/refresh_ui_state(mob/user, list/current_params)
	barricade_catalog = null

/datum/world_edit_generator/barricade_builder/configure_params(mob/user, list/current_params)
	var/list/new_params = current_params.Copy()
	var/list/catalog = get_catalog()
	if(!length(catalog))
		to_chat(user, SPAN_WARNING("Каталог баррикад пуст, настройка невозможна."))
		return null

	var/list/name_map = list()
	var/list/name_list = list()
	for(var/list/entry as anything in catalog)
		var/base_name = entry["name"]
		var/label = base_name
		if(name_map[label])
			label = "[base_name] ([entry["path"]])"

		name_map[label] = entry["path"]
		name_list += label
	name_list = sortList(name_list)

	var/default_name = name_list[1]
	var/current_path = new_params["barricade_path"]
	for(var/label in name_map)
		if(name_map[label] == current_path)
			default_name = label
			break

	var/chosen_name = tgui_input_list(user, "Выберите тип баррикады.", "World Edit: Баррикады", name_list, default_name)
	if(!chosen_name)
		return null
	new_params["barricade_path"] = name_map[chosen_name]

	var/list/shape_options = list("point", "line", "rectangle")
	var/chosen_shape = tgui_input_list(user, "Выберите форму размещения.", "World Edit: Форма", shape_options, new_params["shape_mode"] || "point")
	if(!chosen_shape)
		return null
	new_params["shape_mode"] = chosen_shape

	var/list/dir_mode_options = list("auto", "fixed")
	var/chosen_dir_mode = tgui_input_list(user, "Выберите режим направления.", "World Edit: DIR", dir_mode_options, new_params["dir_mode"] || "auto")
	if(!chosen_dir_mode)
		return null
	new_params["dir_mode"] = chosen_dir_mode

	if(chosen_dir_mode == "fixed")
		var/list/dir_options = list("North", "East", "South", "West")
		var/chosen_dir_label = tgui_input_list(user, "Выберите фиксированное направление.", "World Edit: DIR", dir_options, world_edit_dir_to_label(new_params["fixed_dir"] || NORTH))
		if(!chosen_dir_label)
			return null
		new_params["fixed_dir"] = world_edit_dir_from_label(chosen_dir_label, NORTH)

	var/replace_choice = tgui_alert(user, "Заменять существующие баррикады с тем же DIR на целевых тайлах?", "World Edit: Замена", list("Да", "Нет"))
	if(!replace_choice)
		return null
	new_params["replace_existing_same_dir"] = replace_choice == "Да"

	var/current_max_tiles = text2num("[new_params["max_tiles"]]") || 40
	var/chosen_max_tiles = tgui_input_number(user, "Лимит тайлов на одну операцию.", "World Edit: Лимит", current_max_tiles, 120, 1)
	if(isnull(chosen_max_tiles))
		return null
	new_params["max_tiles"] = clamp(chosen_max_tiles, 1, 120)
	return new_params

/datum/world_edit_generator/barricade_builder/validate_params(mob/user, list/params)
	var/barricade_path = params["barricade_path"]
	if(istext(barricade_path))
		barricade_path = text2path(barricade_path)
	if(!ispath(barricade_path, /datum/human_ai_defense/barricade))
		return "Выбран неверный тип баррикады."

	var/shape_mode = params["shape_mode"]
	if(!(shape_mode in list("point", "line", "rectangle")))
		return "shape_mode должен быть point, line или rectangle."

	var/dir_mode = params["dir_mode"]
	if(!(dir_mode in list("auto", "fixed")))
		return "dir_mode должен быть auto или fixed."

	var/fixed_dir = text2num("[params["fixed_dir"]]")
	if(!(fixed_dir in GLOB.cardinals))
		return "fixed_dir должен быть одним из NORTH/EAST/SOUTH/WEST."

	var/max_tiles = text2num("[params["max_tiles"]]")
	if(!isnum(max_tiles) || max_tiles < 1 || max_tiles > 120)
		return "max_tiles должен быть в диапазоне 1..120."

	return null

/datum/world_edit_generator/barricade_builder/preview(mob/user, list/params)
	var/datum/world_edit_preview_result/result = new
	result.success = TRUE
	result.message = "Click-режим построения: ЛКМ ставит/строит форму, для line/rectangle первый клик задает якорь, второй завершает форму."
	result.meta["shape_mode"] = params["shape_mode"]
	result.meta["dir_mode"] = params["dir_mode"]
	result.meta["max_tiles"] = params["max_tiles"]
	return result

/datum/world_edit_generator/barricade_builder/apply(mob/user, list/params)
	var/datum/world_edit_apply_result/result = new
	if(!manager)
		result.message = "Менеджер World Edit не инициализирован."
		return result
	if(!manager.acquire_click_intercept("Построение баррикад"))
		result.message = "Перехват клика не активирован."
		return result

	click_mode_active = TRUE
	anchor_turf = null
	result.success = TRUE
	result.center_turf = get_turf(user)
	result.message = "Click-режим баррикад активирован. ЛКМ: постановка/форма, СКМ: сбросить якорь."
	return result

/datum/world_edit_generator/barricade_builder/cleanup_preview(mob/user)
	return

/datum/world_edit_generator/barricade_builder/disable_click_mode()
	click_mode_active = FALSE
	anchor_turf = null
	manager?.clear_preview_images()

/datum/world_edit_generator/barricade_builder/get_runtime_status()
	return list(
		list("label" = "Click-режим", "value" = click_mode_active ? "активен" : "выключен"),
		list("label" = "Якорь", "value" = anchor_turf ? "[anchor_turf.x],[anchor_turf.y],[anchor_turf.z]" : "не выбран"),
	)

/datum/world_edit_generator/barricade_builder/get_ui_fields(list/current_params)
	var/list/catalog = get_catalog()
	var/list/barricade_options = list()
	var/list/label_counts = list()
	for(var/list/entry as anything in catalog)
		var/base_label = "[entry["name"]]"
		var/next_count = (label_counts[base_label] || 0) + 1
		label_counts[base_label] = next_count
		var/label = base_label
		if(next_count > 1)
			label = "[base_label] ([entry["path"]])"

		barricade_options += list(list(
			"label" = label,
			"value" = "[entry["path"]]",
			"description" = entry["description"] || "",
		))

	var/current_dir_mode = current_params["dir_mode"] || "auto"

	var/list/fields = list()
	fields += list(list(
		"id" = "barricade_path",
		"label" = "Тип баррикады",
		"kind" = "select",
		"group" = "Основные",
		"description" = "Тип баррикады выбирается из subtypesof(/datum/human_ai_defense/barricade).",
		"value" = "[current_params["barricade_path"]]",
		"options" = barricade_options
	))
	fields += list(list(
		"id" = "shape_mode",
		"label" = "Форма",
		"kind" = "select",
		"group" = "Геометрия",
		"description" = "Point ставит одну баррикаду, line и rectangle используют 2 клика.",
		"value" = current_params["shape_mode"] || "point",
		"options" = list(
			list("label" = "Точка", "value" = "point"),
			list("label" = "Линия", "value" = "line"),
			list("label" = "Прямоугольник", "value" = "rectangle"),
		),
	))
	fields += list(list(
		"id" = "dir_mode",
		"label" = "DIR режим",
		"kind" = "select",
		"group" = "Направление",
		"description" = "Авто определяет направление по клику/вектору формы.",
		"value" = current_params["dir_mode"] || "auto",
		"options" = list(
			list("label" = "Авто", "value" = "auto"),
			list("label" = "Фиксированный", "value" = "fixed"),
		),
	))
	fields += list(list(
		"id" = "fixed_dir",
		"label" = "Фиксированный DIR",
		"kind" = "select",
		"group" = "Направление",
		"description" = "Используется только при dir_mode = fixed.",
		"value" = world_edit_dir_to_label(text2num("[current_params["fixed_dir"]]") || NORTH),
		"disabled" = current_dir_mode != "fixed",
		"options" = list(
			list("label" = "North", "value" = "North"),
			list("label" = "East", "value" = "East"),
			list("label" = "South", "value" = "South"),
			list("label" = "West", "value" = "West"),
		),
	))
	fields += list(list(
		"id" = "replace_existing_same_dir",
		"label" = "Заменять существующие",
		"kind" = "boolean",
		"group" = "Безопасность",
		"description" = "При включении существующие баррикады с тем же DIR могут удаляться.",
		"validate_hint" = "Перед заменой запрашивается отдельное подтверждение",
		"value" = world_edit_parse_bool(current_params["replace_existing_same_dir"]),
	))
	fields += list(list(
		"id" = "max_tiles",
		"label" = "Лимит тайлов",
		"kind" = "number",
		"group" = "Лимиты",
		"description" = "Максимальное количество тайлов за одно подтвержденное применение.",
		"validate_hint" = "Допустимый диапазон: 1..120",
		"value" = text2num("[current_params["max_tiles"]]") || 40,
		"min" = 1,
		"max" = 120,
		"step" = 1,
	))
	return fields

/datum/world_edit_generator/barricade_builder/set_ui_param(mob/user, list/current_params, param_id, value)
	var/list/new_params = current_params.Copy()
	switch(param_id)
		if("barricade_path")
			var/path_value = ispath(value) ? value : text2path("[value]")
			if(!ispath(path_value, /datum/human_ai_defense/barricade))
				return "Неверный тип баррикады."
			new_params[param_id] = path_value

		if("shape_mode")
			var/text_value = "[value]"
			if(!(text_value in list("point", "line", "rectangle")))
				return "Неверная форма."
			new_params[param_id] = text_value

		if("dir_mode")
			var/text_value = "[value]"
			if(!(text_value in list("auto", "fixed")))
				return "Неверный режим DIR."
			new_params[param_id] = text_value

		if("fixed_dir")
			new_params[param_id] = world_edit_dir_from_label("[value]", NORTH)

		if("replace_existing_same_dir")
			new_params[param_id] = world_edit_parse_bool(value)

		if("max_tiles")
			new_params[param_id] = clamp(text2num("[value]"), 1, 120)

		else
			return ..()

	return new_params

/datum/world_edit_generator/barricade_builder/proc/collect_rectangle_perimeter_entries(turf/start_turf, turf/end_turf, dir_mode, fixed_dir)
	var/list/entries = list()
	if(!start_turf || !end_turf || start_turf.z != end_turf.z)
		return entries

	var/min_x = min(start_turf.x, end_turf.x)
	var/max_x = max(start_turf.x, end_turf.x)
	var/min_y = min(start_turf.y, end_turf.y)
	var/max_y = max(start_turf.y, end_turf.y)
	var/z_level = start_turf.z

	var/use_fixed_dir = dir_mode == "fixed"

	for(var/x in min_x to max_x)
		var/turf/top_turf = locate(x, max_y, z_level)
		if(top_turf)
			entries += list(list("turf" = top_turf, "dir" = use_fixed_dir ? fixed_dir : NORTH))

	for(var/y = max_y - 1, y >= min_y, y--)
		var/turf/right_turf = locate(max_x, y, z_level)
		if(right_turf)
			entries += list(list("turf" = right_turf, "dir" = use_fixed_dir ? fixed_dir : EAST))

	if(max_y > min_y)
		for(var/x = max_x - 1, x >= min_x, x--)
			var/turf/bottom_turf = locate(x, min_y, z_level)
			if(bottom_turf)
				entries += list(list("turf" = bottom_turf, "dir" = use_fixed_dir ? fixed_dir : SOUTH))

	if(max_x > min_x)
		for(var/y = min_y + 1, y <= max_y - 1, y++)
			var/turf/left_turf = locate(min_x, y, z_level)
			if(left_turf)
				entries += list(list("turf" = left_turf, "dir" = use_fixed_dir ? fixed_dir : WEST))

	return entries

/datum/world_edit_generator/barricade_builder/proc/pick_line_auto_dir(turf/start_turf, turf/end_turf, fallback_dir = NORTH)
	if(!start_turf || !end_turf)
		return fallback_dir

	var/delta_x = end_turf.x - start_turf.x
	var/delta_y = end_turf.y - start_turf.y
	if(abs(delta_x) >= abs(delta_y))
		return delta_x >= 0 ? EAST : WEST
	return delta_y >= 0 ? NORTH : SOUTH

/datum/world_edit_generator/barricade_builder/proc/find_barricade_in_dir(turf/target_turf, target_dir)
	for(var/obj/structure/barricade/existing in target_turf)
		if(existing.dir == target_dir)
			return existing
	return null

/datum/world_edit_generator/barricade_builder/proc/collect_shape_entries(mob/user, turf/start_turf, turf/end_turf, list/params)
	var/list/entries = list()
	if(!start_turf || !end_turf || start_turf.z != end_turf.z)
		return entries

	var/shape_mode = params["shape_mode"] || "point"
	var/dir_mode = params["dir_mode"] || "auto"
	var/fixed_dir = text2num("[params["fixed_dir"]]") || NORTH

	if(shape_mode == "point")
		var/point_dir = dir_mode == "fixed" ? fixed_dir : user.dir
		entries += list(list("turf" = end_turf, "dir" = point_dir))
		return entries

	if(shape_mode == "line")
		var/list/line_turfs = world_edit_collect_line_turfs(start_turf, end_turf)
		var/line_dir = dir_mode == "fixed" ? fixed_dir : pick_line_auto_dir(start_turf, end_turf, user.dir)
		for(var/turf/target_turf as anything in line_turfs)
			entries += list(list("turf" = target_turf, "dir" = line_dir))
		return entries

	if(shape_mode == "rectangle")
		return collect_rectangle_perimeter_entries(start_turf, end_turf, dir_mode, fixed_dir)

	return entries

/datum/world_edit_generator/barricade_builder/proc/apply_entries(mob/user, list/entries, list/params, turf/center_turf)
	var/barricade_path = params["barricade_path"]
	if(istext(barricade_path))
		barricade_path = text2path(barricade_path)

	var/replace_existing = world_edit_parse_bool(params["replace_existing_same_dir"])
	var/max_tiles = text2num("[params["max_tiles"]]") || 40
	if(length(entries) > max_tiles)
		to_chat(user, SPAN_WARNING("Операция отменена: превышен лимит тайлов ([max_tiles])."))
		return

	var/replace_count = 0
	var/list/preview_turfs = list()
	for(var/list/entry as anything in entries)
		var/turf/target_turf = entry["turf"]
		var/target_dir = entry["dir"]
		preview_turfs += target_turf
		if(find_barricade_in_dir(target_turf, target_dir))
			replace_count++

	world_edit_apply_turf_preview(manager, preview_turfs)

	if(replace_existing && replace_count > 0)
		var/replace_answer = tgui_alert(user, "Найдено [replace_count] существующих баррикад с тем же DIR. Разрешить замену?", "World Edit: Подтверждение замены", list("Да", "Нет"))
		if(replace_answer != "Да")
			manager?.clear_preview_images()
			return

	var/summary_answer = tgui_alert(user, "Применить построение баррикад? Тайлов: [length(entries)], замена: [replace_count], лимит: [max_tiles].", "World Edit: Подтверждение", list("Подтвердить", "Отмена"))
	if(summary_answer != "Подтвердить")
		manager?.clear_preview_images()
		return

	var/start_ds = world.time
	var/created_count = 0
	var/deleted_count = 0
	for(var/list/entry as anything in entries)
		var/turf/target_turf = entry["turf"]
		var/target_dir = entry["dir"]
		var/obj/structure/barricade/existing = find_barricade_in_dir(target_turf, target_dir)
		if(existing)
			if(!replace_existing)
				continue
			qdel(existing)
			deleted_count++

		if(world_edit_spawn_defense_by_path(target_turf, target_dir, barricade_path, null, FALSE))
			created_count++

	manager?.clear_preview_images()

	var/result_code = created_count > 0 ? "click_place" : "click_noop"
	var/params_short = get_params_short(manager?.current_params || params)
	var/duration_ds = world.time - start_ds
	world_edit_log_operation(
		manager?.holder,
		definition.id,
		definition.required_rights,
		center_turf,
		created_count,
		deleted_count,
		duration_ds,
		result_code,
		params_short
	)
	manager?.add_history_entry(
		definition.id,
		result_code,
		created_count,
		deleted_count,
		center_turf,
		params_short,
		"barrier_shape=[params["shape_mode"]] tiles=[length(entries)]",
		duration_ds * 100
	)

	if(created_count > 0)
		to_chat(user, SPAN_NOTICE("Баррикады установлены: [created_count]. Заменено: [deleted_count]."))
	else
		to_chat(user, SPAN_WARNING("Ни одна баррикада не была установлена."))

/datum/world_edit_generator/barricade_builder/InterceptClickOn(mob/user, params, atom/object)
	if(!click_mode_active)
		return FALSE

	var/list/modifiers = params2list(params)
	if(LAZYACCESS(modifiers, MIDDLE_CLICK))
		anchor_turf = null
		manager?.clear_preview_images()
		to_chat(user, SPAN_NOTICE("Якорь формы сброшен."))
		return TRUE

	if(!LAZYACCESS(modifiers, LEFT_CLICK))
		return TRUE

	var/turf/clicked_turf = get_turf(object)
	if(!clicked_turf)
		return TRUE

	var/shape_mode = manager?.current_params["shape_mode"] || "point"
	if(shape_mode == "point")
		var/list/point_entries = collect_shape_entries(user, clicked_turf, clicked_turf, manager.current_params)
		apply_entries(user, point_entries, manager.current_params, clicked_turf)
		return TRUE

	if(!anchor_turf)
		anchor_turf = clicked_turf
		world_edit_apply_turf_preview(manager, list(anchor_turf))
		to_chat(user, SPAN_NOTICE("Якорь установлен: [anchor_turf.x],[anchor_turf.y],[anchor_turf.z]. Выберите вторую точку формы."))
		return TRUE

	var/turf/start_turf = anchor_turf
	anchor_turf = null
	var/list/entries = collect_shape_entries(user, start_turf, clicked_turf, manager.current_params)
	if(!length(entries))
		manager?.clear_preview_images()
		to_chat(user, SPAN_WARNING("Не удалось построить форму для выбранных тайлов."))
		return TRUE

	apply_entries(user, entries, manager.current_params, clicked_turf)
	return TRUE

/datum/world_edit_generator/barricade_builder/get_apply_confirmation_text(list/params)
	return "Включить click-режим генератора баррикад?"

/datum/world_edit_generator/barricade_builder/get_params_short(list/params)
	var/barricade_path = params["barricade_path"]
	return "barricade=[barricade_path] shape=[params["shape_mode"]] dir_mode=[params["dir_mode"]] replace=[params["replace_existing_same_dir"]] max_tiles=[params["max_tiles"]]"
