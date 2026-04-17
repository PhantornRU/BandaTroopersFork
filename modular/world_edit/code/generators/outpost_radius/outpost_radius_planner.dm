/datum/world_edit_generator/outpost_radius/proc/is_perimeter_opening_slot(dir_to_use, offset_x, offset_y, list/layout_profile)
	var/list/opening_dirs = get_layout_opening_dirs(layout_profile)
	if(!islist(opening_dirs) || !(dir_to_use in opening_dirs))
		return FALSE
	var/opening_width = get_layout_opening_width(layout_profile)
	var/opening_start = -((opening_width - 1) / 2)
	if((opening_width % 2) == 0)
		opening_start = -(opening_width / 2)
	var/opening_end = opening_start + opening_width - 1

	switch(dir_to_use)
		if(NORTH, SOUTH)
			return (offset_x >= opening_start) && (offset_x <= opening_end)
		if(EAST, WEST)
			return (offset_y >= opening_start) && (offset_y <= opening_end)

	return FALSE

/datum/world_edit_generator/outpost_radius/proc/select_barricade_path_for_slot(list/barricade_cycle, slot_index, radius, barricade_pattern = "uniform")
	if(!islist(barricade_cycle) || !length(barricade_cycle))
		return null

	if(length(barricade_cycle) <= 1 || barricade_pattern == "uniform")
		return barricade_cycle[1]

	var/effective_slot_index = slot_index
	if(barricade_pattern == "paired")
		effective_slot_index = round((slot_index + 1) / 2)

	var/cycle_index = ((effective_slot_index + max(radius, 1) - 1) % length(barricade_cycle)) + 1
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

/datum/world_edit_generator/outpost_radius/proc/get_outpost_shape_support_class(shape_id)
	switch("[shape_id]")
		if(
			WORLD_EDIT_SHAPE_POINT,
			WORLD_EDIT_SHAPE_LINE,
			WORLD_EDIT_SHAPE_RECTANGLE,
			WORLD_EDIT_SHAPE_FILLED_RECTANGLE,
			WORLD_EDIT_SHAPE_CIRCLE,
			WORLD_EDIT_SHAPE_RING,
			WORLD_EDIT_SHAPE_ELLIPSE,
			WORLD_EDIT_SHAPE_DIAMOND,
			WORLD_EDIT_SHAPE_TRIANGLE,
			WORLD_EDIT_SHAPE_SECTOR,
			WORLD_EDIT_SHAPE_POLYGON
		)
			return "full"
		if(
			WORLD_EDIT_SHAPE_POLYLINE,
			WORLD_EDIT_SHAPE_BRUSH_PATH,
			WORLD_EDIT_SHAPE_CUSTOM_MASK
		)
			return "limited"
		if(WORLD_EDIT_SHAPE_SCATTER_CLUSTER)
			return "risky"
	return "unsupported"

/datum/world_edit_generator/outpost_radius/proc/count_shape_connected_components(list/footprint_turfs)
	if(!islist(footprint_turfs) || !length(footprint_turfs))
		return 0

	var/list/lookup = build_turf_lookup(footprint_turfs)
	var/list/unvisited = lookup.Copy()
	var/component_count = 0
	for(var/turf/start_turf as anything in footprint_turfs)
		if(!istype(start_turf) || !unvisited[start_turf])
			continue
		component_count++
		var/list/open_list = list(start_turf)
		unvisited[start_turf] = FALSE
		while(length(open_list))
			var/turf/current_turf = open_list[length(open_list)]
			open_list.Cut(length(open_list), length(open_list) + 1)
			for(var/check_dir in GLOB.cardinals)
				var/turf/neighbor_turf = get_step(current_turf, check_dir)
				if(!lookup[neighbor_turf] || !unvisited[neighbor_turf])
					continue
				unvisited[neighbor_turf] = FALSE
				open_list += neighbor_turf
	return component_count

