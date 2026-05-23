/datum/world_edit_building_layout_state
	var/datum/world_edit_building_request/request
	var/datum/world_edit_building_archetype/archetype
	var/datum/world_edit_building_semantic_plan/semantic_plan
	var/list/config = list()
	var/current_request_support_status = WORLD_EDIT_BUILDING_SUPPORT_FAILED
	var/user_facing_failure_reason = ""
	var/list/footprint = list()
	var/list/boundary = list()
	var/list/interior = list()
	var/list/bounds = list()
	var/list/footprint_lookup = list()
	var/list/boundary_lookup = list()
	var/list/wall_lookup = list()
	var/list/floor_turfs = list()
	var/list/floor_lookup = list()
	var/list/door_turfs = list()
	var/list/door_dirs = list()
	var/list/window_turfs = list()
	var/list/object_placements = list()
	var/list/fixture_lookup = list()
	var/list/fixture_categories = list()
	var/list/category_counts = list()
	var/list/cluster_counts = list()
	var/list/signature_counts = list()
	var/list/signature_warnings = list()
	var/list/major_fixture_turfs = list()
	var/list/wall_fixture_turfs = list()
	var/list/reserved_lookup = list()
	var/list/zone_by_turf = list()
	var/list/zone_turfs = list()
	var/list/zone_focus_turfs = list()
	var/list/anchor_turfs = list()
	var/list/anchor_lookup = list()
	var/list/adjacent_wall_dirs_by_turf = list()
	var/list/solved_regions = list()
	var/list/solved_rooms = list()
	var/list/room_by_turf = list()
	var/list/corridor_turfs = list()
	var/list/corridor_lookup = list()
	var/list/divider_plans = list()
	var/list/primary_route_turfs = list()
	var/list/separator_lane_turfs = list()
	var/list/separator_lane_lookup = list()
	var/list/internal_wall_turfs = list()
	var/list/category_budgets = list()
	var/list/layout_macros = list()
	var/list/layout_macro_counts = list()
	var/list/semantic_slot_reports = list()
	var/list/semantic_slot_anchor_sets = list()
	var/list/semantic_slot_selected_modes = list()
	var/list/semantic_slot_turf_sets = list()
	var/list/placed_requirement_counts = list()
	var/list/semantic_requirement_counts = list()
	var/list/semantic_requirement_minimums = list()
	var/list/semantic_requirement_reports = list()
	var/list/semantic_slot_reservation_by_turf = list()
	var/list/semantic_slot_reserved_turfs = list()
	var/list/stage_reports = list()
	var/list/room_reports = list()
	var/list/zone_reports = list()
	var/list/corridor_report = list()
	var/list/wall_report = list()
	var/list/door_reports = list()
	var/list/anchor_report = list()
	var/list/pattern_reports = list()
	var/list/infrastructure_report = list()
	var/list/post_emit_validation_report = list()
	var/list/support_status_report = list()
	var/list/fallback_audit = list()
	var/list/old_path_audit = list()
	var/list/validation_reachable_floor_lookup = null
	var/list/errors = list()
	var/list/warnings = list()
	var/turf/center_turf
	var/turf/semantic_hub_turf
	var/turf/front_door_turf
	var/placement_dir = NORTH
	var/max_front_depth = 1
	var/max_lateral_abs = 1
	var/usable_fixture_area = 0
	var/fixture_count = 0
	var/major_fixture_count = 0
	var/signature_score = 0
	var/signature_max_score = 0
	var/category_coverage_score = 0
	var/repeat_index = 0
	var/style_score = 0
	var/empty_floor_ratio = 0
	var/privacy_violation_count = 0
	var/reachability_failure_count = 0
	var/repetition_conflict_count = 0
	var/fixture_density_score = 0
	var/connectivity_score = 0
	var/visibility_privacy_score = 0
	var/space_distribution_score = 0
	var/door_buffer_conflict_count = 0
	var/window_conflict_count = 0
	var/facade_conflict_count = 0
	var/invalid_window_count = 0
	var/service_wall_window_violation_count = 0
	var/secure_wall_window_violation_count = 0
	var/fixture_conflict_count = 0
	var/route_conflict_count = 0
	var/signature_failure_count = 0
	var/layout_candidate_score = 0
	var/region_claim_count = 0
	var/rectangular_region_candidate_count = 0
	var/nested_room_count = 0
	var/microvariation_count = 0
	var/template_chunk_count = 0
	var/template_chunk_cell_count = 0
	var/infrastructure_count = 0
	var/degraded_region_fallback_count = 0
	var/semantic_slot_capacity_count = 0
	var/semantic_slot_shortage_count = 0
	var/semantic_slot_fallback_count = 0
	var/semantic_slot_reservation_conflict_count = 0
	var/mandatory_room_count = 0
	var/mandatory_zone_count = 0
	var/mandatory_room_missing_count = 0
	var/mandatory_room_no_bounds_count = 0
	var/mandatory_room_no_access_count = 0
	var/mandatory_pattern_missing_count = 0
	var/mandatory_pattern_uncredited_count = 0
	var/mandatory_pattern_failure_count = 0
	var/mandatory_anchor_missing_count = 0
	var/mandatory_fixture_access_unreachable_count = 0
	var/reserved_walk_blocked_count = 0
	var/door_cone_blocked_count = 0
	var/double_wall_error_count = 0
	var/double_wall_repair_count = 0
	var/diagonal_only_contact_count = 0
	var/diagonal_wall_repair_count = 0
	var/cutout_violation_count = 0
	var/unsupported_shape_silent_fallback_count = 0
	var/style_required_slot_missing_count = 0
	var/raw_category_credit_count = 0
	var/scatter_signature_credit_count = 0
	var/semantic_credit_without_emitted_slots_count = 0
	var/forbidden_fallback_count = 0
	var/mandatory_room_patch_fallback_count = 0
	var/fallback_anchor_required_cluster_count = 0
	var/emit_missing_path_count = 0
	var/emit_failed_object_count = 0
	var/emit_state_mismatch_count = 0
	var/post_emit_validation_error_count = 0
	var/replace_blocked_turf_count = 0
	var/blocked_turf_conflict_count = 0
	var/blocked_route_conflict_count = 0
	var/blocked_room_conflict_count = 0
	var/blocked_wall_conflict_count = 0
	var/blocked_fixture_conflict_count = 0
	var/route_access_repair_count = 0
	var/direction_honored_count = 0
	var/direction_fallback_count = 0
	var/requested_direction = NORTH
	var/actual_entry_direction = NORTH
	var/direction_fallback_reason = ""
	var/entry_face_readable = FALSE
	var/counter_wrong_facing_count = 0
	var/entry_face_mismatch_count = 0
	var/wall_machinery_invalid_dir_count = 0
	var/wall_machinery_no_wall_count = 0
	var/infrastructure_required_missing_count = 0
	var/infrastructure_route_block_count = 0
	var/root_seed = 0
	var/stage_seed_footprint = 0
	var/stage_seed_rooms = 0
	var/stage_seed_corridor = 0
	var/stage_seed_patterns = 0
	var/stage_seed_details = 0
	var/footprint_hash = 0
	var/room_graph_hash = 0
	var/route_hash = 0
	var/wall_hash = 0
	var/pattern_credit_hash = 0
	var/layout_hash = 0
	var/determinism_check_hash = 0
	var/list/degraded_region_reports = list()
	var/list/region_claim_reports = list()

