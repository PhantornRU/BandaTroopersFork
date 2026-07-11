/datum/world_edit_generator/building_layout/proc/allocate_building_layout_rooms(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_region_candidate/region_candidate, allocation_variant = 0)
	if(!istype(context) || !istype(region_candidate))
		return null
	var/datum/world_edit_building_layout_candidate/candidate = new
	candidate.id = region_candidate.id
	candidate.pattern_id = region_candidate.pattern_id
	candidate.score = region_candidate.score
	candidate.region_candidate = region_candidate
	for(var/datum/world_edit_building_layout_room_connection/connection as anything in region_candidate.room_connections)
		candidate.add_room_connection(connection)
	if(!solve_building_layout_route_from_region(context, candidate, region_candidate))
		candidate.errors += "route.alloc_failed:[region_candidate.id]"
		return null
	for(var/datum/world_edit_building_layout_influence_zone/zone as anything in region_candidate.influence_zones)
		if(!allocate_building_layout_zone_rooms(context, candidate, zone, allocation_variant))
			candidate.errors += "room.alloc_zone_failed:[zone?.id]"
	if(!connect_building_layout_route_to_rooms(context, candidate))
		candidate.errors += "route.room_connect_failed:[region_candidate.id]"
	if(!validate_layout_room_allocation(context, candidate))
		return candidate
	refresh_building_layout_candidate_lookups(candidate)
	return candidate

/datum/world_edit_generator/building_layout/proc/solve_building_layout_route_from_region(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate, datum/world_edit_building_layout_region_candidate/region_candidate)
	if(!istype(context) || !istype(candidate) || !istype(region_candidate))
		return FALSE
	if(length(region_candidate.route_hints))
		for(var/datum/world_edit_building_layout_route_hint/route_hint as anything in region_candidate.route_hints)
			if(!istype(route_hint))
				continue
			add_building_layout_route_rect(context, candidate, route_hint.x1, route_hint.y1, route_hint.x2, route_hint.y2)
	else
		var/spine_x = clamp(round(context.local_width() / 2), 2, max(context.local_width() - 1, 2))
		add_building_layout_route_rect(context, candidate, spine_x, 2, spine_x, max(context.local_height() - 1, 2))
	return length(candidate.route_turfs) > 0 && ensure_building_layout_route_reaches_entry(context, candidate)

/datum/world_edit_generator/building_layout/proc/ensure_building_layout_route_reaches_entry(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate)
	var/datum/world_edit_building_layout_state/state = context?.state
	if(!istype(state) || !istype(candidate) || !length(candidate.route_turfs))
		return FALSE
	var/entry_dir = state.geometry.requested_direction || state.placement_dir || NORTH
	if(!(entry_dir in GLOB.cardinals))
		entry_dir = NORTH
	var/list/targets = list()
	for(var/turf/boundary_turf as anything in state.geometry.boundary)
		if(!istype(boundary_turf) || !boundary_turf_has_outside_dir(boundary_turf, state.geometry.footprint_lookup, entry_dir))
			continue
		var/turf/inside_turf = get_step(boundary_turf, turn(entry_dir, 180))
		if(istype(inside_turf) && state.geometry.footprint_lookup[inside_turf] && !state.geometry.boundary_lookup[inside_turf])
			targets[inside_turf] = TRUE
	if(!length(targets))
		return FALSE
	for(var/turf/route_turf as anything in candidate.route_turfs)
		if(targets[route_turf])
			return TRUE
	var/list/open = candidate.route_turfs.Copy()
	var/list/seen = list()
	var/list/previous = list()
	for(var/turf/start_turf as anything in open)
		seen[start_turf] = TRUE
	var/turf/found = null
	var/expansions = 0
	while(length(open) && expansions < WORLD_EDIT_BUILDING_MAX_ROUTE_EXPANSIONS)
		var/turf/current = open[1]
		open.Cut(1, 2)
		if(targets[current])
			found = current
			break
		for(var/check_dir in GLOB.cardinals)
			var/turf/nearby = get_step(current, check_dir)
			if(!istype(nearby) || seen[nearby] || !state.geometry.footprint_lookup[nearby] || state.geometry.boundary_lookup[nearby])
				continue
			seen[nearby] = TRUE
			previous[nearby] = current
			open += nearby
		expansions++
	if(!istype(found))
		return FALSE
	var/turf/path_turf = found
	while(istype(path_turf) && previous[path_turf])
		candidate.add_route_turf(path_turf)
		path_turf = previous[path_turf]
	return TRUE

