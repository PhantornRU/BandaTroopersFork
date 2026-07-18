/datum/world_edit_generator/building_layout/proc/allocate_building_layout_rooms_bounded(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate, allocation_variant = 0)
	if(!istype(context) || !istype(candidate))
		return FALSE
	if(!istype(candidate.region_candidate))
		candidate.errors += "room.alloc_invalid_region_candidate"
		return FALSE
	var/list/contracts = sort_building_layout_room_contracts_by_topology(candidate, context.program_contract.functional_room_contracts, allocation_variant)
	var/list/beam = list(new /datum/world_edit_building_layout_allocation_partial)
	var/partial_expansions = 0
	for(var/datum/world_edit_building_layout_room_contract/room_contract as anything in contracts)
		if(!istype(room_contract))
			continue
		var/datum/world_edit_building_layout_influence_zone/zone = get_building_layout_contract_seed_zone(candidate.region_candidate, room_contract.id)
		if(!istype(zone))
			if(room_contract.required)
				candidate.errors += "room.seed_region_missing:[room_contract.id]"
			return FALSE
		var/list/next_beam = list()
		for(var/datum/world_edit_building_layout_allocation_partial/partial as anything in beam)
			if(!istype(partial) || partial_expansions >= WORLD_EDIT_BUILDING_ALLOCATION_MAX_EXPANSIONS)
				continue
			partial_expansions++
			var/list/options = enumerate_building_layout_room_rects(context, candidate, partial, zone, room_contract, allocation_variant)
			for(var/list/option as anything in options)
				var/list/rect = option?["rect"]
				if(!islist(rect))
					continue
				var/datum/world_edit_building_layout_allocation_partial/child = partial.fork_with(room_contract.id, rect, option["score"])
				insert_building_layout_partial(next_beam, child, WORLD_EDIT_BUILDING_ALLOCATION_BEAM_WIDTH)
		if(!length(next_beam))
			if(room_contract.required)
				candidate.errors += "room.alloc_failed:[room_contract.id]"
			if(length(beam))
				candidate.errors += "room.alloc_partial:[format_building_layout_partial(beam[1])]"
			return FALSE
		beam = next_beam
	if(!length(beam))
		candidate.errors += "room.alloc_beam_empty"
		return FALSE
	var/datum/world_edit_building_layout_allocation_partial/winner = null
	for(var/datum/world_edit_building_layout_allocation_partial/complete_partial as anything in beam)
		if(istype(complete_partial) && building_layout_partial_route_network_possible(context, candidate, complete_partial))
			winner = complete_partial
			break
	if(!istype(winner))
		candidate.errors += "room.route_partial_unreachable"
		return FALSE
	for(var/room_id as anything in winner.placement_order)
		var/list/rect = winner.placements[room_id]
		var/datum/world_edit_building_layout_room_contract/room_contract = context.program_contract.get_room_contract(room_id)
		if(!islist(rect) || !istype(room_contract))
			candidate.errors += "room.alloc_materialize_missing:[room_id]"
			continue
		var/datum/world_edit_building_layout_room_plan/room_plan = add_building_layout_room_rect(context, candidate, room_contract.id, room_contract.id, room_contract.role, room_contract.zone_id, rect["x1"], rect["y1"], rect["x2"], rect["y2"])
		if(!istype(room_plan))
			candidate.errors += "room.alloc_emit_failed:[room_contract.id]"
			continue
		var/datum/world_edit_building_layout_topology_node/topology_node = candidate.topology_graph?.get_node(room_contract.id)
		var/datum/world_edit_building_layout_influence_zone/seed_zone = get_building_layout_contract_seed_zone(candidate.region_candidate, room_contract.id)
		room_plan.spatial_kind = seed_zone?.role == "open_bay" ? WORLD_EDIT_BUILDING_SPACE_OPEN_BAY : room_contract.spatial_kind
		room_plan.counts_toward_target = room_contract.counts_toward_target
		room_plan.topology_parent = topology_node?.parent_id || ""
		room_plan.graph_depth = topology_node?.depth || 0
	candidate.score += winner.score
	context.state.add_stage_report("layout_bounded_allocation", "ok", null, list("candidate_id" = candidate.id, "rooms" = length(candidate.room_plans), "partial_expansions" = partial_expansions, "score" = winner.score, "placements" = format_building_layout_partial(winner)))
	return !length(candidate.errors)

