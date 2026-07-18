/datum/world_edit_generator/building_layout/proc/solve_building_layout_terminal_route_network(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate)
	var/datum/world_edit_building_layout_state/state = context?.state
	if(!istype(state) || !istype(candidate) || !length(candidate.room_plans))
		return FALSE
	var/turf/entry_seed = find_building_layout_route_entry_seed(context, candidate)
	if(!istype(entry_seed))
		candidate.errors += "route.entry_terminal_missing"
		return FALSE
	candidate.add_route_turf(entry_seed)
	candidate.route_owner_by_turf[entry_seed] = "route"
	var/list/terminal_room_ids = build_building_layout_route_terminal_set(candidate)
	var/list/remaining_terminal_ids = terminal_room_ids.Copy()
	while(length(remaining_terminal_ids))
		var/best_index = 0
		var/establishing_main_segment = !length(candidate.access_reservations_by_room)
		var/best_cost = establishing_main_segment ? -1 : 999999999
		var/list/terminal = null
		var/datum/world_edit_building_layout_room_plan/room_plan = null
		for(var/terminal_index in 1 to length(remaining_terminal_ids))
			var/room_id = remaining_terminal_ids[terminal_index]
			var/datum/world_edit_building_layout_room_plan/indexed_room_plan = candidate.get_room_plan(room_id)
			var/datum/world_edit_building_layout_room_contract/room_contract = context.program_contract?.get_room_contract(room_id)
			if(!istype(indexed_room_plan) || !istype(room_contract))
				continue
			var/list/indexed_terminal = find_building_layout_terminal_route(context, candidate, indexed_room_plan, room_contract)
			if(!islist(indexed_terminal))
				continue
			var/indexed_cost = round(text2num("[indexed_terminal["cost"]]") || 0)
			if(!islist(terminal) || (establishing_main_segment ? indexed_cost > best_cost : indexed_cost < best_cost))
				best_index = terminal_index
				best_cost = indexed_cost
				terminal = indexed_terminal
				room_plan = indexed_room_plan
		if(!best_index || !islist(terminal) || !istype(room_plan))
			for(var/room_id as anything in remaining_terminal_ids)
				var/datum/world_edit_building_layout_room_plan/unreachable_room = candidate.get_room_plan(room_id)
				candidate.errors += "route.terminal_unreachable:[room_id]"
				context.state.add_stage_report("layout_route_terminal", "failed", "bounded A* could not connect terminal", list(
					"candidate_id" = candidate.id,
					"room_id" = room_id,
					"entry_x" = entry_seed.x,
					"entry_y" = entry_seed.y,
					"room_x1" = unreachable_room?.x1,
					"room_y1" = unreachable_room?.y1,
					"room_x2" = unreachable_room?.x2,
					"room_y2" = unreachable_room?.y2,
					"route_count" = length(candidate.route_turfs),
					"frontage_options" = count_building_layout_terminal_frontage_options(context, candidate, unreachable_room, context.program_contract?.get_room_contract(room_id)),
				))
			break
		var/room_id = remaining_terminal_ids[best_index]
		remaining_terminal_ids.Cut(best_index, best_index + 1)
		var/list/path = terminal["path"]
		var/list/route_run = terminal["route_run"]
		var/list/wall_run = terminal["wall_run"]
		for(var/turf/path_turf as anything in path)
			candidate.add_route_turf(path_turf)
			candidate.route_owner_by_turf[path_turf] = "route"
		for(var/turf/route_turf as anything in route_run)
			candidate.add_route_turf(route_turf)
			candidate.route_owner_by_turf[route_turf] = "route"
		if(!candidate.reserve_route_access(room_id, wall_run, route_run, path))
			candidate.errors += "route.terminal_reservation_failed:[room_id]"
		context.state.add_stage_report("layout_route_terminal", "ok", null, list("candidate_id" = candidate.id, "room_id" = room_id, "wall_run" = length(wall_run), "route_run" = length(route_run), "path" = length(path), "cost" = best_cost))
	prune_building_layout_route_branches(candidate, entry_seed, terminal_room_ids)
	if(!assign_building_layout_route_overlay_ownership(context, candidate, entry_seed))
		candidate.errors += "route.overlay_ownership_failed"
	return !length(candidate.errors) && building_layout_route_turfs_are_connected(candidate)

