/datum/unit_test/world_edit_corner_slots/proc/get_world_edit_test_center_turf()
	var/center_x = round((run_loc_floor_bottom_left.x + run_loc_floor_top_right.x) / 2)
	var/center_y = round((run_loc_floor_bottom_left.y + run_loc_floor_top_right.y) / 2)
	return locate(center_x, center_y, run_loc_floor_bottom_left.z)

/datum/unit_test/world_edit_corner_slots/proc/build_slot_lookup(list/placements)
	var/list/slot_lookup = list()
	for(var/list/placement as anything in placements)
		var/turf/target_turf = placement["turf"]
		var/dir_to_use = placement["dir"]
		var/slot_key = GLOB.world_edit_helpers.build_turf_dir_slot_key(target_turf, dir_to_use)
		if(length(slot_key))
			slot_lookup[slot_key] = TRUE
	return slot_lookup

/datum/unit_test/world_edit_corner_slots/proc/count_placements_by_kind(list/placements)
	var/list/counts = list()
	for(var/list/placement as anything in placements)
		var/kind = "[placement["kind"]]"
		if(!length(kind))
			continue
		counts[kind] = (counts[kind] || 0) + 1
	return counts

/datum/unit_test/world_edit_corner_slots/outpost_perimeter/Run()
	var/datum/world_edit_generator/outpost_radius/generator = allocate(/datum/world_edit_generator/outpost_radius)
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit outpost test center turf was not resolved.")

	var/list/family_profile = list(
		"opening_dirs" = list(NORTH, EAST, SOUTH, WEST),
	)
	var/list/barricade_cycle = list(/datum/human_ai_defense/barricade/metal)
	var/list/perimeter_data = generator.collect_perimeter_placements(center_turf, 1, family_profile, barricade_cycle)
	var/list/perimeter_lookup = build_slot_lookup(perimeter_data["placements"])

	TEST_ASSERT_EQUAL(length(perimeter_data["placements"]), 8, "Radius-1 outpost perimeter should keep four corner tiles with two DIR slots each.")

	var/turf/top_left = locate(center_turf.x - 1, center_turf.y + 1, center_turf.z)
	var/turf/top_right = locate(center_turf.x + 1, center_turf.y + 1, center_turf.z)
	var/turf/bottom_left = locate(center_turf.x - 1, center_turf.y - 1, center_turf.z)
	var/turf/bottom_right = locate(center_turf.x + 1, center_turf.y - 1, center_turf.z)

	TEST_ASSERT(perimeter_lookup[GLOB.world_edit_helpers.build_turf_dir_slot_key(top_left, NORTH)], "Top-left corner lost its north-facing slot.")
	TEST_ASSERT(perimeter_lookup[GLOB.world_edit_helpers.build_turf_dir_slot_key(top_left, WEST)], "Top-left corner lost its west-facing slot.")
	TEST_ASSERT(perimeter_lookup[GLOB.world_edit_helpers.build_turf_dir_slot_key(top_right, NORTH)], "Top-right corner lost its north-facing slot.")
	TEST_ASSERT(perimeter_lookup[GLOB.world_edit_helpers.build_turf_dir_slot_key(top_right, EAST)], "Top-right corner lost its east-facing slot.")
	TEST_ASSERT(perimeter_lookup[GLOB.world_edit_helpers.build_turf_dir_slot_key(bottom_left, SOUTH)], "Bottom-left corner lost its south-facing slot.")
	TEST_ASSERT(perimeter_lookup[GLOB.world_edit_helpers.build_turf_dir_slot_key(bottom_left, WEST)], "Bottom-left corner lost its west-facing slot.")
	TEST_ASSERT(perimeter_lookup[GLOB.world_edit_helpers.build_turf_dir_slot_key(bottom_right, SOUTH)], "Bottom-right corner lost its south-facing slot.")
	TEST_ASSERT(perimeter_lookup[GLOB.world_edit_helpers.build_turf_dir_slot_key(bottom_right, EAST)], "Bottom-right corner lost its east-facing slot.")

