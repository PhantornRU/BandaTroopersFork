/datum/world_edit_generator/outpost_radius/proc/build_centered_opening_range(center_offset, opening_width, radius)
	var/start_offset = center_offset - ((opening_width - 1) / 2)
	if((opening_width % 2) == 0)
		start_offset = center_offset - (opening_width / 2)
	start_offset = max(round(start_offset), -radius)
	var/end_offset = min(start_offset + opening_width - 1, radius)
	start_offset = max(end_offset - opening_width + 1, -radius)
	return list(
		"start" = start_offset,
		"end" = end_offset,
	)

/datum/world_edit_generator/outpost_radius/proc/build_split_pair_opening_ranges(radius, opening_width)
	var/span = (radius * 2) + 1
	if(span < opening_width * 2)
		return list(build_centered_opening_range(0, opening_width, radius))

	var/separation = max(round(radius / 2), 1)
	var/list/left_range = build_centered_opening_range(-separation, opening_width, radius)
	var/list/right_range = build_centered_opening_range(separation, opening_width, radius)
	if(left_range["end"] >= right_range["start"])
		return list(build_centered_opening_range(0, opening_width, radius))
	return list(left_range, right_range)

/datum/world_edit_generator/outpost_radius/proc/build_point_opening_ranges(dir_to_use, radius, list/layout_profile)
	var/list/opening_dirs = get_layout_opening_dirs(layout_profile)
	if(!islist(opening_dirs) || !(dir_to_use in opening_dirs))
		return list()

	var/opening_width = get_layout_opening_width(layout_profile)
	var/slot_mode = get_layout_opening_slot_mode(layout_profile)
	var/slots_per_dir = get_layout_opening_slots_per_dir(layout_profile)
	if(slot_mode == "split_pair" && slots_per_dir >= 2)
		return build_split_pair_opening_ranges(radius, opening_width)
	return list(build_centered_opening_range(0, opening_width, radius))

/datum/world_edit_generator/outpost_radius/proc/is_offset_in_opening_ranges(offset_value, list/opening_ranges)
	if(!islist(opening_ranges))
		return FALSE
	for(var/list/range_data as anything in opening_ranges)
		if(!islist(range_data))
			continue
		if(offset_value >= range_data["start"] && offset_value <= range_data["end"])
			return TRUE
	return FALSE

/datum/world_edit_generator/outpost_radius/proc/is_perimeter_opening_slot(dir_to_use, offset_x, offset_y, list/layout_profile, radius)
	var/list/opening_ranges = build_point_opening_ranges(dir_to_use, radius, layout_profile)
	if(!length(opening_ranges))
		return FALSE

	switch(dir_to_use)
		if(NORTH, SOUTH)
			return is_offset_in_opening_ranges(offset_x, opening_ranges)
		if(EAST, WEST)
			return is_offset_in_opening_ranges(offset_y, opening_ranges)

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

/datum/world_edit_generator/outpost_radius/proc/build_sentry_profile_guard_dirs(list/guard_dirs, sentry_profile)
	var/list/resolved_guard_dirs = islist(guard_dirs) ? guard_dirs.Copy() : list()
	if(!length(resolved_guard_dirs))
		return list()

	switch("[sentry_profile]")
		if("none")
			return list()
		if("light_cover")
			return resolved_guard_dirs.Copy(1, min(length(resolved_guard_dirs), 2) + 1)
		if("crossfire")
			var/list/prioritized_dirs = list()
			if((NORTH in resolved_guard_dirs) && (SOUTH in resolved_guard_dirs))
				prioritized_dirs += NORTH
				prioritized_dirs += SOUTH
			if((EAST in resolved_guard_dirs) && (WEST in resolved_guard_dirs))
				prioritized_dirs += EAST
				prioritized_dirs += WEST
			for(var/dir_to_guard as anything in resolved_guard_dirs)
				if(dir_to_guard in prioritized_dirs)
					continue
				prioritized_dirs += dir_to_guard
			return prioritized_dirs.Copy(1, min(length(prioritized_dirs), 4) + 1)
	return resolved_guard_dirs

