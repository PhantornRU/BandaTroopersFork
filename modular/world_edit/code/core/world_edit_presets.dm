#define WORLD_EDIT_PRESET_FILENAME "world_edit_presets.sav"
#define WORLD_EDIT_PRESET_VERSION 1
#define WORLD_EDIT_PRESET_LIMIT 24
#define WORLD_EDIT_PRESET_NAME_MAX_LEN 64

GLOBAL_LIST_INIT(world_edit_preset_supported_generators, list(
	"outpost_radius" = TRUE,
	"destruction_pack" = TRUE,
))

GLOBAL_DATUM_INIT(world_edit_presets, /datum/world_edit_preset_service, new)

/datum/world_edit_preset_service

/datum/world_edit_preset_service/proc/world_edit_is_preset_generator_supported(generator_id)
	if(!length("[generator_id]"))
		return FALSE
	return GLOB.world_edit_preset_supported_generators["[generator_id]"] ? TRUE : FALSE

/datum/world_edit_preset_service/proc/world_edit_is_preset_definition_supported(datum/world_edit_generator_definition/definition)
	if(!istype(definition))
		return FALSE
	if(definition.status != WORLD_EDIT_STATUS_READY)
		return FALSE
	if(definition.execution_mode != WORLD_EDIT_EXECUTION_BATCH)
		return FALSE
	return world_edit_is_preset_generator_supported(definition.id)

/datum/world_edit_preset_service/proc/world_edit_get_player_save_root()
	return CONFIG_GET(string/playersave_path) || "data/player_saves"

/datum/world_edit_preset_service/proc/world_edit_get_player_savefile_path(raw_ckey, filename = WORLD_EDIT_PRESET_FILENAME)
	var/safe_key = ckey("[raw_ckey]")
	if(!length(safe_key) || IsGuestKey(safe_key))
		return null
	return "[world_edit_get_player_save_root()]/[copytext(safe_key, 1, 2)]/[safe_key]/[filename]"

/datum/world_edit_preset_service/proc/world_edit_build_storage_id(prefix)
	return copytext(md5("[prefix]-[world.realtime]-[world.time]-[rand(1, 1000000)]"), 1, 13)

/datum/world_edit_preset_service/proc/world_edit_sanitize_preset_payload(list/raw_params)
	var/list/payload = list()
	if(!islist(raw_params))
		return payload

	for(var/param_id in raw_params)
		var/value = raw_params[param_id]
		var/key_text = "[param_id]"
		if(!length(key_text))
			continue
		if(ispath(value))
			payload[key_text] = "[value]"
			continue
		if(isnum(value) || istext(value) || isnull(value))
			payload[key_text] = value
			continue
		payload[key_text] = "[value]"

	return payload

/datum/world_edit_preset_service/proc/world_edit_sanitize_preset_entry(list/raw_entry)
	if(!islist(raw_entry))
		return null

	var/entry_id = sanitize_filename("[raw_entry["id"]]")
	if(!length(entry_id))
		return null

	var/generator_id = "[raw_entry["generator_id"]]"
	if(!world_edit_is_preset_generator_supported(generator_id))
		return null

	var/list/params_payload = world_edit_sanitize_preset_payload(raw_entry["params"])
	var/preset_name = trim(sanitize_text("[raw_entry["name"]]", ""))
	preset_name = copytext(preset_name, 1, WORLD_EDIT_PRESET_NAME_MAX_LEN + 1)

	return list(
		"id" = entry_id,
		"generator_id" = generator_id,
		"name" = preset_name,
		"params" = params_payload,
		"created_at" = "[raw_entry["created_at"] || ""]",
	)

/datum/world_edit_preset_service/proc/world_edit_load_presets_for_ckey(raw_ckey)
	. = list()

	var/savefile_path = world_edit_get_player_savefile_path(raw_ckey)
	if(!savefile_path || !fexists(savefile_path))
		return

	var/savefile/S = new /savefile(savefile_path)
	if(!S)
		return

	S.cd = "/"

	var/version = 0
	S["version"] >> version
	if(version != WORLD_EDIT_PRESET_VERSION)
		return

	var/list/raw_entries = list()
	S["entries"] >> raw_entries
	if(!islist(raw_entries))
		return

	for(var/list/raw_entry as anything in raw_entries)
		var/list/entry = world_edit_sanitize_preset_entry(raw_entry)
		if(!entry)
			continue
		. += list(entry)

/datum/world_edit_preset_service/proc/world_edit_save_presets_for_ckey(raw_ckey, list/entries)
	var/savefile_path = world_edit_get_player_savefile_path(raw_ckey)
	if(!savefile_path)
		return FALSE

	var/list/sanitized_entries = list()
	if(islist(entries))
		for(var/list/raw_entry as anything in entries)
			var/list/entry = world_edit_sanitize_preset_entry(raw_entry)
			if(!entry)
				continue
			sanitized_entries += list(entry)
			if(length(sanitized_entries) >= WORLD_EDIT_PRESET_LIMIT)
				break

	var/savefile/S = new /savefile(savefile_path)
	if(!S)
		return FALSE

	S.cd = "/"
	S["version"] << WORLD_EDIT_PRESET_VERSION
	S["entries"] << sanitized_entries
	return TRUE
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
