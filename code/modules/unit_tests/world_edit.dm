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

/datum/unit_test/world_edit_corner_slots/proc/build_relative_turf_lookup(list/turfs, turf/origin_turf)
	var/list/lookup = list()
	if(!istype(origin_turf) || !islist(turfs))
		return lookup

	for(var/turf/target_turf as anything in turfs)
		if(!istype(target_turf))
			continue
		lookup["[target_turf.x - origin_turf.x],[target_turf.y - origin_turf.y]"] = TRUE
	return lookup

/datum/unit_test/world_edit_corner_slots/proc/build_shape_result(shape_id, turf/origin_turf, list/params = null, direction = NORTH, turf/end_turf = null)
	return GLOB.world_edit_placement_shapes.world_edit_build_shape_turfs(shape_id, origin_turf, end_turf, params || list(), direction)

/datum/unit_test/world_edit_corner_slots/proc/build_shape_integration_case(shape_id, turf/origin_turf, list/base_params = null, direction = EAST)
	var/list/params = islist(base_params) ? base_params.Copy() : list()
	var/turf/end_turf = origin_turf

	switch("[shape_id]")
		if(WORLD_EDIT_SHAPE_LINE)
			params["shape_line_length"] = 4
			params["shape_line_spacing"] = 1
			end_turf = locate(origin_turf.x + 3, origin_turf.y, origin_turf.z)
		if(WORLD_EDIT_SHAPE_RECTANGLE, WORLD_EDIT_SHAPE_FILLED_RECTANGLE)
			params["shape_rect_width"] = 3
			params["shape_rect_height"] = 3
			end_turf = locate(origin_turf.x + 2, origin_turf.y + 2, origin_turf.z)
		if(WORLD_EDIT_SHAPE_CIRCLE)
			params["shape_radius"] = 2
			end_turf = origin_turf
		if(WORLD_EDIT_SHAPE_RING)
			params["shape_radius"] = 2
			params["shape_thickness"] = 1
			end_turf = origin_turf
		if(WORLD_EDIT_SHAPE_ELLIPSE)
			params["shape_radius_x"] = 3
			params["shape_radius_y"] = 2
			end_turf = locate(origin_turf.x + 3, origin_turf.y + 2, origin_turf.z)
		if(WORLD_EDIT_SHAPE_DIAMOND)
			params["shape_radius"] = 2
			end_turf = locate(origin_turf.x + 2, origin_turf.y, origin_turf.z)
		if(WORLD_EDIT_SHAPE_TRIANGLE)
			params["shape_triangle_size"] = 3
			end_turf = locate(origin_turf.x + 3, origin_turf.y, origin_turf.z)
		if(WORLD_EDIT_SHAPE_SECTOR)
			params["shape_radius"] = 3
			params["shape_thickness"] = 1
			params["shape_sector_angle"] = 90
			end_turf = locate(origin_turf.x + 3, origin_turf.y + 1, origin_turf.z)
		if(WORLD_EDIT_SHAPE_POLYGON)
			params["shape_points_text"] = "0,0; 2,0; 2,2; 0,2"
			params["shape_polygon_filled"] = TRUE
			end_turf = origin_turf
		if(WORLD_EDIT_SHAPE_POLYLINE)
			params["shape_points_text"] = "0,0; 2,0; 3,1; 4,1"
			end_turf = origin_turf
		if(WORLD_EDIT_SHAPE_CUSTOM_MASK)
			params["shape_points_text"] = "0,0; 1,0; 1,1"
			end_turf = origin_turf
		if(WORLD_EDIT_SHAPE_BRUSH_PATH)
			params["shape_points_text"] = "0,0; 2,0; 3,1"
			params["shape_brush_radius"] = 1
			end_turf = origin_turf
		if(WORLD_EDIT_SHAPE_SCATTER_CLUSTER)
			params["shape_scatter_radius"] = 1
			params["shape_scatter_count"] = 5
			params["shape_scatter_seed"] = 13
			end_turf = origin_turf
		else
			end_turf = origin_turf

	var/list/shape_result = build_shape_result(shape_id, origin_turf, params, direction, end_turf)
	return list(
		"params" = params,
		"end_turf" = end_turf,
		"shape_result" = shape_result,
		"placement_context" = list(
			"mode" = "single",
			"shape" = shape_id,
			"shape_metadata" = shape_result["metadata"] || list(),
			"anchor_turfs" = shape_result["turfs"] || list(),
			"start_turf" = origin_turf,
			"end_turf" = end_turf,
			"direction" = direction,
		),
	)

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

/datum/world_edit_generator_definition/world_edit_test_apply_hook
	id = "world_edit_test_apply_hook"
	name_ru = "World Edit Test Apply Hook"
	category_ru = "Tests"
	description_ru = "Unit-test helper definition for preview/apply runtime coverage."
	required_rights = R_DEBUG
	supports_preview = TRUE
	execution_mode = "batch"
	generator_type = /datum/world_edit_generator/world_edit_test_apply_hook
	default_params = list(
		"shape_line_length" = 4,
		"shape_line_spacing" = 1,
		"shape_rect_width" = 3,
		"shape_rect_height" = 3,
		"shape_radius" = 3,
		"shape_radius_x" = 3,
		"shape_radius_y" = 2,
		"shape_triangle_size" = 3,
		"shape_sector_angle" = 90,
		"shape_points_text" = "",
		"shape_polygon_filled" = TRUE,
		"shape_brush_radius" = 1,
		"shape_scatter_radius" = 3,
		"shape_scatter_count" = 4,
		"shape_scatter_seed" = 13,
	)
	status = "draft"

/datum/world_edit_generator/world_edit_test_apply_hook/get_supported_placement_modes()
	return list("single", "repeat")

/datum/world_edit_generator/world_edit_test_apply_hook/get_supported_placement_shapes()
	return GLOB.world_edit_placement_shapes.world_edit_get_supported_shape_ids().Copy()

/datum/world_edit_generator/world_edit_test_apply_hook/supports_placement_direction()
	return TRUE

/datum/world_edit_generator/world_edit_test_apply_hook
	var/apply_calls = 0

/datum/world_edit_generator/world_edit_test_apply_hook/build_placement_plan(mob/user, list/params, list/placement_context)
	var/datum/world_edit_plan/plan = new
	var/list/anchor_turfs = placement_context["anchor_turfs"] || list()
	for(var/turf/anchor_turf as anything in anchor_turfs)
		if(!istype(anchor_turf))
			continue
		plan.placements += list(list("kind" = "test", "turf" = anchor_turf, "dir" = placement_context["direction"] || NORTH))
		plan.affected_turfs += anchor_turf
	plan.metadata["anchor_count"] = length(anchor_turfs)
	plan.metadata["entry_count"] = length(plan.placements)
	plan.metadata["placement_shape"] = "[placement_context["shape"]]"
	plan.metadata["shape_label"] = GLOB.world_edit_placement_shapes.world_edit_get_placement_shape_label(placement_context["shape"])
	plan.metadata["placement_mode"] = "[placement_context["mode"] || "single"]"
	plan.metadata["placement_dir_label"] = GLOB.world_edit_helpers.dir_to_label(placement_context["direction"] || NORTH)
	return plan

/datum/world_edit_generator/world_edit_test_apply_hook/apply(mob/user, list/params)
	var/datum/world_edit_apply_result/result = new
	apply_calls++
	result.success = TRUE
	result.message = "ok"
	result.meta = list("applied" = TRUE)
	return result

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