/datum/world_edit_building_layout_state/proc/add_error(message)
	if(length(errors) >= WORLD_EDIT_BUILDING_MAX_VALIDATION_ERRORS)
		return
	errors += "[message]"

/datum/world_edit_building_layout_state/proc/add_warning(message)
	warnings += "[message]"

/datum/world_edit_building_layout_state/proc/add_capped_report(list/report_list, list/report, max_count)
	if(!islist(report_list) || !islist(report))
		return null
	var/cap = max(round(text2num("[max_count]") || 0), 1)
	if(length(report_list) >= cap)
		return null
	report_list += list(report)
	return report

/datum/world_edit_building_layout_state/proc/set_support_status(status, reason = null)
	current_request_support_status = length("[status]") ? "[status]" : WORLD_EDIT_BUILDING_SUPPORT_FAILED
	if(!isnull(reason))
		user_facing_failure_reason = "[reason]"
	support_status_report = list(
		"status" = current_request_support_status,
		"reason" = user_facing_failure_reason,
		"program_id" = archetype?.id,
		"shape_id" = config["placement_shape_id"],
		"style_id" = config["faction_preset"],
		"size" = "[config["half_width"]]x[config["half_depth"]]",
		"respect_blockers" = config["respect_blockers"] ? TRUE : FALSE,
		"replace_blocked_turfs" = config["replace_blocked_turfs"] ? TRUE : FALSE,
	)

