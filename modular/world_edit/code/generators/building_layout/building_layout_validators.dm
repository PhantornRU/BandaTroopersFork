/datum/world_edit_generator/building_layout/proc/validate_and_repair_building_layout_state(datum/world_edit_building_layout_state/state)
	if(!istype(state))
		return
	validate_building_layout_state(state)
	if(!state.has_errors())
		return

	for(var/attempt in 1 to WORLD_EDIT_BUILDING_MAX_REPAIR_ATTEMPTS)
		var/repaired_this_pass = FALSE
		for(var/datum/world_edit_building_cluster_spec/cluster_spec as anything in state.semantic_plan?.get_cluster_specs("major"))
			if((state.cluster_counts[cluster_spec.id] || 0) >= cluster_spec.min_count)
				continue
			if(place_building_cluster_spec(state, cluster_spec, TRUE))
				repaired_this_pass = TRUE
		validate_building_layout_state(state)
		if(!state.has_errors() || !repaired_this_pass)
			break

/datum/world_edit_generator/building_layout/proc/validate_building_layout_state(datum/world_edit_building_layout_state/state)
	if(!istype(state))
		return
	state.errors.Cut()
	state.signature_warnings.Cut()

	if(!istype(state.archetype) || !istype(state.semantic_plan))
		state.add_error("Building semantic program is unavailable.")
		return
	if(!length(state.footprint) || !length(state.floor_turfs))
		state.add_error("Building layout has no usable footprint or floor turfs.")
	if(!istype(state.front_door_turf) || !length(state.door_turfs))
		state.add_error("Building layout has no entry door.")

	validate_building_zone_requirements(state)
	validate_building_adjacency_rules(state)
	validate_building_door_buffers(state)
	validate_building_windows(state)
	validate_building_reserved_lanes(state)
	validate_building_route_touch(state)
	validate_building_fixture_surface(state)
	validate_building_fixture_reachability(state)
	validate_building_privacy_rules(state)
	validate_building_major_clusters(state)
	validate_building_density_rules(state)
	validate_building_signature_rules(state)
	validate_building_nested_room_rules(state)
	validate_building_divider_rules(state)

/datum/world_edit_generator/building_layout/proc/validate_building_zone_requirements(datum/world_edit_building_layout_state/state)
	for(var/datum/world_edit_building_zone_spec/zone_spec as anything in state.semantic_plan.zone_specs)
		if(!zone_spec.required)
			continue
		var/list/zone_turfs = state.get_zone_turfs(zone_spec.id)
		if(length(zone_turfs) < zone_spec.min_area)
			state.add_error("Required zone '[zone_spec.id]' has [length(zone_turfs)] tiles, expected at least [zone_spec.min_area].")

/datum/world_edit_generator/building_layout/proc/build_building_zone_lookup(datum/world_edit_building_layout_state/state, zone_id)
	var/list/lookup = list()
	for(var/turf/zone_turf as anything in state.get_zone_turfs(zone_id))
		lookup[zone_turf] = TRUE
	return lookup

/datum/world_edit_generator/building_layout/proc/building_zones_are_adjacent(datum/world_edit_building_layout_state/state, zone_a, zone_b)
	var/list/zone_b_lookup = build_building_zone_lookup(state, zone_b)
	for(var/turf/zone_a_turf as anything in state.get_zone_turfs(zone_a))
		for(var/check_dir in GLOB.cardinals)
			if(zone_b_lookup[get_step(zone_a_turf, check_dir)])
				return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/validate_building_adjacency_rules(datum/world_edit_building_layout_state/state)
	for(var/datum/world_edit_building_adjacency_rule/rule as anything in state.semantic_plan.adjacency_rules)
		if(!rule.required)
			continue
		if(!building_zones_are_adjacent(state, rule.zone_a, rule.zone_b))
			state.add_error("Required zone adjacency missing: [rule.zone_a] -> [rule.zone_b].")

/datum/world_edit_generator/building_layout/proc/validate_building_door_buffers(datum/world_edit_building_layout_state/state)
	for(var/turf/door_turf as anything in state.door_turfs)
		if(!istype(door_turf))
			state.add_error("Building door placement contains an invalid turf.")
			continue
		var/door_dir = state.door_dirs[door_turf] || get_outward_dir(door_turf, state.footprint_lookup, (state.bounds["min_x"] + state.bounds["max_x"]) / 2, (state.bounds["min_y"] + state.bounds["max_y"]) / 2, state.placement_dir)
		var/turf/inward_turf = get_step(door_turf, turn(door_dir, 180))
		if(!state.floor_lookup[inward_turf] && door_turf == state.front_door_turf)
			state.add_error("Door at [GLOB.world_edit_helpers.turf_to_text(door_turf)] has no interior buffer.")
		if(state.boundary_lookup[door_turf] && state.fixture_lookup[inward_turf])
			state.add_error("Door buffer at [GLOB.world_edit_helpers.turf_to_text(inward_turf)] is blocked by a fixture.")

