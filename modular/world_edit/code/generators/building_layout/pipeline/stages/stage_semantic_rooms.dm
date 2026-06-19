/datum/world_edit_generation_stage/semantic_rooms
	id = "semantic_rooms"

/datum/world_edit_generation_stage/semantic_rooms/execute(datum/world_edit_generation_context/context)
	var/datum/world_edit_building_layout_state/state = context.state
	if(!istype(state))
		return FALSE

	if(length(state.geometry.solved_rooms))
		context.state.add_stage_report("semantic_rooms", "ok", null, list(
			"nodes_processed" = length(state.geometry.solved_rooms),
			"source" = "solved_rooms"
		))
		return TRUE

	if(!istype(state.geometry.room_graph))
		context.state.add_stage_report("semantic_rooms", "ok", null, list(
			"nodes_processed" = 0,
			"note" = "room_graph absent; nothing to annotate"
		))
		return TRUE

	var/datum/world_edit_building_archetype/archetype = state.archetype
	var/default_faction = archetype ? archetype.faction : "neutral"
	var/default_danger = archetype ? archetype.danger : 0

	for(var/datum/world_edit_room_node/node as anything in state.geometry.room_graph.nodes)
		var/datum/world_edit_building_zone_spec/zone_spec = state.semantic_plan?.get_zone_spec(node.room_type)
		if(zone_spec)
			node.purpose = zone_spec.role
			node.faction = length(zone_spec.faction) ? zone_spec.faction : default_faction
			node.danger = zone_spec.danger > 0 ? zone_spec.danger : default_danger
			node.clutter_density = zone_spec.clutter_density > 0 ? zone_spec.clutter_density : 0
		else
			// Fallback for corridors/unspecified zones
			if(node.room_type == "corridor" || node.room_type == "hub")
				node.purpose = "circulation"
			else
				node.purpose = "support"
			node.faction = default_faction
			node.danger = default_danger
			node.clutter_density = 0

	context.state.add_stage_report("semantic_rooms", "ok", null, list(
		"nodes_processed" = length(state.geometry.room_graph.nodes)
	))
	return TRUE