/datum/world_edit_generator/outpost_radius/proc/get_outpost_shape_support_validation_error(shape_id, list/footprint_turfs, list/placement_context = null)
	var/support_class = get_outpost_shape_support_class(shape_id)
	var/shape_label = GLOB.world_edit_placement_shapes.world_edit_get_placement_shape_label(shape_id)
	switch(support_class)
		if("unsupported")
			return "Outpost Radius does not support [shape_label]."
		if("risky")
			return "Outpost Radius does not support [shape_label] yet; use a connected contour or anchor-based shape instead."

	if(support_class != "limited")
		return null

	var/component_count = count_shape_connected_components(footprint_turfs)
	if(component_count > 1)
		return "[shape_label] resolves to disconnected islands; Outpost Radius requires one connected footprint."
	return null

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

/datum/world_edit_generator/outpost_radius/proc/select_shape_direction_slots(list/candidate_slots, list/target_dirs, slots_per_dir, list/shape_bounds)
	var/list/selected_slots = list()
	if(!islist(candidate_slots) || !length(candidate_slots))
		return selected_slots
	if(!islist(target_dirs) || !length(target_dirs))
		return selected_slots

	var/slots_to_select = max(round(text2num("[slots_per_dir]") || 0), 1)
	var/list/selected_lookup = list()
	for(var/dir_to_use as anything in target_dirs)
		for(var/i in 1 to slots_to_select)
			var/list/best_slot = null
			var/best_score = null
			for(var/list/candidate_slot as anything in candidate_slots)
				if(candidate_slot["dir"] != dir_to_use)
					continue
				var/slot_key = GLOB.world_edit_helpers.build_turf_dir_slot_key(candidate_slot["turf"], candidate_slot["dir"])
				if(!length(slot_key) || selected_lookup[slot_key])
					continue
				var/score = score_shape_opening_slot(candidate_slot, shape_bounds)
				if(isnull(best_score) || score < best_score)
					best_score = score
					best_slot = candidate_slot

			if(!islist(best_slot))
				break

			var/best_slot_key = GLOB.world_edit_helpers.build_turf_dir_slot_key(best_slot["turf"], best_slot["dir"])
			if(length(best_slot_key))
				selected_lookup[best_slot_key] = TRUE
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
	var/place_sentries = config["place_sentries"]
	var/list/candidate_slots = build_shape_perimeter_candidates(footprint_turfs, radius, footprint_lookup, shape_bounds)
	var/list/layout_profile = config["layout_profile"]
	var/list/opening_dirs = get_layout_opening_dirs(layout_profile)
	var/list/guard_dirs = get_layout_guard_dirs(layout_profile)
	var/list/opening_slots = select_shape_direction_slots(candidate_slots, opening_dirs, get_layout_opening_slots_per_dir(layout_profile), shape_bounds)
	var/list/guard_slots = place_sentries ? select_shape_direction_slots(candidate_slots, guard_dirs, 1, shape_bounds) : list()
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
			"defense_path" = select_barricade_path_for_slot(config["barricade_cycle"], candidate_slot["slot_index"] || 1, radius, config["barricade_pattern"]) || config["barricade_path"],
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

	if(place_sentries)
		for(var/list/guard_slot as anything in guard_slots)
			var/list/sentry_candidates = build_shape_sentry_candidates(guard_slot)
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

		if(length(guard_dirs) > length(guard_slots))
			total_blocked_sentries += length(guard_dirs) - length(guard_slots)

	var/expected_openings = get_layout_expected_opening_count(layout_profile)
	if(expected_openings > total_openings)
		total_blocked_openings += expected_openings - total_openings

	for(var/turf/preview_turf as anything in preview_turf_lookup)
		plan.affected_turfs += preview_turf

	var/turf/center_turf = locate(round((shape_bounds["min_x"] + shape_bounds["max_x"]) / 2), round((shape_bounds["min_y"] + shape_bounds["max_y"]) / 2), shape_bounds["z"])
	if(!istype(center_turf))
		center_turf = footprint_turfs[clamp(round((length(footprint_turfs) + 1) / 2), 1, length(footprint_turfs))]

	plan.metadata["center_turf"] = center_turf
	plan.metadata["radius"] = radius
	plan.metadata["shape_mode"] = "footprint_offset"
	plan.metadata["shape_footprint_count"] = length(footprint_turfs)
	plan.metadata["base_shape_turfs"] = footprint_turfs.Copy()
	plan.metadata["anchor_count"] = length(footprint_turfs)
	plan.metadata["family"] = config["family"]
	plan.metadata["family_label"] = config["family_profile"]["label"]
	plan.metadata["family_description"] = config["family_profile"]["description"]
	plan.metadata["layout_variant"] = config["layout_variant"]
	plan.metadata["layout_label"] = config["layout_profile"]["label"]
	plan.metadata["layout_description"] = config["layout_profile"]["description"]
	plan.metadata["opening_width"] = config["opening_width"]
	plan.metadata["guard_mode"] = config["guard_mode"]
	plan.metadata["barricade_pattern"] = config["barricade_pattern"]
	plan.metadata["barricade_count"] = length(plan.placements) - total_openings - total_sentries
	plan.metadata["sentry_count"] = total_sentries
	plan.metadata["opening_count"] = total_openings
	plan.metadata["opening_dirs"] = format_opening_dirs(opening_dirs)
	plan.metadata["blocked_barricades"] = total_blocked_barricades
	plan.metadata["blocked_openings"] = total_blocked_openings
	plan.metadata["blocked_perimeter"] = total_blocked_barricades + total_blocked_openings
	plan.metadata["blocked_sentries"] = total_blocked_sentries
	plan.metadata["generator_effect_turfs"] = plan.affected_turfs.Copy()
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

	var/layout_id = resolve_outpost_layout_id(params["layout_variant"])
	if(!layout_id)
		config["error"] = "Invalid outpost layout selected."
		return config

	var/list/layout_profile = get_outpost_layout_profile(layout_id)
	if(!islist(layout_profile))
		config["error"] = "Invalid outpost layout selected."
		return config

	var/opening_width = resolve_opening_width(params["opening_width"], layout_profile)
	if(isnull(opening_width))
		config["error"] = "Invalid outpost passage width selected."
		return config

	var/guard_mode = resolve_guard_mode(params["guard_mode"])
	if(isnull(guard_mode))
		config["error"] = "Invalid outpost guard mode selected."
		return config

	var/barricade_pattern = resolve_barricade_pattern(params["barricade_pattern"], family_profile)
	if(isnull(barricade_pattern))
		config["error"] = "Invalid barricade pattern selected."
		return config

	var/list/effective_layout_profile = layout_profile.Copy()
	effective_layout_profile["opening_dirs"] = get_layout_opening_dirs(layout_profile)
	effective_layout_profile["opening_width"] = opening_width
	effective_layout_profile["guard_dirs"] = get_guard_dirs_for_mode(guard_mode, layout_profile)

	var/radius = text2num("[params["radius"]]") || 4
	if(!isnum(radius) || radius < 1 || radius > 10)
		config["error"] = "radius must stay in the range 1..10."
		return config
	opening_width = clamp(round(opening_width), 1, (radius * 2) + 1)
	effective_layout_profile["opening_width"] = opening_width

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
	config["layout_variant"] = layout_id
	config["layout_profile"] = effective_layout_profile
	config["opening_width"] = opening_width
	config["guard_mode"] = guard_mode
	config["radius"] = radius
	config["place_sentries"] = place_sentries
	config["barricade_path"] = barricade_path
	config["barricade_cycle"] = build_barricade_cycle(family_profile, barricade_path)
	config["barricade_pattern"] = barricade_pattern
	config["sentry_path"] = sentry_path
	config["faction"] = faction
	config["turned_on"] = turned_on
	return config

