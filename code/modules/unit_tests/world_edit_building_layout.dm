/datum/unit_test/world_edit_building_layout/proc/get_test_anchor_turf()
	var/min_x = min(13, world.maxx)
	var/min_y = min(13, world.maxy)
	var/max_x = max(min_x, world.maxx - 12)
	var/max_y = max(min_y, world.maxy - 12)
	var/turf/center_turf = locate(clamp(round(world.maxx / 2), min_x, max_x), clamp(round(world.maxy / 2), min_y, max_y), 1)
	if(istype(center_turf))
		return center_turf
	for(var/turf/test_turf in block(locate(min_x, min_y, 1), locate(max_x, max_y, 1)))
		if(istype(test_turf))
			return test_turf
	return null

/datum/unit_test/world_edit_building_layout/proc/prepare_building_test_canvas(turf/anchor_turf, radius = 12)
	TEST_ASSERT_NOTNULL(anchor_turf, "Missing test anchor turf.")
	var/min_x = max(anchor_turf.x - radius, 1)
	var/max_x = min(anchor_turf.x + radius, world.maxx)
	var/min_y = max(anchor_turf.y - radius, 1)
	var/max_y = min(anchor_turf.y + radius, world.maxy)
	for(var/y in min_y to max_y)
		for(var/x in min_x to max_x)
			var/turf/target_turf = locate(x, y, anchor_turf.z)
			if(!istype(target_turf))
				continue
			for(var/obj/target_object as anything in target_turf)
				if(istype(target_object, /obj/effect/landmark))
					continue
				qdel(target_object)
			if(!istype(target_turf, /turf/open))
				target_turf.ChangeTurf(/turf/open/floor/plating)

/datum/unit_test/world_edit_building_layout/Run()
	return

/datum/unit_test/world_edit_building_layout/proc/build_point_shape_contract(turf/anchor_turf)
	var/datum/world_edit_shape_contract/shape_contract = new
	shape_contract.shape_id = WORLD_EDIT_SHAPE_POINT
	shape_contract.shape_label = "Point"
	shape_contract.interaction_kind = "single"
	shape_contract.preview_kind = "shape"
	shape_contract.anchor_turfs = list(anchor_turf)
	shape_contract.metadata = list(
		"anchor_count" = 1,
		"final_turfs" = list(anchor_turf),
	)
	shape_contract.raw_result = list(
		"shape_id" = WORLD_EDIT_SHAPE_POINT,
		"turfs" = list(anchor_turf),
		"metadata" = shape_contract.metadata.Copy(),
	)
	return shape_contract

/datum/unit_test/world_edit_building_layout/proc/build_point_context(datum/world_edit_shape_contract/shape_contract, turf/anchor_turf, direction = NORTH)
	var/list/shape_metadata = istype(shape_contract) ? shape_contract.copy_metadata() : list()
	var/list/anchor_turfs = istype(shape_contract) ? shape_contract.copy_anchor_turfs() : list()
	if(!length(anchor_turfs))
		anchor_turfs += anchor_turf
	return list(
		"mode" = "single",
		"shape" = WORLD_EDIT_SHAPE_POINT,
		"shape_contract" = shape_contract,
		"shape_metadata" = shape_metadata,
		"anchor_turfs" = anchor_turfs,
		"start_turf" = anchor_turf,
		"end_turf" = anchor_turf,
		"shape_origin_turf" = anchor_turf,
		"seed_turf" = anchor_turf,
		"requested_end_turf" = anchor_turf,
		"resolved_end_turf" = anchor_turf,
		"direction" = direction,
	)

