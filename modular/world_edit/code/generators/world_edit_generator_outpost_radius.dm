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

/datum/world_edit_generator/outpost_radius/proc/build_turf_lookup(list/turfs)
	var/list/lookup = list()
	if(!islist(turfs))
		return lookup

	for(var/turf/target_turf as anything in turfs)
		if(istype(target_turf))
			lookup[target_turf] = TRUE

	return lookup

/datum/world_edit_generator/outpost_radius/proc/build_turf_bounds(list/turfs)
	var/list/bounds = list(
		"min_x" = null,
		"max_x" = null,
		"min_y" = null,
		"max_y" = null,
		"center_x" = 0,
		"center_y" = 0,
		"z" = null,
	)
	if(!islist(turfs) || !length(turfs))
		return bounds

	for(var/turf/target_turf as anything in turfs)
		if(!istype(target_turf))
			continue
		if(isnull(bounds["min_x"]) || target_turf.x < bounds["min_x"])
			bounds["min_x"] = target_turf.x
		if(isnull(bounds["max_x"]) || target_turf.x > bounds["max_x"])
			bounds["max_x"] = target_turf.x
		if(isnull(bounds["min_y"]) || target_turf.y < bounds["min_y"])
			bounds["min_y"] = target_turf.y
		if(isnull(bounds["max_y"]) || target_turf.y > bounds["max_y"])
			bounds["max_y"] = target_turf.y
		if(isnull(bounds["z"]))
			bounds["z"] = target_turf.z

	if(!isnull(bounds["min_x"]) && !isnull(bounds["max_x"]))
		bounds["center_x"] = (bounds["min_x"] + bounds["max_x"]) / 2
	if(!isnull(bounds["min_y"]) && !isnull(bounds["max_y"]))
		bounds["center_y"] = (bounds["min_y"] + bounds["max_y"]) / 2

	return bounds

/datum/world_edit_generator/outpost_radius/proc/get_cardinal_opposite_dir(dir_to_flip)
	switch(dir_to_flip)
		if(NORTH)
			return SOUTH
		if(SOUTH)
			return NORTH
		if(EAST)
			return WEST
		if(WEST)
			return EAST
	return dir_to_flip

/datum/world_edit_generator/outpost_radius/proc/get_shape_chebyshev_distance_to_footprint(turf/target_turf, list/footprint_turfs)
	if(!istype(target_turf) || !islist(footprint_turfs) || !length(footprint_turfs))
		return null

	var/best_distance = null
	for(var/turf/source_turf as anything in footprint_turfs)
		if(!istype(source_turf))
			continue

		var/current_distance = max(abs(target_turf.x - source_turf.x), abs(target_turf.y - source_turf.y))
		if(isnull(best_distance) || current_distance < best_distance)
			best_distance = current_distance
			if(best_distance <= 0)
				break

	return best_distance

/datum/world_edit_generator/outpost_radius/proc/build_shape_shell_turfs(list/footprint_turfs, radius, list/footprint_lookup, list/shape_bounds)
	var/list/result = list(
		"turfs" = list(),
		"lookup" = list(),
	)
	if(!islist(footprint_turfs) || !length(footprint_turfs))
		return result

	radius = max(round(radius), 1)
	var/list/shell_turfs = result["turfs"]
	var/list/shell_lookup = result["lookup"]
	var/z_level = shape_bounds["z"]
	if(isnull(z_level))
		return result

	for(var/y in (shape_bounds["min_y"] - radius) to (shape_bounds["max_y"] + radius))
		for(var/x in (shape_bounds["min_x"] - radius) to (shape_bounds["max_x"] + radius))
			var/turf/target_turf = locate(x, y, z_level)
			if(!istype(target_turf) || footprint_lookup[target_turf])
				continue

			if(get_shape_chebyshev_distance_to_footprint(target_turf, footprint_turfs) != radius)
				continue

			shell_lookup[target_turf] = TRUE
			shell_turfs += target_turf

	return result

