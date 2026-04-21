/datum/world_edit_blueprint_service/proc/world_edit_resolve_defense_spawn_path(defense_path)
	if(!ispath(defense_path, /datum/human_ai_defense))
		return null

	var/datum/human_ai_defense/definition = new defense_path()
	var/obj_path = definition.path_to_spawn
	qdel(definition)
	return obj_path

/datum/world_edit_blueprint_service/proc/world_edit_build_outpost_recipe_footprint_offsets(datum/world_edit_plan/plan, turf/anchor_turf)
	var/list/offsets = list()
	if(!istype(anchor_turf))
		return offsets
	if("[plan?.metadata["shape_mode"]]" != "footprint_offset")
		return list(list(0, 0))

	var/list/footprint_turfs = islist(plan?.metadata["base_shape_turfs"]) ? plan.metadata["base_shape_turfs"] : null
	if(!islist(footprint_turfs) || !length(footprint_turfs))
		return list(list(0, 0))

	var/list/offset_lookup = list()
	for(var/turf/footprint_turf as anything in footprint_turfs)
		if(!istype(footprint_turf) || footprint_turf.z != anchor_turf.z)
			continue
		var/dx = footprint_turf.x - anchor_turf.x
		var/dy = footprint_turf.y - anchor_turf.y
		var/offset_key = "[dx],[dy]"
		if(offset_lookup[offset_key])
			continue
		offset_lookup[offset_key] = TRUE
		offsets += list(list(dx, dy))

	if(!length(offsets))
		offsets += list(list(0, 0))
	return offsets

/datum/world_edit_blueprint_service/proc/world_edit_build_outpost_recipe_from_plan(datum/world_edit_plan/plan, turf/anchor_turf)
	if(!istype(plan) || !istype(anchor_turf))
		return null

	var/list/metadata = islist(plan.metadata) ? plan.metadata : list()
	if(!length("[metadata["family"]]") || !length("[metadata["layout_variant"]]"))
		return null

	return list(
		"family" = "[metadata["family"]]",
		"layout_variant" = "[metadata["layout_variant"]]",
		"placement_dir" = text2num("[metadata["placement_dir"]]") || NORTH,
		"radius" = text2num("[metadata["radius"]]") || 0,
		"opening_width" = text2num("[metadata["opening_width"]]") || 1,
		"guard_mode" = "[metadata["guard_mode"] || "layout"]",
		"sentry_profile" = "[metadata["sentry_profile"] || "entry_guard"]",
		"place_sentries" = GLOB.world_edit_helpers.parse_bool(metadata["place_sentries"]) ? TRUE : FALSE,
		"barricade_path" = "[metadata["barricade_path"]]",
		"barricade_pattern" = "[metadata["barricade_pattern"] || "uniform"]",
		"barricade_concentration_percent" = text2num("[metadata["barricade_concentration_percent"]]") || 0,
		"place_barricade_doors" = GLOB.world_edit_helpers.parse_bool(metadata["place_barricade_doors"]) ? TRUE : FALSE,
		"sentry_path" = metadata["sentry_path"] ? "[metadata["sentry_path"]]" : null,
		"faction" = "[metadata["faction"] || ""]",
		"turned_on" = GLOB.world_edit_helpers.parse_bool(metadata["turned_on"]) ? TRUE : FALSE,
		"footprint_offsets" = world_edit_build_outpost_recipe_footprint_offsets(plan, anchor_turf),
	)

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

	var/list/outpost_recipe = world_edit_build_outpost_recipe_from_plan(plan, anchor_turf)

	return list("blueprint" = list(
		"id" = world_edit_build_blueprint_id(),
		"name" = copytext(trim(sanitize_text("[blueprint_name]", "Outpost Blueprint")), 1, WORLD_EDIT_BLUEPRINT_NAME_MAX_LEN + 1),
		"created_at" = time_stamp(),
		"created_by" = ckey("[actor_ckey]"),
		"source" = "outpost_radius_plan",
		"bounds" = bounds,
		"entries" = entries,
		"outpost_recipe" = outpost_recipe,
	))
