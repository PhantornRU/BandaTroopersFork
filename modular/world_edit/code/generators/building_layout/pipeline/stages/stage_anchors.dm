/datum/world_edit_generation_stage/anchors
	id = "anchors"

/datum/world_edit_generation_stage/anchors/execute(datum/world_edit_generation_context/context)
	var/datum/world_edit_generator/building_layout/generator = context.generator
	generator.extract_building_anchors(context.state)
	context.state.validation.anchor_report = generator.build_building_anchor_type_counts(context.state)
	context.state.add_stage_report("anchors", "ok", null, list("anchor_type_count" = length(context.state.validation.anchor_report)))
	return TRUE
