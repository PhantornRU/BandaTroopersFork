/datum/unit_test/proc/get_world_edit_test_center_turf() as /turf
	var/center_x = round((run_loc_floor_bottom_left.x + run_loc_floor_top_right.x) / 2)
	var/center_y = round((run_loc_floor_bottom_left.y + run_loc_floor_top_right.y) / 2)
	return locate(center_x, center_y, run_loc_floor_bottom_left.z)

/datum/unit_test/world_edit_corner_slots
	var/list/tracked_fortify_room_contexts

/datum/unit_test/world_edit_corner_slots/New()
	. = ..()
	tracked_fortify_room_contexts = list()

/datum/unit_test/world_edit_corner_slots/Destroy()
	for(var/list/room_context as anything in tracked_fortify_room_contexts)
		cleanup_fortify_test_room(room_context)

	tracked_fortify_room_contexts = null
	return ..()

/datum/unit_test/world_edit_corner_slots/proc/track_fortify_test_room(list/context)
	if(!islist(context))
		return context

	if(!islist(tracked_fortify_room_contexts))
		tracked_fortify_room_contexts = list()
	tracked_fortify_room_contexts += list(context)
	return context

/datum/unit_test/world_edit_corner_slots/proc/build_runtime_status_lookup(list/runtime_status_entries)
	var/list/lookup = list()
	if(!islist(runtime_status_entries))
		return lookup

	for(var/list/entry as anything in runtime_status_entries)
		if(!islist(entry))
			continue
		var/label = "[entry["label"]]"
		if(!length(label))
			continue
		lookup[label] = "[entry["value"]]"
	return lookup

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

/datum/unit_test/world_edit_corner_slots/proc/build_blueprint_relative_slot_lookup(list/entries)
	var/list/lookup = list()
	if(!islist(entries))
		return lookup

	var/barricade_prefix = "/obj/structure/barricade/"
	for(var/list/entry as anything in entries)
		if(!islist(entry) || copytext("[entry["type"]]", 1, length(barricade_prefix) + 1) != barricade_prefix)
			continue
		var/dx = text2num("[entry["dx"]]")
		var/dy = text2num("[entry["dy"]]")
		var/dir_value = text2num("[entry["dir"]]")
		lookup["[dx],[dy],[dir_value]"] = TRUE
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

/datum/unit_test/world_edit_corner_slots/proc/build_outpost_test_params(defense_profile = "none", layout_variant = "crossroads", opening_width = "layout", radius = 1)
	return list(
		"defense_profile" = defense_profile,
		"layout_variant" = layout_variant,
		"opening_width" = opening_width,
		"radius" = radius,
		"primary_material_path" = /datum/human_ai_defense/barricade/metal,
		"secondary_material_path" = /datum/human_ai_defense/barricade/metal,
		"primary_material_share_percent" = 100,
		"place_barricade_doors" = FALSE,
		"primary_door_path" = "follow_material",
		"secondary_door_path" = "follow_material",
		"barricade_pattern" = "uniform",
		"faction" = FACTION_MARINE,
		"turned_on" = TRUE,
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
	var/build_plan_calls = 0

/datum/world_edit_manager/world_edit_test_cache_probe
	var/build_placement_candidate_calls = 0

/datum/world_edit_manager/world_edit_test_cache_probe/build_placement_candidate(datum/world_edit_shape_contract/shape_contract, list/placement_context, datum/world_edit_plan/plan = null, list/runtime_params = null, hover_only = FALSE, list/collector_state_summary = null)
	build_placement_candidate_calls++
	return ..()

/datum/world_edit_generator/world_edit_test_apply_hook/build_placement_plan(mob/user, list/params, list/placement_context)
	build_plan_calls++
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

/datum/world_edit_generator_definition/world_edit_test_rebuild_failure_hook
	id = "world_edit_test_rebuild_failure_hook"
	name_ru = "World Edit Test Rebuild Failure Hook"
	category_ru = "Tests"
	description_ru = "Unit-test helper definition for live rebuild failure handling."
	required_rights = R_DEBUG
	supports_preview = TRUE
	execution_mode = "batch"
	generator_type = /datum/world_edit_generator/world_edit_test_rebuild_failure_hook
	default_params = list(
		"radius" = 1,
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

/datum/world_edit_generator/world_edit_test_rebuild_failure_hook
	parent_type = /datum/world_edit_generator/world_edit_test_apply_hook

/datum/world_edit_generator/world_edit_test_rebuild_failure_hook/build_placement_plan(mob/user, list/params, list/placement_context)
	var/radius = text2num("[params["radius"]]")
	if(isnum(radius) && radius < 0)
		var/datum/world_edit_plan/error_plan = new
		error_plan.metadata["error"] = "Unit test rejected live rebuild."
		return error_plan
	return ..()

/datum/world_edit_generator_definition/world_edit_test_support_plan_hook
	id = "world_edit_test_support_plan_hook"
	name_ru = "World Edit Test Support Plan Hook"
	category_ru = "Tests"
	description_ru = "Unit-test helper definition for support-result plan reuse coverage."
	required_rights = R_DEBUG
	supports_preview = TRUE
	execution_mode = "batch"
	generator_type = /datum/world_edit_generator/world_edit_test_support_plan_hook
	default_params = list(
		"shape_line_length" = 4,
		"shape_line_spacing" = 1,
	)
	status = "draft"

/datum/world_edit_generator/world_edit_test_support_plan_hook
	parent_type = /datum/world_edit_generator/world_edit_test_apply_hook
	var/support_plan_calls = 0
	var/build_plan_from_shape_contract_calls = 0

/datum/world_edit_generator/world_edit_test_support_plan_hook/evaluate_shape_contract(datum/world_edit_shape_contract/shape_contract, list/params, list/placement_context)
	support_plan_calls++
	var/datum/world_edit_plan/plan = new
	var/list/anchor_turfs = shape_contract?.copy_anchor_turfs() || placement_context["anchor_turfs"] || list()
	if(!length(anchor_turfs))
		return list(
			"support_class" = "full",
			"error" = "Unit test support-plan hook is missing anchors.",
			"metadata" = list("shape_support_class" = "full"),
		)

	for(var/turf/anchor_turf as anything in anchor_turfs)
		if(!istype(anchor_turf))
			continue
		plan.placements += list(list(
			"kind" = "test",
			"turf" = anchor_turf,
			"dir" = placement_context["direction"] || NORTH,
		))
		plan.affected_turfs += anchor_turf

	plan.metadata["center_turf"] = placement_context["end_turf"] || placement_context["start_turf"]
	plan.metadata["entry_count"] = length(plan.placements)
	return list(
		"support_class" = "full",
		"error" = null,
		"metadata" = list(
			"shape_support_class" = "full",
			"shape_effective_id" = "[shape_contract?.shape_id || placement_context["shape"] || WORLD_EDIT_SHAPE_POINT]",
		),
		"plan" = plan,
	)

/datum/world_edit_generator/world_edit_test_support_plan_hook/build_plan_from_shape_contract(mob/user, datum/world_edit_shape_contract/shape_contract, list/params, list/placement_context)
	build_plan_from_shape_contract_calls++
	return ..()

/datum/world_edit_generator_definition/world_edit_test_outpost_clamp
	id = "world_edit_test_outpost_clamp"
	name_ru = "World Edit Test Outpost Clamp"
	category_ru = "Tests"
	description_ru = "Unit-test helper definition for anchor-pair clamp confirmation coverage."
	required_rights = R_DEBUG
	supports_preview = TRUE
	execution_mode = "batch"
	generator_type = /datum/world_edit_generator/outpost_radius/world_edit_test_clamp
	default_params = list(
		"shape_line_length" = 4,
		"shape_line_spacing" = 1,
	)
	status = "draft"

/datum/world_edit_generator/outpost_radius/world_edit_test_clamp
	var/apply_calls = 0

/datum/world_edit_generator/outpost_radius/world_edit_test_clamp/get_supported_placement_modes()
	return list("single", "repeat")

/datum/world_edit_generator/outpost_radius/world_edit_test_clamp/get_supported_placement_shapes()
	return list(
		WORLD_EDIT_SHAPE_LINE,
		WORLD_EDIT_SHAPE_POLYLINE,
	)

/datum/world_edit_generator/outpost_radius/world_edit_test_clamp/supports_placement_direction()
	return TRUE

/datum/world_edit_generator/outpost_radius/world_edit_test_clamp/evaluate_shape_contract(datum/world_edit_shape_contract/shape_contract, list/params, list/placement_context)
	var/shape_id = "[shape_contract?.shape_id || placement_context["shape"] || WORLD_EDIT_SHAPE_LINE]"
	var/list/support_metadata = list(
		"shape_support_class" = "shape",
		"shape_requested_id" = shape_id,
		"shape_effective_id" = shape_id,
	)
	var/turf/requested_end_turf = placement_context["requested_end_turf"]
	var/turf/resolved_end_turf = placement_context["resolved_end_turf"] || placement_context["end_turf"]
	if(!istype(requested_end_turf) || !istype(resolved_end_turf))
		return list(
			"support_class" = "shape",
			"error" = "Unit test clamp generator is missing preview endpoints.",
			"metadata" = support_metadata.Copy(),
		)
	if(requested_end_turf == resolved_end_turf)
		return list(
			"support_class" = "shape",
			"error" = "Unit test rejected unclamped endpoint.",
			"metadata" = support_metadata.Copy(),
		)
	return list(
		"support_class" = "shape",
		"error" = null,
		"metadata" = support_metadata.Copy(),
	)

/datum/world_edit_generator/outpost_radius/world_edit_test_clamp/build_placement_plan(mob/user, list/params, list/placement_context)
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

/datum/world_edit_generator/outpost_radius/world_edit_test_clamp/apply(mob/user, list/params)
	var/datum/world_edit_apply_result/result = new
	apply_calls++
	result.success = TRUE
	result.message = "ok"
	result.meta = list("applied" = TRUE)
	return result

/datum/world_edit_generator_definition/world_edit_test_apply_failure_hook
	id = "world_edit_test_apply_failure_hook"
	name_ru = "World Edit Test Apply Failure Hook"
	category_ru = "Tests"
	description_ru = "Unit-test helper definition for failed apply runtime coverage."
	required_rights = R_DEBUG
	supports_preview = TRUE
	execution_mode = "batch"
	generator_type = /datum/world_edit_generator/world_edit_test_apply_failure_hook
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

/datum/world_edit_generator/world_edit_test_apply_failure_hook
	parent_type = /datum/world_edit_generator/world_edit_test_apply_hook

/datum/world_edit_generator/world_edit_test_apply_failure_hook/apply(mob/user, list/params)
	var/datum/world_edit_apply_result/result = new
	apply_calls++
	result.success = FALSE
	result.message = "failed"
	result.meta = list("applied" = FALSE)
	return result

/datum/world_edit_generator_definition/world_edit_test_base_contract_hook
	id = "world_edit_test_base_contract_hook"
	name_ru = "World Edit Test Base Contract Hook"
	category_ru = "Tests"
	description_ru = "Unit-test helper definition for base placement fallback contracts."
	required_rights = R_DEBUG
	supports_preview = TRUE
	execution_mode = "batch"
	generator_type = /datum/world_edit_generator/world_edit_test_base_contract_hook
	default_params = list(
		"shape_line_length" = 4,
		"shape_line_spacing" = 1,
	)
	status = "draft"

/datum/world_edit_generator/world_edit_test_base_contract_hook
	var/apply_calls = 0

/datum/world_edit_generator/world_edit_test_base_contract_hook/get_supported_placement_modes()
	return list("single", "repeat")

/datum/world_edit_generator/world_edit_test_base_contract_hook/get_supported_placement_shapes()
	return list(
		WORLD_EDIT_SHAPE_LINE,
		WORLD_EDIT_SHAPE_POINT,
	)

/datum/world_edit_generator/world_edit_test_base_contract_hook/supports_placement_direction()
	return TRUE

/datum/world_edit_generator/world_edit_test_base_contract_hook/build_placement_plan(mob/user, list/params, list/placement_context)
	var/datum/world_edit_plan/plan = new
	var/list/anchor_turfs = placement_context["anchor_turfs"] || list()
	for(var/turf/anchor_turf as anything in anchor_turfs)
		if(!istype(anchor_turf))
			continue
		plan.placements += list(list("kind" = "test", "turf" = anchor_turf, "dir" = placement_context["direction"] || NORTH))
		plan.affected_turfs += anchor_turf
	plan.metadata["entry_count"] = length(plan.placements)
	return plan

/datum/world_edit_generator/world_edit_test_base_contract_hook/apply(mob/user, list/params)
	var/datum/world_edit_apply_result/result = new
	apply_calls++
	result.success = TRUE
	result.message = "base apply should not run"
	return result

/datum/unit_test/world_edit_corner_slots/outpost_perimeter/Run()
	var/datum/world_edit_generator/outpost_radius/generator = allocate(/datum/world_edit_generator/outpost_radius)
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit outpost test center turf was not resolved.")

	var/list/layout_profile = list(
		"opening_dirs" = list(NORTH, EAST, SOUTH, WEST),
	)
	var/list/perimeter_data = generator.collect_perimeter_placements(center_turf, 1, layout_profile, /datum/human_ai_defense/barricade/metal)
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

/datum/unit_test/world_edit_corner_slots/outpost_perimeter/concentration_prefers_openings_and_places_doors/Run()
	var/datum/world_edit_generator/outpost_radius/generator = allocate(/datum/world_edit_generator/outpost_radius)
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit barricade-concentration test center turf was not resolved.")

	var/list/layout_profile = list(
		"opening_dirs" = list(NORTH, EAST, SOUTH, WEST),
		"opening_width" = 1,
	)
	var/list/perimeter_data = generator.collect_perimeter_placements(
		center_turf,
		2,
		layout_profile,
		/datum/human_ai_defense/barricade/metal,
		/datum/human_ai_defense/barricade/sandbag,
		"alternating",
		null,
		null,
		50,
		TRUE,
		/datum/human_ai_defense/barricade/metal_folding,
		/datum/human_ai_defense/barricade/metal_folding,
	)

	TEST_ASSERT_EQUAL(perimeter_data["dominant_barricade_count"], 8, "World Edit barricade-concentration test should assign the dominant type to exactly half of the non-opening perimeter slots.")
	TEST_ASSERT_EQUAL(perimeter_data["door_count"], 4, "World Edit barricade-concentration test should emit one folding door per supported opening.")
	TEST_ASSERT_EQUAL(perimeter_data["unsupported_door_openings"], 0, "World Edit barricade-concentration test should not mark supported metal openings as unsupported.")
	TEST_ASSERT_EQUAL(perimeter_data["blocked_door_openings"], 0, "World Edit barricade-concentration test should not block door slots on the unit-test floor.")

	var/list/dominant_slot_lookup = list()
	var/observed_door_count = 0
	for(var/list/placement as anything in perimeter_data["placements"])
		if(placement["is_barricade_door"])
			observed_door_count++
			TEST_ASSERT(placement["barricade_path"] == /datum/human_ai_defense/barricade/metal_folding, "World Edit barricade-concentration test should map metal openings to metal folding barricades.")
			continue
		if(placement["barricade_path"] == /datum/human_ai_defense/barricade/metal)
			var/slot_key = GLOB.world_edit_helpers.build_turf_dir_slot_key(placement["turf"], placement["dir"])
			if(length(slot_key))
				dominant_slot_lookup[slot_key] = TRUE

	TEST_ASSERT_EQUAL(observed_door_count, 4, "World Edit barricade-concentration test should tag the emitted door placements.")

	var/list/expected_dominant_slots = list(
		GLOB.world_edit_helpers.build_turf_dir_slot_key(locate(center_turf.x - 1, center_turf.y + 2, center_turf.z), NORTH),
		GLOB.world_edit_helpers.build_turf_dir_slot_key(locate(center_turf.x + 1, center_turf.y + 2, center_turf.z), NORTH),
		GLOB.world_edit_helpers.build_turf_dir_slot_key(locate(center_turf.x - 1, center_turf.y - 2, center_turf.z), SOUTH),
		GLOB.world_edit_helpers.build_turf_dir_slot_key(locate(center_turf.x + 1, center_turf.y - 2, center_turf.z), SOUTH),
		GLOB.world_edit_helpers.build_turf_dir_slot_key(locate(center_turf.x + 2, center_turf.y - 1, center_turf.z), EAST),
		GLOB.world_edit_helpers.build_turf_dir_slot_key(locate(center_turf.x + 2, center_turf.y + 1, center_turf.z), EAST),
		GLOB.world_edit_helpers.build_turf_dir_slot_key(locate(center_turf.x - 2, center_turf.y - 1, center_turf.z), WEST),
		GLOB.world_edit_helpers.build_turf_dir_slot_key(locate(center_turf.x - 2, center_turf.y + 1, center_turf.z), WEST),
	)
	for(var/slot_key as anything in expected_dominant_slots)
		TEST_ASSERT(dominant_slot_lookup[slot_key], "World Edit barricade-concentration test should prioritize slots adjacent to openings before more distant perimeter tiles.")

/datum/unit_test/world_edit_corner_slots/outpost_perimeter/unsupported_door_material_leaves_openings_empty/Run()
	var/datum/world_edit_generator/outpost_radius/generator = allocate(/datum/world_edit_generator/outpost_radius)
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit unsupported-door test center turf was not resolved.")

	var/list/layout_profile = list(
		"opening_dirs" = list(NORTH, EAST, SOUTH, WEST),
		"opening_width" = 1,
	)
	var/list/perimeter_data = generator.collect_perimeter_placements(
		center_turf,
		2,
		layout_profile,
		/datum/human_ai_defense/barricade/sandbag,
		null,
		"uniform",
		null,
		null,
		100,
		TRUE,
		"follow_material",
	)

	TEST_ASSERT_EQUAL(perimeter_data["door_count"], 0, "World Edit unsupported-door test should not emit folding doors for unsupported materials.")
	TEST_ASSERT_EQUAL(perimeter_data["unsupported_door_openings"], 4, "World Edit unsupported-door test should report every sandbag opening as unsupported for door conversion.")
	TEST_ASSERT_EQUAL(length(perimeter_data["placements"]), 16, "World Edit unsupported-door test should keep only the non-opening barricade placements when folding doors are unavailable.")

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
		/datum/human_ai_defense/barricade/metal,
		null,
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
		/datum/human_ai_defense/barricade/metal,
		null,
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

	var/list/params = build_outpost_test_params("none", "crossroads", "layout", 1)
	var/datum/world_edit_plan/plan = generator.build_shape_aware_perimeter_plan(footprint_turfs, params)
	var/list/placement_counts = count_placements_by_kind(plan.placements)

	TEST_ASSERT_NOTNULL(plan, "Shape-aware outpost plan was not created.")
	TEST_ASSERT(!plan.metadata["error"], "Shape-aware outpost plan unexpectedly failed with sentries disabled.")
	TEST_ASSERT_EQUAL(plan.metadata["opening_count"], 4, "Shape-aware outpost plan should preserve four cardinal openings with sentries disabled.")
	TEST_ASSERT_EQUAL(plan.metadata["barricade_count"], 12, "Shape-aware outpost plan should preserve twelve barricade placements with sentries disabled.")
	TEST_ASSERT_EQUAL(plan.metadata["sentry_count"], 0, "Shape-aware outpost plan should not report sentries when the toggle is disabled.")
	TEST_ASSERT_EQUAL(plan.metadata["blocked_sentries"], 0, "Shape-aware outpost plan should not accumulate blocked sentries when the toggle is disabled.")
	TEST_ASSERT_EQUAL(placement_counts["opening"] || 0, 0, "Shape-aware outpost plan should keep openings in metadata/preview only instead of emitting non-executable opening placements.")
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

	var/list/params = build_outpost_test_params("anti_vehicle_stop", "crossroads", "layout", 1)
	var/datum/world_edit_plan/plan = generator.build_shape_aware_perimeter_plan(footprint_turfs, params)
	var/list/placement_counts = count_placements_by_kind(plan.placements)

	TEST_ASSERT_NOTNULL(plan, "Shape-aware outpost plan was not created.")
	TEST_ASSERT(!plan.metadata["error"], "Shape-aware outpost plan unexpectedly failed with sentries enabled.")
	TEST_ASSERT_EQUAL(plan.metadata["opening_count"], 4, "Shape-aware outpost plan should preserve four cardinal openings with sentries enabled.")
	TEST_ASSERT_EQUAL(plan.metadata["barricade_count"], 12, "Shape-aware outpost plan should preserve twelve barricade placements with sentries enabled.")
	TEST_ASSERT_EQUAL(plan.metadata["sentry_count"], 4, "Shape-aware outpost plan should place one sentry candidate per opening when sentries are enabled.")
	TEST_ASSERT_EQUAL(plan.metadata["blocked_sentries"], 0, "Shape-aware outpost plan should not block sentries on the unit-test floor when the toggle is enabled.")
	TEST_ASSERT_EQUAL(placement_counts["opening"] || 0, 0, "Shape-aware outpost plan should keep openings in metadata/preview only instead of emitting non-executable opening placements.")
	TEST_ASSERT_EQUAL(placement_counts["barricade"] || 0, 12, "Shape-aware outpost plan should emit twelve barricade placements with sentries enabled.")
	TEST_ASSERT_EQUAL(placement_counts["sentry"] || 0, 4, "Shape-aware outpost plan should emit four sentry placements when the toggle is enabled.")

/datum/unit_test/world_edit_corner_slots/shape_plan_with_barricade_doors/Run()
	var/datum/world_edit_generator/outpost_radius/generator = allocate(/datum/world_edit_generator/outpost_radius)
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit shape-door test center turf was not resolved.")

	var/list/footprint_turfs = list(
		center_turf,
		locate(center_turf.x + 1, center_turf.y, center_turf.z),
		locate(center_turf.x, center_turf.y + 1, center_turf.z),
		locate(center_turf.x + 1, center_turf.y + 1, center_turf.z),
	)
	for(var/turf/footprint_turf as anything in footprint_turfs)
		TEST_ASSERT_NOTNULL(footprint_turf, "Shape-door footprint resolved outside the unit-test floor area.")

	var/list/params = build_outpost_test_params("none", "crossroads", "layout", 1)
	params["secondary_material_path"] = /datum/human_ai_defense/barricade/sandbag
	params["primary_material_share_percent"] = 50
	params["place_barricade_doors"] = TRUE
	params["barricade_pattern"] = "alternating"
	var/datum/world_edit_plan/plan = generator.build_shape_aware_perimeter_plan(footprint_turfs, params)
	var/list/placement_counts = count_placements_by_kind(plan.placements)

	TEST_ASSERT_NOTNULL(plan, "Shape-door outpost plan was not created.")
	TEST_ASSERT(!plan.metadata["error"], "Shape-door outpost plan unexpectedly failed.")
	TEST_ASSERT_EQUAL(plan.metadata["opening_count"], 4, "Shape-door outpost plan should preserve four openings.")
	TEST_ASSERT_EQUAL(plan.metadata["door_count"], 4, "Shape-door outpost plan should emit four folding door placements.")
	TEST_ASSERT_EQUAL(plan.metadata["dominant_barricade_count"], 6, "Shape-door outpost plan should keep the dominant material on exactly half of the non-opening shell.")
	TEST_ASSERT_EQUAL(placement_counts["barricade"] || 0, 16, "Shape-door outpost plan should emit twelve shell barricades plus four folding doors.")
	TEST_ASSERT_EQUAL(placement_counts["sentry"] || 0, 0, "Shape-door outpost plan should not emit sentries when the toggle is disabled.")

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

	var/list/params = build_outpost_test_params("lane_fort", "crossroads", "layout", 1)
	params["secondary_material_path"] = /datum/human_ai_defense/barricade/sandbag
	params["primary_material_share_percent"] = 50
	params["place_barricade_doors"] = TRUE
	params["barricade_pattern"] = "alternating"
	var/datum/world_edit_plan/plan = generator.build_shape_aware_perimeter_plan(footprint_turfs, params)
	TEST_ASSERT_NOTNULL(plan, "Unit-test outpost plan for blueprint export was not created.")
	TEST_ASSERT(!plan.metadata["error"], "Unit-test outpost plan for blueprint export unexpectedly failed.")

	var/list/export_result = GLOB.world_edit_blueprints.world_edit_export_blueprint_from_outpost_plan(plan, center_turf, "Unit Test Blueprint", "unit_test")
	TEST_ASSERT(!export_result["error"], "Blueprint export from outpost plan unexpectedly failed.")

	var/list/blueprint = export_result["blueprint"]
	TEST_ASSERT(islist(blueprint), "Blueprint export should produce a blueprint payload.")
	TEST_ASSERT(length(blueprint["entries"]), "Blueprint export should contain at least one entry.")
	TEST_ASSERT(islist(blueprint["outpost_recipe"]), "Blueprint export should persist optional outpost_recipe metadata for authored outpost plans.")
	TEST_ASSERT_EQUAL(blueprint["outpost_recipe"]["defense_profile"], "lane_fort", "Blueprint export should persist the resolved tactical profile id.")
	TEST_ASSERT_EQUAL(blueprint["outpost_recipe"]["primary_material_share_percent"], 50, "Blueprint export should persist the resolved primary material share.")
	TEST_ASSERT(blueprint["outpost_recipe"]["place_barricade_doors"], "Blueprint export should persist the folding-door toggle in outpost_recipe.")
	TEST_ASSERT_EQUAL(length(blueprint["outpost_recipe"]["footprint_offsets"]), 4, "Blueprint export should persist the relative footprint offsets for shape-authored outposts.")

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
		"outpost_recipe" = blueprint["outpost_recipe"],
	))
	TEST_ASSERT(!validation_result["error"], "Exported blueprint payload should validate against the live blueprint library schema.")
	TEST_ASSERT(islist(validation_result["blueprint"]["outpost_recipe"]), "Blueprint validation should preserve optional outpost_recipe metadata.")

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