/datum/world_edit_generator/outpost_radius/proc/build_sentry_guard_candidates(dir_to_guard, inner_radius, sentry_profile = "entry_guard")
	var/fallback_distance = max(inner_radius - 1, 0)
	var/deep_distance = max(inner_radius - 2, 0)

	switch(dir_to_guard)
		if(NORTH)
			switch("[sentry_profile]")
				if("inner_guard")
					return list(
						list("dx" = 0, "dy" = fallback_distance, "dir" = NORTH),
						list("dx" = 1, "dy" = fallback_distance, "dir" = NORTH),
						list("dx" = -1, "dy" = fallback_distance, "dir" = NORTH),
						list("dx" = 0, "dy" = inner_radius, "dir" = NORTH),
					)
				if("crossfire")
					return list(
						list("dx" = 1, "dy" = fallback_distance, "dir" = NORTH),
						list("dx" = -1, "dy" = fallback_distance, "dir" = NORTH),
						list("dx" = 0, "dy" = fallback_distance, "dir" = NORTH),
						list("dx" = 0, "dy" = deep_distance, "dir" = NORTH),
						list("dx" = 0, "dy" = inner_radius, "dir" = NORTH),
					)
			return list(
				list("dx" = 0, "dy" = inner_radius, "dir" = NORTH),
				list("dx" = 1, "dy" = fallback_distance, "dir" = NORTH),
				list("dx" = -1, "dy" = fallback_distance, "dir" = NORTH),
				list("dx" = 0, "dy" = fallback_distance, "dir" = NORTH),
			)
		if(SOUTH)
			switch("[sentry_profile]")
				if("inner_guard")
					return list(
						list("dx" = 0, "dy" = -fallback_distance, "dir" = SOUTH),
						list("dx" = 1, "dy" = -fallback_distance, "dir" = SOUTH),
						list("dx" = -1, "dy" = -fallback_distance, "dir" = SOUTH),
						list("dx" = 0, "dy" = -inner_radius, "dir" = SOUTH),
					)
				if("crossfire")
					return list(
						list("dx" = 1, "dy" = -fallback_distance, "dir" = SOUTH),
						list("dx" = -1, "dy" = -fallback_distance, "dir" = SOUTH),
						list("dx" = 0, "dy" = -fallback_distance, "dir" = SOUTH),
						list("dx" = 0, "dy" = -deep_distance, "dir" = SOUTH),
						list("dx" = 0, "dy" = -inner_radius, "dir" = SOUTH),
					)
			return list(
				list("dx" = 0, "dy" = -inner_radius, "dir" = SOUTH),
				list("dx" = 1, "dy" = -fallback_distance, "dir" = SOUTH),
				list("dx" = -1, "dy" = -fallback_distance, "dir" = SOUTH),
				list("dx" = 0, "dy" = -fallback_distance, "dir" = SOUTH),
			)
		if(EAST)
			switch("[sentry_profile]")
				if("inner_guard")
					return list(
						list("dx" = fallback_distance, "dy" = 0, "dir" = EAST),
						list("dx" = fallback_distance, "dy" = 1, "dir" = EAST),
						list("dx" = fallback_distance, "dy" = -1, "dir" = EAST),
						list("dx" = inner_radius, "dy" = 0, "dir" = EAST),
					)
				if("crossfire")
					return list(
						list("dx" = fallback_distance, "dy" = 1, "dir" = EAST),
						list("dx" = fallback_distance, "dy" = -1, "dir" = EAST),
						list("dx" = fallback_distance, "dy" = 0, "dir" = EAST),
						list("dx" = deep_distance, "dy" = 0, "dir" = EAST),
						list("dx" = inner_radius, "dy" = 0, "dir" = EAST),
					)
			return list(
				list("dx" = inner_radius, "dy" = 0, "dir" = EAST),
				list("dx" = fallback_distance, "dy" = 1, "dir" = EAST),
				list("dx" = fallback_distance, "dy" = -1, "dir" = EAST),
				list("dx" = fallback_distance, "dy" = 0, "dir" = EAST),
			)
		if(WEST)
			switch("[sentry_profile]")
				if("inner_guard")
					return list(
						list("dx" = -fallback_distance, "dy" = 0, "dir" = WEST),
						list("dx" = -fallback_distance, "dy" = 1, "dir" = WEST),
						list("dx" = -fallback_distance, "dy" = -1, "dir" = WEST),
						list("dx" = -inner_radius, "dy" = 0, "dir" = WEST),
					)
				if("crossfire")
					return list(
						list("dx" = -fallback_distance, "dy" = 1, "dir" = WEST),
						list("dx" = -fallback_distance, "dy" = -1, "dir" = WEST),
						list("dx" = -fallback_distance, "dy" = 0, "dir" = WEST),
						list("dx" = -deep_distance, "dy" = 0, "dir" = WEST),
						list("dx" = -inner_radius, "dy" = 0, "dir" = WEST),
					)
			return list(
				list("dx" = -inner_radius, "dy" = 0, "dir" = WEST),
				list("dx" = -fallback_distance, "dy" = 1, "dir" = WEST),
				list("dx" = -fallback_distance, "dy" = -1, "dir" = WEST),
				list("dx" = -fallback_distance, "dy" = 0, "dir" = WEST),
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

/datum/world_edit_generator/outpost_radius/proc/build_point_radius_area_turfs(turf/center_turf, radius)
	var/list/area_turfs = list()
	if(!istype(center_turf))
		return area_turfs

	radius = max(round(radius), 1)
	for(var/turf/target_turf in range(radius, center_turf))
		if(!istype(target_turf) || target_turf.z != center_turf.z)
			continue
		if(max(abs(target_turf.x - center_turf.x), abs(target_turf.y - center_turf.y)) > radius)
			continue
		area_turfs += target_turf

	return area_turfs

/datum/world_edit_generator/outpost_radius/proc/build_shape_radius_area_turfs(list/footprint_turfs, radius, list/footprint_lookup, list/shape_bounds, list/distance_cache = null)
	var/list/area_turfs = list()
	if(!islist(footprint_turfs) || !length(footprint_turfs))
		return area_turfs

	radius = max(round(radius), 1)
	var/z_level = shape_bounds["z"]
	if(isnull(z_level))
		return area_turfs

	for(var/y in (shape_bounds["min_y"] - radius) to (shape_bounds["max_y"] + radius))
		for(var/x in (shape_bounds["min_x"] - radius) to (shape_bounds["max_x"] + radius))
			var/turf/target_turf = locate(x, y, z_level)
			if(!istype(target_turf))
				continue
			if(footprint_lookup[target_turf])
				area_turfs += target_turf
				continue
			if(get_shape_chebyshev_distance_to_footprint(target_turf, footprint_turfs, distance_cache) > radius)
				continue
			area_turfs += target_turf

	return area_turfs

/datum/world_edit_generator/outpost_radius/proc/filter_outpost_candidate_turfs(list/start_turfs, list/candidate_turfs, list/traversal_turfs, list/radius_policy, list/pinned_turfs = null, list/pinned_lookup_override = null, list/approach_line_cache = null, list/approach_result_cache = null)
	var/list/result = list()
	var/list/result_lookup = list()
	var/list/policy = islist(radius_policy) ? radius_policy : GLOB.world_edit_helpers.get_world_edit_radius_policy(radius_policy)
	var/only_clear_tiles = !!policy["only_clear_tiles"]
	var/only_reachable_tiles = !!policy["only_reachable_tiles"]
	var/treat_windows_as_blockers = !!policy["treat_windows_as_blockers"]
	var/list/start_lookup = list()
	var/list/pinned_lookup = islist(pinned_lookup_override) ? pinned_lookup_override : list()
	var/z_level = null

	if(islist(start_turfs))
		for(var/turf/start_turf as anything in start_turfs)
			if(!istype(start_turf))
				continue
			if(isnull(z_level))
				z_level = start_turf.z
			if(start_turf.z != z_level || start_lookup[start_turf])
				continue
			start_lookup[start_turf] = TRUE

	var/list/pinned_source = islist(pinned_lookup_override) ? pinned_lookup_override : pinned_turfs
	if(islist(pinned_source))
		for(var/turf/pinned_turf as anything in pinned_source)
			if(!istype(pinned_turf))
				continue
			if(isnull(z_level))
				z_level = pinned_turf.z
			if(pinned_turf.z != z_level || pinned_lookup[pinned_turf])
				continue
			if(!islist(pinned_lookup_override))
				pinned_lookup[pinned_turf] = TRUE
			if(!result_lookup[pinned_turf])
				result_lookup[pinned_turf] = TRUE
				result += pinned_turf

	if(!length(start_lookup))
		for(var/turf/pinned_turf as anything in pinned_lookup)
			start_lookup[pinned_turf] = TRUE

	var/list/filtered_candidate_lookup = list()
	var/list/filtered_candidates = list()
	if(islist(candidate_turfs))
		for(var/turf/candidate_turf as anything in candidate_turfs)
			if(!istype(candidate_turf))
				continue
			if(isnull(z_level))
				z_level = candidate_turf.z
			if(candidate_turf.z != z_level || filtered_candidate_lookup[candidate_turf])
				continue
			filtered_candidate_lookup[candidate_turf] = TRUE
			filtered_candidates += candidate_turf
			if(!only_clear_tiles && !only_reachable_tiles && !result_lookup[candidate_turf])
				result_lookup[candidate_turf] = TRUE
				result += candidate_turf

	if(!only_clear_tiles && !only_reachable_tiles)
		return result

	if(!only_reachable_tiles)
		for(var/turf/candidate_turf as anything in filtered_candidates)
			if(result_lookup[candidate_turf])
				continue

			var/is_allowed = FALSE
			for(var/turf/start_turf as anything in start_lookup)
				if(has_clear_outpost_approach(start_turf, candidate_turf, treat_windows_as_blockers, pinned_lookup, approach_line_cache, approach_result_cache))
					is_allowed = TRUE
					break

			if(!is_allowed)
				continue

			result_lookup[candidate_turf] = TRUE
			result += candidate_turf

		return result

	var/list/traversal_lookup = list()
	var/list/raw_traversal_turfs = islist(traversal_turfs) ? traversal_turfs : filtered_candidates
	for(var/turf/traversal_turf as anything in raw_traversal_turfs)
		if(!istype(traversal_turf))
			continue
		if(isnull(z_level))
			z_level = traversal_turf.z
		if(traversal_turf.z != z_level || traversal_lookup[traversal_turf])
			continue
		if((only_clear_tiles || only_reachable_tiles) && !outpost_path_passable(traversal_turf, treat_windows_as_blockers))
			continue
		traversal_lookup[traversal_turf] = TRUE

	var/list/visited_lookup = list()
	var/list/open_turfs = list()
	for(var/turf/start_turf as anything in start_lookup)
		if(!istype(start_turf) || visited_lookup[start_turf])
			continue
		visited_lookup[start_turf] = TRUE
		open_turfs += start_turf

	var/search_index = 1
	while(search_index <= length(open_turfs))
		var/turf/current_turf = open_turfs[search_index++]
		for(var/check_dir in GLOB.cardinals)
			var/turf/adjacent_turf = get_step(current_turf, check_dir)
			if(!traversal_lookup[adjacent_turf] || visited_lookup[adjacent_turf])
				continue
			visited_lookup[adjacent_turf] = TRUE
			open_turfs += adjacent_turf

	for(var/turf/candidate_turf as anything in filtered_candidates)
		if(result_lookup[candidate_turf] || !is_outpost_candidate_reachable_from_seed(candidate_turf, visited_lookup))
			continue
		result_lookup[candidate_turf] = TRUE
		result += candidate_turf

	return result

/datum/world_edit_generator/outpost_radius/proc/filter_outpost_slots_by_radius_policy(list/start_turfs, list/candidate_slots, list/traversal_turfs, list/radius_policy, list/pinned_turfs = null, list/pinned_lookup_override = null, list/approach_line_cache = null, list/approach_result_cache = null)
	if(!islist(candidate_slots) || !length(candidate_slots))
		return list()

	var/list/candidate_turfs = list()
	var/list/candidate_turf_lookup = list()
	for(var/list/candidate_slot as anything in candidate_slots)
		var/turf/target_turf = candidate_slot["turf"]
		if(!istype(target_turf) || candidate_turf_lookup[target_turf])
			continue
		candidate_turf_lookup[target_turf] = TRUE
		candidate_turfs += target_turf

	var/list/allowed_turfs = filter_outpost_candidate_turfs(start_turfs, candidate_turfs, traversal_turfs, radius_policy, pinned_turfs || start_turfs, pinned_lookup_override, approach_line_cache, approach_result_cache)
	var/list/allowed_lookup = build_turf_lookup(allowed_turfs)
	var/list/filtered_slots = list()
	for(var/list/candidate_slot as anything in candidate_slots)
		var/turf/target_turf = candidate_slot["turf"]
		if(allowed_lookup[target_turf])
			filtered_slots += list(candidate_slot)

	return filtered_slots

/datum/world_edit_generator/outpost_radius/proc/resolve_outpost_shape_seed_turf(list/footprint_turfs, list/placement_context)
	var/turf/seed_turf = get_shape_placement_seed_turf(null, placement_context)
	if(istype(seed_turf))
		return seed_turf
	if(islist(footprint_turfs) && length(footprint_turfs))
		return footprint_turfs[1]
	return null

/datum/world_edit_generator/outpost_radius/proc/build_outpost_approach_line_cache_key(turf/start_turf, turf/target_turf)
	if(!istype(start_turf) || !istype(target_turf))
		return null
	return "[REF(start_turf)]>[REF(target_turf)]"

/datum/world_edit_generator/outpost_radius/proc/build_outpost_approach_result_cache_key(turf/start_turf, turf/target_turf, treat_windows_as_blockers, list/pinned_lookup = null)
	var/line_key = build_outpost_approach_line_cache_key(start_turf, target_turf)
	if(!length(line_key))
		return null
	var/pinned_lookup_ref = islist(pinned_lookup) ? "[REF(pinned_lookup)]" : ""
	return "[line_key]|[treat_windows_as_blockers ? 1 : 0]|[pinned_lookup_ref]"

/datum/world_edit_generator/outpost_radius/proc/has_clear_outpost_approach(turf/start_turf, turf/target_turf, treat_windows_as_blockers, list/pinned_lookup = null, list/approach_line_cache = null, list/approach_result_cache = null)
	if(!istype(start_turf) || !istype(target_turf) || start_turf.z != target_turf.z)
		return FALSE

	var/result_cache_key = build_outpost_approach_result_cache_key(start_turf, target_turf, treat_windows_as_blockers, pinned_lookup)
	if(length(result_cache_key) && islist(approach_result_cache) && !isnull(approach_result_cache[result_cache_key]))
		return approach_result_cache[result_cache_key]

	var/line_cache_key = build_outpost_approach_line_cache_key(start_turf, target_turf)
	var/list/line_turfs = length(line_cache_key) && islist(approach_line_cache) ? approach_line_cache[line_cache_key] : null
	if(!islist(line_turfs))
		line_turfs = GLOB.world_edit_helpers.collect_line_turfs(start_turf, target_turf)
		if(length(line_cache_key) && islist(approach_line_cache))
			approach_line_cache[line_cache_key] = line_turfs
	if(!length(line_turfs))
		if(length(result_cache_key) && islist(approach_result_cache))
			approach_result_cache[result_cache_key] = FALSE
		return FALSE

	for(var/turf/line_turf as anything in line_turfs)
		if(!istype(line_turf))
			continue
		if(line_turf == start_turf || line_turf == target_turf)
			continue
		if(islist(pinned_lookup) && pinned_lookup[line_turf])
			continue
		if(!outpost_path_passable(line_turf, treat_windows_as_blockers))
			if(length(result_cache_key) && islist(approach_result_cache))
				approach_result_cache[result_cache_key] = FALSE
			return FALSE

	if(length(result_cache_key) && islist(approach_result_cache))
		approach_result_cache[result_cache_key] = TRUE
	return TRUE

/datum/world_edit_generator/outpost_radius/proc/is_outpost_candidate_reachable_from_seed(turf/candidate_turf, list/reachable_lookup)
	if(!istype(candidate_turf) || !islist(reachable_lookup))
		return FALSE
	if(reachable_lookup[candidate_turf])
		return TRUE

	for(var/check_dir in GLOB.cardinals)
		if(reachable_lookup[get_step(candidate_turf, check_dir)])
			return TRUE

	return FALSE

/datum/world_edit_generator/outpost_radius/proc/get_outpost_radius_policy_error(shape_id, suffix = "")
	var/target_label = get_outpost_placement_target_label(shape_id)
	var/prefix = ("[shape_id]" == WORLD_EDIT_SHAPE_POINT) ? "Выбранная" : "Выбранный"
	var/error_message = "[prefix] [target_label] не поддерживает обязательные проходы форпоста"
	if(length("[suffix]"))
		error_message += " [suffix]"
	return "[error_message]."

/datum/world_edit_generator/outpost_radius/proc/validate_outpost_footprint_radius_policy(list/footprint_turfs, turf/seed_turf, list/radius_policy, shape_id)
	var/list/policy = islist(radius_policy) ? radius_policy : GLOB.world_edit_helpers.get_world_edit_radius_policy(radius_policy)
	var/only_clear_tiles = !!policy["only_clear_tiles"]
	var/only_reachable_tiles = !!policy["only_reachable_tiles"]
	if(!only_clear_tiles && !only_reachable_tiles)
		return null
	if(!islist(footprint_turfs) || !length(footprint_turfs))
		return "Не удалось определить контур формы."

	var/list/footprint_lookup = build_turf_lookup(footprint_turfs)
	for(var/turf/footprint_turf as anything in footprint_turfs)
		if(!istype(footprint_turf))
			continue
		if(!outpost_footprint_tile_allowed(footprint_turf, policy))
			return get_outpost_radius_policy_error(shape_id, "при текущей политике блокировок радиуса")

	if(!only_reachable_tiles)
		return null

	if(!istype(seed_turf) || !footprint_lookup[seed_turf])
		return get_outpost_radius_policy_error(shape_id, "при текущей политике блокировок радиуса")

	var/list/visited_lookup = list()
	visited_lookup[seed_turf] = TRUE
	var/list/open_turfs = list(seed_turf)
	var/search_index = 1
	while(search_index <= length(open_turfs))
		var/turf/current_turf = open_turfs[search_index++]
		for(var/check_dir in GLOB.cardinals)
			var/turf/neighbor_turf = get_step(current_turf, check_dir)
			if(!footprint_lookup[neighbor_turf] || visited_lookup[neighbor_turf])
				continue
			if(!outpost_path_passable(neighbor_turf, policy["treat_windows_as_blockers"]))
				continue
			visited_lookup[neighbor_turf] = TRUE
			open_turfs += neighbor_turf

	for(var/turf/footprint_turf as anything in footprint_turfs)
		if(!visited_lookup[footprint_turf])
			return get_outpost_radius_policy_error(shape_id, "при текущей политике блокировок радиуса")

	return null

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
			WORLD_EDIT_SHAPE_CUSTOM_MASK,
			WORLD_EDIT_SHAPE_SCATTER_CLUSTER
		)
			return "limited"
	return "unsupported"