/datum/world_edit_building_layout_state/proc/add_stage_report(stage_id, status, reason = null, list/extra = null)
	var/list/report = list(
		"stage_id" = "[stage_id]",
		"status" = "[status]",
	)
	if(!isnull(reason))
		report["reason"] = "[reason]"
	if(islist(extra))
		for(var/key as anything in extra)
			report[key] = extra[key]
	add_capped_report(stage_reports, report, WORLD_EDIT_BUILDING_MAX_STAGE_REPORTS)
	return report

/datum/world_edit_building_layout_state/proc/add_pattern_report(list/report)
	return add_capped_report(pattern_reports, report, WORLD_EDIT_BUILDING_MAX_PATTERN_REPORTS)

/datum/world_edit_building_layout_state/proc/add_semantic_slot_report(list/report)
	return add_capped_report(semantic_slot_reports, report, WORLD_EDIT_BUILDING_MAX_SEMANTIC_SLOT_REPORTS)

/datum/world_edit_building_layout_state/proc/add_semantic_requirement_report(list/report)
	return add_capped_report(semantic_requirement_reports, report, WORLD_EDIT_BUILDING_MAX_SEMANTIC_SLOT_REPORTS)

/datum/world_edit_building_layout_state/proc/add_degraded_region_report(list/report)
	return add_capped_report(degraded_region_reports, report, WORLD_EDIT_BUILDING_MAX_DEGRADED_REGION_REPORTS)

/datum/world_edit_building_layout_state/proc/clear_validation_cache()
	if(islist(validation_reachable_floor_lookup))
		validation_reachable_floor_lookup.Cut()
	validation_reachable_floor_lookup = null

/datum/world_edit_building_layout_state/proc/has_errors()
	return length(errors) > 0

/datum/world_edit_building_layout_state/proc/append_unique_turf(list/target, turf/target_turf)
	if(!islist(target) || !istype(target_turf))
		return FALSE
	if(target_turf in target)
		return FALSE
	target += target_turf
	return TRUE

/datum/world_edit_building_layout_state/proc/add_zone(turf/target_turf, zone_id)
	if(!istype(target_turf) || !length("[zone_id]"))
		return
	var/old_zone_id = zone_by_turf[target_turf]
	if(length("[old_zone_id]") && old_zone_id != "[zone_id]")
		var/list/old_turfs = zone_turfs["[old_zone_id]"]
		if(islist(old_turfs))
			old_turfs -= target_turf
	zone_by_turf[target_turf] = "[zone_id]"
	var/list/turfs = zone_turfs["[zone_id]"]
	if(!islist(turfs))
		turfs = list()
		zone_turfs["[zone_id]"] = turfs
	append_unique_turf(turfs, target_turf)

/datum/world_edit_building_layout_state/proc/clear_zones()
	zone_by_turf.Cut()
	zone_turfs.Cut()
	zone_focus_turfs.Cut()

/datum/world_edit_building_layout_state/proc/get_zone(turf/target_turf)
	return "[zone_by_turf[target_turf] || ""]"

/datum/world_edit_building_layout_state/proc/get_zone_turfs(zone_id)
	var/list/turfs = zone_turfs["[zone_id]"]
	return islist(turfs) ? turfs : list()

