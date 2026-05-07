/datum/world_edit_generator/building_layout/proc/world_edit_building_front_depth(turf/target_turf, list/bounds, direction)
	if(!istype(target_turf) || !islist(bounds))
		return 0
	switch(direction)
		if(NORTH)
			return text2num("[bounds["max_y"]]") - target_turf.y
		if(SOUTH)
			return target_turf.y - text2num("[bounds["min_y"]]")
		if(EAST)
			return text2num("[bounds["max_x"]]") - target_turf.x
		if(WEST)
			return target_turf.x - text2num("[bounds["min_x"]]")
	return 0

/datum/world_edit_generator/building_layout/proc/world_edit_building_lateral_offset(turf/target_turf, list/bounds, direction)
	if(!istype(target_turf) || !islist(bounds))
		return 0
	var/center_x = (text2num("[bounds["min_x"]]") + text2num("[bounds["max_x"]]")) / 2
	var/center_y = (text2num("[bounds["min_y"]]") + text2num("[bounds["max_y"]]")) / 2
	if(direction in list(NORTH, SOUTH))
		return target_turf.x - center_x
	return target_turf.y - center_y

/datum/world_edit_generator/building_layout/proc/build_building_layout_state(datum/world_edit_building_request/request, datum/world_edit_shape_contract/shape_contract, list/placement_context, list/validated)
	var/datum/world_edit_building_layout_state/state = new
	state.request = request
	state.config = request.config
	state.archetype = request.archetype
	state.footprint = validated["footprint"]
	state.boundary = validated["boundary"]
	state.interior = validated["interior"]
	state.footprint_lookup = validated["footprint_lookup"]
	state.bounds = validated["bounds"]
	state.boundary_lookup = GLOB.world_edit_placement_shapes.world_edit_build_turf_lookup(state.boundary)
	state.placement_dir = text2num("[placement_context["direction"]]")
	if(!(state.placement_dir in GLOB.cardinals))
		state.placement_dir = manager?.get_effective_placement_dir() || NORTH

	if(length(state.footprint) > WORLD_EDIT_BUILDING_MAX_FOOTPRINT_TURFS)
		state.add_error("Building footprint exceeds cap ([WORLD_EDIT_BUILDING_MAX_FOOTPRINT_TURFS]).")
		return state

	state.request.config["validated_footprint_count"] = length(state.footprint)
	state.semantic_plan = state.archetype.build_semantic_plan(state.request)
	if(!istype(state.semantic_plan))
		state.add_error("Unable to build semantic plan for [state.archetype.id].")
		return state

	build_building_doors(state)
	if(state.has_errors())
		return state
	solve_building_semantic_regions(state)
	build_building_preliminary_circulation(state)
	build_building_zone_dividers(state)
	build_building_nested_rooms(state)
	build_building_windows(state)
	build_building_walls_and_floors(state)
	build_building_reserved_lanes(state)
	return state

/datum/world_edit_generator/building_layout/proc/build_building_doors(datum/world_edit_building_layout_state/state)
	var/center_x = (state.bounds["min_x"] + state.bounds["max_x"]) / 2
	var/center_y = (state.bounds["min_y"] + state.bounds["max_y"]) / 2
	var/list/door_policy = islist(state.semantic_plan?.door_policy) ? state.semantic_plan.door_policy : list()
	if(("front" in door_policy) && !GLOB.world_edit_helpers.parse_bool(door_policy["front"]))
		state.add_error("Door policy for [state.archetype.id] does not allow a front entry.")
		return
	var/turf/front_door_turf = select_boundary_turf_for_dir(state.boundary, center_x, center_y, state.placement_dir, null, state.footprint_lookup)
	if(!istype(front_door_turf))
		state.add_error("Unable to select a building entry door turf.")
		return
	state.front_door_turf = front_door_turf
	state.append_unique_turf(state.door_turfs, front_door_turf)
	state.door_dirs[front_door_turf] = get_outward_dir(front_door_turf, state.footprint_lookup, center_x, center_y, state.placement_dir)

	var/max_exterior_doors = max(round(text2num("[door_policy["max_exterior_doors"]]") || 2), 1)
	var/allow_back_exit = isnull(door_policy["allow_back_exit"]) ? TRUE : GLOB.world_edit_helpers.parse_bool(door_policy["allow_back_exit"])
	if(state.config["back_exit"] && allow_back_exit && max_exterior_doors >= 2)
		var/list/front_lookup = list()
		front_lookup[front_door_turf] = TRUE
		var/turf/back_door_turf = select_boundary_turf_for_dir(state.boundary, center_x, center_y, turn(state.placement_dir, 180), front_lookup, state.footprint_lookup)
		if(istype(back_door_turf))
			state.append_unique_turf(state.door_turfs, back_door_turf)
			state.door_dirs[back_door_turf] = get_outward_dir(back_door_turf, state.footprint_lookup, center_x, center_y, turn(state.placement_dir, 180))

/datum/world_edit_generator/building_layout/proc/prepare_building_local_metrics(datum/world_edit_building_layout_state/state)
	state.max_front_depth = 1
	state.max_lateral_abs = 1
	for(var/turf/interior_turf as anything in state.interior)
		var/depth = world_edit_building_front_depth(interior_turf, state.bounds, state.placement_dir)
		var/lateral = world_edit_building_lateral_offset(interior_turf, state.bounds, state.placement_dir)
		state.max_front_depth = max(state.max_front_depth, depth)
		state.max_lateral_abs = max(state.max_lateral_abs, abs(lateral))

/datum/world_edit_generator/building_layout/proc/get_building_front_percent(datum/world_edit_building_layout_state/state, turf/target_turf)
	if(!istype(state) || !istype(target_turf))
		return 0
	return round((world_edit_building_front_depth(target_turf, state.bounds, state.placement_dir) * 100) / max(state.max_front_depth, 1))

/datum/world_edit_generator/building_layout/proc/get_building_lateral_percent(datum/world_edit_building_layout_state/state, turf/target_turf)
	if(!istype(state) || !istype(target_turf))
		return 0
	return round((world_edit_building_lateral_offset(target_turf, state.bounds, state.placement_dir) * 100) / max(state.max_lateral_abs, 1))

/datum/world_edit_generator/building_layout/proc/region_spec_contains_turf(datum/world_edit_building_layout_state/state, datum/world_edit_building_region_spec/region_spec, turf/target_turf)
	if(!istype(state) || !istype(region_spec) || !istype(target_turf))
		return FALSE
	var/front_percent = get_building_front_percent(state, target_turf)
	var/lateral_percent = get_building_lateral_percent(state, target_turf)
	return front_percent >= region_spec.front_min && front_percent <= region_spec.front_max && lateral_percent >= region_spec.lateral_min && lateral_percent <= region_spec.lateral_max

/datum/world_edit_generator/building_layout/proc/build_region_source_lookup(list/source_turfs)
	var/list/source_lookup = list()
	if(!islist(source_turfs))
		return source_lookup
	for(var/turf/source_turf as anything in source_turfs)
		if(istype(source_turf))
			source_lookup["[source_turf.x],[source_turf.y]"] = source_turf
	return source_lookup

/datum/world_edit_generator/building_layout/proc/rect_region_candidate_from_bounds(datum/world_edit_building_layout_state/state, datum/world_edit_building_region_spec/region_spec, list/source_lookup, x1, y1, x2, y2, candidate_id, priority_bonus = 0)
	if(!istype(state) || !istype(region_spec) || !islist(source_lookup))
		return null
	var/datum/world_edit_building_solved_region/candidate = new(candidate_id, region_spec.zone_id, region_spec.priority + priority_bonus)
	for(var/x in x1 to x2)
		for(var/y in y1 to y2)
			var/turf/candidate_turf = source_lookup["[x],[y]"]
			if(!istype(candidate_turf))
				return null
			candidate.turfs += candidate_turf
			extend_solved_region_bounds(candidate, candidate_turf)
	return candidate

/datum/world_edit_generator/building_layout/proc/score_rectangular_region_candidate(datum/world_edit_building_layout_state/state, datum/world_edit_building_zone_spec/zone_spec, datum/world_edit_building_solved_region/candidate)
	if(!istype(state) || !istype(zone_spec) || !istype(candidate))
		return -999999999
	var/area = length(candidate.turfs)
	if(area < max(zone_spec.min_area, 1))
		return -999999999
	var/width = isnull(candidate.x1) || isnull(candidate.x2) ? 1 : (candidate.x2 - candidate.x1) + 1
	var/height = isnull(candidate.y1) || isnull(candidate.y2) ? 1 : (candidate.y2 - candidate.y1) + 1
	var/score = candidate.priority * 12
	score += min(area, max(zone_spec.min_area * 3, zone_spec.min_area + 4)) * 18
	score -= abs(width - height) * (zone_spec.divider_mode == "room" ? 8 : 3)
	if(region_candidate_has_wall_affinity(state, candidate.turfs))
		switch(zone_spec.role)
			if("storage", "service", "secure", "private", "nested", "support")
				score += 220
			else
				score += 40
	if(region_candidate_touches_entry(state, candidate.turfs))
		switch(zone_spec.role)
			if("entry", "public", "public_med", "choke")
				score += 240
			if("secure", "private", "nested")
				score -= 240
	if(zone_spec.role in list("route", "choke"))
		score += max(width, height) * 30
	if(zone_spec.divider_mode in list("room", "nook"))
		score += min(width, height) * 55
	return score

