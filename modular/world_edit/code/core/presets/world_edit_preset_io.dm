/datum/world_edit_preset_service/proc/world_edit_get_player_save_root()
	return CONFIG_GET(string/playersave_path) || "data/player_saves"

/datum/world_edit_preset_service/proc/world_edit_get_player_savefile_path(raw_ckey, filename = WORLD_EDIT_PRESET_FILENAME)
	var/safe_key = ckey("[raw_ckey]")
	if(!length(safe_key) || IsGuestKey(safe_key))
		return null
	return "[world_edit_get_player_save_root()]/[copytext(safe_key, 1, 2)]/[safe_key]/[filename]"

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