/datum/world_edit_generator/outpost_radius/proc/get_outpost_effective_shape_id(shape_id, datum/world_edit_shape_contract/shape_contract = null, list/placement_context = null, list/footprint_turfs = null)
	var/effective_shape_id = "[shape_id || shape_contract?.shape_id || placement_context["shape"] || WORLD_EDIT_SHAPE_POINT]"
	if(effective_shape_id == WORLD_EDIT_SHAPE_POINT)
		return WORLD_EDIT_SHAPE_POINT

	var/degenerate_kind = ""
	if(istype(shape_contract))
		degenerate_kind = "[shape_contract.degenerate_kind]"
		if(!length(degenerate_kind) && islist(shape_contract.metadata))
			degenerate_kind = "[shape_contract.metadata["degenerate_kind"]]"
	if(!length(degenerate_kind) && islist(placement_context))
		var/list/shape_metadata = placement_context["shape_metadata"]
		if(islist(shape_metadata))
			degenerate_kind = "[shape_metadata["degenerate_kind"]]"

	if(degenerate_kind == "point")
		return WORLD_EDIT_SHAPE_POINT
	if(islist(footprint_turfs) && length(footprint_turfs) <= 1)
		return WORLD_EDIT_SHAPE_POINT
	return effective_shape_id

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
			return "Генератор форпоста не поддерживает форму [shape_label]."
		if("risky")
			return "Форма [shape_label] пока не поддерживается; используйте связный контур или форму с опорой."

	if(support_class != "limited")
		return null

	var/component_count = count_shape_connected_components(footprint_turfs)
	if(component_count > 1)
		return "Форма [shape_label] распадается на несвязанные островки; для форпоста нужен один связный контур."
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

