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

/datum/world_edit_generator_definition/world_edit_test_shape_hook
	id = "world_edit_test_shape_hook"
	name_ru = "World Edit Test Shape Hook"
	category_ru = "Tests"
	description_ru = "Unit-test helper definition for shape support hook coverage."
	required_rights = R_DEBUG
	supports_preview = TRUE
	execution_mode = "batch"
	generator_type = /datum/world_edit_generator/world_edit_test_shape_hook
	default_params = list(
		"shape_line_length" = 4,
		"shape_line_spacing" = 1,
		"shape_rect_width" = 3,
		"shape_rect_height" = 3,
		"shape_radius" = 3,
		"shape_sector_angle" = 90,
		"shape_points_text" = "",
		"shape_polygon_filled" = TRUE,
		"shape_close_loop" = TRUE,
		"shape_brush_radius" = 1,
		"shape_scatter_radius" = 3,
		"shape_scatter_count" = 4,
		"shape_scatter_seed" = 13,
	)
	status = "draft"

/datum/world_edit_generator/world_edit_test_shape_hook
	var/shape_support_calls = 0
	var/build_plan_calls = 0

/datum/world_edit_generator/world_edit_test_shape_hook/get_supported_placement_modes()
	return list("single", "repeat")

/datum/world_edit_generator/world_edit_test_shape_hook/get_supported_placement_shapes()
	return GLOB.world_edit_placement_shapes.world_edit_get_supported_shape_ids().Copy()

/datum/world_edit_generator/world_edit_test_shape_hook/supports_placement_direction()
	return TRUE

/datum/world_edit_generator/world_edit_test_shape_hook/get_ui_fields(list/current_params)
	return list(
		list(
			"id" = "radius",
			"label" = "Radius",
			"kind" = "number",
			"value" = 1,
		),
	)

/datum/world_edit_generator/world_edit_test_shape_hook/get_shape_support_error(shape_id, list/anchor_turfs, list/params, list/placement_context)
	shape_support_calls++
	return "Unit test rejected [shape_id]."

/datum/world_edit_generator/world_edit_test_shape_hook/build_placement_plan(mob/user, list/params, list/placement_context)
	build_plan_calls++
	var/datum/world_edit_plan/plan = new
	plan.metadata["test_plan_built"] = TRUE
	return plan

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
		"schema" = "world_edit_blueprint_lite",
		"version" = 1,
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
		"schema" = "world_edit_blueprint_lite",
		"version" = 1,
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
		"schema" = "world_edit_blueprint_lite",
		"version" = 1,
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
		TEST_ASSERT(definition.status == "draft" || definition.status == "ready", "[generator_id] exposed an unsupported World Edit status [definition.status].")
		if(definition.status != "ready")
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

