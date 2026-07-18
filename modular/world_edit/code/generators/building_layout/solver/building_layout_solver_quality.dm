/datum/world_edit_generator/building_layout/proc/get_layout_scene_room_solve_order(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate)
	var/list/signature_rooms = list()
	var/list/required_rooms = list()
	var/list/optional_rooms = list()
	if(!istype(context) || !istype(candidate))
		return required_rooms
	for(var/datum/world_edit_building_layout_room_plan/room_plan as anything in candidate.room_plans)
		var/datum/world_edit_building_layout_room_contract/room_contract = context.program_contract?.get_room_contract(room_plan?.contract_id)
		if(building_layout_room_has_required_scene_module(context, room_plan))
			signature_rooms += room_plan
		else if(istype(room_contract) && room_contract.required)
			required_rooms += room_plan
		else
			optional_rooms += room_plan
	return signature_rooms + required_rooms + optional_rooms

/datum/world_edit_generator/building_layout/proc/building_layout_room_has_required_scene_module(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_room_plan/room_plan)
	if(!istype(context?.program_contract) || !istype(room_plan))
		return FALSE
	for(var/datum/world_edit_building_layout_scene_contract/scene_contract as anything in context.program_contract.scene_contracts)
		if(!istype(scene_contract) || !(room_plan.contract_id in scene_contract.allowed_room_ids))
			continue
		if(length(scene_contract.required_modules))
			return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/building_layout_scene_budget_allows(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_scene_plan/scene_plan)
	if(!istype(context?.scene_budget) || !istype(scene_plan))
		return TRUE
	var/list/required_slot_counts = build_building_layout_scene_required_slot_counts(scene_plan)
	for(var/global_slot as anything in required_slot_counts)
		var/amount = round(text2num("[required_slot_counts[global_slot]]") || 0)
		if(amount <= 0)
			continue
		if(!context.scene_budget.can_use(global_slot, amount))
			return FALSE
	return TRUE

/datum/world_edit_generator/building_layout/proc/register_building_layout_scene_budget_use(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_scene_plan/scene_plan)
	if(!istype(context?.scene_budget) || !istype(scene_plan))
		return
	var/list/required_slot_counts = build_building_layout_scene_required_slot_counts(scene_plan)
	for(var/global_slot as anything in required_slot_counts)
		context.scene_budget.use(global_slot, required_slot_counts[global_slot])

/datum/world_edit_generator/building_layout/proc/build_building_layout_scene_required_slot_counts(datum/world_edit_building_layout_scene_plan/scene_plan)
	var/list/counts = list()
	if(!istype(scene_plan))
		return counts
	for(var/list/member as anything in scene_plan.members)
		if(!islist(member) || !GLOB.world_edit_helpers.parse_bool(member["major"]))
			continue
		var/global_slot = building_layout_global_scene_slot_key(member["category"])
		counts[global_slot] = (counts[global_slot] || 0) + 1
	return counts

/datum/world_edit_generator/building_layout/proc/select_building_layout_primary_anchor(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate, datum/world_edit_building_layout_room_plan/room_plan, datum/world_edit_building_layout_scene_contract/scene_contract)
	if(!istype(context) || !istype(candidate) || !istype(room_plan) || !istype(scene_contract))
		return null
	switch(scene_contract.primary_anchor_policy)
		if("far_wall", "longest_wall", "service_wall")
			return select_building_layout_scene_anchor(context, candidate, room_plan, "primary", scene_contract.scene_kind, scene_contract.scene_kind, null, TRUE, TRUE)
		if("near_window")
			return select_building_layout_window_primary_anchor(context, candidate, room_plan, scene_contract)
	return select_building_layout_scene_anchor(context, candidate, room_plan, "primary", scene_contract.scene_kind, scene_contract.scene_kind)

/datum/world_edit_generator/building_layout/proc/select_building_layout_window_primary_anchor(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate, datum/world_edit_building_layout_room_plan/room_plan, datum/world_edit_building_layout_scene_contract/scene_contract)
	var/list/best_anchor = null
	var/best_score = -999999999
	if(!istype(context) || !istype(candidate) || !istype(room_plan))
		return null
	for(var/datum/world_edit_building_layout_route_opening_plan/window_plan as anything in candidate.window_plans)
		if(!istype(window_plan?.opening_turf) || window_plan.from_room != room_plan.id)
			continue
		var/turf/interior_turf = get_step(window_plan.opening_turf, turn(window_plan.dir, 180))
		if(!room_plan.has_turf(interior_turf))
			continue
		var/score = score_building_layout_scene_turf(context, candidate, room_plan, interior_turf, scene_contract.scene_kind)
		if(!islist(best_anchor) || score > best_score)
			best_anchor = list("turf" = interior_turf, "dir" = window_plan.dir, "wall_dir" = turn(window_plan.dir, 180), "score" = score)
			best_score = score
	return best_anchor || select_building_layout_scene_anchor(context, candidate, room_plan, "primary", scene_contract.scene_kind, scene_contract.scene_kind)

/datum/world_edit_generator/building_layout/proc/register_building_layout_scene_hierarchy(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate, datum/world_edit_building_layout_room_plan/room_plan, datum/world_edit_building_layout_scene_contract/scene_contract, datum/world_edit_building_layout_scene_plan/scene_plan)
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
	if(!reserve_building_layout_negative_space(context, candidate, room_plan, scene_plan))
		candidate.errors += "scene.negative_space_missing:[room_plan.id]"
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
	if(!validate_building_layout_scene_composition(context, candidate, room_plan, scene_contract, scene_plan))
		candidate.errors += "scene.hierarchy_composition_failed:[room_plan.id]:members=[length(scene_plan.members)]:occupied=[length(scene_plan.occupied_turfs)]:negative=[length(scene_plan.negative_space_turfs)]:area=[room_plan.area()]"
		return FALSE
	return TRUE

/datum/world_edit_generator/building_layout/proc/reserve_building_layout_negative_space(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate, datum/world_edit_building_layout_room_plan/room_plan, datum/world_edit_building_layout_scene_plan/scene_plan)
	if(!istype(room_plan) || !istype(scene_plan))
		return FALSE
	var/turf/focus_turf = scene_plan.primary_anchors["focus"]
	if(!istype(focus_turf))
		return FALSE
	var/list/door_turfs = get_building_layout_room_door_turfs(candidate, room_plan.id)
	if(!length(door_turfs))
		return FALSE
	var/list/occupied_lookup = list()
	for(var/list/member as anything in scene_plan.members)
		if(!islist(member))
			continue
		var/turf/member_turf = member["turf"]
		if(istype(member_turf) && GLOB.world_edit_helpers.parse_bool(member["major"]))
			occupied_lookup[member_turf] = TRUE
	for(var/turf/door_turf as anything in door_turfs)
		var/turf/start_turf = get_building_layout_room_door_inside_turf(candidate, room_plan, door_turf)
		if(istype(start_turf) && start_turf != focus_turf && !occupied_lookup[start_turf])
			scene_plan.negative_space_turfs |= start_turf
			scene_plan.no_furniture_lookup[start_turf] = TRUE
		var/list/path = build_building_layout_room_internal_path(room_plan, start_turf, focus_turf, occupied_lookup)
		for(var/turf/path_turf as anything in path)
			if(!istype(path_turf) || path_turf == focus_turf)
				continue
			scene_plan.negative_space_turfs += path_turf
			scene_plan.no_furniture_lookup[path_turf] = TRUE
	if(length(scene_plan.negative_space_turfs))
		for(var/member_index = length(scene_plan.members), member_index >= 1, member_index--)
			var/list/member = scene_plan.members[member_index]
			if(!islist(member) || GLOB.world_edit_helpers.parse_bool(member["major"]))
				continue
			var/turf/member_turf = member["turf"]
			if(!scene_plan.no_furniture_lookup[member_turf])
				continue
			scene_plan.members.Cut(member_index, member_index + 1)
			scene_plan.occupied_turfs -= member_turf
	if(!length(scene_plan.negative_space_turfs))
		context.state?.add_stage_report("layout_negative_space", "failed", "no_door_to_focus_path", list(
			"room_id" = room_plan.id,
			"scene_id" = scene_plan.scene_contract_id,
			"focus" = istype(focus_turf) ? "[focus_turf.x],[focus_turf.y],[focus_turf.z]" : "",
			"door_count" = length(door_turfs),
			"member_count" = length(scene_plan.members),
		))
	return length(scene_plan.negative_space_turfs) > 0