/datum/world_edit_generator/building_layout/proc/assign_building_layout_route_overlay_ownership(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate, turf/entry_seed)
	if(!istype(context) || !istype(candidate) || !istype(entry_seed) || !length(candidate.route_turfs))
		return FALSE
	candidate.route_zone_by_turf.Cut()
	var/datum/world_edit_building_layout_room_contract/entry_contract = null
	var/datum/world_edit_building_layout_room_contract/default_contract = null
	for(var/datum/world_edit_building_layout_room_contract/circulation_contract as anything in context.program_contract?.circulation_contracts)
		if(!istype(circulation_contract) || !circulation_contract.required)
			continue
		if(circulation_contract.role == "entry" && !istype(entry_contract))
			entry_contract = circulation_contract
		else if(!istype(default_contract))
			default_contract = circulation_contract
	if(!istype(default_contract))
		default_contract = entry_contract
	if(!istype(default_contract))
		return FALSE
	// Terminal paths carry the identity of their authored circulation endpoint.
	// This keeps the route overlay owner-bound without turning every room into a
	// synthetic room -> route edge.
	for(var/room_id as anything in candidate.access_reservations_by_room)
		var/datum/world_edit_building_layout_room_contract/route_contract = get_building_layout_terminal_circulation_contract(context.program_contract, room_id)
		if(!istype(route_contract))
			route_contract = default_contract
		var/list/reservation = candidate.access_reservations_by_room[room_id]
		for(var/reservation_key as anything in list("connector_run", "route_run"))
			for(var/turf/route_turf as anything in reservation?[reservation_key])
				if(istype(route_turf) && candidate.route_lookup[route_turf])
					candidate.route_zone_by_turf[route_turf] = route_contract.zone_id
	// The entry terminal owns the connected prefix at the authored facade.
	if(istype(entry_contract))
		var/entry_claim_count = 0
		for(var/turf/route_turf as anything in candidate.route_turfs)
			if(!istype(route_turf) || !candidate.route_lookup[route_turf])
				continue
			candidate.route_zone_by_turf[route_turf] = entry_contract.zone_id
			entry_claim_count++
			if(entry_claim_count >= max(entry_contract.min_area, 1))
				break
	for(var/turf/route_turf as anything in candidate.route_turfs)
		if(!istype(route_turf) || !candidate.route_lookup[route_turf])
			continue
		if(!length("[candidate.route_zone_by_turf[route_turf] || ""]"))
			candidate.route_zone_by_turf[route_turf] = default_contract.zone_id
		candidate.route_owner_by_turf[route_turf] = candidate.route_zone_by_turf[route_turf]
	for(var/datum/world_edit_building_layout_room_contract/circulation_contract as anything in context.program_contract?.circulation_contracts)
		if(!istype(circulation_contract) || !circulation_contract.required)
			continue
		var/owned_count = 0
		for(var/turf/route_turf as anything in candidate.route_zone_by_turf)
			if(candidate.route_zone_by_turf[route_turf] == circulation_contract.zone_id)
				owned_count++
		if(owned_count < max(circulation_contract.min_area, 1))
			candidate.errors += "route.overlay_underfill:[circulation_contract.zone_id]:[owned_count]/[circulation_contract.min_area]"
	return !length(candidate.errors)

/datum/world_edit_generator/building_layout/proc/get_building_layout_terminal_circulation_contract(datum/world_edit_building_layout_program_contract/program, room_id)
	if(!istype(program) || !istype(program.topology_graph))
		return null
	for(var/datum/world_edit_building_layout_topology_edge/edge as anything in program.topology_graph.get_edges_for(room_id))
		if(!istype(edge) || !edge.required || edge.kind != WORLD_EDIT_BUILDING_EDGE_ROUTE)
			continue
		var/other_id = edge.from_id == room_id ? edge.to_id : edge.from_id
		var/datum/world_edit_building_layout_room_contract/other_contract = program.get_room_contract(other_id)
		if(istype(other_contract) && !other_contract.counts_toward_target)
			return other_contract
	return null