/datum/unit_test/world_edit_manager_state/reset_placement_runtime_clears_anchor_and_collector_points/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/center_x = round((run_loc_floor_bottom_left.x + run_loc_floor_top_right.x) / 2)
	var/center_y = round((run_loc_floor_bottom_left.y + run_loc_floor_top_right.y) / 2)
	var/turf/center_turf = locate(center_x, center_y, run_loc_floor_bottom_left.z)
	TEST_ASSERT_NOTNULL(center_turf, "World Edit placement reset test center turf was not resolved.")

	manager.current_params = list(
		"shape_points_origin" = "[center_turf.x],[center_turf.y],[center_turf.z]",
		"shape_points_text" = "0,0;1,0;1,1",
	)
	manager.placement_anchor_turf = center_turf
	manager.placement_click_active = TRUE

	manager.reset_placement_runtime()

	TEST_ASSERT(!manager.placement_click_active, "World Edit placement reset should stop click-mode state.")
	TEST_ASSERT(isnull(manager.placement_anchor_turf), "World Edit placement reset should clear the active anchor turf.")
	TEST_ASSERT(isnull(manager.current_params["shape_points_origin"]), "World Edit placement reset should clear collector origin runtime params.")
	TEST_ASSERT(isnull(manager.current_params["shape_points_text"]), "World Edit placement reset should clear collector point runtime params.")

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
	TEST_ASSERT("current_generator_description" in data, "World Edit UI payload builder should expose generator description keys.")
	TEST_ASSERT("current_generator_execution_mode" in data, "World Edit UI payload builder should expose execution mode keys.")
	TEST_ASSERT("current_generator_required_rights" in data, "World Edit UI payload builder should expose rights summary keys.")
	TEST_ASSERT("runtime_status" in data, "World Edit UI payload builder should expose runtime status keys.")
	TEST_ASSERT("current_params_text" in data, "World Edit UI payload builder should expose params summary keys.")
	TEST_ASSERT("requires_preview_before_apply" in data, "World Edit UI payload builder should expose preview requirement keys.")
	TEST_ASSERT("placement_interaction_label" in data, "World Edit UI payload builder should expose placement interaction summary keys.")
	TEST_ASSERT("placement_shape_rollout_stage" in data, "World Edit UI payload builder should expose placement rollout stage keys.")
	TEST_ASSERT("placement_collector_summary" in data, "World Edit UI payload builder should expose collector summary keys.")
	TEST_ASSERT("placement_anchor" in data, "World Edit UI payload builder should expose placement anchor keys.")
	TEST_ASSERT("preset_entries" in data, "World Edit UI payload builder should include preset contract keys.")
	TEST_ASSERT("blueprint_entries" in data, "World Edit UI payload builder should include blueprint contract keys.")
	TEST_ASSERT("history_entries" in data, "World Edit UI payload builder should include history contract keys.")
	TEST_ASSERT("can_run_preview" in data, "World Edit UI payload builder should include actionability contract keys.")
	TEST_ASSERT("can_refresh_ui" in data, "World Edit UI payload builder should expose refresh availability keys.")

	qdel(manager)

/datum/unit_test/world_edit_manager_ui_payload/preset_flag_follows_ready_generator_support/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/outpost_radius/outpost_definition = new
	var/datum/world_edit_generator/outpost_radius/outpost_generator = allocate(/datum/world_edit_generator/outpost_radius)
	outpost_generator.attach(manager, outpost_definition)

	manager.current_definition = outpost_definition
	manager.current_generator = outpost_generator
	manager.current_params = outpost_definition.default_params?.Copy() || list()
	manager.preset_cache_loaded = TRUE
	manager.preset_entries_cache = list()
	manager.blueprint_cache_loaded = TRUE
	manager.blueprint_entries_cache = list()
	manager.apply_shared_placement_prefs_to_current_generator()

	var/list/outpost_data = manager.build_ui_data_payload()
	TEST_ASSERT(outpost_data["can_manage_presets"], "World Edit outpost generator should expose preset support in UI payload.")

	var/datum/world_edit_generator_definition/blueprint_stamp/blueprint_definition = new
	var/datum/world_edit_generator/blueprint_stamp/blueprint_generator = allocate(/datum/world_edit_generator/blueprint_stamp)
	blueprint_generator.attach(manager, blueprint_definition)
	manager.current_definition = blueprint_definition
	manager.current_generator = blueprint_generator
	manager.current_params = blueprint_definition.default_params?.Copy() || list()
	manager.apply_shared_placement_prefs_to_current_generator()

	var/list/blueprint_data = manager.build_ui_data_payload()
	TEST_ASSERT(!blueprint_data["can_manage_presets"], "Blueprint stamp should not expose preset support outside the ready preset scope.")

	qdel(manager)

