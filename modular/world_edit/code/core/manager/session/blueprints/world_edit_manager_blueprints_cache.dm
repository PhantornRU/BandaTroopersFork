/datum/world_edit_manager/proc/ensure_blueprint_cache_loaded()
	if(blueprint_cache_loaded)
		return
	refresh_blueprint_cache()

/datum/world_edit_manager/proc/refresh_blueprint_cache()
	blueprint_entries_cache = GLOB.world_edit_blueprints.world_edit_load_blueprint_library_summaries()
	blueprint_cache_loaded = TRUE

/datum/world_edit_manager/proc/get_blueprint_entries_for_ui()
	ensure_blueprint_cache_loaded()

	var/active_blueprint_id = get_active_blueprint_id()
	var/list/ui_entries = list()
	for(var/list/entry as anything in blueprint_entries_cache)
		var/list/ui_entry = entry.Copy()
		ui_entry["active"] = "[entry["id"]]" == active_blueprint_id
		ui_entries += list(ui_entry)
	return ui_entries

/datum/world_edit_manager/proc/get_active_blueprint_id()
	if(current_definition?.id != "blueprint_stamp")
		return null
	var/blueprint_id = "[current_params["blueprint_id"]]"
	return length(blueprint_id) ? blueprint_id : null

/datum/world_edit_manager/proc/find_cached_blueprint_entry(blueprint_id)
	ensure_blueprint_cache_loaded()
	for(var/list/entry as anything in blueprint_entries_cache)
		if("[entry["id"]]" == "[blueprint_id]")
			return entry
	return null