/datum/unit_test/world_edit_corner_slots/blueprint_validation_accepts_folding_barricades/Run()
	var/turf/anchor_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(anchor_turf, "World Edit folding-barricade blueprint test anchor turf was not resolved.")

	var/list/validation_result = GLOB.world_edit_blueprints.world_edit_validate_blueprint_definition(list(
		"schema" = "world_edit_blueprint_lite",
		"version" = 1,
		"id" = "foldingbarr01",
		"name" = "Folding Barricade",
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
				"type" = "[/obj/structure/barricade/plasteel/metal]",
				"dx" = 0,
				"dy" = 0,
				"dz" = 0,
				"dir" = EAST,
				"vars" = list(),
			),
		),
	))
	TEST_ASSERT(!validation_result["error"], "World Edit folding-barricade blueprint test should accept whitelisted folding barricades.")

	var/datum/world_edit_plan/plan = GLOB.world_edit_blueprints.world_edit_build_plan_from_blueprint(validation_result["blueprint"], anchor_turf, NORTH)
	TEST_ASSERT_NOTNULL(plan, "World Edit folding-barricade blueprint test should build a plan datum.")
	TEST_ASSERT(!plan.metadata["error"], "World Edit folding-barricade blueprint test should translate a valid folding barricade blueprint.")
	TEST_ASSERT_EQUAL(length(plan.placements), 1, "World Edit folding-barricade blueprint test should keep the translated folding barricade placement.")
	TEST_ASSERT_EQUAL(plan.placements[1]["obj_path"], /obj/structure/barricade/plasteel/metal, "World Edit folding-barricade blueprint test should preserve the folding barricade obj path.")

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

	TEST_ASSERT_EQUAL(validation_result["error"], "В шаблоне несколько размещений для одного и того же относительного слота.", "Blueprint validation should reject duplicate relative slot definitions.")

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

	TEST_ASSERT_EQUAL(validation_result["error"], "Для '/obj/structure/barricade/metal' vars не поддерживаются.", "Blueprint validation should reject vars for non-sentry types.")

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
	TEST_ASSERT(isnull(manager.current_params["shape_points_origin"]), "World Edit manager should scrub runtime collector origin params while saving generator context.")
	TEST_ASSERT(isnull(manager.current_params["shape_points_text"]), "World Edit manager should scrub runtime collector point params while saving generator context.")
	TEST_ASSERT_NULL(manager.get_placement_collector_origin_turf(), "World Edit manager should not hydrate collector origin into placement_session while saving generator context.")
	TEST_ASSERT_EQUAL(manager.get_placement_collector_point_count(), 0, "World Edit manager should not hydrate collector points into placement_session while saving generator context.")

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

/datum/unit_test/world_edit_manager_state/restore_generator_context_strips_runtime_shape_params_from_snapshot/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/outpost_radius/definition = new
	var/datum/world_edit_generator/outpost_radius/generator = allocate(/datum/world_edit_generator/outpost_radius)
	var/turf/collector_origin = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(collector_origin, "World Edit context-restore snapshot test origin turf was not resolved.")
	generator.attach(manager, definition)

	manager.current_definition = definition
	manager.current_generator = generator
	manager.generator_context_cache = list(
		definition.id = list(
			"params" = list(
				"radius" = 5,
				"shape_points_origin" = "[collector_origin.x],[collector_origin.y],[collector_origin.z]",
				"shape_points_text" = "0,0;1,0;1,1",
			),
			"placement_mode" = "repeat",
			"placement_shape" = WORLD_EDIT_SHAPE_POLYGON,
			"placement_dir" = WEST,
			"placement_dir_uses_facing" = FALSE,
		),
	)

	TEST_ASSERT(manager.restore_generator_context(definition.id), "World Edit context-restore snapshot test should restore the injected generator snapshot.")
	TEST_ASSERT_EQUAL(manager.current_params["radius"], 5, "World Edit context-restore snapshot test should restore persistent params from the snapshot.")
	TEST_ASSERT(isnull(manager.current_params["shape_points_origin"]), "World Edit context-restore snapshot test should scrub runtime collector origin params from the snapshot.")
	TEST_ASSERT(isnull(manager.current_params["shape_points_text"]), "World Edit context-restore snapshot test should scrub runtime collector point params from the snapshot.")
	TEST_ASSERT_NULL(manager.get_placement_collector_origin_turf(), "World Edit context-restore snapshot test should not hydrate collector origin into placement_session during restore.")
	TEST_ASSERT_EQUAL(manager.get_placement_collector_point_count(), 0, "World Edit context-restore snapshot test should not hydrate collector points into placement_session during restore.")
	TEST_ASSERT_EQUAL(manager.placement_mode, "repeat", "World Edit context-restore snapshot test should still restore placement mode.")
	TEST_ASSERT_EQUAL(manager.placement_shape, WORLD_EDIT_SHAPE_POLYGON, "World Edit context-restore snapshot test should still restore placement shape.")
	TEST_ASSERT_EQUAL(manager.placement_dir, WEST, "World Edit context-restore snapshot test should still restore placement direction.")

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

/datum/unit_test/world_edit_manager_state/base_placement_contract_finalizes_metadata_and_fails_fast_apply/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/world_edit_test_base_contract_hook/definition = new
	var/datum/world_edit_generator/world_edit_test_base_contract_hook/generator = allocate(/datum/world_edit_generator/world_edit_test_base_contract_hook)
	var/turf/center_turf = get_world_edit_test_center_turf()
	var/turf/end_turf = locate(center_turf.x + 3, center_turf.y, center_turf.z)
	TEST_ASSERT_NOTNULL(center_turf, "World Edit base placement-contract test center turf was not resolved.")
	TEST_ASSERT_NOTNULL(end_turf, "World Edit base placement-contract test end turf was not resolved.")

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.current_params = definition.default_params?.Copy() || list()
	manager.placement_shape = WORLD_EDIT_SHAPE_LINE
	manager.placement_mode = "repeat"
	manager.placement_dir = EAST

	var/datum/world_edit_shape_contract/shape_contract = GLOB.world_edit_shape_geometry.build_shape_contract(
		WORLD_EDIT_SHAPE_LINE,
		center_turf,
		end_turf,
		manager.current_params,
		EAST,
	)
	var/list/placement_context = manager.build_placement_context(shape_contract, center_turf, end_turf, end_turf, center_turf, center_turf, EAST, "repeat")
	var/datum/world_edit_plan/plan = generator.build_plan_from_shape_contract(null, shape_contract, manager.current_params.Copy(), placement_context)

	TEST_ASSERT(istype(plan, /datum/world_edit_plan), "World Edit base placement-contract test should build a placement plan.")
	TEST_ASSERT_EQUAL(plan.metadata["placement_mode"], "repeat", "World Edit base placement-contract test should finalize placement mode metadata in the base fallback.")
	TEST_ASSERT_EQUAL(plan.metadata["placement_shape"], WORLD_EDIT_SHAPE_LINE, "World Edit base placement-contract test should finalize placement shape metadata in the base fallback.")
	TEST_ASSERT_EQUAL(plan.metadata["anchor_count"], length(shape_contract.anchor_turfs), "World Edit base placement-contract test should finalize anchor counts in the base fallback.")
	TEST_ASSERT_EQUAL(plan.metadata["placement_dir"], EAST, "World Edit base placement-contract test should finalize placement dir metadata in the base fallback.")
	TEST_ASSERT_EQUAL(plan.metadata["placement_dir_label"], GLOB.world_edit_helpers.dir_to_label(EAST), "World Edit base placement-contract test should finalize placement dir labels in the base fallback.")
	TEST_ASSERT(islist(plan.metadata["shape_result"]), "World Edit base placement-contract test should stamp the shared shape_result metadata in the base fallback.")

	var/datum/world_edit_apply_result/result = generator.apply_built_plan(null, manager.current_params.Copy(), plan)
	TEST_ASSERT(istype(result, /datum/world_edit_apply_result), "World Edit base placement-contract test should return an apply result datum instead of recursing through apply().")
	TEST_ASSERT(!result.success, "World Edit base placement-contract test should fail fast in the base apply_plan fallback.")
	TEST_ASSERT(findtext("[result.message]", "override apply_plan()"), "World Edit base placement-contract test should explain that placement generators must override apply_plan().")
	TEST_ASSERT_EQUAL(generator.apply_calls, 0, "World Edit base placement-contract test should not call apply() through the base apply_plan fallback.")

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

/datum/unit_test/world_edit_manager_state/preview_state_invalidates_on_preview_lock_change/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/outpost_radius/definition = new
	var/center_x = round((run_loc_floor_bottom_left.x + run_loc_floor_top_right.x) / 2)
	var/center_y = round((run_loc_floor_bottom_left.y + run_loc_floor_top_right.y) / 2)
	var/turf/center_turf = locate(center_x, center_y, run_loc_floor_bottom_left.z)
	TEST_ASSERT_NOTNULL(center_turf, "World Edit preview-signature lock test center turf was not resolved.")

	manager.current_definition = definition
	manager.current_params = list("radius" = 4)
	manager.mark_preview_state()
	TEST_ASSERT(manager.is_preview_state_valid(), "World Edit preview signature should start valid before preview-lock changes.")

	manager.set_placement_preview_locked(TRUE, center_turf)
	TEST_ASSERT(!manager.is_preview_state_valid(), "World Edit preview signature should invalidate when the preview enters the locked confirmation state.")

	manager.mark_preview_state()
	manager.set_placement_preview_locked(FALSE)
	TEST_ASSERT(!manager.is_preview_state_valid(), "World Edit preview signature should invalidate when the preview leaves the locked confirmation state.")

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
	TEST_ASSERT("requires_preview_before_apply" in data, "World Edit UI payload builder should expose preview requirement keys.")
	TEST_ASSERT("placement_interaction_label" in data, "World Edit UI payload builder should expose placement interaction summary keys.")
	TEST_ASSERT("placement_anchor" in data, "World Edit UI payload builder should expose placement anchor keys.")
	TEST_ASSERT("preset_entries" in data, "World Edit UI payload builder should include preset contract keys.")
	TEST_ASSERT("blueprint_entries" in data, "World Edit UI payload builder should include blueprint contract keys.")
	TEST_ASSERT("history_entries" in data, "World Edit UI payload builder should include history contract keys.")
	TEST_ASSERT("can_run_preview" in data, "World Edit UI payload builder should include actionability contract keys.")
	TEST_ASSERT(!("current_generator_name" in data), "World Edit UI payload builder should prune legacy generator name keys.")
	TEST_ASSERT(!("current_generator_category" in data), "World Edit UI payload builder should prune legacy generator category keys.")
	TEST_ASSERT(!("current_generator_description" in data), "World Edit UI payload builder should prune legacy generator description keys.")
	TEST_ASSERT(!("current_generator_execution_mode" in data), "World Edit UI payload builder should prune legacy execution mode keys.")
	TEST_ASSERT(!("current_generator_required_rights" in data), "World Edit UI payload builder should prune legacy rights summary keys.")
	TEST_ASSERT("runtime_status" in data, "World Edit UI payload builder should expose runtime status entries for the live panel contract.")
	TEST_ASSERT(islist(data["runtime_status"]), "World Edit UI payload builder should keep runtime status in a list form even before counters are populated.")
	TEST_ASSERT(!("current_params_text" in data), "World Edit UI payload builder should prune legacy params summary keys.")
	TEST_ASSERT(!("placement_collector_origin" in data), "World Edit UI payload builder should prune legacy collector origin keys.")
	TEST_ASSERT(!("placement_collector_points_text" in data), "World Edit UI payload builder should prune legacy collector points text keys.")
	TEST_ASSERT(!("placement_collector_summary" in data), "World Edit UI payload builder should prune legacy collector summary keys.")
	TEST_ASSERT(!("placement_hover" in data), "World Edit UI payload builder should prune legacy hover keys.")
	TEST_ASSERT(!("placement_preview_shape_tiles" in data), "World Edit UI payload builder should prune legacy preview shape tile counts.")
	TEST_ASSERT(!("placement_preview_effect_tiles" in data), "World Edit UI payload builder should prune legacy preview effect counts.")
	TEST_ASSERT(!("last_undo_action" in data), "World Edit UI payload builder should prune legacy undo action keys.")
	TEST_ASSERT(!("can_refresh_ui" in data), "World Edit UI payload builder should prune legacy refresh availability keys.")

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

/datum/unit_test/world_edit_corner_slots/manager_runtime/repeated_last_collector_point_keeps_invalid_outpost_preview_active/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/outpost_radius/definition = new
	var/datum/world_edit_generator/outpost_radius/generator = allocate(/datum/world_edit_generator/outpost_radius)
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit invalid-outpost collector cancel test center turf was not resolved.")
	var/turf/disconnected_turf = locate(center_turf.x + 2, center_turf.y + 2, center_turf.z)
	TEST_ASSERT_NOTNULL(disconnected_turf, "World Edit invalid-outpost collector cancel test disconnected turf was not resolved.")
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

	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit invalid-outpost collector finish test should accept the first collector point.")
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), disconnected_turf), "World Edit invalid-outpost collector finish test should accept the disconnected collector point for validation.")
	TEST_ASSERT(findtext("[manager.last_preview_message]", "несвязанные островки"), "World Edit invalid-outpost collector test should surface the disconnected-footprint support error before cancellation.")
	TEST_ASSERT(manager.placement_click_active, "World Edit invalid-outpost collector finish test should keep placement mode active while the preview stays invalid.")

	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), disconnected_turf), "World Edit invalid-outpost collector finish test should treat a repeated click on the last point as a finish attempt, not as a reset.")
	TEST_ASSERT(manager.placement_click_active, "World Edit invalid-outpost collector finish test should keep placement mode active after the failed finish attempt.")
	TEST_ASSERT(manager.placement_anchor_turf == center_turf, "World Edit invalid-outpost collector finish test should preserve the active anchor after the failed finish attempt.")
	TEST_ASSERT(manager.get_placement_collector_origin_turf() == center_turf, "World Edit invalid-outpost collector finish test should preserve the collector origin after the failed finish attempt.")
	TEST_ASSERT_EQUAL(manager.get_placement_collector_point_count(), 2, "World Edit invalid-outpost collector finish test should keep committed collector points after the failed finish attempt.")
	TEST_ASSERT(istype(manager.get_placement_preview_candidate(), /datum/world_edit_placement_candidate), "World Edit invalid-outpost collector finish test should keep the invalid preview candidate instead of clearing it.")
	TEST_ASSERT(!manager.is_placement_confirm_armed_for_turf(disconnected_turf), "World Edit invalid-outpost collector finish test should not arm confirmation while the shape remains invalid.")
	TEST_ASSERT(findtext("[manager.last_preview_message]", "несвязанные островки"), "World Edit invalid-outpost collector finish test should keep surfacing the disconnected-footprint error after the repeated click.")
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

/datum/unit_test/world_edit_corner_slots/manager_runtime/param_only_shape_param_refresh_keeps_selected_preview_turf/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/world_edit_test_apply_hook/definition = new
	var/datum/world_edit_generator/world_edit_test_apply_hook/generator = allocate(/datum/world_edit_generator/world_edit_test_apply_hook)
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit param-only refresh test center turf was not resolved.")
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, center_turf)

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.current_params = definition.default_params?.Copy() || list()
	manager.current_params["shape_scatter_radius"] = 3
	manager.current_params["shape_scatter_count"] = 6
	manager.current_params["shape_scatter_seed"] = 27
	manager.placement_shape = WORLD_EDIT_SHAPE_SCATTER_CLUSTER
	manager.placement_mode = "single"
	manager.placement_dir = SOUTH
	manager.placement_click_active = TRUE

	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit param-only refresh test should accept the initial placement click.")
	TEST_ASSERT(istype(manager.get_placement_preview_candidate(), /datum/world_edit_placement_candidate), "World Edit param-only refresh test should keep the initial preview candidate.")
	TEST_ASSERT(manager.placement_hover_turf == center_turf, "World Edit param-only refresh test should keep the selected preview turf before the shape-param update.")

	var/list/new_params = manager.apply_shape_ui_param_to_params(manager.current_params, "shape_scatter_radius", 5)
	TEST_ASSERT(islist(new_params), "World Edit param-only refresh test should update the scatter radius through the shared shape-ui field contract.")
	manager.current_params = new_params
	TEST_ASSERT(manager.refresh_shape_preview_after_param_change(user), "World Edit param-only refresh test should rebuild the active preview after a shape-param change.")
	TEST_ASSERT(manager.placement_hover_turf == center_turf, "World Edit param-only refresh test should preserve the selected preview turf after the shape-param change.")
	var/datum/world_edit_placement_candidate/refreshed_candidate = manager.get_placement_preview_candidate()
	TEST_ASSERT(istype(refreshed_candidate, /datum/world_edit_placement_candidate), "World Edit param-only refresh test should rebuild a preview candidate after the shape-param change.")
	TEST_ASSERT(istype(refreshed_candidate.plan, /datum/world_edit_plan), "World Edit param-only refresh test should keep a resolved plan on the rebuilt preview candidate.")
	TEST_ASSERT(text2num("[manager.current_params["shape_scatter_radius"]]") == 5, "World Edit param-only refresh test should persist the updated scatter radius value.")

	qdel(manager)

/datum/unit_test/world_edit_corner_slots/manager_runtime/live_param_refresh_preserves_confirm_arm_for_valid_preview/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/world_edit_test_apply_hook/definition = new
	var/datum/world_edit_generator/world_edit_test_apply_hook/generator = allocate(/datum/world_edit_generator/world_edit_test_apply_hook)
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit live confirm-arm refresh test center turf was not resolved.")
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, center_turf)

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.current_params = definition.default_params?.Copy() || list()
	manager.current_params["radius"] = 1
	manager.placement_shape = WORLD_EDIT_SHAPE_POINT
	manager.placement_mode = "single"
	manager.placement_dir = NORTH
	manager.placement_click_active = TRUE

	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit live confirm-arm refresh test should accept the initial placement click.")
	TEST_ASSERT(manager.is_placement_confirm_armed_for_turf(center_turf), "World Edit live confirm-arm refresh test should arm confirmation on the selected preview tile.")

	manager.current_params["radius"] = 2
	TEST_ASSERT(manager.refresh_shape_preview_after_param_change(user, TRUE), "World Edit live confirm-arm refresh test should rebuild the active preview after a live param change.")
	TEST_ASSERT(manager.placement_hover_turf == center_turf, "World Edit live confirm-arm refresh test should preserve the selected preview turf after the live param change.")
	TEST_ASSERT(manager.is_placement_confirm_armed_for_turf(center_turf), "World Edit live confirm-arm refresh test should preserve the armed confirmation after a valid live param change.")

	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit live confirm-arm refresh test should still accept the repeated confirm click.")
	TEST_ASSERT_EQUAL(generator.apply_calls, 1, "World Edit live confirm-arm refresh test should still apply after the preserved confirm arm.")
	TEST_ASSERT(manager.last_apply_success, "World Edit live confirm-arm refresh test should record a successful apply after the preserved confirm arm.")

	qdel(manager)

/datum/unit_test/world_edit_corner_slots/manager_runtime/live_param_refresh_failure_keeps_click_mode_and_feedback/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/world_edit_test_rebuild_failure_hook/definition = new
	var/datum/world_edit_generator/world_edit_test_rebuild_failure_hook/generator = allocate(/datum/world_edit_generator/world_edit_test_rebuild_failure_hook)
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit live rebuild failure test center turf was not resolved.")
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, center_turf)

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.current_params = definition.default_params?.Copy() || list()
	manager.placement_shape = WORLD_EDIT_SHAPE_POINT
	manager.placement_mode = "single"
	manager.placement_dir = NORTH
	manager.placement_click_active = TRUE

	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit live rebuild failure test should accept the initial placement click.")
	TEST_ASSERT(manager.is_placement_confirm_armed_for_turf(center_turf), "World Edit live rebuild failure test should arm confirmation before the failing refresh.")

	manager.current_params["radius"] = -1
	TEST_ASSERT(!manager.refresh_shape_preview_after_param_change(user, TRUE), "World Edit live rebuild failure test should report a failed rebuild for invalid live params.")
	TEST_ASSERT(manager.placement_click_active, "World Edit live rebuild failure test should keep placement click mode active after a failed refresh.")
	TEST_ASSERT(!manager.is_placement_confirm_armed_for_turf(center_turf), "World Edit live rebuild failure test should clear the armed confirmation after a failed refresh.")
	TEST_ASSERT(length("[manager.last_preview_message]"), "World Edit live rebuild failure test should surface a failure message instead of silently clearing the preview.")
	TEST_ASSERT(!manager.is_preview_state_valid(), "World Edit live rebuild failure test should invalidate the preview state after a failed refresh.")
	var/datum/world_edit_placement_candidate/failed_candidate = manager.get_placement_preview_candidate()
	TEST_ASSERT(istype(failed_candidate, /datum/world_edit_placement_candidate), "World Edit live rebuild failure test should keep a preview candidate for the failed rebuild result.")
	TEST_ASSERT(!failed_candidate.is_ready_for_apply(), "World Edit live rebuild failure test should not leave the failed rebuild candidate apply-ready.")

	qdel(manager)

/datum/unit_test/world_edit_corner_slots/manager_runtime/anchor_pair_same_tile_refresh_preserves_confirm_arm/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/world_edit_test_apply_hook/definition = new
	var/datum/world_edit_generator/world_edit_test_apply_hook/generator = allocate(/datum/world_edit_generator/world_edit_test_apply_hook)
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit same-tile anchor refresh test center turf was not resolved.")
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, center_turf)

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.current_params = definition.default_params?.Copy() || list()
	manager.placement_shape = WORLD_EDIT_SHAPE_FILLED_RECTANGLE
	manager.placement_mode = "single"
	manager.placement_dir = EAST
	manager.placement_click_active = TRUE

	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit same-tile anchor refresh test should accept the first anchor click.")
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit same-tile anchor refresh test should build the minimum-size preview on the repeated same-tile click.")
	TEST_ASSERT(manager.is_placement_confirm_armed_for_turf(center_turf), "World Edit same-tile anchor refresh test should arm confirmation before the live refresh.")

	manager.current_params["shape_rect_width"] = 5
	TEST_ASSERT(manager.refresh_shape_preview_after_param_change(user, TRUE), "World Edit same-tile anchor refresh test should rebuild the same-tile anchor-pair preview after a live param change.")
	TEST_ASSERT(manager.is_placement_confirm_armed_for_turf(center_turf), "World Edit same-tile anchor refresh test should preserve confirmation on the rebuilt same-tile preview.")
	var/datum/world_edit_placement_candidate/refreshed_candidate = manager.get_placement_preview_candidate()
	TEST_ASSERT(istype(refreshed_candidate, /datum/world_edit_placement_candidate), "World Edit same-tile anchor refresh test should keep a rebuilt preview candidate after refresh.")
	TEST_ASSERT(refreshed_candidate.is_ready_for_apply(), "World Edit same-tile anchor refresh test should keep the rebuilt same-tile candidate apply-ready.")

	qdel(manager)

/datum/unit_test/world_edit_corner_slots/manager_runtime/preview_signature_does_not_consume_runtime_shape_params/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/world_edit_test_apply_hook/definition = new
	var/datum/world_edit_generator/world_edit_test_apply_hook/generator = allocate(/datum/world_edit_generator/world_edit_test_apply_hook)
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit preview-signature purity test center turf was not resolved.")

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.current_params = definition.default_params?.Copy() || list()
	manager.current_params["shape_points_origin"] = "[center_turf.x],[center_turf.y],[center_turf.z]"
	manager.current_params["shape_points_text"] = "0,0; 1,0; 1,1"
	manager.placement_shape = WORLD_EDIT_SHAPE_CUSTOM_MASK
	manager.placement_mode = "single"
	manager.placement_dir = EAST

	var/signature = manager.build_preview_params_signature()
	TEST_ASSERT(length(signature), "World Edit preview-signature purity test should still build a signature string.")
	TEST_ASSERT("[manager.current_params["shape_points_origin"]]" == "[center_turf.x],[center_turf.y],[center_turf.z]", "World Edit preview-signature purity test should not consume runtime collector origin params.")
	TEST_ASSERT("[manager.current_params["shape_points_text"]]" == "0,0; 1,0; 1,1", "World Edit preview-signature purity test should not consume runtime collector points params.")
	TEST_ASSERT(!istype(manager.get_placement_session().collector_origin_turf), "World Edit preview-signature purity test should not migrate runtime collector origin state during signature reads.")
	TEST_ASSERT_EQUAL(length(manager.get_placement_session().collector_points), 0, "World Edit preview-signature purity test should not migrate runtime collector points during signature reads.")

	qdel(manager)

/datum/unit_test/world_edit_corner_slots/manager_runtime/selecting_same_generator_preserves_active_safe_placement_preview/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/world_edit_test_apply_hook/definition = new
	var/datum/world_edit_generator/world_edit_test_apply_hook/generator = allocate(/datum/world_edit_generator/world_edit_test_apply_hook)
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit same-generator selection test center turf was not resolved.")
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, center_turf)

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.current_params = definition.default_params?.Copy() || list()
	manager.placement_shape = WORLD_EDIT_SHAPE_POINT
	manager.placement_mode = "single"
	manager.placement_dir = NORTH
	manager.placement_click_active = TRUE

	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit same-generator selection test should accept the initial placement click.")
	TEST_ASSERT(manager.has_active_safe_placement_preview(), "World Edit same-generator selection test should start with an active safe-placement preview.")
	var/datum/world_edit_placement_candidate/preview_candidate = manager.get_placement_preview_candidate()

	TEST_ASSERT(manager.handle_generator_ui_action(user, "select_generator", list("generator_id" = definition.id)), "World Edit same-generator selection test should accept selecting the already-active generator.")
	TEST_ASSERT(manager.current_generator == generator, "World Edit same-generator selection test should keep the same generator instance when the selected id is unchanged.")
	TEST_ASSERT(manager.get_placement_preview_candidate() == preview_candidate, "World Edit same-generator selection test should preserve the active preview candidate when the selected id is unchanged.")
	TEST_ASSERT(manager.placement_click_active, "World Edit same-generator selection test should keep click-mode active when the selected id is unchanged.")
	TEST_ASSERT(manager.is_placement_confirm_armed_for_turf(center_turf), "World Edit same-generator selection test should preserve the armed confirmation when the selected id is unchanged.")

	qdel(manager)

