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

/datum/world_edit_blueprint_service/proc/world_edit_validate_outpost_recipe_footprint_offsets(raw_offsets)
	if(isnull(raw_offsets))
		return list("footprint_offsets" = list(list(0, 0)))
	if(!islist(raw_offsets) || !length(raw_offsets))
		return list("error" = "Blueprint outpost_recipe footprint_offsets must contain at least one offset.")

	var/list/sanitized_offsets = list()
	var/list/offset_lookup = list()
	for(var/raw_offset as anything in raw_offsets)
		if(!islist(raw_offset) || length(raw_offset) < 2)
			return list("error" = "Blueprint outpost_recipe footprint_offsets entries must be (dx, dy) lists.")
		var/dx = world_edit_parse_strict_integer(raw_offset[1])
		var/dy = world_edit_parse_strict_integer(raw_offset[2])
		if(isnull(dx) || isnull(dy))
			return list("error" = "Blueprint outpost_recipe footprint offsets must be numeric.")
		var/offset_key = "[dx],[dy]"
		if(offset_lookup[offset_key])
			continue
		offset_lookup[offset_key] = TRUE
		sanitized_offsets += list(list(dx, dy))

	if(!length(sanitized_offsets))
		sanitized_offsets += list(list(0, 0))
	return list("footprint_offsets" = sanitized_offsets)

