/datum/world_edit_generator/building_layout/proc/build_building_layout_ownership_partition_graph(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate)
	var/datum/world_edit_building_layout_state/state = context?.state
	if(!istype(state) || !istype(candidate))
		return FALSE
	candidate.ownership_by_turf = list()
	candidate.partition_edges = list()
	candidate.reserved_partition_wall_lookup = list()
	for(var/datum/world_edit_building_layout_room_plan/room_plan as anything in candidate.room_plans)
		if(!istype(room_plan))
			continue
		for(var/turf/room_turf as anything in room_plan.turfs)
			candidate.ownership_by_turf[room_turf] = room_plan.id
	for(var/turf/route_turf as anything in candidate.route_turfs)
		candidate.ownership_by_turf[route_turf] = candidate.route_owner_by_turf[route_turf] || "route"
	var/list/seen_partition_turfs = list()
	var/open_bay_partition_skip_count = 0
	for(var/datum/world_edit_building_layout_room_plan/room_plan as anything in candidate.room_plans)
		if(!istype(room_plan))
			continue
		var/datum/world_edit_building_layout_room_contract/room_contract = context.program_contract?.get_room_contract(room_plan.contract_id)
		var/datum/world_edit_building_layout_influence_zone/room_seed_zone = get_building_layout_contract_seed_zone(candidate.region_candidate, room_plan.contract_id)
		var/room_is_named_open_bay = room_seed_zone?.role == "open_bay"
		if(room_plan.id == context.program_contract?.topology_graph?.root_node_id || room_is_named_open_bay)
			state.add_stage_report("layout_partition_room_policy", "ok", null, list("candidate_id" = candidate.id, "room_id" = room_plan.id, "spatial_kind" = room_plan.spatial_kind, "seed_role" = room_seed_zone?.role, "named_open_bay" = room_is_named_open_bay, "pattern_id" = candidate.pattern_id, "root_id" = candidate.topology_graph?.root_node_id))
		for(var/turf/room_turf as anything in room_plan.turfs)
			for(var/check_dir in GLOB.cardinals)
				var/turf/wall_turf = get_step(room_turf, check_dir)
				if(!istype(wall_turf) || room_plan.turf_lookup[wall_turf] || state.geometry.boundary_lookup[wall_turf] || !state.geometry.footprint_lookup[wall_turf])
					continue
				var/turf/opposite_turf = get_step(wall_turf, check_dir)
				var/other_owner = candidate.ownership_by_turf[opposite_turf]
				var/datum/world_edit_building_layout_room_contract/other_contract = context.program_contract?.get_room_contract("[other_owner]")
				var/partition_kind = get_building_layout_partition_edge_kind(candidate, room_plan.id, "[other_owner]")
				var/is_named_open_bay = room_is_named_open_bay || room_plan.spatial_kind == WORLD_EDIT_BUILDING_SPACE_OPEN_BAY || (candidate.pattern_id == "open_bay_perimeter" && room_plan.id == candidate.topology_graph?.root_node_id)
				if(is_named_open_bay)
					if(!other_owner || (istype(other_contract) && !other_contract.counts_toward_target) || (partition_kind in list(WORLD_EDIT_BUILDING_EDGE_ROUTE, WORLD_EDIT_BUILDING_EDGE_OPEN_MERGE)))
						open_bay_partition_skip_count++
						continue
				var/partition_required = !!other_owner || (istype(room_contract) && (room_contract.partition_policy in list(WORLD_EDIT_BUILDING_PARTITION_CLOSED, WORLD_EDIT_BUILDING_PARTITION_SECURE)))
				if(!partition_required)
					continue
				candidate.reserved_partition_wall_lookup[wall_turf] = TRUE
				if(seen_partition_turfs[wall_turf])
					continue
				seen_partition_turfs[wall_turf] = TRUE
				candidate.partition_edges += list(list(
					"wall_turf" = wall_turf,
					"wall_x" = wall_turf.x,
					"wall_y" = wall_turf.y,
					"wall_z" = wall_turf.z,
					"owner_a" = room_plan.id,
					"owner_b" = other_owner ? "[other_owner]" : "negative_space",
					"owner_b_raw" = "[other_owner]",
					"owner_b_is_null" = isnull(other_owner),
					"kind" = partition_kind,
				))
	if(open_bay_partition_skip_count)
		state.add_stage_report("layout_partition_open_bay_skips", "ok", null, list("candidate_id" = candidate.id, "skip_count" = open_bay_partition_skip_count))
	materialize_building_layout_partition_corner_joins(state, candidate)
	return TRUE

/datum/world_edit_generator/building_layout/proc/materialize_building_layout_partition_corner_joins(datum/world_edit_building_layout_state/state, datum/world_edit_building_layout_candidate/candidate)
	if(!istype(state) || !istype(candidate))
		return
	var/list/seen_corner_joins = list()
	var/list/corner_dir_pairs = list(list(NORTH, EAST), list(NORTH, WEST), list(SOUTH, EAST), list(SOUTH, WEST))
	for(var/datum/world_edit_building_layout_room_plan/room_plan as anything in candidate.room_plans)
		if(!istype(room_plan))
			continue
		for(var/turf/room_turf as anything in room_plan.turfs)
			for(var/list/dir_pair as anything in corner_dir_pairs)
				var/dir_a = dir_pair[1]
				var/dir_b = dir_pair[2]
				var/turf/wall_a = get_step(room_turf, dir_a)
				var/turf/wall_b = get_step(room_turf, dir_b)
				if(!candidate.reserved_partition_wall_lookup[wall_a] || !candidate.reserved_partition_wall_lookup[wall_b])
					continue
				var/turf/corner_join = get_step(wall_a, dir_b)
				if(!istype(corner_join) || seen_corner_joins[corner_join] || state.geometry.boundary_lookup[corner_join] || !state.geometry.footprint_lookup[corner_join] || candidate.ownership_by_turf[corner_join])
					continue
				seen_corner_joins[corner_join] = TRUE
				candidate.reserved_partition_wall_lookup[corner_join] = TRUE
				candidate.partition_edges += list(list(
					"wall_turf" = corner_join,
					"wall_x" = corner_join.x,
					"wall_y" = corner_join.y,
					"wall_z" = corner_join.z,
					"owner_a" = room_plan.id,
					"owner_b" = "corner_join",
					"kind" = WORLD_EDIT_BUILDING_EDGE_SHARED,
				))

/datum/world_edit_generator/building_layout/proc/get_building_layout_partition_edge_kind(datum/world_edit_building_layout_candidate/candidate, owner_a, owner_b)
	if(!istype(candidate))
		return WORLD_EDIT_BUILDING_EDGE_SHARED
	if(owner_a == "route" || owner_b == "route")
		return WORLD_EDIT_BUILDING_EDGE_ROUTE
	for(var/datum/world_edit_building_layout_topology_edge/edge as anything in candidate.topology_graph?.get_edges_for(owner_a))
		if(!istype(edge))
			continue
		var/other_id = edge.from_id == owner_a ? edge.to_id : edge.from_id
		if(other_id == owner_b)
			return edge.kind
	return WORLD_EDIT_BUILDING_EDGE_SHARED