/datum/unit_test/world_edit_building_layout/proc/build_living_point_state(list/params)
	var/turf/anchor_turf = get_test_anchor_turf()
	TEST_ASSERT_NOTNULL(anchor_turf, "Building layout test could not resolve an anchor turf.")
	prepare_building_test_canvas(anchor_turf)
	var/datum/world_edit_generator/building_layout/generator = new
	var/datum/world_edit_shape_contract/shape_contract = build_point_shape_contract(anchor_turf)
	var/list/placement_context = build_point_context(shape_contract, anchor_turf)
	var/datum/world_edit_building_request/base_request = generator.build_building_request(islist(params) ? params : list(), shape_contract, placement_context)
	var/datum/world_edit_building_request/candidate_request = generator.build_building_candidate_request(base_request, "RECT", 1)
	return generator.build_building_layout_candidate_state(candidate_request, shape_contract, islist(params) ? params : list(), placement_context)

/datum/unit_test/world_edit_building_layout/proc/build_living_point_plan(list/params, direction = NORTH)
	var/turf/anchor_turf = get_test_anchor_turf()
	TEST_ASSERT_NOTNULL(anchor_turf, "Building layout test could not resolve an anchor turf.")
	prepare_building_test_canvas(anchor_turf)
	var/datum/world_edit_generator/building_layout/generator = new
	var/datum/world_edit_shape_contract/shape_contract = build_point_shape_contract(anchor_turf)
	return generator.build_plan_from_shape_contract(null, shape_contract, islist(params) ? params : list(), build_point_context(shape_contract, anchor_turf, direction))

/datum/unit_test/world_edit_building_layout/proc/get_plan_placement_turf(list/placement)
	if(!islist(placement))
		return null
	var/turf/placement_turf = placement["turf"]
	if(istype(placement_turf))
		return placement_turf
	var/x = round(text2num("[placement["x"]]") || 0)
	var/y = round(text2num("[placement["y"]]") || 0)
	var/z = round(text2num("[placement["z"]]") || 0)
	return locate(x, y, z)

/datum/unit_test/world_edit_building_layout/proc/has_error_containing(datum/world_edit_building_layout_state/state, needle)
	for(var/error_text as anything in state.validation.errors)
		if(findtext("[error_text]", "[needle]"))
			return TRUE
	return FALSE

/datum/unit_test/world_edit_building_layout/proc/assert_living_template_plan_contract(datum/world_edit_plan/plan)
	TEST_ASSERT_NOTNULL(plan, "Living template contract did not return a plan.")
	TEST_ASSERT(!plan.metadata["error"], "Living template contract failed: [plan.metadata["error"]]")
	TEST_ASSERT(round(text2num("[plan.metadata["template_chunk_count"]]") || 0) > 0, "Living layout did not place any template chunks.")
	var/list/reject_counts = plan.metadata["template_reject_reason_counts"]
	var/template_not_found = islist(reject_counts) ? (reject_counts["template_chunk_not_found"] || 0) : 0
	TEST_ASSERT_EQUAL(template_not_found, 0, "Living layout reported missing template chunks.")
	TEST_ASSERT_EQUAL(plan.metadata["mandatory_pattern_failure_count"] || 0, 0, "Living layout left mandatory patterns unsatisfied.")
	TEST_ASSERT_EQUAL(plan.metadata["forbidden_fallback_count"] || 0, 0, "Living layout used forbidden required-cluster fallback.")
	TEST_ASSERT_EQUAL(plan.metadata["fallback_anchor_required_cluster_count"] || 0, 0, "Living layout used required-cluster fallback anchors.")

/datum/unit_test/world_edit_building_layout/proc/living_plan_has_slot(datum/world_edit_plan/plan, slot_id, category_id = null)
	if(!istype(plan))
		return FALSE
	for(var/list/placement as anything in plan.placements)
		if(!islist(placement) || "[placement["kind"]]" != "interior")
			continue
		var/slot = "[placement["requested_slot"] || placement["slot"]]"
		var/category = "[placement["category"]]"
		if(slot != "[slot_id]")
			continue
		if(!isnull(category_id) && category != "[category_id]")
			continue
		return TRUE
	return FALSE

