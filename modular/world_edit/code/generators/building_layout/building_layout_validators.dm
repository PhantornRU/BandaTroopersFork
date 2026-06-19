/datum/world_edit_generator/building_layout/proc/validate_and_repair_building_layout_state(datum/world_edit_building_layout_state/state)
	if(!istype(state))
		return
	if(ensure_required_zone_route_access(state))
		refresh_building_semantic_anchors(state)
	reserve_building_immediate_door_cones(state)
	if(repair_building_fixture_conflicts(state))
		repair_building_missing_major_clusters(state)
	validate_building_layout_state(state)
	if(!state.has_errors())
		return

	for(var/attempt in 1 to WORLD_EDIT_BUILDING_MAX_REPAIR_ATTEMPTS)
		var/repaired_this_pass = FALSE
		var/anchors_dirty = FALSE
		if(repair_building_privacy_conflicts(state))
			repaired_this_pass = TRUE
			anchors_dirty = TRUE
		if(repair_building_window_conflicts(state))
			repaired_this_pass = TRUE
			anchors_dirty = TRUE
		if(anchors_dirty)
			refresh_building_semantic_anchors(state)
		reserve_building_immediate_door_cones(state)
		if(repair_building_fixture_conflicts(state))
			repaired_this_pass = TRUE
			if(repair_building_missing_major_clusters(state))
				repaired_this_pass = TRUE
		if(repair_building_required_fixture_access(state))
			repaired_this_pass = TRUE
			anchors_dirty = TRUE
		if(place_building_infrastructure(state))
			repaired_this_pass = TRUE
		if(repair_building_missing_major_clusters(state))
			repaired_this_pass = TRUE
		if(repair_building_empty_space(state))
			repaired_this_pass = TRUE
		if(repaired_this_pass)
			refresh_building_semantic_anchors(state)
			if(ensure_required_zone_route_access(state))
				refresh_building_semantic_anchors(state)
			reserve_building_immediate_door_cones(state)
			if(repair_building_fixture_conflicts(state))
				repair_building_missing_major_clusters(state)
		validate_building_layout_state(state)
		if(!state.has_errors() || !repaired_this_pass)
			break

/datum/world_edit_generator/building_layout/proc/reserve_building_immediate_door_cones(datum/world_edit_building_layout_state/state)
	if(!istype(state))
		return FALSE
	var/changed = FALSE
	for(var/turf/door_turf as anything in state.geometry.door_turfs)
		if(!istype(door_turf))
			continue
		var/door_dir = state.geometry.door_dirs[door_turf] || state.placement_dir
		if(!(door_dir in GLOB.cardinals))
			continue
		for(var/cone_dir as anything in list(door_dir, turn(door_dir, 180)))
			var/turf/cone_turf = get_step(door_turf, cone_dir)
			if(!istype(cone_turf) || !state.geometry.floor_lookup[cone_turf])
				continue
			if(!state.geometry.reserved_lookup[cone_turf])
				changed = TRUE
			state.add_anchor("door_cone", cone_turf)
			state.add_anchor("primary_lane", cone_turf)
			state.add_reserved(cone_turf)
	return changed

/datum/world_edit_generator/building_layout/proc/building_turf_has_dense_fixture(datum/world_edit_building_layout_state/state, turf/target_turf)
	if(!istype(state) || !istype(target_turf))
		return FALSE
	for(var/list/placement as anything in state.fixtures.object_placements)
		if(!islist(placement) || "[placement["kind"]]" != "interior" || placement["turf"] != target_turf)
			continue
		if(building_object_path_is_dense(placement["obj_path"]))
			return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/repair_building_privacy_conflicts(datum/world_edit_building_layout_state/state)
	if(!istype(state) || !istype(state.semantic_plan))
		return FALSE
	var/repaired = FALSE
	var/fallback_zone = state.semantic_plan.hub_zone_id || state.semantic_plan.primary_zone_id
	if(!length("[fallback_zone]"))
		return FALSE
	for(var/datum/world_edit_building_zone_spec/zone_spec as anything in state.semantic_plan.zone_specs)
		if(!istype(zone_spec) || !zone_spec.privacy_sensitive)
			continue
		for(var/turf/private_turf as anything in state.get_zone_turfs(zone_spec.id).Copy())
			if(!istype(private_turf))
				continue
			var/exposed = state.has_anchor("door_cone", private_turf)
			if(!exposed)
				for(var/check_dir in GLOB.cardinals)
					if(state.has_anchor("door_cone", get_step(private_turf, check_dir)))
						exposed = TRUE
						break
			if(!exposed)
				continue
			state.add_zone(private_turf, fallback_zone)
			repaired = TRUE
	if(repaired)
		repair_building_zone_coverage(state)
	return repaired

/datum/world_edit_generator/building_layout/proc/repair_building_window_conflicts(datum/world_edit_building_layout_state/state)
	if(!istype(state))
		return FALSE
	var/list/door_lookup = GLOB.world_edit_placement_shapes.world_edit_build_turf_lookup(state.geometry.door_turfs)
	var/list/kept_windows = list()
	var/list/kept_lookup = list()
	var/repaired = FALSE
	for(var/turf/window_turf as anything in state.geometry.window_turfs)
		if(!istype(window_turf))
			repaired = TRUE
			continue
		if(!state.geometry.boundary_lookup[window_turf] || door_lookup[window_turf] || !boundary_turf_has_outside_dir(window_turf, state.geometry.footprint_lookup, get_outward_dir(window_turf, state.geometry.footprint_lookup, (state.geometry.bounds["min_x"] + state.geometry.bounds["max_x"]) / 2, (state.geometry.bounds["min_y"] + state.geometry.bounds["max_y"]) / 2, state.placement_dir)) || !can_place_building_window_for_boundary_turf(state, window_turf))
			repaired = TRUE
			continue
		if(!kept_lookup[window_turf])
			kept_windows += window_turf
			kept_lookup[window_turf] = TRUE
	state.geometry.window_turfs = kept_windows
	if(repaired)
		build_building_windows(state)
	return repaired

/datum/world_edit_generator/building_layout/proc/repair_building_fixture_conflicts(datum/world_edit_building_layout_state/state)
	if(!istype(state))
		return FALSE
	var/list/remove_turfs = list()
	var/list/remove_lookup = list()
	for(var/list/placement as anything in state.fixtures.object_placements)
		if(!islist(placement) || "[placement["kind"]]" != "interior")
			continue
		var/turf/target_turf = placement["turf"]
		var/remove_fixture = FALSE
		var/object_is_dense = building_object_path_is_dense(placement["obj_path"])
		if(!state.geometry.floor_lookup[target_turf] || state.geometry.wall_lookup[target_turf] || state.geometry.door_dirs[target_turf] || (object_is_dense && state.geometry.reserved_lookup[target_turf]))
			remove_fixture = TRUE
		if(!remove_fixture && placement["wall_mounted"])
			var/wall_dir = text2num("[placement["wall_dir"]]")
			if(!(wall_dir in GLOB.cardinals) || !state.geometry.wall_lookup[get_step(target_turf, wall_dir)])
				remove_fixture = TRUE
		if(remove_fixture && !remove_lookup[target_turf])
			remove_turfs += target_turf
			remove_lookup[target_turf] = TRUE
	var/repaired = FALSE
	for(var/turf/remove_turf as anything in remove_turfs)
		if(state.remove_fixture_at(remove_turf))
			repaired = TRUE
	return repaired

/datum/world_edit_generator/building_layout/proc/repair_building_required_fixture_access(datum/world_edit_building_layout_state/state)
	if(!istype(state) || !istype(state.semantic_plan))
		return FALSE
	var/list/reachable = get_building_validation_reachable_floor_lookup(state)
	var/repaired = FALSE
	for(var/datum/world_edit_building_cluster_spec/cluster_spec as anything in state.semantic_plan.get_cluster_specs("major"))
		if(!istype(cluster_spec) || !cluster_spec.required)
			continue
		var/effective_minimum = get_effective_cluster_min_count(state, cluster_spec)
		var/requirement_id = get_building_cluster_requirement_id(cluster_spec)
		var/placed_count = get_building_placed_requirement_count(state, requirement_id, cluster_spec.id, cluster_spec.signature_id)
		if(placed_count < effective_minimum)
			continue
		if(building_required_cluster_has_reachable_fixture(state, cluster_spec))
			continue
		for(var/list/placement as anything in state.fixtures.object_placements)
			if(!islist(placement) || "[placement["kind"]]" != "interior")
				continue
			if("[placement["requirement_id"]]" != requirement_id && "[placement["cluster_id"]]" != cluster_spec.id && "[placement["signature_id"]]" != cluster_spec.signature_id)
				continue
			var/turf/target_turf = placement["turf"]
			if(!istype(target_turf) || building_turf_touches_reachable_floor(target_turf, reachable))
				continue
			var/zone_id = state.get_zone(target_turf)
			var/datum/world_edit_building_room/room = state.get_room_for_turf(target_turf)
			if(repair_building_zone_opening_to_reachable_floor(state, zone_id, room, reachable, target_turf, cluster_spec.id))
				repaired = TRUE
				state.clear_validation_cache()
				reachable = build_building_reachable_floor_lookup(state)
				break
	return repaired