/datum/world_edit_generator/building_layout/proc/get_building_layout_room_door_turfs(datum/world_edit_building_layout_candidate/candidate, room_id)
	var/list/door_turfs = list()
	if(!istype(candidate))
		return door_turfs
	for(var/datum/world_edit_building_layout_route_opening_plan/door_plan as anything in candidate.opening_plans)
		if(!istype(door_plan?.opening_turf) || door_plan.kind == "main_exit")
			continue
		if(door_plan.from_room == room_id || door_plan.to_room == room_id)
			door_turfs += get_building_layout_opening_plan_turfs(door_plan)
	return door_turfs

/datum/world_edit_generator/building_layout/proc/get_building_layout_room_door_inside_turf(datum/world_edit_building_layout_candidate/candidate, datum/world_edit_building_layout_room_plan/room_plan, turf/door_turf)
	if(!istype(candidate) || !istype(room_plan) || !istype(door_turf))
		return null
	for(var/datum/world_edit_building_layout_route_opening_plan/door_plan as anything in candidate.opening_plans)
		if(!istype(door_plan) || !(door_turf in get_building_layout_opening_plan_turfs(door_plan)))
			continue
		var/turf/front_turf = get_step(door_turf, door_plan.dir)
		if(room_plan.has_turf(front_turf))
			return front_turf
		var/turf/back_turf = get_step(door_turf, turn(door_plan.dir, 180))
		if(room_plan.has_turf(back_turf))
			return back_turf
	return null

/datum/world_edit_generator/building_layout/proc/build_building_layout_room_internal_path(datum/world_edit_building_layout_room_plan/room_plan, turf/start_turf, turf/focus_turf, list/occupied_lookup = null)
	var/list/path_x_first = build_building_layout_room_internal_path_order(room_plan, start_turf, focus_turf, TRUE)
	var/list/path_y_first = build_building_layout_room_internal_path_order(room_plan, start_turf, focus_turf, FALSE)
	if(!islist(occupied_lookup))
		return length(path_x_first) <= length(path_y_first) ? path_x_first : path_y_first
	if(istype(room_plan) && istype(start_turf) && istype(focus_turf))
		var/list/open = list(start_turf)
		var/list/seen = list()
		seen[start_turf] = TRUE
		var/list/previous = list()
		var/turf/found = null
		var/expansions = 0
		while(length(open) && expansions < min(max(room_plan.area() * 4, 1), WORLD_EDIT_BUILDING_MAX_ROUTE_EXPANSIONS))
			var/turf/current = open[1]
			open.Cut(1, 2)
			if(current == focus_turf)
				found = current
				break
			for(var/check_dir in GLOB.cardinals)
				var/turf/nearby = get_step(current, check_dir)
				if(!istype(nearby) || seen[nearby] || !room_plan.has_turf(nearby) || (occupied_lookup[nearby] && nearby != focus_turf))
					continue
				seen[nearby] = TRUE
				previous[nearby] = current
				open += nearby
			expansions++
		if(istype(found))
			var/list/bfs_path = list()
			var/turf/path_turf = found
			while(istype(path_turf))
				bfs_path.Insert(1, path_turf)
				if(path_turf == start_turf)
					break
				path_turf = previous[path_turf]
			return bfs_path
	var/x_blocks = count_building_layout_path_occupied(path_x_first, occupied_lookup, focus_turf)
	var/y_blocks = count_building_layout_path_occupied(path_y_first, occupied_lookup, focus_turf)
	return x_blocks <= y_blocks ? path_x_first : path_y_first

/datum/world_edit_generator/building_layout/proc/build_building_layout_room_internal_path_order(datum/world_edit_building_layout_room_plan/room_plan, turf/start_turf, turf/focus_turf, x_first = TRUE)
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

/datum/world_edit_generator/building_layout/proc/count_building_layout_path_occupied(list/path, list/occupied_lookup, turf/focus_turf)
	var/count = 0
	for(var/turf/path_turf as anything in path)
		if(istype(path_turf) && path_turf != focus_turf && occupied_lookup[path_turf])
			count++
	return count

/datum/world_edit_generator/building_layout/proc/validate_building_layout_scene_composition(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate, datum/world_edit_building_layout_room_plan/room_plan, datum/world_edit_building_layout_scene_contract/scene_contract, datum/world_edit_building_layout_scene_plan/scene_plan)
	if(!istype(scene_contract) || !istype(scene_plan))
		return FALSE
	var/turf/focus_turf = scene_plan.primary_anchors["focus"]
	if(!istype(focus_turf))
		return FALSE
	if(scene_contract.min_negative_space_tiles > 0 && length(scene_plan.negative_space_turfs) < scene_contract.min_negative_space_tiles)
		candidate?.errors += "scene.composition_negative_short:[room_plan?.id]:[length(scene_plan.negative_space_turfs)]/[scene_contract.min_negative_space_tiles]"
		return FALSE
	for(var/list/member as anything in scene_plan.members)
		if(!islist(member))
			continue
		var/turf/member_turf = member["turf"]
		if(istype(member_turf) && scene_plan.no_furniture_lookup[member_turf] && member_turf != focus_turf)
			candidate?.errors += "scene.composition_member_in_negative:[room_plan?.id]:[member["slot"]]:[member_turf.x],[member_turf.y]"
			return FALSE
	var/room_area = max(room_plan?.area() || 0, 1)
	var/occupancy_ratio = round(length(scene_plan.occupied_turfs) * 100 / room_area)
	if(occupancy_ratio > scene_contract.max_occupancy_ratio)
		candidate?.errors += "scene.composition_overfill:[room_plan?.id]:[occupancy_ratio]/[scene_contract.max_occupancy_ratio]"
		return FALSE
	return TRUE

/datum/world_edit_generator/building_layout/proc/mark_building_layout_scene_negative_space(datum/world_edit_building_layout_state/state, datum/world_edit_building_layout_scene_plan/scene_plan)
	if(!istype(state) || !istype(scene_plan))
		return
	for(var/turf/negative_turf as anything in scene_plan.negative_space_turfs)
		if(!istype(negative_turf))
			continue
		state.fixtures.scene_negative_space_lookup[negative_turf] = TRUE
		state.fixtures.scene_no_furniture_lookup[negative_turf] = TRUE

/datum/world_edit_generator/building_layout/proc/validate_building_layout_quality(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate)
	var/datum/world_edit_building_layout_state/state = context?.state
	if(!istype(state) || !istype(candidate))
		return FALSE
	validate_building_layout_room_quality(context, candidate)
	validate_building_layout_opening_quality(context, candidate)
	validate_building_layout_scene_quality(context, candidate)
	validate_building_layout_window_quality(context, candidate)
	validate_building_layout_architectural_quality(context, candidate)
	return !building_layout_quality_has_hard_failures(context)