/datum/world_edit_blueprint_service/proc/world_edit_validate_outpost_recipe(raw_recipe)
	if(isnull(raw_recipe))
		return list("outpost_recipe" = null)
	if(!islist(raw_recipe))
		return list("error" = "Blueprint outpost_recipe payload must be an object.")

	var/family = trim(sanitize_text("[raw_recipe["family"]]", ""))
	var/layout_variant = trim(sanitize_text("[raw_recipe["layout_variant"]]", ""))
	if(!length(family) || !length(layout_variant))
		return list("error" = "Blueprint outpost_recipe must include family and layout_variant.")

	var/placement_dir = text2num("[raw_recipe["placement_dir"]]")
	if(!(placement_dir in GLOB.cardinals))
		return list("error" = "Blueprint outpost_recipe placement_dir must be cardinal.")

	var/radius = world_edit_parse_strict_integer(raw_recipe["radius"])
	if(isnull(radius) || radius < 1 || radius > 25)
		return list("error" = "Blueprint outpost_recipe radius must be in the range 1..25.")

	var/opening_width = world_edit_parse_strict_integer(raw_recipe["opening_width"])
	if(isnull(opening_width) || opening_width < 1 || opening_width > (radius * 2) + 1)
		return list("error" = "Blueprint outpost_recipe opening_width is invalid for the stored radius.")

	var/guard_mode = "[raw_recipe["guard_mode"] || "layout"]"
	if(!(guard_mode in list("layout", "openings", "all_sides")))
		return list("error" = "Blueprint outpost_recipe guard_mode is unsupported.")

	var/sentry_profile = lowertext("[raw_recipe["sentry_profile"] || "entry_guard"]")
	if(!(sentry_profile in list("none", "light_cover", "entry_guard", "inner_guard", "crossfire")))
		return list("error" = "Blueprint outpost_recipe sentry_profile is unsupported.")

	var/place_sentries = GLOB.world_edit_helpers.parse_bool(raw_recipe["place_sentries"]) ? TRUE : FALSE
	var/place_barricade_doors = GLOB.world_edit_helpers.parse_bool(raw_recipe["place_barricade_doors"]) ? TRUE : FALSE
	var/turned_on = GLOB.world_edit_helpers.parse_bool(raw_recipe["turned_on"]) ? TRUE : FALSE

	var/barricade_pattern = lowertext("[raw_recipe["barricade_pattern"] || "uniform"]")
	if(!(barricade_pattern in list("uniform", "cycle", "paired")))
		return list("error" = "Blueprint outpost_recipe barricade_pattern is unsupported.")

	var/barricade_concentration_percent = world_edit_parse_strict_integer(raw_recipe["barricade_concentration_percent"])
	if(isnull(barricade_concentration_percent))
		barricade_concentration_percent = 0
	if(barricade_concentration_percent < 0 || barricade_concentration_percent > 100)
		return list("error" = "Blueprint outpost_recipe barricade_concentration_percent must be in the range 0..100.")

	var/barricade_path = text2path("[raw_recipe["barricade_path"]]")
	if(!ispath(barricade_path, /datum/human_ai_defense/barricade))
		return list("error" = "Blueprint outpost_recipe barricade_path must be a barricade definition path.")

	var/sentry_path = null
	if(!isnull(raw_recipe["sentry_path"]) && length("[raw_recipe["sentry_path"]]") && "[raw_recipe["sentry_path"]]" != "null")
		sentry_path = text2path("[raw_recipe["sentry_path"]]")
		if(!ispath(sentry_path, /datum/human_ai_defense/defense/sentry))
			return list("error" = "Blueprint outpost_recipe sentry_path must be a sentry definition path.")

	var/faction = "[raw_recipe["faction"] || ""]"
	if(length(faction) && !(faction in GLOB.world_edit_blueprint_valid_factions))
		return list("error" = "Blueprint outpost_recipe contains an invalid faction.")

	var/list/footprint_result = world_edit_validate_outpost_recipe_footprint_offsets(raw_recipe["footprint_offsets"])
	if(footprint_result["error"])
		return footprint_result

	return list("outpost_recipe" = list(
		"family" = family,
		"layout_variant" = layout_variant,
		"placement_dir" = placement_dir,
		"radius" = radius,
		"opening_width" = opening_width,
		"guard_mode" = guard_mode,
		"sentry_profile" = sentry_profile,
		"place_sentries" = place_sentries,
		"barricade_path" = "[barricade_path]",
		"barricade_pattern" = barricade_pattern,
		"barricade_concentration_percent" = barricade_concentration_percent,
		"place_barricade_doors" = place_barricade_doors,
		"sentry_path" = sentry_path ? "[sentry_path]" : null,
		"faction" = faction,
		"turned_on" = turned_on,
		"footprint_offsets" = footprint_result["footprint_offsets"],
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

	var/list/outpost_recipe_result = world_edit_validate_outpost_recipe(raw_definition["outpost_recipe"])
	if(outpost_recipe_result["error"])
		return outpost_recipe_result

	return list("blueprint" = list(
		"id" = blueprint_id,
		"name" = blueprint_name,
		"created_at" = "[raw_definition["created_at"] || ""]",
		"created_by" = ckey("[raw_definition["created_by"]]"),
		"source" = "[raw_definition["source"] || "server"]",
		"bounds" = computed_bounds,
		"entries" = sanitized_entries,
		"outpost_recipe" = outpost_recipe_result["outpost_recipe"],
	))

/datum/world_edit_blueprint_service/proc/world_edit_build_blueprint_summary(list/blueprint, file_path = null, valid = TRUE, error_text = "")
	var/list/bounds = blueprint["bounds"] || list()
	var/footprint_width = (bounds["max_x"] - bounds["min_x"]) + 1
	var/footprint_height = (bounds["max_y"] - bounds["min_y"]) + 1
	var/list/summary = list(
		"id" = blueprint["id"],
		"name" = blueprint["name"],
		"entry_count" = length(blueprint["entries"]),
		"radius" = bounds["radius"] || 0,
		"footprint_width" = max(footprint_width, 0),
		"footprint_height" = max(footprint_height, 0),
		"created_at" = blueprint["created_at"] || "",
		"created_by" = blueprint["created_by"] || "",
		"source" = blueprint["source"] || "",
		"valid" = valid ? TRUE : FALSE,
		"error" = error_text,
	)
	if(file_path)
		summary["file_path"] = file_path
	if(islist(blueprint["outpost_recipe"]))
		summary["has_outpost_recipe"] = TRUE
		summary["outpost_family"] = blueprint["outpost_recipe"]["family"] || ""
		summary["outpost_layout_variant"] = blueprint["outpost_recipe"]["layout_variant"] || ""
	return summary