/datum/unit_test/world_edit_building_layout/living_template_resolution_contract/Run()
	var/datum/world_edit_generator/building_layout/generator = new
	TEST_ASSERT_EQUAL(generator.resolve_existing_building_template_chunk_id("bed_niche_chunk"), "bed_niche_chunk", "Direct sleep template chunk did not resolve.")
	TEST_ASSERT_EQUAL(generator.resolve_existing_building_template_chunk_id("micro_bed_chunk"), "bed_niche_chunk", "Micro bed template did not resolve to the living sleep chunk.")
	TEST_ASSERT_EQUAL(generator.resolve_existing_building_template_chunk_id("island_bed_chunk"), "bed_niche_chunk", "Island bed template did not resolve to the living sleep chunk.")
	TEST_ASSERT_EQUAL(generator.resolve_existing_building_template_chunk_id("cabinet_run_chunk"), "cabinet_run_chunk", "Direct storage template chunk did not resolve.")
	TEST_ASSERT_EQUAL(generator.resolve_existing_building_template_chunk_id("micro_cabinet_chunk"), "cabinet_run_chunk", "Micro cabinet template did not resolve to the storage chunk.")
	TEST_ASSERT_EQUAL(generator.resolve_existing_building_template_chunk_id("wall_toilet_chunk"), "sanitation_combined_chunk", "Sanitation wall object did not resolve to the sanitation chunk.")
	TEST_ASSERT_EQUAL(generator.resolve_existing_building_template_chunk_id("missing_living_contract_chunk"), "", "Unknown chunks must not resolve through a generic fallback.")

	var/datum/world_edit_plan/plan = build_living_point_plan(list(
		"archetype_id" = "living",
		"faction_preset" = "colony",
		"building_seed" = 13,
		"detail_budget" = 80,
		"replace_blocked_turfs" = TRUE,
		"respect_blockers" = FALSE,
	))
	assert_living_template_plan_contract(plan)
	TEST_ASSERT(living_plan_has_slot(plan, "bed", "bed"), "Living template contract did not emit a bed.")
	TEST_ASSERT(living_plan_has_slot(plan, "table", "table"), "Living template contract did not emit a table.")
	TEST_ASSERT(living_plan_has_slot(plan, "toilet", "sanitation"), "Living template contract did not emit a toilet.")

/datum/unit_test/world_edit_building_layout/default_living_preview/Run()
	var/datum/world_edit_generator/building_layout/generator = new
	var/list/config = generator.normalize_building_params(list())
	TEST_ASSERT_EQUAL(config["archetype_id"], "living", "Default building layout program should be living.")
	TEST_ASSERT_EQUAL(config["faction_preset"], "colony", "Default building layout shell should be colony.")
	TEST_ASSERT(config["auto_size"], "Default building layout should use auto_size.")

	var/datum/world_edit_plan/plan = build_living_point_plan(list())
	TEST_ASSERT_NOTNULL(plan, "Default living preview did not return a plan.")
	TEST_ASSERT(!plan.metadata["error"], "[plan.metadata["error"]]")
	TEST_ASSERT_EQUAL(plan.metadata["post_emit_validation_error_count"] || 0, 0, "Default living preview should pass post-emit validation.")
	TEST_ASSERT_EQUAL(plan.metadata["reachability_failure_count"] || 0, 0, "Default living preview should have no route-touch failures.")
	assert_living_template_plan_contract(plan)

/datum/unit_test/world_edit_building_layout/direction_matrix/Run()
	for(var/requested_dir as anything in list(NORTH, SOUTH, EAST, WEST))
		var/datum/world_edit_plan/plan = build_living_point_plan(list(
			"archetype_id" = "living",
			"faction_preset" = "colony",
			"building_seed" = 11,
			"detail_budget" = 40,
			"replace_blocked_turfs" = TRUE,
			"respect_blockers" = FALSE,
		), requested_dir)
		TEST_ASSERT_NOTNULL(plan, "Direction [requested_dir] did not create a plan.")
		TEST_ASSERT(!plan.metadata["error"], "Direction [requested_dir] failed: [plan.metadata["error"]]")
		TEST_ASSERT_EQUAL(round(text2num("[plan.metadata["requested_direction"]]") || 0), requested_dir, "Requested direction was not recorded.")
		TEST_ASSERT(GLOB.world_edit_helpers.parse_bool(plan.metadata["direction_honored"]), "Front door did not honor requested direction [requested_dir].")
		TEST_ASSERT_EQUAL(plan.metadata["post_emit_validation_error_count"] || 0, 0, "Direction [requested_dir] failed post-emit validation.")

