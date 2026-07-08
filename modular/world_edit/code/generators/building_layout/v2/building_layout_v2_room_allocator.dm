/datum/world_edit_generator/building_layout/proc/allocate_building_v2_rooms(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_region_candidate/region_candidate)
	if(!istype(context) || !istype(region_candidate))
		return null
	var/datum/world_edit_building_v2_layout_candidate/candidate = new
	candidate.id = region_candidate.id
	candidate.pattern_id = region_candidate.pattern_id
	candidate.score = region_candidate.score
	candidate.region_candidate = region_candidate
	for(var/datum/world_edit_building_v2_room_connection/connection as anything in region_candidate.room_connections)
		candidate.add_room_connection(connection)
	if(!solve_building_v2_route_from_region(context, candidate, region_candidate))
		candidate.errors += "route.alloc_failed:[region_candidate.id]"
		return null
	for(var/datum/world_edit_building_v2_influence_zone/zone as anything in region_candidate.influence_zones)
		if(!allocate_building_v2_zone_rooms(context, candidate, zone))
			candidate.errors += "room.alloc_zone_failed:[zone?.id]"
	if(!validate_v2_room_allocation(context, candidate))
		return null
	refresh_building_v2_candidate_lookups(candidate)
	return candidate

/datum/world_edit_generator/building_layout/proc/solve_building_v2_route_from_region(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, datum/world_edit_building_v2_region_candidate/region_candidate)
	if(!istype(context) || !istype(candidate) || !istype(region_candidate))
		return FALSE
	if(length(region_candidate.route_hints))
		for(var/datum/world_edit_building_v2_route_hint/route_hint as anything in region_candidate.route_hints)
			if(!istype(route_hint))
				continue
			add_building_v2_route_rect(context, candidate, route_hint.x1, route_hint.y1, route_hint.x2, route_hint.y2)
	else
		var/spine_x = clamp(round(context.local_width() / 2), 2, max(context.local_width() - 1, 2))
		add_building_v2_route_rect(context, candidate, spine_x, 2, spine_x, max(context.local_height() - 1, 2))
	return length(candidate.route_turfs) > 0

/datum/world_edit_generator/building_layout/proc/allocate_building_v2_zone_rooms(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, datum/world_edit_building_v2_influence_zone/zone)
	if(!istype(context) || !istype(candidate) || !istype(zone))
		return FALSE
	var/list/contracts = get_room_contracts_for_building_v2_zone(context, zone)
	if(!length(contracts))
		return TRUE
	var/list/free_rects = list(build_building_v2_rect(zone.x1, zone.y1, zone.x2, zone.y2))
	var/list/ordered_contracts = sort_building_v2_room_contracts_by_priority(contracts)
	for(var/datum/world_edit_building_v2_room_contract/room_contract as anything in ordered_contracts)
		if(!istype(room_contract))
			continue
		if(candidate.get_room_plan(room_contract.id))
			if(room_contract.required)
				candidate.errors += "room.alloc_duplicate:[room_contract.id]"
			continue
		var/list/best_rect = find_best_building_v2_room_rect_for_contract(context, candidate, zone, free_rects, room_contract)
		if(!islist(best_rect))
			if(room_contract.required)
				candidate.errors += "room.alloc_failed:[room_contract.id]"
			continue
		var/datum/world_edit_building_v2_room_plan/room_plan = add_building_v2_room_rect(context, candidate, room_contract.id, room_contract.id, room_contract.role, room_contract.zone_id, best_rect["x1"], best_rect["y1"], best_rect["x2"], best_rect["y2"])
		if(!istype(room_plan))
			if(room_contract.required)
				candidate.errors += "room.alloc_emit_failed:[room_contract.id]"
			continue
		split_building_v2_free_rects(free_rects, best_rect)
	return TRUE

/datum/world_edit_generator/building_layout/proc/get_room_contracts_for_building_v2_zone(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_influence_zone/zone)
	var/list/contracts = list()
	if(!istype(context) || !istype(zone))
		return contracts
	for(var/contract_id as anything in zone.preferred_room_contracts)
		var/datum/world_edit_building_v2_room_contract/room_contract = context.program_contract?.get_room_contract(contract_id)
		if(istype(room_contract))
			contracts += room_contract
	return contracts

