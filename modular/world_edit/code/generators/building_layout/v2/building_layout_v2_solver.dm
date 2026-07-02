/datum/world_edit_generator/building_layout/proc/building_layout_v2_enabled(datum/world_edit_building_layout_state/state)
	return istype(state) && GLOB.world_edit_helpers.parse_bool(state.config["use_layout_v2"]) && state.archetype?.id == "living"

/datum/world_edit_generator/building_layout/proc/use_building_layout_v2(datum/world_edit_building_request/request)
	return istype(request) && GLOB.world_edit_helpers.parse_bool(request.config["use_layout_v2"]) && request.archetype?.id == "living"

/datum/world_edit_generator/building_layout/proc/build_building_layout_v2_state(datum/world_edit_building_layout_state/state)
	if(!building_layout_v2_enabled(state))
		return FALSE
	state.config["layout_v2_enabled"] = TRUE
	var/datum/world_edit_building_v2_program_contract/program_contract = build_building_v2_program_contract(state.archetype.id)
	if(!istype(program_contract))
		state.add_error("Building layout v2 has no program contract for [state.archetype.id].")
		return FALSE
	var/datum/world_edit_building_v2_context/context = new(src, state, program_contract)
	state.layout_v2_context = context
	var/list/candidates = generate_building_layout_v2_candidates(context)
	var/list/scene_solved_candidates = filter_building_layout_v2_scene_solved_candidates(context, candidates)
	state.config["layout_v2_candidate_count"] = length(scene_solved_candidates)
	var/datum/world_edit_building_v2_layout_candidate/best = select_hard_valid_building_layout_v2_candidate(context, scene_solved_candidates)
	if(!istype(best))
		state.add_error("Building layout v2 could not select a valid layout candidate.")
		state.add_stage_report("layout_v2", "failed", format_building_messages(state.validation.errors), list("candidate_count" = length(scene_solved_candidates), "topology_candidate_count" = length(candidates)))
		return FALSE
	context.selected_candidate = best
	if(!run_building_v2_candidate_emission_pipeline(context, best))
		state.add_stage_report("layout_v2", "failed", "selected candidate failed final emission validation", list(
			"pattern_id" = best.pattern_id,
			"candidate_id" = best.id,
			"errors" = state.validation.errors.Copy(),
			"hard_counters" = build_building_state_hard_counter_report(state),
		))
		return FALSE
	state.add_stage_report("layout_v2", state.has_errors() ? "failed" : "ok", state.has_errors() ? format_building_messages(state.validation.errors) : null, list(
		"program_id" = program_contract.id,
		"pattern_id" = best.pattern_id,
		"candidate_count" = length(scene_solved_candidates),
		"topology_candidate_count" = length(candidates),
		"scene_count" = length(best.room_plans),
		"room_count" = length(state.geometry.solved_rooms),
	))
	return !state.has_errors()

/datum/world_edit_generator/building_layout/proc/generate_building_layout_v2_candidates(datum/world_edit_building_v2_context/context)
	var/list/candidates = list()
	if(!istype(context) || !istype(context.program_contract))
		return candidates
	for(var/pattern_id as anything in context.program_contract.allowed_layout_patterns)
		var/datum/world_edit_building_v2_layout_pattern/pattern = get_building_layout_v2_pattern(pattern_id)
		if(!istype(pattern) || !pattern.can_solve(context))
			continue
		for(var/datum/world_edit_building_v2_layout_candidate/candidate as anything in pattern.build_candidates(context))
			if(!istype(candidate))
				continue
			if(!solve_building_v2_room_allocation(context, candidate))
				if(istype(context?.state))
					context.state.add_stage_report("layout_v2_candidate_room_allocation_reject", "failed", format_building_messages(candidate.errors), list("candidate_id" = candidate.id, "pattern_id" = candidate.pattern_id, "errors" = candidate.errors.Copy()))
				continue
			if(!solve_building_v2_openings(context, candidate))
				if(istype(context?.state))
					context.state.add_stage_report("layout_v2_candidate_opening_reject", "failed", format_building_messages(candidate.errors), list("candidate_id" = candidate.id, "pattern_id" = candidate.pattern_id, "errors" = candidate.errors.Copy(), "rooms" = build_building_v2_candidate_room_report(candidate), "routes" = build_building_v2_candidate_route_report(candidate)))
				continue
			if(!validate_building_v2_layout_topology(context, candidate))
				if(istype(context?.state))
					context.state.add_stage_report("layout_v2_candidate_topology_reject", "failed", format_building_messages(candidate.errors), list("candidate_id" = candidate.id, "pattern_id" = candidate.pattern_id, "errors" = candidate.errors.Copy(), "rooms" = build_building_v2_candidate_room_report(candidate), "routes" = build_building_v2_candidate_route_report(candidate)))
				continue
			candidate.score += score_building_v2_layout_candidate(context, candidate)
			candidates += candidate
	return candidates

/datum/world_edit_generator/building_layout/proc/filter_building_layout_v2_scene_solved_candidates(datum/world_edit_building_v2_context/context, list/candidates)
	var/list/solved_candidates = list()
	if(!islist(candidates))
		return solved_candidates
	for(var/datum/world_edit_building_v2_layout_candidate/candidate as anything in candidates)
		if(!istype(candidate) || length(candidate.errors))
			continue
		if(solve_building_v2_scenes(context, candidate))
			candidate.score += score_building_v2_scene_quality(context, candidate)
			solved_candidates += candidate
		else if(istype(context?.state))
			context.state.add_stage_report("layout_v2_candidate_scene_reject", "failed", format_building_messages(candidate.errors), list("candidate_id" = candidate.id, "pattern_id" = candidate.pattern_id, "errors" = candidate.errors.Copy()))
	return solved_candidates

/datum/world_edit_generator/building_layout/proc/select_best_building_layout_v2_candidate(datum/world_edit_building_v2_context/context, list/candidates)
	var/datum/world_edit_building_v2_layout_candidate/best = null
	var/best_score = -999999999
	for(var/datum/world_edit_building_v2_layout_candidate/candidate as anything in candidates)
		if(!istype(candidate) || length(candidate.errors))
			continue
		if(!istype(best) || candidate.score > best_score)
			best = candidate
			best_score = candidate.score
	if(istype(best) && istype(context?.state))
		context.state.config["layout_v2_pattern_id"] = best.pattern_id
		context.state.config["layout_v2_candidate_id"] = best.id
		context.state.config["layout_candidate_score"] = best.score
	return best

/datum/world_edit_generator/building_layout/proc/select_hard_valid_building_layout_v2_candidate(datum/world_edit_building_v2_context/context, list/candidates)
	if(!istype(context) || !istype(context.state) || !islist(candidates))
		return null
	var/list/remaining = candidates.Copy()
	var/hard_valid_count = 0
	var/datum/world_edit_building_v2_layout_candidate/selected_candidate = null
	while(length(remaining))
		var/datum/world_edit_building_v2_layout_candidate/candidate = null
		var/best_score = -999999999
		var/best_index = 0
		for(var/index in 1 to length(remaining))
			var/datum/world_edit_building_v2_layout_candidate/indexed_candidate = remaining[index]
			if(!istype(indexed_candidate) || length(indexed_candidate.errors))
				continue
			if(!istype(candidate) || indexed_candidate.score > best_score)
				candidate = indexed_candidate
				best_score = indexed_candidate.score
				best_index = index
		if(!istype(candidate))
			break
		remaining.Cut(best_index, best_index + 1)
		var/datum/world_edit_building_layout_state/trial_state = build_building_v2_candidate_trial_state(context, candidate)
		if(!istype(trial_state))
			context.state.add_stage_report("layout_v2_candidate_post_emit_reject", "failed", "trial state unavailable", list(
				"candidate_id" = candidate.id,
				"pattern_id" = candidate.pattern_id,
				"score" = candidate.score,
			))
			continue
		var/datum/world_edit_building_v2_context/trial_context = trial_state.layout_v2_context
		if(run_building_v2_candidate_emission_pipeline(trial_context, candidate))
			hard_valid_count++
			if(!istype(selected_candidate))
				selected_candidate = candidate
			continue
		var/list/hard_counters = build_building_state_hard_counter_report(trial_state)
		context.state.add_stage_report("layout_v2_candidate_post_emit_reject", "failed", format_building_messages(trial_state.validation.errors), list(
			"candidate_id" = candidate.id,
			"pattern_id" = candidate.pattern_id,
			"score" = candidate.score,
			"errors" = trial_state.validation.errors.Copy(),
			"hard_counters" = hard_counters,
			"room_count" = length(trial_state.geometry.solved_rooms),
			"corridor_turf_count" = length(trial_state.geometry.corridor_turfs),
			"rooms" = build_building_v2_candidate_room_report(candidate),
			"routes" = build_building_v2_candidate_route_report(candidate),
			"stage_reports" = trial_state.validation.stage_reports.Copy(),
		))
	context.state.config["layout_v2_hard_valid_candidate_count"] = hard_valid_count
	if(istype(selected_candidate))
		stamp_building_v2_selected_candidate(context.state, selected_candidate)
	return selected_candidate

/datum/world_edit_generator/building_layout/proc/stamp_building_v2_selected_candidate(datum/world_edit_building_layout_state/state, datum/world_edit_building_v2_layout_candidate/candidate)
	if(!istype(state) || !istype(candidate))
		return
	state.config["layout_v2_pattern_id"] = candidate.pattern_id
	state.config["layout_v2_candidate_id"] = candidate.id
	state.config["layout_candidate_score"] = candidate.score
	state.validation.layout_candidate_score = candidate.score

/datum/world_edit_generator/building_layout/proc/build_building_v2_candidate_trial_state(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate)
	var/datum/world_edit_building_layout_state/source_state = context?.state
	if(!istype(source_state) || !istype(context?.program_contract) || !istype(candidate))
		return null
	var/datum/world_edit_building_layout_state/trial_state = new()
	trial_state.request = source_state.request
	trial_state.archetype = source_state.archetype
	trial_state.semantic_plan = source_state.semantic_plan
	trial_state.config = source_state.config.Copy()
	trial_state.root_seed = source_state.root_seed
	trial_state.stage_seed_footprint = source_state.stage_seed_footprint
	trial_state.stage_seed_rooms = source_state.stage_seed_rooms
	trial_state.stage_seed_corridor = source_state.stage_seed_corridor
	trial_state.stage_seed_patterns = source_state.stage_seed_patterns
	trial_state.stage_seed_details = source_state.stage_seed_details
	trial_state.placement_dir = source_state.placement_dir
	trial_state.geometry.footprint = source_state.geometry.footprint.Copy()
	trial_state.geometry.boundary = source_state.geometry.boundary.Copy()
	trial_state.geometry.interior = source_state.geometry.interior.Copy()
	trial_state.geometry.footprint_lookup = source_state.geometry.footprint_lookup.Copy()
	trial_state.geometry.boundary_lookup = source_state.geometry.boundary_lookup.Copy()
	trial_state.geometry.bounds = source_state.geometry.bounds.Copy()
	trial_state.geometry.max_front_depth = source_state.geometry.max_front_depth
	trial_state.geometry.max_lateral_abs = source_state.geometry.max_lateral_abs
	trial_state.geometry.requested_direction = source_state.geometry.requested_direction
	trial_state.geometry.actual_entry_direction = source_state.geometry.actual_entry_direction
	trial_state.geometry.footprint_hash = source_state.geometry.footprint_hash
	trial_state.validation.blocked_turf_conflict_count = source_state.validation.blocked_turf_conflict_count
	trial_state.validation.replace_blocked_turf_count = source_state.validation.replace_blocked_turf_count
	trial_state.validation.current_request_support_status = source_state.validation.current_request_support_status
	trial_state.validation.user_facing_failure_reason = source_state.validation.user_facing_failure_reason
	if(islist(source_state.validation.support_status_report))
		trial_state.validation.support_status_report = source_state.validation.support_status_report.Copy()
	stamp_building_v2_selected_candidate(trial_state, candidate)
	trial_state.config["layout_v2_candidate_count"] = source_state.config["layout_v2_candidate_count"] || 0
	trial_state.config["layout_v2_enabled"] = TRUE
	var/datum/world_edit_building_v2_context/trial_context = new(src, trial_state, context.program_contract)
	trial_context.selected_candidate = candidate
	trial_state.layout_v2_context = trial_context
	return trial_state

/datum/world_edit_generator/building_layout/proc/build_building_v2_candidate_room_report(datum/world_edit_building_v2_layout_candidate/candidate)
	var/list/report = list()
	if(!istype(candidate))
		return report
	for(var/datum/world_edit_building_v2_room_plan/room_plan as anything in candidate.room_plans)
		if(!istype(room_plan))
			continue
		report += list(list(
			"id" = room_plan.id,
			"contract_id" = room_plan.contract_id,
			"role" = room_plan.role,
			"area" = room_plan.area(),
			"width" = room_plan.width(),
			"height" = room_plan.height(),
			"bounds" = list("x1" = room_plan.x1, "y1" = room_plan.y1, "x2" = room_plan.x2, "y2" = room_plan.y2),
		))
	return report

/datum/world_edit_generator/building_layout/proc/build_building_v2_candidate_route_report(datum/world_edit_building_v2_layout_candidate/candidate)
	var/list/report = list()
	if(!istype(candidate))
		return report
	var/index = 0
	for(var/turf/route_turf as anything in candidate.route_turfs)
		if(!istype(route_turf))
			continue
		index++
		if(index > 48)
			break
		report += list(list(
			"x" = route_turf.x,
			"y" = route_turf.y,
			"z" = route_turf.z,
		))
	return report