/datum/world_edit_generator/building_layout/proc/format_building_layout_partial(datum/world_edit_building_layout_allocation_partial/partial)
	if(!istype(partial))
		return "invalid"
	var/list/parts = list()
	for(var/room_id as anything in partial.placement_order)
		var/list/rect = partial.placements[room_id]
		parts += "[room_id]=[rect?["x1"]],[rect?["y1"]]-[rect?["x2"]],[rect?["y2"]]"
	return jointext(parts, "|")

/datum/world_edit_generator/building_layout/proc/get_building_layout_contract_seed_zone(datum/world_edit_building_layout_region_candidate/region, room_id)
	if(!istype(region))
		return null
	for(var/datum/world_edit_building_layout_influence_zone/zone as anything in region.influence_zones)
		if(istype(zone) && "[room_id]" in zone.preferred_room_contracts)
			return zone
	return null

/datum/world_edit_generator/building_layout/proc/enumerate_building_layout_room_rects(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate, datum/world_edit_building_layout_allocation_partial/partial, datum/world_edit_building_layout_influence_zone/zone, datum/world_edit_building_layout_room_contract/room_contract, allocation_variant = 0)
	var/list/result = list()
	if(!istype(context) || !istype(candidate) || !istype(partial) || !istype(zone) || !istype(room_contract))
		return result
	// The authored preferred area applies to the primary instance.  Repeated
	// instances are already composition-sized by the compiler; targeting that
	// hard-safe minimum keeps the bounded beam from spending the whole footprint
	// on the first copies and then failing the final required sibling.
	var/target_area = allocation_variant == 1 || room_contract.instance_index > 1 ? room_contract.min_area : room_contract.preferred_area
	var/list/size_variants = build_building_layout_room_size_variants(room_contract, target_area, allocation_variant)
	if(candidate.topology_graph?.root_node_id == room_contract.id)
		var/list/root_variants = list()
		root_variants += list(list("w" = 7, "h" = 7))
		root_variants += list(list("w" = 6, "h" = 7))
		root_variants += list(list("w" = 7, "h" = 6))
		size_variants = root_variants + size_variants
	for(var/list/size_variant as anything in size_variants)
		var/room_w = round(text2num("[size_variant?["w"]]") || 0)
		var/room_h = round(text2num("[size_variant?["h"]]") || 0)
		if(room_w <= 0 || room_h <= 0 || room_w > building_layout_rect_width(list("x1" = zone.x1, "y1" = zone.y1, "x2" = zone.x2, "y2" = zone.y2)) || room_h > building_layout_rect_height(list("x1" = zone.x1, "y1" = zone.y1, "x2" = zone.x2, "y2" = zone.y2)))
			continue
		var/x_span = zone.x2 - room_w + 1
		var/y_span = zone.y2 - room_h + 1
		var/list/x_positions = build_building_layout_axis_anchors(zone.x1, x_span, allocation_variant % 2)
		var/list/y_positions = build_building_layout_axis_anchors(zone.y1, y_span, allocation_variant >= 2)
		add_building_layout_partial_edge_anchors(candidate.topology_graph, partial, room_contract.id, room_w, room_h, x_positions, y_positions)
		add_building_layout_partial_packing_anchors(partial, room_w, room_h, x_positions, y_positions)
		for(var/local_x1 as anything in x_positions)
			if(local_x1 < zone.x1 || local_x1 > x_span)
				continue
			for(var/local_y1 as anything in y_positions)
				if(local_y1 < zone.y1 || local_y1 > y_span)
					continue
				var/list/rect = build_building_layout_rect(local_x1, local_y1, local_x1 + room_w - 1, local_y1 + room_h - 1)
				if(!building_layout_room_rect_valid_for_contract(context, rect, room_contract) || !building_layout_room_rect_inside_footprint(context, rect))
					continue
				if(building_layout_partial_rect_conflicts(partial, rect))
					continue
				if(!building_layout_partial_required_edges_fit(candidate.topology_graph, partial, room_contract.id, rect))
					continue
				var/score = score_building_layout_partial_rect(context, candidate, partial, room_contract, zone, rect, target_area, allocation_variant)
				insert_building_layout_rect_option(result, list(
					"rect" = rect,
					"score" = score,
					"spatial_bucket" = get_building_layout_rect_spatial_bucket(zone, rect),
				), WORLD_EDIT_BUILDING_ALLOCATION_RECTS_PER_NODE)
	return result

