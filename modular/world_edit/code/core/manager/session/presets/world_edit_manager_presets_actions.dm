/datum/world_edit_manager/proc/fail_preset_action(mob/user, message)
	last_ui_error = message
	to_chat(user, SPAN_WARNING(message))
	return FALSE

/datum/world_edit_manager/proc/save_current_preset(mob/user)
	if(!current_generator || !current_definition)
		return fail_preset_action(user, "РЎРЅР°С‡Р°Р»Р° РІС‹Р±РµСЂРёС‚Рµ РіРµРЅРµСЂР°С‚РѕСЂ.")
	if(!can_manage_current_generator_presets())
		return fail_preset_action(user, "Р”Р»СЏ С‚РµРєСѓС‰РµРіРѕ РіРµРЅРµСЂР°С‚РѕСЂР° presets РЅРµРґРѕСЃС‚СѓРїРЅС‹ РІ СЌС‚РѕР№ С„Р°Р·Рµ.")
	if(!check_rights_for(holder, current_definition.required_rights))
		return fail_preset_action(user, "РќРµРґРѕСЃС‚Р°С‚РѕС‡РЅРѕ РїСЂР°РІ РґР»СЏ СЃРѕС…СЂР°РЅРµРЅРёСЏ preset.")

	var/list/preset_params = build_effective_generator_params(current_params)
	var/error_text = current_generator.validate_params(user, preset_params)
	if(error_text)
		return fail_preset_action(user, error_text)

	ensure_preset_cache_loaded()
	if(length(preset_entries_cache) >= WORLD_EDIT_PRESET_LIMIT)
		return fail_preset_action(user, "Р”РѕСЃС‚РёРіРЅСѓС‚ Р»РёРјРёС‚ preset'РѕРІ РґР»СЏ СЌС‚РѕРіРѕ Р°РґРјРёРЅРёСЃС‚СЂР°С‚РѕСЂР°.")

	var/default_name = current_definition.name_ru || current_definition.id
	var/raw_name = tgui_input_text(user, "Р’РІРµРґРёС‚Рµ РёРјСЏ preset'Р°. РћСЃС‚Р°РІСЊС‚Рµ РїРѕР»Рµ РїСѓСЃС‚С‹Рј РґР»СЏ РёРјРµРЅРё РїРѕ СѓРјРѕР»С‡Р°РЅРёСЋ.", "World Edit: Save Preset", default_name, WORLD_EDIT_PRESET_NAME_MAX_LEN, FALSE, FALSE)
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
		return fail_preset_action(user, "РќРµ СѓРґР°Р»РѕСЃСЊ СЃРѕС…СЂР°РЅРёС‚СЊ preset РЅР° СЃРµСЂРІРµСЂРµ.")

	last_ui_error = ""
	to_chat(user, SPAN_NOTICE("Preset '[preset_name]' СЃРѕС…СЂР°РЅС‘РЅ."))
	return TRUE

/datum/world_edit_manager/proc/load_preset_by_id(mob/user, preset_id)
	var/list/preset_entry = find_cached_preset_entry(preset_id)
	if(!preset_entry)
		return fail_preset_action(user, "Preset РЅРµ РЅР°Р№РґРµРЅ.")

	var/generator_id = "[preset_entry["generator_id"]]"
	var/datum/world_edit_generator_definition/definition = GLOB.world_edit_registry.get_generator_definition(generator_id)
	if(!GLOB.world_edit_presets.world_edit_is_preset_definition_supported(definition))
		return fail_preset_action(user, "Preset СЃСЃС‹Р»Р°РµС‚СЃСЏ РЅР° РіРµРЅРµСЂР°С‚РѕСЂ РІРЅРµ РїРѕРґРґРµСЂР¶РёРІР°РµРјРѕРіРѕ READY scope.")
	if(!check_rights_for(holder, definition.required_rights))
		return fail_preset_action(user, "РќРµРґРѕСЃС‚Р°С‚РѕС‡РЅРѕ РїСЂР°РІ РґР»СЏ Р·Р°РіСЂСѓР·РєРё СЌС‚РѕРіРѕ preset.")

	var/list/validated_result = build_validated_preset_params(user, definition, preset_entry["params"])
	if(validated_result["error"])
		return fail_preset_action(user, validated_result["error"])

	var/had_active_placement = is_safe_placement_mode_active()
	var/same_generator = current_definition?.id == generator_id
	if(!same_generator)
		if(!set_generator_by_id(generator_id))
			return fail_preset_action(user, "РќРµ СѓРґР°Р»РѕСЃСЊ Р°РєС‚РёРІРёСЂРѕРІР°С‚СЊ РіРµРЅРµСЂР°С‚РѕСЂ РґР»СЏ preset.")

	current_params = validated_result["params"]
	hydrate_legacy_collector_session_from_params(current_params)
	save_current_generator_context()
	if(!same_generator)
		refresh_runtime_after_config_change(TRUE, TRUE)
	else
		rebuild_runtime_after_generator_config_change(user, had_active_placement, !had_active_placement, !had_active_placement, TRUE)
	last_ui_error = ""
	to_chat(user, SPAN_NOTICE("Preset '[preset_entry["name"] || generator_id]' Р·Р°РіСЂСѓР¶РµРЅ."))
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
		return fail_preset_action(user, "Preset РЅРµ РЅР°Р№РґРµРЅ.")

	preset_entries_cache.Cut(entry_index, entry_index + 1)
	if(!GLOB.world_edit_presets.world_edit_save_presets_for_ckey(get_storage_ckey(), preset_entries_cache))
		refresh_preset_cache()
		return fail_preset_action(user, "РќРµ СѓРґР°Р»РѕСЃСЊ СѓРґР°Р»РёС‚СЊ preset РЅР° СЃРµСЂРІРµСЂРµ.")

	last_ui_error = ""
	to_chat(user, SPAN_NOTICE("Preset '[entry_name || preset_id]' СѓРґР°Р»С‘РЅ."))
	return TRUE