/datum/world_edit_building_layout_state/proc/set_zone_focus(zone_id, turf/target_turf)
	if(!istype(target_turf) || !length("[zone_id]"))
		return
	zone_focus_turfs["[zone_id]"] = target_turf

/datum/world_edit_building_layout_state/proc/get_zone_focus(zone_id)
	return zone_focus_turfs["[zone_id]"]

/datum/world_edit_building_layout_state/proc/add_anchor(anchor_id, turf/target_turf)
	if(!istype(target_turf) || !length("[anchor_id]"))
		return
	var/anchor_key = "[anchor_id]"
	var/list/turfs = anchor_turfs[anchor_key]
	if(!islist(turfs))
		turfs = list()
		anchor_turfs[anchor_key] = turfs
	var/list/lookup = anchor_lookup[anchor_key]
	if(!islist(lookup))
		lookup = list()
		anchor_lookup[anchor_key] = lookup
	if(lookup[target_turf])
		return
	turfs += target_turf
	lookup[target_turf] = TRUE

/datum/world_edit_building_layout_state/proc/get_anchor_turfs(anchor_id)
	var/list/turfs = anchor_turfs["[anchor_id]"]
	return islist(turfs) ? turfs : list()

/datum/world_edit_building_layout_state/proc/has_anchor(anchor_id, turf/target_turf)
	if(!istype(target_turf))
		return FALSE
	var/list/lookup = anchor_lookup["[anchor_id]"]
	return islist(lookup) && lookup[target_turf]

/datum/world_edit_building_layout_state/proc/clear_anchors()
	anchor_turfs.Cut()
	anchor_lookup.Cut()

/datum/world_edit_building_layout_state/proc/add_reserved(turf/target_turf)
	if(istype(target_turf))
		reserved_lookup[target_turf] = TRUE

/datum/world_edit_building_layout_state/proc/add_primary_route(turf/target_turf)
	if(!istype(target_turf))
		return
	append_unique_turf(primary_route_turfs, target_turf)
	add_reserved(target_turf)

/datum/world_edit_building_layout_state/proc/add_corridor_turf(turf/target_turf)
	if(!istype(target_turf) || !footprint_lookup[target_turf])
		return FALSE
	if(!corridor_lookup[target_turf])
		corridor_turfs += target_turf
		corridor_lookup[target_turf] = TRUE
	add_primary_route(target_turf)
	return TRUE

/datum/world_edit_building_layout_state/proc/add_separator_lane(turf/target_turf)
	if(!istype(target_turf) || !footprint_lookup[target_turf])
		return FALSE
	if(boundary_lookup[target_turf] || corridor_lookup[target_turf] || door_dirs[target_turf])
		return FALSE
	if(separator_lane_lookup[target_turf])
		return TRUE
	separator_lane_lookup[target_turf] = TRUE
	append_unique_turf(separator_lane_turfs, target_turf)
	return TRUE

/datum/world_edit_building_layout_state/proc/add_solved_room(datum/world_edit_building_room/room)
	if(!istype(room) || !length(room.turfs))
		return FALSE
	if(!(room in solved_rooms))
		solved_rooms += room
	for(var/turf/room_turf as anything in room.turfs)
		if(!istype(room_turf) || !footprint_lookup[room_turf])
			continue
		room_by_turf[room_turf] = room
		add_zone(room_turf, room.zone_id)
	if(istype(room.focus_turf))
		set_zone_focus(room.zone_id, room.focus_turf)
	return TRUE

/datum/world_edit_building_layout_state/proc/get_room_for_turf(turf/target_turf)
	if(!istype(target_turf))
		return null
	return room_by_turf[target_turf]

/datum/world_edit_building_layout_state/proc/clear_room_layout()
	solved_rooms.Cut()
	room_by_turf.Cut()
	corridor_turfs.Cut()
	corridor_lookup.Cut()
	solved_regions.Cut()
	divider_plans.Cut()
	internal_wall_turfs.Cut()
	primary_route_turfs.Cut()
	separator_lane_turfs.Cut()
	separator_lane_lookup.Cut()
	reserved_lookup.Cut()
	wall_lookup.Cut()
	floor_turfs.Cut()
	floor_lookup.Cut()
	adjacent_wall_dirs_by_turf.Cut()
	clear_zones()

