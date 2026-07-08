/datum/world_edit_generator/building_layout/proc/add_building_v2_connection(datum/world_edit_building_v2_layout_candidate/candidate, connection_id, from_room_id, to_room_id, privacy = "public", required = TRUE, kind = "door")
	if(!istype(candidate))
		return null
	var/datum/world_edit_building_v2_room_connection/connection = new(connection_id, from_room_id, to_room_id, privacy, required, kind)
	candidate.add_room_connection(connection)
	return connection

/datum/world_edit_generator/building_layout/proc/build_building_v2_candidate_lookups(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate)
	if(!istype(candidate))
		return
	refresh_building_v2_candidate_lookups(candidate)
	if(istype(context) && candidate.wall_model_ready)
		candidate.wall_lookup = candidate.solved_wall_lookup

/datum/world_edit_generator/building_layout/proc/get_building_v2_region_lookup(datum/world_edit_building_v2_layout_candidate/candidate, region_id)
	var/list/lookup = list()
	if(!istype(candidate))
		return lookup
	if("[region_id]" == "route")
		return islist(candidate.route_lookup) && length(candidate.route_lookup) ? candidate.route_lookup : building_v2_candidate_route_lookup(candidate)
	var/datum/world_edit_building_v2_room_plan/room_plan = candidate.get_room_plan(region_id)
	if(istype(room_plan))
		return room_plan.turf_lookup
	return lookup

/datum/world_edit_generator/building_layout/proc/collect_building_v2_door_candidates(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, datum/world_edit_building_v2_room_connection/connection)
	var/list/opening_candidates = list()
	if(!istype(context) || !istype(candidate) || !istype(connection))
		return opening_candidates
	var/list/from_lookup = get_building_v2_region_lookup(candidate, connection.from_room_id)
	var/list/to_lookup = get_building_v2_region_lookup(candidate, connection.to_room_id)
	if(!length(from_lookup) || !length(to_lookup))
		return opening_candidates
	var/index = 0
	for(var/turf/from_turf as anything in from_lookup)
		if(!istype(from_turf))
			continue
		for(var/room_to_wall_dir as anything in GLOB.cardinals)
			var/turf/opening_turf = get_step(from_turf, room_to_wall_dir)
			var/turf/to_turf = get_step(opening_turf, room_to_wall_dir)
			if(!to_lookup[to_turf])
				continue
			var/door_dir = turn(room_to_wall_dir, 180)
			if(!building_v2_opening_wall_matches_regions(context, candidate, from_lookup, to_lookup, opening_turf, door_dir))
				continue
			var/datum/world_edit_building_v2_opening_candidate/opening_candidate = new
			index++
			opening_candidate.id = "[connection.id]_[index]"
			opening_candidate.opening_turf = opening_turf
			opening_candidate.dir = door_dir
			opening_candidate.from_room_id = connection.from_room_id
			opening_candidate.to_room_id = connection.to_room_id
			opening_candidate.privacy = connection.privacy
			opening_candidate.segment_len = building_v2_shared_wall_run_length_for_regions(context, candidate, from_lookup, to_lookup, opening_turf, door_dir)
			opening_candidate.segment_center_distance = building_v2_shared_wall_segment_center_distance(context, candidate, from_lookup, to_lookup, opening_turf, door_dir)
			opening_candidate.corner = building_v2_opening_at_segment_end_for_regions(context, candidate, from_lookup, to_lookup, opening_turf, door_dir)
			opening_candidate.near_other_door = building_v2_opening_near_existing_door(candidate, opening_turf, 1, door_dir)
			opening_candidate.front_clear = building_v2_opening_side_clear(candidate, get_step(opening_turf, door_dir))
			opening_candidate.back_clear = building_v2_opening_side_clear(candidate, get_step(opening_turf, turn(door_dir, 180)))
			validate_building_v2_opening_candidate(context, candidate, connection, opening_candidate)
			score_building_v2_opening_candidate(context, candidate, opening_candidate)
			opening_candidates += opening_candidate
	return opening_candidates

