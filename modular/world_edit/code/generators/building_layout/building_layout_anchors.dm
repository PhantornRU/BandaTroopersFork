/datum/world_edit_generator/building_layout/proc/extract_building_anchors(datum/world_edit_building_layout_state/state)
	if(!istype(state))
		return
	for(var/turf/floor_turf as anything in state.floor_turfs)
		var/zone_id = state.get_zone(floor_turf)
		if(length(zone_id))
			state.add_anchor(zone_id, floor_turf)
			var/datum/world_edit_building_zone_spec/zone_spec = state.semantic_plan?.get_zone_spec(zone_id)
			if(istype(zone_spec))
				for(var/anchor_tag as anything in zone_spec.anchor_tags)
					state.add_anchor("[anchor_tag]", floor_turf)
		if(state.reserved_lookup[floor_turf])
			state.add_anchor("primary_lane", floor_turf)
		if(length(get_adjacent_wall_dirs_for_state(state, floor_turf)))
			state.add_anchor("wall_anchor", floor_turf)
		if(is_corner_floor_anchor(state, floor_turf))
			state.add_anchor("corner_anchor", floor_turf)

	add_door_cone_anchors(state)
	add_window_band_anchors(state)
	if(istype(state.center_turf))
		state.add_anchor("focus_center", state.center_turf)
		for(var/check_dir in GLOB.cardinals)
			var/turf/focus_turf = get_step(state.center_turf, check_dir)
			if(state.floor_lookup[focus_turf] && !state.reserved_lookup[focus_turf])
				state.add_anchor("focus_ring", focus_turf)
	if(istype(state.semantic_hub_turf))
		state.add_anchor("semantic_hub", state.semantic_hub_turf)
	for(var/zone_id as anything in state.zone_focus_turfs)
		var/turf/zone_focus = state.zone_focus_turfs[zone_id]
		if(istype(zone_focus))
			state.add_anchor("[zone_id]_focus", zone_focus)

/datum/world_edit_generator/building_layout/proc/get_adjacent_wall_dirs_for_state(datum/world_edit_building_layout_state/state, turf/target_turf)
	var/list/wall_dirs = list()
	if(!istype(state) || !istype(target_turf))
		return wall_dirs
	for(var/check_dir in GLOB.cardinals)
		if(state.wall_lookup[get_step(target_turf, check_dir)])
			wall_dirs += check_dir
	return wall_dirs

/datum/world_edit_generator/building_layout/proc/is_corner_floor_anchor(datum/world_edit_building_layout_state/state, turf/target_turf)
	var/list/wall_dirs = get_adjacent_wall_dirs_for_state(state, target_turf)
	if(length(wall_dirs) < 2)
		return FALSE
	for(var/dir_a in wall_dirs)
		for(var/dir_b in wall_dirs)
			if(dir_a == dir_b)
				continue
			if(turn(dir_a, 90) == dir_b || turn(dir_a, -90) == dir_b)
				return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/add_door_cone_anchors(datum/world_edit_building_layout_state/state)
	for(var/turf/door_turf as anything in state.door_turfs)
		if(!state.boundary_lookup[door_turf])
			continue
		var/outward_dir = state.door_dirs[door_turf] || get_outward_dir(door_turf, state.footprint_lookup, (state.bounds["min_x"] + state.bounds["max_x"]) / 2, (state.bounds["min_y"] + state.bounds["max_y"]) / 2, state.placement_dir)
		var/inward_dir = turn(outward_dir, 180)
		var/turf/cone_turf = door_turf
		for(var/step_index in 1 to 2)
			cone_turf = get_step(cone_turf, inward_dir)
			if(!state.floor_lookup[cone_turf])
				break
			state.add_anchor("door_cone", cone_turf)
			state.add_anchor("primary_lane", cone_turf)
			state.add_reserved(cone_turf)

/datum/world_edit_generator/building_layout/proc/add_window_band_anchors(datum/world_edit_building_layout_state/state)
	for(var/turf/window_turf as anything in state.window_turfs)
		for(var/check_dir in GLOB.cardinals)
			var/turf/nearby = get_step(window_turf, check_dir)
			if(state.floor_lookup[nearby])
				state.add_anchor("window_band", nearby)