/datum/world_edit_generator/outpost_radius/proc/build_shape_shell_slot_dirs(turf/target_turf, radius, list/footprint_turfs, list/shell_lookup)
	var/list/slot_dirs = list()
	if(!istype(target_turf) || !islist(shell_lookup))
		return slot_dirs

	for(var/dir_to_use as anything in GLOB.cardinals)
		var/turf/neighbor_turf = get_step(target_turf, dir_to_use)
		if(shell_lookup[neighbor_turf])
			continue

		var/neighbor_distance = get_shape_chebyshev_distance_to_footprint(neighbor_turf, footprint_turfs)
		if(isnull(neighbor_distance) || neighbor_distance > radius)
			slot_dirs += dir_to_use

	return slot_dirs

/datum/world_edit_generator/outpost_radius/proc/score_shape_opening_slot(list/candidate_slot, list/shape_bounds)
	var/turf/source_turf = candidate_slot["turf"]
	if(!istype(source_turf))
		source_turf = candidate_slot["source_turf"]
	var/dir_to_use = candidate_slot["dir"]
	if(!istype(source_turf))
		return 0

	switch(dir_to_use)
		if(NORTH)
			return ((shape_bounds["max_y"] - source_turf.y) * 100000) + (abs(source_turf.x - shape_bounds["center_x"]) * 1000) + source_turf.x
		if(SOUTH)
			return ((source_turf.y - shape_bounds["min_y"]) * 100000) + (abs(source_turf.x - shape_bounds["center_x"]) * 1000) + source_turf.x
		if(EAST)
			return ((shape_bounds["max_x"] - source_turf.x) * 100000) + (abs(source_turf.y - shape_bounds["center_y"]) * 1000) + source_turf.y
		if(WEST)
			return ((source_turf.x - shape_bounds["min_x"]) * 100000) + (abs(source_turf.y - shape_bounds["center_y"]) * 1000) + source_turf.y

	return 0

/datum/world_edit_generator/outpost_radius/proc/build_shape_perimeter_candidates(list/footprint_turfs, radius, list/footprint_lookup, list/shape_bounds)
	var/list/candidates = list()
	var/list/candidate_lookup = list()
	if(!islist(footprint_turfs) || !length(footprint_turfs))
		return candidates

	radius = max(round(radius), 1)
	var/list/shell_data = build_shape_shell_turfs(footprint_turfs, radius, footprint_lookup, shape_bounds)
	var/list/shell_turfs = shell_data["turfs"]
	var/list/shell_lookup = shell_data["lookup"]
	for(var/turf/target_turf as anything in shell_turfs)
		if(!istype(target_turf))
			continue

		var/list/slot_dirs = build_shape_shell_slot_dirs(target_turf, radius, footprint_turfs, shell_lookup)
		for(var/dir_to_use as anything in slot_dirs)
			var/candidate_key = GLOB.world_edit_helpers.build_turf_dir_slot_key(target_turf, dir_to_use)
			if(!length(candidate_key) || candidate_lookup[candidate_key])
				continue

			candidate_lookup[candidate_key] = TRUE
			candidates += list(list(
				"source_turf" = GLOB.world_edit_helpers.step_turf(target_turf, get_cardinal_opposite_dir(dir_to_use), 1),
				"turf" = target_turf,
				"dir" = dir_to_use,
				"slot_index" = length(candidates) + 1,
			))

	return candidates

/datum/world_edit_generator/outpost_radius/proc/select_shape_opening_slots(list/candidate_slots, list/family_profile, list/shape_bounds)
	var/list/opening_dirs = islist(family_profile) ? family_profile["opening_dirs"] : null
	var/list/selected_slots = list()
	if(!islist(candidate_slots) || !length(candidate_slots))
		return selected_slots
	if(!islist(opening_dirs) || !length(opening_dirs))
		return selected_slots

	for(var/dir_to_use as anything in opening_dirs)
		var/list/best_slot = null
		var/best_score = null
		for(var/list/candidate_slot as anything in candidate_slots)
			if(candidate_slot["dir"] != dir_to_use)
				continue
			var/score = score_shape_opening_slot(candidate_slot, shape_bounds)
			if(isnull(best_score) || score < best_score)
				best_score = score
				best_slot = candidate_slot

		if(islist(best_slot))
			selected_slots += list(best_slot)

	return selected_slots

