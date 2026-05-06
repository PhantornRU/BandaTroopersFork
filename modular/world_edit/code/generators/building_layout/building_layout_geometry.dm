/datum/world_edit_generator/building_layout/proc/world_edit_building_front_depth(turf/target_turf, list/bounds, direction)
	if(!istype(target_turf) || !islist(bounds))
		return 0
	switch(direction)
		if(NORTH)
			return text2num("[bounds["max_y"]]") - target_turf.y
		if(SOUTH)
			return target_turf.y - text2num("[bounds["min_y"]]")
		if(EAST)
			return text2num("[bounds["max_x"]]") - target_turf.x
		if(WEST)
			return target_turf.x - text2num("[bounds["min_x"]]")
	return 0

/datum/world_edit_generator/building_layout/proc/world_edit_building_lateral_offset(turf/target_turf, list/bounds, direction)
	if(!istype(target_turf) || !islist(bounds))
		return 0
	var/center_x = (text2num("[bounds["min_x"]]") + text2num("[bounds["max_x"]]")) / 2
	var/center_y = (text2num("[bounds["min_y"]]") + text2num("[bounds["max_y"]]")) / 2
	if(direction in list(NORTH, SOUTH))
		return target_turf.x - center_x
	return target_turf.y - center_y

/datum/world_edit_generator/building_layout/proc/build_building_layout_state(datum/world_edit_building_request/request, datum/world_edit_shape_contract/shape_contract, list/placement_context, list/validated)
	var/datum/world_edit_building_layout_state/state = new
	state.request = request
	state.config = request.config
	state.archetype = request.archetype
	state.footprint = validated["footprint"]
	state.boundary = validated["boundary"]
	state.interior = validated["interior"]
	state.footprint_lookup = validated["footprint_lookup"]
	state.bounds = validated["bounds"]
	state.boundary_lookup = GLOB.world_edit_placement_shapes.world_edit_build_turf_lookup(state.boundary)
	state.placement_dir = text2num("[placement_context["direction"]]")
	if(!(state.placement_dir in GLOB.cardinals))
		state.placement_dir = manager?.get_effective_placement_dir() || NORTH

	if(length(state.footprint) > WORLD_EDIT_BUILDING_MAX_FOOTPRINT_TURFS)
		state.add_error("Building footprint exceeds cap ([WORLD_EDIT_BUILDING_MAX_FOOTPRINT_TURFS]).")
		return state

	build_building_doors(state)
	if(state.has_errors())
		return state
	assign_building_zones(state)
	build_building_windows(state)
	build_building_walls_and_floors(state)
	build_building_reserved_lanes(state)
	return state

/datum/world_edit_generator/building_layout/proc/build_building_doors(datum/world_edit_building_layout_state/state)
	var/center_x = (state.bounds["min_x"] + state.bounds["max_x"]) / 2
	var/center_y = (state.bounds["min_y"] + state.bounds["max_y"]) / 2
	var/turf/front_door_turf = select_boundary_turf_for_dir(state.boundary, center_x, center_y, state.placement_dir, null, state.footprint_lookup)
	if(!istype(front_door_turf))
		state.add_error("Unable to select a building entry door turf.")
		return
	state.front_door_turf = front_door_turf
	state.append_unique_turf(state.door_turfs, front_door_turf)
	state.door_dirs[front_door_turf] = get_outward_dir(front_door_turf, state.footprint_lookup, center_x, center_y, state.placement_dir)

	if(state.config["back_exit"])
		var/list/front_lookup = list()
		front_lookup[front_door_turf] = TRUE
		var/turf/back_door_turf = select_boundary_turf_for_dir(state.boundary, center_x, center_y, turn(state.placement_dir, 180), front_lookup, state.footprint_lookup)
		if(istype(back_door_turf))
			state.append_unique_turf(state.door_turfs, back_door_turf)
			state.door_dirs[back_door_turf] = get_outward_dir(back_door_turf, state.footprint_lookup, center_x, center_y, turn(state.placement_dir, 180))

/datum/world_edit_generator/building_layout/proc/assign_building_zones(datum/world_edit_building_layout_state/state)
	if(!istype(state) || !istype(state.archetype))
		return

	var/max_depth = 1
	for(var/turf/interior_turf as anything in state.interior)
		max_depth = max(max_depth, world_edit_building_front_depth(interior_turf, state.bounds, state.placement_dir))

	for(var/turf/interior_turf as anything in state.interior)
		var/depth = world_edit_building_front_depth(interior_turf, state.bounds, state.placement_dir)
		var/lateral = world_edit_building_lateral_offset(interior_turf, state.bounds, state.placement_dir)
		var/zone_id = state.archetype.primary_zone
		if(depth <= 1)
			zone_id = state.archetype.entry_zone
		else
			switch(state.archetype.id)
				if("colony_living_small")
					if(depth >= max_depth - 1 && abs(lateral) >= 2)
						zone_id = "sleep_privacy"
					else if(abs(lateral) >= 2)
						zone_id = "storage_service"
					else
						zone_id = "common"
				if("uscm_workshop_small")
					if(abs(lateral) >= 2)
						zone_id = "service_wall"
					else if(depth >= max_depth - 1)
						zone_id = "parts_storage"
					else
						zone_id = "main_work"
				if("uscm_storage_small")
					if(abs(lateral) <= 1)
						zone_id = "loading_axis"
					else if(depth >= max_depth - 1)
						zone_id = "staging"
					else
						zone_id = "rack_zone"
				if("uscm_checkpoint_wedge")
					if(depth <= 2)
						zone_id = "public_side"
					else if(depth <= 3)
						zone_id = "counter_line"
					else if(abs(lateral) >= 2)
						zone_id = "observation"
					else
						zone_id = "secure_side"
				if("medbay_small")
					if(depth <= 2)
						zone_id = "triage"
					else if(abs(lateral) >= 2 || depth >= max_depth - 1)
						zone_id = "med_storage"
					else
						zone_id = "treatment"
		state.add_zone(interior_turf, zone_id)

/datum/world_edit_generator/building_layout/proc/build_building_walls_and_floors(datum/world_edit_building_layout_state/state)
	var/list/door_lookup = GLOB.world_edit_placement_shapes.world_edit_build_turf_lookup(state.door_turfs)
	var/list/window_lookup = GLOB.world_edit_placement_shapes.world_edit_build_turf_lookup(state.window_turfs)
	for(var/turf/footprint_turf as anything in state.footprint)
		if(state.boundary_lookup[footprint_turf] && !door_lookup[footprint_turf] && !window_lookup[footprint_turf])
			state.wall_lookup[footprint_turf] = TRUE
		else
			state.append_unique_turf(state.floor_turfs, footprint_turf)
	state.floor_lookup = GLOB.world_edit_placement_shapes.world_edit_build_turf_lookup(state.floor_turfs)
	var/center_x = (state.bounds["min_x"] + state.bounds["max_x"]) / 2
	var/center_y = (state.bounds["min_y"] + state.bounds["max_y"]) / 2
	state.center_turf = select_center_floor_turf(state.floor_turfs, center_x, center_y) || state.front_door_turf

/datum/world_edit_generator/building_layout/proc/build_building_reserved_lanes(datum/world_edit_building_layout_state/state)
	if(!istype(state.center_turf))
		return
	var/list/reserved_path = build_reserved_paths(state.door_turfs, state.center_turf, state.floor_lookup)
	for(var/turf/reserved_turf as anything in reserved_path)
		state.add_reserved(reserved_turf)