/datum/unit_test/world_edit_corner_slots/manager_runtime/apply_blueprint_by_id_reuses_active_safe_placement_preview/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/blueprint_stamp/definition = new
	var/datum/world_edit_generator/blueprint_stamp/generator = allocate(/datum/world_edit_generator/blueprint_stamp)
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit blueprint apply-through-preview test center turf was not resolved.")
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, center_turf)
	var/list/blueprint = list(
		"id" = "world_edit_apply_blueprint_preview_test",
		"name" = "World Edit Apply Blueprint Preview Test",
		"created_at" = "2026-04-19T00:00:00Z",
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
	TEST_ASSERT(length("[blueprint_file_path]"), "World Edit blueprint apply-through-preview test should save the helper blueprint definition.")

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
	manager.confirm_before_apply = FALSE
	manager.placement_shape = WORLD_EDIT_SHAPE_POINT
	manager.placement_mode = "single"
	manager.placement_dir = NORTH
	manager.placement_click_active = TRUE

	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit blueprint apply-through-preview test should accept the initial placement click.")
	TEST_ASSERT(manager.has_active_safe_placement_preview(), "World Edit blueprint apply-through-preview test should expose an active safe-placement preview before apply.")
	TEST_ASSERT(manager.apply_blueprint_by_id(user, blueprint["id"]), "World Edit blueprint apply-through-preview test should reuse the active placement preview instead of failing while click-mode is active.")
	TEST_ASSERT(manager.last_apply_success, "World Edit blueprint apply-through-preview test should record a successful apply through the active placement preview.")
	TEST_ASSERT(!manager.placement_click_active, "World Edit blueprint apply-through-preview test should exit single-mode placement after the successful apply.")
	var/obj/structure/barricade/metal/created_barricade = locate(/obj/structure/barricade/metal) in center_turf
	TEST_ASSERT(istype(created_barricade, /obj/structure/barricade/metal), "World Edit blueprint apply-through-preview test should create the blueprint barricade on the preview anchor turf.")

	if(istype(created_barricade, /obj/structure/barricade/metal))
		qdel(created_barricade)
	if(length("[blueprint_file_path]") && fexists(blueprint_file_path))
		fdel(blueprint_file_path)
	qdel(manager)

/datum/unit_test/world_edit_corner_slots/manager_runtime/apply_blueprint_by_id_rebuilds_same_id_active_preview_after_definition_change/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/blueprint_stamp/definition = new
	var/datum/world_edit_generator/blueprint_stamp/generator = allocate(/datum/world_edit_generator/blueprint_stamp)
	var/turf/center_turf = get_world_edit_test_center_turf()
	var/turf/east_turf = locate(center_turf.x + 1, center_turf.y, center_turf.z)
	TEST_ASSERT_NOTNULL(center_turf, "World Edit blueprint refresh-on-apply test center turf was not resolved.")
	TEST_ASSERT_NOTNULL(east_turf, "World Edit blueprint refresh-on-apply test east turf was not resolved.")
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, center_turf)
	var/list/blueprint = list(
		"id" = "world_edit_apply_blueprint_refresh_test",
		"name" = "World Edit Apply Blueprint Refresh Test",
		"created_at" = "2026-04-19T00:00:00Z",
		"created_by" = "unit_test",
		"source" = "unit_test",
		"bounds" = list("radius" = 1),
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
	TEST_ASSERT(length("[blueprint_file_path]"), "World Edit blueprint refresh-on-apply test should save the initial helper blueprint definition.")

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
	manager.confirm_before_apply = FALSE
	manager.placement_shape = WORLD_EDIT_SHAPE_POINT
	manager.placement_mode = "single"
	manager.placement_dir = NORTH
	manager.placement_click_active = TRUE

	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit blueprint refresh-on-apply test should accept the initial placement click.")
	var/datum/world_edit_placement_candidate/initial_candidate = manager.get_placement_preview_candidate()
	TEST_ASSERT(istype(initial_candidate, /datum/world_edit_placement_candidate), "World Edit blueprint refresh-on-apply test should build the initial preview candidate.")
	TEST_ASSERT_EQUAL(initial_candidate.plan?.metadata["blueprint_entry_count"], 1, "World Edit blueprint refresh-on-apply test should start with the original single-entry preview.")

	blueprint["entries"] = list(
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
			"dx" = 1,
			"dy" = 0,
			"dz" = 0,
			"dir" = EAST,
			"vars" = list(),
		),
	)
	TEST_ASSERT_EQUAL(GLOB.world_edit_blueprints.world_edit_save_blueprint_definition(blueprint), blueprint_file_path, "World Edit blueprint refresh-on-apply test should overwrite the helper blueprint file in place.")

	TEST_ASSERT(manager.apply_blueprint_by_id(user, blueprint["id"]), "World Edit blueprint refresh-on-apply test should rebuild and apply the updated blueprint when the same id is requested again.")
	TEST_ASSERT(manager.last_apply_success, "World Edit blueprint refresh-on-apply test should record a successful apply after the blueprint definition changes.")
	var/obj/structure/barricade/metal/center_barricade = locate(/obj/structure/barricade/metal) in center_turf
	var/obj/structure/barricade/metal/east_barricade = locate(/obj/structure/barricade/metal) in east_turf
	TEST_ASSERT(istype(center_barricade, /obj/structure/barricade/metal), "World Edit blueprint refresh-on-apply test should still create the original barricade on the anchor turf.")
	TEST_ASSERT(istype(east_barricade, /obj/structure/barricade/metal), "World Edit blueprint refresh-on-apply test should rebuild the active preview and apply the updated east-side barricade from the same blueprint id.")

	if(istype(center_barricade, /obj/structure/barricade/metal))
		qdel(center_barricade)
	if(istype(east_barricade, /obj/structure/barricade/metal))
		qdel(east_barricade)
	if(length("[blueprint_file_path]") && fexists(blueprint_file_path))
		fdel(blueprint_file_path)
	qdel(manager)

/datum/unit_test/world_edit_corner_slots/manager_runtime/activate_blueprint_generator_invalidates_same_id_preview_revision_cache/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/blueprint_stamp/definition = new
	var/datum/world_edit_generator/blueprint_stamp/generator = allocate(/datum/world_edit_generator/blueprint_stamp)
	var/list/blueprint = list(
		"id" = "world_edit_blueprint_revision_refresh_test",
		"name" = "World Edit Blueprint Revision Refresh Test",
		"created_at" = "2026-04-22T00:00:00Z",
		"created_by" = "unit_test",
		"source" = "unit_test",
		"bounds" = list("radius" = 1),
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
	TEST_ASSERT(length("[blueprint_file_path]"), "World Edit blueprint revision-refresh test should save the initial helper blueprint definition.")

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

	var/initial_revision = manager.get_active_blueprint_revision()
	TEST_ASSERT(length(initial_revision), "World Edit blueprint revision-refresh test should resolve the initial revision hash.")
	manager.mark_preview_state()
	TEST_ASSERT(manager.is_preview_state_valid(), "World Edit blueprint revision-refresh test should start with a valid cached preview signature.")

	blueprint["entries"] = list(
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
			"dx" = 1,
			"dy" = 0,
			"dz" = 0,
			"dir" = EAST,
			"vars" = list(),
		),
	)
	TEST_ASSERT_EQUAL(GLOB.world_edit_blueprints.world_edit_save_blueprint_definition(blueprint), blueprint_file_path, "World Edit blueprint revision-refresh test should overwrite the helper blueprint file in place.")
	TEST_ASSERT(manager.is_preview_state_valid(), "World Edit blueprint revision-refresh test should still expose the stale cached signature before the same-id reload invalidates it.")
	TEST_ASSERT(manager.activate_blueprint_generator(null, blueprint["id"], FALSE), "World Edit blueprint revision-refresh test should allow reloading the same blueprint id.")

	var/refreshed_revision = manager.get_active_blueprint_revision()
	TEST_ASSERT(length(refreshed_revision), "World Edit blueprint revision-refresh test should resolve the refreshed revision hash after reload.")
	TEST_ASSERT_NOTEQUAL(refreshed_revision, initial_revision, "World Edit blueprint revision-refresh test should invalidate and recalculate the active blueprint revision hash after a same-id reload.")
	TEST_ASSERT(!manager.is_preview_state_valid(), "World Edit blueprint revision-refresh test should invalidate the stale preview signature after reloading the same blueprint id.")

	if(length("[blueprint_file_path]") && fexists(blueprint_file_path))
		fdel(blueprint_file_path)
	qdel(manager)

/datum/unit_test/world_edit_corner_slots/manager_runtime/refresh_ui_keeps_active_collector_preview_context/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/world_edit_test_apply_hook/definition = new
	var/datum/world_edit_generator/world_edit_test_apply_hook/generator = allocate(/datum/world_edit_generator/world_edit_test_apply_hook)
	var/turf/center_turf = get_world_edit_test_center_turf()
	var/turf/line_turf = locate(center_turf.x + 2, center_turf.y, center_turf.z)
	var/turf/triangle_turf = locate(center_turf.x + 2, center_turf.y + 2, center_turf.z)
	TEST_ASSERT_NOTNULL(center_turf, "World Edit live-refresh collector test center turf was not resolved.")
	TEST_ASSERT_NOTNULL(line_turf, "World Edit live-refresh collector test line turf was not resolved.")
	TEST_ASSERT_NOTNULL(triangle_turf, "World Edit live-refresh collector test triangle turf was not resolved.")
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, center_turf)

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.current_params = definition.default_params?.Copy() || list()
	manager.current_params["radius"] = 5
	manager.placement_shape = WORLD_EDIT_SHAPE_POLYGON
	manager.placement_mode = "single"
	manager.placement_dir = NORTH
	manager.placement_click_active = TRUE

	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit live-refresh collector test should accept the first point.")
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), line_turf), "World Edit live-refresh collector test should accept the second point.")
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), triangle_turf), "World Edit live-refresh collector test should accept the third point.")
	TEST_ASSERT_EQUAL(manager.get_placement_collector_point_count(), 3, "World Edit live-refresh collector test should start with three committed collector points.")

	manager.refresh_current_generator_ui(user)
	TEST_ASSERT(manager.placement_click_active, "World Edit live-refresh collector test should keep click-mode active after refresh.")
	TEST_ASSERT_EQUAL(manager.get_placement_collector_point_count(), 3, "World Edit live-refresh collector test should preserve committed collector points across refresh.")
	TEST_ASSERT(manager.get_placement_collector_origin_turf() == center_turf, "World Edit live-refresh collector test should preserve the collector origin across refresh.")
	TEST_ASSERT(manager.placement_hover_turf == triangle_turf, "World Edit live-refresh collector test should preserve the active preview turf across refresh.")
	var/datum/world_edit_placement_candidate/refreshed_candidate = manager.get_placement_preview_candidate()
	TEST_ASSERT(istype(refreshed_candidate, /datum/world_edit_placement_candidate), "World Edit live-refresh collector test should rebuild the collector preview after refresh.")
	TEST_ASSERT_EQUAL(refreshed_candidate.shape_contract?.shape_id, WORLD_EDIT_SHAPE_POLYGON, "World Edit live-refresh collector test should keep the current collector shape after refresh.")

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
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit polygon collector should build a finish preview when the first point is clicked again.")
	TEST_ASSERT_EQUAL(generator.apply_calls, 0, "World Edit polygon collector should wait for a repeated click on the same tile before applying.")
	TEST_ASSERT(manager.is_placement_confirm_armed_for_turf(center_turf), "World Edit polygon collector should arm confirmation on the finishing tile.")
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit polygon collector should confirm on a repeated click over the same first point.")
	TEST_ASSERT_EQUAL(generator.apply_calls, 1, "World Edit polygon collector should apply after the repeated finish click.")

	manager.reset_placement_runtime()
	manager.current_params = definition.default_params?.Copy() || list()
	manager.placement_shape = "polyline"
	manager.placement_mode = "single"
	manager.placement_dir = NORTH
	manager.placement_click_active = TRUE
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit polyline collector should accept the first point.")
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), line_turf), "World Edit polyline collector should accept the second point.")
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), triangle_turf), "World Edit polyline collector should accept the third point.")
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit polyline collector should build a finish preview when the first point is clicked again.")
	TEST_ASSERT_EQUAL(generator.apply_calls, 1, "World Edit polyline collector should wait for a repeated click on the same tile before applying.")
	TEST_ASSERT(manager.is_placement_confirm_armed_for_turf(center_turf), "World Edit polyline collector should arm confirmation on the finishing tile.")
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit polyline collector should confirm on a repeated click over the same first point.")
	TEST_ASSERT_EQUAL(generator.apply_calls, 2, "World Edit polyline collector should apply after the repeated finish click.")

	manager.reset_placement_runtime()
	manager.current_params = definition.default_params?.Copy() || list()
	manager.placement_shape = "brush_path"
	manager.placement_mode = "single"
	manager.placement_dir = NORTH
	manager.placement_click_active = TRUE
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit brush-path collector should accept the first point.")
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), line_turf), "World Edit brush-path collector should accept the second point.")
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), triangle_turf), "World Edit brush-path collector should accept the third point.")
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit brush-path collector should build a finish preview when the first point is clicked again.")
	TEST_ASSERT_EQUAL(generator.apply_calls, 2, "World Edit brush-path collector should wait for a repeated click on the same tile before applying.")
	TEST_ASSERT(manager.is_placement_confirm_armed_for_turf(center_turf), "World Edit brush-path collector should arm confirmation on the finishing tile.")
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit brush-path collector should confirm on a repeated click over the same first point.")
	TEST_ASSERT_EQUAL(generator.apply_calls, 3, "World Edit brush-path collector should apply after the repeated finish click.")

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

/datum/unit_test/world_edit_corner_slots/manager_runtime/collector_finish_action_arms_confirm_instead_of_applying/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/world_edit_test_apply_hook/definition = new
	var/datum/world_edit_generator/world_edit_test_apply_hook/generator = allocate(/datum/world_edit_generator/world_edit_test_apply_hook)
	var/turf/center_turf = get_world_edit_test_center_turf()
	var/turf/line_turf = locate(center_turf.x + 2, center_turf.y, center_turf.z)
	var/turf/triangle_turf = locate(center_turf.x + 2, center_turf.y + 2, center_turf.z)
	TEST_ASSERT_NOTNULL(center_turf, "World Edit collector-finish action test center turf was not resolved.")
	TEST_ASSERT_NOTNULL(line_turf, "World Edit collector-finish action test line turf was not resolved.")
	TEST_ASSERT_NOTNULL(triangle_turf, "World Edit collector-finish action test triangle turf was not resolved.")
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, center_turf)

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.current_params = definition.default_params?.Copy() || list()
	manager.placement_shape = WORLD_EDIT_SHAPE_POLYGON
	manager.placement_mode = "single"
	manager.placement_dir = NORTH
	manager.placement_click_active = TRUE

	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit collector-finish action test should accept the first point.")
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), line_turf), "World Edit collector-finish action test should accept the second point.")
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), triangle_turf), "World Edit collector-finish action test should accept the third point.")

	TEST_ASSERT(manager.handle_placement_ui_action(user, "finish_placement_collection", list()), "World Edit collector-finish action test should accept the finish action.")
	TEST_ASSERT_EQUAL(generator.apply_calls, 0, "World Edit collector-finish action test should not apply immediately from the finish action.")
	TEST_ASSERT(manager.is_placement_confirm_armed_for_turf(triangle_turf), "World Edit collector-finish action test should arm confirmation on the resolved finish turf after the finish action.")
	var/datum/world_edit_placement_candidate/finish_candidate = manager.get_placement_preview_candidate()
	TEST_ASSERT(istype(finish_candidate, /datum/world_edit_placement_candidate), "World Edit collector-finish action test should keep a preview candidate after the finish action.")
	TEST_ASSERT(finish_candidate.placement_context["resolved_end_turf"] == triangle_turf, "World Edit collector-finish action test should keep the last hovered tile as the resolved finish turf.")

	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), triangle_turf), "World Edit collector-finish action test should accept the repeated confirm click.")
	TEST_ASSERT_EQUAL(generator.apply_calls, 1, "World Edit collector-finish action test should apply only after the repeated left click on the armed finish turf.")
	TEST_ASSERT(manager.last_apply_success, "World Edit collector-finish action test should record a successful apply after the repeated left click.")

	qdel(manager)

/datum/unit_test/world_edit_corner_slots/manager_runtime/collector_finish_action_works_for_custom_mask_and_brush_path/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/world_edit_test_apply_hook/definition = new
	var/datum/world_edit_generator/world_edit_test_apply_hook/generator = allocate(/datum/world_edit_generator/world_edit_test_apply_hook)
	var/turf/center_turf = get_world_edit_test_center_turf()
	var/turf/line_turf = locate(center_turf.x + 2, center_turf.y, center_turf.z)
	var/turf/triangle_turf = locate(center_turf.x + 2, center_turf.y + 2, center_turf.z)
	TEST_ASSERT_NOTNULL(center_turf, "World Edit collector-finish action multi-shape test center turf was not resolved.")
	TEST_ASSERT_NOTNULL(line_turf, "World Edit collector-finish action multi-shape test line turf was not resolved.")
	TEST_ASSERT_NOTNULL(triangle_turf, "World Edit collector-finish action multi-shape test triangle turf was not resolved.")
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, center_turf)

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.current_params = definition.default_params?.Copy() || list()
	manager.placement_shape = WORLD_EDIT_SHAPE_CUSTOM_MASK
	manager.placement_mode = "single"
	manager.placement_dir = NORTH
	manager.placement_click_active = TRUE

	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit custom-mask finish action test should accept the first point.")
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), line_turf), "World Edit custom-mask finish action test should accept the second point.")
	TEST_ASSERT(manager.handle_placement_ui_action(user, "finish_placement_collection", list()), "World Edit custom-mask finish action test should accept the finish action.")
	TEST_ASSERT(manager.is_placement_confirm_armed_for_turf(line_turf), "World Edit custom-mask finish action test should arm confirmation on the last committed point.")
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), line_turf), "World Edit custom-mask finish action test should accept the repeated confirm click.")
	TEST_ASSERT_EQUAL(generator.apply_calls, 1, "World Edit custom-mask finish action test should apply after the repeated confirm click.")

	manager.reset_placement_runtime()
	manager.current_params = definition.default_params?.Copy() || list()
	manager.placement_shape = WORLD_EDIT_SHAPE_BRUSH_PATH
	manager.placement_mode = "single"
	manager.placement_dir = NORTH
	manager.placement_click_active = TRUE

	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit brush-path finish action test should accept the first point.")
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), line_turf), "World Edit brush-path finish action test should accept the second point.")
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), triangle_turf), "World Edit brush-path finish action test should accept the third point.")
	TEST_ASSERT(manager.handle_placement_ui_action(user, "finish_placement_collection", list()), "World Edit brush-path finish action test should accept the finish action.")
	TEST_ASSERT(manager.is_placement_confirm_armed_for_turf(triangle_turf), "World Edit brush-path finish action test should arm confirmation on the last committed point.")
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), triangle_turf), "World Edit brush-path finish action test should accept the repeated confirm click.")
	TEST_ASSERT_EQUAL(generator.apply_calls, 2, "World Edit brush-path finish action test should apply after the repeated confirm click.")

	qdel(manager)

/datum/unit_test/world_edit_corner_slots/manager_runtime/non_left_clicks_remain_inert_during_safe_placement/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/world_edit_test_apply_hook/definition = new
	var/datum/world_edit_generator/world_edit_test_apply_hook/generator = allocate(/datum/world_edit_generator/world_edit_test_apply_hook)
	var/turf/center_turf = get_world_edit_test_center_turf()
	var/turf/line_turf = locate(center_turf.x + 2, center_turf.y, center_turf.z)
	var/turf/triangle_turf = locate(center_turf.x + 2, center_turf.y + 2, center_turf.z)
	TEST_ASSERT_NOTNULL(center_turf, "World Edit non-left-click test center turf was not resolved.")
	TEST_ASSERT_NOTNULL(line_turf, "World Edit non-left-click test line turf was not resolved.")
	TEST_ASSERT_NOTNULL(triangle_turf, "World Edit non-left-click test triangle turf was not resolved.")
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, center_turf)

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.current_params = definition.default_params?.Copy() || list()
	manager.placement_shape = WORLD_EDIT_SHAPE_LINE
	manager.placement_mode = "single"
	manager.placement_dir = EAST
	manager.placement_click_active = TRUE

	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit non-left-click test should accept the initial anchor click.")
	var/datum/world_edit_placement_candidate/anchor_candidate = manager.get_placement_preview_candidate()
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(RIGHT_CLICK = 1)), line_turf), "World Edit non-left-click test should swallow right clicks during anchor-pair placement.")
	TEST_ASSERT(manager.placement_anchor_turf == center_turf, "World Edit non-left-click test should keep the anchor turf unchanged after a right click.")
	TEST_ASSERT(manager.placement_hover_turf == center_turf, "World Edit non-left-click test should keep the hover turf unchanged after a right click.")
	TEST_ASSERT(manager.get_placement_preview_candidate() == anchor_candidate, "World Edit non-left-click test should keep the same anchor-pair preview candidate after a right click.")
	TEST_ASSERT(!manager.is_placement_confirm_armed_for_turf(line_turf), "World Edit non-left-click test should not arm confirmation from a right click.")

	manager.reset_placement_runtime()
	manager.current_params = definition.default_params?.Copy() || list()
	manager.placement_shape = WORLD_EDIT_SHAPE_POLYGON
	manager.placement_mode = "single"
	manager.placement_dir = NORTH
	manager.placement_click_active = TRUE

	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit non-left-click test should accept the collector origin click.")
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), line_turf), "World Edit non-left-click test should accept the second collector point.")
	var/datum/world_edit_placement_candidate/collector_candidate = manager.get_placement_preview_candidate()
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(MIDDLE_CLICK = 1)), triangle_turf), "World Edit non-left-click test should swallow middle clicks during collector placement.")
	TEST_ASSERT_EQUAL(manager.get_placement_collector_point_count(), 2, "World Edit non-left-click test should keep committed collector points unchanged after a non-left click.")
	TEST_ASSERT(manager.placement_hover_turf == line_turf, "World Edit non-left-click test should keep the collector hover turf unchanged after a non-left click.")
	TEST_ASSERT(manager.get_placement_preview_candidate() == collector_candidate, "World Edit non-left-click test should keep the same collector preview candidate after a non-left click.")
	TEST_ASSERT(!manager.is_placement_confirm_armed_for_turf(triangle_turf), "World Edit non-left-click test should not arm confirmation from a non-left collector click.")

	qdel(manager)

/datum/unit_test/world_edit_corner_slots/manager_runtime/live_refresh_preserves_hover_only_collector_preview_state/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/world_edit_test_apply_hook/definition = new
	var/datum/world_edit_generator/world_edit_test_apply_hook/generator = allocate(/datum/world_edit_generator/world_edit_test_apply_hook)
	var/turf/center_turf = get_world_edit_test_center_turf()
	var/turf/line_turf = locate(center_turf.x + 2, center_turf.y, center_turf.z)
	var/turf/triangle_turf = locate(center_turf.x + 2, center_turf.y + 2, center_turf.z)
	TEST_ASSERT_NOTNULL(center_turf, "World Edit hover-refresh collector test center turf was not resolved.")
	TEST_ASSERT_NOTNULL(line_turf, "World Edit hover-refresh collector test line turf was not resolved.")
	TEST_ASSERT_NOTNULL(triangle_turf, "World Edit hover-refresh collector test triangle turf was not resolved.")
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, center_turf)

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.current_params = definition.default_params?.Copy() || list()
	manager.current_params["radius"] = 5
	manager.placement_shape = WORLD_EDIT_SHAPE_POLYGON
	manager.placement_mode = "single"
	manager.placement_dir = NORTH
	manager.placement_click_active = TRUE

	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit hover-refresh collector test should accept the first point.")
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), line_turf), "World Edit hover-refresh collector test should accept the second point.")
	TEST_ASSERT(manager.handle_safe_placement_hover(user, triangle_turf), "World Edit hover-refresh collector test should accept the hover preview update.")
	TEST_ASSERT_EQUAL(manager.get_placement_collector_point_count(), 2, "World Edit hover-refresh collector test should keep only committed collector points after hover.")
	var/datum/world_edit_placement_candidate/hover_candidate = manager.get_placement_preview_candidate()
	TEST_ASSERT(istype(hover_candidate, /datum/world_edit_placement_candidate), "World Edit hover-refresh collector test should build a hover preview candidate.")
	TEST_ASSERT(hover_candidate.hover_only, "World Edit hover-refresh collector test should mark the collector hover preview as hover-only.")
	TEST_ASSERT(hover_candidate.placement_context["resolved_end_turf"] == triangle_turf, "World Edit hover-refresh collector test should keep the hovered turf as the resolved preview endpoint.")

	manager.refresh_current_generator_ui(user)
	var/datum/world_edit_placement_candidate/refreshed_hover_candidate = manager.get_placement_preview_candidate()
	TEST_ASSERT(istype(refreshed_hover_candidate, /datum/world_edit_placement_candidate), "World Edit hover-refresh collector test should rebuild the collector preview after refresh.")
	TEST_ASSERT(refreshed_hover_candidate.hover_only, "World Edit hover-refresh collector test should preserve hover-only preview semantics after refresh.")
	TEST_ASSERT(refreshed_hover_candidate.placement_context["resolved_end_turf"] == triangle_turf, "World Edit hover-refresh collector test should preserve the hovered preview turf after refresh.")
	TEST_ASSERT_EQUAL(manager.get_placement_collector_point_count(), 2, "World Edit hover-refresh collector test should keep committed collector points unchanged after refresh.")

	qdel(manager)