/datum/world_edit_generator/building_layout/proc/validate_building_layout_room_quality(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate)
	var/datum/world_edit_building_layout_state/state = context?.state
	if(!istype(state))
		return
	for(var/datum/world_edit_building_layout_room_plan/room_plan as anything in candidate.room_plans)
		if(!istype(room_plan))
			continue
		var/datum/world_edit_building_layout_room_contract/room_contract = context.program_contract?.get_room_contract(room_plan.contract_id)
		var/room_min_dim = min(room_plan.width(), room_plan.height())
		var/room_max_dim = max(room_plan.width(), room_plan.height())
		var/aspect = room_max_dim / max(room_min_dim, 1)
		if(istype(room_contract) && aspect > max(room_contract.max_aspect, 1))
			state.validation.layout_room_bad_aspect_count++
		if(room_plan.area() >= 12 && (room_min_dim <= 2 || room_max_dim > room_min_dim * 4))
			state.validation.layout_room_thin_strip_count++
		if(istype(room_contract) && room_contract.required && room_contract.must_touch_route && !building_layout_room_has_valid_route_connection(candidate, room_plan.id))
			state.validation.layout_isolated_room_count++
		var/scene_member_count = istype(room_plan.scene_plan) ? length(room_plan.scene_plan.members) : 0
		if(room_plan.area() >= 16 && scene_member_count <= 1 && !(room_plan.role in list("storage", "route")) && !(room_plan.contract_id in list("sanitation", "utility")))
			state.validation.layout_empty_large_room_count++
		if(istype(room_contract) && length(room_contract.required_scene_kinds) && !building_layout_room_can_fit_required_scene(context, build_building_layout_rect(room_plan.x1, room_plan.y1, room_plan.x2, room_plan.y2), room_contract))
			state.validation.layout_room_scene_capacity_failed_count++

/datum/world_edit_generator/building_layout/proc/building_layout_room_has_valid_route_connection(datum/world_edit_building_layout_candidate/candidate, room_id)
	if(!istype(candidate))
		return FALSE
	var/list/open = list("route")
	var/list/seen = list("route" = TRUE)
	while(length(open))
		var/current_id = open[1]
		open.Cut(1, 2)
		if(current_id == "[room_id]")
			return TRUE
		for(var/datum/world_edit_building_layout_route_opening_plan/door_plan as anything in candidate.opening_plans)
			if(!istype(door_plan) || door_plan.kind == "main_exit")
				continue
			var/next_id = ""
			if(door_plan.from_room == current_id)
				next_id = door_plan.to_room
			else if(door_plan.to_room == current_id)
				next_id = door_plan.from_room
			if(!length(next_id) || seen[next_id])
				continue
			seen[next_id] = TRUE
			open += next_id
	return FALSE

/datum/world_edit_generator/building_layout/proc/validate_building_layout_opening_quality(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate)
	var/datum/world_edit_building_layout_state/state = context?.state
	if(!istype(state))
		return
	for(var/datum/world_edit_building_layout_route_opening_plan/door_plan as anything in candidate.opening_plans)
		if(!istype(door_plan) || door_plan.kind == "main_exit")
			continue
		if(!building_layout_door_plan_has_valid_shared_wall(context, candidate, door_plan))
			state.validation.layout_door_not_on_shared_wall_count++
		var/segment_length = building_layout_door_plan_segment_length(context, candidate, door_plan)
		if(segment_length <= 0)
			state.validation.layout_door_no_shared_wall_count++
		var/datum/world_edit_building_layout_room_contract/room_contract = context.program_contract?.get_room_contract(door_plan.from_room == "route" ? door_plan.to_room : door_plan.from_room)
		var/min_opening_width = istype(room_contract) ? max(room_contract.min_route_opening_width, 1) : 1
		if(segment_length > 0 && segment_length < min_opening_width)
			state.validation.layout_door_short_segment_count++
		var/emits_door_object = building_layout_opening_plan_emits_door_object(context, door_plan)
		if(emits_door_object && building_layout_door_plan_at_segment_end(context, candidate, door_plan) && !building_layout_opening_has_wall_shoulders(candidate, door_plan.opening_turf, door_plan.dir))
			state.validation.layout_door_corner_count++
			state.add_stage_report("layout_door_corner", "failed", "controlled opening lacks an intact wall shoulder", list("opening_id" = door_plan.id, "x" = door_plan.opening_turf.x, "y" = door_plan.opening_turf.y, "z" = door_plan.opening_turf.z, "dir" = door_plan.dir))
		if(emits_door_object && building_layout_opening_near_other_door_excluding(candidate, door_plan, 1))
			state.validation.layout_door_near_other_door_count++
		if(!building_layout_door_clearance_ok(candidate, door_plan))
			state.validation.layout_door_invalid_clearance_count++

/datum/world_edit_generator/building_layout/proc/building_layout_door_plan_segment_length(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate, datum/world_edit_building_layout_route_opening_plan/door_plan)
	var/list/from_lookup = get_building_layout_region_lookup(candidate, door_plan?.from_room)
	var/list/to_lookup = get_building_layout_region_lookup(candidate, door_plan?.to_room)
	return building_layout_shared_wall_run_length_for_regions(context, candidate, from_lookup, to_lookup, door_plan?.opening_turf, door_plan?.dir)

/datum/world_edit_generator/building_layout/proc/building_layout_door_plan_at_segment_end(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate, datum/world_edit_building_layout_route_opening_plan/door_plan)
	var/list/from_lookup = get_building_layout_region_lookup(candidate, door_plan?.from_room)
	var/list/to_lookup = get_building_layout_region_lookup(candidate, door_plan?.to_room)
	return building_layout_opening_at_segment_end_for_regions(context, candidate, from_lookup, to_lookup, door_plan?.opening_turf, door_plan?.dir)

/datum/world_edit_generator/building_layout/proc/building_layout_opening_near_other_door_excluding(datum/world_edit_building_layout_candidate/candidate, datum/world_edit_building_layout_route_opening_plan/source_door, radius = 2)
	if(source_door?.public_opening)
		return FALSE
	for(var/datum/world_edit_building_layout_route_opening_plan/door_plan as anything in candidate?.opening_plans)
		if(!istype(door_plan?.opening_turf) || door_plan == source_door || door_plan.public_opening)
			continue
		for(var/turf/source_turf as anything in get_building_layout_opening_plan_turfs(source_door))
			for(var/turf/other_turf as anything in get_building_layout_opening_plan_turfs(door_plan))
				if(building_layout_openings_are_opposite_route_pair(candidate, source_turf, source_door.dir, other_turf, door_plan.dir))
					continue
				if(get_dist(source_turf, other_turf) <= radius)
					return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/building_layout_door_clearance_ok(datum/world_edit_building_layout_candidate/candidate, datum/world_edit_building_layout_route_opening_plan/door_plan)
	if(!istype(candidate) || !istype(door_plan?.opening_turf))
		return FALSE
	for(var/turf/opening_turf as anything in get_building_layout_opening_plan_turfs(door_plan))
		if(!building_layout_opening_side_clear(candidate, get_step(opening_turf, door_plan.dir)) || !building_layout_opening_side_clear(candidate, get_step(opening_turf, turn(door_plan.dir, 180))))
			return FALSE
	return TRUE

