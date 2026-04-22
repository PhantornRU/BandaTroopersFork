/datum/world_edit_blueprint_service/proc/world_edit_get_blueprint_file_path(blueprint_id)
	var/safe_id = sanitize_filename("[blueprint_id]")
	if(!length(safe_id))
		return null
	if(length(safe_id) > WORLD_EDIT_BLUEPRINT_ID_LEN)
		return null
	return "[WORLD_EDIT_BLUEPRINT_DIR][safe_id].json"

/datum/world_edit_blueprint_service/proc/world_edit_ensure_blueprint_storage_dir()
	if(fexists(WORLD_EDIT_BLUEPRINT_DIR))
		return TRUE

	var/probe_path = "[WORLD_EDIT_BLUEPRINT_DIR]__probe.sav"
	var/savefile/S = new /savefile(probe_path)
	if(!S)
		return FALSE

	S.cd = "/"
	S["version"] << WORLD_EDIT_BLUEPRINT_VERSION
	if(fexists(probe_path))
		fdel(probe_path)

	return fexists(WORLD_EDIT_BLUEPRINT_DIR)

/datum/world_edit_blueprint_service/proc/world_edit_load_blueprint_from_file(file_path)
	if(!file_path || !fexists(file_path))
		return list("error" = "Файл шаблона не найден.")

	var/json_text = file2text(file_path)
	if(!length(json_text))
		return list("error" = "Файл шаблона пуст.")

	var/list/raw_definition = json_decode(json_text)
	var/list/validation_result = world_edit_validate_blueprint_definition(raw_definition)
	if(validation_result["error"])
		return validation_result

	var/list/blueprint = validation_result["blueprint"]
	blueprint["file_path"] = file_path
	return list("blueprint" = blueprint)

/datum/world_edit_blueprint_service/proc/world_edit_load_blueprint_library_summaries()
	. = list()

	if(!world_edit_ensure_blueprint_storage_dir())
		return

	var/list/file_names = flist(WORLD_EDIT_BLUEPRINT_DIR)
	if(!islist(file_names) || !length(file_names))
		return

	file_names = sortList(file_names)
	for(var/file_name in file_names)
		if(lowertext(copytext("[file_name]", length("[file_name]") - 4, 0)) != ".json")
			continue

		var/file_path = "[WORLD_EDIT_BLUEPRINT_DIR][file_name]"
		var/list/load_result = world_edit_load_blueprint_from_file(file_path)
		if(load_result["error"])
			. += list(list(
				"id" = sanitize_filename("[file_name]"),
				"name" = "[file_name]",
				"entry_count" = 0,
				"radius" = 0,
				"footprint_width" = 0,
				"footprint_height" = 0,
				"created_at" = "",
				"created_by" = "",
				"source" = "file",
				"valid" = FALSE,
				"error" = load_result["error"],
				"file_path" = file_path,
			))
			continue

		. += list(world_edit_build_blueprint_summary(load_result["blueprint"], file_path, TRUE))

/datum/world_edit_blueprint_service/proc/world_edit_save_blueprint_definition(list/blueprint)
	if(!islist(blueprint))
		return FALSE
	if(!world_edit_ensure_blueprint_storage_dir())
		return FALSE

	var/blueprint_id = sanitize_filename("[blueprint["id"]]")
	if(!length(blueprint_id))
		return FALSE

	var/list/entries = blueprint["entries"]
	var/list/bounds = blueprint["bounds"]
	if(!islist(entries) || !length(entries) || !islist(bounds))
		return FALSE

	var/file_path = world_edit_get_blueprint_file_path(blueprint_id)
	if(!file_path)
		return FALSE

	var/list/file_payload = list(
		"schema" = WORLD_EDIT_BLUEPRINT_SCHEMA,
		"version" = WORLD_EDIT_BLUEPRINT_VERSION,
		"id" = blueprint_id,
		"name" = copytext(trim(sanitize_text("[blueprint["name"]]", blueprint_id)), 1, WORLD_EDIT_BLUEPRINT_NAME_MAX_LEN + 1),
		"created_at" = blueprint["created_at"] || time_stamp(),
		"created_by" = ckey("[blueprint["created_by"]]"),
		"source" = blueprint["source"] || "server",
		"bounds" = bounds,
		"entries" = entries,
	)
	if(islist(blueprint["outpost_recipe"]))
		file_payload["outpost_recipe"] = blueprint["outpost_recipe"]

	var/serialized_payload = json_encode(file_payload)
	rustg_file_write(serialized_payload, file_path)
	if(!fexists(file_path))
		return FALSE
	if(file2text(file_path) != serialized_payload)
		return FALSE
	return file_path
