/datum/world_edit_generation_stage/fixtures
	id = "fixtures"

/datum/world_edit_generation_stage/fixtures/execute(datum/world_edit_generation_context/context)
	var/datum/world_edit_generator/building_layout/generator = context.generator
	if(context.state.fixtures.semantic_interiors_emitted)
		context.state.fixtures.pattern_credit_hash = generator.build_building_assoc_hash(context.state.fixtures.semantic_requirement_counts)
		context.state.add_stage_report("mandatory_patterns", "ok", null, list(
			"semantic_interiors_owned" = TRUE,
			"semantic_interiors_scene_count" = context.state.fixtures.semantic_interiors_scene_count,
			"semantic_requirement_count" = length(context.state.fixtures.semantic_requirement_counts),
			"pattern_credit_hash" = context.state.fixtures.pattern_credit_hash,
		))
		return TRUE
	generator.place_building_fixtures(context.state)
	context.state.fixtures.pattern_credit_hash = generator.build_building_assoc_hash(context.state.fixtures.semantic_requirement_counts)
	context.state.add_stage_report("mandatory_patterns", context.state.validation.signature_failure_count > 0 ? "failed" : "ok", null, list(
		"major_fixture_count" = context.state.fixtures.major_fixture_count,
		"semantic_requirement_count" = length(context.state.fixtures.semantic_requirement_counts),
		"pattern_credit_hash" = context.state.fixtures.pattern_credit_hash,
	))
	return TRUE