/datum/world_edit_generator/building_layout/proc/building_turf_touches_reachable_floor(turf/target_turf, list/reachable)
	if(!istype(target_turf) || !islist(reachable))
		return FALSE
	if(reachable[target_turf])
		return TRUE
	for(var/check_dir in GLOB.cardinals)
		if(reachable[get_step(target_turf, check_dir)])
			return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/repair_building_zone_opening_to_reachable_floor(datum/world_edit_building_layout_state/state, zone_id, datum/world_edit_building_room/room, list/reachable, turf/focus_turf, cluster_id)
	if(!istype(state) || !islist(reachable))
		return FALSE
	var/list/source_turfs = list()
	var/list/source_lookup = list()
	if(istype(room))
		for(var/turf/room_turf as anything in room.turfs)
			if(istype(room_turf) && !source_lookup[room_turf])
				source_lookup[room_turf] = TRUE
				source_turfs += room_turf
	if(!length(source_turfs) && length("[zone_id]"))
		for(var/turf/zone_turf as anything in state.get_zone_turfs(zone_id))
			if(istype(zone_turf) && !source_lookup[zone_turf])
				source_lookup[zone_turf] = TRUE
				source_turfs += zone_turf
	if(!length(source_turfs))
		return FALSE
	var/turf/best_opening_turf = null
	var/turf/best_reachable_turf = null
	var/best_dir = null
	var/best_score = -999999999
	for(var/turf/source_turf as anything in source_turfs)
		if(!istype(source_turf) || state.geometry.reserved_lookup[source_turf] || state.geometry.door_dirs[source_turf])
			continue
		if(state.geometry.wall_lookup[source_turf])
			for(var/check_dir in GLOB.cardinals)
				var/turf/nearby_turf = get_step(source_turf, check_dir)
				if(!reachable[nearby_turf] || !state.geometry.floor_lookup[nearby_turf] || state.geometry.wall_lookup[nearby_turf])
					continue
				if(!building_door_cone_is_clear_for_validation(state, source_turf, check_dir))
					continue
				var/score = 1000
				if(istype(focus_turf))
					score -= get_dist(source_turf, focus_turf)
				if(score > best_score)
					best_opening_turf = source_turf
					best_reachable_turf = nearby_turf
					best_dir = check_dir
					best_score = score
			continue
		if(!state.geometry.floor_lookup[source_turf])
			continue
		for(var/check_dir in GLOB.cardinals)
			var/turf/wall_turf = get_step(source_turf, check_dir)
			if(!istype(wall_turf) || state.geometry.reserved_lookup[wall_turf] || state.geometry.door_dirs[wall_turf] || !state.geometry.wall_lookup[wall_turf])
				continue
			var/turf/far_turf = get_step(wall_turf, check_dir)
			if(!reachable[far_turf] || !state.geometry.floor_lookup[far_turf] || state.geometry.wall_lookup[far_turf])
				continue
			if(!building_door_cone_is_clear_for_validation(state, wall_turf, check_dir))
				continue
			var/score = 500
			if(istype(focus_turf))
				score -= get_dist(source_turf, focus_turf)
			if(score > best_score)
				best_opening_turf = wall_turf
				best_reachable_turf = far_turf
				best_dir = check_dir
				best_score = score
	if(!istype(best_opening_turf))
		return FALSE
	state.geometry.wall_lookup -= best_opening_turf
	state.geometry.internal_wall_turfs -= best_opening_turf
	state.geometry.boundary_lookup[best_opening_turf] = FALSE
	state.append_unique_turf(state.geometry.floor_turfs, best_opening_turf)
	state.geometry.floor_lookup[best_opening_turf] = TRUE
	state.append_unique_turf(state.geometry.door_turfs, best_opening_turf)
	state.geometry.door_dirs[best_opening_turf] = best_dir || get_cardinal_dir_toward(best_opening_turf, best_reachable_turf, state.placement_dir)
	if(length("[zone_id]"))
		state.add_zone(best_opening_turf, zone_id)
	state.add_primary_route(best_opening_turf)
	state.validation.door_reports += list(list(
		"turf" = best_opening_turf,
		"dir" = state.geometry.door_dirs[best_opening_turf],
		"kind" = "required_fixture_access_repair",
		"zone_id" = "[zone_id]",
		"cluster_id" = "[cluster_id]",
	))
	state.add_warning("Opened required fixture access for cluster '[cluster_id]' in zone '[zone_id]'.")
	return TRUE

/datum/world_edit_generator/building_layout/proc/repair_building_missing_major_clusters(datum/world_edit_building_layout_state/state)
	if(!istype(state) || !istype(state.semantic_plan))
		return FALSE
	var/repaired = FALSE
	for(var/datum/world_edit_building_cluster_spec/cluster_spec as anything in state.semantic_plan.get_cluster_specs("major"))
		if(!istype(cluster_spec) || !cluster_spec.required)
			continue
		var/requirement_id = get_building_cluster_requirement_id(cluster_spec)
		var/placed_count = get_building_semantic_requirement_count(state, requirement_id, cluster_spec.id, cluster_spec.signature_id)
		var/effective_minimum = get_effective_cluster_min_count(state, cluster_spec)
		if(placed_count >= effective_minimum)
			continue
		if(place_building_cluster_spec(state, cluster_spec, TRUE))
			repaired = TRUE
			placed_count = get_building_semantic_requirement_count(state, requirement_id, cluster_spec.id, cluster_spec.signature_id)
		if(placed_count < effective_minimum)
			state.add_warning("Repair could not restore missing mandatory pattern '[requirement_id]': placed=[placed_count], min=[effective_minimum].")
	return repaired

/datum/world_edit_generator/building_layout/proc/repair_building_empty_space(datum/world_edit_building_layout_state/state)
	if(!istype(state) || !istype(state.semantic_plan))
		return FALSE
	if(state.validation.empty_floor_ratio <= get_building_max_empty_floor_ratio(state))
		return FALSE
	state.add_warning("Repair refused empty-space filler; empty floor must be solved by room/pattern planning.")
	return FALSE

/datum/world_edit_generator/building_layout/proc/validate_building_layout_state(datum/world_edit_building_layout_state/state)
	if(!istype(state))
		return
	state.validation.errors.Cut()
	state.fixtures.signature_warnings.Cut()
	state.validation.pattern_reports.Cut()
	state.fixtures.semantic_requirement_counts.Cut()
	state.reset_validation_metrics()

	if(!istype(state.archetype) || !istype(state.semantic_plan))
		state.add_error("Building semantic program is unavailable.")
		return
	if(!length(state.geometry.footprint) || !length(state.geometry.floor_turfs))
		state.add_error("Building layout has no usable footprint or floor turfs.")
	if(!istype(state.geometry.front_door_turf) || !length(state.geometry.door_turfs))
		state.add_error("Building layout has no entry door.")
	state.validation.validation_reachable_floor_lookup = build_building_reachable_floor_lookup(state)

	validate_building_zone_requirements(state)
	validate_building_adjacency_rules(state)
	validate_building_door_buffers(state)
	validate_building_windows(state)
	validate_building_facade_policy(state)
	validate_building_rect_no_cutout(state)
	validate_building_reserved_lanes(state)
	validate_building_blocker_policy(state)
	validate_building_route_touch(state)
	validate_building_route_patterns(state)
	validate_building_semantic_room_access(state)
	validate_building_fixture_surface(state)
	validate_building_fixture_reachability(state)
	validate_building_privacy_rules(state)
	validate_building_forbidden_rules(state)
	validate_building_semantic_slot_preflight(state)
	validate_building_major_clusters(state)
	validate_building_infrastructure_rules(state)
	validate_building_direction_contract(state)
	validate_building_counter_facing(state)
	validate_building_density_rules(state)
	validate_building_signature_rules(state)
	validate_building_nested_room_rules(state)
	validate_building_divider_rules(state)
	validate_building_acceptance_counters(state)

/datum/world_edit_generator/building_layout/proc/validate_building_zone_requirements(datum/world_edit_building_layout_state/state)
	for(var/datum/world_edit_building_zone_spec/zone_spec as anything in state.semantic_plan.zone_specs)
		if(!zone_spec.required)
			continue
		var/list/zone_turfs = state.get_zone_turfs(zone_spec.id)
		if(length(zone_turfs) < zone_spec.min_area)
			state.validation.mandatory_room_missing_count++
			if(zone_spec.divider_mode == "room")
				state.validation.mandatory_room_no_bounds_count++
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
			var/turf/nearby_turf = get_step(zone_a_turf, check_dir)
			if(zone_b_lookup[nearby_turf])
				return TRUE
			if(state.geometry.wall_lookup[nearby_turf] || state.geometry.door_dirs[nearby_turf])
				var/turf/beyond_turf = get_step(nearby_turf, check_dir)
				if(zone_b_lookup[beyond_turf])
					return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/validate_building_adjacency_rules(datum/world_edit_building_layout_state/state)
	for(var/datum/world_edit_building_adjacency_rule/rule as anything in state.semantic_plan.adjacency_rules)
		if(!rule.required)
			continue
		if(!building_zones_are_adjacent(state, rule.zone_a, rule.zone_b))
			state.add_warning("Required zone adjacency missing: [rule.zone_a] -> [rule.zone_b]. Relaxed zoning applied.")

/datum/world_edit_generator/building_layout/proc/validate_building_door_buffers(datum/world_edit_building_layout_state/state)
	for(var/turf/door_turf as anything in state.geometry.door_turfs)
		if(!istype(door_turf))
			state.add_error("Building door placement contains an invalid turf.")
			continue
		var/door_dir = state.geometry.door_dirs[door_turf] || get_outward_dir(door_turf, state.geometry.footprint_lookup, (state.geometry.bounds["min_x"] + state.geometry.bounds["max_x"]) / 2, (state.geometry.bounds["min_y"] + state.geometry.bounds["max_y"]) / 2, state.placement_dir)
		var/turf/inward_turf = get_step(door_turf, turn(door_dir, 180))
		if(!state.geometry.floor_lookup[inward_turf] && door_turf == state.geometry.front_door_turf)
			state.validation.door_buffer_conflict_count++
			state.validation.door_cone_blocked_count++
			state.add_error("Door at [GLOB.world_edit_helpers.turf_to_text(door_turf)] has no interior buffer.")
		if(state.geometry.boundary_lookup[door_turf] && building_turf_has_dense_fixture(state, inward_turf))
			state.validation.door_buffer_conflict_count++
			state.validation.door_cone_blocked_count++
			state.add_error("Door buffer at [GLOB.world_edit_helpers.turf_to_text(inward_turf)] is blocked by a fixture.")

/datum/world_edit_generator/building_layout/proc/validate_building_windows(datum/world_edit_building_layout_state/state)
	var/list/door_lookup = GLOB.world_edit_placement_shapes.world_edit_build_turf_lookup(state.geometry.door_turfs)
	for(var/turf/window_turf as anything in state.geometry.window_turfs)
		var/outward_dir = get_outward_dir(window_turf, state.geometry.footprint_lookup, (state.geometry.bounds["min_x"] + state.geometry.bounds["max_x"]) / 2, (state.geometry.bounds["min_y"] + state.geometry.bounds["max_y"]) / 2, state.placement_dir)
		var/turf/interior_turf = get_step(window_turf, turn(outward_dir, 180))
		var/zone_id = state.get_zone(interior_turf)
		var/datum/world_edit_building_zone_spec/zone_spec = state.semantic_plan?.zone_specs_by_id["[zone_id]"]
		if(!state.geometry.boundary_lookup[window_turf])
			state.validation.window_conflict_count++
			state.validation.invalid_window_count++
			state.add_error("Window placement must stay on exterior boundary.")
		if(door_lookup[window_turf])
			state.validation.window_conflict_count++
			state.validation.invalid_window_count++
			state.add_error("Window placement overlaps a door.")
		if(!boundary_turf_has_outside_dir(window_turf, state.geometry.footprint_lookup, outward_dir))
			state.validation.window_conflict_count++
			state.validation.invalid_window_count++
			state.add_error("Window placement has no exterior side.")
		if(!can_place_building_window_for_boundary_turf(state, window_turf))
			state.validation.window_conflict_count++
			if(istype(zone_spec) && (zone_spec.privacy_class == "secure" || zone_spec.role == "secure"))
				state.validation.secure_wall_window_violation_count++
			else if(istype(zone_spec) && (zone_spec.role in list("service", "support", "storage")))
				state.validation.service_wall_window_violation_count++
			else
				state.validation.invalid_window_count++
			state.add_error("Window placement contradicts the adjacent semantic zone.")