/datum/unit_test/world_edit_corner_slots/manager_runtime/collector_shape_switch_preserves_points_when_interaction_kind_matches/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/world_edit_test_apply_hook/definition = new
	var/datum/world_edit_generator/world_edit_test_apply_hook/generator = allocate(/datum/world_edit_generator/world_edit_test_apply_hook)
	var/turf/center_turf = get_world_edit_test_center_turf()
	var/turf/line_turf = locate(center_turf.x + 2, center_turf.y, center_turf.z)
	var/turf/triangle_turf = locate(center_turf.x + 2, center_turf.y + 2, center_turf.z)
	TEST_ASSERT_NOTNULL(center_turf, "World Edit collector shape-switch test center turf was not resolved.")
	TEST_ASSERT_NOTNULL(line_turf, "World Edit collector shape-switch test line turf was not resolved.")
	TEST_ASSERT_NOTNULL(triangle_turf, "World Edit collector shape-switch test triangle turf was not resolved.")
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, center_turf)

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.current_params = definition.default_params?.Copy() || list()
	manager.placement_shape = WORLD_EDIT_SHAPE_POLYGON
	manager.placement_mode = "single"
	manager.placement_dir = NORTH
	manager.placement_click_active = TRUE

	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit collector shape-switch test should accept the first point.")
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), line_turf), "World Edit collector shape-switch test should accept the second point.")
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), triangle_turf), "World Edit collector shape-switch test should accept the third point.")

	TEST_ASSERT(manager.handle_placement_ui_action(user, "set_placement_shape", list("shape" = WORLD_EDIT_SHAPE_POLYLINE)), "World Edit collector shape-switch test should accept switching to another collector shape.")
	TEST_ASSERT_EQUAL(manager.get_placement_collector_point_count(), 3, "World Edit collector shape-switch test should preserve collected points when the new shape uses the same collector interaction kind.")
	TEST_ASSERT(manager.get_placement_collector_origin_turf() == center_turf, "World Edit collector shape-switch test should preserve the collector origin across collector-shape switches.")
	TEST_ASSERT(manager.placement_hover_turf == triangle_turf, "World Edit collector shape-switch test should preserve the active preview turf across collector-shape switches.")
	TEST_ASSERT_EQUAL(manager.placement_shape, WORLD_EDIT_SHAPE_POLYLINE, "World Edit collector shape-switch test should switch the selected shape id.")
	var/datum/world_edit_placement_candidate/switched_candidate = manager.get_placement_preview_candidate()
	TEST_ASSERT(istype(switched_candidate, /datum/world_edit_placement_candidate), "World Edit collector shape-switch test should rebuild the preview after switching collector shapes.")
	TEST_ASSERT_EQUAL(switched_candidate.shape_contract?.shape_id, WORLD_EDIT_SHAPE_POLYLINE, "World Edit collector shape-switch test should rebuild the preview for the new collector shape.")

	qdel(manager)

/datum/unit_test/world_edit_corner_slots/manager_runtime/collector_repeat_mode_clears_finished_contour_before_next_attempt/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/world_edit_test_apply_hook/definition = new
	var/datum/world_edit_generator/world_edit_test_apply_hook/generator = allocate(/datum/world_edit_generator/world_edit_test_apply_hook)
	var/turf/center_turf = get_world_edit_test_center_turf()
	var/turf/line_turf = locate(center_turf.x + 2, center_turf.y, center_turf.z)
	var/turf/triangle_turf = locate(center_turf.x + 2, center_turf.y + 2, center_turf.z)
	var/turf/restart_turf = locate(center_turf.x + 4, center_turf.y, center_turf.z)
	TEST_ASSERT_NOTNULL(center_turf, "World Edit collector-repeat reset test center turf was not resolved.")
	TEST_ASSERT_NOTNULL(line_turf, "World Edit collector-repeat reset test line turf was not resolved.")
	TEST_ASSERT_NOTNULL(triangle_turf, "World Edit collector-repeat reset test triangle turf was not resolved.")
	TEST_ASSERT_NOTNULL(restart_turf, "World Edit collector-repeat reset test restart turf was not resolved.")
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, center_turf)

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.current_params = definition.default_params?.Copy() || list()
	manager.placement_shape = WORLD_EDIT_SHAPE_POLYGON
	manager.placement_mode = "repeat"
	manager.placement_dir = NORTH
	manager.placement_click_active = TRUE

	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit collector-repeat reset test should accept the first point.")
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), line_turf), "World Edit collector-repeat reset test should accept the second point.")
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), triangle_turf), "World Edit collector-repeat reset test should accept the third point.")
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit collector-repeat reset test should build the finish preview on the first-point click.")
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit collector-repeat reset test should apply on the repeated finish click.")
	TEST_ASSERT_EQUAL(generator.apply_calls, 1, "World Edit collector-repeat reset test should apply exactly once for the finished contour.")
	TEST_ASSERT_EQUAL(manager.get_placement_collector_point_count(), 0, "World Edit collector-repeat reset test should clear committed collector points after a successful repeat-mode apply.")
	TEST_ASSERT_NULL(manager.get_placement_collector_origin_turf(), "World Edit collector-repeat reset test should clear the collector origin after a successful repeat-mode apply.")
	TEST_ASSERT_NULL(manager.placement_anchor_turf, "World Edit collector-repeat reset test should clear the active anchor after a successful repeat-mode apply.")
	TEST_ASSERT_NULL(manager.placement_hover_turf, "World Edit collector-repeat reset test should clear the preview hover turf after a successful repeat-mode apply.")

	manager.placement_click_active = TRUE
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), restart_turf), "World Edit collector-repeat reset test should let the next click start a fresh contour.")
	TEST_ASSERT_EQUAL(manager.get_placement_collector_point_count(), 1, "World Edit collector-repeat reset test should start a new contour from a single fresh point after the reset.")
	TEST_ASSERT(manager.get_placement_collector_origin_turf() == restart_turf, "World Edit collector-repeat reset test should treat the next click as a new collector origin.")

	qdel(manager)

/datum/unit_test/world_edit_corner_slots/manager_runtime/collector_repeated_last_point_click_arms_confirm_before_apply/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/world_edit_test_apply_hook/definition = new
	var/datum/world_edit_generator/world_edit_test_apply_hook/generator = allocate(/datum/world_edit_generator/world_edit_test_apply_hook)
	var/turf/center_turf = get_world_edit_test_center_turf()
	var/turf/line_turf = locate(center_turf.x + 2, center_turf.y, center_turf.z)
	var/turf/triangle_turf = locate(center_turf.x + 2, center_turf.y + 2, center_turf.z)
	TEST_ASSERT_NOTNULL(center_turf, "World Edit collector-last-point finish test center turf was not resolved.")
	TEST_ASSERT_NOTNULL(line_turf, "World Edit collector-last-point finish test line turf was not resolved.")
	TEST_ASSERT_NOTNULL(triangle_turf, "World Edit collector-last-point finish test triangle turf was not resolved.")
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, center_turf)

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.current_params = definition.default_params?.Copy() || list()
	manager.placement_shape = WORLD_EDIT_SHAPE_POLYLINE
	manager.placement_mode = "single"
	manager.placement_dir = NORTH
	manager.placement_click_active = TRUE

	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit collector-last-point finish test should accept the first point.")
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), line_turf), "World Edit collector-last-point finish test should accept the second point.")
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), triangle_turf), "World Edit collector-last-point finish test should accept the third point.")
	TEST_ASSERT_EQUAL(manager.get_placement_collector_point_count(), 3, "World Edit collector-last-point finish test should keep all committed points before the repeated finish click.")

	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), triangle_turf), "World Edit collector-last-point finish test should build a finish preview when the same last tile is clicked again.")
	TEST_ASSERT_EQUAL(manager.get_placement_collector_point_count(), 3, "World Edit collector-last-point finish test should keep committed points intact while only arming confirmation.")
	TEST_ASSERT(manager.get_placement_collector_origin_turf() == center_turf, "World Edit collector-last-point finish test should preserve the collector origin after the repeated finish click.")
	TEST_ASSERT(manager.placement_hover_turf == triangle_turf, "World Edit collector-last-point finish test should keep the repeated last tile as the preview hover turf.")
	TEST_ASSERT_EQUAL(generator.apply_calls, 0, "World Edit collector-last-point finish test should not apply before the repeated confirm click.")
	var/datum/world_edit_placement_candidate/finish_candidate = manager.get_placement_preview_candidate()
	TEST_ASSERT(istype(finish_candidate, /datum/world_edit_placement_candidate), "World Edit collector-last-point finish test should keep a preview candidate after arming confirmation.")
	TEST_ASSERT(finish_candidate.placement_context["resolved_end_turf"] == triangle_turf, "World Edit collector-last-point finish test should keep the repeated last point as the resolved finish turf.")
	TEST_ASSERT(manager.is_placement_confirm_armed_for_turf(triangle_turf), "World Edit collector-last-point finish test should arm confirmation on the repeated last point.")
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), triangle_turf), "World Edit collector-last-point finish test should accept the repeated confirm click on the armed finish turf.")
	TEST_ASSERT_EQUAL(generator.apply_calls, 1, "World Edit collector-last-point finish test should apply only after the repeated confirm click on the armed finish turf.")

	qdel(manager)

/datum/unit_test/world_edit_corner_slots/manager_runtime/anchor_pair_same_tile_click_keeps_valid_minimum_footprint_placeable/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/world_edit_test_apply_hook/definition = new
	var/datum/world_edit_generator/world_edit_test_apply_hook/generator = allocate(/datum/world_edit_generator/world_edit_test_apply_hook)
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit anchor-pair same-tile valid test center turf was not resolved.")
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, center_turf)

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.current_params = definition.default_params?.Copy() || list()
	manager.placement_shape = WORLD_EDIT_SHAPE_FILLED_RECTANGLE
	manager.placement_mode = "single"
	manager.placement_dir = EAST
	manager.placement_click_active = TRUE

	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit anchor-pair same-tile valid test should accept the first anchor click.")
	TEST_ASSERT(manager.placement_anchor_turf == center_turf, "World Edit anchor-pair same-tile valid test should keep the selected anchor turf after the first click.")

	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit anchor-pair same-tile valid test should build a minimum-size preview when the anchor tile is clicked again.")
	TEST_ASSERT(manager.placement_click_active, "World Edit anchor-pair same-tile valid test should keep placement mode active while the preview waits for confirmation.")
	TEST_ASSERT(manager.placement_anchor_turf == center_turf, "World Edit anchor-pair same-tile valid test should keep the active anchor for the valid minimum-size footprint.")
	var/datum/world_edit_placement_candidate/minimum_candidate = manager.get_placement_preview_candidate()
	TEST_ASSERT(istype(minimum_candidate, /datum/world_edit_placement_candidate), "World Edit anchor-pair same-tile valid test should keep a preview candidate for the valid same-tile footprint.")
	TEST_ASSERT(minimum_candidate.placement_context["resolved_end_turf"] == center_turf, "World Edit anchor-pair same-tile valid test should keep the same tile as the resolved footprint endpoint.")
	TEST_ASSERT(manager.is_placement_confirm_armed_for_turf(center_turf), "World Edit anchor-pair same-tile valid test should arm confirmation for the valid same-tile footprint.")
	TEST_ASSERT_EQUAL(generator.apply_calls, 0, "World Edit anchor-pair same-tile valid test should not apply before the repeated confirmation click.")

	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit anchor-pair same-tile valid test should confirm on the repeated click over the valid same-tile footprint.")
	TEST_ASSERT_EQUAL(generator.apply_calls, 1, "World Edit anchor-pair same-tile valid test should apply the minimum-size footprint after confirmation.")
	TEST_ASSERT(manager.last_apply_success, "World Edit anchor-pair same-tile valid test should record a successful apply for the minimum-size footprint.")

	qdel(manager)

/datum/unit_test/world_edit_corner_slots/manager_runtime/anchor_pair_requires_repeat_click_for_confirm/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/world_edit_test_apply_hook/definition = new
	var/datum/world_edit_generator/world_edit_test_apply_hook/generator = allocate(/datum/world_edit_generator/world_edit_test_apply_hook)
	var/turf/center_turf = get_world_edit_test_center_turf()
	var/turf/end_turf = locate(center_turf.x + 3, center_turf.y, center_turf.z)
	TEST_ASSERT_NOTNULL(center_turf, "World Edit anchor-pair confirm test center turf was not resolved.")
	TEST_ASSERT_NOTNULL(end_turf, "World Edit anchor-pair confirm test end turf was not resolved.")
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, center_turf)

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.current_params = definition.default_params?.Copy() || list()
	manager.placement_shape = WORLD_EDIT_SHAPE_LINE
	manager.placement_mode = "single"
	manager.placement_dir = EAST
	manager.placement_click_active = TRUE

	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit anchor-pair confirm test should accept the first anchor click.")
	TEST_ASSERT(manager.placement_anchor_turf == center_turf, "World Edit anchor-pair confirm test should keep the selected anchor turf.")

	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), end_turf), "World Edit anchor-pair confirm test should build a preview on the second click.")
	TEST_ASSERT_EQUAL(generator.apply_calls, 0, "World Edit anchor-pair confirm test should not apply on the first endpoint click.")
	TEST_ASSERT(manager.placement_anchor_turf == center_turf, "World Edit anchor-pair confirm test should keep the anchor until the repeated click confirms placement.")
	TEST_ASSERT(manager.is_placement_confirm_armed_for_turf(end_turf), "World Edit anchor-pair confirm test should arm confirmation on the chosen endpoint.")

	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), end_turf), "World Edit anchor-pair confirm test should accept the repeated endpoint click.")
	TEST_ASSERT_EQUAL(generator.apply_calls, 1, "World Edit anchor-pair confirm test should apply after the repeated endpoint click.")
	TEST_ASSERT(manager.last_apply_success, "World Edit anchor-pair confirm test should record a successful apply instead of reporting that preview is not ready.")

	qdel(manager)

/datum/unit_test/world_edit_corner_slots/manager_runtime/armed_single_preview_ignores_hover_updates_until_next_click/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/world_edit_test_apply_hook/definition = new
	var/datum/world_edit_generator/world_edit_test_apply_hook/generator = allocate(/datum/world_edit_generator/world_edit_test_apply_hook)
	var/turf/center_turf = get_world_edit_test_center_turf()
	var/turf/other_turf = locate(center_turf.x + 2, center_turf.y + 1, center_turf.z)
	TEST_ASSERT_NOTNULL(center_turf, "World Edit armed-hover test center turf was not resolved.")
	TEST_ASSERT_NOTNULL(other_turf, "World Edit armed-hover test alternate turf was not resolved.")
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, center_turf)

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.current_params = definition.default_params?.Copy() || list()
	manager.placement_shape = WORLD_EDIT_SHAPE_POINT
	manager.placement_mode = "single"
	manager.placement_dir = EAST
	manager.placement_click_active = TRUE

	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit armed-hover test should accept the first placement click.")
	var/datum/world_edit_placement_candidate/armed_candidate = manager.get_placement_preview_candidate()
	TEST_ASSERT(istype(armed_candidate, /datum/world_edit_placement_candidate), "World Edit armed-hover test should keep the armed preview candidate.")
	TEST_ASSERT(manager.is_placement_confirm_armed_for_turf(center_turf), "World Edit armed-hover test should arm confirmation on the selected tile.")

	TEST_ASSERT(manager.handle_safe_placement_hover(user, other_turf), "World Edit armed-hover test should swallow hover updates while a placement confirm is armed.")
	TEST_ASSERT(manager.placement_hover_turf == center_turf, "World Edit armed-hover test should keep the armed preview turf fixed while confirmation is pending.")
	TEST_ASSERT(manager.get_placement_preview_candidate() == armed_candidate, "World Edit armed-hover test should keep the original armed preview candidate while hover is ignored.")
	TEST_ASSERT(manager.is_placement_confirm_armed_for_turf(center_turf), "World Edit armed-hover test should keep the confirm arm valid after ignored hover movement.")

	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit armed-hover test should accept the repeated click on the armed tile.")
	TEST_ASSERT_EQUAL(generator.apply_calls, 1, "World Edit armed-hover test should still apply after ignored hover movement.")

	qdel(manager)

/datum/unit_test/world_edit_corner_slots/manager_runtime/repeated_same_hover_preview_is_noop/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/world_edit_test_apply_hook/definition = new
	var/datum/world_edit_generator/world_edit_test_apply_hook/generator = allocate(/datum/world_edit_generator/world_edit_test_apply_hook)
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit same-hover test center turf was not resolved.")
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, center_turf)

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.current_params = definition.default_params?.Copy() || list()
	manager.placement_shape = WORLD_EDIT_SHAPE_POINT
	manager.placement_mode = "single"
	manager.placement_dir = NORTH
	manager.placement_click_active = TRUE

	TEST_ASSERT(manager.handle_safe_placement_hover(user, center_turf), "World Edit same-hover test should build the initial hover preview.")
	var/datum/world_edit_placement_candidate/first_candidate = manager.get_placement_preview_candidate()
	TEST_ASSERT(istype(first_candidate, /datum/world_edit_placement_candidate), "World Edit same-hover test should keep the first hover preview candidate.")
	TEST_ASSERT(first_candidate.hover_only, "World Edit same-hover test should keep the initial hover candidate in hover-only mode.")
	TEST_ASSERT_EQUAL(generator.build_plan_calls, 1, "World Edit same-hover test should build exactly one preview plan for the first hover request.")

	TEST_ASSERT(manager.handle_safe_placement_hover(user, center_turf), "World Edit same-hover test should treat an identical hover request as a no-op success.")
	TEST_ASSERT_EQUAL(generator.build_plan_calls, 1, "World Edit same-hover test should not rebuild the preview plan for the same hover request.")
	TEST_ASSERT(manager.get_placement_preview_candidate() == first_candidate, "World Edit same-hover test should keep the existing preview candidate instead of rebuilding it.")

	qdel(manager)

/datum/unit_test/world_edit_corner_slots/manager_runtime/mode_switch_keeps_active_anchor_pair_preview_context/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/world_edit_test_apply_hook/definition = new
	var/datum/world_edit_generator/world_edit_test_apply_hook/generator = allocate(/datum/world_edit_generator/world_edit_test_apply_hook)
	var/turf/center_turf = get_world_edit_test_center_turf()
	var/turf/end_turf = locate(center_turf.x + 3, center_turf.y, center_turf.z)
	TEST_ASSERT_NOTNULL(center_turf, "World Edit mode-switch preview test center turf was not resolved.")
	TEST_ASSERT_NOTNULL(end_turf, "World Edit mode-switch preview test end turf was not resolved.")
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, center_turf)

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.current_params = definition.default_params?.Copy() || list()
	manager.placement_shape = WORLD_EDIT_SHAPE_LINE
	manager.placement_mode = "single"
	manager.placement_dir = EAST
	manager.placement_click_active = TRUE

	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit mode-switch preview test should accept the first anchor click.")
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), end_turf), "World Edit mode-switch preview test should build the initial anchor-pair preview.")
	TEST_ASSERT(manager.handle_placement_ui_action(user, "set_placement_mode", list("mode" = "repeat")), "World Edit mode-switch preview test should accept switching placement mode during an active preview.")
	TEST_ASSERT(manager.placement_anchor_turf == center_turf, "World Edit mode-switch preview test should preserve the active anchor across a placement-mode switch.")
	TEST_ASSERT(manager.placement_hover_turf == end_turf, "World Edit mode-switch preview test should preserve the preview target across a placement-mode switch.")
	TEST_ASSERT_EQUAL(manager.placement_mode, "repeat", "World Edit mode-switch preview test should persist the new placement mode.")
	var/datum/world_edit_placement_candidate/mode_switched_candidate = manager.get_placement_preview_candidate()
	TEST_ASSERT(istype(mode_switched_candidate, /datum/world_edit_placement_candidate), "World Edit mode-switch preview test should rebuild the preview after switching placement mode.")
	TEST_ASSERT(mode_switched_candidate.placement_context["start_turf"] == center_turf, "World Edit mode-switch preview test should keep the original anchor in the rebuilt preview context.")
	TEST_ASSERT(mode_switched_candidate.placement_context["resolved_end_turf"] == end_turf, "World Edit mode-switch preview test should keep the original end turf in the rebuilt preview context.")

	qdel(manager)

/datum/unit_test/world_edit_corner_slots/manager_runtime/single_mode_apply_failure_keeps_click_mode_active/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/world_edit_test_apply_failure_hook/definition = new
	var/datum/world_edit_generator/world_edit_test_apply_failure_hook/generator = allocate(/datum/world_edit_generator/world_edit_test_apply_failure_hook)
	var/turf/center_turf = get_world_edit_test_center_turf()
	var/turf/other_turf = locate(center_turf.x + 2, center_turf.y, center_turf.z)
	TEST_ASSERT_NOTNULL(center_turf, "World Edit single-failure test center turf was not resolved.")
	TEST_ASSERT_NOTNULL(other_turf, "World Edit single-failure test alternate turf was not resolved.")
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, center_turf)

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.current_params = definition.default_params?.Copy() || list()
	manager.placement_shape = WORLD_EDIT_SHAPE_POINT
	manager.placement_mode = "single"
	manager.placement_dir = NORTH
	manager.placement_click_active = TRUE

	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit single-failure test should accept the initial placement click.")
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit single-failure test should accept the repeated confirm click and run apply.")
	TEST_ASSERT_EQUAL(generator.apply_calls, 1, "World Edit single-failure test should run the failing apply exactly once.")
	TEST_ASSERT(!manager.last_apply_success, "World Edit single-failure test should record the failed apply result.")
	TEST_ASSERT(manager.placement_click_active, "World Edit single-failure test should keep click-mode active after a failed apply in single mode.")

	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), other_turf), "World Edit single-failure test should let the user start another attempt immediately after the failed apply.")
	TEST_ASSERT(manager.is_placement_confirm_armed_for_turf(other_turf), "World Edit single-failure test should rebuild and arm a new preview after the failed apply.")

	qdel(manager)

/datum/unit_test/world_edit_corner_slots/manager_runtime/anchor_pair_clamp_arms_confirm_on_resolved_preview_turf/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/world_edit_test_outpost_clamp/definition = new
	var/datum/world_edit_generator/outpost_radius/world_edit_test_clamp/generator = allocate(/datum/world_edit_generator/outpost_radius/world_edit_test_clamp)
	var/turf/center_turf = get_world_edit_test_center_turf()
	var/turf/clamped_turf = locate(center_turf.x + 2, center_turf.y, center_turf.z)
	var/turf/requested_turf = locate(center_turf.x + 3, center_turf.y, center_turf.z)
	TEST_ASSERT_NOTNULL(center_turf, "World Edit anchor-pair clamp-confirm test center turf was not resolved.")
	TEST_ASSERT_NOTNULL(clamped_turf, "World Edit anchor-pair clamp-confirm test clamped turf was not resolved.")
	TEST_ASSERT_NOTNULL(requested_turf, "World Edit anchor-pair clamp-confirm test requested turf was not resolved.")
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, center_turf)

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.current_params = definition.default_params?.Copy() || list()
	manager.placement_shape = WORLD_EDIT_SHAPE_LINE
	manager.placement_mode = "single"
	manager.placement_dir = EAST
	manager.placement_click_active = TRUE

	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit anchor-pair clamp-confirm test should accept the first anchor click.")
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), requested_turf), "World Edit anchor-pair clamp-confirm test should build a clamped preview on the second click.")
	var/datum/world_edit_placement_candidate/candidate = manager.get_placement_preview_candidate()
	TEST_ASSERT(istype(candidate, /datum/world_edit_placement_candidate), "World Edit anchor-pair clamp-confirm test should keep the clamped preview candidate.")
	TEST_ASSERT(candidate.placement_context["requested_end_turf"] == requested_turf, "World Edit anchor-pair clamp-confirm test should keep the original requested endpoint on the preview context.")
	TEST_ASSERT(candidate.placement_context["resolved_end_turf"] == clamped_turf, "World Edit anchor-pair clamp-confirm test should expose the clamped endpoint on the preview context.")
	TEST_ASSERT(manager.placement_hover_turf == clamped_turf, "World Edit anchor-pair clamp-confirm test should move the preview hover turf to the clamped endpoint.")
	TEST_ASSERT(manager.is_placement_confirm_armed_for_turf(clamped_turf), "World Edit anchor-pair clamp-confirm test should arm confirmation on the resolved clamped endpoint.")
	TEST_ASSERT(!manager.is_placement_confirm_armed_for_turf(requested_turf), "World Edit anchor-pair clamp-confirm test should not keep confirmation armed on the rejected requested endpoint.")

	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), clamped_turf), "World Edit anchor-pair clamp-confirm test should accept the repeated click on the clamped endpoint.")
	TEST_ASSERT_EQUAL(generator.apply_calls, 1, "World Edit anchor-pair clamp-confirm test should apply after repeating the click on the resolved endpoint.")
	TEST_ASSERT(manager.last_apply_success, "World Edit anchor-pair clamp-confirm test should record a successful apply on the resolved endpoint.")

	qdel(manager)

/datum/unit_test/world_edit_corner_slots/manager_runtime/anchor_pair_hover_only_preview_does_not_run_outpost_clamp/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/world_edit_test_outpost_clamp/definition = new
	var/datum/world_edit_generator/outpost_radius/world_edit_test_clamp/generator = allocate(/datum/world_edit_generator/outpost_radius/world_edit_test_clamp)
	var/turf/center_turf = get_world_edit_test_center_turf()
	var/turf/requested_turf = locate(center_turf.x + 3, center_turf.y, center_turf.z)
	TEST_ASSERT_NOTNULL(center_turf, "World Edit anchor-pair hover-no-clamp test center turf was not resolved.")
	TEST_ASSERT_NOTNULL(requested_turf, "World Edit anchor-pair hover-no-clamp test requested turf was not resolved.")
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, center_turf)

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.current_params = definition.default_params?.Copy() || list()
	manager.placement_shape = WORLD_EDIT_SHAPE_LINE
	manager.placement_mode = "single"
	manager.placement_dir = EAST
	manager.placement_click_active = TRUE

	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit anchor-pair hover-no-clamp test should accept the first anchor click.")
	TEST_ASSERT(!manager.handle_safe_placement_hover(user, requested_turf), "World Edit anchor-pair hover-no-clamp test should keep the hover-only preview invalid when only the unclamped endpoint is available.")
	var/datum/world_edit_placement_candidate/candidate = manager.get_placement_preview_candidate()
	TEST_ASSERT(istype(candidate, /datum/world_edit_placement_candidate), "World Edit anchor-pair hover-no-clamp test should still keep a hover candidate for the requested endpoint.")
	TEST_ASSERT(candidate.hover_only, "World Edit anchor-pair hover-no-clamp test should keep hover-only semantics on the stored candidate.")
	TEST_ASSERT(candidate.placement_context["requested_end_turf"] == requested_turf, "World Edit anchor-pair hover-no-clamp test should keep the original requested endpoint on the hover candidate context.")
	TEST_ASSERT(candidate.placement_context["resolved_end_turf"] == requested_turf, "World Edit anchor-pair hover-no-clamp test should not clamp the resolved endpoint during hover-only preview.")
	TEST_ASSERT(!candidate.is_preview_ready(), "World Edit anchor-pair hover-no-clamp test should avoid synthesizing a valid clamped plan during hover-only preview.")
	TEST_ASSERT(manager.placement_hover_turf == requested_turf, "World Edit anchor-pair hover-no-clamp test should leave the hover turf on the actual requested endpoint.")

	qdel(manager)