/datum/world_edit_generator/building_layout/proc/add_rectangular_region_candidate_limited(datum/world_edit_building_layout_state/state, list/candidates, datum/world_edit_building_zone_spec/zone_spec, datum/world_edit_building_solved_region/candidate)
	if(!islist(candidates) || !istype(candidate) || !istype(zone_spec))
		return
	var/score = score_rectangular_region_candidate(state, zone_spec, candidate)
	if(score <= -999999000)
		return
	candidate.priority += round(score / 20)
	if(length(candidates) < WORLD_EDIT_BUILDING_MAX_REGION_CANDIDATES_PER_SPEC)
		candidates += candidate
		return
	var/datum/world_edit_building_solved_region/worst_candidate = null
	var/worst_score = 999999999
	for(var/datum/world_edit_building_solved_region/existing_candidate as anything in candidates)
		var/existing_score = score_rectangular_region_candidate(state, zone_spec, existing_candidate)
		if(!istype(worst_candidate) || existing_score < worst_score)
			worst_candidate = existing_candidate
			worst_score = existing_score
	if(istype(worst_candidate) && score > worst_score)
		candidates -= worst_candidate
		candidates += candidate

/datum/world_edit_generator/building_layout/proc/get_rectangular_region_dimension_pairs(datum/world_edit_building_zone_spec/zone_spec, max_width, max_height)
	var/list/pairs = list()
	max_width = max(round(max_width), 1)
	max_height = max(round(max_height), 1)
	var/min_area = max(zone_spec?.min_area || 1, 1)
	var/base_side = max(2, round(sqrt(min_area + 3)))
	var/compact_w = min(max_width, max(base_side, 2))
	var/compact_h = min(max_height, max(base_side, 2))
	pairs += list(list("w" = compact_w, "h" = compact_h))
	pairs += list(list("w" = min(max_width, compact_w + 1), "h" = compact_h))
	pairs += list(list("w" = compact_w, "h" = min(max_height, compact_h + 1)))
	if(zone_spec?.role in list("route", "choke"))
		pairs += list(list("w" = min(max_width, 3), "h" = max_height))
		pairs += list(list("w" = max_width, "h" = min(max_height, 3)))
	else if(zone_spec?.role in list("storage", "service", "secure", "private", "nested", "support"))
		pairs += list(list("w" = min(max_width, max(3, round(max_width / 2))), "h" = min(max_height, 3)))
		pairs += list(list("w" = min(max_width, 3), "h" = min(max_height, max(3, round(max_height / 2)))))
	else
		pairs += list(list("w" = min(max_width, max(3, round(max_width * 2 / 3))), "h" = min(max_height, max(3, round(max_height * 2 / 3)))))
	return pairs

/datum/world_edit_generator/building_layout/proc/build_rectangular_region_candidates_for_spec(datum/world_edit_building_layout_state/state, datum/world_edit_building_region_spec/region_spec)
	var/list/candidates = list()
	if(!istype(state) || !istype(region_spec))
		return candidates
	var/datum/world_edit_building_zone_spec/zone_spec = state.semantic_plan?.get_zone_spec(region_spec.zone_id)
	if(!istype(zone_spec))
		return candidates
	var/list/source_turfs = list()
	for(var/turf/interior_turf as anything in state.interior)
		if(region_spec_contains_turf(state, region_spec, interior_turf))
			source_turfs += interior_turf
	if(!length(source_turfs))
		return candidates
	var/list/source_lookup = build_region_source_lookup(source_turfs)
	var/min_x = null
	var/max_x = null
	var/min_y = null
	var/max_y = null
	for(var/turf/source_turf as anything in source_turfs)
		if(isnull(min_x) || source_turf.x < min_x)
			min_x = source_turf.x
		if(isnull(max_x) || source_turf.x > max_x)
			max_x = source_turf.x
		if(isnull(min_y) || source_turf.y < min_y)
			min_y = source_turf.y
		if(isnull(max_y) || source_turf.y > max_y)
			max_y = source_turf.y
	if(isnull(min_x) || isnull(min_y))
		return candidates
	var/list/dimension_pairs = get_rectangular_region_dimension_pairs(zone_spec, max_x - min_x + 1, max_y - min_y + 1)
	var/candidate_index = 1
	for(var/turf/center_turf as anything in source_turfs)
		if(!istype(center_turf))
			continue
		for(var/list/dims as anything in dimension_pairs)
			var/rect_w = max(round(text2num("[dims["w"]]") || 1), 1)
			var/rect_h = max(round(text2num("[dims["h"]]") || 1), 1)
			var/x1 = clamp(center_turf.x - round((rect_w - 1) / 2), min_x, max_x - rect_w + 1)
			var/y1 = clamp(center_turf.y - round((rect_h - 1) / 2), min_y, max_y - rect_h + 1)
			var/x2 = x1 + rect_w - 1
			var/y2 = y1 + rect_h - 1
			var/datum/world_edit_building_solved_region/candidate = rect_region_candidate_from_bounds(state, region_spec, source_lookup, x1, y1, x2, y2, "[region_spec.id]_rect_[candidate_index++]")
			add_rectangular_region_candidate_limited(state, candidates, zone_spec, candidate)
	var/datum/world_edit_building_solved_region/fallback_candidate = new("[region_spec.id]_strip_fallback", region_spec.zone_id, region_spec.priority - 120)
	for(var/turf/source_turf as anything in source_turfs)
		fallback_candidate.turfs += source_turf
		extend_solved_region_bounds(fallback_candidate, source_turf)
	add_rectangular_region_candidate_limited(state, candidates, zone_spec, fallback_candidate)
	return candidates

/datum/world_edit_generator/building_layout/proc/build_building_room_region_candidates(datum/world_edit_building_layout_state/state)
	var/list/candidates = list()
	if(!istype(state) || !istype(state.semantic_plan))
		return candidates
	state.rectangular_region_candidate_count = 0
	for(var/datum/world_edit_building_region_spec/region_spec as anything in state.semantic_plan.region_specs)
		if(!istype(region_spec))
			continue
		var/list/spec_candidates = build_rectangular_region_candidates_for_spec(state, region_spec)
		for(var/datum/world_edit_building_solved_region/candidate as anything in spec_candidates)
			if(istype(candidate) && length(candidate.turfs))
				candidates += candidate
				state.rectangular_region_candidate_count++
	return candidates

/datum/world_edit_generator/building_layout/proc/extend_solved_region_bounds(datum/world_edit_building_solved_region/region, turf/target_turf)
	if(!istype(region) || !istype(target_turf))
		return
	if(isnull(region.x1) || target_turf.x < region.x1)
		region.x1 = target_turf.x
	if(isnull(region.x2) || target_turf.x > region.x2)
		region.x2 = target_turf.x
	if(isnull(region.y1) || target_turf.y < region.y1)
		region.y1 = target_turf.y
	if(isnull(region.y2) || target_turf.y > region.y2)
		region.y2 = target_turf.y

/datum/world_edit_generator/building_layout/proc/build_zone_region_candidate_map(datum/world_edit_building_layout_state/state, list/region_candidates)
	var/list/candidates_by_zone = list()
	for(var/datum/world_edit_building_solved_region/region_candidate as anything in region_candidates)
		if(!istype(region_candidate) || !length(region_candidate.zone_id))
			continue
		var/list/zone_candidates = candidates_by_zone[region_candidate.zone_id]
		if(!islist(zone_candidates))
			zone_candidates = list()
			candidates_by_zone[region_candidate.zone_id] = zone_candidates
		zone_candidates += region_candidate

	for(var/datum/world_edit_building_zone_spec/zone_spec as anything in state.semantic_plan.zone_specs)
		var/list/zone_candidates = candidates_by_zone[zone_spec.id]
		if(!islist(zone_candidates))
			zone_candidates = list()
			candidates_by_zone[zone_spec.id] = zone_candidates
		var/has_viable_candidate = FALSE
		for(var/datum/world_edit_building_solved_region/region_candidate as anything in zone_candidates)
			if(istype(region_candidate) && length(region_candidate.turfs) >= zone_spec.min_area)
				has_viable_candidate = TRUE
				break
		var/datum/world_edit_building_solved_region/union_candidate = new("zone_union_[zone_spec.id]", zone_spec.id, -100)
		var/list/union_lookup = list()
		for(var/datum/world_edit_building_solved_region/region_candidate as anything in zone_candidates)
			for(var/turf/candidate_turf as anything in region_candidate.turfs)
				if(!istype(candidate_turf) || union_lookup[candidate_turf])
					continue
				union_lookup[candidate_turf] = TRUE
				union_candidate.turfs += candidate_turf
				extend_solved_region_bounds(union_candidate, candidate_turf)
		if(!length(union_candidate.turfs))
			union_candidate.priority = -900
			for(var/turf/interior_turf as anything in state.interior)
				union_candidate.turfs += interior_turf
				extend_solved_region_bounds(union_candidate, interior_turf)
			state.degraded_region_fallback_count++
			state.degraded_region_reports += list(list(
				"zone" = zone_spec.id,
				"reason" = "no_region_candidates",
				"fallback_area" = length(union_candidate.turfs),
			))
		else if(!has_viable_candidate)
			union_candidate.priority = -650
			state.degraded_region_fallback_count++
			state.degraded_region_reports += list(list(
				"zone" = zone_spec.id,
				"reason" = "union_only",
				"fallback_area" = length(union_candidate.turfs),
			))
		if(length(union_candidate.turfs))
			zone_candidates += union_candidate
	return candidates_by_zone