/datum/world_edit_generator/building_layout/proc/count_building_layout_terminal_frontage_options(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate, datum/world_edit_building_layout_room_plan/room_plan, datum/world_edit_building_layout_room_contract/room_contract)
	if(!istype(context) || !istype(candidate) || !istype(room_plan) || !istype(room_contract))
		return 0
	var/list/width_attempts = list(1)
	if(room_contract.min_route_opening_width > 1 || room_plan.spatial_kind == WORLD_EDIT_BUILDING_SPACE_OPEN_BAY || (room_contract.route_opening_kind in list(WORLD_EDIT_BUILDING_OPENING_ARCH, WORLD_EDIT_BUILDING_OPENING_WIDE_ARCH)))
		width_attempts += 2
	var/options = 0
	for(var/route_width as anything in width_attempts)
		var/list/axis_offsets = route_width == 2 ? list(0, 1) : list(0)
		for(var/turf/room_turf as anything in room_plan.turfs)
			for(var/check_dir in GLOB.cardinals)
				var/valid = TRUE
				for(var/axis_offset as anything in axis_offsets)
					var/turf/run_room_turf = axis_offset ? get_step(room_turf, turn(check_dir, 90)) : room_turf
					var/turf/wall_turf = get_step(run_room_turf, check_dir)
					var/turf/route_turf = get_step(wall_turf, check_dir)
					if(!room_plan.turf_lookup[run_room_turf] || !building_layout_route_turf_is_free(context, candidate, wall_turf, room_plan) || !building_layout_route_turf_is_free(context, candidate, route_turf, room_plan) || candidate.route_lookup[wall_turf] || candidate.access_reserved_lookup[wall_turf])
						valid = FALSE
						break
				if(valid)
					options++
	return options

/datum/world_edit_generator/building_layout/proc/find_building_layout_route_entry_seed(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate)
	var/datum/world_edit_building_layout_state/state = context?.state
	if(!istype(state) || !istype(candidate))
		return null
	var/entry_dir = state.geometry.requested_direction || state.placement_dir || NORTH
	if(!(entry_dir in GLOB.cardinals))
		entry_dir = NORTH
	var/turf/center_turf = context.local_turf(round((context.local_width() + 1) / 2), round((context.local_height() + 1) / 2))
	var/turf/best = null
	var/best_distance = 999999
	for(var/turf/boundary_turf as anything in state.geometry.boundary)
		if(!istype(boundary_turf) || !boundary_turf_has_outside_dir(boundary_turf, state.geometry.footprint_lookup, entry_dir) || is_corner_boundary_turf(boundary_turf, state.geometry.footprint_lookup))
			continue
		var/turf/inside_turf = get_step(boundary_turf, turn(entry_dir, 180))
		if(!building_layout_route_turf_is_free(context, candidate, inside_turf, null))
			continue
		// get_dist() is Chebyshev distance. Every cell on a square boundary can
		// therefore tie against the center and make iteration order select a
		// corner-side entry. Manhattan distance preserves the authored entry
		// face while selecting its actual center terminal.
		var/distance = istype(center_turf) ? abs(inside_turf.x - center_turf.x) + abs(inside_turf.y - center_turf.y) : 0
		if(!istype(best) || distance < best_distance)
			best = inside_turf
			best_distance = distance
	return best

/datum/world_edit_generator/building_layout/proc/build_building_layout_route_terminal_set(datum/world_edit_building_layout_candidate/candidate)
	var/list/result = list()
	if(!istype(candidate))
		return result
	for(var/datum/world_edit_building_layout_room_connection/connection as anything in candidate.room_connections)
		if(!istype(connection) || !connection.required)
			continue
		if(connection.from_room_id == "route" && length(connection.to_room_id))
			result |= connection.to_room_id
		else if(connection.to_room_id == "route" && length(connection.from_room_id))
			result |= connection.from_room_id
	return result