/datum/unit_test/world_edit_corner_slots/manager_runtime/placement_preview_render_token_uses_turf_contents_not_list_identity/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/turf/center_turf = get_world_edit_test_center_turf()
	var/turf/other_turf = locate(center_turf.x + 1, center_turf.y, center_turf.z)
	TEST_ASSERT_NOTNULL(center_turf, "World Edit preview-render-token test center turf was not resolved.")
	TEST_ASSERT_NOTNULL(other_turf, "World Edit preview-render-token test sibling turf was not resolved.")

	var/datum/world_edit_preview_model/first_preview_model = new
	first_preview_model.final_turfs = list(center_turf, other_turf)
	first_preview_model.generator_effect_turfs = list(center_turf)

	var/datum/world_edit_preview_model/second_preview_model = new
	second_preview_model.final_turfs = list(center_turf, other_turf)
	second_preview_model.generator_effect_turfs = list(center_turf)

	var/first_render_token = manager.build_placement_preview_render_token(first_preview_model)
	var/second_render_token = manager.build_placement_preview_render_token(second_preview_model)
	TEST_ASSERT_EQUAL(first_render_token, second_render_token, "World Edit preview-render-token test should keep identical preview contents stable across fresh list instances.")

	qdel(manager)

/datum/unit_test/world_edit_corner_slots/manager_runtime/collector_clamp_arms_confirm_on_resolved_finish_turf/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/world_edit_test_outpost_clamp/definition = new
	var/datum/world_edit_generator/outpost_radius/world_edit_test_clamp/generator = allocate(/datum/world_edit_generator/outpost_radius/world_edit_test_clamp)
	var/turf/center_turf = get_world_edit_test_center_turf()
	var/turf/line_turf = locate(center_turf.x + 2, center_turf.y, center_turf.z)
	var/turf/triangle_turf = locate(center_turf.x + 2, center_turf.y + 2, center_turf.z)
	var/turf/clamped_turf = locate(center_turf.x + 1, center_turf.y + 1, center_turf.z)
	TEST_ASSERT_NOTNULL(center_turf, "World Edit collector clamp-confirm test center turf was not resolved.")
	TEST_ASSERT_NOTNULL(line_turf, "World Edit collector clamp-confirm test line turf was not resolved.")
	TEST_ASSERT_NOTNULL(triangle_turf, "World Edit collector clamp-confirm test triangle turf was not resolved.")
	TEST_ASSERT_NOTNULL(clamped_turf, "World Edit collector clamp-confirm test clamped turf was not resolved.")
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, center_turf)

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.current_params = definition.default_params?.Copy() || list()
	manager.placement_shape = WORLD_EDIT_SHAPE_POLYLINE
	manager.placement_mode = "single"
	manager.placement_dir = EAST
	manager.placement_click_active = TRUE

	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit collector clamp-confirm test should accept the first point.")
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), line_turf), "World Edit collector clamp-confirm test should accept the second point.")
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), triangle_turf), "World Edit collector clamp-confirm test should accept the third point.")
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit collector clamp-confirm test should build a clamped finish preview when the first point is clicked again.")
	var/datum/world_edit_placement_candidate/collector_candidate = manager.get_placement_preview_candidate()
	TEST_ASSERT(istype(collector_candidate, /datum/world_edit_placement_candidate), "World Edit collector clamp-confirm test should keep the clamped finish preview candidate.")
	TEST_ASSERT(collector_candidate.placement_context["requested_end_turf"] == center_turf, "World Edit collector clamp-confirm test should keep the requested finish turf in the preview context.")
	TEST_ASSERT(collector_candidate.placement_context["resolved_end_turf"] == clamped_turf, "World Edit collector clamp-confirm test should expose the clamped finish turf in the preview context.")
	TEST_ASSERT(manager.is_placement_confirm_armed_for_turf(clamped_turf), "World Edit collector clamp-confirm test should arm confirmation on the resolved clamped finish turf.")
	TEST_ASSERT(!manager.is_placement_confirm_armed_for_turf(center_turf), "World Edit collector clamp-confirm test should not keep confirmation armed on the rejected first-point turf.")

	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), clamped_turf), "World Edit collector clamp-confirm test should accept the repeated click on the resolved clamped finish turf.")
	TEST_ASSERT_EQUAL(generator.apply_calls, 1, "World Edit collector clamp-confirm test should apply after repeating the click on the resolved collector finish turf.")
	TEST_ASSERT(manager.last_apply_success, "World Edit collector clamp-confirm test should record a successful apply on the resolved collector finish turf.")

	qdel(manager)

/datum/unit_test/world_edit_corner_slots/manager_runtime/outpost_anchor_pair_same_tile_click_cancels_current_attempt/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/outpost_radius/definition = new
	var/datum/world_edit_generator/outpost_radius/generator = allocate(/datum/world_edit_generator/outpost_radius)
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit outpost same-tile anchor cancel test center turf was not resolved.")
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, center_turf)

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.current_params = definition.default_params?.Copy() || list()
	manager.current_params["radius"] = 1
	manager.current_params["opening_width"] = "broad"
	manager.placement_shape = WORLD_EDIT_SHAPE_LINE
	manager.placement_mode = "single"
	manager.placement_dir = EAST
	manager.placement_click_active = TRUE

	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit outpost same-tile anchor cancel test should accept the first anchor click.")
	TEST_ASSERT(manager.placement_anchor_turf == center_turf, "World Edit outpost same-tile anchor cancel test should keep the selected anchor turf after the first click.")

	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit outpost same-tile anchor cancel test should accept the repeated same-tile click.")
	TEST_ASSERT(manager.placement_click_active, "World Edit outpost same-tile anchor cancel test should keep placement mode active after resetting the current attempt.")
	TEST_ASSERT_NULL(manager.placement_anchor_turf, "World Edit outpost same-tile anchor cancel test should clear the active anchor instead of leaving an invalid preview state.")
	TEST_ASSERT_NULL(manager.get_placement_preview_candidate(), "World Edit outpost same-tile anchor cancel test should clear the preview candidate after the reset.")
	TEST_ASSERT(!manager.is_placement_confirm_armed_for_turf(center_turf), "World Edit outpost same-tile anchor cancel test should not arm confirmation for the degenerate same-tile click.")
	TEST_ASSERT(findtext("[manager.last_preview_message]", "конечная точка совпала с опорной"), "World Edit outpost same-tile anchor cancel test should report the reset reason instead of surfacing the outpost support error.")

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
	manager.current_params = build_outpost_test_params("none", "crossroads", "layout", 1)

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
		TEST_ASSERT(istype(plan, /datum/world_edit_plan), "World Edit outpost integration should return a plan datum or an explicit support error for shape '[shape_id]'.")
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
		TEST_ASSERT(istype(plan, /datum/world_edit_plan), "World Edit blueprint integration should return a plan datum or an explicit support error for shape '[shape_id]'.")
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
		TEST_ASSERT(istype(plan, /datum/world_edit_plan), "World Edit destruction integration should return a plan datum or an explicit support error for shape '[shape_id]'.")
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
	TEST_ASSERT(istype(shape_contract, /datum/world_edit_shape_contract), "World Edit shape-contract service should return a shape contract datum.")
	TEST_ASSERT_EQUAL(shape_contract.shape_id, WORLD_EDIT_SHAPE_LINE, "World Edit shape-contract service should preserve the requested shape id.")
	TEST_ASSERT_EQUAL(shape_contract.interaction_kind, "anchor_pair", "World Edit shape-contract service should expose the interaction kind.")
	TEST_ASSERT(length(shape_contract.anchor_turfs) > 0, "World Edit shape-contract service should keep the resolved footprint turfs.")

	var/datum/world_edit_preview_model/preview_model = GLOB.world_edit_shape_preview.build_shape_preview(shape_contract)
	TEST_ASSERT(istype(preview_model, /datum/world_edit_preview_model), "World Edit preview-model service should return a preview model datum.")
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
	TEST_ASSERT(istype(locked_candidate, /datum/world_edit_placement_candidate), "World Edit locked-preview test should keep the resolved preview candidate in session state.")
	TEST_ASSERT(manager.placement_hover_turf == center_turf, "World Edit locked-preview test should keep the confirmed turf as the preview hover anchor.")

	manager.set_placement_preview_locked(TRUE, center_turf)
	TEST_ASSERT(manager.is_placement_preview_locked(), "World Edit locked-preview test should expose the pending-confirmation lock flag.")
	TEST_ASSERT(manager.handle_safe_placement_hover(user, other_turf), "World Edit locked-preview test should swallow hover updates while confirmation is pending.")
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), other_turf), "World Edit locked-preview test should swallow click updates while confirmation is pending.")
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
	TEST_ASSERT(istype(plan, /datum/world_edit_plan), "World Edit standard-preview layer test should build a placement plan from the shared shape result.")
	plan.metadata["center_turf"] = center_turf
	TEST_ASSERT(islist(plan.metadata["shape_result"]), "World Edit standard-preview layer test should keep the canonical shape snapshot on the plan metadata.")

	TEST_ASSERT(manager.render_plan_preview_with_placement_layers(null, plan, effective_params), "World Edit standard-preview layer test should build grouped placement layers from a normal preview plan.")
	var/datum/world_edit_placement_candidate/preview_candidate = manager.get_placement_preview_candidate()
	TEST_ASSERT(istype(preview_candidate, /datum/world_edit_placement_candidate), "World Edit standard-preview layer test should store the synthesized placement candidate.")
	TEST_ASSERT(preview_candidate.plan == plan, "World Edit standard-preview layer test should keep the original preview plan on the synthesized candidate.")
	TEST_ASSERT(preview_candidate.placement_context["start_turf"] == center_turf, "World Edit standard-preview layer test should keep the original shape origin on the synthesized candidate.")
	TEST_ASSERT(preview_candidate.placement_context["resolved_end_turf"] == end_turf, "World Edit standard-preview layer test should restore the resolved shape endpoint from plan metadata.")
	TEST_ASSERT(length(manager.placement_preview_anchor_turfs) > 0, "World Edit standard-preview layer test should expose anchor tiles.")
	TEST_ASSERT(length(manager.placement_preview_edge_turfs) > 0, "World Edit standard-preview layer test should expose edge tiles.")
	TEST_ASSERT(length(manager.placement_preview_final_turfs) > 0, "World Edit standard-preview layer test should expose final footprint tiles.")
	TEST_ASSERT(length(manager.placement_preview_generator_effect_turfs) > 0, "World Edit standard-preview layer test should expose generator effect tiles.")

	qdel(manager)

/datum/unit_test/world_edit_corner_slots/manager_runtime/standard_preview_fails_closed_without_stamped_shape_result/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/world_edit_test_apply_hook/definition = new
	var/datum/world_edit_generator/world_edit_test_apply_hook/generator = allocate(/datum/world_edit_generator/world_edit_test_apply_hook)
	var/turf/center_turf = get_world_edit_test_center_turf()
	var/turf/end_turf = locate(center_turf.x + 3, center_turf.y, center_turf.z)
	TEST_ASSERT_NOTNULL(center_turf, "World Edit standard-preview fail-closed test center turf was not resolved.")
	TEST_ASSERT_NOTNULL(end_turf, "World Edit standard-preview fail-closed test end turf was not resolved.")

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.current_params = definition.default_params?.Copy() || list()
	manager.placement_shape = WORLD_EDIT_SHAPE_LINE
	manager.placement_mode = "single"
	manager.placement_dir = EAST

	var/list/effective_params = manager.build_effective_generator_params()
	var/list/shape_result = GLOB.world_edit_placement_shapes.world_edit_build_shape_turfs(WORLD_EDIT_SHAPE_LINE, center_turf, end_turf, effective_params, EAST)
	TEST_ASSERT(!shape_result["error"], "World Edit standard-preview fail-closed test should resolve the shared line footprint.")

	var/datum/world_edit_plan/plan = manager.build_safe_placement_plan_from_shape_result(null, WORLD_EDIT_SHAPE_LINE, shape_result, center_turf, end_turf)
	TEST_ASSERT(istype(plan, /datum/world_edit_plan), "World Edit standard-preview fail-closed test should build a placement plan from the shared shape result.")
	plan.metadata["center_turf"] = center_turf
	plan.metadata -= "shape_result"

	TEST_ASSERT(!manager.render_plan_preview_with_placement_layers(null, plan, effective_params), "World Edit standard-preview fail-closed test should refuse to rehydrate preview layers when the stamped shape snapshot is missing.")
	TEST_ASSERT_NULL(manager.get_placement_preview_candidate(), "World Edit standard-preview fail-closed test should not synthesize a preview candidate from live manager state when plan shape metadata is missing.")

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
	TEST_ASSERT(manager.update_placement_collector_runtime_state(null, hover_turf, "", TRUE, TRUE), "World Edit manager preview should build a hover-time polygon collector preview.")
	TEST_ASSERT(length(manager.placement_preview_closure_turfs) > 0, "World Edit polygon collector preview should expose closure tiles on hover.")

	manager.placement_shape = "polyline"
	TEST_ASSERT(manager.update_placement_collector_runtime_state(null, hover_turf, "", TRUE, TRUE), "World Edit manager preview should build a hover-time polyline collector preview.")
	TEST_ASSERT_EQUAL(length(manager.placement_preview_closure_turfs), 0, "World Edit polyline collector preview should not expose closure tiles.")

	manager.placement_shape = "custom_mask"
	manager.set_placement_collector_points(list(
		list("x" = 0, "y" = 0),
		list("x" = 2, "y" = 0),
		list("x" = 2, "y" = 2),
	))
	TEST_ASSERT(manager.update_placement_collector_runtime_state(null, hover_turf, "", TRUE, FALSE), "World Edit manager preview should build a custom-mask collector preview.")
	TEST_ASSERT_EQUAL(length(manager.placement_preview_edge_turfs), 0, "World Edit custom-mask collector preview should not expose edge tiles.")

	manager.reset_placement_runtime()
	TEST_ASSERT(isnull(manager.placement_hover_turf), "World Edit manager reset should clear the hover turf.")
	TEST_ASSERT_EQUAL(length(manager.placement_preview_anchor_turfs), 0, "World Edit manager reset should clear anchor preview tiles.")
	TEST_ASSERT_EQUAL(length(manager.placement_preview_generator_effect_turfs), 0, "World Edit manager reset should clear generator effect preview tiles.")

	qdel(manager)

/datum/unit_test/world_edit_corner_slots/manager_runtime/store_preview_candidate_reuses_snapshot_layers_and_render_token/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/world_edit_test_apply_hook/definition = new
	var/datum/world_edit_generator/world_edit_test_apply_hook/generator = allocate(/datum/world_edit_generator/world_edit_test_apply_hook)
	var/turf/center_turf = get_world_edit_test_center_turf()
	var/turf/end_turf = locate(center_turf.x + 3, center_turf.y, center_turf.z)
	TEST_ASSERT_NOTNULL(center_turf, "World Edit preview-token test center turf was not resolved.")
	TEST_ASSERT_NOTNULL(end_turf, "World Edit preview-token test end turf was not resolved.")

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.current_params = definition.default_params?.Copy() || list()

	var/datum/world_edit_placement_candidate/candidate = manager.resolve_placement_candidate(null, center_turf, end_turf)
	TEST_ASSERT(istype(candidate, /datum/world_edit_placement_candidate), "World Edit preview-token test should build a placement candidate.")
	TEST_ASSERT(istype(candidate.preview_model, /datum/world_edit_preview_model), "World Edit preview-token test should build a preview model for the placement candidate.")
	TEST_ASSERT(length("[candidate.preview_render_token]"), "World Edit preview-token test should stamp a preview render token on the placement candidate.")

	var/anchor_ref = islist(candidate.preview_model.anchor_turfs) ? "[REF(candidate.preview_model.anchor_turfs)]" : ""
	var/final_ref = islist(candidate.preview_model.final_turfs) ? "[REF(candidate.preview_model.final_turfs)]" : ""
	manager.store_placement_preview_candidate(candidate)
	TEST_ASSERT_EQUAL(manager.placement_preview_render_token, candidate.preview_render_token, "World Edit preview-token test should preserve the candidate render token in preview session state.")
	TEST_ASSERT_EQUAL(islist(manager.placement_preview_anchor_turfs) ? "[REF(manager.placement_preview_anchor_turfs)]" : "", anchor_ref, "World Edit preview-token test should reuse the anchor-layer snapshot instead of copying it again.")
	TEST_ASSERT_EQUAL(islist(manager.placement_preview_final_turfs) ? "[REF(manager.placement_preview_final_turfs)]" : "", final_ref, "World Edit preview-token test should reuse the final-layer snapshot instead of copying it again.")

	var/list/groups = manager.get_placement_preview_groups()
	TEST_ASSERT_EQUAL("[groups["preview_render_token"]]", "[candidate.preview_render_token]", "World Edit preview-token test should expose the stored render token through grouped preview payloads.")

	qdel(manager)

/datum/unit_test/world_edit_corner_slots/manager_runtime/render_cycle_preserves_last_resolved_placement_candidate_cache/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/world_edit_test_apply_hook/definition = new
	var/datum/world_edit_generator/world_edit_test_apply_hook/generator = allocate(/datum/world_edit_generator/world_edit_test_apply_hook)
	var/turf/center_turf = get_world_edit_test_center_turf()
	var/turf/end_turf = locate(center_turf.x + 3, center_turf.y, center_turf.z)
	TEST_ASSERT_NOTNULL(center_turf, "World Edit memoization test center turf was not resolved.")
	TEST_ASSERT_NOTNULL(end_turf, "World Edit memoization test end turf was not resolved.")

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.current_params = definition.default_params?.Copy() || list()
	manager.placement_shape = WORLD_EDIT_SHAPE_LINE
	manager.placement_mode = "single"
	manager.placement_dir = EAST

	var/datum/world_edit_placement_candidate/initial_candidate = manager.resolve_placement_candidate(null, center_turf, end_turf)
	TEST_ASSERT(istype(initial_candidate, /datum/world_edit_placement_candidate), "World Edit memoization test should build the initial placement candidate.")
	TEST_ASSERT(initial_candidate.is_preview_ready(), "World Edit memoization test should build a preview-ready initial candidate.")
	var/initial_ref = "[REF(initial_candidate)]"

	manager.render_safe_placement_preview(initial_candidate)

	var/datum/world_edit_placement_candidate/reused_candidate = manager.resolve_placement_candidate(null, center_turf, end_turf)
	TEST_ASSERT(istype(reused_candidate, /datum/world_edit_placement_candidate), "World Edit memoization test should resolve a candidate after the render cycle.")
	TEST_ASSERT_EQUAL("[REF(reused_candidate)]", initial_ref, "World Edit memoization test should reuse the cached resolved candidate after rendering the preview.")

	manager.reset_preview_runtime()
	var/datum/world_edit_placement_candidate/fresh_candidate = manager.resolve_placement_candidate(null, center_turf, end_turf)
	TEST_ASSERT(istype(fresh_candidate, /datum/world_edit_placement_candidate), "World Edit memoization test should still resolve a candidate after the runtime reset.")
	TEST_ASSERT_NOTEQUAL("[REF(fresh_candidate)]", initial_ref, "World Edit memoization test should clear the cached resolved candidate on a full runtime reset.")

	qdel(manager)

/datum/unit_test/world_edit_corner_slots/manager_runtime/cached_resolve_skips_rebuilding_preview_candidate/Run()
	var/datum/world_edit_manager/world_edit_test_cache_probe/manager = new
	var/datum/world_edit_generator_definition/world_edit_test_apply_hook/definition = new
	var/datum/world_edit_generator/world_edit_test_apply_hook/generator = allocate(/datum/world_edit_generator/world_edit_test_apply_hook)
	var/turf/center_turf = get_world_edit_test_center_turf()
	var/turf/end_turf = locate(center_turf.x + 3, center_turf.y, center_turf.z)
	TEST_ASSERT_NOTNULL(center_turf, "World Edit resolve-cache build-skip test center turf was not resolved.")
	TEST_ASSERT_NOTNULL(end_turf, "World Edit resolve-cache build-skip test end turf was not resolved.")

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.current_params = definition.default_params?.Copy() || list()
	manager.placement_shape = WORLD_EDIT_SHAPE_LINE
	manager.placement_mode = "single"
	manager.placement_dir = EAST

	var/datum/world_edit_placement_candidate/initial_candidate = manager.resolve_placement_candidate(null, center_turf, end_turf)
	TEST_ASSERT(istype(initial_candidate, /datum/world_edit_placement_candidate), "World Edit resolve-cache build-skip test should build the initial placement candidate.")
	TEST_ASSERT(initial_candidate.is_preview_ready(), "World Edit resolve-cache build-skip test should cache a preview-ready initial candidate.")
	TEST_ASSERT_EQUAL(manager.build_placement_candidate_calls, 1, "World Edit resolve-cache build-skip test should build exactly one preview candidate on the first resolve.")

	var/datum/world_edit_placement_candidate/reused_candidate = manager.resolve_placement_candidate(null, center_turf, end_turf)
	TEST_ASSERT(istype(reused_candidate, /datum/world_edit_placement_candidate), "World Edit resolve-cache build-skip test should still resolve a candidate on the repeated query.")
	TEST_ASSERT_EQUAL("[REF(reused_candidate)]", "[REF(initial_candidate)]", "World Edit resolve-cache build-skip test should reuse the cached candidate object on an identical repeated query.")
	TEST_ASSERT_EQUAL(manager.build_placement_candidate_calls, 1, "World Edit resolve-cache build-skip test should not rebuild the preview candidate before returning the cached result.")

	qdel(manager)

/datum/unit_test/world_edit_corner_slots/manager_runtime/runtime_status_tracks_hover_render_and_cache_churn/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/world_edit_test_apply_hook/definition = new
	var/datum/world_edit_generator/world_edit_test_apply_hook/generator = allocate(/datum/world_edit_generator/world_edit_test_apply_hook)
	var/turf/center_turf = get_world_edit_test_center_turf()
	var/turf/end_turf = locate(center_turf.x + 3, center_turf.y, center_turf.z)
	TEST_ASSERT_NOTNULL(center_turf, "World Edit runtime-status hover/render test center turf was not resolved.")
	TEST_ASSERT_NOTNULL(end_turf, "World Edit runtime-status hover/render test end turf was not resolved.")

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.current_params = definition.default_params?.Copy() || list()
	manager.placement_shape = WORLD_EDIT_SHAPE_LINE
	manager.placement_mode = "single"
	manager.placement_dir = EAST

	var/datum/world_edit_placement_candidate/initial_candidate = manager.resolve_placement_candidate(null, center_turf, end_turf, null, TRUE)
	TEST_ASSERT(istype(initial_candidate, /datum/world_edit_placement_candidate), "World Edit runtime-status hover/render test should build the initial hover candidate.")
	TEST_ASSERT(initial_candidate.is_preview_ready(), "World Edit runtime-status hover/render test should build a preview-ready hover candidate.")

	manager.render_safe_placement_preview(initial_candidate)
	manager.render_safe_placement_preview(initial_candidate)

	var/datum/world_edit_placement_candidate/reused_candidate = manager.resolve_placement_candidate(null, center_turf, end_turf, null, TRUE)
	TEST_ASSERT(istype(reused_candidate, /datum/world_edit_placement_candidate), "World Edit runtime-status hover/render test should resolve a repeated hover candidate.")
	TEST_ASSERT_EQUAL("[REF(reused_candidate)]", "[REF(initial_candidate)]", "World Edit runtime-status hover/render test should reuse the cached hover candidate on the repeated resolve.")

	var/list/runtime_status = build_runtime_status_lookup(manager.build_runtime_status_entries())
	TEST_ASSERT_EQUAL(runtime_status["Hover resolve"], "2", "World Edit runtime-status hover/render test should report both hover resolves.")
	TEST_ASSERT_EQUAL(runtime_status["Cache"], "1/1", "World Edit runtime-status hover/render test should expose one cache hit and one miss after the repeated hover resolve.")
	TEST_ASSERT_EQUAL(runtime_status["Render rebuilds"], "1", "World Edit runtime-status hover/render test should expose a single preview image rebuild for the first render.")
	TEST_ASSERT_EQUAL(runtime_status["Render skips"], "1", "World Edit runtime-status hover/render test should expose the token-reuse skip for the second identical render.")

	qdel(manager)

/datum/unit_test/world_edit_corner_slots/manager_runtime/runtime_status_tracks_outpost_clamp_skip_and_success/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/world_edit_test_outpost_clamp/definition = new
	var/datum/world_edit_generator/outpost_radius/world_edit_test_clamp/generator = allocate(/datum/world_edit_generator/outpost_radius/world_edit_test_clamp)
	var/turf/center_turf = get_world_edit_test_center_turf()
	var/turf/requested_turf = locate(center_turf.x + 3, center_turf.y, center_turf.z)
	TEST_ASSERT_NOTNULL(center_turf, "World Edit runtime-status clamp test center turf was not resolved.")
	TEST_ASSERT_NOTNULL(requested_turf, "World Edit runtime-status clamp test requested turf was not resolved.")
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, center_turf)

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.current_params = definition.default_params?.Copy() || list()
	manager.placement_shape = WORLD_EDIT_SHAPE_LINE
	manager.placement_mode = "single"
	manager.placement_dir = EAST
	manager.placement_click_active = TRUE

	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), center_turf), "World Edit runtime-status clamp test should accept the first anchor click.")
	TEST_ASSERT(!manager.handle_safe_placement_hover(user, requested_turf), "World Edit runtime-status clamp test should keep the hover-only preview invalid on the unclamped endpoint.")
	TEST_ASSERT(manager.handle_safe_placement_click(user, list2params(list(LEFT_CLICK = 1)), requested_turf), "World Edit runtime-status clamp test should build the clamped preview on click.")

	var/list/runtime_status = build_runtime_status_lookup(manager.build_runtime_status_entries())
	TEST_ASSERT_EQUAL(runtime_status["Clamp hover skip"], "1", "World Edit runtime-status clamp test should record the skipped hover-only clamp path.")
	TEST_ASSERT_EQUAL(runtime_status["Clamp tries"], "1", "World Edit runtime-status clamp test should record the single click-time clamp attempt.")
	TEST_ASSERT_EQUAL(runtime_status["Clamp ok"], "1", "World Edit runtime-status clamp test should record the successful click-time clamp result.")

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

	var/list/params = build_outpost_test_params("none", "crossroads", "layout", 1)
	params["shape_line_length"] = 4
	params["shape_line_spacing"] = 1
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

	var/list/params = build_outpost_test_params("none", "crossroads", "layout", 1)
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

