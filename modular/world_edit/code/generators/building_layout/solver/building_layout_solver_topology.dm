#define WORLD_EDIT_BUILDING_ALLOCATION_BEAM_WIDTH 6
#define WORLD_EDIT_BUILDING_ALLOCATION_RECTS_PER_NODE 8
#define WORLD_EDIT_BUILDING_ALLOCATION_MAX_EXPANSIONS 96

/datum/world_edit_building_layout_family_policy
	var/id = ""
	var/min_width = 9
	var/min_height = 9

/datum/world_edit_building_layout_family_policy/proc/can_solve(datum/world_edit_building_layout_context/context)
	return istype(context) && context.local_width() >= min_width && context.local_height() >= min_height

/datum/world_edit_building_layout_family_policy/proc/build_constraints(datum/world_edit_building_layout_context/context, orientation_variant = 0)
	var/list/result = list(
		"family" = id,
		"orientation" = orientation_variant,
		"requires_root_first" = TRUE,
		"requires_edge_geometry" = TRUE,
	)
	switch(id)
		if("hub_spoke")
			result["root_position"] = "center"
			result["spoke_count"] = 5
		if("split_wing")
			result["wing_count"] = 2
			result["central_transition"] = TRUE
		if("open_bay_perimeter")
			result["open_bay_min_percent"] = 35
			result["open_bay_max_percent"] = 60
			result["perimeter_services"] = TRUE
		if("secure_core")
			result["secure_core"] = TRUE
			result["controlled_transition"] = TRUE
		if("nested_service")
			result["requires_nested_parent_child"] = TRUE
			result["child_after_parent"] = TRUE
		if("compound_cells")
			result["compound_pods"] = 4
			result["courtyard"] = TRUE
		if("axial_fallback")
			result["axial_fallback_only"] = TRUE
	return result

/datum/world_edit_building_layout_family_policy/proc/build_seed_regions(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_region_candidate/region, orientation_variant = 0)
	switch(id)
		if("hub_spoke") return build_hub_spoke_seed_regions(context, region, orientation_variant)
		if("split_wing") return build_split_wing_seed_regions(context, region, orientation_variant)
		if("open_bay_perimeter") return build_open_bay_perimeter_seed_regions(context, region, orientation_variant)
		if("secure_core") return build_secure_core_seed_regions(context, region, orientation_variant)
		if("nested_service") return build_nested_service_seed_regions(context, region, orientation_variant)
		if("compound_cells") return build_compound_cells_seed_regions(context, region, orientation_variant)
		if("axial_fallback") return build_axial_fallback_seed_regions(context, region, orientation_variant)
	return FALSE

/datum/world_edit_building_layout_family_policy/proc/score_partial(datum/world_edit_building_layout_context/context, list/placements)
	return islist(placements) ? length(placements) * 100 : 0

/datum/world_edit_building_layout_family_policy/proc/hard_validate(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate)
	return istype(candidate) && candidate.family_policy_id == id && length(candidate.room_plans)

/datum/world_edit_building_layout_family_policy/proc/add_seed_zone(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_region_candidate/region, zone_id, role, x1, y1, x2, y2, list/room_ids, priority, orientation_variant)
	if(!istype(context) || !istype(region) || !islist(room_ids) || !length(room_ids))
		return
	var/w = context.local_width()
	var/h = context.local_height()
	if(orientation_variant % 2)
		var/old_x1 = x1
		var/old_x2 = x2
		x1 = y1
		x2 = y2
		y1 = old_x1
		y2 = old_x2
	x1 = clamp(round(x1), 2, max(w - 1, 2))
	x2 = clamp(round(x2), 2, max(w - 1, 2))
	y1 = clamp(round(y1), 2, max(h - 1, 2))
	y2 = clamp(round(y2), 2, max(h - 1, 2))
	region.add_influence_zone(zone_id, role, min(x1, x2), min(y1, y2), max(x1, x2), max(y1, y2), room_ids, priority)

