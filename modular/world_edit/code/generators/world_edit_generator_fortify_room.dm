/datum/world_edit_generator/fortify_room
	requires_preview_before_apply = TRUE
	var/list/last_preview_data

/datum/world_edit_generator/fortify_room/configure_params(mob/user, list/current_params)
	var/list/new_params = current_params.Copy()
	var/list/presets = GLOB.world_edit_legacy.world_edit_get_fortify_level_presets()
	var/list/preset_names = list()
	for(var/preset_name in presets)
		preset_names += preset_name
	preset_names = sortList(preset_names)

	var/current_level = new_params["fortification_level"] || "Metal"
	var/chosen_level = tgui_input_list(user, "Выберите уровень укрепления.", "World Edit: Укрепление", preset_names, current_level)
	if(!chosen_level)
		return null
	new_params["fortification_level"] = chosen_level

	var/current_limit = text2num("[new_params["tile_scan_limit"]]") || 195
	var/new_limit = tgui_input_number(user, "Лимит скана комнаты (рекомендуется не выше 195).", "World Edit: Лимит скана", current_limit, 195, 1)
	if(isnull(new_limit))
		return null
	new_params["tile_scan_limit"] = clamp(new_limit, 1, 195)

	var/current_radius = text2num("[new_params["scan_radius"]]") || 12
	var/new_radius = tgui_input_number(user, "Радиус распространения от текущего тайла (в тайлах).", "World Edit: Радиус", current_radius, 30, 1)
	if(isnull(new_radius))
		return null
	new_params["scan_radius"] = clamp(new_radius, 1, 30)

	var/windows_choice = tgui_alert(user, "Учитывать окна как границу комнаты и точки установки баррикад?", "World Edit: Окна", list("Да", "Нет"))
	if(!windows_choice)
		return null
	new_params["respect_windows"] = windows_choice == "Да"

	var/doors_choice = tgui_alert(user, "Учитывать двери для установки складных баррикад?", "World Edit: Двери", list("Да", "Нет"))
	if(!doors_choice)
		return null
	new_params["respect_doors"] = doors_choice == "Да"

	return new_params

/datum/world_edit_generator/fortify_room/validate_params(mob/user, list/params)
	if(!get_turf(user))
		return "Не удалось определить стартовый тайл."

	var/list/presets = GLOB.world_edit_legacy.world_edit_get_fortify_level_presets()
	var/level_name = params["fortification_level"]
	if(!presets[level_name])
		return "Неизвестный уровень укрепления: [level_name]."

	var/scan_limit = text2num("[params["tile_scan_limit"]]")
	if(!isnum(scan_limit) || scan_limit < 1 || scan_limit > 195)
		return "Лимит скана должен быть в диапазоне 1..195."

	var/scan_radius = text2num("[params["scan_radius"]]")
	if(!isnum(scan_radius) || scan_radius < 1 || scan_radius > 30)
		return "scan_radius должен быть в диапазоне 1..30."

	return null

/datum/world_edit_generator/fortify_room/preview(mob/user, list/params)
	var/datum/world_edit_preview_result/result = new
	var/turf/start_turf = get_turf(user)
	if(!start_turf)
		result.message = "Не удалось определить стартовый тайл."
		return result

	var/list/presets = GLOB.world_edit_legacy.world_edit_get_fortify_level_presets()
	var/list/preset = presets[params["fortification_level"]]
	var/scan_limit = text2num("[params["tile_scan_limit"]]") || 195
	var/scan_radius = text2num("[params["scan_radius"]]") || 12
	var/respect_windows = params["respect_windows"] ? TRUE : FALSE
	var/respect_doors = params["respect_doors"] ? TRUE : FALSE

	var/list/preview_data = GLOB.world_edit_legacy.world_edit_collect_room_fortify_preview(start_turf, preset["folding"], scan_limit, scan_radius, respect_windows, respect_doors)
	last_preview_data = preview_data

	var/list/tiles = preview_data["tiles"]
	var/list/placements = preview_data["placements"]
	var/success = preview_data["success"]
	result.preview_images = GLOB.world_edit_helpers.build_turf_preview_images(tiles)

	result.success = TRUE
	result.meta["tiles_scanned"] = length(tiles)
	result.meta["placements_planned"] = length(placements)
	result.meta["scan_completed"] = success
	result.meta["scan_radius"] = scan_radius
	if(success)
		result.message = "Предпросмотр готов: тайлов [length(tiles)], установок [length(placements)], радиус [scan_radius]."
	else
		result.message = "Предпросмотр частичный: достигнут лимит [scan_limit] или граница радиуса [scan_radius], тайлов [length(tiles)], установок [length(placements)]."
	return result

