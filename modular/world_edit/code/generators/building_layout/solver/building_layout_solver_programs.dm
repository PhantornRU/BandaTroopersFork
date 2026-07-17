#define WORLD_EDIT_BUILDING_MAX_LAYOUT_CANDIDATES 24
#define WORLD_EDIT_BUILDING_MAX_ROOM_CANDIDATES 128
#define WORLD_EDIT_BUILDING_MAX_ROUTE_EXPANSIONS 4096
#define WORLD_EDIT_BUILDING_MAX_MODULE_ANCHORS 64
#define WORLD_EDIT_BUILDING_MAX_MODULE_CANDIDATES 32

/datum/world_edit_generator/building_layout/proc/build_building_layout_program_contract(datum/world_edit_building_layout_state/state)
	if(!istype(state) || !istype(state.archetype) || !istype(state.semantic_plan))
		return null
	var/datum/world_edit_building_layout_program_contract/program = new
	program.id = state.archetype.id
	program.allowed_layout_patterns = state.archetype.layout_families.Copy()
	program.max_layout_candidates = WORLD_EDIT_BUILDING_MAX_LAYOUT_CANDIDATES
	var/list/selected_zone_specs = select_building_layout_room_zone_specs(state)
	if(!islist(selected_zone_specs) || !length(selected_zone_specs))
		state.add_error("Program contract '[program.id]' has no active room zones.")
		return null
	var/target_room_count = round(text2num("[state.config["target_room_count"]]") || 0)
	if(target_room_count <= 0)
		for(var/datum/world_edit_building_zone_spec/default_zone as anything in selected_zone_specs)
			if(istype(default_zone) && default_zone.counts_toward_target)
				target_room_count++
	var/required_zone_count = 0
	for(var/datum/world_edit_building_zone_spec/required_zone as anything in selected_zone_specs)
		if(istype(required_zone) && required_zone.required && required_zone.counts_toward_target)
			required_zone_count++
	if(target_room_count < required_zone_count)
		state.add_error("program.target_room_count_unreachable: requested [target_room_count], required [required_zone_count].")
		return null
	program.target_room_count = target_room_count
	program.target_functional_room_count = target_room_count
	var/list/room_zone_demands = build_building_layout_room_zone_demands(state, selected_zone_specs, target_room_count)
	var/functional_demand_count = 0
	for(var/datum/world_edit_building_zone_spec/demand_zone as anything in room_zone_demands)
		if(istype(demand_zone) && demand_zone.counts_toward_target)
			functional_demand_count++
	if(functional_demand_count != target_room_count)
		state.add_error("program.target_room_count_unreachable: requested [target_room_count], allocated [functional_demand_count] functional spaces.")
		return null
	var/list/zone_instance_counts = list()
	for(var/datum/world_edit_building_zone_spec/zone_spec as anything in room_zone_demands)
		if(!istype(zone_spec))
			continue
		var/instance_index = round(text2num("[zone_instance_counts[zone_spec.id]]") || 0) + 1
		zone_instance_counts[zone_spec.id] = instance_index
		var/datum/world_edit_building_layout_room_contract/room_contract = compile_building_layout_room_contract(state, zone_spec, instance_index, target_room_count)
		if(istype(room_contract))
			program.add_room_contract(room_contract)
	if(length(program.functional_room_contracts) != target_room_count)
		state.add_error("program.target_room_count_unreachable: compiled [length(program.functional_room_contracts)] of [target_room_count] functional room contracts.")
		return null
	for(var/datum/world_edit_building_layout_room_contract/circulation_contract as anything in program.circulation_contracts)
		if(istype(circulation_contract))
			program.min_circulation_area += circulation_contract.min_area
	compile_building_layout_connection_contracts(state, program)
	program.topology_graph = compile_building_layout_topology_graph(state, program)
	if(!istype(program.topology_graph) || !length(program.topology_graph.nodes))
		state.add_error("Program contract '[program.id]' has no functional topology graph.")
		return null
	compile_building_layout_scene_contracts(state, program)
	for(var/category as anything in state.semantic_plan.object_budgets)
		if(!is_building_infrastructure_category(category))
			program.global_scene_slot_limits["[category]"] = state.semantic_plan.object_budgets[category]
	reserve_building_layout_required_scene_identity_budget(program)
	return program

/datum/world_edit_generator/building_layout/proc/select_building_layout_room_zone_specs(datum/world_edit_building_layout_state/state)
	var/list/required_zones = list()
	var/list/optional_zones = list()
	for(var/datum/world_edit_building_zone_spec/zone_spec as anything in state.semantic_plan?.zone_specs)
		if(!istype(zone_spec))
			continue
		if(zone_spec.required)
			required_zones += zone_spec
		else
			optional_zones += zone_spec
	return required_zones + optional_zones

/datum/world_edit_generator/building_layout/proc/build_building_layout_room_zone_demands(datum/world_edit_building_layout_state/state, list/zone_specs, target_room_count)
	var/list/demands = list()
	var/list/functional_demands = list()
	var/list/optional = list()
	for(var/datum/world_edit_building_zone_spec/zone_spec as anything in zone_specs)
		if(!istype(zone_spec))
			continue
		if(!zone_spec.counts_toward_target)
			if(zone_spec.required)
				demands += zone_spec
			continue
		if(zone_spec.required)
			functional_demands += zone_spec
		else
			optional += zone_spec
	for(var/datum/world_edit_building_zone_spec/optional_zone as anything in optional)
		if(length(functional_demands) >= target_room_count)
			break
		functional_demands += optional_zone
	var/guard = 0
	while(length(functional_demands) < target_room_count && guard < 24)
		guard++
		var/datum/world_edit_building_zone_spec/repeat_zone = select_building_layout_repeat_zone(state, zone_specs, functional_demands)
		if(!istype(repeat_zone))
			break
		functional_demands += repeat_zone
	return functional_demands + demands

