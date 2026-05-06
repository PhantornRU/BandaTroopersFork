/datum/world_edit_generator/building_layout/proc/build_building_windows(datum/world_edit_building_layout_state/state)
	var/window_density = clamp(round(text2num("[state.config["window_density"]]")), 0, 100)
	if(window_density <= 0)
		return
	window_density = round((window_density + state.archetype.window_bias) / 2)
	var/list/door_lookup = GLOB.world_edit_placement_shapes.world_edit_build_turf_lookup(state.door_turfs)
	var/list/candidates = list()
	var/list/candidate_lookup = list()
	for(var/turf/boundary_turf as anything in state.boundary)
		if(door_lookup[boundary_turf])
			continue
		if(is_corner_boundary_turf(boundary_turf, state.footprint_lookup))
			continue
		if(!can_place_building_window_for_boundary_turf(state, boundary_turf))
			continue
		append_unique_turf(candidates, candidate_lookup, boundary_turf)

	if(!length(candidates) || window_density <= 0)
		return

	var/target_count = min(WORLD_EDIT_BUILDING_MAX_WINDOWS, max(1, round(length(candidates) * window_density / 250)))
	var/stride = max(round(length(candidates) / max(target_count, 1)), 1)
	var/index = state.request.facade_rng.next_between(1, min(stride, length(candidates)))
	while(length(state.window_turfs) < target_count && index <= length(candidates))
		var/turf/window_turf = candidates[index]
		state.append_unique_turf(state.window_turfs, window_turf)
		index += stride

/datum/world_edit_generator/building_layout/proc/get_building_window_interior_turf(datum/world_edit_building_layout_state/state, turf/boundary_turf)
	if(!istype(state) || !istype(boundary_turf) || !state.boundary_lookup[boundary_turf])
		return null
	for(var/check_dir in GLOB.cardinals)
		var/turf/nearby_turf = get_step(boundary_turf, check_dir)
		if(state.footprint_lookup[nearby_turf] && !state.boundary_lookup[nearby_turf] && !state.wall_lookup[nearby_turf])
			return nearby_turf
	return null

/datum/world_edit_generator/building_layout/proc/can_place_building_window_for_boundary_turf(datum/world_edit_building_layout_state/state, turf/boundary_turf)
	var/turf/interior_turf = get_building_window_interior_turf(state, boundary_turf)
	if(!istype(interior_turf))
		return FALSE
	var/datum/world_edit_building_zone_spec/zone_spec = state.semantic_plan?.get_zone_spec(state.get_zone(interior_turf))
	if(!istype(zone_spec))
		return FALSE
	if(zone_spec.privacy_sensitive || !zone_spec.window_allowed)
		return FALSE
	return TRUE

/datum/world_edit_generator/building_layout/proc/apply_building_facade_rules(datum/world_edit_building_layout_state/state)
	if(!istype(state))
		return
	for(var/turf/boundary_turf as anything in state.boundary)
		if(state.wall_lookup[boundary_turf])
			state.add_anchor("facade_segment", boundary_turf)