/datum/world_edit_generator/building_layout/proc/validate_building_facade_policy(datum/world_edit_building_layout_state/state)
	for(var/turf/boundary_turf as anything in state.geometry.boundary)
		if(!istype(boundary_turf) || !state.geometry.wall_lookup[boundary_turf])
			continue
		var/facade_role = get_building_facade_role_for_boundary_turf(state, boundary_turf)
		if(!length("[facade_role]"))
			state.validation.facade_conflict_count++
			state.add_error("Facade boundary has no resolved facade role.")
	if(!istype(state.geometry.front_door_turf))
		state.validation.entry_face_mismatch_count++
		state.validation.facade_conflict_count++
		state.add_error("Facade entry side has no front door turf.")
		return
	var/front_door_dir = state.geometry.door_dirs[state.geometry.front_door_turf] || state.geometry.actual_entry_direction
	var/front_facade_role = get_building_facade_role_for_boundary_turf(state, state.geometry.front_door_turf)
	if(!(front_door_dir in GLOB.cardinals) || front_door_dir != state.geometry.actual_entry_direction)
		state.validation.entry_face_mismatch_count++
		state.validation.facade_conflict_count++
		state.add_error("Facade entry side does not match actual entry direction.")
	if(!(front_facade_role in list("public_face", "neutral_face", "service_face")))
		state.validation.entry_face_mismatch_count++
		state.validation.facade_conflict_count++
		state.add_error("Facade entry side is not readable as a public/entry face.")
	else
		state.geometry.entry_face_readable = TRUE

/datum/world_edit_generator/building_layout/proc/validate_building_rect_no_cutout(datum/world_edit_building_layout_state/state)
	if(!istype(state) || !islist(state.geometry.bounds))
		return
	var/shape_id = "[state.config["placement_shape_id"] || WORLD_EDIT_SHAPE_POINT]"
	var/footprint_family = uppertext("[state.config["footprint_family"] || ""]")
	if(!(shape_id in list(WORLD_EDIT_SHAPE_POINT, WORLD_EDIT_SHAPE_RECTANGLE, WORLD_EDIT_SHAPE_FILLED_RECTANGLE)))
		return
	if(length(footprint_family) && !(footprint_family in list("RECT", "RECTANGLE", "FILLED_RECTANGLE")))
		return
	var/min_x = round(text2num("[state.geometry.bounds["min_x"]]") || 0)
	var/max_x = round(text2num("[state.geometry.bounds["max_x"]]") || 0)
	var/min_y = round(text2num("[state.geometry.bounds["min_y"]]") || 0)
	var/max_y = round(text2num("[state.geometry.bounds["max_y"]]") || 0)
	var/turf/reference_turf = istype(state.geometry.center_turf) ? state.geometry.center_turf : (length(state.geometry.footprint) ? state.geometry.footprint[1] : null)
	var/z_value = istype(reference_turf) ? reference_turf.z : 0
	var/missing_count = 0
	for(var/x in min_x to max_x)
		for(var/y in min_y to max_y)
			var/turf/check_turf = locate(x, y, z_value)
			if(!state.geometry.footprint_lookup[check_turf])
				missing_count++
	if(missing_count <= 0)
		return
	state.validation.cutout_violation_count += missing_count
	state.add_error("RECT/POINT-as-RECT building footprint has [missing_count] missing tiles inside rectangular exterior contour.")

/datum/world_edit_generator/building_layout/proc/validate_building_reserved_lanes(datum/world_edit_building_layout_state/state)
	for(var/turf/reserved_turf as anything in state.geometry.floor_turfs)
		if(!state.geometry.reserved_lookup[reserved_turf])
			continue
		if(building_turf_has_dense_fixture(state, reserved_turf))
			state.validation.route_conflict_count++
			state.validation.reserved_walk_blocked_count++
			state.add_error("Primary lane at [GLOB.world_edit_helpers.turf_to_text(reserved_turf)] is blocked by a fixture.")

/datum/world_edit_generator/building_layout/proc/validate_building_blocker_policy(datum/world_edit_building_layout_state/state)
	if(!istype(state))
		return
	var/blocked_count = 0
	for(var/turf/check_turf as anything in state.geometry.footprint)
		if(!length("[get_footprint_blocker_error(check_turf)]"))
			continue
		blocked_count++
		if(state.geometry.reserved_lookup[check_turf] || state.geometry.corridor_lookup[check_turf])
			state.validation.blocked_route_conflict_count++
		if(state.geometry.room_by_turf[check_turf])
			state.validation.blocked_room_conflict_count++
		if(state.geometry.wall_lookup[check_turf])
			state.validation.blocked_wall_conflict_count++
		if(state.fixtures.fixture_lookup[check_turf])
			state.validation.blocked_fixture_conflict_count++
	state.validation.blocked_turf_conflict_count = max(state.validation.blocked_turf_conflict_count, blocked_count)
	if(blocked_count <= 0)
		return
	if(state.config["respect_blockers"] || !state.config["replace_blocked_turfs"])
		state.add_error("Cannot build: blockers intersect resolved building layout while blocker replacement is disabled.")

/datum/world_edit_generator/building_layout/proc/building_separator_lane_touches_corridor(datum/world_edit_building_layout_state/state, turf/separator_turf)
	if(!istype(state) || !istype(separator_turf))
		return FALSE
	if(state.geometry.corridor_lookup[separator_turf] || state.geometry.reserved_lookup[separator_turf])
		return TRUE
	for(var/check_dir in GLOB.cardinals)
		var/turf/nearby_turf = get_step(separator_turf, check_dir)
		if(state.geometry.corridor_lookup[nearby_turf] || state.geometry.reserved_lookup[nearby_turf])
			return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/building_door_touches_circulation(datum/world_edit_building_layout_state/state, turf/door_turf)
	if(!istype(state) || !istype(door_turf))
		return FALSE
	if(state.geometry.corridor_lookup[door_turf] || state.geometry.reserved_lookup[door_turf])
		return TRUE
	for(var/check_dir in GLOB.cardinals)
		var/turf/nearby_turf = get_step(door_turf, check_dir)
		if(state.geometry.corridor_lookup[nearby_turf] || state.geometry.reserved_lookup[nearby_turf])
			return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/building_door_cone_is_clear_for_validation(datum/world_edit_building_layout_state/state, turf/door_turf, door_dir)
	if(!istype(state) || !istype(door_turf) || !(door_dir in GLOB.cardinals))
		return FALSE
	for(var/cone_dir in list(door_dir, turn(door_dir, 180)))
		var/turf/cone_turf = get_step(door_turf, cone_dir)
		if(!istype(cone_turf) || !state.geometry.floor_lookup[cone_turf])
			return FALSE
		if(building_turf_has_dense_fixture(state, cone_turf))
			return FALSE
		if(cone_turf.density)
			return FALSE
		for(var/atom/movable/blocker as anything in cone_turf)
			if(ismob(blocker))
				continue
			if(blocker.density)
				return FALSE
	return TRUE

/datum/world_edit_generator/building_layout/proc/building_turf_touches_circulation(datum/world_edit_building_layout_state/state, turf/target_turf)
	if(!istype(state) || !istype(target_turf))
		return FALSE
	if(state.geometry.corridor_lookup[target_turf] || state.geometry.reserved_lookup[target_turf])
		return TRUE
	if(state.geometry.door_dirs[target_turf] && building_door_touches_circulation(state, target_turf))
		return TRUE
	for(var/check_dir in GLOB.cardinals)
		var/turf/nearby_turf = get_step(target_turf, check_dir)
		if(state.geometry.corridor_lookup[nearby_turf] || state.geometry.reserved_lookup[nearby_turf])
			return TRUE
		if(state.geometry.door_dirs[nearby_turf] && building_door_touches_circulation(state, nearby_turf))
			return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/building_room_touches_circulation(datum/world_edit_building_layout_state/state, datum/world_edit_building_room/room)
	if(!istype(state) || !istype(room))
		return FALSE
	for(var/turf/room_turf as anything in room.turfs)
		if(building_turf_touches_circulation(state, room_turf))
			return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/building_zone_touches_circulation(datum/world_edit_building_layout_state/state, zone_id)
	if(!istype(state) || !length("[zone_id]"))
		return FALSE
	for(var/turf/zone_turf as anything in state.get_zone_turfs(zone_id))
		if(building_turf_touches_circulation(state, zone_turf))
			return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/ensure_required_zone_route_access(datum/world_edit_building_layout_state/state)
	if(!istype(state) || !istype(state.semantic_plan))
		return FALSE
	var/changed = FALSE
	for(var/datum/world_edit_building_zone_spec/zone_spec as anything in state.semantic_plan.zone_specs)
		if(!istype(zone_spec) || !zone_spec.required || !zone_spec.must_touch_route)
			continue
		if(building_zone_touches_circulation(state, zone_spec.id))
			continue
		if(ensure_zone_has_circulation_door(state, zone_spec.id))
			changed = TRUE
			continue
		if(ensure_zone_has_service_spur(state, zone_spec.id))
			changed = TRUE
			continue
		if(ensure_zone_has_route_endpoint(state, zone_spec.id))
			changed = TRUE
			continue
		state.add_warning("Required zone '[zone_spec.id]' could not be connected to the circulation graph during route access solving.")
	return changed

/datum/world_edit_generator/building_layout/proc/ensure_zone_has_circulation_door(datum/world_edit_building_layout_state/state, zone_id)
	if(!istype(state) || !length("[zone_id]"))
		return FALSE
	var/list/zone_turfs = state.get_zone_turfs(zone_id)
	if(!length(zone_turfs))
		return FALSE
	for(var/turf/zone_turf as anything in zone_turfs)
		if(!istype(zone_turf))
			continue
		for(var/check_dir in GLOB.cardinals)
			var/turf/door_turf = get_step(zone_turf, check_dir)
			if(!istype(door_turf) || !state.geometry.footprint_lookup[door_turf])
				continue
			if(state.geometry.boundary_lookup[door_turf] || state.fixtures.fixture_lookup[door_turf])
				continue
			if(!state.geometry.separator_lane_lookup[door_turf] && !state.geometry.wall_lookup[door_turf] && !state.geometry.door_dirs[door_turf])
				continue
			var/turf/route_turf = null
			for(var/route_dir in GLOB.cardinals)
				var/turf/check_turf = get_step(door_turf, route_dir)
				if(check_turf == zone_turf)
					continue
				if(state.geometry.corridor_lookup[check_turf] || state.geometry.reserved_lookup[check_turf])
					route_turf = check_turf
					break
			if(!istype(route_turf))
				continue
			if(!building_door_cone_is_clear_for_validation(state, door_turf, check_dir))
				continue
			state.geometry.wall_lookup -= door_turf
			state.geometry.internal_wall_turfs -= door_turf
			state.append_unique_turf(state.geometry.door_turfs, door_turf)
			state.geometry.door_dirs[door_turf] = check_dir
			state.add_zone(door_turf, zone_id)
			state.add_primary_route(route_turf)
			state.validation.route_access_repair_count++
			state.validation.door_reports += list(list(
				"turf" = door_turf,
				"dir" = state.geometry.door_dirs[door_turf],
				"kind" = "required_route_access",
				"zone_id" = "[zone_id]",
			))
			return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/ensure_zone_has_service_spur(datum/world_edit_building_layout_state/state, zone_id)
	if(!istype(state) || !length("[zone_id]"))
		return FALSE
	for(var/turf/zone_turf as anything in state.get_zone_turfs(zone_id))
		if(!istype(zone_turf) || state.geometry.wall_lookup[zone_turf] || state.fixtures.fixture_lookup[zone_turf])
			continue
		for(var/check_dir in GLOB.cardinals)
			var/turf/nearby_turf = get_step(zone_turf, check_dir)
			if(!istype(nearby_turf) || !state.geometry.floor_lookup[nearby_turf])
				continue
			if(!state.geometry.corridor_lookup[nearby_turf] && !state.geometry.reserved_lookup[nearby_turf])
				continue
			state.add_primary_route(nearby_turf)
			state.validation.route_access_repair_count++
			return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/ensure_zone_has_route_endpoint(datum/world_edit_building_layout_state/state, zone_id)
	if(!istype(state) || !length("[zone_id]"))
		return FALSE
	for(var/turf/zone_turf as anything in state.get_zone_turfs(zone_id))
		if(!istype(zone_turf) || !state.geometry.floor_lookup[zone_turf] || state.geometry.wall_lookup[zone_turf] || state.fixtures.fixture_lookup[zone_turf])
			continue
		state.add_primary_route(zone_turf)
		state.validation.route_access_repair_count++
		return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/validate_building_route_touch(datum/world_edit_building_layout_state/state)
	for(var/datum/world_edit_building_zone_spec/zone_spec as anything in state.semantic_plan.zone_specs)
		if(!zone_spec.required || !zone_spec.must_touch_route)
			continue
		if(!building_zone_touches_circulation(state, zone_spec.id))
			state.validation.reachability_failure_count++
			state.add_error("Required zone '[zone_spec.id]' is not connected to the circulation graph.")

