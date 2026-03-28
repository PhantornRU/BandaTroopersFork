/datum/world_edit_generator/outpost_radius
	requires_preview_before_apply = TRUE
	var/static/list/valid_factions = list(FACTION_MARINE, FACTION_UA_REBEL, FACTION_UPP, FACTION_CANC, FACTION_WY, FACTION_FREELANCER, FACTION_TWE, FACTION_TWE_REBEL, FACTION_MERCENARY)
	var/static/list/allowed_barricade_types = list(
		/datum/human_ai_defense/barricade/metal,
		/datum/human_ai_defense/barricade/metal/wired,
		/datum/human_ai_defense/barricade/sandbag,
		/datum/human_ai_defense/barricade/plasteel,
		/datum/human_ai_defense/barricade/plasteel/wired,
		/datum/human_ai_defense/barricade/wooden,
	)
	var/static/list/allowed_sentry_types = list(
		/datum/human_ai_defense/defense/sentry/uscm,
		/datum/human_ai_defense/defense/sentry/uscm/shotgun,
		/datum/human_ai_defense/defense/sentry/uscm/dmr,
		/datum/human_ai_defense/defense/sentry/uscm/mini,
		/datum/human_ai_defense/defense/sentry/upp,
		/datum/human_ai_defense/defense/sentry/wy,
	)

/datum/world_edit_generator/outpost_radius/proc/build_type_options(list/type_list)
	var/list/options = list()
	for(var/datum/human_ai_defense/type_path as anything in type_list)
		options += list(list(
			"label" = type_path::name || "[type_path]",
			"value" = "[type_path]",
			"description" = type_path::desc || "",
		))
	return options

/datum/world_edit_generator/outpost_radius/proc/resolve_whitelisted_type(value, list/type_list, expected_root)
	var/path_value = ispath(value) ? value : text2path("[value]")
	if(!ispath(path_value, expected_root))
		return null
	if(!(path_value in type_list))
		return null
	return path_value

/datum/world_edit_generator/outpost_radius/proc/is_open_construction_turf(turf/target_turf)
	if(!istype(target_turf, /turf/open))
		return FALSE

	var/turf/open/open_turf = target_turf
	if(!open_turf.allow_construction)
		return FALSE

	return TRUE

/datum/world_edit_generator/outpost_radius/proc/has_dense_blocker(turf/target_turf)
	for(var/atom/movable/blocker as anything in target_turf)
		if(ismob(blocker))
			continue
		if(blocker.density)
			return TRUE
	return FALSE

/datum/world_edit_generator/outpost_radius/proc/can_place_barricade_on_turf(turf/target_turf)
	if(!is_open_construction_turf(target_turf))
		return FALSE
	if(has_dense_blocker(target_turf))
		return FALSE
	for(var/obj/structure/barricade/existing_barricade in target_turf)
		return FALSE
	return TRUE

/datum/world_edit_generator/outpost_radius/proc/can_place_sentry_on_turf(turf/target_turf)
	if(!is_open_construction_turf(target_turf))
		return FALSE
	if(has_dense_blocker(target_turf))
		return FALSE
	for(var/obj/structure/machinery/defenses/existing_defense in target_turf)
		return FALSE
	return TRUE

/datum/world_edit_generator/outpost_radius/proc/spawn_defense_path(turf/target_turf, dir_to_spawn, defense_path, faction = null, turned_on = FALSE)
	if(!ispath(defense_path, /datum/human_ai_defense))
		return FALSE

	var/datum/human_ai_defense/defense_definition = new defense_path()
	defense_definition.spawn_object(target_turf, dir_to_spawn, faction, turned_on)
	return TRUE