/datum/unit_test/world_edit_corner_slots/shape_hook_runtime/anchor_pair_click_path_invokes_shape_support_hook/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/world_edit_test_shape_hook/definition = new
	var/datum/world_edit_generator/world_edit_test_shape_hook/generator = allocate(/datum/world_edit_generator/world_edit_test_shape_hook)
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit anchor-pair hook test center turf was not resolved.")
	var/turf/end_turf = locate(center_turf.x + 3, center_turf.y, center_turf.z)
	TEST_ASSERT_NOTNULL(end_turf, "World Edit anchor-pair hook test end turf was not resolved.")
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, center_turf)

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.current_params = definition.default_params?.Copy() || list()
	manager.placement_shape = "line"
	manager.placement_mode = "single"
	manager.placement_dir = EAST
	manager.placement_click_active = TRUE

	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit anchor-pair hook test should accept the first anchor click.")
	TEST_ASSERT_EQUAL(generator.shape_support_calls, 0, "World Edit anchor-pair hook should not run on the first anchor click.")
	TEST_ASSERT(manager.placement_anchor_turf == center_turf, "World Edit anchor-pair hook test should keep the first anchor turf.")

	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), end_turf), "World Edit anchor-pair hook test should accept the second anchor click.")
	TEST_ASSERT_EQUAL(generator.shape_support_calls, 1, "World Edit anchor-pair click path should invoke the shape-support hook once.")
	TEST_ASSERT_EQUAL(generator.build_plan_calls, 0, "World Edit anchor-pair click path should stop before build_placement_plan when the hook rejects the shape.")
	TEST_ASSERT_EQUAL(manager.last_preview_message, "Unit test rejected line.", "World Edit anchor-pair click path should surface the shape hook error.")

	qdel(manager)

/datum/unit_test/world_edit_corner_slots/shape_hook_runtime/collector_click_path_invokes_shape_support_hook/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/world_edit_test_shape_hook/definition = new
	var/datum/world_edit_generator/world_edit_test_shape_hook/generator = allocate(/datum/world_edit_generator/world_edit_test_shape_hook)
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit collector hook test center turf was not resolved.")
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, center_turf)

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.current_params = definition.default_params?.Copy() || list()
	manager.placement_shape = "custom_mask"
	manager.placement_mode = "single"
	manager.placement_dir = NORTH
	manager.placement_click_active = TRUE

	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit collector hook test should accept the first collector click.")
	TEST_ASSERT_EQUAL(generator.shape_support_calls, 1, "World Edit collector click path should invoke the shape-support hook once the collector becomes valid.")
	TEST_ASSERT_EQUAL(generator.build_plan_calls, 0, "World Edit collector click path should stop before build_placement_plan when the hook rejects the shape.")
	TEST_ASSERT_EQUAL(manager.last_preview_message, "Unit test rejected custom_mask.", "World Edit collector click path should surface the shape hook error.")

	qdel(manager)

/datum/unit_test/world_edit_corner_slots/shape_hook_runtime/param_only_click_path_invokes_shape_support_hook/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/world_edit_test_shape_hook/definition = new
	var/datum/world_edit_generator/world_edit_test_shape_hook/generator = allocate(/datum/world_edit_generator/world_edit_test_shape_hook)
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit param-only hook test center turf was not resolved.")
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, center_turf)

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.current_params = definition.default_params?.Copy() || list()
	manager.current_params["shape_scatter_radius"] = 4
	manager.current_params["shape_scatter_count"] = 6
	manager.current_params["shape_scatter_seed"] = 27
	manager.placement_shape = "scatter_cluster"
	manager.placement_mode = "single"
	manager.placement_dir = SOUTH
	manager.placement_click_active = TRUE

	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit param-only hook test should accept the placement click.")
	TEST_ASSERT_EQUAL(generator.shape_support_calls, 1, "World Edit param-only click path should invoke the shape-support hook once.")
	TEST_ASSERT_EQUAL(generator.build_plan_calls, 0, "World Edit param-only click path should stop before build_placement_plan when the hook rejects the shape.")
	TEST_ASSERT_EQUAL(manager.last_preview_message, "Unit test rejected scatter_cluster.", "World Edit param-only click path should surface the shape hook error.")

	qdel(manager)

/datum/unit_test/world_edit_live_contract/shape_catalog_expands_for_outpost_and_destruction/Run()
	var/list/expected_shapes = GLOB.world_edit_placement_shapes.world_edit_get_supported_shape_ids()
	var/datum/world_edit_generator/outpost_radius/outpost_generator = allocate(/datum/world_edit_generator/outpost_radius)
	var/datum/world_edit_generator/destruction_pack/destruction_generator = allocate(/datum/world_edit_generator/destruction_pack)

	TEST_ASSERT_EQUAL(jointext(outpost_generator.get_supported_placement_shapes(), "|"), jointext(expected_shapes, "|"), "Outpost generator should expose the full shared World Edit shape catalog.")
	TEST_ASSERT(outpost_generator.supports_placement_direction(), "Outpost generator should keep direction support when the full shape catalog is enabled.")
	TEST_ASSERT_EQUAL(jointext(destruction_generator.get_supported_placement_shapes(), "|"), jointext(expected_shapes, "|"), "Destruction generator should expose the full shared World Edit shape catalog.")
	TEST_ASSERT(destruction_generator.supports_placement_direction(), "Destruction generator should expose direction support for directional shapes.")

