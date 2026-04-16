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

/datum/unit_test/world_edit_corner_slots/blueprint_export_roundtrip_validates/Run()
	var/datum/world_edit_generator/outpost_radius/generator = allocate(/datum/world_edit_generator/outpost_radius)
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit blueprint-export center turf was not resolved.")

	var/list/footprint_turfs = list(
		center_turf,
		locate(center_turf.x + 1, center_turf.y, center_turf.z),
		locate(center_turf.x, center_turf.y + 1, center_turf.z),
		locate(center_turf.x + 1, center_turf.y + 1, center_turf.z),
	)
	for(var/turf/footprint_turf as anything in footprint_turfs)
		TEST_ASSERT_NOTNULL(footprint_turf, "Blueprint-export footprint resolved outside the unit-test floor area.")

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
	TEST_ASSERT_NOTNULL(plan, "Unit-test outpost plan for blueprint export was not created.")
	TEST_ASSERT(!plan.metadata["error"], "Unit-test outpost plan for blueprint export unexpectedly failed.")

	var/list/export_result = GLOB.world_edit_blueprints.world_edit_export_blueprint_from_outpost_plan(plan, center_turf, "Unit Test Blueprint", "unit_test")
	TEST_ASSERT(!export_result["error"], "Blueprint export from outpost plan unexpectedly failed.")

	var/list/blueprint = export_result["blueprint"]
	TEST_ASSERT(islist(blueprint), "Blueprint export should produce a blueprint payload.")
	TEST_ASSERT(length(blueprint["entries"]), "Blueprint export should contain at least one entry.")

	var/list/validation_result = GLOB.world_edit_blueprints.world_edit_validate_blueprint_definition(list(
		"schema" = WORLD_EDIT_BLUEPRINT_SCHEMA,
		"version" = WORLD_EDIT_BLUEPRINT_VERSION,
		"id" = blueprint["id"],
		"name" = blueprint["name"],
		"created_at" = blueprint["created_at"],
		"created_by" = blueprint["created_by"],
		"source" = blueprint["source"],
		"bounds" = blueprint["bounds"],
		"entries" = blueprint["entries"],
	))
	TEST_ASSERT(!validation_result["error"], "Exported blueprint payload should validate against the live blueprint library schema.")

/datum/unit_test/world_edit_corner_slots/blueprint_plan_rotation_translates_offsets/Run()
	var/turf/anchor_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(anchor_turf, "World Edit blueprint-plan anchor turf was not resolved.")

	var/list/blueprint = list(
		"id" = "unit_test_blueprint",
		"name" = "Unit Test Blueprint",
		"bounds" = list("radius" = 1),
		"entries" = list(
			list(
				"type" = "[/obj/structure/barricade/metal]",
				"dx" = 1,
				"dy" = 0,
				"dz" = 0,
				"dir" = NORTH,
				"vars" = list(),
			),
			list(
				"type" = "[/obj/structure/machinery/defenses/sentry]",
				"dx" = 0,
				"dy" = 1,
				"dz" = 0,
				"dir" = EAST,
				"vars" = list("faction" = FACTION_MARINE, "turned_on" = FALSE),
			),
		),
	)
	var/datum/world_edit_plan/plan = GLOB.world_edit_blueprints.world_edit_build_plan_from_blueprint(blueprint, anchor_turf, EAST)
	TEST_ASSERT_NOTNULL(plan, "Blueprint translation should return a plan datum.")
	TEST_ASSERT(!plan.metadata["error"], "Blueprint translation unexpectedly failed on the unit-test floor.")
	TEST_ASSERT_EQUAL(length(plan.placements), 2, "Blueprint translation should keep both unit-test entries on a clear floor.")
	TEST_ASSERT_EQUAL(plan.metadata["placement_dir"], EAST, "Blueprint translation should preserve the requested placement dir in metadata.")

	var/turf/expected_barricade_turf = locate(anchor_turf.x, anchor_turf.y - 1, anchor_turf.z)
	var/turf/expected_sentry_turf = locate(anchor_turf.x + 1, anchor_turf.y, anchor_turf.z)
	var/found_barricade = FALSE
	var/found_sentry = FALSE
	for(var/list/placement as anything in plan.placements)
		if(placement["obj_path"] == /obj/structure/barricade/metal)
			found_barricade = TRUE
			TEST_ASSERT(placement["turf"] == expected_barricade_turf, "Rotated barricade entry resolved to the wrong turf.")
			TEST_ASSERT_EQUAL(placement["dir"], EAST, "Rotated barricade entry should rotate NORTH to EAST.")
		if(placement["obj_path"] == /obj/structure/machinery/defenses/sentry)
			found_sentry = TRUE
			TEST_ASSERT(placement["turf"] == expected_sentry_turf, "Rotated sentry entry resolved to the wrong turf.")
			TEST_ASSERT_EQUAL(placement["dir"], SOUTH, "Rotated sentry entry should rotate EAST to SOUTH.")

	TEST_ASSERT(found_barricade, "Blueprint translation lost the barricade entry.")
	TEST_ASSERT(found_sentry, "Blueprint translation lost the sentry entry.")