/datum/world_edit_generator/building_layout/proc/validate_building_route_patterns(datum/world_edit_building_layout_state/state)
	if(!istype(state) || !istype(state.archetype))
		return
	for(var/list/route_spec as anything in get_building_required_route_pattern_specs(state))
		if(!islist(route_spec))
			continue
		var/pattern_id = "[route_spec["id"]]"
		var/semantic_credit = "[route_spec["semantic_credit"] || pattern_id]"
		var/acceptance_counter = "[route_spec["acceptance_counter"] || "[semantic_credit]_ok"]"
		var/list/required_zones = route_spec["zones"]
		var/route_zone_id = "[route_spec["route_zone_id"] || ""]"
		var/route_exists = length(state.geometry.corridor_turfs) || length(state.geometry.primary_route_turfs)
		var/route_zone_ok = !length(route_zone_id) || building_route_pattern_has_reserved_zone_turf(state, route_zone_id)
		var/zones_reachable = route_exists && route_zone_ok && building_route_pattern_reaches_zones(state, required_zones)
		var/route_blocking = building_route_pattern_has_blocking_fixture(state, route_zone_id)
		var/credited = zones_reachable && !route_blocking
		state.add_pattern_report(list(
			"id" = pattern_id,
			"status" = credited ? "credited" : "failed",
			"pattern" = "route_pattern",
			"slot" = "reserved_walk",
			"category" = "route",
			"semantic_credit" = semantic_credit,
			"failure_severity" = "required",
			"acceptance_counter" = acceptance_counter,
			"required" = 1,
			"placed" = credited ? 1 : 0,
			"semantic_credit_granted" = credited,
			"access_ok" = zones_reachable,
			"clearance_ok" = !route_blocking,
			"route_blocking" = route_blocking,
			"failure_reason" = credited ? "" : "Route pattern '[pattern_id]' does not have concrete unblocked reserved_walk turfs reaching required zones.",
		))
		if(credited)
			state.register_requirement(pattern_id, 1)
			if(semantic_credit != pattern_id)
				state.register_requirement(semantic_credit, 1)
			state.register_requirement(acceptance_counter, 1)
			continue
		state.validation.route_conflict_count++
		state.validation.mandatory_pattern_failure_count++
		state.validation.mandatory_pattern_uncredited_count++
		if(route_blocking)
			state.validation.reserved_walk_blocked_count++
		state.add_warning("Program [state.archetype.id] route pattern '[pattern_id]' failed validator credit checks.")

/datum/world_edit_generator/building_layout/proc/get_building_required_route_pattern_specs(datum/world_edit_building_layout_state/state)
	var/list/specs = list()
	if(!istype(state) || !istype(state.archetype))
		return specs
	switch(state.archetype.id)
		if("storage")
			specs += list(list("id" = "clear_loading_axis", "semantic_credit" = "loading_axis", "acceptance_counter" = "loading_axis_ok", "route_zone_id" = "loading_axis", "zones" = list("loading_axis", "rack_zone", "staging")))
		if("workshop")
			specs += list(list("id" = "clear_work_aisle", "semantic_credit" = "clear_work_aisle", "acceptance_counter" = "clear_work_aisle_ok", "zones" = list("main_work", "service_wall", "parts_storage")))
		if("hydroponics")
			specs += list(list("id" = "service_aisle", "semantic_credit" = "service_aisle", "acceptance_counter" = "service_aisle_ok", "route_zone_id" = "service_aisle", "zones" = list("service_aisle", "grow_rows", "work_counter", "seed_storage")))
		if("dormitory")
			specs += list(list("id" = "central_sleeping_aisle", "semantic_credit" = "sleeping_aisle", "acceptance_counter" = "sleeping_aisle_ok", "route_zone_id" = "central_aisle", "zones" = list("central_aisle", "sleep_bay", "locker_strip", "ready_area")))
		if("checkpoint")
			specs += list(list("id" = "controlled_passage", "semantic_credit" = "controlled_passage", "acceptance_counter" = "controlled_passage_count", "zones" = list("public_side", "counter_line", "secure_side")))
		if("security")
			specs += list(list("id" = "controlled_passage", "semantic_credit" = "controlled_passage", "acceptance_counter" = "controlled_passage_count", "zones" = list("public_lobby", "desk_line", "secure_work")))
		if("medbay")
			specs += list(list("id" = "medical_access_control", "semantic_credit" = "medical_access_control", "acceptance_counter" = "medical_access_control_count", "zones" = list("entry_buffer", "triage", "treatment", "med_storage")))
		if("chapel")
			specs += list(list("id" = "focal_axis", "semantic_credit" = "focal_axis", "acceptance_counter" = "focal_axis_count", "route_zone_id" = "nave_axis", "zones" = list("nave_axis", "seating_rows", "sanctum")))
		if("ritual_chamber")
			specs += list(list("id" = "focal_axis", "semantic_credit" = "focal_axis", "acceptance_counter" = "focal_axis_count", "route_zone_id" = "ritual_axis", "zones" = list("ritual_axis", "outer_ring", "ritual_focus")))
		if("engineering")
			specs += list(list("id" = "service_aisle", "semantic_credit" = "service_aisle", "acceptance_counter" = "service_aisle_ok", "route_zone_id" = "service_spine", "zones" = list("service_spine", "machine_bay", "power_control", "parts_storage")))
		if("laboratory")
			specs += list(list("id" = "controlled_access", "semantic_credit" = "controlled_access", "acceptance_counter" = "controlled_access_count", "route_zone_id" = "clean_spine", "zones" = list("clean_spine", "analysis_core", "lab_wall", "specimen_storage")))
		if("compound_colony")
			specs += list(list("id" = "spine_corridor", "semantic_credit" = "compound_spine", "acceptance_counter" = "compound_spine_ok", "zones" = list("central_court", "living_wing", "work_bay", "storage_service")))
	return specs

/datum/world_edit_generator/building_layout/proc/building_route_pattern_has_reserved_zone_turf(datum/world_edit_building_layout_state/state, zone_id)
	if(!istype(state) || !length("[zone_id]"))
		return FALSE
	for(var/turf/zone_turf as anything in state.get_zone_turfs(zone_id))
		if(state.geometry.reserved_lookup[zone_turf] || state.geometry.corridor_lookup[zone_turf])
			return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/building_route_pattern_reaches_zones(datum/world_edit_building_layout_state/state, list/required_zones)
	if(!istype(state) || !islist(required_zones))
		return FALSE
	for(var/zone_id as anything in required_zones)
		if(!length("[zone_id]"))
			continue
		if(!length(state.get_zone_turfs(zone_id)))
			return FALSE
		if(!building_route_pattern_touches_zone(state, zone_id))
			return FALSE
	return TRUE

/datum/world_edit_generator/building_layout/proc/building_route_pattern_touches_zone(datum/world_edit_building_layout_state/state, zone_id)
	if(!istype(state) || !length("[zone_id]"))
		return FALSE
	for(var/turf/zone_turf as anything in state.get_zone_turfs(zone_id))
		if(building_turf_touches_circulation(state, zone_turf))
			return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/building_route_pattern_has_blocking_fixture(datum/world_edit_building_layout_state/state, route_zone_id)
	if(!istype(state))
		return TRUE
	for(var/turf/route_turf as anything in state.geometry.primary_route_turfs)
		if(building_turf_has_dense_fixture(state, route_turf) || state.geometry.wall_lookup[route_turf])
			return TRUE
	if(length("[route_zone_id]"))
		for(var/turf/zone_turf as anything in state.get_zone_turfs(route_zone_id))
			if((state.geometry.reserved_lookup[zone_turf] || state.geometry.corridor_lookup[zone_turf]) && (building_turf_has_dense_fixture(state, zone_turf) || state.geometry.wall_lookup[zone_turf]))
				return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/validate_building_semantic_room_access(datum/world_edit_building_layout_state/state)
	if(!istype(state))
		return
	if(!length(state.geometry.corridor_turfs))
		state.validation.route_conflict_count++
		state.add_error("Semantic layout has no reserved route from the entry.")
	if(!length(state.geometry.solved_rooms))
		state.validation.space_distribution_score = 0
		state.add_error("Semantic layout has no solved rooms.")
	var/entry_connected = FALSE
	if(state.geometry.corridor_lookup[state.geometry.front_door_turf])
		entry_connected = TRUE
	else if(istype(state.geometry.front_door_turf))
		var/door_dir = state.geometry.door_dirs[state.geometry.front_door_turf] || state.placement_dir
		if(state.geometry.corridor_lookup[get_step(state.geometry.front_door_turf, turn(door_dir, 180))])
			entry_connected = TRUE
	if(!entry_connected)
		state.validation.route_conflict_count++
		state.add_error("Main route is not connected to the exterior entry door.")

	for(var/turf/corridor_turf as anything in state.geometry.corridor_turfs)
		if(!istype(corridor_turf))
			continue
		if(state.geometry.wall_lookup[corridor_turf])
			state.validation.route_conflict_count++
			state.validation.reserved_walk_blocked_count++
			state.add_error("Main route is blocked by a wall at [GLOB.world_edit_helpers.turf_to_text(corridor_turf)].")
		if(building_turf_has_dense_fixture(state, corridor_turf))
			state.validation.route_conflict_count++
			state.validation.reserved_walk_blocked_count++
			state.add_error("Main route is blocked by a fixture at [GLOB.world_edit_helpers.turf_to_text(corridor_turf)].")

	for(var/datum/world_edit_building_room/room as anything in state.geometry.solved_rooms)
		if(!istype(room))
			continue
		if(!building_room_touches_circulation(state, room))
			state.validation.reachability_failure_count++
			state.validation.mandatory_room_no_access_count++
			state.add_error("Room '[room.id]' for zone '[room.zone_id]' has no door or corridor access.")
		if(room.tiny && !(room.role in list("service", "storage", "private", "nested", "support")))
			state.add_warning("Room '[room.id]' is a one-tile compact room outside a utility/private role.")

	validate_building_wall_geometry_rules(state)

