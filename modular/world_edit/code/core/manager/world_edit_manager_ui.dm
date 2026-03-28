/datum/world_edit_manager/tgui_interact(mob/user, datum/tgui/ui)
	if(!holder || QDELETED(holder) || holder != user?.client)
		return

	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "WorldEditPanel")
		ui.open()

/datum/world_edit_manager/ui_state(mob/user)
	return GLOB.admin_state

/datum/world_edit_manager/ui_close(mob/user)
	. = ..()
	stop_click_mode()
	reset_preview_runtime()

/datum/world_edit_manager/ui_static_data(mob/user)
	var/list/data = list()
	data["categories"] = build_available_generator_categories()
	return data

/datum/world_edit_manager/ui_data(mob/user)
	var/list/data = list()
	var/has_generator = (current_definition && current_generator) ? TRUE : FALSE
	var/list/ui_fields = get_normalized_ui_fields()
	var/has_inline_fields = length(ui_fields) > 0
	var/requires_preview = current_generator?.requires_preview_before_apply ? TRUE : FALSE
	var/can_run_preview = has_generator && current_definition?.supports_preview
	var/click_generator_active = click_intercept_owned && current_definition?.execution_mode == WORLD_EDIT_EXECUTION_CLICK
	var/can_run_apply = has_generator && (!requires_preview || is_preview_state_valid()) && !click_generator_active

	data["has_generator"] = has_generator
	data["current_generator_id"] = current_definition?.id
	data["current_generator_name"] = current_definition?.name_ru
	data["current_generator_category"] = current_definition?.category_ru
	data["current_generator_description"] = current_definition?.description_ru
	data["current_generator_execution_mode"] = current_definition?.execution_mode
	data["current_generator_required_rights"] = current_definition ? rights2text(current_definition.required_rights, " ") : ""
	data["current_generator_status"] = current_definition?.status
	data["current_generator_supports_preview"] = current_definition?.supports_preview ? TRUE : FALSE
	data["requires_preview_before_apply"] = requires_preview

	data["current_params_text"] = world_edit_params_to_text(current_params, 600)
	data["ui_fields"] = ui_fields
	data["has_inline_fields"] = has_inline_fields
	data["ui_mode"] = has_inline_fields ? "inline" : "wizard_fallback"
	data["runtime_status"] = current_generator?.get_runtime_status() || list()
	data["last_ui_error"] = last_ui_error || ""

	data["preview_valid"] = is_preview_state_valid()
	data["preview_success"] = last_preview_success
	data["preview_message"] = last_preview_message
	data["preview_meta"] = last_preview_meta || list()

	data["last_apply_success"] = last_apply_success
	data["last_apply_message"] = last_apply_message

	data["click_mode_active"] = click_intercept_owned
	data["can_run_preview"] = can_run_preview ? TRUE : FALSE
	data["can_run_apply"] = can_run_apply ? TRUE : FALSE
	data["can_stop_click_mode"] = click_intercept_owned ? TRUE : FALSE
	data["can_refresh_ui"] = has_generator ? TRUE : FALSE
	data["history_entries"] = get_history_entries_desc()
	return data

/datum/world_edit_manager/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	if(!holder || holder != ui.user?.client)
		return

	switch(action)
		if("select_generator")
			if(set_generator_by_id(params["generator_id"]))
				last_ui_error = ""
			return TRUE

		if("reset_generator")
			reset_current_generator()
			to_chat(ui.user, SPAN_NOTICE("Текущий генератор сброшен."))
			return TRUE

		if("refresh_ui")
			refresh_current_generator_ui(ui.user)
			return TRUE

		if("configure_wizard")
			configure_current_generator(ui.user)
			return TRUE

		if("set_param")
			return handle_set_param_action(ui.user, params)

		if("run_preview")
			run_preview(ui.user)
			return TRUE

		if("run_apply")
			run_apply(ui.user)
			return TRUE

		if("clear_preview")
			reset_preview_runtime()
			to_chat(ui.user, SPAN_NOTICE("Предпросмотр очищен."))
			return TRUE

		if("stop_click_mode")
			stop_click_mode()
			to_chat(ui.user, SPAN_NOTICE("Click-режим остановлен."))
			return TRUE

		if("clear_history")
			history_entries = list()
			to_chat(ui.user, SPAN_NOTICE("История операций очищена."))
			return TRUE

/datum/world_edit_manager/proc/refresh_current_generator_ui(mob/user)
	if(!current_generator || !current_definition)
		last_ui_error = "Сначала выберите генератор."
		to_chat(user, SPAN_WARNING(last_ui_error))
		return

	current_generator.refresh_ui_state(user, current_params)
	last_ui_error = ""
	reset_preview_runtime()
	to_chat(user, SPAN_NOTICE("Параметры генератора обновлены."))