/datum/world_edit_generator/building_layout/proc/validate_building_windows(datum/world_edit_building_layout_state/state)
	var/list/door_lookup = GLOB.world_edit_placement_shapes.world_edit_build_turf_lookup(state.door_turfs)
	for(var/turf/window_turf as anything in state.window_turfs)
		if(!state.boundary_lookup[window_turf])
			state.add_error("Window placement must stay on exterior boundary.")
		if(door_lookup[window_turf])
			state.add_error("Window placement overlaps a door.")
		if(!boundary_turf_has_outside_dir(window_turf, state.footprint_lookup, get_outward_dir(window_turf, state.footprint_lookup, (state.bounds["min_x"] + state.bounds["max_x"]) / 2, (state.bounds["min_y"] + state.bounds["max_y"]) / 2, state.placement_dir)))
			state.add_error("Window placement has no exterior side.")
		if(!can_place_building_window_for_boundary_turf(state, window_turf))
			state.add_error("Window placement contradicts the adjacent semantic zone.")

/datum/world_edit_generator/building_layout/proc/validate_building_reserved_lanes(datum/world_edit_building_layout_state/state)
	for(var/turf/reserved_turf as anything in state.floor_turfs)
		if(!state.reserved_lookup[reserved_turf])
			continue
		if(state.fixture_lookup[reserved_turf])
			state.add_error("Primary lane at [GLOB.world_edit_helpers.turf_to_text(reserved_turf)] is blocked by a fixture.")

/datum/world_edit_generator/building_layout/proc/validate_building_route_touch(datum/world_edit_building_layout_state/state)
	for(var/datum/world_edit_building_zone_spec/zone_spec as anything in state.semantic_plan.zone_specs)
		if(!zone_spec.required || !zone_spec.must_touch_route)
			continue
		var/route_touches_zone = FALSE
		for(var/turf/zone_turf as anything in state.get_zone_turfs(zone_spec.id))
			if(state.reserved_lookup[zone_turf])
				route_touches_zone = TRUE
				break
			for(var/check_dir in GLOB.cardinals)
				if(state.reserved_lookup[get_step(zone_turf, check_dir)])
					route_touches_zone = TRUE
					break
			if(route_touches_zone)
				break
		if(!route_touches_zone)
			state.add_error("Required zone '[zone_spec.id]' is not connected to the circulation graph.")

/datum/world_edit_generator/building_layout/proc/validate_building_fixture_surface(datum/world_edit_building_layout_state/state)
	var/list/wall_fixture_placement_lookup = list()
	for(var/list/placement as anything in state.object_placements)
		var/turf/target_turf = placement["turf"]
		if(!state.floor_lookup[target_turf])
			state.add_error("Fixture placement must target a floor turf.")
		if(state.wall_lookup[target_turf])
			state.add_error("Fixture placement overlaps a wall turf.")
		if(state.door_dirs[target_turf])
			state.add_error("Fixture placement overlaps a door turf.")
		if(placement["wall_mounted"])
			wall_fixture_placement_lookup[target_turf] = TRUE
			var/wall_dir = text2num("[placement["wall_dir"]]")
			var/dir_mode = text2num("[placement["dir_mode"]]")
			var/dir_to_use = text2num("[placement["dir"]]")
			if(!(wall_dir in GLOB.cardinals))
				state.add_error("Wall fixture placement is missing its wall direction.")
				continue
			if(!state.wall_lookup[get_step(target_turf, wall_dir)])
				state.add_error("Wall fixture placement does not point at an adjacent wall.")
				continue
			var/expected_dir = resolve_building_place_rule_dir(wall_dir, dir_mode)
			if(expected_dir != dir_to_use)
				state.add_error("Wall fixture placement dir does not match its wall rule.")
	for(var/turf/wall_fixture_turf as anything in state.wall_fixture_turfs)
		if(!length(get_adjacent_wall_dirs_for_state(state, wall_fixture_turf)))
			state.add_error("Wall fixture has no adjacent wall.")
		if(!wall_fixture_placement_lookup[wall_fixture_turf])
			state.add_error("Wall fixture has no emitted object placement.")

