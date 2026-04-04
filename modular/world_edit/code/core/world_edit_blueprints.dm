#define WORLD_EDIT_BLUEPRINT_SCHEMA "world_edit_blueprint_lite"
#define WORLD_EDIT_BLUEPRINT_VERSION 1
#define WORLD_EDIT_BLUEPRINT_DIR "data/world_edit/blueprints/"
#define WORLD_EDIT_BLUEPRINT_ID_LEN 12
#define WORLD_EDIT_BLUEPRINT_NAME_MAX_LEN 64
#define WORLD_EDIT_BLUEPRINT_MAX_ENTRIES 68
#define WORLD_EDIT_BLUEPRINT_MAX_RADIUS 8

GLOBAL_LIST_INIT(world_edit_blueprint_valid_factions, list(
	FACTION_MARINE,
	FACTION_UA_REBEL,
	FACTION_UPP,
	FACTION_CANC,
	FACTION_WY,
	FACTION_FREELANCER,
	FACTION_TWE,
	FACTION_TWE_REBEL,
	FACTION_MERCENARY,
))

GLOBAL_DATUM_INIT(world_edit_blueprints, /datum/world_edit_blueprint_service, new)

/datum/world_edit_blueprint_service
	var/list/world_edit_blueprint_type_rules = list()

/datum/world_edit_blueprint_service/New()
	. = ..()
	world_edit_blueprint_type_rules = world_edit_build_blueprint_type_rules()

/datum/world_edit_blueprint_service/proc/world_edit_build_blueprint_type_rules()
	. = list()

	world_edit_register_blueprint_type(., /obj/structure/barricade/metal, "barricade", "Metal Barricade")
	world_edit_register_blueprint_type(., /obj/structure/barricade/metal/wired, "barricade", "Metal Barricade - Wired")
	world_edit_register_blueprint_type(., /obj/structure/barricade/sandbags/full, "barricade", "Sandbags")
	world_edit_register_blueprint_type(., /obj/structure/barricade/metal/plasteel, "barricade", "Plasteel Barricade")
	world_edit_register_blueprint_type(., /obj/structure/barricade/metal/plasteel/wired, "barricade", "Plasteel Barricade - Wired")
	world_edit_register_blueprint_type(., /obj/structure/barricade/wooden, "barricade", "Wooden Barricade")

	world_edit_register_blueprint_type(., /obj/structure/machinery/defenses/sentry, "sentry", "USCM Sentry")
	world_edit_register_blueprint_type(., /obj/structure/machinery/defenses/sentry/dmr, "sentry", "USCM Sentry - DMR")
	world_edit_register_blueprint_type(., /obj/structure/machinery/defenses/sentry/shotgun, "sentry", "USCM Sentry - Shotgun")
	world_edit_register_blueprint_type(., /obj/structure/machinery/defenses/sentry/mini, "sentry", "USCM Sentry - Mini")
	world_edit_register_blueprint_type(., /obj/structure/machinery/defenses/sentry/upp, "sentry", "UPP Sentry")
	world_edit_register_blueprint_type(., /obj/structure/machinery/defenses/sentry/wy, "sentry", "W-Y Sentry")

/datum/world_edit_blueprint_service/proc/world_edit_register_blueprint_type(list/rules, obj_path, category, label)
	rules["[obj_path]"] = list(
		"obj_path" = obj_path,
		"category" = category,
		"label" = label,
	)

/datum/world_edit_blueprint_service/proc/world_edit_get_blueprint_type_rule(obj_path)
	if(!ispath(obj_path, /obj))
		return null
	return world_edit_blueprint_type_rules["[obj_path]"]

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