/datum/world_edit_generator/building_layout/proc/validate_building_layout_scene_quality(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate)
	var/datum/world_edit_building_layout_state/state = context?.state
	if(!istype(state))
		return
	var/list/global_slots = list()
	for(var/datum/world_edit_building_layout_room_plan/room_plan as anything in candidate.room_plans)
		var/datum/world_edit_building_layout_room_contract/room_contract = context.program_contract?.get_room_contract(room_plan?.contract_id)
		var/datum/world_edit_building_layout_scene_plan/scene_plan = room_plan?.scene_plan
		if(istype(room_contract) && room_contract.required && length(room_contract.required_scene_kinds) && !istype(scene_plan))
			state.validation.layout_scene_required_missing_count++
		if(!istype(scene_plan))
			continue
		var/turf/focus_turf = scene_plan.primary_anchors["focus"]
		if(!istype(focus_turf))
			state.validation.layout_primary_anchor_missing_count++
		if(!length(scene_plan.negative_space_turfs))
			state.validation.layout_negative_space_missing_count++
		for(var/list/member as anything in scene_plan.members)
			if(!islist(member))
				continue
			var/turf/member_turf = member["turf"]
			if(istype(member_turf) && scene_plan.no_furniture_lookup[member_turf] && member_turf != focus_turf)
				state.validation.layout_scene_blocks_negative_space_count++
		var/room_area = max(room_plan.area(), 1)
		var/occupancy_ratio = round(length(scene_plan.occupied_turfs) * 100 / room_area)
		var/datum/world_edit_building_layout_scene_contract/scene_contract = context.program_contract?.get_scene_contract(scene_plan.scene_contract_id)
		if(istype(scene_contract) && occupancy_ratio > scene_contract.max_occupancy_ratio)
			state.validation.layout_scene_overfill_count++
		for(var/scene_slot as anything in scene_plan.scene_slot_counts)
			var/global_slot = building_layout_global_scene_slot_key(scene_slot)
			global_slots[global_slot] = (global_slots[global_slot] || 0) + round(text2num("[scene_plan.scene_slot_counts[scene_slot]]") || 0)
	var/public_focal_count = round(text2num("[global_slots["public_focal"]]") || 0)
	if(public_focal_count > 1)
		state.validation.layout_duplicate_focal_scene_count += public_focal_count - 1
	for(var/scene_slot as anything in context.program_contract?.global_scene_slot_limits)
		var/limit = round(text2num("[context.program_contract.global_scene_slot_limits[scene_slot]]") || 0)
		var/current = round(text2num("[global_slots[scene_slot]]") || 0)
		if(limit > 0 && current > limit)
			state.validation.layout_scene_budget_overflow_count += current - limit
	for(var/scene_slot as anything in context.program_contract?.global_scene_slot_minimums)
		var/minimum = round(text2num("[context.program_contract.global_scene_slot_minimums[scene_slot]]") || 0)
		var/current = round(text2num("[global_slots[scene_slot]]") || 0)
		if(current < minimum)
			state.validation.layout_scene_budget_missing_required_count += minimum - current

/datum/world_edit_generator/building_layout/proc/validate_building_layout_window_quality(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate)
	var/datum/world_edit_building_layout_state/state = context?.state
	if(!istype(state))
		return
	for(var/datum/world_edit_building_layout_route_opening_plan/window_plan as anything in candidate.window_plans)
		if(!building_layout_window_plan_obeys_policy(context, candidate, window_plan))
			state.validation.layout_window_policy_violation_count++
	for(var/datum/world_edit_building_layout_room_plan/room_plan as anything in candidate.room_plans)
		var/datum/world_edit_building_layout_room_contract/room_contract = context.program_contract?.get_room_contract(room_plan?.contract_id)
		if(istype(room_contract) && (room_contract.window_policy == "required" || room_contract.exterior_window_policy == "required") && !building_layout_room_has_window(candidate, room_plan.id))
			state.validation.layout_window_policy_violation_count++

/datum/world_edit_generator/building_layout/proc/building_layout_room_has_window(datum/world_edit_building_layout_candidate/candidate, room_id)
	for(var/datum/world_edit_building_layout_route_opening_plan/window_plan as anything in candidate?.window_plans)
		if(istype(window_plan) && window_plan.from_room == room_id)
			return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/validate_building_layout_architectural_quality(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate)
	var/datum/world_edit_building_layout_state/state = context?.state
	if(!istype(state) || !istype(candidate))
		return
	validate_building_layout_public_openings(context, candidate)
	validate_building_layout_opposing_route_doors(state, candidate)
	validate_building_layout_route_wall_canyons(state)
	validate_building_layout_template_reject_quality(state)
	validate_building_layout_candidate_diversity(state)

/datum/world_edit_generator/building_layout/proc/validate_building_layout_public_openings(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate)
	var/datum/world_edit_building_layout_state/state = context?.state
	if(!istype(state))
		return
	for(var/datum/world_edit_building_layout_room_plan/room_plan as anything in candidate?.room_plans)
		var/datum/world_edit_building_layout_room_contract/room_contract = context.program_contract?.get_room_contract(room_plan?.contract_id)
		if(!istype(room_contract) || !(room_contract.partition_policy in list(WORLD_EDIT_BUILDING_PARTITION_OPEN, WORLD_EDIT_BUILDING_PARTITION_SOFT)))
			continue
		var/public_opening_tiles = count_building_layout_room_public_opening_tiles(context, candidate, room_plan.id)
		if(public_opening_tiles <= 0)
			state.validation.layout_public_room_hard_closed_count++
			state.validation.layout_public_opening_missing_count++

/datum/world_edit_generator/building_layout/proc/count_building_layout_room_public_opening_tiles(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate, room_id)
	var/count = 0
	for(var/datum/world_edit_building_layout_route_opening_plan/opening_plan as anything in candidate?.opening_plans)
		if(!istype(opening_plan) || !building_layout_opening_plan_is_public(context, opening_plan))
			continue
		if(opening_plan.from_room == room_id || opening_plan.to_room == room_id)
			count += length(get_building_layout_opening_plan_turfs(opening_plan))
	return count

/datum/world_edit_generator/building_layout/proc/validate_building_layout_opposing_route_doors(datum/world_edit_building_layout_state/state, datum/world_edit_building_layout_candidate/candidate)
	if(!istype(state) || !istype(candidate))
		return
	var/list/physical_doors = list()
	for(var/datum/world_edit_building_layout_route_opening_plan/door_plan as anything in candidate.opening_plans)
		if(!istype(door_plan) || !building_layout_opening_plan_emits_door_object(state.layout_context, door_plan) || door_plan.kind == "main_exit")
			continue
		for(var/turf/opening_turf as anything in get_building_layout_opening_plan_turfs(door_plan))
			if(istype(opening_turf))
				physical_doors += list(list("turf" = opening_turf, "dir" = door_plan.dir))
	for(var/i in 1 to length(physical_doors))
		if(i >= length(physical_doors))
			continue
		var/list/a = physical_doors[i]
		for(var/j in i + 1 to length(physical_doors))
			var/list/b = physical_doors[j]
			if(building_layout_openings_are_opposite_route_pair(candidate, a["turf"], a["dir"], b["turf"], b["dir"]))
				state.validation.layout_opposing_route_door_pair_count++

