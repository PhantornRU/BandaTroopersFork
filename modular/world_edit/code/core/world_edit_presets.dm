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
