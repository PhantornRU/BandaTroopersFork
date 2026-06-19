/datum/world_edit_generation_stage/layout_graph
	id = "layout_graph"

/datum/world_edit_generation_stage/layout_graph/execute(datum/world_edit_generation_context/context)
	var/datum/world_edit_building_layout_state/state = context.state

	state.geometry.room_graph = new /datum/world_edit_room_graph()
	var/datum/world_edit_room_node/hub = null
	var/hub_zone_id = "[state.semantic_plan?.hub_zone_id || state.semantic_plan?.primary_zone_id || "hub"]"
	for(var/datum/world_edit_building_zone_spec/zone_spec as anything in state.semantic_plan?.zone_specs)
		if(!istype(zone_spec))
			continue
		var/datum/world_edit_room_node/node = state.geometry.room_graph.add_node(zone_spec.id, zone_spec.id, "medium")
		node.purpose = zone_spec.role
		node.tags += zone_spec.anchor_tags
		if(zone_spec.id == hub_zone_id || (!istype(hub) && zone_spec.role in list("hub", "route")))
			hub = node
	if(!istype(hub) && length(state.geometry.room_graph.nodes))
		hub = state.geometry.room_graph.nodes[1]
	state.geometry.room_graph.root_node = hub
	for(var/datum/world_edit_room_node/node as anything in state.geometry.room_graph.nodes)
		if(!istype(node) || node == hub || !istype(hub))
			continue
		state.geometry.room_graph.add_edge(hub, node, "route")

	context.state.add_stage_report("layout_graph", "ok", null, list(
		"nodes" = length(state.geometry.room_graph.nodes),
		"edges" = length(state.geometry.room_graph.edges)
	))
	
	return TRUE