/datum/world_edit_generator/outpost_radius/proc/build_shape_sentry_candidates(list/opening_slot)
	var/list/candidates = list()
	if(!islist(opening_slot))
		return candidates

	var/turf/source_turf = opening_slot["source_turf"]
	if(!istype(source_turf))
		source_turf = opening_slot["turf"]
	var/dir_to_guard = opening_slot["dir"]
	if(!istype(source_turf))
		return candidates

	candidates += list(list(
		"turf" = source_turf,
		"dir" = dir_to_guard,
		"opening_dir" = dir_to_guard,
	))

	var/inward_dir = get_cardinal_opposite_dir(dir_to_guard)
	var/turf/inward_turf = GLOB.world_edit_helpers.step_turf(source_turf, inward_dir, 1)
	if(istype(inward_turf))
		candidates += list(list(
			"turf" = inward_turf,
			"dir" = dir_to_guard,
			"opening_dir" = dir_to_guard,
		))

	return candidates

/datum/world_edit_generator/outpost_radius/proc/build_shape_aware_perimeter_plan(list/footprint_turfs, list/params)
	var/datum/world_edit_plan/plan = new
	if(!islist(footprint_turfs) || !length(footprint_turfs))
		plan.metadata["error"] = "Unable to resolve the shape footprint."
		return plan

	var/list/config = params
	if(!islist(config) || !config["family_profile"])
		config = resolve_outpost_configuration(params)
	if(config["error"])
		plan.metadata["error"] = "[config["error"]]"
		return plan

	var/list/footprint_lookup = build_turf_lookup(footprint_turfs)
	var/list/shape_bounds = build_turf_bounds(footprint_turfs)
	var/radius = config["radius"]
	var/list/candidate_slots = build_shape_perimeter_candidates(footprint_turfs, radius, footprint_lookup, shape_bounds)
	var/list/opening_slots = select_shape_opening_slots(candidate_slots, config["family_profile"], shape_bounds)
	var/list/opening_lookup = list()
	var/list/opening_seen_lookup = list()
	for(var/list/opening_slot as anything in opening_slots)
		var/opening_slot_key = GLOB.world_edit_helpers.build_turf_dir_slot_key(opening_slot["turf"], opening_slot["dir"])
		if(!length(opening_slot_key) || opening_seen_lookup[opening_slot_key])
			continue
		opening_seen_lookup[opening_slot_key] = TRUE
		opening_lookup[opening_slot_key] = TRUE

	var/list/preview_turf_lookup = list()
	var/list/barricade_lookup = list()
	var/list/sentry_lookup = list()
	var/total_blocked_barricades = 0
	var/total_openings = 0
	var/total_blocked_openings = 0
	var/total_sentries = 0
	var/total_blocked_sentries = 0
	var/list/opening_dirs = islist(config["family_profile"]) ? config["family_profile"]["opening_dirs"] : null
	if(!islist(opening_dirs) || !length(opening_dirs))
		opening_dirs = list(NORTH, EAST, SOUTH, WEST)

	for(var/list/candidate_slot as anything in candidate_slots)
		var/turf/target_turf = candidate_slot["turf"]
		var/candidate_dir = candidate_slot["dir"]
		var/barricade_slot_key = GLOB.world_edit_helpers.build_turf_dir_slot_key(target_turf, candidate_dir)
		if(!istype(target_turf))
			continue
		if(!length(barricade_slot_key))
			continue
		if(opening_lookup[barricade_slot_key])
			continue
		if(!can_place_barricade_on_turf(target_turf, candidate_dir))
			total_blocked_barricades++
			continue
		if(barricade_lookup[barricade_slot_key])
			continue

		barricade_lookup[barricade_slot_key] = TRUE
		preview_turf_lookup[target_turf] = TRUE
		plan.placements += list(list(
			"kind" = "barricade",
			"turf" = target_turf,
			"dir" = candidate_dir,
			"defense_path" = select_barricade_path_for_slot(config["barricade_cycle"], candidate_slot["slot_index"] || 1, radius) || config["barricade_path"],
		))

	for(var/list/opening_slot as anything in opening_slots)
		var/turf/open_turf = opening_slot["turf"]
		var/opening_slot_key = GLOB.world_edit_helpers.build_turf_dir_slot_key(open_turf, opening_slot["dir"])
		if(!length(opening_slot_key) || opening_seen_lookup[opening_slot_key] != TRUE)
			continue
		opening_seen_lookup[opening_slot_key] = FALSE
		if(!istype(open_turf))
			total_blocked_openings++
			continue
		if(!can_place_barricade_on_turf(open_turf, opening_slot["dir"]))
			total_blocked_openings++
			continue

		total_openings++
		preview_turf_lookup[open_turf] = TRUE
		plan.placements += list(list(
			"kind" = "opening",
			"turf" = open_turf,
			"dir" = opening_slot["dir"],
		))

		var/list/sentry_candidates = build_shape_sentry_candidates(opening_slot)
		var/placed_sentry = FALSE
		for(var/list/sentry_candidate as anything in sentry_candidates)
			var/turf/sentry_turf = sentry_candidate["turf"]
			if(!istype(sentry_turf) || preview_turf_lookup[sentry_turf] || sentry_lookup[sentry_turf])
				continue
			if(!can_place_sentry_on_turf(sentry_turf))
				continue

			sentry_lookup[sentry_turf] = TRUE
			preview_turf_lookup[sentry_turf] = TRUE
			plan.placements += list(list(
				"kind" = "sentry",
				"turf" = sentry_turf,
				"dir" = sentry_candidate["dir"],
				"opening_dir" = sentry_candidate["opening_dir"],
				"defense_path" = config["sentry_path"],
				"faction" = config["faction"],
				"turned_on" = config["turned_on"],
			))
			placed_sentry = TRUE
			total_sentries++
			break

		if(!placed_sentry)
			total_blocked_sentries++

	if(length(opening_dirs) > total_openings)
		total_blocked_openings += length(opening_dirs) - total_openings

	for(var/turf/preview_turf as anything in preview_turf_lookup)
		plan.affected_turfs += preview_turf

	var/turf/center_turf = locate(round((shape_bounds["min_x"] + shape_bounds["max_x"]) / 2), round((shape_bounds["min_y"] + shape_bounds["max_y"]) / 2), shape_bounds["z"])
	if(!istype(center_turf))
		center_turf = footprint_turfs[clamp(round((length(footprint_turfs) + 1) / 2), 1, length(footprint_turfs))]

	plan.metadata["center_turf"] = center_turf
	plan.metadata["radius"] = radius
	plan.metadata["shape_mode"] = "footprint_offset"
	plan.metadata["shape_footprint_count"] = length(footprint_turfs)
	plan.metadata["anchor_count"] = length(footprint_turfs)
	plan.metadata["family"] = config["family"]
	plan.metadata["family_label"] = config["family_profile"]["label"]
	plan.metadata["family_description"] = config["family_profile"]["description"]
	plan.metadata["barricade_count"] = length(plan.placements) - total_openings - total_sentries
	plan.metadata["sentry_count"] = total_sentries
	plan.metadata["opening_count"] = total_openings
	plan.metadata["opening_dirs"] = format_opening_dirs(opening_dirs)
	plan.metadata["blocked_barricades"] = total_blocked_barricades
	plan.metadata["blocked_openings"] = total_blocked_openings
	plan.metadata["blocked_perimeter"] = total_blocked_barricades + total_blocked_openings
	plan.metadata["blocked_sentries"] = total_blocked_sentries
	return plan

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
	return null