/datum/unit_test/world_edit_corner_slots/radius_policy/shared_helper_handles_windows_and_reachability/Run()
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit radius-policy helper test center turf was not resolved.")
	var/turf/window_turf = locate(center_turf.x + 1, center_turf.y, center_turf.z)
	var/turf/far_turf = locate(center_turf.x + 2, center_turf.y, center_turf.z)
	TEST_ASSERT_NOTNULL(window_turf, "World Edit radius-policy helper test window turf was not resolved.")
	TEST_ASSERT_NOTNULL(far_turf, "World Edit radius-policy helper test far turf was not resolved.")

	var/list/default_policy = GLOB.world_edit_helpers.get_world_edit_radius_policy(list())
	TEST_ASSERT(default_policy["only_clear_tiles"], "World Edit radius-policy helper should default to only-clear filtering.")
	TEST_ASSERT(!default_policy["only_reachable_tiles"], "World Edit radius-policy helper should keep reachable filtering disabled by default.")
	TEST_ASSERT(default_policy["treat_windows_as_blockers"], "World Edit radius-policy helper should treat windows as blockers by default.")

	var/obj/structure/window/test_window = allocate(/obj/structure/window, window_turf)
	TEST_ASSERT_NOTNULL(test_window, "World Edit radius-policy helper test should create a window blocker.")

	var/list/reachable_blocked = GLOB.world_edit_helpers.filter_radius_candidate_turfs(
		list(center_turf),
		list(center_turf, window_turf, far_turf),
		list(center_turf, window_turf, far_turf),
		list(
			"only_clear_tiles" = TRUE,
			"only_reachable_tiles" = TRUE,
			"treat_windows_as_blockers" = TRUE,
		),
		list(center_turf),
	)
	TEST_ASSERT(center_turf in reachable_blocked, "World Edit radius-policy helper should keep the selected anchor turf pinned.")
	TEST_ASSERT(!(window_turf in reachable_blocked), "World Edit radius-policy helper should exclude a window tile when windows count as blockers.")
	TEST_ASSERT(!(far_turf in reachable_blocked), "World Edit radius-policy helper should block tiles behind the window when reachable filtering is enabled.")

	var/list/reachable_unblocked = GLOB.world_edit_helpers.filter_radius_candidate_turfs(
		list(center_turf),
		list(center_turf, window_turf, far_turf),
		list(center_turf, window_turf, far_turf),
		list(
			"only_clear_tiles" = TRUE,
			"only_reachable_tiles" = TRUE,
			"treat_windows_as_blockers" = FALSE,
		),
		list(center_turf),
	)
	TEST_ASSERT(window_turf in reachable_unblocked, "World Edit radius-policy helper should allow a window tile when windows are not blockers.")
	TEST_ASSERT(far_turf in reachable_unblocked, "World Edit radius-policy helper should restore tiles behind the window when window blocking is disabled.")

	qdel(test_window)

/datum/unit_test/world_edit_corner_slots/outpost_perimeter/radius_policy_reachable_filters_blocked_shell_tiles/Run()
	var/datum/world_edit_generator/outpost_radius/generator = allocate(/datum/world_edit_generator/outpost_radius)
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit outpost radius-policy test center turf was not resolved.")

	var/list/layout_profile = list(
		"opening_dirs" = list(),
		"opening_width" = 1,
	)
	var/list/barricade_cycle = list(/datum/human_ai_defense/barricade/metal)
	var/list/barriers = list()
	for(var/offset_y in -2 to 2)
		var/turf/barrier_turf = locate(center_turf.x + 1, center_turf.y + offset_y, center_turf.z)
		TEST_ASSERT_NOTNULL(barrier_turf, "World Edit outpost radius-policy barrier turf was not resolved.")
		barriers += allocate(/obj/structure/barricade/metal, barrier_turf)

	var/list/traversal_turfs = generator.build_point_radius_area_turfs(center_turf, 2)
	var/list/no_reach = generator.collect_perimeter_placements(
		center_turf,
		2,
		layout_profile,
		barricade_cycle,
		"uniform",
		list(
			"only_clear_tiles" = TRUE,
			"only_reachable_tiles" = FALSE,
			"treat_windows_as_blockers" = TRUE,
		),
		traversal_turfs,
	)
	var/list/with_reach = generator.collect_perimeter_placements(
		center_turf,
		2,
		layout_profile,
		barricade_cycle,
		"uniform",
		list(
			"only_clear_tiles" = TRUE,
			"only_reachable_tiles" = TRUE,
			"treat_windows_as_blockers" = TRUE,
		),
		traversal_turfs,
	)
	var/turf/east_shell_turf = locate(center_turf.x + 2, center_turf.y, center_turf.z)
	var/east_shell_key = GLOB.world_edit_helpers.build_turf_dir_slot_key(east_shell_turf, EAST)
	var/list/no_reach_lookup = build_slot_lookup(no_reach["placements"])
	var/list/with_reach_lookup = build_slot_lookup(with_reach["placements"])
	TEST_ASSERT(!no_reach_lookup[east_shell_key], "World Edit outpost perimeter clear-path filtering should drop shell slots hidden behind a full blocker line.")
	TEST_ASSERT(!with_reach_lookup[east_shell_key], "World Edit outpost perimeter reachable filtering should drop shell slots behind a full blocker line.")

	for(var/obj/barrier as anything in barriers)
		qdel(barrier)

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
	manager.placement_mode = "repeat"
	manager.placement_shape = WORLD_EDIT_SHAPE_BRUSH_PATH
	manager.placement_dir = WEST
	manager.placement_dir_uses_facing = FALSE

	TEST_ASSERT(manager.save_current_generator_context(), "World Edit manager should save context for an active generator definition.")

	manager.current_params = list()
	manager.placement_mode = "single"
	manager.placement_shape = WORLD_EDIT_SHAPE_POINT
	manager.placement_dir = NORTH
	manager.placement_dir_uses_facing = TRUE
	TEST_ASSERT(manager.restore_generator_context(definition.id), "World Edit manager should restore saved context by generator id.")
	TEST_ASSERT_EQUAL(manager.current_params["radius"], 5, "World Edit manager should restore persistent generator params.")
	TEST_ASSERT(isnull(manager.current_params["shape_points_origin"]), "World Edit manager should not persist collector origin runtime params.")
	TEST_ASSERT(isnull(manager.current_params["shape_points_text"]), "World Edit manager should not persist collector points runtime params.")
	TEST_ASSERT_EQUAL(manager.placement_mode, "repeat", "World Edit manager should restore placement mode from generator context.")
	TEST_ASSERT_EQUAL(manager.placement_shape, WORLD_EDIT_SHAPE_BRUSH_PATH, "World Edit manager should restore placement shape from generator context.")
	TEST_ASSERT_EQUAL(manager.placement_dir, WEST, "World Edit manager should restore placement direction from generator context.")
	TEST_ASSERT(!manager.placement_dir_uses_facing, "World Edit manager should restore the facing-toggle preference from generator context.")

	qdel(manager)

/datum/unit_test/world_edit_manager_state/restore_generator_session_state_uses_generator_defaults_without_snapshot/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/outpost_radius/definition = new
	var/datum/world_edit_generator/outpost_radius/generator = allocate(/datum/world_edit_generator/outpost_radius)
	generator.attach(manager, definition)

	manager.current_definition = definition
	manager.current_generator = generator
	manager.current_params = definition.default_params?.Copy() || list()
	manager.placement_shared_mode = "repeat"
	manager.placement_shared_shape = WORLD_EDIT_SHAPE_BRUSH_PATH
	manager.placement_shared_dir = WEST
	manager.placement_shared_dir_uses_facing = FALSE
	manager.placement_mode = "repeat"
	manager.placement_shape = WORLD_EDIT_SHAPE_BRUSH_PATH
	manager.placement_dir = WEST
	manager.placement_dir_uses_facing = FALSE

	TEST_ASSERT(!manager.restore_generator_session_state(definition.id), "World Edit manager should report that no saved generator snapshot exists yet.")
	TEST_ASSERT_EQUAL(manager.placement_mode, "single", "World Edit manager should use the generator default mode when no saved snapshot exists.")
	TEST_ASSERT_EQUAL(manager.placement_shape, WORLD_EDIT_SHAPE_POINT, "World Edit manager should use the generator default shape instead of inheriting a previous generator brush shape.")
	TEST_ASSERT_EQUAL(manager.placement_dir, NORTH, "World Edit manager should use the generator default direction when no saved snapshot exists.")
	TEST_ASSERT(manager.placement_dir_uses_facing, "World Edit manager should restore the default facing-toggle state when no saved snapshot exists.")
	TEST_ASSERT_EQUAL(manager.placement_shared_mode, "single", "World Edit manager should keep shared placement mode in sync with the restored generator state.")
	TEST_ASSERT_EQUAL(manager.placement_shared_shape, WORLD_EDIT_SHAPE_POINT, "World Edit manager should keep shared placement shape in sync with the restored generator state.")
	TEST_ASSERT_EQUAL(manager.placement_shared_dir, NORTH, "World Edit manager should keep shared placement direction in sync with the restored generator state.")
	TEST_ASSERT(manager.placement_shared_dir_uses_facing, "World Edit manager should keep the shared facing-toggle state in sync with the restored generator state.")

	qdel(manager)