/datum/world_edit_building_layout_state/proc/add_internal_wall(turf/target_turf)
	if(!istype(target_turf) || !footprint_lookup[target_turf])
		return FALSE
	if(reserved_lookup[target_turf] || door_dirs[target_turf])
		return FALSE
	wall_lookup[target_turf] = TRUE
	adjacent_wall_dirs_by_turf.Cut()
	append_unique_turf(internal_wall_turfs, target_turf)
	return TRUE

/datum/world_edit_building_layout_state/proc/add_divider_plan(datum/world_edit_building_divider_plan/divider_plan)
	if(!istype(divider_plan))
		return FALSE
	if(!(divider_plan in divider_plans))
		divider_plans += divider_plan
	for(var/turf/inner_turf as anything in divider_plan.inner_turfs)
		if(istype(inner_turf) && footprint_lookup[inner_turf] && !reserved_lookup[inner_turf])
			add_zone(inner_turf, divider_plan.inner_zone_id)
	var/list/emitted_wall_turfs = list()
	for(var/turf/wall_turf as anything in divider_plan.wall_turfs)
		if(add_internal_wall(wall_turf))
			emitted_wall_turfs += wall_turf
	divider_plan.wall_turfs = emitted_wall_turfs
	for(var/turf/opening_turf as anything in divider_plan.opening_turfs)
		if(!istype(opening_turf) || !footprint_lookup[opening_turf])
			continue
		append_unique_turf(door_turfs, opening_turf)
		door_dirs[opening_turf] = divider_plan.opening_dirs[opening_turf] || NORTH
		add_zone(opening_turf, divider_plan.source_zone_id)
	return TRUE

/datum/world_edit_building_layout_state/proc/can_place_fixture(turf/target_turf, allow_reserved = FALSE)
	if(!istype(target_turf))
		return FALSE
	if(!floor_lookup[target_turf])
		return FALSE
	if(wall_lookup[target_turf] || door_dirs[target_turf])
		return FALSE
	if(fixture_lookup[target_turf])
		return FALSE
	if(!allow_reserved && reserved_lookup[target_turf])
		return FALSE
	if(has_anchor("door_cone", target_turf))
		return FALSE
	return TRUE

/datum/world_edit_building_layout_state/proc/register_fixture(turf/target_turf, category, major = FALSE, wall_mounted = FALSE)
	if(!istype(target_turf))
		return
	fixture_lookup[target_turf] = TRUE
	fixture_categories[target_turf] = "[category]"
	category_counts["[category]"] = (category_counts["[category]"] || 0) + 1
	fixture_count++
	if(major)
		major_fixture_count++
		append_unique_turf(major_fixture_turfs, target_turf)
	if(wall_mounted)
		append_unique_turf(wall_fixture_turfs, target_turf)