/datum/world_edit_generator/building_layout/proc/find_building_layout_terminal_route(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate, datum/world_edit_building_layout_room_plan/room_plan, datum/world_edit_building_layout_room_contract/room_contract)
	if(!istype(context) || !istype(candidate) || !istype(room_plan) || !istype(room_contract))
		return null
	var/list/width_attempts = list(1)
	if(room_contract.min_route_opening_width > 1)
		width_attempts += 2
	var/transition_width = 1
	if(room_plan.spatial_kind == WORLD_EDIT_BUILDING_SPACE_OPEN_BAY || (room_contract.route_opening_kind in list(WORLD_EDIT_BUILDING_OPENING_ARCH, WORLD_EDIT_BUILDING_OPENING_WIDE_ARCH)))
		transition_width = 2
	if(transition_width > 1 && !width_attempts.Find(2))
		width_attempts += 2
	for(var/route_width as anything in width_attempts)
		var/list/axis_offsets = route_width == 2 ? list(0, 1) : list(0)
		var/list/best = null
		var/best_cost = 999999999
		var/evaluated = 0
		for(var/turf/room_turf as anything in room_plan.turfs)
			if(evaluated >= 48)
				break
			for(var/check_dir in GLOB.cardinals)
				if(evaluated >= 48)
					break
				var/list/wall_run = list()
				var/list/route_run = list()
				var/valid = TRUE
				for(var/axis_offset as anything in axis_offsets)
					var/axis_dir = axis_offset ? turn(check_dir, 90) : 0
					var/turf/run_room_turf = axis_offset ? get_step(room_turf, axis_dir) : room_turf
					if(route_width == 1 && transition_width == 1 && (!room_plan.turf_lookup[get_step(run_room_turf, turn(check_dir, 90))] || !room_plan.turf_lookup[get_step(run_room_turf, turn(check_dir, -90))]))
						valid = FALSE
						break
					var/turf/wall_turf = get_step(run_room_turf, check_dir)
					var/turf/route_turf = get_step(wall_turf, check_dir)
					if(!room_plan.turf_lookup[run_room_turf] || !building_layout_route_turf_is_free(context, candidate, wall_turf, room_plan) || !building_layout_route_turf_is_free(context, candidate, route_turf, room_plan) || candidate.route_lookup[wall_turf] || candidate.access_reserved_lookup[wall_turf])
						valid = FALSE
						break
					wall_run += wall_turf
					route_run += route_turf
				if(!valid)
					continue
				evaluated++
				var/turf/target_turf = route_run[max(round((length(route_run) + 1) / 2), 1)]
				var/list/path_result = find_building_layout_bounded_route_path(context, candidate, target_turf, room_plan, wall_run)
				var/list/path = path_result?["path"]
				if(!islist(path))
					continue
				var/path_cost = round(text2num("[path_result["cost"]]") || length(path) * 10)
				if(!islist(best) || path_cost < best_cost)
					best = list("wall_run" = wall_run, "route_run" = route_run, "path" = path, "cost" = path_cost, "width" = route_width)
					best_cost = path_cost
		if(islist(best) && route_width >= transition_width)
			return best
	return null

/datum/world_edit_generator/building_layout/proc/building_layout_route_turf_is_free(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate, turf/check_turf, datum/world_edit_building_layout_room_plan/ignored_room)
	var/datum/world_edit_building_layout_state/state = context?.state
	if(!istype(state) || !istype(candidate) || !istype(check_turf) || !state.geometry.footprint_lookup[check_turf] || state.geometry.boundary_lookup[check_turf])
		return FALSE
	for(var/datum/world_edit_building_layout_room_plan/room_plan as anything in candidate.room_plans)
		if(istype(room_plan) && room_plan != ignored_room && room_plan.turf_lookup[check_turf])
			return FALSE
	if(istype(ignored_room) && ignored_room.turf_lookup[check_turf])
		return FALSE
	if(building_layout_turf_is_functional_partition_gap(candidate, check_turf))
		return FALSE
	return TRUE

