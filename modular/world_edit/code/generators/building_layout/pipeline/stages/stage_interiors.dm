/datum/world_edit_generation_stage/interiors
	id = "interiors"

/datum/world_edit_generation_stage/interiors/execute(datum/world_edit_generation_context/context)
	var/datum/world_edit_generator/building_layout/generator = context.generator
	generator.run_building_semantic_interiors(context.state)
	return TRUE
