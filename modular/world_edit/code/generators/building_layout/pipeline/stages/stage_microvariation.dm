/datum/world_edit_generation_stage/microvariation
	id = "microvariation"

/datum/world_edit_generation_stage/microvariation/execute(datum/world_edit_generation_context/context)
	var/datum/world_edit_generator/building_layout/generator = context.generator
	generator.apply_building_microvariation_if_available(context.state)
	context.state.add_stage_report("microvariation", "ok", null, list("microvariation_count" = context.state.validation.microvariation_count))
	return TRUE