/datum/world_edit_generator/building_layout/proc/select_building_layout_repeat_zone(datum/world_edit_building_layout_state/state, list/zone_specs, list/current_demands)
	var/datum/world_edit_building_zone_spec/best = null
	var/best_score = -999999999
	var/list/instance_counts = list()
	for(var/datum/world_edit_building_zone_spec/current as anything in current_demands)
		if(istype(current))
			instance_counts[current.id] = round(text2num("[instance_counts[current.id]]") || 0) + 1
	for(var/datum/world_edit_building_zone_spec/zone_spec as anything in zone_specs)
		if(!istype(zone_spec) || !zone_spec.counts_toward_target)
			continue
		// The primary signature zone is unique program identity. Exact target-room
		// expansion must add support/private/service instances, not clone the
		// program centerpiece into a second fake primary room.
		if(zone_spec.id == state.archetype?.primary_zone)
			continue
		var/score = zone_spec.required ? 100 : 50
		score += zone_spec.min_area * 4
		switch(zone_spec.role)
			if("private", "storage", "service", "support", "secure")
				score += 180
			if("hub", "public", "public_med", "staging")
				score += 100
		for(var/datum/world_edit_building_region_spec/region_spec as anything in state.semantic_plan?.region_specs)
			if(istype(region_spec) && region_spec.zone_id == zone_spec.id)
				score += 35
		score -= round(text2num("[instance_counts[zone_spec.id]]") || 0) * 90
		if(!istype(best) || score > best_score)
			best = zone_spec
			best_score = score
	return best

/datum/world_edit_generator/building_layout/proc/compile_building_layout_room_contract(datum/world_edit_building_layout_state/state, datum/world_edit_building_zone_spec/zone_spec, instance_index, target_room_count)
	if(!istype(state) || !istype(zone_spec))
		return null
	var/usable_area = max(length(state.geometry.footprint) - length(state.geometry.boundary), 1)
	var/average_room_area = max(round(usable_area / max(target_room_count, 1)), zone_spec.min_area)
	var/min_area = max(zone_spec.min_area, (zone_spec.role in list("hub", "public", "public_med")) ? 9 : ((zone_spec.role in list("entry", "route", "choke")) ? 2 : 4))
	min_area = max(min_area, get_building_layout_zone_scene_min_area(state, zone_spec, instance_index))
	// Large explicit footprints must be substantially claimed by functional
	// rooms instead of leaving an object-poor unassigned moat around a compact
	// recipe. Standard/compact footprints keep a little more circulation slack.
	var/preferred_fill_ratio = usable_area >= 360 ? 1.0 : 0.75
	var/preferred_area = max(min_area, round(average_room_area * preferred_fill_ratio))
	var/max_area = max(preferred_area, round(average_room_area * 1.05))
	var/min_width = max(2, min(round(sqrt(min_area)), 5))
	var/requires_controlled_route_access = zone_spec.privacy_class != "public"
	if(requires_controlled_route_access)
		min_width = max(min_width, 3)
	var/min_height = max(2, round(min_area / max(min_width, 1)))
	if(requires_controlled_route_access)
		min_height = max(min_height, 3)
		min_area = max(min_area, min_width * min_height)
		preferred_area = max(preferred_area, min_area)
		max_area = max(max_area, min_area)
	if(zone_spec.role in list("hub", "public", "public_med"))
		min_width = max(min_width, 3)
		min_height = max(min_height, 3)
	var/max_width = max(min_width, min(12, round(state.geometry.bounds["width"]) - 2))
	var/max_height = max(min_height, min(12, round(state.geometry.bounds["height"]) - 2))
	var/room_id = instance_index > 1 ? "[zone_spec.id]_[instance_index]" : zone_spec.id
	var/datum/world_edit_building_layout_room_contract/room = new(room_id, zone_spec.role, zone_spec.id, zone_spec.required || zone_spec.counts_toward_target || instance_index > 1, min_area, preferred_area, max_area, min_width, min_height, max_width, max_height)
	room.instance_index = instance_index
	room.spatial_kind = zone_spec.spatial_kind
	room.counts_toward_target = zone_spec.counts_toward_target
	room.min_capacity_units = zone_spec.min_capacity_units
	room.capacity_kind = zone_spec.capacity_kind
	room.privacy_class = length("[zone_spec.privacy_class]") ? zone_spec.privacy_class : "semi_private"
	room.must_touch_route = zone_spec.must_touch_route
	room.max_aspect = (zone_spec.role in list("route", "staging")) ? 3.5 : 2.4
	room.target_aspect = (zone_spec.role in list("storage", "service")) ? 1.6 : 1.25
	room.anchor_tags = zone_spec.anchor_tags.Copy()
	room.window_policy = zone_spec.window_allowed ? "desired" : "forbidden"
	room.exterior_window_policy = room.window_policy
	configure_building_layout_partition_policy(room)
	room.required_scene_kinds = list()
	room.allowed_scene_kinds = list()
	return room