/datum/unit_test/world_edit_manager_state/restore_generator_session_state_restores_saved_placement_prefs/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/outpost_radius/definition = new
	var/datum/world_edit_generator/outpost_radius/generator = allocate(/datum/world_edit_generator/outpost_radius)
	generator.attach(manager, definition)

	manager.current_definition = definition
	manager.current_generator = generator
	manager.current_params = definition.default_params?.Copy() || list()
	manager.current_params["radius"] = 7
	manager.placement_mode = "repeat"
	manager.placement_shape = WORLD_EDIT_SHAPE_BRUSH_PATH
	manager.placement_dir = WEST
	manager.placement_dir_uses_facing = FALSE
	TEST_ASSERT(manager.save_current_generator_context(), "World Edit manager should save placement prefs together with generator params.")

	manager.current_params = definition.default_params?.Copy() || list()
	manager.placement_mode = "single"
	manager.placement_shape = WORLD_EDIT_SHAPE_POINT
	manager.placement_dir = NORTH
	manager.placement_dir_uses_facing = TRUE

	TEST_ASSERT(manager.restore_generator_session_state(definition.id), "World Edit manager should restore the saved generator snapshot when it exists.")
	TEST_ASSERT_EQUAL(manager.current_params["radius"], 7, "World Edit manager should restore saved generator params when re-entering a generator.")
	TEST_ASSERT_EQUAL(manager.placement_mode, "repeat", "World Edit manager should restore the saved placement mode for a generator.")
	TEST_ASSERT_EQUAL(manager.placement_shape, WORLD_EDIT_SHAPE_BRUSH_PATH, "World Edit manager should restore the saved placement shape for a generator.")
	TEST_ASSERT_EQUAL(manager.placement_dir, WEST, "World Edit manager should restore the saved placement direction for a generator.")
	TEST_ASSERT(!manager.placement_dir_uses_facing, "World Edit manager should restore the saved facing-toggle state for a generator.")

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

/datum/unit_test/world_edit_manager_state/preview_state_invalidates_on_collector_session_change/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/outpost_radius/definition = new
	manager.current_definition = definition
	manager.current_params = list("radius" = 4)
	manager.placement_shape = WORLD_EDIT_SHAPE_POLYGON
	manager.set_placement_collector_points(list(
		list("x" = 0, "y" = 0),
		list("x" = 1, "y" = 0),
		list("x" = 1, "y" = 1),
	))

	manager.mark_preview_state()
	TEST_ASSERT(manager.is_preview_state_valid(), "World Edit preview state should be valid before collector-session changes.")

	manager.set_placement_collector_points(list(
		list("x" = 0, "y" = 0),
		list("x" = 2, "y" = 0),
		list("x" = 2, "y" = 2),
	))
	TEST_ASSERT(!manager.is_preview_state_valid(), "World Edit preview signature should invalidate when collector-session points change.")

	qdel(manager)

/datum/unit_test/world_edit_manager_state/preview_state_invalidates_on_anchor_and_resolved_target_change/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/outpost_radius/definition = new
	var/center_x = round((run_loc_floor_bottom_left.x + run_loc_floor_top_right.x) / 2)
	var/center_y = round((run_loc_floor_bottom_left.y + run_loc_floor_top_right.y) / 2)
	var/turf/center_turf = locate(center_x, center_y, run_loc_floor_bottom_left.z)
	var/turf/end_turf = locate(center_turf.x + 2, center_turf.y, center_turf.z)
	var/turf/other_turf = locate(center_turf.x + 3, center_turf.y + 1, center_turf.z)
	TEST_ASSERT_NOTNULL(center_turf, "World Edit preview-signature anchor test center turf was not resolved.")
	TEST_ASSERT_NOTNULL(end_turf, "World Edit preview-signature anchor test end turf was not resolved.")
	TEST_ASSERT_NOTNULL(other_turf, "World Edit preview-signature anchor test alternate turf was not resolved.")

	manager.current_definition = definition
	manager.current_params = list("radius" = 4)
	manager.placement_shape = WORLD_EDIT_SHAPE_LINE
	manager.set_placement_anchor_turf(center_turf)

	var/datum/world_edit_placement_candidate/candidate = new
	candidate.placement_context = list(
		"seed_turf" = center_turf,
		"requested_end_turf" = end_turf,
		"resolved_end_turf" = end_turf,
	)
	manager.store_placement_preview_candidate(candidate)
	manager.mark_preview_state()
	TEST_ASSERT(manager.is_preview_state_valid(), "World Edit preview signature should start valid before anchor/target changes.")

	manager.set_placement_anchor_turf(other_turf)
	TEST_ASSERT(!manager.is_preview_state_valid(), "World Edit preview signature should invalidate when the active anchor turf changes.")

	manager.set_placement_anchor_turf(center_turf)
	manager.mark_preview_state()
	var/datum/world_edit_placement_candidate/updated_candidate = new
	updated_candidate.placement_context = list(
		"seed_turf" = center_turf,
		"requested_end_turf" = end_turf,
		"resolved_end_turf" = other_turf,
	)
	manager.store_placement_preview_candidate(updated_candidate)
	TEST_ASSERT(!manager.is_preview_state_valid(), "World Edit preview signature should invalidate when the resolved preview target changes.")

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
	TEST_ASSERT("placement_hover" in data, "World Edit UI payload builder should expose placement hover keys.")
	TEST_ASSERT("placement_preview_effect_tiles" in data, "World Edit UI payload builder should expose preview effect tile counts.")
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

/datum/unit_test/world_edit_manager_ui_payload/shape_params_apply_without_generator_field_lookup/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	manager.current_params = list()

	var/list/shape_field = manager.find_shape_ui_field_by_id("shape_sector_angle", WORLD_EDIT_SHAPE_SECTOR)
	TEST_ASSERT(islist(shape_field), "World Edit shape ui-field lookup should resolve sector-only shape parameters outside the generator field catalog.")

	var/list/new_params = manager.apply_shape_ui_param_to_params(manager.current_params, "shape_sector_angle", 135, shape_field)
	TEST_ASSERT(islist(new_params), "World Edit shape ui-field application should return a params list for supported shape fields.")
	TEST_ASSERT_EQUAL(text2num("[new_params["shape_sector_angle"]]"), 135, "World Edit shape ui-field application should persist sector angle values.")
	TEST_ASSERT(isnull(new_params["shape_sector_angle.2"]), "World Edit shape ui-field application should not persist malformed duplicate parameter ids.")

	new_params = manager.apply_shape_ui_param_to_params(new_params, "shape_sector_angle.2", 180)
	TEST_ASSERT(islist(new_params), "World Edit shape ui-field application should canonicalize dotted numeric suffixes from stale UI controls.")
	TEST_ASSERT_EQUAL(text2num("[new_params["shape_sector_angle"]]"), 180, "World Edit shape ui-field canonicalization should still update the intended sector field.")
	TEST_ASSERT(isnull(new_params["shape_sector_angle.2"]), "World Edit shape ui-field canonicalization should collapse dotted suffix ids to the shared canonical field id.")

	new_params = manager.apply_shape_ui_param_to_params(new_params, "shape_scatter_radius", 99)
	TEST_ASSERT(islist(new_params), "World Edit shape ui-field application should also work for non-current-shape fields.")
	TEST_ASSERT_EQUAL(text2num("[new_params["shape_scatter_radius"]]"), 12, "World Edit shape ui-field application should clamp values to the shared shape field contract.")

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

/datum/unit_test/world_edit_corner_slots/manager_runtime/right_click_cancels_invalid_outpost_collection/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/outpost_radius/definition = new
	var/datum/world_edit_generator/outpost_radius/generator = allocate(/datum/world_edit_generator/outpost_radius)
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit invalid-outpost collector test center turf was not resolved.")
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, center_turf)

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.current_params = definition.default_params?.Copy() || list()
	manager.current_params["radius"] = 1
	manager.current_params["opening_width"] = "broad"
	manager.placement_shape = "custom_mask"
	manager.placement_mode = "single"
	manager.placement_dir = NORTH
	manager.placement_click_active = TRUE

	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit invalid-outpost collector test should accept the first collector point.")
	TEST_ASSERT(findtext("[manager.last_preview_message]", "Выбранный контур размещения не поддерживает обязательные проходы форпоста."), "World Edit invalid-outpost collector test should surface the expected support error before cancellation.")
	TEST_ASSERT(manager.placement_click_active, "World Edit invalid-outpost collector test should keep placement mode active until the user cancels it.")

	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(RIGHT_CLICK = 1)), center_turf), "World Edit invalid-outpost collector test should accept right-click cancellation.")
	TEST_ASSERT(!manager.placement_click_active, "World Edit invalid-outpost collector test should stop placement mode after right-clicking an invalid collector preview.")
	TEST_ASSERT(isnull(manager.placement_anchor_turf), "World Edit invalid-outpost collector test should clear the active anchor when cancellation stops placement mode.")
	TEST_ASSERT_EQUAL(manager.get_placement_collector_point_count(), 0, "World Edit invalid-outpost collector test should clear collector points when cancellation stops placement mode.")

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