/datum/world_edit_generator/outpost_radius/proc/collect_perimeter_placements(turf/center_turf, radius)
	var/list/result = list(
		"placements" = list(),
		"blocked_count" = 0,
	)
	var/list/placements = result["placements"]

	for(var/offset_x in -radius to radius)
		var/turf/top_turf = locate(center_turf.x + offset_x, center_turf.y + radius, center_turf.z)
		if(can_place_barricade_on_turf(top_turf))
			placements += list(list("turf" = top_turf, "dir" = NORTH))
		else
			result["blocked_count"]++

		if(radius <= 0)
			continue

		var/turf/bottom_turf = locate(center_turf.x + offset_x, center_turf.y - radius, center_turf.z)
		if(can_place_barricade_on_turf(bottom_turf))
			placements += list(list("turf" = bottom_turf, "dir" = SOUTH))
		else
			result["blocked_count"]++

	if(radius <= 1)
		return result

	for(var/offset_y in (-radius + 1) to (radius - 1))
		var/turf/right_turf = locate(center_turf.x + radius, center_turf.y + offset_y, center_turf.z)
		if(can_place_barricade_on_turf(right_turf))
			placements += list(list("turf" = right_turf, "dir" = EAST))
		else
			result["blocked_count"]++

		var/turf/left_turf = locate(center_turf.x - radius, center_turf.y + offset_y, center_turf.z)
		if(can_place_barricade_on_turf(left_turf))
			placements += list(list("turf" = left_turf, "dir" = WEST))
		else
			result["blocked_count"]++

	return result

/datum/world_edit_generator/outpost_radius/proc/collect_sentry_placements(turf/center_turf, radius)
	var/list/result = list(
		"placements" = list(),
		"blocked_count" = 0,
	)
	var/list/placements = result["placements"]
	var/inner_radius = max(radius - 1, 1)
	var/list/sentry_offsets = list(
		list("dx" = 0, "dy" = inner_radius, "dir" = NORTH),
		list("dx" = 0, "dy" = -inner_radius, "dir" = SOUTH),
		list("dx" = inner_radius, "dy" = 0, "dir" = EAST),
		list("dx" = -inner_radius, "dy" = 0, "dir" = WEST),
	)

	for(var/list/offset as anything in sentry_offsets)
		var/turf/target_turf = locate(center_turf.x + offset["dx"], center_turf.y + offset["dy"], center_turf.z)
		if(can_place_sentry_on_turf(target_turf))
			placements += list(list("turf" = target_turf, "dir" = offset["dir"]))
		else
			result["blocked_count"]++

	return result

/datum/world_edit_generator/outpost_radius/proc/build_outpost_plan(turf/center_turf, list/params)
	var/radius = text2num("[params["radius"]]") || 4
	var/place_sentries = world_edit_parse_bool(params["place_sentries"])

	var/list/perimeter_data = collect_perimeter_placements(center_turf, radius)
	var/list/sentry_data = place_sentries ? collect_sentry_placements(center_turf, radius) : list(
		"placements" = list(),
		"blocked_count" = 0,
	)

	var/list/preview_turf_lookup = list()
	for(var/list/placement as anything in perimeter_data["placements"])
		preview_turf_lookup[placement["turf"]] = TRUE
	for(var/list/placement as anything in sentry_data["placements"])
		preview_turf_lookup[placement["turf"]] = TRUE

	var/list/preview_turfs = list()
	for(var/turf/preview_turf as anything in preview_turf_lookup)
		preview_turfs += preview_turf

	return list(
		"barricade_placements" = perimeter_data["placements"],
		"sentry_placements" = sentry_data["placements"],
		"preview_turfs" = preview_turfs,
		"blocked_barricades" = perimeter_data["blocked_count"],
		"blocked_sentries" = sentry_data["blocked_count"],
	)