/datum/world_edit_generator/fortify_room/apply(mob/user, list/params)
	var/datum/world_edit_apply_result/result = new
	var/turf/start_turf = get_turf(user)
	if(!start_turf)
		result.message = "Не удалось определить стартовый тайл."
		return result

	var/list/presets = GLOB.world_edit_legacy.world_edit_get_fortify_level_presets()
	var/list/preset = presets[params["fortification_level"]]
	var/scan_limit = text2num("[params["tile_scan_limit"]]") || 195
	var/scan_radius = text2num("[params["scan_radius"]]") || 12
	var/respect_windows = params["respect_windows"] ? TRUE : FALSE
	var/respect_doors = params["respect_doors"] ? TRUE : FALSE

	var/list/apply_data = GLOB.world_edit_legacy.world_edit_apply_room_fortify(start_turf, preset["cade"], preset["folding"], scan_limit, scan_radius, respect_windows, respect_doors)

	result.success = apply_data["success"]
	result.center_turf = start_turf
	result.created_count = apply_data["placements_created"]
	if(apply_data["success"])
		result.message = "Комната укреплена. Просканировано тайлов: [apply_data["tiles_scanned"]], радиус: [scan_radius], создано баррикад: [apply_data["placements_created"]]."
	else
		result.message = "Укрепление остановлено из-за лимита скана или радиуса. Просканировано тайлов: [apply_data["tiles_scanned"]]."
	result.meta["tiles_scanned"] = apply_data["tiles_scanned"]
	result.meta["scan_radius"] = scan_radius
	return result

/datum/world_edit_generator/fortify_room/cleanup_preview(mob/user)
	last_preview_data = null

/datum/world_edit_generator/fortify_room/get_ui_fields(list/current_params)
	var/list/preset_options = list()
	var/list/presets = GLOB.world_edit_legacy.world_edit_get_fortify_level_presets()
	var/list/preset_names = list()
	for(var/preset_name in presets)
		preset_names += preset_name
	preset_names = sortList(preset_names)

	for(var/preset_name in preset_names)
		preset_options += list(list(
			"label" = preset_name,
			"value" = preset_name,
		))

	return list(
		list(
			"id" = "fortification_level",
			"label" = "Уровень укрепления",
			"kind" = "select",
			"group" = "Основные",
			"description" = "Тип баррикад для фортификации комнаты.",
			"value" = current_params["fortification_level"] || "Metal",
			"options" = preset_options,
		),
		list(
			"id" = "tile_scan_limit",
			"label" = "Лимит скана",
			"kind" = "number",
			"group" = "Лимиты",
			"description" = "Максимум тайлов для flood-fill сканирования.",
			"validate_hint" = "Допустимый диапазон: 1..195",
			"value" = text2num("[current_params["tile_scan_limit"]]") || 195,
			"min" = 1,
			"max" = 195,
			"step" = 1,
		),
		list(
			"id" = "scan_radius",
			"label" = "Радиус скана",
			"kind" = "number",
			"group" = "Лимиты",
			"description" = "Радиус распространения от стартового тайла.",
			"validate_hint" = "Допустимый диапазон: 1..30",
			"value" = text2num("[current_params["scan_radius"]]") || 12,
			"min" = 1,
			"max" = 30,
			"step" = 1,
		),
		list(
			"id" = "respect_windows",
			"label" = "Учитывать окна",
			"kind" = "boolean",
			"group" = "Границы",
			"description" = "Считать окна границей комнаты и точкой установки баррикад.",
			"value" = current_params["respect_windows"] ? TRUE : FALSE,
		),
		list(
			"id" = "respect_doors",
			"label" = "Учитывать двери",
			"kind" = "boolean",
			"group" = "Границы",
			"description" = "Ставить складные баррикады для дверных проходов.",
			"value" = current_params["respect_doors"] ? TRUE : FALSE,
		),
	)

/datum/world_edit_generator/fortify_room/set_ui_param(mob/user, list/current_params, param_id, value)
	var/list/new_params = current_params.Copy()

	switch(param_id)
		if("fortification_level")
			var/list/presets = GLOB.world_edit_legacy.world_edit_get_fortify_level_presets()
			var/level_name = "[value]"
			if(!presets[level_name])
				return "Неизвестный уровень укрепления."
			new_params[param_id] = level_name

		if("tile_scan_limit")
			new_params[param_id] = clamp(text2num("[value]"), 1, 195)

		if("scan_radius")
			new_params[param_id] = clamp(text2num("[value]"), 1, 30)

		if("respect_windows")
			new_params[param_id] = GLOB.world_edit_helpers.parse_bool(value)

		if("respect_doors")
			new_params[param_id] = GLOB.world_edit_helpers.parse_bool(value)

		else
			return ..()

	return new_params

/datum/world_edit_generator/fortify_room/get_apply_confirmation_text(list/params)
	return "Применить укрепление комнаты с уровнем '[params["fortification_level"]]'?"
