/datum/world_edit_generation_stage/facade
	id = "facade"

/datum/world_edit_generation_stage/facade/execute(datum/world_edit_generation_context/context)
	var/datum/world_edit_generator/building_layout/generator = context.generator
	generator.apply_building_facade_rules(context.state)
	return TRUE