/datum/world_edit_generator/building_layout/proc/connect_building_layout_route_to_rooms(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate)
	var/datum/world_edit_building_layout_state/state = context?.state
	if(!istype(context) || !istype(state) || !istype(candidate))
		return FALSE
	for(var/datum/world_edit_building_layout_room_plan/room_plan as anything in candidate.room_plans)
		if(!istype(room_plan))
			continue
		if(building_layout_room_plan_has_route_partition(candidate, room_plan))
			continue
		var/list/reservation = candidate.get_route_access_reservation(room_plan.id)
		var/list/wall_run = reservation?["wall_run"]
		var/list/route_run = reservation?["route_run"]
		if(!islist(reservation) || !islist(wall_run) || !islist(route_run) || length(wall_run) < 2 || length(wall_run) != length(route_run))
			candidate.errors += "route.room_connect_missing_reservation:[room_plan.id]"
			return FALSE
		var/list/room_lookup = list()
		for(var/datum/world_edit_building_layout_room_plan/occupied_room as anything in candidate.room_plans)
			if(!istype(occupied_room))
				continue
			for(var/turf/occupied_turf as anything in occupied_room.turfs)
				room_lookup[occupied_turf] = TRUE
		var/list/connector_run = reservation?["connector_run"]
		var/turf/target_turf = route_run[max(round((length(route_run) + 1) / 2), 1)]
		if(!islist(connector_run) || !istype(target_turf) || room_lookup[target_turf] || !state.geometry.footprint_lookup[target_turf] || state.geometry.boundary_lookup[target_turf])
			candidate.errors += "route.room_connect_invalid_reservation:[room_plan.id]"
			return FALSE
		for(var/turf/connector_turf as anything in connector_run)
			candidate.add_route_turf(connector_turf)
		for(var/turf/reserved_route_turf as anything in route_run)
			candidate.add_route_turf(reserved_route_turf)
	return TRUE

/datum/world_edit_generator/building_layout/proc/building_layout_room_plan_has_route_partition(datum/world_edit_building_layout_candidate/candidate, datum/world_edit_building_layout_room_plan/room_plan)
	if(!istype(candidate) || !istype(room_plan))
		return FALSE
	var/list/reservation = candidate.get_route_access_reservation(room_plan.id)
	var/list/wall_run = reservation?["wall_run"]
	var/list/route_run = reservation?["route_run"]
	if(islist(wall_run) && islist(route_run) && length(wall_run) >= 2 && length(wall_run) == length(route_run))
		for(var/run_index in 1 to length(wall_run))
			var/turf/wall_turf = wall_run[run_index]
			var/turf/route_turf = route_run[run_index]
			if(!istype(wall_turf) || !istype(route_turf) || candidate.route_lookup[wall_turf] || !candidate.route_lookup[route_turf])
				return FALSE
		return TRUE
	var/list/route_lookup = list()
	var/list/room_lookup = list()
	for(var/datum/world_edit_building_layout_room_plan/occupied_room as anything in candidate.room_plans)
		if(!istype(occupied_room))
			continue
		for(var/turf/occupied_turf as anything in occupied_room.turfs)
			if(istype(occupied_turf))
				room_lookup[occupied_turf] = TRUE
	for(var/turf/route_turf as anything in candidate.route_turfs)
		route_lookup[route_turf] = TRUE
	for(var/turf/room_turf as anything in room_plan.turfs)
		for(var/check_dir in GLOB.cardinals)
			if(!room_plan.has_turf(get_step(room_turf, turn(check_dir, 90))) && !room_plan.has_turf(get_step(room_turf, turn(check_dir, -90))))
				continue
			var/turf/wall_turf = get_step(room_turf, check_dir)
			if(!room_lookup[wall_turf] && !route_lookup[wall_turf] && route_lookup[get_step(wall_turf, check_dir)])
				return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/allocate_building_layout_zone_rooms(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate, datum/world_edit_building_layout_influence_zone/zone, allocation_variant = 0)
	if(!istype(context) || !istype(candidate) || !istype(zone))
		return FALSE
	var/list/contracts = get_room_contracts_for_building_layout_zone(context, zone)
	if(!length(contracts))
		return TRUE
	var/list/free_rects = list(build_building_layout_rect(zone.x1, zone.y1, zone.x2, zone.y2))
	var/list/ordered_contracts = sort_building_layout_room_contracts_by_priority(contracts, allocation_variant)
	for(var/contract_index in 1 to length(ordered_contracts))
		var/datum/world_edit_building_layout_room_contract/room_contract = ordered_contracts[contract_index]
		if(!istype(room_contract))
			continue
		if(candidate.get_room_plan(room_contract.id))
			if(room_contract.required)
				candidate.errors += "room.alloc_duplicate:[room_contract.id]"
			continue
		var/free_area = 0
		for(var/list/free_rect as anything in free_rects)
			free_area += building_layout_rect_area(free_rect)
		var/remaining_min_area = 0
		var/remaining_count = 0
		for(var/remaining_index in contract_index to length(ordered_contracts))
			var/datum/world_edit_building_layout_room_contract/remaining_contract = ordered_contracts[remaining_index]
			if(!istype(remaining_contract) || candidate.get_room_plan(remaining_contract.id))
				continue
			remaining_min_area += remaining_contract.min_area
			remaining_count++
		var/partition_reserve = max(remaining_count - 1, 0) * 3
		var/available_surplus = max(free_area - remaining_min_area - partition_reserve, 0)
		var/target_area = min(room_contract.preferred_area, room_contract.min_area + round(available_surplus / max(remaining_count, 1)))
		if(allocation_variant == 1)
			target_area = min(room_contract.preferred_area, room_contract.min_area + 2)
		var/list/best_rect = find_best_building_layout_room_rect_for_contract(context, candidate, zone, free_rects, room_contract, target_area, FALSE, allocation_variant)
		if(!islist(best_rect))
			var/list/global_free_rects = list(build_building_layout_rect(2, 2, max(context.local_width() - 1, 2), max(context.local_height() - 1, 2)))
			best_rect = find_best_building_layout_room_rect_for_contract(context, candidate, zone, global_free_rects, room_contract, target_area, TRUE, allocation_variant)
		if(!islist(best_rect))
			if(room_contract.required)
				candidate.errors += "room.alloc_failed:[room_contract.id]"
			continue
		var/datum/world_edit_building_layout_room_plan/room_plan = add_building_layout_room_rect(context, candidate, room_contract.id, room_contract.id, room_contract.role, room_contract.zone_id, best_rect["x1"], best_rect["y1"], best_rect["x2"], best_rect["y2"])
		if(!istype(room_plan))
			if(room_contract.required)
				candidate.errors += "room.alloc_emit_failed:[room_contract.id]"
			continue
		if(!reserve_building_layout_room_route_access(context, candidate, room_plan))
			candidate.errors += "room.route_access_unreservable:[room_contract.id]"
		split_building_layout_free_rects(free_rects, best_rect)
	return TRUE