/datum/world_edit_generator/building_layout/proc/get_required_zone_specs_for_assignment(datum/world_edit_building_layout_state/state)
	var/list/result = list()
	if(!istype(state) || !istype(state.semantic_plan))
		return result
	for(var/datum/world_edit_building_zone_spec/zone_spec as anything in state.semantic_plan.zone_specs)
		if(istype(zone_spec) && zone_spec.required)
			result += zone_spec
	return result

/datum/world_edit_generator/building_layout/proc/score_turf_for_zone_seed(datum/world_edit_building_layout_state/state, turf/candidate_turf, datum/world_edit_building_zone_spec/zone_spec, datum/world_edit_building_solved_region/candidate_region)
	if(!istype(state) || !istype(candidate_turf) || !istype(zone_spec))
		return -999999999
	var/score = 0
	if(istype(candidate_region))
		score += candidate_region.priority * 3
	var/front_percent = get_building_front_percent(state, candidate_turf)
	var/lateral_abs = abs(get_building_lateral_percent(state, candidate_turf))
	var/boundary_neighbors = 0
	for(var/check_dir in GLOB.cardinals)
		if(state.boundary_lookup[get_step(candidate_turf, check_dir)])
			boundary_neighbors++
	switch(zone_spec.role)
		if("entry", "public", "public_med")
			score += 180 - (front_percent * 2)
			score -= lateral_abs
		if("hub", "staging")
			score += 120 - lateral_abs
			score -= abs(front_percent - 55)
		if("storage", "service", "secure", "private", "nested", "support")
			score += front_percent
			score += boundary_neighbors * 90
		if("route", "choke")
			score += 160 - lateral_abs
			score -= abs(front_percent - 50) / 2
		else
			score += 80 - lateral_abs
	if(zone_spec.divider_mode in list("room", "nook"))
		score += boundary_neighbors * 45
	return score

/datum/world_edit_generator/building_layout/proc/select_available_zone_seed_turfs(datum/world_edit_building_layout_state/state, datum/world_edit_building_zone_spec/zone_spec, datum/world_edit_building_solved_region/candidate, list/claimed_lookup)
	var/list/result = list()
	if(!istype(state) || !istype(zone_spec) || !istype(candidate))
		return result
	var/target_count = max(zone_spec.min_area, min(length(candidate.turfs), zone_spec.min_area + 2))
	var/list/result_lookup = list()
	while(length(result) < target_count)
		var/turf/best_turf = null
		var/best_score = -999999999
		for(var/turf/candidate_turf as anything in candidate.turfs)
			if(!istype(candidate_turf) || claimed_lookup[candidate_turf] || result_lookup[candidate_turf] || state.boundary_lookup[candidate_turf] || state.wall_lookup[candidate_turf])
				continue
			var/score = score_turf_for_zone_seed(state, candidate_turf, zone_spec, candidate)
			if(length(result))
				var/near_seed = FALSE
				var/min_seed_dist = 9999
				for(var/turf/seed_turf as anything in result)
					if(!istype(seed_turf))
						continue
					var/seed_dist = abs(candidate_turf.x - seed_turf.x) + abs(candidate_turf.y - seed_turf.y)
					min_seed_dist = min(min_seed_dist, seed_dist)
					if(seed_dist == 1)
						near_seed = TRUE
				score += near_seed ? 240 : -min_seed_dist * 30
			if(!istype(best_turf) || score > best_score)
				best_turf = candidate_turf
				best_score = score
		if(!istype(best_turf))
			break
		result += best_turf
		result_lookup[best_turf] = TRUE
	return result

/datum/world_edit_generator/building_layout/proc/region_candidate_has_wall_affinity(datum/world_edit_building_layout_state/state, list/candidate_turfs)
	for(var/turf/candidate_turf as anything in candidate_turfs)
		if(!istype(candidate_turf))
			continue
		for(var/check_dir in GLOB.cardinals)
			if(state.boundary_lookup[get_step(candidate_turf, check_dir)])
				return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/region_candidate_touches_entry(datum/world_edit_building_layout_state/state, list/candidate_turfs)
	for(var/turf/candidate_turf as anything in candidate_turfs)
		if(!istype(candidate_turf))
			continue
		if(candidate_turf == state.front_door_turf || get_dist(candidate_turf, state.front_door_turf) <= 2)
			return TRUE
		if(get_building_front_percent(state, candidate_turf) <= 25)
			return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/region_candidate_respects_privacy(datum/world_edit_building_layout_state/state, list/candidate_turfs)
	for(var/turf/candidate_turf as anything in candidate_turfs)
		if(!istype(candidate_turf) || !istype(state.front_door_turf))
			continue
		if(get_dist(candidate_turf, state.front_door_turf) <= 2)
			return FALSE
	return TRUE

/datum/world_edit_generator/building_layout/proc/zone_seed_candidate_satisfies_constraints(datum/world_edit_building_layout_state/state, datum/world_edit_building_zone_spec/zone_spec, list/candidate_turfs)
	if(length(candidate_turfs) < zone_spec.min_area)
		return FALSE
	switch(zone_spec.role)
		if("entry", "public", "public_med", "choke")
			if(!region_candidate_touches_entry(state, candidate_turfs))
				return FALSE
		if("storage", "service", "secure", "private", "nested", "support")
			if(!region_candidate_has_wall_affinity(state, candidate_turfs))
				return FALSE
	if(zone_spec.privacy_sensitive && !region_candidate_respects_privacy(state, candidate_turfs))
		return FALSE
	return TRUE

/datum/world_edit_generator/building_layout/proc/get_zone_region_claim_target_area(datum/world_edit_building_layout_state/state, datum/world_edit_building_zone_spec/zone_spec, datum/world_edit_building_solved_region/candidate)
	if(!istype(zone_spec) || !istype(candidate))
		return 0
	var/candidate_area = length(candidate.turfs)
	if(candidate_area <= 0)
		return 0
	var/base_area = max(zone_spec.min_area, min(candidate_area, zone_spec.min_area + 4))
	switch(zone_spec.role)
		if("hub", "staging")
			return max(base_area, min(candidate_area, round((candidate_area * 3) / 4)))
		if("route", "choke")
			return max(base_area, min(candidate_area, round((candidate_area * 7) / 10)))
		if("storage", "service", "secure", "private", "nested", "support")
			return max(base_area, min(candidate_area, round((candidate_area * 13) / 20)))
		if("entry", "public", "public_med")
			return max(base_area, min(candidate_area, round((candidate_area * 11) / 20)))
	if(zone_spec.divider_mode == "room")
		return max(base_area, min(candidate_area, round((candidate_area * 13) / 20)))
	if(zone_spec.divider_mode == "nook")
		return max(base_area, min(candidate_area, round(candidate_area / 2)))
	return base_area

/datum/world_edit_generator/building_layout/proc/score_zone_region_candidate(datum/world_edit_building_layout_state/state, datum/world_edit_building_zone_spec/zone_spec, datum/world_edit_building_solved_region/candidate, list/claimed_lookup)
	if(!istype(state) || !istype(zone_spec) || !istype(candidate))
		return -999999999
	var/list/seed_turfs = select_available_zone_seed_turfs(state, zone_spec, candidate, claimed_lookup)
	if(!zone_seed_candidate_satisfies_constraints(state, zone_spec, seed_turfs))
		return -999999999

	var/candidate_area = length(candidate.turfs)
	var/target_area = get_zone_region_claim_target_area(state, zone_spec, candidate)
	var/score = candidate.priority * 25
	score += min(candidate_area, max(target_area, zone_spec.min_area) * 2) * 8
	score += length(seed_turfs) * 45
	if(findtext("[candidate.id]", "zone_union_"))
		score -= candidate.priority <= -650 ? 6500 : 4200
	if(zone_spec.divider_mode == "room")
		score += 450
	if(zone_spec.divider_mode == "nook")
		score += 220

	var/conflict_count = 0
	for(var/turf/candidate_turf as anything in candidate.turfs)
		if(!istype(candidate_turf))
			continue
		if(claimed_lookup[candidate_turf])
			conflict_count++
	score -= conflict_count * 120

	if(region_candidate_has_wall_affinity(state, candidate.turfs))
		switch(zone_spec.role)
			if("storage", "service", "secure", "private", "nested", "support")
				score += 360
			else
				score += 80
	if(region_candidate_touches_entry(state, candidate.turfs))
		switch(zone_spec.role)
			if("entry", "public", "public_med", "choke")
				score += 360
			if("secure", "private", "nested")
				score -= 220
	if(zone_spec.privacy_sensitive && !region_candidate_respects_privacy(state, candidate.turfs))
		score -= 2000

	var/width = 0
	var/height = 0
	if(!isnull(candidate.x1) && !isnull(candidate.x2))
		width = (candidate.x2 - candidate.x1) + 1
	if(!isnull(candidate.y1) && !isnull(candidate.y2))
		height = (candidate.y2 - candidate.y1) + 1
	if(zone_spec.divider_mode in list("room", "nook"))
		score += min(width, height) * 90
		score -= abs(width - height) * 18
	if(candidate_area > target_area * 2)
		score -= (candidate_area - (target_area * 2)) * 6
	return score

