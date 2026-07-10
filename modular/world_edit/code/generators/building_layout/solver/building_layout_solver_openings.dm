/datum/world_edit_generator/building_layout/proc/add_building_layout_connection(datum/world_edit_building_layout_candidate/candidate, connection_id, from_room_id, to_room_id, privacy = "public", required = TRUE, kind = "door")
	if(!istype(candidate))
		return null
	var/datum/world_edit_building_layout_room_connection/connection = new(connection_id, from_room_id, to_room_id, privacy, required, kind)
	candidate.add_room_connection(connection)
	return connection

/datum/world_edit_generator/building_layout/proc/build_building_layout_candidate_lookups(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate)
	if(!istype(candidate))
		return
	refresh_building_layout_candidate_lookups(candidate)
	if(istype(context) && candidate.wall_model_ready)
		candidate.wall_lookup = candidate.solved_wall_lookup

/datum/world_edit_generator/building_layout/proc/get_building_layout_region_lookup(datum/world_edit_building_layout_candidate/candidate, region_id)
	var/list/lookup = list()
	if(!istype(candidate))
		return lookup
	if("[region_id]" == "route")
		return islist(candidate.route_lookup) && length(candidate.route_lookup) ? candidate.route_lookup : building_layout_candidate_route_lookup(candidate)
	var/datum/world_edit_building_layout_room_plan/room_plan = candidate.get_room_plan(region_id)
	if(istype(room_plan))
		return room_plan.turf_lookup
	return lookup

/datum/world_edit_generator/building_layout/proc/collect_building_layout_opening_candidates(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate, datum/world_edit_building_layout_room_connection/connection, datum/world_edit_building_layout_room_contract/room_contract = null)
	var/list/opening_candidates = list()
	if(!istype(context) || !istype(candidate) || !istype(connection))
		return opening_candidates
	if(!istype(room_contract))
		room_contract = get_building_layout_connection_room_contract(context, connection)
	var/list/from_lookup = get_building_layout_region_lookup(candidate, connection.from_room_id)
	var/list/to_lookup = get_building_layout_region_lookup(candidate, connection.to_room_id)
	if(!length(from_lookup) || !length(to_lookup))
		return opening_candidates
	var/opening_kind = get_building_layout_connection_opening_kind(context, connection, room_contract)
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
			if(!building_layout_opening_wall_matches_regions(context, candidate, from_lookup, to_lookup, opening_turf, door_dir))
				continue
			var/datum/world_edit_building_layout_opening_candidate/opening_candidate = new
			index++
			opening_candidate.id = "[connection.id]_[index]"
			opening_candidate.opening_turf = opening_turf
			opening_candidate.dir = door_dir
			opening_candidate.from_room_id = connection.from_room_id
			opening_candidate.to_room_id = connection.to_room_id
			opening_candidate.privacy = connection.privacy
			opening_candidate.segment_len = building_layout_shared_wall_run_length_for_regions(context, candidate, from_lookup, to_lookup, opening_turf, door_dir)
			var/opening_width = get_building_layout_connection_opening_width(room_contract, opening_kind, opening_candidate.segment_len)
			opening_candidate.opening_turfs = build_building_layout_opening_turf_run(context, candidate, from_lookup, to_lookup, opening_turf, door_dir, opening_width)
			opening_candidate.segment_center_distance = building_layout_shared_wall_segment_center_distance(context, candidate, from_lookup, to_lookup, opening_turf, door_dir)
			opening_candidate.corner = building_layout_opening_at_segment_end_for_regions(context, candidate, from_lookup, to_lookup, opening_turf, door_dir)
			var/avoid_near_opening = !istype(room_contract) || (room_contract.avoid_facing_route_doors && !room_contract.allow_public_route_merge)
			opening_candidate.near_other_door = avoid_near_opening && building_layout_opening_near_existing_door(candidate, opening_turf, 1, door_dir)
			opening_candidate.front_clear = building_layout_opening_side_clear(candidate, get_step(opening_turf, door_dir))
			opening_candidate.back_clear = building_layout_opening_side_clear(candidate, get_step(opening_turf, turn(door_dir, 180)))
			validate_building_layout_opening_candidate(context, candidate, connection, room_contract, opening_candidate)
			score_building_layout_opening_candidate(context, candidate, room_contract, opening_candidate)
			opening_candidates += opening_candidate
	return opening_candidates

