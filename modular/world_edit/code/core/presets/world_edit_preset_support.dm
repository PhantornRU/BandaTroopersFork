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