/datum/world_edit_generator/outpost_radius/proc/get_shape_chebyshev_distance_to_footprint(turf/target_turf, list/footprint_turfs, list/distance_cache = null)
	if(!istype(target_turf) || !islist(footprint_turfs) || !length(footprint_turfs))
		return null
	if(islist(distance_cache) && !isnull(distance_cache[target_turf]))
		return distance_cache[target_turf]

	var/best_distance = null
	for(var/turf/source_turf as anything in footprint_turfs)
		if(!istype(source_turf))
			continue

		var/current_distance = max(abs(target_turf.x - source_turf.x), abs(target_turf.y - source_turf.y))
		if(isnull(best_distance) || current_distance < best_distance)
			best_distance = current_distance
			if(best_distance <= 0)
				break

	if(islist(distance_cache) && !isnull(best_distance))
		distance_cache[target_turf] = best_distance
	return best_distance

/datum/world_edit_generator/outpost_radius/proc/build_shape_shell_turfs(list/footprint_turfs, radius, list/footprint_lookup, list/shape_bounds, list/distance_cache = null)
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

			if(get_shape_chebyshev_distance_to_footprint(target_turf, footprint_turfs, distance_cache) != radius)
				continue

			shell_lookup[target_turf] = TRUE
			shell_turfs += target_turf

	return result

/datum/world_edit_generator/outpost_radius/proc/build_shape_shell_slot_dirs(turf/target_turf, radius, list/footprint_turfs, list/shell_lookup, list/distance_cache = null)
	var/list/slot_dirs = list()
	if(!istype(target_turf) || !islist(shell_lookup))
		return slot_dirs

	for(var/dir_to_use as anything in GLOB.cardinals)
		var/turf/neighbor_turf = get_step(target_turf, dir_to_use)
		if(shell_lookup[neighbor_turf])
			continue

		var/neighbor_distance = get_shape_chebyshev_distance_to_footprint(neighbor_turf, footprint_turfs, distance_cache)
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

/datum/world_edit_generator/outpost_radius/proc/get_shape_slot_cross_axis(list/candidate_slot, list/shape_bounds)
	var/turf/source_turf = candidate_slot["turf"]
	if(!istype(source_turf))
		source_turf = candidate_slot["source_turf"]
	var/dir_to_use = candidate_slot["dir"]
	if(!istype(source_turf))
		return 0

	switch(dir_to_use)
		if(NORTH, SOUTH)
			return source_turf.x - shape_bounds["center_x"]
		if(EAST, WEST)
			return source_turf.y - shape_bounds["center_y"]
	return 0

/datum/world_edit_generator/outpost_radius/proc/select_best_shape_slots(list/candidate_slots, slots_to_select, list/shape_bounds, list/selected_lookup)
	var/list/selected_slots = list()
	if(!islist(candidate_slots) || !length(candidate_slots))
		return selected_slots

	for(var/i in 1 to max(round(text2num("[slots_to_select]") || 0), 0))
		var/list/best_slot = null
		var/best_score = null
		for(var/list/candidate_slot as anything in candidate_slots)
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

/datum/world_edit_generator/outpost_radius/proc/build_shape_perimeter_candidates(list/footprint_turfs, radius, list/footprint_lookup, list/shape_bounds, list/distance_cache = null)
	var/list/candidates = list()
	var/list/candidate_lookup = list()
	if(!islist(footprint_turfs) || !length(footprint_turfs))
		return candidates

	radius = max(round(radius), 1)
	var/list/shell_data = build_shape_shell_turfs(footprint_turfs, radius, footprint_lookup, shape_bounds, distance_cache)
	var/list/shell_turfs = shell_data["turfs"]
	var/list/shell_lookup = shell_data["lookup"]
	for(var/turf/target_turf as anything in shell_turfs)
		if(!istype(target_turf))
			continue

		var/list/slot_dirs = build_shape_shell_slot_dirs(target_turf, radius, footprint_turfs, shell_lookup, distance_cache)
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