/datum/unit_test/world_edit_corner_slots/manager_runtime/collector_clicking_first_point_finishes_open_and_closed_paths/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/world_edit_test_apply_hook/definition = new
	var/datum/world_edit_generator/world_edit_test_apply_hook/generator = allocate(/datum/world_edit_generator/world_edit_test_apply_hook)
	var/turf/center_turf = get_world_edit_test_center_turf()
	var/turf/line_turf = locate(center_turf.x + 2, center_turf.y, center_turf.z)
	var/turf/triangle_turf = locate(center_turf.x + 2, center_turf.y + 2, center_turf.z)
	TEST_ASSERT_NOTNULL(center_turf, "World Edit collector-first-point test center turf was not resolved.")
	TEST_ASSERT_NOTNULL(line_turf, "World Edit collector-first-point test line turf was not resolved.")
	TEST_ASSERT_NOTNULL(triangle_turf, "World Edit collector-first-point test triangle turf was not resolved.")
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, center_turf)

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.current_params = definition.default_params?.Copy() || list()
	manager.placement_mode = "single"
	manager.placement_dir = NORTH
	manager.placement_click_active = TRUE

	manager.placement_shape = "polygon"
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit polygon collector should accept the first point.")
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), line_turf), "World Edit polygon collector should accept the second point.")
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), triangle_turf), "World Edit polygon collector should accept the third point.")
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit polygon collector should finish when the first point is clicked again.")
	TEST_ASSERT_EQUAL(generator.apply_calls, 1, "World Edit polygon collector should apply immediately when the user closes the chain on the first point.")

	manager.reset_placement_runtime()
	manager.current_params = definition.default_params?.Copy() || list()
	manager.placement_shape = "polyline"
	manager.placement_mode = "single"
	manager.placement_dir = NORTH
	manager.placement_click_active = TRUE
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit polyline collector should accept the first point.")
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), line_turf), "World Edit polyline collector should accept the second point.")
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), triangle_turf), "World Edit polyline collector should accept the third point.")
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit polyline collector should finish when the first point is clicked again.")
	TEST_ASSERT_EQUAL(generator.apply_calls, 2, "World Edit polyline collector should use the first-point click as a finish gesture without requiring right-click.")

	manager.reset_placement_runtime()
	manager.current_params = definition.default_params?.Copy() || list()
	manager.placement_shape = "brush_path"
	manager.placement_mode = "single"
	manager.placement_dir = NORTH
	manager.placement_click_active = TRUE
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit brush-path collector should accept the first point.")
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), line_turf), "World Edit brush-path collector should accept the second point.")
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), triangle_turf), "World Edit brush-path collector should accept the third point.")
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit brush-path collector should finish when the first point is clicked again.")
	TEST_ASSERT_EQUAL(generator.apply_calls, 3, "World Edit brush-path collector should reuse the first-point click as a finish gesture for open paths.")

	manager.reset_placement_runtime()
	manager.current_params = definition.default_params?.Copy() || list()
	manager.placement_shape = "custom_mask"
	manager.placement_mode = "single"
	manager.placement_dir = NORTH
	manager.placement_click_active = TRUE
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit custom-mask collector should accept the first point.")
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), line_turf), "World Edit custom-mask collector should accept the second point.")
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit custom-mask collector should treat a repeated first point as a duplicate, not as a finish gesture.")
	TEST_ASSERT_EQUAL(generator.apply_calls, 3, "World Edit custom-mask collector should stay in exact-point mode and should not auto-finish on the first point.")

	qdel(manager)

/datum/unit_test/world_edit_live_contract/shape_catalog_expands_for_outpost_and_destruction/Run()
	var/list/expected_shapes = GLOB.world_edit_placement_shapes.world_edit_get_supported_shape_ids()
	var/datum/world_edit_generator/outpost_radius/outpost_generator = allocate(/datum/world_edit_generator/outpost_radius)
	var/datum/world_edit_generator/destruction_pack/destruction_generator = allocate(/datum/world_edit_generator/destruction_pack)

	TEST_ASSERT_EQUAL(jointext(outpost_generator.get_supported_placement_shapes(), "|"), jointext(expected_shapes, "|"), "Outpost generator should expose the full shared World Edit shape catalog.")
	TEST_ASSERT(outpost_generator.supports_placement_direction(), "Outpost generator should keep direction support when the full shape catalog is enabled.")
	TEST_ASSERT_EQUAL(jointext(destruction_generator.get_supported_placement_shapes(), "|"), jointext(expected_shapes, "|"), "Destruction generator should expose the full shared World Edit shape catalog.")
	TEST_ASSERT(destruction_generator.supports_placement_direction(), "Destruction generator should expose direction support for directional shapes.")

/datum/unit_test/world_edit_live_contract/placement_generator_validate_params_are_map_agnostic/Run()
	var/datum/world_edit_generator_definition/outpost_radius/outpost_definition = new
	var/datum/world_edit_generator/outpost_radius/outpost_generator = allocate(/datum/world_edit_generator/outpost_radius)
	TEST_ASSERT(isnull(outpost_generator.validate_params(null, outpost_definition.default_params?.Copy() || list())), "Outpost validate_params should stay map-agnostic without a live user turf.")

	var/datum/world_edit_generator_definition/destruction_pack/destruction_definition = new
	var/datum/world_edit_generator/destruction_pack/destruction_generator = allocate(/datum/world_edit_generator/destruction_pack)
	TEST_ASSERT(isnull(destruction_generator.validate_params(null, destruction_definition.default_params?.Copy() || list())), "Destruction validate_params should stay map-agnostic without a live user turf.")

	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/blueprint_stamp/blueprint_definition = new
	var/datum/world_edit_generator/blueprint_stamp/blueprint_generator = allocate(/datum/world_edit_generator/blueprint_stamp)
	var/list/blueprint = list(
		"id" = "world_edit_validate_params_test",
		"name" = "World Edit Validate Params Test",
		"created_at" = "2026-04-18T00:00:00Z",
		"created_by" = "unit_test",
		"source" = "unit_test",
		"bounds" = list("radius" = 0),
		"entries" = list(
			list(
				"type" = "[/obj/structure/barricade/metal]",
				"dx" = 0,
				"dy" = 0,
				"dz" = 0,
				"dir" = NORTH,
				"vars" = list(),
			),
		),
	)
	var/blueprint_file_path = GLOB.world_edit_blueprints.world_edit_save_blueprint_definition(blueprint)
	TEST_ASSERT(length("[blueprint_file_path]"), "World Edit validate_params test should save the helper blueprint definition.")

	blueprint_generator.attach(manager, blueprint_definition)
	manager.current_definition = blueprint_definition
	manager.current_generator = blueprint_generator
	manager.current_params = blueprint_definition.default_params?.Copy() || list()
	manager.current_params["blueprint_id"] = blueprint["id"]
	manager.blueprint_cache_loaded = TRUE
	manager.blueprint_entries_cache = list(list(
		"id" = blueprint["id"],
		"valid" = TRUE,
		"file_path" = blueprint_file_path,
	))
	TEST_ASSERT(isnull(blueprint_generator.validate_params(null, manager.current_params)), "Blueprint validate_params should stay map-agnostic without a live anchor turf.")

	if(length("[blueprint_file_path]") && fexists(blueprint_file_path))
		fdel(blueprint_file_path)
	qdel(manager)

/datum/unit_test/world_edit_corner_slots/generator_integration/outpost_advertised_shapes_are_never_silent/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/outpost_radius/definition = new
	var/datum/world_edit_generator/outpost_radius/generator = allocate(/datum/world_edit_generator/outpost_radius)
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit outpost integration test center turf was not resolved.")

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.current_params = definition.default_params?.Copy() || list()
	manager.current_params["radius"] = 1
	manager.current_params["place_sentries"] = FALSE

	for(var/shape_id in generator.get_supported_placement_shapes())
		var/list/case_data = build_shape_integration_case(shape_id, center_turf, manager.current_params, EAST)
		var/list/shape_result = case_data["shape_result"]
		var/list/params = case_data["params"]
		var/list/placement_context = case_data["placement_context"]
		TEST_ASSERT(!shape_result["error"], "World Edit outpost integration should build a shared shape result for advertised shape '[shape_id]'.")

		var/shape_support_error = generator.get_shape_support_error(shape_id, shape_result["turfs"] || list(), params, placement_context)
		if(length("[shape_support_error]"))
			continue

		var/datum/world_edit_plan/plan = generator.build_placement_plan(null, params, placement_context)
		TEST_ASSERT(istype(plan), "World Edit outpost integration should return a plan datum or an explicit support error for shape '[shape_id]'.")
		if(plan.metadata["error"])
			continue
		TEST_ASSERT(length(plan.placements) > 0, "World Edit outpost integration should not leave advertised shape '[shape_id]' with a silent empty plan.")

	qdel(manager)