/datum/world_edit_generator/building_layout/proc/building_layout_turf_is_functional_partition_gap(datum/world_edit_building_layout_candidate/candidate, turf/check_turf)
	if(!istype(candidate) || !istype(check_turf))
		return FALSE
	for(var/check_dir in list(NORTH, EAST))
		var/owner_a = ""
		var/owner_b = ""
		var/turf/side_a = get_step(check_turf, check_dir)
		var/turf/side_b = get_step(check_turf, turn(check_dir, 180))
		for(var/datum/world_edit_building_layout_room_plan/room_plan as anything in candidate.room_plans)
			if(!istype(room_plan))
				continue
			if(room_plan.turf_lookup[side_a])
				owner_a = room_plan.id
			if(room_plan.turf_lookup[side_b])
				owner_b = room_plan.id
		if(length(owner_a) && length(owner_b) && owner_a != owner_b)
			return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/find_building_layout_bounded_route_path(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate, turf/target_turf, datum/world_edit_building_layout_room_plan/terminal_room, list/protected_wall_run)
	var/datum/world_edit_building_layout_state/state = context?.state
	if(!istype(state) || !istype(candidate) || !istype(target_turf) || !length(candidate.route_turfs))
		return null
	if(candidate.route_lookup[target_turf])
		return list("path" = list(), "cost" = 0)
	var/list/open = list(target_turf)
	var/list/closed = list()
	var/list/previous = list()
	var/list/cost_lookup = list()
	var/list/estimate_lookup = list()
	var/list/protected_wall_lookup = list()
	for(var/turf/protected_wall_turf as anything in protected_wall_run)
		if(istype(protected_wall_turf))
			protected_wall_lookup[protected_wall_turf] = TRUE
	cost_lookup[target_turf] = 0
	estimate_lookup[target_turf] = get_building_layout_nearest_route_distance(candidate, target_turf) * 10
	var/turf/found = null
	var/expansions = 0
	var/max_expansions = min(length(state.geometry.footprint) * 4, 4096)
	while(length(open) && expansions < max_expansions)
		var/best_index = 1
		var/best_estimate = 999999999
		for(var/open_index in 1 to length(open))
			var/turf/open_turf = open[open_index]
			var/open_estimate = round(text2num("[estimate_lookup[open_turf]]") || 0)
			if(open_estimate < best_estimate)
				best_estimate = open_estimate
				best_index = open_index
		var/turf/current = open[best_index]
		open.Cut(best_index, best_index + 1)
		if(closed[current])
			continue
		closed[current] = TRUE
		if(candidate.route_lookup[current])
			found = current
			break
		var/turf/previous_turf = previous[current]
		var/previous_dir = istype(previous_turf) ? get_dir(previous_turf, current) : 0
		for(var/check_dir in GLOB.cardinals)
			var/turf/nearby = get_step(current, check_dir)
			if(!building_layout_route_turf_is_free(context, candidate, nearby, terminal_room) || closed[nearby] || protected_wall_lookup[nearby] || (candidate.access_reserved_lookup[nearby] && !candidate.route_lookup[nearby]))
				continue
			var/step_cost = candidate.route_lookup[nearby] ? 0 : get_building_layout_route_turf_cost(context, candidate, nearby)
			if(previous_dir && previous_dir != check_dir)
				step_cost += 12
			if(count_building_layout_free_route_neighbors(context, candidate, nearby, terminal_room) <= 1)
				step_cost += 20
			if(!candidate.route_lookup[nearby] && building_layout_turf_has_parallel_route_neighbor(candidate, nearby, check_dir))
				step_cost += 25
			var/next_cost = round(text2num("[cost_lookup[current]]") || 0) + step_cost
			var/existing_cost = cost_lookup[nearby]
			if(!isnull(existing_cost) && next_cost >= existing_cost)
				continue
			cost_lookup[nearby] = next_cost
			previous[nearby] = current
			estimate_lookup[nearby] = next_cost + get_building_layout_nearest_route_distance(candidate, nearby) * 10
			open |= nearby
		expansions++
	if(!istype(found))
		return null
	var/list/path = list()
	var/turf/path_turf = found
	while(istype(path_turf) && path_turf != target_turf)
		path_turf = previous[path_turf]
		if(istype(path_turf))
			path += path_turf
	return list("path" = path, "cost" = round(text2num("[cost_lookup[found]]") || length(path) * 10), "expansions" = expansions)