/datum/world_edit_generator/building_layout/proc/select_best_zone_region_candidate(datum/world_edit_building_layout_state/state, datum/world_edit_building_zone_spec/zone_spec, list/remaining_candidates, list/claimed_lookup)
	var/datum/world_edit_building_solved_region/best_candidate = null
	var/best_score = -999999999
	for(var/datum/world_edit_building_solved_region/candidate as anything in remaining_candidates)
		if(!istype(candidate))
			continue
		var/score = score_zone_region_candidate(state, zone_spec, candidate, claimed_lookup)
		if(score <= -999999000)
			continue
		if(!istype(best_candidate) || score > best_score)
			best_candidate = candidate
			best_score = score
	return best_candidate

/datum/world_edit_generator/building_layout/proc/assign_required_zone_region_seeds(datum/world_edit_building_layout_state/state, list/zone_specs, list/candidates_by_zone, zone_index, list/claimed_lookup, list/assignments, list/region_assignments, list/search_budget = null)
	if(zone_index > length(zone_specs))
		return TRUE
	if(!islist(search_budget))
		search_budget = list("remaining" = WORLD_EDIT_BUILDING_MAX_REGION_ASSIGNMENT_STEPS)
	var/remaining_steps = round(text2num("[search_budget["remaining"]]") || 0)
	if(remaining_steps <= 0)
		return FALSE
	search_budget["remaining"] = remaining_steps - 1
	var/datum/world_edit_building_zone_spec/zone_spec = zone_specs[zone_index]
	if(!istype(zone_spec))
		return assign_required_zone_region_seeds(state, zone_specs, candidates_by_zone, zone_index + 1, claimed_lookup, assignments, region_assignments, search_budget)
	var/list/zone_candidates = candidates_by_zone[zone_spec.id]
	if(!islist(zone_candidates) || !length(zone_candidates))
		return FALSE
	var/list/remaining_candidates = zone_candidates.Copy()
	var/branch_attempts = 0
	while(length(remaining_candidates) && branch_attempts < WORLD_EDIT_BUILDING_MAX_REGION_ASSIGNMENT_BRANCHES)
		branch_attempts++
		var/datum/world_edit_building_solved_region/candidate = select_best_zone_region_candidate(state, zone_spec, remaining_candidates, claimed_lookup)
		if(!istype(candidate))
			break
		remaining_candidates -= candidate
		var/list/seed_turfs = select_available_zone_seed_turfs(state, zone_spec, candidate, claimed_lookup)
		if(!zone_seed_candidate_satisfies_constraints(state, zone_spec, seed_turfs))
			continue
		for(var/turf/seed_turf as anything in seed_turfs)
			claimed_lookup[seed_turf] = TRUE
		assignments[zone_spec.id] = seed_turfs
		region_assignments[zone_spec.id] = candidate
		if(assign_required_zone_region_seeds(state, zone_specs, candidates_by_zone, zone_index + 1, claimed_lookup, assignments, region_assignments, search_budget))
			return TRUE
		for(var/turf/seed_turf as anything in seed_turfs)
			claimed_lookup.Remove(seed_turf)
		assignments.Remove(zone_spec.id)
		region_assignments.Remove(zone_spec.id)
	return FALSE

/datum/world_edit_generator/building_layout/proc/apply_required_zone_seed_assignments(datum/world_edit_building_layout_state/state, list/assignments)
	if(!islist(assignments))
		return
	for(var/zone_id as anything in assignments)
		var/list/seed_turfs = assignments[zone_id]
		if(!islist(seed_turfs))
			continue
		for(var/turf/seed_turf as anything in seed_turfs)
			state.add_zone(seed_turf, zone_id)

/datum/world_edit_generator/building_layout/proc/score_turf_for_region_claim(datum/world_edit_building_layout_state/state, turf/candidate_turf, datum/world_edit_building_zone_spec/zone_spec, datum/world_edit_building_solved_region/selected_region)
	if(!istype(state) || !istype(candidate_turf) || !istype(zone_spec))
		return -999999999
	var/score = score_turf_for_zone_repair(state, candidate_turf, zone_spec)
	if(istype(selected_region))
		score += selected_region.priority * 4
	var/current_zone_id = state.get_zone(candidate_turf)
	if(!length(current_zone_id))
		score += 80
	else if(current_zone_id == state.semantic_plan?.primary_zone_id)
		score += 20
	else
		score -= 80

	var/same_zone_neighbors = 0
	var/boundary_neighbors = 0
	for(var/check_dir in GLOB.cardinals)
		var/turf/nearby_turf = get_step(candidate_turf, check_dir)
		if(state.get_zone(nearby_turf) == zone_spec.id)
			same_zone_neighbors++
		if(state.boundary_lookup[nearby_turf])
			boundary_neighbors++
	score += same_zone_neighbors * 130
	if(zone_spec.role in list("storage", "service", "secure", "private", "nested", "support"))
		score += boundary_neighbors * 55
	if(zone_spec.role in list("entry", "public", "public_med", "choke"))
		score += 100 - get_building_front_percent(state, candidate_turf)
	if(zone_spec.divider_mode in list("room", "nook"))
		score += boundary_neighbors * 30
	return score

/datum/world_edit_generator/building_layout/proc/select_region_claim_turf(datum/world_edit_building_layout_state/state, datum/world_edit_building_zone_spec/zone_spec, datum/world_edit_building_solved_region/selected_region)
	if(!istype(state) || !istype(zone_spec) || !istype(selected_region))
		return null
	var/turf/best_turf = null
	var/best_score = -999999999
	for(var/turf/candidate_turf as anything in selected_region.turfs)
		if(!istype(candidate_turf) || state.boundary_lookup[candidate_turf] || state.wall_lookup[candidate_turf])
			continue
		if(state.get_zone(candidate_turf) == zone_spec.id)
			continue
		if(!can_reassign_turf_to_zone(state, candidate_turf, zone_spec))
			continue
		var/score = score_turf_for_region_claim(state, candidate_turf, zone_spec, selected_region)
		if(!istype(best_turf) || score > best_score)
			best_turf = candidate_turf
			best_score = score
	return best_turf

/datum/world_edit_generator/building_layout/proc/apply_required_zone_region_claims(datum/world_edit_building_layout_state/state, list/region_assignments)
	if(!istype(state) || !islist(region_assignments))
		return
	state.region_claim_count = 0
	state.region_claim_reports.Cut()
	for(var/zone_id as anything in region_assignments)
		var/datum/world_edit_building_solved_region/selected_region = region_assignments[zone_id]
		if(!istype(selected_region))
			continue
		var/datum/world_edit_building_zone_spec/zone_spec = state.semantic_plan?.get_zone_spec(zone_id)
		if(!istype(zone_spec))
			continue
		var/target_area = get_zone_region_claim_target_area(state, zone_spec, selected_region)
		var/attempts = 0
		var/list/zone_turfs = state.get_zone_turfs(zone_spec.id)
		var/before_count = length(zone_turfs)
		while(length(zone_turfs) < target_area && attempts < WORLD_EDIT_BUILDING_MAX_CLUSTER_STEPS)
			attempts++
			var/turf/claim_turf = select_region_claim_turf(state, zone_spec, selected_region)
			if(!istype(claim_turf))
				break
			state.add_zone(claim_turf, zone_spec.id)
			zone_turfs = state.get_zone_turfs(zone_spec.id)
		var/after_count = length(zone_turfs)
		state.region_claim_count += after_count
		var/list/report = list(
			"zone" = zone_spec.id,
			"region" = selected_region.id,
			"target_area" = target_area,
			"seed_area" = before_count,
			"claimed_area" = after_count,
			"added_area" = max(after_count - before_count, 0),
		)
		state.region_claim_reports += list(report)

/datum/world_edit_generator/building_layout/proc/select_highest_priority_region_candidate(list/remaining_candidates)
	var/datum/world_edit_building_solved_region/best_candidate = null
	var/best_priority = -999999
	for(var/datum/world_edit_building_solved_region/candidate as anything in remaining_candidates)
		if(!istype(candidate))
			continue
		if(!istype(best_candidate) || candidate.priority > best_priority)
			best_candidate = candidate
			best_priority = candidate.priority
	return best_candidate

/datum/world_edit_generator/building_layout/proc/apply_region_candidate_growth(datum/world_edit_building_layout_state/state, list/region_candidates)
	var/list/remaining_candidates = region_candidates.Copy()
	while(length(remaining_candidates))
		var/datum/world_edit_building_solved_region/candidate = select_highest_priority_region_candidate(remaining_candidates)
		if(!istype(candidate))
			break
		remaining_candidates -= candidate
		for(var/turf/candidate_turf as anything in candidate.turfs)
			if(!istype(candidate_turf) || state.boundary_lookup[candidate_turf])
				continue
			if(!length(state.get_zone(candidate_turf)))
				state.add_zone(candidate_turf, candidate.zone_id)
	for(var/turf/interior_turf as anything in state.interior)
		if(!length(state.get_zone(interior_turf)))
			state.add_zone(interior_turf, state.semantic_plan.primary_zone_id || state.archetype.primary_zone)