/datum/unit_test/world_edit_corner_slots/outpost_scatter_cluster_stays_connected_for_large_radius/Run()
	var/datum/world_edit_generator/outpost_radius/generator = allocate(/datum/world_edit_generator/outpost_radius)
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit outpost scatter-cluster connectivity test center turf was not resolved.")

	var/list/params = build_outpost_test_params("none", "crossroads", "layout", 1)
	params["shape_scatter_radius"] = 4
	params["shape_scatter_count"] = 11
	params["shape_scatter_seed"] = 29
	var/list/shape_result = GLOB.world_edit_placement_shapes.world_edit_build_shape_turfs(WORLD_EDIT_SHAPE_SCATTER_CLUSTER, center_turf, center_turf, params, NORTH)
	TEST_ASSERT(!shape_result["error"], "World Edit outpost scatter-cluster connectivity test should build a shared shape result.")
	TEST_ASSERT_EQUAL(generator.count_shape_connected_components(shape_result["turfs"] || list()), 1, "World Edit scatter-cluster shape service should keep the footprint connected for outpost support.")

	var/list/placement_context = list(
		"mode" = "single",
		"shape" = WORLD_EDIT_SHAPE_SCATTER_CLUSTER,
		"shape_metadata" = shape_result["metadata"] || list(),
		"anchor_turfs" = shape_result["turfs"] || list(),
		"start_turf" = center_turf,
		"end_turf" = center_turf,
		"direction" = NORTH,
	)
	var/shape_error = generator.get_shape_support_error(WORLD_EDIT_SHAPE_SCATTER_CLUSTER, shape_result["turfs"] || list(), params, placement_context)
	TEST_ASSERT(isnull(shape_error), "World Edit outpost scatter-cluster connectivity test should not reject the footprint as disconnected islands.")

	var/datum/world_edit_plan/plan = generator.build_placement_plan(null, params, placement_context)
	TEST_ASSERT(!plan.metadata["error"], "World Edit outpost scatter-cluster connectivity test should build a shape-aware plan once the footprint is connected.")
	TEST_ASSERT(length(plan.placements) > 0, "World Edit outpost scatter-cluster connectivity test should still produce placements for the connected footprint.")

	qdel(generator)

/datum/unit_test/world_edit_corner_slots/outpost_pointlike_shapes_fall_back_to_point_support/Run()
	var/datum/world_edit_generator/outpost_radius/generator = allocate(/datum/world_edit_generator/outpost_radius)
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit outpost pointlike-fallback test center turf was not resolved.")

	var/list/params = build_outpost_test_params("none", "crossroads", "broad", 1)

	var/list/placement_context = list(
		"mode" = "single",
		"shape" = "custom_mask",
		"shape_metadata" = list("degenerate_kind" = "point"),
		"anchor_turfs" = list(center_turf),
		"start_turf" = center_turf,
		"end_turf" = center_turf,
		"shape_origin_turf" = center_turf,
		"seed_turf" = center_turf,
		"requested_end_turf" = center_turf,
		"resolved_end_turf" = center_turf,
		"direction" = NORTH,
	)
	var/shape_error = generator.get_shape_support_error("custom_mask", list(center_turf), params, placement_context)
	TEST_ASSERT(isnull(shape_error), "World Edit outpost pointlike-fallback test should keep a point-degenerate shape placeable instead of rejecting it on required openings.")

	var/datum/world_edit_plan/plan = generator.build_placement_plan(null, params, placement_context)
	TEST_ASSERT(!plan.metadata["error"], "World Edit outpost pointlike-fallback test should build a valid plan for a point-degenerate shape.")
	TEST_ASSERT_EQUAL(plan.metadata["placement_shape"], "custom_mask", "World Edit outpost pointlike-fallback test should preserve the requested shape id on the plan metadata.")
	TEST_ASSERT_EQUAL(plan.metadata["shape_effective_id"], WORLD_EDIT_SHAPE_POINT, "World Edit outpost pointlike-fallback test should mark the effective point fallback semantics.")
	TEST_ASSERT(length(plan.placements) > 0, "World Edit outpost pointlike-fallback test should still produce outpost placements for the degenerate point footprint.")

/datum/unit_test/world_edit_corner_slots/outpost_point_support_respects_clicked_footprint_policy/Run()
	var/datum/world_edit_generator/outpost_radius/generator = allocate(/datum/world_edit_generator/outpost_radius)
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit outpost point-footprint policy test center turf was not resolved.")

	var/obj/structure/window/test_window = allocate(/obj/structure/window, center_turf)
	TEST_ASSERT_NOTNULL(test_window, "World Edit outpost point-footprint policy test should create a window blocker on the clicked turf.")

	var/list/params = build_outpost_test_params("none", "crossroads", "layout", 2)
	params["radius_only_clear_tiles"] = TRUE
	params["radius_only_reachable_tiles"] = FALSE
	params["radius_windows_blockers"] = TRUE

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

/datum/unit_test/world_edit_corner_slots/outpost_radius_policy_reuses_approach_cache_for_identical_queries/Run()
	var/datum/world_edit_generator/outpost_radius/generator = allocate(/datum/world_edit_generator/outpost_radius)
	var/turf/center_turf = get_world_edit_test_center_turf()
	var/turf/adjacent_turf = locate(center_turf.x + 1, center_turf.y, center_turf.z)
	var/turf/far_turf = locate(center_turf.x + 2, center_turf.y, center_turf.z)
	TEST_ASSERT_NOTNULL(center_turf, "World Edit outpost approach-cache test center turf was not resolved.")
	TEST_ASSERT_NOTNULL(adjacent_turf, "World Edit outpost approach-cache test adjacent turf was not resolved.")
	TEST_ASSERT_NOTNULL(far_turf, "World Edit outpost approach-cache test far turf was not resolved.")

	var/list/policy = list(
		"only_clear_tiles" = TRUE,
		"only_reachable_tiles" = FALSE,
		"treat_windows_as_blockers" = TRUE,
	)
	var/list/pinned_lookup = generator.build_turf_lookup(list(center_turf))
	var/list/approach_line_cache = list()
	var/list/approach_result_cache = list()
	var/list/first_allowed = generator.filter_outpost_candidate_turfs(
		list(center_turf),
		list(adjacent_turf, far_turf),
		list(center_turf, adjacent_turf, far_turf),
		policy,
		list(center_turf),
		pinned_lookup,
		approach_line_cache,
		approach_result_cache,
	)
	var/first_line_cache_size = length(approach_line_cache)
	var/first_result_cache_size = length(approach_result_cache)
	TEST_ASSERT(first_line_cache_size > 0, "World Edit outpost approach-cache test should populate the cached line-of-approach table on the first query.")
	TEST_ASSERT(first_result_cache_size > 0, "World Edit outpost approach-cache test should populate the cached approach result table on the first query.")

	var/list/second_allowed = generator.filter_outpost_candidate_turfs(
		list(center_turf),
		list(adjacent_turf, far_turf),
		list(center_turf, adjacent_turf, far_turf),
		policy,
		list(center_turf),
		pinned_lookup,
		approach_line_cache,
		approach_result_cache,
	)
	TEST_ASSERT_EQUAL(length(approach_line_cache), first_line_cache_size, "World Edit outpost approach-cache test should reuse cached line data for identical policy queries instead of appending new entries.")
	TEST_ASSERT_EQUAL(length(approach_result_cache), first_result_cache_size, "World Edit outpost approach-cache test should reuse cached passability results for identical policy queries instead of appending new entries.")
	TEST_ASSERT_EQUAL(length(first_allowed), length(second_allowed), "World Edit outpost approach-cache test should keep the allowed-candidate count stable when cache reuse kicks in.")
	TEST_ASSERT((adjacent_turf in first_allowed) == (adjacent_turf in second_allowed), "World Edit outpost approach-cache test should preserve adjacent candidate results when reusing the cache.")
	TEST_ASSERT((far_turf in first_allowed) == (far_turf in second_allowed), "World Edit outpost approach-cache test should preserve far candidate results when reusing the cache.")

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

/datum/unit_test/world_edit_corner_slots/destruction_damage_entries_spill_toward_outer_band/Run()
	var/datum/world_edit_generator/destruction_pack/generator = allocate(/datum/world_edit_generator/destruction_pack)
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit destruction damage-band test center turf was not resolved.")

	var/list/influence_map = generator.build_influence_map(list(center_turf), 3)
	var/list/ruin_entries = generator.build_damage_entries(influence_map["turfs"], influence_map["lookup"], "ruin", 1337)
	var/list/collapse_entries = generator.build_damage_entries(influence_map["turfs"], influence_map["lookup"], "collapse", 1337)
	var/list/ruin_bands = list()
	for(var/list/ruin_entry as anything in ruin_entries)
		ruin_bands["[ruin_entry["band"]]"] = TRUE
	var/list/collapse_bands = list()
	for(var/list/collapse_entry as anything in collapse_entries)
		collapse_bands["[collapse_entry["band"]]"] = TRUE

	TEST_ASSERT(ruin_bands["core"], "World Edit destruction ruin profile should still include the core band.")
	TEST_ASSERT(ruin_bands["mid_spill"], "World Edit destruction ruin profile should spill beyond the core into the mid band.")
	TEST_ASSERT(ruin_bands["outer"], "World Edit destruction ruin profile should reach the outer band for visible edge damage.")
	TEST_ASSERT(collapse_bands["core"], "World Edit destruction collapse profile should still include the core band.")
	TEST_ASSERT(collapse_bands["mid"], "World Edit destruction collapse profile should keep the full mid band damage entry.")
	TEST_ASSERT(collapse_bands["outer"], "World Edit destruction collapse profile should also reach the outer band.")

/datum/unit_test/world_edit_corner_slots/destruction_ruin_keeps_objects_but_collapse_breaks_them/Run()
	var/datum/world_edit_generator/destruction_pack/generator = allocate(/datum/world_edit_generator/destruction_pack)
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit destruction ruin-vs-collapse runtime test center turf was not resolved.")

	var/turf/ruin_turf = get_step(center_turf, EAST)
	var/turf/collapse_turf = get_step(center_turf, WEST)
	TEST_ASSERT(istype(ruin_turf), "World Edit destruction ruin-vs-collapse runtime test should resolve a turf for ruin damage.")
	TEST_ASSERT(istype(collapse_turf), "World Edit destruction ruin-vs-collapse runtime test should resolve a turf for collapse damage.")

	var/obj/structure/ruin_target = allocate(/obj/structure, ruin_turf)
	var/obj/structure/collapse_target = allocate(/obj/structure, collapse_turf)
	TEST_ASSERT_NOTNULL(ruin_target, "World Edit destruction ruin-vs-collapse runtime test should spawn a ruin target.")
	TEST_ASSERT_NOTNULL(collapse_target, "World Edit destruction ruin-vs-collapse runtime test should spawn a collapse target.")
	ruin_target.health = 1
	collapse_target.health = 1

	var/ruin_count = generator.apply_structural_damage_profile(list(ruin_turf), EXPLOSION_THRESHOLD_VLOW, null, "ruin")
	var/collapse_count = generator.apply_structural_damage_profile(list(collapse_turf), EXPLOSION_THRESHOLD_LOW, null, "collapse")

	TEST_ASSERT_EQUAL(ruin_count, 1, "World Edit destruction ruin-vs-collapse runtime test should still register ruin damage on the target turf.")
	TEST_ASSERT(!QDELETED(ruin_target), "World Edit destruction ruin-vs-collapse runtime test should keep the ruin target alive.")
	TEST_ASSERT_EQUAL(ruin_target.loc, ruin_turf, "World Edit destruction ruin-vs-collapse runtime test should keep the ruin target on its turf.")
	TEST_ASSERT(ruin_target.health > 0, "World Edit destruction ruin-vs-collapse runtime test should leave the ruin target with non-zero health.")
	TEST_ASSERT_EQUAL(collapse_count, 1, "World Edit destruction ruin-vs-collapse runtime test should register collapse damage on the target turf.")
	TEST_ASSERT(QDELETED(collapse_target) || collapse_target.loc != collapse_turf, "World Edit destruction ruin-vs-collapse runtime test should destroy or remove the collapse target.")

/datum/unit_test/world_edit_corner_slots/destruction_persistent_fire_reaches_outer_band/Run()
	var/datum/world_edit_generator/destruction_pack/generator = allocate(/datum/world_edit_generator/destruction_pack)
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit destruction persistent-fire reach test center turf was not resolved.")

	var/list/influence_map = generator.build_influence_map(list(center_turf), 3)
	var/list/fire_entries = generator.build_persistent_fire_entries(influence_map["turfs"], influence_map["lookup"], 35, 1337)
	var/list/fire_bands = list()
	for(var/list/fire_entry as anything in fire_entries)
		var/turf/fire_turf = fire_entry["turf"]
		var/list/influence_info = influence_map["lookup"][fire_turf]
		if(islist(influence_info))
			fire_bands["[influence_info["band"]]"] = TRUE

	TEST_ASSERT(length(fire_entries) > 0, "World Edit destruction persistent-fire reach test should produce fire placements at non-zero density.")
	TEST_ASSERT(fire_bands["core"], "World Edit destruction persistent-fire reach test should still favor the core band.")
	TEST_ASSERT(fire_bands["outer"], "World Edit destruction persistent-fire reach test should also place fire on the outer band.")

/datum/unit_test/world_edit_corner_slots/destruction_persistent_fire_density_uses_placeable_pool/Run()
	var/datum/world_edit_generator/destruction_pack/generator = allocate(/datum/world_edit_generator/destruction_pack)
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit destruction persistent-fire density test center turf was not resolved.")

	var/turf/east_turf = get_step(center_turf, EAST)
	var/turf/west_turf = get_step(center_turf, WEST)
	var/turf/north_turf = get_step(center_turf, NORTH)
	var/turf/south_turf = get_step(center_turf, SOUTH)
	TEST_ASSERT(istype(east_turf) && istype(west_turf) && istype(north_turf) && istype(south_turf), "World Edit destruction persistent-fire density test should resolve four neighbor turfs.")

	var/list/influence_turfs = list(center_turf, east_turf, west_turf, north_turf)
	var/list/influence_lookup = list()
	influence_lookup[center_turf] = list("normalized_weight" = 1, "band" = "core")
	influence_lookup[east_turf] = list("normalized_weight" = 0.7, "band" = "mid")
	influence_lookup[west_turf] = list("normalized_weight" = 0.5, "band" = "mid")
	influence_lookup[north_turf] = list("normalized_weight" = 0.2, "band" = "outer")

	var/obj/structure/blocked_structure = allocate(/obj/structure, east_turf)
	var/obj/effect/world_edit_persistent_fire/existing_fire = allocate(/obj/effect/world_edit_persistent_fire, west_turf)
	TEST_ASSERT_NOTNULL(blocked_structure, "World Edit destruction persistent-fire density test should spawn a dense blocker.")
	TEST_ASSERT_NOTNULL(existing_fire, "World Edit destruction persistent-fire density test should spawn an existing fire tile.")

	var/list/fire_entries = generator.build_persistent_fire_entries(influence_turfs, influence_lookup, 50, 4242)
	TEST_ASSERT_EQUAL(length(fire_entries), 1, "World Edit destruction persistent-fire density test should use only valid placeable tiles when calculating density.")
	for(var/list/fire_entry as anything in fire_entries)
		var/turf/fire_turf = fire_entry["turf"]
		TEST_ASSERT(fire_turf == center_turf || fire_turf == north_turf, "World Edit destruction persistent-fire density test should only place fire on the two valid tiles.")

/datum/unit_test/world_edit_corner_slots/destruction_persistent_fire_plan_keeps_mode_and_color/Run()
	var/datum/world_edit_generator/destruction_pack/generator = allocate(/datum/world_edit_generator/destruction_pack)
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit destruction persistent-fire mode/color test center turf was not resolved.")

	var/list/params = list(
		"radius" = 2,
		"shuffle_enabled" = FALSE,
		"scatter_enabled" = FALSE,
		"persistent_fire_enabled" = TRUE,
		"persistent_fire_density" = 100,
		"persistent_fire_mode" = "decorative",
		"persistent_fire_color" = "custom",
		"persistent_fire_custom_color" = "#33aaff",
		"blast_enabled" = FALSE,
		"damage_profile" = "none",
		"max_atoms" = 60,
		"scatter_steps" = 2,
	)
	var/list/placement_context = list(
		"mode" = "single",
		"shape" = WORLD_EDIT_SHAPE_POINT,
		"shape_metadata" = list(),
		"anchor_turfs" = list(center_turf),
		"start_turf" = center_turf,
		"end_turf" = center_turf,
		"direction" = NORTH,
	)

	var/datum/world_edit_plan/plan = generator.build_placement_plan(null, params, placement_context)
	TEST_ASSERT(istype(plan, /datum/world_edit_plan), "World Edit destruction persistent-fire mode/color test should build a plan datum.")
	TEST_ASSERT(!plan.metadata["error"], "World Edit destruction persistent-fire mode/color test should build a valid plan.")
	TEST_ASSERT_EQUAL(plan.metadata["persistent_fire_mode"], "decorative", "World Edit destruction persistent-fire mode/color test should keep the selected fire mode in plan metadata.")
	TEST_ASSERT_EQUAL(plan.metadata["persistent_fire_color"], "#33aaff", "World Edit destruction persistent-fire mode/color test should keep the resolved custom fire color in plan metadata.")
	TEST_ASSERT_EQUAL(plan.metadata["persistent_fire_preview_color"], "#33aaff", "World Edit destruction persistent-fire mode/color test should publish the resolved fire color for preview consumers.")

	var/fire_entries = 0
	for(var/list/placement as anything in plan.placements)
		if(placement["kind"] != "fire")
			continue
		fire_entries++
		TEST_ASSERT_EQUAL(placement["fire_mode"], "decorative", "World Edit destruction persistent-fire mode/color test should stamp the selected mode onto each fire placement.")
		TEST_ASSERT_EQUAL(placement["fire_color"], "#33aaff", "World Edit destruction persistent-fire mode/color test should stamp the resolved color onto each fire placement.")

	TEST_ASSERT(fire_entries > 0, "World Edit destruction persistent-fire mode/color test should produce fire placements for the selected area.")

/datum/unit_test/world_edit_corner_slots/destruction_persistent_fire_validation_rejects_bad_custom_hex/Run()
	var/datum/world_edit_generator/destruction_pack/generator = allocate(/datum/world_edit_generator/destruction_pack)
	var/list/params = list(
		"radius" = 2,
		"shuffle_enabled" = FALSE,
		"scatter_enabled" = FALSE,
		"persistent_fire_enabled" = TRUE,
		"persistent_fire_density" = 50,
		"persistent_fire_mode" = "damaging",
		"persistent_fire_color" = "custom",
		"persistent_fire_custom_color" = "blue",
		"blast_enabled" = FALSE,
		"damage_profile" = "none",
		"max_atoms" = 60,
		"scatter_steps" = 2,
	)

	var/error_text = generator.validate_params(null, params)
	TEST_ASSERT(length("[error_text]"), "World Edit destruction persistent-fire validation test should reject invalid custom fire colors.")

/datum/unit_test/world_edit_corner_slots/world_edit_persistent_fire_configuration_updates_runtime_contract/Run()
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit persistent-fire runtime contract test center turf was not resolved.")

	var/obj/effect/world_edit_persistent_fire/fire = allocate(/obj/effect/world_edit_persistent_fire, center_turf)
	TEST_ASSERT_NOTNULL(fire, "World Edit persistent-fire runtime contract test should create a persistent fire object.")
	fire.configure_persistent_fire("#33aaff", "decorative")

	TEST_ASSERT_EQUAL(fire.fire_color, "#33aaff", "World Edit persistent-fire runtime contract test should update the fire color.")
	TEST_ASSERT_EQUAL(fire.light_color, "#33aaff", "World Edit persistent-fire runtime contract test should keep the light color aligned with the configured fire color.")
	TEST_ASSERT_EQUAL(fire.color, "#33aaff", "World Edit persistent-fire runtime contract test should tint the visual to the configured fire color.")
	TEST_ASSERT(fire.is_decorative_mode(), "World Edit persistent-fire runtime contract test should expose decorative mode after configuration.")

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

/datum/unit_test/world_edit_corner_slots/manager_runtime/support_result_plan_reuses_candidate_build_path/Run()
	var/datum/world_edit_generator_definition/world_edit_test_support_plan_hook/definition = new
	var/datum/world_edit_generator/world_edit_test_support_plan_hook/generator = allocate(/datum/world_edit_generator/world_edit_test_support_plan_hook)
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit support-plan reuse test center turf was not resolved.")

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.current_params = definition.default_params?.Copy() || list()
	manager.placement_shape = WORLD_EDIT_SHAPE_POINT
	manager.placement_mode = "single"

	var/datum/world_edit_placement_candidate/candidate = manager.resolve_placement_candidate(null, center_turf, center_turf)
	TEST_ASSERT(istype(candidate, /datum/world_edit_placement_candidate), "World Edit support-plan reuse test should return a placement candidate.")
	TEST_ASSERT(candidate.is_preview_ready(), "World Edit support-plan reuse test should still build a preview-ready candidate when support returns a prebuilt plan.")
	TEST_ASSERT_EQUAL(generator.support_plan_calls, 1, "World Edit support-plan reuse test should resolve support exactly once.")
	TEST_ASSERT_EQUAL(generator.build_plan_from_shape_contract_calls, 0, "World Edit support-plan reuse test should reuse the support-provided plan instead of rebuilding it.")
	TEST_ASSERT_EQUAL(candidate.plan.metadata["placement_shape"], WORLD_EDIT_SHAPE_POINT, "World Edit support-plan reuse test should still finalize shared placement metadata on the reused plan.")
	TEST_ASSERT_EQUAL(candidate.plan.metadata["anchor_count"], 1, "World Edit support-plan reuse test should keep anchor metadata on the reused plan.")

	qdel(manager)

/datum/unit_test/world_edit_corner_slots/outpost_build_plan_path_matches_support_validation_for_disconnected_limited_shapes/Run()
	var/datum/world_edit_generator_definition/outpost_radius/definition = new
	var/datum/world_edit_generator/outpost_radius/generator = allocate(/datum/world_edit_generator/outpost_radius)
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit outpost support/build consistency test center turf was not resolved.")

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.current_params = definition.default_params?.Copy() || list()
	manager.placement_shape = WORLD_EDIT_SHAPE_CUSTOM_MASK

	var/list/shape_result = build_shape_result(WORLD_EDIT_SHAPE_CUSTOM_MASK, center_turf, list(
		"shape_points_text" = "0,0; 2,0",
	))
	TEST_ASSERT(!shape_result["error"], "World Edit outpost support/build consistency test should build a disconnected custom-mask footprint without shape-service errors.")

	var/list/placement_context = list(
		"mode" = "single",
		"shape" = WORLD_EDIT_SHAPE_CUSTOM_MASK,
		"shape_metadata" = shape_result["metadata"] || list(),
		"anchor_turfs" = shape_result["turfs"] || list(),
		"start_turf" = center_turf,
		"end_turf" = center_turf,
		"direction" = NORTH,
	)
	var/datum/world_edit_shape_contract/shape_contract = GLOB.world_edit_shape_geometry.build_shape_contract_from_result(WORLD_EDIT_SHAPE_CUSTOM_MASK, shape_result)
	var/shape_support_error = generator.get_shape_support_error(WORLD_EDIT_SHAPE_CUSTOM_MASK, shape_result["turfs"] || list(), manager.current_params, placement_context)
	TEST_ASSERT(length("[shape_support_error]"), "World Edit outpost support/build consistency test should still reject disconnected limited shapes at the support boundary.")

	var/datum/world_edit_plan/plan = generator.build_plan_from_shape_contract(null, shape_contract, manager.current_params, placement_context)
	TEST_ASSERT(istype(plan, /datum/world_edit_plan), "World Edit outpost support/build consistency test should still return a plan datum on the build path.")
	TEST_ASSERT_EQUAL("[plan.metadata["error"]]", "[shape_support_error]", "World Edit outpost build_plan_from_shape_contract should return the same explicit support failure instead of drifting into a misleading plan path.")

	qdel(manager)

/datum/unit_test/world_edit_corner_slots/outpost_dir_driven_layouts_rotate_with_placement_dir/Run()
	var/datum/world_edit_generator/outpost_radius/generator = allocate(/datum/world_edit_generator/outpost_radius)
	var/list/params = build_outpost_test_params("none", "gate", "layout", 2)

	var/list/config = generator.resolve_outpost_configuration(params, list("direction" = EAST))
	TEST_ASSERT(!config["error"], "World Edit outpost DIR-layout test should resolve a gate layout without configuration errors.")
	TEST_ASSERT_EQUAL(config["layout_variant"], "gate", "World Edit outpost DIR-layout test should keep the canonical layout id on resolved config.")
	TEST_ASSERT_EQUAL(config["placement_dir"], EAST, "World Edit outpost DIR-layout test should preserve the placement DIR on resolved config.")
	TEST_ASSERT_EQUAL(length(config["layout_profile"]["opening_dirs"] || list()), 1, "World Edit outpost DIR-layout test should keep exactly one gate opening.")
	TEST_ASSERT_EQUAL(config["layout_profile"]["opening_dirs"][1], EAST, "World Edit outpost DIR-layout test should rotate the gate opening to the current placement DIR instead of using a hardcoded north-facing layout.")