/datum/world_edit_generator/building_layout/proc/get_building_layout_zone_scene_min_area(datum/world_edit_building_layout_state/state, datum/world_edit_building_zone_spec/zone_spec, instance_index = 1)
	if(!istype(state) || !istype(zone_spec))
		return 0
	var/min_scene_area = 0
	for(var/datum/world_edit_building_cluster_spec/cluster_spec as anything in state.semantic_plan?.cluster_specs)
		if(!istype(cluster_spec) || !cluster_spec.required || is_building_infrastructure_category(cluster_spec.category))
			continue
		var/cluster_matches_zone = get_building_layout_cluster_zone_anchor_score(cluster_spec, zone_spec.id) > 0 || cluster_spec.optional_zone_id == zone_spec.id
		if(!cluster_matches_zone)
			continue
		var/datum/world_edit_building_cluster_spec/capacity_spec = cluster_spec
		if(instance_index > 1 && length(cluster_spec.compact_substitute_id))
			var/datum/world_edit_building_cluster_spec/compact_spec = state.semantic_plan?.get_cluster_spec_by_id(cluster_spec.compact_substitute_id)
			if(istype(compact_spec) && compact_spec.compact_substitute_only)
				capacity_spec = compact_spec
		var/effective_min_count = instance_index > 1 ? (capacity_spec.slot == "bed" ? 2 : 1) : max(capacity_spec.min_count, 1)
		var/module_area = max(4, effective_min_count * 2)
		if(effective_min_count >= 2)
			module_area = max(module_area, 12)
		if(effective_min_count >= 4)
			module_area = max(module_area, 24)
		if(capacity_spec.category == "sanitation")
			module_area = max(module_area, 16)
		if(capacity_spec.pattern == "table_cluster")
			module_area = max(module_area, 8 + max(capacity_spec.chair_count, 0) * 2)
		if(capacity_spec.wall_required)
			module_area = max(module_area, 6)
		min_scene_area = max(min_scene_area, module_area)
	if(instance_index > 1)
		min_scene_area = max(min_scene_area, 12)
	return min_scene_area

/datum/world_edit_generator/building_layout/proc/configure_building_layout_partition_policy(datum/world_edit_building_layout_room_contract/room)
	if(!istype(room))
		return
	switch(room.privacy_class)
		if("public")
			if(room.role == "entry")
				room.partition_policy = WORLD_EDIT_BUILDING_PARTITION_OPEN
				room.route_opening_kind = WORLD_EDIT_BUILDING_OPENING_WIDE_ARCH
				room.min_route_opening_width = 2
				room.max_route_opening_width = 3
			else
				room.partition_policy = WORLD_EDIT_BUILDING_PARTITION_SOFT
				room.route_opening_kind = WORLD_EDIT_BUILDING_OPENING_ARCH
				room.min_route_opening_width = 2
				room.max_route_opening_width = 2
			room.allow_public_route_merge = TRUE
		if("private")
			room.partition_policy = WORLD_EDIT_BUILDING_PARTITION_CLOSED
			room.route_opening_kind = WORLD_EDIT_BUILDING_OPENING_DOOR
			room.window_policy = "forbidden"
			room.exterior_window_policy = "forbidden"
		if("secure")
			room.partition_policy = WORLD_EDIT_BUILDING_PARTITION_SECURE
			room.route_opening_kind = WORLD_EDIT_BUILDING_OPENING_SECURE_DOOR
			room.window_policy = "forbidden"
			room.exterior_window_policy = "forbidden"
		else
			room.partition_policy = WORLD_EDIT_BUILDING_PARTITION_CLOSED
			room.route_opening_kind = WORLD_EDIT_BUILDING_OPENING_DOOR

/datum/world_edit_generator/building_layout/proc/compile_building_layout_connection_contracts(datum/world_edit_building_layout_state/state, datum/world_edit_building_layout_program_contract/program)
	if(!istype(state) || !istype(program))
		return
	for(var/datum/world_edit_building_adjacency_rule/rule as anything in state.semantic_plan?.adjacency_rules)
		if(!istype(rule))
			continue
		var/list/from_room_ids = get_building_layout_functional_room_ids_for_zone(program, rule.zone_a)
		var/list/to_room_ids = get_building_layout_functional_room_ids_for_zone(program, rule.zone_b)
		if(!length(from_room_ids) || !length(to_room_ids))
			continue
		for(var/from_index in 1 to length(from_room_ids))
			var/from_room_id = from_room_ids[from_index]
			var/to_room_id = to_room_ids[((from_index - 1) % length(to_room_ids)) + 1]
			program.add_connection_contract(new /datum/world_edit_building_layout_connection_contract(from_room_id, to_room_id, rule.required, WORLD_EDIT_BUILDING_EDGE_SHARED))
		for(var/to_index in 1 to length(to_room_ids))
			var/to_room_id = to_room_ids[to_index]
			var/from_room_id = from_room_ids[((to_index - 1) % length(from_room_ids)) + 1]
			if(!building_layout_program_has_connection(program, from_room_id, to_room_id))
				program.add_connection_contract(new /datum/world_edit_building_layout_connection_contract(from_room_id, to_room_id, rule.required, WORLD_EDIT_BUILDING_EDGE_SHARED))