/datum/world_edit_blueprint_service/proc/world_edit_validate_blueprint_entry(list/raw_entry)
	if(!islist(raw_entry))
		return list("error" = "Blueprint entry must be a list.")

	var/type_text = "[raw_entry["type"]]"
	var/obj_path = text2path(type_text)
	var/list/rule = world_edit_get_blueprint_type_rule(obj_path)
	if(!rule)
		return list("error" = "Blueprint contains a non-whitelisted type '[type_text]'.")

	var/dx = text2num("[raw_entry["dx"]]")
	var/dy = text2num("[raw_entry["dy"]]")
	var/dz = text2num("[raw_entry["dz"]]")
	if(!isnum(dx) || !isnum(dy) || !isnum(dz))
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
		var/coord_key = "[sanitized_entry["dx"]],[sanitized_entry["dy"]],[sanitized_entry["dz"]]"
		if(relative_coord_lookup[coord_key])
			return list("error" = "Blueprint contains multiple placements for the same relative turf.")
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

/datum/world_edit_blueprint_service/proc/world_edit_load_blueprint_from_file(file_path)
	if(!file_path || !fexists(file_path))
		return list("error" = "Blueprint file was not found.")

	var/json_text = file2text(file_path)
	if(!length(json_text))
		return list("error" = "Blueprint file is empty.")

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

	rustg_file_write(json_encode(file_payload), file_path)
	return file_path

/datum/world_edit_blueprint_service/proc/world_edit_resolve_defense_spawn_path(defense_path)
	if(!ispath(defense_path, /datum/human_ai_defense))
		return null

	var/datum/human_ai_defense/definition = new defense_path()
	var/obj_path = definition.path_to_spawn
	qdel(definition)
	return obj_path

/datum/world_edit_blueprint_service/proc/world_edit_export_blueprint_from_outpost_plan(datum/world_edit_plan/plan, turf/anchor_turf, blueprint_name, actor_ckey)
	if(!istype(plan))
		return list("error" = "No built outpost plan is available.")
	if(!anchor_turf)
		return list("error" = "Unable to resolve the blueprint anchor turf.")
	if(!length(plan.placements))
		return list("error" = "Current outpost plan contains no placeable entries.")

	var/list/entries = list()
	var/list/spawn_path_cache = list()
	var/list/relative_coord_lookup = list()
	for(var/list/placement as anything in plan.placements)
		var/placement_kind = "[placement["kind"]]"
		if(!(placement_kind in list("barricade", "sentry")))
			return list("error" = "Current plan contains a placement kind that Blueprint Lite does not support.")

		var/turf/target_turf = placement["turf"]
		if(!istype(target_turf) || target_turf.z != anchor_turf.z)
			return list("error" = "Current plan contains a placement outside the allowed z-level.")

		var/defense_path = placement["defense_path"]
		var/obj_path = spawn_path_cache["[defense_path]"]
		if(!obj_path)
			obj_path = world_edit_resolve_defense_spawn_path(defense_path)
			spawn_path_cache["[defense_path]"] = obj_path

		var/list/rule = world_edit_get_blueprint_type_rule(obj_path)
		if(!rule)
			return list("error" = "Current plan contains a non-whitelisted placeable type.")

		var/dir_value = text2num("[placement["dir"]]")
		if(!(dir_value in GLOB.cardinals))
			return list("error" = "Current plan contains a non-cardinal dir.")

		var/list/entry_vars = list()
		if(placement_kind == "sentry")
			var/faction = "[placement["faction"]]"
			if(!(faction in GLOB.world_edit_blueprint_valid_factions))
				return list("error" = "Current plan contains an invalid sentry faction.")
			entry_vars["faction"] = faction
			entry_vars["turned_on"] = GLOB.world_edit_helpers.parse_bool(placement["turned_on"]) ? TRUE : FALSE

		var/dx = target_turf.x - anchor_turf.x
		var/dy = target_turf.y - anchor_turf.y
		var/coord_key = "[dx],[dy],0"
		if(relative_coord_lookup[coord_key])
			return list("error" = "Current plan contains multiple placements for the same relative turf.")
		relative_coord_lookup[coord_key] = TRUE

		entries += list(list(
			"type" = "[obj_path]",
			"dx" = dx,
			"dy" = dy,
			"dz" = 0,
			"dir" = dir_value,
			"vars" = entry_vars,
		))

	if(length(entries) > WORLD_EDIT_BLUEPRINT_MAX_ENTRIES)
		return list("error" = "Current plan exceeds the Blueprint Lite entry cap.")

	var/list/bounds = world_edit_compute_blueprint_bounds(entries)
	if(bounds["radius"] > WORLD_EDIT_BLUEPRINT_MAX_RADIUS)
		return list("error" = "Current plan exceeds the Blueprint Lite radius cap.")

	return list("blueprint" = list(
		"id" = world_edit_build_blueprint_id(),
		"name" = copytext(trim(sanitize_text("[blueprint_name]", "Outpost Blueprint")), 1, WORLD_EDIT_BLUEPRINT_NAME_MAX_LEN + 1),
		"created_at" = time_stamp(),
		"created_by" = ckey("[actor_ckey]"),
		"source" = "outpost_radius_plan",
		"bounds" = bounds,
		"entries" = entries,
	))