/datum/world_edit_generator/building_layout/proc/rebuild_solved_regions_from_zone_assignments(datum/world_edit_building_layout_state/state, list/region_candidates)
	state.solved_regions.Cut()
	var/list/seen_region_ids = list()
	for(var/datum/world_edit_building_solved_region/candidate as anything in region_candidates)
		if(!istype(candidate) || seen_region_ids[candidate.id])
			continue
		var/datum/world_edit_building_solved_region/solved_region = new(candidate.id, candidate.zone_id, candidate.priority)
		for(var/turf/candidate_turf as anything in candidate.turfs)
			if(state.get_zone(candidate_turf) != candidate.zone_id)
				continue
			solved_region.turfs += candidate_turf
			extend_solved_region_bounds(solved_region, candidate_turf)
		if(length(solved_region.turfs))
			state.solved_regions += solved_region
			seen_region_ids[candidate.id] = TRUE

/datum/world_edit_generator/building_layout/proc/solve_building_semantic_regions(datum/world_edit_building_layout_state/state)
	if(!istype(state) || !istype(state.semantic_plan))
		return
	prepare_building_local_metrics(state)
	state.clear_zones()
	state.solved_regions.Cut()

	var/list/region_candidates = build_building_room_region_candidates(state)
	var/list/candidates_by_zone = build_zone_region_candidate_map(state, region_candidates)
	var/list/required_zone_specs = get_required_zone_specs_for_assignment(state)
	var/list/claimed_lookup = list()
	var/list/assignments = list()
	var/list/region_assignments = list()
	var/list/search_budget = list("remaining" = WORLD_EDIT_BUILDING_MAX_REGION_ASSIGNMENT_STEPS)
	if(assign_required_zone_region_seeds(state, required_zone_specs, candidates_by_zone, 1, claimed_lookup, assignments, region_assignments, search_budget))
		apply_required_zone_seed_assignments(state, assignments)
		apply_required_zone_region_claims(state, region_assignments)
	else
		state.degraded_region_fallback_count++
		state.degraded_region_reports += list(list(
			"reason" = "backtracking_assignment_failed",
			"required_zone_count" = length(required_zone_specs),
			"search_budget_remaining" = search_budget["remaining"],
			"search_budget_exhausted" = (round(text2num("[search_budget["remaining"]]") || 0) <= 0),
		))
		state.add_warning("Room region solver fell back to priority growth for one or more required zones.")
	apply_region_candidate_growth(state, region_candidates)
	repair_building_zone_coverage(state)
	rebuild_solved_regions_from_zone_assignments(state, region_candidates)

/datum/world_edit_generator/building_layout/proc/repair_building_zone_coverage(datum/world_edit_building_layout_state/state)
	if(!istype(state) || !istype(state.semantic_plan))
		return
	for(var/pass in 1 to 3)
		var/repaired_this_pass = FALSE
		for(var/datum/world_edit_building_zone_spec/zone_spec as anything in state.semantic_plan.zone_specs)
			if(!zone_spec.required)
				continue
			var/list/zone_turfs = state.get_zone_turfs(zone_spec.id)
			var/attempts = 0
			while(length(zone_turfs) < zone_spec.min_area && attempts < WORLD_EDIT_BUILDING_MAX_CLUSTER_STEPS)
				attempts++
				var/turf/repair_turf = select_zone_repair_turf(state, zone_spec)
				if(!istype(repair_turf))
					break
				state.add_zone(repair_turf, zone_spec.id)
				repaired_this_pass = TRUE
				zone_turfs = state.get_zone_turfs(zone_spec.id)
		if(!repaired_this_pass)
			break

/datum/world_edit_generator/building_layout/proc/select_zone_repair_turf(datum/world_edit_building_layout_state/state, datum/world_edit_building_zone_spec/zone_spec)
	var/turf/best_turf = null
	var/best_score = -999999999
	for(var/turf/candidate as anything in state.interior)
		if(!can_reassign_turf_to_zone(state, candidate, zone_spec))
			continue
		var/score = score_turf_for_zone_repair(state, candidate, zone_spec)
		if(!istype(best_turf) || score > best_score)
			best_turf = candidate
			best_score = score
	return best_turf

/datum/world_edit_generator/building_layout/proc/can_reassign_turf_to_zone(datum/world_edit_building_layout_state/state, turf/candidate, datum/world_edit_building_zone_spec/target_zone_spec)
	if(!istype(state) || !istype(candidate) || !istype(target_zone_spec))
		return FALSE
	if(state.boundary_lookup[candidate] || state.wall_lookup[candidate])
		return FALSE
	var/current_zone_id = state.get_zone(candidate)
	if(current_zone_id == target_zone_spec.id)
		return FALSE
	var/datum/world_edit_building_zone_spec/current_zone_spec = state.semantic_plan.get_zone_spec(current_zone_id)
	if(istype(current_zone_spec) && current_zone_spec.required && length(state.get_zone_turfs(current_zone_spec.id)) <= current_zone_spec.min_area)
		return FALSE
	return TRUE

/datum/world_edit_generator/building_layout/proc/score_turf_for_zone_repair(datum/world_edit_building_layout_state/state, turf/candidate, datum/world_edit_building_zone_spec/zone_spec)
	var/score = 0
	for(var/datum/world_edit_building_region_spec/region_spec as anything in state.semantic_plan.region_specs)
		if(region_spec.zone_id != zone_spec.id)
			continue
		if(region_spec_contains_turf(state, region_spec, candidate))
			score += 200 + region_spec.priority

	var/same_zone_neighbors = 0
	var/boundary_neighbors = 0
	var/route_neighbors = 0
	for(var/check_dir in GLOB.cardinals)
		var/turf/nearby_turf = get_step(candidate, check_dir)
		if(state.get_zone(nearby_turf) == zone_spec.id)
			same_zone_neighbors++
		if(state.boundary_lookup[nearby_turf])
			boundary_neighbors++
		if(state.reserved_lookup[nearby_turf])
			route_neighbors++
	score += same_zone_neighbors * 90
	score += route_neighbors * 20

	var/front_percent = get_building_front_percent(state, candidate)
	var/lateral_abs = abs(get_building_lateral_percent(state, candidate))
	switch(zone_spec.role)
		if("entry", "public", "public_med")
			score += 100 - front_percent
			score -= lateral_abs / 2
		if("hub", "staging")
			score += 100 - lateral_abs
			score -= abs(front_percent - 55) / 2
		if("storage", "service", "secure", "private", "nested")
			score += front_percent
			score += boundary_neighbors * 35
		if("route", "choke")
			score += 100 - lateral_abs
			score += route_neighbors * 35
		else
			score += 50 - lateral_abs / 2

	var/current_zone_id = state.get_zone(candidate)
	if(current_zone_id == state.semantic_plan.primary_zone_id)
		score += 25
	return score

/datum/world_edit_generator/building_layout/proc/select_zone_focus_turf(datum/world_edit_building_layout_state/state, zone_id)
	var/list/zone_turfs = state.get_zone_turfs(zone_id)
	if(!length(zone_turfs))
		return null
	var/center_x = (state.bounds["min_x"] + state.bounds["max_x"]) / 2
	var/center_y = (state.bounds["min_y"] + state.bounds["max_y"]) / 2
	var/turf/best_turf = null
	var/best_score = -999999999
	for(var/turf/zone_turf as anything in zone_turfs)
		if(!istype(zone_turf) || state.wall_lookup[zone_turf])
			continue
		var/score = 0
		score -= abs(zone_turf.x - center_x) + abs(zone_turf.y - center_y)
		if(state.reserved_lookup[zone_turf])
			score += 15
		if(length(get_adjacent_wall_dirs_for_state(state, zone_turf)))
			score -= 4
		if(!istype(best_turf) || score > best_score)
			best_turf = zone_turf
			best_score = score
	return best_turf

/datum/world_edit_generator/building_layout/proc/refresh_building_zone_foci(datum/world_edit_building_layout_state/state)
	if(!istype(state) || !istype(state.semantic_plan))
		return
	for(var/datum/world_edit_building_zone_spec/zone_spec as anything in state.semantic_plan.zone_specs)
		var/turf/focus_turf = select_zone_focus_turf(state, zone_spec.id)
		if(istype(focus_turf))
			state.set_zone_focus(zone_spec.id, focus_turf)
	for(var/datum/world_edit_building_solved_region/solved_region as anything in state.solved_regions)
		var/turf/region_focus = select_zone_focus_turf(state, solved_region.zone_id)
		if(istype(region_focus))
			solved_region.focus_turf = region_focus

