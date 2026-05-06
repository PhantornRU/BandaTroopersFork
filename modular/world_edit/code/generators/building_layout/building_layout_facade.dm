/datum/world_edit_generator/building_layout/proc/build_building_windows(datum/world_edit_building_layout_state/state)
	var/window_density = clamp(round(text2num("[state.config["window_density"]]")), 0, 100)
	if(window_density <= 0)
		return
	window_density = round((window_density + state.archetype.window_bias) / 2)
	var/list/door_lookup = GLOB.world_edit_placement_shapes.world_edit_build_turf_lookup(state.door_turfs)
	var/list/candidates = list()
	var/list/candidate_lookup = list()
	var/list/weighted_candidates = list()
	for(var/turf/boundary_turf as anything in state.boundary)
		if(door_lookup[boundary_turf])
			continue
		if(is_corner_boundary_turf(boundary_turf, state.footprint_lookup))
			continue
		if(!can_place_building_window_for_boundary_turf(state, boundary_turf))
			continue
		append_unique_turf(candidates, candidate_lookup, boundary_turf)
		var/weight = clamp(round(get_building_window_role_weight(state, boundary_turf) / 50), 1, 4)
		for(var/repeat_index in 1 to weight)
			weighted_candidates += boundary_turf

	if(!length(candidates) || window_density <= 0)
		return

	var/target_count = min(WORLD_EDIT_BUILDING_MAX_WINDOWS, max(1, round(length(candidates) * window_density / 250)))
	var/list/source_candidates = length(weighted_candidates) ? weighted_candidates : candidates
	var/stride = max(round(length(source_candidates) / max(target_count, 1)), 1)
	var/index = state.request.facade_rng.next_between(1, min(stride, length(source_candidates)))
	var/list/window_lookup = list()
	for(var/turf/existing_window as anything in state.window_turfs)
		window_lookup[existing_window] = TRUE
	while(length(state.window_turfs) < target_count && index <= length(source_candidates))
		var/turf/window_turf = source_candidates[index]
		if(!window_lookup[window_turf])
			state.append_unique_turf(state.window_turfs, window_turf)
			window_lookup[window_turf] = TRUE
		index += stride

/datum/world_edit_generator/building_layout/proc/get_building_window_interior_turf(datum/world_edit_building_layout_state/state, turf/boundary_turf)
	if(!istype(state) || !istype(boundary_turf) || !state.boundary_lookup[boundary_turf])
		return null
	for(var/check_dir in GLOB.cardinals)
		var/turf/nearby_turf = get_step(boundary_turf, check_dir)
		if(state.footprint_lookup[nearby_turf] && !state.boundary_lookup[nearby_turf] && !state.wall_lookup[nearby_turf])
			return nearby_turf
	return null

/datum/world_edit_generator/building_layout/proc/can_place_building_window_for_boundary_turf(datum/world_edit_building_layout_state/state, turf/boundary_turf)
	var/turf/interior_turf = get_building_window_interior_turf(state, boundary_turf)
	if(!istype(interior_turf))
		return FALSE
	var/datum/world_edit_building_zone_spec/zone_spec = state.semantic_plan?.get_zone_spec(state.get_zone(interior_turf))
	if(!istype(zone_spec))
		return FALSE
	if(zone_spec.privacy_sensitive || !zone_spec.window_allowed)
		return FALSE
	return TRUE

/datum/world_edit_generator/building_layout/proc/get_building_window_role_weight(datum/world_edit_building_layout_state/state, turf/boundary_turf)
	var/turf/interior_turf = get_building_window_interior_turf(state, boundary_turf)
	var/zone_id = state.get_zone(interior_turf)
	if(!length(zone_id))
		return 50
	if(building_zone_matches_any_signature_token(state, zone_id, list("grow", "hydro", "greenhouse")))
		return 180
	if(building_zone_matches_any_signature_token(state, zone_id, list("public", "entry", "triage", "dining", "office", "visitor")))
		return 120
	if(building_zone_matches_any_signature_token(state, zone_id, list("treatment", "med")))
		return 70
	if(building_zone_matches_any_signature_token(state, zone_id, list("secure", "storage", "locker", "holding", "cold", "service", "machine")))
		return 25
	return 50

/datum/world_edit_generator/building_layout/proc/get_building_facade_role_for_boundary_turf(datum/world_edit_building_layout_state/state, turf/boundary_turf)
	var/turf/interior_turf = get_building_window_interior_turf(state, boundary_turf)
	if(!istype(interior_turf))
		for(var/check_dir in GLOB.cardinals)
			var/turf/nearby_turf = get_step(boundary_turf, check_dir)
			if(state.footprint_lookup[nearby_turf] && !state.wall_lookup[nearby_turf])
				interior_turf = nearby_turf
				break
	var/zone_id = state.get_zone(interior_turf)
	if(building_zone_matches_any_signature_token(state, zone_id, list("entry", "public", "triage", "dining", "visitor")))
		return "public_face"
	if(building_zone_matches_any_signature_token(state, zone_id, list("grow", "hydro", "greenhouse")))
		return "greenhouse_face"
	if(building_zone_matches_any_signature_token(state, zone_id, list("secure", "holding", "locker")))
		return "secure_face"
	if(building_zone_matches_any_signature_token(state, zone_id, list("service", "storage", "machine", "cold", "work")))
		return "service_face"
	if(building_zone_matches_any_signature_token(state, zone_id, list("med", "treatment")))
		return "medical_face"
	return "neutral_face"

/datum/world_edit_generator/building_layout/proc/apply_building_facade_rules(datum/world_edit_building_layout_state/state)
	if(!istype(state))
		return
	for(var/turf/boundary_turf as anything in state.boundary)
		if(state.wall_lookup[boundary_turf])
			state.add_anchor("facade_segment", boundary_turf)
			state.add_anchor("facade_[get_building_facade_role_for_boundary_turf(state, boundary_turf)]", boundary_turf)