/datum/unit_test/world_edit_corner_slots/blueprint_spawn_entry_sets_barricade_dir/Run()
	var/turf/target_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(target_turf, "World Edit blueprint-spawn turf was not resolved.")

	var/obj/created_object = GLOB.world_edit_blueprints.world_edit_spawn_blueprint_entry(list(
		"obj_path" = /obj/structure/barricade/metal,
		"turf" = target_turf,
		"dir" = WEST,
		"vars" = list(),
	))
	TEST_ASSERT(istype(created_object, /obj/structure/barricade/metal), "Blueprint spawn helper should create the requested barricade type.")
	TEST_ASSERT_EQUAL(created_object.dir, WEST, "Blueprint spawn helper should preserve the requested barricade dir.")

	qdel(created_object)

/datum/unit_test/world_edit_corner_slots/blueprint_validation_rejects_duplicate_relative_slots/Run()
	var/list/validation_result = GLOB.world_edit_blueprints.world_edit_validate_blueprint_definition(list(
		"schema" = WORLD_EDIT_BLUEPRINT_SCHEMA,
		"version" = WORLD_EDIT_BLUEPRINT_VERSION,
		"id" = "dupeslots001",
		"name" = "Duplicate Slots",
		"created_at" = "",
		"created_by" = "unit_test",
		"source" = "unit_test",
		"bounds" = list(
			"min_x" = 0,
			"max_x" = 0,
			"min_y" = 0,
			"max_y" = 0,
			"min_z" = 0,
			"max_z" = 0,
			"radius" = 0,
		),
		"entries" = list(
			list(
				"type" = "[/obj/structure/barricade/metal]",
				"dx" = 0,
				"dy" = 0,
				"dz" = 0,
				"dir" = NORTH,
				"vars" = list(),
			),
			list(
				"type" = "[/obj/structure/barricade/metal]",
				"dx" = 0,
				"dy" = 0,
				"dz" = 0,
				"dir" = NORTH,
				"vars" = list(),
			),
		),
	))

	TEST_ASSERT_EQUAL(validation_result["error"], "Blueprint contains multiple placements for the same relative slot.", "Blueprint validation should reject duplicate relative slot definitions.")

/datum/unit_test/world_edit_corner_slots/blueprint_validation_rejects_barricade_vars/Run()
	var/list/validation_result = GLOB.world_edit_blueprints.world_edit_validate_blueprint_definition(list(
		"schema" = WORLD_EDIT_BLUEPRINT_SCHEMA,
		"version" = WORLD_EDIT_BLUEPRINT_VERSION,
		"id" = "badvars00001",
		"name" = "Invalid Vars",
		"created_at" = "",
		"created_by" = "unit_test",
		"source" = "unit_test",
		"bounds" = list(
			"min_x" = 0,
			"max_x" = 0,
			"min_y" = 0,
			"max_y" = 0,
			"min_z" = 0,
			"max_z" = 0,
			"radius" = 0,
		),
		"entries" = list(
			list(
				"type" = "[/obj/structure/barricade/metal]",
				"dx" = 0,
				"dy" = 0,
				"dz" = 0,
				"dir" = NORTH,
				"vars" = list("turned_on" = TRUE),
			),
		),
	))

	TEST_ASSERT_EQUAL(validation_result["error"], "Vars are not allowed for '/obj/structure/barricade/metal'.", "Blueprint validation should reject vars for non-sentry types.")

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