/datum/unit_test/world_edit_corner_slots/generator_integration/blueprint_stamp_advertised_shapes_are_never_silent/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/blueprint_stamp/definition = new
	var/datum/world_edit_generator/blueprint_stamp/generator = allocate(/datum/world_edit_generator/blueprint_stamp)
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit blueprint integration test center turf was not resolved.")

	var/list/blueprint = list(
		"id" = "world_edit_shape_contract_test",
		"name" = "World Edit Shape Contract Test",
		"created_at" = "2026-04-17T00:00:00Z",
		"created_by" = "unit_test",
		"source" = "unit_test",
		"bounds" = list("radius" = 0),
		"entries" = list(
			list(
				"type" = "[/obj/structure/barricade/metal]",
				"dx" = 0,
				"dy" = 0,
				"dz" = 0,
				"dir" = NORTH,
				"vars" = list(),
			),
		),
	)
	var/blueprint_file_path = GLOB.world_edit_blueprints.world_edit_save_blueprint_definition(blueprint)
	TEST_ASSERT(length("[blueprint_file_path]"), "World Edit blueprint integration test should save the helper blueprint definition.")

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.current_params = definition.default_params?.Copy() || list()
	manager.current_params["blueprint_id"] = blueprint["id"]
	manager.blueprint_cache_loaded = TRUE
	manager.blueprint_entries_cache = list(list(
		"id" = blueprint["id"],
		"valid" = TRUE,
		"file_path" = blueprint_file_path,
	))

	for(var/shape_id in generator.get_supported_placement_shapes())
		var/list/case_data = build_shape_integration_case(shape_id, center_turf, manager.current_params, EAST)
		var/list/shape_result = case_data["shape_result"]
		var/list/params = case_data["params"]
		var/list/placement_context = case_data["placement_context"]
		TEST_ASSERT(!shape_result["error"], "World Edit blueprint integration should build a shared shape result for advertised shape '[shape_id]'.")

		var/shape_support_error = generator.get_shape_support_error(shape_id, shape_result["turfs"] || list(), params, placement_context)
		if(length("[shape_support_error]"))
			continue

		var/datum/world_edit_plan/plan = generator.build_placement_plan(null, params, placement_context)
		TEST_ASSERT(istype(plan), "World Edit blueprint integration should return a plan datum or an explicit support error for shape '[shape_id]'.")
		if(plan.metadata["error"])
			continue
		TEST_ASSERT(length(plan.placements) > 0, "World Edit blueprint integration should not leave advertised shape '[shape_id]' with a silent empty plan.")

	if(length("[blueprint_file_path]") && fexists(blueprint_file_path))
		fdel(blueprint_file_path)
	qdel(manager)

/datum/unit_test/world_edit_corner_slots/generator_integration/destruction_pack_advertised_shapes_are_never_silent/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/destruction_pack/definition = new
	var/datum/world_edit_generator/destruction_pack/generator = allocate(/datum/world_edit_generator/destruction_pack)
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit destruction integration test center turf was not resolved.")

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

	for(var/shape_id in generator.get_supported_placement_shapes())
		var/list/case_data = build_shape_integration_case(shape_id, center_turf, manager.current_params, EAST)
		var/list/shape_result = case_data["shape_result"]
		var/list/params = case_data["params"]
		var/list/placement_context = case_data["placement_context"]
		TEST_ASSERT(!shape_result["error"], "World Edit destruction integration should build a shared shape result for advertised shape '[shape_id]'.")

		var/shape_support_error = generator.get_shape_support_error(shape_id, shape_result["turfs"] || list(), params, placement_context)
		if(length("[shape_support_error]"))
			continue

		var/datum/world_edit_plan/plan = generator.build_placement_plan(null, params, placement_context)
		TEST_ASSERT(istype(plan), "World Edit destruction integration should return a plan datum or an explicit support error for shape '[shape_id]'.")
		if(plan.metadata["error"])
			continue
		TEST_ASSERT(length(plan.placements) > 0 || length(plan.deletions) > 0, "World Edit destruction integration should not leave advertised shape '[shape_id]' with a silent empty plan.")

	qdel(manager)

/datum/unit_test/world_edit_corner_slots/shape_geometry/line_rectangles_and_fill_contracts/Run()
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit geometry test center turf was not resolved.")
	var/turf/end_turf = locate(center_turf.x + 3, center_turf.y, center_turf.z)
	TEST_ASSERT_NOTNULL(end_turf, "World Edit geometry test end turf was not resolved.")

	var/list/line_params = list(
		"shape_line_length" = 4,
		"shape_line_spacing" = 1,
		"shape_radius" = 9,
	)
	var/list/line_result = build_shape_result("line", center_turf, line_params, EAST, end_turf)
	TEST_ASSERT(!line_result["error"], "World Edit line test should build a line footprint.")
	TEST_ASSERT_EQUAL(line_result["degenerate_kind"], "", "World Edit line test should not degenerate when the end turf resolves four tiles.")
	var/list/line_lookup = build_relative_turf_lookup(line_result["turfs"], center_turf)
	TEST_ASSERT(line_lookup["0,0"] && line_lookup["1,0"] && line_lookup["2,0"] && line_lookup["3,0"], "World Edit line footprint should ignore shape_radius and keep only the resolved line tiles.")

	var/list/spaced_params = line_params.Copy()
	spaced_params["shape_line_spacing"] = 2
	var/list/spaced_line_result = build_shape_result("line", center_turf, spaced_params, EAST, end_turf)
	var/list/spaced_lookup = build_relative_turf_lookup(spaced_line_result["turfs"], center_turf)
	TEST_ASSERT_EQUAL(length(spaced_line_result["turfs"]), 2, "World Edit line spacing should keep every second tile on the resolved line.")
	TEST_ASSERT(spaced_lookup["0,0"] && spaced_lookup["2,0"], "World Edit line spacing should preserve ordered subsampling of the base line.")

	var/list/rect_point_result = build_shape_result("rectangle", center_turf, list("shape_rect_width" = 1, "shape_rect_height" = 1))
	TEST_ASSERT_EQUAL(rect_point_result["degenerate_kind"], "point", "World Edit rectangle 1x1 should collapse to a point.")
	TEST_ASSERT_EQUAL(length(rect_point_result["turfs"]), 1, "World Edit rectangle 1x1 should keep exactly one turf.")

	var/list/rect_line_result = build_shape_result("rectangle", center_turf, list("shape_rect_width" = 1, "shape_rect_height" = 3))
	TEST_ASSERT_EQUAL(rect_line_result["degenerate_kind"], "line", "World Edit rectangle 1xN should collapse to a line.")
	TEST_ASSERT_EQUAL(length(rect_line_result["turfs"]), 3, "World Edit rectangle 1xN should keep the thin border as a line footprint.")

	var/list/filled_rect_result = build_shape_result("filled_rectangle", center_turf, list("shape_rect_width" = 3, "shape_rect_height" = 3))
	TEST_ASSERT(!filled_rect_result["error"], "World Edit filled rectangle test should build a footprint.")
	TEST_ASSERT(filled_rect_result["is_filled"], "World Edit filled rectangle should report a filled footprint.")
	TEST_ASSERT_EQUAL(length(filled_rect_result["turfs"]), 9, "World Edit filled rectangle 3x3 should keep the full area.")

/datum/unit_test/world_edit_corner_slots/shape_geometry/degenerate_area_contracts/Run()
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit degenerate-area test center turf was not resolved.")

	var/list/circle_result = build_shape_result("circle", center_turf, list("shape_radius" = 0))
	TEST_ASSERT_EQUAL(circle_result["degenerate_kind"], "point", "World Edit circle radius 0 should collapse to a point.")

	var/list/ring_result = build_shape_result("ring", center_turf, list("shape_radius" = 0, "shape_thickness" = 5))
	TEST_ASSERT_EQUAL(ring_result["degenerate_kind"], "point", "World Edit ring radius 0 should collapse to a point.")

	var/list/ellipse_point_result = build_shape_result("ellipse", center_turf, list("shape_radius_x" = 0, "shape_radius_y" = 0))
	TEST_ASSERT_EQUAL(ellipse_point_result["degenerate_kind"], "point", "World Edit ellipse 0/0 should collapse to a point.")
	var/list/ellipse_line_result = build_shape_result("ellipse", center_turf, list("shape_radius_x" = 3, "shape_radius_y" = 0))
	TEST_ASSERT_EQUAL(ellipse_line_result["degenerate_kind"], "line", "World Edit ellipse N/0 should collapse to a line.")

	var/list/diamond_result = build_shape_result("diamond", center_turf, list("shape_radius" = 0))
	TEST_ASSERT_EQUAL(diamond_result["degenerate_kind"], "point", "World Edit diamond radius 0 should collapse to a point.")

	var/list/triangle_result = build_shape_result("triangle", center_turf, list("shape_triangle_size" = 0))
	TEST_ASSERT_EQUAL(triangle_result["degenerate_kind"], "point", "World Edit triangle size 0 should collapse to a point.")

	var/list/sector_result = build_shape_result("sector", center_turf, list("shape_radius" = 0, "shape_sector_angle" = 30), EAST)
	TEST_ASSERT_EQUAL(sector_result["degenerate_kind"], "point", "World Edit sector radius 0 should collapse to a point.")

