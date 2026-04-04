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
	var/static/list/outpost_family_profiles = list(
		"standard" = list(
			"label" = "Standard",
			"description" = "Balanced perimeter with cardinal passages and a mixed barricade ring.",
			"default_barricade_path" = /datum/human_ai_defense/barricade/metal,
			"barricade_mix" = list(
				/datum/human_ai_defense/barricade/metal,
				/datum/human_ai_defense/barricade/metal/wired,
				/datum/human_ai_defense/barricade/sandbag,
				/datum/human_ai_defense/barricade/plasteel,
			),
			"default_sentry_path" = /datum/human_ai_defense/defense/sentry/uscm,
			"opening_dirs" = list(NORTH, EAST, SOUTH, WEST),
		),
		"fortified" = list(
			"label" = "Fortified",
			"description" = "Plasteel-forward ring with reinforced openings and heavier sentry defaults.",
			"default_barricade_path" = /datum/human_ai_defense/barricade/plasteel,
			"barricade_mix" = list(
				/datum/human_ai_defense/barricade/plasteel,
				/datum/human_ai_defense/barricade/plasteel/wired,
				/datum/human_ai_defense/barricade/metal/wired,
				/datum/human_ai_defense/barricade/sandbag,
			),
			"default_sentry_path" = /datum/human_ai_defense/defense/sentry/uscm/dmr,
			"opening_dirs" = list(NORTH, EAST, SOUTH, WEST),
		),
		"light" = list(
			"label" = "Light",
			"description" = "Cheaper temporary outpost with wooden and sandbag elements.",
			"default_barricade_path" = /datum/human_ai_defense/barricade/wooden,
			"barricade_mix" = list(
				/datum/human_ai_defense/barricade/wooden,
				/datum/human_ai_defense/barricade/sandbag,
				/datum/human_ai_defense/barricade/metal,
				/datum/human_ai_defense/barricade/metal/wired,
			),
			"default_sentry_path" = /datum/human_ai_defense/defense/sentry/uscm/shotgun,
			"opening_dirs" = list(NORTH, EAST, SOUTH, WEST),
		),
	)

/datum/world_edit_generator/outpost_radius/get_supported_placement_modes()
	return list("single", "repeat")