/datum/world_edit_generator/outpost_radius/validate_params(mob/user, list/params)
	var/turf/center_turf = get_turf(user)
	if(!center_turf)
		return "Unable to resolve the anchor turf."

	var/radius = text2num("[params["radius"]]")
	if(!isnum(radius) || radius < 1 || radius > 8)
		return "radius must stay in the range 1..8."

	var/barricade_path = resolve_whitelisted_type(params["barricade_path"], allowed_barricade_types, /datum/human_ai_defense/barricade)
	if(!barricade_path)
		return "Invalid barricade type selected."

	var/place_sentries = world_edit_parse_bool(params["place_sentries"])
	if(place_sentries)
		if(radius < 2)
			return "radius must be at least 2 when sentries are enabled."

		var/sentry_path = resolve_whitelisted_type(params["sentry_path"], allowed_sentry_types, /datum/human_ai_defense/defense/sentry)
		if(!sentry_path)
			return "Invalid sentry type selected."

		if(!("[params["faction"]]" in valid_factions))
			return "Invalid faction selected for sentries."

	var/planned_total = (radius * 8) + (place_sentries ? 4 : 0)
	if(planned_total > 68)
		return "The requested outpost exceeds the Phase 1 placement cap."

	return null

/datum/world_edit_generator/outpost_radius/preview(mob/user, list/params)
	var/datum/world_edit_preview_result/result = new
	var/turf/center_turf = get_turf(user)
	if(!center_turf)
		result.message = "Unable to resolve the anchor turf."
		return result

	var/list/plan = build_outpost_plan(center_turf, params)
	var/list/barricade_placements = plan["barricade_placements"]
	var/list/sentry_placements = plan["sentry_placements"]
	var/list/preview_turfs = plan["preview_turfs"]
	var/blocked_barricades = plan["blocked_barricades"]
	var/blocked_sentries = plan["blocked_sentries"]

	if(!length(preview_turfs))
		result.message = "No valid outpost placements were found around the current turf."
		return result

	result.success = TRUE
	result.preview_images = world_edit_build_turf_preview_images(preview_turfs)
	result.meta["radius"] = text2num("[params["radius"]]") || 4
	result.meta["barricade_count"] = length(barricade_placements)
	result.meta["sentry_count"] = length(sentry_placements)
	result.meta["blocked_barricades"] = blocked_barricades
	result.meta["blocked_sentries"] = blocked_sentries
	result.message = "Preview ready: barricades=[length(barricade_placements)], sentries=[length(sentry_placements)], blocked=[blocked_barricades + blocked_sentries]."
	return result

/datum/world_edit_generator/outpost_radius/apply(mob/user, list/params)
	var/datum/world_edit_apply_result/result = new
	var/turf/center_turf = get_turf(user)
	if(!center_turf)
		result.message = "Unable to resolve the anchor turf."
		return result

	var/barricade_path = resolve_whitelisted_type(params["barricade_path"], allowed_barricade_types, /datum/human_ai_defense/barricade)
	var/sentry_path = resolve_whitelisted_type(params["sentry_path"], allowed_sentry_types, /datum/human_ai_defense/defense/sentry)
	var/list/plan = build_outpost_plan(center_turf, params)
	var/list/barricade_placements = plan["barricade_placements"]
	var/list/sentry_placements = plan["sentry_placements"]
	var/faction = "[params["faction"]]"
	var/turned_on = world_edit_parse_bool(params["turned_on"])
	var/created_barricades = 0
	var/created_sentries = 0
	var/skipped_runtime = 0

	for(var/list/placement as anything in barricade_placements)
		var/turf/target_turf = placement["turf"]
		if(!can_place_barricade_on_turf(target_turf))
			skipped_runtime++
			continue
		if(spawn_defense_path(target_turf, placement["dir"], barricade_path))
			created_barricades++
		else
			skipped_runtime++

	for(var/list/placement as anything in sentry_placements)
		var/turf/target_turf = placement["turf"]
		if(!can_place_sentry_on_turf(target_turf))
			skipped_runtime++
			continue
		if(spawn_defense_path(target_turf, placement["dir"], sentry_path, faction, turned_on))
			created_sentries++
		else
			skipped_runtime++

	result.center_turf = center_turf
	result.created_count = created_barricades + created_sentries
	result.meta["barricade_count"] = created_barricades
	result.meta["sentry_count"] = created_sentries
	result.meta["skipped_runtime"] = skipped_runtime

	if(result.created_count <= 0)
		result.message = "Outpost apply finished with no created placements."
		return result

	result.success = TRUE
	result.message = "Outpost created: barricades=[created_barricades], sentries=[created_sentries], skipped=[skipped_runtime]."
	return result

