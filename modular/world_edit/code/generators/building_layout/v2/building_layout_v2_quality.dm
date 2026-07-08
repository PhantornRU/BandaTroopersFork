/datum/world_edit_generator/building_layout/proc/get_v2_scene_room_solve_order(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate)
	var/list/required_rooms = list()
	var/list/optional_rooms = list()
	if(!istype(context) || !istype(candidate))
		return required_rooms
	for(var/datum/world_edit_building_v2_room_plan/room_plan as anything in candidate.room_plans)
		var/datum/world_edit_building_v2_room_contract/room_contract = context.program_contract?.get_room_contract(room_plan?.contract_id)
		if(istype(room_contract) && room_contract.required)
			required_rooms += room_plan
		else
			optional_rooms += room_plan
	return required_rooms + optional_rooms

/datum/world_edit_generator/building_layout/proc/building_v2_scene_budget_allows(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_scene_plan/scene_plan)
	if(!istype(context?.scene_budget) || !istype(scene_plan))
		return TRUE
	for(var/scene_slot as anything in scene_plan.scene_slot_counts)
		var/global_slot = building_v2_global_scene_slot_key(scene_slot)
		var/amount = round(text2num("[scene_plan.scene_slot_counts[scene_slot]]") || 0)
		if(amount <= 0)
			continue
		if(!context.scene_budget.can_use(global_slot, amount))
			return FALSE
	return TRUE

/datum/world_edit_generator/building_layout/proc/register_building_v2_scene_budget_use(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_scene_plan/scene_plan)
	if(!istype(context?.scene_budget) || !istype(scene_plan))
		return
	for(var/scene_slot as anything in scene_plan.scene_slot_counts)
		var/global_slot = building_v2_global_scene_slot_key(scene_slot)
		context.scene_budget.use(global_slot, scene_plan.scene_slot_counts[scene_slot])

/datum/world_edit_generator/building_layout/proc/select_building_v2_primary_anchor(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, datum/world_edit_building_v2_room_plan/room_plan, datum/world_edit_building_v2_scene_contract/scene_contract)
	if(!istype(context) || !istype(candidate) || !istype(room_plan) || !istype(scene_contract))
		return null
	switch(scene_contract.primary_anchor_policy)
		if("far_wall", "longest_wall", "service_wall")
			return select_building_v2_scene_anchor(context, candidate, room_plan, "primary", scene_contract.scene_kind, scene_contract.scene_kind, null, TRUE, TRUE)
		if("near_window")
			return select_building_v2_window_primary_anchor(context, candidate, room_plan, scene_contract)
	return select_building_v2_scene_anchor(context, candidate, room_plan, "primary", scene_contract.scene_kind, scene_contract.scene_kind)

/datum/world_edit_generator/building_layout/proc/select_building_v2_window_primary_anchor(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, datum/world_edit_building_v2_room_plan/room_plan, datum/world_edit_building_v2_scene_contract/scene_contract)
	var/list/best_anchor = null
	var/best_score = -999999999
	if(!istype(context) || !istype(candidate) || !istype(room_plan))
		return null
	for(var/datum/world_edit_building_v2_route_opening_plan/window_plan as anything in candidate.window_plans)
		if(!istype(window_plan?.opening_turf) || window_plan.from_room != room_plan.id)
			continue
		var/turf/interior_turf = get_step(window_plan.opening_turf, turn(window_plan.dir, 180))
		if(!room_plan.has_turf(interior_turf))
			continue
		var/score = score_building_v2_scene_turf(context, candidate, room_plan, interior_turf, scene_contract.scene_kind)
		if(!islist(best_anchor) || score > best_score)
			best_anchor = list("turf" = interior_turf, "dir" = window_plan.dir, "wall_dir" = turn(window_plan.dir, 180), "score" = score)
			best_score = score
	return best_anchor || select_building_v2_scene_anchor(context, candidate, room_plan, "primary", scene_contract.scene_kind, scene_contract.scene_kind)