/datum/world_edit_generator/building_layout/proc/get_room_contracts_for_building_layout_zone(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_influence_zone/zone)
	var/list/contracts = list()
	if(!istype(context) || !istype(zone))
		return contracts
	for(var/contract_id as anything in zone.preferred_room_contracts)
		var/datum/world_edit_building_layout_room_contract/room_contract = context.program_contract?.get_room_contract(contract_id)
		if(istype(room_contract))
			contracts += room_contract
	return contracts

/datum/world_edit_generator/building_layout/proc/sort_building_layout_room_contracts_by_priority(list/contracts, allocation_variant = 0)
	var/list/pending = islist(contracts) ? contracts.Copy() : list()
	var/list/ordered = list()
	while(length(pending))
		var/best_index = 0
		var/best_score = -999999999
		for(var/index in 1 to length(pending))
			var/datum/world_edit_building_layout_room_contract/room_contract = pending[index]
			if(!istype(room_contract))
				continue
			var/score = (room_contract.required ? 100000 : 0)
			switch(allocation_variant)
				if(1)
					score += room_contract.min_area * 100
				if(2)
					score -= room_contract.min_area * 100
				if(3)
					score += room_contract.max_area * 10
				else
					score += room_contract.preferred_area
					if(room_contract.role == "entry")
						score += 50000
					else if(room_contract.role == "route")
						score += 25000
			if(score > best_score)
				best_score = score
				best_index = index
		if(!best_index)
			break
		ordered += pending[best_index]
		pending.Cut(best_index, best_index + 1)
	return ordered

/datum/world_edit_generator/building_layout/proc/find_best_building_layout_room_rect_for_contract(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate, datum/world_edit_building_layout_influence_zone/zone, list/free_rects, datum/world_edit_building_layout_room_contract/room_contract, target_area_override = 0, record_failure = TRUE, placement_variant = 0)
	if(!istype(context) || !istype(candidate) || !istype(zone) || !islist(free_rects) || !istype(room_contract))
		return null
	var/list/best_rect = null
	var/best_score = -999999999
	var/contract_shape_count = 0
	var/inside_footprint_count = 0
	var/blocked_contact_count = 0
	var/evaluated_candidate_count = 0
	var/list/ideal_size = building_layout_ideal_room_size(room_contract, room_contract.target_aspect)
	var/ideal_w = round(text2num("[ideal_size["w"]]") || room_contract.min_width)
	var/ideal_h = round(text2num("[ideal_size["h"]]") || room_contract.min_height)
	var/target_area = max(room_contract.min_area, min(room_contract.preferred_area, round(text2num("[target_area_override]") || room_contract.preferred_area)))
	var/list/direct_route_rect = find_building_layout_direct_route_room_rect(context, candidate, zone, free_rects, room_contract, target_area, placement_variant)
	if(islist(direct_route_rect))
		return direct_route_rect
	for(var/list/free_rect as anything in free_rects)
		if(evaluated_candidate_count >= WORLD_EDIT_BUILDING_MAX_ROOM_CANDIDATES)
			break
		if(!islist(free_rect))
			continue
		var/free_w = building_layout_rect_width(free_rect)
		var/free_h = building_layout_rect_height(free_rect)
		for(var/room_w in 1 to free_w)
			if(evaluated_candidate_count >= WORLD_EDIT_BUILDING_MAX_ROOM_CANDIDATES)
				break
			for(var/room_h in 1 to free_h)
				if(evaluated_candidate_count >= WORLD_EDIT_BUILDING_MAX_ROOM_CANDIDATES)
					break
				var/list/rect = build_building_layout_rect(free_rect["x1"], free_rect["y1"], free_rect["x1"] + room_w - 1, free_rect["y1"] + room_h - 1)
				if(!building_layout_room_rect_valid_for_contract(context, rect, room_contract))
					continue
				contract_shape_count++
				for(var/local_x1 in free_rect["x1"] to (free_rect["x2"] - room_w + 1))
					if(evaluated_candidate_count >= WORLD_EDIT_BUILDING_MAX_ROOM_CANDIDATES)
						break
					for(var/local_y1 in free_rect["y1"] to (free_rect["y2"] - room_h + 1))
						if(evaluated_candidate_count >= WORLD_EDIT_BUILDING_MAX_ROOM_CANDIDATES)
							break
						rect = build_building_layout_rect(local_x1, local_y1, local_x1 + room_w - 1, local_y1 + room_h - 1)
						if(!building_layout_room_rect_inside_footprint(context, rect))
							continue
						inside_footprint_count++
						if(building_layout_room_rect_hits_candidate_reservation(context, candidate, rect))
							continue
						if(!building_layout_room_rect_has_available_route_access(context, candidate, rect, room_contract))
							continue
						if(building_layout_room_rect_has_blocked_room_contact(context, candidate, rect, room_contract))
							blocked_contact_count++
							continue
						evaluated_candidate_count++
						var/area = building_layout_rect_area(rect)
						var/aspect = max(room_w, room_h) / max(min(room_w, room_h), 1)
						var/score = 100000
						score -= abs(area - target_area) * 12
						score -= abs(room_w - ideal_w) * 20
						score -= abs(room_h - ideal_h) * 20
						score -= round(aspect * 10)
						score += min(room_w, room_h) * 6
						var/route_distance = building_layout_rect_min_route_distance(context, candidate, rect)
						score -= abs(route_distance - 2) * 1000
						if(route_distance == 2)
							score += 2000
						score += zone.priority
						switch(placement_variant)
							if(1)
								score += (local_x1 + local_y1) * 80
							if(2)
								score += (local_x1 - local_y1) * 80
							if(3)
								score -= (local_x1 + local_y1) * 80
						if(!islist(best_rect) || score > best_score)
							best_rect = rect
							best_score = score
	if(!islist(best_rect) && record_failure)
		candidate.errors += "room.alloc_diag:[room_contract.id]:shape=[contract_shape_count],inside=[inside_footprint_count],blocked=[blocked_contact_count],area=[room_contract.min_area]-[room_contract.max_area],dims=[room_contract.min_width]x[room_contract.min_height]-[room_contract.max_width]x[room_contract.max_height],aspect=[room_contract.max_aspect],zone=[zone.x1],[zone.y1]-[zone.x2],[zone.y2]"
	return best_rect