/datum/world_edit_generator/building_layout/proc/select_best_building_v2_opening_candidate(list/opening_candidates)
	var/datum/world_edit_building_v2_opening_candidate/best = null
	var/best_score = -999999999
	if(!islist(opening_candidates))
		return null
	for(var/datum/world_edit_building_v2_opening_candidate/opening_candidate as anything in opening_candidates)
		if(!istype(opening_candidate) || length(opening_candidate.reject_reasons))
			continue
		if(!istype(best) || opening_candidate.score > best_score)
			best = opening_candidate
			best_score = opening_candidate.score
	return best

/datum/world_edit_generator/building_layout/proc/validate_building_v2_opening_candidate(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, datum/world_edit_building_v2_room_connection/connection, datum/world_edit_building_v2_opening_candidate/opening_candidate)
	if(!istype(opening_candidate?.opening_turf))
		opening_candidate.reject_reasons += "missing_turf"
		return
	if(opening_candidate.segment_len < max(connection?.min_shared_wall_length || 3, 1))
		opening_candidate.reject_reasons += "short_segment"
	if(opening_candidate.corner && !connection?.allow_corner)
		opening_candidate.reject_reasons += "corner"
	if(opening_candidate.near_other_door)
		opening_candidate.reject_reasons += "near_other_door"
	if(!opening_candidate.front_clear)
		opening_candidate.reject_reasons += "front_blocked"
	if(!opening_candidate.back_clear)
		opening_candidate.reject_reasons += "back_blocked"

/datum/world_edit_generator/building_layout/proc/score_building_v2_opening_candidate(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, datum/world_edit_building_v2_opening_candidate/opening_candidate)
	if(!istype(opening_candidate))
		return 0
	var/score = 0
	score += opening_candidate.segment_len * 20
	score -= opening_candidate.segment_center_distance * 15
	if(opening_candidate.front_clear && opening_candidate.back_clear)
		score += 300
	if(opening_candidate.privacy == "private")
		score -= opening_exposes_private_room(context, candidate, opening_candidate) ? 400 : 0
	if(opening_candidate.corner)
		score -= 10000
	if(opening_candidate.near_other_door)
		score -= 1000
	opening_candidate.score = score
	return score

/datum/world_edit_generator/building_layout/proc/building_v2_opening_wall_matches_regions(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, list/from_lookup, list/to_lookup, turf/opening_turf, door_dir)
	if(!istype(context?.state) || !istype(candidate) || !islist(from_lookup) || !islist(to_lookup) || !istype(opening_turf) || !(door_dir in GLOB.cardinals))
		return FALSE
	if(!context.state.geometry.footprint_lookup[opening_turf] || context.state.geometry.boundary_lookup[opening_turf])
		return FALSE
	if(building_v2_opening_turf_is_room_or_route(candidate, opening_turf))
		return FALSE
	var/turf/from_turf = get_step(opening_turf, door_dir)
	var/turf/to_turf = get_step(opening_turf, turn(door_dir, 180))
	return from_lookup[from_turf] && to_lookup[to_turf]

/datum/world_edit_generator/building_layout/proc/building_v2_shared_wall_run_length_for_regions(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, list/from_lookup, list/to_lookup, turf/opening_turf, door_dir)
	if(!building_v2_opening_wall_matches_regions(context, candidate, from_lookup, to_lookup, opening_turf, door_dir))
		return 0
	var/run_length = 1
	for(var/axis_dir in list(turn(door_dir, 90), turn(door_dir, -90)))
		var/turf/check_turf = get_step(opening_turf, axis_dir)
		while(building_v2_opening_wall_matches_regions(context, candidate, from_lookup, to_lookup, check_turf, door_dir))
			run_length++
			check_turf = get_step(check_turf, axis_dir)
	return run_length

