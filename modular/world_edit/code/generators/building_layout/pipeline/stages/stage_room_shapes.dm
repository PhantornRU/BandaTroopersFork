/datum/world_edit_generation_stage/room_shapes
	id = "room_shapes"

/datum/world_edit_generation_stage/room_shapes/execute(datum/world_edit_generation_context/context)
	var/datum/world_edit_building_layout_state/state = context.state

	var/datum/world_edit_building_prng/prng = context.request.geometry_rng
	var/deformations = 0

	for(var/datum/world_edit_room_node/room_node as anything in state.geometry.room_graph.nodes)
		if(room_node.width >= 6 && room_node.height >= 6)
			// Shape Grammar: apply one or more deformations based on room type / size
			// 1. Cut corner
			if(prng.chance(40))
				deformations += cut_corner(room_node, prng, state)
			
			// 2. Add alcove / niche (by removing an edge block)
			if(prng.chance(30))
				deformations += carve_alcove(room_node, prng, state)
				
	context.state.add_stage_report("room_shapes", "ok", null, list("deformations" = deformations))
	return TRUE

/datum/world_edit_generation_stage/room_shapes/proc/cut_corner(datum/world_edit_room_node/room_node, datum/world_edit_building_prng/prng, datum/world_edit_building_layout_state/state)
	var/cut_size_x = prng.next_between(2, 3)
	var/cut_size_y = prng.next_between(2, 3)
	var/corner_x = prng.chance(50) ? room_node.x : room_node.x + room_node.width - cut_size_x
	var/corner_y = prng.chance(50) ? room_node.y : room_node.y + room_node.height - cut_size_y
	
	var/list/cut_turfs = list()
	var/z_level = state.geometry.bounds["z"]
	for(var/cx in corner_x to corner_x + cut_size_x - 1)
		for(var/cy in corner_y to corner_y + cut_size_y - 1)
			var/turf/T = locate(cx, cy, z_level)
			if(T in room_node.turfs)
				cut_turfs += T
	
	if(length(cut_turfs))
		room_node.turfs -= cut_turfs
		return 1
	return 0

/datum/world_edit_generation_stage/room_shapes/proc/carve_alcove(datum/world_edit_room_node/room_node, datum/world_edit_building_prng/prng, datum/world_edit_building_layout_state/state)
	var/alcove_depth = prng.next_between(1, 2)
	var/alcove_width = prng.next_between(2, 4)
	
	var/is_vertical = prng.chance(50)
	var/ax
	var/ay
	var/aw
	var/ah
	
	if(is_vertical)
		// Carve from left or right edge
		aw = alcove_depth
		ah = alcove_width
		ax = prng.chance(50) ? room_node.x : room_node.x + room_node.width - aw
		// ensure we don't pick an edge that goes out of bounds by checking height
		if(room_node.height <= ah + 2)
			return 0
		ay = room_node.y + prng.next_between(1, room_node.height - ah - 1) // strictly inside edge
	else
		// Carve from top or bottom edge
		aw = alcove_width
		ah = alcove_depth
		if(room_node.width <= aw + 2)
			return 0
		ax = room_node.x + prng.next_between(1, room_node.width - aw - 1)
		ay = prng.chance(50) ? room_node.y : room_node.y + room_node.height - ah
	
	var/list/cut_turfs = list()
	var/z_level = state.geometry.bounds["z"]
	for(var/cx in ax to ax + aw - 1)
		for(var/cy in ay to ay + ah - 1)
			var/turf/T = locate(cx, cy, z_level)
			if(T in room_node.turfs)
				cut_turfs += T
				
	if(length(cut_turfs))
		room_node.turfs -= cut_turfs
		return 1
	return 0