/datum/world_edit_generator/building_layout/proc/validate_building_v2_layout_topology(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate)
	if(!istype(context) || !istype(candidate) || !istype(context.state))
		return FALSE
	var/list/room_turf_owner = list()
	var/list/candidate_floor_lookup = list()
	for(var/datum/world_edit_building_v2_room_plan/room_plan as anything in candidate.room_plans)
		if(!istype(room_plan) || !length(room_plan.turfs))
			candidate.errors += "room.empty:[room_plan?.id]"
			continue
		var/datum/world_edit_building_v2_room_contract/room_contract = context.program_contract.get_room_contract(room_plan.contract_id)
		if(istype(room_contract))
			var/room_width = room_plan.width()
			var/room_height = room_plan.height()
			var/fits_min_dimensions = (room_width >= room_contract.min_width && room_height >= room_contract.min_height) || (room_width >= room_contract.min_height && room_height >= room_contract.min_width)
			var/fits_max_dimensions = (room_width <= room_contract.max_width && room_height <= room_contract.max_height) || (room_width <= room_contract.max_height && room_height <= room_contract.max_width)
			if(room_plan.area() < room_contract.min_area || !fits_min_dimensions)
				candidate.errors += "room.too_small:[room_plan.id]"
			if(room_plan.area() > room_contract.max_area || !fits_max_dimensions)
				candidate.errors += "room.too_large:[room_plan.id]"
		var/room_min_dim = min(room_plan.width(), room_plan.height())
		var/room_max_dim = max(room_plan.width(), room_plan.height())
		if(room_plan.area() >= 12 && (room_min_dim <= 2 || room_max_dim > room_min_dim * 4))
			candidate.errors += "room.thin_strip:[room_plan.id]"
		for(var/turf/room_turf as anything in room_plan.turfs)
			if(!istype(room_turf) || !context.state.geometry.footprint_lookup[room_turf] || context.state.geometry.boundary_lookup[room_turf])
				candidate.errors += "room.out_of_bounds:[room_plan.id]"
				continue
			if(room_turf_owner[room_turf])
				candidate.errors += "room.overlap:[room_plan.id]"
				continue
			room_turf_owner[room_turf] = room_plan.id
			candidate_floor_lookup[room_turf] = TRUE
	for(var/datum/world_edit_building_v2_room_contract/required_contract as anything in context.program_contract.room_contracts)
		if(!istype(required_contract) || !required_contract.required)
			continue
		var/datum/world_edit_building_v2_room_plan/required_room_plan = candidate.get_room_plan(required_contract.id)
		if(!istype(required_room_plan))
			candidate.errors += "room.required_missing:[required_contract.id]"
	for(var/turf/route_turf as anything in candidate.route_turfs)
		if(!istype(route_turf) || !context.state.geometry.footprint_lookup[route_turf] || context.state.geometry.boundary_lookup[route_turf])
			candidate.errors += "route.out_of_bounds"
			continue
		candidate_floor_lookup[route_turf] = TRUE
	var/list/connected_rooms = list()
	var/has_main_exit = FALSE
	for(var/datum/world_edit_building_v2_route_opening_plan/door_plan as anything in candidate.door_plans)
		if(!istype(door_plan) || !istype(door_plan.opening_turf))
			candidate.errors += "door.missing"
			continue
		if(!context.state.geometry.footprint_lookup[door_plan.opening_turf])
			candidate.errors += "door.out_of_bounds:[door_plan.id]"
			continue
		if(!building_v2_door_plan_has_valid_shared_wall(context, candidate, door_plan))
			candidate.errors += "door.not_shared_wall:[door_plan.id]"
			continue
		if(door_plan.kind == "main_exit")
			has_main_exit = TRUE
		else
			if(length(door_plan.from_room) && door_plan.from_room != "route")
				connected_rooms[door_plan.from_room] = TRUE
			if(length(door_plan.to_room) && door_plan.to_room != "route")
				connected_rooms[door_plan.to_room] = TRUE
		candidate_floor_lookup[door_plan.opening_turf] = TRUE
	if(!has_main_exit)
		candidate.errors += "door.main_exit_missing"
	if(!building_v2_route_turfs_are_connected(candidate))
		candidate.errors += "route.disconnected"
	for(var/datum/world_edit_building_v2_route_opening_plan/window_plan as anything in candidate.window_plans)
		if(!building_v2_window_plan_obeys_policy(context, candidate, window_plan))
			candidate.errors += "window.policy_or_boundary:[window_plan?.id]"
	var/interior_count = length(context.state.geometry.interior)
	if(interior_count >= 180)
		var/min_floor_count = round(interior_count * 0.50)
		if(length(candidate_floor_lookup) < min_floor_count)
			candidate.errors += "coverage.too_sparse:[length(candidate_floor_lookup)]/[interior_count]"
	for(var/datum/world_edit_building_v2_room_contract/connection_contract as anything in context.program_contract.room_contracts)
		if(!istype(connection_contract) || !connection_contract.required || !connection_contract.must_touch_route)
			continue
		if(!connected_rooms[connection_contract.id])
			candidate.errors += "route.room_unconnected:[connection_contract.id]"
	return !length(candidate.errors)

/datum/world_edit_generator/building_layout/proc/score_building_v2_layout_candidate(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate)
	var/score = 0
	for(var/datum/world_edit_building_v2_room_plan/room_plan as anything in candidate.room_plans)
		var/datum/world_edit_building_v2_room_contract/room_contract = context.program_contract.get_room_contract(room_plan.contract_id)
		if(!istype(room_contract))
			continue
		score += room_contract.required ? 200 : 60
		score -= abs(room_plan.area() - room_contract.preferred_area)
	var/expected_route_turfs = max(12, length(candidate.room_plans) * 3)
	if(length(candidate.route_turfs) > expected_route_turfs)
		score -= (length(candidate.route_turfs) - expected_route_turfs) * 8
	var/expected_door_count = 1
	for(var/datum/world_edit_building_v2_room_plan/door_room_plan as anything in candidate.room_plans)
		var/datum/world_edit_building_v2_room_contract/door_room_contract = context.program_contract.get_room_contract(door_room_plan.contract_id)
		if(istype(door_room_contract) && door_room_contract.must_touch_route)
			expected_door_count++
	if(length(candidate.door_plans) > expected_door_count)
		score -= (length(candidate.door_plans) - expected_door_count) * 40
	return score

/datum/world_edit_generator/building_layout/proc/score_building_v2_scene_quality(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate)
	if(!istype(context) || !istype(candidate))
		return 0
	var/score = 0
	for(var/datum/world_edit_building_v2_room_plan/room_plan as anything in candidate.room_plans)
		if(!istype(room_plan))
			continue
		var/member_count = istype(room_plan.scene_plan) ? length(room_plan.scene_plan.members) : 0
		var/min_member_count = get_building_v2_min_scene_members_for_room(room_plan.contract_id, room_plan.role, room_plan.area())
		if(min_member_count > 0 && member_count < min_member_count)
			score -= (min_member_count - member_count) * 300
		score += min(member_count, 6) * 18
	return score

/datum/world_edit_generator/building_layout/proc/solve_building_v2_room_allocation(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate)
	if(!istype(context) || !istype(candidate))
		return FALSE
	if(length(candidate.room_plans))
		return TRUE
	if(!length(candidate.room_allocation_requests))
		candidate.errors += "room_allocation.none"
		return FALSE
	for(var/datum/world_edit_building_v2_room_allocation_request/allocation_request as anything in candidate.room_allocation_requests)
		if(!istype(allocation_request))
			continue
		if(!allocate_building_v2_room_from_request(context, candidate, allocation_request))
			candidate.errors += "room_allocation.failed:[allocation_request.id]"
	return !length(candidate.errors)

/datum/world_edit_generator/building_layout/proc/allocate_building_v2_room_from_request(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, datum/world_edit_building_v2_room_allocation_request/allocation_request)
	if(!istype(context) || !istype(candidate) || !istype(allocation_request))
		return FALSE
	var/datum/world_edit_building_v2_room_contract/room_contract = context.program_contract?.get_room_contract(allocation_request.contract_id)
	if(!istype(room_contract))
		candidate.errors += "room_allocation.unknown_contract:[allocation_request.contract_id]"
		return FALSE
	var/min_x = min(allocation_request.x1, allocation_request.x2)
	var/max_x = max(allocation_request.x1, allocation_request.x2)
	var/min_y = min(allocation_request.y1, allocation_request.y2)
	var/max_y = max(allocation_request.y1, allocation_request.y2)
	var/slot_width = max(max_x - min_x + 1, 0)
	var/slot_height = max(max_y - min_y + 1, 0)
	var/list/dimensions = select_building_v2_room_dimensions_for_slot(context, allocation_request, room_contract, slot_width, slot_height)
	if(!islist(dimensions))
		candidate.errors += "room_allocation.no_fit:[allocation_request.id]"
		return FALSE
	var/room_width = round(text2num("[dimensions["width"]]") || 0)
	var/room_height = round(text2num("[dimensions["height"]]") || 0)
	if(room_width <= 0 || room_height <= 0)
		candidate.errors += "room_allocation.invalid_dimensions:[allocation_request.id]"
		return FALSE
	var/local_x1 = align_building_v2_room_axis(min_x, max_x, room_width, allocation_request.align_x)
	var/local_y1 = align_building_v2_room_axis(min_y, max_y, room_height, allocation_request.align_y)
	var/local_x2 = local_x1 + room_width - 1
	var/local_y2 = local_y1 + room_height - 1
	var/datum/world_edit_building_v2_room_plan/room_plan = add_building_v2_room_rect(context, candidate, allocation_request.id, allocation_request.contract_id, allocation_request.role, allocation_request.zone_id, local_x1, local_y1, local_x2, local_y2)
	return istype(room_plan)

/datum/world_edit_generator/building_layout/proc/select_building_v2_room_dimensions_for_slot(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_room_allocation_request/allocation_request, datum/world_edit_building_v2_room_contract/room_contract, slot_width, slot_height)
	if(!istype(context) || !istype(allocation_request) || !istype(room_contract) || slot_width <= 0 || slot_height <= 0)
		return null
	var/list/best_dimensions = null
	var/best_score = -999999999
	var/slot_area = slot_width * slot_height
	var/should_fill_slot = room_contract.required || length(room_contract.required_scene_kinds)
	var/target_area = should_fill_slot ? min(room_contract.max_area, slot_area) : min(room_contract.max_area, max(room_contract.preferred_area, round(slot_area * 0.80)))
	for(var/room_width in 1 to slot_width)
		for(var/room_height in 1 to slot_height)
			var/room_area = room_width * room_height
			if(!building_v2_room_dimensions_fit_contract(room_contract, room_width, room_height, room_area))
				continue
			if(!building_v2_room_dimensions_have_required_scene_fit(context, allocation_request, room_contract, room_width, room_height, room_area))
				continue
			var/score = 0
			score -= abs(room_area - target_area) * 4
			score -= abs(room_area - room_contract.preferred_area)
			score += min(room_width, room_height) * 3
			if(room_width == slot_width)
				score += 4
			if(room_height == slot_height)
				score += 4
			if(!islist(best_dimensions) || score > best_score)
				best_score = score
				best_dimensions = list("width" = room_width, "height" = room_height)
	return best_dimensions

/datum/world_edit_generator/building_layout/proc/building_v2_room_dimensions_fit_contract(datum/world_edit_building_v2_room_contract/room_contract, room_width, room_height, room_area)
	if(!istype(room_contract))
		return FALSE
	var/fits_min_dimensions = (room_width >= room_contract.min_width && room_height >= room_contract.min_height) || (room_width >= room_contract.min_height && room_height >= room_contract.min_width)
	var/fits_max_dimensions = (room_width <= room_contract.max_width && room_height <= room_contract.max_height) || (room_width <= room_contract.max_height && room_height <= room_contract.max_width)
	return room_area >= room_contract.min_area && room_area <= room_contract.max_area && fits_min_dimensions && fits_max_dimensions

/datum/world_edit_generator/building_layout/proc/building_v2_room_dimensions_have_required_scene_fit(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_room_allocation_request/allocation_request, datum/world_edit_building_v2_room_contract/room_contract, room_width, room_height, room_area)
	if(!istype(context) || !istype(allocation_request) || !istype(room_contract))
		return FALSE
	if(!length(room_contract.required_scene_kinds))
		return TRUE
	for(var/required_scene_kind as anything in room_contract.required_scene_kinds)
		var/has_fit = FALSE
		for(var/datum/world_edit_building_v2_scene_contract/scene_contract as anything in context.program_contract.scene_contracts)
			if(!building_v2_scene_contract_can_fit_room_allocation(context, allocation_request, room_contract, scene_contract, "[required_scene_kind]", room_width, room_height, room_area))
				continue
			has_fit = TRUE
			break
		if(!has_fit)
			return FALSE
	return TRUE

/datum/world_edit_generator/building_layout/proc/building_v2_scene_contract_can_fit_room_allocation(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_room_allocation_request/allocation_request, datum/world_edit_building_v2_room_contract/room_contract, datum/world_edit_building_v2_scene_contract/scene_contract, required_scene_kind, room_width, room_height, room_area)
	if(!istype(context) || !istype(allocation_request) || !istype(room_contract) || !istype(scene_contract))
		return FALSE
	if(length(scene_contract.allowed_programs) && !(context.program_contract?.id in scene_contract.allowed_programs))
		return FALSE
	if(scene_contract.scene_kind != "[required_scene_kind]")
		return FALSE
	if(length(scene_contract.allowed_room_roles) && !(room_contract.role in scene_contract.allowed_room_roles))
		return FALSE
	if(length(scene_contract.allowed_room_ids) && !(allocation_request.id in scene_contract.allowed_room_ids) && !(allocation_request.contract_id in scene_contract.allowed_room_ids))
		return FALSE
	return room_area >= scene_contract.min_room_area && room_width >= scene_contract.min_room_width && room_height >= scene_contract.min_room_height

/datum/world_edit_generator/building_layout/proc/align_building_v2_room_axis(slot_min, slot_max, room_size, alignment)
	var/span = max(slot_max - slot_min + 1, 1)
	var/clamped_size = clamp(room_size, 1, span)
	switch("[alignment]")
		if("min", "front", "left", "top")
			return slot_min
		if("max", "back", "right", "bottom")
			return slot_max - clamped_size + 1
	return slot_min + round((span - clamped_size) / 2)

/datum/world_edit_generator/building_layout/proc/add_building_v2_room_allocation_slot(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, room_id, contract_id, role, zone_id, relation_zone, x1, y1, x2, y2, align_x = "center", align_y = "center")
	if(!istype(context) || !istype(candidate))
		return null
	var/datum/world_edit_building_v2_room_allocation_request/allocation_request = new(room_id, contract_id, role, zone_id, relation_zone, x1, y1, x2, y2, align_x, align_y)
	candidate.add_room_allocation_request(allocation_request)
	return allocation_request

/datum/world_edit_generator/building_layout/proc/add_building_v2_room_rect(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, room_id, contract_id, role, zone_id, x1, y1, x2, y2)
	if(!istype(context) || !istype(candidate))
		return null
	var/datum/world_edit_building_v2_room_plan/room_plan = new(room_id, contract_id, role, zone_id)
	var/min_x = min(x1, x2)
	var/max_x = max(x1, x2)
	var/min_y = min(y1, y2)
	var/max_y = max(y1, y2)
	for(var/local_x in min_x to max_x)
		for(var/local_y in min_y to max_y)
			var/turf/room_turf = context.local_turf(local_x, local_y)
			if(istype(room_turf))
				room_plan.add_turf(room_turf)
	candidate.add_room_plan(room_plan)
	return room_plan

/datum/world_edit_generator/building_layout/proc/add_building_v2_route_rect(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, x1, y1, x2, y2)
	if(!istype(context) || !istype(candidate))
		return
	var/min_x = min(x1, x2)
	var/max_x = max(x1, x2)
	var/min_y = min(y1, y2)
	var/max_y = max(y1, y2)
	for(var/local_x in min_x to max_x)
		for(var/local_y in min_y to max_y)
			candidate.add_route_turf(context.local_turf(local_x, local_y))

