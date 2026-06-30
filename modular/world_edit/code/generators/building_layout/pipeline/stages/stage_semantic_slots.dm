/datum/world_edit_generation_stage/semantic_slots
	id = "semantic_slots"

/datum/world_edit_generation_stage/semantic_slots/execute(datum/world_edit_generation_context/context)
	var/datum/world_edit_generator/building_layout/generator = context.generator
	generator.reserve_building_immediate_door_cones(context.state)
	generator.run_building_semantic_slot_preflight(context.state)
	context.state.add_stage_report("semantic_slots", context.state.validation.semantic_slot_shortage_count > 0 || context.state.validation.semantic_slot_reservation_conflict_count > 0 ? "failed" : "ok", null, list(
		"semantic_slot_capacity_count" = context.state.validation.semantic_slot_capacity_count,
		"semantic_slot_shortage_count" = context.state.validation.semantic_slot_shortage_count,
		"semantic_slot_reservation_conflict_count" = context.state.validation.semantic_slot_reservation_conflict_count,
	))
	return TRUE
