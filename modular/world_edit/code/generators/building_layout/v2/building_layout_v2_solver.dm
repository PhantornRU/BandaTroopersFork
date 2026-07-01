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
	var/datum/world_edit_building_v2_layout_candidate/best = select_best_building_layout_v2_candidate(context, scene_solved_candidates)
	if(!istype(best))
		state.add_error("Building layout v2 could not select a valid layout candidate.")
		state.add_stage_report("layout_v2", "failed", format_building_messages(state.validation.errors), list("candidate_count" = length(scene_solved_candidates), "topology_candidate_count" = length(candidates)))
		return FALSE
	if(!emit_building_v2_candidate_to_state(context, best))
		state.add_error("Building layout v2 could not emit the selected candidate.")
		state.add_stage_report("layout_v2", "failed", "state emission failed", list("pattern_id" = best.pattern_id))
		return FALSE
	refresh_building_semantic_anchors(state)
	reserve_building_immediate_door_cones(state)
	if(!place_building_v2_scene_plans(context, best))
		state.add_error("Building layout v2 could not place solved room scenes.")
		state.add_stage_report("layout_v2", "failed", "scene placement failed", list("pattern_id" = best.pattern_id))
		return FALSE
	place_building_infrastructure(state)
	state.rebuild_fixture_indexes()
	add_building_v2_scene_placement_report(state)
	validate_building_layout_state(state)
	if(state.has_errors())
		add_building_v2_validation_debug_report(state)
	state.fixtures.pattern_credit_hash = build_building_assoc_hash(state.fixtures.semantic_requirement_counts)
	build_building_v2_layout_hashes(state)
	state.config["layout_v2_scene_count"] = length(best.room_plans)
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
			if(!validate_building_v2_layout_topology(context, candidate))
				if(istype(context?.state))
					context.state.add_stage_report("layout_v2_candidate_topology_reject", "failed", format_building_messages(candidate.errors), list("candidate_id" = candidate.id, "pattern_id" = candidate.pattern_id, "errors" = candidate.errors.Copy()))
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
	for(var/datum/world_edit_building_v2_route_opening_plan/door_plan as anything in candidate.door_plans)
		if(!istype(door_plan) || !istype(door_plan.opening_turf))
			candidate.errors += "door.missing"
			continue
		if(!context.state.geometry.footprint_lookup[door_plan.opening_turf])
			candidate.errors += "door.out_of_bounds:[door_plan.id]"
			continue
		candidate_floor_lookup[door_plan.opening_turf] = TRUE
	var/interior_count = length(context.state.geometry.interior)
	if(interior_count >= 180)
		var/min_floor_count = round(interior_count * 0.66)
		if(length(candidate_floor_lookup) < min_floor_count)
			candidate.errors += "coverage.too_sparse:[length(candidate_floor_lookup)]/[interior_count]"
	var/list/connected_rooms = list()
	for(var/datum/world_edit_building_v2_route_opening_plan/connected_door as anything in candidate.door_plans)
		if(!istype(connected_door))
			continue
		if(length(connected_door.from_room) && connected_door.from_room != "route")
			connected_rooms[connected_door.from_room] = TRUE
		if(length(connected_door.to_room) && connected_door.to_room != "route")
			connected_rooms[connected_door.to_room] = TRUE
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
	score += length(candidate.route_turfs) * 3
	score += length(candidate.door_plans) * 25
	return score

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

/datum/world_edit_generator/building_layout/proc/solve_building_v2_scenes(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate)
	if(!istype(context) || !istype(candidate))
		return FALSE
	for(var/datum/world_edit_building_v2_room_plan/room_plan as anything in candidate.room_plans)
		var/list/scene_candidates = get_building_v2_scene_candidates_for_room(context, room_plan, candidate)
		var/datum/world_edit_building_v2_scene_plan/best_scene = select_best_building_v2_scene_for_room(context, candidate, room_plan, scene_candidates)
		var/datum/world_edit_building_v2_room_contract/room_contract = context.program_contract.get_room_contract(room_plan.contract_id)
		if(!istype(best_scene))
			if(istype(room_contract) && (room_contract.required || room_plan.area() >= 12))
				candidate.errors += "scene.required_missing:[room_plan.id]"
			continue
		room_plan.scene_plan = best_scene
		room_plan.scene_kind = best_scene.scene_kind
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
		if((scene_contract.id == "common_dining_4" || scene_contract.id == "common_dining_2") && room_plan.contract_id == "entry_common" && istype(dining_room_plan))
			continue
		if(room_plan.role == "utility" && scene_contract.id != "storage_crate_corner")
			continue
		scenes += scene_contract
	return scenes

/datum/world_edit_generator/building_layout/proc/select_best_building_v2_scene_for_room(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, datum/world_edit_building_v2_room_plan/room_plan, list/scenes)
	var/datum/world_edit_building_v2_scene_plan/best = null
	var/best_score = -999999999
	for(var/datum/world_edit_building_v2_scene_contract/scene_contract as anything in scenes)
		var/datum/world_edit_building_v2_scene_plan/scene_plan = build_building_v2_scene_plan(context, candidate, room_plan, scene_contract)
		if(!istype(scene_plan) || !length(scene_plan.members))
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
		if(room_plan.area() >= 48)
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
		var/list/second_crate = select_building_v2_scene_anchor(context, candidate, room_plan, "crate", category, "storage", occupied_lookup, FALSE, TRUE, 1)
		if(islist(second_crate))
			add_building_v2_scene_member_from_anchor(scene_plan, "crate", category, second_crate, scene_slot, FALSE, FALSE)
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
		if(room.area >= 64 && scene_member_count <= 2 && !(room_contract_id in list("sanitation", "storage", "utility")))
			state.validation.large_sparse_room_count++
		if(room_contract_id in list("entry_common", "dining"))
			var/dining_focal = islist(slot_counts) ? round(text2num("[slot_counts["dining_focal"]]") || 0) : 0
			var/lounge_focal = islist(slot_counts) ? round(text2num("[slot_counts["lounge_focal"]]") || 0) : 0
			common_focal_count += dining_focal > 0 ? 1 : 0
			common_small_social_count += lounge_focal > 0 ? 1 : 0
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
		if(orphan_internal_wall_count > 10)
			state.validation.unclaimed_interior_wall_count += orphan_internal_wall_count - 10
	var/allowed_route_count = max(32, length(state.geometry.solved_rooms) * 6)
	if(length(state.geometry.primary_route_turfs) > allowed_route_count)
		state.validation.corridor_ribbon_count += length(state.geometry.primary_route_turfs) - allowed_route_count

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