/datum/unit_test/world_edit_corner_slots/outpost_shape_sector_builds_shape_aware_plan/Run()
	var/datum/world_edit_generator/outpost_radius/generator = allocate(/datum/world_edit_generator/outpost_radius)
	var/datum/world_edit_generator_definition/outpost_radius/definition = new
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit outpost sector test center turf was not resolved.")

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.current_params = definition.default_params?.Copy() || list()

	var/list/params = definition.default_params?.Copy() || list()
	params["radius"] = 1
	params["shape_radius"] = 3
	params["shape_sector_angle"] = 90
	var/list/shape_result = GLOB.world_edit_placement_shapes.world_edit_build_shape_turfs("sector", center_turf, null, params, EAST)
	TEST_ASSERT(!shape_result["error"], "World Edit outpost sector test should build sector anchor turfs.")

	var/datum/world_edit_plan/plan = generator.build_placement_plan(null, params, list(
		"mode" = "single",
		"shape" = "sector",
		"shape_metadata" = shape_result["metadata"] || list(),
		"anchor_turfs" = shape_result["turfs"] || list(),
		"start_turf" = center_turf,
		"end_turf" = center_turf,
		"direction" = EAST,
	))
	TEST_ASSERT(!plan.metadata["error"], "World Edit outpost sector test should build a shape-aware outpost plan.")
	TEST_ASSERT_EQUAL(plan.metadata["placement_shape"], "sector", "World Edit outpost sector plan should record the sector shape id.")
	TEST_ASSERT((plan.metadata["anchor_count"] || 0) > 1, "World Edit outpost sector plan should keep the multi-tile sector footprint.")
	TEST_ASSERT(length(plan.placements) > 0, "World Edit outpost sector plan should produce outpost placements.")

	qdel(manager)

/datum/unit_test/world_edit_corner_slots/outpost_shape_line_support_validation_handles_dir_keys/Run()
	var/datum/world_edit_generator/outpost_radius/generator = allocate(/datum/world_edit_generator/outpost_radius)
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit outpost line-shape validation test center turf was not resolved.")

	var/turf/end_turf = locate(center_turf.x + 3, center_turf.y, center_turf.z)
	TEST_ASSERT_NOTNULL(end_turf, "World Edit outpost line-shape validation test end turf was not resolved.")

	var/list/params = list(
		"family" = "metal_perimeter",
		"layout_variant" = "crossroads",
		"opening_width" = "profile",
		"radius" = 1,
		"barricade_path" = /datum/human_ai_defense/barricade/metal,
		"barricade_pattern" = "profile",
		"place_sentries" = FALSE,
		"guard_mode" = "layout",
		"sentry_path" = /datum/human_ai_defense/defense/sentry/uscm,
		"faction" = FACTION_MARINE,
		"turned_on" = TRUE,
		"shape_line_length" = 4,
		"shape_line_spacing" = 1,
	)
	var/list/shape_result = GLOB.world_edit_placement_shapes.world_edit_build_shape_turfs("line", center_turf, end_turf, params, EAST)
	TEST_ASSERT(!shape_result["error"], "World Edit outpost line-shape validation test should build line anchor turfs.")

	var/shape_error = generator.get_shape_support_error("line", shape_result["turfs"] || list(), params, list(
		"mode" = "single",
		"shape" = "line",
		"shape_metadata" = shape_result["metadata"] || list(),
		"anchor_turfs" = shape_result["turfs"] || list(),
		"start_turf" = center_turf,
		"end_turf" = end_turf,
		"direction" = EAST,
	))
	TEST_ASSERT(isnull(shape_error), "World Edit outpost line-shape validation should not fail on an open floor and should not treat cardinal dirs as positional list indexes.")