/datum/world_edit_generator/building_layout/proc/build_building_provisional_floor_lookup(datum/world_edit_building_layout_state/state)
	var/list/provisional_floor_turfs = list()
	var/list/provisional_lookup = list()
	for(var/turf/interior_turf as anything in state.interior)
		if(!state.wall_lookup[interior_turf])
			append_unique_turf(provisional_floor_turfs, provisional_lookup, interior_turf)
	for(var/turf/door_turf as anything in state.door_turfs)
		append_unique_turf(provisional_floor_turfs, provisional_lookup, door_turf)
	return provisional_lookup

/datum/world_edit_generator/building_layout/proc/build_building_preliminary_circulation(datum/world_edit_building_layout_state/state)
	if(!istype(state) || !istype(state.semantic_plan))
		return
	state.floor_lookup = build_building_provisional_floor_lookup(state)
	var/center_x = (state.bounds["min_x"] + state.bounds["max_x"]) / 2
	var/center_y = (state.bounds["min_y"] + state.bounds["max_y"]) / 2
	state.center_turf = select_center_floor_turf(state.interior, center_x, center_y) || state.front_door_turf
	refresh_building_zone_foci(state)
	state.semantic_hub_turf = state.get_zone_focus(state.semantic_plan.hub_zone_id) || state.center_turf
	build_building_reserved_lanes(state)

/datum/world_edit_generator/building_layout/proc/build_building_zone_dividers(datum/world_edit_building_layout_state/state)
	if(!istype(state) || !istype(state.semantic_plan))
		return
	for(var/datum/world_edit_building_zone_spec/zone_spec as anything in state.semantic_plan.zone_specs)
		if(!(zone_spec.divider_mode in list("room", "nook")))
			continue
		var/target_divider_count = zone_spec.divider_mode == "room" ? 4 : 2
		var/built_dividers = 0
		while(built_dividers < target_divider_count)
			var/datum/world_edit_building_divider_plan/divider_plan = build_zone_edge_divider_plan(state, zone_spec)
			if(!istype(divider_plan))
				break
			state.add_divider_plan(divider_plan)
			built_dividers++
			if(findtext("[divider_plan.id]", "box_") == 1)
				break

/datum/world_edit_generator/building_layout/proc/build_zone_edge_divider_plan(datum/world_edit_building_layout_state/state, datum/world_edit_building_zone_spec/zone_spec)
	var/list/zone_turfs = state.get_zone_turfs(zone_spec.id)
	if(length(zone_turfs) < zone_spec.min_area + 2)
		return null
	var/list/edge_runs = build_region_border_divider_runs(state, zone_spec)
	var/run_attempts = 0
	while(length(edge_runs) && run_attempts < WORLD_EDIT_BUILDING_MAX_DIVIDER_RUN_ATTEMPTS)
		run_attempts++
		var/datum/world_edit_building_divider_edge_run/best_run = select_best_divider_edge_run(edge_runs)
		if(!istype(best_run))
			break
		edge_runs -= best_run
		var/datum/world_edit_building_divider_plan/divider_plan = build_divider_plan_from_edge_run(state, zone_spec, best_run)
		if(!istype(divider_plan))
			continue
		if(!divider_plan_keeps_floor_reachable(state, divider_plan))
			continue
		return divider_plan
	return build_zone_box_divider_plan(state, zone_spec)

/datum/world_edit_generator/building_layout/proc/build_zone_box_divider_plan(datum/world_edit_building_layout_state/state, datum/world_edit_building_zone_spec/zone_spec)
	var/list/zone_turfs = state.get_zone_turfs(zone_spec.id)
	if(length(zone_turfs) < max(zone_spec.min_area + 2, 6))
		return null
	var/min_x = 999999
	var/max_x = -999999
	var/min_y = 999999
	var/max_y = -999999
	for(var/turf/zone_turf as anything in zone_turfs)
		if(!istype(zone_turf))
			continue
		min_x = min(min_x, zone_turf.x)
		max_x = max(max_x, zone_turf.x)
		min_y = min(min_y, zone_turf.y)
		max_y = max(max_y, zone_turf.y)
	if((max_x - min_x) < 2 || (max_y - min_y) < 2)
		return null
	var/list/zone_lookup = GLOB.world_edit_placement_shapes.world_edit_build_turf_lookup(zone_turfs)
	var/list/perimeter = list()
	var/list/inner_turfs = list()
	for(var/turf/zone_turf as anything in zone_turfs)
		if(!istype(zone_turf) || state.boundary_lookup[zone_turf] || state.door_dirs[zone_turf] || state.wall_lookup[zone_turf])
			continue
		if(zone_turf.x == min_x || zone_turf.x == max_x || zone_turf.y == min_y || zone_turf.y == max_y)
			if(!state.reserved_lookup[zone_turf])
				perimeter += zone_turf
		else
			inner_turfs += zone_turf
	if(length(perimeter) < 3 || !length(inner_turfs))
		return null
	var/turf/opening_turf = select_divider_opening_turf(state, perimeter)
	if(!istype(opening_turf))
		return null
	var/datum/world_edit_building_divider_plan/divider_plan = new("box_[zone_spec.id]_[length(state.divider_plans) + 1]", state.semantic_plan.primary_zone_id || state.semantic_plan.hub_zone_id, zone_spec.id)
	divider_plan.opening_turfs += opening_turf
	divider_plan.opening_dirs[opening_turf] = get_cardinal_dir_toward(opening_turf, state.semantic_hub_turf || state.front_door_turf || state.center_turf, state.placement_dir)
	for(var/turf/perimeter_turf as anything in perimeter)
		if(!istype(perimeter_turf) || perimeter_turf == opening_turf || !zone_lookup[perimeter_turf])
			continue
		divider_plan.wall_turfs += perimeter_turf
	for(var/turf/inner_turf as anything in inner_turfs)
		if(istype(inner_turf))
			divider_plan.inner_turfs += inner_turf
	if(length(divider_plan.wall_turfs) < 2)
		return null
	if(!divider_plan_keeps_floor_reachable(state, divider_plan))
		return null
	return divider_plan

/datum/world_edit_generator/building_layout/proc/build_region_border_divider_runs(datum/world_edit_building_layout_state/state, datum/world_edit_building_zone_spec/zone_spec)
	var/list/runs = list()
	var/list/group_turfs_by_key = list()
	var/list/group_dirs_by_key = list()
	var/list/group_source_by_key = list()
	for(var/turf/zone_turf as anything in state.get_zone_turfs(zone_spec.id))
		if(!istype(zone_turf) || state.wall_lookup[zone_turf] || state.reserved_lookup[zone_turf] || state.boundary_lookup[zone_turf] || state.door_dirs[zone_turf])
			continue
		for(var/check_dir in GLOB.cardinals)
			var/turf/nearby_turf = get_step(zone_turf, check_dir)
			if(!state.footprint_lookup[nearby_turf] || state.boundary_lookup[nearby_turf])
				continue
			var/source_zone_id = state.get_zone(nearby_turf)
			if(!length(source_zone_id) || source_zone_id == zone_spec.id)
				continue
			var/orientation = (check_dir in list(NORTH, SOUTH)) ? "horizontal" : "vertical"
			var/axis_value = orientation == "horizontal" ? zone_turf.y : zone_turf.x
			var/key = "[orientation]|[axis_value]|[check_dir]|[source_zone_id]"
			var/list/group_turfs = group_turfs_by_key[key]
			if(!islist(group_turfs))
				group_turfs = list()
				group_turfs_by_key[key] = group_turfs
				group_dirs_by_key[key] = list()
				group_source_by_key[key] = source_zone_id
			group_turfs += zone_turf
			var/list/group_dirs = group_dirs_by_key[key]
			group_dirs[zone_turf] = check_dir
	for(var/group_key as anything in group_turfs_by_key)
		var/list/group_turfs = group_turfs_by_key[group_key]
		if(!islist(group_turfs) || length(group_turfs) < 2)
			continue
		var/list/group_lookup = GLOB.world_edit_placement_shapes.world_edit_build_turf_lookup(group_turfs)
		var/list/visited = list()
		var/list/group_dirs = group_dirs_by_key[group_key]
		var/source_zone_id = group_source_by_key[group_key]
		var/run_index = 1
		for(var/turf/start_turf as anything in group_turfs)
			if(!istype(start_turf) || visited[start_turf])
				continue
			var/list/segment = collect_divider_edge_segment(start_turf, group_lookup, visited)
			if(length(segment) < 2)
				continue
			var/orientation = findtext("[group_key]", "horizontal") == 1 ? "horizontal" : "vertical"
			var/datum/world_edit_building_divider_edge_run/run = new("edge_[zone_spec.id]_[run_index++]", zone_spec.id, source_zone_id, orientation)
			for(var/turf/segment_turf as anything in segment)
				run.wall_turfs += segment_turf
				run.outside_dirs[segment_turf] = group_dirs[segment_turf]
			run.score = score_divider_edge_run(state, zone_spec, run)
			runs += run
	return runs

/datum/world_edit_generator/building_layout/proc/collect_divider_edge_segment(turf/start_turf, list/group_lookup, list/visited)
	var/list/segment = list()
	var/list/queue = list(start_turf)
	visited[start_turf] = TRUE
	var/index = 1
	while(index <= length(queue))
		var/turf/current_turf = queue[index++]
		segment += current_turf
		for(var/check_dir in GLOB.cardinals)
			var/turf/nearby_turf = get_step(current_turf, check_dir)
			if(!group_lookup[nearby_turf] || visited[nearby_turf])
				continue
			visited[nearby_turf] = TRUE
			queue += nearby_turf
	return segment

