#define WORLD_EDIT_BUILDING_PARTITION_OPEN "open"
#define WORLD_EDIT_BUILDING_PARTITION_SOFT "soft"
#define WORLD_EDIT_BUILDING_PARTITION_CLOSED "closed"
#define WORLD_EDIT_BUILDING_PARTITION_SECURE "secure"

#define WORLD_EDIT_BUILDING_OPENING_NONE "none"
#define WORLD_EDIT_BUILDING_OPENING_ARCH "arch"
#define WORLD_EDIT_BUILDING_OPENING_WIDE_ARCH "wide_arch"
#define WORLD_EDIT_BUILDING_OPENING_DOOR "door"
#define WORLD_EDIT_BUILDING_OPENING_SECURE_DOOR "secure_door"

#define WORLD_EDIT_BUILDING_EDGE_SHARED "shared"
#define WORLD_EDIT_BUILDING_EDGE_ROUTE "route"
#define WORLD_EDIT_BUILDING_EDGE_OPEN_MERGE "open_merge"
#define WORLD_EDIT_BUILDING_EDGE_SECURE "secure"
#define WORLD_EDIT_BUILDING_EDGE_NESTED "nested"

#define WORLD_EDIT_BUILDING_TOPOLOGY_FUNCTIONAL "functional"
#define WORLD_EDIT_BUILDING_TOPOLOGY_CIRCULATION_TERMINAL "circulation_terminal"
#define WORLD_EDIT_BUILDING_TOPOLOGY_TRANSITION "transition"

#define WORLD_EDIT_BUILDING_CLUSTER_GLOBAL_ONCE "global_once"
#define WORLD_EDIT_BUILDING_CLUSTER_PRIMARY_ONLY "primary_only"
#define WORLD_EDIT_BUILDING_CLUSTER_PER_INSTANCE "per_instance"
#define WORLD_EDIT_BUILDING_CLUSTER_DISTRIBUTE_TOTAL "distribute_total"

/datum/world_edit_building_layout_context
	var/datum/world_edit_generator/building_layout/generator
	var/datum/world_edit_building_layout_state/state
	var/datum/world_edit_building_layout_program_contract/program_contract
	var/datum/world_edit_building_layout_scene_budget/scene_budget
	var/datum/world_edit_building_layout_candidate/selected_candidate = null
	var/list/errors = list()
	var/list/warnings = list()

/datum/world_edit_building_layout_context/New(datum/world_edit_generator/building_layout/_generator, datum/world_edit_building_layout_state/_state, datum/world_edit_building_layout_program_contract/_program_contract)
	. = ..()
	generator = _generator
	state = _state
	program_contract = _program_contract
	if(istype(program_contract))
		scene_budget = new
		scene_budget.limits = islist(program_contract.global_scene_slot_limits) ? program_contract.global_scene_slot_limits.Copy() : list()
		scene_budget.minimums = islist(program_contract.global_scene_slot_minimums) ? program_contract.global_scene_slot_minimums.Copy() : list()

/datum/world_edit_building_layout_context/proc/bounds_width()
	if(!istype(state) || !islist(state.geometry.bounds))
		return 0
	return round(text2num("[state.geometry.bounds["width"]]") || 0)

/datum/world_edit_building_layout_context/proc/bounds_height()
	if(!istype(state) || !islist(state.geometry.bounds))
		return 0
	return round(text2num("[state.geometry.bounds["height"]]") || 0)

/datum/world_edit_building_layout_context/proc/local_width()
	if(state?.placement_dir == EAST || state?.placement_dir == WEST)
		return bounds_height()
	return bounds_width()

/datum/world_edit_building_layout_context/proc/local_height()
	if(state?.placement_dir == EAST || state?.placement_dir == WEST)
		return bounds_width()
	return bounds_height()

/datum/world_edit_building_layout_context/proc/local_turf(local_x, local_y)
	if(!istype(state) || !islist(state.geometry.bounds))
		return null
	var/min_x = round(text2num("[state.geometry.bounds["min_x"]]") || 0)
	var/max_x = round(text2num("[state.geometry.bounds["max_x"]]") || 0)
	var/min_y = round(text2num("[state.geometry.bounds["min_y"]]") || 0)
	var/max_y = round(text2num("[state.geometry.bounds["max_y"]]") || 0)
	var/z_level = round(text2num("[state.geometry.bounds["z"]]") || 1)
	var/x = min_x + local_x - 1
	var/y = max_y - local_y + 1
	switch(state.placement_dir)
		if(SOUTH)
			x = max_x - local_x + 1
			y = min_y + local_y - 1
		if(EAST)
			x = max_x - local_y + 1
			y = max_y - local_x + 1
		if(WEST)
			x = min_x + local_y - 1
			y = min_y + local_x - 1
	return locate(x, y, z_level)