/datum/unit_test/world_edit_building_layout/wall_fixture_direction_contract/Run()
	var/datum/world_edit_plan/plan = build_living_point_plan(list(
		"archetype_id" = "living",
		"faction_preset" = "colony",
		"building_seed" = 12,
		"detail_budget" = 60,
		"replace_blocked_turfs" = TRUE,
		"respect_blockers" = FALSE,
	))
	TEST_ASSERT_NOTNULL(plan, "Wall fixture contract plan was not created.")
	TEST_ASSERT(!plan.metadata["error"], "Wall fixture contract plan failed: [plan.metadata["error"]]")
	var/list/wall_lookup = list()
	for(var/list/placement as anything in plan.placements)
		if(!islist(placement) || "[placement["kind"]]" != "wall")
			continue
		var/turf/wall_turf = get_plan_placement_turf(placement)
		if(istype(wall_turf))
			wall_lookup[wall_turf] = TRUE
	var/wall_fixture_count = 0
	for(var/list/placement as anything in plan.placements)
		if(!islist(placement) || "[placement["kind"]]" != "interior" || !GLOB.world_edit_helpers.parse_bool(placement["wall_mounted"]))
			continue
		wall_fixture_count++
		var/turf/target_turf = get_plan_placement_turf(placement)
		var/wall_dir = round(text2num("[placement["wall_dir"]]") || 0)
		var/dir_to_use = round(text2num("[placement["dir"]]") || 0)
		var/dir_mode = round(text2num("[placement["dir_mode"]]") || 0)
		TEST_ASSERT(wall_dir in GLOB.cardinals, "Wall fixture [placement["slot"]] has invalid wall_dir.")
		TEST_ASSERT(wall_lookup[get_step(target_turf, wall_dir)], "Wall fixture [placement["slot"]] has no adjacent wall at wall_dir.")
		if(dir_mode == 1)
			TEST_ASSERT_EQUAL(dir_to_use, wall_dir, "Attached-wall fixture [placement["slot"]] does not face the attached wall.")
		if(dir_mode == 2)
			TEST_ASSERT_EQUAL(dir_to_use, turn(wall_dir, 180), "Front-face fixture [placement["slot"]] does not face away from the wall.")
		TEST_ASSERT(length("[placement["dir_source"]]"), "Wall fixture [placement["slot"]] did not record dir_source.")
	TEST_ASSERT(wall_fixture_count > 0, "No wall fixtures were emitted for the direction contract test.")

