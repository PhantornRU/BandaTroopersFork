/datum/world_edit_generation_stage/infrastructure
	id = "infrastructure"

/datum/world_edit_generation_stage/infrastructure/execute(datum/world_edit_generation_context/context)
	var/datum/world_edit_generator/building_layout/generator = context.generator
	generator.place_building_infrastructure(context.state)
	context.state.validation.infrastructure_report = list(
		"infrastructure_count" = context.state.fixtures.infrastructure_count,
		"placed_requirement_counts" = context.state.fixtures.placed_requirement_counts.Copy(),
	)
	context.state.add_stage_report("infrastructure", "ok", null, context.state.validation.infrastructure_report)
	return TRUE