/datum/unit_test/world_edit_corner_slots/shape_shell/Run()
	var/datum/world_edit_generator/outpost_radius/generator = allocate(/datum/world_edit_generator/outpost_radius)
	var/turf/anchor_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(anchor_turf, "World Edit shape-shell anchor turf was not resolved.")

	var/list/footprint_turfs = list(
		anchor_turf,
		locate(anchor_turf.x + 1, anchor_turf.y, anchor_turf.z),
		locate(anchor_turf.x, anchor_turf.y + 1, anchor_turf.z),
		locate(anchor_turf.x + 1, anchor_turf.y + 1, anchor_turf.z),
	)
	for(var/turf/footprint_turf as anything in footprint_turfs)
		TEST_ASSERT_NOTNULL(footprint_turf, "Shape-shell footprint resolved outside the unit-test floor area.")
	var/list/footprint_lookup = generator.build_turf_lookup(footprint_turfs)
	var/list/shape_bounds = generator.build_turf_bounds(footprint_turfs)
	var/list/candidate_slots = generator.build_shape_perimeter_candidates(footprint_turfs, 1, footprint_lookup, shape_bounds)
	var/list/slot_lookup = build_slot_lookup(candidate_slots)

	TEST_ASSERT_EQUAL(length(candidate_slots), 16, "A 2x2 footprint with radius 1 should produce 16 directed shell slots including corner-stacks.")

	var/turf/north_west_corner = locate(anchor_turf.x - 1, anchor_turf.y + 2, anchor_turf.z)
	var/turf/north_side = locate(anchor_turf.x, anchor_turf.y + 2, anchor_turf.z)

	TEST_ASSERT(slot_lookup[GLOB.world_edit_helpers.build_turf_dir_slot_key(north_west_corner, NORTH)], "Shape shell lost the north-facing corner slot.")
	TEST_ASSERT(slot_lookup[GLOB.world_edit_helpers.build_turf_dir_slot_key(north_west_corner, WEST)], "Shape shell lost the west-facing corner slot.")
	TEST_ASSERT(slot_lookup[GLOB.world_edit_helpers.build_turf_dir_slot_key(north_side, NORTH)], "Shape shell lost the straight north side slot.")
	TEST_ASSERT(!slot_lookup[GLOB.world_edit_helpers.build_turf_dir_slot_key(north_side, WEST)], "Straight north shell tile incorrectly received a west-facing slot.")

/datum/unit_test/world_edit_corner_slots/shape_plan_without_sentries/Run()
	var/datum/world_edit_generator/outpost_radius/generator = allocate(/datum/world_edit_generator/outpost_radius)
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit shape-plan center turf was not resolved.")

	var/list/footprint_turfs = list(
		center_turf,
		locate(center_turf.x + 1, center_turf.y, center_turf.z),
		locate(center_turf.x, center_turf.y + 1, center_turf.z),
		locate(center_turf.x + 1, center_turf.y + 1, center_turf.z),
	)
	for(var/turf/footprint_turf as anything in footprint_turfs)
		TEST_ASSERT_NOTNULL(footprint_turf, "Shape-plan footprint resolved outside the unit-test floor area.")

	var/list/config = list(
		"family" = "standard",
		"family_profile" = list(
			"label" = "Standard",
			"description" = "Unit test family profile",
			"opening_dirs" = list(NORTH, EAST, SOUTH, WEST),
		),
		"radius" = 1,
		"place_sentries" = FALSE,
		"barricade_path" = /datum/human_ai_defense/barricade/metal,
		"barricade_cycle" = list(/datum/human_ai_defense/barricade/metal),
		"sentry_path" = null,
		"faction" = FACTION_MARINE,
		"turned_on" = FALSE,
	)
	var/datum/world_edit_plan/plan = generator.build_shape_aware_perimeter_plan(footprint_turfs, config)
	var/list/placement_counts = count_placements_by_kind(plan.placements)

	TEST_ASSERT_NOTNULL(plan, "Shape-aware outpost plan was not created.")
	TEST_ASSERT(!plan.metadata["error"], "Shape-aware outpost plan unexpectedly failed with sentries disabled.")
	TEST_ASSERT_EQUAL(plan.metadata["opening_count"], 4, "Shape-aware outpost plan should preserve four cardinal openings with sentries disabled.")
	TEST_ASSERT_EQUAL(plan.metadata["barricade_count"], 12, "Shape-aware outpost plan should preserve twelve barricade placements with sentries disabled.")
	TEST_ASSERT_EQUAL(plan.metadata["sentry_count"], 0, "Shape-aware outpost plan should not report sentries when the toggle is disabled.")
	TEST_ASSERT_EQUAL(plan.metadata["blocked_sentries"], 0, "Shape-aware outpost plan should not accumulate blocked sentries when the toggle is disabled.")
	TEST_ASSERT_EQUAL(placement_counts["opening"] || 0, 4, "Shape-aware outpost plan should still emit four opening placements with sentries disabled.")
	TEST_ASSERT_EQUAL(placement_counts["barricade"] || 0, 12, "Shape-aware outpost plan should still emit twelve barricade placements with sentries disabled.")
	TEST_ASSERT_EQUAL(placement_counts["sentry"] || 0, 0, "Shape-aware outpost plan should not emit sentry placements when the toggle is disabled.")