/datum/world_edit_generator/building_layout/proc/add_building_v2_door(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, door_id, kind, local_x, local_y, local_dir, from_room = "", to_room = "")
	if(!istype(context) || !istype(candidate))
		return
	var/turf/door_turf = context.local_turf(local_x, local_y)
	if(!istype(door_turf))
		return
	var/world_dir = context.local_dir_to_world_dir(local_dir)
	candidate.add_door_plan(new /datum/world_edit_building_v2_route_opening_plan(door_id, kind, door_turf, world_dir, from_room, to_room))

/datum/world_edit_generator/building_layout/proc/add_building_v2_window(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, window_id, local_x, local_y, local_dir, room_id = "")
	if(!istype(context) || !istype(candidate))
		return
	var/turf/window_turf = context.local_turf(local_x, local_y)
	if(!istype(window_turf))
		return
	var/world_dir = context.local_dir_to_world_dir(local_dir)
	candidate.add_window_plan(new /datum/world_edit_building_v2_route_opening_plan(window_id, "window", window_turf, world_dir, room_id, "outside"))

/datum/world_edit_generator/building_layout/proc/solve_building_v2_openings(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate)
	if(!istype(context) || !istype(candidate))
		return FALSE
	candidate.door_plans.Cut()
	candidate.window_plans.Cut()
	for(var/datum/world_edit_building_v2_room_plan/room_plan as anything in candidate.room_plans)
		if(!istype(room_plan))
			continue
		room_plan.door_candidates.Cut()
		room_plan.window_candidates.Cut()
	if(!solve_building_v2_main_exit(context, candidate))
		candidate.errors += "door.main_exit_missing"
		return FALSE
	for(var/datum/world_edit_building_v2_room_plan/room_plan as anything in candidate.room_plans)
		if(!istype(room_plan))
			continue
		var/datum/world_edit_building_v2_room_contract/room_contract = context.program_contract.get_room_contract(room_plan.contract_id)
		if(istype(room_contract) && !room_contract.must_touch_route)
			continue
		if(!solve_building_v2_room_route_door(context, candidate, room_plan))
			candidate.errors += "door.no_shared_route_wall:[room_plan.id]"
	solve_building_v2_windows(context, candidate)
	return !length(candidate.errors)

/datum/world_edit_generator/building_layout/proc/building_v2_candidate_route_lookup(datum/world_edit_building_v2_layout_candidate/candidate)
	var/list/route_lookup = list()
	if(!istype(candidate))
		return route_lookup
	for(var/turf/route_turf as anything in candidate.route_turfs)
		if(istype(route_turf))
			route_lookup[route_turf] = TRUE
	return route_lookup

/datum/world_edit_generator/building_layout/proc/building_v2_candidate_room_floor_lookup(datum/world_edit_building_v2_layout_candidate/candidate)
	var/list/room_lookup = list()
	if(!istype(candidate))
		return room_lookup
	for(var/datum/world_edit_building_v2_room_plan/room_plan as anything in candidate.room_plans)
		if(!istype(room_plan))
			continue
		for(var/turf/room_turf as anything in room_plan.turfs)
			if(istype(room_turf))
				room_lookup[room_turf] = room_plan.id
	return room_lookup

/datum/world_edit_generator/building_layout/proc/building_v2_opening_turf_is_room_or_route(datum/world_edit_building_v2_layout_candidate/candidate, turf/opening_turf)
	if(!istype(candidate) || !istype(opening_turf))
		return FALSE
	for(var/datum/world_edit_building_v2_room_plan/room_plan as anything in candidate.room_plans)
		if(istype(room_plan) && room_plan.has_turf(opening_turf))
			return TRUE
	for(var/turf/route_turf as anything in candidate.route_turfs)
		if(route_turf == opening_turf)
			return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/solve_building_v2_main_exit(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate)
	var/datum/world_edit_building_layout_state/state = context?.state
	if(!istype(state) || !istype(candidate))
		return FALSE
	var/entry_dir = state.geometry.requested_direction || state.placement_dir || NORTH
	if(!(entry_dir in GLOB.cardinals))
		entry_dir = NORTH
	var/center_x = (state.geometry.bounds["min_x"] + state.geometry.bounds["max_x"]) / 2
	var/center_y = (state.geometry.bounds["min_y"] + state.geometry.bounds["max_y"]) / 2
	var/turf/best_turf = null
	var/best_score = -999999999
	for(var/turf/route_turf as anything in candidate.route_turfs)
		if(!istype(route_turf))
			continue
		var/turf/boundary_turf = get_step(route_turf, entry_dir)
		if(!istype(boundary_turf) || !state.geometry.boundary_lookup[boundary_turf] || !state.geometry.footprint_lookup[boundary_turf])
			continue
		if(!boundary_turf_has_outside_dir(boundary_turf, state.geometry.footprint_lookup, entry_dir))
			continue
		if(is_corner_boundary_turf(boundary_turf, state.geometry.footprint_lookup))
			continue
		var/score = 100000 - (get_lateral_distance_for_dir(boundary_turf, center_x, center_y, entry_dir) * 25)
		score += get_projection_for_dir(boundary_turf, center_x, center_y, entry_dir) * 10
		if(!istype(best_turf) || score > best_score)
			best_turf = boundary_turf
			best_score = score
	if(!istype(best_turf))
		return FALSE
	candidate.add_door_plan(new /datum/world_edit_building_v2_route_opening_plan("front_entry", "main_exit", best_turf, entry_dir, "", "route"))
	return TRUE

/datum/world_edit_generator/building_layout/proc/solve_building_v2_room_route_door(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, datum/world_edit_building_v2_room_plan/room_plan)
	var/list/candidates = collect_building_v2_room_route_door_candidates(context, candidate, room_plan)
	var/list/best = null
	var/best_score = -999999999
	for(var/list/door_candidate as anything in candidates)
		if(!islist(door_candidate))
			continue
		var/score = round(text2num("[door_candidate["score"]]") || 0)
		if(!islist(best) || score > best_score)
			best = door_candidate
			best_score = score
	if(!islist(best))
		return FALSE
	var/turf/opening_turf = best["opening_turf"]
	var/door_dir = best["dir"]
	candidate.add_door_plan(new /datum/world_edit_building_v2_route_opening_plan("[room_plan.id]_to_route", "door", opening_turf, door_dir, room_plan.id, "route"))
	return TRUE

/datum/world_edit_generator/building_layout/proc/collect_building_v2_room_route_door_candidates(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, datum/world_edit_building_v2_room_plan/room_plan)
	var/list/candidates = list()
	if(!istype(context) || !istype(candidate) || !istype(room_plan))
		return candidates
	var/list/route_lookup = building_v2_candidate_route_lookup(candidate)
	var/datum/world_edit_building_v2_room_contract/room_contract = context.program_contract.get_room_contract(room_plan.contract_id)
	for(var/turf/room_turf as anything in room_plan.turfs)
		if(!istype(room_turf))
			continue
		for(var/room_to_wall_dir in GLOB.cardinals)
			var/turf/opening_turf = get_step(room_turf, room_to_wall_dir)
			var/turf/route_turf = get_step(opening_turf, room_to_wall_dir)
			if(!route_lookup[route_turf])
				continue
			var/door_dir = turn(room_to_wall_dir, 180)
			if(!building_v2_opening_wall_matches_room_route(context, candidate, room_plan, opening_turf, door_dir))
				continue
			var/segment_length = building_v2_shared_wall_run_length(context, candidate, room_plan, opening_turf, door_dir)
			if(segment_length < 3)
				continue
			if(building_v2_opening_at_segment_end(context, candidate, room_plan, opening_turf, door_dir))
				continue
			var/score = score_building_v2_room_route_door_candidate(context, candidate, room_plan, room_contract, opening_turf, door_dir, segment_length)
			var/list/door_candidate = list(
				"opening_turf" = opening_turf,
				"room_turf" = room_turf,
				"route_turf" = route_turf,
				"dir" = door_dir,
				"segment_length" = segment_length,
				"score" = score,
			)
			room_plan.door_candidates += list(door_candidate)
			candidates += list(door_candidate)
	return candidates

/datum/world_edit_generator/building_layout/proc/building_v2_opening_wall_matches_room_route(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, datum/world_edit_building_v2_room_plan/room_plan, turf/opening_turf, door_dir)
	if(!istype(context) || !istype(candidate) || !istype(room_plan) || !istype(opening_turf) || !(door_dir in GLOB.cardinals))
		return FALSE
	var/datum/world_edit_building_layout_state/state = context.state
	if(!istype(state) || !state.geometry.footprint_lookup[opening_turf] || state.geometry.boundary_lookup[opening_turf])
		return FALSE
	if(building_v2_opening_turf_is_room_or_route(candidate, opening_turf))
		return FALSE
	var/turf/room_turf = get_step(opening_turf, door_dir)
	var/turf/route_turf = get_step(opening_turf, turn(door_dir, 180))
	if(!room_plan.has_turf(room_turf))
		return FALSE
	var/list/route_lookup = building_v2_candidate_route_lookup(candidate)
	return route_lookup[route_turf] ? TRUE : FALSE

/datum/world_edit_generator/building_layout/proc/building_v2_shared_wall_run_length(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, datum/world_edit_building_v2_room_plan/room_plan, turf/opening_turf, door_dir)
	if(!building_v2_opening_wall_matches_room_route(context, candidate, room_plan, opening_turf, door_dir))
		return 0
	var/run_length = 1
	for(var/axis_dir in list(turn(door_dir, 90), turn(door_dir, -90)))
		var/turf/check_turf = get_step(opening_turf, axis_dir)
		while(building_v2_opening_wall_matches_room_route(context, candidate, room_plan, check_turf, door_dir))
			run_length++
			check_turf = get_step(check_turf, axis_dir)
	return run_length

/datum/world_edit_generator/building_layout/proc/building_v2_opening_at_segment_end(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, datum/world_edit_building_v2_room_plan/room_plan, turf/opening_turf, door_dir)
	if(!building_v2_opening_wall_matches_room_route(context, candidate, room_plan, opening_turf, door_dir))
		return TRUE
	for(var/axis_dir in list(turn(door_dir, 90), turn(door_dir, -90)))
		if(!building_v2_opening_wall_matches_room_route(context, candidate, room_plan, get_step(opening_turf, axis_dir), door_dir))
			return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/score_building_v2_room_route_door_candidate(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, datum/world_edit_building_v2_room_plan/room_plan, datum/world_edit_building_v2_room_contract/room_contract, turf/opening_turf, door_dir, segment_length)
	var/center_x = round((room_plan.x1 + room_plan.x2) / 2)
	var/center_y = round((room_plan.y1 + room_plan.y2) / 2)
	var/score = 10000 + (min(round(text2num("[segment_length]") || 0), 8) * 120)
	score -= (abs(opening_turf.x - center_x) + abs(opening_turf.y - center_y)) * 45
	var/route_center_score = 0
	for(var/turf/route_turf as anything in candidate.route_turfs)
		if(!istype(route_turf))
			continue
		route_center_score = max(route_center_score, 100 - get_dist(opening_turf, route_turf))
	score += route_center_score
	for(var/datum/world_edit_building_v2_route_opening_plan/existing_door as anything in candidate.door_plans)
		if(!istype(existing_door) || !istype(existing_door.opening_turf))
			continue
		var/distance = get_dist(opening_turf, existing_door.opening_turf)
		if(distance <= 1)
			score -= 5000
		else if(distance <= 3)
			score -= 450
		if(istype(room_contract) && room_contract.privacy_class in list("private", "service") && existing_door.kind == "main_exit" && distance <= 4)
			score -= 1200
	if(istype(room_contract) && room_contract.required)
		score += 300
	return score

/datum/world_edit_generator/building_layout/proc/building_v2_door_plan_has_valid_shared_wall(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, datum/world_edit_building_v2_route_opening_plan/door_plan)
	if(!istype(context) || !istype(candidate) || !istype(door_plan) || !istype(door_plan.opening_turf))
		return FALSE
	if(door_plan.kind == "main_exit")
		return building_v2_main_exit_has_valid_boundary(context, candidate, door_plan)
	var/datum/world_edit_building_v2_room_plan/room_plan = candidate.get_room_plan(door_plan.from_room)
	if(!istype(room_plan))
		room_plan = candidate.get_room_plan(door_plan.to_room)
	return building_v2_opening_wall_matches_room_route(context, candidate, room_plan, door_plan.opening_turf, door_plan.dir)

/datum/world_edit_generator/building_layout/proc/building_v2_main_exit_has_valid_boundary(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, datum/world_edit_building_v2_route_opening_plan/door_plan)
	var/datum/world_edit_building_layout_state/state = context?.state
	if(!istype(state) || !istype(candidate) || !istype(door_plan) || !istype(door_plan.opening_turf))
		return FALSE
	if(!state.geometry.boundary_lookup[door_plan.opening_turf])
		return FALSE
	if(!boundary_turf_has_outside_dir(door_plan.opening_turf, state.geometry.footprint_lookup, door_plan.dir))
		return FALSE
	var/turf/inside_turf = get_step(door_plan.opening_turf, turn(door_plan.dir, 180))
	var/list/route_lookup = building_v2_candidate_route_lookup(candidate)
	return route_lookup[inside_turf] ? TRUE : FALSE

/datum/world_edit_generator/building_layout/proc/building_v2_route_turfs_are_connected(datum/world_edit_building_v2_layout_candidate/candidate)
	if(!istype(candidate) || !length(candidate.route_turfs))
		return FALSE
	var/list/route_lookup = building_v2_candidate_route_lookup(candidate)
	var/list/open = list(candidate.route_turfs[1])
	var/list/seen = list()
	while(length(open))
		var/turf/current = open[1]
		open.Cut(1, 2)
		if(!istype(current) || seen[current])
			continue
		seen[current] = TRUE
		for(var/check_dir in GLOB.cardinals)
			var/turf/nearby_turf = get_step(current, check_dir)
			if(route_lookup[nearby_turf] && !seen[nearby_turf])
				open += nearby_turf
	for(var/turf/route_turf as anything in candidate.route_turfs)
		if(istype(route_turf) && !seen[route_turf])
			return FALSE
	return TRUE