/datum/world_edit_blueprint_service/proc/world_edit_is_open_construction_turf_for_blueprint(turf/target_turf)
	if(!istype(target_turf, /turf/open))
		return FALSE

	var/turf/open/open_turf = target_turf
	return open_turf.allow_construction ? TRUE : FALSE

/datum/world_edit_blueprint_service/proc/world_edit_has_dense_blocker_for_blueprint(turf/target_turf)
	if(!target_turf)
		return TRUE
	for(var/atom/movable/blocker as anything in target_turf)
		if(ismob(blocker))
			continue
		if(blocker.density)
			return TRUE
	return FALSE

/datum/world_edit_blueprint_service/proc/world_edit_validate_blueprint_target_turf(turf/target_turf, obj_path)
	if(!world_edit_is_open_construction_turf_for_blueprint(target_turf))
		return "Blueprint target must be an open construction turf."

	if(ispath(obj_path, /obj/structure/barricade))
		if(world_edit_has_dense_blocker_for_blueprint(target_turf))
			return "Blueprint target turf is blocked for a barricade."
		for(var/obj/structure/barricade/existing_barricade in target_turf)
			return "Blueprint target turf already contains a barricade."
		return null

	if(ispath(obj_path, /obj/structure/machinery/defenses))
		if(world_edit_has_dense_blocker_for_blueprint(target_turf))
			return "Blueprint target turf is blocked for a sentry."
		for(var/obj/structure/machinery/defenses/existing_defense in target_turf)
			return "Blueprint target turf already contains a defense structure."
		return null

	return "Blueprint contains an unsupported placement type."

/datum/world_edit_blueprint_service/proc/world_edit_rotate_blueprint_offset(dx, dy, placement_dir)
	switch(placement_dir)
		if(EAST)
			return list("dx" = dy, "dy" = -dx)
		if(SOUTH)
			return list("dx" = -dx, "dy" = -dy)
		if(WEST)
			return list("dx" = -dy, "dy" = dx)
		else
			return list("dx" = dx, "dy" = dy)

/datum/world_edit_blueprint_service/proc/world_edit_rotate_blueprint_dir(dir_value, placement_dir)
	if(!(dir_value in GLOB.cardinals))
		return dir_value

	switch(placement_dir)
		if(EAST)
			switch(dir_value)
				if(NORTH)
					return EAST
				if(EAST)
					return SOUTH
				if(SOUTH)
					return WEST
				if(WEST)
					return NORTH
		if(SOUTH)
			switch(dir_value)
				if(NORTH)
					return SOUTH
				if(EAST)
					return WEST
				if(SOUTH)
					return NORTH
				if(WEST)
					return EAST
		if(WEST)
			switch(dir_value)
				if(NORTH)
					return WEST
				if(EAST)
					return NORTH
				if(SOUTH)
					return EAST
				if(WEST)
					return SOUTH
	return dir_value

