/datum/world_edit_generation_stage/macros
	id = "macros"

/datum/world_edit_generation_stage/macros/execute(datum/world_edit_generation_context/context)
	var/datum/world_edit_generator/building_layout/generator = context.generator
	generator.apply_building_layout_macro_overlays(context.state)
	context.state.add_stage_report("macros", "ok", null, list("layout_macro_count" = length(context.state.fixtures.layout_macros)))
	return TRUE

/datum/world_edit_generation_stage/scoring
	id = "scoring"

/datum/world_edit_generation_stage/scoring/execute(datum/world_edit_generation_context/context)
	var/datum/world_edit_generator/building_layout/generator = context.generator
	generator.calculate_building_style_metrics(context.state)
	context.state.validation.layout_candidate_score = generator.score_building_layout_candidate(context.state)
	context.state.clear_validation_cache()
	var/object_placement_hash = generator.build_building_object_placement_hash(context.state.fixtures.object_placements)
	var/door_hash = generator.build_building_door_hash(context.state)
	var/room_ownership_hash = generator.build_building_room_ownership_hash(context.state)
	context.state.geometry.layout_hash = generator.build_building_hash_from_strings(list(
		"footprint=[context.state.geometry.footprint_hash]",
		"rooms=[context.state.geometry.room_graph_hash]",
		"ownership=[room_ownership_hash]",
		"route=[context.state.geometry.route_hash]",
		"walls=[context.state.geometry.wall_hash]",
		"doors=[door_hash]",
		"patterns=[context.state.fixtures.pattern_credit_hash]",
		"objects=[object_placement_hash]",
	))
	context.state.validation.determinism_check_hash = context.state.geometry.layout_hash
	return TRUE