/datum/unit_test/world_edit_corner_slots/shape_geometry/freeform_contracts/Run()
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit freeform test center turf was not resolved.")

	var/list/polygon_result = build_shape_result("polygon", center_turf, list(
		"shape_points_text" = "0,0; 2,0; 2,2; 2,2; 0,2",
		"shape_polygon_filled" = TRUE,
	))
	TEST_ASSERT(!polygon_result["error"], "World Edit polygon test should build a closed footprint.")
	TEST_ASSERT(polygon_result["is_closed"], "World Edit polygon should stay closed.")
	TEST_ASSERT(polygon_result["is_filled"], "World Edit polygon filled flag should be preserved.")
	var/list/polygon_metadata = polygon_result["metadata"]
	var/list/polygon_layers = polygon_metadata["preview_layers"]
	TEST_ASSERT_EQUAL(polygon_metadata["custom_point_count"], 4, "World Edit polygon should normalize repeated consecutive points.")
	TEST_ASSERT(length(polygon_layers["closure_turfs"]) > 0, "World Edit polygon preview should keep a closure edge.")
	var/list/polygon_lookup = build_relative_turf_lookup(polygon_result["turfs"], center_turf)
	TEST_ASSERT(polygon_lookup["1,1"], "World Edit filled polygon should include interior tiles.")

	var/list/polyline_result = build_shape_result("polyline", center_turf, list("shape_points_text" = "0,0; 2,0; 2,2"))
	TEST_ASSERT(!polyline_result["is_closed"], "World Edit polyline should stay open.")
	TEST_ASSERT(!polyline_result["is_filled"], "World Edit polyline should never be filled.")
	var/list/polyline_metadata = polyline_result["metadata"]
	var/list/polyline_layers = polyline_metadata["preview_layers"]
	TEST_ASSERT_EQUAL(length(polyline_layers["closure_turfs"]), 0, "World Edit polyline preview should not emit closure tiles.")

	var/list/custom_mask_result = build_shape_result("custom_mask", center_turf, list("shape_points_text" = "0,0; 2,0; 2,2; 2,0"))
	TEST_ASSERT(!custom_mask_result["error"], "World Edit custom mask should keep exact point masks.")
	TEST_ASSERT_EQUAL(length(custom_mask_result["turfs"]), 3, "World Edit custom mask should dedupe exact points without drawing edges.")
	var/list/custom_mask_metadata = custom_mask_result["metadata"]
	var/list/custom_mask_layers = custom_mask_metadata["preview_layers"]
	TEST_ASSERT_EQUAL(length(custom_mask_layers["edge_turfs"]), 0, "World Edit custom mask preview should not emit edge tiles.")

/datum/unit_test/world_edit_corner_slots/shape_geometry/brush_and_scatter_contracts/Run()
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit brush/scatter test center turf was not resolved.")

	var/list/brush_result = build_shape_result("brush_path", center_turf, list(
		"shape_points_text" = "0,0; 2,0; 2,2",
		"shape_brush_radius" = 0,
	))
	TEST_ASSERT(!brush_result["error"], "World Edit brush-path radius 0 should still build a path footprint.")
	TEST_ASSERT(!brush_result["is_filled"], "World Edit brush-path radius 0 should behave like a path footprint, not a filled area.")
	var/list/brush_lookup = build_relative_turf_lookup(brush_result["turfs"], center_turf)
	TEST_ASSERT(brush_lookup["1,0"] && brush_lookup["2,1"], "World Edit brush-path radius 0 should keep the polyline path tiles.")

	var/list/scatter_result = build_shape_result("scatter_cluster", center_turf, list(
		"shape_scatter_radius" = 0,
		"shape_scatter_count" = 5,
		"shape_scatter_seed" = 0,
	))
	TEST_ASSERT(!scatter_result["error"], "World Edit scatter-cluster radius 0 should keep a valid degenerate footprint.")
	TEST_ASSERT_EQUAL(length(scatter_result["turfs"]), 1, "World Edit scatter-cluster radius 0 should collapse to one deduped point.")
	TEST_ASSERT_EQUAL(scatter_result["degenerate_kind"], "point", "World Edit scatter-cluster radius 0 should report point degeneration.")
	TEST_ASSERT((scatter_result["metadata"]["seed"] || 0) > 0, "World Edit scatter-cluster auto seed should resolve to a deterministic non-zero seed.")

/datum/unit_test/world_edit_corner_slots/shape_geometry/shape_contract_service_builds_preview_model/Run()
	var/turf/center_turf = get_world_edit_test_center_turf()
	var/turf/end_turf = locate(center_turf.x + 3, center_turf.y, center_turf.z)
	TEST_ASSERT_NOTNULL(center_turf, "World Edit shape-contract service test center turf was not resolved.")
	TEST_ASSERT_NOTNULL(end_turf, "World Edit shape-contract service test end turf was not resolved.")

	var/datum/world_edit_shape_contract/shape_contract = GLOB.world_edit_shape_geometry.build_shape_contract(WORLD_EDIT_SHAPE_LINE, center_turf, end_turf, list("shape_line_spacing" = 1), EAST)
	TEST_ASSERT(istype(shape_contract), "World Edit shape-contract service should return a shape contract datum.")
	TEST_ASSERT_EQUAL(shape_contract.shape_id, WORLD_EDIT_SHAPE_LINE, "World Edit shape-contract service should preserve the requested shape id.")
	TEST_ASSERT_EQUAL(shape_contract.interaction_kind, "anchor_pair", "World Edit shape-contract service should expose the interaction kind.")
	TEST_ASSERT(length(shape_contract.anchor_turfs) > 0, "World Edit shape-contract service should keep the resolved footprint turfs.")

	var/datum/world_edit_preview_model/preview_model = GLOB.world_edit_shape_preview.build_shape_preview(shape_contract)
	TEST_ASSERT(istype(preview_model), "World Edit preview-model service should return a preview model datum.")
	TEST_ASSERT(length(preview_model.anchor_turfs) > 0, "World Edit preview-model service should expose anchor tiles.")
	TEST_ASSERT(length(preview_model.edge_turfs) > 0, "World Edit preview-model service should expose edge tiles.")
	TEST_ASSERT(length(preview_model.final_turfs) > 0, "World Edit preview-model service should expose final footprint tiles.")

/datum/unit_test/world_edit_corner_slots/manager_runtime/locked_preview_ignores_pending_hover_and_click_updates/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/world_edit_test_apply_hook/definition = new
	var/datum/world_edit_generator/world_edit_test_apply_hook/generator = allocate(/datum/world_edit_generator/world_edit_test_apply_hook)
	var/turf/center_turf = get_world_edit_test_center_turf()
	var/turf/other_turf = locate(center_turf.x + 2, center_turf.y + 1, center_turf.z)
	TEST_ASSERT_NOTNULL(center_turf, "World Edit locked-preview test center turf was not resolved.")
	TEST_ASSERT_NOTNULL(other_turf, "World Edit locked-preview test alternate turf was not resolved.")
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, center_turf)

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.current_params = definition.default_params?.Copy() || list()
	manager.placement_shape = WORLD_EDIT_SHAPE_POINT
	manager.placement_mode = "single"
	manager.placement_dir = EAST
	manager.placement_click_active = TRUE

	TEST_ASSERT(manager.evaluate_safe_placement_preview(user, WORLD_EDIT_SHAPE_POINT, center_turf, center_turf, null, "", TRUE), "World Edit locked-preview test should resolve a point preview before locking it.")
	var/datum/world_edit_placement_candidate/locked_candidate = manager.get_placement_preview_candidate()
	TEST_ASSERT(istype(locked_candidate), "World Edit locked-preview test should keep the resolved preview candidate in session state.")
	TEST_ASSERT(manager.placement_hover_turf == center_turf, "World Edit locked-preview test should keep the confirmed turf as the preview hover anchor.")

	manager.set_placement_preview_locked(TRUE, center_turf)
	TEST_ASSERT(manager.is_placement_preview_locked(), "World Edit locked-preview test should expose the pending-confirmation lock flag.")
	TEST_ASSERT(manager.handle_safe_placement_hover(user, other_turf), "World Edit locked-preview test should swallow hover updates while confirmation is pending.")
	TEST_ASSERT(manager.handle_safe_placement_click_v2(user, list2params(list(LEFT_CLICK = 1)), other_turf), "World Edit locked-preview test should swallow click updates while confirmation is pending.")
	TEST_ASSERT(manager.placement_hover_turf == center_turf, "World Edit locked-preview test should keep the preview fixed on the confirmed turf while locked.")
	TEST_ASSERT(manager.get_placement_preview_candidate() == locked_candidate, "World Edit locked-preview test should keep the original preview candidate while locked.")
	TEST_ASSERT_EQUAL(generator.apply_calls, 0, "World Edit locked-preview test should not apply anything while the preview is locked for confirmation.")

	manager.set_placement_preview_locked(FALSE)
	qdel(manager)