/datum/unit_test/world_edit_corner_slots/shape_plan_with_sentries/Run()
	var/datum/world_edit_generator/outpost_radius/generator = allocate(/datum/world_edit_generator/outpost_radius)
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit shape-plan center turf was not resolved.")

	var/list/footprint_turfs = list(
		center_turf,
		locate(center_turf.x + 1, center_turf.y, center_turf.z),
		locate(center_turf.x, center_turf.y + 1, center_turf.z),
		locate(center_turf.x + 1, center_turf.y + 1, center_turf.z),
	)
	for(var/turf/footprint_turf as anything in footprint_turfs)
		TEST_ASSERT_NOTNULL(footprint_turf, "Shape-plan footprint resolved outside the unit-test floor area.")

	var/list/config = list(
		"family" = "standard",
		"family_profile" = list(
			"label" = "Standard",
			"description" = "Unit test family profile",
			"opening_dirs" = list(NORTH, EAST, SOUTH, WEST),
		),
		"radius" = 1,
		"place_sentries" = TRUE,
		"barricade_path" = /datum/human_ai_defense/barricade/metal,
		"barricade_cycle" = list(/datum/human_ai_defense/barricade/metal),
		"sentry_path" = /datum/human_ai_defense/defense/sentry/uscm,
		"faction" = FACTION_MARINE,
		"turned_on" = FALSE,
	)
	var/datum/world_edit_plan/plan = generator.build_shape_aware_perimeter_plan(footprint_turfs, config)
	var/list/placement_counts = count_placements_by_kind(plan.placements)

	TEST_ASSERT_NOTNULL(plan, "Shape-aware outpost plan was not created.")
	TEST_ASSERT(!plan.metadata["error"], "Shape-aware outpost plan unexpectedly failed with sentries enabled.")
	TEST_ASSERT_EQUAL(plan.metadata["opening_count"], 4, "Shape-aware outpost plan should preserve four cardinal openings with sentries enabled.")
	TEST_ASSERT_EQUAL(plan.metadata["barricade_count"], 12, "Shape-aware outpost plan should preserve twelve barricade placements with sentries enabled.")
	TEST_ASSERT_EQUAL(plan.metadata["sentry_count"], 4, "Shape-aware outpost plan should place one sentry candidate per opening when sentries are enabled.")
	TEST_ASSERT_EQUAL(plan.metadata["blocked_sentries"], 0, "Shape-aware outpost plan should not block sentries on the unit-test floor when the toggle is enabled.")
	TEST_ASSERT_EQUAL(placement_counts["opening"] || 0, 4, "Shape-aware outpost plan should emit four opening placements with sentries enabled.")
	TEST_ASSERT_EQUAL(placement_counts["barricade"] || 0, 12, "Shape-aware outpost plan should emit twelve barricade placements with sentries enabled.")
	TEST_ASSERT_EQUAL(placement_counts["sentry"] || 0, 4, "Shape-aware outpost plan should emit four sentry placements when the toggle is enabled.")

/datum/unit_test/world_edit_live_contract/ready_generators_expose_inline_fields/Run()
	var/list/expected_ready_ids = list(
		"outpost_radius",
		"destruction_pack",
		"blueprint_stamp",
	)
	var/list/seen_ready_ids = list()

	for(var/generator_id in GLOB.world_edit_registry.definitions_by_id)
		var/datum/world_edit_generator_definition/definition = GLOB.world_edit_registry.definitions_by_id[generator_id]
		TEST_ASSERT(definition.status == WORLD_EDIT_STATUS_DRAFT || definition.status == WORLD_EDIT_STATUS_READY, "[generator_id] exposed an unsupported World Edit status [definition.status].")
		if(definition.status != WORLD_EDIT_STATUS_READY)
			continue

		seen_ready_ids += definition.id
		var/datum/world_edit_generator/generator = allocate(definition.generator_type)
		generator.attach(null, definition)
		var/list/ui_fields = generator.get_ui_fields(definition.default_params?.Copy() || list())

		TEST_ASSERT(islist(ui_fields), "[generator_id] should expose inline ui_fields for the live TGUI contract.")
		TEST_ASSERT(length(ui_fields), "[generator_id] should expose at least one inline ui_field.")

	for(var/expected_id in expected_ready_ids)
		TEST_ASSERT(expected_id in seen_ready_ids, "World Edit ready generator [expected_id] dropped out of the live runtime surface.")
	TEST_ASSERT_EQUAL(length(seen_ready_ids), length(expected_ready_ids), "World Edit ready generator surface changed unexpectedly.")
