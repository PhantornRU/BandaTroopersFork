/datum/world_edit_generation_stage/interiors
	id = "interiors"

/datum/world_edit_generation_stage/interiors/execute(datum/world_edit_generation_context/context)
	var/datum/world_edit_generator/building_layout/generator = context.generator
	var/datum/world_edit_building_layout_state/state = context.state
	if(!istype(generator) || !istype(state))
		return FALSE
	generator.reserve_building_immediate_door_cones(state)
	var/ok = generator.run_building_semantic_interiors(state)
	state.add_stage_report("interiors", ok ? "ok" : "failed", ok ? null : "semantic interiors failed", list(
		"structured_scene_emitted" = state.fixtures.structured_scene_emitted ? TRUE : FALSE,
		"structured_scene_owner" = state.fixtures.structured_scene_owner,
		"structured_scene_count" = state.fixtures.structured_scene_count,
		"structured_primary_scene_count" = state.fixtures.structured_primary_scene_count,
		"semantic_scene_required_missing_count" = state.validation.semantic_scene_required_missing_count,
		"semantic_room_primary_scene_missing_count" = state.validation.semantic_room_primary_scene_missing_count,
	))
	return ok