/datum/world_edit_generator/building_layout/proc/score_divider_edge_run(datum/world_edit_building_layout_state/state, datum/world_edit_building_zone_spec/zone_spec, datum/world_edit_building_divider_edge_run/run)
	var/score = length(run.wall_turfs) * 30
	var/turf/target_turf = state.semantic_hub_turf || state.front_door_turf || state.center_turf
	var/turf/opening_turf = select_divider_opening_turf(state, run.wall_turfs)
	if(!istype(opening_turf))
		score -= 10000
	else if(istype(target_turf))
		score -= (abs(opening_turf.x - target_turf.x) + abs(opening_turf.y - target_turf.y)) * 5
	if(zone_spec.divider_mode == "room")
		score += 45
	else
		score += 15
	for(var/turf/run_turf as anything in run.wall_turfs)
		if(state.primary_route_turfs.Find(run_turf) || state.reserved_lookup[run_turf] || state.wall_lookup[run_turf] || state.door_dirs[run_turf])
			score -= 200
		if(run_turf == state.front_door_turf)
			score -= 1000
	return score

/datum/world_edit_generator/building_layout/proc/select_best_divider_edge_run(list/runs)
	var/datum/world_edit_building_divider_edge_run/best_run = null
	var/best_score = -999999999
	for(var/datum/world_edit_building_divider_edge_run/run as anything in runs)
		if(!istype(run))
			continue
		if(!istype(best_run) || run.score > best_score)
			best_run = run
			best_score = run.score
	return best_run

/datum/world_edit_generator/building_layout/proc/build_divider_plan_from_edge_run(datum/world_edit_building_layout_state/state, datum/world_edit_building_zone_spec/zone_spec, datum/world_edit_building_divider_edge_run/run)
	if(!istype(state) || !istype(zone_spec) || !istype(run) || length(run.wall_turfs) < 2)
		return null
	var/turf/opening_turf = select_divider_opening_turf(state, run.wall_turfs)
	if(!istype(opening_turf))
		return null
	var/datum/world_edit_building_divider_plan/divider_plan = new("divider_[zone_spec.id]_[run.id]", run.source_zone_id || state.semantic_plan.primary_zone_id, zone_spec.id)
	divider_plan.opening_turfs += opening_turf
	divider_plan.opening_dirs[opening_turf] = run.outside_dirs[opening_turf] || get_cardinal_dir_toward(opening_turf, state.semantic_hub_turf || state.front_door_turf, state.placement_dir)
	var/max_wall_count = max(1, length(run.wall_turfs) - 1)
	if(zone_spec.divider_mode == "nook")
		max_wall_count = min(max_wall_count, max(1, round(length(run.wall_turfs) * 2 / 3)))
	var/placed_walls = 0
	for(var/turf/run_turf as anything in run.wall_turfs)
		if(!istype(run_turf) || run_turf == opening_turf || state.reserved_lookup[run_turf] || state.door_dirs[run_turf] || state.wall_lookup[run_turf])
			continue
		if(placed_walls >= max_wall_count)
			break
		divider_plan.wall_turfs += run_turf
		placed_walls++
	for(var/turf/zone_turf as anything in state.get_zone_turfs(zone_spec.id))
		if(!(zone_turf in divider_plan.wall_turfs) && zone_turf != opening_turf)
			divider_plan.inner_turfs += zone_turf
	if(!length(divider_plan.wall_turfs))
		return null
	return divider_plan

/datum/world_edit_generator/building_layout/proc/build_floor_lookup_after_divider_plan(datum/world_edit_building_layout_state/state, datum/world_edit_building_divider_plan/divider_plan)
	var/list/floor_lookup = list()
	var/list/planned_wall_lookup = GLOB.world_edit_placement_shapes.world_edit_build_turf_lookup(divider_plan.wall_turfs)
	var/list/source_floor_turfs = length(state.floor_turfs) ? state.floor_turfs : state.floor_lookup
	for(var/turf/floor_turf as anything in source_floor_turfs)
		if(!istype(floor_turf) || state.wall_lookup[floor_turf] || planned_wall_lookup[floor_turf])
			continue
		floor_lookup[floor_turf] = TRUE
	for(var/turf/opening_turf as anything in divider_plan.opening_turfs)
		if(istype(opening_turf) && state.footprint_lookup[opening_turf])
			floor_lookup[opening_turf] = TRUE
	return floor_lookup

/datum/world_edit_generator/building_layout/proc/build_reachable_lookup_from_floor_lookup(datum/world_edit_building_layout_state/state, list/floor_lookup)
	var/list/reachable = list()
	var/list/queue = list()
	var/list/start_doors = list()
	for(var/turf/door_turf as anything in state.door_turfs)
		if(state.boundary_lookup[door_turf])
			start_doors += door_turf
	if(!length(start_doors))
		start_doors = state.door_turfs
	for(var/turf/door_turf as anything in start_doors)
		if(floor_lookup[door_turf] && !reachable[door_turf])
			reachable[door_turf] = TRUE
			queue += door_turf
		var/door_dir = state.door_dirs[door_turf] || state.placement_dir
		var/turf/inward_turf = get_step(door_turf, turn(door_dir, 180))
		if(floor_lookup[inward_turf] && !reachable[inward_turf])
			reachable[inward_turf] = TRUE
			queue += inward_turf
	var/index = 1
	while(index <= length(queue))
		var/turf/current_turf = queue[index++]
		for(var/check_dir in GLOB.cardinals)
			var/turf/nearby_turf = get_step(current_turf, check_dir)
			if(!floor_lookup[nearby_turf] || reachable[nearby_turf])
				continue
			reachable[nearby_turf] = TRUE
			queue += nearby_turf
	return reachable

/datum/world_edit_generator/building_layout/proc/divider_plan_keeps_floor_reachable(datum/world_edit_building_layout_state/state, datum/world_edit_building_divider_plan/divider_plan)
	if(!istype(state) || !istype(divider_plan))
		return FALSE
	for(var/turf/opening_turf as anything in divider_plan.opening_turfs)
		if(!istype(opening_turf) || state.wall_lookup[opening_turf] || state.boundary_lookup[opening_turf] || state.door_dirs[opening_turf])
			return FALSE
	var/list/floor_lookup = build_floor_lookup_after_divider_plan(state, divider_plan)
	var/list/reachable = build_reachable_lookup_from_floor_lookup(state, floor_lookup)
	for(var/turf/floor_turf as anything in floor_lookup)
		if(!floor_lookup[floor_turf])
			continue
		if(!reachable[floor_turf])
			return FALSE
	return TRUE

/datum/world_edit_generator/building_layout/proc/select_divider_opening_turf(datum/world_edit_building_layout_state/state, list/candidate_turfs)
	var/turf/best_turf = null
	var/best_score = -999999999
	var/turf/target_turf = state.semantic_hub_turf || state.front_door_turf || state.center_turf
	for(var/turf/candidate as anything in candidate_turfs)
		if(!istype(candidate) || state.reserved_lookup[candidate] || state.wall_lookup[candidate] || state.boundary_lookup[candidate] || state.door_dirs[candidate])
			continue
		var/score = 0
		if(istype(target_turf))
			score -= abs(candidate.x - target_turf.x) + abs(candidate.y - target_turf.y)
		if(candidate == state.front_door_turf)
			score -= 1000
		if(!istype(best_turf) || score > best_score)
			best_turf = candidate
			best_score = score
	return best_turf

/datum/world_edit_generator/building_layout/proc/build_building_nested_rooms(datum/world_edit_building_layout_state/state)
	if(!istype(state) || !istype(state.semantic_plan))
		return
	var/list/nested_specs = islist(state.semantic_plan.nested_room_specs) ? state.semantic_plan.nested_room_specs.Copy() : list()
	if(!length(nested_specs) && length("[state.semantic_plan.nested_inner_zone]"))
		nested_specs += new /datum/world_edit_building_nested_room_spec(state.semantic_plan.nested_outer_zone, state.semantic_plan.nested_inner_zone, state.semantic_plan.nested_min_width, state.semantic_plan.nested_min_height, 1)
	for(var/datum/world_edit_building_nested_room_spec/nested_spec as anything in nested_specs)
		if(!istype(nested_spec) || !length(nested_spec.outer_zone_id) || !length(nested_spec.inner_zone_id))
			continue
		if((state.bounds["width"] || 0) < nested_spec.min_width || (state.bounds["height"] || 0) < nested_spec.min_height)
			continue
		var/inner_width = max(3, round(nested_spec.min_width / 3))
		var/inner_height = max(3, round(nested_spec.min_height / 3))
		if(make_room_in_room(state, nested_spec.outer_zone_id, nested_spec.inner_zone_id, nested_spec.margin, inner_width, inner_height))
			state.nested_room_count++

