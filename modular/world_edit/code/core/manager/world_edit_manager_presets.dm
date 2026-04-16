/datum/world_edit_manager/proc/get_storage_ckey()
	return holder?.ckey ? ckey(holder.ckey) : null

/datum/world_edit_manager/proc/ensure_preset_cache_loaded()
	if(preset_cache_loaded)
		return
	refresh_preset_cache()

/datum/world_edit_manager/proc/refresh_preset_cache()
	preset_entries_cache = GLOB.world_edit_presets.world_edit_load_presets_for_ckey(get_storage_ckey())
	preset_cache_loaded = TRUE

/datum/world_edit_manager/proc/get_current_generator_presets()
	ensure_preset_cache_loaded()

	var/list/presets = list()
	var/current_generator_id = current_definition?.id
	if(!length(current_generator_id))
		return presets

	for(var/list/entry as anything in preset_entries_cache)
		if("[entry["generator_id"]]" != current_generator_id)
			continue

		presets += list(list(
			"id" = entry["id"],
			"name" = entry["name"],
			"generator_id" = entry["generator_id"],
			"params_short" = GLOB.world_edit_logging.params_to_text(entry["params"], 220),
			"created_at" = entry["created_at"],
		))

	return presets

/datum/world_edit_manager/proc/can_manage_current_generator_presets()
	return GLOB.world_edit_presets.world_edit_is_preset_definition_supported(current_definition)

/datum/world_edit_manager/proc/fail_preset_action(mob/user, message)
	last_ui_error = message
	to_chat(user, SPAN_WARNING(message))
	return FALSE

/datum/world_edit_manager/proc/build_validated_preset_params(mob/user, datum/world_edit_generator_definition/definition, list/raw_payload)
	if(!istype(definition))
		return list("error" = "Preset references an unknown generator.")
	if(!GLOB.world_edit_presets.world_edit_is_preset_definition_supported(definition))
		return list("error" = "Presets are not supported for this generator.")

	var/datum/world_edit_generator/temp_generator = new definition.generator_type()
	temp_generator.attach(src, definition)

	var/list/params_to_apply = definition.default_params?.Copy() || list()
	var/list/sanitized_payload = GLOB.world_edit_presets.world_edit_sanitize_preset_payload(raw_payload)

	for(var/param_id in sanitized_payload)
		var/key_text = "[param_id]"
		if(!(key_text in definition.default_params))
			qdel(temp_generator)
			return list("error" = "Preset contains an unsupported parameter '[key_text]'.")

		var/new_params = temp_generator.set_ui_param(user, params_to_apply, key_text, sanitized_payload[param_id])
		if(istext(new_params))
			qdel(temp_generator)
			return list("error" = "[new_params]")
		if(!islist(new_params))
			qdel(temp_generator)
			return list("error" = "Preset payload could not be applied to generator params.")

		params_to_apply = new_params

	var/error_text = temp_generator.validate_params(user, params_to_apply)
	qdel(temp_generator)
	if(error_text)
		return list("error" = error_text)

	return list("params" = params_to_apply)

/datum/world_edit_manager/proc/save_current_preset(mob/user)
	if(!current_generator || !current_definition)
		return fail_preset_action(user, "Сначала выберите генератор.")
	if(!can_manage_current_generator_presets())
		return fail_preset_action(user, "Для текущего генератора presets недоступны в этой фазе.")
	if(!check_rights_for(holder, current_definition.required_rights))
		return fail_preset_action(user, "Недостаточно прав для сохранения preset.")

	var/error_text = current_generator.validate_params(user, current_params)
	if(error_text)
		return fail_preset_action(user, error_text)

	ensure_preset_cache_loaded()
	if(length(preset_entries_cache) >= WORLD_EDIT_PRESET_LIMIT)
		return fail_preset_action(user, "Достигнут лимит preset'ов для этого администратора.")

	var/default_name = current_definition.name_ru || current_definition.id
	var/raw_name = tgui_input_text(user, "Введите имя preset'а. Оставьте поле пустым для имени по умолчанию.", "World Edit: Save Preset", default_name, WORLD_EDIT_PRESET_NAME_MAX_LEN, FALSE, FALSE)
	if(isnull(raw_name))
		return FALSE

	var/preset_name = trim(sanitize_text("[raw_name]", ""))
	if(!length(preset_name))
		preset_name = default_name

	var/list/entry = list(
		"id" = "preset_[GLOB.world_edit_presets.world_edit_build_storage_id(current_definition.id)]",
		"generator_id" = current_definition.id,
		"name" = copytext(preset_name, 1, WORLD_EDIT_PRESET_NAME_MAX_LEN + 1),
		"params" = GLOB.world_edit_presets.world_edit_sanitize_preset_payload(current_params),
		"created_at" = time_stamp(),
	)

	preset_entries_cache += list(entry)
	if(!GLOB.world_edit_presets.world_edit_save_presets_for_ckey(get_storage_ckey(), preset_entries_cache))
		preset_entries_cache.Cut(length(preset_entries_cache), length(preset_entries_cache) + 1)
		return fail_preset_action(user, "Не удалось сохранить preset на сервере.")

	last_ui_error = ""
	to_chat(user, SPAN_NOTICE("Preset '[preset_name]' сохранён."))
	return TRUE

/datum/world_edit_manager/proc/find_cached_preset_entry(preset_id)
	ensure_preset_cache_loaded()
	for(var/list/entry as anything in preset_entries_cache)
		if("[entry["id"]]" == "[preset_id]")
			return entry
	return null

/datum/world_edit_manager/proc/load_preset_by_id(mob/user, preset_id)
	var/list/preset_entry = find_cached_preset_entry(preset_id)
	if(!preset_entry)
		return fail_preset_action(user, "Preset не найден.")

	var/generator_id = "[preset_entry["generator_id"]]"
	var/datum/world_edit_generator_definition/definition = GLOB.world_edit_registry.get_generator_definition(generator_id)
	if(!GLOB.world_edit_presets.world_edit_is_preset_definition_supported(definition))
		return fail_preset_action(user, "Preset ссылается на генератор вне поддерживаемого READY scope.")
	if(!check_rights_for(holder, definition.required_rights))
		return fail_preset_action(user, "Недостаточно прав для загрузки этого preset.")

	var/list/validated_result = build_validated_preset_params(user, definition, preset_entry["params"])
	if(validated_result["error"])
		return fail_preset_action(user, validated_result["error"])

	var/keep_active_placement = is_safe_placement_mode_active()
	var/same_generator = current_definition?.id == generator_id
	if(!same_generator)
		if(!set_generator_by_id(generator_id, keep_active_placement))
			return fail_preset_action(user, "Не удалось активировать генератор для preset.")

	if(keep_active_placement && same_generator)
		validated_result["params"] = preserve_active_placement_runtime_params(validated_result["params"])

	current_params = validated_result["params"]
	save_current_generator_context()
	refresh_runtime_after_config_change()
	last_ui_error = ""
	to_chat(user, SPAN_NOTICE("Preset '[preset_entry["name"] || generator_id]' загружен."))
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
		return fail_preset_action(user, "Preset не найден.")

	preset_entries_cache.Cut(entry_index, entry_index + 1)
	if(!GLOB.world_edit_presets.world_edit_save_presets_for_ckey(get_storage_ckey(), preset_entries_cache))
		refresh_preset_cache()
		return fail_preset_action(user, "Не удалось удалить preset на сервере.")

	last_ui_error = ""
	to_chat(user, SPAN_NOTICE("Preset '[entry_name || preset_id]' удалён."))
	return TRUE