/datum/world_edit_generator/building_layout/proc/validate_building_layout_route_wall_canyons(datum/world_edit_building_layout_state/state)
	if(!istype(state))
		return
	var/list/opening_lookup = list()
	for(var/datum/world_edit_building_layout_route_opening_plan/opening_plan as anything in state.geometry.layout_route_opening_plans)
		if(!istype(opening_plan))
			continue
		for(var/turf/opening_turf as anything in get_building_layout_opening_plan_turfs(opening_plan))
			if(istype(opening_turf))
				opening_lookup[opening_turf] = TRUE
	var/canyon_len = 0
	for(var/turf/route_turf as anything in state.geometry.primary_route_turfs)
		if(!istype(route_turf))
			continue
		if(opening_lookup[route_turf])
			continue
		var/turf/east_turf = get_step(route_turf, EAST)
		var/turf/west_turf = get_step(route_turf, WEST)
		var/turf/north_turf = get_step(route_turf, NORTH)
		var/turf/south_turf = get_step(route_turf, SOUTH)
		var/ns_canyon = state.geometry.wall_lookup[east_turf] && !opening_lookup[east_turf] && state.geometry.wall_lookup[west_turf] && !opening_lookup[west_turf]
		var/ew_canyon = state.geometry.wall_lookup[north_turf] && !opening_lookup[north_turf] && state.geometry.wall_lookup[south_turf] && !opening_lookup[south_turf]
		if(ns_canyon || ew_canyon)
			canyon_len++
	state.validation.layout_route_wall_canyon_length = canyon_len
	var/allowed = max(7, round(length(state.geometry.primary_route_turfs) * 0.35))
	if(canyon_len > allowed)
		state.validation.layout_corridor_wall_canyon_count += canyon_len - allowed
	var/floor_count = max(length(state.geometry.floor_turfs), 1)
	var/wall_ratio = round(length(state.geometry.wall_lookup) * 100 / floor_count)
	if(wall_ratio > 95)
		state.validation.layout_excessive_wall_to_floor_ratio_count++

/datum/world_edit_generator/building_layout/proc/validate_building_layout_template_reject_quality(datum/world_edit_building_layout_state/state)
	if(!istype(state) || !islist(state.validation.template_reject_reason_counts))
		return
	state.validation.layout_template_geometry_reject_count = round(text2num("[state.validation.template_reject_reason_counts["template_geometry_conflict"]]") || 0)
	state.validation.layout_missing_wall_context_reject_count = round(text2num("[state.validation.template_reject_reason_counts["missing_wall_context"]]") || 0)

/datum/world_edit_generator/building_layout/proc/validate_building_layout_candidate_diversity(datum/world_edit_building_layout_state/state)
	if(!istype(state) || GLOB.world_edit_helpers.parse_bool(state.config["layout_trial_emission"]) || isnull(state.config["layout_hard_valid_candidate_count"]))
		return
	var/is_compact = is_building_compact_or_micro_state(state)
	var/min_hard_valid_candidates = is_compact ? 1 : 2
	var/min_distinct_families = is_compact ? 1 : 2
	var/hard_valid_count = round(text2num("[state.config["layout_hard_valid_candidate_count"]]") || 0)
	var/distinct_family_count = round(text2num("[state.config["layout_distinct_hard_valid_family_count"]]") || 0)
	state.add_stage_report("layout_candidate_diversity", "ok", null, list(
		"is_compact" = is_compact,
		"size_profile" = state.config["size_profile"],
		"half_width" = state.config["half_width"],
		"half_depth" = state.config["half_depth"],
		"geometry_width" = state.geometry?.bounds?["width"],
		"geometry_height" = state.geometry?.bounds?["height"],
		"hard_valid_count" = hard_valid_count,
		"min_hard_valid_candidates" = min_hard_valid_candidates,
		"distinct_family_count" = distinct_family_count,
		"min_distinct_families" = min_distinct_families,
	))
	if(hard_valid_count < min_hard_valid_candidates || distinct_family_count < min_distinct_families)
		state.validation.layout_hard_valid_candidate_shortage_count++