/datum/world_edit_generator/outpost_radius/get_supported_placement_shapes()
	return list(
		WORLD_EDIT_SHAPE_POINT,
		WORLD_EDIT_SHAPE_LINE,
		WORLD_EDIT_SHAPE_RECTANGLE,
		WORLD_EDIT_SHAPE_CIRCLE,
		WORLD_EDIT_SHAPE_RING,
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

/datum/world_edit_generator/outpost_radius/proc/get_default_outpost_family_id()
	return "standard"

/datum/world_edit_generator/outpost_radius/proc/resolve_outpost_family_id(value)
	if(isnull(value) || !length("[value]") || "[value]" == "null")
		return get_default_outpost_family_id()

	var/family_id = "[value]"
	if(family_id in outpost_family_profiles)
		return family_id
	return null

/datum/world_edit_generator/outpost_radius/proc/get_outpost_family_profile(family_id)
	if(!(family_id in outpost_family_profiles))
		return null
	return outpost_family_profiles[family_id]

/datum/world_edit_generator/outpost_radius/proc/build_family_options()
	var/list/options = list()
	for(var/family_id in outpost_family_profiles)
		var/list/profile = outpost_family_profiles[family_id]
		options += list(list(
			"label" = profile["label"] || family_id,
			"value" = family_id,
			"description" = profile["description"] || "",
		))
	return options

/datum/world_edit_generator/outpost_radius/proc/resolve_whitelisted_type(value, list/type_list, expected_root, default_value = null)
	if(isnull(value) || !length("[value]") || "[value]" == "null")
		if(ispath(default_value, expected_root) && (default_value in type_list))
			return default_value
		return null

	var/path_value = ispath(value) ? value : text2path("[value]")
	if(!ispath(path_value, expected_root))
		return null
	if(!(path_value in type_list))
		return null
	return path_value

/datum/world_edit_generator/outpost_radius/proc/build_barricade_cycle(list/family_profile, selected_barricade_path)
	var/list/cycle = list()
	if(ispath(selected_barricade_path, /datum/human_ai_defense/barricade))
		cycle += selected_barricade_path

	var/list/family_mix = islist(family_profile) ? family_profile["barricade_mix"] : null
	if(islist(family_mix))
		for(var/datum/human_ai_defense/barricade/type_path as anything in family_mix)
			if(type_path in cycle)
				continue
			cycle += type_path

	if(!length(cycle))
		var/default_barricade_path = islist(family_profile) ? family_profile["default_barricade_path"] : null
		if(ispath(default_barricade_path, /datum/human_ai_defense/barricade))
			cycle += default_barricade_path

	return cycle

/datum/world_edit_generator/outpost_radius/proc/format_opening_dirs(list/opening_dirs)
	if(!islist(opening_dirs) || !length(opening_dirs))
		return "none"

	var/list/labels = list()
	for(var/dir_value as anything in opening_dirs)
		labels += GLOB.world_edit_helpers.dir_to_label(dir_value)
	return jointext(labels, ", ")

/datum/world_edit_generator/outpost_radius/proc/is_perimeter_opening_slot(dir_to_use, offset_x, offset_y, list/family_profile)
	var/list/opening_dirs = islist(family_profile) ? family_profile["opening_dirs"] : null
	if(!islist(opening_dirs) || !(dir_to_use in opening_dirs))
		return FALSE

	switch(dir_to_use)
		if(NORTH, SOUTH)
			return offset_x == 0
		if(EAST, WEST)
			return offset_y == 0

	return FALSE

/datum/world_edit_generator/outpost_radius/proc/select_barricade_path_for_slot(list/barricade_cycle, slot_index, radius)
	if(!islist(barricade_cycle) || !length(barricade_cycle))
		return null

	var/cycle_index = ((slot_index + max(radius, 1) - 1) % length(barricade_cycle)) + 1
	return barricade_cycle[cycle_index]

/datum/world_edit_generator/outpost_radius/proc/build_sentry_guard_candidates(dir_to_guard, inner_radius)
	var/fallback_distance = max(inner_radius - 1, 0)

	switch(dir_to_guard)
		if(NORTH)
			return list(
				list("dx" = 0, "dy" = inner_radius, "dir" = NORTH),
				list("dx" = 1, "dy" = fallback_distance, "dir" = NORTH),
				list("dx" = -1, "dy" = fallback_distance, "dir" = NORTH),
			)
		if(SOUTH)
			return list(
				list("dx" = 0, "dy" = -inner_radius, "dir" = SOUTH),
				list("dx" = 1, "dy" = -fallback_distance, "dir" = SOUTH),
				list("dx" = -1, "dy" = -fallback_distance, "dir" = SOUTH),
			)
		if(EAST)
			return list(
				list("dx" = inner_radius, "dy" = 0, "dir" = EAST),
				list("dx" = fallback_distance, "dy" = 1, "dir" = EAST),
				list("dx" = fallback_distance, "dy" = -1, "dir" = EAST),
			)
		if(WEST)
			return list(
				list("dx" = -inner_radius, "dy" = 0, "dir" = WEST),
				list("dx" = -fallback_distance, "dy" = 1, "dir" = WEST),
				list("dx" = -fallback_distance, "dy" = -1, "dir" = WEST),
			)

	return list()

/datum/world_edit_generator/outpost_radius/proc/resolve_outpost_configuration(list/params)
	var/list/config = list()
	var/family_id = resolve_outpost_family_id(params["family"])
	if(!family_id)
		config["error"] = "Invalid outpost family selected."
		return config

	var/list/family_profile = get_outpost_family_profile(family_id)
	if(!islist(family_profile))
		config["error"] = "Invalid outpost family selected."
		return config

	var/radius = text2num("[params["radius"]]") || 4
	if(!isnum(radius))
		config["error"] = "radius must stay in the range 1..8."
		return config

	var/place_sentries = GLOB.world_edit_helpers.parse_bool(params["place_sentries"])
	var/barricade_path = resolve_whitelisted_type(params["barricade_path"], allowed_barricade_types, /datum/human_ai_defense/barricade, family_profile["default_barricade_path"])
	if(!barricade_path)
		config["error"] = "Invalid barricade type selected."
		return config

	var/sentry_path = null
	if(place_sentries)
		sentry_path = resolve_whitelisted_type(params["sentry_path"], allowed_sentry_types, /datum/human_ai_defense/defense/sentry, family_profile["default_sentry_path"])
		if(!sentry_path)
			config["error"] = "Invalid sentry type selected."
			return config

	var/faction = "[params["faction"]]"
	var/turned_on = GLOB.world_edit_helpers.parse_bool(params["turned_on"])

	config["family"] = family_id
	config["family_profile"] = family_profile
	config["radius"] = radius
	config["place_sentries"] = place_sentries
	config["barricade_path"] = barricade_path
	config["barricade_cycle"] = build_barricade_cycle(family_profile, barricade_path)
	config["sentry_path"] = sentry_path
	config["faction"] = faction
	config["turned_on"] = turned_on
	return config

/datum/world_edit_generator/outpost_radius/proc/get_shape_support_error(shape_id, list/anchor_turfs)
	if(!islist(anchor_turfs) || length(anchor_turfs) <= 1)
		return null

	var/shape_label = GLOB.world_edit_placement_shapes.world_edit_get_placement_shape_label(shape_id)
	return "Outpost Radius v1 only supports Point or single-turf shapes. Shape '[shape_label]' resolved to [length(anchor_turfs)] anchor turfs, which would create overlapping perimeter plans."

/datum/world_edit_generator/outpost_radius/proc/is_open_construction_turf(turf/target_turf)
	if(!istype(target_turf, /turf/open))
		return FALSE

	var/turf/open/open_turf = target_turf
	if(!open_turf.allow_construction)
		return FALSE

	return TRUE

/datum/world_edit_generator/outpost_radius/proc/has_dense_blocker(turf/target_turf)
	if(!target_turf)
		return TRUE
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
	if(!target_turf)
		return null
	if(!ispath(defense_path, /datum/human_ai_defense))
		return null

	var/datum/human_ai_defense/defense_definition = new defense_path()
	var/obj_path = defense_definition.path_to_spawn || GLOB.world_edit_blueprints.world_edit_resolve_defense_spawn_path(defense_path)
	var/list/existing_lookup = list()
	if(ispath(obj_path, /obj))
		for(var/obj/existing as anything in target_turf)
			if(istype(existing, obj_path))
				existing_lookup[existing] = TRUE

	defense_definition.spawn_object(target_turf, dir_to_spawn, faction, turned_on)

	var/obj/created_object
	if(ispath(obj_path, /obj))
		for(var/obj/candidate as anything in target_turf)
			if(!istype(candidate, obj_path) || existing_lookup[candidate])
				continue
			created_object = candidate
			break

	qdel(defense_definition)
	return created_object

/datum/world_edit_generator/outpost_radius/proc/collect_perimeter_placements(turf/center_turf, radius, list/family_profile, list/barricade_cycle)
	var/list/result = list(
		"placements" = list(),
		"blocked_count" = 0,
		"blocked_barricades" = 0,
		"blocked_openings" = 0,
		"opening_count" = 0,
		"openings" = list(),
	)
	if(!center_turf)
		return result
	var/list/placements = result["placements"]
	var/slot_index = 0

	for(var/offset_x in -radius to radius)
		slot_index++
		var/turf/top_turf = locate(center_turf.x + offset_x, center_turf.y + radius, center_turf.z)
		if(is_perimeter_opening_slot(NORTH, offset_x, radius, family_profile))
			if(can_place_barricade_on_turf(top_turf))
				result["opening_count"]++
				result["openings"] += list(list("turf" = top_turf, "dir" = NORTH, "slot_index" = slot_index))
			else
				result["blocked_count"]++
				result["blocked_openings"]++
		else if(can_place_barricade_on_turf(top_turf))
			placements += list(list(
				"turf" = top_turf,
				"dir" = NORTH,
				"barricade_path" = select_barricade_path_for_slot(barricade_cycle, slot_index, radius),
				"slot_index" = slot_index,
			))
		else
			result["blocked_count"]++
			result["blocked_barricades"]++

		if(radius <= 0)
			continue

		slot_index++
		var/turf/bottom_turf = locate(center_turf.x + offset_x, center_turf.y - radius, center_turf.z)
		if(is_perimeter_opening_slot(SOUTH, offset_x, -radius, family_profile))
			if(can_place_barricade_on_turf(bottom_turf))
				result["opening_count"]++
				result["openings"] += list(list("turf" = bottom_turf, "dir" = SOUTH, "slot_index" = slot_index))
			else
				result["blocked_count"]++
				result["blocked_openings"]++
		else if(can_place_barricade_on_turf(bottom_turf))
			placements += list(list(
				"turf" = bottom_turf,
				"dir" = SOUTH,
				"barricade_path" = select_barricade_path_for_slot(barricade_cycle, slot_index, radius),
				"slot_index" = slot_index,
			))
		else
			result["blocked_count"]++
			result["blocked_barricades"]++

	if(radius <= 1)
		return result

	for(var/offset_y in (-radius + 1) to (radius - 1))
		slot_index++
		var/turf/right_turf = locate(center_turf.x + radius, center_turf.y + offset_y, center_turf.z)
		if(is_perimeter_opening_slot(EAST, radius, offset_y, family_profile))
			if(can_place_barricade_on_turf(right_turf))
				result["opening_count"]++
				result["openings"] += list(list("turf" = right_turf, "dir" = EAST, "slot_index" = slot_index))
			else
				result["blocked_count"]++
				result["blocked_openings"]++
		else if(can_place_barricade_on_turf(right_turf))
			placements += list(list(
				"turf" = right_turf,
				"dir" = EAST,
				"barricade_path" = select_barricade_path_for_slot(barricade_cycle, slot_index, radius),
				"slot_index" = slot_index,
			))
		else
			result["blocked_count"]++
			result["blocked_barricades"]++

		slot_index++
		var/turf/left_turf = locate(center_turf.x - radius, center_turf.y + offset_y, center_turf.z)
		if(is_perimeter_opening_slot(WEST, -radius, offset_y, family_profile))
			if(can_place_barricade_on_turf(left_turf))
				result["opening_count"]++
				result["openings"] += list(list("turf" = left_turf, "dir" = WEST, "slot_index" = slot_index))
			else
				result["blocked_count"]++
				result["blocked_openings"]++
		else if(can_place_barricade_on_turf(left_turf))
			placements += list(list(
				"turf" = left_turf,
				"dir" = WEST,
				"barricade_path" = select_barricade_path_for_slot(barricade_cycle, slot_index, radius),
				"slot_index" = slot_index,
			))
		else
			result["blocked_count"]++
			result["blocked_barricades"]++

	return result

/datum/world_edit_generator/outpost_radius/proc/collect_sentry_placements(turf/center_turf, radius, list/family_profile)
	var/list/result = list(
		"placements" = list(),
		"blocked_count" = 0,
	)
	if(!center_turf)
		return result
	var/list/placements = result["placements"]
	var/inner_radius = max(radius - 1, 1)
	var/list/opening_dirs = islist(family_profile) ? family_profile["opening_dirs"] : null
	if(!islist(opening_dirs) || !length(opening_dirs))
		opening_dirs = list(NORTH, EAST, SOUTH, WEST)

	for(var/dir_to_guard as anything in opening_dirs)
		var/list/candidates = build_sentry_guard_candidates(dir_to_guard, inner_radius)
		var/placed = FALSE
		for(var/list/candidate as anything in candidates)
			var/turf/target_turf = locate(center_turf.x + candidate["dx"], center_turf.y + candidate["dy"], center_turf.z)
			if(!can_place_sentry_on_turf(target_turf))
				continue

			placements += list(list(
				"turf" = target_turf,
				"dir" = candidate["dir"],
				"opening_dir" = dir_to_guard,
			))
			placed = TRUE
			break

		if(!placed)
			result["blocked_count"]++

	return result

/datum/world_edit_generator/outpost_radius/proc/build_outpost_plan(turf/center_turf, list/params)
	var/datum/world_edit_plan/plan = new
	if(!center_turf)
		return plan

	var/list/config = params
	if(!islist(config) || !config["family_profile"])
		config = resolve_outpost_configuration(params)
	if(config["error"])
		plan.metadata["error"] = "[config["error"]]"
		return plan

	var/radius = config["radius"]
	var/list/family_profile = config["family_profile"]
	var/place_sentries = config["place_sentries"]
	var/list/barricade_cycle = config["barricade_cycle"]
	var/faction = config["faction"]
	var/turned_on = config["turned_on"]
	var/barricade_path = config["barricade_path"]
	var/sentry_path = config["sentry_path"]

	var/list/perimeter_data = collect_perimeter_placements(center_turf, radius, family_profile, barricade_cycle)
	var/list/sentry_data = place_sentries ? collect_sentry_placements(center_turf, radius, family_profile) : list(
		"placements" = list(),
		"blocked_count" = 0,
	)

	var/list/preview_turf_lookup = list()
	for(var/list/placement as anything in perimeter_data["placements"])
		var/turf/target_turf = placement["turf"]
		if(!target_turf)
			continue
		preview_turf_lookup[target_turf] = TRUE
		plan.placements += list(list(
			"kind" = "barricade",
			"turf" = target_turf,
			"dir" = placement["dir"],
			"defense_path" = placement["barricade_path"] || barricade_path,
		))
	for(var/list/placement as anything in sentry_data["placements"])
		var/turf/target_turf = placement["turf"]
		if(!target_turf)
			continue
		preview_turf_lookup[target_turf] = TRUE
		plan.placements += list(list(
			"kind" = "sentry",
			"turf" = target_turf,
			"dir" = placement["dir"],
			"defense_path" = sentry_path,
			"faction" = faction,
			"turned_on" = turned_on,
		))

	for(var/turf/preview_turf as anything in preview_turf_lookup)
		plan.affected_turfs += preview_turf

	plan.metadata["center_turf"] = center_turf
	plan.metadata["radius"] = radius
	plan.metadata["family"] = config["family"]
	plan.metadata["family_label"] = family_profile["label"]
	plan.metadata["family_description"] = family_profile["description"]
	plan.metadata["barricade_count"] = length(perimeter_data["placements"])
	plan.metadata["sentry_count"] = length(sentry_data["placements"])
	plan.metadata["opening_count"] = perimeter_data["opening_count"]
	plan.metadata["opening_dirs"] = format_opening_dirs(family_profile["opening_dirs"])
	plan.metadata["blocked_barricades"] = perimeter_data["blocked_barricades"]
	plan.metadata["blocked_openings"] = perimeter_data["blocked_openings"]
	plan.metadata["blocked_perimeter"] = perimeter_data["blocked_count"]
	plan.metadata["blocked_sentries"] = sentry_data["blocked_count"]
	return plan

/datum/world_edit_generator/outpost_radius/build_placement_plan(mob/user, list/params, list/placement_context)
	var/datum/world_edit_plan/plan = new
	var/list/anchor_turfs = placement_context["anchor_turfs"]
	if(!islist(anchor_turfs) || !length(anchor_turfs))
		plan.metadata["error"] = "Unable to resolve the anchor turf."
		return plan

	var/list/config = resolve_outpost_configuration(params)
	if(config["error"])
		plan.metadata["error"] = "[config["error"]]"
		return plan

	var/shape_id = "[placement_context["shape"] || manager?.get_effective_placement_shape() || WORLD_EDIT_SHAPE_POINT]"
	var/shape_label = GLOB.world_edit_placement_shapes.world_edit_get_placement_shape_label(shape_id)
	plan.metadata["placement_shape"] = shape_id
	plan.metadata["shape_label"] = shape_label
	plan.metadata["family"] = config["family"]
	plan.metadata["family_label"] = config["family_profile"]["label"]
	plan.metadata["family_description"] = config["family_profile"]["description"]
	plan.metadata["opening_dirs"] = format_opening_dirs(config["family_profile"]["opening_dirs"])

	var/shape_error = get_shape_support_error(shape_id, anchor_turfs)
	if(shape_error)
		plan.metadata["error"] = shape_error
		plan.metadata["anchor_count"] = length(anchor_turfs)
		return plan

	var/list/occupied_lookup = list()
	var/list/preview_lookup = list()
	var/total_barricades = 0
	var/total_sentries = 0
	var/total_blocked_barricades = 0
	var/total_openings = 0
	var/total_blocked_openings = 0
	var/total_blocked_sentries = 0
	for(var/turf/anchor_turf as anything in anchor_turfs)
		if(!istype(anchor_turf))
			continue
		var/datum/world_edit_plan/anchor_plan = build_outpost_plan(anchor_turf, config)
		if(anchor_plan.metadata["error"])
			plan.metadata["error"] = "[anchor_plan.metadata["error"]]"
			return plan
		for(var/list/placement as anything in anchor_plan.placements)
			var/turf/target_turf = placement["turf"]
			if(!istype(target_turf))
				continue
			if(occupied_lookup[target_turf])
				plan.metadata["error"] = "Requested outpost footprint overlaps itself."
				plan.metadata["blocked_turf"] = "[target_turf.x],[target_turf.y],[target_turf.z]"
				return plan
			occupied_lookup[target_turf] = TRUE
			preview_lookup[target_turf] = TRUE
			plan.placements += list(placement.Copy())
		if(length(plan.placements) > WORLD_EDIT_PLACEMENT_MAX_TOTAL_PLACEMENTS)
			plan.metadata["error"] = "Requested outpost placement exceeds the safe placement cap ([WORLD_EDIT_PLACEMENT_MAX_TOTAL_PLACEMENTS])."
			return plan

		total_barricades += anchor_plan.metadata["barricade_count"] || 0
		total_sentries += anchor_plan.metadata["sentry_count"] || 0
		total_blocked_barricades += anchor_plan.metadata["blocked_barricades"] || 0
		total_openings += anchor_plan.metadata["opening_count"] || 0
		total_blocked_openings += anchor_plan.metadata["blocked_openings"] || 0
		total_blocked_sentries += anchor_plan.metadata["blocked_sentries"] || 0

	for(var/turf/preview_turf as anything in preview_lookup)
		plan.affected_turfs += preview_turf

	var/turf/center_turf = placement_context["end_turf"]
	if(!istype(center_turf))
		center_turf = anchor_turfs[clamp(round((length(anchor_turfs) + 1) / 2), 1, length(anchor_turfs))]

	plan.metadata["center_turf"] = center_turf
	plan.metadata["radius"] = config["radius"]
	plan.metadata["barricade_count"] = total_barricades
	plan.metadata["sentry_count"] = total_sentries
	plan.metadata["blocked_barricades"] = total_blocked_barricades
	plan.metadata["blocked_sentries"] = total_blocked_sentries
	plan.metadata["anchor_count"] = length(anchor_turfs)
	plan.metadata["placement_mode"] = "[placement_context["mode"] || "single"]"
	plan.metadata["family"] = config["family"]
	plan.metadata["family_label"] = config["family_profile"]["label"]
	plan.metadata["family_description"] = config["family_profile"]["description"]
	plan.metadata["opening_count"] = total_openings
	plan.metadata["blocked_openings"] = total_blocked_openings
	plan.metadata["shape_label"] = shape_label
	if(islist(placement_context["shape_metadata"]))
		for(var/key in placement_context["shape_metadata"])
			if(!(key in plan.metadata))
				plan.metadata[key] = placement_context["shape_metadata"][key]
	return plan

/datum/world_edit_generator/outpost_radius/build_plan(list/params)
	var/turf/anchor_turf = get_turf(manager?.holder?.mob)
	var/list/shape_result = GLOB.world_edit_placement_shapes.world_edit_build_shape_turfs(manager?.get_effective_placement_shape() || WORLD_EDIT_SHAPE_POINT, anchor_turf, null, params, NORTH)
	if(shape_result["error"])
		var/datum/world_edit_plan/error_plan = new
		error_plan.metadata["error"] = "[shape_result["error"]]"
		return error_plan
	return build_placement_plan(manager?.holder?.mob, params, list(
		"mode" = manager?.get_effective_placement_mode() || "single",
		"shape" = manager?.get_effective_placement_shape() || WORLD_EDIT_SHAPE_POINT,
		"shape_metadata" = shape_result["metadata"] || list(),
		"anchor_turfs" = shape_result["turfs"] || list(anchor_turf),
		"end_turf" = anchor_turf,
	))

/datum/world_edit_generator/outpost_radius/validate_params(mob/user, list/params)
	var/turf/center_turf = get_turf(user)
	if(!center_turf)
		return "Unable to resolve the anchor turf."

	var/list/config = resolve_outpost_configuration(params)
	if(config["error"])
		return "[config["error"]]"

	var/radius = config["radius"]
	if(!isnum(radius) || radius < 1 || radius > 8)
		return "radius must stay in the range 1..8."

	var/place_sentries = config["place_sentries"]
	if(place_sentries)
		if(radius < 2)
			return "radius must be at least 2 when sentries are enabled."

		if(!(config["faction"] in valid_factions))
			return "Invalid faction selected for sentries."

	var/planned_total = (radius * 8) + (place_sentries ? 4 : 0)
	if(planned_total > 68)
		return "The requested outpost exceeds the Phase 1 placement cap."

	var/list/shape_result = GLOB.world_edit_placement_shapes.world_edit_build_shape_turfs(manager?.get_effective_placement_shape() || WORLD_EDIT_SHAPE_POINT, center_turf, null, params, NORTH)
	if(shape_result["error"])
		return "[shape_result["error"]]"

	var/datum/world_edit_plan/plan = build_placement_plan(user, params, list(
		"mode" = manager?.get_effective_placement_mode() || "single",
		"shape" = manager?.get_effective_placement_shape() || WORLD_EDIT_SHAPE_POINT,
		"shape_metadata" = shape_result["metadata"] || list(),
		"anchor_turfs" = shape_result["turfs"] || list(center_turf),
		"end_turf" = center_turf,
	))
	if(plan.metadata["error"])
		return "[plan.metadata["error"]]"
	if(!length(plan.placements) && !length(plan.deletions))
		return "No valid outpost placements were found around the current turf."

	return null

/datum/world_edit_generator/outpost_radius/preview(mob/user, list/params)
	var/datum/world_edit_preview_result/result = new
	clear_built_plan()
	var/datum/world_edit_plan/plan = build_plan(params)
	if(!istype(plan))
		result.message = "Unable to build the outpost plan."
		return result
	if(plan.metadata["error"])
		result.message = "[plan.metadata["error"]]"
		return result
	if(!length(plan.placements) && !length(plan.deletions))
		result.message = "No valid outpost placements were found around the current turf."
		return result

	current_plan = plan
	result.success = TRUE
	result.preview_images = GLOB.world_edit_helpers.build_turf_preview_images(plan.affected_turfs)
	result.meta = plan.metadata.Copy()
	result.message = "Preview ready: family=[plan.metadata["family_label"] || "Standard"], anchors=[plan.metadata["anchor_count"] || 1], openings=[plan.metadata["opening_count"] || 0], barricades=[plan.metadata["barricade_count"]], sentries=[plan.metadata["sentry_count"]], blocked=[(plan.metadata["blocked_barricades"] || 0) + (plan.metadata["blocked_openings"] || 0) + (plan.metadata["blocked_sentries"] || 0)]."
	return result

/datum/world_edit_generator/outpost_radius/apply(mob/user, list/params)
	var/datum/world_edit_apply_result/result = new
	var/datum/world_edit_plan/plan = current_plan
	if(!istype(plan))
		result.message = "Run preview first to build the outpost plan."
		return result
	if(plan.metadata["error"])
		result.message = "[plan.metadata["error"]]"
		return result
	if(!length(plan.placements) && !length(plan.deletions))
		result.message = "Outpost apply finished with no valid placements."
		return result
	var/turf/center_turf = plan.metadata["center_turf"]
	var/created_barricades = 0
	var/created_sentries = 0
	var/skipped_runtime = 0
	var/datum/world_edit_changeset/changeset = new /datum/world_edit_changeset(definition?.id || "outpost_radius", WORLD_EDIT_UNDO_FULL, list(
		"center_turf" = center_turf,
		"anchor_count" = plan.metadata["anchor_count"] || 1,
		"placement_mode" = plan.metadata["placement_mode"] || "single",
	))

	for(var/list/placement as anything in plan.placements)
		var/turf/target_turf = placement["turf"]
		var/placement_kind = placement["kind"]
		var/defense_path = placement["defense_path"]
		if(!target_turf || !ispath(defense_path, /datum/human_ai_defense))
			skipped_runtime++
			continue
		if(placement_kind == "barricade")
			if(!can_place_barricade_on_turf(target_turf))
				skipped_runtime++
				continue
			var/obj/created_object = spawn_defense_path(target_turf, placement["dir"], defense_path)
			if(created_object)
				created_barricades++
				changeset.add_created(created_object, target_turf, list("kind" = placement_kind))
			else
				skipped_runtime++
			continue
		if(placement_kind != "sentry")
			skipped_runtime++
			continue
		if(!can_place_sentry_on_turf(target_turf))
			skipped_runtime++
			continue
		var/obj/created_sentry = spawn_defense_path(target_turf, placement["dir"], defense_path, placement["faction"], placement["turned_on"])
		if(created_sentry)
			created_sentries++
			changeset.add_created(created_sentry, target_turf, list("kind" = placement_kind))
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
	result.changeset = changeset
	result.message = "Outpost created: family=[plan.metadata["family_label"] || "Standard"], anchors=[plan.metadata["anchor_count"] || 1], barricades=[created_barricades], sentries=[created_sentries], skipped=[skipped_runtime]."
	return result

/datum/world_edit_generator/outpost_radius/get_ui_fields(list/current_params)
	var/place_sentries = GLOB.world_edit_helpers.parse_bool(current_params["place_sentries"])
	var/family_id = resolve_outpost_family_id(current_params["family"])
	if(!family_id)
		family_id = get_default_outpost_family_id()
	var/list/family_profile = get_outpost_family_profile(family_id)
	var/default_barricade_path = family_profile["default_barricade_path"] || /datum/human_ai_defense/barricade/metal
	var/default_sentry_path = family_profile["default_sentry_path"] || /datum/human_ai_defense/defense/sentry/uscm
	var/list/faction_options = list()
	for(var/faction in valid_factions)
		faction_options += list(list(
			"label" = "[faction]",
			"value" = faction,
		))

	return list(
		list(
			"id" = "family",
			"label" = "Template Family",
			"kind" = "select",
			"group" = "Layout",
			"description" = "Deterministic defaults for barricade mix, sentry type, and passage layout.",
			"value" = current_params["family"] || family_id,
			"options" = build_family_options(),
		),
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
			"description" = "Whitelisted barricade type from human_ai_defense. The family preset uses this as the leading barricade mix entry.",
			"value" = "[current_params["barricade_path"] || default_barricade_path]",
			"options" = build_type_options(allowed_barricade_types),
		),
		list(
			"id" = "place_sentries",
			"label" = "Place Cardinal Sentries",
			"kind" = "boolean",
			"group" = "Sentries",
			"description" = "Adds cardinal sentries just inside each intended passage.",
			"value" = place_sentries,
		),
		list(
			"id" = "sentry_path",
			"label" = "Sentry Type",
			"kind" = "select",
			"group" = "Sentries",
			"description" = "Whitelisted sentry type for the optional inner guard positions.",
			"value" = "[current_params["sentry_path"] || default_sentry_path]",
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
		if("family")
			var/family_id = resolve_outpost_family_id(value)
			if(!family_id)
				return "Invalid outpost family selected."
			new_params[param_id] = family_id
			var/list/family_profile = get_outpost_family_profile(family_id)
			new_params["barricade_path"] = family_profile["default_barricade_path"] || /datum/human_ai_defense/barricade/metal
			new_params["sentry_path"] = family_profile["default_sentry_path"] || /datum/human_ai_defense/defense/sentry/uscm

		if("radius")
			new_params[param_id] = clamp(text2num("[value]"), 1, 8)

		if("barricade_path")
			var/path_value = resolve_whitelisted_type(value, allowed_barricade_types, /datum/human_ai_defense/barricade, get_outpost_family_profile(resolve_outpost_family_id(new_params["family"]) || get_default_outpost_family_id())["default_barricade_path"])
			if(!path_value)
				return "Invalid barricade type selected."
			new_params[param_id] = path_value

		if("place_sentries")
			new_params[param_id] = GLOB.world_edit_helpers.parse_bool(value)

		if("sentry_path")
			var/path_value = resolve_whitelisted_type(value, allowed_sentry_types, /datum/human_ai_defense/defense/sentry, get_outpost_family_profile(resolve_outpost_family_id(new_params["family"]) || get_default_outpost_family_id())["default_sentry_path"])
			if(!path_value)
				return "Invalid sentry type selected."
			new_params[param_id] = path_value

		if("faction")
			if(!("[value]" in valid_factions))
				return "Invalid sentry faction selected."
			new_params[param_id] = "[value]"

		if("turned_on")
			new_params[param_id] = GLOB.world_edit_helpers.parse_bool(value)

		else
			return ..()

	return new_params

/datum/world_edit_generator/outpost_radius/get_apply_confirmation_text(list/params)
	var/family_id = resolve_outpost_family_id(params["family"])
	if(!family_id)
		family_id = get_default_outpost_family_id()
	var/list/family_profile = get_outpost_family_profile(family_id)
	return "Apply [family_profile["label"] || "Outpost"] radius plan at the current turf with radius [params["radius"]]?"

/datum/world_edit_generator/outpost_radius/get_params_short(list/params)
	return "family=[params["family"] || get_default_outpost_family_id()] radius=[params["radius"]] shape=[manager?.get_effective_placement_shape() || WORLD_EDIT_SHAPE_POINT] mode=[manager?.get_effective_placement_mode() || "single"] barricade=[params["barricade_path"]] sentries=[params["place_sentries"]] sentry_type=[params["sentry_path"]]"