/datum/world_edit_generator/building_layout/proc/build_building_layout_family_groups(datum/world_edit_building_layout_context/context)
	var/list/root_rooms = list()
	var/list/public_rooms = list()
	var/list/secure_rooms = list()
	var/list/nested_rooms = list()
	var/list/other_rooms = list()
	var/list/groups = list()
	var/root_id = "[context.program_contract.topology_graph.root_node_id || ""]"
	for(var/room_index in 1 to length(context.program_contract.functional_room_contracts))
		var/datum/world_edit_building_layout_room_contract/room = context.program_contract.functional_room_contracts[room_index]
		if(isnull(room))
			continue
		var/datum/world_edit_building_layout_topology_node/topology_node = context.program_contract.topology_graph.get_node(room.id)
		if(room.id == root_id)
			root_rooms += room.id
		else if(room.privacy_class == "secure" || room.partition_policy == WORLD_EDIT_BUILDING_PARTITION_SECURE)
			secure_rooms += room.id
		else if(room.spatial_kind == WORLD_EDIT_BUILDING_SPACE_NESTED_ROOM || context.generator.building_layout_topology_node_has_nested_parent(context.program_contract.topology_graph, topology_node))
			nested_rooms += room.id
		else if(room.privacy_class == "public" || room.spatial_kind == WORLD_EDIT_BUILDING_SPACE_OPEN_BAY || room.role in list("hub", "public", "public_med", "staging"))
			public_rooms += room.id
		else
			other_rooms += room.id
	if(!length(root_rooms) && length(context.program_contract.functional_room_contracts))
		var/datum/world_edit_building_layout_room_contract/first_room = context.program_contract.functional_room_contracts[1]
		root_rooms += first_room.id
		other_rooms -= first_room.id
	groups["root"] = root_rooms.Copy()
	groups["public"] = public_rooms.Copy()
	groups["secure"] = secure_rooms.Copy()
	groups["nested"] = nested_rooms.Copy()
	groups["other"] = other_rooms.Copy()
	return groups

/datum/world_edit_generator/building_layout/proc/building_layout_topology_node_has_nested_parent(datum/world_edit_building_layout_topology_graph/graph, datum/world_edit_building_layout_topology_node/node)
	if(!istype(graph) || !istype(node) || !length(node.parent_id))
		return FALSE
	for(var/datum/world_edit_building_layout_topology_edge/edge as anything in graph.get_edges_for(node.id))
		if(!istype(edge) || edge.kind != WORLD_EDIT_BUILDING_EDGE_NESTED)
			continue
		var/other_id = edge.from_id == node.id ? edge.to_id : edge.from_id
		if(other_id == node.parent_id)
			return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/split_building_layout_ids_round_robin(list/source, bucket_count)
	var/list/result = list()
	for(var/index in 1 to max(bucket_count, 1))
		result.len++
		result[result.len] = list()
	var/source_index = 0
	for(var/id as anything in source)
		source_index++
		var/bucket_index = ((source_index - 1) % length(result)) + 1
		var/list/bucket = result[bucket_index]
		bucket += id
		result[bucket_index] = bucket
	return result