/datum/world_edit_blueprint_service/proc/world_edit_build_plan_from_blueprint(list/blueprint, turf/anchor_turf, placement_dir = NORTH)
	var/datum/world_edit_plan/plan = new
	if(!anchor_turf)
		plan.metadata["error"] = "Unable to resolve the blueprint anchor turf."
		return plan

	if(!islist(blueprint))
		plan.metadata["error"] = "Blueprint payload is missing."
		return plan

	var/list/entries = blueprint["entries"]
	if(!islist(entries) || !length(entries))
		plan.metadata["error"] = "Blueprint contains no entries."
		return plan

	var/list/affected_lookup = list()
	for(var/list/entry as anything in entries)
		var/obj_path = text2path("[entry["type"]]")
		var/list/rotated_offset = world_edit_rotate_blueprint_offset(text2num("[entry["dx"]]"), text2num("[entry["dy"]]"), placement_dir)
		var/turf/target_turf = locate(anchor_turf.x + rotated_offset["dx"], anchor_turf.y + rotated_offset["dy"], anchor_turf.z)
		if(!istype(target_turf))
			plan.metadata["error"] = "Blueprint points outside the current z-level bounds."
			return plan
		if(affected_lookup[target_turf])
			plan.metadata["error"] = "Blueprint contains multiple placements for the same turf."
			return plan

		var/error_text = world_edit_validate_blueprint_target_turf(target_turf, obj_path)
		if(error_text)
			plan.metadata["error"] = error_text
			plan.metadata["blocked_turf"] = "[target_turf.x],[target_turf.y],[target_turf.z]"
			return plan

		affected_lookup[target_turf] = TRUE
		plan.placements += list(list(
			"kind" = "blueprint_spawn",
			"obj_path" = obj_path,
			"turf" = target_turf,
			"dir" = world_edit_rotate_blueprint_dir(text2num("[entry["dir"]]"), placement_dir),
			"vars" = entry["vars"] || list(),
		))

	for(var/turf/affected_turf as anything in affected_lookup)
		plan.affected_turfs += affected_turf

	plan.metadata["center_turf"] = anchor_turf
	plan.metadata["blueprint_id"] = blueprint["id"]
	plan.metadata["blueprint_name"] = blueprint["name"]
	plan.metadata["entry_count"] = length(plan.placements)
	plan.metadata["radius"] = blueprint["bounds"] ? blueprint["bounds"]["radius"] : 0
	plan.metadata["placement_dir"] = placement_dir
	plan.metadata["placement_dir_label"] = GLOB.world_edit_helpers.dir_to_label(placement_dir)
	return plan

/datum/world_edit_blueprint_service/proc/world_edit_spawn_blueprint_entry(list/placement)
	var/obj_path = placement["obj_path"]
	var/turf/target_turf = placement["turf"]
	var/dir_value = placement["dir"]
	var/list/entry_vars = placement["vars"] || list()
	if(!istype(target_turf) || !ispath(obj_path, /obj))
		return null

	if(ispath(obj_path, /obj/structure/barricade))
		var/obj/structure/barricade/barricade = new obj_path(target_turf)
		barricade.setDir(dir_value)
		return barricade

	if(ispath(obj_path, /obj/structure/machinery/defenses))
		var/obj/structure/machinery/defenses/defense = new obj_path(target_turf)
		defense.setDir(dir_value)
		defense.placed = TRUE
		if(entry_vars["faction"])
			defense.handle_iff(entry_vars["faction"])
		if(GLOB.world_edit_helpers.parse_bool(entry_vars["turned_on"]))
			defense.power_on()
		else
			defense.power_off()
		return defense

	return null

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

/datum/world_edit_manager/proc/fail_blueprint_action(mob/user, message)
	last_ui_error = message
	to_chat(user, SPAN_WARNING(message))
	return FALSE

