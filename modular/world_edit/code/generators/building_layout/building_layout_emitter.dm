/datum/world_edit_generator/building_layout/proc/format_building_messages(list/messages)
	if(!islist(messages) || !length(messages))
		return ""
	var/output = ""
	for(var/message as anything in messages)
		if(!length("[message]"))
			continue
		if(length(output))
			output = "[output]; "
		output = "[output][message]"
	return output

/datum/world_edit_generator/building_layout/proc/apply_building_microvariation_if_available(datum/world_edit_building_layout_state/state)
	if(!istype(state) || !hascall(src, "apply_building_microvariation"))
		return
	call(src, "apply_building_microvariation")(state)

/datum/world_edit_generator/building_layout/proc/build_building_anchor_type_counts(datum/world_edit_building_layout_state/state, prefix_filter = null)
	var/list/counts = list()
	if(!istype(state) || !islist(state.anchor_turfs))
		return counts
	var/filter = "[prefix_filter || ""]"
	for(var/anchor_id as anything in state.anchor_turfs)
		var/anchor_text = "[anchor_id]"
		if(length(filter) && copytext(anchor_text, 1, length(filter) + 1) != filter)
			continue
		var/list/turfs = state.anchor_turfs[anchor_id]
		counts[anchor_text] = islist(turfs) ? length(turfs) : 0
	return counts

/datum/world_edit_generator/building_layout/proc/count_building_anchor_turfs(datum/world_edit_building_layout_state/state, prefix_filter = null)
	var/total = 0
	var/list/counts = build_building_anchor_type_counts(state, prefix_filter)
	for(var/anchor_id as anything in counts)
		total += round(text2num("[counts[anchor_id]]") || 0)
	return total

/datum/world_edit_generator/building_layout/proc/validate_building_plan_post_emit(datum/world_edit_plan/plan, datum/world_edit_building_layout_state/state)
	var/list/report = list(
		"status" = "ok",
		"missing_path_count" = 0,
		"failed_object_count" = 0,
		"state_mismatch_count" = 0,
		"route_blocking_count" = 0,
		"semantic_credit_without_emitted_slots_count" = 0,
		"error_count" = 0,
	)
	if(!istype(plan) || !istype(state))
		report["status"] = "failed"
		report["error_count"] = 1
		return report

	var/wall_emit_count = 0
	var/door_emit_count = 0
	var/interior_emit_count = 0
	var/list/emitted_requirement_counts = list()
	for(var/list/placement as anything in plan.placements)
		if(!islist(placement))
			continue
		var/kind = "[placement["kind"]]"
		var/turf/target_turf = placement["turf"]
		switch(kind)
			if("floor", "wall")
				if(!istype(target_turf) || !ispath(placement["turf_path"], /turf))
					report["missing_path_count"] = round(text2num("[report["missing_path_count"]]") || 0) + 1
				if(kind == "wall")
					wall_emit_count++
			if("door", "window", "interior", "microvariation")
				if(!istype(target_turf) || !ispath(placement["obj_path"], /obj))
					report["missing_path_count"] = round(text2num("[report["missing_path_count"]]") || 0) + 1
				if(kind == "door")
					door_emit_count++
				if(kind == "interior")
					interior_emit_count++
					if(state.reserved_lookup[target_turf])
						report["route_blocking_count"] = round(text2num("[report["route_blocking_count"]]") || 0) + 1
					var/requirement_credit = round(text2num("[placement["requirement_count_credit"]]") || 0)
					var/requirement_id = "[placement["requirement_id"] || ""]"
					if(requirement_credit > 0 && length(requirement_id))
						emitted_requirement_counts[requirement_id] = round(text2num("[emitted_requirement_counts[requirement_id]]") || 0) + requirement_credit

	if(wall_emit_count != length(state.wall_lookup))
		report["state_mismatch_count"] = round(text2num("[report["state_mismatch_count"]]") || 0) + abs(wall_emit_count - length(state.wall_lookup))
	if(door_emit_count != length(state.door_turfs))
		report["state_mismatch_count"] = round(text2num("[report["state_mismatch_count"]]") || 0) + abs(door_emit_count - length(state.door_turfs))
	if(interior_emit_count != length(state.object_placements))
		report["state_mismatch_count"] = round(text2num("[report["state_mismatch_count"]]") || 0) + abs(interior_emit_count - length(state.object_placements))

	for(var/requirement_id as anything in state.semantic_requirement_counts)
		var/planned_count = round(text2num("[state.semantic_requirement_counts[requirement_id]]") || 0)
		var/emitted_count = round(text2num("[emitted_requirement_counts[requirement_id]]") || 0)
		if(planned_count > emitted_count)
			report["semantic_credit_without_emitted_slots_count"] = round(text2num("[report["semantic_credit_without_emitted_slots_count"]]") || 0) + (planned_count - emitted_count)

	var/error_count = round(text2num("[report["missing_path_count"]]") || 0) + round(text2num("[report["failed_object_count"]]") || 0) + round(text2num("[report["state_mismatch_count"]]") || 0) + round(text2num("[report["route_blocking_count"]]") || 0) + round(text2num("[report["semantic_credit_without_emitted_slots_count"]]") || 0)
	report["error_count"] = error_count
	if(error_count > 0)
		report["status"] = "failed"
		state.emit_missing_path_count = round(text2num("[report["missing_path_count"]]") || 0)
		state.emit_failed_object_count = round(text2num("[report["failed_object_count"]]") || 0)
		state.emit_state_mismatch_count = round(text2num("[report["state_mismatch_count"]]") || 0)
		state.post_emit_validation_error_count = error_count
		state.semantic_credit_without_emitted_slots_count = round(text2num("[report["semantic_credit_without_emitted_slots_count"]]") || 0)
		state.add_error("Post-emit validation failed for building layout: [error_count] emitted/reserved-state errors.")
	state.post_emit_validation_report = report
	return report