/datum/world_edit_generator/building_layout/proc/get_building_layout_functional_room_ids_for_zone(datum/world_edit_building_layout_program_contract/program, zone_id)
	var/list/result = list()
	for(var/datum/world_edit_building_layout_room_contract/room_contract as anything in program?.functional_room_contracts)
		if(istype(room_contract) && room_contract.zone_id == zone_id)
			result += room_contract.id
	return result

/datum/world_edit_generator/building_layout/proc/building_layout_program_has_connection(datum/world_edit_building_layout_program_contract/program, from_room_id, to_room_id)
	for(var/datum/world_edit_building_layout_connection_contract/connection as anything in program?.connection_contracts)
		if((connection.from_room == from_room_id && connection.to_room == to_room_id) || (connection.from_room == to_room_id && connection.to_room == from_room_id))
			return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/compile_building_layout_topology_graph(datum/world_edit_building_layout_state/state, datum/world_edit_building_layout_program_contract/program)
	if(!istype(state) || !istype(program))
		return null
	var/datum/world_edit_building_layout_topology_graph/graph = new
	for(var/datum/world_edit_building_layout_room_contract/room_contract as anything in program.functional_room_contracts)
		if(istype(room_contract))
			graph.add_node(new /datum/world_edit_building_layout_topology_node(room_contract))
	for(var/datum/world_edit_building_layout_connection_contract/connection as anything in program.connection_contracts)
		if(!istype(connection) || !graph.get_node(connection.from_room) || !graph.get_node(connection.to_room))
			continue
		var/datum/world_edit_building_layout_topology_edge/edge = new(connection.from_room, connection.to_room, connection.kind, connection.required)
		edge.privacy_transition = connection.privacy_transition
		edge.min_shared_wall = 2
		graph.add_edge(edge)
	for(var/datum/world_edit_building_nested_room_spec/nested_spec as anything in state.semantic_plan?.nested_room_specs)
		if(!istype(nested_spec))
			continue
		var/list/outer_ids = get_building_layout_functional_room_ids_for_zone(program, nested_spec.outer_zone_id)
		var/list/inner_ids = get_building_layout_functional_room_ids_for_zone(program, nested_spec.inner_zone_id)
		for(var/inner_index in 1 to length(inner_ids))
			if(!length(outer_ids))
				break
			graph.add_edge(new /datum/world_edit_building_layout_topology_edge(outer_ids[((inner_index - 1) % length(outer_ids)) + 1], inner_ids[inner_index], WORLD_EDIT_BUILDING_EDGE_NESTED, TRUE))
	graph.root_node_id = select_building_layout_topology_root(state, program, graph)
	connect_building_layout_topology_components(graph)
	assign_building_layout_topology_depths(graph)
	return graph

/datum/world_edit_generator/building_layout/proc/select_building_layout_topology_root(datum/world_edit_building_layout_state/state, datum/world_edit_building_layout_program_contract/program, datum/world_edit_building_layout_topology_graph/graph)
	for(var/datum/world_edit_building_adjacency_rule/rule as anything in state.semantic_plan?.adjacency_rules)
		if(!istype(rule) || !rule.required)
			continue
		var/datum/world_edit_building_zone_spec/zone_a = state.semantic_plan.get_zone_spec(rule.zone_a)
		var/datum/world_edit_building_zone_spec/zone_b = state.semantic_plan.get_zone_spec(rule.zone_b)
		if(istype(zone_a) && !zone_a.counts_toward_target)
			var/list/candidates_b = get_building_layout_functional_room_ids_for_zone(program, rule.zone_b)
			if(length(candidates_b))
				return candidates_b[1]
		if(istype(zone_b) && !zone_b.counts_toward_target)
			var/list/candidates_a = get_building_layout_functional_room_ids_for_zone(program, rule.zone_a)
			if(length(candidates_a))
				return candidates_a[1]
	var/list/preferred_zones = list(state.archetype?.primary_zone, state.archetype?.hub_zone)
	for(var/preferred_zone as anything in preferred_zones)
		var/list/preferred_ids = get_building_layout_functional_room_ids_for_zone(program, preferred_zone)
		if(length(preferred_ids))
			return preferred_ids[1]
	var/datum/world_edit_building_layout_topology_node/first_node = length(graph.nodes) ? graph.nodes[1] : null
	return first_node?.id || ""

/datum/world_edit_generator/building_layout/proc/connect_building_layout_topology_components(datum/world_edit_building_layout_topology_graph/graph)
	if(!istype(graph) || !length(graph.root_node_id))
		return
	var/list/reachable = build_building_layout_topology_reachable_lookup(graph, graph.root_node_id)
	for(var/datum/world_edit_building_layout_topology_node/node as anything in graph.nodes)
		if(!istype(node) || reachable[node.id] || node.id == graph.root_node_id)
			continue
		graph.add_edge(new /datum/world_edit_building_layout_topology_edge(graph.root_node_id, node.id, WORLD_EDIT_BUILDING_EDGE_ROUTE, TRUE))
		reachable = build_building_layout_topology_reachable_lookup(graph, graph.root_node_id)

/datum/world_edit_generator/building_layout/proc/build_building_layout_topology_reachable_lookup(datum/world_edit_building_layout_topology_graph/graph, root_id)
	var/list/reachable = list()
	if(!istype(graph) || !length("[root_id]"))
		return reachable
	var/list/open = list("[root_id]")
	reachable["[root_id]"] = TRUE
	while(length(open))
		var/current_id = open[1]
		open.Cut(1, 2)
		for(var/datum/world_edit_building_layout_topology_edge/edge as anything in graph.get_edges_for(current_id))
			var/next_id = edge.from_id == current_id ? edge.to_id : edge.from_id
			if(reachable[next_id])
				continue
			reachable[next_id] = TRUE
			open += next_id
	return reachable