/datum/unit_test/world_edit_corner_slots/outpost_split_layout_builds_separated_openings/Run()
	var/datum/world_edit_generator/outpost_radius/generator = allocate(/datum/world_edit_generator/outpost_radius)
	var/list/params = build_outpost_test_params("none", "split_mouth", "layout", 3)
	var/list/config = generator.resolve_outpost_configuration(params, list("direction" = NORTH))

	TEST_ASSERT(!config["error"], "World Edit split-opening test should resolve split_mouth without configuration errors.")
	TEST_ASSERT_EQUAL(generator.get_layout_opening_slot_mode(config["layout_profile"]), "split_pair", "World Edit split-opening test should keep split_pair slot mode on the resolved layout.")
	TEST_ASSERT_EQUAL(generator.get_layout_total_opening_tiles_per_dir(config["layout_profile"]), 2, "World Edit split-opening test should expose two total opening tiles on the split-mouthed side.")

	var/list/opening_ranges = generator.build_point_opening_ranges(NORTH, config["radius"], config["layout_profile"])
	TEST_ASSERT_EQUAL(length(opening_ranges), 2, "World Edit split-opening test should build two distinct opening ranges for the split mouth.")
	TEST_ASSERT(opening_ranges[1]["end"] < opening_ranges[2]["start"], "World Edit split-opening test should keep the two openings separated by a closed center segment.")
	TEST_ASSERT(!generator.is_perimeter_opening_slot(NORTH, 0, config["radius"], config["layout_profile"], config["radius"]), "World Edit split-opening test should keep the centered front slot closed for split-mouthed layouts.")

/datum/unit_test/world_edit_corner_slots/outpost_defense_profiles_resolve_without_legacy_switches/Run()
	var/datum/world_edit_generator/outpost_radius/generator = allocate(/datum/world_edit_generator/outpost_radius)
	var/list/heavy_params = build_outpost_test_params("anti_vehicle_stop", "crossroads", "layout", 2)
	var/list/heavy_config = generator.resolve_outpost_configuration(heavy_params, list("direction" = NORTH))
	TEST_ASSERT(!heavy_config["error"], "World Edit defense-profile test should resolve the anti_vehicle_stop tactical profile.")
	TEST_ASSERT_EQUAL(heavy_config["defense_profile"], "anti_vehicle_stop", "World Edit defense-profile test should preserve the selected tactical profile id.")
	TEST_ASSERT(heavy_config["needs_anchor_map"], "World Edit defense-profile test should request anchor-map generation for active defenses.")
	var/list/heavy_profile = heavy_config["defense_profile_data"]
	TEST_ASSERT_EQUAL(length(heavy_profile["defense_rules"] || list()), 4, "World Edit defense-profile test should expose the bundled sentry, mine and extra-defense rules for the selected tactical profile.")
	var/list/tesla_rule = null
	for(var/list/rule as anything in heavy_profile["defense_rules"] || list())
		if(rule["kind"] == "extra_defense")
			tesla_rule = rule
			break
	var/tesla_path = islist(tesla_rule) ? tesla_rule["defense_path"] : null
	TEST_ASSERT_EQUAL(tesla_path, /datum/human_ai_defense/defense/tesla, "World Edit defense-profile test should keep the heavy profile's tesla placement rule.")

	var/list/none_params = build_outpost_test_params("none", "crossroads", "layout", 2)
	var/list/none_config = generator.resolve_outpost_configuration(none_params, list("direction" = NORTH))
	TEST_ASSERT(!none_config["error"], "World Edit defense-profile test should resolve the empty tactical profile.")
	TEST_ASSERT_EQUAL(none_config["defense_profile"], "none", "World Edit defense-profile test should preserve the explicit no-defense profile.")
	TEST_ASSERT(!(none_config["needs_anchor_map"]), "World Edit defense-profile test should skip anchor-map work for the no-defense profile.")
	var/list/none_profile = none_config["defense_profile_data"]
	TEST_ASSERT_EQUAL(length(none_profile["defense_rules"] || list()), 0, "World Edit defense-profile test should expose no defense rules for the no-defense profile.")

/datum/unit_test/world_edit_corner_slots/outpost_plan_preview_specs_follow_runtime_placements/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/outpost_radius/definition = new
	var/datum/world_edit_generator/outpost_radius/generator = allocate(/datum/world_edit_generator/outpost_radius)
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit outpost preview-spec test center turf was not resolved.")

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.placement_shape = WORLD_EDIT_SHAPE_POINT
	manager.placement_dir = NORTH
	manager.placement_anchor_turf = center_turf

	var/list/params = build_outpost_test_params("lane_fort", "gate", "layout", 2)
	params["primary_material_path"] = /datum/human_ai_defense/barricade/metal/wired
	params["secondary_material_path"] = /datum/human_ai_defense/barricade/metal/wired
	manager.current_params = params.Copy()

	var/list/placement_context = list(
		"mode" = "single",
		"shape" = WORLD_EDIT_SHAPE_POINT,
		"shape_metadata" = list(),
		"anchor_turfs" = list(center_turf),
		"start_turf" = center_turf,
		"end_turf" = center_turf,
		"direction" = NORTH,
	)
	var/datum/world_edit_plan/plan = generator.build_placement_plan(null, params, placement_context)
	TEST_ASSERT(istype(plan, /datum/world_edit_plan), "World Edit outpost preview-spec test should build a plan datum.")
	TEST_ASSERT(!plan.metadata["error"], "World Edit outpost preview-spec test should build a valid plan.")
	TEST_ASSERT(length(plan.placements) > 0, "World Edit outpost preview-spec test should produce runtime placements.")
	TEST_ASSERT(manager.render_plan_preview_with_placement_layers(null, plan, params), "World Edit outpost preview-spec test should synthesize placement-preview layers from the plan.")

	var/datum/world_edit_placement_candidate/candidate = manager.get_placement_preview_candidate()
	TEST_ASSERT(istype(candidate?.preview_model, /datum/world_edit_preview_model), "World Edit outpost preview-spec test should keep a preview model on the synthesized candidate.")
	TEST_ASSERT_EQUAL(length(candidate.preview_model.generator_preview_object_specs), length(plan.placements), "World Edit outpost preview-spec test should expose one object-preview spec per runtime placement.")
	TEST_ASSERT_EQUAL(length(GLOB.world_edit_helpers.build_preview_images_from_specs(candidate.preview_model.generator_preview_object_specs)), length(plan.placements), "World Edit outpost preview-spec test should resolve each object-preview spec into a preview image.")

	qdel(manager)

/datum/unit_test/world_edit_corner_slots/blueprint_stamp_plan_preview_specs_follow_runtime_placements/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/blueprint_stamp/definition = new
	var/datum/world_edit_generator/blueprint_stamp/generator = allocate(/datum/world_edit_generator/blueprint_stamp)
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit blueprint preview-spec test center turf was not resolved.")

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.placement_shape = WORLD_EDIT_SHAPE_POINT
	manager.placement_dir = NORTH
	manager.placement_anchor_turf = center_turf
	manager.refresh_blueprint_cache()

	var/list/params = definition.default_params?.Copy() || list()
	params["blueprint_id"] = "checkpoint_gate"
	manager.current_params = params.Copy()

	var/list/placement_context = list(
		"mode" = "single",
		"shape" = WORLD_EDIT_SHAPE_POINT,
		"shape_metadata" = list(),
		"anchor_turfs" = list(center_turf),
		"start_turf" = center_turf,
		"end_turf" = center_turf,
		"direction" = NORTH,
	)
	var/datum/world_edit_plan/plan = generator.build_placement_plan(null, params, placement_context)
	TEST_ASSERT(istype(plan, /datum/world_edit_plan), "World Edit blueprint preview-spec test should build a plan datum.")
	TEST_ASSERT(!plan.metadata["error"], "World Edit blueprint preview-spec test should build a valid blueprint plan.")
	TEST_ASSERT(length(plan.placements) > 0, "World Edit blueprint preview-spec test should expose runtime placements.")
	TEST_ASSERT(manager.render_plan_preview_with_placement_layers(null, plan, params), "World Edit blueprint preview-spec test should synthesize placement-preview layers from the plan.")

	var/datum/world_edit_placement_candidate/candidate = manager.get_placement_preview_candidate()
	TEST_ASSERT(istype(candidate?.preview_model, /datum/world_edit_preview_model), "World Edit blueprint preview-spec test should keep a preview model on the synthesized candidate.")
	TEST_ASSERT_EQUAL(length(candidate.preview_model.generator_preview_object_specs), length(plan.placements), "World Edit blueprint preview-spec test should expose one object-preview spec per blueprint placement.")
	TEST_ASSERT_EQUAL(length(GLOB.world_edit_helpers.build_preview_images_from_specs(candidate.preview_model.generator_preview_object_specs)), length(plan.placements), "World Edit blueprint preview-spec test should resolve each blueprint object-preview spec into a preview image.")

	qdel(manager)

/datum/unit_test/world_edit_corner_slots/destruction_pack_preview_stays_generator_owned/Run()
	var/datum/world_edit_manager/manager = new /datum/world_edit_manager()
	var/datum/world_edit_generator_definition/destruction_pack/definition = new
	var/datum/world_edit_generator/destruction_pack/generator = allocate(/datum/world_edit_generator/destruction_pack)
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit destruction preview-ownership test center turf was not resolved.")

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.placement_shape = WORLD_EDIT_SHAPE_POINT
	manager.placement_mode = "single"
	manager.placement_dir = NORTH

	var/list/params = definition.default_params?.Copy() || list()
	params["radius"] = 2
	params["shuffle_enabled"] = FALSE
	params["scatter_enabled"] = FALSE
	params["persistent_fire_enabled"] = TRUE
	params["persistent_fire_density"] = 100
	params["blast_enabled"] = FALSE
	params["damage_profile"] = "none"
	manager.current_params = params.Copy()

	var/datum/world_edit_plan/plan = generator.build_plan(params, center_turf)
	TEST_ASSERT(istype(plan, /datum/world_edit_plan), "World Edit destruction preview-ownership test should build a plan datum.")
	TEST_ASSERT(!plan.metadata["error"], "World Edit destruction preview-ownership test should build a valid destruction plan.")
	TEST_ASSERT(!manager.should_use_placement_layer_preview(plan), "World Edit destruction preview-ownership test should keep the generator on its specialized preview renderer.")
	TEST_ASSERT(length(generator.build_plan_preview_images(plan)) > 0, "World Edit destruction preview-ownership test should still build specialized generator preview images.")

	qdel(manager)

/datum/unit_test/world_edit_corner_slots/blueprint_library_curated_tactical_pack_entries_are_valid/Run()
	var/list/summaries = GLOB.world_edit_blueprints.world_edit_load_blueprint_library_summaries()
	var/list/summary_lookup = list()
	for(var/list/summary as anything in summaries)
		summary_lookup["[summary["id"]]"] = summary

	var/list/expected_ids = list(
		"checkpoint_gate",
		"killbox_alpha",
		"funnel_nest",
		"fallback_pocket",
		"wire_gate",
		"vehicle_stop",
		"trench_stub",
		"crossfire_corner",
		"arc_hold",
		"courtyard_compound",
		"ammo_cache",
		"med_evac_point",
		"generator_shelter",
		"comms_post",
		"inner_bastion",
		"zigzag_cover_strip",
		"broken_outpost",
		"encampment_light",
		"turret_pad",
		"split_entry_checkpoint",
	)

	for(var/blueprint_id as anything in expected_ids)
		var/list/summary = summary_lookup["[blueprint_id]"]
		TEST_ASSERT(islist(summary), "World Edit curated tactical-pack test should expose blueprint '[blueprint_id]' in the server-side library summary list.")
		TEST_ASSERT(summary["valid"], "World Edit curated tactical-pack test should keep blueprint '[blueprint_id]' valid in the server-side library.")
		TEST_ASSERT((summary["footprint_width"] || 0) > 0, "World Edit curated tactical-pack test should expose a positive footprint width for blueprint '[blueprint_id]'.")
		TEST_ASSERT((summary["footprint_height"] || 0) > 0, "World Edit curated tactical-pack test should expose a positive footprint height for blueprint '[blueprint_id]'.")

/datum/unit_test/world_edit_corner_slots/blueprint_library_curated_pack_corner_slots_use_multi_dir_border_semantics/Run()
	var/list/summaries = GLOB.world_edit_blueprints.world_edit_load_blueprint_library_summaries()
	var/list/file_path_lookup = list()
	for(var/list/summary as anything in summaries)
		if(!islist(summary) || !summary["valid"] || !length("[summary["id"]]"))
			continue
		file_path_lookup["[summary["id"]]"] = "[summary["file_path"]]"

	var/list/expectations = list(
		"checkpoint_gate" = list(
			"-2,1,8",
			"2,1,4",
		),
		"killbox_alpha" = list(
			"-3,2,8",
			"3,2,4",
			"-3,-2,8",
			"3,-2,4",
		),
		"funnel_nest" = list(
			"-2,2,8",
			"2,2,4",
			"-1,-1,8",
			"1,-1,4",
		),
		"fallback_pocket" = list(
			"-2,2,8",
			"1,2,4",
			"-2,-1,8",
		),
		"wire_gate" = list(
			"-2,1,8",
			"2,1,4",
		),
		"vehicle_stop" = list(
			"-3,1,8",
			"3,1,4",
		),
		"crossfire_corner" = list(
			"-2,0,1",
			"-2,-2,8",
			"0,-2,4",
		),
		"arc_hold" = list(
			"-2,2,8",
			"2,2,4",
		),
		"courtyard_compound" = list(
			"-2,2,8",
			"2,2,4",
			"-2,-2,8",
			"2,-2,4",
		),
		"ammo_cache" = list(
			"-1,1,8",
			"1,1,4",
		),
		"generator_shelter" = list(
			"-2,2,8",
			"2,2,4",
			"-2,-2,8",
			"2,-2,4",
		),
		"comms_post" = list(
			"-1,1,8",
			"1,1,4",
		),
		"inner_bastion" = list(
			"-1,1,8",
			"1,1,4",
			"-1,-1,8",
			"1,-1,4",
		),
		"broken_outpost" = list(
			"-2,2,8",
			"2,2,4",
		),
		"encampment_light" = list(
			"-2,1,8",
			"2,1,4",
		),
		"turret_pad" = list(
			"-1,1,8",
			"1,1,4",
		),
		"split_entry_checkpoint" = list(
			"-3,1,8",
			"3,1,4",
		),
	)

	for(var/blueprint_id as anything in expectations)
		var/file_path = file_path_lookup["[blueprint_id]"]
		TEST_ASSERT(length(file_path), "World Edit blueprint corner-slot test should resolve a library file path for curated blueprint '[blueprint_id]'.")
		var/list/load_result = GLOB.world_edit_blueprints.world_edit_load_blueprint_from_file(file_path)
		TEST_ASSERT(!load_result["error"], "World Edit blueprint corner-slot test should load curated blueprint '[blueprint_id]' from disk.")
		var/list/blueprint = load_result["blueprint"]
		var/list/slot_lookup = build_blueprint_relative_slot_lookup(blueprint["entries"])
		for(var/slot_key as anything in expectations[blueprint_id])
			TEST_ASSERT(slot_lookup[slot_key], "World Edit blueprint corner-slot test should keep the expected multi-dir border slot '[slot_key]' in curated blueprint '[blueprint_id]'.")

/datum/unit_test/world_edit_corner_slots/blueprint_support_props_follow_whitelist_and_slot_rules/Run()
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit support-prop blueprint test center turf was not resolved.")
	var/blueprint_schema = "world_edit_blueprint_lite"
	var/blueprint_version = 1

	var/list/valid_blueprint = list(
		"schema" = blueprint_schema,
		"version" = blueprint_version,
		"id" = "support_prop_ok",
		"name" = "Support Prop OK",
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
		"entries" = list(list(
			"type" = "/obj/structure/closet/crate/ammo",
			"dx" = 0,
			"dy" = 0,
			"dz" = 0,
			"dir" = NORTH,
			"vars" = list(),
		)),
	)
	var/list/valid_result = GLOB.world_edit_blueprints.world_edit_validate_blueprint_definition(valid_blueprint)
	TEST_ASSERT(!valid_result["error"], "World Edit support-prop blueprint test should accept whitelisted support props in Blueprint Lite definitions.")

	var/list/invalid_blueprint = list(
		"schema" = blueprint_schema,
		"version" = blueprint_version,
		"id" = "support_prop_bad",
		"name" = "Support Prop Bad",
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
		"entries" = list(list(
			"type" = "/obj/structure/closet/crate",
			"dx" = 0,
			"dy" = 0,
			"dz" = 0,
			"dir" = NORTH,
			"vars" = list(),
		)),
	)
	var/list/invalid_result = GLOB.world_edit_blueprints.world_edit_validate_blueprint_definition(invalid_blueprint)
	TEST_ASSERT(length("[invalid_result["error"]]"), "World Edit support-prop blueprint test should reject non-whitelisted support props at schema-validation time.")

	TEST_ASSERT(isnull(GLOB.world_edit_blueprints.world_edit_validate_blueprint_target_turf(center_turf, /obj/structure/closet/crate/ammo, NORTH)), "World Edit support-prop blueprint test should allow a support prop on an empty construction turf.")

	var/obj/structure/barricade/metal/barrier = allocate(/obj/structure/barricade/metal, center_turf)
	TEST_ASSERT_NOTNULL(barrier, "World Edit support-prop blueprint test should create a barricade helper.")
	barrier.setDir(NORTH)
	TEST_ASSERT(isnull(GLOB.world_edit_blueprints.world_edit_validate_blueprint_target_turf(center_turf, /obj/structure/closet/crate/ammo, NORTH)), "World Edit support-prop blueprint test should still allow support props on a turf that only contains barricades.")
	qdel(barrier)

	var/obj/structure/deployable_beacon/beacon = allocate(/obj/structure/deployable_beacon, center_turf)
	TEST_ASSERT_NOTNULL(beacon, "World Edit support-prop blueprint test should create a non-barricade support object helper.")
	var/support_prop_error = GLOB.world_edit_blueprints.world_edit_validate_blueprint_target_turf(center_turf, /obj/structure/closet/crate/ammo, NORTH)
	TEST_ASSERT(length("[support_prop_error]"), "World Edit support-prop blueprint test should reject support props on a turf that already contains a non-barricade structure.")
	qdel(beacon)

/datum/unit_test/world_edit_corner_slots/proc/capture_fortify_test_turf_state(turf/target_turf)
	if(!istype(target_turf))
		return null

	return list(
		"x" = target_turf.x,
		"y" = target_turf.y,
		"z" = target_turf.z,
		"type" = target_turf.type,
		"baseturfs" = islist(target_turf.baseturfs) ? target_turf.baseturfs.Copy() : target_turf.baseturfs,
	)

/datum/unit_test/world_edit_corner_slots/proc/setup_fortify_test_room(turf/center_turf, interior_half_width = 1, interior_half_height = 1, include_north_door = TRUE, include_east_window = TRUE)
	var/list/result = list(
		"states" = list(),
		"cleanup_atoms" = list(),
		"interior_count" = ((interior_half_width * 2) + 1) * ((interior_half_height * 2) + 1),
	)
	if(!istype(center_turf))
		return result

	var/list/states = result["states"]
	var/min_x = center_turf.x - interior_half_width - 1
	var/max_x = center_turf.x + interior_half_width + 1
	var/min_y = center_turf.y - interior_half_height - 1
	var/max_y = center_turf.y + interior_half_height + 1

	for(var/x in min_x to max_x)
		for(var/y in min_y to max_y)
			var/turf/current_turf = locate(x, y, center_turf.z)
			if(!istype(current_turf))
				continue

			var/list/state = capture_fortify_test_turf_state(current_turf)
			if(islist(state))
				states[length(states) + 1] = state

			var/dx = x - center_turf.x
			var/dy = y - center_turf.y
			var/target_type = (abs(dx) <= interior_half_width && abs(dy) <= interior_half_height) ? /turf/open/floor/plating : /turf/closed/wall/almayer
			current_turf.ChangeTurf(target_type)

	var/list/cleanup_atoms = result["cleanup_atoms"]
	var/turf/north_boundary_turf = locate(center_turf.x, center_turf.y + interior_half_height + 1, center_turf.z)
	if(include_north_door && istype(north_boundary_turf))
		north_boundary_turf = north_boundary_turf.ChangeTurf(/turf/open/floor/plating)
		var/obj/structure/machinery/door/unpowered/test_door = allocate(/obj/structure/machinery/door/unpowered, north_boundary_turf)
		if(!test_door)
			result["error"] = "World Edit fortify room helper should create a door boundary atom."
		else
			cleanup_atoms[length(cleanup_atoms) + 1] = test_door
			result["north_boundary_turf"] = north_boundary_turf
			result["north_door"] = test_door

	var/turf/east_boundary_turf = locate(center_turf.x + interior_half_width + 1, center_turf.y, center_turf.z)
	if(include_east_window && istype(east_boundary_turf))
		east_boundary_turf = east_boundary_turf.ChangeTurf(/turf/open/floor/plating)
		var/obj/structure/window/test_window = allocate(/obj/structure/window, east_boundary_turf)
		if(!test_window)
			result["error"] = result["error"] || "World Edit fortify room helper should create a window boundary atom."
		else
			cleanup_atoms[length(cleanup_atoms) + 1] = test_window
			result["east_boundary_turf"] = east_boundary_turf
			result["east_window"] = test_window

	result["center_turf"] = locate(center_turf.x, center_turf.y, center_turf.z)
	result["north_edge_turf"] = locate(center_turf.x, center_turf.y + interior_half_height, center_turf.z)
	result["east_edge_turf"] = locate(center_turf.x + interior_half_width, center_turf.y, center_turf.z)
	return result

/datum/unit_test/world_edit_corner_slots/proc/cleanup_fortify_test_room(list/context)
	if(!islist(context))
		return

	for(var/atom/cleanup_atom as anything in context["cleanup_atoms"] || list())
		if(cleanup_atom && !QDELETED(cleanup_atom))
			qdel(cleanup_atom)

	for(var/list/state as anything in context["states"] || list())
		if(!islist(state))
			continue
		var/turf/current_turf = locate(text2num("[state["x"]]"), text2num("[state["y"]]"), text2num("[state["z"]]"))
		if(!istype(current_turf))
			continue
		current_turf.ChangeTurf(state["type"], state["baseturfs"])

/datum/unit_test/world_edit_corner_slots/proc/build_fortify_test_placement_context(turf/anchor_turf, mode = "single")
	return list(
		"mode" = mode,
		"shape" = WORLD_EDIT_SHAPE_POINT,
		"shape_metadata" = list(),
		"anchor_turfs" = list(anchor_turf),
		"start_turf" = anchor_turf,
		"end_turf" = anchor_turf,
		"shape_origin_turf" = anchor_turf,
		"seed_turf" = anchor_turf,
		"requested_end_turf" = anchor_turf,
		"resolved_end_turf" = anchor_turf,
		"direction" = NORTH,
	)

/datum/unit_test/world_edit_corner_slots/proc/build_fortify_relative_slot_lookup(list/placements, turf/origin_turf)
	var/list/lookup = list()
	if(!istype(origin_turf) || !islist(placements))
		return lookup

	for(var/list/placement as anything in placements)
		if(!islist(placement))
			continue
		var/turf/target_turf = placement["turf"]
		var/dir_to_use = placement["dir"]
		var/kind = "[placement["kind"]]"
		if(!istype(target_turf) || !length(kind))
			continue
		lookup["[target_turf.x - origin_turf.x],[target_turf.y - origin_turf.y],[dir_to_use],[kind]"] = placement["obj_path"]
	return lookup

/datum/unit_test/world_edit_corner_slots/proc/assert_fortify_test_room_ready(list/room_context, context_label)
	TEST_ASSERT(islist(room_context), "[context_label] should keep a valid tracked room context.")
	TEST_ASSERT(!length("[room_context["error"]]"), "[room_context["error"]]")

/datum/world_edit_generator/fortify_room/world_edit_test_over_limit
	var/forced_placement_count = 601

/datum/world_edit_generator/fortify_room/world_edit_test_over_limit/collect_fortify_room_scan(turf/seed_turf, list/config, list/global_room_lookup = null, list/global_slot_lookup = null)
	var/list/result = list(
		"room_turfs" = list(),
		"placements" = list(),
		"room_tile_count" = 0,
		"window_slot_count" = 0,
		"door_slot_count" = 0,
		"skipped_existing_count" = 0,
		"cap_hit" = FALSE,
	)
	if(!istype(seed_turf))
		result["error"] = "World Edit fortify over-limit test could not resolve a seed turf."
		return result
	if(islist(global_room_lookup) && global_room_lookup[seed_turf])
		return result
	if(islist(global_room_lookup))
		global_room_lookup[seed_turf] = TRUE

	var/list/placements = list()
	for(var/i in 1 to forced_placement_count)
		placements += list(list(
			"kind" = "window_barricade",
			"boundary_kind" = "window",
			"turf" = seed_turf,
			"dir" = NORTH,
			"obj_path" = /obj/structure/barricade/metal,
			"slot_key" = "world_edit_test_over_limit_[i]",
		))

	result["room_turfs"] = list(seed_turf)
	result["placements"] = placements
	result["room_tile_count"] = 1
	result["window_slot_count"] = forced_placement_count
	return result