/datum/world_edit_generator/building_layout/proc/sort_building_v2_room_contracts_by_priority(list/contracts)
	var/list/pending = islist(contracts) ? contracts.Copy() : list()
	var/list/ordered = list()
	while(length(pending))
		var/best_index = 0
		var/best_score = -999999999
		for(var/index in 1 to length(pending))
			var/datum/world_edit_building_v2_room_contract/room_contract = pending[index]
			if(!istype(room_contract))
				continue
			var/score = (room_contract.required ? 100000 : 0) + room_contract.preferred_area
			if(score > best_score)
				best_score = score
				best_index = index
		if(!best_index)
			break
		ordered += pending[best_index]
		pending.Cut(best_index, best_index + 1)
	return ordered

/datum/world_edit_generator/building_layout/proc/find_best_building_v2_room_rect_for_contract(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, datum/world_edit_building_v2_influence_zone/zone, list/free_rects, datum/world_edit_building_v2_room_contract/room_contract)
	if(!istype(context) || !istype(candidate) || !istype(zone) || !islist(free_rects) || !istype(room_contract))
		return null
	var/list/best_rect = null
	var/best_score = -999999999
	var/list/ideal_size = building_v2_ideal_room_size(room_contract, room_contract.target_aspect)
	var/ideal_w = round(text2num("[ideal_size["w"]]") || room_contract.min_width)
	var/ideal_h = round(text2num("[ideal_size["h"]]") || room_contract.min_height)
	var/zone_area = building_v2_rect_area(build_building_v2_rect(zone.x1, zone.y1, zone.x2, zone.y2))
	var/target_area = room_contract.required ? min(room_contract.max_area, max(room_contract.preferred_area, round(zone_area * 0.85))) : room_contract.preferred_area
	for(var/list/free_rect as anything in free_rects)
		if(!islist(free_rect))
			continue
		var/free_w = building_v2_rect_width(free_rect)
		var/free_h = building_v2_rect_height(free_rect)
		for(var/room_w in 1 to free_w)
			for(var/room_h in 1 to free_h)
				var/list/rect = build_building_v2_rect(free_rect["x1"], free_rect["y1"], free_rect["x1"] + room_w - 1, free_rect["y1"] + room_h - 1)
				if(!building_v2_room_rect_valid_for_contract(context, rect, room_contract))
					continue
				for(var/local_x1 in free_rect["x1"] to (free_rect["x2"] - room_w + 1))
					for(var/local_y1 in free_rect["y1"] to (free_rect["y2"] - room_h + 1))
						rect = build_building_v2_rect(local_x1, local_y1, local_x1 + room_w - 1, local_y1 + room_h - 1)
						if(!building_v2_room_rect_inside_footprint(context, rect))
							continue
						if(building_v2_room_rect_has_blocked_room_contact(context, candidate, rect, room_contract))
							continue
						var/area = building_v2_rect_area(rect)
						var/aspect = max(room_w, room_h) / max(min(room_w, room_h), 1)
						var/score = 100000
						score -= abs(area - target_area) * 12
						score -= abs(room_w - ideal_w) * 20
						score -= abs(room_h - ideal_h) * 20
						score -= round(aspect * 10)
						score += min(room_w, room_h) * 6
						if(room_contract.must_touch_route)
							var/route_distance = building_v2_rect_min_route_distance(context, candidate, rect)
							score -= abs(route_distance - 2) * 250
							if(route_distance == 2)
								score += 500
						score += zone.priority
						if(!islist(best_rect) || score > best_score)
							best_rect = rect
							best_score = score
	return best_rect

/datum/world_edit_generator/building_layout/proc/building_v2_room_rect_has_blocked_room_contact(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, list/rect, datum/world_edit_building_v2_room_contract/room_contract)
	if(!istype(context) || !istype(candidate) || !islist(rect) || !istype(room_contract))
		return FALSE
	for(var/local_x in rect["x1"] to rect["x2"])
		for(var/local_y in rect["y1"] to rect["y2"])
			var/turf/check_turf = context.local_turf(local_x, local_y)
			if(!istype(check_turf))
				continue
			for(var/check_dir in GLOB.cardinals)
				var/turf/nearby_turf = get_step(check_turf, check_dir)
				for(var/datum/world_edit_building_v2_room_plan/existing_room as anything in candidate.room_plans)
					if(!istype(existing_room) || !existing_room.turf_lookup[nearby_turf])
						continue
					if(building_v2_room_contracts_can_touch(context, room_contract, existing_room))
						continue
					return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/building_v2_room_contracts_can_touch(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_room_contract/room_contract, datum/world_edit_building_v2_room_plan/existing_room)
	if(!istype(context) || !istype(room_contract) || !istype(existing_room))
		return FALSE
	var/datum/world_edit_building_v2_room_contract/existing_contract = context.program_contract?.get_room_contract(existing_room.contract_id)
	if(room_contract.zone_id == "common" && existing_room.zone_id == "common")
		return TRUE
	if(istype(existing_contract) && room_contract.role == "entry_common" && existing_contract.role == "dining")
		return TRUE
	if(istype(existing_contract) && room_contract.role == "dining" && existing_contract.role == "entry_common")
		return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/building_v2_ideal_room_size(datum/world_edit_building_v2_room_contract/room_contract, target_aspect = 1.333)
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