/datum/world_edit_generator/outpost_radius/evaluate_shape_contract(datum/world_edit_shape_contract/shape_contract, list/params, list/placement_context)
	var/shape_id = "[shape_contract?.shape_id || placement_context["shape"] || WORLD_EDIT_SHAPE_POINT]"
	var/list/anchor_turfs = shape_contract?.copy_anchor_turfs() || placement_context["anchor_turfs"]
	var/support_class = get_outpost_shape_support_class(shape_id)
	if("[shape_id]" == WORLD_EDIT_SHAPE_POINT)
		return list(
			"support_class" = support_class,
			"error" = null,
			"metadata" = list("shape_support_class" = support_class),
		)
	if(!islist(anchor_turfs) || !length(anchor_turfs))
		return list(
			"support_class" = support_class,
			"error" = "Unable to resolve the shape footprint.",
			"metadata" = list("shape_support_class" = support_class),
		)

	var/list/config = resolve_outpost_configuration(params)
	if(config["error"])
		return list(
			"support_class" = support_class,
			"error" = "[config["error"]]",
			"metadata" = list("shape_support_class" = support_class),
		)

	var/list/footprint_lookup = build_turf_lookup(anchor_turfs)
	if(!length(footprint_lookup))
		return list(
			"support_class" = support_class,
			"error" = "Unable to resolve the shape footprint.",
			"metadata" = list("shape_support_class" = support_class),
		)

	var/list/footprint_turfs = list()
	for(var/turf/footprint_turf as anything in footprint_lookup)
		if(istype(footprint_turf))
			footprint_turfs += footprint_turf
	if(!length(footprint_turfs))
		return list(
			"support_class" = support_class,
			"error" = "Unable to resolve the shape footprint.",
			"metadata" = list("shape_support_class" = support_class),
		)

	var/support_validation_error = get_outpost_shape_support_validation_error(shape_id, footprint_turfs, placement_context)
	if(length("[support_validation_error]"))
		return list(
			"support_class" = support_class,
			"error" = support_validation_error,
			"metadata" = list("shape_support_class" = support_class),
		)

	var/list/shape_bounds = build_turf_bounds(footprint_turfs)
	var/list/candidate_slots = build_shape_perimeter_candidates(footprint_turfs, config["radius"], footprint_lookup, shape_bounds)
	if(!length(candidate_slots))
		return list(
			"support_class" = support_class,
			"error" = "Selected footprint cannot build a perimeter shell for Outpost Radius.",
			"metadata" = list("shape_support_class" = support_class),
		)

	var/list/layout_profile = config["layout_profile"]
	var/list/opening_dirs = get_layout_opening_dirs(layout_profile)
	if(length(opening_dirs))
		var/list/opening_slots = select_shape_direction_slots(candidate_slots, opening_dirs, get_layout_opening_slots_per_dir(layout_profile), shape_bounds)
		var/list/placeable_by_dir = list()
		for(var/list/opening_slot as anything in opening_slots)
			var/opening_dir = opening_slot["dir"]
			var/turf/open_turf = opening_slot["turf"]
			if(!GLOB.world_edit_helpers.is_cardinal_dir(opening_dir))
				continue
			if(!can_place_barricade_on_turf(open_turf, opening_dir))
				continue
			placeable_by_dir["[opening_dir]"] = TRUE

		for(var/opening_dir as anything in opening_dirs)
			if(!placeable_by_dir["[opening_dir]"])
				return list(
					"support_class" = support_class,
					"error" = "Selected footprint cannot support the required Outpost Radius openings.",
					"metadata" = list("shape_support_class" = support_class),
				)

	var/datum/world_edit_plan/shape_plan = build_shape_aware_perimeter_plan(footprint_turfs, config)
	if(shape_plan.metadata["error"])
		return list(
			"support_class" = support_class,
			"error" = "[shape_plan.metadata["error"]]",
			"metadata" = list("shape_support_class" = support_class),
		)
	if(!length(shape_plan.placements) && !length(shape_plan.deletions))
		return list(
			"support_class" = support_class,
			"error" = "Outpost Radius could not build any valid placements for the selected footprint.",
			"metadata" = list("shape_support_class" = support_class),
		)
	if((shape_plan.metadata["opening_count"] || 0) <= 0 && length(opening_dirs))
		return list(
			"support_class" = support_class,
			"error" = "Selected footprint cannot support the required Outpost Radius openings.",
			"metadata" = list("shape_support_class" = support_class),
		)

	return list(
		"support_class" = support_class,
		"error" = null,
		"metadata" = list("shape_support_class" = support_class),
	)

/datum/world_edit_generator/outpost_radius/get_shape_support_error(shape_id, list/anchor_turfs, list/params, list/placement_context)
	var/datum/world_edit_shape_contract/shape_contract = build_shape_contract_from_placement_context(shape_id, anchor_turfs, placement_context)
	var/list/support_result = evaluate_shape_contract(shape_contract, params, placement_context)
	return support_result["error"]