/datum/world_edit_generator/building_layout/proc/split_building_layout_atomic_topology_groups(datum/world_edit_building_layout_topology_graph/graph, list/source, bucket_count)
	var/list/result = list()
	for(var/index in 1 to max(bucket_count, 1))
		result.len++
		result[result.len] = list()
	if(!istype(graph) || !islist(source) || !length(source))
		return result
	var/list/source_lookup = list()
	for(var/room_id as anything in source)
		source_lookup["[room_id]"] = TRUE
	var/list/visited = list()
	var/list/components = list()
	for(var/source_id as anything in source)
		var/source_key = "[source_id]"
		if(visited[source_key])
			continue
		var/list/component = list()
		var/list/queue = list(source_key)
		visited[source_key] = TRUE
		var/queue_index = 1
		while(queue_index <= length(queue))
			var/current_id = "[queue[queue_index]]"
			queue_index++
			component += current_id
			for(var/datum/world_edit_building_layout_topology_edge/edge as anything in graph.get_edges_for(current_id))
				if(!istype(edge) || !edge.required || !(edge.kind in list(WORLD_EDIT_BUILDING_EDGE_NESTED, WORLD_EDIT_BUILDING_EDGE_SECURE)))
					continue
				var/other_id = edge.from_id == current_id ? edge.to_id : edge.from_id
				if(!source_lookup[other_id] || visited[other_id])
					continue
				visited[other_id] = TRUE
				queue += other_id
		components += list(component)
	for(var/list/component as anything in components)
		var/best_bucket_index = 1
		var/best_bucket_size = length(result[1])
		for(var/bucket_index in 2 to length(result))
			var/list/bucket = result[bucket_index]
			if(length(bucket) >= best_bucket_size)
				continue
			best_bucket_index = bucket_index
			best_bucket_size = length(bucket)
		var/list/best_bucket = result[best_bucket_index]
		best_bucket += component
		result[best_bucket_index] = best_bucket
	return result

/datum/world_edit_generator/building_layout/proc/sort_building_layout_ids_by_min_area(datum/world_edit_building_layout_context/context, list/source)
	var/list/result = list()
	if(!istype(context) || !islist(source))
		return result
	for(var/room_id as anything in source)
		var/datum/world_edit_building_layout_room_contract/room_contract = context.program_contract?.get_room_contract(room_id)
		var/inserted = FALSE
		for(var/index in 1 to length(result))
			var/datum/world_edit_building_layout_room_contract/existing_contract = context.program_contract?.get_room_contract(result[index])
			if((room_contract?.min_area || 0) <= (existing_contract?.min_area || 0))
				continue
			result.Insert(index, room_id)
			inserted = TRUE
			break
		if(!inserted)
			result += room_id
	return result

/datum/world_edit_building_layout_family_policy/hub_spoke
	id = "hub_spoke"

/datum/world_edit_building_layout_family_policy/hub_spoke/build_constraints(datum/world_edit_building_layout_context/context, orientation_variant = 0)
	var/list/result = ..()
	result["root_position"] = "center"
	result["spoke_count"] = 5
	return result

/datum/world_edit_building_layout_family_policy/proc/build_hub_spoke_seed_regions(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_region_candidate/region, orientation_variant = 0)
	var/list/groups = context.generator.build_building_layout_family_groups(context)
	var/w = context.local_width()
	var/h = context.local_height()
	var/cx = round((w + 1) / 2)
	var/cy = round((h + 1) / 2)
	// Keep a seven-cell long side on the hub and move it one cell away from
	// the entry. That gives one real front partition and two non-overlapping
	// partitions on each long side without inventing a rear spoke.
	add_seed_zone(context, region, "hub_root", "root", cx - 3, cy - 2, cx + 2, cy + 4, groups["root"], 200, orientation_variant)
	var/list/spoke_ids = groups["public"] + groups["secure"] + groups["nested"] + groups["other"]
	spoke_ids = context.generator.sort_building_layout_ids_by_min_area(context, spoke_ids)
	var/list/spokes = context.generator.split_building_layout_ids_round_robin(spoke_ids, 5)
	// The widest service footprint gets the four-cell outer side. The front
	// spoke remains three cells wide and leaves the entry terminal unobstructed.
	add_seed_zone(context, region, "spoke_front", "spoke", 2, 2, cx - 1, cy - 4, spokes[2], 120, orientation_variant)
	add_seed_zone(context, region, "spoke_right_front", "spoke", cx + 4, 2, w - 1, cy, spokes[1], 120, orientation_variant)
	add_seed_zone(context, region, "spoke_right_back", "spoke", cx + 4, cy + 2, w - 1, h - 1, spokes[3], 120, orientation_variant)
	add_seed_zone(context, region, "spoke_left_front", "spoke", 2, 2, cx - 5, cy, spokes[4], 120, orientation_variant)
	add_seed_zone(context, region, "spoke_left_back", "spoke", 2, cy + 2, cx - 5, h - 1, spokes[5], 120, orientation_variant)
	region.add_route_hint("hub_cross", "cross", cx, 2, cx, h - 1, list())
	return TRUE