/datum/world_edit_building_layout_context/proc/local_coordinates(turf/world_turf)
	if(!istype(world_turf) || !istype(state) || !islist(state.geometry.bounds))
		return null
	var/min_x = round(text2num("[state.geometry.bounds["min_x"]]") || 0)
	var/max_x = round(text2num("[state.geometry.bounds["max_x"]]") || 0)
	var/min_y = round(text2num("[state.geometry.bounds["min_y"]]") || 0)
	var/max_y = round(text2num("[state.geometry.bounds["max_y"]]") || 0)
	var/local_x = world_turf.x - min_x + 1
	var/local_y = max_y - world_turf.y + 1
	switch(state.placement_dir)
		if(SOUTH)
			local_x = max_x - world_turf.x + 1
			local_y = world_turf.y - min_y + 1
		if(EAST)
			local_x = max_y - world_turf.y + 1
			local_y = max_x - world_turf.x + 1
		if(WEST)
			local_x = world_turf.y - min_y + 1
			local_y = world_turf.x - min_x + 1
	return list("x" = local_x, "y" = local_y)

/datum/world_edit_building_layout_context/proc/local_dir_to_world_dir(local_dir)
	switch(state?.placement_dir)
		if(SOUTH)
			switch(local_dir)
				if(NORTH) return SOUTH
				if(SOUTH) return NORTH
				if(EAST) return WEST
				if(WEST) return EAST
		if(EAST)
			switch(local_dir)
				if(NORTH) return EAST
				if(SOUTH) return WEST
				if(EAST) return SOUTH
				if(WEST) return NORTH
		if(WEST)
			switch(local_dir)
				if(NORTH) return WEST
				if(SOUTH) return EAST
				if(EAST) return NORTH
				if(WEST) return SOUTH
	return local_dir

/datum/world_edit_building_layout_program_contract
	var/id = ""
	var/list/room_contracts = list()
	var/list/room_contracts_by_id = list()
	var/list/functional_room_contracts = list()
	var/list/circulation_contracts = list()
	var/list/connection_contracts = list()
	var/list/scene_contracts = list()
	var/list/scene_contracts_by_id = list()
	var/list/composition_contracts = list()
	var/list/composition_contracts_by_room = list()
	var/list/allowed_layout_patterns = list()
	var/list/global_scene_kind_limits = list()
	var/list/global_scene_slot_limits = list()
	var/list/global_scene_slot_minimums = list()
	var/min_total_area = 0
	var/preferred_total_area = 0
	var/target_room_count = 0
	var/target_functional_room_count = 0
	var/min_circulation_area = 0
	var/datum/world_edit_building_layout_topology_graph/topology_graph = null
	var/max_layout_candidates = 24

/datum/world_edit_building_layout_program_contract/proc/add_room_contract(datum/world_edit_building_layout_room_contract/room_contract)
	if(!istype(room_contract) || !length(room_contract.id))
		return
	room_contracts += room_contract
	room_contracts_by_id[room_contract.id] = room_contract
	if(room_contract.counts_toward_target)
		functional_room_contracts += room_contract
	else
		circulation_contracts += room_contract

/datum/world_edit_building_layout_program_contract/proc/get_room_contract(contract_id)
	return room_contracts_by_id["[contract_id]"]

/datum/world_edit_building_layout_program_contract/proc/add_connection_contract(datum/world_edit_building_layout_connection_contract/connection_contract)
	if(istype(connection_contract))
		connection_contracts += connection_contract

/datum/world_edit_building_layout_program_contract/proc/add_scene_contract(datum/world_edit_building_layout_scene_contract/scene_contract)
	if(!istype(scene_contract) || !length(scene_contract.id))
		return
	scene_contracts += scene_contract
	scene_contracts_by_id[scene_contract.id] = scene_contract

/datum/world_edit_building_layout_program_contract/proc/get_scene_contract(scene_id)
	return scene_contracts_by_id["[scene_id]"]

/datum/world_edit_building_layout_program_contract/proc/add_composition_contract(datum/world_edit_building_layout_composition_contract/composition)
	if(!istype(composition) || !length(composition.room_id))
		return
	composition_contracts += composition
	composition_contracts_by_room[composition.room_id] = composition