/datum/world_edit_generator/building_layout/proc/building_v2_shared_wall_segment_center_distance(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, list/from_lookup, list/to_lookup, turf/opening_turf, door_dir)
	if(!building_v2_opening_wall_matches_regions(context, candidate, from_lookup, to_lookup, opening_turf, door_dir))
		return 999
	var/left_count = 0
	var/turf/check_turf = get_step(opening_turf, turn(door_dir, 90))
	while(building_v2_opening_wall_matches_regions(context, candidate, from_lookup, to_lookup, check_turf, door_dir))
		left_count++
		check_turf = get_step(check_turf, turn(door_dir, 90))
	var/right_count = 0
	check_turf = get_step(opening_turf, turn(door_dir, -90))
	while(building_v2_opening_wall_matches_regions(context, candidate, from_lookup, to_lookup, check_turf, door_dir))
		right_count++
		check_turf = get_step(check_turf, turn(door_dir, -90))
	return abs(left_count - right_count)

/datum/world_edit_generator/building_layout/proc/building_v2_opening_at_segment_end_for_regions(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, list/from_lookup, list/to_lookup, turf/opening_turf, door_dir)
	if(!building_v2_opening_wall_matches_regions(context, candidate, from_lookup, to_lookup, opening_turf, door_dir))
		return TRUE
	for(var/axis_dir in list(turn(door_dir, 90), turn(door_dir, -90)))
		if(!building_v2_opening_wall_matches_regions(context, candidate, from_lookup, to_lookup, get_step(opening_turf, axis_dir), door_dir))
			return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/building_v2_opening_near_existing_door(datum/world_edit_building_v2_layout_candidate/candidate, turf/opening_turf, radius = 2, door_dir = null)
	if(!istype(candidate) || !istype(opening_turf))
		return FALSE
	for(var/datum/world_edit_building_v2_route_opening_plan/door_plan as anything in candidate.door_plans)
		if(istype(door_plan?.opening_turf) && get_dist(opening_turf, door_plan.opening_turf) <= radius)
			if(building_v2_openings_are_opposite_route_pair(candidate, opening_turf, door_dir, door_plan.opening_turf, door_plan.dir))
				continue
			return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/building_v2_openings_are_opposite_route_pair(datum/world_edit_building_v2_layout_candidate/candidate, turf/a, a_dir, turf/b, b_dir)
	if(!istype(candidate) || !istype(a) || !istype(b) || !(a_dir in GLOB.cardinals) || !(b_dir in GLOB.cardinals))
		return FALSE
	if(get_dist(a, b) != 2 || turn(a_dir, 180) != b_dir)
		return FALSE
	var/mid_x = round((a.x + b.x) / 2)
	var/mid_y = round((a.y + b.y) / 2)
	var/turf/mid_turf = locate(mid_x, mid_y, a.z)
	return candidate.route_lookup[mid_turf] ? TRUE : FALSE

/datum/world_edit_generator/building_layout/proc/building_v2_opening_side_clear(datum/world_edit_building_v2_layout_candidate/candidate, turf/check_turf)
	if(!istype(candidate) || !istype(check_turf))
		return FALSE
	if(candidate.route_lookup[check_turf])
		return TRUE
	for(var/datum/world_edit_building_v2_room_plan/room_plan as anything in candidate.room_plans)
		if(istype(room_plan) && room_plan.has_turf(check_turf))
			return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/opening_exposes_private_room(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, datum/world_edit_building_v2_opening_candidate/opening_candidate)
	if(!istype(candidate) || !istype(opening_candidate?.opening_turf))
		return FALSE
	for(var/datum/world_edit_building_v2_route_opening_plan/door_plan as anything in candidate.door_plans)
		if(istype(door_plan?.opening_turf) && door_plan.kind == "main_exit" && get_dist(opening_candidate.opening_turf, door_plan.opening_turf) <= 4)
			return TRUE
	return FALSE