/datum/world_edit_generator/building_layout/proc/resolve_building_zone_floor_type(datum/world_edit_building_layout_state/state, turf/floor_turf)
	if(!istype(state) || !istype(floor_turf))
		return state?.config?["floor_type"]
	var/zone_id = state.get_zone(floor_turf)
	var/floor_path = null
	switch(state.archetype?.id)
		if("medbay")
			if(building_zone_matches_any_signature_token(state, zone_id, list("treatment", "triage", "med", "surgery")))
				floor_path = "/turf/open/floor/prison/sterile_white"
		if("hydroponics")
			if(building_zone_matches_any_signature_token(state, zone_id, list("grow", "hydro", "greenhouse")))
				floor_path = "/turf/open/floor/prison/greenblue"
			else if(building_zone_matches_any_signature_token(state, zone_id, list("seed", "work", "service")))
				floor_path = "/turf/open/floor/prison/green"
		if("kitchen")
			if(building_zone_matches_any_signature_token(state, zone_id, list("kitchen", "prep", "cooking", "serving", "cold")))
				floor_path = "/turf/open/floor/prison/kitchen"
			else if(building_zone_matches_any_signature_token(state, zone_id, list("dining")))
				floor_path = "/turf/open/floor/interior/wood/alt"
		if("dormitory")
			if(building_zone_matches_any_signature_token(state, zone_id, list("sleep", "locker")))
				floor_path = "/turf/open/floor/interior/wood/alt"
		if("office")
			if(building_zone_matches_any_signature_token(state, zone_id, list("desk", "filing", "visitor")))
				floor_path = "/turf/open/floor/prison/blue_plate"
		if("security", "checkpoint")
			if(building_zone_matches_any_signature_token(state, zone_id, list("secure", "holding", "locker")))
				floor_path = "/turf/open/floor/prison/cell_stripe"
			else if(building_zone_matches_any_signature_token(state, zone_id, list("public", "counter", "desk")))
				floor_path = "/turf/open/floor/prison/blue"
		if("workshop")
			if(building_zone_matches_any_signature_token(state, zone_id, list("work", "service", "parts")))
				floor_path = "/turf/open/floor/almayer/orange"
		if("storage")
			if(building_zone_matches_any_signature_token(state, zone_id, list("rack", "loading", "staging")))
				floor_path = "/turf/open/floor/almayer/cargo"
		if("engineering")
			if(building_zone_matches_any_signature_token(state, zone_id, list("machine", "power", "engineering")))
				floor_path = "/turf/open/floor/almayer/orange"
			else if(building_zone_matches_any_signature_token(state, zone_id, list("parts", "storage")))
				floor_path = "/turf/open/floor/almayer/cargo"
		if("laboratory")
			if(building_zone_matches_any_signature_token(state, zone_id, list("lab", "analysis", "clean")))
				floor_path = "/turf/open/floor/prison/sterile_white"
			else if(building_zone_matches_any_signature_token(state, zone_id, list("specimen", "containment")))
				floor_path = "/turf/open/floor/prison/blue_plate"
	if(!isnull(floor_path))
		var/resolved_floor = resolve_building_type_path(floor_path, /turf)
		if(resolved_floor)
			return resolved_floor
	return state.config["floor_type"]