/datum/world_edit_generator/building_layout/proc/register_building_v2_scene_hierarchy(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, datum/world_edit_building_v2_room_plan/room_plan, datum/world_edit_building_v2_scene_contract/scene_contract, datum/world_edit_building_v2_scene_plan/scene_plan)
	if(!istype(context) || !istype(candidate) || !istype(room_plan) || !istype(scene_contract) || !istype(scene_plan))
		return FALSE
	var/turf/focus_turf = null
	for(var/list/member as anything in scene_plan.members)
		if(!islist(member) || !GLOB.world_edit_helpers.parse_bool(member["major"]))
			continue
		focus_turf = member["turf"]
		break
	if(!istype(focus_turf))
		var/list/candidate_anchor = scene_plan.primary_anchors["candidate_focus"]
		if(islist(candidate_anchor))
			focus_turf = candidate_anchor["turf"]
	if(!istype(focus_turf) && length(scene_plan.members))
		var/list/first_member = scene_plan.members[1]
		if(islist(first_member))
			focus_turf = first_member["turf"]
	if(!istype(focus_turf))
		return FALSE
	scene_plan.primary_anchors["focus"] = focus_turf
	if(!reserve_building_v2_negative_space(context, candidate, room_plan, scene_plan))
		return FALSE
	for(var/list/member as anything in scene_plan.members)
		if(!islist(member))
			continue
		var/turf/member_turf = member["turf"]
		if(member_turf == focus_turf)
			continue
		if(member["major"])
			scene_plan.secondary_anchors += member_turf
		else
			scene_plan.detail_anchors += member_turf
	return validate_building_v2_scene_composition(context, candidate, room_plan, scene_contract, scene_plan)

/datum/world_edit_generator/building_layout/proc/reserve_building_v2_negative_space(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, datum/world_edit_building_v2_room_plan/room_plan, datum/world_edit_building_v2_scene_plan/scene_plan)
	if(!istype(room_plan) || !istype(scene_plan))
		return FALSE
	var/turf/focus_turf = scene_plan.primary_anchors["focus"]
	if(!istype(focus_turf))
		return FALSE
	var/list/door_turfs = get_building_v2_room_door_turfs(candidate, room_plan.id)
	if(!length(door_turfs))
		return FALSE
	var/list/occupied_lookup = list()
	for(var/list/member as anything in scene_plan.members)
		if(!islist(member))
			continue
		var/turf/member_turf = member["turf"]
		if(istype(member_turf))
			occupied_lookup[member_turf] = TRUE
	for(var/turf/door_turf as anything in door_turfs)
		var/turf/start_turf = get_building_v2_room_door_inside_turf(candidate, room_plan, door_turf)
		var/list/path = build_building_v2_room_internal_path(room_plan, start_turf, focus_turf, occupied_lookup)
		for(var/turf/path_turf as anything in path)
			if(!istype(path_turf) || path_turf == focus_turf)
				continue
			scene_plan.negative_space_turfs += path_turf
			scene_plan.no_furniture_lookup[path_turf] = TRUE
	return length(scene_plan.negative_space_turfs) > 0

/datum/world_edit_generator/building_layout/proc/get_building_v2_room_door_turfs(datum/world_edit_building_v2_layout_candidate/candidate, room_id)
	var/list/door_turfs = list()
	if(!istype(candidate))
		return door_turfs
	for(var/datum/world_edit_building_v2_route_opening_plan/door_plan as anything in candidate.door_plans)
		if(!istype(door_plan?.opening_turf) || door_plan.kind == "main_exit")
			continue
		if(door_plan.from_room == room_id || door_plan.to_room == room_id)
			door_turfs += door_plan.opening_turf
	return door_turfs

/datum/world_edit_generator/building_layout/proc/get_building_v2_room_door_inside_turf(datum/world_edit_building_v2_layout_candidate/candidate, datum/world_edit_building_v2_room_plan/room_plan, turf/door_turf)
	if(!istype(candidate) || !istype(room_plan) || !istype(door_turf))
		return null
	for(var/datum/world_edit_building_v2_route_opening_plan/door_plan as anything in candidate.door_plans)
		if(!istype(door_plan) || door_plan.opening_turf != door_turf)
			continue
		var/turf/front_turf = get_step(door_turf, door_plan.dir)
		if(room_plan.has_turf(front_turf))
			return front_turf
		var/turf/back_turf = get_step(door_turf, turn(door_plan.dir, 180))
		if(room_plan.has_turf(back_turf))
			return back_turf
	return null

