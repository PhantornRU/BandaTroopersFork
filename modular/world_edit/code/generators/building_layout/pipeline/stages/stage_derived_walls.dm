/datum/world_edit_generation_stage/derived_walls
	id = "derived_walls"

/datum/world_edit_generation_stage/derived_walls/execute(datum/world_edit_generation_context/context)
	var/datum/world_edit_building_layout_state/state = context.state
	var/datum/world_edit_generator/building_layout/generator = context.generator

	// Step 1: Collect walkable turfs
	var/list/walkable = list()
	var/list/explicit_walls = list()
	state.geometry.room_by_turf.Cut()
	state.geometry.floor_turfs.Cut()
	
	for(var/datum/world_edit_building_room/room as anything in state.geometry.solved_rooms)
		for(var/turf/T as anything in room.turfs)
			if(!istype(T) || state.geometry.wall_lookup[T])
				continue
			walkable[T] = TRUE
			state.geometry.room_by_turf[T] = room
			state.append_unique_turf(state.geometry.floor_turfs, T)

	for(var/turf/T as anything in state.geometry.primary_route_turfs)
		if(!istype(T) || state.geometry.wall_lookup[T])
			continue
		if(!walkable[T])
			walkable[T] = TRUE
			state.append_unique_turf(state.geometry.floor_turfs, T)

	if((round(text2num("[state.config["target_room_count"]]") || 0)) > 0)
		for(var/turf/T as anything in state.geometry.door_dirs)
			if(!istype(T) || !state.geometry.footprint_lookup[T])
				continue
			state.geometry.wall_lookup -= T
			state.geometry.internal_wall_turfs -= T
			if(!walkable[T])
				walkable[T] = TRUE
				state.append_unique_turf(state.geometry.floor_turfs, T)

	// Step 2: Derive walls
	var/list/walls = list()
	for(var/turf/existing_wall_turf as anything in state.geometry.wall_lookup)
		if(istype(existing_wall_turf))
			walls[existing_wall_turf] = TRUE
			explicit_walls[existing_wall_turf] = TRUE
	
	for(var/turf/W as anything in walkable)
		for(var/dir in GLOB.alldirs)
			var/turf/neighbor = get_step(W, dir)
			if(!neighbor || walkable[neighbor])
				continue
				
			// Ensure it's inside footprint
			if(!state.geometry.footprint_lookup[neighbor])
				continue
				
			if(!walls[neighbor])
				walls[neighbor] = TRUE
				state.geometry.wall_lookup[neighbor] = TRUE

	// Step 3: Cleanup isolated walls (acne / spikes)
	var/removed = 0
	for(var/turf/wall_turf as anything in walls)
		if(explicit_walls[wall_turf])
			continue
		var/wall_neighbors = 0
		for(var/dir in GLOB.alldirs)
			var/turf/n = get_step(wall_turf, dir)
			if(walls[n])
				wall_neighbors++
		
		if(wall_neighbors <= 1)
			state.geometry.wall_lookup -= wall_turf
			walls -= wall_turf
			removed++

	// Recalculate floor lookup
	state.geometry.floor_lookup = GLOB.world_edit_placement_shapes.world_edit_build_turf_lookup(state.geometry.floor_turfs)
	
	// Legacy center logic re-evaluation based on new floor definition
	var/center_x = (state.geometry.bounds["min_x"] + state.geometry.bounds["max_x"]) / 2
	var/center_y = (state.geometry.bounds["min_y"] + state.geometry.bounds["max_y"]) / 2
	state.geometry.center_turf = generator.select_center_floor_turf(state.geometry.floor_turfs, center_x, center_y) || state.geometry.front_door_turf
	generator.refresh_building_zone_foci(state)
	state.geometry.semantic_hub_turf = state.get_zone_focus(state.semantic_plan?.hub_zone_id) || state.geometry.center_turf

	state.geometry.wall_hash = generator.build_building_turf_lookup_hash(state.geometry.wall_lookup)
	state.validation.wall_report = list(
		"wall_count" = length(state.geometry.wall_lookup),
		"wall_hash" = state.geometry.wall_hash,
	)

	context.state.add_stage_report("derived_walls", "ok", null, list(
		"derived_walls" = length(walls),
		"cleaned_walls" = removed,
		"wall_hash" = state.geometry.wall_hash
	))
	return TRUE