/datum/world_edit_generator/building_layout/proc/get_building_layout_rect_spatial_bucket(datum/world_edit_building_layout_influence_zone/zone, list/rect)
	if(!istype(zone) || !islist(rect))
		return "invalid"
	var/zone_width = max(zone.x2 - zone.x1 + 1, 1)
	var/center_x = round((rect["x1"] + rect["x2"]) / 2)
	var/center_y = round((rect["y1"] + rect["y2"]) / 2)
	var/x_bucket = clamp(round((center_x - zone.x1) * 4 / zone_width), 0, 3)
	var/y_bucket = center_y <= round((zone.y1 + zone.y2) / 2) ? 0 : 1
	return "[x_bucket]:[y_bucket]"

/datum/world_edit_generator/building_layout/proc/add_building_layout_partial_edge_anchors(datum/world_edit_building_layout_topology_graph/graph, datum/world_edit_building_layout_allocation_partial/partial, room_id, room_w, room_h, list/x_positions, list/y_positions)
	if(!istype(graph) || !istype(partial) || !islist(x_positions) || !islist(y_positions))
		return
	for(var/datum/world_edit_building_layout_topology_edge/edge as anything in graph.get_edges_for(room_id))
		if(!istype(edge) || !edge.required || edge.kind == WORLD_EDIT_BUILDING_EDGE_ROUTE)
			continue
		var/other_id = edge.from_id == room_id ? edge.to_id : edge.from_id
		var/list/other_rect = partial.placements[other_id]
		if(!islist(other_rect))
			continue
		var/required_overlap = max(edge.min_shared_wall, 1)
		// Exact partition-distance anchors make geometry-aware edges reachable
		// without widening the bounded scan or relying on a later repair pass.
		x_positions |= other_rect["x2"] + 2
		x_positions |= other_rect["x1"] - room_w - 1
		x_positions |= other_rect["x1"]
		x_positions |= other_rect["x2"] - room_w + 1
		x_positions |= other_rect["x1"] - room_w + required_overlap
		x_positions |= other_rect["x2"] - required_overlap + 1
		y_positions |= other_rect["y2"] + 2
		y_positions |= other_rect["y1"] - room_h - 1
		y_positions |= other_rect["y1"]
		y_positions |= other_rect["y2"] - room_h + 1
		y_positions |= other_rect["y1"] - room_h + required_overlap
		y_positions |= other_rect["y2"] - required_overlap + 1

/datum/world_edit_generator/building_layout/proc/add_building_layout_partial_packing_anchors(datum/world_edit_building_layout_allocation_partial/partial, room_w, room_h, list/x_positions, list/y_positions)
	if(!istype(partial) || !islist(x_positions) || !islist(y_positions))
		return
	// Siblings which share the same family region still need bounded positions
	// beside each other.  Anchoring to their partition edge prevents a valid
	// final room from disappearing between the five coarse region anchors.
	for(var/existing_id as anything in partial.placement_order)
		var/list/existing_rect = partial.placements[existing_id]
		if(!islist(existing_rect))
			continue
		x_positions |= existing_rect["x2"] + 2
		x_positions |= existing_rect["x1"] - room_w - 1
		x_positions |= existing_rect["x1"]
		x_positions |= existing_rect["x2"] - room_w + 1
		y_positions |= existing_rect["y2"] + 2
		y_positions |= existing_rect["y1"] - room_h - 1
		y_positions |= existing_rect["y1"]
		y_positions |= existing_rect["y2"] - room_h + 1

/datum/world_edit_generator/building_layout/proc/build_building_layout_axis_anchors(axis_min, axis_max, reverse_order = FALSE)
	var/list/result = list()
	result |= reverse_order ? axis_max : axis_min
	result |= reverse_order ? axis_min : axis_max
	result |= round((axis_min + axis_max) / 2)
	result |= round((axis_min * 3 + axis_max) / 4)
	result |= round((axis_min + axis_max * 3) / 4)
	return result