/datum/world_edit_building_layout_program_contract/proc/get_composition_contract(room_id)
	return composition_contracts_by_room["[room_id]"]

/datum/world_edit_building_layout_room_contract
	var/id = ""
	var/role = ""
	var/zone_id = ""
	var/required = TRUE
	var/min_area = 1
	var/preferred_area = 1
	var/max_area = 999
	var/min_width = 1
	var/min_height = 1
	var/max_width = 999
	var/max_height = 999
	var/privacy_class = "public"
	var/must_touch_route = TRUE
	var/exterior_window_policy = "optional"
	var/window_policy = "optional"
	var/partition_policy = WORLD_EDIT_BUILDING_PARTITION_CLOSED
	var/route_opening_kind = WORLD_EDIT_BUILDING_OPENING_DOOR
	var/min_route_opening_width = 1
	var/max_route_opening_width = 1
	var/avoid_facing_route_doors = TRUE
	var/allow_public_route_merge = FALSE
	var/max_aspect = 4
	var/target_aspect = 1.333
	var/max_scene_count = 1
	var/list/required_scene_kinds = list()
	var/list/allowed_scene_kinds = list()
	var/list/forbidden_scene_kinds = list()
	var/list/anchor_tags = list()
	var/instance_index = 1
	var/split_priority = 0
	var/spatial_kind = WORLD_EDIT_BUILDING_SPACE_FUNCTIONAL_ROOM
	var/counts_toward_target = TRUE
	var/min_capacity_units = 0
	var/capacity_kind = ""

/datum/world_edit_building_layout_room_contract/New(_id = "", _role = "", _zone_id = "", _required = TRUE, _min_area = 1, _preferred_area = 1, _max_area = 999, _min_width = 1, _min_height = 1, _max_width = 999, _max_height = 999)
	. = ..()
	id = "[_id]"
	role = "[_role]"
	zone_id = length("[_zone_id]") ? "[_zone_id]" : role
	required = _required ? TRUE : FALSE
	min_area = max(round(text2num("[_min_area]") || 1), 1)
	preferred_area = max(round(text2num("[_preferred_area]") || min_area), min_area)
	max_area = max(round(text2num("[_max_area]") || preferred_area), preferred_area)
	min_width = max(round(text2num("[_min_width]") || 1), 1)
	min_height = max(round(text2num("[_min_height]") || 1), 1)
	max_width = max(round(text2num("[_max_width]") || 999), min_width)
	max_height = max(round(text2num("[_max_height]") || 999), min_height)

/datum/world_edit_building_layout_connection_contract
	var/from_room = ""
	var/to_room = ""
	var/required = TRUE
	var/kind = "route"
	var/door_required = TRUE
	var/privacy_transition = ""

/datum/world_edit_building_layout_connection_contract/New(_from_room = "", _to_room = "", _required = TRUE, _kind = "route", _door_required = TRUE)
	. = ..()
	from_room = "[_from_room]"
	to_room = "[_to_room]"
	required = _required ? TRUE : FALSE
	kind = length("[_kind]") ? "[_kind]" : "route"
	door_required = _door_required ? TRUE : FALSE

/datum/world_edit_building_layout_topology_graph
	var/list/nodes = list()
	var/list/nodes_by_id = list()
	var/list/edges = list()
	var/root_node_id = ""
	var/list/compile_errors = list()
	var/required_connected = FALSE

/datum/world_edit_building_layout_topology_graph/proc/add_node(datum/world_edit_building_layout_topology_node/node)
	if(!istype(node) || !length(node.id) || nodes_by_id[node.id])
		return
	nodes += node
	nodes_by_id[node.id] = node

/datum/world_edit_building_layout_topology_graph/proc/add_edge(datum/world_edit_building_layout_topology_edge/edge)
	if(!istype(edge) || !length(edge.from_id) || !length(edge.to_id) || edge.from_id == edge.to_id)
		return FALSE
	for(var/datum/world_edit_building_layout_topology_edge/existing as anything in edges)
		if((existing.from_id == edge.from_id && existing.to_id == edge.to_id) || (existing.from_id == edge.to_id && existing.to_id == edge.from_id))
			return FALSE
	edges += edge
	return TRUE

/datum/world_edit_building_layout_topology_graph/proc/get_node(node_id)
	return nodes_by_id["[node_id]"]