/datum/world_edit_generator/building_layout/proc/building_layout_quality_has_hard_failures(datum/world_edit_building_layout_context/context)
	var/datum/world_edit_building_layout_validation_state/validation = context?.state?.validation
	if(!istype(validation))
		return TRUE
	if(validation.layout_empty_large_room_count > 0)
		return TRUE
	if(validation.layout_isolated_room_count > 0)
		return TRUE
	if(validation.layout_door_corner_count > 0)
		return TRUE
	if(validation.layout_door_not_on_shared_wall_count > 0)
		return TRUE
	if(validation.layout_door_no_shared_wall_count > 0)
		return TRUE
	if(validation.layout_door_short_segment_count > 0)
		return TRUE
	if(validation.layout_door_near_other_door_count > 0)
		return TRUE
	if(validation.layout_door_invalid_clearance_count > 0)
		return TRUE
	if(validation.layout_room_bad_aspect_count > 0)
		return TRUE
	if(validation.layout_room_thin_strip_count > 0)
		return TRUE
	if(validation.layout_room_scene_capacity_failed_count > 0)
		return TRUE
	if(validation.layout_scene_required_missing_count > 0)
		return TRUE
	if(validation.layout_primary_anchor_missing_count > 0)
		return TRUE
	if(validation.layout_negative_space_missing_count > 0)
		return TRUE
	if(validation.layout_scene_blocks_negative_space_count > 0)
		return TRUE
	if(validation.layout_scene_budget_overflow_count > 0)
		return TRUE
	if(validation.layout_scene_budget_missing_required_count > 0)
		return TRUE
	if(validation.layout_duplicate_focal_scene_count > 0)
		return TRUE
	if(validation.layout_window_policy_violation_count > 0)
		return TRUE
	if(validation.layout_public_room_hard_closed_count > 0)
		return TRUE
	if(validation.layout_public_opening_missing_count > 0)
		return TRUE
	if(validation.layout_corridor_wall_canyon_count > 0)
		return TRUE
	if(validation.layout_hard_valid_candidate_shortage_count > 0)
		return TRUE
	if(validation.layout_underfurnished_room_count > 0)
		return TRUE
	if(validation.large_sparse_room_count > 0)
		return TRUE
	if(validation.layout_scene_underfill_count > 0)
		return TRUE
	if(validation.layout_room_composition_missing_count > 0)
		return TRUE
	if(validation.layout_room_capacity_shortfall_count > 0)
		return TRUE
	if(validation.layout_required_adjacency_missing_count > 0)
		return TRUE
	if(validation.layout_required_adjacency_geometry_missing_count > 0)
		return TRUE
	if(validation.layout_unassigned_interior_excess_count > 0)
		return TRUE
	if(validation.layout_ownerless_open_bay_count > 0)
		return TRUE
	if(validation.layout_route_component_error_count > 0)
		return TRUE
	if(validation.layout_wall_stub_count > 0)
		return TRUE
	if(validation.layout_wall_notch_count > 0)
		return TRUE
	if(validation.layout_wall_stair_step_count > 0)
		return TRUE
	if(validation.layout_wall_misaligned_join_count > 0)
		return TRUE
	if(validation.layout_atomic_module_fragmentation_count > 0)
		return TRUE
	if(validation.layout_required_module_fallback_count > 0)
		return TRUE
	if(validation.layout_required_template_reject_count > 0)
		return TRUE
	if(validation.layout_wall_cleanup_unmapped_count > 0)
		return TRUE
	if(validation.layout_wall_cleanup_spur_count > 0)
		return TRUE
	if(validation.layout_functional_room_count_gap > 0)
		return TRUE
	if(validation.layout_candidate_metric_mismatch_count > 0)
		return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/validate_building_layout_review_contract(datum/world_edit_building_layout_state/state)
	if(!istype(state))
		return
	var/datum/world_edit_building_layout_context/context = state.layout_context
	var/datum/world_edit_building_layout_candidate/candidate = context?.selected_candidate
	var/datum/world_edit_building_layout_program_contract/program = context?.program_contract
	if(!istype(candidate) || !istype(program))
		return
	state.validation.layout_functional_room_count = 0
	state.validation.layout_circulation_region_count = 0
	state.validation.layout_room_composition_missing_count = 0
	state.validation.layout_room_capacity_shortfall_count = 0
	state.validation.layout_required_adjacency_missing_count = 0
	state.validation.layout_required_adjacency_geometry_missing_count = 0
	state.validation.layout_unassigned_interior_turf_count = 0
	state.validation.layout_unassigned_interior_ratio_percent = 0
	state.validation.layout_unassigned_interior_excess_count = 0
	state.validation.layout_ownerless_open_bay_count = 0
	state.validation.layout_route_component_count = 0
	state.validation.layout_route_component_error_count = 0
	state.validation.layout_wall_stub_count = 0
	state.validation.layout_wall_notch_count = 0
	state.validation.layout_wall_stair_step_count = 0
	state.validation.layout_wall_misaligned_join_count = 0
	state.validation.layout_atomic_module_fragmentation_count = 0
	state.validation.layout_scene_underfill_count = 0
	state.validation.layout_underfurnished_room_count = 0
	state.validation.layout_candidate_metric_mismatch_count = 0
	for(var/datum/world_edit_building_layout_room_plan/room_plan as anything in candidate.room_plans)
		if(!istype(room_plan))
			continue
		var/datum/world_edit_building_layout_room_contract/room_contract = program.get_room_contract(room_plan.contract_id)
		if(istype(room_contract) && !room_contract.counts_toward_target)
			state.validation.layout_circulation_region_count++
			continue
		state.validation.layout_functional_room_count++
		var/datum/world_edit_building_layout_scene_plan/scene_plan = room_plan.scene_plan
		var/list/occupied_lookup = list()
		var/member_count = 0
		var/bed_capacity = 0
		if(istype(scene_plan))
			for(var/list/member as anything in scene_plan.members)
				if(!islist(member))
					continue
				var/turf/member_turf = member["turf"]
				if(istype(member_turf))
					occupied_lookup[member_turf] = TRUE
				member_count++
				if("[member["slot"]]" == "bed")
					bed_capacity++
		if(!istype(scene_plan) || member_count <= 0)
			state.validation.layout_room_composition_missing_count++
			state.add_stage_report("layout_room_composition_missing", "failed", "functional room has no authored scene", list(
				"room_id" = room_plan.id,
				"contract_id" = room_plan.contract_id,
				"role" = room_plan.role,
				"area" = room_plan.area(),
				"width" = room_plan.width(),
				"height" = room_plan.height(),
			))
		else
			var/datum/world_edit_building_layout_composition_contract/composition = program.get_composition_contract(room_plan.contract_id)
			var/missing_required_group_count = 0
			for(var/datum/world_edit_building_cluster_spec/required_group as anything in composition?.required_groups)
				if(!building_layout_scene_contains_required_group(scene_plan, required_group))
					missing_required_group_count++
			if(missing_required_group_count > 0)
				state.validation.layout_scene_underfill_count += missing_required_group_count
				state.validation.layout_underfurnished_room_count += missing_required_group_count
				state.add_stage_report("layout_room_composition_underfill", "failed", "authored required composition group is missing", list(
					"room_id" = room_plan.id,
					"contract_id" = room_plan.contract_id,
					"missing_group_count" = missing_required_group_count,
					"member_count" = member_count,
				))
		if(room_plan.role == "private" && room_plan.scene_kind == "bedroom" && istype(room_contract) && room_contract.instance_index > 1 && bed_capacity < 2)
			state.validation.layout_room_capacity_shortfall_count++
	var/list/circulation_zone_lookup = list()
	for(var/turf/circulation_turf as anything in candidate.route_zone_by_turf)
		var/zone_id = "[candidate.route_zone_by_turf[circulation_turf] || ""]"
		if(length(zone_id) && zone_id != "circulation_open_bay")
			circulation_zone_lookup[zone_id] = TRUE
	state.validation.layout_circulation_region_count = length(circulation_zone_lookup)
	state.validation.layout_target_functional_room_count = program.target_room_count
	state.validation.layout_functional_room_count_gap = abs(program.target_room_count - state.validation.layout_functional_room_count)
	var/reported_candidate_count = round(text2num("[state.config["layout_candidate_count"]]") || 0)
	var/reported_hard_valid_count = round(text2num("[state.config["layout_hard_valid_candidate_count"]]") || 0)
	if(reported_candidate_count <= 0 || reported_hard_valid_count > reported_candidate_count || "[state.config["layout_candidate_id"]]" != candidate.id)
		state.validation.layout_candidate_metric_mismatch_count++
	for(var/datum/world_edit_building_layout_connection_contract/connection_contract as anything in program.connection_contracts)
		if(!istype(connection_contract) || !connection_contract.required)
			continue
		var/from_endpoint = normalize_building_layout_topology_endpoint(program, connection_contract.from_room)
		var/to_endpoint = normalize_building_layout_topology_endpoint(program, connection_contract.to_room)
		var/circulation_edge = from_endpoint == "route" && to_endpoint == "route"
		if(!(circulation_edge ? building_layout_candidate_has_circulation_edge(candidate, program, connection_contract) : building_layout_candidate_has_required_topology_edge(candidate, from_endpoint, to_endpoint)))
			state.validation.layout_required_adjacency_missing_count++
			state.add_stage_report("layout_required_adjacency", "failed", "candidate topology edge is missing", list("from" = connection_contract.from_room, "to" = connection_contract.to_room, "normalized_from" = from_endpoint, "normalized_to" = to_endpoint, "kind" = connection_contract.kind))
		if(!building_layout_candidate_has_required_topology_geometry(context, candidate, program, connection_contract))
			state.validation.layout_required_adjacency_geometry_missing_count++
			state.add_stage_report("layout_required_adjacency_geometry", "failed", "required edge has no matching physical opening", list("from" = connection_contract.from_room, "to" = connection_contract.to_room, "normalized_from" = from_endpoint, "normalized_to" = to_endpoint, "kind" = connection_contract.kind))
	var/list/unassigned_lookup = list()
	for(var/turf/interior_turf as anything in state.geometry.interior)
		if(!istype(interior_turf))
			continue
		if(candidate.route_zone_by_turf[interior_turf] == "circulation_open_bay")
			unassigned_lookup[interior_turf] = TRUE
	state.validation.layout_unassigned_interior_turf_count = length(unassigned_lookup)
	state.validation.layout_unassigned_interior_ratio_percent = round(length(unassigned_lookup) * 100 / max(length(state.geometry.interior), 1))
	var/unassigned_limit_percent = state.config["footprint_family"] == WORLD_EDIT_BUILDING_FOOTPRINT_FAMILY_RECT ? 3 : 5
	var/allowed_unassigned_count = round(length(state.geometry.interior) * unassigned_limit_percent / 100)
	state.validation.layout_unassigned_interior_excess_count = max(length(unassigned_lookup) - allowed_unassigned_count, 0)
	state.validation.layout_ownerless_open_bay_count = count_building_layout_lookup_components(unassigned_lookup)
	state.validation.layout_route_component_count = count_building_layout_lookup_components(candidate.route_lookup)
	state.validation.layout_route_component_error_count = state.validation.layout_route_component_count == 1 ? 0 : abs(state.validation.layout_route_component_count - 1)
	var/list/wall_defects = count_building_layout_wall_geometry_defects(candidate)
	state.validation.layout_wall_stub_count = wall_defects["stub_count"] || 0
	state.validation.layout_wall_notch_count = wall_defects["notch_count"] || 0
	state.validation.layout_wall_stair_step_count = wall_defects["stair_step_count"] || 0
	state.validation.layout_wall_misaligned_join_count = wall_defects["misaligned_join_count"] || 0
	if(state.validation.layout_wall_stub_count || state.validation.layout_wall_notch_count || state.validation.layout_wall_stair_step_count || state.validation.layout_wall_misaligned_join_count)
		state.add_stage_report("layout_wall_geometry_defects", "failed", "candidate wall graph contains prohibited geometry", wall_defects)
	var/list/wall_cleanup_report = candidate.wall_cleanup_report
	var/removed_unmapped = round(text2num("[wall_cleanup_report?["removed_unmapped_wall_tile_count"]]") || 0)
	var/removed_spurs = round(text2num("[wall_cleanup_report?["removed_single_sided_wall_tile_count"]]") || 0)
	var/removed_components = round(text2num("[wall_cleanup_report?["removed_wall_tile_count"]]") || 0)
	state.validation.layout_wall_cleanup_removed_count = removed_unmapped + removed_spurs + removed_components
	state.validation.layout_wall_cleanup_unmapped_count = removed_unmapped + removed_components
	state.validation.layout_wall_cleanup_spur_count = removed_spurs
	state.validation.layout_wall_cleanup_ratio_percent = round(state.validation.layout_wall_cleanup_removed_count * 100 / max(length(candidate.wall_turfs) + state.validation.layout_wall_cleanup_removed_count, 1))
	var/list/canyon_report = count_building_layout_route_band_canyon_slices(candidate, state.geometry.wall_lookup)
	state.validation.layout_route_wall_canyon_length = canyon_report["slice_count"] || 0
	state.validation.layout_corridor_wall_canyon_count = canyon_report["failure_count"] || 0