/datum/unit_test/world_edit_corner_slots/outpost_shape_polygon_builds_shape_aware_plan/Run()
	var/datum/world_edit_generator/outpost_radius/generator = allocate(/datum/world_edit_generator/outpost_radius)
	var/datum/world_edit_generator_definition/outpost_radius/definition = new
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit outpost polygon test center turf was not resolved.")

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.current_params = definition.default_params?.Copy() || list()

	var/list/params = definition.default_params?.Copy() || list()
	params["radius"] = 1
	params["shape_points_text"] = "0,0; 2,0; 2,2; 0,2"
	params["shape_polygon_filled"] = TRUE
	var/list/shape_result = GLOB.world_edit_placement_shapes.world_edit_build_shape_turfs("polygon", center_turf, null, params, NORTH)
	TEST_ASSERT(!shape_result["error"], "World Edit outpost polygon test should build polygon anchor turfs.")

	var/datum/world_edit_plan/plan = generator.build_placement_plan(null, params, list(
		"mode" = "single",
		"shape" = "polygon",
		"shape_metadata" = shape_result["metadata"] || list(),
		"anchor_turfs" = shape_result["turfs"] || list(),
		"start_turf" = center_turf,
		"end_turf" = center_turf,
		"direction" = NORTH,
	))
	TEST_ASSERT(!plan.metadata["error"], "World Edit outpost polygon test should build a collector-driven outpost plan.")
	TEST_ASSERT_EQUAL(plan.metadata["placement_shape"], "polygon", "World Edit outpost polygon plan should record the polygon shape id.")
	TEST_ASSERT((plan.metadata["shape_footprint_count"] || 0) >= 4, "World Edit outpost polygon plan should preserve the polygon footprint size.")
	TEST_ASSERT(length(plan.placements) > 0, "World Edit outpost polygon plan should produce outpost placements.")

	qdel(manager)

/datum/unit_test/world_edit_corner_slots/outpost_shape_scatter_cluster_builds_shape_aware_plan/Run()
	var/datum/world_edit_generator/outpost_radius/generator = allocate(/datum/world_edit_generator/outpost_radius)
	var/datum/world_edit_generator_definition/outpost_radius/definition = new
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit outpost scatter-cluster test center turf was not resolved.")

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.current_params = definition.default_params?.Copy() || list()

	var/list/params = definition.default_params?.Copy() || list()
	params["radius"] = 1
	params["shape_scatter_radius"] = 4
	params["shape_scatter_count"] = 8
	params["shape_scatter_seed"] = 19
	var/list/shape_result = GLOB.world_edit_placement_shapes.world_edit_build_shape_turfs("scatter_cluster", center_turf, null, params, NORTH)
	TEST_ASSERT(!shape_result["error"], "World Edit outpost scatter-cluster test should build deterministic scatter anchors.")

	var/datum/world_edit_plan/plan = generator.build_placement_plan(null, params, list(
		"mode" = "single",
		"shape" = "scatter_cluster",
		"shape_metadata" = shape_result["metadata"] || list(),
		"anchor_turfs" = shape_result["turfs"] || list(),
		"start_turf" = center_turf,
		"end_turf" = center_turf,
		"direction" = NORTH,
	))
	TEST_ASSERT(!plan.metadata["error"], "World Edit outpost scatter-cluster test should build a param-driven outpost plan.")
	TEST_ASSERT_EQUAL(plan.metadata["placement_shape"], "scatter_cluster", "World Edit outpost scatter-cluster plan should record the scatter-cluster shape id.")
	TEST_ASSERT((plan.metadata["anchor_count"] || 0) > 1, "World Edit outpost scatter-cluster plan should keep multiple resolved anchors.")
	TEST_ASSERT(length(plan.placements) > 0, "World Edit outpost scatter-cluster plan should produce outpost placements.")

	qdel(manager)