/datum/world_edit_generator/building_layout/proc/assign_building_layout_topology_depths(datum/world_edit_building_layout_topology_graph/graph)
	if(!istype(graph) || !length(graph.root_node_id))
		return
	var/list/open = list(graph.root_node_id)
	var/list/seen = list(graph.root_node_id = TRUE)
	while(length(open))
		var/current_id = open[1]
		open.Cut(1, 2)
		var/datum/world_edit_building_layout_topology_node/current = graph.get_node(current_id)
		for(var/datum/world_edit_building_layout_topology_edge/edge as anything in graph.get_edges_for(current_id))
			var/next_id = edge.from_id == current_id ? edge.to_id : edge.from_id
			if(seen[next_id])
				continue
			var/datum/world_edit_building_layout_topology_node/next = graph.get_node(next_id)
			if(!istype(next))
				continue
			next.parent_id = current_id
			next.depth = (current?.depth || 0) + 1
			seen[next_id] = TRUE
			open += next_id

/datum/world_edit_generator/building_layout/proc/get_building_layout_first_room_id_for_zone(datum/world_edit_building_layout_program_contract/program, zone_id)
	for(var/datum/world_edit_building_layout_room_contract/room as anything in program?.room_contracts)
		if(istype(room) && room.zone_id == "[zone_id]")
			return room.id
	return ""

/datum/world_edit_generator/building_layout/proc/compile_building_layout_scene_contracts(datum/world_edit_building_layout_state/state, datum/world_edit_building_layout_program_contract/program)
	if(!istype(state) || !istype(program))
		return
	for(var/datum/world_edit_building_layout_room_contract/room as anything in program.room_contracts)
		if(!istype(room))
			continue
		if(room.role == "route")
			room.allowed_scene_kinds = list()
			room.required_scene_kinds = list()
			continue
		var/list/exact_module_specs = list()
		var/list/fallback_module_specs = list()
		for(var/datum/world_edit_building_cluster_spec/cluster_spec as anything in state.semantic_plan?.cluster_specs)
			if(!istype(cluster_spec) || cluster_spec.compact_substitute_only || is_building_infrastructure_category(cluster_spec.category))
				continue
			if(!building_layout_cluster_owned_by_room(program, cluster_spec, room))
				continue
			if(building_layout_cluster_exactly_matches_room(cluster_spec, room))
				exact_module_specs += cluster_spec
			else if(building_layout_cluster_matches_room(cluster_spec, room))
				fallback_module_specs += cluster_spec
		var/list/module_specs = length(exact_module_specs) ? exact_module_specs : fallback_module_specs
		var/scene_kind = resolve_building_layout_scene_kind(room, module_specs)
		var/datum/world_edit_building_layout_scene_contract/scene = new("[room.id]_identity", scene_kind)
		scene.allowed_programs = list(program.id)
		scene.allowed_room_ids = list(room.id)
		scene.allowed_room_roles = list(room.role)
		scene.required = room.required
		scene.min_room_area = room.min_area
		scene.primary_anchor_policy = (room.privacy_class in list("private", "secure")) ? "far_wall" : "center"
		scene.negative_space_policy = "door_to_focus"
		for(var/datum/world_edit_building_cluster_spec/cluster_spec as anything in module_specs)
			var/datum/world_edit_building_cluster_spec/instance_spec = build_building_layout_scene_instance_module_spec(state, cluster_spec, room)
			if(!istype(instance_spec))
				continue
			scene.module_specs += instance_spec
			if(instance_spec.required)
				scene.required_modules += instance_spec.id
			else
				scene.optional_modules += instance_spec.id
		var/composition_members = 0
		for(var/datum/world_edit_building_cluster_spec/required_instance_spec as anything in scene.module_specs)
			if(!istype(required_instance_spec) || !required_instance_spec.required)
				continue
			composition_members += max(required_instance_spec.min_count, 1)
			if(required_instance_spec.pattern == "table_cluster")
				composition_members += max(required_instance_spec.chair_count, 0)
		var/min_composition_members = get_building_layout_min_scene_members_for_room(room.id, room.role, room.preferred_area)
		if(room.instance_index > 1)
			min_composition_members = max(min_composition_members, 2)
		if(composition_members < min_composition_members)
			var/datum/world_edit_building_cluster_spec/composition_support = build_building_layout_scene_instance_support_spec(room, scene_kind)
			if(istype(composition_support))
				scene.module_specs += composition_support
				scene.required_modules += composition_support.id
		configure_building_layout_scene_fallback(scene, room)
		room.allowed_scene_kinds = list(scene_kind)
		if(room.required)
			room.required_scene_kinds = list(scene_kind)
		program.add_scene_contract(scene)