/datum/world_edit_generator/outpost_radius/proc/select_shape_direction_slots(list/candidate_slots, list/target_dirs, slots_per_dir, list/shape_bounds, slot_mode = "centered")
	var/list/selected_slots = list()
	if(!islist(candidate_slots) || !length(candidate_slots))
		return selected_slots
	if(!islist(target_dirs) || !length(target_dirs))
		return selected_slots

	var/slots_to_select = max(round(text2num("[slots_per_dir]") || 0), 1)
	var/list/selected_lookup = list()
	for(var/dir_to_use as anything in target_dirs)
		var/list/dir_candidates = list()
		var/list/negative_candidates = list()
		var/list/positive_candidates = list()
		for(var/list/candidate_slot as anything in candidate_slots)
			if(candidate_slot["dir"] != dir_to_use)
				continue
			dir_candidates += list(candidate_slot)
			var/cross_axis = get_shape_slot_cross_axis(candidate_slot, shape_bounds)
			if(cross_axis < 0)
				negative_candidates += list(candidate_slot)
			else if(cross_axis > 0)
				positive_candidates += list(candidate_slot)

		if(slot_mode == "split_pair" && slots_to_select >= 2 && length(negative_candidates) && length(positive_candidates))
			var/dir_selected_before = length(selected_slots)
			var/negative_count = round(slots_to_select / 2)
			var/positive_count = slots_to_select - negative_count
			selected_slots += select_best_shape_slots(negative_candidates, negative_count, shape_bounds, selected_lookup)
			selected_slots += select_best_shape_slots(positive_candidates, positive_count, shape_bounds, selected_lookup)
			var/missing_count = slots_to_select - (length(selected_slots) - dir_selected_before)
			if(missing_count > 0)
				selected_slots += select_best_shape_slots(dir_candidates, missing_count, shape_bounds, selected_lookup)
			continue

		selected_slots += select_best_shape_slots(dir_candidates, slots_to_select, shape_bounds, selected_lookup)

	return selected_slots

/datum/world_edit_generator/outpost_radius/proc/build_shape_sentry_candidates(list/opening_slot, sentry_profile = "entry_guard")
	var/list/candidates = list()
	if(!islist(opening_slot))
		return candidates

	var/turf/source_turf = opening_slot["source_turf"]
	if(!istype(source_turf))
		source_turf = opening_slot["turf"]
	var/dir_to_guard = opening_slot["dir"]
	if(!istype(source_turf))
		return candidates

	var/inward_dir = get_cardinal_opposite_dir(dir_to_guard)
	var/turf/inward_turf = GLOB.world_edit_helpers.step_turf(source_turf, inward_dir, 1)
	var/turf/deep_turf = istype(inward_turf) ? GLOB.world_edit_helpers.step_turf(inward_turf, inward_dir, 1) : null

	switch("[sentry_profile]")
		if("inner_guard")
			if(istype(inward_turf))
				candidates += list(list(
					"turf" = inward_turf,
					"dir" = dir_to_guard,
					"opening_dir" = dir_to_guard,
				))
			if(istype(deep_turf))
				candidates += list(list(
					"turf" = deep_turf,
					"dir" = dir_to_guard,
					"opening_dir" = dir_to_guard,
				))
			candidates += list(list(
				"turf" = source_turf,
				"dir" = dir_to_guard,
				"opening_dir" = dir_to_guard,
			))
			return candidates
		if("crossfire")
			if(istype(inward_turf))
				candidates += list(list(
					"turf" = inward_turf,
					"dir" = dir_to_guard,
					"opening_dir" = dir_to_guard,
				))
			if(istype(deep_turf))
				candidates += list(list(
					"turf" = deep_turf,
					"dir" = dir_to_guard,
					"opening_dir" = dir_to_guard,
				))
			candidates += list(list(
				"turf" = source_turf,
				"dir" = dir_to_guard,
				"opening_dir" = dir_to_guard,
			))
			return candidates

	candidates += list(list(
		"turf" = source_turf,
		"dir" = dir_to_guard,
		"opening_dir" = dir_to_guard,
	))
	if(istype(inward_turf))
		candidates += list(list(
			"turf" = inward_turf,
			"dir" = dir_to_guard,
			"opening_dir" = dir_to_guard,
		))

	return candidates