/datum/world_edit_generator/outpost_radius/proc/is_open_construction_turf(turf/target_turf)
	if(!istype(target_turf, /turf/open))
		return FALSE

	var/turf/open/open_turf = target_turf
	if(!open_turf.allow_construction)
		return FALSE

	return TRUE

/datum/world_edit_generator/outpost_radius/proc/has_dense_blocker(turf/target_turf, ignore_barricades = FALSE)
	return GLOB.world_edit_helpers.has_dense_nonmob_blocker(target_turf, ignore_barricades)

/datum/world_edit_generator/outpost_radius/proc/can_place_barricade_on_turf(turf/target_turf, dir_to_use)
	if(!is_open_construction_turf(target_turf))
		return FALSE
	if(!GLOB.world_edit_helpers.is_cardinal_dir(dir_to_use))
		return FALSE
	if(has_dense_blocker(target_turf, TRUE))
		return FALSE
	if(GLOB.world_edit_helpers.has_barricade_in_dir(target_turf, dir_to_use))
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

/datum/world_edit_generator/outpost_radius/proc/register_perimeter_slot(list/result, turf/target_turf, dir_to_use, slot_index, offset_x, offset_y, radius, list/family_profile, list/barricade_cycle)
	if(!islist(result))
		return

	var/list/placements = result["placements"]
	var/list/openings = result["openings"]
	if(is_perimeter_opening_slot(dir_to_use, offset_x, offset_y, family_profile))
		if(can_place_barricade_on_turf(target_turf, dir_to_use))
			result["opening_count"]++
			openings += list(list(
				"turf" = target_turf,
				"dir" = dir_to_use,
				"slot_index" = slot_index,
			))
		else
			result["blocked_count"]++
			result["blocked_openings"]++
		return

	if(can_place_barricade_on_turf(target_turf, dir_to_use))
		placements += list(list(
			"turf" = target_turf,
			"dir" = dir_to_use,
			"barricade_path" = select_barricade_path_for_slot(barricade_cycle, slot_index, radius),
			"slot_index" = slot_index,
		))
		return

	result["blocked_count"]++
	result["blocked_barricades"]++

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
		register_perimeter_slot(result, top_turf, NORTH, slot_index, offset_x, radius, radius, family_profile, barricade_cycle)

		slot_index++
		var/turf/bottom_turf = locate(center_turf.x + offset_x, center_turf.y - radius, center_turf.z)
		register_perimeter_slot(result, bottom_turf, SOUTH, slot_index, offset_x, -radius, radius, family_profile, barricade_cycle)

	for(var/offset_y in -radius to radius)
		slot_index++
		var/turf/right_turf = locate(center_turf.x + radius, center_turf.y + offset_y, center_turf.z)
		register_perimeter_slot(result, right_turf, EAST, slot_index, radius, offset_y, radius, family_profile, barricade_cycle)

		slot_index++
		var/turf/left_turf = locate(center_turf.x - radius, center_turf.y + offset_y, center_turf.z)
		register_perimeter_slot(result, left_turf, WEST, slot_index, -radius, offset_y, radius, family_profile, barricade_cycle)

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

	if(length(anchor_turfs) > 1)
		var/datum/world_edit_plan/shape_plan = build_shape_aware_perimeter_plan(anchor_turfs, config)
		if(shape_plan.metadata["error"])
			plan.metadata["error"] = "[shape_plan.metadata["error"]]"
			return plan

		plan.placements = shape_plan.placements.Copy()
		plan.affected_turfs = shape_plan.affected_turfs.Copy()
		for(var/key in shape_plan.metadata)
			plan.metadata[key] = shape_plan.metadata[key]
		plan.metadata["placement_mode"] = "[placement_context["mode"] || "single"]"
		plan.metadata["anchor_count"] = length(anchor_turfs)
		plan.metadata["shape_label"] = shape_label
		if(islist(placement_context["shape_metadata"]))
			for(var/key in placement_context["shape_metadata"])
				if(!(key in plan.metadata))
					plan.metadata[key] = placement_context["shape_metadata"][key]
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
			var/placement_key
			if(placement["kind"] == "barricade")
				placement_key = GLOB.world_edit_helpers.build_turf_dir_slot_key(target_turf, placement["dir"])
			else
				placement_key = "[target_turf.x],[target_turf.y],[target_turf.z]:[placement["kind"]]"
			if(!length(placement_key))
				continue
			if(occupied_lookup[placement_key])
				plan.metadata["error"] = "Requested outpost footprint overlaps itself."
				plan.metadata["blocked_turf"] = "[target_turf.x],[target_turf.y],[target_turf.z]"
				return plan
			occupied_lookup[placement_key] = TRUE
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

	var/list/shape_result = GLOB.world_edit_placement_shapes.world_edit_build_shape_turfs(manager?.get_effective_placement_shape() || WORLD_EDIT_SHAPE_POINT, center_turf, null, params, NORTH)
	if(shape_result["error"])
		return "[shape_result["error"]]"

	var/planned_total = (radius * 8) + (place_sentries ? 4 : 0)
	if((!length(shape_result["turfs"]) || length(shape_result["turfs"]) <= 1) && planned_total > 68)
		return "The requested outpost exceeds the Phase 1 placement cap."

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
			if(!can_place_barricade_on_turf(target_turf, placement["dir"]))
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