/datum/world_edit_generator/building_layout/proc/build_building_layout_scene_instance_module_spec(datum/world_edit_building_layout_state/state, datum/world_edit_building_cluster_spec/cluster_spec, datum/world_edit_building_layout_room_contract/room)
	if(!istype(state) || !istype(cluster_spec) || !istype(room))
		return null
	var/datum/world_edit_building_cluster_spec/source_spec = cluster_spec
	var/use_compact_spec = FALSE
	if(length(cluster_spec.compact_substitute_id))
		var/datum/world_edit_building_cluster_spec/compact_spec = state.semantic_plan?.get_cluster_spec_by_id(cluster_spec.compact_substitute_id)
		var/compact_area_threshold = max(cluster_spec.min_count * 6, 12)
		if(istype(compact_spec) && compact_spec.compact_substitute_only && (room.instance_index > 1 || room.min_area < compact_area_threshold))
			source_spec = compact_spec
			use_compact_spec = TRUE
	if(room.instance_index <= 1 && !use_compact_spec)
		return cluster_spec
	var/datum/world_edit_building_cluster_spec/instance_spec = source_spec.clone()
	instance_spec.id = "[room.id]_[source_spec.id]"
	instance_spec.count_cluster_id = source_spec.id
	instance_spec.compact_substitute_only = FALSE
	instance_spec.required = cluster_spec.required || (room.required && cluster_spec.optional_zone_id == room.zone_id)
	instance_spec.failure_severity = instance_spec.required ? "required" : "optional"
	if(room.instance_index <= 1)
		instance_spec.signature_required = cluster_spec.signature_required
		instance_spec.signature_id = cluster_spec.signature_id
		instance_spec.semantic_credit = cluster_spec.semantic_credit
		return instance_spec
	instance_spec.signature_required = FALSE
	instance_spec.signature_id = "[room.zone_id]_instance_composition"
	instance_spec.semantic_credit = "[room.zone_id]_instance_identity"
	if(instance_spec.wall_required && instance_spec.slot == "table")
		instance_spec.pattern = "table_cluster"
		instance_spec.wall_required = FALSE
		instance_spec.min_count = 1
		instance_spec.max_count = 1
		instance_spec.chair_count = max(instance_spec.chair_count, 1)
	if(instance_spec.required)
		var/min_members = instance_spec.slot == "bed" ? 2 : 1
		instance_spec.min_count = min_members
		instance_spec.max_count = max(min_members, min(instance_spec.max_count, 2))
	return instance_spec

/datum/world_edit_generator/building_layout/proc/build_building_layout_scene_instance_support_spec(datum/world_edit_building_layout_room_contract/room, scene_kind = "")
	if(!istype(room))
		return null
	var/slot = "chair"
	var/category = "chair"
	var/wall_required = FALSE
	if("[scene_kind]" == "sanitation")
		slot = "sink"
		category = "sanitation"
	else
		switch(room.role)
			if("storage", "service", "support")
				slot = "crate"
				category = "crate"
			if("private")
				slot = "cabinet"
				category = "cabinet"
				wall_required = TRUE
	var/datum/world_edit_building_cluster_spec/support = new("[room.id]_composition_support", "secondary", "object", slot, category, list(room.zone_id), 1, 1, wall_required, 0, 65, TRUE)
	support.signature_required = FALSE
	support.signature_id = "[room.zone_id]_instance_composition"
	support.semantic_credit = "[room.zone_id]_instance_support"
	return support

/datum/world_edit_generator/building_layout/proc/reserve_building_layout_required_scene_identity_budget(datum/world_edit_building_layout_program_contract/program)
	if(!istype(program))
		return
	var/list/required_category_counts = list()
	var/list/composition_support_categories = list()
	var/required_scene_count = 0
	for(var/datum/world_edit_building_layout_scene_contract/scene as anything in program.scene_contracts)
		if(!istype(scene) || !scene.required)
			continue
		required_scene_count++
		var/datum/world_edit_building_cluster_spec/best_required = null
		for(var/datum/world_edit_building_cluster_spec/module_spec as anything in scene.module_specs)
			if(!istype(module_spec) || !module_spec.required || findtext(module_spec.id, "_composition_support"))
				continue
			if(!istype(best_required) || module_spec.priority > best_required.priority)
				best_required = module_spec
		if(!istype(best_required))
			required_category_counts[scene.fallback_category] = (required_category_counts[scene.fallback_category] || 0) + 1
			var/datum/world_edit_building_layout_room_contract/fallback_room = program.get_room_contract(scene.allowed_room_ids?[1])
			var/fallback_occupancy_minimum = istype(fallback_room) ? get_building_layout_min_scene_members_for_room(fallback_room.id, fallback_room.role, fallback_room.preferred_area) : 1
			if(fallback_occupancy_minimum > 1)
				var/fallback_detail_category = get_building_layout_scene_identity_detail_category(scene.scene_kind, fallback_room?.role, scene.fallback_category)
				required_category_counts[fallback_detail_category] = (required_category_counts[fallback_detail_category] || 0) + fallback_occupancy_minimum - 1
			continue
		var/required_count = max(best_required.min_count, 1)
		required_category_counts[best_required.category] = (required_category_counts[best_required.category] || 0) + required_count
		if(best_required.pattern == "table_cluster" && best_required.chair_count > 0)
			required_category_counts["chair"] = (required_category_counts["chair"] || 0) + best_required.chair_count
		var/datum/world_edit_building_layout_room_contract/room = program.get_room_contract(scene.allowed_room_ids?[1])
		var/occupancy_minimum = istype(room) ? get_building_layout_min_scene_members_for_room(room.id, room.role, room.preferred_area) : 1
		var/primary_members = required_count + (best_required.pattern == "table_cluster" ? max(best_required.chair_count, 0) : 0)
		for(var/datum/world_edit_building_cluster_spec/support_spec as anything in scene.module_specs)
			if(!istype(support_spec) || !support_spec.required || !findtext(support_spec.id, "_composition_support"))
				continue
			var/support_count = max(support_spec.min_count, 1)
			required_category_counts[support_spec.category] = (required_category_counts[support_spec.category] || 0) + support_count
			composition_support_categories[support_spec.category] = TRUE
			primary_members += support_count
		if(occupancy_minimum > primary_members)
			var/detail_category = get_building_layout_scene_identity_detail_category(scene.scene_kind, room?.role, scene.fallback_category)
			required_category_counts[detail_category] = (required_category_counts[detail_category] || 0) + occupancy_minimum - primary_members
	for(var/category as anything in required_category_counts)
		program.global_scene_slot_limits[category] = max(round(text2num("[program.global_scene_slot_limits[category]]") || 0), required_category_counts[category])
	for(var/support_category as anything in composition_support_categories)
		program.global_scene_slot_limits[support_category] = max(round(text2num("[program.global_scene_slot_limits[support_category]]") || 0), required_scene_count)

