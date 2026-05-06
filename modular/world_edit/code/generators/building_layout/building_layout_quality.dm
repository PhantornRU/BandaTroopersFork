/datum/world_edit_generator/building_layout/proc/run_building_quality_batch(turf/anchor_turf, list/program_ids = null, list/style_ids = null, seed_start = 1, seed_count = 8, half_width = 4, half_depth = 4)
	var/list/result = list(
		"sample_count" = 0,
		"pass_count" = 0,
		"fail_count" = 0,
		"samples" = list(),
	)
	if(!istype(anchor_turf))
		result["error"] = "Quality batch requires an anchor turf."
		return result
	if(!islist(program_ids) || !length(program_ids))
		program_ids = get_building_archetype_ids()
	if(!islist(style_ids) || !length(style_ids))
		style_ids = get_building_faction_options()
	seed_count = clamp(round(text2num("[seed_count]") || 8), 1, 50)
	var/list/placement_context = list(
		"mode" = "single",
		"shape" = WORLD_EDIT_SHAPE_POINT,
		"anchor_turfs" = list(anchor_turf),
		"start_turf" = anchor_turf,
		"end_turf" = anchor_turf,
		"shape_origin_turf" = anchor_turf,
		"seed_turf" = anchor_turf,
		"requested_end_turf" = anchor_turf,
		"resolved_end_turf" = anchor_turf,
		"direction" = NORTH,
	)
	var/datum/world_edit_shape_contract/shape_contract = build_shape_contract_from_placement_context(WORLD_EDIT_SHAPE_POINT, list(anchor_turf), placement_context)
	for(var/program_id as anything in program_ids)
		for(var/style_id as anything in style_ids)
			for(var/seed_offset in 0 to seed_count - 1)
				var/seed_value = seed_start + seed_offset
				var/list/params = list(
					"archetype_id" = program_id,
					"faction_preset" = style_id,
					"building_seed" = seed_value,
					"half_width" = half_width,
					"half_depth" = half_depth,
					"detail_budget" = 100,
					"window_density" = 60,
					"back_exit" = TRUE,
				)
				var/datum/world_edit_plan/plan = build_plan_from_shape_contract(null, shape_contract, params, placement_context)
				var/list/sample = build_building_quality_sample(program_id, style_id, seed_value, plan)
				result["samples"] += list(sample)
				result["sample_count"] = result["sample_count"] + 1
				if(sample["passed"])
					result["pass_count"] = result["pass_count"] + 1
				else
					result["fail_count"] = result["fail_count"] + 1
	return result

/datum/world_edit_generator/building_layout/proc/build_building_quality_sample(program_id, style_id, seed_value, datum/world_edit_plan/plan)
	var/list/metadata = islist(plan?.metadata) ? plan.metadata : list()
	var/passed = istype(plan) && !metadata["error"] && GLOB.world_edit_helpers.parse_bool(metadata["program_signature_ok"])
	var/empty_floor_ratio = round(text2num("[metadata["empty_floor_ratio"]]") || 0)
	var/template_chunk_count = round(text2num("[metadata["template_chunk_count"]]") || 0)
	var/infrastructure_count = round(text2num("[metadata["infrastructure_count"]]") || 0)
	if(empty_floor_ratio > WORLD_EDIT_BUILDING_DEFAULT_MAX_EMPTY_FLOOR_RATIO)
		passed = FALSE
	if(template_chunk_count <= 0)
		passed = FALSE
	if(infrastructure_count < 4)
		passed = FALSE
	return list(
		"program" = "[program_id]",
		"style" = "[style_id]",
		"seed" = seed_value,
		"passed" = passed ? TRUE : FALSE,
		"error" = metadata["error"],
		"signature_score" = metadata["signature_score"],
		"empty_floor_ratio" = empty_floor_ratio,
		"template_chunk_count" = template_chunk_count,
		"infrastructure_count" = infrastructure_count,
		"fixture_count" = metadata["fixture_count"],
		"divider_plan_count" = metadata["divider_plan_count"],
		"nested_room_count" = metadata["nested_room_count"],
		"degraded_region_fallback_count" = metadata["degraded_region_fallback_count"],
	)
