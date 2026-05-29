/datum/world_edit_generation_stage/layout_graph
	id = "layout_graph"

/datum/world_edit_generation_stage/layout_graph/execute(datum/world_edit_generation_context/context)
	var/datum/world_edit_building_layout_state/state = context.state
	
	// Create graph
	state.geometry.room_graph = new /datum/world_edit_room_graph()
	
	// If fallback mode is enabled, we just leave it empty and let legacy handle it
	if(state.config["room_first_layout"])
		return TRUE

	// TODO: implement actual layout generation using archetypes
	// For now, create a basic root node depending on the archetype
	var/datum/world_edit_building_archetype/archetype = state.archetype
	if(archetype)
		// We'll generate a dummy graph just for structure.
		// For proper graph, we need to read zone_specs from archetype.
		var/datum/world_edit_room_node/hub = state.geometry.room_graph.add_node("hub", "corridor", "medium")
		state.geometry.room_graph.root_node = hub
		
		for(var/datum/world_edit_building_zone_spec/zone_spec as anything in archetype.zone_specs)
			if(zone_spec.id == "hub") continue // already created
			
			var/datum/world_edit_room_node/node = state.geometry.room_graph.add_node(zone_spec.id, zone_spec.role, "medium")
			node.tags += zone_spec.anchor_tags
			state.geometry.room_graph.add_edge(hub, node, "door")

	context.state.add_stage_report("layout_graph", "ok", null, list(
		"nodes" = length(state.geometry.room_graph.nodes),
		"edges" = length(state.geometry.room_graph.edges)
	))
	
	return TRUE