/datum/unit_test/world_edit_corner_slots/outpost_shape_support_rejects_impossible_openings/Run()
	var/datum/world_edit_generator/outpost_radius/generator = allocate(/datum/world_edit_generator/outpost_radius)
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit outpost impossible-openings test center turf was not resolved.")

	var/list/params = list(
		"family" = "metal_perimeter",
		"layout_variant" = "crossroads",
		"opening_width" = "broad",
		"radius" = 1,
		"barricade_path" = /datum/human_ai_defense/barricade/metal,
		"barricade_pattern" = "profile",
		"place_sentries" = FALSE,
		"guard_mode" = "layout",
		"sentry_path" = /datum/human_ai_defense/defense/sentry/uscm,
		"faction" = FACTION_MARINE,
		"turned_on" = TRUE,
	)

	var/shape_error = generator.get_shape_support_error("custom_mask", list(center_turf), params, list(
		"mode" = "single",
		"shape" = "custom_mask",
		"shape_metadata" = list(),
		"anchor_turfs" = list(center_turf),
		"start_turf" = center_turf,
		"end_turf" = center_turf,
		"direction" = NORTH,
	))
	TEST_ASSERT_EQUAL(shape_error, "Selected footprint cannot support the required outpost openings.", "World Edit outpost shape validation should reject footprints that cannot satisfy required openings.")

/datum/unit_test/world_edit_corner_slots/destruction_shape_build_plan_uses_manager_shape_prefs/Run()
	var/datum/world_edit_generator/destruction_pack/generator = allocate(/datum/world_edit_generator/destruction_pack)
	var/datum/world_edit_generator_definition/destruction_pack/definition = new
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit destruction build-plan test center turf was not resolved.")

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.current_params = definition.default_params?.Copy() || list()
	manager.current_params["radius"] = 2
	manager.current_params["shuffle_enabled"] = FALSE
	manager.current_params["scatter_enabled"] = FALSE
	manager.current_params["persistent_fire_enabled"] = TRUE
	manager.current_params["persistent_fire_density"] = 100
	manager.current_params["blast_enabled"] = FALSE
	manager.current_params["damage_profile"] = "none"
	manager.current_params["shape_radius"] = 3
	manager.current_params["shape_sector_angle"] = 90
	manager.placement_shape = "sector"
	manager.placement_dir = EAST

	var/datum/world_edit_plan/plan = generator.build_plan(manager.current_params, center_turf)
	TEST_ASSERT(!plan.metadata["error"], "World Edit destruction build_plan should respect manager shape prefs for ordinary preview/apply.")
	TEST_ASSERT_EQUAL(plan.metadata["placement_shape"], "sector", "World Edit destruction build_plan should record the manager-selected shape.")
	TEST_ASSERT_EQUAL(plan.metadata["falloff_model"], "nearest_seed_nonstacking", "World Edit destruction build_plan should expose the non-stacking falloff model.")
	TEST_ASSERT((plan.metadata["seed_count"] || 0) > 0, "World Edit destruction build_plan should keep the resolved shape seeds.")
	TEST_ASSERT((plan.metadata["influence_tile_count"] || 0) > 0, "World Edit destruction build_plan should keep the influenced turf count.")
	TEST_ASSERT(length(plan.placements) > 0, "World Edit destruction build_plan should produce fire placements for the selected footprint.")

	qdel(manager)

/datum/unit_test/world_edit_corner_slots/destruction_influence_map_uses_nearest_seed_without_stacking/Run()
	var/datum/world_edit_generator/destruction_pack/generator = allocate(/datum/world_edit_generator/destruction_pack)
	var/turf/seed_a = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(seed_a, "World Edit destruction influence-map test seed A was not resolved.")
	var/turf/seed_b = locate(seed_a.x + 4, seed_a.y, seed_a.z)
	var/turf/mid_turf = locate(seed_a.x + 2, seed_a.y, seed_a.z)
	TEST_ASSERT_NOTNULL(seed_b, "World Edit destruction influence-map test seed B was not resolved.")
	TEST_ASSERT_NOTNULL(mid_turf, "World Edit destruction influence-map test midpoint turf was not resolved.")

	var/list/influence_map = generator.build_influence_map(list(seed_a, seed_b), 3)
	var/list/influence_info = influence_map["lookup"][mid_turf]
	TEST_ASSERT(islist(influence_info), "World Edit destruction influence-map test should resolve midpoint turf info.")
	TEST_ASSERT_EQUAL(text2num("[influence_info["distance"]]"), 2, "World Edit destruction influence-map should keep the nearest-seed distance without stacking.")
	TEST_ASSERT_EQUAL(round((text2num("[influence_info["normalized_weight"]]") || 0) * 100), 50, "World Edit destruction influence-map should preserve the nearest-seed normalized weight.")
	TEST_ASSERT(influence_info["seed_turf"] == seed_a || influence_info["seed_turf"] == seed_b, "World Edit destruction influence-map should attribute midpoint turf to one nearest seed.")