/datum/unit_test/world_edit_building_layout/living_semantic_object_contract/Run()
	var/datum/world_edit_plan/plan = null
	for(var/seed_value in 13 to 24)
		var/datum/world_edit_plan/candidate_plan = build_living_point_plan(list(
			"archetype_id" = "living",
			"faction_preset" = "colony",
			"building_seed" = seed_value,
			"detail_budget" = 70,
			"replace_blocked_turfs" = TRUE,
			"respect_blockers" = FALSE,
		))
		if(!istype(candidate_plan) || candidate_plan.metadata["error"])
			continue
		var/candidate_bed_seen = FALSE
		var/candidate_table_seen = FALSE
		var/candidate_toilet_seen = FALSE
		for(var/list/candidate_placement as anything in candidate_plan.placements)
			if(!islist(candidate_placement) || "[candidate_placement["kind"]]" != "interior")
				continue
			var/candidate_slot = "[candidate_placement["requested_slot"] || candidate_placement["slot"]]"
			var/candidate_category = "[candidate_placement["category"]]"
			if(candidate_slot == "bed")
				candidate_bed_seen = TRUE
			if(candidate_slot == "table" && candidate_category == "table")
				candidate_table_seen = TRUE
			if(candidate_slot == "toilet" || candidate_category == "sanitation")
				candidate_toilet_seen = TRUE
		if(candidate_bed_seen && candidate_table_seen && candidate_toilet_seen)
			plan = candidate_plan
			break
	TEST_ASSERT_NOTNULL(plan, "Living semantic object contract plan was not created.")
	TEST_ASSERT(!plan.metadata["error"], "Living semantic object contract failed: [plan.metadata["error"]]")
	var/bed_seen = FALSE
	var/table_seen = FALSE
	var/toilet_seen = FALSE
	for(var/list/placement as anything in plan.placements)
		if(!islist(placement) || "[placement["kind"]]" != "interior")
			continue
		var/slot = "[placement["requested_slot"] || placement["slot"]]"
		var/category = "[placement["category"]]"
		var/zone_id = "[placement["zone_id"]]"
		var/requirement_id = "[placement["semantic_requirement_id"] || placement["requirement_id"]]"
		if(slot == "bed")
			bed_seen = TRUE
			TEST_ASSERT_EQUAL(zone_id, "sleep_privacy", "Bed was emitted outside sleep_privacy.")
		if(slot == "cabinet" && findtext(requirement_id, "sleep"))
			TEST_ASSERT_EQUAL(zone_id, "sleep_privacy", "Sleep cabinet was emitted outside sleep_privacy.")
		if(slot == "toilet" || category == "sanitation")
			toilet_seen = TRUE
			TEST_ASSERT_EQUAL(zone_id, "sanitation", "Sanitation fixture was emitted outside sanitation.")
		if(slot == "sink" && findtext(requirement_id, "sanitation"))
			TEST_ASSERT_EQUAL(zone_id, "sanitation", "Sanitation sink was emitted outside sanitation.")
		if(slot == "table" && category == "table")
			table_seen = TRUE
			TEST_ASSERT_EQUAL(zone_id, "common", "Living table was emitted outside common.")
		if(slot == "chair" && category == "chair" && findtext(requirement_id, "common"))
			TEST_ASSERT_EQUAL(zone_id, "common", "Living chair was emitted outside common.")
	TEST_ASSERT(bed_seen, "Living layout did not emit a bed.")
	TEST_ASSERT(table_seen, "Living layout did not emit a common table.")
	TEST_ASSERT(toilet_seen, "Living layout did not emit a sanitation fixture.")

/datum/unit_test/world_edit_building_layout/full_layout_no_required_fallback_credit/Run()
	var/datum/world_edit_plan/plan = build_living_point_plan(list(
		"archetype_id" = "living",
		"faction_preset" = "colony",
		"building_seed" = 14,
		"detail_budget" = 70,
		"replace_blocked_turfs" = TRUE,
		"respect_blockers" = FALSE,
	))
	TEST_ASSERT_NOTNULL(plan, "Full layout fallback-credit contract plan was not created.")
	TEST_ASSERT(!plan.metadata["error"], "Full layout fallback-credit contract failed: [plan.metadata["error"]]")
	var/degrade_level = "[plan.metadata["size_degrade_level"]]"
	if(!length(degrade_level))
		degrade_level = "none"
	TEST_ASSERT_EQUAL(degrade_level, "none", "Full layout unexpectedly degraded.")
	TEST_ASSERT_EQUAL(plan.metadata["fallback_anchor_required_cluster_count"] || 0, 0, "Full layout used required-cluster fallback anchors.")
	TEST_ASSERT_EQUAL(plan.metadata["raw_category_credit_count"] || 0, 0, "Full layout used raw category semantic credit.")
	TEST_ASSERT_EQUAL(plan.metadata["semantic_credit_without_emitted_slots_count"] || 0, 0, "Full layout credited semantic slots without emitted objects.")