/datum/world_edit_generator/building_layout/proc/building_layout_partial_rect_conflicts(datum/world_edit_building_layout_allocation_partial/partial, list/rect)
	if(!istype(partial) || !islist(rect))
		return TRUE
	for(var/existing_id as anything in partial.placement_order)
		var/list/existing = partial.placements[existing_id]
		if(!islist(existing))
			continue
		var/list/partition_reserve = build_building_layout_rect(existing["x1"] - 1, existing["y1"] - 1, existing["x2"] + 1, existing["y2"] + 1)
		if(building_layout_rects_intersect(partition_reserve, rect))
			return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/building_layout_partial_required_edges_fit(datum/world_edit_building_layout_topology_graph/graph, datum/world_edit_building_layout_allocation_partial/partial, room_id, list/rect)
	if(!istype(graph) || !istype(partial) || !islist(rect))
		return FALSE
	for(var/datum/world_edit_building_layout_topology_edge/edge as anything in graph.get_edges_for(room_id))
		if(!istype(edge) || !edge.required || edge.kind == WORLD_EDIT_BUILDING_EDGE_ROUTE)
			continue
		var/other_id = edge.from_id == room_id ? edge.to_id : edge.from_id
		var/list/other_rect = partial.placements[other_id]
		if(!islist(other_rect))
			continue
		if(building_layout_rect_partition_overlap(rect, other_rect) < max(edge.min_shared_wall, 1))
			return FALSE
	return TRUE

/datum/world_edit_generator/building_layout/proc/building_layout_rect_partition_overlap(list/a, list/b)
	if(!islist(a) || !islist(b))
		return 0
	if(a["x2"] + 2 == b["x1"] || b["x2"] + 2 == a["x1"])
		return max(min(a["y2"], b["y2"]) - max(a["y1"], b["y1"]) + 1, 0)
	if(a["y2"] + 2 == b["y1"] || b["y2"] + 2 == a["y1"])
		return max(min(a["x2"], b["x2"]) - max(a["x1"], b["x1"]) + 1, 0)
	return 0

/datum/world_edit_generator/building_layout/proc/building_layout_partial_route_network_possible(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate, datum/world_edit_building_layout_allocation_partial/partial)
	var/datum/world_edit_building_layout_state/state = context?.state
	if(!istype(state) || !istype(candidate) || !istype(partial))
		return FALSE
	var/list/owner_by_turf = list()
	for(var/room_id as anything in partial.placement_order)
		var/list/rect = partial.placements[room_id]
		if(!islist(rect))
			continue
		for(var/local_x in rect["x1"] to rect["x2"])
			for(var/local_y in rect["y1"] to rect["y2"])
				var/turf/room_turf = context.local_turf(local_x, local_y)
				if(istype(room_turf))
					owner_by_turf[room_turf] = "[room_id]"
	var/list/free_lookup = list()
	for(var/turf/interior_turf as anything in state.geometry.footprint)
		if(!istype(interior_turf) || state.geometry.boundary_lookup[interior_turf] || owner_by_turf[interior_turf])
			continue
		var/is_partition_gap = FALSE
		for(var/check_dir in list(NORTH, EAST))
			var/owner_a = "[owner_by_turf[get_step(interior_turf, check_dir)] || ""]"
			var/owner_b = "[owner_by_turf[get_step(interior_turf, turn(check_dir, 180))] || ""]"
			if(length(owner_a) && length(owner_b) && owner_a != owner_b)
				is_partition_gap = TRUE
				break
		if(!is_partition_gap)
			free_lookup[interior_turf] = TRUE
	var/entry_dir = state.geometry.requested_direction || state.placement_dir || NORTH
	if(!(entry_dir in GLOB.cardinals))
		entry_dir = NORTH
	var/turf/center_turf = context.local_turf(round((context.local_width() + 1) / 2), round((context.local_height() + 1) / 2))
	var/turf/entry_seed = null
	var/best_entry_distance = 999999
	for(var/turf/boundary_turf as anything in state.geometry.boundary)
		if(!istype(boundary_turf) || !boundary_turf_has_outside_dir(boundary_turf, state.geometry.footprint_lookup, entry_dir) || is_corner_boundary_turf(boundary_turf, state.geometry.footprint_lookup))
			continue
		var/turf/inside_turf = get_step(boundary_turf, turn(entry_dir, 180))
		if(!free_lookup[inside_turf])
			continue
		var/entry_distance = istype(center_turf) ? abs(inside_turf.x - center_turf.x) + abs(inside_turf.y - center_turf.y) : 0
		if(!istype(entry_seed) || entry_distance < best_entry_distance)
			entry_seed = inside_turf
			best_entry_distance = entry_distance
	if(!istype(entry_seed))
		return FALSE
	var/list/reachable = list()
	reachable[entry_seed] = TRUE
	var/list/open = list(entry_seed)
	var/open_index = 1
	while(open_index <= length(open))
		var/turf/current = open[open_index++]
		for(var/check_dir in GLOB.cardinals)
			var/turf/nearby = get_step(current, check_dir)
			if(!free_lookup[nearby] || reachable[nearby])
				continue
			reachable[nearby] = TRUE
			open += nearby
	var/list/terminal_ids = list()
	for(var/datum/world_edit_building_layout_topology_edge/edge as anything in candidate.topology_graph?.edges)
		if(!istype(edge) || !edge.required || edge.kind != WORLD_EDIT_BUILDING_EDGE_ROUTE)
			continue
		var/datum/world_edit_building_layout_room_contract/from_contract = context.program_contract?.get_room_contract(edge.from_id)
		var/datum/world_edit_building_layout_room_contract/to_contract = context.program_contract?.get_room_contract(edge.to_id)
		if(istype(from_contract) && from_contract.counts_toward_target)
			terminal_ids |= from_contract.id
		if(istype(to_contract) && to_contract.counts_toward_target)
			terminal_ids |= to_contract.id
	for(var/terminal_id as anything in terminal_ids)
		var/list/terminal_rect = partial.placements[terminal_id]
		var/datum/world_edit_building_layout_room_contract/terminal_contract = context.program_contract?.get_room_contract(terminal_id)
		if(!islist(terminal_rect) || !istype(terminal_contract) || !building_layout_partial_rect_has_route_access(context, terminal_rect, terminal_contract, free_lookup, reachable))
			return FALSE
	return TRUE