/datum/world_edit_generator/building_layout/proc/building_v2_room_rect_valid_for_contract(datum/world_edit_building_v2_context/context, list/rect, datum/world_edit_building_v2_room_contract/room_contract)
	if(!islist(rect) || !istype(room_contract))
		return FALSE
	var/w = building_v2_rect_width(rect)
	var/h = building_v2_rect_height(rect)
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
	if(!building_v2_room_can_fit_required_scene(context, rect, room_contract))
		return FALSE
	return TRUE

/datum/world_edit_generator/building_layout/proc/building_v2_room_can_fit_required_scene(datum/world_edit_building_v2_context/context, list/room_rect, datum/world_edit_building_v2_room_contract/room_contract)
	if(!istype(context) || !islist(room_rect) || !istype(room_contract))
		return FALSE
	if(!length(room_contract.required_scene_kinds))
		return TRUE
	for(var/required_scene_kind as anything in room_contract.required_scene_kinds)
		var/has_fit = FALSE
		for(var/datum/world_edit_building_v2_scene_contract/scene_contract as anything in context.program_contract.scene_contracts)
			if(!istype(scene_contract) || scene_contract.scene_kind != "[required_scene_kind]")
				continue
			if(length(scene_contract.allowed_room_roles) && !(room_contract.role in scene_contract.allowed_room_roles))
				continue
			if(building_v2_rect_area(room_rect) < scene_contract.min_room_area || building_v2_rect_width(room_rect) < scene_contract.min_room_width || building_v2_rect_height(room_rect) < scene_contract.min_room_height)
				continue
			has_fit = TRUE
			break
		if(!has_fit)
			return FALSE
	return TRUE

/datum/world_edit_generator/building_layout/proc/validate_v2_room_allocation(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate)
	if(!istype(context) || !istype(candidate))
		return FALSE
	var/list/seen_turfs = list()
	for(var/datum/world_edit_building_v2_room_plan/room_plan as anything in candidate.room_plans)
		if(!istype(room_plan) || !length(room_plan.turfs))
			candidate.errors += "room.empty:[room_plan?.id]"
			continue
		var/datum/world_edit_building_v2_room_contract/room_contract = context.program_contract.get_room_contract(room_plan.contract_id)
		var/list/rect = build_building_v2_rect(room_plan.x1, room_plan.y1, room_plan.x2, room_plan.y2)
		if(istype(room_contract) && !building_v2_room_rect_valid_for_contract(context, rect, room_contract))
			candidate.errors += "room.invalid_contract_rect:[room_plan.id]"
		for(var/turf/room_turf as anything in room_plan.turfs)
			if(!istype(room_turf) || seen_turfs[room_turf])
				candidate.errors += "room.overlap:[room_plan.id]"
				continue
			seen_turfs[room_turf] = TRUE
	for(var/datum/world_edit_building_v2_room_contract/required_contract as anything in context.program_contract.room_contracts)
		var/datum/world_edit_building_v2_room_plan/required_room_plan = candidate.get_room_plan(required_contract?.id)
		if(istype(required_contract) && required_contract.required && !istype(required_room_plan))
			candidate.errors += "room.required_missing:[required_contract.id]"
	return !length(candidate.errors)