/datum/world_edit_generator/building_layout/proc/get_building_layout_scene_identity_detail_category(scene_kind, room_role, fallback_category)
	switch("[scene_kind]")
		if("dining", "living_common")
			return "chair"
		if("bedroom")
			return "cabinet"
		if("sanitation")
			return "sanitation"
		if("storage")
			return "rack"
	switch("[room_role]")
		if("private")
			return "cabinet"
		if("public")
			return "chair"
		if("hub", "work", "secure")
			return "console"
		if("service", "support")
			return "rack"
	return length("[fallback_category]") ? "[fallback_category]" : "table"

/datum/world_edit_generator/building_layout/proc/building_layout_cluster_owned_by_room(datum/world_edit_building_layout_program_contract/program, datum/world_edit_building_cluster_spec/cluster_spec, datum/world_edit_building_layout_room_contract/room)
	if(!istype(program) || !istype(cluster_spec) || !istype(room))
		return FALSE
	if(room.instance_index > 1)
		return building_layout_cluster_exactly_matches_room(cluster_spec, room)
	var/owner_room_id = ""
	var/best_score = -999999999
	for(var/datum/world_edit_building_layout_room_contract/candidate_room as anything in program.room_contracts)
		if(!istype(candidate_room) || !building_layout_cluster_matches_room(cluster_spec, candidate_room))
			continue
		var/score = candidate_room.preferred_area * 100 + candidate_room.min_area * 10
		if(length(cluster_spec.optional_zone_id) && cluster_spec.optional_zone_id == candidate_room.zone_id)
			score += 100000
		score += get_building_layout_cluster_zone_anchor_score(cluster_spec, candidate_room.zone_id)
		if(candidate_room.role in list("hub", "public", "public_med", "staging", "work"))
			score += 500
		if(!length(owner_room_id) || score > best_score)
			owner_room_id = candidate_room.id
			best_score = score
	return owner_room_id == room.id

/datum/world_edit_generator/building_layout/proc/building_layout_cluster_exactly_matches_room(datum/world_edit_building_cluster_spec/cluster_spec, datum/world_edit_building_layout_room_contract/room)
	if(!istype(cluster_spec) || !istype(room))
		return FALSE
	if(length(cluster_spec.optional_zone_id) && cluster_spec.optional_zone_id == room.zone_id)
		return TRUE
	return building_layout_cluster_has_zone_anchor(cluster_spec, room.zone_id)

/datum/world_edit_generator/building_layout/proc/building_layout_cluster_has_zone_anchor(datum/world_edit_building_cluster_spec/cluster_spec, zone_id)
	return get_building_layout_cluster_zone_anchor_score(cluster_spec, zone_id) > 0

/datum/world_edit_generator/building_layout/proc/get_building_layout_cluster_zone_anchor_score(datum/world_edit_building_cluster_spec/cluster_spec, zone_id)
	if(!istype(cluster_spec) || !length("[zone_id]"))
		return 0
	var/zone_prefix = "[zone_id]_"
	var/anchor_index = 0
	for(var/anchor_id as anything in cluster_spec.anchors)
		anchor_index++
		var/anchor_key = "[anchor_id]"
		if(anchor_key == "[zone_id]")
			return max(60000 - anchor_index * 1000, 1)
		if(findtext(anchor_key, zone_prefix) == 1)
			return max(50000 - anchor_index * 1000, 1)
	return 0

/datum/world_edit_generator/building_layout/proc/building_layout_cluster_matches_room(datum/world_edit_building_cluster_spec/cluster_spec, datum/world_edit_building_layout_room_contract/room)
	if(!istype(cluster_spec) || !istype(room) || is_building_infrastructure_category(cluster_spec.category))
		return FALSE
	if(length(cluster_spec.optional_zone_id) && cluster_spec.optional_zone_id == room.zone_id)
		return TRUE
	if(building_layout_cluster_has_zone_anchor(cluster_spec, room.zone_id))
		return TRUE
	for(var/anchor_id as anything in cluster_spec.anchors)
		if("[anchor_id]" == room.role || "[anchor_id]" in room.anchor_tags)
			return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/resolve_building_layout_scene_kind(datum/world_edit_building_layout_room_contract/room, list/module_specs)
	if(!istype(room))
		return "room_identity"
	if(findtext(room.zone_id, "sleep") || ("sleeping" in room.anchor_tags))
		return "bedroom"
	var/has_social_module = FALSE
	for(var/datum/world_edit_building_cluster_spec/cluster_spec as anything in module_specs)
		if(!istype(cluster_spec))
			continue
		if(cluster_spec.slot == "bed" || (cluster_spec.category in list("bed", "sleeping_bed")))
			return "bedroom"
		if((cluster_spec.slot in list("toilet", "sink")) || cluster_spec.category == "sanitation")
			return "sanitation"
		if(cluster_spec.pattern == "table_cluster" && cluster_spec.chair_count > 0)
			has_social_module = TRUE
	if(room.role == "storage" || findtext(room.zone_id, "storage"))
		return "storage"
	if(has_social_module)
		return "living_common"
	return room.zone_id

