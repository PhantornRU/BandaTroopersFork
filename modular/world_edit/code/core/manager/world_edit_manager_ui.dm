/datum/world_edit_manager/tgui_interact(mob/user, datum/tgui/ui)
	if(!holder || QDELETED(holder) || holder != user?.client)
		return
	if(!check_rights_for(holder, R_DEBUG))
		return

	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "WorldEditPanel")
		ui.open()

/datum/world_edit_manager/ui_state(mob/user)
	return GLOB.admin_state

/datum/world_edit_manager/ui_close(mob/user)
	. = ..()
	reset_preview_runtime()

/datum/world_edit_manager/ui_static_data(mob/user)
	if(!holder || holder != user?.client || !check_rights_for(holder, R_DEBUG))
		return list()

	var/list/data = list()
	data["categories"] = build_available_generator_categories()
	return data

/datum/world_edit_manager/ui_data(mob/user)
	if(!holder || holder != user?.client || !check_rights_for(holder, R_DEBUG))
		return list()

	ensure_preset_cache_loaded()
	ensure_blueprint_cache_loaded()

	var/list/data = list()
	var/has_generator = (current_definition && current_generator) ? TRUE : FALSE
	var/list/ui_fields = get_normalized_ui_fields()
	var/has_inline_fields = length(ui_fields) > 0
	var/requires_preview = current_generator?.requires_preview_before_apply ? TRUE : FALSE
	var/list/placement_modes = build_placement_mode_options()
	var/placement_supported = length(placement_modes) > 0
	var/click_mode_active = sync_click_intercept_state()
	var/can_run_preview = has_generator && current_definition?.supports_preview && !click_mode_active
	var/can_run_apply = has_generator && (!requires_preview || is_preview_state_valid()) && !click_mode_active

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
	data["placement_supported"] = placement_supported ? TRUE : FALSE
	data["placement_active"] = (placement_click_active && click_mode_active) ? TRUE : FALSE
	data["placement_mode"] = get_effective_placement_mode() || "single"
	data["placement_mode_options"] = placement_modes
	data["placement_supports_direction"] = supports_current_placement_direction() ? TRUE : FALSE
	data["placement_dir"] = world_edit_dir_to_label(get_effective_placement_dir())
	data["placement_dir_options"] = build_placement_dir_options()
	data["placement_anchor"] = get_placement_anchor_desc()
	data["can_start_placement_mode"] = (placement_supported && !click_mode_active) ? TRUE : FALSE
	data["can_manage_presets"] = can_manage_current_generator_presets()
	data["preset_entries"] = get_current_generator_presets()
	data["blueprint_entries"] = get_blueprint_entries_for_ui()
	data["active_blueprint_id"] = get_active_blueprint_id()
	data["can_save_blueprint_from_plan"] = can_save_blueprint_from_current_plan()
	data["last_ui_error"] = last_ui_error || ""

	data["preview_valid"] = is_preview_state_valid()
	data["preview_success"] = last_preview_success
	data["preview_message"] = last_preview_message
	data["preview_meta"] = last_preview_meta || list()

	data["last_apply_success"] = last_apply_success
	data["last_apply_message"] = last_apply_message
	data["last_undo_success"] = last_undo_success
	data["last_undo_message"] = last_undo_message
	data["last_undo_action"] = last_undo_action
	data["last_changeset"] = build_last_changeset_summary()

	data["click_mode_active"] = click_mode_active ? TRUE : FALSE
	data["can_run_preview"] = can_run_preview ? TRUE : FALSE
	data["can_run_apply"] = can_run_apply ? TRUE : FALSE
	data["can_stop_click_mode"] = click_mode_active ? TRUE : FALSE
	data["can_undo_last_operation"] = can_undo_last_operation()
	data["can_cleanup_last_owned_effects"] = can_cleanup_last_owned_effects()
	data["can_refresh_ui"] = has_generator ? TRUE : FALSE
	data["history_entries"] = get_history_entries_desc()
	return data

/datum/world_edit_manager/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	if(!holder || holder != ui.user?.client)
		return
	if(!check_rights_for(holder, R_DEBUG))
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

		if("save_preset")
			save_current_preset(ui.user)
			return TRUE

		if("load_preset")
			load_preset_by_id(ui.user, params["preset_id"])
			return TRUE

		if("delete_preset")
			delete_preset_by_id(ui.user, params["preset_id"])
			return TRUE

		if("list_blueprints")
			refresh_blueprint_cache()
			last_ui_error = ""
			return TRUE

		if("save_blueprint")
			save_blueprint_from_current_plan(ui.user)
			return TRUE

		if("load_blueprint")
			load_blueprint_into_manager(ui.user, params["blueprint_id"])
			return TRUE

		if("preview_blueprint")
			preview_blueprint_by_id(ui.user, params["blueprint_id"])
			return TRUE

		if("apply_blueprint")
			apply_blueprint_by_id(ui.user, params["blueprint_id"])
			return TRUE

		if("configure_wizard")
			configure_current_generator(ui.user)
			return TRUE

		if("set_param")
			return handle_set_param_action(ui.user, params)

		if("set_placement_mode")
			var/new_mode = "[params["mode"]]"
			if(!(new_mode in get_supported_placement_modes()))
				last_ui_error = "Выбранный placement mode недоступен для текущего генератора."
				to_chat(ui.user, SPAN_WARNING(last_ui_error))
				return TRUE
			placement_mode = new_mode
			last_ui_error = ""
			reset_preview_runtime()
			return TRUE

		if("set_placement_dir")
			if(!supports_current_placement_direction())
				return TRUE
			placement_dir = world_edit_dir_from_label("[params["direction"]]", current_generator?.get_default_placement_direction() || NORTH)
			last_ui_error = ""
			reset_preview_runtime()
			return TRUE

		if("start_placement_mode")
			start_safe_placement_mode(ui.user)
			return TRUE

		if("run_preview")
			run_preview(ui.user)
			return TRUE

		if("run_apply")
			run_apply(ui.user)
			return TRUE

		if("undo_last_operation")
			undo_last_operation(ui.user)
			return TRUE

		if("cleanup_last_owned_effects")
			cleanup_last_owned_effects(ui.user)
			return TRUE

		if("clear_preview")
			reset_preview_runtime()
			to_chat(ui.user, SPAN_NOTICE("Предпросмотр очищен."))
			return TRUE

		if("stop_click_mode")
			reset_preview_runtime()
			to_chat(ui.user, SPAN_NOTICE("Click-режим остановлен."))
			return TRUE

		if("clear_history")
			history_entries = list()
			if(islist(changeset_entries))
				for(var/datum/world_edit_changeset/changeset as anything in changeset_entries)
					qdel(changeset)
			changeset_entries = list()
			reset_undo_feedback()
			to_chat(ui.user, SPAN_NOTICE("История операций и undo-стек очищены."))
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