/datum/world_edit_generator/building_layout/proc/select_best_building_layout_opening_candidate(list/opening_candidates)
	var/datum/world_edit_building_layout_opening_candidate/best = null
	var/best_score = -999999999
	if(!islist(opening_candidates))
		return null
	for(var/datum/world_edit_building_layout_opening_candidate/opening_candidate as anything in opening_candidates)
		if(!istype(opening_candidate) || length(opening_candidate.reject_reasons))
			continue
		if(!istype(best) || opening_candidate.score > best_score)
			best = opening_candidate
			best_score = opening_candidate.score
	return best

/datum/world_edit_generator/building_layout/proc/get_building_layout_connection_room_contract(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_room_connection/connection)
	if(!istype(context?.program_contract) || !istype(connection))
		return null
	var/room_id = connection.from_room_id == "route" ? connection.to_room_id : connection.from_room_id
	return context.program_contract.get_room_contract(room_id)

/datum/world_edit_generator/building_layout/proc/get_building_layout_connection_opening_kind(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_room_connection/connection, datum/world_edit_building_layout_room_contract/room_contract = null)
	var/opening_kind = WORLD_EDIT_BUILDING_OPENING_DOOR
	if(istype(room_contract) && length(room_contract.route_opening_kind))
		opening_kind = room_contract.route_opening_kind
	else if(length(connection?.kind))
		opening_kind = connection.kind
	if(opening_kind == WORLD_EDIT_BUILDING_OPENING_DOOR && istype(room_contract))
		switch(room_contract.partition_policy)
			if(WORLD_EDIT_BUILDING_PARTITION_OPEN)
				return WORLD_EDIT_BUILDING_OPENING_WIDE_ARCH
			if(WORLD_EDIT_BUILDING_PARTITION_SOFT)
				return WORLD_EDIT_BUILDING_OPENING_ARCH
	return opening_kind

/datum/world_edit_generator/building_layout/proc/get_building_layout_connection_opening_width(datum/world_edit_building_layout_room_contract/room_contract, opening_kind, segment_len)
	var/max_segment_width = max(round(text2num("[segment_len]") || 0), 0)
	if(max_segment_width <= 0 || opening_kind == WORLD_EDIT_BUILDING_OPENING_NONE)
		return 0
	if(!(opening_kind in list(WORLD_EDIT_BUILDING_OPENING_ARCH, WORLD_EDIT_BUILDING_OPENING_WIDE_ARCH)))
		return 1
	var/min_width = istype(room_contract) ? max(room_contract.min_route_opening_width, 1) : 1
	var/max_width = istype(room_contract) ? max(room_contract.max_route_opening_width, min_width) : min_width
	return min(max_width, max(min_width, min(max_segment_width, max_width)))

/datum/world_edit_generator/building_layout/proc/get_building_layout_opening_plan_room_contract(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_route_opening_plan/opening_plan)
	if(!istype(context?.program_contract) || !istype(opening_plan))
		return null
	var/room_id = "[opening_plan.from_room]"
	if(!length(room_id) || room_id == "route")
		room_id = "[opening_plan.to_room]"
	if(!length(room_id) || room_id == "route")
		return null
	return context.program_contract.get_room_contract(room_id)