/datum/world_edit_manager/proc/handle_set_param_action(mob/user, list/params)
	if(!current_generator || !current_definition)
		return TRUE

	if(!check_rights_for(holder, current_definition.required_rights))
		last_ui_error = "Недостаточно прав для настройки этого генератора."
		to_chat(user, SPAN_WARNING(last_ui_error))
		return TRUE

	var/param_id = params["param_id"]
	if(!param_id)
		last_ui_error = "Не передан идентификатор параметра."
		to_chat(user, SPAN_WARNING(last_ui_error))
		return TRUE

	var/list/ui_fields = get_normalized_ui_fields()
	var/list/target_field = find_ui_field_by_id(ui_fields, param_id)
	if(!target_field)
		last_ui_error = "Параметр '[param_id]' недоступен в текущей форме генератора."
		to_chat(user, SPAN_WARNING(last_ui_error))
		return TRUE

	if(world_edit_parse_bool(target_field["disabled"]))
		var/target_field_label = "[target_field["label"]]"
		last_ui_error = "Параметр '[target_field_label]' сейчас недоступен для редактирования."
		to_chat(user, SPAN_WARNING(last_ui_error))
		return TRUE

	var/value = params["value"]
	var/new_params = current_generator.set_ui_param(user, current_params, param_id, value)
	if(isnull(new_params))
		return TRUE

	if(istext(new_params))
		last_ui_error = new_params
		to_chat(user, SPAN_WARNING(last_ui_error))
		return TRUE

	if(!islist(new_params))
		last_ui_error = "Не удалось обновить параметр генератора."
		to_chat(user, SPAN_WARNING(last_ui_error))
		return TRUE

	current_params = new_params
	last_ui_error = ""
	reset_preview_runtime()
	return TRUE

/datum/world_edit_manager/proc/get_normalized_ui_fields()
	if(!current_generator)
		return list()

	var/list/raw_fields = current_generator.get_ui_fields(current_params)
	return normalize_ui_fields(raw_fields)

/datum/world_edit_manager/proc/normalize_ui_fields(list/raw_fields)
	var/list/normalized_fields = list()
	if(!islist(raw_fields) || !length(raw_fields))
		return normalized_fields

	var/static/list/supported_kinds = list("select", "number", "boolean", "text")
	for(var/list/raw_field as anything in raw_fields)
		if(!islist(raw_field))
			continue

		var/field_id = "[raw_field["id"]]"
		if(!length(field_id))
			continue

		var/visible = TRUE
		if("visible" in raw_field)
			visible = world_edit_parse_bool(raw_field["visible"])
		if(!visible)
			continue

		var/field_kind = lowertext("[raw_field["kind"] || "text"]")
		if(!(field_kind in supported_kinds))
			continue

		var/list/field = list()
		field["id"] = field_id
		field["label"] = raw_field["label"] ? "[raw_field["label"]]" : field_id
		field["kind"] = field_kind
		field["group"] = raw_field["group"] ? "[raw_field["group"]]" : "Основные"
		field["disabled"] = ("disabled" in raw_field) ? world_edit_parse_bool(raw_field["disabled"]) : FALSE
		field["required"] = ("required" in raw_field) ? world_edit_parse_bool(raw_field["required"]) : FALSE

		var/value = raw_field["value"]
		if(isnull(value) && islist(current_params) && (field_id in current_params))
			value = current_params[field_id]
		field["value"] = value

		if(!isnull(raw_field["description"]))
			field["description"] = "[raw_field["description"]]"
		if(!isnull(raw_field["placeholder"]))
			field["placeholder"] = "[raw_field["placeholder"]]"
		if(!isnull(raw_field["validate_hint"]))
			field["validate_hint"] = "[raw_field["validate_hint"]]"

		switch(field_kind)
			if("select")
				field["options"] = normalize_ui_select_options(raw_field["options"])
			if("number")
				if("min" in raw_field)
					var/min_value = text2num("[raw_field["min"]]")
					if(isnum(min_value))
						field["min"] = min_value
				if("max" in raw_field)
					var/max_value = text2num("[raw_field["max"]]")
					if(isnum(max_value))
						field["max"] = max_value
				if("step" in raw_field)
					var/step_value = text2num("[raw_field["step"]]")
					if(isnum(step_value))
						field["step"] = step_value

		normalized_fields += list(field)

	return normalized_fields

/datum/world_edit_manager/proc/normalize_ui_select_options(list/raw_options)
	var/list/options = list()
	if(!islist(raw_options) || !length(raw_options))
		return options

	var/list/label_counts = list()
	for(var/raw_option in raw_options)
		var/option_value
		var/option_label
		var/option_description = ""

		if(islist(raw_option))
			var/list/entry = raw_option
			if(!("value" in entry))
				continue
			option_value = entry["value"]
			option_label = entry["label"]
			if(!isnull(entry["description"]))
				option_description = "[entry["description"]]"
		else
			option_value = raw_option
			option_label = "[raw_option]"

		if(isnull(option_value))
			continue

		if(!length("[option_label]"))
			option_label = "[option_value]"

		var/base_label = "[option_label]"
		var/next_count = (label_counts[base_label] || 0) + 1
		label_counts[base_label] = next_count
		if(next_count > 1)
			option_label = "[base_label] ([next_count])"

		var/list/normalized_option = list(
			"label" = option_label,
			"value" = option_value,
		)
		if(length(option_description))
			normalized_option["description"] = option_description

		options += list(normalized_option)

	return options

/datum/world_edit_manager/proc/find_ui_field_by_id(list/ui_fields, field_id)
	if(!islist(ui_fields) || !length(field_id))
		return null

	for(var/list/field as anything in ui_fields)
		if("[field["id"]]" == "[field_id]")
			return field

	return null