/datum/world_edit_generator/building_layout/proc/build_building_reachable_floor_lookup(datum/world_edit_building_layout_state/state)
	var/list/reachable = list()
	if(!istype(state))
		return reachable
	var/list/queue = list()
	var/list/start_doors = list()
	for(var/turf/door_turf as anything in state.door_turfs)
		if(state.boundary_lookup[door_turf])
			start_doors += door_turf
	if(!length(start_doors))
		start_doors = state.door_turfs
	for(var/turf/door_turf as anything in start_doors)
		if(state.floor_lookup[door_turf])
			queue += door_turf
			reachable[door_turf] = TRUE
		var/door_dir = state.door_dirs[door_turf] || state.placement_dir
		var/turf/inward_turf = get_step(door_turf, turn(door_dir, 180))
		if(state.floor_lookup[inward_turf] && !reachable[inward_turf])
			queue += inward_turf
			reachable[inward_turf] = TRUE
	var/index = 1
	while(index <= length(queue))
		var/turf/current_turf = queue[index++]
		for(var/check_dir in GLOB.cardinals)
			var/turf/nearby_turf = get_step(current_turf, check_dir)
			if(!state.floor_lookup[nearby_turf] || reachable[nearby_turf])
				continue
			reachable[nearby_turf] = TRUE
			queue += nearby_turf
	return reachable

/datum/world_edit_generator/building_layout/proc/validate_building_fixture_reachability(datum/world_edit_building_layout_state/state)
	var/list/reachable = build_building_reachable_floor_lookup(state)
	for(var/turf/fixture_turf as anything in state.major_fixture_turfs)
		if(reachable[fixture_turf])
			continue
		var/has_adjacent_reachable_floor = FALSE
		for(var/check_dir in GLOB.cardinals)
			if(reachable[get_step(fixture_turf, check_dir)])
				has_adjacent_reachable_floor = TRUE
				break
		if(!has_adjacent_reachable_floor)
			state.add_error("Major fixture at [GLOB.world_edit_helpers.turf_to_text(fixture_turf)] is not reachable from an entry.")

/datum/world_edit_generator/building_layout/proc/validate_building_privacy_rules(datum/world_edit_building_layout_state/state)
	for(var/datum/world_edit_building_zone_spec/zone_spec as anything in state.semantic_plan.zone_specs)
		if(!zone_spec.privacy_sensitive)
			continue
		for(var/turf/private_turf as anything in state.get_zone_turfs(zone_spec.id))
			if(state.has_anchor("door_cone", private_turf))
				state.add_error("Privacy zone '[zone_spec.id]' overlaps an entry door cone.")
			for(var/check_dir in GLOB.cardinals)
				var/turf/nearby_turf = get_step(private_turf, check_dir)
				if(state.has_anchor("door_cone", nearby_turf))
					state.add_error("Privacy zone '[zone_spec.id]' is directly exposed to an entry door cone.")
					break

/datum/world_edit_generator/building_layout/proc/validate_building_major_clusters(datum/world_edit_building_layout_state/state)
	for(var/datum/world_edit_building_cluster_spec/cluster_spec as anything in state.semantic_plan.get_cluster_specs("major"))
		if(!cluster_spec.required)
			continue
		if((state.cluster_counts[cluster_spec.id] || 0) < cluster_spec.min_count)
			state.add_error("Major cluster '[cluster_spec.id]' placed [state.cluster_counts[cluster_spec.id] || 0], expected at least [cluster_spec.min_count].")

/datum/world_edit_generator/building_layout/proc/validate_building_density_rules(datum/world_edit_building_layout_state/state)
	for(var/category as anything in state.semantic_plan.category_minimums)
		var/minimum = round(text2num("[state.semantic_plan.category_minimums[category]]") || 0)
		if((state.category_counts["[category]"] || 0) < minimum)
			state.add_error("Program [state.archetype.id] requires [minimum] [category] fixtures.")