/datum/world_edit_generator/building_layout/proc/building_layout_opening_plan_is_public(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_route_opening_plan/opening_plan)
	if(!istype(opening_plan) || opening_plan.kind == "main_exit")
		return FALSE
	var/datum/world_edit_building_layout_room_contract/room_contract = get_building_layout_opening_plan_room_contract(context, opening_plan)
	if(istype(room_contract))
		if(room_contract.partition_policy in list(WORLD_EDIT_BUILDING_PARTITION_CLOSED, WORLD_EDIT_BUILDING_PARTITION_SECURE))
			return FALSE
		if(room_contract.partition_policy in list(WORLD_EDIT_BUILDING_PARTITION_OPEN, WORLD_EDIT_BUILDING_PARTITION_SOFT))
			return TRUE
	if(opening_plan.kind in list(WORLD_EDIT_BUILDING_OPENING_ARCH, WORLD_EDIT_BUILDING_OPENING_WIDE_ARCH))
		return TRUE
	if(opening_plan.public_opening)
		return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/building_layout_opening_plan_emits_door_object(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_route_opening_plan/opening_plan)
	if(!istype(opening_plan))
		return FALSE
	if(opening_plan.kind == "main_exit")
		return TRUE
	var/datum/world_edit_building_layout_room_contract/room_contract = get_building_layout_opening_plan_room_contract(context, opening_plan)
	if(istype(room_contract))
		if(room_contract.partition_policy in list(WORLD_EDIT_BUILDING_PARTITION_CLOSED, WORLD_EDIT_BUILDING_PARTITION_SECURE))
			return TRUE
		if(room_contract.partition_policy in list(WORLD_EDIT_BUILDING_PARTITION_OPEN, WORLD_EDIT_BUILDING_PARTITION_SOFT))
			return FALSE
	if(building_layout_opening_plan_is_public(context, opening_plan))
		return FALSE
	return opening_plan.kind in list(WORLD_EDIT_BUILDING_OPENING_DOOR, WORLD_EDIT_BUILDING_OPENING_SECURE_DOOR)

/datum/world_edit_generator/building_layout/proc/build_building_layout_opening_turf_run(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate, list/from_lookup, list/to_lookup, turf/opening_turf, door_dir, opening_width)
	var/list/opening_turfs = list()
	var/width = max(round(text2num("[opening_width]") || 0), 0)
	if(width <= 0 || !building_layout_opening_wall_matches_regions(context, candidate, from_lookup, to_lookup, opening_turf, door_dir))
		return opening_turfs
	var/list/segment = list(opening_turf)
	var/turf/check_turf = get_step(opening_turf, turn(door_dir, 90))
	while(building_layout_opening_wall_matches_regions(context, candidate, from_lookup, to_lookup, check_turf, door_dir))
		segment.Insert(1, check_turf)
		check_turf = get_step(check_turf, turn(door_dir, 90))
	check_turf = get_step(opening_turf, turn(door_dir, -90))
	while(building_layout_opening_wall_matches_regions(context, candidate, from_lookup, to_lookup, check_turf, door_dir))
		segment += check_turf
		check_turf = get_step(check_turf, turn(door_dir, -90))
	if(length(segment) < width)
		return opening_turfs
	var/center_index = max(segment.Find(opening_turf), 1)
	var/start_index = clamp(center_index - round((width - 1) / 2), 1, length(segment) - width + 1)
	for(var/index in start_index to start_index + width - 1)
		opening_turfs += segment[index]
	return opening_turfs

/datum/world_edit_generator/building_layout/proc/configure_building_layout_opening_plan(datum/world_edit_building_layout_route_opening_plan/opening_plan, list/opening_turfs, opening_kind)
	if(!istype(opening_plan))
		return
	if(islist(opening_turfs) && length(opening_turfs))
		opening_plan.opening_turfs = opening_turfs.Copy()
	else if(istype(opening_plan.opening_turf))
		opening_plan.opening_turfs = list(opening_plan.opening_turf)
	opening_plan.opening_width = max(length(opening_plan.opening_turfs), 1)
	opening_plan.kind = length("[opening_kind]") ? "[opening_kind]" : opening_plan.kind
	opening_plan.public_opening = opening_plan.kind in list(WORLD_EDIT_BUILDING_OPENING_ARCH, WORLD_EDIT_BUILDING_OPENING_WIDE_ARCH)
	opening_plan.emits_door_object = opening_plan.kind in list(WORLD_EDIT_BUILDING_OPENING_DOOR, WORLD_EDIT_BUILDING_OPENING_SECURE_DOOR, "main_exit")

