/datum/world_edit_generator/breach_layout
	var/click_mode_active = FALSE

/datum/world_edit_generator/breach_layout/configure_params(mob/user, list/current_params)
	var/list/new_params = current_params.Copy()
	var/list/charge_dict = world_edit_get_breach_charge_dict()
	var/list/charge_names = list()
	for(var/charge_name in charge_dict)
		charge_names += charge_name
	charge_names = sortList(charge_names)

	var/default_charge_name = charge_names[1]
	var/current_charge_path = new_params["charge_type"]
	for(var/charge_name in charge_dict)
		if(charge_dict[charge_name] == current_charge_path)
			default_charge_name = charge_name
			break

	var/chosen_charge_name = tgui_input_list(user, "Выберите тип заряда.", "World Edit: Breach", charge_names, default_charge_name)
	if(!chosen_charge_name)
		return null
	new_params["charge_type"] = charge_dict[chosen_charge_name]

	var/list/direction_dict = world_edit_get_breach_direction_dict()
	var/list/direction_names = list()
	for(var/direction_name in direction_dict)
		direction_names += direction_name

	var/default_direction_name = "North"
	var/current_direction = new_params["direction"]
	for(var/direction_name in direction_dict)
		if(direction_dict[direction_name] == current_direction)
			default_direction_name = direction_name
			break

	var/chosen_direction_name = tgui_input_list(user, "Выберите направление установки.", "World Edit: Breach", direction_names, default_direction_name)
	if(!chosen_direction_name)
		return null
	new_params["direction"] = direction_dict[chosen_direction_name]

	var/list/profile_dict = world_edit_get_breach_allowed_profiles()
	var/list/profile_names = list()
	for(var/profile_name in profile_dict)
		profile_names += profile_name
	profile_names = sortList(profile_names)

	var/default_profile = new_params["allowed_profile"] || "Стандартный"
	if(!(default_profile in profile_names))
		default_profile = "Стандартный"

	var/chosen_profile = tgui_input_list(user, "Выберите профиль допустимых целей.", "World Edit: Breach", profile_names, default_profile)
	if(!chosen_profile)
		return null
	new_params["allowed_profile"] = chosen_profile

	return new_params

/datum/world_edit_generator/breach_layout/get_ui_fields(list/current_params)
	var/list/charge_dict = world_edit_get_breach_charge_dict()
	var/list/charge_options = list()
	var/list/charge_names = list()
	for(var/charge_name in charge_dict)
		charge_names += charge_name
	charge_names = sortList(charge_names)
	for(var/charge_name in charge_names)
		charge_options += list(list(
			"label" = charge_name,
			"value" = "[charge_dict[charge_name]]",
		))

	var/list/direction_options = list()
	var/list/direction_dict = world_edit_get_breach_direction_dict()
	for(var/dir_name in list("North", "East", "South", "West"))
		direction_options += list(list(
			"label" = dir_name,
			"value" = dir_name,
		))

	var/list/profile_options = list()
	var/list/profile_dict = world_edit_get_breach_allowed_profiles()
	for(var/profile_name in sortList(profile_dict.Copy()))
		profile_options += list(list(
			"label" = profile_name,
			"value" = profile_name,
		))

	var/current_direction_label = "North"
	for(var/dir_name in direction_dict)
		if(direction_dict[dir_name] == current_params["direction"])
			current_direction_label = dir_name
			break

	return list(
		list(
			"id" = "charge_type",
			"label" = "Тип заряда",
			"kind" = "select",
			"group" = "Основные",
			"description" = "Тип заряда для размещения в click-режиме.",
			"value" = "[current_params["charge_type"] || /obj/item/explosive/plastic]",
			"options" = charge_options,
		),
		list(
			"id" = "direction",
			"label" = "Направление",
			"kind" = "select",
			"group" = "Основные",
			"description" = "Направление установки объекта заряда.",
			"value" = current_direction_label,
			"options" = direction_options,
		),
		list(
			"id" = "allowed_profile",
			"label" = "Профиль целей",
			"kind" = "select",
			"group" = "Ограничения",
			"description" = "Набор допустимых типов целей для установки.",
			"value" = current_params["allowed_profile"] || "Стандартный",
			"options" = profile_options,
		),
	)

/datum/world_edit_generator/breach_layout/set_ui_param(mob/user, list/current_params, param_id, value)
	var/list/new_params = current_params.Copy()

	switch(param_id)
		if("charge_type")
			var/path_value = ispath(value) ? value : text2path("[value]")
			if(!ispath(path_value, /obj/item/explosive/plastic))
				return "Выбран неверный тип заряда."
			new_params[param_id] = path_value

		if("direction")
			var/list/direction_dict = world_edit_get_breach_direction_dict()
			var/label = "[value]"
			if(!direction_dict[label])
				return "Выбрано неверное направление установки."
			new_params[param_id] = direction_dict[label]

		if("allowed_profile")
			var/list/profiles = world_edit_get_breach_allowed_profiles()
			var/profile_name = "[value]"
			if(!profiles[profile_name])
				return "Выбран неизвестный профиль допустимых целей."
			new_params[param_id] = profile_name

		else
			return ..()

	return new_params