/datum/world_edit_building_layout_state/proc/rebuild_fixture_indexes()
	fixture_lookup.Cut()
	fixture_categories.Cut()
	category_counts.Cut()
	cluster_counts.Cut()
	signature_counts.Cut()
	placed_requirement_counts.Cut()
	semantic_requirement_counts.Cut()
	major_fixture_turfs.Cut()
	wall_fixture_turfs.Cut()
	fixture_count = 0
	major_fixture_count = 0
	template_chunk_count = 0
	template_chunk_cell_count = 0
	infrastructure_count = 0
	var/list/template_chunk_instance_lookup = list()
	for(var/list/object_placement as anything in object_placements)
		if(!islist(object_placement) || "[object_placement["kind"]]" != "interior")
			continue
		var/turf/target_turf = object_placement["turf"]
		if(!istype(target_turf))
			continue
		var/category = "[object_placement["category"] || ""]"
		if(!length(category))
			category = "object"
		register_fixture(target_turf, category, GLOB.world_edit_helpers.parse_bool(object_placement["major"]), GLOB.world_edit_helpers.parse_bool(object_placement["wall_mounted"]))
		var/cluster_credit = round(text2num("[object_placement["cluster_count_credit"]]") || 0)
		if(cluster_credit > 0 && length("[object_placement["cluster_id"]]"))
			register_cluster(object_placement["cluster_id"], cluster_credit)
		var/signature_credit = round(text2num("[object_placement["signature_count_credit"]]") || 0)
		if(signature_credit > 0 && length("[object_placement["signature_id"]]"))
			register_signature(object_placement["signature_id"], signature_credit)
		var/requirement_credit = round(text2num("[object_placement["requirement_count_credit"]]") || 0)
		if(requirement_credit > 0 && length("[object_placement["requirement_id"]]"))
			register_placed_requirement(object_placement["requirement_id"], requirement_credit)
		if(length("[object_placement["template_chunk_id"]]"))
			template_chunk_cell_count++
			var/template_chunk_instance_id = "[object_placement["template_chunk_instance_id"]]"
			if(!length(template_chunk_instance_id))
				template_chunk_instance_id = "[object_placement["template_chunk_id"]]@[target_turf.x],[target_turf.y],[target_turf.z]"
			if(!template_chunk_instance_lookup[template_chunk_instance_id])
				template_chunk_instance_lookup[template_chunk_instance_id] = TRUE
				template_chunk_count++
		if(GLOB.world_edit_helpers.parse_bool(object_placement["infrastructure"]))
			infrastructure_count++
	reconcile_canonical_requirement_count("infrastructure_lights", "light")
	reconcile_canonical_requirement_count("infrastructure_apc", "apc")
	reconcile_canonical_requirement_count("infrastructure_air_alarm", "air_alarm")
	reconcile_canonical_requirement_count("infrastructure_light_switch", "light_switch")
	reconcile_canonical_requirement_count("infrastructure_fire_alarm", "fire_alarm")

/datum/world_edit_building_layout_state/proc/remove_fixture_at(turf/target_turf)
	if(!istype(target_turf))
		return FALSE
	var/removed = FALSE
	for(var/index = length(object_placements), index >= 1, index--)
		var/list/object_placement = object_placements[index]
		if(!islist(object_placement) || object_placement["turf"] != target_turf || "[object_placement["kind"]]" != "interior")
			continue
		object_placements.Cut(index, index + 1)
		removed = TRUE
	if(removed)
		rebuild_fixture_indexes()
	return removed

/datum/world_edit_building_layout_state/proc/reset_validation_metrics()
	privacy_violation_count = 0
	reachability_failure_count = 0
	repetition_conflict_count = 0
	door_buffer_conflict_count = 0
	window_conflict_count = 0
	facade_conflict_count = 0
	invalid_window_count = 0
	service_wall_window_violation_count = 0
	secure_wall_window_violation_count = 0
	fixture_conflict_count = 0
	route_conflict_count = 0
	signature_failure_count = 0
	mandatory_room_missing_count = 0
	mandatory_room_no_bounds_count = 0
	mandatory_room_no_access_count = 0
	mandatory_pattern_missing_count = 0
	mandatory_pattern_uncredited_count = 0
	mandatory_pattern_failure_count = 0
	mandatory_anchor_missing_count = 0
	mandatory_fixture_access_unreachable_count = 0
	reserved_walk_blocked_count = 0
	door_cone_blocked_count = 0
	double_wall_error_count = 0
	double_wall_repair_count = 0
	diagonal_only_contact_count = 0
	diagonal_wall_repair_count = 0
	raw_category_credit_count = 0
	scatter_signature_credit_count = 0
	semantic_credit_without_emitted_slots_count = 0
	wall_machinery_invalid_dir_count = 0
	wall_machinery_no_wall_count = 0
	infrastructure_required_missing_count = 0
	infrastructure_route_block_count = 0
	blocked_route_conflict_count = 0
	blocked_room_conflict_count = 0
	blocked_wall_conflict_count = 0
	blocked_fixture_conflict_count = 0
	clear_validation_cache()

