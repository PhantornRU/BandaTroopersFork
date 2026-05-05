/datum/world_edit_manager/proc/fail_preset_action(mob/user, message)
	last_ui_error = message
	to_chat(user, SPAN_WARNING(message))
	return FALSE

/datum/world_edit_manager/proc/save_current_preset(mob/user)
	if(!current_generator || !current_definition)
		return fail_preset_action(user, "Сначала выберите генератор.")
	if(!can_manage_current_generator_presets())
		return fail_preset_action(user, "Для текущего генератора пресеты недоступны в этой фазе.")
	if(!check_rights_for(holder, current_definition.required_rights))
		return fail_preset_action(user, "Недостаточно прав для сохранения пресета.")

	var/list/preset_params = build_effective_generator_params(current_params)
	var/error_text = current_generator.validate_params(user, preset_params)
	if(error_text)
		return fail_preset_action(user, error_text)

	ensure_preset_cache_loaded()
	if(length(preset_entries_cache) >= WORLD_EDIT_PRESET_LIMIT)
		return fail_preset_action(user, "Достигнут лимит пресетов для этого администратора.")

	var/default_name = current_definition.name_ru || current_definition.id
	var/raw_name = tgui_input_text(user, "Введите имя пресета. Оставьте поле пустым для имени по умолчанию.", "Панель редактирования мира: сохранить пресет", default_name, WORLD_EDIT_PRESET_NAME_MAX_LEN, FALSE, FALSE)
	if(isnull(raw_name))
		return FALSE

	var/preset_name = trim(sanitize_text("[raw_name]", ""))
	if(!length(preset_name))
		preset_name = default_name

	var/list/entry = list(
		"id" = "preset_[GLOB.world_edit_presets.world_edit_build_storage_id(current_definition.id)]",
		"generator_id" = current_definition.id,
		"name" = copytext(preset_name, 1, WORLD_EDIT_PRESET_NAME_MAX_LEN + 1),
		"params" = GLOB.world_edit_presets.world_edit_sanitize_preset_payload(preset_params),
		"created_at" = time_stamp(),
	)

	preset_entries_cache += list(entry)
	if(!GLOB.world_edit_presets.world_edit_save_presets_for_ckey(get_storage_ckey(), preset_entries_cache))
		preset_entries_cache.Cut(length(preset_entries_cache), length(preset_entries_cache) + 1)
		return fail_preset_action(user, "Не удалось сохранить пресет на сервере.")

	last_ui_error = ""
	to_chat(user, SPAN_NOTICE("Пресет '[preset_name]' сохранен."))
	return TRUE

/datum/world_edit_manager/proc/load_preset_by_id(mob/user, preset_id)
	var/list/preset_entry = find_cached_preset_entry(preset_id)
	if(!preset_entry)
		return fail_preset_action(user, "Пресет не найден.")

	var/generator_id = "[preset_entry["generator_id"]]"
	var/datum/world_edit_generator_definition/definition = GLOB.world_edit_registry.get_generator_definition(generator_id)
	if(!GLOB.world_edit_presets.world_edit_is_preset_definition_supported(definition))
		return fail_preset_action(user, "Пресет ссылается на генератор вне поддерживаемой стадии READY.")
	if(!check_rights_for(holder, definition.required_rights))
		return fail_preset_action(user, "Недостаточно прав для загрузки этого пресета.")

	var/list/validated_result = build_validated_preset_params(user, definition, preset_entry["params"])
	if(validated_result["error"])
		return fail_preset_action(user, validated_result["error"])

	var/had_active_placement = is_safe_placement_mode_active()
	var/same_generator = current_definition?.id == generator_id
	if(!same_generator)
		if(!set_generator_by_id(generator_id))
			return fail_preset_action(user, "Не удалось активировать генератор для пресета.")

	current_params = sanitize_persistent_generator_params(validated_result["params"])
	save_current_generator_context()
	if(!same_generator)
		refresh_runtime_after_config_change(TRUE, TRUE)
	else
		rebuild_runtime_after_generator_config_change(user, had_active_placement, !had_active_placement, !had_active_placement, TRUE)
	last_ui_error = ""
	to_chat(user, SPAN_NOTICE("Пресет '[preset_entry["name"] || generator_id]' загружен."))
	return TRUE

/datum/world_edit_manager/proc/delete_preset_by_id(mob/user, preset_id)
	ensure_preset_cache_loaded()

	var/entry_index = 0
	var/entry_name = ""
	for(var/i in 1 to length(preset_entries_cache))
		var/list/entry = preset_entries_cache[i]
		if("[entry["id"]]" != "[preset_id]")
			continue
		entry_index = i
		entry_name = "[entry["name"]]"
		break

	if(!entry_index)
		return fail_preset_action(user, "Пресет не найден.")

	preset_entries_cache.Cut(entry_index, entry_index + 1)
	if(!GLOB.world_edit_presets.world_edit_save_presets_for_ckey(get_storage_ckey(), preset_entries_cache))
		refresh_preset_cache()
		return fail_preset_action(user, "Не удалось удалить пресет на сервере.")

	last_ui_error = ""
	to_chat(user, SPAN_NOTICE("Пресет '[entry_name || preset_id]' удален."))
	return TRUE