/datum/world_edit_generator/building_layout/proc/configure_building_layout_scene_fallback(datum/world_edit_building_layout_scene_contract/scene, datum/world_edit_building_layout_room_contract/room)
	if(!istype(scene) || !istype(room))
		return
	switch(room.role)
		if("private")
			if(scene.scene_kind == "bedroom")
				scene.fallback_slot = "bed"
				scene.fallback_category = "bed"
			else
				scene.fallback_slot = "cabinet"
				scene.fallback_category = "cabinet"
		if("storage", "service", "support")
			scene.fallback_slot = "rack"
			scene.fallback_category = "rack"
		if("secure", "work", "hub")
			scene.fallback_slot = "console"
			scene.fallback_category = "console"
		if("entry", "route")
			scene.fallback_slot = "light"
			scene.fallback_category = "light"
		else
			scene.fallback_slot = "table"
			scene.fallback_category = "table"

/datum/world_edit_generator/building_layout/proc/get_building_layout_pattern(pattern_id)
	switch("[pattern_id]")
		if("hub_spoke")
			return new /datum/world_edit_building_layout_pattern/topology_family/hub_spoke()
		if("split_wing")
			return new /datum/world_edit_building_layout_pattern/topology_family/split_wing()
		if("open_bay_perimeter")
			return new /datum/world_edit_building_layout_pattern/topology_family/open_bay_perimeter()
		if("secure_core")
			return new /datum/world_edit_building_layout_pattern/topology_family/secure_core()
		if("nested_service")
			return new /datum/world_edit_building_layout_pattern/topology_family/nested_service()
		if("compound_cells")
			return new /datum/world_edit_building_layout_pattern/topology_family/compound_cells()
		if("axial_fallback")
			return new /datum/world_edit_building_layout_pattern/topology_family/axial_fallback()
	return null

/datum/world_edit_building_layout_pattern/topology_family
	min_width = 9
	min_height = 9
	max_width = 64
	max_height = 64
	var/list/orientation_variants = list("primary", "rotated")

/datum/world_edit_building_layout_pattern/topology_family/build_region_candidates(datum/world_edit_building_layout_context/context)
	var/list/candidates = list()
	if(!can_solve(context))
		return candidates
	var/variant_index = 0
	for(var/orientation as anything in orientation_variants)
		variant_index++
		var/datum/world_edit_building_layout_region_candidate/candidate = context.generator.build_building_layout_topology_region_candidate(context, id, "[id]_[orientation]", variant_index - 1)
		if(istype(candidate))
			candidates += candidate
	return candidates

/datum/world_edit_building_layout_pattern/topology_family/hub_spoke
	id = "hub_spoke"

/datum/world_edit_building_layout_pattern/topology_family/split_wing
	id = "split_wing"

/datum/world_edit_building_layout_pattern/topology_family/open_bay_perimeter
	id = "open_bay_perimeter"

/datum/world_edit_building_layout_pattern/topology_family/secure_core
	id = "secure_core"

/datum/world_edit_building_layout_pattern/topology_family/nested_service
	id = "nested_service"

/datum/world_edit_building_layout_pattern/topology_family/compound_cells
	id = "compound_cells"

/datum/world_edit_building_layout_pattern/topology_family/axial_fallback
	id = "axial_fallback"

/datum/world_edit_generator/building_layout/proc/build_building_layout_topology_region_candidate(datum/world_edit_building_layout_context/context, family_id, candidate_id, orientation_variant = 0)
	if(!istype(context) || !istype(context.program_contract))
		return null
	if(!istype(context.program_contract.topology_graph) || !length(context.program_contract.functional_room_contracts))
		return null
	var/datum/world_edit_building_layout_region_candidate/region = new(family_id, candidate_id, 600 - orientation_variant * 5)
	region.topology_graph = context.program_contract.topology_graph
	region.topology_family = "[family_id]"
	var/list/functional_ids = list()
	for(var/datum/world_edit_building_layout_room_contract/room as anything in context.program_contract.functional_room_contracts)
		if(istype(room))
			functional_ids += room.id
	region.add_influence_zone("functional_field", "functional", 2, 2, max(context.local_width() - 1, 2), max(context.local_height() - 1, 2), functional_ids, 100)
	for(var/datum/world_edit_building_layout_topology_edge/edge as anything in region.topology_graph.edges)
		if(!istype(edge))
			continue
		var/datum/world_edit_building_layout_room_contract/from_contract = context.program_contract.get_room_contract(edge.from_id)
		var/privacy = from_contract?.privacy_class || "public"
		var/datum/world_edit_building_layout_room_connection/connection = region.add_connection("topology_[edge.from_id]_[edge.to_id]", edge.from_id, edge.to_id, privacy, FALSE, "topology")
		connection.min_shared_wall_length = edge.min_shared_wall
	return region
