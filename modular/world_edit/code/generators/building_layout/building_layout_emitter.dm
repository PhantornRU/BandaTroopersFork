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
	plan.metadata["placement_shape_used_as_seed_only"] = state.config["placement_shape_used_as_seed_only"] ? TRUE : FALSE
	plan.metadata["layout_candidate_score"] = state.config["layout_candidate_score"] || state.layout_candidate_score
	plan.metadata["layout_candidate_count"] = state.config["layout_candidate_count"] || 1
	plan.metadata["layout_candidate_reports"] = islist(state.config["layout_candidate_reports"]) ? state.config["layout_candidate_reports"].Copy() : list()
	plan.metadata["layout_candidate_index"] = state.config["layout_candidate_index"] || 1
	plan.metadata["semantic_region_claim_count"] = state.region_claim_count
	plan.metadata["semantic_region_claim_reports"] = state.region_claim_reports.Copy()
	plan.metadata["rectangular_region_candidate_count"] = state.rectangular_region_candidate_count
	plan.metadata["nested_room_count"] = state.nested_room_count
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
	plan.metadata["signature_warnings"] = state.signature_warnings.Copy()
	plan.metadata["empty_floor_ratio"] = state.empty_floor_ratio
	plan.metadata["program_signature_ok"] = state.signature_max_score <= 0 || state.signature_score >= state.semantic_plan?.min_signature_score

	if(state.has_errors())
		plan.metadata["error"] = format_building_messages(state.errors)
		plan.metadata["errors"] = state.errors.Copy()
		finalize_shared_placement_plan_metadata(plan, shape_contract, placement_context)
		return plan

	apply_building_microvariation_if_available(state)

	for(var/turf/footprint_turf as anything in state.footprint)
		if(!istype(footprint_turf))
			continue
		if(state.wall_lookup[footprint_turf])
			plan.placements += list(build_turf_placement("wall", footprint_turf, state.config["wall_type"]))
		else
			plan.placements += list(build_turf_placement("floor", footprint_turf, resolve_building_zone_floor_type(state, footprint_turf)))
		plan.affected_turfs += footprint_turf

	for(var/turf/door_turf as anything in state.door_turfs)
		if(!istype(door_turf))
			continue
		var/door_dir = state.door_dirs[door_turf] || state.placement_dir
		plan.placements += list(build_object_placement("door", door_turf, state.config["door_type"], door_dir))

	for(var/turf/window_turf as anything in state.window_turfs)
		if(!istype(window_turf))
			continue
		var/window_dir = get_outward_dir(window_turf, state.footprint_lookup, (state.bounds["min_x"] + state.bounds["max_x"]) / 2, (state.bounds["min_y"] + state.bounds["max_y"]) / 2, state.placement_dir)
		plan.placements += list(build_object_placement("window", window_turf, state.config["window_type"], window_dir))

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
	plan.metadata["fixture_category_budgets"] = state.category_budgets.Copy()
	plan.metadata["zone_count"] = length(state.zone_turfs)
	plan.metadata["anchor_count"] = length(state.anchor_turfs)
	plan.metadata["anchor_type_counts"] = build_building_anchor_type_counts(state)
	plan.metadata["microvariation_anchor_counts"] = build_building_anchor_type_counts(state, "microvariation_")
	plan.metadata["microvariation_anchor_count"] = count_building_anchor_turfs(state, "microvariation_")
	plan.metadata["microvariation_count"] = state.microvariation_count
	plan.metadata["semantic_region_count"] = length(state.solved_regions)
	plan.metadata["primary_route_count"] = length(state.primary_route_turfs)
	plan.metadata["internal_wall_count"] = length(state.internal_wall_turfs)
	plan.metadata["divider_plan_count"] = length(state.divider_plans)
	plan.metadata["usable_fixture_area"] = state.usable_fixture_area
	plan.metadata["patterned_layout"] = TRUE
	plan.metadata["layout_contract"] = "semantic_region_cluster_rework"
	finalize_shared_placement_plan_metadata(plan, shape_contract, placement_context)
	return plan