/datum/world_edit_building_layout_topology_graph/proc/get_edges_for(node_id)
	var/list/result = list()
	for(var/datum/world_edit_building_layout_topology_edge/edge as anything in edges)
		if(istype(edge) && (edge.from_id == node_id || edge.to_id == node_id))
			result += edge
	return result

/datum/world_edit_building_layout_topology_node
	var/id = ""
	var/datum/world_edit_building_layout_room_contract/room_contract = null
	var/depth = 0
	var/parent_id = ""
	var/placement_group = ""
	var/centrality_score = 0
	var/node_kind = WORLD_EDIT_BUILDING_TOPOLOGY_FUNCTIONAL
	var/required = TRUE

/datum/world_edit_building_layout_topology_node/New(datum/world_edit_building_layout_room_contract/_room_contract)
	. = ..()
	room_contract = _room_contract
	id = "[_room_contract?.id || ""]"
	placement_group = "[_room_contract?.zone_id || ""]"
	required = _room_contract?.required ? TRUE : FALSE
	if(_room_contract?.spatial_kind in list(WORLD_EDIT_BUILDING_SPACE_CIRCULATION, WORLD_EDIT_BUILDING_SPACE_CHOKE))
		node_kind = _room_contract.spatial_kind == WORLD_EDIT_BUILDING_SPACE_CHOKE ? WORLD_EDIT_BUILDING_TOPOLOGY_TRANSITION : WORLD_EDIT_BUILDING_TOPOLOGY_CIRCULATION_TERMINAL

/datum/world_edit_building_layout_topology_edge
	var/from_id = ""
	var/to_id = ""
	var/kind = WORLD_EDIT_BUILDING_EDGE_SHARED
	var/required = TRUE
	var/min_shared_wall = 0
	var/privacy_transition = ""

/datum/world_edit_building_layout_topology_edge/New(_from_id = "", _to_id = "", _kind = WORLD_EDIT_BUILDING_EDGE_SHARED, _required = TRUE)
	. = ..()
	from_id = "[_from_id]"
	to_id = "[_to_id]"
	kind = "[_kind]"
	required = _required ? TRUE : FALSE

/datum/world_edit_building_layout_pattern
	var/id = ""
	var/list/allowed_programs = list()
	var/list/allowed_shapes = list()
	var/min_width = 1
	var/min_height = 1
	var/max_width = 32
	var/max_height = 32

/datum/world_edit_building_layout_pattern/proc/can_solve(datum/world_edit_building_layout_context/context)
	if(!istype(context) || !istype(context.state))
		return FALSE
	if(length(allowed_programs) && !(context.program_contract?.id in allowed_programs))
		return FALSE
	var/w = context.local_width()
	var/h = context.local_height()
	return w >= min_width && h >= min_height && w <= max_width && h <= max_height

/datum/world_edit_building_layout_pattern/proc/build_candidates(datum/world_edit_building_layout_context/context)
	return list()

/datum/world_edit_building_layout_pattern/proc/build_region_candidates(datum/world_edit_building_layout_context/context)
	return list()

/datum/world_edit_building_layout_candidate
	var/id = ""
	var/pattern_id = ""
	var/datum/world_edit_building_layout_region_candidate/region_candidate = null
	var/list/room_allocation_requests = list()
	var/list/room_plans = list()
	var/list/room_plans_by_id = list()
	var/list/room_connections = list()
	var/list/route_turfs = list()
	var/list/route_lookup = list()
	var/list/access_reserved_lookup = list()
	var/list/access_reservations_by_room = list()
	var/list/reserved_partition_wall_lookup = list()
	var/list/wall_turfs = list()
	var/list/wall_lookup = list()
	var/list/floor_lookup = list()
	var/list/solved_wall_lookup = list()
	var/list/solved_internal_wall_turfs = list()
	var/list/wall_cleanup_report = list()
	var/wall_model_ready = FALSE
	var/list/opening_plans = list()
	var/list/window_plans = list()
	var/list/errors = list()
	var/list/warnings = list()
	var/score = 0
	var/datum/world_edit_building_layout_topology_graph/topology_graph = null
	var/topology_family = ""
	var/list/route_overlay_turfs = list()
	var/list/route_overlay_lookup = list()
	var/list/route_zone_by_turf = list()
	var/list/route_owner_by_turf = list()
	var/list/ownership_by_turf = list()
	var/list/partition_edges = list()
	var/list/composition_contracts = list()
	var/list/family_constraints = list()
	var/family_policy_id = ""
	var/orientation_variant = 0
	var/topology_signature = ""
	var/list/quality_vector = list()