/datum/unit_test/world_edit_corner_slots/manager_runtime/standard_preview_reuses_placement_layers/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/world_edit_test_apply_hook/definition = new
	var/datum/world_edit_generator/world_edit_test_apply_hook/generator = allocate(/datum/world_edit_generator/world_edit_test_apply_hook)
	var/turf/center_turf = get_world_edit_test_center_turf()
	var/turf/end_turf = locate(center_turf.x + 3, center_turf.y, center_turf.z)
	TEST_ASSERT_NOTNULL(center_turf, "World Edit standard-preview layer test center turf was not resolved.")
	TEST_ASSERT_NOTNULL(end_turf, "World Edit standard-preview layer test end turf was not resolved.")

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.current_params = definition.default_params?.Copy() || list()
	manager.placement_shape = WORLD_EDIT_SHAPE_LINE
	manager.placement_mode = "single"
	manager.placement_dir = EAST

	var/list/effective_params = manager.build_effective_generator_params()
	var/list/shape_result = GLOB.world_edit_placement_shapes.world_edit_build_shape_turfs(WORLD_EDIT_SHAPE_LINE, center_turf, end_turf, effective_params, EAST)
	TEST_ASSERT(!shape_result["error"], "World Edit standard-preview layer test should resolve the shared line footprint.")

	var/datum/world_edit_plan/plan = manager.build_safe_placement_plan_from_shape_result(null, WORLD_EDIT_SHAPE_LINE, shape_result, center_turf, end_turf)
	TEST_ASSERT(istype(plan), "World Edit standard-preview layer test should build a placement plan from the shared shape result.")
	plan.metadata["center_turf"] = center_turf
	TEST_ASSERT(islist(plan.metadata["shape_result"]), "World Edit standard-preview layer test should keep the canonical shape snapshot on the plan metadata.")

	TEST_ASSERT(manager.render_plan_preview_with_placement_layers(null, plan, effective_params), "World Edit standard-preview layer test should build grouped placement layers from a normal preview plan.")
	var/datum/world_edit_placement_candidate/preview_candidate = manager.get_placement_preview_candidate()
	TEST_ASSERT(istype(preview_candidate), "World Edit standard-preview layer test should store the synthesized placement candidate.")
	TEST_ASSERT(preview_candidate.plan == plan, "World Edit standard-preview layer test should keep the original preview plan on the synthesized candidate.")
	TEST_ASSERT(preview_candidate.placement_context["start_turf"] == center_turf, "World Edit standard-preview layer test should keep the original shape origin on the synthesized candidate.")
	TEST_ASSERT(preview_candidate.placement_context["resolved_end_turf"] == end_turf, "World Edit standard-preview layer test should restore the resolved shape endpoint from plan metadata.")
	TEST_ASSERT(length(manager.placement_preview_anchor_turfs) > 0, "World Edit standard-preview layer test should expose anchor tiles.")
	TEST_ASSERT(length(manager.placement_preview_edge_turfs) > 0, "World Edit standard-preview layer test should expose edge tiles.")
	TEST_ASSERT(length(manager.placement_preview_final_turfs) > 0, "World Edit standard-preview layer test should expose final footprint tiles.")
	TEST_ASSERT(length(manager.placement_preview_generator_effect_turfs) > 0, "World Edit standard-preview layer test should expose generator effect tiles.")

	qdel(manager)

/datum/unit_test/world_edit_corner_slots/manager_runtime/preview_layers_follow_shape_semantics_and_cleanup/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/world_edit_test_apply_hook/definition = new
	var/datum/world_edit_generator/world_edit_test_apply_hook/generator = allocate(/datum/world_edit_generator/world_edit_test_apply_hook)
	var/turf/center_turf = get_world_edit_test_center_turf()
	var/turf/end_turf = locate(center_turf.x + 3, center_turf.y, center_turf.z)
	var/turf/hover_turf = locate(center_turf.x + 2, center_turf.y + 2, center_turf.z)
	TEST_ASSERT_NOTNULL(center_turf, "World Edit manager preview test center turf was not resolved.")
	TEST_ASSERT_NOTNULL(end_turf, "World Edit manager preview test end turf was not resolved.")
	TEST_ASSERT_NOTNULL(hover_turf, "World Edit manager preview test hover turf was not resolved.")

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.current_params = definition.default_params?.Copy() || list()

	TEST_ASSERT(manager.evaluate_safe_placement_preview(null, "line", center_turf, end_turf, null, "", TRUE), "World Edit manager preview test should build an anchor-pair preview.")
	TEST_ASSERT(manager.placement_hover_turf == end_turf, "World Edit manager preview should store the current hover turf.")
	var/datum/world_edit_placement_candidate/preview_candidate = manager.get_placement_preview_candidate()
	TEST_ASSERT(istype(preview_candidate, /datum/world_edit_placement_candidate), "World Edit manager preview should store the resolved placement candidate in session state.")
	TEST_ASSERT(istype(preview_candidate.plan, /datum/world_edit_plan), "World Edit manager preview should keep the resolved plan on the placement candidate.")
	TEST_ASSERT(isnull(generator.current_plan), "World Edit safe placement preview should no longer rely on generator.current_plan as preview-session state.")
	TEST_ASSERT(length(manager.placement_preview_anchor_turfs) > 0, "World Edit manager preview should keep anchor preview tiles.")
	TEST_ASSERT(length(manager.placement_preview_edge_turfs) > 0, "World Edit manager preview should keep skeleton edge tiles.")
	TEST_ASSERT(length(manager.placement_preview_final_turfs) > 0, "World Edit manager preview should keep the final shape footprint.")
	TEST_ASSERT(length(manager.placement_preview_generator_effect_turfs) > 0, "World Edit manager preview should keep generator effect tiles separate from the shape footprint.")

	manager.placement_shape = "polygon"
	manager.set_placement_collector_origin_turf(center_turf)
	manager.set_placement_collector_points(list(
		list("x" = 0, "y" = 0),
		list("x" = 2, "y" = 0),
	))
	TEST_ASSERT(manager.update_placement_collector_runtime_state_v2(null, hover_turf, "", TRUE, TRUE), "World Edit manager preview should build a hover-time polygon collector preview.")
	TEST_ASSERT(length(manager.placement_preview_closure_turfs) > 0, "World Edit polygon collector preview should expose closure tiles on hover.")

	manager.placement_shape = "polyline"
	TEST_ASSERT(manager.update_placement_collector_runtime_state_v2(null, hover_turf, "", TRUE, TRUE), "World Edit manager preview should build a hover-time polyline collector preview.")
	TEST_ASSERT_EQUAL(length(manager.placement_preview_closure_turfs), 0, "World Edit polyline collector preview should not expose closure tiles.")

	manager.placement_shape = "custom_mask"
	manager.set_placement_collector_points(list(
		list("x" = 0, "y" = 0),
		list("x" = 2, "y" = 0),
		list("x" = 2, "y" = 2),
	))
	TEST_ASSERT(manager.update_placement_collector_runtime_state_v2(null, hover_turf, "", TRUE, FALSE), "World Edit manager preview should build a custom-mask collector preview.")
	TEST_ASSERT_EQUAL(length(manager.placement_preview_edge_turfs), 0, "World Edit custom-mask collector preview should not expose edge tiles.")

	manager.reset_placement_runtime()
	TEST_ASSERT(isnull(manager.placement_hover_turf), "World Edit manager reset should clear the hover turf.")
	TEST_ASSERT_EQUAL(length(manager.placement_preview_anchor_turfs), 0, "World Edit manager reset should clear anchor preview tiles.")
	TEST_ASSERT_EQUAL(length(manager.placement_preview_generator_effect_turfs), 0, "World Edit manager reset should clear generator effect preview tiles.")

	qdel(manager)

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

/datum/unit_test/world_edit_corner_slots/outpost_connected_freeform_shapes_build_shape_aware_plans/Run()
	var/datum/world_edit_generator/outpost_radius/generator = allocate(/datum/world_edit_generator/outpost_radius)
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit outpost connected-freeform test center turf was not resolved.")

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
	)
	for(var/shape_id in list(WORLD_EDIT_SHAPE_POLYLINE, WORLD_EDIT_SHAPE_CUSTOM_MASK, WORLD_EDIT_SHAPE_BRUSH_PATH, WORLD_EDIT_SHAPE_SCATTER_CLUSTER))
		var/list/case_data = build_shape_integration_case(shape_id, center_turf, params, NORTH)
		var/list/shape_result = case_data["shape_result"]
		var/list/case_params = case_data["params"]
		var/list/placement_context = case_data["placement_context"]
		TEST_ASSERT(!shape_result["error"], "World Edit outpost connected-freeform test should build a shared shape result for '[shape_id]'.")

		var/shape_error = generator.get_shape_support_error(shape_id, shape_result["turfs"] || list(), case_params, placement_context)
		TEST_ASSERT(isnull(shape_error), "World Edit outpost should accept connected freeform shape '[shape_id]' instead of rejecting it at the support boundary.")

		var/datum/world_edit_plan/plan = generator.build_placement_plan(null, case_params, placement_context)
		TEST_ASSERT(!plan.metadata["error"], "World Edit outpost should build a shape-aware plan for connected freeform shape '[shape_id]'.")
		TEST_ASSERT(length(plan.placements) > 0, "World Edit outpost should not leave connected freeform shape '[shape_id]' with an empty plan.")

	qdel(generator)

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
	TEST_ASSERT_EQUAL(shape_error, "Выбранный контур размещения не поддерживает обязательные проходы форпоста.", "World Edit outpost shape validation should reject footprints that cannot satisfy required openings.")