/datum/world_edit_manager/proc/load_blueprint_definition_by_id(blueprint_id)
	var/list/entry = find_cached_blueprint_entry(blueprint_id)
	if(!entry)
		return list("error" = "Blueprint не найден.")
	if(!entry["valid"])
		return list("error" = entry["error"] || "Blueprint невалиден.")
	return GLOB.world_edit_blueprints.world_edit_load_blueprint_from_file(entry["file_path"])

/datum/world_edit_manager/proc/activate_blueprint_generator(mob/user, blueprint_id, preserve_valid_preview = FALSE)
	var/list/load_result = load_blueprint_definition_by_id(blueprint_id)
	if(load_result["error"])
		return fail_blueprint_action(user, load_result["error"])

	var/current_blueprint_id = get_active_blueprint_id()
	if(preserve_valid_preview && current_definition?.id == "blueprint_stamp" && current_blueprint_id == "[blueprint_id]" && is_preview_state_valid())
		last_ui_error = ""
		return TRUE

	if(!set_generator_by_id("blueprint_stamp"))
		return fail_blueprint_action(user, "Не удалось активировать blueprint stamp generator.")

	current_params["blueprint_id"] = "[blueprint_id]"
	reset_preview_runtime()
	last_ui_error = ""
	return TRUE

/datum/world_edit_manager/proc/load_blueprint_into_manager(mob/user, blueprint_id)
	if(!activate_blueprint_generator(user, blueprint_id, FALSE))
		return FALSE

	to_chat(user, SPAN_NOTICE("Blueprint '[blueprint_id]' загружен в blueprint stamp generator."))
	return TRUE

/datum/world_edit_manager/proc/preview_blueprint_by_id(mob/user, blueprint_id)
	if(!activate_blueprint_generator(user, blueprint_id, FALSE))
		return FALSE
	run_preview(user)
	return TRUE

/datum/world_edit_manager/proc/apply_blueprint_by_id(mob/user, blueprint_id)
	if(!activate_blueprint_generator(user, blueprint_id, TRUE))
		return FALSE
	if(!is_preview_state_valid())
		return fail_blueprint_action(user, "Сначала выполните preview выбранного blueprint.")
	run_apply(user)
	return TRUE

/datum/world_edit_manager/proc/can_save_blueprint_from_current_plan()
	if(current_definition?.id != "outpost_radius")
		return FALSE
	return istype(current_generator?.current_plan, /datum/world_edit_plan)

/datum/world_edit_manager/proc/save_blueprint_from_current_plan(mob/user)
	if(!can_save_blueprint_from_current_plan())
		return fail_blueprint_action(user, "Сначала выполните preview outpost_radius для сохранения blueprint.")

	var/datum/world_edit_plan/current_plan = current_generator.current_plan
	var/turf/anchor_turf = current_plan?.metadata["center_turf"]
	if(!anchor_turf)
		anchor_turf = get_turf(user)

	var/default_name = "Outpost Blueprint"
	var/raw_name = tgui_input_text(user, "Введите имя blueprint. Сохраняется только bounded outpost plan текущего preview.", "World Edit: Save Blueprint", default_name, WORLD_EDIT_BLUEPRINT_NAME_MAX_LEN, FALSE, FALSE)
	if(isnull(raw_name))
		return FALSE

	var/blueprint_name = trim(sanitize_text("[raw_name]", ""))
	if(!length(blueprint_name))
		blueprint_name = default_name

	var/list/export_result = GLOB.world_edit_blueprints.world_edit_export_blueprint_from_outpost_plan(current_plan, anchor_turf, blueprint_name, holder?.ckey)
	if(export_result["error"])
		return fail_blueprint_action(user, export_result["error"])

	var/file_path = GLOB.world_edit_blueprints.world_edit_save_blueprint_definition(export_result["blueprint"])
	if(!file_path)
		return fail_blueprint_action(user, "Не удалось сохранить blueprint на сервере.")

	refresh_blueprint_cache()
	last_ui_error = ""
	to_chat(user, SPAN_NOTICE("Blueprint '[export_result["blueprint"]["name"]]' сохранён в библиотеку."))
	return TRUE