/datum/world_edit_generator/outpost_radius/get_ui_fields(list/current_params)
	var/place_sentries = world_edit_parse_bool(current_params["place_sentries"])
	var/list/faction_options = list()
	for(var/faction in valid_factions)
		faction_options += list(list(
			"label" = "[faction]",
			"value" = faction,
		))

	return list(
		list(
			"id" = "radius",
			"label" = "Radius",
			"kind" = "number",
			"group" = "Layout",
			"description" = "Square perimeter radius around the current turf.",
			"validate_hint" = "Allowed range: 1..8",
			"value" = text2num("[current_params["radius"]]") || 4,
			"min" = 1,
			"max" = 8,
			"step" = 1,
		),
		list(
			"id" = "barricade_path",
			"label" = "Barricade Type",
			"kind" = "select",
			"group" = "Barricades",
			"description" = "Whitelisted barricade type from human_ai_defense.",
			"value" = "[current_params["barricade_path"] || /datum/human_ai_defense/barricade/metal]",
			"options" = build_type_options(allowed_barricade_types),
		),
		list(
			"id" = "place_sentries",
			"label" = "Place Cardinal Sentries",
			"kind" = "boolean",
			"group" = "Sentries",
			"description" = "Adds four sentries inside the perimeter on cardinal points.",
			"value" = place_sentries,
		),
		list(
			"id" = "sentry_path",
			"label" = "Sentry Type",
			"kind" = "select",
			"group" = "Sentries",
			"description" = "Whitelisted sentry type for the optional inner points.",
			"value" = "[current_params["sentry_path"] || /datum/human_ai_defense/defense/sentry/uscm]",
			"options" = build_type_options(allowed_sentry_types),
			"visible" = place_sentries,
			"disabled" = !place_sentries,
		),
		list(
			"id" = "faction",
			"label" = "IFF Faction",
			"kind" = "select",
			"group" = "Sentries",
			"description" = "Faction passed to human_ai_defense sentries.",
			"value" = current_params["faction"] || FACTION_MARINE,
			"options" = faction_options,
			"visible" = place_sentries,
			"disabled" = !place_sentries,
		),
		list(
			"id" = "turned_on",
			"label" = "Power On Sentries",
			"kind" = "boolean",
			"group" = "Sentries",
			"description" = "Turns sentries on immediately after placement.",
			"value" = current_params["turned_on"] ? TRUE : FALSE,
			"visible" = place_sentries,
			"disabled" = !place_sentries,
		),
	)

/datum/world_edit_generator/outpost_radius/set_ui_param(mob/user, list/current_params, param_id, value)
	var/list/new_params = current_params.Copy()

	switch(param_id)
		if("radius")
			new_params[param_id] = clamp(text2num("[value]"), 1, 8)

		if("barricade_path")
			var/path_value = resolve_whitelisted_type(value, allowed_barricade_types, /datum/human_ai_defense/barricade)
			if(!path_value)
				return "Invalid barricade type selected."
			new_params[param_id] = path_value

		if("place_sentries")
			new_params[param_id] = world_edit_parse_bool(value)

		if("sentry_path")
			var/path_value = resolve_whitelisted_type(value, allowed_sentry_types, /datum/human_ai_defense/defense/sentry)
			if(!path_value)
				return "Invalid sentry type selected."
			new_params[param_id] = path_value

		if("faction")
			if(!("[value]" in valid_factions))
				return "Invalid sentry faction selected."
			new_params[param_id] = "[value]"

		if("turned_on")
			new_params[param_id] = world_edit_parse_bool(value)

		else
			return ..()

	return new_params

/datum/world_edit_generator/outpost_radius/get_apply_confirmation_text(list/params)
	return "Apply Outpost Radius at the current turf with radius [params["radius"]]?"

/datum/world_edit_generator/outpost_radius/get_params_short(list/params)
	return "radius=[params["radius"]] barricade=[params["barricade_path"]] sentries=[params["place_sentries"]] sentry_type=[params["sentry_path"]]"