/datum/world_edit_generator/building_layout/proc/build_building_v2_room_internal_path(datum/world_edit_building_v2_room_plan/room_plan, turf/start_turf, turf/focus_turf, list/occupied_lookup = null)
	var/list/path_x_first = build_building_v2_room_internal_path_order(room_plan, start_turf, focus_turf, TRUE)
	var/list/path_y_first = build_building_v2_room_internal_path_order(room_plan, start_turf, focus_turf, FALSE)
	if(!islist(occupied_lookup))
		return length(path_x_first) <= length(path_y_first) ? path_x_first : path_y_first
	var/x_blocks = count_building_v2_path_occupied(path_x_first, occupied_lookup, focus_turf)
	var/y_blocks = count_building_v2_path_occupied(path_y_first, occupied_lookup, focus_turf)
	return x_blocks <= y_blocks ? path_x_first : path_y_first

/datum/world_edit_generator/building_layout/proc/build_building_v2_room_internal_path_order(datum/world_edit_building_v2_room_plan/room_plan, turf/start_turf, turf/focus_turf, x_first = TRUE)
	var/list/path = list()
	if(!istype(room_plan) || !istype(start_turf) || !istype(focus_turf) || !room_plan.has_turf(start_turf) || !room_plan.has_turf(focus_turf))
		return path
	var/current_x = start_turf.x
	var/current_y = start_turf.y
	var/z_level = start_turf.z
	if(x_first)
		while(current_x != focus_turf.x)
			current_x += current_x < focus_turf.x ? 1 : -1
			var/turf/check_turf = locate(current_x, current_y, z_level)
			if(room_plan.has_turf(check_turf))
				path += check_turf
		while(current_y != focus_turf.y)
			current_y += current_y < focus_turf.y ? 1 : -1
			var/turf/check_turf = locate(current_x, current_y, z_level)
			if(room_plan.has_turf(check_turf))
				path += check_turf
	else
		while(current_y != focus_turf.y)
			current_y += current_y < focus_turf.y ? 1 : -1
			var/turf/check_turf = locate(current_x, current_y, z_level)
			if(room_plan.has_turf(check_turf))
				path += check_turf
		while(current_x != focus_turf.x)
			current_x += current_x < focus_turf.x ? 1 : -1
			var/turf/check_turf = locate(current_x, current_y, z_level)
			if(room_plan.has_turf(check_turf))
				path += check_turf
	return path

/datum/world_edit_generator/building_layout/proc/count_building_v2_path_occupied(list/path, list/occupied_lookup, turf/focus_turf)
	var/count = 0
	for(var/turf/path_turf as anything in path)
		if(istype(path_turf) && path_turf != focus_turf && occupied_lookup[path_turf])
			count++
	return count

/datum/world_edit_generator/building_layout/proc/validate_building_v2_scene_composition(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, datum/world_edit_building_v2_room_plan/room_plan, datum/world_edit_building_v2_scene_contract/scene_contract, datum/world_edit_building_v2_scene_plan/scene_plan)
	if(!istype(scene_contract) || !istype(scene_plan))
		return FALSE
	var/turf/focus_turf = scene_plan.primary_anchors["focus"]
	if(!istype(focus_turf))
		return FALSE
	if(scene_contract.min_negative_space_tiles > 0 && length(scene_plan.negative_space_turfs) < scene_contract.min_negative_space_tiles)
		return FALSE
	for(var/list/member as anything in scene_plan.members)
		if(!islist(member))
			continue
		var/turf/member_turf = member["turf"]
		if(istype(member_turf) && scene_plan.no_furniture_lookup[member_turf] && member_turf != focus_turf)
			return FALSE
	var/room_area = max(room_plan?.area() || 0, 1)
	var/occupancy_ratio = round(length(scene_plan.occupied_turfs) * 100 / room_area)
	if(occupancy_ratio > scene_contract.max_occupancy_ratio)
		return FALSE
	return TRUE