/datum/world_edit_generator/building_layout/proc/get_building_layout_opening_plan_turfs(datum/world_edit_building_layout_route_opening_plan/opening_plan)
	var/list/opening_turfs = list()
	if(!istype(opening_plan))
		return opening_turfs
	if(islist(opening_plan.opening_turfs) && length(opening_plan.opening_turfs))
		return opening_plan.opening_turfs.Copy()
	if(istype(opening_plan.opening_turf))
		opening_turfs += opening_plan.opening_turf
	return opening_turfs

/datum/world_edit_generator/building_layout/proc/validate_building_layout_opening_candidate(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate, datum/world_edit_building_layout_room_connection/connection, datum/world_edit_building_layout_room_contract/room_contract, datum/world_edit_building_layout_opening_candidate/opening_candidate)
	if(!istype(opening_candidate?.opening_turf))
		opening_candidate.reject_reasons += "missing_turf"
		return
	var/min_segment_length = max(connection?.min_shared_wall_length || 3, 1)
	if(istype(room_contract))
		min_segment_length = max(min_segment_length, room_contract.min_route_opening_width)
	if(opening_candidate.segment_len < min_segment_length)
		opening_candidate.reject_reasons += "short_segment"
	if(opening_candidate.segment_len > 0 && !length(opening_candidate.opening_turfs))
		opening_candidate.reject_reasons += "opening_width"
	if(opening_candidate.corner && !connection?.allow_corner)
		opening_candidate.reject_reasons += "corner"
	if(opening_candidate.near_other_door)
		opening_candidate.reject_reasons += "near_other_door"
	if(!opening_candidate.front_clear)
		opening_candidate.reject_reasons += "front_blocked"
	if(!opening_candidate.back_clear)
		opening_candidate.reject_reasons += "back_blocked"

/datum/world_edit_generator/building_layout/proc/score_building_layout_opening_candidate(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate, datum/world_edit_building_layout_room_contract/room_contract, datum/world_edit_building_layout_opening_candidate/opening_candidate)
	if(!istype(opening_candidate))
		return 0
	var/score = 0
	score += opening_candidate.segment_len * 20
	if(istype(room_contract) && room_contract.partition_policy in list(WORLD_EDIT_BUILDING_PARTITION_OPEN, WORLD_EDIT_BUILDING_PARTITION_SOFT))
		score += length(opening_candidate.opening_turfs) * 220
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

/datum/world_edit_generator/building_layout/proc/building_layout_opening_wall_matches_regions(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate, list/from_lookup, list/to_lookup, turf/opening_turf, door_dir)
	if(!istype(context?.state) || !istype(candidate) || !islist(from_lookup) || !islist(to_lookup) || !istype(opening_turf) || !(door_dir in GLOB.cardinals))
		return FALSE
	if(!context.state.geometry.footprint_lookup[opening_turf] || context.state.geometry.boundary_lookup[opening_turf])
		return FALSE
	if(building_layout_opening_turf_is_room_or_route(candidate, opening_turf))
		return FALSE
	var/turf/from_turf = get_step(opening_turf, door_dir)
	var/turf/to_turf = get_step(opening_turf, turn(door_dir, 180))
	return from_lookup[from_turf] && to_lookup[to_turf]

/datum/world_edit_generator/building_layout/proc/building_layout_shared_wall_run_length_for_regions(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate, list/from_lookup, list/to_lookup, turf/opening_turf, door_dir)
	if(!building_layout_opening_wall_matches_regions(context, candidate, from_lookup, to_lookup, opening_turf, door_dir))
		return 0
	var/run_length = 1
	for(var/axis_dir in list(turn(door_dir, 90), turn(door_dir, -90)))
		var/turf/check_turf = get_step(opening_turf, axis_dir)
		while(building_layout_opening_wall_matches_regions(context, candidate, from_lookup, to_lookup, check_turf, door_dir))
			run_length++
			check_turf = get_step(check_turf, axis_dir)
	return run_length