/datum/world_edit_generator/outpost_radius/proc/build_outpost_shape_analysis(list/footprint_turfs, list/params, list/placement_context = null)
	var/list/analysis = list(
		"error" = null,
		"config" = null,
		"footprint_turfs" = list(),
		"footprint_lookup" = list(),
		"shape_bounds" = list(),
		"seed_turf" = null,
		"traversal_turfs" = list(),
		"candidate_slots" = list(),
		"filtered_candidate_slots" = list(),
		"opening_slots" = list(),
		"opening_slot_keys" = list(),
		"opening_lookup" = list(),
		"opening_slots_by_dir" = list(),
		"guard_dirs" = list(),
		"guard_slots" = list(),
		"guard_sentry_candidates" = list(),
		"raw_sentry_candidate_turfs" = list(),
		"allowed_sentry_lookup" = list(),
		"opening_dirs" = list(),
		"distance_cache" = list(),
		"approach_line_cache" = list(),
		"approach_result_cache" = list(),
	)
	if(!islist(footprint_turfs) || !length(footprint_turfs))
		analysis["error"] = "Не удалось определить контур формы."
		return analysis

	var/list/config = params
	if(!islist(config) || !config["family_profile"])
		config = resolve_outpost_configuration(params, placement_context)
	if(config["error"])
		analysis["error"] = "[config["error"]]"
		return analysis

	var/list/footprint_lookup = build_turf_lookup(footprint_turfs)
	if(!length(footprint_lookup))
		analysis["error"] = "Не удалось определить контур формы."
		return analysis

	var/list/unique_footprint_turfs = list()
	for(var/turf/footprint_turf as anything in footprint_lookup)
		if(istype(footprint_turf))
			unique_footprint_turfs += footprint_turf
	if(!length(unique_footprint_turfs))
		analysis["error"] = "Не удалось определить контур формы."
		return analysis

	var/list/shape_bounds = build_turf_bounds(unique_footprint_turfs)
	var/turf/seed_turf = resolve_outpost_shape_seed_turf(unique_footprint_turfs, placement_context)
	if(!istype(seed_turf))
		seed_turf = unique_footprint_turfs[1]
	var/list/distance_cache = list()
	var/list/approach_line_cache = list()
	var/list/approach_result_cache = list()
	var/list/traversal_turfs = build_shape_radius_area_turfs(unique_footprint_turfs, config["radius"], footprint_lookup, shape_bounds, distance_cache)
	var/list/candidate_slots = build_shape_perimeter_candidates(unique_footprint_turfs, config["radius"], footprint_lookup, shape_bounds, distance_cache)
	var/list/filtered_candidate_slots = filter_outpost_slots_by_radius_policy(list(seed_turf), candidate_slots, traversal_turfs, config["radius_policy"], unique_footprint_turfs, footprint_lookup, approach_line_cache, approach_result_cache)
	var/list/family_profile = islist(config["family_profile"]) ? config["family_profile"] : list()
	var/list/layout_profile = islist(config["layout_profile"]) ? config["layout_profile"] : list(
		"opening_dirs" = islist(family_profile["opening_dirs"]) ? family_profile["opening_dirs"].Copy() : list(NORTH, EAST, SOUTH, WEST),
		"guard_dirs" = islist(family_profile["opening_dirs"]) ? family_profile["opening_dirs"].Copy() : list(NORTH, EAST, SOUTH, WEST),
		"opening_width" = max(text2num("[config["opening_width"]]"), 1),
		"opening_slots_per_dir" = 1,
		"opening_slot_mode" = "centered",
	)
	config["layout_profile"] = layout_profile
	var/list/opening_dirs = get_layout_opening_dirs(layout_profile)
	var/opening_tiles_per_dir = get_layout_total_opening_tiles_per_dir(layout_profile)
	var/list/opening_slots = length(opening_dirs) ? select_shape_direction_slots(filtered_candidate_slots, opening_dirs, opening_tiles_per_dir, shape_bounds, get_layout_opening_slot_mode(layout_profile)) : list()
	var/list/opening_slot_keys = list()
	var/list/opening_lookup = list()
	var/list/opening_slots_by_dir = list()
	for(var/list/opening_slot as anything in opening_slots)
		var/opening_slot_key = GLOB.world_edit_helpers.build_turf_dir_slot_key(opening_slot["turf"], opening_slot["dir"])
		if(!length(opening_slot_key) || opening_lookup[opening_slot_key])
			continue
		opening_lookup[opening_slot_key] = TRUE
		opening_slot_keys += opening_slot_key
		var/opening_dir = opening_slot["dir"]
		if(GLOB.world_edit_helpers.is_cardinal_dir(opening_dir))
			opening_slots_by_dir["[opening_dir]"] = (opening_slots_by_dir["[opening_dir]"] || 0) + 1

	var/list/guard_dirs = build_sentry_profile_guard_dirs(get_layout_guard_dirs(layout_profile), config["sentry_profile"])
	var/list/guard_slots = list()
	var/list/guard_sentry_candidates = list()
	var/list/raw_sentry_candidate_turfs = list()
	var/list/allowed_sentry_lookup = list()
	if(config["place_sentries"])
		guard_slots = select_shape_direction_slots(filtered_candidate_slots, guard_dirs, 1, shape_bounds)
		var/list/raw_sentry_candidate_lookup = list()
		for(var/list/guard_slot as anything in guard_slots)
			var/list/sentry_candidates = build_shape_sentry_candidates(guard_slot, config["sentry_profile"])
			guard_sentry_candidates += list(sentry_candidates)
			for(var/list/sentry_candidate as anything in sentry_candidates)
				var/turf/sentry_turf = sentry_candidate["turf"]
				if(!istype(sentry_turf) || raw_sentry_candidate_lookup[sentry_turf])
					continue
				raw_sentry_candidate_lookup[sentry_turf] = TRUE
				raw_sentry_candidate_turfs += sentry_turf
		allowed_sentry_lookup = build_turf_lookup(filter_outpost_candidate_turfs(list(seed_turf), raw_sentry_candidate_turfs, traversal_turfs, config["radius_policy"], unique_footprint_turfs, footprint_lookup, approach_line_cache, approach_result_cache))

	analysis["config"] = config
	analysis["footprint_turfs"] = unique_footprint_turfs
	analysis["footprint_lookup"] = footprint_lookup
	analysis["shape_bounds"] = shape_bounds
	analysis["seed_turf"] = seed_turf
	analysis["traversal_turfs"] = traversal_turfs
	analysis["candidate_slots"] = candidate_slots
	analysis["filtered_candidate_slots"] = filtered_candidate_slots
	analysis["opening_slots"] = opening_slots
	analysis["opening_slot_keys"] = opening_slot_keys
	analysis["opening_lookup"] = opening_lookup
	analysis["opening_slots_by_dir"] = opening_slots_by_dir
	analysis["guard_dirs"] = guard_dirs
	analysis["guard_slots"] = guard_slots
	analysis["guard_sentry_candidates"] = guard_sentry_candidates
	analysis["raw_sentry_candidate_turfs"] = raw_sentry_candidate_turfs
	analysis["allowed_sentry_lookup"] = allowed_sentry_lookup
	analysis["opening_dirs"] = opening_dirs
	analysis["distance_cache"] = distance_cache
	analysis["approach_line_cache"] = approach_line_cache
	analysis["approach_result_cache"] = approach_result_cache
	return analysis