/datum/world_edit_generator/building_layout/proc/emit_building_layout_plan(datum/world_edit_building_layout_state/state, datum/world_edit_shape_contract/shape_contract, list/placement_context)
	var/datum/world_edit_plan/plan = new
	if(!istype(state))
		plan.metadata["error"] = "Building layout state is unavailable."
		finalize_shared_placement_plan_metadata(plan, shape_contract, placement_context)
		return plan

	plan.metadata["archetype_id"] = state.archetype?.id
	plan.metadata["archetype_label"] = state.archetype?.label
	plan.metadata["faction_preset"] = state.config["faction_preset"]
	plan.metadata["footprint_family"] = state.config["footprint_family"]
	plan.metadata["placement_shape_id"] = state.config["placement_shape_id"]
	plan.metadata["footprint_source"] = state.config["footprint_source"]
	plan.metadata["placement_shape_used_as_seed_only"] = state.config["placement_shape_used_as_seed_only"] ? TRUE : FALSE
	plan.metadata["current_request_support_status"] = state.current_request_support_status
	plan.metadata["user_facing_failure_reason"] = state.user_facing_failure_reason
	plan.metadata["support_status_report"] = state.support_status_report.Copy()
	plan.metadata["stage_reports"] = state.stage_reports.Copy()
	plan.metadata["room_reports"] = state.room_reports.Copy()
	plan.metadata["zone_reports"] = state.zone_reports.Copy()
	plan.metadata["corridor_report"] = state.corridor_report.Copy()
	plan.metadata["wall_report"] = state.wall_report.Copy()
	plan.metadata["door_reports"] = state.door_reports.Copy()
	plan.metadata["pattern_reports"] = state.pattern_reports.Copy()
	plan.metadata["infrastructure_report"] = state.infrastructure_report.Copy()
	plan.metadata["fallback_audit"] = state.fallback_audit.Copy()
	plan.metadata["old_path_audit"] = state.old_path_audit.Copy()
	plan.metadata["root_seed"] = state.root_seed
	plan.metadata["stage_seed_footprint"] = state.stage_seed_footprint
	plan.metadata["stage_seed_rooms"] = state.stage_seed_rooms
	plan.metadata["stage_seed_corridor"] = state.stage_seed_corridor
	plan.metadata["stage_seed_patterns"] = state.stage_seed_patterns
	plan.metadata["stage_seed_details"] = state.stage_seed_details
	plan.metadata["footprint_hash"] = state.footprint_hash
	plan.metadata["room_graph_hash"] = state.room_graph_hash
	plan.metadata["route_hash"] = state.route_hash
	plan.metadata["wall_hash"] = state.wall_hash
	plan.metadata["pattern_credit_hash"] = state.pattern_credit_hash
	plan.metadata["layout_hash"] = state.layout_hash
	plan.metadata["determinism_check_hash"] = state.determinism_check_hash
	plan.metadata["building_placement_contract"] = list(
		"program_id" = state.archetype?.id,
		"shell_preset" = state.config["faction_preset"],
		"shape_id" = state.config["placement_shape_id"],
		"direction" = state.placement_dir,
		"footprint_source" = state.config["footprint_source"],
		"usable_area" = state.usable_fixture_area,
		"room_first_layout" = GLOB.world_edit_helpers.parse_bool(state.config["room_first_layout"]),
		"room_count" = length(state.solved_rooms),
		"corridor_turf_count" = length(state.corridor_turfs),
		"semantic_requirement_minimums" = state.semantic_requirement_minimums.Copy(),
		"semantic_requirement_counts" = state.semantic_requirement_counts.Copy(),
		"reservation_count" = length(state.semantic_slot_reservation_by_turf),
	)
	plan.metadata["layout_candidate_score"] = state.config["layout_candidate_score"] || state.layout_candidate_score
	plan.metadata["layout_candidate_count"] = state.config["layout_candidate_count"] || 1
	plan.metadata["layout_candidate_reports"] = islist(state.config["layout_candidate_reports"]) ? state.config["layout_candidate_reports"].Copy() : list()
	plan.metadata["layout_candidate_index"] = state.config["layout_candidate_index"] || 1
	plan.metadata["semantic_region_claim_count"] = state.region_claim_count
	plan.metadata["semantic_region_claim_reports"] = state.region_claim_reports.Copy()
	plan.metadata["rectangular_region_candidate_count"] = state.rectangular_region_candidate_count
	plan.metadata["nested_room_count"] = state.nested_room_count
	plan.metadata["template_chunk_count"] = state.template_chunk_count
	plan.metadata["template_chunk_cell_count"] = state.template_chunk_cell_count
	plan.metadata["infrastructure_count"] = state.infrastructure_count
	plan.metadata["semantic_slot_capacity_count"] = state.semantic_slot_capacity_count
	plan.metadata["semantic_slot_shortage_count"] = state.semantic_slot_shortage_count
	plan.metadata["semantic_slot_fallback_count"] = state.semantic_slot_fallback_count
	plan.metadata["semantic_slot_reports"] = state.semantic_slot_reports.Copy()
	plan.metadata["semantic_requirement_minimums"] = state.semantic_requirement_minimums.Copy()
	plan.metadata["semantic_requirement_counts"] = state.semantic_requirement_counts.Copy()
	plan.metadata["semantic_requirement_reports"] = state.semantic_requirement_reports.Copy()
	plan.metadata["semantic_slot_reservation_count"] = length(state.semantic_slot_reservation_by_turf)
	plan.metadata["semantic_slot_reservation_conflict_count"] = state.semantic_slot_reservation_conflict_count
	plan.metadata["mandatory_room_count"] = state.mandatory_room_count
	plan.metadata["mandatory_zone_count"] = state.mandatory_zone_count
	plan.metadata["mandatory_room_missing_count"] = state.mandatory_room_missing_count
	plan.metadata["mandatory_room_no_bounds_count"] = state.mandatory_room_no_bounds_count
	plan.metadata["mandatory_room_no_access_count"] = state.mandatory_room_no_access_count
	plan.metadata["mandatory_pattern_missing_count"] = state.mandatory_pattern_missing_count
	plan.metadata["mandatory_pattern_uncredited_count"] = state.mandatory_pattern_uncredited_count
	plan.metadata["mandatory_pattern_failure_count"] = state.mandatory_pattern_failure_count
	plan.metadata["reserved_walk_blocked_count"] = state.reserved_walk_blocked_count
	plan.metadata["door_cone_blocked_count"] = state.door_cone_blocked_count
	plan.metadata["mandatory_fixture_access_unreachable_count"] = state.mandatory_fixture_access_unreachable_count
	plan.metadata["double_wall_error_count"] = state.double_wall_error_count
	plan.metadata["diagonal_only_contact_count"] = state.diagonal_only_contact_count
	plan.metadata["cutout_violation_count"] = state.cutout_violation_count
	plan.metadata["unsupported_shape_silent_fallback_count"] = state.unsupported_shape_silent_fallback_count
	plan.metadata["style_required_slot_missing_count"] = state.style_required_slot_missing_count
	plan.metadata["raw_category_credit_count"] = state.raw_category_credit_count
	plan.metadata["scatter_signature_credit_count"] = state.scatter_signature_credit_count
	plan.metadata["semantic_credit_without_emitted_slots_count"] = state.semantic_credit_without_emitted_slots_count
	plan.metadata["forbidden_fallback_count"] = state.forbidden_fallback_count
	plan.metadata["mandatory_room_patch_fallback_count"] = state.mandatory_room_patch_fallback_count
	plan.metadata["fallback_anchor_required_cluster_count"] = state.fallback_anchor_required_cluster_count
	plan.metadata["blocked_turf_conflict_count"] = state.blocked_turf_conflict_count
	plan.metadata["blocked_route_conflict_count"] = state.blocked_route_conflict_count
	plan.metadata["blocked_room_conflict_count"] = state.blocked_room_conflict_count
	plan.metadata["blocked_wall_conflict_count"] = state.blocked_wall_conflict_count
	plan.metadata["blocked_fixture_conflict_count"] = state.blocked_fixture_conflict_count
	plan.metadata["replace_blocked_turf_count"] = state.replace_blocked_turf_count
	plan.metadata["requested_direction"] = state.requested_direction
	plan.metadata["requested_direction_label"] = GLOB.world_edit_helpers.dir_to_label(state.requested_direction)
	plan.metadata["actual_entry_direction"] = state.actual_entry_direction
	plan.metadata["actual_entry_direction_label"] = GLOB.world_edit_helpers.dir_to_label(state.actual_entry_direction)
	plan.metadata["direction_honored"] = state.actual_entry_direction == state.requested_direction
	plan.metadata["direction_honored_count"] = state.direction_honored_count
	plan.metadata["direction_fallback_count"] = state.direction_fallback_count
	plan.metadata["direction_fallback_reason"] = state.direction_fallback_reason
	plan.metadata["counter_wrong_facing_count"] = state.counter_wrong_facing_count
	plan.metadata["entry_face_mismatch_count"] = state.entry_face_mismatch_count
	plan.metadata["degraded_region_fallback_count"] = state.degraded_region_fallback_count
	plan.metadata["degraded_region_reports"] = state.degraded_region_reports.Copy()
	plan.metadata["microvariation_count"] = state.microvariation_count
	plan.metadata["footprint_mask_score"] = state.config["footprint_mask_score"]
	plan.metadata["footprint_mask_candidate_count"] = state.config["footprint_mask_candidate_count"]
	plan.metadata["effective_seed"] = state.config["effective_seed"]
	plan.metadata["building_seed"] = state.config["building_seed"]
	plan.metadata["detail_budget"] = state.config["detail_budget"]
	plan.metadata["window_density"] = state.config["window_density"]
	plan.metadata["generator_effect_turfs"] = state.footprint.Copy()
	plan.metadata["warnings"] = state.warnings.Copy()
	plan.metadata["signature_counts"] = state.signature_counts.Copy()
	plan.metadata["signature_score"] = state.signature_score
	plan.metadata["signature_max_score"] = state.signature_max_score
	plan.metadata["style_score"] = state.style_score
	plan.metadata["category_coverage_score"] = state.category_coverage_score
	plan.metadata["repeat_index"] = state.repeat_index
	plan.metadata["privacy_violation_count"] = state.privacy_violation_count
	plan.metadata["reachability_failure_count"] = state.reachability_failure_count
	plan.metadata["repetition_conflict_count"] = state.repetition_conflict_count
	plan.metadata["fixture_density_score"] = state.fixture_density_score
	plan.metadata["connectivity_score"] = state.connectivity_score
	plan.metadata["visibility_privacy_score"] = state.visibility_privacy_score
	plan.metadata["space_distribution_score"] = state.space_distribution_score
	plan.metadata["door_buffer_conflict_count"] = state.door_buffer_conflict_count
	plan.metadata["window_conflict_count"] = state.window_conflict_count
	plan.metadata["facade_conflict_count"] = state.facade_conflict_count
	plan.metadata["fixture_conflict_count"] = state.fixture_conflict_count
	plan.metadata["route_conflict_count"] = state.route_conflict_count
	plan.metadata["signature_warnings"] = state.signature_warnings.Copy()
	plan.metadata["empty_floor_ratio"] = state.empty_floor_ratio
	plan.metadata["program_signature_ok"] = state.signature_max_score <= 0 || state.signature_score >= state.semantic_plan?.min_signature_score

	if(state.has_errors())
		plan.metadata["error"] = format_building_messages(state.errors)
		plan.metadata["errors"] = state.errors.Copy()
		finalize_shared_placement_plan_metadata(plan, shape_contract, placement_context)
		return plan

	for(var/turf/footprint_turf as anything in state.footprint)
		if(!istype(footprint_turf))
			continue
		var/list/turf_placement
		if(state.wall_lookup[footprint_turf])
			turf_placement = build_turf_placement("wall", footprint_turf, state.config["wall_type"])
			var/wall_macro_id = get_building_layout_macro_id_for_turf(state, "facade", footprint_turf)
			if(length(wall_macro_id))
				turf_placement["layout_macro"] = wall_macro_id
				turf_placement["template_overlay"] = TRUE
				turf_placement["dmm_chunk"] = wall_macro_id
		else
			turf_placement = build_turf_placement("floor", footprint_turf, resolve_building_zone_floor_type(state, footprint_turf))
		plan.placements += list(turf_placement)
		plan.affected_turfs += footprint_turf

	for(var/turf/door_turf as anything in state.door_turfs)
		if(!istype(door_turf))
			continue
		var/door_dir = state.door_dirs[door_turf] || state.placement_dir
		var/list/door_placement = build_object_placement("door", door_turf, state.config["door_type"], door_dir)
		var/door_macro_id = get_building_layout_macro_id_for_turf(state, "door", door_turf)
		if(length(door_macro_id))
			door_placement["layout_macro"] = door_macro_id
			door_placement["template_overlay"] = TRUE
			door_placement["dmm_chunk"] = door_macro_id
		plan.placements += list(door_placement)

	for(var/turf/window_turf as anything in state.window_turfs)
		if(!istype(window_turf))
			continue
		var/window_dir = get_outward_dir(window_turf, state.footprint_lookup, (state.bounds["min_x"] + state.bounds["max_x"]) / 2, (state.bounds["min_y"] + state.bounds["max_y"]) / 2, state.placement_dir)
		var/list/window_placement = build_object_placement("window", window_turf, state.config["window_type"], window_dir)
		var/window_macro_id = get_building_layout_macro_id_for_turf(state, "window", window_turf)
		if(length(window_macro_id))
			window_placement["layout_macro"] = window_macro_id
			window_placement["template_overlay"] = TRUE
			window_placement["dmm_chunk"] = window_macro_id
		plan.placements += list(window_placement)

	for(var/list/object_placement as anything in state.object_placements)
		if(islist(object_placement))
			plan.placements += list(object_placement)

	plan.metadata["center_turf"] = state.center_turf
	plan.metadata["entry_count"] = length(plan.placements)
	plan.metadata["footprint_count"] = length(state.footprint)
	plan.metadata["boundary_count"] = length(state.boundary)
	plan.metadata["wall_count"] = length(state.wall_lookup)
	plan.metadata["floor_count"] = length(state.floor_turfs)
	plan.metadata["door_count"] = length(state.door_turfs)
	plan.metadata["window_count"] = length(state.window_turfs)
	plan.metadata["interior_object_count"] = length(state.object_placements)
	plan.metadata["major_fixture_count"] = state.major_fixture_count
	plan.metadata["fixture_count"] = state.fixture_count
	plan.metadata["fixture_category_counts"] = state.category_counts.Copy()
	plan.metadata["cluster_counts"] = state.cluster_counts.Copy()
	plan.metadata["signature_counts"] = state.signature_counts.Copy()
	plan.metadata["style_score"] = state.style_score
	plan.metadata["category_coverage_score"] = state.category_coverage_score
	plan.metadata["repeat_index"] = state.repeat_index
	plan.metadata["privacy_violation_count"] = state.privacy_violation_count
	plan.metadata["reachability_failure_count"] = state.reachability_failure_count
	plan.metadata["repetition_conflict_count"] = state.repetition_conflict_count
	plan.metadata["fixture_density_score"] = state.fixture_density_score
	plan.metadata["connectivity_score"] = state.connectivity_score
	plan.metadata["visibility_privacy_score"] = state.visibility_privacy_score
	plan.metadata["space_distribution_score"] = state.space_distribution_score
	plan.metadata["door_buffer_conflict_count"] = state.door_buffer_conflict_count
	plan.metadata["window_conflict_count"] = state.window_conflict_count
	plan.metadata["facade_conflict_count"] = state.facade_conflict_count
	plan.metadata["fixture_conflict_count"] = state.fixture_conflict_count
	plan.metadata["route_conflict_count"] = state.route_conflict_count
	plan.metadata["fixture_category_budgets"] = state.category_budgets.Copy()
	plan.metadata["zone_count"] = length(state.zone_turfs)
	plan.metadata["anchor_count"] = length(state.anchor_turfs)
	plan.metadata["anchor_type_counts"] = build_building_anchor_type_counts(state)
	plan.metadata["microvariation_anchor_counts"] = build_building_anchor_type_counts(state, "microvariation_")
	plan.metadata["microvariation_anchor_count"] = count_building_anchor_turfs(state, "microvariation_")
	plan.metadata["microvariation_count"] = state.microvariation_count
	plan.metadata["template_chunk_count"] = state.template_chunk_count
	plan.metadata["template_chunk_cell_count"] = state.template_chunk_cell_count
	plan.metadata["infrastructure_count"] = state.infrastructure_count
	plan.metadata["degraded_region_fallback_count"] = state.degraded_region_fallback_count
	plan.metadata["degraded_region_reports"] = state.degraded_region_reports.Copy()
	plan.metadata["layout_macros"] = state.layout_macros.Copy()
	plan.metadata["layout_macro_counts"] = state.layout_macro_counts.Copy()
	plan.metadata["layout_macro_count"] = length(state.layout_macros)
	plan.metadata["semantic_region_count"] = length(state.solved_regions)
	plan.metadata["room_first_layout"] = GLOB.world_edit_helpers.parse_bool(state.config["room_first_layout"])
	plan.metadata["room_count"] = length(state.solved_rooms)
	plan.metadata["corridor_turf_count"] = length(state.corridor_turfs)
	plan.metadata["primary_route_count"] = length(state.primary_route_turfs)
	plan.metadata["internal_wall_count"] = length(state.internal_wall_turfs)
	plan.metadata["divider_plan_count"] = length(state.divider_plans)
	plan.metadata["usable_fixture_area"] = state.usable_fixture_area
	plan.metadata["patterned_layout"] = TRUE
	plan.metadata["layout_contract"] = "room_first_corridor_pattern_rework"
	var/list/post_emit_report = validate_building_plan_post_emit(plan, state)
	plan.metadata["post_emit_validation_report"] = post_emit_report
	plan.metadata["post_emit_validation_error_count"] = state.post_emit_validation_error_count
	plan.metadata["emit_missing_path_count"] = state.emit_missing_path_count
	plan.metadata["emit_failed_object_count"] = state.emit_failed_object_count
	plan.metadata["emit_state_mismatch_count"] = state.emit_state_mismatch_count
	plan.metadata["semantic_credit_without_emitted_slots_count"] = state.semantic_credit_without_emitted_slots_count
	if(state.has_errors())
		plan.metadata["error"] = format_building_messages(state.errors)
		plan.metadata["errors"] = state.errors.Copy()
	finalize_shared_placement_plan_metadata(plan, shape_contract, placement_context)
	return plan