/datum/unit_test/world_edit_corner_slots/outpost_point_support_respects_clicked_footprint_policy/Run()
	var/datum/world_edit_generator/outpost_radius/generator = allocate(/datum/world_edit_generator/outpost_radius)
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit outpost point-footprint policy test center turf was not resolved.")

	var/obj/structure/window/test_window = allocate(/obj/structure/window, center_turf)
	TEST_ASSERT_NOTNULL(test_window, "World Edit outpost point-footprint policy test should create a window blocker on the clicked turf.")

	var/list/params = list(
		"family" = "metal_perimeter",
		"layout_variant" = "crossroads",
		"opening_width" = "profile",
		"radius" = 2,
		"barricade_path" = /datum/human_ai_defense/barricade/metal,
		"barricade_pattern" = "profile",
		"place_sentries" = FALSE,
		"guard_mode" = "layout",
		"sentry_path" = /datum/human_ai_defense/defense/sentry/uscm,
		"faction" = FACTION_MARINE,
		"turned_on" = TRUE,
		"radius_only_clear_tiles" = TRUE,
		"radius_only_reachable_tiles" = FALSE,
		"radius_windows_blockers" = TRUE,
	)

	var/shape_error = generator.get_shape_support_error(WORLD_EDIT_SHAPE_POINT, list(center_turf), params, list(
		"mode" = "single",
		"shape" = WORLD_EDIT_SHAPE_POINT,
		"shape_metadata" = list(),
		"anchor_turfs" = list(center_turf),
		"start_turf" = center_turf,
		"end_turf" = center_turf,
		"shape_origin_turf" = center_turf,
		"seed_turf" = center_turf,
		"requested_end_turf" = center_turf,
		"resolved_end_turf" = center_turf,
		"direction" = NORTH,
	))
	TEST_ASSERT(isnull(shape_error), "World Edit outpost point validation should keep a blocked clicked tile valid and let radius filtering cut only the expansion behind blockers.")

	qdel(test_window)

/datum/unit_test/world_edit_corner_slots/outpost_radius_policy_keeps_blocked_candidate_tiles_with_clear_approach/Run()
	var/datum/world_edit_generator/outpost_radius/generator = allocate(/datum/world_edit_generator/outpost_radius)
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit outpost blocked-candidate test center turf was not resolved.")

	var/turf/blocked_candidate_turf = locate(center_turf.x + 1, center_turf.y, center_turf.z)
	var/turf/far_candidate_turf = locate(center_turf.x + 2, center_turf.y, center_turf.z)
	TEST_ASSERT_NOTNULL(blocked_candidate_turf, "World Edit outpost blocked-candidate test adjacent turf was not resolved.")
	TEST_ASSERT_NOTNULL(far_candidate_turf, "World Edit outpost blocked-candidate test far turf was not resolved.")

	var/obj/structure/window/test_window = allocate(/obj/structure/window, blocked_candidate_turf)
	TEST_ASSERT_NOTNULL(test_window, "World Edit outpost blocked-candidate test should create a blocking window on the candidate turf.")

	var/list/policy = list(
		"only_clear_tiles" = TRUE,
		"only_reachable_tiles" = FALSE,
		"treat_windows_as_blockers" = TRUE,
	)
	var/list/allowed_blocked_candidate = generator.filter_outpost_candidate_turfs(
		list(center_turf),
		list(blocked_candidate_turf),
		list(center_turf, blocked_candidate_turf),
		policy,
		list(center_turf),
	)
	TEST_ASSERT(blocked_candidate_turf in allowed_blocked_candidate, "World Edit outpost radius-policy filtering should keep a blocked candidate tile when the approach from the drawing start is still clear.")

	qdel(test_window)
	var/obj/structure/barricade/metal/test_barrier = allocate(/obj/structure/barricade/metal, blocked_candidate_turf)
	TEST_ASSERT_NOTNULL(test_barrier, "World Edit outpost blocked-candidate test should create a blocker between the start and the far tile.")

	var/list/blocked_far_candidate = generator.filter_outpost_candidate_turfs(
		list(center_turf),
		list(far_candidate_turf),
		list(center_turf, blocked_candidate_turf, far_candidate_turf),
		policy,
		list(center_turf),
	)
	TEST_ASSERT(!(far_candidate_turf in blocked_far_candidate), "World Edit outpost radius-policy filtering should still drop tiles that sit behind a blocker line from the drawing start.")

	qdel(test_barrier)

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

/datum/unit_test/world_edit_corner_slots/destruction_connected_freeform_shapes_build_plans/Run()
	var/datum/world_edit_generator/destruction_pack/generator = allocate(/datum/world_edit_generator/destruction_pack)
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit destruction connected-freeform test center turf was not resolved.")

	var/list/params = list(
		"radius" = 2,
		"shuffle_enabled" = FALSE,
		"scatter_enabled" = FALSE,
		"persistent_fire_enabled" = TRUE,
		"persistent_fire_density" = 100,
		"blast_enabled" = FALSE,
		"damage_profile" = "none",
	)
	for(var/shape_id in list(WORLD_EDIT_SHAPE_POLYLINE, WORLD_EDIT_SHAPE_CUSTOM_MASK, WORLD_EDIT_SHAPE_BRUSH_PATH, WORLD_EDIT_SHAPE_SCATTER_CLUSTER))
		var/list/case_data = build_shape_integration_case(shape_id, center_turf, params, EAST)
		var/list/shape_result = case_data["shape_result"]
		var/list/case_params = case_data["params"]
		var/list/placement_context = case_data["placement_context"]
		TEST_ASSERT(!shape_result["error"], "World Edit destruction connected-freeform test should build a shared shape result for '[shape_id]'.")

		var/shape_error = generator.get_shape_support_error(shape_id, shape_result["turfs"] || list(), case_params, placement_context)
		TEST_ASSERT(isnull(shape_error), "World Edit destruction should accept freeform shape '[shape_id]' at the support boundary.")

		var/datum/world_edit_plan/plan = generator.build_placement_plan(null, case_params, placement_context)
		TEST_ASSERT(!plan.metadata["error"], "World Edit destruction should build a plan for freeform shape '[shape_id]'.")
		TEST_ASSERT(length(plan.placements) > 0 || length(plan.deletions) > 0, "World Edit destruction should not leave freeform shape '[shape_id]' with an empty plan.")

	qdel(generator)

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

/datum/unit_test/world_edit_corner_slots/destruction_radius_policy_blocks_tiles_behind_windows/Run()
	var/datum/world_edit_generator/destruction_pack/generator = allocate(/datum/world_edit_generator/destruction_pack)
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit destruction radius-policy test center turf was not resolved.")
	var/turf/window_turf = locate(center_turf.x + 1, center_turf.y, center_turf.z)
	var/turf/far_turf = locate(center_turf.x + 2, center_turf.y, center_turf.z)
	TEST_ASSERT_NOTNULL(window_turf, "World Edit destruction radius-policy test window turf was not resolved.")
	TEST_ASSERT_NOTNULL(far_turf, "World Edit destruction radius-policy test far turf was not resolved.")

	var/obj/structure/window/test_window = allocate(/obj/structure/window, window_turf)
	TEST_ASSERT_NOTNULL(test_window, "World Edit destruction radius-policy test should create a window blocker.")

	var/list/blocked_map = generator.build_influence_map(
		list(center_turf),
		2,
		list(
			"only_clear_tiles" = TRUE,
			"only_reachable_tiles" = TRUE,
			"treat_windows_as_blockers" = TRUE,
		),
	)
	var/list/unblocked_map = generator.build_influence_map(
		list(center_turf),
		2,
		list(
			"only_clear_tiles" = TRUE,
			"only_reachable_tiles" = TRUE,
			"treat_windows_as_blockers" = FALSE,
		),
	)
	TEST_ASSERT(!(far_turf in (blocked_map["lookup"] || list())), "World Edit destruction reachable radius should stop behind window blockers.")
	TEST_ASSERT(far_turf in (unblocked_map["lookup"] || list()), "World Edit destruction reachable radius should continue through windows when window blocking is disabled.")

	qdel(test_window)

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
