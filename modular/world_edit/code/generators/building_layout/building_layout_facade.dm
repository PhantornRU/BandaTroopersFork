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
		if(boundary_turf_has_outside_dir(boundary_turf, state.footprint_lookup, state.placement_dir) && state.archetype.id in list("storage_small", "checkpoint_small"))
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

/datum/world_edit_generator/building_layout/proc/apply_building_facade_rules(datum/world_edit_building_layout_state/state)
	if(!istype(state))
		return
	for(var/turf/boundary_turf as anything in state.boundary)
		if(state.wall_lookup[boundary_turf])
			state.add_anchor("facade_segment", boundary_turf)