/datum/world_edit_building_layout_candidate/proc/add_room_allocation_request(datum/world_edit_building_layout_room_allocation_request/allocation_request)
	if(istype(allocation_request))
		room_allocation_requests += allocation_request

/datum/world_edit_building_layout_candidate/proc/add_room_plan(datum/world_edit_building_layout_room_plan/room_plan)
	if(!istype(room_plan) || !length(room_plan.id))
		return
	room_plans += room_plan
	room_plans_by_id[room_plan.id] = room_plan

/datum/world_edit_building_layout_candidate/proc/get_room_plan(room_id)
	return room_plans_by_id["[room_id]"]

/datum/world_edit_building_layout_candidate/proc/add_route_turf(turf/route_turf)
	if(!istype(route_turf) || route_turf in route_turfs)
		return
	route_turfs += route_turf
	route_lookup[route_turf] = TRUE

/datum/world_edit_building_layout_candidate/proc/reserve_route_access(room_id, list/wall_run, list/route_run, list/connector_run = null)
	if(!length("[room_id]") || !islist(wall_run) || !islist(route_run) || !length(wall_run) || length(wall_run) != length(route_run))
		return FALSE
	var/list/reservation = list("room_id" = "[room_id]", "wall_run" = wall_run.Copy(), "route_run" = route_run.Copy(), "connector_run" = islist(connector_run) ? connector_run.Copy() : list())
	access_reservations_by_room["[room_id]"] = reservation
	for(var/turf/wall_turf as anything in wall_run)
		if(istype(wall_turf))
			access_reserved_lookup[wall_turf] = TRUE
	for(var/turf/route_turf as anything in route_run)
		if(istype(route_turf))
			access_reserved_lookup[route_turf] = TRUE
	for(var/turf/connector_turf as anything in connector_run)
		if(istype(connector_turf))
			access_reserved_lookup[connector_turf] = TRUE
	return TRUE

/datum/world_edit_building_layout_candidate/proc/get_route_access_reservation(room_id)
	return access_reservations_by_room["[room_id]"]

/datum/world_edit_building_layout_allocation_partial
	var/list/placements = list()
	var/list/placement_order = list()
	var/score = 0

/datum/world_edit_building_layout_allocation_partial/proc/fork_with(room_id, list/rect, score_delta = 0)
	if(!length("[room_id]") || !islist(rect))
		return null
	var/datum/world_edit_building_layout_allocation_partial/child = new
	child.placements = placements.Copy()
	child.placement_order = placement_order.Copy()
	child.placements["[room_id]"] = rect.Copy()
	child.placement_order += "[room_id]"
	child.score = score + round(text2num("[score_delta]") || 0)
	return child

/datum/world_edit_building_layout_candidate/proc/add_room_connection(datum/world_edit_building_layout_room_connection/connection)
	if(istype(connection))
		room_connections += connection

/datum/world_edit_building_layout_candidate/proc/add_door_plan(datum/world_edit_building_layout_route_opening_plan/opening_plan)
	if(istype(opening_plan))
		opening_plans += opening_plan

/datum/world_edit_building_layout_candidate/proc/add_window_plan(datum/world_edit_building_layout_route_opening_plan/opening_plan)
	if(istype(opening_plan))
		window_plans += opening_plan

/datum/world_edit_building_layout_room_allocation_request
	var/id = ""
	var/contract_id = ""
	var/role = ""
	var/zone_id = ""
	var/relation_zone = ""
	var/x1 = 1
	var/y1 = 1
	var/x2 = 1
	var/y2 = 1
	var/align_x = "center"
	var/align_y = "center"

/datum/world_edit_building_layout_room_allocation_request/New(_id = "", _contract_id = "", _role = "", _zone_id = "", _relation_zone = "", _x1 = 1, _y1 = 1, _x2 = 1, _y2 = 1, _align_x = "center", _align_y = "center")
	. = ..()
	id = "[_id]"
	contract_id = length("[_contract_id]") ? "[_contract_id]" : id
	role = "[_role]"
	zone_id = length("[_zone_id]") ? "[_zone_id]" : role
	relation_zone = "[_relation_zone]"
	x1 = round(text2num("[_x1]") || 1)
	y1 = round(text2num("[_y1]") || 1)
	x2 = round(text2num("[_x2]") || x1)
	y2 = round(text2num("[_y2]") || y1)
	align_x = length("[_align_x]") ? "[_align_x]" : "center"
	align_y = length("[_align_y]") ? "[_align_y]" : "center"

