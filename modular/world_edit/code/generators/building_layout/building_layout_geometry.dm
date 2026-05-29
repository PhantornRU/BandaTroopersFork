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
	state.root_seed = round(text2num("[state.config["root_seed"] || request.effective_seed]") || 0)
	state.stage_seed_footprint = build_stage_seed(state.root_seed, "footprint")
	state.stage_seed_rooms = round(text2num("[state.config["stage_seed_geometry"]]") || build_stage_seed(state.root_seed, "geometry"))
	state.stage_seed_corridor = build_stage_seed(state.stage_seed_rooms, "corridor")
	state.stage_seed_patterns = round(text2num("[state.config["stage_seed_fixtures"]]") || build_stage_seed(state.root_seed, "fixtures"))
	state.stage_seed_details = round(text2num("[state.config["stage_seed_microvariation"]]") || build_stage_seed(state.root_seed, "microvariation"))
	state.set_support_status(state.config["current_request_support_status"] || WORLD_EDIT_BUILDING_SUPPORT_SUPPORTED, state.config["user_facing_failure_reason"] || "")
	state.add_stage_report("state_init", "ok", null, list("root_seed" = state.root_seed))
	state.geometry.footprint = validated["footprint"]
	state.geometry.boundary = validated["boundary"]
	state.geometry.interior = validated["interior"]
	state.geometry.footprint_lookup = validated["footprint_lookup"]
	state.geometry.bounds = validated["bounds"]
	state.validation.blocked_turf_conflict_count = round(text2num("[validated["blocked_turf_conflict_count"]]") || 0)
	state.validation.replace_blocked_turf_count = round(text2num("[validated["replace_blocked_turf_count"]]") || 0)
	state.geometry.boundary_lookup = GLOB.world_edit_placement_shapes.world_edit_build_turf_lookup(state.geometry.boundary)
	state.placement_dir = text2num("[placement_context["direction"]]")
	if(!(state.placement_dir in GLOB.cardinals))
		state.placement_dir = manager?.get_effective_placement_dir() || NORTH
	state.geometry.requested_direction = state.placement_dir
	state.geometry.actual_entry_direction = state.placement_dir

	if(length(state.geometry.footprint) > WORLD_EDIT_BUILDING_MAX_FOOTPRINT_TURFS)
		state.add_error("Building footprint exceeds cap ([WORLD_EDIT_BUILDING_MAX_FOOTPRINT_TURFS]).")
		state.add_stage_report("footprint", "failed", "footprint cap exceeded")
		return state

	state.request.config["validated_footprint_count"] = length(state.geometry.footprint)
	state.request.config["validated_interior_count"] = length(state.geometry.interior)
	state.request.config["validated_boundary_count"] = length(state.geometry.boundary)
	state.geometry.footprint_hash = build_building_turf_list_hash(state.geometry.footprint)
	state.add_stage_report("footprint", "ok", null, list(
		"footprint_count" = length(state.geometry.footprint),
		"footprint_hash" = state.geometry.footprint_hash,
	))
	var/list/support_report = state.config["support_status_report"]
	if(!length("[state.config["size_degrade_level"]]"))
		state.config["size_degrade_level"] = islist(support_report) ? (support_report["degrade_level"] || WORLD_EDIT_BUILDING_DEGRADE_NONE) : WORLD_EDIT_BUILDING_DEGRADE_NONE
	if(isnull(state.config["program_shedding"]))
		state.config["program_shedding"] = islist(support_report) ? (support_report["program_shedding"] ? TRUE : FALSE) : FALSE
	state.semantic_plan = state.archetype.build_semantic_plan(state.request)
	if(!istype(state.semantic_plan))
		state.add_error("Unable to build semantic plan for [state.archetype.id].")
		state.add_stage_report("semantic_plan", "failed", "semantic plan unavailable")
		return state
	for(var/datum/world_edit_building_zone_spec/zone_spec as anything in state.semantic_plan.zone_specs)
		if(!istype(zone_spec) || !zone_spec.required)
			continue
		state.validation.mandatory_zone_count++
		if(zone_spec.divider_mode == "room")
			state.validation.mandatory_room_count++
	state.add_stage_report("semantic_plan", "ok", null, list(
		"program_id" = state.archetype.id,
		"mandatory_room_count" = state.validation.mandatory_room_count,
		"mandatory_zone_count" = state.validation.mandatory_zone_count,
	))

	return state

/datum/world_edit_generator/building_layout/proc/build_building_doors(datum/world_edit_building_layout_state/state)
	state.validation.door_reports.Cut()
	var/center_x = (state.geometry.bounds["min_x"] + state.geometry.bounds["max_x"]) / 2
	var/center_y = (state.geometry.bounds["min_y"] + state.geometry.bounds["max_y"]) / 2
	var/list/door_policy = islist(state.semantic_plan?.door_policy) ? state.semantic_plan.door_policy : list()
	if(("front" in door_policy) && !GLOB.world_edit_helpers.parse_bool(door_policy["front"]))
		state.add_error("Door policy for [state.archetype.id] does not allow a front entry.")
		return
	var/turf/front_door_turf = select_boundary_turf_for_dir(state.geometry.boundary, center_x, center_y, state.placement_dir, null, state.geometry.footprint_lookup)
	if(!istype(front_door_turf))
		state.add_error("Unable to select a building entry door turf.")
		return
	state.geometry.front_door_turf = front_door_turf
	state.append_unique_turf(state.geometry.door_turfs, front_door_turf)
	state.geometry.door_dirs[front_door_turf] = get_outward_dir(front_door_turf, state.geometry.footprint_lookup, center_x, center_y, state.placement_dir)
	state.validation.door_reports += list(list(
		"turf" = front_door_turf,
		"dir" = state.geometry.door_dirs[front_door_turf],
		"kind" = "main_exit",
		"requested_direction" = state.placement_dir,
	))

	var/max_exterior_doors = max(round(text2num("[door_policy["max_exterior_doors"]]") || 2), 1)
	var/allow_back_exit = isnull(door_policy["allow_back_exit"]) ? TRUE : GLOB.world_edit_helpers.parse_bool(door_policy["allow_back_exit"])
	if(state.config["back_exit"] && allow_back_exit && max_exterior_doors >= 2)
		var/list/front_lookup = list()
		front_lookup[front_door_turf] = TRUE
		var/turf/back_door_turf = select_boundary_turf_for_dir(state.geometry.boundary, center_x, center_y, turn(state.placement_dir, 180), front_lookup, state.geometry.footprint_lookup)
		if(istype(back_door_turf))
			state.append_unique_turf(state.geometry.door_turfs, back_door_turf)
			state.geometry.door_dirs[back_door_turf] = get_outward_dir(back_door_turf, state.geometry.footprint_lookup, center_x, center_y, turn(state.placement_dir, 180))
		state.validation.door_reports += list(list(
			"turf" = back_door_turf,
			"dir" = state.geometry.door_dirs[back_door_turf],
			"kind" = "service_exit",
			"requested_direction" = turn(state.placement_dir, 180),
		))

/datum/world_edit_generator/building_layout/proc/build_building_micro_layout(datum/world_edit_building_layout_state/state)
	if(!istype(state) || !istype(state.semantic_plan))
		return FALSE
	state.clear_room_layout()
	prepare_building_local_metrics(state)
	var/primary_zone_id = state.semantic_plan.primary_zone_id
	if(!length("[primary_zone_id]"))
		primary_zone_id = state.semantic_plan.hub_zone_id
	if(!length("[primary_zone_id]"))
		primary_zone_id = state.semantic_plan.entry_zone_id
	if(!length("[primary_zone_id]"))
		primary_zone_id = "main"
	var/list/micro_turfs = list()
	for(var/turf/interior_turf as anything in state.geometry.interior)
		if(istype(interior_turf))
			micro_turfs += interior_turf
	if(!length(micro_turfs) && istype(state.geometry.center_turf))
		micro_turfs += state.geometry.center_turf
	if(!length(micro_turfs))
		state.add_error("Micro building layout has no usable tile.")
		return FALSE
	var/datum/world_edit_building_room/room = new("room_micro_main", primary_zone_id, "hub")
	for(var/turf/micro_turf as anything in micro_turfs)
		state.add_zone(micro_turf, primary_zone_id)
		state.add_corridor_turf(micro_turf)
		room.add_turf(micro_turf)
	room.focus_turf = micro_turfs[1]
	state.add_solved_room(room)
	state.set_zone_focus(primary_zone_id, room.focus_turf)
	state.geometry.semantic_hub_turf = room.focus_turf
	state.geometry.center_turf = room.focus_turf
	state.config["micro_layout"] = TRUE
	state.config["room_first_layout"] = TRUE
	state.config["room_count"] = 1
	state.config["corridor_turf_count"] = length(state.geometry.corridor_turfs)
	state.validation.room_reports.Cut()
	state.validation.room_reports += list(list(
		"id" = room.id,
		"zone_id" = room.zone_id,
		"role" = room.role,
		"area" = length(room.turfs),
		"useful_area" = length(room.turfs),
		"tiny" = TRUE,
	))
	state.validation.zone_reports.Cut()
	state.validation.zone_reports += list(list(
		"id" = primary_zone_id,
		"area" = length(room.turfs),
		"focus" = room.focus_turf,
	))
	state.validation.corridor_report = list(
		"reserved_walk_count" = length(state.geometry.primary_route_turfs),
		"corridor_turf_count" = length(state.geometry.corridor_turfs),
		"front_door_turf" = state.geometry.front_door_turf,
		"micro_layout" = TRUE,
	)
	return TRUE