/datum/world_edit_generator/building_layout/proc/split_building_v2_free_rects(list/free_rects, list/used_rect)
	if(!islist(free_rects) || !islist(used_rect))
		return
	for(var/index = length(free_rects), index >= 1, index--)
		var/list/free_rect = free_rects[index]
		if(!islist(free_rect) || !building_v2_rects_intersect(free_rect, used_rect))
			continue
		free_rects.Cut(index, index + 1)
		var/left_width = used_rect["x1"] - free_rect["x1"]
		var/right_width = free_rect["x2"] - used_rect["x2"]
		var/top_height = used_rect["y1"] - free_rect["y1"]
		var/bottom_height = free_rect["y2"] - used_rect["y2"]
		if(max(left_width, right_width) >= max(top_height, bottom_height))
			if(left_width > 0)
				free_rects += list(build_building_v2_rect(free_rect["x1"], free_rect["y1"], used_rect["x1"] - 1, free_rect["y2"]))
			if(right_width > 0)
				free_rects += list(build_building_v2_rect(used_rect["x2"] + 1, free_rect["y1"], free_rect["x2"], free_rect["y2"]))
			if(top_height > 0)
				free_rects += list(build_building_v2_rect(used_rect["x1"], free_rect["y1"], used_rect["x2"], used_rect["y1"] - 1))
			if(bottom_height > 0)
				free_rects += list(build_building_v2_rect(used_rect["x1"], used_rect["y2"] + 1, used_rect["x2"], free_rect["y2"]))
		else
			if(top_height > 0)
				free_rects += list(build_building_v2_rect(free_rect["x1"], free_rect["y1"], free_rect["x2"], used_rect["y1"] - 1))
			if(bottom_height > 0)
				free_rects += list(build_building_v2_rect(free_rect["x1"], used_rect["y2"] + 1, free_rect["x2"], free_rect["y2"]))
			if(left_width > 0)
				free_rects += list(build_building_v2_rect(free_rect["x1"], used_rect["y1"], used_rect["x1"] - 1, used_rect["y2"]))
			if(right_width > 0)
				free_rects += list(build_building_v2_rect(used_rect["x2"] + 1, used_rect["y1"], free_rect["x2"], used_rect["y2"]))

/datum/world_edit_generator/building_layout/proc/refresh_building_v2_candidate_lookups(datum/world_edit_building_v2_layout_candidate/candidate)
	if(!istype(candidate))
		return
	candidate.route_lookup = list()
	for(var/turf/route_turf as anything in candidate.route_turfs)
		if(istype(route_turf))
			candidate.route_lookup[route_turf] = TRUE
	candidate.floor_lookup = build_building_v2_candidate_floor_lookup(candidate)
	candidate.wall_lookup = candidate.solved_wall_lookup

/datum/world_edit_generator/building_layout/proc/build_building_v2_rect(x1, y1, x2, y2)
	return list("x1" = min(x1, x2), "y1" = min(y1, y2), "x2" = max(x1, x2), "y2" = max(y1, y2))

/datum/world_edit_generator/building_layout/proc/building_v2_rect_width(list/rect)
	return islist(rect) ? max(round(text2num("[rect["x2"]]") || 0) - round(text2num("[rect["x1"]]") || 0) + 1, 0) : 0

/datum/world_edit_generator/building_layout/proc/building_v2_rect_height(list/rect)
	return islist(rect) ? max(round(text2num("[rect["y2"]]") || 0) - round(text2num("[rect["y1"]]") || 0) + 1, 0) : 0

/datum/world_edit_generator/building_layout/proc/building_v2_rect_area(list/rect)
	return building_v2_rect_width(rect) * building_v2_rect_height(rect)

/datum/world_edit_generator/building_layout/proc/building_v2_rects_intersect(list/a, list/b)
	if(!islist(a) || !islist(b))
		return FALSE
	return !(a["x2"] < b["x1"] || b["x2"] < a["x1"] || a["y2"] < b["y1"] || b["y2"] < a["y1"])

/datum/world_edit_generator/building_layout/proc/building_v2_room_rect_inside_footprint(datum/world_edit_building_v2_context/context, list/rect)
	if(!istype(context) || !islist(rect))
		return FALSE
	for(var/local_x in rect["x1"] to rect["x2"])
		for(var/local_y in rect["y1"] to rect["y2"])
			var/turf/check_turf = context.local_turf(local_x, local_y)
			if(!istype(check_turf) || !context.state.geometry.footprint_lookup[check_turf] || context.state.geometry.boundary_lookup[check_turf])
				return FALSE
	return TRUE

/datum/world_edit_generator/building_layout/proc/building_v2_rect_min_route_distance(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, list/rect)
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