/datum/world_edit_generator/outpost_radius/proc/build_shape_aware_perimeter_plan(list/footprint_turfs, list/params, list/placement_context = null, list/shape_analysis = null)
	var/datum/world_edit_plan/plan = new
	shape_analysis = islist(shape_analysis) ? shape_analysis : build_outpost_shape_analysis(footprint_turfs, params, placement_context)
	if(!islist(shape_analysis))
		plan.metadata["error"] = "Не удалось определить контур формы."
		return plan
	if(shape_analysis["error"])
		plan.metadata["error"] = "[shape_analysis["error"]]"
		return plan

	var/list/config = shape_analysis["config"]
	footprint_turfs = shape_analysis["footprint_turfs"]
	var/list/shape_bounds = shape_analysis["shape_bounds"]
	var/list/family_profile = islist(config["family_profile"]) ? config["family_profile"] : list()
	var/radius = config["radius"]
	var/list/radius_policy = islist(config["radius_policy"]) ? config["radius_policy"] : GLOB.world_edit_helpers.get_world_edit_radius_policy(config)
	var/place_sentries = config["place_sentries"]
	var/turf/seed_turf = shape_analysis["seed_turf"]
	var/list/candidate_slots = shape_analysis["filtered_candidate_slots"]
	if(!length(candidate_slots))
		plan.metadata["error"] = "Выбранный контур размещения не позволяет построить оболочку периметра при текущей политике блокировок радиуса."
		return plan
	var/list/layout_profile = islist(config["layout_profile"]) ? config["layout_profile"] : list(
		"label" = config["layout_variant"] || "shape_layout",
		"description" = "",
		"opening_dirs" = islist(shape_analysis["opening_dirs"]) ? shape_analysis["opening_dirs"].Copy() : list(),
		"guard_dirs" = islist(shape_analysis["guard_dirs"]) ? shape_analysis["guard_dirs"].Copy() : list(),
		"opening_width" = max(text2num("[config["opening_width"]]"), 1),
		"opening_slots_per_dir" = 1,
		"opening_slot_mode" = "centered",
	)
	var/list/opening_dirs = shape_analysis["opening_dirs"]
	var/list/guard_dirs = shape_analysis["guard_dirs"]
	var/list/opening_slots = shape_analysis["opening_slots"]
	var/list/guard_slots = shape_analysis["guard_slots"]
	var/list/guard_sentry_candidates = shape_analysis["guard_sentry_candidates"]
	var/list/allowed_sentry_lookup = shape_analysis["allowed_sentry_lookup"]
	var/list/opening_lookup = shape_analysis["opening_lookup"]
	var/list/opening_slot_keys = shape_analysis["opening_slot_keys"]

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
		preview_turf_lookup[target_turf] = TRUE
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

	var/list/opening_seen_lookup = opening_lookup.Copy()
	var/opening_index = 1
	for(var/list/opening_slot as anything in opening_slots)
		var/turf/open_turf = opening_slot["turf"]
		var/opening_slot_key = opening_slot_keys[opening_index++]
		if(!length(opening_slot_key) || opening_seen_lookup[opening_slot_key] != TRUE)
			continue
		opening_seen_lookup[opening_slot_key] = FALSE
		if(!istype(open_turf))
			total_blocked_openings++
			continue
		preview_turf_lookup[open_turf] = TRUE
		if(!can_place_barricade_on_turf(open_turf, opening_slot["dir"]))
			total_blocked_openings++
			continue

		total_openings++
		preview_turf_lookup[open_turf] = TRUE

	if(place_sentries)
		var/guard_index = 1
		for(var/list/guard_slot as anything in guard_slots)
			var/list/sentry_candidates = guard_sentry_candidates[guard_index++]
			var/placed_sentry = FALSE
			var/turf/preview_sentry_turf = null
			for(var/list/sentry_candidate as anything in sentry_candidates)
				var/turf/sentry_turf = sentry_candidate["turf"]
				if(!istype(sentry_turf) || !allowed_sentry_lookup[sentry_turf] || sentry_lookup[sentry_turf])
					continue
				if(!istype(preview_sentry_turf))
					preview_sentry_turf = sentry_turf
				if(preview_turf_lookup[sentry_turf])
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

			if(istype(preview_sentry_turf))
				preview_turf_lookup[preview_sentry_turf] = TRUE
			if(!placed_sentry)
				total_blocked_sentries++

		if(length(guard_dirs) > length(guard_slots))
			total_blocked_sentries += length(guard_dirs) - length(guard_slots)

	var/expected_openings = get_layout_expected_opening_count(layout_profile)
	if(expected_openings > total_openings)
		total_blocked_openings += expected_openings - total_openings
	if(length(plan.placements) > WORLD_EDIT_PLACEMENT_MAX_TOTAL_PLACEMENTS)
		plan.metadata["error"] = "Запрошенное размещение форпоста превышает безопасный лимит ([WORLD_EDIT_PLACEMENT_MAX_TOTAL_PLACEMENTS])."
		return plan

	for(var/turf/preview_turf as anything in preview_turf_lookup)
		plan.affected_turfs += preview_turf

	var/turf/center_turf = locate(round((shape_bounds["min_x"] + shape_bounds["max_x"]) / 2), round((shape_bounds["min_y"] + shape_bounds["max_y"]) / 2), shape_bounds["z"])
	if(!istype(center_turf))
		center_turf = footprint_turfs[clamp(round((length(footprint_turfs) + 1) / 2), 1, length(footprint_turfs))]

	plan.metadata["center_turf"] = center_turf
	plan.metadata["radius"] = radius
	plan.metadata["radius_only_clear_tiles"] = radius_policy["only_clear_tiles"]
	plan.metadata["radius_only_reachable_tiles"] = radius_policy["only_reachable_tiles"]
	plan.metadata["radius_windows_blockers"] = radius_policy["treat_windows_as_blockers"]
	plan.metadata["shape_mode"] = "footprint_offset"
	plan.metadata["seed_turf"] = seed_turf
	plan.metadata["shape_footprint_count"] = length(footprint_turfs)
	plan.metadata["base_shape_turfs"] = footprint_turfs.Copy()
	plan.metadata["anchor_count"] = length(footprint_turfs)
	plan.metadata["family"] = config["family"]
	plan.metadata["family_label"] = family_profile["label"]
	plan.metadata["family_description"] = family_profile["description"]
	plan.metadata["layout_variant"] = config["layout_variant"]
	plan.metadata["layout_label"] = layout_profile["label"]
	plan.metadata["layout_description"] = layout_profile["description"]
	plan.metadata["opening_width"] = config["opening_width"]
	plan.metadata["guard_mode"] = config["guard_mode"]
	plan.metadata["sentry_profile"] = config["sentry_profile"]
	plan.metadata["barricade_pattern"] = config["barricade_pattern"]
	plan.metadata["barricade_count"] = length(plan.placements) - total_sentries
	plan.metadata["sentry_count"] = total_sentries
	plan.metadata["opening_count"] = total_openings
	plan.metadata["opening_dirs"] = format_opening_dirs(opening_dirs)
	plan.metadata["blocked_barricades"] = total_blocked_barricades
	plan.metadata["blocked_openings"] = total_blocked_openings
	plan.metadata["blocked_perimeter"] = total_blocked_barricades + total_blocked_openings
	plan.metadata["blocked_sentries"] = total_blocked_sentries
	plan.metadata["generator_effect_turfs"] = plan.affected_turfs.Copy()
	return plan

