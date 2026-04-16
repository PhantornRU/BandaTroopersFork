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

/datum/world_edit_manager/proc/find_cached_preset_entry(preset_id)
	ensure_preset_cache_loaded()
	for(var/list/entry as anything in preset_entries_cache)
		if("[entry["id"]]" == "[preset_id]")
			return entry
	return null