/datum/unit_test/world_edit_corner_slots/destruction_damage_entries_follow_core_mid_outer_bands/Run()
	var/datum/world_edit_generator/destruction_pack/generator = allocate(/datum/world_edit_generator/destruction_pack)
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit destruction damage-band test center turf was not resolved.")

	var/list/influence_map = generator.build_influence_map(list(center_turf), 3)
	var/list/ruin_entries = generator.build_damage_entries(influence_map["turfs"], influence_map["lookup"], "ruin")
	var/list/collapse_entries = generator.build_damage_entries(influence_map["turfs"], influence_map["lookup"], "collapse")
	TEST_ASSERT_EQUAL(length(ruin_entries), 1, "World Edit destruction ruin profile should only emit the core band.")
	TEST_ASSERT_EQUAL(ruin_entries[1]["band"], "core", "World Edit destruction ruin profile should target the core band.")
	TEST_ASSERT_EQUAL(length(collapse_entries), 2, "World Edit destruction collapse profile should emit core and mid bands.")
	TEST_ASSERT_EQUAL(collapse_entries[1]["band"], "core", "World Edit destruction collapse profile should keep the core band first.")
	TEST_ASSERT_EQUAL(collapse_entries[2]["band"], "mid", "World Edit destruction collapse profile should convert the mid band to ruin damage.")
	TEST_ASSERT_EQUAL(collapse_entries[2]["damage_profile"], "ruin", "World Edit destruction collapse profile should downgrade the mid band to ruin severity.")

/datum/unit_test/world_edit_corner_slots/destruction_blast_centers_cap_and_spacing_hold_for_large_seed_sets/Run()
	var/datum/world_edit_generator/destruction_pack/generator = allocate(/datum/world_edit_generator/destruction_pack)
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit destruction blast-center test center turf was not resolved.")
	var/z_level = center_turf.z

	var/list/seed_turfs = list()
	var/list/candidate_turfs = list(
		run_loc_floor_bottom_left,
		run_loc_floor_top_right,
		locate(run_loc_floor_bottom_left.x, run_loc_floor_top_right.y, z_level),
		locate(run_loc_floor_top_right.x, run_loc_floor_bottom_left.y, z_level),
		locate(center_turf.x, run_loc_floor_bottom_left.y, z_level),
		locate(center_turf.x, run_loc_floor_top_right.y, z_level),
		locate(run_loc_floor_bottom_left.x, center_turf.y, z_level),
		locate(run_loc_floor_top_right.x, center_turf.y, z_level),
	)
	for(var/turf/candidate_turf as anything in candidate_turfs)
		if(istype(candidate_turf) && !(candidate_turf in seed_turfs))
			seed_turfs += candidate_turf

	var/list/blast_centers = generator.build_blast_centers(seed_turfs, center_turf, 1, 1337)
	TEST_ASSERT(length(blast_centers) > 1, "World Edit destruction blast-center test should produce secondary centers for wide seed sets.")
	TEST_ASSERT(length(blast_centers) <= 6, "World Edit destruction blast-center selection should respect the hard cap of six centers.")
	for(var/i in 1 to length(blast_centers))
		for(var/j in (i + 1) to length(blast_centers))
			if(j > length(blast_centers))
				continue
			TEST_ASSERT(generator.get_chebyshev_distance(blast_centers[i], blast_centers[j]) > 2, "World Edit destruction blast-center selection should keep every center more than radius*2 apart.")