/datum/unit_test/world_edit_building_layout/living_sanitation_connected/Run()
	var/datum/world_edit_building_layout_state/state = build_living_point_state(list(
		"archetype_id" = "living",
		"faction_preset" = "colony",
		"building_seed" = 1,
	))
	TEST_ASSERT_NOTNULL(state, "Living layout state did not build.")
	TEST_ASSERT(!state.has_errors(), length(state.validation.errors) ? state.validation.errors[1] : "Living layout state has errors.")
	TEST_ASSERT(length(state.get_zone_turfs("sanitation")) >= 2, "Sanitation zone missing or too small.")
	var/datum/world_edit_generator/building_layout/generator = new
	TEST_ASSERT(generator.building_zone_touches_circulation(state, "sanitation"), "Sanitation is not connected to circulation.")

/datum/unit_test/world_edit_building_layout/sealed_sanitation_rejected/Run()
	var/datum/world_edit_generator/building_layout/generator = new
	var/list/config = generator.normalize_building_params(list("archetype_id" = "living", "half_width" = 6, "half_depth" = 6))
	var/datum/world_edit_building_request/request = new
	request.config = config
	request.archetype = generator.get_building_archetype("living")
	var/datum/world_edit_building_layout_state/state = new
	state.config = config
	state.request = request
	state.archetype = request.archetype
	state.semantic_plan = request.archetype.build_semantic_plan(request)
	var/turf/anchor_turf = get_test_anchor_turf()
	TEST_ASSERT_NOTNULL(anchor_turf, "Sealed sanitation test could not resolve anchor turf.")
	prepare_building_test_canvas(anchor_turf, 4)
	var/turf/other_turf = get_step(anchor_turf, EAST)
	TEST_ASSERT_NOTNULL(other_turf, "Sealed sanitation test could not resolve second turf.")
	state.geometry.floor_turfs += anchor_turf
	state.geometry.floor_turfs += other_turf
	state.geometry.floor_lookup[anchor_turf] = TRUE
	state.geometry.floor_lookup[other_turf] = TRUE
	state.add_zone(anchor_turf, "sanitation")
	state.add_zone(other_turf, "sanitation")

	generator.validate_building_route_touch(state)
	TEST_ASSERT(has_error_containing(state, "Required zone 'sanitation' is not connected"), "Validator should reject sealed sanitation.")

/datum/unit_test/world_edit_building_layout/explicit_small_size_locked/Run()
	var/datum/world_edit_plan/plan = build_living_point_plan(list(
		"archetype_id" = "living",
		"faction_preset" = "colony",
		"auto_size" = FALSE,
		"half_width" = 2,
		"half_depth" = 2,
		"detail_budget" = 0,
		"window_density" = 0,
		"replace_blocked_turfs" = TRUE,
		"respect_blockers" = FALSE,
	))
	TEST_ASSERT_NOTNULL(plan, "Small explicit building plan was not created.")
	TEST_ASSERT(!plan.metadata["error"], "Small explicit building failed: [plan.metadata["error"]]")
	TEST_ASSERT_EQUAL(round(text2num("[plan.metadata["half_width"]]") || 0), 2, "Explicit half_width changed.")
	TEST_ASSERT_EQUAL(round(text2num("[plan.metadata["half_depth"]]") || 0), 2, "Explicit half_depth changed.")
	TEST_ASSERT(!GLOB.world_edit_helpers.parse_bool(plan.metadata["size_auto_adjusted"]), "Explicit size was auto-adjusted.")
	TEST_ASSERT("[plan.metadata["size_degrade_level"]]" in list("compact", "micro"), "Small explicit building did not report compact/micro degrade.")
	TEST_ASSERT(GLOB.world_edit_helpers.parse_bool(plan.metadata["program_shedding"]), "Small explicit building did not enable program shedding.")
	TEST_ASSERT(GLOB.world_edit_helpers.parse_bool(plan.metadata["compact_program"]), "Small explicit building did not build a compact semantic program.")
	TEST_ASSERT(length(plan.placements) > 0, "Small explicit building emitted no placements.")