/datum/world_edit_generator/building_layout/proc/make_room_in_room(datum/world_edit_building_layout_state/state, outer_zone_id, inner_zone_id, margin = 1, min_room_width = 3, min_room_height = 3)
	if(!istype(state) || !length("[outer_zone_id]") || !length("[inner_zone_id]"))
		return null
	var/list/outer_turfs = state.get_zone_turfs(outer_zone_id)
	if(length(outer_turfs) < min_room_width * min_room_height)
		return null
	margin = max(round(text2num("[margin]") || 1), 1)
	min_room_width = max(round(text2num("[min_room_width]") || 3), 3)
	min_room_height = max(round(text2num("[min_room_height]") || 3), 3)
	var/list/candidates = build_room_in_room_rect_candidates(state, outer_zone_id, outer_turfs, margin, min_room_width, min_room_height)
	var/list/best_candidate = null
	var/best_score = -999999999
	for(var/list/candidate as anything in candidates)
		if(!islist(candidate))
			continue
		var/score = round(text2num("[candidate["score"]]") || 0)
		if(!islist(best_candidate) || score > best_score)
			best_candidate = candidate
			best_score = score
	if(!islist(best_candidate))
		return null

	var/list/wall_turfs = best_candidate["wall_turfs"]
	var/list/inner_turfs = best_candidate["inner_turfs"]
	var/turf/internal_door_turf = best_candidate["door_turf"]
	var/door_dir = best_candidate["door_dir"] || state.placement_dir
	if(!islist(wall_turfs) || !islist(inner_turfs) || !istype(internal_door_turf))
		return null
	var/datum/world_edit_building_divider_plan/divider_plan = new("nested_[inner_zone_id]", outer_zone_id, inner_zone_id)
	for(var/turf/wall_turf as anything in wall_turfs)
		if(istype(wall_turf) && wall_turf != internal_door_turf)
			divider_plan.wall_turfs += wall_turf
	for(var/turf/inner_turf as anything in inner_turfs)
		if(istype(inner_turf))
			divider_plan.inner_turfs += inner_turf
	divider_plan.opening_turfs += internal_door_turf
	divider_plan.opening_dirs[internal_door_turf] = door_dir
	if(!divider_plan_keeps_floor_reachable(state, divider_plan))
		return null
	state.add_divider_plan(divider_plan)
	return divider_plan

/datum/world_edit_generator/building_layout/proc/build_room_in_room_rect_candidates(datum/world_edit_building_layout_state/state, outer_zone_id, list/outer_turfs, margin, min_room_width, min_room_height)
	var/list/candidates = list()
	var/min_x = 999999
	var/max_x = -999999
	var/min_y = 999999
	var/max_y = -999999
	for(var/turf/outer_turf as anything in outer_turfs)
		if(!istype(outer_turf))
			continue
		min_x = min(min_x, outer_turf.x)
		max_x = max(max_x, outer_turf.x)
		min_y = min(min_y, outer_turf.y)
		max_y = max(max_y, outer_turf.y)
	var/outer_width = (max_x - min_x) + 1
	var/outer_height = (max_y - min_y) + 1
	if(outer_width < min_room_width + margin || outer_height < min_room_height + margin)
		return candidates
	var/list/width_options = list(min_room_width)
	var/list/height_options = list(min_room_height)
	if(outer_width >= min_room_width + 2)
		width_options += min(min_room_width + 1, outer_width - margin)
	if(outer_height >= min_room_height + 2)
		height_options += min(min_room_height + 1, outer_height - margin)
	for(var/room_width as anything in width_options)
		for(var/room_height as anything in height_options)
			for(var/x1 in min_x to max_x - room_width + 1)
				for(var/y1 in min_y to max_y - room_height + 1)
					var/list/candidate = build_room_in_room_rect_candidate(state, outer_zone_id, x1, y1, x1 + room_width - 1, y1 + room_height - 1, margin)
					if(islist(candidate))
						candidates += list(candidate)
						if(length(candidates) >= WORLD_EDIT_BUILDING_MAX_ROOM_IN_ROOM_CANDIDATES)
							return candidates
	return candidates

/datum/world_edit_generator/building_layout/proc/build_room_in_room_rect_candidate(datum/world_edit_building_layout_state/state, outer_zone_id, x1, y1, x2, y2, margin)
	var/list/wall_turfs = list()
	var/list/inner_turfs = list()
	var/list/perimeter_turfs = list()
	var/turf/door_turf = null
	var/best_door_score = -999999999
	for(var/x in x1 to x2)
		for(var/y in y1 to y2)
			var/turf/check_turf = locate(x, y, state.bounds["z"])
			if(!state.footprint_lookup[check_turf] || state.boundary_lookup[check_turf] || state.wall_lookup[check_turf] || state.door_dirs[check_turf])
				return null
			if(state.get_zone(check_turf) != "[outer_zone_id]")
				return null
			var/is_perimeter = (x == x1 || x == x2 || y == y1 || y == y2)
			if(is_perimeter)
				if(state.reserved_lookup[check_turf])
					return null
				perimeter_turfs += check_turf
				var/score = 0
				if(istype(state.front_door_turf))
					score -= abs(check_turf.x - state.front_door_turf.x) + abs(check_turf.y - state.front_door_turf.y)
				if(istype(state.semantic_hub_turf))
					score -= round((abs(check_turf.x - state.semantic_hub_turf.x) + abs(check_turf.y - state.semantic_hub_turf.y)) / 2)
				if(!istype(door_turf) || score > best_door_score)
					door_turf = check_turf
					best_door_score = score
			else
				inner_turfs += check_turf
	for(var/x in (x1 - margin) to (x2 + margin))
		for(var/y in (y1 - margin) to (y2 + margin))
			if(x >= x1 && x <= x2 && y >= y1 && y <= y2)
				continue
			var/turf/margin_turf = locate(x, y, state.bounds["z"])
			if(!istype(margin_turf) || !state.footprint_lookup[margin_turf])
				continue
			if(state.wall_lookup[margin_turf] || state.boundary_lookup[margin_turf])
				return null
	if(!istype(door_turf) || !length(perimeter_turfs) || !length(inner_turfs))
		return null
	for(var/turf/perimeter_turf as anything in perimeter_turfs)
		if(perimeter_turf != door_turf)
			wall_turfs += perimeter_turf
	var/turf/center_turf = locate(round((x1 + x2) / 2), round((y1 + y2) / 2), state.bounds["z"])
	var/door_dir = get_cardinal_dir_toward(door_turf, state.semantic_hub_turf || state.front_door_turf || center_turf, state.placement_dir)
	var/score = 0
	if(istype(center_turf))
		score += get_building_front_percent(state, center_turf)
		score += abs(get_building_lateral_percent(state, center_turf)) / 3
	score += length(inner_turfs) * 8
	return list(
		"wall_turfs" = wall_turfs,
		"inner_turfs" = inner_turfs,
		"door_turf" = door_turf,
		"door_dir" = door_dir,
		"score" = score,
	)

/datum/world_edit_generator/building_layout/proc/build_building_walls_and_floors(datum/world_edit_building_layout_state/state)
	var/list/door_lookup = GLOB.world_edit_placement_shapes.world_edit_build_turf_lookup(state.door_turfs)
	var/list/window_lookup = GLOB.world_edit_placement_shapes.world_edit_build_turf_lookup(state.window_turfs)
	for(var/turf/footprint_turf as anything in state.footprint)
		if((state.boundary_lookup[footprint_turf] || state.wall_lookup[footprint_turf]) && !door_lookup[footprint_turf] && !window_lookup[footprint_turf])
			state.wall_lookup[footprint_turf] = TRUE
		else
			state.append_unique_turf(state.floor_turfs, footprint_turf)
	state.adjacent_wall_dirs_by_turf.Cut()
	state.floor_lookup = GLOB.world_edit_placement_shapes.world_edit_build_turf_lookup(state.floor_turfs)
	var/center_x = (state.bounds["min_x"] + state.bounds["max_x"]) / 2
	var/center_y = (state.bounds["min_y"] + state.bounds["max_y"]) / 2
	state.center_turf = select_center_floor_turf(state.floor_turfs, center_x, center_y) || state.front_door_turf
	refresh_building_zone_foci(state)
	state.semantic_hub_turf = state.get_zone_focus(state.semantic_plan?.hub_zone_id) || state.center_turf

/datum/world_edit_generator/building_layout/proc/build_building_reserved_lanes(datum/world_edit_building_layout_state/state)
	if(!istype(state.semantic_hub_turf))
		return
	var/list/exterior_door_turfs = list()
	for(var/turf/door_turf as anything in state.door_turfs)
		if(state.boundary_lookup[door_turf])
			exterior_door_turfs += door_turf
	if(!length(exterior_door_turfs))
		exterior_door_turfs = state.door_turfs
	var/list/reserved_path = build_reserved_paths(exterior_door_turfs, state.semantic_hub_turf, state.floor_lookup)
	for(var/turf/reserved_turf as anything in reserved_path)
		state.add_primary_route(reserved_turf)
	for(var/zone_id as anything in state.semantic_plan.mandatory_zones)
		var/turf/focus_turf = state.get_zone_focus(zone_id)
		if(!istype(focus_turf) || focus_turf == state.semantic_hub_turf)
			continue
		var/list/zone_path = build_reserved_path(state.semantic_hub_turf, focus_turf, state.floor_lookup)
		for(var/turf/path_turf as anything in zone_path)
			state.add_primary_route(path_turf)
