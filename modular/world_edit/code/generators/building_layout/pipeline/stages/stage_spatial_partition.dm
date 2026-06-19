/datum/world_edit_generation_stage/spatial_partition
	id = "spatial_partition"

/datum/world_edit_generation_stage/spatial_partition/execute(datum/world_edit_generation_context/context)
	var/datum/world_edit_building_layout_state/state = context.state

	var/bounds = state.geometry.bounds
	if(!islist(bounds))
		context.state.add_error("No bounds available for BSP spatial partitioning.")
		return FALSE

	var/min_x = bounds["min_x"]
	var/min_y = bounds["min_y"]
	var/width = bounds["width"]
	var/height = bounds["height"]
	
	state.geometry.bsp_root = new /datum/world_edit_bsp_node(min_x, min_y, width, height, 5) // min_size 5 for a reasonable room
	
	// Split based on PRNG
	var/datum/world_edit_building_prng/prng = context.request.geometry_rng
	
	var/list/queue = list(state.geometry.bsp_root)
	var/index = 1
	var/split_count = 0
	
	// Target splits based on node count
	var/target_leaves = length(state.geometry.room_graph.nodes)
	
	while(index <= length(queue) && length(state.geometry.bsp_root.get_leaves()) < target_leaves && split_count < 20)
		var/datum/world_edit_bsp_node/node = queue[index++]
		if(node.split(prng))
			queue += node.left
			queue += node.right
			split_count++

	var/list/leaves = state.geometry.bsp_root.get_leaves()
	
	// Assign rooms to BSP leaves
	var/leaf_index = 1
	for(var/datum/world_edit_room_node/room_node as anything in state.geometry.room_graph.nodes)
		if(leaf_index <= length(leaves))
			var/datum/world_edit_bsp_node/leaf = leaves[leaf_index++]
			leaf.assigned_room = room_node
			room_node.x = leaf.x
			room_node.y = leaf.y
			room_node.width = leaf.width
			room_node.height = leaf.height
			
			// Compute turfs for this room based on footprint intersection
			var/z_level = bounds["z"]
			for(var/y in leaf.y to leaf.y + leaf.height - 1)
				for(var/x in leaf.x to leaf.x + leaf.width - 1)
					var/turf/T = locate(x, y, z_level)
					if(state.geometry.footprint_lookup[T])
						room_node.turfs += T

	context.state.add_stage_report("spatial_partition", "ok", null, list(
		"splits" = split_count,
		"leaves" = length(leaves)
	))
	
	return TRUE
