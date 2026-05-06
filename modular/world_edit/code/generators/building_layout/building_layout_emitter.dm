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

/datum/world_edit_generator/building_layout/proc/emit_building_layout_plan(datum/world_edit_building_layout_state/state, datum/world_edit_shape_contract/shape_contract, list/placement_context)
	var/datum/world_edit_plan/plan = new
	if(!istype(state))
		plan.metadata["error"] = "Building layout state is unavailable."
		finalize_shared_placement_plan_metadata(plan, shape_contract, placement_context)
		return plan

	plan.metadata["archetype_id"] = state.archetype?.id
	plan.metadata["archetype_label"] = state.archetype?.label
	plan.metadata["faction_preset"] = state.config["faction_preset"]
	plan.metadata["effective_seed"] = state.config["effective_seed"]
	plan.metadata["building_seed"] = state.config["building_seed"]
	plan.metadata["detail_budget"] = state.config["detail_budget"]
	plan.metadata["window_density"] = state.config["window_density"]
	plan.metadata["generator_effect_turfs"] = state.footprint.Copy()
	plan.metadata["warnings"] = state.warnings.Copy()

	if(state.has_errors())
		plan.metadata["error"] = format_building_messages(state.errors)
		plan.metadata["errors"] = state.errors.Copy()
		finalize_shared_placement_plan_metadata(plan, shape_contract, placement_context)
		return plan

	for(var/turf/footprint_turf as anything in state.footprint)
		if(!istype(footprint_turf))
			continue
		if(state.wall_lookup[footprint_turf])
			plan.placements += list(build_turf_placement("wall", footprint_turf, state.config["wall_type"]))
		else
			plan.placements += list(build_turf_placement("floor", footprint_turf, state.config["floor_type"]))
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
	plan.metadata["zone_count"] = length(state.zone_turfs)
	plan.metadata["anchor_count"] = length(state.anchor_turfs)
	plan.metadata["patterned_layout"] = TRUE
	plan.metadata["layout_contract"] = "phased_replacement"
	finalize_shared_placement_plan_metadata(plan, shape_contract, placement_context)
	return plan