/datum/world_edit_generator/outpost_radius/proc/resolve_outpost_configuration(list/params, list/placement_context = null)
	var/list/config = list()
	var/family_id = resolve_outpost_family_id(params["family"])
	if(!family_id)
		config["error"] = "Выбран недопустимый профиль форпоста."
		return config

	var/list/family_profile = get_outpost_family_profile(family_id)
	if(!islist(family_profile))
		config["error"] = "Выбран недопустимый профиль форпоста."
		return config

	var/layout_id = resolve_outpost_layout_id(params["layout_variant"])
	if(!layout_id)
		config["error"] = "Выбран недопустимый вариант схемы форпоста."
		return config

	var/list/layout_profile = get_outpost_layout_profile(layout_id)
	if(!islist(layout_profile))
		config["error"] = "Выбран недопустимый вариант схемы форпоста."
		return config

	var/opening_width = resolve_opening_width(params["opening_width"], layout_profile)
	if(isnull(opening_width))
		config["error"] = "Выбрана недопустимая ширина проходов."
		return config

	var/guard_mode = resolve_guard_mode(params["guard_mode"])
	if(isnull(guard_mode))
		config["error"] = "Выбран недопустимый режим охвата турелей."
		return config

	var/sentry_profile = resolve_sentry_profile(params["sentry_profile"], family_profile)
	if(isnull(sentry_profile))
		config["error"] = "Выбран недопустимый стиль турелей."
		return config

	var/barricade_pattern = resolve_barricade_pattern(params["barricade_pattern"], family_profile)
	if(isnull(barricade_pattern))
		config["error"] = "Выбрана недопустимая схема баррикад."
		return config

	var/placement_dir = get_outpost_effective_placement_dir(placement_context)
	var/list/effective_layout_profile = layout_profile.Copy()
	effective_layout_profile["opening_dirs"] = get_layout_opening_dirs(layout_profile, placement_dir)
	effective_layout_profile["opening_width"] = opening_width
	effective_layout_profile["guard_dirs"] = get_guard_dirs_for_mode(guard_mode, layout_profile, placement_dir)
	effective_layout_profile["opening_slot_mode"] = get_layout_opening_slot_mode(layout_profile)
	effective_layout_profile["opening_slots_per_dir"] = get_layout_opening_slots_per_dir(layout_profile)

	var/radius = text2num("[params["radius"]]") || 4
	if(!isnum(radius) || radius < 1 || radius > WORLD_EDIT_OUTPOST_RADIUS_MAX)
		config["error"] = "Радиус должен быть в диапазоне 1..[WORLD_EDIT_OUTPOST_RADIUS_MAX]."
		return config
	opening_width = clamp(round(opening_width), 1, (radius * 2) + 1)
	effective_layout_profile["opening_width"] = opening_width

	var/place_sentries = GLOB.world_edit_helpers.parse_bool(params["place_sentries"])
	var/list/radius_policy = GLOB.world_edit_helpers.get_world_edit_radius_policy(params)
	var/barricade_path = resolve_whitelisted_type(params["barricade_path"], allowed_barricade_types, /datum/human_ai_defense/barricade, family_profile["default_barricade_path"])
	if(!barricade_path)
		config["error"] = "Выбран недопустимый тип баррикады."
		return config

	var/sentry_path = null
	if(place_sentries)
		sentry_path = resolve_whitelisted_type(params["sentry_path"], allowed_sentry_types, /datum/human_ai_defense/defense/sentry, family_profile["default_sentry_path"])
		if(!sentry_path)
			config["error"] = "Выбран недопустимый тип турели."
			return config

	var/faction = "[params["faction"]]"
	var/turned_on = GLOB.world_edit_helpers.parse_bool(params["turned_on"])

	config["family"] = family_id
	config["family_profile"] = family_profile
	config["layout_variant"] = layout_id
	config["layout_profile"] = effective_layout_profile
	config["placement_dir"] = placement_dir
	config["opening_width"] = opening_width
	config["guard_mode"] = guard_mode
	config["sentry_profile"] = sentry_profile
	config["radius"] = radius
	config["radius_policy"] = radius_policy
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
	var/effective_shape_id = shape_id
	var/support_class = get_outpost_shape_support_class(effective_shape_id)
	var/list/support_metadata = list(
		"shape_support_class" = support_class,
		"shape_requested_id" = shape_id,
		"shape_effective_id" = effective_shape_id,
	)
	if(!islist(anchor_turfs) || !length(anchor_turfs))
		return list(
			"support_class" = support_class,
			"error" = "Не удалось определить контур формы.",
			"metadata" = support_metadata.Copy(),
		)

	var/list/config = resolve_outpost_configuration(params, placement_context)
	if(config["error"])
		return list(
			"support_class" = support_class,
			"error" = "[config["error"]]",
			"metadata" = support_metadata.Copy(),
		)

	var/list/footprint_lookup = build_turf_lookup(anchor_turfs)
	if(!length(footprint_lookup))
		return list(
			"support_class" = support_class,
			"error" = "Не удалось определить контур формы.",
			"metadata" = support_metadata.Copy(),
		)

	var/list/footprint_turfs = list()
	for(var/turf/footprint_turf as anything in footprint_lookup)
		if(istype(footprint_turf))
			footprint_turfs += footprint_turf
	if(!length(footprint_turfs))
		return list(
			"support_class" = support_class,
			"error" = "Не удалось определить контур формы.",
			"metadata" = support_metadata.Copy(),
		)

	effective_shape_id = get_outpost_effective_shape_id(shape_id, shape_contract, placement_context, footprint_turfs)
	support_class = get_outpost_shape_support_class(effective_shape_id)
	support_metadata["shape_support_class"] = support_class
	support_metadata["shape_effective_id"] = effective_shape_id

	var/turf/seed_turf = resolve_outpost_shape_seed_turf(footprint_turfs, placement_context)
	if(!istype(seed_turf))
		seed_turf = footprint_turfs[1]
	if(effective_shape_id == WORLD_EDIT_SHAPE_POINT)
		var/datum/world_edit_plan/point_plan = build_outpost_plan(seed_turf, config)
		if(point_plan.metadata["error"])
			return list(
				"support_class" = support_class,
				"error" = "[point_plan.metadata["error"]]",
				"metadata" = support_metadata.Copy(),
			)
		if(!length(point_plan.placements) && !length(point_plan.deletions))
			return list(
				"support_class" = support_class,
				"error" = "Не удалось построить ни одного допустимого размещения форпоста для выбранной точки размещения.",
				"metadata" = support_metadata.Copy(),
			)
		return list(
			"support_class" = support_class,
			"error" = null,
			"plan" = point_plan,
			"metadata" = support_metadata.Copy(),
		)

	var/support_validation_error = get_outpost_shape_support_validation_error(effective_shape_id, footprint_turfs, placement_context)
	if(length("[support_validation_error]"))
		return list(
			"support_class" = support_class,
			"error" = support_validation_error,
			"metadata" = support_metadata.Copy(),
		)

	var/list/shape_analysis = build_outpost_shape_analysis(footprint_turfs, config, placement_context)
	if(shape_analysis["error"])
		return list(
			"support_class" = support_class,
			"error" = "[shape_analysis["error"]]",
			"metadata" = support_metadata.Copy(),
		)

	var/list/candidate_slots = shape_analysis["filtered_candidate_slots"]
	if(!length(candidate_slots))
		return list(
			"support_class" = support_class,
			"error" = get_outpost_radius_policy_error(effective_shape_id),
			"metadata" = support_metadata.Copy(),
		)

	var/list/opening_dirs = shape_analysis["opening_dirs"]
	if(length(opening_dirs))
		var/list/opening_slots_by_dir = shape_analysis["opening_slots_by_dir"]
		var/required_opening_tiles_per_dir = get_layout_total_opening_tiles_per_dir(config["layout_profile"])
		for(var/opening_dir as anything in opening_dirs)
			if((opening_slots_by_dir["[opening_dir]"] || 0) < required_opening_tiles_per_dir)
				return list(
					"support_class" = support_class,
					"error" = get_outpost_radius_policy_error(effective_shape_id),
					"metadata" = support_metadata.Copy(),
				)

	var/datum/world_edit_plan/shape_plan = build_shape_aware_perimeter_plan(footprint_turfs, config, placement_context, shape_analysis)
	if(shape_plan.metadata["error"])
		return list(
			"support_class" = support_class,
			"error" = "[shape_plan.metadata["error"]]",
			"metadata" = support_metadata.Copy(),
		)
	if(!length(shape_plan.placements) && !length(shape_plan.deletions))
		return list(
			"support_class" = support_class,
			"error" = "Не удалось построить ни одного допустимого размещения форпоста для выбранного контура размещения.",
			"metadata" = support_metadata.Copy(),
		)
	return list(
		"support_class" = support_class,
		"error" = null,
		"plan" = shape_plan,
		"metadata" = support_metadata.Copy(),
	)

/datum/world_edit_generator/outpost_radius/get_shape_support_error(shape_id, list/anchor_turfs, list/params, list/placement_context)
	var/datum/world_edit_shape_contract/shape_contract = build_shape_contract_from_placement_context(shape_id, anchor_turfs, placement_context)
	var/list/support_result = evaluate_shape_contract(shape_contract, params, placement_context)
	return support_result["error"]