/datum/world_edit_generator/building_layout/proc/building_wall_has_axis(datum/world_edit_building_layout_state/state, turf/wall_turf, axis)
	if(!istype(state) || !istype(wall_turf))
		return FALSE
	if("[axis]" == "vertical")
		return state.geometry.wall_lookup[get_step(wall_turf, NORTH)] || state.geometry.wall_lookup[get_step(wall_turf, SOUTH)]
	if("[axis]" == "horizontal")
		return state.geometry.wall_lookup[get_step(wall_turf, EAST)] || state.geometry.wall_lookup[get_step(wall_turf, WEST)]
	return FALSE

/datum/world_edit_generator/building_layout/proc/validate_building_wall_geometry_rules(datum/world_edit_building_layout_state/state)
	if(!istype(state))
		return
	var/list/protected_wall_lookup = build_building_wall_repair_protection_lookup(state)
	for(var/turf/wall_turf as anything in state.geometry.wall_lookup)
		if(!istype(wall_turf) || state.geometry.door_dirs[wall_turf])
			continue
		var/vertical_wall = building_wall_has_axis(state, wall_turf, "vertical")
		var/horizontal_wall = building_wall_has_axis(state, wall_turf, "horizontal")
		if(vertical_wall)
			for(var/check_dir in list(EAST, WEST))
				var/turf/side_turf = get_step(wall_turf, check_dir)
				if(state.geometry.wall_lookup[side_turf] && building_wall_has_axis(state, side_turf, "vertical"))
					// Attempt repair: remove one of the double walls (prefer the one not on a zone boundary)
					var/turf/remove_turf = null
					var/can_remove_side = !state.geometry.door_dirs[side_turf] && !state.geometry.reserved_lookup[side_turf] && !protected_wall_lookup[side_turf]
					var/can_remove_wall = !state.geometry.door_dirs[wall_turf] && !state.geometry.reserved_lookup[wall_turf] && !protected_wall_lookup[wall_turf]
					if(can_remove_side && !can_remove_wall)
						remove_turf = side_turf
					else if(!can_remove_side && can_remove_wall)
						remove_turf = wall_turf
					else if(can_remove_side && can_remove_wall)
						remove_turf = (!state.geometry.door_dirs[side_turf] && !state.geometry.reserved_lookup[side_turf]) ? side_turf : wall_turf
					if(istype(remove_turf) && !state.geometry.door_dirs[remove_turf] && !state.geometry.reserved_lookup[remove_turf])
						state.geometry.wall_lookup -= remove_turf
						state.geometry.internal_wall_turfs -= remove_turf
						state.validation.double_wall_repair_count++
						state.add_warning("Double-thick vertical wall at [GLOB.world_edit_helpers.turf_to_text(wall_turf)] repaired by removing wall at [GLOB.world_edit_helpers.turf_to_text(remove_turf)].")
					else
						state.validation.fixture_conflict_count++
						state.validation.double_wall_error_count++
						state.add_error("Wall geometry has a double-thick vertical segment at [GLOB.world_edit_helpers.turf_to_text(wall_turf)].")
					break
		if(horizontal_wall)
			for(var/check_dir in list(NORTH, SOUTH))
				var/turf/side_turf = get_step(wall_turf, check_dir)
				if(state.geometry.wall_lookup[side_turf] && building_wall_has_axis(state, side_turf, "horizontal"))
					// Attempt repair: remove one of the double walls
					var/turf/remove_turf = null
					var/can_remove_side = !state.geometry.door_dirs[side_turf] && !state.geometry.reserved_lookup[side_turf] && !protected_wall_lookup[side_turf]
					var/can_remove_wall = !state.geometry.door_dirs[wall_turf] && !state.geometry.reserved_lookup[wall_turf] && !protected_wall_lookup[wall_turf]
					if(can_remove_side && !can_remove_wall)
						remove_turf = side_turf
					else if(!can_remove_side && can_remove_wall)
						remove_turf = wall_turf
					else if(can_remove_side && can_remove_wall)
						remove_turf = (!state.geometry.door_dirs[side_turf] && !state.geometry.reserved_lookup[side_turf]) ? side_turf : wall_turf
					if(istype(remove_turf) && !state.geometry.door_dirs[remove_turf] && !state.geometry.reserved_lookup[remove_turf])
						state.geometry.wall_lookup -= remove_turf
						state.geometry.internal_wall_turfs -= remove_turf
						state.validation.double_wall_repair_count++
						state.add_warning("Double-thick horizontal wall at [GLOB.world_edit_helpers.turf_to_text(wall_turf)] repaired by removing wall at [GLOB.world_edit_helpers.turf_to_text(remove_turf)].")
					else
						state.validation.fixture_conflict_count++
						state.validation.double_wall_error_count++
						state.add_error("Wall geometry has a double-thick horizontal segment at [GLOB.world_edit_helpers.turf_to_text(wall_turf)].")
					break
		validate_building_wall_diagonal_pair(state, wall_turf, NORTHEAST, NORTH, EAST)
		validate_building_wall_diagonal_pair(state, wall_turf, NORTHWEST, NORTH, WEST)
		validate_building_wall_diagonal_pair(state, wall_turf, SOUTHEAST, SOUTH, EAST)
		validate_building_wall_diagonal_pair(state, wall_turf, SOUTHWEST, SOUTH, WEST)

/datum/world_edit_generator/building_layout/proc/validate_building_wall_diagonal_pair(datum/world_edit_building_layout_state/state, turf/wall_turf, diagonal_dir, ortho_a, ortho_b)
	var/turf/diagonal_turf = get_step(wall_turf, diagonal_dir)
	if(!state.geometry.wall_lookup[diagonal_turf])
		return
	var/turf/ortho_turf_a = get_step(wall_turf, ortho_a)
	var/turf/ortho_turf_b = get_step(wall_turf, ortho_b)
	if(state.geometry.wall_lookup[ortho_turf_a] || state.geometry.wall_lookup[ortho_turf_b])
		return
	if(!state.geometry.footprint_lookup[ortho_turf_a] || !state.geometry.footprint_lookup[ortho_turf_b])
		return
	// Attempt repair: add a wall on one of the orthogonal neighbors to break diagonal-only contact
	// Only repair if it won't create a double-wall (check that the repair turf doesn't have a wall neighbor on the same axis)
	var/turf/repair_turf = null
	if(istype(ortho_turf_a) && state.geometry.footprint_lookup[ortho_turf_a] && !state.geometry.door_dirs[ortho_turf_a] && !state.geometry.reserved_lookup[ortho_turf_a] && !state.geometry.corridor_lookup[ortho_turf_a])
		// Check that adding a wall here won't create a double-wall
		var/would_double = FALSE
		for(var/check_dir in list(ortho_a, turn(ortho_a, 180)))
			var/turf/check_turf = get_step(ortho_turf_a, check_dir)
			if(state.geometry.wall_lookup[check_turf])
				would_double = TRUE
				break
		if(!would_double)
			repair_turf = ortho_turf_a
	if(!istype(repair_turf) && istype(ortho_turf_b) && state.geometry.footprint_lookup[ortho_turf_b] && !state.geometry.door_dirs[ortho_turf_b] && !state.geometry.reserved_lookup[ortho_turf_b] && !state.geometry.corridor_lookup[ortho_turf_b])
		var/would_double = FALSE
		for(var/check_dir in list(ortho_b, turn(ortho_b, 180)))
			var/turf/check_turf = get_step(ortho_turf_b, check_dir)
			if(state.geometry.wall_lookup[check_turf])
				would_double = TRUE
				break
		if(!would_double)
			repair_turf = ortho_turf_b
	if(istype(repair_turf))
		state.add_internal_wall(repair_turf)
		state.validation.diagonal_wall_repair_count++
		state.add_warning("Wall diagonal-only contact at [GLOB.world_edit_helpers.turf_to_text(wall_turf)] repaired by adding wall at [GLOB.world_edit_helpers.turf_to_text(repair_turf)].")
		return
	// For small/medium footprints where repair would create double-walls, diagonal-only contacts are acceptable with a warning
	if(is_building_compact_or_micro_state(state) || length(state.geometry.interior) < 500)
		state.validation.diagonal_only_contact_count++
		state.add_warning("Wall diagonal-only contact at [GLOB.world_edit_helpers.turf_to_text(wall_turf)] accepted for small footprint (interior=[length(state.geometry.interior)]).")
		return
	state.validation.fixture_conflict_count++
	state.validation.diagonal_only_contact_count++
	state.add_error("Wall geometry has a diagonal-only wall contact at [GLOB.world_edit_helpers.turf_to_text(wall_turf)].")

/datum/world_edit_generator/building_layout/proc/validate_building_fixture_surface(datum/world_edit_building_layout_state/state)
	var/list/wall_fixture_placement_lookup = list()
	for(var/list/placement as anything in state.fixtures.object_placements)
		if(!islist(placement) || "[placement["kind"]]" != "interior")
			continue
		var/turf/target_turf = placement["turf"]
		if(!state.geometry.floor_lookup[target_turf])
			state.validation.fixture_conflict_count++
			state.add_error("Fixture placement must target a floor turf.")
		if(state.geometry.wall_lookup[target_turf])
			state.validation.fixture_conflict_count++
			state.add_error("Fixture placement overlaps a wall turf.")
		if(state.geometry.door_dirs[target_turf])
			state.validation.fixture_conflict_count++
			state.add_error("Fixture placement overlaps a door turf.")
		if(placement["wall_mounted"])
			wall_fixture_placement_lookup[target_turf] = TRUE
			var/wall_dir = text2num("[placement["wall_dir"]]")
			var/dir_mode = text2num("[placement["dir_mode"]]")
			var/dir_to_use = text2num("[placement["dir"]]")
			if(!(wall_dir in GLOB.cardinals))
				state.validation.fixture_conflict_count++
				state.validation.wall_machinery_invalid_dir_count++
				state.add_error("Wall fixture placement is missing its wall direction.")
				continue
			if(!state.geometry.wall_lookup[get_step(target_turf, wall_dir)])
				state.validation.fixture_conflict_count++
				state.validation.wall_machinery_no_wall_count++
				state.add_error("Wall fixture placement does not point at an adjacent wall.")
				continue
			var/expected_dir = resolve_building_place_rule_dir(wall_dir, dir_mode)
			if(expected_dir != dir_to_use)
				state.validation.fixture_conflict_count++
				state.validation.wall_machinery_invalid_dir_count++
				state.add_error("Wall fixture placement dir does not match its wall rule.")
	for(var/turf/wall_fixture_turf as anything in state.fixtures.wall_fixture_turfs)
		if(!length(get_adjacent_wall_dirs_for_state(state, wall_fixture_turf)))
			state.validation.fixture_conflict_count++
			state.validation.wall_machinery_no_wall_count++
			state.add_error("Wall fixture has no adjacent wall.")
		if(!wall_fixture_placement_lookup[wall_fixture_turf])
			state.validation.fixture_conflict_count++
			state.validation.emit_state_mismatch_count++
			state.add_error("Wall fixture has no emitted object placement.")