/datum/world_edit_generator/building_layout/proc/mark_building_v2_scene_negative_space(datum/world_edit_building_layout_state/state, datum/world_edit_building_v2_scene_plan/scene_plan)
	if(!istype(state) || !istype(scene_plan))
		return
	for(var/turf/negative_turf as anything in scene_plan.negative_space_turfs)
		if(!istype(negative_turf))
			continue
		state.fixtures.scene_negative_space_lookup[negative_turf] = TRUE
		state.fixtures.scene_no_furniture_lookup[negative_turf] = TRUE

/datum/world_edit_generator/building_layout/proc/validate_building_v2_quality(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate)
	var/datum/world_edit_building_layout_state/state = context?.state
	if(!istype(state) || !istype(candidate))
		return FALSE
	validate_building_v2_room_quality(context, candidate)
	validate_building_v2_opening_quality(context, candidate)
	validate_building_v2_scene_quality(context, candidate)
	validate_building_v2_window_quality(context, candidate)
	return !building_v2_quality_has_hard_failures(context)

/datum/world_edit_generator/building_layout/proc/validate_building_v2_room_quality(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate)
	var/datum/world_edit_building_layout_state/state = context?.state
	if(!istype(state))
		return
	for(var/datum/world_edit_building_v2_room_plan/room_plan as anything in candidate.room_plans)
		if(!istype(room_plan))
			continue
		var/datum/world_edit_building_v2_room_contract/room_contract = context.program_contract?.get_room_contract(room_plan.contract_id)
		var/room_min_dim = min(room_plan.width(), room_plan.height())
		var/room_max_dim = max(room_plan.width(), room_plan.height())
		var/aspect = room_max_dim / max(room_min_dim, 1)
		if(istype(room_contract) && aspect > max(room_contract.max_aspect, 1))
			state.validation.v2_room_bad_aspect_count++
		if(room_plan.area() >= 12 && (room_min_dim <= 2 || room_max_dim > room_min_dim * 4))
			state.validation.v2_room_thin_strip_count++
		if(istype(room_contract) && room_contract.required && room_contract.must_touch_route && !building_v2_room_has_valid_route_connection(candidate, room_plan.id))
			state.validation.v2_isolated_room_count++
		var/scene_member_count = istype(room_plan.scene_plan) ? length(room_plan.scene_plan.members) : 0
		if(room_plan.area() >= 16 && scene_member_count <= 1 && !(room_plan.contract_id in list("sanitation", "storage", "utility")))
			state.validation.v2_empty_large_room_count++
		if(istype(room_contract) && length(room_contract.required_scene_kinds) && !building_v2_room_can_fit_required_scene(context, build_building_v2_rect(room_plan.x1, room_plan.y1, room_plan.x2, room_plan.y2), room_contract))
			state.validation.v2_room_scene_capacity_failed_count++

/datum/world_edit_generator/building_layout/proc/building_v2_room_has_valid_route_connection(datum/world_edit_building_v2_layout_candidate/candidate, room_id)
	if(!istype(candidate))
		return FALSE
	for(var/datum/world_edit_building_v2_route_opening_plan/door_plan as anything in candidate.door_plans)
		if(!istype(door_plan) || door_plan.kind == "main_exit")
			continue
		if(door_plan.from_room == room_id && door_plan.to_room == "route")
			return TRUE
		if(door_plan.to_room == room_id && door_plan.from_room == "route")
			return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/validate_building_v2_opening_quality(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate)
	var/datum/world_edit_building_layout_state/state = context?.state
	if(!istype(state))
		return
	for(var/datum/world_edit_building_v2_route_opening_plan/door_plan as anything in candidate.door_plans)
		if(!istype(door_plan) || door_plan.kind == "main_exit")
			continue
		if(!building_v2_door_plan_has_valid_shared_wall(context, candidate, door_plan))
			state.validation.v2_door_not_on_shared_wall_count++
		var/segment_length = building_v2_door_plan_segment_length(context, candidate, door_plan)
		if(segment_length <= 0)
			state.validation.v2_door_no_shared_wall_count++
		if(segment_length > 0 && segment_length < 3)
			state.validation.v2_door_short_segment_count++
		if(building_v2_door_plan_at_segment_end(context, candidate, door_plan))
			state.validation.v2_door_corner_count++
		if(building_v2_opening_near_other_door_excluding(candidate, door_plan, 1))
			state.validation.v2_door_near_other_door_count++
		if(!building_v2_door_clearance_ok(candidate, door_plan))
			state.validation.v2_door_invalid_clearance_count++