/datum/world_edit_generator/building_layout/proc/building_layout_partial_rect_has_route_access(datum/world_edit_building_layout_context/context, list/rect, datum/world_edit_building_layout_room_contract/room_contract, list/free_lookup, list/reachable)
	if(!istype(context) || !islist(rect) || !istype(room_contract) || !islist(free_lookup) || !islist(reachable))
		return FALSE
	var/required_width = max(room_contract.min_route_opening_width, 1)
	if(room_contract.spatial_kind == WORLD_EDIT_BUILDING_SPACE_OPEN_BAY || (room_contract.route_opening_kind in list(WORLD_EDIT_BUILDING_OPENING_ARCH, WORLD_EDIT_BUILDING_OPENING_WIDE_ARCH)))
		required_width = max(required_width, 2)
	for(var/check_dir in GLOB.cardinals)
		var/axis_start = (check_dir in list(NORTH, SOUTH)) ? rect["x1"] : rect["y1"]
		var/axis_end = (check_dir in list(NORTH, SOUTH)) ? rect["x2"] : rect["y2"]
		for(var/run_start in axis_start to axis_end - required_width + 1)
			var/run_valid = TRUE
			for(var/run_offset in 0 to required_width - 1)
				var/local_x = (check_dir in list(NORTH, SOUTH)) ? run_start + run_offset : (check_dir == EAST ? rect["x2"] : rect["x1"])
				var/local_y = (check_dir in list(EAST, WEST)) ? run_start + run_offset : (check_dir == NORTH ? rect["y2"] : rect["y1"])
				var/turf/room_turf = context.local_turf(local_x, local_y)
				var/turf/wall_turf = get_step(room_turf, check_dir)
				var/turf/route_turf = get_step(wall_turf, check_dir)
				if(!free_lookup[wall_turf] || !reachable[route_turf])
					run_valid = FALSE
					break
			if(run_valid)
				return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/score_building_layout_partial_rect(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate, datum/world_edit_building_layout_allocation_partial/partial, datum/world_edit_building_layout_room_contract/room_contract, datum/world_edit_building_layout_influence_zone/zone, list/rect, target_area, allocation_variant)
	var/score = 100000 + zone.priority
	score -= abs(building_layout_rect_area(rect) - target_area) * 24
	var/center_x = round((rect["x1"] + rect["x2"]) / 2)
	var/center_y = round((rect["y1"] + rect["y2"]) / 2)
	var/field_x = round((context.local_width() + 1) / 2)
	var/field_y = round((context.local_height() + 1) / 2)
	var/datum/world_edit_building_layout_topology_node/node = candidate.topology_graph?.get_node(room_contract.id)
	if(node?.id == candidate.topology_graph?.root_node_id)
		score += building_layout_rect_area(rect) * 80
		score -= (abs(center_x - field_x) + abs(center_y - field_y)) * 300
	// Prefer placements that reuse a clean one-tile partition line instead of
	// scattering siblings across the seed region.  This is a partial quality
	// signal only: authored topology edges below remain hard geometry checks.
	for(var/existing_id as anything in partial.placement_order)
		var/list/existing_rect = partial.placements[existing_id]
		if(islist(existing_rect))
			score += building_layout_rect_partition_overlap(rect, existing_rect) * 180
	for(var/datum/world_edit_building_layout_topology_edge/edge as anything in candidate.topology_graph?.get_edges_for(room_contract.id))
		if(!istype(edge) || edge.kind == WORLD_EDIT_BUILDING_EDGE_ROUTE)
			continue
		var/other_id = edge.from_id == room_contract.id ? edge.to_id : edge.from_id
		var/list/other_rect = partial.placements[other_id]
		if(islist(other_rect))
			var/shared_length = building_layout_rect_partition_overlap(rect, other_rect)
			var/required_length = max(edge.min_shared_wall, 1)
			score += min(shared_length, required_length) * 1200
			// Once the hard overlap is satisfied, consuming more of the same root
			// frontage can make later spokes impossible.  Prefer the authored
			// overlap and leave the remaining partition axes available.
			score -= max(shared_length - required_length, 0) * 1200
	switch(candidate.family_policy_id)
		if("hub_spoke")
			score -= (node?.depth || 0) ? abs((abs(center_x - field_x) + abs(center_y - field_y)) - 5) * 20 : 0
		if("open_bay_perimeter")
			if(room_contract.spatial_kind == WORLD_EDIT_BUILDING_SPACE_OPEN_BAY || room_contract.privacy_class == "public")
				score -= (abs(center_x - field_x) + abs(center_y - field_y)) * 40
		if("secure_core")
			if(room_contract.privacy_class == "secure")
				score -= (abs(center_x - field_x) + abs(center_y - field_y)) * 80
	if(allocation_variant % 2)
		score += center_x
	if(allocation_variant >= 2)
		score += center_y
	score += ((center_x * 17 + center_y * 31 + allocation_variant * 13) % 23)
	return score