/datum/unit_test/world_edit_corner_slots/fortify_room_preset_mapping_and_manual_override/Run()
	var/datum/world_edit_manager/manager = allocate(/datum/world_edit_manager)
	var/datum/world_edit_generator_definition/fortify_room/definition = allocate(/datum/world_edit_generator_definition/fortify_room)
	var/datum/world_edit_generator/fortify_room/generator = allocate(/datum/world_edit_generator/fortify_room)
	var/turf/base_center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(base_center_turf, "World Edit fortify preset test center turf was not resolved.")

	var/list/room_context = track_fortify_test_room(setup_fortify_test_room(base_center_turf))
	assert_fortify_test_room_ready(room_context, "World Edit fortify preset test room helper")
	var/turf/center_turf = room_context["center_turf"]
	TEST_ASSERT_NOTNULL(center_turf, "World Edit fortify preset test should keep a valid center turf after room setup.")

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.placement_shape = WORLD_EDIT_SHAPE_POINT
	manager.placement_mode = "single"
	manager.placement_anchor_turf = center_turf

	var/list/expectations = list(
		"legacy_wood" = list(
			"main" = /obj/structure/barricade/wooden,
			"door" = null,
		),
		"legacy_sandbag" = list(
			"main" = /obj/structure/barricade/sandbags/full,
			"door" = null,
		),
		"legacy_sandbag_wired" = list(
			"main" = /obj/structure/barricade/sandbags/wired,
			"door" = null,
		),
		"legacy_metal" = list(
			"main" = /obj/structure/barricade/metal,
			"door" = /obj/structure/barricade/plasteel/metal,
		),
		"legacy_metal_wired" = list(
			"main" = /obj/structure/barricade/metal/wired,
			"door" = /obj/structure/barricade/plasteel/metal/wired,
		),
		"legacy_plasteel" = list(
			"main" = /obj/structure/barricade/metal/plasteel,
			"door" = /obj/structure/barricade/plasteel,
		),
		"legacy_plasteel_wired" = list(
			"main" = /obj/structure/barricade/metal/plasteel/wired,
			"door" = /obj/structure/barricade/plasteel/wired,
		),
	)

	for(var/preset_id as anything in expectations)
		var/list/params = definition.default_params?.Copy() || list()
		params["preset_id"] = preset_id
		var/datum/world_edit_plan/plan = generator.build_placement_plan(null, params, build_fortify_test_placement_context(center_turf))
		TEST_ASSERT(istype(plan, /datum/world_edit_plan), "World Edit fortify preset test should build a placement plan for preset '[preset_id]'.")
		TEST_ASSERT(!plan.metadata["error"], "World Edit fortify preset test should not emit a plan error for preset '[preset_id]'.")

		var/list/expected = expectations[preset_id]
		var/main_path = expected["main"]
		var/door_path = expected["door"]
		var/list/kind_counts = count_placements_by_kind(plan.placements)
		TEST_ASSERT_EQUAL(kind_counts["window_barricade"] || 0, 1, "World Edit fortify preset test should always place exactly one window barricade for preset '[preset_id]' in the controlled room.")
		if(ispath(door_path, /obj/structure/barricade))
			TEST_ASSERT_EQUAL(kind_counts["door_barricade"] || 0, 1, "World Edit fortify preset test should place exactly one folding door barricade for preset '[preset_id]'.")
		else
			TEST_ASSERT_EQUAL(kind_counts["door_barricade"] || 0, 0, "World Edit fortify preset test should skip door barricades for preset '[preset_id]' when legacy behavior has none.")

		for(var/list/placement as anything in plan.placements)
			if(placement["kind"] == "window_barricade")
				TEST_ASSERT_EQUAL(placement["obj_path"], main_path, "World Edit fortify preset test should map preset '[preset_id]' to the expected window barricade path.")
			else if(placement["kind"] == "door_barricade")
				TEST_ASSERT_EQUAL(placement["obj_path"], door_path, "World Edit fortify preset test should map preset '[preset_id]' to the expected folding door path.")

	var/list/ui_params = definition.default_params?.Copy() || list()
	var/list/preset_params = generator.set_ui_param(null, ui_params, "preset_id", "legacy_metal")
	TEST_ASSERT(islist(preset_params), "World Edit fortify preset UI test should return a params list after selecting a legacy preset.")
	var/list/customized_params = generator.set_ui_param(null, preset_params, "material_family", "plasteel")
	TEST_ASSERT(islist(customized_params), "World Edit fortify preset UI test should return a params list after manual material override.")
	TEST_ASSERT_EQUAL(customized_params["preset_id"], "custom", "World Edit fortify preset UI test should switch the preset id back to custom after a manual material override.")
	TEST_ASSERT_EQUAL(customized_params["material_family"], "plasteel", "World Edit fortify preset UI test should keep the manually selected material family.")
	TEST_ASSERT_EQUAL(customized_params["door_policy"], "auto", "World Edit fortify preset UI test should preserve the automatic door policy on a manual material override.")
	TEST_ASSERT_EQUAL(customized_params["door_material_family"], "plasteel", "World Edit fortify preset UI test should re-sync auto door material to the manual main material override.")

/datum/unit_test/world_edit_corner_slots/fortify_room_boundary_scan_respects_window_and_door_toggles/Run()
	var/datum/world_edit_generator/fortify_room/generator = allocate(/datum/world_edit_generator/fortify_room)
	var/turf/base_center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(base_center_turf, "World Edit fortify boundary test center turf was not resolved.")

	var/list/room_context = track_fortify_test_room(setup_fortify_test_room(base_center_turf))
	assert_fortify_test_room_ready(room_context, "World Edit fortify boundary test room helper")
	var/turf/center_turf = room_context["center_turf"]
	TEST_ASSERT_NOTNULL(center_turf, "World Edit fortify boundary test should keep a valid center turf after room setup.")

	var/list/default_config = generator.resolve_fortify_configuration(list(
		"preset_id" = "legacy_metal",
	))
	var/list/default_scan = generator.collect_fortify_room_scan(center_turf, default_config)
	TEST_ASSERT(!default_scan["error"], "World Edit fortify boundary test should scan the default room without errors.")
	TEST_ASSERT_EQUAL(default_scan["room_tile_count"], 9, "World Edit fortify boundary test should keep the 3x3 room interior size when windows and doors are treated as boundaries.")
	TEST_ASSERT_EQUAL(default_scan["window_slot_count"], 1, "World Edit fortify boundary test should expose one window slot in the controlled room.")
	TEST_ASSERT_EQUAL(default_scan["door_slot_count"], 1, "World Edit fortify boundary test should expose one door slot in the controlled room.")

	var/list/no_door_config = generator.resolve_fortify_configuration(list(
		"preset_id" = "legacy_metal",
		"treat_doors_as_boundary" = FALSE,
	))
	var/list/no_door_scan = generator.collect_fortify_room_scan(center_turf, no_door_config)
	TEST_ASSERT(!no_door_scan["error"], "World Edit fortify boundary test should scan successfully when door boundaries are disabled.")
	TEST_ASSERT_EQUAL(no_door_scan["room_tile_count"], 10, "World Edit fortify boundary test should absorb the door turf into the room when door boundaries are disabled.")
	TEST_ASSERT_EQUAL(no_door_scan["door_slot_count"], 0, "World Edit fortify boundary test should suppress door placements when doors are not treated as room boundaries.")
	TEST_ASSERT_EQUAL(no_door_scan["window_slot_count"], 1, "World Edit fortify boundary test should keep the window slot when only door boundaries are disabled.")

	var/list/no_window_config = generator.resolve_fortify_configuration(list(
		"preset_id" = "legacy_metal",
		"treat_windows_as_boundary" = FALSE,
	))
	var/list/no_window_scan = generator.collect_fortify_room_scan(center_turf, no_window_config)
	TEST_ASSERT(!no_window_scan["error"], "World Edit fortify boundary test should scan successfully when window boundaries are disabled.")
	TEST_ASSERT_EQUAL(no_window_scan["room_tile_count"], 10, "World Edit fortify boundary test should absorb the window turf into the room when window boundaries are disabled.")
	TEST_ASSERT_EQUAL(no_window_scan["window_slot_count"], 0, "World Edit fortify boundary test should suppress window placements when windows are not treated as room boundaries.")
	TEST_ASSERT_EQUAL(no_window_scan["door_slot_count"], 1, "World Edit fortify boundary test should keep the door slot when only window boundaries are disabled.")

/datum/unit_test/world_edit_corner_slots/fortify_room_scan_honors_room_tile_cap/Run()
	var/datum/world_edit_generator/fortify_room/generator = allocate(/datum/world_edit_generator/fortify_room)
	var/turf/base_center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(base_center_turf, "World Edit fortify cap test center turf was not resolved.")

	var/list/room_context = track_fortify_test_room(setup_fortify_test_room(base_center_turf, 3, 3, FALSE, FALSE))
	assert_fortify_test_room_ready(room_context, "World Edit fortify cap test room helper")
	var/turf/center_turf = room_context["center_turf"]
	TEST_ASSERT_NOTNULL(center_turf, "World Edit fortify cap test should keep a valid center turf after room setup.")

	var/list/config = generator.resolve_fortify_configuration(list(
		"preset_id" = "legacy_metal",
		"room_tile_cap" = 25,
	))
	var/list/scan_result = generator.collect_fortify_room_scan(center_turf, config)
	TEST_ASSERT(!scan_result["error"], "World Edit fortify cap test should scan the oversized room without hard errors.")
	TEST_ASSERT(scan_result["cap_hit"], "World Edit fortify cap test should report that the scan cap was hit for the oversized room.")
	TEST_ASSERT_EQUAL(scan_result["room_tile_count"], 25, "World Edit fortify cap test should clamp the reported room tile count to the requested cap.")

/datum/unit_test/world_edit_corner_slots/fortify_room_plan_builds_expected_window_and_door_slots/Run()
	var/datum/world_edit_manager/manager = allocate(/datum/world_edit_manager)
	var/datum/world_edit_generator_definition/fortify_room/definition = allocate(/datum/world_edit_generator_definition/fortify_room)
	var/datum/world_edit_generator/fortify_room/generator = allocate(/datum/world_edit_generator/fortify_room)
	var/turf/base_center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(base_center_turf, "World Edit fortify plan test center turf was not resolved.")

	var/list/room_context = track_fortify_test_room(setup_fortify_test_room(base_center_turf))
	assert_fortify_test_room_ready(room_context, "World Edit fortify plan test room helper")
	var/turf/center_turf = room_context["center_turf"]
	TEST_ASSERT_NOTNULL(center_turf, "World Edit fortify plan test should keep a valid center turf after room setup.")

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.placement_shape = WORLD_EDIT_SHAPE_POINT
	manager.placement_mode = "repeat"
	manager.placement_anchor_turf = center_turf

	var/list/params = definition.default_params?.Copy() || list()
	var/datum/world_edit_plan/plan = generator.build_placement_plan(null, params, build_fortify_test_placement_context(center_turf, "repeat"))
	TEST_ASSERT(istype(plan, /datum/world_edit_plan), "World Edit fortify plan test should build a placement plan.")
	TEST_ASSERT(!plan.metadata["error"], "World Edit fortify plan test should not emit a plan error in the controlled room.")
	TEST_ASSERT_EQUAL(plan.metadata["seed_turf"], center_turf, "World Edit fortify plan test should preserve the point seed turf in plan metadata.")
	TEST_ASSERT_EQUAL(plan.metadata["placement_mode"], "repeat", "World Edit fortify plan test should preserve the repeat placement mode in shared plan metadata.")
	TEST_ASSERT_EQUAL(plan.metadata["placement_count"], 2, "World Edit fortify plan test should expose two additive placements in the controlled room.")
	TEST_ASSERT_EQUAL(plan.metadata["window_slot_count"], 1, "World Edit fortify plan test should expose the single window slot count in metadata.")
	TEST_ASSERT_EQUAL(plan.metadata["door_slot_count"], 1, "World Edit fortify plan test should expose the single door slot count in metadata.")

	var/list/relative_slot_lookup = build_fortify_relative_slot_lookup(plan.placements, center_turf)
	TEST_ASSERT_EQUAL(length(relative_slot_lookup), 2, "World Edit fortify plan test should produce exactly the expected two relative barricade slots.")
	TEST_ASSERT(relative_slot_lookup["0,1,1,door_barricade"], "World Edit fortify plan test should create the folding barricade slot on the north interior edge.")
	TEST_ASSERT(relative_slot_lookup["1,0,4,window_barricade"], "World Edit fortify plan test should create the window barricade slot on the east interior edge.")

/datum/unit_test/world_edit_corner_slots/fortify_room_plan_rejects_unsafe_placement_count/Run()
	var/datum/world_edit_manager/manager = allocate(/datum/world_edit_manager)
	var/datum/world_edit_generator_definition/fortify_room/definition = allocate(/datum/world_edit_generator_definition/fortify_room)
	var/datum/world_edit_generator/fortify_room/world_edit_test_over_limit/generator = allocate(/datum/world_edit_generator/fortify_room/world_edit_test_over_limit)
	var/turf/center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(center_turf, "World Edit fortify over-limit test center turf was not resolved.")

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.placement_shape = WORLD_EDIT_SHAPE_POINT
	manager.placement_mode = "repeat"
	manager.placement_anchor_turf = center_turf

	var/list/params = definition.default_params?.Copy() || list()
	var/datum/world_edit_plan/plan = generator.build_placement_plan(null, params, build_fortify_test_placement_context(center_turf, "repeat"))
	TEST_ASSERT(istype(plan, /datum/world_edit_plan), "World Edit fortify over-limit test should still return a plan datum on guard failure.")
	TEST_ASSERT_EQUAL("[plan.metadata["error"]]", "Fortify Room requested placement exceeds safe limit (600).", "World Edit fortify over-limit test should reject synthetic scans that exceed the placement safety cap.")
	TEST_ASSERT_EQUAL(length(plan.placements), 0, "World Edit fortify over-limit test should clear placements when the safety cap trips.")
	TEST_ASSERT_EQUAL(length(plan.affected_turfs), 0, "World Edit fortify over-limit test should clear affected turf state when the safety cap trips.")

/datum/unit_test/world_edit_corner_slots/fortify_room_apply_and_undo_preserves_existing_barricades/Run()
	var/datum/world_edit_manager/manager = allocate(/datum/world_edit_manager)
	var/datum/world_edit_generator_definition/fortify_room/definition = allocate(/datum/world_edit_generator_definition/fortify_room)
	var/datum/world_edit_generator/fortify_room/generator = allocate(/datum/world_edit_generator/fortify_room)
	var/turf/base_center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(base_center_turf, "World Edit fortify apply/undo test center turf was not resolved.")

	var/list/room_context = track_fortify_test_room(setup_fortify_test_room(base_center_turf))
	assert_fortify_test_room_ready(room_context, "World Edit fortify apply/undo test room helper")
	var/turf/center_turf = room_context["center_turf"]
	var/turf/east_edge_turf = room_context["east_edge_turf"]
	var/turf/north_edge_turf = room_context["north_edge_turf"]
	TEST_ASSERT_NOTNULL(center_turf, "World Edit fortify apply/undo test should keep a valid center turf after room setup.")
	TEST_ASSERT_NOTNULL(east_edge_turf, "World Edit fortify apply/undo test should resolve the east interior edge turf.")
	TEST_ASSERT_NOTNULL(north_edge_turf, "World Edit fortify apply/undo test should resolve the north interior edge turf.")

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.placement_shape = WORLD_EDIT_SHAPE_POINT
	manager.placement_mode = "single"
	manager.placement_anchor_turf = center_turf

	var/obj/structure/barricade/metal/existing_window_barricade = allocate(/obj/structure/barricade/metal, east_edge_turf)
	TEST_ASSERT_NOTNULL(existing_window_barricade, "World Edit fortify apply/undo test should create an existing same-direction barricade helper.")
	existing_window_barricade.setDir(EAST)
	var/list/cleanup_atoms = room_context["cleanup_atoms"]
	cleanup_atoms[length(cleanup_atoms) + 1] = existing_window_barricade

	var/list/params = definition.default_params?.Copy() || list()
	var/datum/world_edit_plan/plan = generator.build_placement_plan(null, params, build_fortify_test_placement_context(center_turf))
	TEST_ASSERT(istype(plan, /datum/world_edit_plan), "World Edit fortify apply/undo test should build a placement plan.")
	TEST_ASSERT(!plan.metadata["error"], "World Edit fortify apply/undo test should not emit a plan error in the controlled room.")
	TEST_ASSERT_EQUAL(plan.metadata["skipped_existing_count"], 1, "World Edit fortify apply/undo test should mark the pre-existing same-direction barricade slot as skipped.")
	TEST_ASSERT_EQUAL(length(plan.placements), 1, "World Edit fortify apply/undo test should keep only the door placement once the matching window slot already exists.")

	var/datum/world_edit_apply_result/apply_result = generator.apply_plan(null, params, plan)
	TEST_ASSERT(istype(apply_result, /datum/world_edit_apply_result), "World Edit fortify apply/undo test should return an apply result datum.")
	TEST_ASSERT(apply_result.success, "World Edit fortify apply/undo test should still succeed when only the door slot remains additive.")
	TEST_ASSERT_EQUAL(apply_result.created_count, 1, "World Edit fortify apply/undo test should create exactly one new barricade after skipping the existing window slot.")
	TEST_ASSERT_EQUAL(apply_result.meta["created_door_count"], 1, "World Edit fortify apply/undo test should report the created folding door barricade.")
	TEST_ASSERT_EQUAL(apply_result.meta["created_window_count"], 0, "World Edit fortify apply/undo test should not create a new window barricade when that slot is already occupied.")

	var/obj/structure/barricade/plasteel/created_door_barricade = null
	for(var/obj/structure/barricade/plasteel/test_barricade in north_edge_turf)
		if(test_barricade.dir == NORTH)
			created_door_barricade = test_barricade
			break
	TEST_ASSERT_NOTNULL(created_door_barricade, "World Edit fortify apply/undo test should place the folding barricade door on the north edge turf.")
	TEST_ASSERT_NOTNULL(existing_window_barricade, "World Edit fortify apply/undo test should keep the original east-edge barricade instance alive after apply.")
	TEST_ASSERT(!QDELETED(existing_window_barricade), "World Edit fortify apply/undo test should preserve the original east-edge barricade instead of replacing it.")

	var/list/undo_result = GLOB.world_edit_changesets.revert_changeset(apply_result.changeset)
	TEST_ASSERT_EQUAL(undo_result["outcome"], "full", "World Edit fortify apply/undo test should fully revert the created folding barricade door.")
	TEST_ASSERT_EQUAL(undo_result["reverted_count"], 1, "World Edit fortify apply/undo test should revert exactly the created folding barricade door.")
	TEST_ASSERT(QDELETED(created_door_barricade), "World Edit fortify apply/undo test should remove the created folding barricade door on undo.")
	TEST_ASSERT(!QDELETED(existing_window_barricade), "World Edit fortify apply/undo test should leave the pre-existing east-edge barricade intact after undo.")

/datum/unit_test/world_edit_corner_slots/fortify_room_apply_noop_with_fully_fortified_room_is_successful/Run()
	var/datum/world_edit_manager/manager = allocate(/datum/world_edit_manager)
	var/datum/world_edit_generator_definition/fortify_room/definition = allocate(/datum/world_edit_generator_definition/fortify_room)
	var/datum/world_edit_generator/fortify_room/generator = allocate(/datum/world_edit_generator/fortify_room)
	var/turf/base_center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(base_center_turf, "World Edit fortify no-op apply test center turf was not resolved.")

	var/list/room_context = track_fortify_test_room(setup_fortify_test_room(base_center_turf))
	assert_fortify_test_room_ready(room_context, "World Edit fortify no-op apply test room helper")
	var/turf/center_turf = room_context["center_turf"]
	var/turf/east_edge_turf = room_context["east_edge_turf"]
	var/turf/north_edge_turf = room_context["north_edge_turf"]
	TEST_ASSERT_NOTNULL(center_turf, "World Edit fortify no-op apply test should keep a valid center turf after room setup.")
	TEST_ASSERT_NOTNULL(east_edge_turf, "World Edit fortify no-op apply test should resolve the east interior edge turf.")
	TEST_ASSERT_NOTNULL(north_edge_turf, "World Edit fortify no-op apply test should resolve the north interior edge turf.")

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.placement_shape = WORLD_EDIT_SHAPE_POINT
	manager.placement_mode = "single"
	manager.placement_anchor_turf = center_turf

	var/obj/structure/barricade/metal/existing_window_barricade = allocate(/obj/structure/barricade/metal, east_edge_turf)
	TEST_ASSERT_NOTNULL(existing_window_barricade, "World Edit fortify no-op apply test should create the pre-existing window barricade helper.")
	existing_window_barricade.setDir(EAST)

	var/obj/structure/barricade/plasteel/metal/existing_door_barricade = allocate(/obj/structure/barricade/plasteel/metal, north_edge_turf)
	TEST_ASSERT_NOTNULL(existing_door_barricade, "World Edit fortify no-op apply test should create the pre-existing door barricade helper.")
	existing_door_barricade.setDir(NORTH)

	var/list/cleanup_atoms = room_context["cleanup_atoms"]
	cleanup_atoms[length(cleanup_atoms) + 1] = existing_window_barricade
	cleanup_atoms[length(cleanup_atoms) + 1] = existing_door_barricade

	var/list/params = definition.default_params?.Copy() || list()
	var/datum/world_edit_plan/plan = generator.build_placement_plan(null, params, build_fortify_test_placement_context(center_turf))
	TEST_ASSERT(istype(plan, /datum/world_edit_plan), "World Edit fortify no-op apply test should build a placement plan.")
	TEST_ASSERT(!plan.metadata["error"], "World Edit fortify no-op apply test should not emit a plan error in the controlled room.")
	TEST_ASSERT_EQUAL(plan.metadata["skipped_existing_count"], 2, "World Edit fortify no-op apply test should skip both pre-existing same-direction barricade slots.")
	TEST_ASSERT_EQUAL(length(plan.placements), 0, "World Edit fortify no-op apply test should produce no new placements when every slot is already fortified.")

	var/datum/world_edit_apply_result/apply_result = generator.apply_plan(null, params, plan)
	TEST_ASSERT(istype(apply_result, /datum/world_edit_apply_result), "World Edit fortify no-op apply test should return an apply result datum.")
	TEST_ASSERT(apply_result.success, "World Edit fortify no-op apply test should treat a fully-fortified room as a successful no-op apply.")
	TEST_ASSERT_EQUAL(apply_result.created_count, 0, "World Edit fortify no-op apply test should not create any new barricades.")
	TEST_ASSERT_EQUAL(apply_result.meta["created_window_count"], 0, "World Edit fortify no-op apply test should report zero created window barricades.")
	TEST_ASSERT_EQUAL(apply_result.meta["created_door_count"], 0, "World Edit fortify no-op apply test should report zero created door barricades.")
	TEST_ASSERT_EQUAL(apply_result.meta["skipped_runtime"], 0, "World Edit fortify no-op apply test should not accumulate runtime skips when the plan is already empty.")
	TEST_ASSERT_NULL(apply_result.changeset, "World Edit fortify no-op apply test should not create an undo changeset for a successful no-op apply.")

/datum/unit_test/world_edit_corner_slots/fortify_room_preview_specs_match_plan_placements_and_seed_fallbacks/Run()
	var/datum/world_edit_manager/manager = allocate(/datum/world_edit_manager)
	var/datum/world_edit_generator_definition/fortify_room/definition = allocate(/datum/world_edit_generator_definition/fortify_room)
	var/datum/world_edit_generator/fortify_room/generator = allocate(/datum/world_edit_generator/fortify_room)
	var/turf/base_center_turf = get_world_edit_test_center_turf()
	TEST_ASSERT_NOTNULL(base_center_turf, "World Edit fortify preview-spec test center turf was not resolved.")

	var/list/room_context = track_fortify_test_room(setup_fortify_test_room(base_center_turf))
	assert_fortify_test_room_ready(room_context, "World Edit fortify preview-spec test room helper")
	var/turf/center_turf = room_context["center_turf"]
	TEST_ASSERT_NOTNULL(center_turf, "World Edit fortify preview-spec test should keep a valid center turf after room setup.")

	generator.attach(manager, definition)
	manager.current_definition = definition
	manager.current_generator = generator
	manager.placement_shape = WORLD_EDIT_SHAPE_POINT
	manager.placement_mode = "single"

	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human, center_turf)
	TEST_ASSERT_NOTNULL(human, "World Edit fortify preview-spec test should create a fallback-seed human helper.")
	var/list/cleanup_atoms = room_context["cleanup_atoms"]
	cleanup_atoms[length(cleanup_atoms) + 1] = human

	manager.placement_anchor_turf = null
	TEST_ASSERT_EQUAL(generator.resolve_fortify_anchor_turf(human), center_turf, "World Edit fortify preview-spec test should fall back to the user's current turf when no placement anchor is active.")

	manager.placement_anchor_turf = center_turf
	TEST_ASSERT_EQUAL(generator.resolve_fortify_anchor_turf(human), center_turf, "World Edit fortify preview-spec test should prefer the active placement anchor when one exists.")

	var/list/params = definition.default_params?.Copy() || list()
	manager.current_params = params.Copy()
	var/datum/world_edit_plan/plan = generator.build_plan(params)
	TEST_ASSERT(istype(plan, /datum/world_edit_plan), "World Edit fortify preview-spec test should build a plan from the manager anchor turf.")
	TEST_ASSERT(!plan.metadata["error"], "World Edit fortify preview-spec test should build a valid fortify plan from the manager anchor turf.")
	TEST_ASSERT_EQUAL(plan.metadata["seed_turf"], center_turf, "World Edit fortify preview-spec test should expose the point seed turf in the built plan metadata.")
	TEST_ASSERT_EQUAL(length(generator.build_plan_preview_object_specs(plan, params, build_fortify_test_placement_context(center_turf), TRUE)), 0, "World Edit fortify preview-spec test should skip expensive object-preview specs for hover-only placement previews.")
	TEST_ASSERT(manager.render_plan_preview_with_placement_layers(null, plan, params), "World Edit fortify preview-spec test should synthesize placement-preview layers from the fortify plan.")

	var/datum/world_edit_placement_candidate/candidate = manager.get_placement_preview_candidate()
	TEST_ASSERT(istype(candidate?.preview_model, /datum/world_edit_preview_model), "World Edit fortify preview-spec test should keep a preview model on the synthesized placement candidate.")
	TEST_ASSERT_EQUAL(length(candidate.preview_model.generator_preview_object_specs), length(plan.placements), "World Edit fortify preview-spec test should expose one object-preview spec per planned barricade placement.")
	TEST_ASSERT_EQUAL(length(GLOB.world_edit_helpers.build_preview_images_from_specs(candidate.preview_model.generator_preview_object_specs)), length(plan.placements), "World Edit fortify preview-spec test should resolve each planned barricade placement into a preview image.")