/datum/world_edit_generator/building_layout/proc/find_building_layout_direct_route_room_rect(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate, datum/world_edit_building_layout_influence_zone/zone, list/free_rects, datum/world_edit_building_layout_room_contract/room_contract, target_area, placement_variant = 0)
	if(!istype(context) || !istype(candidate) || !istype(zone) || !islist(free_rects) || !istype(room_contract))
		return null
	var/list/best_rect = null
	var/best_score = -999999999
	var/evaluated_candidate_count = 0
	var/direct_candidate_limit = min(WORLD_EDIT_BUILDING_MAX_ROOM_CANDIDATES, 8)
	var/list/alignments = placement_variant == 1 ? list(1, 0, -1) : (placement_variant == 2 ? list(-1, 0, 1) : list(0, -1, 1))
	var/list/ideal_size = building_layout_ideal_room_size(room_contract, room_contract.target_aspect)
	var/ideal_w = clamp(round(text2num("[ideal_size["w"]]") || room_contract.min_width), room_contract.min_width, room_contract.max_width)
	var/ideal_h = clamp(round(text2num("[ideal_size["h"]]") || room_contract.min_height), room_contract.min_height, room_contract.max_height)
	var/list/width_variants = list(room_contract.min_width)
	width_variants |= min(room_contract.max_width, room_contract.min_height)
	width_variants |= ideal_w
	width_variants |= min(room_contract.max_width, room_contract.min_width + 2)
	var/list/height_variants = list(room_contract.min_height)
	height_variants |= min(room_contract.max_height, room_contract.min_width)
	height_variants |= ideal_h
	height_variants |= min(room_contract.max_height, room_contract.min_height + 2)
	for(var/turf/route_turf as anything in candidate.route_turfs)
		if(evaluated_candidate_count >= direct_candidate_limit)
			break
		var/list/route_local = context.local_coordinates(route_turf)
		if(!islist(route_local))
			continue
		var/route_x = round(text2num("[route_local["x"]]") || 0)
		var/route_y = round(text2num("[route_local["y"]]") || 0)
		for(var/access_dir in GLOB.cardinals)
			if(evaluated_candidate_count >= direct_candidate_limit)
				break
			for(var/room_w as anything in width_variants)
				if(evaluated_candidate_count >= direct_candidate_limit)
					break
				for(var/room_h as anything in height_variants)
					if(evaluated_candidate_count >= direct_candidate_limit)
						break
					for(var/alignment as anything in alignments)
						if(evaluated_candidate_count >= direct_candidate_limit)
							break
						var/local_x1 = 0
						var/local_y1 = 0
						switch(access_dir)
							if(EAST)
								local_x1 = route_x + 2
								local_y1 = route_y - round((room_h - 1) / 2) + alignment
							if(WEST)
								local_x1 = route_x - room_w - 1
								local_y1 = route_y - round((room_h - 1) / 2) + alignment
							if(SOUTH)
								local_x1 = route_x - round((room_w - 1) / 2) + alignment
								local_y1 = route_y + 2
							if(NORTH)
								local_x1 = route_x - round((room_w - 1) / 2) + alignment
								local_y1 = route_y - room_h - 1
						var/list/rect = build_building_layout_rect(local_x1, local_y1, local_x1 + room_w - 1, local_y1 + room_h - 1)
						if(!building_layout_room_rect_valid_for_contract(context, rect, room_contract) || !building_layout_rect_inside_any_free_rect(rect, free_rects) || !building_layout_room_rect_inside_footprint(context, rect) || building_layout_room_rect_hits_candidate_reservation(context, candidate, rect) || !building_layout_room_rect_has_available_route_access(context, candidate, rect, room_contract) || building_layout_room_rect_has_blocked_room_contact(context, candidate, rect, room_contract))
							continue
						evaluated_candidate_count++
						var/area = building_layout_rect_area(rect)
						var/score = 100000 - abs(area - target_area) * 20 - abs(alignment) * 10
						score += zone.priority
						switch(placement_variant)
							if(1)
								score -= (local_x1 + local_y1) * 2
							if(2)
								score += (local_x1 - local_y1) * 40
							if(3)
								score -= (local_x1 + local_y1) * 40
						if(!islist(best_rect) || score > best_score)
							best_rect = rect
							best_score = score
	return best_rect