/datum/world_edit_generator/breach_layout/validate_params(mob/user, list/params)
	if(!ispath(params["charge_type"], /obj/item/explosive/plastic))
		return "Выбран неверный тип заряда."

	var/list/profiles = world_edit_get_breach_allowed_profiles()
	if(!profiles[params["allowed_profile"]])
		return "Выбран неизвестный профиль допустимых целей."

	return null

/datum/world_edit_generator/breach_layout/preview(mob/user, list/params)
	var/datum/world_edit_preview_result/result = new
	result.success = TRUE
	result.message = "Click-режим: ЛКМ ставит заряд, СКМ меняет тип и направление. Профиль целей: [params["allowed_profile"]]."
	return result

/datum/world_edit_generator/breach_layout/apply(mob/user, list/params)
	var/datum/world_edit_apply_result/result = new
	if(!manager)
		result.message = "Менеджер World Edit не инициализирован."
		return result

	if(!manager.acquire_click_intercept("Схема бреш-зарядов"))
		result.message = "Перехват клика не активирован."
		return result

	click_mode_active = TRUE
	result.success = TRUE
	result.center_turf = get_turf(user)
	result.message = "Click-режим активирован: ЛКМ ставит заряд, СКМ меняет тип и направление."
	return result

/datum/world_edit_generator/breach_layout/cleanup_preview(mob/user)
	return

/datum/world_edit_generator/breach_layout/disable_click_mode()
	click_mode_active = FALSE

/datum/world_edit_generator/breach_layout/get_runtime_status()
	return list(
		list("label" = "Click-режим", "value" = click_mode_active ? "активен" : "выключен"),
		list("label" = "Профиль целей", "value" = manager?.current_params["allowed_profile"] || "Стандартный"),
	)

/datum/world_edit_generator/breach_layout/InterceptClickOn(mob/user, params, atom/object)
	if(!click_mode_active)
		return FALSE

	var/list/modifiers = params2list(params)
	if(LAZYACCESS(modifiers, LEFT_CLICK))
		var/list/profiles = world_edit_get_breach_allowed_profiles()
		var/list/allowed_types = profiles[manager.current_params["allowed_profile"]] || profiles["Стандартный"]
		var/charge_path = manager.current_params["charge_type"]
		var/place_dir = manager.current_params["direction"]

		if(!world_edit_place_breach_charge(user, object, charge_path, place_dir, allowed_types))
			to_chat(user, SPAN_WARNING("Нельзя установить заряд на эту цель для текущего профиля."))
			return TRUE

		var/charge_name = "[charge_path]"
		to_chat(user, SPAN_BOLDNOTICE("[charge_name] установлен, подрыв через таймер устройства."))

		var/turf/center_turf = get_turf(object)
		world_edit_log_operation(
			manager.holder,
			definition.id,
			definition.required_rights,
			center_turf,
			1,
			0,
			0,
			"click_place",
			get_params_short(manager.current_params)
		)
		manager.add_history_entry(
			definition.id,
			"click_place",
			1,
			0,
			center_turf,
			get_params_short(manager.current_params)
		)
		return TRUE

	if(LAZYACCESS(modifiers, MIDDLE_CLICK))
		var/list/charge_dict = world_edit_get_breach_charge_dict()
		var/list/charge_names = list()
		for(var/charge_name in charge_dict)
			charge_names += charge_name
		charge_names = sortList(charge_names)
		var/chosen_charge_name = tgui_input_list(user, "Выберите тип заряда.", "World Edit: Breach", charge_names)
		if(!chosen_charge_name)
			return TRUE

		var/list/direction_names = list("North", "East", "South", "West")
		var/chosen_direction_name = tgui_input_list(user, "Выберите направление установки.", "World Edit: Breach", direction_names)
		if(!chosen_direction_name)
			return TRUE

		manager.current_params["charge_type"] = charge_dict[chosen_charge_name]
		manager.current_params["direction"] = world_edit_get_breach_direction_dict()[chosen_direction_name]
		manager.invalidate_preview_state()
		to_chat(user, SPAN_BOLDNOTICE("Параметры обновлены: [chosen_charge_name], направление [chosen_direction_name]."))
		return TRUE

	return TRUE

/datum/world_edit_generator/breach_layout/get_apply_confirmation_text(list/params)
	return "Включить click-режим установки зарядов?"