/datum/world_edit_building_layout_family_policy/split_wing
	id = "split_wing"

/datum/world_edit_building_layout_family_policy/split_wing/build_constraints(datum/world_edit_building_layout_context/context, orientation_variant = 0)
	var/list/result = ..()
	result["wing_count"] = 2
	result["central_transition"] = TRUE
	return result

/datum/world_edit_building_layout_family_policy/proc/build_split_wing_seed_regions(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_region_candidate/region, orientation_variant = 0)
	var/list/groups = context.generator.build_building_layout_family_groups(context)
	var/list/all_ids = groups["root"] + groups["public"] + groups["secure"] + groups["nested"] + groups["other"]
	var/list/wings = context.generator.split_building_layout_atomic_topology_groups(context.program_contract.topology_graph, all_ids, 2)
	var/w = context.local_width()
	var/h = context.local_height()
	var/cx = round((w + 1) / 2)
	add_seed_zone(context, region, "wing_a", "wing", 2, 2, cx - 1, h - 1, wings[1], 140, orientation_variant)
	add_seed_zone(context, region, "wing_b", "wing", cx + 1, 2, w - 1, h - 1, wings[2], 140, orientation_variant)
	region.add_route_hint("wing_transition", "line", cx, 2, cx, h - 1, list())
	return TRUE

/datum/world_edit_building_layout_family_policy/open_bay_perimeter
	id = "open_bay_perimeter"

/datum/world_edit_building_layout_family_policy/open_bay_perimeter/build_constraints(datum/world_edit_building_layout_context/context, orientation_variant = 0)
	var/list/result = ..()
	result["open_bay_min_percent"] = 35
	result["open_bay_max_percent"] = 60
	result["perimeter_services"] = TRUE
	return result

/datum/world_edit_building_layout_family_policy/proc/build_open_bay_perimeter_seed_regions(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_region_candidate/region, orientation_variant = 0)
	var/list/groups = context.generator.build_building_layout_family_groups(context)
	var/w = context.local_width()
	var/h = context.local_height()
	var/open_bay_width = max(round((w - 2) * 0.67), 3)
	var/open_bay_height = max(round((h - 2) * 0.67), 3)
	var/margin_x = max(round((w + 1 - open_bay_width) / 2), 3)
	var/margin_y = max(round((h + 1 - open_bay_height) / 2), 3)
	var/list/bay_ids = groups["root"]
	var/list/perimeter_ids = groups["public"] + groups["secure"] + groups["nested"] + groups["other"]
	var/list/root_adjacent_ids = list()
	var/root_id = "[context.program_contract.topology_graph.root_node_id || ""]"
	for(var/datum/world_edit_building_layout_topology_edge/edge as anything in context.program_contract.topology_graph.get_edges_for(root_id))
		if(!istype(edge) || !edge.required || edge.kind == WORLD_EDIT_BUILDING_EDGE_ROUTE)
			continue
		var/other_id = edge.from_id == root_id ? edge.to_id : edge.from_id
		if(other_id in perimeter_ids)
			root_adjacent_ids |= other_id
	for(var/root_adjacent_id as anything in root_adjacent_ids)
		perimeter_ids -= root_adjacent_id
	var/list/perimeter = context.generator.split_building_layout_atomic_topology_groups(context.program_contract.topology_graph, perimeter_ids, 4)
	add_seed_zone(context, region, "named_open_bay", "open_bay", margin_x, margin_y, w - margin_x + 1, h - margin_y + 1, bay_ids, 220, orientation_variant)
	add_seed_zone(context, region, "open_bay_root_edge", "root_edge", 2, 2, w - 1, h - 1, root_adjacent_ids, 200, orientation_variant)
	add_seed_zone(context, region, "perimeter_front", "perimeter", 2, 2, w - 1, margin_y, perimeter[1], 130, orientation_variant)
	add_seed_zone(context, region, "perimeter_right", "perimeter", w - margin_x + 1, 2, w - 1, h - 1, perimeter[2], 130, orientation_variant)
	add_seed_zone(context, region, "perimeter_back", "perimeter", 2, h - margin_y + 1, w - 1, h - 1, perimeter[3], 130, orientation_variant)
	add_seed_zone(context, region, "perimeter_left", "perimeter", 2, 2, margin_x, h - 1, perimeter[4], 130, orientation_variant)
	return TRUE