/datum/world_edit_generator/building_layout/proc/building_layout_rect_inside_any_free_rect(list/rect, list/free_rects)
	if(!islist(rect) || !islist(free_rects))
		return FALSE
	for(var/list/free_rect as anything in free_rects)
		if(islist(free_rect) && rect["x1"] >= free_rect["x1"] && rect["y1"] >= free_rect["y1"] && rect["x2"] <= free_rect["x2"] && rect["y2"] <= free_rect["y2"])
			return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/reserve_building_layout_room_route_access(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate, datum/world_edit_building_layout_room_plan/room_plan)
	if(!istype(context) || !istype(candidate) || !istype(room_plan))
		return FALSE
	var/datum/world_edit_building_layout_room_contract/room_contract = context.program_contract?.get_room_contract(room_plan.contract_id)
	var/list/reservation = find_building_layout_route_access_reservation(context, candidate, room_plan.turfs, room_plan, building_layout_room_access_run_length(room_contract))
	if(!islist(reservation))
		return FALSE
	var/list/wall_run = reservation["wall_run"]
	var/list/route_run = reservation["route_run"]
	var/list/connector_run = reservation["connector_run"]
	if(!islist(wall_run) || !islist(route_run))
		return FALSE
	return candidate.reserve_route_access(room_plan.id, wall_run, route_run, connector_run)

/datum/world_edit_generator/building_layout/proc/building_layout_room_rect_has_available_route_access(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate, list/rect, datum/world_edit_building_layout_room_contract/room_contract)
	if(!istype(context) || !istype(candidate) || !islist(rect))
		return FALSE
	var/list/room_turfs = list()
	for(var/local_x in rect["x1"] to rect["x2"])
		for(var/local_y in rect["y1"] to rect["y2"])
			var/turf/room_turf = context.local_turf(local_x, local_y)
			if(!istype(room_turf))
				return FALSE
			room_turfs += room_turf
	return islist(find_building_layout_route_access_reservation(context, candidate, room_turfs, null, building_layout_room_access_run_length(room_contract)))

/datum/world_edit_generator/building_layout/proc/building_layout_room_access_run_length(datum/world_edit_building_layout_room_contract/room_contract)
	if(istype(room_contract) && room_contract.route_opening_kind in list(WORLD_EDIT_BUILDING_OPENING_ARCH, WORLD_EDIT_BUILDING_OPENING_WIDE_ARCH))
		return 2
	return 3