/datum/world_edit_generator/building_layout/proc/build_building_room_first_layout(datum/world_edit_building_layout_state/state)
	if(!istype(state) || !istype(state.semantic_plan))
		return FALSE
	if(length(state.geometry.interior) < 3 || "[state.config["size_degrade_level"]]" == WORLD_EDIT_BUILDING_DEGRADE_MICRO)
		return build_building_micro_layout(state)
	state.clear_room_layout()
	prepare_building_local_metrics(state)
	var/corridor_zone_id = select_room_first_corridor_zone_id(state)
	var/entry_zone_id = length("[state.semantic_plan.entry_zone_id]") ? state.semantic_plan.entry_zone_id : "entry_buffer"
	var/list/free_lookup = GLOB.world_edit_placement_shapes.world_edit_build_turf_lookup(state.geometry.interior)
	if(istype(state.geometry.front_door_turf))
		free_lookup[state.geometry.front_door_turf] = TRUE
	if(!length(free_lookup))
		state.add_error("Building room solver found no usable BSP room area.")
		return FALSE
	var/list/required_room_specs = get_room_first_zone_specs(state, corridor_zone_id, entry_zone_id)
	var/room_candidate_target = max(length(required_room_specs) + 2, 5)
	var/list/room_candidates = build_room_first_bsp_candidates(state, free_lookup, room_candidate_target, max(length(required_room_specs), 1))
	if(!length(room_candidates))
		state.add_error("Building room solver could not derive BSP rooms from the footprint.")
		return FALSE
	var/list/adjacency_edges = build_room_first_candidate_adjacency_edges(state, room_candidates)
	annotate_room_first_candidate_adjacency(state, room_candidates, adjacency_edges)
	annotate_room_first_route_access(state, room_candidates)
	assign_room_first_zone_rooms(state, room_candidates, required_room_specs, corridor_zone_id, entry_zone_id)
	assign_room_first_unclaimed_floor_to_hub(state, free_lookup, room_candidates, corridor_zone_id)
	rebuild_room_first_corridor_from_hub(state, corridor_zone_id, entry_zone_id)
	build_room_first_internal_walls(state)
	ensure_room_first_required_room_access(state)
	refresh_building_zone_foci(state)
	state.geometry.semantic_hub_turf = state.get_zone_focus(state.semantic_plan.hub_zone_id) || state.get_zone_focus(corridor_zone_id) || state.geometry.semantic_hub_turf
	state.geometry.center_turf = state.geometry.semantic_hub_turf || state.geometry.center_turf || state.geometry.front_door_turf
	state.config["room_first_layout"] = TRUE
	state.config["room_count"] = length(state.geometry.solved_rooms)
	state.config["corridor_turf_count"] = length(state.geometry.corridor_turfs)
	state.validation.room_reports.Cut()
	for(var/datum/world_edit_building_room/room as anything in state.geometry.solved_rooms)
		if(!istype(room))
			continue
		state.validation.room_reports += list(list(
			"id" = room.id,
			"zone_id" = room.zone_id,
			"role" = room.role,
			"area" = room.area,
			"useful_area" = length(room.turfs),
			"bounds" = list("x1" = room.x1, "y1" = room.y1, "x2" = room.x2, "y2" = room.y2),
			"focus" = room.focus_turf,
			"tiny" = room.tiny,
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
		"separator_lane_count" = length(state.geometry.separator_lane_turfs),
		"door_transition_count" = length(state.validation.door_reports),
		"front_door_turf" = state.geometry.front_door_turf,
	)
	return length(state.geometry.solved_rooms) > 0 && length(state.geometry.corridor_turfs) > 0

/datum/world_edit_generator/building_layout/proc/build_room_first_candidate_adjacency_edges(datum/world_edit_building_layout_state/state, list/candidates)
	var/list/edges = list()
	if(!istype(state) || !islist(candidates))
		return edges
	var/list/candidate_by_turf = list()
	for(var/list/candidate as anything in candidates)
		if(!islist(candidate))
			continue
		candidate["adjacency_edges"] = list()
		for(var/turf/candidate_turf as anything in candidate["turfs"])
			if(istype(candidate_turf))
				candidate_by_turf[candidate_turf] = candidate
	var/list/seen_edges = list()
	for(var/list/candidate as anything in candidates)
		if(!islist(candidate))
			continue
		for(var/turf/candidate_turf as anything in candidate["turfs"])
			if(!istype(candidate_turf))
				continue
			for(var/check_dir in GLOB.cardinals)
				var/turf/nearby_turf = get_step(candidate_turf, check_dir)
				var/list/other_candidate = candidate_by_turf[nearby_turf]
				if(!islist(other_candidate) || other_candidate == candidate)
					continue
				var/id_a = "[candidate["id"]]"
				var/id_b = "[other_candidate["id"]]"
				var/edge_key = id_a < id_b ? "[id_a]|[id_b]" : "[id_b]|[id_a]"
				var/list/edge = seen_edges[edge_key]
				if(!islist(edge))
					edge = list(
						"id_a" = id_a,
						"id_b" = id_b,
						"candidate_a" = candidate,
						"candidate_b" = other_candidate,
						"contacts" = list(),
						"contact_count" = 0,
					)
					seen_edges[edge_key] = edge
					edges += list(edge)
				var/list/contacts = edge["contacts"]
				contacts += list(list(
					"turf_a" = candidate_turf,
					"turf_b" = nearby_turf,
					"dir" = check_dir,
				))
				edge["contact_count"] = round(text2num("[edge["contact_count"]]") || 0) + 1
	return edges

/datum/world_edit_generator/building_layout/proc/annotate_room_first_candidate_adjacency(datum/world_edit_building_layout_state/state, list/candidates, list/edges)
	if(!istype(state) || !islist(candidates) || !islist(edges))
		return
	for(var/list/candidate as anything in candidates)
		if(!islist(candidate))
			continue
		candidate["shared_room_ids"] = list()
		candidate["shared_wall_count"] = 0
		candidate["adjacent_entry_room_count"] = 0
		candidate["adjacency_contact_count"] = 0
	for(var/list/edge as anything in edges)
		if(!islist(edge))
			continue
		var/list/candidate_a = edge["candidate_a"]
		var/list/candidate_b = edge["candidate_b"]
		var/contact_count = round(text2num("[edge["contact_count"]]") || 0)
		if(!islist(candidate_a) || !islist(candidate_b) || contact_count <= 0)
			continue
		candidate_a["shared_room_ids"]["[candidate_b["id"]]"] = TRUE
		candidate_b["shared_room_ids"]["[candidate_a["id"]]"] = TRUE
		candidate_a["shared_wall_count"] = round(text2num("[candidate_a["shared_wall_count"]]") || 0) + contact_count
		candidate_b["shared_wall_count"] = round(text2num("[candidate_b["shared_wall_count"]]") || 0) + contact_count
		candidate_a["adjacency_contact_count"] = round(text2num("[candidate_a["adjacency_contact_count"]]") || 0) + contact_count
		candidate_b["adjacency_contact_count"] = round(text2num("[candidate_b["adjacency_contact_count"]]") || 0) + contact_count
		candidate_a["adjacency_edges"] += list(edge)
		candidate_b["adjacency_edges"] += list(edge)
	var/list/entry_candidate = select_room_first_entry_candidate(state, candidates)
	if(islist(entry_candidate))
		var/list/entry_neighbors = entry_candidate["shared_room_ids"]
		for(var/list/candidate as anything in candidates)
			if(!islist(candidate) || candidate == entry_candidate)
				continue
			candidate["adjacent_entry_room_count"] = islist(entry_neighbors) && entry_neighbors["[candidate["id"]]"] ? 1 : 0

/datum/world_edit_generator/building_layout/proc/annotate_room_first_route_access(datum/world_edit_building_layout_state/state, list/room_candidates)
	if(!istype(state) || !islist(room_candidates))
		return
	var/list/entry_candidate = select_room_first_entry_candidate(state, room_candidates)
	var/list/entry_neighbor_ids = islist(entry_candidate) ? entry_candidate["shared_room_ids"] : null
	for(var/list/candidate as anything in room_candidates)
		if(!islist(candidate))
			continue
		var/route_access = 0
		var/corridor_touch = candidate["touches_entry"] ? 2 : 0
		if(candidate == entry_candidate)
			route_access += 3
		if(islist(entry_neighbor_ids) && entry_neighbor_ids["[candidate["id"]]"])
			route_access += 2
		if(round(text2num("[candidate["shared_wall_count"]]") || 0) > 0)
			route_access += 1
		candidate["corridor_touch"] = max(round(text2num("[candidate["corridor_touch"]]") || 0), corridor_touch)
		candidate["route_access"] = max(round(text2num("[candidate["route_access"]]") || 0), route_access + candidate["corridor_touch"])

/datum/world_edit_generator/building_layout/proc/select_room_first_corridor_zone_id(datum/world_edit_building_layout_state/state)
	if(!istype(state) || !istype(state.semantic_plan))
		return "common"
	var/datum/world_edit_building_zone_spec/hub_spec = state.semantic_plan.get_zone_spec(state.semantic_plan.hub_zone_id)
	if(istype(hub_spec) && hub_spec.role == "route")
		return hub_spec.id
	for(var/datum/world_edit_building_zone_spec/zone_spec as anything in state.semantic_plan.zone_specs)
		if(istype(zone_spec) && zone_spec.required && zone_spec.role == "route")
			return zone_spec.id
	var/datum/world_edit_building_zone_spec/primary_spec = state.semantic_plan.get_zone_spec(state.semantic_plan.primary_zone_id)
	if(istype(primary_spec) && primary_spec.role != "choke")
		return state.semantic_plan.primary_zone_id
	if(istype(hub_spec) && hub_spec.role != "choke")
		return hub_spec.id
	return state.semantic_plan.entry_zone_id



/datum/world_edit_generator/building_layout/proc/build_room_first_bsp_candidates(datum/world_edit_building_layout_state/state, list/free_lookup, max_candidate_count = 0, target_count = 0)
	var/list/candidates = list()
	var/candidate_limit = round(text2num("[max_candidate_count]") || 0)
	if(candidate_limit <= 0)
		candidate_limit = max(length(free_lookup), 1)
	candidate_limit = clamp(candidate_limit, 1, max(length(free_lookup), 1))
	var/effective_target = max(round(text2num("[target_count]") || 0), 1)
	var/list/seed_candidate = build_room_first_candidate_from_turfs(state, get_room_first_sorted_free_turfs(free_lookup), "room_candidate_root")
	if(!islist(seed_candidate))
		return candidates
	var/list/pending = list(seed_candidate)
	var/split_index = 1
	while(length(pending) && (length(candidates) + length(pending)) < candidate_limit)
		var/list/candidate = pending[1]
		pending.Cut(1, 2)
		if(!islist(candidate))
			continue
		if(length(candidates) + length(pending) + 1 >= effective_target && !room_first_bsp_candidate_should_split(state, candidate, effective_target, length(candidates), length(pending), candidate_limit))
			candidates += list(candidate)
			continue
		var/list/split = split_room_first_bsp_candidate(state, free_lookup, candidate, split_index++)
		if(islist(split) && length(split) >= 2)
			pending += split
		else
			candidates += list(candidate)
	while(length(pending) && length(candidates) < candidate_limit)
		var/list/candidate = pending[1]
		pending.Cut(1, 2)
		if(islist(candidate))
			candidates += list(candidate)
	if(length(candidates) < effective_target)
		ensure_room_first_candidate_count(state, candidates, effective_target)
	annotate_room_first_bsp_candidates(state, candidates)
	return candidates


/datum/world_edit_generator/building_layout/proc/annotate_room_first_bsp_candidates(datum/world_edit_building_layout_state/state, list/candidates)
	if(!istype(state) || !islist(candidates))
		return
	for(var/list/candidate as anything in candidates)
		if(!islist(candidate))
			continue
		candidate["touches_entry"] = room_first_candidate_touches_entry(state, candidate) ? TRUE : FALSE


/datum/world_edit_generator/building_layout/proc/room_first_candidate_touches_entry(datum/world_edit_building_layout_state/state, list/candidate)
	if(!istype(state) || !islist(candidate) || !istype(state.geometry.front_door_turf))
		return FALSE
	if(state.geometry.front_door_turf in candidate["turfs"])
		return TRUE
	var/door_dir = state.geometry.door_dirs[state.geometry.front_door_turf] || state.placement_dir
	var/turf/inward_turf = get_step(state.geometry.front_door_turf, turn(door_dir, 180))
	if(istype(inward_turf) && inward_turf in candidate["turfs"])
		return TRUE
	for(var/turf/room_turf as anything in candidate["turfs"])
		if(!istype(room_turf))
			continue
		if(get_dist(room_turf, state.geometry.front_door_turf) <= 1)
			return TRUE
	return FALSE


/datum/world_edit_generator/building_layout/proc/get_room_first_sorted_free_turfs(list/free_lookup)
	var/list/turfs = list()
	for(var/turf/free_turf as anything in free_lookup)
		if(istype(free_turf))
			turfs += free_turf
	if(length(turfs) <= 1)
		return turfs
	for(var/i in 1 to length(turfs) - 1)
		for(var/j in i + 1 to length(turfs))
			var/turf/a = turfs[i]
			var/turf/b = turfs[j]
			if(!istype(a) || !istype(b))
				continue
			if(a.x > b.x || (a.x == b.x && a.y > b.y))
				turfs[i] = b
				turfs[j] = a
	return turfs

/datum/world_edit_generator/building_layout/proc/room_first_bsp_candidate_should_split(datum/world_edit_building_layout_state/state, list/candidate, target_count, solved_count, pending_count, candidate_limit)
	if(!islist(candidate))
		return FALSE
	var/area = round(text2num("[candidate["area"]]") || 0)
	var/width = (round(text2num("[candidate["x2"]]") || 0) - round(text2num("[candidate["x1"]]") || 0)) + 1
	var/height = (round(text2num("[candidate["y2"]]") || 0) - round(text2num("[candidate["y1"]]") || 0)) + 1
	if((solved_count + pending_count + 1) >= candidate_limit)
		return FALSE
	if(area < 6)
		return FALSE
	if(width < 3 && height < 3)
		return FALSE
	if((solved_count + pending_count + 1) < target_count)
		return TRUE
	if(area >= 16)
		return TRUE
	return max(width, height) >= 6

/datum/world_edit_generator/building_layout/proc/split_room_first_bsp_candidate(datum/world_edit_building_layout_state/state, list/free_lookup, list/candidate, split_index)
	var/list/result = list()
	if(!islist(candidate) || !islist(free_lookup))
		return result
	var/x1 = round(text2num("[candidate["x1"]]") || 0)
	var/x2 = round(text2num("[candidate["x2"]]") || 0)
	var/y1 = round(text2num("[candidate["y1"]]") || 0)
	var/y2 = round(text2num("[candidate["y2"]]") || 0)
	var/width = (x2 - x1) + 1
	var/height = (y2 - y1) + 1
	var/split_vertical = width >= height
	var/list/first_turfs = list()
	var/list/second_turfs = list()
	if(split_vertical && width >= 3)
		var/split_x = x1 + max(1, round(width / 2)) - 1
		for(var/turf/room_turf as anything in candidate["turfs"])
			if(!istype(room_turf) || !free_lookup[room_turf])
				continue
			if(room_turf.x <= split_x)
				first_turfs += room_turf
			else
				second_turfs += room_turf
	else if(height >= 3)
		var/split_y = y1 + max(1, round(height / 2)) - 1
		for(var/turf/room_turf as anything in candidate["turfs"])
			if(!istype(room_turf) || !free_lookup[room_turf])
				continue
			if(room_turf.y <= split_y)
				first_turfs += room_turf
			else
				second_turfs += room_turf
	if(!length(first_turfs) || !length(second_turfs))
		return result
	var/list/first_regions = extract_room_first_connected_components(free_lookup, first_turfs)
	var/list/second_regions = extract_room_first_connected_components(free_lookup, second_turfs)
	for(var/list/region as anything in first_regions)
		var/list/region_candidate = build_room_first_candidate_from_turfs(state, region, "[candidate["id"]]_split_[split_index]_a")
		if(islist(region_candidate))
			result += list(region_candidate)
	for(var/list/region as anything in second_regions)
		var/list/region_candidate = build_room_first_candidate_from_turfs(state, region, "[candidate["id"]]_split_[split_index]_b")
		if(islist(region_candidate))
			result += list(region_candidate)
	return result

/datum/world_edit_generator/building_layout/proc/extract_room_first_connected_components(list/free_lookup, list/source_turfs)
	var/list/components = list()
	if(!islist(free_lookup) || !islist(source_turfs) || !length(source_turfs))
		return components
	var/list/allowed = list()
	for(var/turf/source_turf as anything in source_turfs)
		if(istype(source_turf) && free_lookup[source_turf])
			allowed[source_turf] = TRUE
	var/list/visited = list()
	for(var/turf/start_turf as anything in source_turfs)
		if(!istype(start_turf) || !allowed[start_turf] || visited[start_turf])
			continue
		var/list/component = list()
		var/list/queue = list(start_turf)
		visited[start_turf] = TRUE
		var/index = 1
		while(index <= length(queue))
			var/turf/current = queue[index++]
			component += current
			for(var/check_dir in GLOB.cardinals)
				var/turf/nearby = get_step(current, check_dir)
				if(!allowed[nearby] || visited[nearby])
					continue
				visited[nearby] = TRUE
				queue += nearby
		if(length(component))
			components += list(component)
	return components

/datum/world_edit_generator/building_layout/proc/build_room_first_candidate_from_turfs(datum/world_edit_building_layout_state/state, list/turfs, candidate_id)
	if(!islist(turfs) || !length(turfs))
		return null
	var/list/candidate = list(
		"id" = "[candidate_id]",
		"turfs" = turfs.Copy(),
		"area" = length(turfs),
		"x1" = null,
		"x2" = null,
		"y1" = null,
		"y2" = null,
		"wall_affinity" = 0,
		"corridor_touch" = 0,
		"separator_access" = 0,
		"route_access" = 0,
	)
	var/min_x = null
	var/max_x = null
	var/min_y = null
	var/max_y = null
	var/wall_affinity = 0
	var/corridor_touch = 0
	var/separator_access = 0
	for(var/turf/room_turf as anything in turfs)
		if(!istype(room_turf))
			continue
		if(isnull(min_x) || room_turf.x < min_x)
			min_x = room_turf.x
		if(isnull(max_x) || room_turf.x > max_x)
			max_x = room_turf.x
		if(isnull(min_y) || room_turf.y < min_y)
			min_y = room_turf.y
		if(isnull(max_y) || room_turf.y > max_y)
			max_y = room_turf.y
		for(var/check_dir in GLOB.cardinals)
			var/turf/nearby_turf = get_step(room_turf, check_dir)
			if(state.geometry.boundary_lookup[nearby_turf] || !state.geometry.footprint_lookup[nearby_turf])
				wall_affinity++
			if(state.geometry.corridor_lookup[nearby_turf])
				corridor_touch++
			if(state.geometry.separator_lane_lookup[nearby_turf] && building_separator_lane_touches_corridor(state, nearby_turf))
				separator_access++
	candidate["x1"] = min_x
	candidate["x2"] = max_x
	candidate["y1"] = min_y
	candidate["y2"] = max_y
	candidate["wall_affinity"] = wall_affinity
	candidate["corridor_touch"] = corridor_touch
	candidate["separator_access"] = separator_access
	candidate["route_access"] = corridor_touch + separator_access
	candidate["focus"] = select_room_first_candidate_focus(turfs, min_x, min_y, max_x, max_y)
	return candidate

/datum/world_edit_generator/building_layout/proc/select_room_first_candidate_focus(list/turfs, min_x, min_y, max_x, max_y)
	var/center_x = (min_x + max_x) / 2
	var/center_y = (min_y + max_y) / 2
	var/turf/best_turf = null
	var/best_score = -999999999
	for(var/turf/check_turf as anything in turfs)
		if(!istype(check_turf))
			continue
		var/score = 0 - abs(check_turf.x - center_x) - abs(check_turf.y - center_y)
		if(!istype(best_turf) || score > best_score)
			best_turf = check_turf
			best_score = score
	return best_turf

/datum/world_edit_generator/building_layout/proc/score_room_first_raw_candidate(datum/world_edit_building_layout_state/state, list/candidate)
	var/area = round(text2num("[candidate["area"]]") || 0)
	var/width = (round(text2num("[candidate["x2"]]") || 0) - round(text2num("[candidate["x1"]]") || 0)) + 1
	var/height = (round(text2num("[candidate["y2"]]") || 0) - round(text2num("[candidate["y1"]]") || 0)) + 1
	var/score = area * 100
	score -= abs(width - height) * 8
	score += round(text2num("[candidate["wall_affinity"]]") || 0) * 12
	score += round(text2num("[candidate["corridor_touch"]]") || 0) * 45
	score += round(text2num("[candidate["separator_access"]]") || 0) * 90
	return score

/datum/world_edit_generator/building_layout/proc/get_room_first_region_specs_for_zone(datum/world_edit_building_layout_state/state, zone_id)
	var/list/result = list()
	if(!istype(state) || !istype(state.semantic_plan) || !length("[zone_id]"))
		return result
	for(var/datum/world_edit_building_region_spec/region_spec as anything in state.semantic_plan.region_specs)
		if(istype(region_spec) && region_spec.zone_id == "[zone_id]")
			result += region_spec
	return result

/datum/world_edit_generator/building_layout/proc/score_room_first_candidate_region_intent(datum/world_edit_building_layout_state/state, list/candidate, datum/world_edit_building_zone_spec/zone_spec)
	if(!istype(state) || !islist(candidate) || !istype(zone_spec))
		return 0
	var/list/region_specs = get_room_first_region_specs_for_zone(state, zone_spec.id)
	if(!length(region_specs))
		candidate["region_match_area"] = null
		candidate["region_match_id"] = null
		return 0
	var/best_overlap = 0
	var/best_priority = -999999999
	var/best_region_id = ""
	var/focus_region_match = FALSE
	var/turf/focus_turf = candidate["focus"]
	for(var/datum/world_edit_building_region_spec/region_spec as anything in region_specs)
		if(!istype(region_spec))
			continue
		var/overlap = 0
		for(var/turf/candidate_turf as anything in candidate["turfs"])
			if(istype(candidate_turf) && region_spec_contains_turf(state, region_spec, candidate_turf))
				overlap++
		if(overlap > best_overlap || (overlap == best_overlap && region_spec.priority > best_priority))
			best_overlap = overlap
			best_priority = region_spec.priority
			best_region_id = region_spec.id
			focus_region_match = istype(focus_turf) && region_spec_contains_turf(state, region_spec, focus_turf)
	candidate["region_match_area"] = best_overlap
	candidate["region_match_id"] = best_region_id
	candidate["region_focus_match"] = focus_region_match ? TRUE : FALSE
	var/area = max(round(text2num("[candidate["area"]]") || 0), 1)
	var/score = best_overlap * 160
	score += best_priority * 5
	score += round((best_overlap * 100) / area) * 4
	if(focus_region_match)
		score += 360
	if(best_overlap <= 0 && zone_spec.required && !is_building_compact_or_micro_state(state))
		score -= 1000000
	return score

/datum/world_edit_generator/building_layout/proc/room_first_candidate_satisfies_region_intent(datum/world_edit_building_layout_state/state, list/candidate, datum/world_edit_building_zone_spec/zone_spec)
	if(!istype(state) || !islist(candidate) || !istype(zone_spec))
		return FALSE
	if(is_building_compact_or_micro_state(state))
		return TRUE
	var/list/region_specs = get_room_first_region_specs_for_zone(state, zone_spec.id)
	if(!length(region_specs))
		return TRUE
	score_room_first_candidate_region_intent(state, candidate, zone_spec)
	return round(text2num("[candidate["region_match_area"]]") || 0) > 0

/datum/world_edit_generator/building_layout/proc/score_room_first_candidate_adjacency_contract(datum/world_edit_building_layout_state/state, list/candidate, datum/world_edit_building_zone_spec/zone_spec)
	if(!istype(state) || !islist(candidate) || !istype(zone_spec) || !istype(state.semantic_plan))
		return 0
	var/score = 0
	var/required_missing = 0
	for(var/datum/world_edit_building_adjacency_rule/rule as anything in state.semantic_plan.adjacency_rules)
		if(!istype(rule) || !rule.required)
			continue
		var/other_zone_id = ""
		if(rule.zone_a == zone_spec.id)
			other_zone_id = rule.zone_b
		else if(rule.zone_b == zone_spec.id)
			other_zone_id = rule.zone_a
		if(!length(other_zone_id))
			continue
		var/list/other_zone_turfs = state.get_zone_turfs(other_zone_id)
		if(!length(other_zone_turfs))
			continue
		var/list/other_lookup = GLOB.world_edit_placement_shapes.world_edit_build_turf_lookup(other_zone_turfs)
		var/contact_count = 0
		for(var/turf/candidate_turf as anything in candidate["turfs"])
			if(!istype(candidate_turf))
				continue
			for(var/check_dir in GLOB.cardinals)
				var/turf/nearby_turf = get_step(candidate_turf, check_dir)
				if(other_lookup[nearby_turf])
					contact_count++
					continue
				if(state.geometry.wall_lookup[nearby_turf] || state.geometry.door_dirs[nearby_turf])
					var/turf/beyond_turf = get_step(nearby_turf, check_dir)
					if(other_lookup[beyond_turf])
						contact_count++
		if(contact_count > 0)
			score += 650 + (contact_count * 220)
		else if(!is_building_compact_or_micro_state(state) && length(state.geometry.interior) >= 40)
			required_missing++
	if(required_missing > 0)
		score -= required_missing * 160000
	return score

/datum/world_edit_generator/building_layout/proc/get_room_first_zone_specs(datum/world_edit_building_layout_state/state, corridor_zone_id, entry_zone_id)
	var/list/specs = list()
	var/list/added = list()
	var/list/preferred_ids = list(state.semantic_plan.primary_zone_id, state.semantic_plan.hub_zone_id)
	for(var/preferred_id as anything in preferred_ids)
		if(!length("[preferred_id]") || preferred_id == corridor_zone_id || preferred_id == entry_zone_id || added["[preferred_id]"])
			continue
		var/datum/world_edit_building_zone_spec/preferred_spec = state.semantic_plan.get_zone_spec(preferred_id)
		if(istype(preferred_spec) && preferred_spec.required)
			specs += preferred_spec
			added[preferred_spec.id] = TRUE
	for(var/datum/world_edit_building_zone_spec/zone_spec as anything in state.semantic_plan.zone_specs)
		if(!istype(zone_spec) || !zone_spec.required || zone_spec.id == corridor_zone_id || zone_spec.id == entry_zone_id || added[zone_spec.id])
			continue
		specs += zone_spec
		added[zone_spec.id] = TRUE
	return specs

/datum/world_edit_generator/building_layout/proc/ensure_room_first_candidate_count(datum/world_edit_building_layout_state/state, list/candidates, target_count)
	if(!islist(candidates))
		return
	var/split_index = 1
	while(length(candidates) < target_count)
		var/list/largest = null
		var/largest_index = null
		var/largest_area = 0
		for(var/index in 1 to length(candidates))
			var/list/candidate = candidates[index]
			if(!islist(candidate))
				continue
			var/area = round(text2num("[candidate["area"]]") || 0)
			if(area > largest_area)
				largest = candidate
				largest_index = index
				largest_area = area
		if(!islist(largest) || isnull(largest_index) || largest_area < 6)
			break
		var/list/split = split_room_first_candidate(state, largest, split_index++)
		if(!islist(split) || length(split) < 2)
			break
		candidates.Cut(largest_index, largest_index + 1)
		for(var/list/split_candidate as anything in split)
			candidates += list(split_candidate)

/datum/world_edit_generator/building_layout/proc/split_room_first_candidate(datum/world_edit_building_layout_state/state, list/candidate, split_index)
	var/list/result = list()
	var/list/left_turfs = list()
	var/list/right_turfs = list()
	var/x1 = round(text2num("[candidate["x1"]]") || 0)
	var/x2 = round(text2num("[candidate["x2"]]") || 0)
	var/y1 = round(text2num("[candidate["y1"]]") || 0)
	var/y2 = round(text2num("[candidate["y2"]]") || 0)
	var/width = (x2 - x1) + 1
	var/height = (y2 - y1) + 1
	if(width >= height && width >= 3)
		var/split_x = x1 + max(0, round((width - 1) / 2))
		for(var/turf/room_turf as anything in candidate["turfs"])
			if(room_turf.x <= split_x)
				left_turfs += room_turf
			else
				right_turfs += room_turf
	else if(height >= 3)
		var/split_y = y1 + max(0, round((height - 1) / 2))
		for(var/turf/room_turf as anything in candidate["turfs"])
			if(room_turf.y <= split_y)
				left_turfs += room_turf
			else
				right_turfs += room_turf
	if(length(left_turfs) && length(right_turfs))
		result += list(build_room_first_candidate_from_turfs(state, left_turfs, "[candidate["id"]]_split_[split_index]_a"))
		result += list(build_room_first_candidate_from_turfs(state, right_turfs, "[candidate["id"]]_split_[split_index]_b"))
	return result

/datum/world_edit_generator/building_layout/proc/assign_room_first_zone_rooms(datum/world_edit_building_layout_state/state, list/room_candidates, list/zone_specs, corridor_zone_id, entry_zone_id)
	var/list/used_candidate_ids = list()
	var/list/claimed_turfs = list()
	var/list/root_selection = assign_room_first_entry_and_hub_rooms(state, room_candidates, used_candidate_ids, corridor_zone_id, entry_zone_id)
	if(islist(root_selection))
		for(var/turf/claimed_turf as anything in root_selection["claimed_turfs"])
			claimed_turfs[claimed_turf] = TRUE
	for(var/datum/world_edit_building_zone_spec/zone_spec as anything in zone_specs)
		if(!istype(zone_spec))
			continue
		if(zone_spec.id == corridor_zone_id || zone_spec.id == entry_zone_id)
			continue
		var/list/candidate = select_room_first_candidate_for_zone(state, room_candidates, used_candidate_ids, zone_spec)
		if(islist(candidate))
			used_candidate_ids["[candidate["id"]]"] = TRUE
			candidate["used"] = TRUE
			var/datum/world_edit_building_room/room = emit_room_first_room_for_candidate(state, candidate, zone_spec)
			if(istype(room))
				for(var/turf/room_turf as anything in room.turfs)
					claimed_turfs[room_turf] = TRUE
			continue
		if(zone_spec.required)
			state.validation.mandatory_room_missing_count++
			if(zone_spec.divider_mode == "room")
				state.validation.mandatory_room_no_bounds_count++
			state.add_warning("Required zone '[zone_spec.id]' has no valid room candidate. Soft fallback active: continuing without zone.")
			continue
		state.add_warning("Optional zone '[zone_spec.id]' skipped because no BSP room candidate satisfied the semantic assignment contract.")


/datum/world_edit_generator/building_layout/proc/assign_room_first_entry_and_hub_rooms(datum/world_edit_building_layout_state/state, list/room_candidates, list/used_candidate_ids, corridor_zone_id, entry_zone_id)
	var/list/result = list("claimed_turfs" = list())
	if(!istype(state) || !islist(room_candidates) || !islist(used_candidate_ids))
		return result
	var/list/entry_candidate = select_room_first_entry_candidate(state, room_candidates)
	var/list/hub_candidate = select_room_first_hub_candidate(state, room_candidates, entry_candidate)
	var/assigned_entry_zone_id = length("[entry_zone_id]") ? "[entry_zone_id]" : corridor_zone_id
	if(!islist(entry_candidate) && islist(hub_candidate))
		entry_candidate = hub_candidate
	if(islist(entry_candidate) && islist(hub_candidate) && entry_candidate == hub_candidate)
		assigned_entry_zone_id = corridor_zone_id
	if(islist(entry_candidate))
		used_candidate_ids["[entry_candidate["id"]]"] = TRUE
		entry_candidate["used"] = TRUE
		var/datum/world_edit_building_zone_spec/entry_spec = state.semantic_plan.get_zone_spec(assigned_entry_zone_id)
		if(!istype(entry_spec) && assigned_entry_zone_id == corridor_zone_id)
			entry_spec = state.semantic_plan.get_zone_spec(corridor_zone_id)
		if(istype(entry_spec))
			var/datum/world_edit_building_room/entry_room = emit_room_first_room_for_candidate(state, entry_candidate, entry_spec)
			if(istype(entry_room))
				for(var/turf/entry_turf as anything in entry_room.turfs)
					result["claimed_turfs"] += entry_turf
				state.geometry.semantic_hub_turf = entry_room.focus_turf
	if(islist(hub_candidate) && hub_candidate != entry_candidate)
		used_candidate_ids["[hub_candidate["id"]]"] = TRUE
		hub_candidate["used"] = TRUE
		var/datum/world_edit_building_zone_spec/hub_spec = state.semantic_plan.get_zone_spec(corridor_zone_id)
		if(istype(hub_spec))
			var/datum/world_edit_building_room/hub_room = emit_room_first_room_for_candidate(state, hub_candidate, hub_spec)
			if(istype(hub_room))
				for(var/turf/hub_turf as anything in hub_room.turfs)
					result["claimed_turfs"] += hub_turf
				state.geometry.semantic_hub_turf = hub_room.focus_turf
				state.set_zone_focus(corridor_zone_id, hub_room.focus_turf)
	if(!istype(state.geometry.semantic_hub_turf) && islist(entry_candidate))
		state.geometry.semantic_hub_turf = entry_candidate["focus"]
	return result


/datum/world_edit_generator/building_layout/proc/select_room_first_entry_candidate(datum/world_edit_building_layout_state/state, list/room_candidates)
	var/list/best_candidate = null
	var/best_score = -999999999
	for(var/list/candidate as anything in room_candidates)
		if(!islist(candidate))
			continue
		var/score = candidate["touches_entry"] ? 100000 : 0
		var/turf/focus_turf = candidate["focus"]
		if(istype(focus_turf) && istype(state.geometry.front_door_turf))
			score -= get_dist(focus_turf, state.geometry.front_door_turf) * 100
		if(score > best_score)
			best_candidate = candidate
			best_score = score
	return best_candidate


/datum/world_edit_generator/building_layout/proc/select_room_first_hub_candidate(datum/world_edit_building_layout_state/state, list/room_candidates, list/entry_candidate)
	var/list/best_candidate = null
	var/best_score = -999999999
	var/list/entry_neighbors = islist(entry_candidate) ? entry_candidate["shared_room_ids"] : null
	for(var/list/candidate as anything in room_candidates)
		if(!islist(candidate))
			continue
		var/score = round(text2num("[candidate["area"]]") || 0) * 100
		if(candidate == entry_candidate)
			score += 25000
		if(islist(entry_neighbors) && entry_neighbors["[candidate["id"]]"])
			score += 50000
		score += round(text2num("[candidate["shared_wall_count"]]") || 0) * 20
		score += round(text2num("[candidate["adjacency_contact_count"]]") || 0) * 15
		if(candidate["touches_entry"])
			score += 15000
		if(score > best_score)
			best_candidate = candidate
			best_score = score
	return best_candidate

/datum/world_edit_generator/building_layout/proc/select_room_first_candidate_for_zone(datum/world_edit_building_layout_state/state, list/room_candidates, list/used_candidate_ids, datum/world_edit_building_zone_spec/zone_spec)
	var/list/best_candidate = null
	var/best_score = -999999999
	var/requires_route_access = istype(zone_spec) && zone_spec.required && zone_spec.must_touch_route
	var/min_required_area = istype(zone_spec) ? max(zone_spec.min_area, 1) : 1
	// First pass: strict region intent
	for(var/list/candidate as anything in room_candidates)
		if(!islist(candidate) || used_candidate_ids["[candidate["id"]]"])
			continue
		var/candidate_area = round(text2num("[candidate["area"]]") || 0)
		if(istype(zone_spec) && zone_spec.required && candidate_area < min_required_area)
			continue
		if(requires_route_access && round(text2num("[candidate["route_access"]]") || 0) <= 0)
			continue
		if(zone_spec.required && !room_first_candidate_satisfies_region_intent(state, candidate, zone_spec))
			continue
		var/score = score_room_first_candidate_for_zone(state, candidate, zone_spec)
		if(score > best_score)
			best_candidate = candidate
			best_score = score
	// Second pass: relaxed region intent for required zones when no strict match found
	if(!islist(best_candidate) && istype(zone_spec) && zone_spec.required)
		for(var/list/candidate as anything in room_candidates)
			if(!islist(candidate) || used_candidate_ids["[candidate["id"]]"])
				continue
			var/candidate_area = round(text2num("[candidate["area"]]") || 0)
			if(candidate_area < min_required_area)
				continue
			var/score = score_room_first_candidate_for_zone(state, candidate, zone_spec)
			// Penalize candidates that don't satisfy region intent or route access, but still allow them
			if(!room_first_candidate_satisfies_region_intent(state, candidate, zone_spec))
				score -= 50000
				state.add_warning("Zone '[zone_spec.id]' assigned candidate '[candidate["id"]]' outside preferred region (relaxed region intent).")
			if(requires_route_access && round(text2num("[candidate["route_access"]]") || 0) <= 0)
				score -= 30000
				state.add_warning("Zone '[zone_spec.id]' assigned candidate '[candidate["id"]]' without direct route access (relaxed route requirement).")
			if(score > best_score)
				best_candidate = candidate
				best_score = score
	// Third pass: extreme fallback for required zones - ignore area constraints completely
	if(!islist(best_candidate) && istype(zone_spec) && zone_spec.required)
		var/fallback_score = -999999999
		for(var/list/candidate as anything in room_candidates)
			if(!islist(candidate) || used_candidate_ids["[candidate["id"]]"])
				continue
			var/score = round(text2num("[candidate["area"]]") || 0)
			if(score > fallback_score)
				best_candidate = candidate
				fallback_score = score
		if(islist(best_candidate))
			state.add_warning("Zone '[zone_spec.id]' assigned to extreme fallback candidate '[best_candidate["id"]]' bypassing area constraints.")
	return best_candidate


/datum/world_edit_generator/building_layout/proc/rebuild_room_first_corridor_from_hub(datum/world_edit_building_layout_state/state, corridor_zone_id, entry_zone_id)
	if(!istype(state))
		return
	state.geometry.corridor_turfs.Cut()
	state.geometry.corridor_lookup.Cut()
	state.geometry.primary_route_turfs.Cut()
	var/list/entry_zone_turfs = state.get_zone_turfs(entry_zone_id)
	for(var/turf/room_turf as anything in state.get_zone_turfs(corridor_zone_id))
		state.add_corridor_turf(room_turf)
	if(entry_zone_id != corridor_zone_id)
		for(var/turf/entry_turf as anything in entry_zone_turfs)
			state.add_primary_route(entry_turf)
	for(var/turf/entry_turf as anything in entry_zone_turfs)
		state.add_corridor_turf(entry_turf)
	if(istype(state.geometry.front_door_turf))
		state.add_corridor_turf(state.geometry.front_door_turf)
		state.add_primary_route(state.geometry.front_door_turf)

/datum/world_edit_generator/building_layout/proc/score_room_first_candidate_for_zone(datum/world_edit_building_layout_state/state, list/candidate, datum/world_edit_building_zone_spec/zone_spec)
	var/area = round(text2num("[candidate["area"]]") || 0)
	var/min_area = max(zone_spec.min_area, 1)
	var/score = min(area, max(min_area * 3, min_area + 2)) * 80
	var/route_access = round(text2num("[candidate["route_access"]]") || 0)
	if(area < min_area)
		score -= (min_area - area) * 400
		if(zone_spec.required && zone_spec.must_touch_route)
			if(route_access <= 0)
				score -= 100000
			else
				score += route_access * 220
		if(zone_spec.id == state.semantic_plan.hub_zone_id || zone_spec.role == "hub" || zone_spec.role == "route")
			score += round(text2num("[candidate["adjacent_entry_room_count"]]") || 0) * 400
			score += round(text2num("[candidate["adjacency_contact_count"]]") || 0) * 25
	var/turf/focus_turf = candidate["focus"]
	var/front_depth = istype(focus_turf) ? world_edit_building_front_depth(focus_turf, state.geometry.bounds, state.placement_dir) : 0
	var/lateral_abs = istype(focus_turf) ? abs(world_edit_building_lateral_offset(focus_turf, state.geometry.bounds, state.placement_dir)) : 0
	if(zone_spec.id == state.semantic_plan.primary_zone_id || zone_spec.id == state.semantic_plan.hub_zone_id || zone_spec.role == "hub")
		score += area * 60
		score -= lateral_abs * 10
	switch(zone_spec.role)
		if("entry", "public", "public_med")
			score -= front_depth * 35
			score -= lateral_abs * 8
		if("private", "storage", "service", "secure", "support", "nested")
			score += front_depth * 35
			score += round(text2num("[candidate["wall_affinity"]]") || 0) * 85
		if("choke", "route")
			score += round(text2num("[candidate["corridor_touch"]]") || 0) * 120
	if(zone_spec.divider_mode == "room")
		score += round(text2num("[candidate["wall_affinity"]]") || 0) * 55
	score += score_room_first_candidate_region_intent(state, candidate, zone_spec)
	score += score_room_first_candidate_adjacency_contract(state, candidate, zone_spec)
	return score

/datum/world_edit_generator/building_layout/proc/emit_room_first_room_for_candidate(datum/world_edit_building_layout_state/state, list/candidate, datum/world_edit_building_zone_spec/zone_spec)
	var/datum/world_edit_building_room/room = new("room_[zone_spec.id]_[length(state.geometry.solved_rooms) + 1]", zone_spec.id, zone_spec.role)
	for(var/turf/room_turf as anything in candidate["turfs"])
		room.add_turf(room_turf)
	room.focus_turf = candidate["focus"]
	state.add_solved_room(room)
	var/datum/world_edit_building_solved_region/region = new("room_region_[room.id]", zone_spec.id, zone_spec.required ? 100 : 50)
	for(var/turf/room_turf as anything in room.turfs)
		region.turfs += room_turf
		extend_solved_region_bounds(region, room_turf)
	region.focus_turf = room.focus_turf
	state.geometry.solved_regions += region
	state.add_pattern_report(list(
		"type" = "room_region_contract",
		"room_id" = room.id,
		"zone_id" = zone_spec.id,
		"candidate_id" = candidate["id"],
		"region_match_id" = candidate["region_match_id"],
		"region_match_area" = candidate["region_match_area"],
		"region_focus_match" = candidate["region_focus_match"] ? TRUE : FALSE,
	))
	return room

/datum/world_edit_generator/building_layout/proc/assign_room_first_unclaimed_floor_to_hub(datum/world_edit_building_layout_state/state, list/free_lookup, list/room_candidates, corridor_zone_id)
	var/fallback_zone_id = length("[state.semantic_plan.primary_zone_id]") ? state.semantic_plan.primary_zone_id : corridor_zone_id
	var/datum/world_edit_building_zone_spec/fallback_spec = state.semantic_plan.get_zone_spec(fallback_zone_id)
	for(var/list/candidate as anything in room_candidates)
		if(!islist(candidate) || candidate["used"])
			continue
		var/has_unclaimed_turf = FALSE
		for(var/turf/candidate_turf as anything in candidate["turfs"])
			if(istype(candidate_turf) && !length(state.get_zone(candidate_turf)))
				has_unclaimed_turf = TRUE
				break
		if(!has_unclaimed_turf)
			continue
		if(istype(fallback_spec))
			emit_room_first_room_for_candidate(state, candidate, fallback_spec)
			candidate["used"] = TRUE
	for(var/turf/free_turf as anything in free_lookup)
		if(!istype(free_turf) || length(state.get_zone(free_turf)))
			continue
		state.add_zone(free_turf, fallback_zone_id)
	var/list/corridor_region_turfs = list()
	for(var/turf/corridor_turf as anything in state.geometry.corridor_turfs)
		if(istype(corridor_turf))
			corridor_region_turfs += corridor_turf
	if(length(corridor_region_turfs))
		var/datum/world_edit_building_solved_region/corridor_region = new("room_first_corridor", corridor_zone_id, 120)
		for(var/turf/corridor_turf as anything in corridor_region_turfs)
			corridor_region.turfs += corridor_turf
			extend_solved_region_bounds(corridor_region, corridor_turf)
		corridor_region.focus_turf = state.geometry.semantic_hub_turf
		state.geometry.solved_regions += corridor_region

/datum/world_edit_generator/building_layout/proc/build_room_first_internal_walls(datum/world_edit_building_layout_state/state)
	for(var/datum/world_edit_building_room/room as anything in state.geometry.solved_rooms)
		if(!istype(room))
			continue
		var/datum/world_edit_building_divider_plan/divider_plan = build_building_large_room_divider_plan(state, room)
		if(istype(divider_plan))
			state.add_divider_plan(divider_plan)
	build_room_first_room_boundary_walls(state)

/datum/world_edit_generator/building_layout/proc/build_building_large_room_divider_plan(datum/world_edit_building_layout_state/state, datum/world_edit_building_room/room)
	if(!istype(state) || !istype(room))
		return null
	if(room.area < 40 || length(room.turfs) < 12)
		return null
	var/datum/world_edit_building_zone_spec/zone_spec = state.semantic_plan?.get_zone_spec(room.zone_id)
	if(istype(zone_spec) && zone_spec.divider_mode == "none")
		return null
	var/room_width = isnull(room.x1) || isnull(room.x2) ? 0 : (room.x2 - room.x1) + 1
	var/room_height = isnull(room.y1) || isnull(room.y2) ? 0 : (room.y2 - room.y1) + 1
	if(room_width < 5 || room_height < 4)
		return null
	var/prefer_vertical = room_width >= room_height
	var/datum/world_edit_building_divider_plan/divider_plan = build_building_large_room_axis_divider_plan(state, room, prefer_vertical ? "vertical" : "horizontal")
	if(istype(divider_plan))
		return divider_plan
	return build_building_large_room_axis_divider_plan(state, room, prefer_vertical ? "horizontal" : "vertical")

/datum/world_edit_generator/building_layout/proc/build_building_large_room_axis_divider_plan(datum/world_edit_building_layout_state/state, datum/world_edit_building_room/room, orientation)
	if(!istype(state) || !istype(room))
		return null
	var/list/room_lookup = GLOB.world_edit_placement_shapes.world_edit_build_turf_lookup(room.turfs)
	if(!length(room_lookup))
		return null
	var/list/axis_candidates = build_building_large_room_divider_axis_candidates(room, orientation)
	var/list/best_plan_data = null
	var/best_score = -999999999
	for(var/axis_value as anything in axis_candidates)
		var/list/plan_data = build_building_large_room_axis_plan_data(state, room, room_lookup, orientation, axis_value)
		if(!islist(plan_data))
			continue
		var/score = round(text2num("[plan_data["score"]]") || 0)
		if(!islist(best_plan_data) || score > best_score)
			best_plan_data = plan_data
			best_score = score
	if(!islist(best_plan_data))
		return null
	var/datum/world_edit_building_divider_plan/divider_plan = new("room_[room.id]_[orientation]", room.zone_id, "[room.zone_id]_subroom")
	var/list/wall_turfs = best_plan_data["wall_turfs"]
	var/list/inner_turfs = best_plan_data["inner_turfs"]
	var/turf/opening_turf = best_plan_data["opening_turf"]
	var/opening_dir = best_plan_data["opening_dir"]
	for(var/turf/wall_turf as anything in wall_turfs)
		if(istype(wall_turf))
			divider_plan.wall_turfs += wall_turf
	for(var/turf/inner_turf as anything in inner_turfs)
		if(istype(inner_turf))
			divider_plan.inner_turfs += inner_turf
	if(!istype(opening_turf) || !length(divider_plan.wall_turfs) || !length(divider_plan.inner_turfs))
		return null
	divider_plan.opening_turfs += opening_turf
	divider_plan.opening_dirs[opening_turf] = opening_dir || get_cardinal_dir_toward(opening_turf, state.geometry.semantic_hub_turf || state.geometry.front_door_turf || room.focus_turf, state.placement_dir)
	if(!divider_plan_keeps_floor_reachable(state, divider_plan))
		return null
	return divider_plan

/datum/world_edit_generator/building_layout/proc/build_building_large_room_divider_axis_candidates(datum/world_edit_building_room/room, orientation)
	var/list/axis_candidates = list()
	if(!istype(room))
		return axis_candidates
	if(orientation == "vertical")
		for(var/axis_x in room.x1 + 2 to room.x2 - 2)
			axis_candidates += axis_x
	else
		for(var/axis_y in room.y1 + 2 to room.y2 - 2)
			axis_candidates += axis_y
	return axis_candidates

/datum/world_edit_generator/building_layout/proc/build_building_large_room_axis_plan_data(datum/world_edit_building_layout_state/state, datum/world_edit_building_room/room, list/room_lookup, orientation, axis_value)
	var/list/wall_turfs = list()
	var/list/left_side = list()
	var/list/right_side = list()
	var/list/opening_candidates = list()
	if(orientation == "vertical")
		for(var/y in room.y1 to room.y2)
			var/turf/center_turf = locate(axis_value, y, room.focus_turf?.z || state.geometry.front_door_turf?.z || 1)
			if(!room_lookup[center_turf])
				return null
			var/turf/west_turf = locate(axis_value - 1, y, center_turf.z)
			var/turf/east_turf = locate(axis_value + 1, y, center_turf.z)
			if(!room_lookup[west_turf] || !room_lookup[east_turf])
				return null
			if(state.geometry.reserved_lookup[center_turf] || state.geometry.boundary_lookup[center_turf] || state.geometry.wall_lookup[center_turf] || state.geometry.door_dirs[center_turf])
				return null
			wall_turfs += center_turf
			opening_candidates += center_turf
			left_side += west_turf
			right_side += east_turf
	else
		for(var/x in room.x1 to room.x2)
			var/turf/center_turf = locate(x, axis_value, room.focus_turf?.z || state.geometry.front_door_turf?.z || 1)
			if(!room_lookup[center_turf])
				return null
			var/turf/south_turf = locate(x, axis_value - 1, center_turf.z)
			var/turf/north_turf = locate(x, axis_value + 1, center_turf.z)
			if(!room_lookup[south_turf] || !room_lookup[north_turf])
				return null
			if(state.geometry.reserved_lookup[center_turf] || state.geometry.boundary_lookup[center_turf] || state.geometry.wall_lookup[center_turf] || state.geometry.door_dirs[center_turf])
				return null
			wall_turfs += center_turf
			opening_candidates += center_turf
			left_side += south_turf
			right_side += north_turf
	if(length(wall_turfs) < 4 || length(left_side) < 3 || length(right_side) < 3)
		return null
	var/turf/opening_turf = select_divider_opening_turf(state, opening_candidates)
	if(!istype(opening_turf))
		return null
	wall_turfs -= opening_turf
	var/list/inner_side = length(left_side) <= length(right_side) ? left_side : right_side
	var/turf/target_turf = state.geometry.semantic_hub_turf || state.geometry.front_door_turf || room.focus_turf
	var/opening_dir = get_cardinal_dir_toward(opening_turf, target_turf, state.placement_dir)
	var/list/plan_data = list(
		"wall_turfs" = wall_turfs,
		"inner_turfs" = inner_side,
		"opening_turf" = opening_turf,
		"opening_dir" = opening_dir,
		"score" = length(wall_turfs) * 20 + min(length(inner_side), 8) * 15,
	)
	return plan_data

/datum/world_edit_generator/building_layout/proc/select_room_first_internal_door_turf(datum/world_edit_building_layout_state/state, list/edge_turfs, datum/world_edit_building_room/room)
	var/turf/best_turf = null
	var/best_score = -999999999
	var/turf/target_turf = state.geometry.semantic_hub_turf || state.geometry.front_door_turf || room?.focus_turf
	for(var/turf/edge_turf as anything in edge_turfs)
		if(!istype(edge_turf) || state.geometry.reserved_lookup[edge_turf] || state.geometry.door_dirs[edge_turf])
			continue
		var/score = 0
		if(state.geometry.boundary_lookup[edge_turf])
			score -= 50000
		if(istype(target_turf))
			score -= abs(edge_turf.x - target_turf.x) + abs(edge_turf.y - target_turf.y)
		if(!istype(best_turf) || score > best_score)
			best_turf = edge_turf
			best_score = score
	return best_turf

/datum/world_edit_generator/building_layout/proc/select_room_first_internal_door_turf_scored(datum/world_edit_building_layout_state/state, list/edge_turfs, list/edge_scores, datum/world_edit_building_room/room, list/pair_lookup)
	var/turf/best_turf = null
	var/best_score = -999999999
	var/turf/target_turf = state.geometry.semantic_hub_turf || state.geometry.front_door_turf || room?.focus_turf
	for(var/turf/edge_turf as anything in edge_turfs)
		if(!istype(edge_turf) || state.geometry.reserved_lookup[edge_turf] || state.geometry.door_dirs[edge_turf])
			continue
		var/score = (edge_scores[edge_turf] || 0) * 1000
		if(state.geometry.boundary_lookup[edge_turf])
			score -= 50000
		var/turf/pair_turf = pair_lookup ? pair_lookup[edge_turf] : null
		if(istype(pair_turf) && state.geometry.boundary_lookup[pair_turf])
			score -= 50000
		if(istype(target_turf))
			score -= abs(edge_turf.x - target_turf.x) + abs(edge_turf.y - target_turf.y)
		if(!istype(best_turf) || score > best_score)
			best_turf = edge_turf
			best_score = score
	return best_turf

/datum/world_edit_generator/building_layout/proc/ensure_room_first_required_room_access(datum/world_edit_building_layout_state/state)
	if(!istype(state) || !istype(state.semantic_plan))
		return
	for(var/datum/world_edit_building_room/room as anything in state.geometry.solved_rooms)
		if(!istype(room))
			continue
		var/datum/world_edit_building_zone_spec/zone_spec = state.semantic_plan.get_zone_spec(room.zone_id)
		if(!istype(zone_spec))
			continue
		if(building_room_has_internal_door(state, room))
			continue
		var/list/opening = select_room_first_shared_boundary_opening(state, room)
		var/turf/opening_turf = opening ? opening["opening_turf"] : null
		if(!istype(opening_turf))
			opening = get_hard_fallback_shared_boundary_opening(state, room)
			opening_turf = opening ? opening["opening_turf"] : null
			if(!istype(opening_turf))
				if(zone_spec.required)
					state.validation.mandatory_room_no_access_count++
					state.add_error("Required room '[room.zone_id]' has no semantic shared-wall door candidate and fallback failed.")
				continue
		apply_room_first_shared_boundary_opening(state, room, opening)

/datum/world_edit_generator/building_layout/proc/building_room_has_internal_door(datum/world_edit_building_layout_state/state, datum/world_edit_building_room/room)
	if(!istype(state) || !istype(room))
		return FALSE
	for(var/turf/door_turf as anything in state.geometry.door_turfs)
		if(!istype(door_turf) || !(door_turf in room.turfs))
			continue
		var/opening_dir = state.geometry.door_dirs[door_turf]
		if(!(opening_dir in GLOB.cardinals))
			continue
		var/turf/pair_turf = get_step(door_turf, opening_dir)
		if(!istype(pair_turf) || !state.geometry.footprint_lookup[pair_turf])
			pair_turf = get_step(door_turf, turn(opening_dir, 180))
		var/pair_zone_id = state.get_zone(pair_turf)
		if(length(pair_zone_id) && pair_zone_id != room.zone_id)
			return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/get_hard_fallback_shared_boundary_opening(datum/world_edit_building_layout_state/state, datum/world_edit_building_room/room)
	if(!istype(state) || !istype(room))
		return null
	var/list/best_opening = null
	var/best_score = -999999999
	for(var/turf/room_turf as anything in room.turfs)
		if(!istype(room_turf) || state.geometry.reserved_lookup[room_turf])
			continue
		for(var/check_dir in GLOB.cardinals)
			var/turf/nearby_turf = get_step(room_turf, check_dir)
			if(!state.geometry.footprint_lookup[nearby_turf])
				continue
			var/datum/world_edit_building_room/nearby_room = state.get_room_for_turf(nearby_turf)
			if(istype(nearby_room) && nearby_room == room)
				continue
			var/target_zone_id = istype(nearby_room) ? nearby_room.zone_id : state.get_zone(nearby_turf)
			if(!length(target_zone_id) || target_zone_id == room.zone_id)
				continue
			var/score = 100
			score -= abs(room_turf.x - (state.geometry.semantic_hub_turf?.x || room_turf.x)) + abs(room_turf.y - (state.geometry.semantic_hub_turf?.y || room_turf.y))
			if(score > best_score)
				best_opening = list(
					"opening_turf" = room_turf,
					"pair_turf" = nearby_turf,
					"opening_dir" = check_dir,
					"target_zone_id" = target_zone_id,
				)
				best_score = score
	return best_opening


/datum/world_edit_generator/building_layout/proc/apply_room_first_shared_boundary_opening(datum/world_edit_building_layout_state/state, datum/world_edit_building_room/room, list/opening)
	if(!istype(state) || !istype(room) || !islist(opening))
		return FALSE
	var/turf/opening_turf = opening["opening_turf"]
	if(!istype(opening_turf))
		return FALSE
	var/opening_dir = opening["opening_dir"]
	var/turf/pair_turf = opening["pair_turf"]
	if(istype(pair_turf))
		state.geometry.wall_lookup -= pair_turf
		state.geometry.internal_wall_turfs -= pair_turf
		state.geometry.boundary_lookup[pair_turf] = FALSE
	state.geometry.wall_lookup -= opening_turf
	state.geometry.internal_wall_turfs -= opening_turf
	state.geometry.boundary_lookup[opening_turf] = FALSE
	state.append_unique_turf(state.geometry.door_turfs, opening_turf)
	state.geometry.door_dirs[opening_turf] = opening_dir || get_cardinal_dir_toward(opening_turf, state.geometry.semantic_hub_turf || state.geometry.front_door_turf, state.placement_dir)
	state.add_zone(opening_turf, room.zone_id)
	state.validation.door_reports += list(list(
		"turf" = opening_turf,
		"dir" = state.geometry.door_dirs[opening_turf],
		"kind" = "shared_boundary_adjacency_door",
		"room_id" = room.id,
		"zone_id" = room.zone_id,
		"target_zone_id" = opening["target_zone_id"],
	))
	return TRUE


/datum/world_edit_generator/building_layout/proc/select_room_first_shared_boundary_opening(datum/world_edit_building_layout_state/state, datum/world_edit_building_room/room)
	if(!istype(state) || !istype(room))
		return null
	var/list/best_opening = null
	var/best_score = -999999999
	for(var/turf/room_turf as anything in room.turfs)
		if(!istype(room_turf) || state.geometry.reserved_lookup[room_turf])
			continue
		for(var/check_dir in GLOB.cardinals)
			var/turf/nearby_turf = get_step(room_turf, check_dir)
			if(!state.geometry.footprint_lookup[nearby_turf])
				continue
			var/datum/world_edit_building_room/nearby_room = state.get_room_for_turf(nearby_turf)
			if(istype(nearby_room) && nearby_room == room)
				continue
			var/target_zone_id = istype(nearby_room) ? nearby_room.zone_id : state.get_zone(nearby_turf)
			if(!length(target_zone_id) || target_zone_id == room.zone_id)
				continue
			if(!room_first_zones_should_connect(state, room.zone_id, target_zone_id))
				continue
			var/score = 1000 + room_first_get_zone_adjacency_score(state, room.zone_id, target_zone_id)
			score -= abs(room_turf.x - (state.geometry.semantic_hub_turf?.x || room_turf.x)) + abs(room_turf.y - (state.geometry.semantic_hub_turf?.y || room_turf.y))
			if(score > best_score)
				best_opening = list(
					"opening_turf" = room_turf,
					"pair_turf" = nearby_turf,
					"opening_dir" = check_dir,
					"target_zone_id" = target_zone_id,
				)
				best_score = score
	return best_opening


/datum/world_edit_generator/building_layout/proc/room_first_zones_should_connect(datum/world_edit_building_layout_state/state, zone_a, zone_b)
	if(!istype(state) || !istype(state.semantic_plan))
		return FALSE
	if(!length("[zone_a]") || !length("[zone_b]") || zone_a == zone_b)
		return FALSE
	for(var/datum/world_edit_building_adjacency_rule/rule as anything in state.semantic_plan.adjacency_rules)
		if(!istype(rule) || !rule.required)
			continue
		if((rule.zone_a == zone_a && rule.zone_b == zone_b) || (rule.zone_a == zone_b && rule.zone_b == zone_a))
			return TRUE
	return (zone_a == state.semantic_plan.hub_zone_id || zone_b == state.semantic_plan.hub_zone_id || zone_a == state.semantic_plan.entry_zone_id || zone_b == state.semantic_plan.entry_zone_id)


/datum/world_edit_generator/building_layout/proc/room_first_get_zone_adjacency_score(datum/world_edit_building_layout_state/state, zone_a, zone_b)
	if(!istype(state) || !istype(state.semantic_plan))
		return 0
	for(var/datum/world_edit_building_adjacency_rule/rule as anything in state.semantic_plan.adjacency_rules)
		if(!istype(rule) || !rule.required)
			continue
		if((rule.zone_a == zone_a && rule.zone_b == zone_b) || (rule.zone_a == zone_b && rule.zone_b == zone_a))
			return 1000
	if(zone_a == state.semantic_plan.hub_zone_id || zone_b == state.semantic_plan.hub_zone_id)
		return 400
	if(zone_a == state.semantic_plan.entry_zone_id || zone_b == state.semantic_plan.entry_zone_id)
		return 200
	return 0

/datum/world_edit_generator/building_layout/proc/build_room_first_room_boundary_walls(datum/world_edit_building_layout_state/state)
	var/list/seen_edges = list()
	for(var/turf/floor_turf as anything in state.geometry.interior)
		var/datum/world_edit_building_room/source_room = state.get_room_for_turf(floor_turf)
		if(!istype(source_room) || state.geometry.corridor_lookup[floor_turf] || state.geometry.wall_lookup[floor_turf] || state.geometry.door_dirs[floor_turf])
			continue
		for(var/check_dir in GLOB.cardinals)
			var/turf/nearby_turf = get_step(floor_turf, check_dir)
			if(!state.geometry.footprint_lookup[nearby_turf])
				continue
			var/datum/world_edit_building_room/nearby_room = state.get_room_for_turf(nearby_turf)
			var/nearby_zone_id = istype(nearby_room) ? nearby_room.zone_id : state.get_zone(nearby_turf)
			if(state.geometry.corridor_lookup[nearby_turf] || state.geometry.door_dirs[nearby_turf])
				continue
			if(istype(nearby_room) && nearby_room == source_room)
				continue
			if(!length(nearby_zone_id))
				continue
			if(nearby_zone_id == source_room.zone_id)
				continue
			var/edge_key = "[min(floor_turf.x, nearby_turf.x)],[min(floor_turf.y, nearby_turf.y)]|[max(floor_turf.x, nearby_turf.x)],[max(floor_turf.y, nearby_turf.y)]"
			if(seen_edges[edge_key])
				continue
			seen_edges[edge_key] = TRUE
			if(state.geometry.reserved_lookup[floor_turf] || state.geometry.door_dirs[floor_turf])
				continue
			var/datum/world_edit_building_zone_spec/source_zone_spec = state.semantic_plan?.get_zone_spec(source_room.zone_id)
			var/datum/world_edit_building_zone_spec/nearby_zone_spec = state.semantic_plan?.get_zone_spec(nearby_zone_id)
			if((istype(source_zone_spec) && source_zone_spec.required) || (istype(nearby_zone_spec) && nearby_zone_spec.required))
				if(!room_first_boundary_requires_separator(state, source_zone_spec, nearby_zone_spec))
					continue
			state.add_internal_wall(floor_turf)

/datum/world_edit_generator/building_layout/proc/room_first_boundary_requires_separator(datum/world_edit_building_layout_state/state, datum/world_edit_building_zone_spec/source_zone_spec, datum/world_edit_building_zone_spec/nearby_zone_spec)
	if(!istype(source_zone_spec) || !istype(nearby_zone_spec))
		return FALSE
	if(source_zone_spec.divider_mode == "room" || nearby_zone_spec.divider_mode == "room")
		return TRUE
	if(source_zone_spec.privacy_sensitive || nearby_zone_spec.privacy_sensitive)
		return TRUE
	if(length(source_zone_spec.privacy_class) || length(nearby_zone_spec.privacy_class))
		return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/prepare_building_local_metrics(datum/world_edit_building_layout_state/state)
	state.geometry.max_front_depth = 1
	state.geometry.max_lateral_abs = 1
	for(var/turf/interior_turf as anything in state.geometry.interior)
		var/depth = world_edit_building_front_depth(interior_turf, state.geometry.bounds, state.placement_dir)
		var/lateral = world_edit_building_lateral_offset(interior_turf, state.geometry.bounds, state.placement_dir)
		state.geometry.max_front_depth = max(state.geometry.max_front_depth, depth)
		state.geometry.max_lateral_abs = max(state.geometry.max_lateral_abs, abs(lateral))

/datum/world_edit_generator/building_layout/proc/get_building_front_percent(datum/world_edit_building_layout_state/state, turf/target_turf)
	if(!istype(state) || !istype(target_turf))
		return 0
	return round((world_edit_building_front_depth(target_turf, state.geometry.bounds, state.placement_dir) * 100) / max(state.geometry.max_front_depth, 1))

/datum/world_edit_generator/building_layout/proc/get_building_lateral_percent(datum/world_edit_building_layout_state/state, turf/target_turf)
	if(!istype(state) || !istype(target_turf))
		return 0
	return round((world_edit_building_lateral_offset(target_turf, state.geometry.bounds, state.placement_dir) * 100) / max(state.geometry.max_lateral_abs, 1))

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
	for(var/turf/interior_turf as anything in state.geometry.interior)
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
	state.validation.rectangular_region_candidate_count = 0
	for(var/datum/world_edit_building_region_spec/region_spec as anything in state.semantic_plan.region_specs)
		if(!istype(region_spec))
			continue
		var/list/spec_candidates = build_rectangular_region_candidates_for_spec(state, region_spec)
		for(var/datum/world_edit_building_solved_region/candidate as anything in spec_candidates)
			if(istype(candidate) && length(candidate.turfs))
				candidates += candidate
				state.validation.rectangular_region_candidate_count++
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
			for(var/turf/interior_turf as anything in state.geometry.interior)
				union_candidate.turfs += interior_turf
				extend_solved_region_bounds(union_candidate, interior_turf)
			state.validation.degraded_region_fallback_count++
			state.add_degraded_region_report(list(
				"zone" = zone_spec.id,
				"reason" = "no_region_candidates",
				"fallback_area" = length(union_candidate.turfs),
			))
		else if(!has_viable_candidate)
			union_candidate.priority = -650
			state.validation.degraded_region_fallback_count++
			state.add_degraded_region_report(list(
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
		if(state.geometry.boundary_lookup[get_step(candidate_turf, check_dir)])
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
			if(!istype(candidate_turf) || claimed_lookup[candidate_turf] || result_lookup[candidate_turf] || state.geometry.boundary_lookup[candidate_turf] || state.geometry.wall_lookup[candidate_turf])
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
			if(state.geometry.boundary_lookup[get_step(candidate_turf, check_dir)])
				return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/region_candidate_touches_entry(datum/world_edit_building_layout_state/state, list/candidate_turfs)
	for(var/turf/candidate_turf as anything in candidate_turfs)
		if(!istype(candidate_turf))
			continue
		if(candidate_turf == state.geometry.front_door_turf || get_dist(candidate_turf, state.geometry.front_door_turf) <= 2)
			return TRUE
		if(get_building_front_percent(state, candidate_turf) <= 25)
			return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/region_candidate_respects_privacy(datum/world_edit_building_layout_state/state, list/candidate_turfs)
	for(var/turf/candidate_turf as anything in candidate_turfs)
		if(!istype(candidate_turf) || !istype(state.geometry.front_door_turf))
			continue
		if(get_dist(candidate_turf, state.geometry.front_door_turf) <= 2)
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
		if(state.geometry.boundary_lookup[nearby_turf])
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
		if(!istype(candidate_turf) || state.geometry.boundary_lookup[candidate_turf] || state.geometry.wall_lookup[candidate_turf])
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
	state.validation.region_claim_count = 0
	state.validation.region_claim_reports.Cut()
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
		state.validation.region_claim_count += after_count
		var/list/report = list(
			"zone" = zone_spec.id,
			"region" = selected_region.id,
			"target_area" = target_area,
			"seed_area" = before_count,
			"claimed_area" = after_count,
			"added_area" = max(after_count - before_count, 0),
		)
		state.validation.region_claim_reports += list(report)

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
			if(!istype(candidate_turf) || state.geometry.boundary_lookup[candidate_turf])
				continue
			if(!length(state.get_zone(candidate_turf)))
				state.add_zone(candidate_turf, candidate.zone_id)
	for(var/turf/interior_turf as anything in state.geometry.interior)
		if(!length(state.get_zone(interior_turf)))
			state.add_zone(interior_turf, state.semantic_plan.primary_zone_id || state.archetype.primary_zone)

/datum/world_edit_generator/building_layout/proc/rebuild_solved_regions_from_zone_assignments(datum/world_edit_building_layout_state/state, list/region_candidates)
	state.geometry.solved_regions.Cut()
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
			state.geometry.solved_regions += solved_region
			seen_region_ids[candidate.id] = TRUE

/datum/world_edit_generator/building_layout/proc/solve_building_semantic_regions(datum/world_edit_building_layout_state/state)
	if(!istype(state) || !istype(state.semantic_plan))
		return
	prepare_building_local_metrics(state)
	state.clear_zones()
	state.geometry.solved_regions.Cut()

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
		state.validation.degraded_region_fallback_count++
		state.add_degraded_region_report(list(
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
	for(var/turf/candidate as anything in state.geometry.interior)
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
	if(state.geometry.boundary_lookup[candidate] || state.geometry.wall_lookup[candidate])
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
		if(state.geometry.boundary_lookup[nearby_turf])
			boundary_neighbors++
		if(state.geometry.reserved_lookup[nearby_turf])
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
	var/center_x = (state.geometry.bounds["min_x"] + state.geometry.bounds["max_x"]) / 2
	var/center_y = (state.geometry.bounds["min_y"] + state.geometry.bounds["max_y"]) / 2
	var/turf/best_turf = null
	var/best_score = -999999999
	for(var/turf/zone_turf as anything in zone_turfs)
		if(!istype(zone_turf) || state.geometry.wall_lookup[zone_turf])
			continue
		var/score = 0
		score -= abs(zone_turf.x - center_x) + abs(zone_turf.y - center_y)
		if(state.geometry.reserved_lookup[zone_turf])
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
	for(var/datum/world_edit_building_solved_region/solved_region as anything in state.geometry.solved_regions)
		var/turf/region_focus = select_zone_focus_turf(state, solved_region.zone_id)
		if(istype(region_focus))
			solved_region.focus_turf = region_focus

/datum/world_edit_generator/building_layout/proc/build_building_provisional_floor_lookup(datum/world_edit_building_layout_state/state)
	var/list/provisional_floor_turfs = list()
	var/list/provisional_lookup = list()
	for(var/turf/interior_turf as anything in state.geometry.interior)
		if(!state.geometry.wall_lookup[interior_turf])
			append_unique_turf(provisional_floor_turfs, provisional_lookup, interior_turf)
	for(var/turf/door_turf as anything in state.geometry.door_turfs)
		append_unique_turf(provisional_floor_turfs, provisional_lookup, door_turf)
	return provisional_lookup

/datum/world_edit_generator/building_layout/proc/build_building_preliminary_circulation(datum/world_edit_building_layout_state/state)
	if(!istype(state) || !istype(state.semantic_plan))
		return
	state.geometry.floor_lookup = build_building_provisional_floor_lookup(state)
	var/center_x = (state.geometry.bounds["min_x"] + state.geometry.bounds["max_x"]) / 2
	var/center_y = (state.geometry.bounds["min_y"] + state.geometry.bounds["max_y"]) / 2
	state.geometry.center_turf = select_center_floor_turf(state.geometry.interior, center_x, center_y) || state.geometry.front_door_turf
	refresh_building_zone_foci(state)
	state.geometry.semantic_hub_turf = state.get_zone_focus(state.semantic_plan.hub_zone_id) || state.geometry.center_turf

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
		if(!istype(zone_turf) || state.geometry.boundary_lookup[zone_turf] || state.geometry.door_dirs[zone_turf] || state.geometry.wall_lookup[zone_turf])
			continue
		if(zone_turf.x == min_x || zone_turf.x == max_x || zone_turf.y == min_y || zone_turf.y == max_y)
			if(!state.geometry.reserved_lookup[zone_turf])
				perimeter += zone_turf
		else
			inner_turfs += zone_turf
	if(length(perimeter) < 3 || !length(inner_turfs))
		return null
	var/turf/opening_turf = select_divider_opening_turf(state, perimeter)
	if(!istype(opening_turf))
		return null
	var/datum/world_edit_building_divider_plan/divider_plan = new("box_[zone_spec.id]_[length(state.geometry.divider_plans) + 1]", state.semantic_plan.primary_zone_id || state.semantic_plan.hub_zone_id, zone_spec.id)
	divider_plan.opening_turfs += opening_turf
	divider_plan.opening_dirs[opening_turf] = get_cardinal_dir_toward(opening_turf, state.geometry.semantic_hub_turf || state.geometry.front_door_turf || state.geometry.center_turf, state.placement_dir)
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
		if(!istype(zone_turf) || state.geometry.wall_lookup[zone_turf] || state.geometry.reserved_lookup[zone_turf] || state.geometry.boundary_lookup[zone_turf] || state.geometry.door_dirs[zone_turf])
			continue
		for(var/check_dir in GLOB.cardinals)
			var/turf/nearby_turf = get_step(zone_turf, check_dir)
			if(!state.geometry.footprint_lookup[nearby_turf] || state.geometry.boundary_lookup[nearby_turf])
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
	var/turf/target_turf = state.geometry.semantic_hub_turf || state.geometry.front_door_turf || state.geometry.center_turf
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
		if(state.geometry.primary_route_turfs.Find(run_turf) || state.geometry.reserved_lookup[run_turf] || state.geometry.wall_lookup[run_turf] || state.geometry.door_dirs[run_turf])
			score -= 200
		if(run_turf == state.geometry.front_door_turf)
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
	divider_plan.opening_dirs[opening_turf] = run.outside_dirs[opening_turf] || get_cardinal_dir_toward(opening_turf, state.geometry.semantic_hub_turf || state.geometry.front_door_turf, state.placement_dir)
	var/max_wall_count = max(1, length(run.wall_turfs) - 1)
	if(zone_spec.divider_mode == "nook")
		max_wall_count = min(max_wall_count, max(1, round(length(run.wall_turfs) * 2 / 3)))
	var/placed_walls = 0
	for(var/turf/run_turf as anything in run.wall_turfs)
		if(!istype(run_turf) || run_turf == opening_turf || state.geometry.reserved_lookup[run_turf] || state.geometry.door_dirs[run_turf] || state.geometry.wall_lookup[run_turf])
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
	var/list/source_floor_turfs = length(state.geometry.floor_turfs) ? state.geometry.floor_turfs : state.geometry.floor_lookup
	for(var/turf/floor_turf as anything in source_floor_turfs)
		if(!istype(floor_turf) || state.geometry.wall_lookup[floor_turf] || planned_wall_lookup[floor_turf])
			continue
		floor_lookup[floor_turf] = TRUE
	for(var/turf/opening_turf as anything in divider_plan.opening_turfs)
		if(istype(opening_turf) && state.geometry.footprint_lookup[opening_turf])
			floor_lookup[opening_turf] = TRUE
	return floor_lookup

/datum/world_edit_generator/building_layout/proc/build_reachable_lookup_from_floor_lookup(datum/world_edit_building_layout_state/state, list/floor_lookup)
	var/list/reachable = list()
	var/list/queue = list()
	var/list/start_doors = list()
	for(var/turf/door_turf as anything in state.geometry.door_turfs)
		if(state.geometry.boundary_lookup[door_turf])
			start_doors += door_turf
	if(!length(start_doors))
		start_doors = state.geometry.door_turfs
	for(var/turf/door_turf as anything in start_doors)
		if(floor_lookup[door_turf] && !reachable[door_turf])
			reachable[door_turf] = TRUE
			queue += door_turf
		var/door_dir = state.geometry.door_dirs[door_turf] || state.placement_dir
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
		if(!istype(opening_turf) || state.geometry.wall_lookup[opening_turf] || state.geometry.boundary_lookup[opening_turf] || state.geometry.door_dirs[opening_turf])
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
	var/turf/target_turf = state.geometry.semantic_hub_turf || state.geometry.front_door_turf || state.geometry.center_turf
	for(var/turf/candidate as anything in candidate_turfs)
		if(!istype(candidate) || state.geometry.reserved_lookup[candidate] || state.geometry.wall_lookup[candidate] || state.geometry.boundary_lookup[candidate] || state.geometry.door_dirs[candidate])
			continue
		var/score = 0
		if(istype(target_turf))
			score -= abs(candidate.x - target_turf.x) + abs(candidate.y - target_turf.y)
		if(candidate == state.geometry.front_door_turf)
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
		if((state.geometry.bounds["width"] || 0) < nested_spec.min_width || (state.geometry.bounds["height"] || 0) < nested_spec.min_height)
			continue
		var/inner_width = max(3, round(nested_spec.min_width / 3))
		var/inner_height = max(3, round(nested_spec.min_height / 3))
		if(make_room_in_room(state, nested_spec.outer_zone_id, nested_spec.inner_zone_id, nested_spec.margin, inner_width, inner_height))
			state.validation.nested_room_count++

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
			var/turf/check_turf = locate(x, y, state.geometry.bounds["z"])
			if(!state.geometry.footprint_lookup[check_turf] || state.geometry.boundary_lookup[check_turf] || state.geometry.wall_lookup[check_turf] || state.geometry.door_dirs[check_turf])
				return null
			if(state.get_zone(check_turf) != "[outer_zone_id]")
				return null
			var/is_perimeter = (x == x1 || x == x2 || y == y1 || y == y2)
			if(is_perimeter)
				if(state.geometry.reserved_lookup[check_turf])
					return null
				perimeter_turfs += check_turf
				var/score = 0
				if(istype(state.geometry.front_door_turf))
					score -= abs(check_turf.x - state.geometry.front_door_turf.x) + abs(check_turf.y - state.geometry.front_door_turf.y)
				if(istype(state.geometry.semantic_hub_turf))
					score -= round((abs(check_turf.x - state.geometry.semantic_hub_turf.x) + abs(check_turf.y - state.geometry.semantic_hub_turf.y)) / 2)
				if(!istype(door_turf) || score > best_door_score)
					door_turf = check_turf
					best_door_score = score
			else
				inner_turfs += check_turf
	for(var/x in (x1 - margin) to (x2 + margin))
		for(var/y in (y1 - margin) to (y2 + margin))
			if(x >= x1 && x <= x2 && y >= y1 && y <= y2)
				continue
			var/turf/margin_turf = locate(x, y, state.geometry.bounds["z"])
			if(!istype(margin_turf) || !state.geometry.footprint_lookup[margin_turf])
				continue
			if(state.geometry.wall_lookup[margin_turf] || state.geometry.boundary_lookup[margin_turf])
				return null
	if(!istype(door_turf) || !length(perimeter_turfs) || !length(inner_turfs))
		return null
	for(var/turf/perimeter_turf as anything in perimeter_turfs)
		if(perimeter_turf != door_turf)
			wall_turfs += perimeter_turf
	var/turf/center_turf = locate(round((x1 + x2) / 2), round((y1 + y2) / 2), state.geometry.bounds["z"])
	var/door_dir = get_cardinal_dir_toward(door_turf, state.geometry.semantic_hub_turf || state.geometry.front_door_turf || center_turf, state.placement_dir)
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
	var/list/door_lookup = GLOB.world_edit_placement_shapes.world_edit_build_turf_lookup(state.geometry.door_turfs)
	var/list/window_lookup = GLOB.world_edit_placement_shapes.world_edit_build_turf_lookup(state.geometry.window_turfs)
	for(var/turf/footprint_turf as anything in state.geometry.footprint)
		if((state.geometry.boundary_lookup[footprint_turf] || state.geometry.wall_lookup[footprint_turf]) && !door_lookup[footprint_turf] && !window_lookup[footprint_turf])
			state.geometry.wall_lookup[footprint_turf] = TRUE
		else
			state.append_unique_turf(state.geometry.floor_turfs, footprint_turf)
	state.geometry.adjacent_wall_dirs_by_turf.Cut()
	state.geometry.floor_lookup = GLOB.world_edit_placement_shapes.world_edit_build_turf_lookup(state.geometry.floor_turfs)
	var/center_x = (state.geometry.bounds["min_x"] + state.geometry.bounds["max_x"]) / 2
	var/center_y = (state.geometry.bounds["min_y"] + state.geometry.bounds["max_y"]) / 2
	state.geometry.center_turf = select_center_floor_turf(state.geometry.floor_turfs, center_x, center_y) || state.geometry.front_door_turf
	refresh_building_zone_foci(state)
	state.geometry.semantic_hub_turf = state.get_zone_focus(state.semantic_plan?.hub_zone_id) || state.geometry.center_turf