/datum/world_edit_building_layout_state/proc/register_layout_macro(macro_id, category, turf/anchor_turf, dir_value = SOUTH, list/covered_turfs = null, list/source_ids = null)
	if(!length("[macro_id]") || !istype(anchor_turf))
		return
	var/list/macro = list(
		"id" = "[macro_id]",
		"category" = length("[category]") ? "[category]" : "generic",
		"turf" = anchor_turf,
		"dir" = dir_value,
		"covered_turfs" = islist(covered_turfs) ? covered_turfs.Copy() : list(anchor_turf),
		"source_ids" = islist(source_ids) ? source_ids.Copy() : list(),
	)
	layout_macros += list(macro)
	layout_macro_counts["[macro_id]"] = (layout_macro_counts["[macro_id]"] || 0) + 1

/datum/world_edit_building_layout_state/proc/register_cluster(cluster_id, placed_count)
	if(!length("[cluster_id]") || placed_count <= 0)
		return
	cluster_counts["[cluster_id]"] = (cluster_counts["[cluster_id]"] || 0) + placed_count

/datum/world_edit_building_layout_state/proc/register_signature(signature_id, placed_count)
	if(!length("[signature_id]") || placed_count <= 0)
		return
	signature_counts["[signature_id]"] = (signature_counts["[signature_id]"] || 0) + placed_count

/datum/world_edit_building_layout_state/proc/register_requirement(requirement_id, placed_count)
	if(!length("[requirement_id]") || placed_count <= 0)
		return
	semantic_requirement_counts["[requirement_id]"] = (semantic_requirement_counts["[requirement_id]"] || 0) + placed_count

/datum/world_edit_building_layout_state/proc/register_placed_requirement(requirement_id, placed_count)
	if(!length("[requirement_id]") || placed_count <= 0)
		return
	placed_requirement_counts["[requirement_id]"] = (placed_requirement_counts["[requirement_id]"] || 0) + placed_count

/datum/world_edit_building_layout_state/proc/reconcile_canonical_requirement_count(requirement_id, category)
	if(!length("[requirement_id]") || !length("[category]"))
		return
	var/current_count = round(text2num("[placed_requirement_counts["[requirement_id]"]]") || 0)
	var/category_count = round(text2num("[category_counts["[category]"]]") || 0)
	if(category_count > current_count)
		placed_requirement_counts["[requirement_id]"] = category_count

/datum/world_edit_building_layout_state/proc/clear_semantic_slot_reservations()
	semantic_slot_reservation_by_turf.Cut()
	semantic_slot_reserved_turfs.Cut()
	semantic_slot_reservation_conflict_count = 0

/datum/world_edit_building_layout_state/proc/reserve_semantic_slot(requirement_id, turf/target_turf)
	if(!length("[requirement_id]") || !istype(target_turf))
		return FALSE
	var/owner = "[semantic_slot_reservation_by_turf[target_turf] || ""]"
	if(length(owner) && owner != "[requirement_id]")
		semantic_slot_reservation_conflict_count++
		return FALSE
	semantic_slot_reservation_by_turf[target_turf] = "[requirement_id]"
	var/list/turfs = semantic_slot_reserved_turfs["[requirement_id]"]
	if(!islist(turfs))
		turfs = list()
		semantic_slot_reserved_turfs["[requirement_id]"] = turfs
	append_unique_turf(turfs, target_turf)
	return TRUE

/datum/world_edit_building_layout_state/proc/get_semantic_slot_owner(turf/target_turf)
	if(!istype(target_turf))
		return ""
	return "[semantic_slot_reservation_by_turf[target_turf] || ""]"

/datum/world_edit_building_layout_state/proc/get_category_budget(category)
	var/budget = category_budgets["[category]"]
	if(isnum(budget) && budget > 0)
		return budget
	budget = semantic_plan?.object_budgets["[category]"]
	if(isnum(budget) && budget > 0)
		return budget
	budget = archetype?.object_budgets["[category]"]
	if(isnum(budget) && budget > 0)
		return budget
	return WORLD_EDIT_BUILDING_MAX_FIXTURE_OBJECTS