/datum/world_edit_generator/building_layout/proc/build_building_wall_repair_protection_lookup(datum/world_edit_building_layout_state/state)
	var/list/protected = list()
	if(!istype(state))
		return protected
	for(var/datum/world_edit_building_divider_plan/divider_plan as anything in state.geometry.divider_plans)
		if(!istype(divider_plan))
			continue
		for(var/turf/wall_turf as anything in divider_plan.wall_turfs)
			if(istype(wall_turf))
				protected[wall_turf] = TRUE
	for(var/list/placement as anything in state.fixtures.object_placements)
		if(!islist(placement) || !GLOB.world_edit_helpers.parse_bool(placement["wall_mounted"]))
			continue
		var/turf/target_turf = placement["turf"]
		if(!istype(target_turf))
			continue
		var/wall_dir = text2num("[placement["wall_dir"]]") || 0
		if(!(wall_dir in GLOB.cardinals))
			continue
		var/turf/wall_turf = get_step(target_turf, wall_dir)
		if(istype(wall_turf))
			protected[wall_turf] = TRUE
	return protected

/datum/world_edit_generator/building_layout/proc/build_building_reachable_floor_lookup(datum/world_edit_building_layout_state/state)
	var/list/reachable = list()
	if(!istype(state))
		return reachable
	var/list/queue = list()
	var/list/start_doors = list()
	for(var/turf/door_turf as anything in state.geometry.door_turfs)
		if(state.geometry.boundary_lookup[door_turf])
			start_doors += door_turf
	if(!length(start_doors))
		start_doors = state.geometry.door_turfs
	for(var/turf/door_turf as anything in start_doors)
		if(state.geometry.floor_lookup[door_turf])
			queue += door_turf
			reachable[door_turf] = TRUE
		var/door_dir = state.geometry.door_dirs[door_turf] || state.placement_dir
		var/turf/inward_turf = get_step(door_turf, turn(door_dir, 180))
		if(state.geometry.floor_lookup[inward_turf] && !reachable[inward_turf])
			queue += inward_turf
			reachable[inward_turf] = TRUE
	var/index = 1
	while(index <= length(queue))
		var/turf/current_turf = queue[index++]
		for(var/check_dir in GLOB.cardinals)
			var/turf/nearby_turf = get_step(current_turf, check_dir)
			if(!state.geometry.floor_lookup[nearby_turf] || reachable[nearby_turf])
				continue
			reachable[nearby_turf] = TRUE
			queue += nearby_turf
	return reachable

/datum/world_edit_generator/building_layout/proc/get_building_validation_reachable_floor_lookup(datum/world_edit_building_layout_state/state)
	if(!istype(state))
		return list()
	if(islist(state.validation.validation_reachable_floor_lookup))
		return state.validation.validation_reachable_floor_lookup
	state.validation.validation_reachable_floor_lookup = build_building_reachable_floor_lookup(state)
	return state.validation.validation_reachable_floor_lookup

/datum/world_edit_generator/building_layout/proc/validate_building_fixture_reachability(datum/world_edit_building_layout_state/state)
	var/list/reachable = get_building_validation_reachable_floor_lookup(state)
	for(var/turf/fixture_turf as anything in state.fixtures.major_fixture_turfs)
		if(reachable[fixture_turf])
			continue
		var/has_adjacent_reachable_floor = FALSE
		for(var/check_dir in GLOB.cardinals)
			if(reachable[get_step(fixture_turf, check_dir)])
				has_adjacent_reachable_floor = TRUE
				break
		if(!has_adjacent_reachable_floor)
			state.validation.reachability_failure_count++
			state.validation.mandatory_fixture_access_unreachable_count++
			state.add_warning("Major fixture at [GLOB.world_edit_helpers.turf_to_text(fixture_turf)] is not reachable from an entry.")

/datum/world_edit_generator/building_layout/proc/validate_building_privacy_rules(datum/world_edit_building_layout_state/state)
	for(var/datum/world_edit_building_zone_spec/zone_spec as anything in state.semantic_plan.zone_specs)
		if(!zone_spec.privacy_sensitive)
			continue
		for(var/turf/private_turf as anything in state.get_zone_turfs(zone_spec.id))
			if(state.has_anchor("door_cone", private_turf))
				state.validation.privacy_violation_count++
				state.add_warning("Privacy zone '[zone_spec.id]' overlaps an entry door cone.")
			for(var/check_dir in GLOB.cardinals)
				var/turf/nearby_turf = get_step(private_turf, check_dir)
				if(state.has_anchor("door_cone", nearby_turf))
					state.validation.privacy_violation_count++
					state.add_warning("Privacy zone '[zone_spec.id]' is directly exposed to an entry door cone.")
					break

/datum/world_edit_generator/building_layout/proc/validate_building_forbidden_rules(datum/world_edit_building_layout_state/state)
	var/list/forbidden_rules = islist(state.semantic_plan?.forbidden_rules) ? state.semantic_plan.forbidden_rules : list()
	for(var/datum/world_edit_building_forbidden_rule/rule as anything in forbidden_rules)
		if(!istype(rule))
			continue
		switch(rule.kind)
			if("zone_anchor")
				for(var/turf/zone_turf as anything in state.get_zone_turfs(rule.zone_id))
					if(state.has_anchor(rule.target_id, zone_turf))
						state.validation.privacy_violation_count++
						state.add_warning("Forbidden rule '[rule.id]' violated: zone '[rule.zone_id]' overlaps anchor '[rule.target_id]'.")
						break
			if("adjacency")
				if(building_zones_are_adjacent(state, rule.zone_id, rule.target_id))
					state.validation.facade_conflict_count++
					state.add_warning("Forbidden rule '[rule.id]' violated: zones '[rule.zone_id]' and '[rule.target_id]' are adjacent.")

/datum/world_edit_generator/building_layout/proc/validate_building_semantic_slot_preflight(datum/world_edit_building_layout_state/state)
	if(!istype(state) || !islist(state.validation.semantic_slot_reports))
		return
	for(var/list/report as anything in state.validation.semantic_slot_reports)
		if(!islist(report))
			continue
		var/shortage = max(round(text2num("[report["shortage"]]") || 0), 0)
		if(shortage <= 0)
			continue
		state.validation.signature_failure_count++
		var/shape_label = "[state.config["footprint_family"] || state.config["placement_shape_id"] || "shape"]"
		state.add_warning("Program [state.archetype.id] in [shape_label] footprint cannot reserve required pattern '[report["id"]]': found [round(text2num("[report["best_capacity"]]") || 0)] slots, needs [round(text2num("[report["required"]]") || 0)].")

/datum/world_edit_generator/building_layout/proc/validate_building_major_clusters(datum/world_edit_building_layout_state/state)
	for(var/datum/world_edit_building_cluster_spec/cluster_spec as anything in state.semantic_plan.get_cluster_specs("major"))
		if(!cluster_spec.required)
			continue
		var/effective_minimum = get_effective_cluster_min_count(state, cluster_spec)
		var/requirement_id = get_building_cluster_requirement_id(cluster_spec)
		var/placed_count = get_building_placed_requirement_count(state, requirement_id, cluster_spec.id, cluster_spec.signature_id)
		var/semantic_credit = length(cluster_spec.semantic_credit) ? cluster_spec.semantic_credit : requirement_id
		var/acceptance_counter = length(cluster_spec.acceptance_counter) ? cluster_spec.acceptance_counter : "[semantic_credit]_count"
		var/list/credit_alias_specs = get_building_cluster_credit_alias_specs(cluster_spec)
		var/access_ok = placed_count >= effective_minimum && building_required_cluster_has_reachable_fixture(state, cluster_spec)
		var/clearance_ok = placed_count >= effective_minimum && building_required_cluster_has_unblocked_fixture(state, cluster_spec)
		var/credited = placed_count >= effective_minimum && access_ok && clearance_ok
		state.add_pattern_report(list(
			"id" = requirement_id,
			"cluster_id" = cluster_spec.id,
			"status" = credited ? "credited" : "failed",
			"pattern" = cluster_spec.pattern,
			"slot" = cluster_spec.slot,
			"category" = cluster_spec.category,
			"semantic_credit" = semantic_credit,
			"semantic_credit_aliases" = build_building_cluster_credit_alias_report(credit_alias_specs),
			"failure_severity" = cluster_spec.failure_severity,
			"acceptance_counter" = acceptance_counter,
			"required" = effective_minimum,
			"placed" = placed_count,
			"semantic_credit_granted" = credited,
			"access_ok" = access_ok,
			"clearance_ok" = clearance_ok,
			"route_blocking" = FALSE,
			"failure_reason" = credited ? "" : "Required pattern placed [placed_count], needs [effective_minimum].",
		))
		if(credited)
			state.register_requirement(requirement_id, placed_count)
			if(length(cluster_spec.id) && cluster_spec.id != requirement_id)
				state.register_requirement(cluster_spec.id, placed_count)
			if(length(cluster_spec.signature_id) && cluster_spec.signature_id != requirement_id)
				state.register_requirement(cluster_spec.signature_id, placed_count)
			for(var/list/alias_spec as anything in credit_alias_specs)
				if(!islist(alias_spec))
					continue
				var/required_alias_capability = "[alias_spec["capability"] || ""]"
				var/alias_count = placed_count
				if(length(required_alias_capability))
					alias_count = get_building_cluster_capability_placement_count(state, cluster_spec, required_alias_capability)
					if(alias_count <= 0)
						continue
				var/alias_credit = "[alias_spec["semantic_credit"]]"
				var/alias_counter = "[alias_spec["acceptance_counter"] || "[alias_credit]_count"]"
				if(length(alias_credit))
					state.register_requirement(alias_credit, alias_count)
				if(length(alias_counter))
					state.register_requirement(alias_counter, alias_count)
			continue
		if(placed_count < effective_minimum)
			state.validation.signature_failure_count++
			state.validation.mandatory_pattern_failure_count++
			state.validation.mandatory_pattern_uncredited_count += max(effective_minimum - placed_count, 1)
			state.add_warning("Program [state.archetype.id] required pattern '[requirement_id]' placed [placed_count], needs [effective_minimum].")
		else
			state.validation.signature_failure_count++
			state.validation.mandatory_pattern_failure_count++
			state.validation.mandatory_pattern_uncredited_count++
			state.add_warning("Program [state.archetype.id] required pattern '[requirement_id]' failed validator credit checks.")