/datum/world_edit_generator/building_layout/proc/find_building_layout_route_access_reservation(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate, list/room_turfs, datum/world_edit_building_layout_room_plan/ignored_room = null, required_run_length = 3)
	var/datum/world_edit_building_layout_state/state = context?.state
	if(!istype(context) || !istype(state) || !istype(candidate) || !islist(room_turfs) || length(room_turfs) < 3)
		return null
	var/list/room_lookup = list()
	required_run_length = clamp(round(text2num("[required_run_length]") || 3), 2, 3)
	var/list/axis_offsets = required_run_length == 2 ? list(0, 1) : list(-1, 0, 1)
	for(var/turf/room_turf as anything in room_turfs)
		if(istype(room_turf))
			room_lookup[room_turf] = TRUE
	if(length(room_lookup) < 3)
		return null
	var/list/occupied_lookup = list()
	for(var/datum/world_edit_building_layout_room_plan/occupied_room as anything in candidate.room_plans)
		if(!istype(occupied_room) || occupied_room == ignored_room)
			continue
		for(var/turf/occupied_turf as anything in occupied_room.turfs)
			occupied_lookup[occupied_turf] = TRUE
	var/list/best_reservation = null
	var/best_score = 999999
	for(var/turf/room_turf as anything in room_turfs)
		for(var/check_dir in GLOB.cardinals)
			var/list/wall_run = list()
			var/list/route_run = list()
			var/valid_run = TRUE
			for(var/axis_offset as anything in axis_offsets)
				var/axis_dir = axis_offset < 0 ? turn(check_dir, -90) : (axis_offset > 0 ? turn(check_dir, 90) : 0)
				var/turf/run_room_turf = axis_offset ? get_step(room_turf, axis_dir) : room_turf
				var/turf/wall_turf = get_step(run_room_turf, check_dir)
				var/turf/route_turf = get_step(wall_turf, check_dir)
				if(!room_lookup[run_room_turf] || !istype(wall_turf) || !istype(route_turf) || occupied_lookup[wall_turf] || occupied_lookup[route_turf] || candidate.route_lookup[wall_turf] || candidate.access_reserved_lookup[wall_turf] || (candidate.access_reserved_lookup[route_turf] && !candidate.route_lookup[route_turf]) || !state.geometry.footprint_lookup[wall_turf] || !state.geometry.footprint_lookup[route_turf] || state.geometry.boundary_lookup[wall_turf] || state.geometry.boundary_lookup[route_turf])
					valid_run = FALSE
					break
				wall_run += wall_turf
				route_run += route_turf
			if(valid_run)
				var/center_index = max(round((length(route_run) + 1) / 2), 1)
				var/list/connector_run = find_building_layout_route_connector(context, candidate, route_run[center_index], room_lookup, ignored_room)
				if(!islist(connector_run))
					continue
				var/score = candidate.route_lookup[route_run[center_index]] ? -10000 : 0
				for(var/turf/current_route as anything in candidate.route_turfs)
					score = min(score || 999999, get_dist(route_run[center_index], current_route))
				if(score < best_score)
					best_score = score
					best_reservation = list("wall_run" = wall_run, "route_run" = route_run, "connector_run" = connector_run)
	return best_reservation

/datum/world_edit_generator/building_layout/proc/find_building_layout_route_connector(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate, turf/target_turf, list/protected_room_lookup, datum/world_edit_building_layout_room_plan/ignored_room = null)
	if(!istype(context) || !istype(candidate) || !istype(target_turf) || !islist(protected_room_lookup))
		return null
	return candidate.route_lookup[target_turf] ? list() : null

/datum/world_edit_generator/building_layout/proc/building_layout_room_rect_has_route_partition(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate, list/rect)
	if(!istype(context) || !istype(candidate) || !islist(rect))
		return FALSE
	var/list/route_lookup = list()
	var/list/room_lookup = list()
	for(var/turf/route_turf as anything in candidate.route_turfs)
		if(istype(route_turf))
			route_lookup[route_turf] = TRUE
	for(var/datum/world_edit_building_layout_room_plan/existing_room as anything in candidate.room_plans)
		if(!istype(existing_room))
			continue
		for(var/turf/room_turf as anything in existing_room.turfs)
			if(istype(room_turf))
				room_lookup[room_turf] = TRUE
	for(var/local_x in rect["x1"] to rect["x2"])
		for(var/local_y in rect["y1"] to rect["y2"])
			var/turf/room_turf = context.local_turf(local_x, local_y)
			for(var/check_dir in GLOB.cardinals)
				var/turf/partition_turf = get_step(room_turf, check_dir)
				if(!room_lookup[partition_turf] && !route_lookup[partition_turf] && route_lookup[get_step(partition_turf, check_dir)])
					return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/building_layout_room_rect_hits_candidate_reservation(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate, list/rect)
	if(!istype(context) || !istype(candidate) || !islist(rect))
		return TRUE
	var/list/route_lookup = list()
	for(var/turf/route_turf as anything in candidate.route_turfs)
		if(istype(route_turf))
			route_lookup[route_turf] = TRUE
	for(var/local_x in rect["x1"] to rect["x2"])
		for(var/local_y in rect["y1"] to rect["y2"])
			var/turf/check_turf = context.local_turf(local_x, local_y)
			if(!istype(check_turf))
				return TRUE
			for(var/datum/world_edit_building_layout_room_plan/existing_room as anything in candidate.room_plans)
				if(istype(existing_room) && existing_room.turf_lookup[check_turf])
					return TRUE
			if(route_lookup[check_turf])
				return TRUE
			if(candidate.access_reserved_lookup[check_turf])
				return TRUE
			for(var/check_dir in GLOB.cardinals)
				if(route_lookup[get_step(check_turf, check_dir)])
					return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/building_layout_room_rect_has_blocked_room_contact(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate, list/rect, datum/world_edit_building_layout_room_contract/room_contract)
	if(!istype(context) || !istype(candidate) || !islist(rect) || !istype(room_contract))
		return FALSE
	for(var/local_x in rect["x1"] to rect["x2"])
		for(var/local_y in rect["y1"] to rect["y2"])
			var/turf/check_turf = context.local_turf(local_x, local_y)
			if(!istype(check_turf))
				continue
			for(var/check_dir in GLOB.cardinals)
				var/turf/nearby_turf = get_step(check_turf, check_dir)
				for(var/datum/world_edit_building_layout_room_plan/existing_room as anything in candidate.room_plans)
					if(!istype(existing_room) || !existing_room.turf_lookup[nearby_turf])
						continue
					if(building_layout_room_contracts_can_touch(context, room_contract, existing_room))
						continue
					return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/building_layout_room_contracts_can_touch(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_room_contract/room_contract, datum/world_edit_building_layout_room_plan/existing_room)
	if(!istype(context) || !istype(room_contract) || !istype(existing_room))
		return FALSE
	var/datum/world_edit_building_layout_room_contract/existing_contract = context.program_contract?.get_room_contract(existing_room.contract_id)
	if(room_contract.zone_id == "common" && existing_room.zone_id == "common")
		return TRUE
	if(istype(existing_contract) && room_contract.role == "entry_common" && existing_contract.role == "dining")
		return TRUE
	if(istype(existing_contract) && room_contract.role == "dining" && existing_contract.role == "entry_common")
		return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/building_layout_ideal_room_size(datum/world_edit_building_layout_room_contract/room_contract, target_aspect = 1.333)
	var/list/result = list("w" = 1, "h" = 1)
	if(!istype(room_contract))
		return result
	var/area = clamp(room_contract.preferred_area, room_contract.min_area, room_contract.max_area)
	var/aspect = max(text2num("[target_aspect]") || 1.333, 1)
	var/ideal_w = round(sqrt(area * aspect))
	var/ideal_h = round(max(area / max(ideal_w, 1), 1))
	ideal_w = clamp(ideal_w, room_contract.min_width, room_contract.max_width)
	ideal_h = clamp(ideal_h, room_contract.min_height, room_contract.max_height)
	result["w"] = ideal_w
	result["h"] = ideal_h
	return result