/datum/world_edit_building_layout_room_plan
	var/id = ""
	var/contract_id = ""
	var/role = ""
	var/zone_id = ""
	var/x1 = null
	var/y1 = null
	var/x2 = null
	var/y2 = null
	var/list/turfs = list()
	var/list/turf_lookup = list()
	var/list/door_candidates = list()
	var/list/window_candidates = list()
	var/scene_kind = ""
	var/datum/world_edit_building_layout_scene_plan/scene_plan = null
	var/spatial_kind = WORLD_EDIT_BUILDING_SPACE_FUNCTIONAL_ROOM
	var/counts_toward_target = TRUE
	var/topology_parent = ""
	var/graph_depth = 0

/datum/world_edit_building_layout_room_plan/New(_id = "", _contract_id = "", _role = "", _zone_id = "")
	. = ..()
	id = "[_id]"
	contract_id = length("[_contract_id]") ? "[_contract_id]" : id
	role = "[_role]"
	zone_id = length("[_zone_id]") ? "[_zone_id]" : role

/datum/world_edit_building_layout_room_plan/proc/add_turf(turf/target_turf)
	if(!istype(target_turf) || turf_lookup[target_turf])
		return
	turfs += target_turf
	turf_lookup[target_turf] = TRUE
	if(isnull(x1) || target_turf.x < x1)
		x1 = target_turf.x
	if(isnull(x2) || target_turf.x > x2)
		x2 = target_turf.x
	if(isnull(y1) || target_turf.y < y1)
		y1 = target_turf.y
	if(isnull(y2) || target_turf.y > y2)
		y2 = target_turf.y

/datum/world_edit_building_layout_room_plan/proc/has_turf(turf/target_turf)
	return istype(target_turf) && turf_lookup[target_turf]

/datum/world_edit_building_layout_room_plan/proc/width()
	return isnull(x1) || isnull(x2) ? 0 : max(x2 - x1 + 1, 0)

/datum/world_edit_building_layout_room_plan/proc/height()
	return isnull(y1) || isnull(y2) ? 0 : max(y2 - y1 + 1, 0)

/datum/world_edit_building_layout_room_plan/proc/area()
	return length(turfs)

/datum/world_edit_building_layout_route_opening_plan
	var/id = ""
	var/kind = "door"
	var/from_room = ""
	var/to_room = ""
	var/turf/opening_turf
	var/list/opening_turfs = list()
	var/opening_width = 1
	var/emits_door_object = TRUE
	var/public_opening = FALSE
	var/dir = NORTH

/datum/world_edit_building_layout_route_opening_plan/New(_id = "", _kind = "door", turf/_opening_turf = null, _dir = NORTH, _from_room = "", _to_room = "")
	. = ..()
	id = "[_id]"
	kind = length("[_kind]") ? "[_kind]" : "door"
	opening_turf = _opening_turf
	if(istype(opening_turf))
		opening_turfs = list(opening_turf)
	opening_width = max(length(opening_turfs), 1)
	public_opening = kind in list(WORLD_EDIT_BUILDING_OPENING_ARCH, WORLD_EDIT_BUILDING_OPENING_WIDE_ARCH)
	emits_door_object = kind in list(WORLD_EDIT_BUILDING_OPENING_DOOR, WORLD_EDIT_BUILDING_OPENING_SECURE_DOOR, "main_exit")
	dir = _dir
	if(!(dir in GLOB.cardinals))
		dir = NORTH
	from_room = "[_from_room]"
	to_room = "[_to_room]"

/datum/world_edit_building_layout_room_connection
	var/id = ""
	var/from_room_id = ""
	var/to_room_id = ""
	var/kind = "door"
	var/privacy = "public"
	var/required = TRUE
	var/min_shared_wall_length = 3
	var/max_door_count = 1
	var/prefer_center = TRUE
	var/allow_corner = FALSE

/datum/world_edit_building_layout_room_connection/New(_id = "", _from_room_id = "", _to_room_id = "", _privacy = "public", _required = TRUE, _kind = "door")
	. = ..()
	id = "[_id]"
	from_room_id = "[_from_room_id]"
	to_room_id = "[_to_room_id]"
	privacy = length("[_privacy]") ? "[_privacy]" : "public"
	required = _required ? TRUE : FALSE
	kind = length("[_kind]") ? "[_kind]" : "door"

