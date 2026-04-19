/datum/world_edit_blueprint_service/proc/world_edit_build_blueprint_id()
	return copytext(md5("[world.realtime]-[world.time]-[rand(1, 1000000)]"), 1, WORLD_EDIT_BLUEPRINT_ID_LEN + 1)

/datum/world_edit_blueprint_service/proc/world_edit_compute_blueprint_bounds(list/entries)
	var/min_x = 0
	var/max_x = 0
	var/min_y = 0
	var/max_y = 0
	var/min_z = 0
	var/max_z = 0
	var/radius = 0
	var/is_first = TRUE

	for(var/list/entry as anything in entries)
		var/dx = text2num("[entry["dx"]]")
		var/dy = text2num("[entry["dy"]]")
		var/dz = text2num("[entry["dz"]]")
		if(is_first)
			min_x = max_x = dx
			min_y = max_y = dy
			min_z = max_z = dz
			is_first = FALSE
		else
			min_x = min(min_x, dx)
			max_x = max(max_x, dx)
			min_y = min(min_y, dy)
			max_y = max(max_y, dy)
			min_z = min(min_z, dz)
			max_z = max(max_z, dz)

		radius = max(radius, abs(dx), abs(dy))

	return list(
		"min_x" = min_x,
		"max_x" = max_x,
		"min_y" = min_y,
		"max_y" = max_y,
		"min_z" = min_z,
		"max_z" = max_z,
		"radius" = radius,
	)

/datum/world_edit_blueprint_service/proc/world_edit_blueprint_bounds_match(list/raw_bounds, list/computed_bounds)
	if(!islist(raw_bounds) || !islist(computed_bounds))
		return FALSE

	for(var/key in computed_bounds)
		if(text2num("[raw_bounds[key]]") != text2num("[computed_bounds[key]]"))
			return FALSE

	return TRUE

/datum/world_edit_blueprint_service/proc/world_edit_validate_blueprint_entry_vars(obj_path, raw_vars)
	var/list/rule = world_edit_get_blueprint_type_rule(obj_path)
	if(!rule)
		return list("error" = "Blueprint contains a non-whitelisted type.")

	var/list/safe_vars = list()
	var/category = "[rule["category"]]"
	if(isnull(raw_vars))
		return list("vars" = safe_vars)
	if(!islist(raw_vars))
		return list("error" = "Blueprint vars payload must be a list.")
	if(!length(raw_vars))
		return list("vars" = safe_vars)

	if(category != "sentry")
		return list("error" = "Vars are not allowed for '[obj_path]'.")

	for(var/var_id in raw_vars)
		var/key_text = "[var_id]"
		switch(key_text)
			if("faction")
				var/faction = "[raw_vars[var_id]]"
				if(!(faction in GLOB.world_edit_blueprint_valid_factions))
					return list("error" = "Blueprint contains an invalid sentry faction.")
				safe_vars[key_text] = faction
			if("turned_on")
				safe_vars[key_text] = GLOB.world_edit_helpers.parse_bool(raw_vars[var_id]) ? TRUE : FALSE
			else
				return list("error" = "Blueprint contains a non-whitelisted var '[key_text]'.")

	return list("vars" = safe_vars)

/datum/world_edit_blueprint_service/proc/world_edit_parse_strict_integer(raw_value)
	var/value_text = trim("[raw_value]")
	if(!length(value_text))
		return null

	var/start_index = 1
	var/first_char = copytext(value_text, 1, 2)
	if(first_char == "+" || first_char == "-")
		start_index = 2
	if(start_index > length(value_text))
		return null

	for(var/i = start_index, i <= length(value_text), i++)
		var/char = copytext(value_text, i, i + 1)
		if(!(char in list("0", "1", "2", "3", "4", "5", "6", "7", "8", "9")))
			return null

	return text2num(value_text)

/datum/world_edit_blueprint_service/proc/world_edit_validate_blueprint_entry(list/raw_entry)
	if(!islist(raw_entry))
		return list("error" = "Blueprint entry must be a list.")

	var/type_text = "[raw_entry["type"]]"
	var/obj_path = text2path(type_text)
	var/list/rule = world_edit_get_blueprint_type_rule(obj_path)
	if(!rule)
		return list("error" = "Blueprint contains a non-whitelisted type '[type_text]'.")

	var/dx = world_edit_parse_strict_integer(raw_entry["dx"])
	var/dy = world_edit_parse_strict_integer(raw_entry["dy"])
	var/dz = world_edit_parse_strict_integer(raw_entry["dz"])
	if(isnull(dx) || isnull(dy) || isnull(dz))
		return list("error" = "Blueprint coordinates must be numeric.")
	if(dz != 0)
		return list("error" = "Phase 3A blueprints must stay on the same z-level.")
	if(abs(dx) > WORLD_EDIT_BLUEPRINT_MAX_RADIUS || abs(dy) > WORLD_EDIT_BLUEPRINT_MAX_RADIUS)
		return list("error" = "Blueprint exceeds the allowed radius cap.")

	var/dir_value = SOUTH
	if("dir" in raw_entry)
		dir_value = text2num("[raw_entry["dir"]]")
		if(!(dir_value in GLOB.cardinals))
			return list("error" = "Blueprint contains a non-cardinal dir.")

	var/list/vars_result = world_edit_validate_blueprint_entry_vars(obj_path, raw_entry["vars"])
	if(vars_result["error"])
		return vars_result

	return list("entry" = list(
		"type" = "[obj_path]",
		"dx" = dx,
		"dy" = dy,
		"dz" = dz,
		"dir" = dir_value,
		"vars" = vars_result["vars"],
	))