/datum/world_edit_generator/building_layout/proc/building_v2_door_plan_segment_length(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, datum/world_edit_building_v2_route_opening_plan/door_plan)
	var/list/from_lookup = get_building_v2_region_lookup(candidate, door_plan?.from_room)
	var/list/to_lookup = get_building_v2_region_lookup(candidate, door_plan?.to_room)
	return building_v2_shared_wall_run_length_for_regions(context, candidate, from_lookup, to_lookup, door_plan?.opening_turf, door_plan?.dir)

/datum/world_edit_generator/building_layout/proc/building_v2_door_plan_at_segment_end(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, datum/world_edit_building_v2_route_opening_plan/door_plan)
	var/list/from_lookup = get_building_v2_region_lookup(candidate, door_plan?.from_room)
	var/list/to_lookup = get_building_v2_region_lookup(candidate, door_plan?.to_room)
	return building_v2_opening_at_segment_end_for_regions(context, candidate, from_lookup, to_lookup, door_plan?.opening_turf, door_plan?.dir)

/datum/world_edit_generator/building_layout/proc/building_v2_opening_near_other_door_excluding(datum/world_edit_building_v2_layout_candidate/candidate, datum/world_edit_building_v2_route_opening_plan/source_door, radius = 2)
	for(var/datum/world_edit_building_v2_route_opening_plan/door_plan as anything in candidate?.door_plans)
		if(!istype(door_plan?.opening_turf) || door_plan == source_door)
			continue
		if(building_v2_openings_are_opposite_route_pair(candidate, source_door.opening_turf, source_door.dir, door_plan.opening_turf, door_plan.dir))
			continue
		if(get_dist(source_door.opening_turf, door_plan.opening_turf) <= radius)
			return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/building_v2_door_clearance_ok(datum/world_edit_building_v2_layout_candidate/candidate, datum/world_edit_building_v2_route_opening_plan/door_plan)
	if(!istype(candidate) || !istype(door_plan?.opening_turf))
		return FALSE
	return building_v2_opening_side_clear(candidate, get_step(door_plan.opening_turf, door_plan.dir)) && building_v2_opening_side_clear(candidate, get_step(door_plan.opening_turf, turn(door_plan.dir, 180)))

/datum/world_edit_generator/building_layout/proc/validate_building_v2_scene_quality(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate)
	var/datum/world_edit_building_layout_state/state = context?.state
	if(!istype(state))
		return
	var/list/global_slots = list()
	for(var/datum/world_edit_building_v2_room_plan/room_plan as anything in candidate.room_plans)
		var/datum/world_edit_building_v2_room_contract/room_contract = context.program_contract?.get_room_contract(room_plan?.contract_id)
		var/datum/world_edit_building_v2_scene_plan/scene_plan = room_plan?.scene_plan
		if(istype(room_contract) && room_contract.required && length(room_contract.required_scene_kinds) && !istype(scene_plan))
			state.validation.v2_scene_required_missing_count++
		if(!istype(scene_plan))
			continue
		var/turf/focus_turf = scene_plan.primary_anchors["focus"]
		if(!istype(focus_turf))
			state.validation.v2_primary_anchor_missing_count++
		if(!length(scene_plan.negative_space_turfs))
			state.validation.v2_negative_space_missing_count++
		for(var/list/member as anything in scene_plan.members)
			if(!islist(member))
				continue
			var/turf/member_turf = member["turf"]
			if(istype(member_turf) && scene_plan.no_furniture_lookup[member_turf] && member_turf != focus_turf)
				state.validation.v2_scene_blocks_negative_space_count++
		var/room_area = max(room_plan.area(), 1)
		var/occupancy_ratio = round(length(scene_plan.occupied_turfs) * 100 / room_area)
		var/datum/world_edit_building_v2_scene_contract/scene_contract = context.program_contract?.get_scene_contract(scene_plan.scene_contract_id)
		if(istype(scene_contract) && occupancy_ratio > scene_contract.max_occupancy_ratio)
			state.validation.v2_scene_overfill_count++
		for(var/scene_slot as anything in scene_plan.scene_slot_counts)
			var/global_slot = building_v2_global_scene_slot_key(scene_slot)
			global_slots[global_slot] = (global_slots[global_slot] || 0) + round(text2num("[scene_plan.scene_slot_counts[scene_slot]]") || 0)
	var/public_focal_count = round(text2num("[global_slots["public_focal"]]") || 0)
	if(public_focal_count > 1)
		state.validation.v2_duplicate_focal_scene_count += public_focal_count - 1
	for(var/scene_slot as anything in context.program_contract?.global_scene_slot_limits)
		var/limit = round(text2num("[context.program_contract.global_scene_slot_limits[scene_slot]]") || 0)
		var/current = round(text2num("[global_slots[scene_slot]]") || 0)
		if(limit > 0 && current > limit)
			state.validation.v2_scene_budget_overflow_count += current - limit
	for(var/scene_slot as anything in context.program_contract?.global_scene_slot_minimums)
		var/minimum = round(text2num("[context.program_contract.global_scene_slot_minimums[scene_slot]]") || 0)
		var/current = round(text2num("[global_slots[scene_slot]]") || 0)
		if(current < minimum)
			state.validation.v2_scene_budget_missing_required_count += minimum - current