/datum/world_edit_building_layout_opening_candidate
	var/id = ""
	var/turf/opening_turf
	var/dir = NORTH
	var/from_room_id = ""
	var/to_room_id = ""
	var/segment_index = 0
	var/segment_len = 0
	var/segment_center_distance = 0
	var/corner = FALSE
	var/near_other_door = FALSE
	var/front_clear = FALSE
	var/back_clear = FALSE
	var/privacy = "public"
	var/privacy_penalty = 0
	var/score = 0
	var/list/opening_turfs = list()
	var/list/reject_reasons = list()

/datum/world_edit_building_layout_influence_zone
	var/id = ""
	var/role = ""
	var/x1 = 0
	var/y1 = 0
	var/x2 = 0
	var/y2 = 0
	var/list/preferred_room_contracts = list()
	var/list/forbidden_room_contracts = list()
	var/priority = 0

/datum/world_edit_building_layout_influence_zone/New(_id = "", _role = "", _x1 = 0, _y1 = 0, _x2 = 0, _y2 = 0, list/_preferred_room_contracts = null, _priority = 0)
	. = ..()
	id = "[_id]"
	role = "[_role]"
	x1 = round(text2num("[_x1]") || 0)
	y1 = round(text2num("[_y1]") || 0)
	x2 = round(text2num("[_x2]") || 0)
	y2 = round(text2num("[_y2]") || 0)
	preferred_room_contracts = islist(_preferred_room_contracts) ? _preferred_room_contracts.Copy() : list()
	priority = round(text2num("[_priority]") || 0)

/datum/world_edit_building_layout_route_hint
	var/id = ""
	var/kind = "line"
	var/x1 = 0
	var/y1 = 0
	var/x2 = 0
	var/y2 = 0
	var/list/zone_ids = list()

/datum/world_edit_building_layout_route_hint/New(_id = "", _kind = "line", _x1 = 0, _y1 = 0, _x2 = 0, _y2 = 0, list/_zone_ids = null)
	. = ..()
	id = "[_id]"
	kind = length("[_kind]") ? "[_kind]" : "line"
	x1 = round(text2num("[_x1]") || 0)
	y1 = round(text2num("[_y1]") || 0)
	x2 = round(text2num("[_x2]") || x1)
	y2 = round(text2num("[_y2]") || y1)
	zone_ids = islist(_zone_ids) ? _zone_ids.Copy() : list()

/datum/world_edit_building_layout_region_candidate
	var/id = ""
	var/pattern_id = ""
	var/score = 0
	var/list/influence_zones = list()
	var/list/route_hints = list()
	var/list/room_connections = list()
	var/datum/world_edit_building_layout_topology_graph/topology_graph = null
	var/topology_family = ""
	var/list/family_constraints = list()
	var/family_policy_id = ""
	var/orientation_variant = 0

/datum/world_edit_building_layout_region_candidate/New(_pattern_id = "", _id = "", _score = 0)
	. = ..()
	pattern_id = "[_pattern_id]"
	id = length("[_id]") ? "[_id]" : pattern_id
	score = round(text2num("[_score]") || 0)

/datum/world_edit_building_layout_region_candidate/proc/add_influence_zone(zone_id, role, x1, y1, x2, y2, list/preferred_room_contracts = null, priority = 0)
	var/datum/world_edit_building_layout_influence_zone/zone = new(zone_id, role, x1, y1, x2, y2, preferred_room_contracts, priority)
	influence_zones += zone
	return zone

/datum/world_edit_building_layout_region_candidate/proc/add_route_hint(hint_id, kind, x1, y1, x2, y2, list/zone_ids = null)
	var/datum/world_edit_building_layout_route_hint/hint = new(hint_id, kind, x1, y1, x2, y2, zone_ids)
	route_hints += hint
	return hint

/datum/world_edit_building_layout_region_candidate/proc/add_connection(connection_id, from_room_id, to_room_id, privacy = "public", required = TRUE, kind = "door")
	var/datum/world_edit_building_layout_room_connection/connection = new(connection_id, from_room_id, to_room_id, privacy, required, kind)
	room_connections += connection
	return connection

