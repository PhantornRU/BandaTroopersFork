/datum/world_edit_generation_stage/validation
	id = "validation"

/datum/world_edit_generation_stage/validation/execute(datum/world_edit_generation_context/context)
	var/datum/world_edit_generator/building_layout/generator = context.generator
	
	// Phase 6: Graph-level connectivity check (Flood-fill)
	if(istype(context.state.geometry.room_graph) && length(context.state.geometry.room_graph.nodes))
		var/list/datum/world_edit_room_node/nodes = context.state.geometry.room_graph.nodes
		var/list/connected = list()
		var/list/queue = list(nodes[1])
		connected[nodes[1]] = TRUE
		var/idx = 1
		while(idx <= length(queue))
			var/datum/world_edit_room_node/curr = queue[idx++]
			for(var/datum/world_edit_room_edge/edge as anything in curr.connections)
				var/datum/world_edit_room_node/neighbor = edge.get_other(curr)
				if(neighbor && !connected[neighbor])
					connected[neighbor] = TRUE
					queue += neighbor
		
		if(length(connected) < length(nodes))
			context.state.add_error("Room graph topology is broken: [length(nodes) - length(connected)] rooms are unreachable.")

	generator.validate_and_repair_building_layout_state(context.state)
	context.state.fixtures.pattern_credit_hash = generator.build_building_assoc_hash(context.state.fixtures.semantic_requirement_counts)
	context.state.add_stage_report("validation", context.has_errors() ? "failed" : "ok", context.has_errors() ? generator.format_building_messages(context.state.validation.errors) : null, list(
		"error_count" = length(context.state.validation.errors),
		"forbidden_fallback_count" = context.state.validation.forbidden_fallback_count,
		"pattern_credit_hash" = context.state.fixtures.pattern_credit_hash,
	))
	return TRUE