/datum/world_edit_generator/building_layout/proc/building_layout_scene_contains_required_group(datum/world_edit_building_layout_scene_plan/scene_plan, datum/world_edit_building_cluster_spec/required_group)
	if(!istype(scene_plan) || !istype(required_group))
		return FALSE
	var/credit = 0
	for(var/list/member as anything in scene_plan.members)
		var/datum/world_edit_building_cluster_spec/member_group = member?["cluster_spec"]
		if(!istype(member_group))
			continue
		var/group_match = member_group == required_group || member_group.id == required_group.id || (length(member_group.count_cluster_id) && member_group.count_cluster_id == required_group.id) || (length(required_group.count_cluster_id) && required_group.count_cluster_id == member_group.id)
		if(!group_match)
			continue
		credit += get_building_fixture_count_credit(required_group, member["slot"], member["category"])
	return credit >= max(required_group.min_count, 1)

/datum/world_edit_generator/building_layout/proc/building_layout_candidate_has_required_topology_edge(datum/world_edit_building_layout_candidate/candidate, from_room, to_room)
	if(!istype(candidate))
		return FALSE
	for(var/datum/world_edit_building_layout_room_connection/connection as anything in candidate.room_connections)
		if(!istype(connection))
			continue
		if((connection.from_room_id == from_room && connection.to_room_id == to_room) || (connection.from_room_id == to_room && connection.to_room_id == from_room))
			return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/normalize_building_layout_topology_endpoint(datum/world_edit_building_layout_program_contract/program, endpoint_id)
	var/datum/world_edit_building_layout_room_contract/room_contract = program?.get_room_contract(endpoint_id)
	return istype(room_contract) && room_contract.counts_toward_target ? "[endpoint_id]" : "route"

/datum/world_edit_generator/building_layout/proc/building_layout_candidate_has_required_topology_geometry(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate, datum/world_edit_building_layout_program_contract/program, datum/world_edit_building_layout_connection_contract/connection_contract)
	if(!istype(context) || !istype(candidate) || !istype(program) || !istype(connection_contract))
		return FALSE
	var/from_endpoint = normalize_building_layout_topology_endpoint(program, connection_contract.from_room)
	var/to_endpoint = normalize_building_layout_topology_endpoint(program, connection_contract.to_room)
	if(from_endpoint == "route" && to_endpoint == "route")
		return building_layout_candidate_has_circulation_edge(candidate, program, connection_contract)
	for(var/datum/world_edit_building_layout_route_opening_plan/opening_plan as anything in candidate.opening_plans)
		if(!istype(opening_plan))
			continue
		var/endpoint_match = (opening_plan.from_room == from_endpoint && opening_plan.to_room == to_endpoint) || (opening_plan.from_room == to_endpoint && opening_plan.to_room == from_endpoint)
		if(!endpoint_match)
			continue
		if(from_endpoint == "route" || to_endpoint == "route")
			if(building_layout_door_plan_has_valid_shared_wall(context, candidate, opening_plan))
				return TRUE
			continue
		var/datum/world_edit_building_layout_room_plan/from_plan = candidate.get_room_plan(opening_plan.from_room)
		var/datum/world_edit_building_layout_room_plan/to_plan = candidate.get_room_plan(opening_plan.to_room)
		if(!istype(from_plan) || !istype(to_plan))
			continue
		var/forward_match = from_plan.contract_id == connection_contract.from_room && to_plan.contract_id == connection_contract.to_room
		var/reverse_match = from_plan.contract_id == connection_contract.to_room && to_plan.contract_id == connection_contract.from_room
		if(!forward_match && !reverse_match)
			continue
		for(var/turf/opening_turf as anything in get_building_layout_opening_plan_turfs(opening_plan))
			if(building_layout_opening_bridges_room_plans(opening_turf, from_plan, to_plan))
				return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/building_layout_candidate_has_circulation_edge(datum/world_edit_building_layout_candidate/candidate, datum/world_edit_building_layout_program_contract/program, datum/world_edit_building_layout_connection_contract/connection_contract)
	if(!istype(candidate) || !istype(program) || !istype(connection_contract) || !building_layout_route_turfs_are_connected(candidate))
		return FALSE
	var/datum/world_edit_building_layout_room_contract/from_contract = program.get_room_contract(connection_contract.from_room)
	var/datum/world_edit_building_layout_room_contract/to_contract = program.get_room_contract(connection_contract.to_room)
	if(!istype(from_contract) || !istype(to_contract))
		return FALSE
	for(var/turf/from_turf as anything in candidate.route_zone_by_turf)
		if(candidate.route_zone_by_turf[from_turf] != from_contract.zone_id)
			continue
		for(var/check_dir in GLOB.cardinals)
			var/turf/to_turf = get_step(from_turf, check_dir)
			if(candidate.route_zone_by_turf[to_turf] == to_contract.zone_id)
				return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/building_layout_opening_bridges_room_plans(turf/opening_turf, datum/world_edit_building_layout_room_plan/from_plan, datum/world_edit_building_layout_room_plan/to_plan)
	if(!istype(opening_turf) || !istype(from_plan) || !istype(to_plan))
		return FALSE
	for(var/check_dir in GLOB.cardinals)
		var/turf/near_turf = get_step(opening_turf, check_dir)
		var/turf/far_turf = get_step(opening_turf, turn(check_dir, 180))
		if((from_plan.turf_lookup[near_turf] && to_plan.turf_lookup[far_turf]) || (to_plan.turf_lookup[near_turf] && from_plan.turf_lookup[far_turf]))
			return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/count_building_layout_lookup_components(list/turf_lookup)
	if(!islist(turf_lookup) || !length(turf_lookup))
		return 0
	var/list/visited = list()
	var/component_count = 0
	for(var/turf/seed as anything in turf_lookup)
		if(!istype(seed) || visited[seed])
			continue
		component_count++
		var/list/open = list(seed)
		visited[seed] = TRUE
		while(length(open))
			var/turf/current = open[1]
			open.Cut(1, 2)
			for(var/check_dir in GLOB.cardinals)
				var/turf/nearby = get_step(current, check_dir)
				if(!istype(nearby) || !turf_lookup[nearby] || visited[nearby])
					continue
				visited[nearby] = TRUE
				open += nearby
	return component_count