/datum/world_edit_generator/building_layout/proc/validate_building_density_rules(datum/world_edit_building_layout_state/state)
	return

/datum/world_edit_generator/building_layout/proc/get_building_semantic_requirement_count(datum/world_edit_building_layout_state/state, requirement_id, cluster_id = null, signature_id = null)
	if(!istype(state))
		return 0
	var/count = round(text2num("[state.fixtures.semantic_requirement_counts["[requirement_id]"]]") || 0)
	if(length("[cluster_id]"))
		count = max(count, round(text2num("[state.fixtures.semantic_requirement_counts["[cluster_id]"]]") || 0))
	if(length("[signature_id]"))
		count = max(count, round(text2num("[state.fixtures.semantic_requirement_counts["[signature_id]"]]") || 0))
	return count

/datum/world_edit_generator/building_layout/proc/get_building_placed_requirement_count(datum/world_edit_building_layout_state/state, requirement_id, cluster_id = null, signature_id = null)
	if(!istype(state))
		return 0
	var/count = round(text2num("[state.fixtures.placed_requirement_counts["[requirement_id]"]]") || 0)
	if(length("[cluster_id]"))
		count = max(count, round(text2num("[state.fixtures.placed_requirement_counts["[cluster_id]"]]") || 0))
	if(length("[signature_id]"))
		count = max(count, round(text2num("[state.fixtures.placed_requirement_counts["[signature_id]"]]") || 0))
	return count

/datum/world_edit_generator/building_layout/proc/get_building_cluster_credit_alias_specs(datum/world_edit_building_cluster_spec/cluster_spec)
	var/list/alias_specs = list()
	if(!istype(cluster_spec))
		return alias_specs
	switch(cluster_spec.id)
		if("loading_crates")
			alias_specs += list(list("semantic_credit" = "crate_overflow", "acceptance_counter" = "crate_overflow_count", "capability" = "supply_storage"))
		if("serving_counter")
			alias_specs += list(list("semantic_credit" = "serving_surface", "acceptance_counter" = "serving_surface_count", "capability" = "work_surface"))
		if("primary_desk_suite")
			alias_specs += list(list("semantic_credit" = "office_work_surface", "acceptance_counter" = "office_work_surface_count", "capability" = "work_surface"))
		if("locker_run")
			alias_specs += list(list("semantic_credit" = "secure_storage", "acceptance_counter" = "secure_storage_count", "capability" = "storage"))
			alias_specs += list(list("semantic_credit" = "locker_or_armory_wall", "acceptance_counter" = "locker_or_armory_wall_count", "capability" = "storage"))
		if("security_storage")
			alias_specs += list(list("semantic_credit" = "secure_storage", "acceptance_counter" = "secure_storage_count", "capability" = "storage"))
		if("altar_focus")
			alias_specs += list(list("semantic_credit" = "focal_object", "acceptance_counter" = "focal_object_count", "capability" = "work_surface"))
		if("seating_left_rows", "seating_right_rows")
			alias_specs += list(list("semantic_credit" = "seating_group", "acceptance_counter" = "seating_group_count", "capability" = "seating"))
		if("ritual_centerpiece")
			alias_specs += list(list("semantic_credit" = "focal_object", "acceptance_counter" = "focal_object_count", "capability" = "work_surface"))
		if("axis_barriers")
			alias_specs += list(list("semantic_credit" = "ritual_markers", "acceptance_counter" = "ritual_markers_count", "capability" = "barrier"))
		if("power_console_wall")
			alias_specs += list(list("semantic_credit" = "power_control_surface", "acceptance_counter" = "power_control_surface_count", "capability" = "power_control"))
		if("sample_storage_wall")
			alias_specs += list(list("semantic_credit" = "sample_storage", "acceptance_counter" = "sample_storage_count", "capability" = "sample_storage"))
		if("analysis_table")
			alias_specs += list(list("semantic_credit" = "data_surface", "acceptance_counter" = "data_surface_count", "capability" = "work_surface"))
		if("cooking_run")
			alias_specs += list(list("semantic_credit" = "sink_wash", "acceptance_counter" = "sink_wash_count", "capability" = "sink_wash"))
			alias_specs += list(list("semantic_credit" = "kitchen_core", "acceptance_counter" = "kitchen_core_count", "capability" = "food_preparation"))
	return alias_specs

/datum/world_edit_generator/building_layout/proc/build_building_cluster_credit_alias_report(list/alias_specs)
	var/list/report = list()
	if(!islist(alias_specs))
		return report
	for(var/list/alias_spec as anything in alias_specs)
		if(!islist(alias_spec))
			continue
		report += "[alias_spec["semantic_credit"]]"
	return report

/datum/world_edit_generator/building_layout/proc/building_cluster_has_capability_placement(datum/world_edit_building_layout_state/state, datum/world_edit_building_cluster_spec/cluster_spec, required_capability)
	return get_building_cluster_capability_placement_count(state, cluster_spec, required_capability) > 0

/datum/world_edit_generator/building_layout/proc/get_building_cluster_capability_placement_count(datum/world_edit_building_layout_state/state, datum/world_edit_building_cluster_spec/cluster_spec, required_capability)
	if(!istype(state) || !istype(cluster_spec) || !length("[required_capability]"))
		return 0
	var/requirement_id = get_building_cluster_requirement_id(cluster_spec)
	var/count = 0
	for(var/list/placement as anything in state.fixtures.object_placements)
		if(!islist(placement) || "[placement["kind"]]" != "interior")
			continue
		if("[placement["requirement_id"]]" != requirement_id && "[placement["cluster_id"]]" != cluster_spec.id && "[placement["signature_id"]]" != cluster_spec.signature_id)
			continue
		if(building_placement_provides_capability(placement, required_capability))
			count += max(round(text2num("[placement["requirement_count_credit"]]") || 0), 1)
	return count

/datum/world_edit_generator/building_layout/proc/building_required_cluster_has_reachable_fixture(datum/world_edit_building_layout_state/state, datum/world_edit_building_cluster_spec/cluster_spec)
	if(!istype(state) || !istype(cluster_spec))
		return FALSE
	var/requirement_id = get_building_cluster_requirement_id(cluster_spec)
	var/list/reachable = get_building_validation_reachable_floor_lookup(state)
	for(var/list/placement as anything in state.fixtures.object_placements)
		if(!islist(placement) || "[placement["kind"]]" != "interior")
			continue
		if("[placement["requirement_id"]]" != requirement_id && "[placement["cluster_id"]]" != cluster_spec.id && "[placement["signature_id"]]" != cluster_spec.signature_id)
			continue
		var/turf/target_turf = placement["turf"]
		if(reachable[target_turf])
			return TRUE
		for(var/check_dir in GLOB.cardinals)
			if(reachable[get_step(target_turf, check_dir)])
				return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/building_required_cluster_has_unblocked_fixture(datum/world_edit_building_layout_state/state, datum/world_edit_building_cluster_spec/cluster_spec)
	if(!istype(state) || !istype(cluster_spec))
		return FALSE
	var/requirement_id = get_building_cluster_requirement_id(cluster_spec)
	for(var/list/placement as anything in state.fixtures.object_placements)
		if(!islist(placement) || "[placement["kind"]]" != "interior")
			continue
		if("[placement["requirement_id"]]" != requirement_id && "[placement["cluster_id"]]" != cluster_spec.id && "[placement["signature_id"]]" != cluster_spec.signature_id)
			continue
		var/turf/target_turf = placement["turf"]
		if(!istype(target_turf) || state.geometry.reserved_lookup[target_turf] || state.has_anchor("door_cone", target_turf))
			continue
		return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/get_building_requirement_or_category_count(datum/world_edit_building_layout_state/state, requirement_id, category)
	if(!istype(state))
		return 0
	return round(text2num("[state.fixtures.placed_requirement_counts["[requirement_id]"]]") || 0)

/datum/world_edit_generator/building_layout/proc/validate_building_infrastructure_rules(datum/world_edit_building_layout_state/state)
	if(!istype(state) || length(state.geometry.floor_turfs) < 12)
		return
	var/light_count = get_building_requirement_or_category_count(state, "infrastructure_lights", "light")
	if(light_count >= 2)
		state.fixtures.semantic_requirement_counts["infrastructure_lights"] = light_count
	if(light_count < 2)
		state.validation.fixture_conflict_count++
		state.validation.infrastructure_required_missing_count++
		state.add_warning("SS13 infrastructure requires at least two light fixtures.")
	var/apc_count = get_building_requirement_or_category_count(state, "infrastructure_apc", "apc")
	if(apc_count >= 1)
		state.fixtures.semantic_requirement_counts["infrastructure_apc"] = apc_count
	if(apc_count < 1)
		state.validation.fixture_conflict_count++
		state.validation.infrastructure_required_missing_count++
		state.add_warning("SS13 infrastructure requires an APC.")
	var/air_alarm_count = get_building_requirement_or_category_count(state, "infrastructure_air_alarm", "air_alarm")
	if(air_alarm_count >= 1)
		state.fixtures.semantic_requirement_counts["infrastructure_air_alarm"] = air_alarm_count
	if(air_alarm_count < 1)
		state.validation.fixture_conflict_count++
		state.validation.infrastructure_required_missing_count++
		state.add_warning("SS13 infrastructure requires an air alarm.")
	var/light_switch_count = get_building_requirement_or_category_count(state, "infrastructure_light_switch", "light_switch")
	if(light_switch_count >= 1)
		state.fixtures.semantic_requirement_counts["infrastructure_light_switch"] = light_switch_count
	if(light_switch_count < 1)
		state.validation.fixture_conflict_count++
		state.validation.infrastructure_required_missing_count++
		state.add_warning("SS13 infrastructure requires a light switch near entry/service wall.")
	var/fire_alarm_count = get_building_requirement_or_category_count(state, "infrastructure_fire_alarm", "fire_alarm")
	if(fire_alarm_count >= 1)
		state.fixtures.semantic_requirement_counts["infrastructure_fire_alarm"] = fire_alarm_count
	if(length(state.geometry.floor_turfs) >= 30 && fire_alarm_count < 1)
		state.validation.fixture_conflict_count++
		state.validation.infrastructure_required_missing_count++
		state.add_warning("SS13 infrastructure requires a fire alarm for medium/large buildings.")

/datum/world_edit_generator/building_layout/proc/validate_building_direction_contract(datum/world_edit_building_layout_state/state)
	if(!istype(state))
		return
	if(!(state.geometry.requested_direction in GLOB.cardinals) || !(state.geometry.actual_entry_direction in GLOB.cardinals))
		state.validation.entry_face_mismatch_count++
		state.add_error("Building entry direction contract has non-cardinal requested or actual direction.")
		return
	if(state.geometry.actual_entry_direction == state.geometry.requested_direction)
		state.validation.direction_honored_count = max(state.validation.direction_honored_count, 1)
		return
	state.validation.direction_fallback_count = max(state.validation.direction_fallback_count, 1)
	if(!length(state.geometry.direction_fallback_reason))
		state.geometry.direction_fallback_reason = "Selected footprint could not emit entry on requested direction."
	state.validation.entry_face_mismatch_count++
	state.add_error("Building entry direction does not match requested direction.")