/datum/world_edit_blueprint_service/proc/world_edit_validate_blueprint_definition(list/raw_definition)
	if(!islist(raw_definition))
		return list("error" = "Blueprint payload is not a JSON object.")
	if("[raw_definition["schema"]]" != WORLD_EDIT_BLUEPRINT_SCHEMA)
		return list("error" = "Blueprint schema is missing or unsupported.")

	var/version = text2num("[raw_definition["version"]]")
	if(version != WORLD_EDIT_BLUEPRINT_VERSION)
		return list("error" = "Blueprint version is unsupported.")

	var/blueprint_id = sanitize_filename("[raw_definition["id"]]")
	if(!length(blueprint_id))
		return list("error" = "Blueprint id is missing.")
	if(length(blueprint_id) > WORLD_EDIT_BLUEPRINT_ID_LEN)
		return list("error" = "Blueprint id exceeds the Phase 3A length cap.")

	var/blueprint_name = trim(sanitize_text("[raw_definition["name"]]", ""))
	if(!length(blueprint_name))
		blueprint_name = blueprint_id
	blueprint_name = copytext(blueprint_name, 1, WORLD_EDIT_BLUEPRINT_NAME_MAX_LEN + 1)

	var/list/raw_entries = raw_definition["entries"]
	if(!islist(raw_entries) || !length(raw_entries))
		return list("error" = "Blueprint contains no entries.")
	if(length(raw_entries) > WORLD_EDIT_BLUEPRINT_MAX_ENTRIES)
		return list("error" = "Blueprint exceeds the entry cap.")

	var/list/sanitized_entries = list()
	var/list/relative_coord_lookup = list()
	for(var/list/raw_entry as anything in raw_entries)
		var/list/entry_result = world_edit_validate_blueprint_entry(raw_entry)
		if(entry_result["error"])
			return entry_result
		var/list/sanitized_entry = entry_result["entry"]
		var/obj_path = text2path("[sanitized_entry["type"]]")
		var/coord_key = world_edit_build_blueprint_relative_slot_key(obj_path, sanitized_entry["dx"], sanitized_entry["dy"], sanitized_entry["dz"], sanitized_entry["dir"])
		if(!length(coord_key))
			return list("error" = "Blueprint contains an invalid directional placement slot.")
		if(relative_coord_lookup[coord_key])
			return list("error" = "Blueprint contains multiple placements for the same relative slot.")
		relative_coord_lookup[coord_key] = TRUE
		sanitized_entries += list(sanitized_entry)

	var/list/computed_bounds = world_edit_compute_blueprint_bounds(sanitized_entries)
	if(computed_bounds["radius"] > WORLD_EDIT_BLUEPRINT_MAX_RADIUS)
		return list("error" = "Blueprint exceeds the allowed radius cap.")

	if(!world_edit_blueprint_bounds_match(raw_definition["bounds"], computed_bounds))
		return list("error" = "Blueprint bounds metadata is stale or invalid.")

	return list("blueprint" = list(
		"id" = blueprint_id,
		"name" = blueprint_name,
		"created_at" = "[raw_definition["created_at"] || ""]",
		"created_by" = ckey("[raw_definition["created_by"]]"),
		"source" = "[raw_definition["source"] || "server"]",
		"bounds" = computed_bounds,
		"entries" = sanitized_entries,
	))

/datum/world_edit_blueprint_service/proc/world_edit_build_blueprint_summary(list/blueprint, file_path = null, valid = TRUE, error_text = "")
	var/list/bounds = blueprint["bounds"] || list()
	var/list/summary = list(
		"id" = blueprint["id"],
		"name" = blueprint["name"],
		"entry_count" = length(blueprint["entries"]),
		"radius" = bounds["radius"] || 0,
		"created_at" = blueprint["created_at"] || "",
		"created_by" = blueprint["created_by"] || "",
		"source" = blueprint["source"] || "",
		"valid" = valid ? TRUE : FALSE,
		"error" = error_text,
	)
	if(file_path)
		summary["file_path"] = file_path
	return summary