/datum/world_edit_generator/building_layout/proc/count_building_layout_wall_geometry_defects(datum/world_edit_building_layout_candidate/candidate)
	var/list/report = list("stub_count" = 0, "notch_count" = 0, "stair_step_count" = 0, "misaligned_join_count" = 0, "stub_turfs" = list(), "notch_turfs" = list(), "stair_step_turfs" = list(), "misaligned_join_turfs" = list())
	if(!istype(candidate) || !length(candidate.wall_lookup))
		return report
	var/list/opening_lookup = list()
	for(var/datum/world_edit_building_layout_route_opening_plan/opening_plan as anything in candidate.opening_plans)
		for(var/turf/opening_turf as anything in get_building_layout_opening_plan_turfs(opening_plan))
			if(istype(opening_turf))
				opening_lookup[opening_turf] = TRUE
	for(var/turf/wall_turf as anything in candidate.wall_lookup)
		if(!istype(wall_turf))
			continue
		var/neighbor_count = 0
		for(var/check_dir in GLOB.cardinals)
			var/turf/nearby = get_step(wall_turf, check_dir)
			if(candidate.wall_lookup[nearby] || opening_lookup[nearby])
				neighbor_count++
		if(neighbor_count <= 1)
			report["stub_count"]++
			report["stub_turfs"] += "[wall_turf.x],[wall_turf.y],[wall_turf.z]"
		else if(neighbor_count >= 3)
			var/opposite_axis = (candidate.wall_lookup[get_step(wall_turf, NORTH)] || opening_lookup[get_step(wall_turf, NORTH)]) && (candidate.wall_lookup[get_step(wall_turf, SOUTH)] || opening_lookup[get_step(wall_turf, SOUTH)])
			var/other_axis = (candidate.wall_lookup[get_step(wall_turf, EAST)] || opening_lookup[get_step(wall_turf, EAST)]) && (candidate.wall_lookup[get_step(wall_turf, WEST)] || opening_lookup[get_step(wall_turf, WEST)])
			if(!opposite_axis && !other_axis)
				report["misaligned_join_count"]++
				report["misaligned_join_turfs"] += "[wall_turf.x],[wall_turf.y],[wall_turf.z]"
	for(var/turf/floor_turf as anything in candidate.floor_lookup)
		if(!istype(floor_turf) || candidate.wall_lookup[floor_turf] || opening_lookup[floor_turf])
			continue
		var/cardinal_walls = 0
		for(var/check_dir in GLOB.cardinals)
			if(candidate.wall_lookup[get_step(floor_turf, check_dir)])
				cardinal_walls++
		if(cardinal_walls >= 3)
			report["notch_count"]++
			report["notch_turfs"] += "[floor_turf.x],[floor_turf.y],[floor_turf.z]"
		var/ne = candidate.wall_lookup[get_step(get_step(floor_turf, NORTH), EAST)]
		var/nw = candidate.wall_lookup[get_step(get_step(floor_turf, NORTH), WEST)]
		var/se = candidate.wall_lookup[get_step(get_step(floor_turf, SOUTH), EAST)]
		var/sw = candidate.wall_lookup[get_step(get_step(floor_turf, SOUTH), WEST)]
		if((ne && sw && !nw && !se) || (nw && se && !ne && !sw))
			report["stair_step_count"]++
			report["stair_step_turfs"] += "[floor_turf.x],[floor_turf.y],[floor_turf.z]"
	return report

/datum/world_edit_generator/building_layout/proc/count_building_layout_route_band_canyon_slices(datum/world_edit_building_layout_candidate/candidate, list/wall_lookup)
	var/list/report = list("slice_count" = 0, "failure_count" = 0, "share_percent" = 0)
	if(!istype(candidate) || !islist(wall_lookup) || !length(candidate.route_turfs))
		return report
	var/list/opening_lookup = list()
	var/list/access_approach_lookup = list()
	for(var/datum/world_edit_building_layout_route_opening_plan/opening_plan as anything in candidate.opening_plans)
		for(var/turf/opening_turf as anything in get_building_layout_opening_plan_turfs(opening_plan))
			if(istype(opening_turf))
				opening_lookup[opening_turf] = TRUE
	for(var/room_id as anything in candidate.access_reservations_by_room)
		var/list/reservation = candidate.access_reservations_by_room[room_id]
		for(var/turf/approach_turf as anything in reservation?["route_run"])
			if(istype(approach_turf))
				access_approach_lookup[approach_turf] = TRUE
		var/list/connector_run = reservation?["connector_run"]
		if(islist(connector_run) && length(connector_run))
			for(var/connector_index in max(length(connector_run) - 1, 1) to length(connector_run))
				var/turf/connector_approach = connector_run[connector_index]
				if(istype(connector_approach))
					access_approach_lookup[connector_approach] = TRUE
	var/list/canyon_lookup = list()
	var/list/orientation_lookup = list()
	for(var/turf/route_turf as anything in candidate.route_turfs)
		if(!istype(route_turf) || opening_lookup[route_turf] || access_approach_lookup[route_turf])
			continue
		var/vertical = candidate.route_lookup[get_step(route_turf, NORTH)] || candidate.route_lookup[get_step(route_turf, SOUTH)]
		var/horizontal = candidate.route_lookup[get_step(route_turf, EAST)] || candidate.route_lookup[get_step(route_turf, WEST)]
		if(!vertical && !horizontal)
			continue
		var/side_a = vertical ? WEST : NORTH
		var/side_b = vertical ? EAST : SOUTH
		var/turf/wall_a = find_building_layout_first_non_route_turf(candidate, route_turf, side_a)
		var/turf/wall_b = find_building_layout_first_non_route_turf(candidate, route_turf, side_b)
		if(!istype(wall_a) || !istype(wall_b) || !wall_lookup[wall_a] || !wall_lookup[wall_b] || opening_lookup[wall_a] || opening_lookup[wall_b])
			continue
		canyon_lookup[route_turf] = TRUE
		orientation_lookup[route_turf] = vertical ? "V" : "H"
	var/slice_count = length(canyon_lookup)
	var/share_percent = round(slice_count * 100 / max(length(candidate.route_turfs), 1))
	report["slice_count"] = slice_count
	report["share_percent"] = share_percent
	var/list/visited_lookup = list()
	var/failure_count = 0
	for(var/turf/canyon_turf as anything in canyon_lookup)
		if(!istype(canyon_turf) || visited_lookup[canyon_turf])
			continue
		var/orientation = orientation_lookup[canyon_turf]
		var/list/open = list(canyon_turf)
		var/component_length = 0
		while(length(open))
			var/turf/current = open[1]
			open.Cut(1, 2)
			if(visited_lookup[current] || orientation_lookup[current] != orientation)
				continue
			visited_lookup[current] = TRUE
			component_length++
			var/list/axis_dirs = orientation == "V" ? list(NORTH, SOUTH) : list(EAST, WEST)
			for(var/axis_dir in axis_dirs)
				var/turf/nearby = get_step(current, axis_dir)
				if(canyon_lookup[nearby] && !visited_lookup[nearby] && orientation_lookup[nearby] == orientation)
					open += nearby
		if(component_length > 3)
			failure_count += component_length - 3
	report["failure_count"] = failure_count
	return report

/datum/world_edit_generator/building_layout/proc/find_building_layout_first_non_route_turf(datum/world_edit_building_layout_candidate/candidate, turf/start_turf, step_dir)
	if(!istype(candidate) || !istype(start_turf))
		return null
	var/turf/current = get_step(start_turf, step_dir)
	var/guard = 0
	while(istype(current) && candidate.route_lookup[current] && guard < 8)
		current = get_step(current, step_dir)
		guard++
	return current