/datum/world_edit_generator/building_layout/proc/solve_building_v2_windows(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate)
	if(!istype(context) || !istype(candidate))
		return FALSE
	var/raw_window_density = null
	if(istype(context.state))
		raw_window_density = context.state.config["window_density"]
	var/window_density = clamp(round(text2num("[raw_window_density]") || 0), 0, 100)
	var/list/window_lookup = list()
	for(var/datum/world_edit_building_v2_room_plan/room_plan as anything in candidate.room_plans)
		if(!istype(room_plan))
			continue
		var/datum/world_edit_building_v2_room_contract/room_contract = context.program_contract.get_room_contract(room_plan.contract_id)
		var/policy = istype(room_contract) ? "[room_contract.exterior_window_policy]" : "optional"
		if(policy == "forbidden")
			continue
		if(!(policy in list("required", "desired")))
			continue
		if(window_density <= 0 && policy != "required")
			continue
		if(!(room_plan.role in list("entry_common", "dining", "sleeping")) && !(policy in list("required", "desired")))
			continue
		var/list/window_candidate = select_building_v2_room_window_candidate(context, candidate, room_plan, window_lookup)
		if(!islist(window_candidate))
			if(policy == "required")
				candidate.errors += "window.required_missing:[room_plan.id]"
			continue
		var/turf/window_turf = window_candidate["window_turf"]
		var/window_dir = window_candidate["dir"]
		candidate.add_window_plan(new /datum/world_edit_building_v2_route_opening_plan("[room_plan.id]_window", "window", window_turf, window_dir, room_plan.id, "outside"))
		window_lookup[window_turf] = TRUE
	return !length(candidate.errors)

/datum/world_edit_generator/building_layout/proc/select_building_v2_room_window_candidate(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, datum/world_edit_building_v2_room_plan/room_plan, list/window_lookup)
	var/list/door_lookup = list()
	for(var/datum/world_edit_building_v2_route_opening_plan/door_plan as anything in candidate.door_plans)
		if(istype(door_plan) && istype(door_plan.opening_turf))
			door_lookup[door_plan.opening_turf] = TRUE
	var/list/best = null
	var/best_score = -999999999
	var/center_x = round((room_plan.x1 + room_plan.x2) / 2)
	var/center_y = round((room_plan.y1 + room_plan.y2) / 2)
	for(var/turf/room_turf as anything in room_plan.turfs)
		if(!istype(room_turf))
			continue
		for(var/check_dir in GLOB.cardinals)
			var/turf/window_turf = get_step(room_turf, check_dir)
			if(!istype(window_turf) || !context.state.geometry.boundary_lookup[window_turf] || !context.state.geometry.footprint_lookup[window_turf])
				continue
			if(door_lookup[window_turf] || (islist(window_lookup) && window_lookup[window_turf]))
				continue
			if(is_corner_boundary_turf(window_turf, context.state.geometry.footprint_lookup))
				continue
			if(!boundary_turf_has_outside_dir(window_turf, context.state.geometry.footprint_lookup, check_dir))
				continue
			var/score = 10000 - ((abs(window_turf.x - center_x) + abs(window_turf.y - center_y)) * 35)
			if(room_plan.role in list("entry_common", "dining"))
				score += 300
			if(room_plan.role == "sleeping")
				score += 80
			if(!islist(best) || score > best_score)
				best = list("window_turf" = window_turf, "dir" = check_dir, "score" = score)
				best_score = score
	if(islist(best))
		room_plan.window_candidates += list(best)
	return best

/datum/world_edit_generator/building_layout/proc/building_v2_window_plan_obeys_policy(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, datum/world_edit_building_v2_route_opening_plan/window_plan)
	if(!istype(context) || !istype(candidate) || !istype(window_plan) || !istype(window_plan.opening_turf))
		return FALSE
	var/datum/world_edit_building_layout_state/state = context.state
	if(!istype(state) || !state.geometry.boundary_lookup[window_plan.opening_turf] || !state.geometry.footprint_lookup[window_plan.opening_turf])
		return FALSE
	if(!boundary_turf_has_outside_dir(window_plan.opening_turf, state.geometry.footprint_lookup, window_plan.dir))
		return FALSE
	for(var/datum/world_edit_building_v2_route_opening_plan/door_plan as anything in candidate.door_plans)
		if(istype(door_plan) && door_plan.opening_turf == window_plan.opening_turf)
			return FALSE
	var/datum/world_edit_building_v2_room_plan/room_plan = candidate.get_room_plan(window_plan.from_room)
	if(!istype(room_plan))
		return FALSE
	var/turf/interior_turf = get_step(window_plan.opening_turf, turn(window_plan.dir, 180))
	if(!room_plan.has_turf(interior_turf))
		return FALSE
	var/datum/world_edit_building_v2_room_contract/room_contract = context.program_contract.get_room_contract(room_plan.contract_id)
	if(istype(room_contract) && room_contract.exterior_window_policy == "forbidden")
		return FALSE
	return TRUE

/datum/world_edit_generator/building_layout/proc/solve_building_v2_scenes(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate)
	if(!istype(context) || !istype(candidate))
		return FALSE
	var/list/global_scene_kind_counts = list()
	var/list/global_scene_slot_counts = list()
	for(var/datum/world_edit_building_v2_room_plan/room_plan as anything in candidate.room_plans)
		var/list/scene_candidates = get_building_v2_scene_candidates_for_room(context, room_plan, candidate)
		var/datum/world_edit_building_v2_scene_plan/best_scene = select_best_building_v2_scene_for_room(context, candidate, room_plan, scene_candidates, global_scene_kind_counts, global_scene_slot_counts)
		var/datum/world_edit_building_v2_room_contract/room_contract = context.program_contract.get_room_contract(room_plan.contract_id)
		if(!istype(best_scene))
			if(istype(room_contract) && (room_contract.required || room_plan.area() >= 12))
				candidate.errors += "scene.required_missing:[room_plan.id]"
			continue
		room_plan.scene_plan = best_scene
		room_plan.scene_kind = best_scene.scene_kind
		commit_building_v2_scene_global_counts(context, best_scene, global_scene_kind_counts, global_scene_slot_counts)
	return !length(candidate.errors)

/datum/world_edit_generator/building_layout/proc/get_building_v2_scene_candidates_for_room(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_room_plan/room_plan, datum/world_edit_building_v2_layout_candidate/candidate)
	var/list/scenes = list()
	for(var/datum/world_edit_building_v2_scene_contract/scene_contract as anything in context.program_contract.scene_contracts)
		if(!istype(scene_contract))
			continue
		if(length(scene_contract.allowed_programs) && !(context.program_contract.id in scene_contract.allowed_programs))
			continue
		if(length(scene_contract.allowed_room_roles) && !(room_plan.role in scene_contract.allowed_room_roles))
			continue
		if(length(scene_contract.allowed_room_ids) && !(room_plan.id in scene_contract.allowed_room_ids))
			continue
		if(room_plan.area() < scene_contract.min_room_area || room_plan.width() < scene_contract.min_room_width || room_plan.height() < scene_contract.min_room_height)
			continue
		var/datum/world_edit_building_v2_room_plan/dining_room_plan = candidate.get_room_plan("dining")
		if((scene_contract.id in list("common_dining_4", "common_dining_2", "common_lounge_pair")) && room_plan.contract_id == "entry_common" && istype(dining_room_plan))
			continue
		if(room_plan.role == "utility" && scene_contract.id != "storage_crate_corner")
			continue
		scenes += scene_contract
	return scenes

/datum/world_edit_generator/building_layout/proc/select_best_building_v2_scene_for_room(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, datum/world_edit_building_v2_room_plan/room_plan, list/scenes, list/global_scene_kind_counts = null, list/global_scene_slot_counts = null)
	var/datum/world_edit_building_v2_scene_plan/best = null
	var/best_score = -999999999
	for(var/datum/world_edit_building_v2_scene_contract/scene_contract as anything in scenes)
		var/datum/world_edit_building_v2_scene_plan/scene_plan = build_building_v2_scene_plan(context, candidate, room_plan, scene_contract)
		if(!istype(scene_plan) || !length(scene_plan.members))
			continue
		if(!building_v2_scene_within_global_limits(context, scene_plan, global_scene_kind_counts, global_scene_slot_counts))
			continue
		var/score = scene_plan.score
		if(!istype(best) || score > best_score)
			best = scene_plan
			best_score = score
	return best

/datum/world_edit_generator/building_layout/proc/build_building_v2_scene_plan(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, datum/world_edit_building_v2_room_plan/room_plan, datum/world_edit_building_v2_scene_contract/scene_contract)
	var/datum/world_edit_building_v2_scene_plan/scene_plan = new
	scene_plan.id = "[room_plan.id]_[scene_contract.id]"
	scene_plan.room_id = room_plan.id
	scene_plan.room_contract_id = room_plan.contract_id
	scene_plan.scene_contract_id = scene_contract.id
	scene_plan.scene_kind = scene_contract.scene_kind
	scene_plan.primary = scene_contract.primary
	scene_plan.score = 100 + room_plan.area()
	switch(scene_contract.id)
		if("common_dining_4")
			if(!add_building_v2_table_scene_members(context, candidate, room_plan, scene_plan, 4))
				return null
			scene_plan.score += 80
		if("common_dining_2")
			if(!add_building_v2_table_scene_members(context, candidate, room_plan, scene_plan, 2))
				return null
			scene_plan.score += 40
		if("common_lounge_pair")
			if(!add_building_v2_lounge_scene_members(context, candidate, room_plan, scene_plan))
				return null
			scene_plan.score += 30
		if("common_entry_side_surface")
			if(!add_building_v2_side_surface_scene_members(context, candidate, room_plan, scene_plan))
				return null
			scene_plan.score += 10
		if("bedroom_bed_cabinet")
			if(!add_building_v2_bedroom_scene_members(context, candidate, room_plan, scene_plan, TRUE))
				return null
			scene_plan.score += 60
		if("bedroom_single_wall")
			if(!add_building_v2_bedroom_scene_members(context, candidate, room_plan, scene_plan, FALSE))
				return null
			scene_plan.score += 35
		if("sanitation_toilet_sink")
			if(!add_building_v2_sanitation_scene_members(context, candidate, room_plan, scene_plan, TRUE))
				return null
			scene_plan.score += 50
		if("sanitation_toilet_only")
			if(!add_building_v2_sanitation_scene_members(context, candidate, room_plan, scene_plan, FALSE))
				return null
			scene_plan.score += 20
		if("storage_rack_wall")
			if(!add_building_v2_storage_scene_members(context, candidate, room_plan, scene_plan, "rack"))
				return null
			scene_plan.score += 45
		if("storage_cabinet_wall")
			if(!add_building_v2_storage_scene_members(context, candidate, room_plan, scene_plan, "cabinet"))
				return null
			scene_plan.score += 35
		if("storage_crate_corner")
			if(!add_building_v2_storage_scene_members(context, candidate, room_plan, scene_plan, "crate"))
				return null
			scene_plan.score += 15
	if(!building_v2_scene_members_inside_room(room_plan, scene_plan))
		return null
	if(!building_v2_scene_members_clear_candidate_paths(candidate, scene_plan))
		return null
	if(!building_v2_scene_slots_within_contract(scene_plan, scene_contract))
		return null
	return scene_plan

/datum/world_edit_generator/building_layout/proc/building_v2_global_scene_slot_key(scene_slot)
	switch("[scene_slot]")
		if("dining_focal", "lounge_focal")
			return "public_focal"
	return "[scene_slot]"

/datum/world_edit_generator/building_layout/proc/building_v2_scene_within_global_limits(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_scene_plan/scene_plan, list/global_scene_kind_counts = null, list/global_scene_slot_counts = null)
	if(!istype(context) || !istype(scene_plan))
		return FALSE
	var/list/kind_limits = islist(context.program_contract?.global_scene_kind_limits) ? context.program_contract.global_scene_kind_limits : list()
	var/list/slot_limits = islist(context.program_contract?.global_scene_slot_limits) ? context.program_contract.global_scene_slot_limits : list()
	var/kind_limit = round(text2num("[kind_limits[scene_plan.scene_kind]]") || 0)
	if(kind_limit > 0 && islist(global_scene_kind_counts) && (round(text2num("[global_scene_kind_counts[scene_plan.scene_kind]]") || 0) + 1) > kind_limit)
		return FALSE
	for(var/scene_slot as anything in scene_plan.scene_slot_counts)
		var/global_slot = building_v2_global_scene_slot_key(scene_slot)
		var/slot_limit = round(text2num("[slot_limits[global_slot]]") || 0)
		if(slot_limit <= 0 || !islist(global_scene_slot_counts))
			continue
		var/current_count = round(text2num("[global_scene_slot_counts[global_slot]]") || 0)
		var/add_count = round(text2num("[scene_plan.scene_slot_counts[scene_slot]]") || 0)
		if(current_count + add_count > slot_limit)
			return FALSE
	return TRUE

/datum/world_edit_generator/building_layout/proc/commit_building_v2_scene_global_counts(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_scene_plan/scene_plan, list/global_scene_kind_counts, list/global_scene_slot_counts)
	if(!istype(context) || !istype(scene_plan))
		return
	if(islist(global_scene_kind_counts))
		global_scene_kind_counts[scene_plan.scene_kind] = (global_scene_kind_counts[scene_plan.scene_kind] || 0) + 1
	if(!islist(global_scene_slot_counts))
		return
	for(var/scene_slot as anything in scene_plan.scene_slot_counts)
		var/global_slot = building_v2_global_scene_slot_key(scene_slot)
		global_scene_slot_counts[global_slot] = (global_scene_slot_counts[global_slot] || 0) + round(text2num("[scene_plan.scene_slot_counts[scene_slot]]") || 0)

/datum/world_edit_generator/building_layout/proc/building_v2_scene_members_clear_candidate_paths(datum/world_edit_building_v2_layout_candidate/candidate, datum/world_edit_building_v2_scene_plan/scene_plan)
	if(!istype(candidate) || !istype(scene_plan))
		return FALSE
	var/list/route_lookup = list()
	for(var/turf/route_turf as anything in candidate.route_turfs)
		if(istype(route_turf))
			route_lookup[route_turf] = TRUE
	var/list/door_clearance_lookup = list()
	for(var/datum/world_edit_building_v2_route_opening_plan/door_plan as anything in candidate.door_plans)
		if(!istype(door_plan) || !istype(door_plan.opening_turf))
			continue
		door_clearance_lookup[door_plan.opening_turf] = TRUE
		door_clearance_lookup[get_step(door_plan.opening_turf, door_plan.dir)] = TRUE
		door_clearance_lookup[get_step(door_plan.opening_turf, turn(door_plan.dir, 180))] = TRUE
	for(var/list/member as anything in scene_plan.members)
		var/turf/member_turf = member["turf"]
		if(!istype(member_turf) || route_lookup[member_turf] || door_clearance_lookup[member_turf])
			return FALSE
	return TRUE

/datum/world_edit_generator/building_layout/proc/building_v2_scene_slots_within_contract(datum/world_edit_building_v2_scene_plan/scene_plan, datum/world_edit_building_v2_scene_contract/scene_contract)
	if(!istype(scene_plan) || !istype(scene_contract))
		return FALSE
	for(var/scene_slot as anything in scene_plan.scene_slot_counts)
		var/count = round(text2num("[scene_plan.scene_slot_counts[scene_slot]]") || 0)
		var/limit = round(text2num("[scene_contract.scene_slot_limits[scene_slot]]") || 0)
		if(limit > 0 && count > limit)
			return FALSE
	return TRUE