/datum/world_edit_building_layout_family_policy/secure_core
	id = "secure_core"

/datum/world_edit_building_layout_family_policy/secure_core/build_constraints(datum/world_edit_building_layout_context/context, orientation_variant = 0)
	var/list/result = ..()
	result["secure_core"] = TRUE
	result["controlled_transition"] = TRUE
	return result

/datum/world_edit_building_layout_family_policy/proc/build_secure_core_seed_regions(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_region_candidate/region, orientation_variant = 0)
	var/list/groups = context.generator.build_building_layout_family_groups(context)
	var/w = context.local_width()
	var/h = context.local_height()
	var/cx = round((w + 1) / 2)
	var/cy = round((h + 1) / 2)
	var/list/core_ids = groups["secure"]
	if(!length(core_ids))
		core_ids = groups["root"].Copy()
	var/list/ring_ids = groups["root"] + groups["public"] + groups["nested"] + groups["other"]
	for(var/core_id as anything in core_ids)
		ring_ids -= core_id
	var/list/ring = context.generator.split_building_layout_ids_round_robin(ring_ids, 4)
	add_seed_zone(context, region, "secure_core", "secure", cx - 3, cy - 3, cx + 3, cy + 3, core_ids, 230, orientation_variant)
	add_seed_zone(context, region, "secure_ring_front", "ring", 2, 2, w - 1, cy - 3, ring[1], 120, orientation_variant)
	add_seed_zone(context, region, "secure_ring_right", "ring", cx + 3, 2, w - 1, h - 1, ring[2], 120, orientation_variant)
	add_seed_zone(context, region, "secure_ring_back", "ring", 2, cy + 3, w - 1, h - 1, ring[3], 120, orientation_variant)
	add_seed_zone(context, region, "secure_ring_left", "ring", 2, 2, cx - 3, h - 1, ring[4], 120, orientation_variant)
	return TRUE

/datum/world_edit_building_layout_family_policy/nested_service
	id = "nested_service"

/datum/world_edit_building_layout_family_policy/nested_service/build_constraints(datum/world_edit_building_layout_context/context, orientation_variant = 0)
	var/list/result = ..()
	result["requires_nested_parent_child"] = TRUE
	result["child_after_parent"] = TRUE
	return result

/datum/world_edit_building_layout_family_policy/proc/build_nested_service_seed_regions(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_region_candidate/region, orientation_variant = 0)
	var/list/groups = context.generator.build_building_layout_family_groups(context)
	var/w = context.local_width()
	var/h = context.local_height()
	var/list/parent_ids = groups["root"] + groups["public"]
	var/list/service_ids = groups["nested"] + groups["secure"]
	var/list/other_ids = groups["other"]
	add_seed_zone(context, region, "nested_parent", "parent", 2, 2, round(w * 0.7), h - 1, parent_ids, 210, orientation_variant)
	add_seed_zone(context, region, "nested_child", "child", round(w * 0.55), round(h * 0.35), w - 1, h - 1, service_ids, 190, orientation_variant)
	add_seed_zone(context, region, "nested_support", "support", round(w * 0.55), 2, w - 1, round(h * 0.45), other_ids, 120, orientation_variant)
	return TRUE

/datum/world_edit_building_layout_family_policy/compound_cells
	id = "compound_cells"