/datum/world_edit_generator/building_layout/proc/building_layout_shared_wall_segment_center_distance(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate, list/from_lookup, list/to_lookup, turf/opening_turf, door_dir)
	if(!building_layout_opening_wall_matches_regions(context, candidate, from_lookup, to_lookup, opening_turf, door_dir))
		return 999
	var/left_count = 0
	var/turf/check_turf = get_step(opening_turf, turn(door_dir, 90))
	while(building_layout_opening_wall_matches_regions(context, candidate, from_lookup, to_lookup, check_turf, door_dir))
		left_count++
		check_turf = get_step(check_turf, turn(door_dir, 90))
	var/right_count = 0
	check_turf = get_step(opening_turf, turn(door_dir, -90))
	while(building_layout_opening_wall_matches_regions(context, candidate, from_lookup, to_lookup, check_turf, door_dir))
		right_count++
		check_turf = get_step(check_turf, turn(door_dir, -90))
	return abs(left_count - right_count)

/datum/world_edit_generator/building_layout/proc/building_layout_opening_at_segment_end_for_regions(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate, list/from_lookup, list/to_lookup, turf/opening_turf, door_dir)
	if(!building_layout_opening_wall_matches_regions(context, candidate, from_lookup, to_lookup, opening_turf, door_dir))
		return TRUE
	for(var/axis_dir in list(turn(door_dir, 90), turn(door_dir, -90)))
		if(!building_layout_opening_wall_matches_regions(context, candidate, from_lookup, to_lookup, get_step(opening_turf, axis_dir), door_dir))
			return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/building_layout_opening_near_existing_door(datum/world_edit_building_layout_candidate/candidate, turf/opening_turf, radius = 2, door_dir = null)
	if(!istype(candidate) || !istype(opening_turf))
		return FALSE
	for(var/datum/world_edit_building_layout_route_opening_plan/door_plan as anything in candidate.opening_plans)
		if(!istype(door_plan) || door_plan.public_opening)
			continue
		for(var/turf/existing_turf as anything in get_building_layout_opening_plan_turfs(door_plan))
			if(istype(existing_turf) && get_dist(opening_turf, existing_turf) <= radius)
				if(building_layout_openings_are_opposite_route_pair(candidate, opening_turf, door_dir, existing_turf, door_plan.dir))
					continue
				return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/building_layout_openings_are_opposite_route_pair(datum/world_edit_building_layout_candidate/candidate, turf/a, a_dir, turf/b, b_dir)
	if(!istype(candidate) || !istype(a) || !istype(b) || !(a_dir in GLOB.cardinals) || !(b_dir in GLOB.cardinals))
		return FALSE
	if(get_dist(a, b) != 2 || turn(a_dir, 180) != b_dir)
		return FALSE
	var/mid_x = round((a.x + b.x) / 2)
	var/mid_y = round((a.y + b.y) / 2)
	var/turf/mid_turf = locate(mid_x, mid_y, a.z)
	return candidate.route_lookup[mid_turf] ? TRUE : FALSE

/datum/world_edit_generator/building_layout/proc/building_layout_opening_side_clear(datum/world_edit_building_layout_candidate/candidate, turf/check_turf)
	if(!istype(candidate) || !istype(check_turf))
		return FALSE
	if(candidate.route_lookup[check_turf])
		return TRUE
	for(var/datum/world_edit_building_layout_room_plan/room_plan as anything in candidate.room_plans)
		if(istype(room_plan) && room_plan.has_turf(check_turf))
			return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/opening_exposes_private_room(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate, datum/world_edit_building_layout_opening_candidate/opening_candidate)
	if(!istype(candidate) || !istype(opening_candidate?.opening_turf))
		return FALSE
	for(var/datum/world_edit_building_layout_route_opening_plan/door_plan as anything in candidate.opening_plans)
		if(istype(door_plan?.opening_turf) && door_plan.kind == "main_exit" && get_dist(opening_candidate.opening_turf, door_plan.opening_turf) <= 4)
			return TRUE
	return FALSE