/datum/world_edit_generator/building_layout/proc/validate_building_v2_window_quality(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate)
	var/datum/world_edit_building_layout_state/state = context?.state
	if(!istype(state))
		return
	for(var/datum/world_edit_building_v2_route_opening_plan/window_plan as anything in candidate.window_plans)
		if(!building_v2_window_plan_obeys_policy(context, candidate, window_plan))
			state.validation.v2_window_policy_violation_count++
	for(var/datum/world_edit_building_v2_room_plan/room_plan as anything in candidate.room_plans)
		var/datum/world_edit_building_v2_room_contract/room_contract = context.program_contract?.get_room_contract(room_plan?.contract_id)
		if(istype(room_contract) && (room_contract.window_policy == "required" || room_contract.exterior_window_policy == "required") && !building_v2_room_has_window(candidate, room_plan.id))
			state.validation.v2_window_policy_violation_count++

/datum/world_edit_generator/building_layout/proc/building_v2_room_has_window(datum/world_edit_building_v2_layout_candidate/candidate, room_id)
	for(var/datum/world_edit_building_v2_route_opening_plan/window_plan as anything in candidate?.window_plans)
		if(istype(window_plan) && window_plan.from_room == room_id)
			return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/building_v2_quality_has_hard_failures(datum/world_edit_building_v2_context/context)
	var/datum/world_edit_building_layout_validation_state/validation = context?.state?.validation
	if(!istype(validation))
		return TRUE
	if(validation.v2_empty_large_room_count > 0)
		return TRUE
	if(validation.v2_isolated_room_count > 0)
		return TRUE
	if(validation.v2_door_corner_count > 0)
		return TRUE
	if(validation.v2_door_not_on_shared_wall_count > 0)
		return TRUE
	if(validation.v2_door_no_shared_wall_count > 0)
		return TRUE
	if(validation.v2_door_short_segment_count > 0)
		return TRUE
	if(validation.v2_door_near_other_door_count > 0)
		return TRUE
	if(validation.v2_door_invalid_clearance_count > 0)
		return TRUE
	if(validation.v2_room_bad_aspect_count > 0)
		return TRUE
	if(validation.v2_room_thin_strip_count > 0)
		return TRUE
	if(validation.v2_room_scene_capacity_failed_count > 0)
		return TRUE
	if(validation.v2_scene_required_missing_count > 0)
		return TRUE
	if(validation.v2_primary_anchor_missing_count > 0)
		return TRUE
	if(validation.v2_negative_space_missing_count > 0)
		return TRUE
	if(validation.v2_scene_blocks_negative_space_count > 0)
		return TRUE
	if(validation.v2_scene_budget_overflow_count > 0)
		return TRUE
	if(validation.v2_scene_budget_missing_required_count > 0)
		return TRUE
	if(validation.v2_duplicate_focal_scene_count > 0)
		return TRUE
	if(validation.v2_window_policy_violation_count > 0)
		return TRUE
	return FALSE
