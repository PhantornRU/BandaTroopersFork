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
		var/coord_key = world_edit_build_blueprint_relative_slot_key(obj_path, dx, dy, 0, dir_value)
		if(!length(coord_key))
			return list("error" = "Current plan contains an invalid directional placement slot.")
		if(relative_coord_lookup[coord_key])
			return list("error" = "Current plan contains multiple placements for the same relative slot.")
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
	return GLOB.world_edit_helpers.has_dense_nonmob_blocker(target_turf)

/datum/world_edit_blueprint_service/proc/world_edit_build_blueprint_relative_slot_key(obj_path, dx, dy, dz, dir_value)
	if(ispath(obj_path, /obj/structure/barricade))
		if(!(dir_value in GLOB.cardinals))
			return null
		return "[dx],[dy],[dz]:[dir_value]"
	return "[dx],[dy],[dz]"

/datum/world_edit_blueprint_service/proc/world_edit_build_blueprint_target_slot_key(turf/target_turf, obj_path, dir_value)
	if(!istype(target_turf))
		return null
	if(ispath(obj_path, /obj/structure/barricade))
		return GLOB.world_edit_helpers.build_turf_dir_slot_key(target_turf, dir_value)
	return "[target_turf.x],[target_turf.y],[target_turf.z]"

/datum/world_edit_blueprint_service/proc/world_edit_validate_blueprint_target_turf(turf/target_turf, obj_path, dir_value = SOUTH)
	if(!world_edit_is_open_construction_turf_for_blueprint(target_turf))
		return "Blueprint target must be an open construction turf."

	if(ispath(obj_path, /obj/structure/barricade))
		if(GLOB.world_edit_helpers.has_dense_nonmob_blocker(target_turf, TRUE))
			return "Blueprint target turf is blocked for a barricade."
		if(GLOB.world_edit_helpers.has_barricade_in_dir(target_turf, dir_value))
			return "Blueprint target turf already contains a barricade on that side."
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
	var/list/placement_lookup = list()
	var/blocked_entry_count = 0
	var/duplicate_entry_count = 0
	for(var/list/entry as anything in entries)
		var/obj_path = text2path("[entry["type"]]")
		var/list/rotated_offset = world_edit_rotate_blueprint_offset(text2num("[entry["dx"]]"), text2num("[entry["dy"]]"), placement_dir)
		var/turf/target_turf = locate(anchor_turf.x + rotated_offset["dx"], anchor_turf.y + rotated_offset["dy"], anchor_turf.z)
		if(!istype(target_turf))
			plan.metadata["error"] = "Blueprint points outside the current z-level bounds."
			return plan

		var/dir_value = world_edit_rotate_blueprint_dir(text2num("[entry["dir"]]"), placement_dir)
		var/placement_key = world_edit_build_blueprint_target_slot_key(target_turf, obj_path, dir_value)
		if(!length(placement_key))
			plan.metadata["error"] = "Blueprint contains an invalid directional placement slot."
			return plan
		if(placement_lookup[placement_key])
			duplicate_entry_count++
			continue

		var/error_text = world_edit_validate_blueprint_target_turf(target_turf, obj_path, dir_value)
		if(error_text)
			if(error_text == "Blueprint contains an unsupported placement type.")
				plan.metadata["error"] = error_text
				return plan
			if(isnull(plan.metadata["first_blocked_turf"]))
				plan.metadata["first_blocked_turf"] = "[target_turf.x],[target_turf.y],[target_turf.z]"
			blocked_entry_count++
			continue

		placement_lookup[placement_key] = TRUE
		affected_lookup[target_turf] = TRUE
		plan.placements += list(list(
			"kind" = "blueprint_spawn",
			"obj_path" = obj_path,
			"turf" = target_turf,
			"dir" = dir_value,
			"vars" = entry["vars"] || list(),
		))

	for(var/turf/affected_turf as anything in affected_lookup)
		plan.affected_turfs += affected_turf

	plan.metadata["center_turf"] = anchor_turf
	plan.metadata["blueprint_id"] = blueprint["id"]
	plan.metadata["blueprint_name"] = blueprint["name"]
	plan.metadata["entry_count"] = length(plan.placements)
	plan.metadata["blocked_entry_count"] = blocked_entry_count
	plan.metadata["duplicate_entry_count"] = duplicate_entry_count
	plan.metadata["skipped_entry_count"] = blocked_entry_count + duplicate_entry_count
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