/datum/world_edit_generator/building_layout/proc/validate_building_signature_rules(datum/world_edit_building_layout_state/state)
	var/raw_score = 0
	var/max_score = 0
	if(islist(state.semantic_plan.signature_minimums))
		for(var/signature_id as anything in state.semantic_plan.signature_minimums)
			var/minimum = max(round(text2num("[state.semantic_plan.signature_minimums[signature_id]]") || 0), 0)
			var/weight = max(round(text2num("[state.semantic_plan.signature_weights[signature_id]]") || 0), 1)
			var/placed = round(text2num("[state.signature_counts[signature_id]]") || 0)
			max_score += weight
			if(placed >= minimum)
				raw_score += weight
				continue
			var/message = "Program signature '[signature_id]' placed [placed], expected at least [minimum]."
			state.signature_warnings += message
			state.add_error(message)
	state.signature_max_score = max_score > 0 ? 100 : 0
	state.signature_score = max_score > 0 ? round(raw_score * 100 / max_score) : 100
	if(max_score > 0 && state.signature_score < state.semantic_plan.min_signature_score)
		state.add_error("Program [state.archetype.id] signature score [state.signature_score]/100 is below [state.semantic_plan.min_signature_score].")

	var/open_floor = 0
	var/relevant_floor = 0
	for(var/turf/floor_turf as anything in state.floor_turfs)
		if(!istype(floor_turf) || state.wall_lookup[floor_turf] || state.door_dirs[floor_turf])
			continue
		relevant_floor++
		if(!state.fixture_lookup[floor_turf] && !state.reserved_lookup[floor_turf])
			open_floor++
	state.empty_floor_ratio = relevant_floor > 0 ? round(open_floor * 100 / relevant_floor) : 0
	if(relevant_floor >= 24 && state.empty_floor_ratio > 72)
		var/empty_message = "Program [state.archetype.id] leaves [state.empty_floor_ratio]% non-route floor empty after mandatory signatures."
		state.signature_warnings += empty_message
		if(!(empty_message in state.warnings))
			state.add_warning(empty_message)

/datum/world_edit_generator/building_layout/proc/validate_building_nested_room_rules(datum/world_edit_building_layout_state/state)
	var/list/nested_specs = islist(state.semantic_plan?.nested_room_specs) ? state.semantic_plan.nested_room_specs.Copy() : list()
	if(!length(nested_specs) && length("[state.semantic_plan?.nested_inner_zone]"))
		nested_specs += new /datum/world_edit_building_nested_room_spec(state.semantic_plan.nested_outer_zone, state.semantic_plan.nested_inner_zone, state.semantic_plan.nested_min_width, state.semantic_plan.nested_min_height, 1)
	for(var/datum/world_edit_building_nested_room_spec/nested_spec as anything in nested_specs)
		if(!istype(nested_spec) || !length(nested_spec.inner_zone_id))
			continue
		if((state.bounds["width"] || 0) < nested_spec.min_width || (state.bounds["height"] || 0) < nested_spec.min_height)
			continue
		if(!length(state.get_zone_turfs(nested_spec.inner_zone_id)))
			continue
		var/datum/world_edit_building_zone_spec/inner_zone_spec = state.semantic_plan.get_zone_spec(nested_spec.inner_zone_id)
		if(istype(inner_zone_spec) && inner_zone_spec.role != "nested")
			continue
		var/nested_plan_found = FALSE
		for(var/datum/world_edit_building_divider_plan/divider_plan as anything in state.divider_plans)
			if(istype(divider_plan) && divider_plan.inner_zone_id == nested_spec.inner_zone_id && findtext("[divider_plan.id]", "nested_") == 1)
				nested_plan_found = TRUE
				break
		if(!nested_plan_found)
			state.add_error("Nested zone '[nested_spec.inner_zone_id]' exists without a data-driven nested room plan.")
		else if(!length(state.internal_wall_turfs))
			state.add_error("Nested zone '[nested_spec.inner_zone_id]' exists without internal walls.")

/datum/world_edit_generator/building_layout/proc/validate_building_divider_rules(datum/world_edit_building_layout_state/state)
	for(var/datum/world_edit_building_divider_plan/divider_plan as anything in state.divider_plans)
		if(!istype(divider_plan))
			continue
		if(length(divider_plan.wall_turfs) && !length(divider_plan.opening_turfs))
			state.add_error("Divider '[divider_plan.id]' has walls without a controlled opening.")
		for(var/turf/wall_turf as anything in divider_plan.wall_turfs)
			if(state.reserved_lookup[wall_turf])
				state.add_error("Divider '[divider_plan.id]' overlaps a primary route.")
			if(!state.wall_lookup[wall_turf])
				state.add_error("Divider '[divider_plan.id]' planned wall was not emitted as a wall.")
		for(var/turf/opening_turf as anything in divider_plan.opening_turfs)
			if(!state.door_dirs[opening_turf])
				state.add_error("Divider '[divider_plan.id]' opening is missing a controlled door.")
			if(state.wall_lookup[opening_turf])
				state.add_error("Divider '[divider_plan.id]' opening overlaps a wall.")