/datum/world_edit_building_layout_scene_contract
	var/id = ""
	var/scene_kind = ""
	var/list/allowed_programs = list()
	var/list/allowed_room_roles = list()
	var/list/allowed_room_ids = list()
	var/required = FALSE
	var/primary = TRUE
	var/scene_layer = "primary"
	var/min_room_area = 1
	var/min_room_width = 1
	var/min_room_height = 1
	var/max_per_room = 1
	var/max_per_building = 999
	var/max_occupancy_ratio = 50
	var/min_free_ratio = 30
	var/list/primary_modules = list()
	var/list/secondary_modules = list()
	var/list/detail_modules = list()
	var/primary_anchor_policy = "center"
	var/secondary_anchor_policy = "free_walls"
	var/negative_space_policy = "door_to_focus"
	var/max_primary_count = 1
	var/max_secondary_count = 2
	var/max_detail_count = 2
	var/min_negative_space_tiles = 1
	var/list/required_modules = list()
	var/list/optional_modules = list()
	var/list/scene_slot_limits = list()
	var/list/forbidden_module_slots = list()
	var/list/module_specs = list()
	var/fallback_slot = "light"
	var/fallback_category = "light"

/datum/world_edit_building_layout_scene_contract/New(_id = "", _scene_kind = "")
	. = ..()
	id = "[_id]"
	scene_kind = length("[_scene_kind]") ? "[_scene_kind]" : id

/datum/world_edit_building_layout_composition_contract
	var/id = ""
	var/room_id = ""
	var/scene_contract_id = ""
	var/instance_policy = WORLD_EDIT_BUILDING_CLUSTER_GLOBAL_ONCE
	var/list/required_groups = list()
	var/list/optional_groups = list()
	var/min_negative_space_tiles = 1
	var/reserve_interaction_lane = TRUE

/datum/world_edit_building_layout_composition_contract/New(_id = "", _room_id = "", _scene_contract_id = "")
	. = ..()
	id = "[_id]"
	room_id = "[_room_id]"
	scene_contract_id = "[_scene_contract_id]"

/datum/world_edit_building_layout_scene_plan
	var/id = ""
	var/scene_contract_id = ""
	var/scene_kind = ""
	var/room_id = ""
	var/room_contract_id = ""
	var/primary = TRUE
	var/list/members = list()
	var/list/occupied_turfs = list()
	var/list/clearance_turfs = list()
	var/list/primary_anchors = list()
	var/list/secondary_anchors = list()
	var/list/detail_anchors = list()
	var/list/negative_space_turfs = list()
	var/list/no_furniture_lookup = list()
	var/list/scene_slot_counts = list()
	var/score = 0

/datum/world_edit_building_layout_scene_plan/proc/add_member(slot, category, turf/member_turf, dir_to_use = SOUTH, scene_slot = "", wall_mounted = FALSE, major = FALSE, datum/world_edit_building_cluster_spec/cluster_spec = null)
	if(!istype(member_turf))
		return
	var/list/member = list(
		"slot" = "[slot]",
		"category" = "[category]",
		"turf" = member_turf,
		"dir" = dir_to_use,
		"scene_slot" = length("[scene_slot]") ? "[scene_slot]" : "[slot]",
		"wall_mounted" = wall_mounted ? TRUE : FALSE,
		"major" = major ? TRUE : FALSE,
	)
	if(istype(cluster_spec))
		member["cluster_spec"] = cluster_spec
	members += list(member)
	occupied_turfs += member_turf
	if(major)
		scene_slot_counts[member["scene_slot"]] = (scene_slot_counts[member["scene_slot"]] || 0) + 1

/datum/world_edit_building_layout_scene_budget
	var/list/limits = list()
	var/list/minimums = list()
	var/list/used = list()

/datum/world_edit_building_layout_scene_budget/proc/can_use(scene_slot, amount = 1)
	var/current = round(text2num("[used[scene_slot]]") || 0)
	var/limit = round(text2num("[limits[scene_slot]]") || 0)
	if(limit <= 0)
		return TRUE
	return current + amount <= limit

/datum/world_edit_building_layout_scene_budget/proc/use(scene_slot, amount = 1)
	used[scene_slot] = round(text2num("[used[scene_slot]]") || 0) + round(text2num("[amount]") || 0)

/datum/world_edit_building_layout_scene_budget/proc/missing_minimums()
	var/list/missing = list()
	for(var/scene_slot as anything in minimums)
		var/current = round(text2num("[used[scene_slot]]") || 0)
		var/minimum = round(text2num("[minimums[scene_slot]]") || 0)
		if(current < minimum)
			missing[scene_slot] = minimum - current
	return missing