/datum/world_edit_generator/building_layout/proc/insert_building_layout_rect_option(list/options, list/option, limit)
	if(!islist(options) || !islist(option))
		return
	var/spatial_bucket = "[option["spatial_bucket"] || ""]"
	if(length(spatial_bucket))
		for(var/existing_index in 1 to length(options))
			var/list/existing_option = options[existing_index]
			if("[existing_option?["spatial_bucket"] || ""]" != spatial_bucket)
				continue
			if(round(text2num("[option["score"]]") || 0) <= round(text2num("[existing_option?["score"]]") || 0))
				return
			options.Cut(existing_index, existing_index + 1)
			break
	options.len++
	options[options.len] = option
	for(var/index = length(options), index > 1, index--)
		var/list/current = options[index]
		var/list/previous = options[index - 1]
		if(round(text2num("[current?["score"]]") || 0) <= round(text2num("[previous?["score"]]") || 0))
			break
		options[index - 1] = current
		options[index] = previous
	if(length(options) > limit)
		options.Cut(limit + 1)

/datum/world_edit_generator/building_layout/proc/insert_building_layout_partial(list/partials, datum/world_edit_building_layout_allocation_partial/partial, limit)
	if(!islist(partials) || !istype(partial))
		return
	partials.len++
	partials[partials.len] = partial
	for(var/index = length(partials), index > 1, index--)
		var/datum/world_edit_building_layout_allocation_partial/current = partials[index]
		var/datum/world_edit_building_layout_allocation_partial/previous = partials[index - 1]
		if(istype(previous) && current.score <= previous.score)
			break
		partials[index - 1] = current
		partials[index] = previous
	if(length(partials) > limit)
		partials.Cut(limit + 1)