/datum/world_edit_generator/building_layout/proc/building_v2_scene_members_inside_room(datum/world_edit_building_v2_room_plan/room_plan, datum/world_edit_building_v2_scene_plan/scene_plan)
	if(!istype(room_plan) || !istype(scene_plan))
		return FALSE
	var/list/seen = list()
	for(var/list/member as anything in scene_plan.members)
		var/turf/member_turf = member["turf"]
		if(!room_plan.has_turf(member_turf) || seen[member_turf])
			return FALSE
		seen[member_turf] = TRUE
	return TRUE

/datum/world_edit_generator/building_layout/proc/add_building_v2_scene_blocked_turf(list/blocked_lookup, turf/target_turf)
	if(islist(blocked_lookup) && istype(target_turf))
		blocked_lookup[target_turf] = TRUE

/datum/world_edit_generator/building_layout/proc/build_building_v2_candidate_floor_lookup(datum/world_edit_building_v2_layout_candidate/candidate)
	var/list/floor_lookup = list()
	if(!istype(candidate))
		return floor_lookup
	for(var/datum/world_edit_building_v2_room_plan/room_plan as anything in candidate.room_plans)
		if(!istype(room_plan))
			continue
		for(var/turf/room_turf as anything in room_plan.turfs)
			if(istype(room_turf))
				floor_lookup[room_turf] = TRUE
	for(var/turf/route_turf as anything in candidate.route_turfs)
		if(istype(route_turf))
			floor_lookup[route_turf] = TRUE
	for(var/datum/world_edit_building_v2_route_opening_plan/door_plan as anything in candidate.door_plans)
		if(istype(door_plan) && istype(door_plan.opening_turf))
			floor_lookup[door_plan.opening_turf] = TRUE
	return floor_lookup

/datum/world_edit_generator/building_layout/proc/build_building_v2_window_lookup(datum/world_edit_building_v2_layout_candidate/candidate)
	var/list/window_lookup = list()
	if(!istype(candidate))
		return window_lookup
	for(var/datum/world_edit_building_v2_route_opening_plan/window_plan as anything in candidate.window_plans)
		if(istype(window_plan) && istype(window_plan.opening_turf))
			window_lookup[window_plan.opening_turf] = TRUE
	return window_lookup

/datum/world_edit_generator/building_layout/proc/build_building_v2_scene_blocked_lookup(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, list/occupied_lookup = null)
	var/list/blocked_lookup = list()
	if(!istype(context) || !istype(candidate))
		return blocked_lookup
	for(var/turf/route_turf as anything in candidate.route_turfs)
		add_building_v2_scene_blocked_turf(blocked_lookup, route_turf)
	for(var/datum/world_edit_building_v2_route_opening_plan/door_plan as anything in candidate.door_plans)
		if(!istype(door_plan) || !istype(door_plan.opening_turf))
			continue
		add_building_v2_scene_blocked_turf(blocked_lookup, door_plan.opening_turf)
		add_building_v2_scene_blocked_turf(blocked_lookup, get_step(door_plan.opening_turf, door_plan.dir))
		add_building_v2_scene_blocked_turf(blocked_lookup, get_step(door_plan.opening_turf, turn(door_plan.dir, 180)))
	for(var/datum/world_edit_building_v2_route_opening_plan/window_plan as anything in candidate.window_plans)
		if(!istype(window_plan) || !istype(window_plan.opening_turf))
			continue
		add_building_v2_scene_blocked_turf(blocked_lookup, window_plan.opening_turf)
		add_building_v2_scene_blocked_turf(blocked_lookup, get_step(window_plan.opening_turf, turn(window_plan.dir, 180)))
	if(islist(occupied_lookup))
		for(var/turf/occupied_turf as anything in occupied_lookup)
			add_building_v2_scene_blocked_turf(blocked_lookup, occupied_turf)
	return blocked_lookup

/datum/world_edit_generator/building_layout/proc/building_v2_scene_turf_clear(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, datum/world_edit_building_v2_room_plan/room_plan, turf/target_turf, list/blocked_lookup, list/occupied_lookup = null)
	if(!istype(context) || !istype(candidate) || !istype(room_plan) || !istype(target_turf))
		return FALSE
	if(!room_plan.has_turf(target_turf))
		return FALSE
	if(blocked_lookup[target_turf])
		return FALSE
	if(islist(occupied_lookup) && occupied_lookup[target_turf])
		return FALSE
	var/datum/world_edit_building_layout_state/state = context.state
	if(istype(state))
		if(state.fixtures.fixture_lookup[target_turf] || state.fixtures.semantic_slot_clearance_by_turf[target_turf])
			return FALSE
	return TRUE

/datum/world_edit_generator/building_layout/proc/building_v2_scene_clearance_turf_open(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, datum/world_edit_building_v2_room_plan/room_plan, turf/check_turf, list/blocked_lookup, list/occupied_lookup = null)
	return building_v2_scene_turf_clear(context, candidate, room_plan, check_turf, blocked_lookup, occupied_lookup)

/datum/world_edit_generator/building_layout/proc/building_v2_scene_place_rule_clearance_ok(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, datum/world_edit_building_v2_room_plan/room_plan, turf/target_turf, dir_to_use, wall_dir, datum/world_edit_building_place_rule/place_rule, list/blocked_lookup, list/occupied_lookup = null)
	if(!istype(place_rule))
		place_rule = resolve_building_place_rule(null, null)
	var/front_steps = max(round(text2num("[place_rule.clear_front]") || 0), 0)
	var/side_steps = max(round(text2num("[place_rule.clear_sides]") || 0), 0)
	if(front_steps <= 0 && side_steps <= 0)
		return TRUE
	var/front_dir = get_building_place_rule_front_dir(dir_to_use, wall_dir, place_rule)
	if(!front_dir)
		return FALSE
	if(front_steps > 0)
		var/turf/front_turf = target_turf
		for(var/step_index in 1 to front_steps)
			front_turf = get_step(front_turf, front_dir)
			if(!building_v2_scene_clearance_turf_open(context, candidate, room_plan, front_turf, blocked_lookup, occupied_lookup))
				return FALSE
	if(side_steps > 0)
		for(var/side_dir as anything in list(turn(front_dir, 90), turn(front_dir, -90)))
			var/turf/side_turf = target_turf
			for(var/step_index in 1 to side_steps)
				side_turf = get_step(side_turf, side_dir)
				if(!building_v2_scene_clearance_turf_open(context, candidate, room_plan, side_turf, blocked_lookup, occupied_lookup))
					return FALSE
	return TRUE

/datum/world_edit_generator/building_layout/proc/get_building_v2_scene_adjacent_wall_dirs(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, turf/target_turf)
	var/list/wall_dirs = list()
	if(!istype(context) || !istype(candidate) || !istype(target_turf))
		return wall_dirs
	var/list/floor_lookup = build_building_v2_candidate_floor_lookup(candidate)
	var/list/window_lookup = build_building_v2_window_lookup(candidate)
	for(var/check_dir as anything in GLOB.cardinals)
		var/turf/wall_turf = get_step(target_turf, check_dir)
		if(!istype(wall_turf) || !context.state.geometry.footprint_lookup[wall_turf])
			continue
		if(floor_lookup[wall_turf] || window_lookup[wall_turf])
			continue
		wall_dirs += check_dir
	return wall_dirs

/datum/world_edit_generator/building_layout/proc/score_building_v2_scene_turf(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, datum/world_edit_building_v2_room_plan/room_plan, turf/target_turf, scene_kind, wall_dir = null)
	if(!istype(context) || !istype(candidate) || !istype(room_plan) || !istype(target_turf))
		return -999999999
	var/center_x = round((room_plan.x1 + room_plan.x2) / 2)
	var/center_y = round((room_plan.y1 + room_plan.y2) / 2)
	var/center_dist = abs(target_turf.x - center_x) + abs(target_turf.y - center_y)
	var/list/wall_dirs = get_building_v2_scene_adjacent_wall_dirs(context, candidate, target_turf)
	var/adjacent_wall_count = length(wall_dirs)
	var/score = 1000 - (center_dist * 12)
	if(!isnull(wall_dir))
		score += 160
	switch("[scene_kind]")
		if("dining")
			score += 260 - (center_dist * 18)
			score -= adjacent_wall_count * 80
		if("living_common")
			score += adjacent_wall_count * 75
		if("bedroom")
			score += adjacent_wall_count * 140
		if("sanitation")
			score += adjacent_wall_count * 120
		if("storage")
			score += adjacent_wall_count * 150
	for(var/datum/world_edit_building_v2_route_opening_plan/door_plan as anything in candidate.door_plans)
		if(!istype(door_plan) || !istype(door_plan.opening_turf))
			continue
		var/door_dist = get_dist(target_turf, door_plan.opening_turf)
		if(door_dist <= 1)
			score -= 900
		else if(door_dist == 2)
			score -= 180
	for(var/datum/world_edit_building_v2_route_opening_plan/window_plan as anything in candidate.window_plans)
		if(!istype(window_plan) || !istype(window_plan.opening_turf))
			continue
		if(get_dist(target_turf, window_plan.opening_turf) <= 1)
			score -= 180
	for(var/turf/route_turf as anything in candidate.route_turfs)
		if(istype(route_turf) && get_dist(target_turf, route_turf) == 1)
			score -= 80
	return score

/datum/world_edit_generator/building_layout/proc/select_building_v2_scene_anchor(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, datum/world_edit_building_v2_room_plan/room_plan, slot, category, scene_kind, list/occupied_lookup = null, require_wall = FALSE, prefer_wall = FALSE, min_adjacent_walls = 0)
	var/list/blocked_lookup = build_building_v2_scene_blocked_lookup(context, candidate, occupied_lookup)
	var/datum/world_edit_building_place_rule/place_rule = resolve_building_place_rule(slot, category)
	var/list/best_anchor = null
	var/best_score = -999999999
	for(var/turf/candidate_turf as anything in room_plan.turfs)
		if(!building_v2_scene_turf_clear(context, candidate, room_plan, candidate_turf, blocked_lookup, occupied_lookup))
			continue
		var/list/wall_dirs = get_building_v2_scene_adjacent_wall_dirs(context, candidate, candidate_turf)
		if(length(wall_dirs) < min_adjacent_walls)
			continue
		if(require_wall || place_rule.needs_wall || prefer_wall)
			for(var/wall_dir as anything in wall_dirs)
				var/dir_to_use = resolve_building_place_rule_dir(wall_dir, place_rule.dir_mode)
				if(!dir_to_use)
					continue
				if(!building_v2_scene_place_rule_clearance_ok(context, candidate, room_plan, candidate_turf, dir_to_use, wall_dir, place_rule, blocked_lookup, occupied_lookup))
					continue
				var/score = score_building_v2_scene_turf(context, candidate, room_plan, candidate_turf, scene_kind, wall_dir) + place_rule.priority_bonus
				if(!islist(best_anchor) || score > best_score)
					best_anchor = list("turf" = candidate_turf, "dir" = dir_to_use, "wall_dir" = wall_dir, "score" = score)
					best_score = score
			if(require_wall || place_rule.needs_wall)
				continue
		var/fallback_dir = context.state ? (context.state.placement_dir || SOUTH) : SOUTH
		if(!building_v2_scene_place_rule_clearance_ok(context, candidate, room_plan, candidate_turf, fallback_dir, null, place_rule, blocked_lookup, occupied_lookup))
			continue
		var/fallback_score = score_building_v2_scene_turf(context, candidate, room_plan, candidate_turf, scene_kind) + place_rule.priority_bonus
		if(!islist(best_anchor) || fallback_score > best_score)
			best_anchor = list("turf" = candidate_turf, "dir" = fallback_dir, "wall_dir" = null, "score" = fallback_score)
			best_score = fallback_score
	return best_anchor

/datum/world_edit_generator/building_layout/proc/add_building_v2_scene_member_from_anchor(datum/world_edit_building_v2_scene_plan/scene_plan, slot, category, anchor, scene_slot, wall_mounted = FALSE, major = FALSE)
	var/turf/anchor_turf = null
	if(islist(anchor))
		anchor_turf = anchor["turf"]
	if(!istype(scene_plan) || !istype(anchor_turf))
		return FALSE
	scene_plan.add_member(slot, category, anchor_turf, anchor["dir"] || SOUTH, scene_slot, wall_mounted, major)
	return TRUE

/datum/world_edit_generator/building_layout/proc/add_building_v2_table_scene_members(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, datum/world_edit_building_v2_room_plan/room_plan, datum/world_edit_building_v2_scene_plan/scene_plan, chair_count)
	var/list/blocked_lookup = build_building_v2_scene_blocked_lookup(context, candidate)
	var/list/chair_sets = chair_count >= 4 ? list(list(list(0, 1), list(0, -1), list(1, 0), list(-1, 0))) : list(list(list(0, 1), list(0, -1)), list(list(1, 0), list(-1, 0)))
	var/list/best_members = null
	var/best_score = -999999999
	for(var/turf/table_turf as anything in room_plan.turfs)
		if(!building_v2_scene_turf_clear(context, candidate, room_plan, table_turf, blocked_lookup))
			continue
		for(var/list/chair_offsets as anything in chair_sets)
			var/list/occupied_lookup = list()
			occupied_lookup[table_turf] = TRUE
			var/table_dir = context.state ? (context.state.placement_dir || SOUTH) : SOUTH
			var/list/members = list(list("slot" = "table", "category" = "table", "turf" = table_turf, "dir" = table_dir, "scene_slot" = "dining_focal", "wall_mounted" = FALSE, "major" = TRUE))
			var/valid = TRUE
			for(var/list/offset as anything in chair_offsets)
				var/turf/chair_turf = locate(table_turf.x + offset[1], table_turf.y + offset[2], table_turf.z)
				if(!building_v2_scene_turf_clear(context, candidate, room_plan, chair_turf, blocked_lookup, occupied_lookup))
					valid = FALSE
					break
				occupied_lookup[chair_turf] = TRUE
				members += list(list("slot" = "chair", "category" = "chair", "turf" = chair_turf, "dir" = get_cardinal_dir_toward(chair_turf, table_turf, SOUTH), "scene_slot" = "dining_focal", "wall_mounted" = FALSE, "major" = FALSE))
			if(!valid)
				continue
			var/score = score_building_v2_scene_turf(context, candidate, room_plan, table_turf, "dining") + length(members) * 35
			if(!islist(best_members) || score > best_score)
				best_members = members
				best_score = score
	if(!islist(best_members))
		return FALSE
	for(var/list/member as anything in best_members)
		scene_plan.add_member(member["slot"], member["category"], member["turf"], member["dir"], member["scene_slot"], member["wall_mounted"], member["major"])
	return TRUE