/datum/world_edit_building_layout_family_policy/compound_cells/build_constraints(datum/world_edit_building_layout_context/context, orientation_variant = 0)
	var/list/result = ..()
	result["compound_pods"] = 4
	result["courtyard"] = TRUE
	return result

/datum/world_edit_building_layout_family_policy/proc/build_compound_cells_seed_regions(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_region_candidate/region, orientation_variant = 0)
	var/list/groups = context.generator.build_building_layout_family_groups(context)
	var/list/all_ids = groups["root"] + groups["public"] + groups["secure"] + groups["nested"] + groups["other"]
	var/list/pods = context.generator.split_building_layout_ids_round_robin(all_ids, 4)
	var/w = context.local_width()
	var/h = context.local_height()
	var/cx = round((w + 1) / 2)
	var/cy = round((h + 1) / 2)
	add_seed_zone(context, region, "pod_nw", "pod", 2, 2, cx - 1, cy - 1, pods[1], 150, orientation_variant)
	add_seed_zone(context, region, "pod_ne", "pod", cx + 1, 2, w - 1, cy - 1, pods[2], 150, orientation_variant)
	add_seed_zone(context, region, "pod_se", "pod", cx + 1, cy + 1, w - 1, h - 1, pods[3], 150, orientation_variant)
	add_seed_zone(context, region, "pod_sw", "pod", 2, cy + 1, cx - 1, h - 1, pods[4], 150, orientation_variant)
	region.add_route_hint("compound_courtyard", "cross", cx, cy, cx, cy, list())
	return TRUE

/datum/world_edit_building_layout_family_policy/axial_fallback
	id = "axial_fallback"

/datum/world_edit_building_layout_family_policy/axial_fallback/can_solve(datum/world_edit_building_layout_context/context)
	if(!..())
		return FALSE
	var/w = context.local_width()
	var/h = context.local_height()
	var/aspect = max(w, h) / max(min(w, h), 1)
	return context.generator.is_building_compact_or_micro_state(context.state) || min(w, h) <= 11 || aspect >= 1.7

/datum/world_edit_building_layout_family_policy/axial_fallback/build_constraints(datum/world_edit_building_layout_context/context, orientation_variant = 0)
	var/list/result = ..()
	result["axial_fallback_only"] = TRUE
	return result

/datum/world_edit_building_layout_family_policy/proc/build_axial_fallback_seed_regions(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_region_candidate/region, orientation_variant = 0)
	var/list/groups = context.generator.build_building_layout_family_groups(context)
	var/list/all_ids = groups["root"] + groups["public"] + groups["secure"] + groups["nested"] + groups["other"]
	var/list/bands = context.generator.split_building_layout_ids_round_robin(all_ids, 2)
	var/w = context.local_width()
	var/h = context.local_height()
	var/cx = round((w + 1) / 2)
	add_seed_zone(context, region, "axial_a", "axial", 2, 2, cx - 1, h - 1, bands[1], 100, orientation_variant)
	add_seed_zone(context, region, "axial_b", "axial", cx + 1, 2, w - 1, h - 1, bands[2], 100, orientation_variant)
	region.add_route_hint("axial_route", "line", cx, 2, cx, h - 1, list())
	return TRUE

/datum/world_edit_generator/building_layout/proc/get_building_layout_family_policy(family_id)
	switch("[family_id]")
		if("hub_spoke") return new /datum/world_edit_building_layout_family_policy/hub_spoke()
		if("split_wing") return new /datum/world_edit_building_layout_family_policy/split_wing()
		if("open_bay_perimeter") return new /datum/world_edit_building_layout_family_policy/open_bay_perimeter()
		if("secure_core") return new /datum/world_edit_building_layout_family_policy/secure_core()
		if("nested_service") return new /datum/world_edit_building_layout_family_policy/nested_service()
		if("compound_cells") return new /datum/world_edit_building_layout_family_policy/compound_cells()
		if("axial_fallback") return new /datum/world_edit_building_layout_family_policy/axial_fallback()
	return null