/datum/world_edit_generator/building_layout/proc/building_layout_room_rect_valid_for_contract(datum/world_edit_building_layout_context/context, list/rect, datum/world_edit_building_layout_room_contract/room_contract)
	if(!islist(rect) || !istype(room_contract))
		return FALSE
	var/w = building_layout_rect_width(rect)
	var/h = building_layout_rect_height(rect)
	var/area = w * h
	if(area < room_contract.min_area || area > room_contract.max_area)
		return FALSE
	var/fits_min_dimensions = (w >= room_contract.min_width && h >= room_contract.min_height) || (w >= room_contract.min_height && h >= room_contract.min_width)
	var/fits_max_dimensions = (w <= room_contract.max_width && h <= room_contract.max_height) || (w <= room_contract.max_height && h <= room_contract.max_width)
	if(!fits_min_dimensions || !fits_max_dimensions)
		return FALSE
	var/aspect = max(w, h) / max(min(w, h), 1)
	if(aspect > max(room_contract.max_aspect, 1))
		return FALSE
	return TRUE

/datum/world_edit_generator/building_layout/proc/building_layout_room_can_fit_required_scene(datum/world_edit_building_layout_context/context, list/room_rect, datum/world_edit_building_layout_room_contract/room_contract)
	if(!istype(context) || !islist(room_rect) || !istype(room_contract))
		return FALSE
	if(!length(room_contract.required_scene_kinds))
		return TRUE
	for(var/required_scene_kind as anything in room_contract.required_scene_kinds)
		var/has_fit = FALSE
		for(var/datum/world_edit_building_layout_scene_contract/scene_contract as anything in context.program_contract.scene_contracts)
			if(!istype(scene_contract) || scene_contract.scene_kind != "[required_scene_kind]")
				continue
			if(length(scene_contract.allowed_room_roles) && !(room_contract.role in scene_contract.allowed_room_roles))
				continue
			if(building_layout_rect_area(room_rect) < scene_contract.min_room_area || building_layout_rect_width(room_rect) < scene_contract.min_room_width || building_layout_rect_height(room_rect) < scene_contract.min_room_height)
				continue
			has_fit = TRUE
			break
		if(!has_fit)
			return FALSE
	return TRUE

/datum/world_edit_generator/building_layout/proc/validate_layout_room_allocation(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate)
	if(!istype(context) || !istype(candidate))
		return FALSE
	var/list/seen_turfs = list()
	for(var/datum/world_edit_building_layout_room_plan/room_plan as anything in candidate.room_plans)
		if(!istype(room_plan) || !length(room_plan.turfs))
			candidate.errors += "room.empty:[room_plan?.id]"
			continue
		var/datum/world_edit_building_layout_room_contract/room_contract = context.program_contract.get_room_contract(room_plan.contract_id)
		var/list/rect = build_building_layout_rect(room_plan.x1, room_plan.y1, room_plan.x2, room_plan.y2)
		if(istype(room_contract) && !building_layout_room_rect_valid_for_contract(context, rect, room_contract))
			candidate.errors += "room.invalid_contract_rect:[room_plan.id]"
		for(var/turf/room_turf as anything in room_plan.turfs)
			if(!istype(room_turf) || seen_turfs[room_turf])
				candidate.errors += "room.overlap:[room_plan.id]"
				continue
			seen_turfs[room_turf] = TRUE
	for(var/datum/world_edit_building_layout_room_contract/required_contract as anything in context.program_contract.room_contracts)
		var/datum/world_edit_building_layout_room_plan/required_room_plan = candidate.get_room_plan(required_contract?.id)
		if(istype(required_contract) && required_contract.required && !istype(required_room_plan))
			candidate.errors += "room.required_missing:[required_contract.id]"
	return !length(candidate.errors)