/datum/world_edit_generator/building_layout/proc/add_building_v2_lounge_scene_members(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, datum/world_edit_building_v2_room_plan/room_plan, datum/world_edit_building_v2_scene_plan/scene_plan)
	var/list/blocked_lookup = build_building_v2_scene_blocked_lookup(context, candidate)
	var/list/best_members = null
	var/best_score = -999999999
	for(var/turf/left_turf as anything in room_plan.turfs)
		if(!building_v2_scene_turf_clear(context, candidate, room_plan, left_turf, blocked_lookup))
			continue
		for(var/pair_dir as anything in list(EAST, SOUTH))
			var/turf/right_turf = get_step(left_turf, pair_dir)
			var/list/occupied_lookup = list()
			occupied_lookup[left_turf] = TRUE
			if(!building_v2_scene_turf_clear(context, candidate, room_plan, right_turf, blocked_lookup, occupied_lookup))
				continue
			occupied_lookup[right_turf] = TRUE
			var/turf/table_turf = null
			for(var/table_dir as anything in list(turn(pair_dir, 90), turn(pair_dir, -90)))
				var/turf/left_table_turf = get_step(left_turf, table_dir)
				if(building_v2_scene_turf_clear(context, candidate, room_plan, left_table_turf, blocked_lookup, occupied_lookup))
					table_turf = left_table_turf
					break
				var/turf/right_table_turf = get_step(right_turf, table_dir)
				if(building_v2_scene_turf_clear(context, candidate, room_plan, right_table_turf, blocked_lookup, occupied_lookup))
					table_turf = right_table_turf
					break
			var/score = score_building_v2_scene_turf(context, candidate, room_plan, left_turf, "living_common") + score_building_v2_scene_turf(context, candidate, room_plan, right_turf, "living_common")
			if(istype(table_turf))
				score += score_building_v2_scene_turf(context, candidate, room_plan, table_turf, "living_common") + 20
			if(!islist(best_members) || score > best_score)
				var/list/members = list(
					list("slot" = "chair", "category" = "chair", "turf" = left_turf, "dir" = pair_dir, "scene_slot" = "lounge_focal", "wall_mounted" = FALSE, "major" = TRUE),
					list("slot" = "chair", "category" = "chair", "turf" = right_turf, "dir" = turn(pair_dir, 180), "scene_slot" = "lounge_focal", "wall_mounted" = FALSE, "major" = FALSE),
				)
				if(istype(table_turf))
					members += list(list("slot" = "table", "category" = "table", "turf" = table_turf, "dir" = get_cardinal_dir_toward(table_turf, left_turf, SOUTH), "scene_slot" = "lounge_focal", "wall_mounted" = FALSE, "major" = FALSE))
				best_members = members
				best_score = score
	if(!islist(best_members))
		return FALSE
	for(var/list/member as anything in best_members)
		scene_plan.add_member(member["slot"], member["category"], member["turf"], member["dir"], member["scene_slot"], member["wall_mounted"], member["major"])
	return TRUE

/datum/world_edit_generator/building_layout/proc/add_building_v2_side_surface_scene_members(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, datum/world_edit_building_v2_room_plan/room_plan, datum/world_edit_building_v2_scene_plan/scene_plan)
	var/list/table_anchor = select_building_v2_scene_anchor(context, candidate, room_plan, "table", "table", "living_common", null, TRUE, TRUE)
	if(!add_building_v2_scene_member_from_anchor(scene_plan, "table", "table", table_anchor, "side_surface", TRUE, TRUE))
		return FALSE
	var/list/occupied_lookup = list()
	var/turf/table_turf = islist(table_anchor) ? table_anchor["turf"] : null
	if(istype(table_turf))
		occupied_lookup[table_turf] = TRUE
	var/detail_target = room_plan.area() >= 48 ? 4 : (room_plan.area() >= 36 ? 3 : 1)
	for(var/detail_index in 2 to detail_target)
		var/detail_slot = (detail_index % 2) ? "cabinet" : "table"
		var/detail_category = detail_slot == "cabinet" ? "cabinet" : "table"
		var/list/detail_anchor = select_building_v2_scene_anchor(context, candidate, room_plan, detail_slot, detail_category, "living_common", occupied_lookup, TRUE, TRUE)
		if(!islist(detail_anchor))
			continue
		if(add_building_v2_scene_member_from_anchor(scene_plan, detail_slot, detail_category, detail_anchor, "side_surface", TRUE, FALSE))
			var/turf/detail_turf = detail_anchor["turf"]
			if(istype(detail_turf))
				occupied_lookup[detail_turf] = TRUE
	return TRUE

/datum/world_edit_generator/building_layout/proc/add_building_v2_bedroom_scene_members(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, datum/world_edit_building_v2_room_plan/room_plan, datum/world_edit_building_v2_scene_plan/scene_plan, include_cabinet)
	var/list/bed_anchor = select_building_v2_scene_anchor(context, candidate, room_plan, "bed", "bed", "bedroom", null, TRUE, TRUE)
	if(!islist(bed_anchor))
		return FALSE
	var/list/occupied_lookup = list()
	var/turf/bed_turf = bed_anchor["turf"]
	occupied_lookup[bed_turf] = TRUE
	var/access_dir = get_building_place_rule_front_dir(bed_anchor["dir"], bed_anchor["wall_dir"], resolve_building_place_rule("bed", "bed"))
	var/turf/access_turf = access_dir ? get_step(bed_turf, access_dir) : null
	var/list/blocked_lookup = build_building_v2_scene_blocked_lookup(context, candidate, occupied_lookup)
	if(!building_v2_scene_clearance_turf_open(context, candidate, room_plan, access_turf, blocked_lookup, occupied_lookup))
		return FALSE
	if(istype(access_turf))
		occupied_lookup[access_turf] = TRUE
	scene_plan.add_member("bed", "bed", bed_turf, bed_anchor["dir"], "sleep_fixture", TRUE, TRUE)
	if(include_cabinet)
		var/list/cabinet_anchor = select_building_v2_scene_anchor(context, candidate, room_plan, "cabinet", "cabinet", "bedroom", occupied_lookup, TRUE, TRUE)
		if(!add_building_v2_scene_member_from_anchor(scene_plan, "cabinet", "cabinet", cabinet_anchor, "bedroom_storage", TRUE, FALSE))
			return FALSE
		if(islist(cabinet_anchor))
			occupied_lookup[cabinet_anchor["turf"]] = TRUE
		if(room_plan.area() >= 28)
			var/list/second_cabinet_anchor = select_building_v2_scene_anchor(context, candidate, room_plan, "cabinet", "cabinet", "bedroom", occupied_lookup, TRUE, TRUE)
			if(islist(second_cabinet_anchor))
				add_building_v2_scene_member_from_anchor(scene_plan, "cabinet", "cabinet", second_cabinet_anchor, "bedroom_storage", TRUE, FALSE)
	return TRUE

/datum/world_edit_generator/building_layout/proc/add_building_v2_sanitation_scene_members(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, datum/world_edit_building_v2_room_plan/room_plan, datum/world_edit_building_v2_scene_plan/scene_plan, include_sink)
	var/list/toilet_anchor = select_building_v2_scene_anchor(context, candidate, room_plan, "toilet", "sanitation", "sanitation", null, FALSE, TRUE, 1)
	if(!add_building_v2_scene_member_from_anchor(scene_plan, "toilet", "sanitation", toilet_anchor, "sanitation_fixture", FALSE, TRUE))
		return FALSE
	var/list/occupied_lookup = list()
	occupied_lookup[toilet_anchor["turf"]] = TRUE
	if(include_sink)
		var/list/sink_anchor = select_building_v2_scene_anchor(context, candidate, room_plan, "sink", "kitchen_machine", "sanitation", occupied_lookup, TRUE, TRUE)
		if(!add_building_v2_scene_member_from_anchor(scene_plan, "sink", "kitchen_machine", sink_anchor, "sanitation_fixture", TRUE, FALSE))
			return FALSE
	return TRUE

/datum/world_edit_generator/building_layout/proc/add_building_v2_storage_scene_members(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, datum/world_edit_building_v2_room_plan/room_plan, datum/world_edit_building_v2_scene_plan/scene_plan, storage_slot)
	var/category = storage_slot == "crate" ? "crate" : storage_slot
	var/scene_slot = storage_slot == "crate" ? "storage_corner" : "storage_run"
	if(storage_slot == "crate")
		var/list/crate_anchor = select_building_v2_scene_anchor(context, candidate, room_plan, "crate", category, "storage", null, FALSE, TRUE, 1)
		if(!add_building_v2_scene_member_from_anchor(scene_plan, "crate", category, crate_anchor, scene_slot, FALSE, TRUE))
			return FALSE
		var/list/occupied_lookup = list()
		occupied_lookup[crate_anchor["turf"]] = TRUE
		var/detail_target = room_plan.area() >= 32 ? 4 : (room_plan.area() >= 28 ? 3 : 2)
		for(var/detail_index in 2 to detail_target)
			var/list/detail_crate = select_building_v2_scene_anchor(context, candidate, room_plan, "crate", category, "storage", occupied_lookup, FALSE, TRUE, 1)
			if(!islist(detail_crate))
				continue
			if(add_building_v2_scene_member_from_anchor(scene_plan, "crate", category, detail_crate, scene_slot, FALSE, FALSE))
				var/turf/detail_turf = detail_crate["turf"]
				if(istype(detail_turf))
					occupied_lookup[detail_turf] = TRUE
		return TRUE
	var/list/primary_anchor = select_building_v2_scene_anchor(context, candidate, room_plan, storage_slot, category, "storage", null, TRUE, TRUE)
	if(!add_building_v2_scene_member_from_anchor(scene_plan, storage_slot, category, primary_anchor, scene_slot, TRUE, TRUE))
		return FALSE
	var/list/occupied_lookup = list()
	occupied_lookup[primary_anchor["turf"]] = TRUE
	var/list/secondary_anchor = select_building_v2_scene_anchor(context, candidate, room_plan, storage_slot, category, "storage", occupied_lookup, TRUE, TRUE)
	if(islist(secondary_anchor))
		add_building_v2_scene_member_from_anchor(scene_plan, storage_slot, category, secondary_anchor, scene_slot, TRUE, FALSE)
	return TRUE

/datum/world_edit_generator/building_layout/proc/run_building_v2_candidate_emission_pipeline(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate)
	var/datum/world_edit_building_layout_state/state = context?.state
	if(!istype(state) || !istype(candidate))
		return FALSE
	context.selected_candidate = candidate
	state.layout_v2_context = context
	stamp_building_v2_selected_candidate(state, candidate)
	if(!emit_building_v2_candidate_to_state(context, candidate))
		state.add_error("Building layout v2 could not emit the selected candidate.")
		return FALSE
	refresh_building_semantic_anchors(state)
	reserve_building_immediate_door_cones(state)
	if(!place_building_v2_scene_plans(context, candidate))
		state.add_error("Building layout v2 could not place solved room scenes.")
		return FALSE
	place_building_infrastructure(state)
	state.rebuild_fixture_indexes()
	add_building_v2_scene_placement_report(state)
	validate_building_layout_state(state)
	if(state.has_errors())
		add_building_v2_validation_debug_report(state)
	state.fixtures.pattern_credit_hash = build_building_assoc_hash(state.fixtures.semantic_requirement_counts)
	build_building_v2_layout_hashes(state)
	state.config["layout_v2_scene_count"] = length(candidate.room_plans)
	return !state.has_errors()

/datum/world_edit_generator/building_layout/proc/emit_building_v2_candidate_to_state(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate)
	var/datum/world_edit_building_layout_state/state = context.state
	if(!istype(state) || !istype(candidate))
		return FALSE
	state.clear_room_layout()
	state.geometry.door_turfs.Cut()
	state.geometry.door_dirs.Cut()
	state.geometry.window_turfs.Cut()
	state.validation.door_reports.Cut()
	state.validation.room_reports.Cut()
	state.validation.zone_reports.Cut()
	state.validation.corridor_report = list()
	state.fixtures.scene_plans.Cut()
	state.fixtures.scene_counts_by_room.Cut()
	state.fixtures.scene_primary_counts_by_room.Cut()
	state.fixtures.scene_kind_by_room.Cut()
	state.fixtures.scene_slot_counts_by_room.Cut()
	state.geometry.layout_v2_room_plans = candidate.room_plans.Copy()
	state.geometry.layout_v2_route_opening_plans = candidate.door_plans.Copy()
	var/list/floor_lookup = list()
	var/list/floor_turfs = list()
	for(var/datum/world_edit_building_v2_room_plan/room_plan as anything in candidate.room_plans)
		var/datum/world_edit_building_room/room = new("v2_[room_plan.id]", room_plan.zone_id, room_plan.role)
		for(var/turf/room_turf as anything in room_plan.turfs)
			room.add_turf(room_turf)
			if(!floor_lookup[room_turf])
				floor_lookup[room_turf] = TRUE
				floor_turfs += room_turf
			state.add_zone(room_turf, room_plan.zone_id)
		room.focus_turf = select_building_v2_room_focus(room_plan)
		state.add_solved_room(room)
		var/datum/world_edit_building_solved_region/region = new("v2_region_[room_plan.id]", room_plan.zone_id, room_plan.role in list("entry_common", "sleeping", "sanitation", "storage") ? 100 : 50)
		for(var/turf/region_turf as anything in room_plan.turfs)
			region.turfs += region_turf
			extend_solved_region_bounds(region, region_turf)
		region.focus_turf = room.focus_turf
		state.geometry.solved_regions += region
	for(var/turf/route_turf as anything in candidate.route_turfs)
		if(!istype(route_turf))
			continue
		if(!floor_lookup[route_turf])
			floor_lookup[route_turf] = TRUE
			floor_turfs += route_turf
		state.add_corridor_turf(route_turf)
		if(!length(state.get_zone(route_turf)))
			state.add_zone(route_turf, "entry_buffer")
	for(var/datum/world_edit_building_v2_route_opening_plan/door_plan as anything in candidate.door_plans)
		var/turf/door_turf = door_plan.opening_turf
		if(!istype(door_turf))
			continue
		if(!floor_lookup[door_turf])
			floor_lookup[door_turf] = TRUE
			floor_turfs += door_turf
		state.append_unique_turf(state.geometry.door_turfs, door_turf)
		state.geometry.door_dirs[door_turf] = door_plan.dir
		state.add_primary_route(door_turf)
		var/door_zone = "entry_buffer"
		var/datum/world_edit_building_v2_room_plan/door_room = candidate.get_room_plan(door_plan.from_room)
		if(!istype(door_room))
			door_room = candidate.get_room_plan(door_plan.to_room)
		if(istype(door_room))
			door_zone = door_room.zone_id
		state.add_zone(door_turf, door_zone)
		if(door_plan.kind == "main_exit")
			state.geometry.front_door_turf = door_turf
			state.geometry.actual_entry_direction = door_plan.dir
		state.validation.door_reports += list(list(
			"turf" = door_turf,
			"dir" = door_plan.dir,
			"kind" = door_plan.kind,
			"zone_id" = door_zone,
			"from_room" = door_plan.from_room,
			"to_room" = door_plan.to_room,
		))
	for(var/datum/world_edit_building_v2_route_opening_plan/window_plan as anything in candidate.window_plans)
		if(istype(window_plan.opening_turf))
			state.append_unique_turf(state.geometry.window_turfs, window_plan.opening_turf)
	state.geometry.floor_turfs = floor_turfs
	state.geometry.floor_lookup = floor_lookup
	for(var/turf/footprint_turf as anything in state.geometry.footprint)
		if(!istype(footprint_turf) || floor_lookup[footprint_turf])
			continue
		state.geometry.wall_lookup[footprint_turf] = TRUE
		if(!state.geometry.boundary_lookup[footprint_turf])
			state.append_unique_turf(state.geometry.internal_wall_turfs, footprint_turf)
	state.geometry.center_turf = select_center_floor_turf(state.geometry.floor_turfs, (state.geometry.bounds["min_x"] + state.geometry.bounds["max_x"]) / 2, (state.geometry.bounds["min_y"] + state.geometry.bounds["max_y"]) / 2)
	state.geometry.semantic_hub_turf = length(candidate.route_turfs) ? candidate.route_turfs[max(1, round(length(candidate.route_turfs) / 2))] : state.geometry.center_turf
	state.validation.direction_honored_count = state.geometry.actual_entry_direction == state.geometry.requested_direction ? 1 : 0
	state.validation.direction_fallback_count = state.validation.direction_honored_count ? 0 : 1
	state.fixtures.usable_fixture_area = max(length(state.geometry.floor_turfs) - length(state.geometry.primary_route_turfs), 1)
	state.config["room_count"] = length(state.geometry.solved_rooms)
	state.config["corridor_turf_count"] = length(state.geometry.corridor_turfs)
	build_building_v2_room_reports(state)
	build_building_v2_layout_hashes(state)
	return TRUE