/datum/world_edit_generator/building_layout/proc/get_building_layout_route_turf_cost(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate, turf/route_turf)
	var/cost = 10
	for(var/datum/world_edit_building_layout_room_plan/room_plan as anything in candidate.room_plans)
		if(!istype(room_plan))
			continue
		for(var/check_dir in GLOB.cardinals)
			if(!room_plan.turf_lookup[get_step(get_step(route_turf, check_dir), check_dir)])
				continue
			var/datum/world_edit_building_layout_room_contract/room_contract = context.program_contract?.get_room_contract(room_plan.contract_id)
			if(istype(room_contract) && (room_contract.privacy_class == "public" || room_contract.spatial_kind == WORLD_EDIT_BUILDING_SPACE_OPEN_BAY))
				return 8
			if(istype(room_contract) && room_contract.role in list("service", "storage", "support"))
				cost = max(cost, 12)
	return cost

/datum/world_edit_generator/building_layout/proc/get_building_layout_nearest_route_distance(datum/world_edit_building_layout_candidate/candidate, turf/check_turf)
	var/best = 999
	for(var/turf/route_turf as anything in candidate?.route_turfs)
		if(istype(route_turf))
			best = min(best, get_dist(check_turf, route_turf))
	return best

/datum/world_edit_generator/building_layout/proc/count_building_layout_free_route_neighbors(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate, turf/check_turf, datum/world_edit_building_layout_room_plan/terminal_room)
	var/count = 0
	for(var/check_dir in GLOB.cardinals)
		if(building_layout_route_turf_is_free(context, candidate, get_step(check_turf, check_dir), terminal_room))
			count++
	return count

/datum/world_edit_generator/building_layout/proc/building_layout_turf_has_parallel_route_neighbor(datum/world_edit_building_layout_candidate/candidate, turf/check_turf, travel_dir)
	if(!istype(candidate) || !istype(check_turf))
		return FALSE
	var/side_a = turn(travel_dir, 90)
	var/side_b = turn(travel_dir, -90)
	return candidate.route_lookup[get_step(check_turf, side_a)] || candidate.route_lookup[get_step(check_turf, side_b)]

/datum/world_edit_generator/building_layout/proc/prune_building_layout_route_branches(datum/world_edit_building_layout_candidate/candidate, turf/entry_seed, list/terminal_room_ids)
	if(!istype(candidate) || !istype(entry_seed))
		return
	var/list/protected = list()
	protected[entry_seed] = TRUE
	for(var/room_id as anything in terminal_room_ids)
		var/list/reservation = candidate.get_route_access_reservation(room_id)
		for(var/turf/route_turf as anything in reservation?["route_run"])
			if(istype(route_turf))
				protected[route_turf] = TRUE
	var/changed = TRUE
	while(changed)
		changed = FALSE
		for(var/index = length(candidate.route_turfs), index >= 1, index--)
			var/turf/route_turf = candidate.route_turfs[index]
			if(!istype(route_turf) || protected[route_turf])
				continue
			var/neighbors = 0
			for(var/check_dir in GLOB.cardinals)
				if(candidate.route_lookup[get_step(route_turf, check_dir)])
					neighbors++
			if(neighbors > 1)
				continue
			candidate.route_turfs.Cut(index, index + 1)
			candidate.route_lookup -= route_turf
			candidate.route_owner_by_turf -= route_turf
			changed = TRUE