/datum/world_edit_generator/building_layout/proc/split_building_layout_free_rects(list/free_rects, list/used_rect)
	if(!islist(free_rects) || !islist(used_rect))
		return
	for(var/index = length(free_rects), index >= 1, index--)
		var/list/free_rect = free_rects[index]
		if(!islist(free_rect) || !building_layout_rects_intersect(free_rect, used_rect))
			continue
		free_rects.Cut(index, index + 1)
		var/left_width = used_rect["x1"] - free_rect["x1"]
		var/right_width = free_rect["x2"] - used_rect["x2"]
		var/top_height = used_rect["y1"] - free_rect["y1"]
		var/bottom_height = free_rect["y2"] - used_rect["y2"]
		if(max(left_width, right_width) >= max(top_height, bottom_height))
			if(left_width > 0)
				free_rects += list(build_building_layout_rect(free_rect["x1"], free_rect["y1"], used_rect["x1"] - 1, free_rect["y2"]))
			if(right_width > 0)
				free_rects += list(build_building_layout_rect(used_rect["x2"] + 1, free_rect["y1"], free_rect["x2"], free_rect["y2"]))
			if(top_height > 0)
				free_rects += list(build_building_layout_rect(used_rect["x1"], free_rect["y1"], used_rect["x2"], used_rect["y1"] - 1))
			if(bottom_height > 0)
				free_rects += list(build_building_layout_rect(used_rect["x1"], used_rect["y2"] + 1, used_rect["x2"], free_rect["y2"]))
		else
			if(top_height > 0)
				free_rects += list(build_building_layout_rect(free_rect["x1"], free_rect["y1"], free_rect["x2"], used_rect["y1"] - 1))
			if(bottom_height > 0)
				free_rects += list(build_building_layout_rect(free_rect["x1"], used_rect["y2"] + 1, free_rect["x2"], free_rect["y2"]))
			if(left_width > 0)
				free_rects += list(build_building_layout_rect(free_rect["x1"], used_rect["y1"], used_rect["x1"] - 1, used_rect["y2"]))
			if(right_width > 0)
				free_rects += list(build_building_layout_rect(used_rect["x2"] + 1, used_rect["y1"], free_rect["x2"], used_rect["y2"]))

/datum/world_edit_generator/building_layout/proc/refresh_building_layout_candidate_lookups(datum/world_edit_building_layout_candidate/candidate)
	if(!istype(candidate))
		return
	candidate.route_lookup = list()
	for(var/turf/route_turf as anything in candidate.route_turfs)
		if(istype(route_turf))
			candidate.route_lookup[route_turf] = TRUE
	candidate.floor_lookup = build_building_layout_candidate_floor_lookup(candidate)
	candidate.wall_lookup = candidate.solved_wall_lookup

/datum/world_edit_generator/building_layout/proc/build_building_layout_rect(x1, y1, x2, y2)
	return list("x1" = min(x1, x2), "y1" = min(y1, y2), "x2" = max(x1, x2), "y2" = max(y1, y2))

/datum/world_edit_generator/building_layout/proc/building_layout_rect_width(list/rect)
	return islist(rect) ? max(round(text2num("[rect["x2"]]") || 0) - round(text2num("[rect["x1"]]") || 0) + 1, 0) : 0

/datum/world_edit_generator/building_layout/proc/building_layout_rect_height(list/rect)
	return islist(rect) ? max(round(text2num("[rect["y2"]]") || 0) - round(text2num("[rect["y1"]]") || 0) + 1, 0) : 0

/datum/world_edit_generator/building_layout/proc/building_layout_rect_area(list/rect)
	return building_layout_rect_width(rect) * building_layout_rect_height(rect)

/datum/world_edit_generator/building_layout/proc/building_layout_rects_intersect(list/a, list/b)
	if(!islist(a) || !islist(b))
		return FALSE
	return !(a["x2"] < b["x1"] || b["x2"] < a["x1"] || a["y2"] < b["y1"] || b["y2"] < a["y1"])

/datum/world_edit_generator/building_layout/proc/building_layout_room_rect_inside_footprint(datum/world_edit_building_layout_context/context, list/rect)
	if(!istype(context) || !islist(rect))
		return FALSE
	for(var/local_x in rect["x1"] to rect["x2"])
		for(var/local_y in rect["y1"] to rect["y2"])
			var/turf/check_turf = context.local_turf(local_x, local_y)
			if(!istype(check_turf) || !context.state.geometry.footprint_lookup[check_turf] || context.state.geometry.boundary_lookup[check_turf])
				return FALSE
	return TRUE

/datum/world_edit_generator/building_layout/proc/building_layout_rect_min_route_distance(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate, list/rect)
	if(!istype(context) || !istype(candidate) || !islist(rect) || !length(candidate.route_turfs))
		return 999
	var/min_distance = 999
	for(var/local_x in rect["x1"] to rect["x2"])
		for(var/local_y in rect["y1"] to rect["y2"])
			var/turf/room_turf = context.local_turf(local_x, local_y)
			if(!istype(room_turf))
				continue
			for(var/turf/route_turf as anything in candidate.route_turfs)
				if(!istype(route_turf))
					continue
				min_distance = min(min_distance, get_dist(room_turf, route_turf))
	return min_distance