/datum/world_edit_generator/building_layout/proc/select_building_v2_room_focus(datum/world_edit_building_v2_room_plan/room_plan)
	if(!istype(room_plan) || !length(room_plan.turfs))
		return null
	var/turf/first_turf = room_plan.turfs[1]
	var/turf/center_turf = locate(round((room_plan.x1 + room_plan.x2) / 2), round((room_plan.y1 + room_plan.y2) / 2), first_turf?.z)
	if(room_plan.has_turf(center_turf))
		return center_turf
	return room_plan.turfs[1]

/datum/world_edit_generator/building_layout/proc/place_building_v2_scene_plans(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate)
	var/datum/world_edit_building_layout_state/state = context.state
	if(!istype(state) || !istype(candidate))
		return FALSE
	for(var/datum/world_edit_building_v2_room_plan/room_plan as anything in candidate.room_plans)
		if(!istype(room_plan.scene_plan))
			continue
		if(!place_building_v2_scene_plan(state, room_plan, room_plan.scene_plan))
			return FALSE
	return TRUE

/datum/world_edit_generator/building_layout/proc/place_building_v2_scene_plan(datum/world_edit_building_layout_state/state, datum/world_edit_building_v2_room_plan/room_plan, datum/world_edit_building_v2_scene_plan/scene_plan)
	var/module_id = "v2_scene_[scene_plan.scene_contract_id]"
	var/module_instance_id = "v2_scene_[room_plan.id]_[scene_plan.scene_contract_id]"
	var/list/occupied = list()
	for(var/list/member as anything in scene_plan.members)
		var/turf/member_turf = member["turf"]
		var/block_reason = occupied[member_turf] ? "scene_member_overlap" : get_building_v2_scene_member_block_reason(state, member_turf, FALSE)
		if(length(block_reason))
			state.add_stage_report("layout_v2_scene", "failed", block_reason, list(
				"room_id" = room_plan.id,
				"scene_id" = scene_plan.scene_contract_id,
				"slot" = member["slot"],
				"category" = member["category"],
				"turf" = member_turf,
				"coords" = istype(member_turf) ? "[member_turf.x],[member_turf.y],[member_turf.z]" : "",
			))
			state.remove_module_instance(module_instance_id)
			return FALSE
		occupied[member_turf] = TRUE
	var/placed_members = 0
	for(var/list/member as anything in scene_plan.members)
		var/turf/member_turf = member["turf"]
		var/slot = "[member["slot"]]"
		var/category = "[member["category"]]"
		var/datum/world_edit_building_place_rule/place_rule = resolve_building_place_rule(slot, category)
		var/list/place_context = build_building_fixture_place_context(state, member_turf, place_rule, member["dir"], place_rule.needs_wall, null, null)
		if(!islist(place_context))
			state.add_stage_report("layout_v2_scene", "failed", "place_context_failed", list(
				"room_id" = room_plan.id,
				"scene_id" = scene_plan.scene_contract_id,
				"slot" = slot,
				"category" = category,
				"turf" = member_turf,
				"needs_wall" = place_rule.needs_wall ? TRUE : FALSE,
				"dir" = member["dir"],
			))
			state.remove_module_instance(module_instance_id)
			return FALSE
		var/wall_mounted = place_context["wall_mounted"] ? TRUE : FALSE
		var/wall_dir = place_context["wall_dir"]
		if(!place_fixture_at(state, member_turf, slot, place_context["dir"] || member["dir"], category, member["major"], wall_mounted, place_rule, wall_dir, null, null, null, "layout_v2_scene", FALSE, module_id, module_instance_id, length(scene_plan.members), scene_plan.scene_kind, "v2_[room_plan.id]", slot in list("table", "chair"), TRUE))
			state.add_stage_report("layout_v2_scene", "failed", "fixture_emit_failed", list(
				"room_id" = room_plan.id,
				"scene_id" = scene_plan.scene_contract_id,
				"slot" = slot,
				"category" = category,
				"turf" = member_turf,
			))
			state.remove_module_instance(module_instance_id)
			return FALSE
		annotate_building_v2_scene_placement(state, member_turf, scene_plan, member)
		placed_members++
	if(placed_members != length(scene_plan.members))
		state.remove_module_instance(module_instance_id)
		return FALSE
	state.register_module_instance(module_id, module_instance_id, length(scene_plan.members), "v2_[room_plan.id]", scene_plan.scene_kind)
	register_building_v2_scene_plan(state, room_plan, scene_plan)
	return TRUE

/datum/world_edit_generator/building_layout/proc/add_building_v2_scene_placement_report(datum/world_edit_building_layout_state/state)
	if(!istype(state))
		return
	var/list/placements = list()
	for(var/list/object_placement as anything in state.fixtures.object_placements)
		if(!islist(object_placement) || !GLOB.world_edit_helpers.parse_bool(object_placement["layout_v2"]))
			continue
		var/turf/target_turf = object_placement["turf"]
		placements += list(list(
			"slot" = object_placement["slot"],
			"category" = object_placement["category"],
			"scene_id" = object_placement["scene_id"],
			"scene_kind" = object_placement["scene_kind"],
			"scene_slot" = object_placement["scene_slot"],
			"kind" = object_placement["kind"],
			"module_id" = object_placement["module_id"],
			"module_instance_id" = object_placement["module_instance_id"],
			"room_id" = object_placement["module_room_id"],
			"stored_zone" = object_placement["zone_id"],
			"actual_zone" = state.get_zone(target_turf),
			"turf" = target_turf,
			"coords" = istype(target_turf) ? "[target_turf.x],[target_turf.y],[target_turf.z]" : "",
		))
	state.add_stage_report("layout_v2_scene_summary", "ok", null, list(
		"placement_count" = length(placements),
		"placements" = placements,
	))

/datum/world_edit_generator/building_layout/proc/add_building_v2_validation_debug_report(datum/world_edit_building_layout_state/state)
	if(!istype(state))
		return
	var/list/reachable = get_building_validation_reachable_floor_lookup(state)
	var/list/unreachable_major = list()
	var/list/module_actual_counts = list()
	var/list/module_expected_counts = list()
	var/list/toilet_placements = list()
	var/list/wall_overlap_placements = list()
	var/list/orphan_internal_walls = list()
	for(var/list/object_placement as anything in state.fixtures.object_placements)
		if(!islist(object_placement))
			continue
		var/turf/target_turf = object_placement["turf"]
		if(istype(target_turf) && state.geometry.wall_lookup[target_turf])
			wall_overlap_placements += list(list(
				"slot" = object_placement["slot"],
				"category" = object_placement["category"],
				"layout_v2" = GLOB.world_edit_helpers.parse_bool(object_placement["layout_v2"]) ? TRUE : FALSE,
				"module_instance_id" = object_placement["module_instance_id"],
				"stored_zone" = object_placement["zone_id"],
				"actual_zone" = state.get_zone(target_turf),
				"coords" = "[target_turf.x],[target_turf.y],[target_turf.z]",
			))
		if("[object_placement["slot"]]" == "toilet")
			toilet_placements += list(list(
				"slot" = object_placement["slot"],
				"category" = object_placement["category"],
				"layout_v2" = GLOB.world_edit_helpers.parse_bool(object_placement["layout_v2"]) ? TRUE : FALSE,
				"module_instance_id" = object_placement["module_instance_id"],
				"stored_zone" = object_placement["zone_id"],
				"actual_zone" = state.get_zone(target_turf),
				"coords" = istype(target_turf) ? "[target_turf.x],[target_turf.y],[target_turf.z]" : "",
			))
		if(!GLOB.world_edit_helpers.parse_bool(object_placement["layout_v2"]))
			continue
		var/module_instance_id = "[object_placement["module_instance_id"] || ""]"
		if(length(module_instance_id))
			module_actual_counts[module_instance_id] = (module_actual_counts[module_instance_id] || 0) + 1
			module_expected_counts[module_instance_id] = max(round(text2num("[object_placement["module_expected_member_count"]]") || 0), round(text2num("[module_expected_counts[module_instance_id]]") || 0), 1)
		if(GLOB.world_edit_helpers.parse_bool(object_placement["major"]) && !reachable[target_turf])
			var/has_adjacent_reachable = FALSE
			for(var/check_dir in GLOB.cardinals)
				if(reachable[get_step(target_turf, check_dir)])
					has_adjacent_reachable = TRUE
					break
			if(!has_adjacent_reachable)
				unreachable_major += list(list(
					"slot" = object_placement["slot"],
					"category" = object_placement["category"],
					"scene_id" = object_placement["scene_id"],
					"room_id" = object_placement["module_room_id"],
					"zone" = state.get_zone(target_turf),
					"coords" = istype(target_turf) ? "[target_turf.x],[target_turf.y],[target_turf.z]" : "",
				))
	for(var/turf/internal_wall_turf as anything in state.geometry.internal_wall_turfs)
		if(!istype(internal_wall_turf))
			continue
		var/adjacent_floor = FALSE
		for(var/check_dir in GLOB.cardinals)
			var/turf/nearby_turf = get_step(internal_wall_turf, check_dir)
			if(state.geometry.floor_lookup[nearby_turf] || state.geometry.door_dirs[nearby_turf])
				adjacent_floor = TRUE
				break
		if(!adjacent_floor)
			orphan_internal_walls += list("[internal_wall_turf.x],[internal_wall_turf.y],[internal_wall_turf.z]")
			if(length(orphan_internal_walls) >= 16)
				break
	var/list/module_reports = list()
	for(var/module_instance_id as anything in module_expected_counts)
		var/actual_count = round(text2num("[module_actual_counts[module_instance_id]]") || 0)
		var/expected_count = round(text2num("[module_expected_counts[module_instance_id]]") || 0)
		if(actual_count != expected_count)
			module_reports += list(list(
				"module_instance_id" = module_instance_id,
				"actual" = actual_count,
				"expected" = expected_count,
			))
	state.add_stage_report("layout_v2_validation_debug", "ok", null, list(
		"unreachable_major" = unreachable_major,
		"fragmented_modules" = module_reports,
		"toilet_placements" = toilet_placements,
		"wall_overlap_placements" = wall_overlap_placements,
		"orphan_internal_walls" = orphan_internal_walls,
	))

/datum/world_edit_generator/building_layout/proc/get_building_v2_scene_member_block_reason(datum/world_edit_building_layout_state/state, turf/member_turf, allow_reserved = FALSE)
	if(!istype(member_turf))
		return "invalid_turf"
	if(!state.geometry.floor_lookup[member_turf])
		return "not_floor"
	if(state.geometry.wall_lookup[member_turf])
		return "wall"
	if(state.geometry.door_dirs[member_turf])
		return "door"
	if(state.fixtures.fixture_lookup[member_turf])
		return "fixture"
	if(state.fixtures.semantic_slot_clearance_by_turf[member_turf])
		return "semantic_clearance"
	if(!allow_reserved && state.geometry.reserved_lookup[member_turf])
		return "reserved_route"
	if(state.has_anchor("door_cone", member_turf))
		return "door_cone"
	return ""

/datum/world_edit_generator/building_layout/proc/annotate_building_v2_scene_placement(datum/world_edit_building_layout_state/state, turf/member_turf, datum/world_edit_building_v2_scene_plan/scene_plan, list/member)
	for(var/index = length(state.fixtures.object_placements), index >= 1, index--)
		var/list/placement = state.fixtures.object_placements[index]
		if(!islist(placement) || placement["turf"] != member_turf || "[placement["module_instance_id"]]" != "v2_scene_[scene_plan.room_id]_[scene_plan.scene_contract_id]")
			continue
		placement["layout_v2"] = TRUE
		placement["scene_id"] = scene_plan.scene_contract_id
		placement["scene_kind"] = scene_plan.scene_kind
		placement["scene_slot"] = member["scene_slot"]
		placement["scene_primary"] = scene_plan.primary ? TRUE : FALSE
		return

/datum/world_edit_generator/building_layout/proc/register_building_v2_scene_plan(datum/world_edit_building_layout_state/state, datum/world_edit_building_v2_room_plan/room_plan, datum/world_edit_building_v2_scene_plan/scene_plan)
	var/room_key = "v2_[room_plan.id]"
	state.fixtures.scene_plans += list(list(
		"id" = scene_plan.id,
		"room_id" = room_key,
		"room_contract_id" = room_plan.contract_id,
		"room_role" = room_plan.role,
		"scene_id" = scene_plan.scene_contract_id,
		"scene_kind" = scene_plan.scene_kind,
		"primary" = scene_plan.primary ? TRUE : FALSE,
		"member_count" = length(scene_plan.members),
		"scene_slot_counts" = scene_plan.scene_slot_counts.Copy(),
	))
	state.fixtures.scene_counts_by_room[room_key] = (state.fixtures.scene_counts_by_room[room_key] || 0) + 1
	if(scene_plan.primary)
		state.fixtures.scene_primary_counts_by_room[room_key] = (state.fixtures.scene_primary_counts_by_room[room_key] || 0) + 1
	state.fixtures.scene_kind_by_room[room_key] = scene_plan.scene_kind
	state.fixtures.scene_slot_counts_by_room[room_key] = scene_plan.scene_slot_counts.Copy()