/datum/unit_test/world_edit_manager_state/context_restore_strips_runtime_params/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/outpost_radius/definition = new
	manager.current_definition = definition
	manager.current_params = list(
		"radius" = 5,
		"shape_points_origin" = "10,10,1",
		"shape_points_text" = "0,0;1,0;1,1",
	)

	TEST_ASSERT(manager.save_current_generator_context(), "World Edit manager should save context for an active generator definition.")

	manager.current_params = list()
	TEST_ASSERT(manager.restore_generator_context(definition.id), "World Edit manager should restore saved context by generator id.")
	TEST_ASSERT_EQUAL(manager.current_params["radius"], 5, "World Edit manager should restore persistent generator params.")
	TEST_ASSERT(isnull(manager.current_params["shape_points_origin"]), "World Edit manager should not persist collector origin runtime params.")
	TEST_ASSERT(isnull(manager.current_params["shape_points_text"]), "World Edit manager should not persist collector points runtime params.")

	qdel(manager)

/datum/unit_test/world_edit_manager_state/preview_state_invalidates_on_signature_change/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/outpost_radius/definition = new
	manager.current_definition = definition
	manager.current_params = list("radius" = 4)

	TEST_ASSERT(!manager.is_preview_state_valid(), "Fresh World Edit manager preview state should start invalid.")

	manager.mark_preview_state()
	TEST_ASSERT(manager.is_preview_state_valid(), "Marked World Edit preview state should be valid before any signature change.")

	manager.current_params["radius"] = 6
	TEST_ASSERT(!manager.is_preview_state_valid(), "Changing generator params should invalidate cached World Edit preview state.")

	manager.current_params["radius"] = 4
	manager.mark_preview_state()
	manager.current_definition = new /datum/world_edit_generator_definition/destruction_pack
	TEST_ASSERT(!manager.is_preview_state_valid(), "Switching generator definition should invalidate cached World Edit preview state.")

	qdel(manager)

/datum/unit_test/world_edit_manager_ui_payload/live_payload_exposes_flat_contract/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/outpost_radius/definition = new
	var/datum/world_edit_generator/outpost_radius/generator = allocate(/datum/world_edit_generator/outpost_radius)
	generator.attach(manager, definition)

	manager.current_definition = definition
	manager.current_generator = generator
	manager.current_params = definition.default_params?.Copy() || list()
	manager.preset_cache_loaded = TRUE
	manager.preset_entries_cache = list()
	manager.blueprint_cache_loaded = TRUE
	manager.blueprint_entries_cache = list()
	manager.apply_shared_placement_prefs_to_current_generator()

	var/list/data = manager.build_ui_data_payload()

	TEST_ASSERT(islist(data), "World Edit UI payload builder should return a flat list payload.")
	TEST_ASSERT(data["has_generator"], "World Edit UI payload builder should report an active generator when one is attached.")
	TEST_ASSERT_EQUAL(data["current_generator_id"], "outpost_radius", "World Edit UI payload builder should expose the current generator id.")
	TEST_ASSERT(islist(data["ui_fields"]), "World Edit UI payload builder should expose normalized inline ui_fields.")
	TEST_ASSERT(length(data["ui_fields"]), "World Edit UI payload builder should include at least one inline ui_field for a live generator.")
	TEST_ASSERT("placement_supported" in data, "World Edit UI payload builder should include placement contract keys.")
	TEST_ASSERT("preset_entries" in data, "World Edit UI payload builder should include preset contract keys.")
	TEST_ASSERT("blueprint_entries" in data, "World Edit UI payload builder should include blueprint contract keys.")
	TEST_ASSERT("history_entries" in data, "World Edit UI payload builder should include history contract keys.")
	TEST_ASSERT("can_run_preview" in data, "World Edit UI payload builder should include actionability contract keys.")

	qdel(manager)