/datum/world_edit_generator/building_layout/proc/validate_building_counter_facing(datum/world_edit_building_layout_state/state)
	if(!istype(state) || !istype(state.archetype))
		return
	if(!(state.archetype.id in list("checkpoint", "security")))
		return
	var/list/public_zone_lookup = list()
	if(state.archetype.id == "checkpoint")
		public_zone_lookup["public_side"] = TRUE
	else
		public_zone_lookup["public_lobby"] = TRUE
	var/checked_counter_count = 0
	var/correct_counter_count = 0
	for(var/list/placement as anything in state.fixtures.object_placements)
		if(!islist(placement) || "[placement["kind"]]" != "interior")
			continue
		if("[placement["cluster_pattern"]]" != "signature_security_counter")
			continue
		checked_counter_count++
		var/turf/target_turf = placement["turf"]
		var/counter_dir = text2num("[placement["dir"]]")
		if(!(counter_dir in GLOB.cardinals))
			state.validation.counter_wrong_facing_count++
			continue
		var/turf/front_turf = get_step(target_turf, counter_dir)
		if(public_zone_lookup[state.get_zone(front_turf)] || state.has_anchor("public_route", front_turf) || state.has_anchor("counter_front", front_turf))
			correct_counter_count++
			continue
		state.validation.counter_wrong_facing_count++
	if(checked_counter_count > 0 && correct_counter_count <= 0)
		state.add_error("Security/checkpoint counter does not face the public approach.")

/datum/world_edit_generator/building_layout/proc/validate_building_signature_rules(datum/world_edit_building_layout_state/state)
	var/raw_score = 0
	var/max_score = 0
	if(islist(state.semantic_plan.signature_minimums))
		for(var/signature_id as anything in state.semantic_plan.signature_minimums)
			var/minimum = max(round(text2num("[state.semantic_plan.signature_minimums[signature_id]]") || 0), 0)
			minimum = get_effective_signature_min_count(state, signature_id, minimum)
			var/weight = max(round(text2num("[state.semantic_plan.signature_weights[signature_id]]") || 0), 1)
			var/placed = round(text2num("[state.fixtures.semantic_requirement_counts["[signature_id]"]]") || 0)
			max_score += weight
			if(placed >= minimum)
				raw_score += weight
				continue
			var/message = "Program [state.archetype.id] semantic signature '[signature_id]' placed [placed], needs [minimum]."
			state.fixtures.signature_warnings += message
			state.validation.signature_failure_count++
			state.validation.mandatory_pattern_failure_count++
			state.add_warning(message)
	state.validation.signature_max_score = max_score > 0 ? 100 : 0
	state.validation.signature_score = max_score > 0 ? round(raw_score * 100 / max_score) : 100
	if(max_score > 0 && state.validation.signature_score < state.semantic_plan.min_signature_score)
		state.validation.signature_failure_count++
		state.add_warning("Program [state.archetype.id] signature score [state.validation.signature_score]/100 is below [state.semantic_plan.min_signature_score].")

	var/open_floor = 0
	var/relevant_floor = 0
	for(var/turf/floor_turf as anything in state.geometry.floor_turfs)
		if(!istype(floor_turf) || state.geometry.wall_lookup[floor_turf] || state.geometry.door_dirs[floor_turf])
			continue
		relevant_floor++
		if(!state.fixtures.fixture_lookup[floor_turf] && !state.geometry.reserved_lookup[floor_turf])
			open_floor++
	state.validation.empty_floor_ratio = relevant_floor > 0 ? round(open_floor * 100 / relevant_floor) : 0
	var/max_empty_floor_ratio = get_building_max_empty_floor_ratio(state)
	if(relevant_floor >= 24 && state.validation.empty_floor_ratio > max_empty_floor_ratio)
		var/empty_message = "Program [state.archetype.id] leaves [state.validation.empty_floor_ratio]% non-route floor empty after mandatory signatures."
		state.fixtures.signature_warnings += empty_message
		state.validation.signature_failure_count++
		state.add_warning("[empty_message] Maximum allowed is [max_empty_floor_ratio]%.")

/datum/world_edit_generator/building_layout/proc/get_building_max_empty_floor_ratio(datum/world_edit_building_layout_state/state)
	if(!istype(state))
		return WORLD_EDIT_BUILDING_DEFAULT_MAX_EMPTY_FLOOR_RATIO
	var/list/style_budget = islist(state.semantic_plan?.style_budget) ? state.semantic_plan.style_budget : list()
	var/threshold = round(text2num("[style_budget["max_empty_floor_ratio"]]") || WORLD_EDIT_BUILDING_DEFAULT_MAX_EMPTY_FLOOR_RATIO)
	return clamp(threshold, 35, 78)

/datum/world_edit_generator/building_layout/proc/validate_building_nested_room_rules(datum/world_edit_building_layout_state/state)
	var/list/nested_specs = islist(state.semantic_plan?.nested_room_specs) ? state.semantic_plan.nested_room_specs.Copy() : list()
	if(!length(nested_specs) && length("[state.semantic_plan?.nested_inner_zone]"))
		nested_specs += new /datum/world_edit_building_nested_room_spec(state.semantic_plan.nested_outer_zone, state.semantic_plan.nested_inner_zone, state.semantic_plan.nested_min_width, state.semantic_plan.nested_min_height, 1)
	for(var/datum/world_edit_building_nested_room_spec/nested_spec as anything in nested_specs)
		if(!istype(nested_spec) || !length(nested_spec.inner_zone_id))
			continue
		if((state.geometry.bounds["width"] || 0) < nested_spec.min_width || (state.geometry.bounds["height"] || 0) < nested_spec.min_height)
			continue
		if(!length(state.get_zone_turfs(nested_spec.inner_zone_id)))
			continue
		var/datum/world_edit_building_zone_spec/inner_zone_spec = state.semantic_plan.get_zone_spec(nested_spec.inner_zone_id)
		if(istype(inner_zone_spec) && inner_zone_spec.role != "nested")
			continue
		var/nested_plan_found = FALSE
		for(var/datum/world_edit_building_divider_plan/divider_plan as anything in state.geometry.divider_plans)
			if(istype(divider_plan) && divider_plan.inner_zone_id == nested_spec.inner_zone_id && findtext("[divider_plan.id]", "nested_") == 1)
				nested_plan_found = TRUE
				break
		if(!nested_plan_found)
			state.add_error("Nested zone '[nested_spec.inner_zone_id]' exists without a data-driven nested room plan.")
		else if(!length(state.geometry.internal_wall_turfs))
			state.add_error("Nested zone '[nested_spec.inner_zone_id]' exists without internal walls.")

/datum/world_edit_generator/building_layout/proc/validate_building_divider_rules(datum/world_edit_building_layout_state/state)
	for(var/datum/world_edit_building_divider_plan/divider_plan as anything in state.geometry.divider_plans)
		if(!istype(divider_plan))
			continue
		if(length(divider_plan.wall_turfs) && !length(divider_plan.opening_turfs))
			state.add_error("Divider '[divider_plan.id]' has walls without a controlled opening.")
		for(var/turf/wall_turf as anything in divider_plan.wall_turfs)
			if(state.geometry.reserved_lookup[wall_turf])
				state.add_error("Divider '[divider_plan.id]' overlaps a primary route.")
			if(!state.geometry.wall_lookup[wall_turf])
				state.add_error("Divider '[divider_plan.id]' planned wall was not emitted as a wall.")
		for(var/turf/opening_turf as anything in divider_plan.opening_turfs)
			if(!state.geometry.door_dirs[opening_turf])
				state.add_error("Divider '[divider_plan.id]' opening is missing a controlled door.")
			if(state.geometry.wall_lookup[opening_turf])
				state.add_error("Divider '[divider_plan.id]' opening overlaps a wall.")

/datum/world_edit_generator/building_layout/proc/validate_building_acceptance_counters(datum/world_edit_building_layout_state/state)
	if(!istype(state))
		return
	var/hard_failure = FALSE
	if(state.validation.forbidden_fallback_count > 0)
		state.add_error("Forbidden fallback use is not accepted: forbidden_fallback_count=[state.validation.forbidden_fallback_count].")
		hard_failure = TRUE
	if(state.validation.fallback_anchor_required_cluster_count > 0)
		state.add_error("Required pattern attempted fallback anchors: fallback_anchor_required_cluster_count=[state.validation.fallback_anchor_required_cluster_count].")
		hard_failure = TRUE
	if(state.validation.style_required_slot_missing_count > 0)
		state.add_error("Required fixture capabilities are missing: style_required_slot_missing_count=[state.validation.style_required_slot_missing_count].")
		hard_failure = TRUE
	if(state.validation.mandatory_room_patch_fallback_count > 0)
		state.add_error("Required room patch fallback is not accepted: mandatory_room_patch_fallback_count=[state.validation.mandatory_room_patch_fallback_count].")
		hard_failure = TRUE
	if(state.validation.unsupported_shape_silent_fallback_count > 0)
		state.add_error("Unsupported shape silent fallback is not accepted: unsupported_shape_silent_fallback_count=[state.validation.unsupported_shape_silent_fallback_count].")
		hard_failure = TRUE
	if(state.validation.raw_category_credit_count > 0)
		state.add_error("Raw category counts cannot satisfy semantic credit: raw_category_credit_count=[state.validation.raw_category_credit_count].")
		hard_failure = TRUE
	if(state.validation.scatter_signature_credit_count > 0)
		state.add_error("Scatter placement cannot satisfy program signature: scatter_signature_credit_count=[state.validation.scatter_signature_credit_count].")
		hard_failure = TRUE
	if(state.validation.mandatory_pattern_failure_count > 0)
		state.add_error("Mandatory pattern failures detected: mandatory_pattern_failure_count=[state.validation.mandatory_pattern_failure_count].")
		hard_failure = TRUE
	if(state.validation.post_emit_validation_error_count > 0)
		state.add_error("Post-emit validation errors detected: post_emit_validation_error_count=[state.validation.post_emit_validation_error_count].")
		hard_failure = TRUE
	if(state.validation.reachability_failure_count > 0)
		state.add_error("Reachability failures detected: reachability_failure_count=[state.validation.reachability_failure_count].")
		hard_failure = TRUE
	if(hard_failure)
		state.set_support_status(WORLD_EDIT_BUILDING_SUPPORT_FAILED, "Hard counter failures: forbidden_fallback=[state.validation.forbidden_fallback_count], style_required_slot_missing=[state.validation.style_required_slot_missing_count], mandatory_pattern_failure=[state.validation.mandatory_pattern_failure_count], post_emit_validation_error=[state.validation.post_emit_validation_error_count], reachability_failure=[state.validation.reachability_failure_count].")