/datum/world_edit_generator/building_layout/proc/build_building_v2_room_reports(datum/world_edit_building_layout_state/state)
	state.validation.room_reports.Cut()
	for(var/datum/world_edit_building_room/room as anything in state.geometry.solved_rooms)
		state.validation.room_reports += list(list(
			"id" = room.id,
			"zone_id" = room.zone_id,
			"role" = room.role,
			"area" = room.area,
			"useful_area" = length(room.turfs),
			"bounds" = list("x1" = room.x1, "y1" = room.y1, "x2" = room.x2, "y2" = room.y2),
			"focus" = room.focus_turf,
			"layout_v2" = TRUE,
		))
	state.validation.zone_reports.Cut()
	for(var/zone_id as anything in state.geometry.zone_turfs)
		var/list/zone_turfs = state.geometry.zone_turfs[zone_id]
		state.validation.zone_reports += list(list(
			"id" = "[zone_id]",
			"area" = islist(zone_turfs) ? length(zone_turfs) : 0,
			"focus" = state.geometry.zone_focus_turfs[zone_id],
		))
	state.validation.corridor_report = list(
		"reserved_walk_count" = length(state.geometry.primary_route_turfs),
		"corridor_turf_count" = length(state.geometry.corridor_turfs),
		"door_transition_count" = length(state.validation.door_reports),
		"front_door_turf" = state.geometry.front_door_turf,
		"layout_v2" = TRUE,
	)

/datum/world_edit_generator/building_layout/proc/build_building_v2_layout_hashes(datum/world_edit_building_layout_state/state)
	state.geometry.room_graph_hash = build_building_room_ownership_hash(state)
	state.geometry.route_hash = build_building_turf_list_hash(state.geometry.primary_route_turfs)
	state.geometry.wall_hash = build_building_turf_lookup_hash(state.geometry.wall_lookup)
	var/object_placement_hash = build_building_object_placement_hash(state.fixtures.object_placements)
	state.geometry.layout_hash = build_building_hash_from_strings(list(
		"v2=1",
		"footprint=[state.geometry.footprint_hash]",
		"rooms=[state.geometry.room_graph_hash]",
		"route=[state.geometry.route_hash]",
		"walls=[state.geometry.wall_hash]",
		"objects=[object_placement_hash]",
	))
	state.validation.determinism_check_hash = state.geometry.layout_hash

/datum/world_edit_generator/building_layout/proc/validate_building_layout_v2_scenes(datum/world_edit_building_layout_state/state)
	if(!building_layout_v2_enabled(state))
		return
	var/datum/world_edit_building_v2_context/context = state.layout_v2_context
	var/datum/world_edit_building_v2_program_contract/program = context?.program_contract
	if(!istype(program))
		program = build_building_v2_program_contract(state.archetype?.id)
	validate_building_layout_v2_openings(state, context, context?.selected_candidate)
	var/list/scene_by_room = state.fixtures.scene_kind_by_room
	var/list/primary_counts = state.fixtures.scene_primary_counts_by_room
	var/list/slot_counts_by_room = state.fixtures.scene_slot_counts_by_room
	var/list/scene_member_counts_by_room = list()
	for(var/list/object_placement as anything in state.fixtures.object_placements)
		if(!islist(object_placement) || !GLOB.world_edit_helpers.parse_bool(object_placement["layout_v2"]))
			continue
		var/member_room_id = "[object_placement["module_room_id"] || ""]"
		if(length(member_room_id))
			scene_member_counts_by_room[member_room_id] = (scene_member_counts_by_room[member_room_id] || 0) + 1
	var/common_focal_count = 0
	var/common_small_social_count = 0
	var/public_focal_count = 0
	for(var/datum/world_edit_building_room/room as anything in state.geometry.solved_rooms)
		if(!istype(room))
			continue
		var/room_contract_id = building_v2_room_contract_id_from_room(room)
		var/datum/world_edit_building_v2_room_contract/room_contract = program?.get_room_contract(room_contract_id)
		var/scene_kind = "[scene_by_room[room.id] || ""]"
		var/primary_count = round(text2num("[primary_counts[room.id]]") || 0)
		var/list/slot_counts = slot_counts_by_room[room.id]
		if(primary_count > 1)
			state.validation.room_scene_duplicate_count += primary_count - 1
		if(istype(room_contract) && primary_count > room_contract.max_scene_count)
			state.validation.scene_slot_overflow_count += primary_count - room_contract.max_scene_count
		if(istype(room_contract) && room_contract.required && length(room_contract.required_scene_kinds) && !length(scene_kind))
			state.validation.scene_required_missing_count++
			state.validation.room_primary_scene_missing_count++
		if(room.area >= 12 && !(room.role in list("route", "entry")) && !length(scene_kind))
			state.validation.room_identity_missing_count++
			state.validation.large_empty_unassigned_floor_count++
		if(room_contract_id == "sleeping" && scene_kind != "bedroom")
			state.validation.private_room_without_bed_scene_count++
		if(room_contract_id == "sanitation" && scene_kind != "sanitation")
			state.validation.sanitation_without_sanitation_scene_count++
		if(room_contract_id == "storage" && scene_kind != "storage")
			state.validation.storage_without_storage_scene_count++
		if(istype(room_contract) && room.area > room_contract.max_area)
			state.validation.oversized_role_room_count++
		var/room_width = isnull(room.x1) || isnull(room.x2) ? 0 : max(room.x2 - room.x1 + 1, 0)
		var/room_height = isnull(room.y1) || isnull(room.y2) ? 0 : max(room.y2 - room.y1 + 1, 0)
		var/room_min_dim = min(room_width, room_height)
		var/room_max_dim = max(room_width, room_height)
		if(room.area >= 12 && (room_min_dim <= 2 || room_max_dim > room_min_dim * 4))
			state.validation.thin_room_strip_count++
		var/scene_member_count = round(text2num("[scene_member_counts_by_room[room.id]]") || 0)
		var/min_scene_member_count = get_building_v2_min_scene_members_for_room(room_contract_id, room.role, room.area)
		if(min_scene_member_count > 0 && scene_member_count < min_scene_member_count)
			state.validation.layout_v2_underfurnished_room_count += min_scene_member_count - scene_member_count
		if(room.area >= 64 && scene_member_count <= 2 && !(room_contract_id in list("sanitation", "storage", "utility")))
			state.validation.large_sparse_room_count++
		if(room_contract_id in list("entry_common", "dining"))
			var/dining_focal = islist(slot_counts) ? round(text2num("[slot_counts["dining_focal"]]") || 0) : 0
			var/lounge_focal = islist(slot_counts) ? round(text2num("[slot_counts["lounge_focal"]]") || 0) : 0
			common_focal_count += dining_focal > 0 ? 1 : 0
			common_small_social_count += lounge_focal > 0 ? 1 : 0
			public_focal_count += dining_focal + lounge_focal
			if(dining_focal > 1)
				state.validation.scene_slot_overflow_count += dining_focal - 1
	for(var/list/placement as anything in state.fixtures.object_placements)
		if(!islist(placement) || !GLOB.world_edit_helpers.parse_bool(placement["layout_v2"]))
			continue
		var/turf/target_turf = placement["turf"]
		if(istype(target_turf) && building_object_path_is_dense(placement["obj_path"]) && (state.geometry.reserved_lookup[target_turf] || state.has_anchor("door_cone", target_turf)))
			state.validation.scene_blocks_route_count++
		validate_building_v2_scene_placement_role(state, placement)
	if(common_focal_count > 1)
		state.validation.common_scene_fragmentation_count += common_focal_count - 1
	if(public_focal_count > 1)
		state.validation.common_scene_fragmentation_count += public_focal_count - 1
	if(common_small_social_count > 1)
		state.validation.excessive_small_social_groups_count += common_small_social_count - 1
	var/interior_count = length(state.geometry.interior)
	if(interior_count >= 180)
		var/orphan_internal_wall_count = 0
		for(var/turf/internal_wall_turf as anything in state.geometry.internal_wall_turfs)
			if(!istype(internal_wall_turf))
				continue
			var/adjacent_floor = FALSE
			for(var/check_dir in GLOB.cardinals)
				var/turf/nearby_turf = get_step(internal_wall_turf, check_dir)
				if(state.geometry.floor_lookup[nearby_turf] || state.geometry.door_dirs[nearby_turf])
					adjacent_floor = TRUE
					break
			if(!adjacent_floor)
				orphan_internal_wall_count++
		var/orphan_internal_wall_allowance = max(10, length(state.geometry.solved_rooms) * 3)
		if(orphan_internal_wall_count > orphan_internal_wall_allowance)
			state.validation.unclaimed_interior_wall_count += orphan_internal_wall_count - orphan_internal_wall_allowance
	var/allowed_route_count = max(28, length(state.geometry.solved_rooms) * 4)
	if(length(state.geometry.primary_route_turfs) > allowed_route_count)
		state.validation.corridor_ribbon_count += length(state.geometry.primary_route_turfs) - allowed_route_count

/datum/world_edit_generator/building_layout/proc/get_building_v2_min_scene_members_for_room(room_contract_id, room_role, room_area)
	var/resolved_room = "[room_contract_id]"
	var/resolved_role = "[room_role]"
	var/resolved_area = round(text2num("[room_area]") || 0)
	if(resolved_room == "entry_common" || resolved_role == "entry_common")
		if(resolved_area >= 48)
			return 4
		if(resolved_area >= 36)
			return 3
		return 1
	if(resolved_room == "dining" || resolved_role == "dining")
		if(resolved_area >= 36)
			return 5
		return 2
	if(resolved_room == "sleeping" || resolved_role == "sleeping")
		if(resolved_area >= 28)
			return 3
		return 1
	if(resolved_room == "utility" || resolved_role == "utility")
		if(resolved_area >= 32)
			return 4
		if(resolved_area >= 28)
			return 3
		return 0
	return 0

/datum/world_edit_generator/building_layout/proc/validate_building_v2_scene_placement_role(datum/world_edit_building_layout_state/state, list/placement)
	if(!istype(state) || !islist(placement))
		return
	var/slot = "[placement["requested_slot"] || placement["slot"] || ""]"
	var/scene_kind = "[placement["scene_kind"] || ""]"
	var/scene_slot = "[placement["scene_slot"] || ""]"
	var/room_id = "[placement["module_room_id"] || ""]"
	if(slot in list("table", "chair"))
		if(!(scene_kind in list("dining", "living_common")))
			if(slot == "table")
				state.validation.loose_table_count++
			else
				state.validation.loose_chair_count++
	if(slot == "bed" && (scene_kind != "bedroom" || !findtext(room_id, "sleeping")))
		state.validation.bed_outside_sleeping_count++
	if(slot in list("toilet", "sink") && scene_kind != "sanitation")
		state.validation.toilet_outside_sanitation_count++
		if(scene_slot in list("storage_run", "storage_corner") && scene_kind != "storage")
			state.validation.storage_without_storage_scene_count++

/datum/world_edit_generator/building_layout/proc/validate_building_layout_v2_openings(datum/world_edit_building_layout_state/state, datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate)
	if(!istype(state) || !istype(context) || !istype(candidate))
		return
	var/list/room_door_counts = list()
	var/main_exit_ok = FALSE
	for(var/datum/world_edit_building_v2_route_opening_plan/door_plan as anything in candidate.door_plans)
		if(!istype(door_plan))
			continue
		var/valid = building_v2_door_plan_has_valid_shared_wall(context, candidate, door_plan)
		if(!valid)
			state.validation.layout_v2_door_not_shared_wall_count++
			state.add_error("Layout v2 door '[door_plan.id]' is not a valid shared-wall opening.")
			continue
		if(door_plan.kind == "main_exit")
			main_exit_ok = TRUE
			continue
		if(length(door_plan.from_room) && door_plan.from_room != "route")
			room_door_counts[door_plan.from_room] = (room_door_counts[door_plan.from_room] || 0) + 1
		if(length(door_plan.to_room) && door_plan.to_room != "route")
			room_door_counts[door_plan.to_room] = (room_door_counts[door_plan.to_room] || 0) + 1
	if(!main_exit_ok)
		state.validation.layout_v2_required_connection_missing_count++
		state.add_error("Layout v2 has no valid main exit opening.")
	for(var/datum/world_edit_building_v2_room_plan/room_plan as anything in candidate.room_plans)
		if(!istype(room_plan))
			continue
		var/datum/world_edit_building_v2_room_contract/room_contract = context.program_contract.get_room_contract(room_plan.contract_id)
		if(!istype(room_contract) || !room_contract.must_touch_route)
			continue
		if(room_door_counts[room_plan.id])
			continue
		state.validation.layout_v2_room_without_door_count++
		if(room_contract.required)
			state.validation.layout_v2_required_connection_missing_count++
		state.add_error("Layout v2 room '[room_plan.id]' has no valid route opening.")
	for(var/datum/world_edit_building_v2_route_opening_plan/window_plan as anything in candidate.window_plans)
		if(!istype(window_plan))
			continue
		var/datum/world_edit_building_v2_room_plan/window_room = candidate.get_room_plan(window_plan.from_room)
		var/datum/world_edit_building_v2_room_contract/window_contract = context.program_contract.get_room_contract(window_room?.contract_id)
		if(istype(window_contract) && window_contract.exterior_window_policy == "forbidden")
			state.validation.layout_v2_forbidden_room_window_count++
			state.add_error("Layout v2 room '[window_room.id]' has a forbidden exterior window.")
			continue
		if(!building_v2_window_plan_obeys_policy(context, candidate, window_plan))
			state.validation.invalid_window_count++
			state.add_error("Layout v2 window '[window_plan.id]' violates exterior/window policy.")

/datum/world_edit_generator/building_layout/proc/building_v2_room_contract_id_from_room(datum/world_edit_building_room/room)
	if(!istype(room))
		return ""
	if(findtext(room.id, "entry_common"))
		return "entry_common"
	if(findtext(room.id, "sleeping"))
		return "sleeping"
	if(findtext(room.id, "sanitation"))
		return "sanitation"
	if(findtext(room.id, "storage") && !findtext(room.id, "utility"))
		return "storage"
	if(findtext(room.id, "dining"))
		return "dining"
	if(findtext(room.id, "utility"))
		return "utility"
	return ""
