/datum/world_edit_generation_stage/interiors
	id = "interiors"

/datum/world_edit_generation_stage/interiors/execute(datum/world_edit_generation_context/context)
	var/datum/world_edit_generator/building_layout/generator = context.generator
	
	// Phase 8: Room Analysis & Anchor generation
	for(var/datum/world_edit_building_room/room as anything in context.state.geometry.solved_rooms)
		analyze_room_geometry(context.state, room)
		generate_room_anchors(context.state, room)
		place_room_prefab_groups(context.state, room, generator)
		
	context.state.add_stage_report("interiors", "ok", null, list(
		"rooms_analyzed" = length(context.state.geometry.solved_rooms)
	))
	return TRUE

/datum/world_edit_generation_stage/interiors/proc/analyze_room_geometry(datum/world_edit_building_layout_state/state, datum/world_edit_building_room/room)
	if(!istype(state) || !istype(room))
		return
	
	// Calculate center
	var/min_x = null
	var/max_x = null
	var/min_y = null
	var/max_y = null
	var/z_level = null
	
	var/list/perimeter_turfs = list()
	var/list/free_zones = list()
	var/list/door_turfs = list()
	
	for(var/turf/T in room.turfs)
		if(isnull(min_x) || T.x < min_x) min_x = T.x
		if(isnull(max_x) || T.x > max_x) max_x = T.x
		if(isnull(min_y) || T.y < min_y) min_y = T.y
		if(isnull(max_y) || T.y > max_y) max_y = T.y
		if(isnull(z_level)) z_level = T.z
		
		if(state.geometry.door_turfs[T])
			door_turfs += T
			continue
			
		// Check perimeter
		var/is_perimeter = FALSE
		for(var/dir in GLOB.cardinals)
			var/turf/nearby = get_step(T, dir)
			if(state.geometry.wall_lookup[nearby] || state.geometry.door_turfs[nearby])
				is_perimeter = TRUE
				break
				
		if(is_perimeter)
			perimeter_turfs += T
		else if(!state.geometry.reserved_lookup[T])
			free_zones += T
			
	var/center_x = round((min_x + max_x) / 2)
	var/center_y = round((min_y + max_y) / 2)
	room.focus_turf = locate(center_x, center_y, z_level)
	
	// Store in room metadata or state if needed. We can just use state anchors for now.

/datum/world_edit_generation_stage/interiors/proc/generate_room_anchors(datum/world_edit_building_layout_state/state, datum/world_edit_building_room/room)
	if(!istype(state) || !istype(room))
		return
		
	var/room_prefix = "room_[room.id]_"
	
	if(istype(room.focus_turf))
		state.add_anchor("center_anchors", room.focus_turf)
		state.add_anchor(room_prefix + "center", room.focus_turf)
		
	for(var/turf/T in room.turfs)
		if(state.geometry.reserved_lookup[T] || state.geometry.door_turfs[T])
			continue
			
		var/wall_count = 0
		for(var/dir in GLOB.cardinals)
			var/turf/nearby = get_step(T, dir)
			if(state.geometry.wall_lookup[nearby])
				wall_count++
				
		if(wall_count >= 2)
			state.add_anchor("corner_anchors", T)
			state.add_anchor(room_prefix + "corner", T)
		else if(wall_count == 1)
			state.add_anchor("wall_anchors", T)
			state.add_anchor(room_prefix + "wall", T)

/datum/world_edit_generation_stage/interiors/proc/place_room_prefab_groups(datum/world_edit_building_layout_state/state, datum/world_edit_building_room/room, datum/world_edit_generator/building_layout/generator)
	if(!istype(state) || !istype(room))
		return
		
	var/room_purpose = room.role
	var/list/prefab_macros = list()
	
	switch(room_purpose)
		if("storage")
			prefab_macros = list("rack_aisles", "loading_staging")
		if("sleep_privacy", "dorm")
			prefab_macros = list("sleep_nook")
		if("treatment")
			prefab_macros = list("treatment_bay", "medical_storage_wall")
		if("office")
			prefab_macros = list("office_desk_cluster")
		if("sanitation")
			prefab_macros = list("sanitation_combined_chunk")
			
	for(var/macro_id in prefab_macros)
		// We'd ask generator to place this prefab inside the room's anchors if possible
		// Since we don't have direct chunk placing here yet, we simulate semantic credit by relying on the stage_fixtures.dm to do it, OR we do it ourselves.
		// ACTUALLY, Phase 8 says: "Furniture groups (prefab compositions) вместо одиночных объектов."
		// For now, this is a placeholder implementation that fulfills the requested stage skeleton.
		continue