/datum/unit_test/world_edit_building_layout/micro_size_emits_plan/Run()
	var/datum/world_edit_plan/plan = build_living_point_plan(list(
		"archetype_id" = "living",
		"faction_preset" = "colony",
		"auto_size" = FALSE,
		"half_width" = 1,
		"half_depth" = 1,
		"detail_budget" = 0,
		"window_density" = 0,
		"replace_blocked_turfs" = TRUE,
		"respect_blockers" = FALSE,
	))
	TEST_ASSERT_NOTNULL(plan, "Micro building plan was not created.")
	TEST_ASSERT(!plan.metadata["error"], "Micro building failed: [plan.metadata["error"]]")
	TEST_ASSERT(length(plan.placements) > 0, "Micro building emitted no placements.")
	TEST_ASSERT(GLOB.world_edit_helpers.parse_bool(plan.metadata["micro_layout"]) || "[plan.metadata["size_degrade_level"]]" == "micro", "Micro metadata was not set.")
	TEST_ASSERT(GLOB.world_edit_helpers.parse_bool(plan.metadata["program_shedding"]), "Micro building did not enable program shedding.")
	TEST_ASSERT(GLOB.world_edit_helpers.parse_bool(plan.metadata["compact_program"]), "Micro building did not build a compact semantic program.")

/datum/unit_test/world_edit_building_layout/request_key_shape_params/Run()
	var/datum/world_edit_generator/building_layout/generator = new
	var/key_a = generator.build_building_runtime_request_key(list(
		"auto_size" = FALSE,
		"half_width" = 4,
		"half_depth" = 4,
		"shape_radius" = 4,
	))
	var/key_b = generator.build_building_runtime_request_key(list(
		"auto_size" = FALSE,
		"half_width" = 4,
		"half_depth" = 4,
		"shape_radius" = 5,
	))
	TEST_ASSERT(key_a != key_b, "Building runtime request key should change when shape params change.")

/datum/unit_test/world_edit_building_layout/locked_unsupported_shape/Run()
	var/datum/world_edit_generator/building_layout/generator = new
	var/turf/anchor_turf = get_test_anchor_turf()
	TEST_ASSERT_NOTNULL(anchor_turf, "Advertised shape test could not resolve an anchor turf.")
	prepare_building_test_canvas(anchor_turf, 16)
	for(var/shape_id as anything in generator.get_supported_placement_shapes())
		var/list/shape_params = generator.build_building_quality_shape_params(shape_id, 12345, 4, 4)
		var/list/shape_context = generator.build_building_quality_shape_context(anchor_turf, shape_id, shape_params)
		TEST_ASSERT(islist(shape_context), "Shape context was not created for [shape_id].")
		var/datum/world_edit_shape_contract/shape_contract = shape_context["shape_contract"]
		var/list/placement_context = shape_context["placement_context"]
		var/list/params = list(
			"archetype_id" = "living",
			"faction_preset" = "colony",
			"auto_size" = FALSE,
			"half_width" = 4,
			"half_depth" = 4,
			"detail_budget" = 20,
			"replace_blocked_turfs" = TRUE,
			"respect_blockers" = FALSE,
		)
		for(var/shape_param as anything in shape_params)
			params[shape_param] = shape_params[shape_param]
		var/datum/world_edit_plan/plan = generator.build_plan_from_shape_contract(null, shape_contract, params, placement_context)
		TEST_ASSERT_NOTNULL(plan, "Plan was null for shape [shape_id].")
		TEST_ASSERT(!plan.metadata["error"], "Advertised shape [shape_id] failed: [plan.metadata["error"]]")
