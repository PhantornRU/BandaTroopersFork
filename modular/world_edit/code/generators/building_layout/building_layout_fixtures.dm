/datum/world_edit_generator/building_layout/proc/place_building_fixtures(datum/world_edit_building_layout_state/state)
	if(!istype(state) || state.has_errors())
		return
	for(var/cluster_id as anything in state.archetype.major_clusters)
		place_building_cluster(state, "[cluster_id]", TRUE)
	var/detail_budget = clamp(round(text2num("[state.config["detail_budget"]]")), 0, 100)
	if(detail_budget <= 0)
		return
	var/secondary_limit = min(length(state.archetype.secondary_clusters), round(length(state.archetype.secondary_clusters) * detail_budget / 100))
	if(secondary_limit <= 0)
		secondary_limit = 1
	var/placed_secondary = 0
	for(var/cluster_id as anything in state.archetype.secondary_clusters)
		if(placed_secondary >= secondary_limit)
			break
		if(!state.request.fixture_rng.chance(detail_budget))
			continue
		if(place_building_cluster(state, "[cluster_id]", FALSE))
			placed_secondary++

/datum/world_edit_generator/building_layout/proc/place_building_cluster(datum/world_edit_building_layout_state/state, cluster_id, major)
	if(state.fixture_count >= WORLD_EDIT_BUILDING_MAX_FIXTURE_OBJECTS)
		return FALSE
	switch("[cluster_id]")
		if("bed_niche")
			return place_wall_fixture(state, "bed", list("sleep_privacy", "privacy_zone", "wall_anchor"), major)
		if("dining_pair")
			return place_table_cluster(state, list("common", "focus_center"), major, 2)
		if("personal_storage")
			return place_wall_fixture(state, "cabinet", list("storage_service", "privacy_zone", "wall_anchor"), major)
		if("window_seat")
			return place_fixture_object(state, "chair", list("window_band", "common"), FALSE, major)
		if("workbench_run")
			return place_fixture_run(state, "table", list("service_strip", "work_cluster", "wall_anchor"), 3, major)
		if("parts_rack_run")
			return place_fixture_run(state, "rack", list("parts_storage", "service_strip", "wall_anchor"), 4, major)
		if("operator_console")
			return place_wall_fixture(state, "console", list("observation", "counter_back", "service_strip", "wall_anchor"), major)
		if("tool_storage")
			return place_wall_fixture(state, "cabinet", list("service_strip", "wall_anchor"), major)
		if("storage_loading_axis")
			return place_fixture_object(state, "crate", list("staging", "rack_zone"), FALSE, major)
		if("rack_run")
			return place_fixture_run(state, "rack", list("rack_zone", "wall_anchor"), 5, major)
		if("crate_stack")
			return place_fixture_run(state, "crate", list("staging", "rack_zone"), 3, major)
		if("inspection_table")
			return place_fixture_object(state, "table", list("staging", "loading_axis"), FALSE, major)
		if("checkpoint_counter")
			return place_fixture_run(state, "table", list("counter_line", "counter_front"), 3, major)
		if("security_storage")
			return place_wall_fixture(state, "cabinet", list("secure_side", "observation", "wall_anchor"), major)
		if("visitor_chair")
			return place_fixture_object(state, "chair", list("public_side"), FALSE, major)
		if("barricade_line")
			return place_fixture_run(state, "barrier", list("entry_buffer", "public_side"), 2, major)
		if("triage_bed_cluster")
			return place_fixture_run(state, "medical_bed", list("treatment", "triage"), 2, major)
		if("med_storage_wall")
			return place_fixture_run(state, "medical_storage", list("med_storage", "service_strip", "wall_anchor"), 3, major)
		if("treatment_table")
			return place_fixture_object(state, "table", list("treatment"), FALSE, major)
		if("waiting_chair")
			return place_fixture_object(state, "chair", list("triage", "entry_buffer"), FALSE, major)
	return FALSE

/datum/world_edit_generator/building_layout/proc/place_table_cluster(datum/world_edit_building_layout_state/state, list/anchors, major, chair_target = 2)
	var/turf/table_turf = select_fixture_turf(state, anchors, FALSE)
	if(!istype(table_turf))
		return FALSE
	place_fixture_at(state, table_turf, "table", get_cardinal_dir_toward(table_turf, state.center_turf, SOUTH), "table", major, FALSE)
	var/placed_chairs = 0
	for(var/check_dir in GLOB.cardinals)
		if(placed_chairs >= chair_target)
			break
		var/turf/chair_turf = get_step(table_turf, check_dir)
		if(!state.can_place_fixture(chair_turf))
			continue
		place_fixture_at(state, chair_turf, "chair", get_cardinal_dir_toward(chair_turf, table_turf, SOUTH), "chair", FALSE, FALSE)
		placed_chairs++
	return TRUE

/datum/world_edit_generator/building_layout/proc/place_fixture_run(datum/world_edit_building_layout_state/state, slot, list/anchors, target_count, major)
	var/placed = 0
	var/steps = 0
	while(placed < target_count && steps < WORLD_EDIT_BUILDING_MAX_CLUSTER_STEPS && state.fixture_count < WORLD_EDIT_BUILDING_MAX_FIXTURE_OBJECTS)
		steps++
		var/turf/target_turf = select_fixture_turf(state, anchors, slot in list("rack", "cabinet", "medical_storage"))
		if(!istype(target_turf))
			break
		var/list/wall_dirs = get_adjacent_wall_dirs_for_state(state, target_turf)
		var/dir_to_use = length(wall_dirs) ? turn(wall_dirs[1], 180) : get_cardinal_dir_toward(target_turf, state.center_turf, SOUTH)
		if(place_fixture_at(state, target_turf, slot, dir_to_use, slot, major && placed <= 0, length(wall_dirs)))
			placed++
		else
			break
	return placed > 0

/datum/world_edit_generator/building_layout/proc/place_wall_fixture(datum/world_edit_building_layout_state/state, slot, list/anchors, major)
	var/turf/target_turf = select_fixture_turf(state, anchors, TRUE)
	if(!istype(target_turf))
		return FALSE
	var/list/wall_dirs = get_adjacent_wall_dirs_for_state(state, target_turf)
	var/wall_dir = length(wall_dirs) ? wall_dirs[1] : NORTH
	return place_fixture_at(state, target_turf, slot, turn(wall_dir, 180), slot, major, TRUE)

/datum/world_edit_generator/building_layout/proc/place_fixture_object(datum/world_edit_building_layout_state/state, slot, list/anchors, needs_wall = FALSE, major = FALSE)
	var/turf/target_turf = select_fixture_turf(state, anchors, needs_wall)
	if(!istype(target_turf))
		return FALSE
	var/list/wall_dirs = get_adjacent_wall_dirs_for_state(state, target_turf)
	var/dir_to_use = length(wall_dirs) ? turn(wall_dirs[1], 180) : get_cardinal_dir_toward(target_turf, state.center_turf, SOUTH)
	return place_fixture_at(state, target_turf, slot, dir_to_use, slot, major, needs_wall)

/datum/world_edit_generator/building_layout/proc/select_fixture_turf(datum/world_edit_building_layout_state/state, list/anchor_ids, needs_wall = FALSE)
	var/list/best_turfs = list()
	var/best_score = -999999999
	for(var/turf/floor_turf as anything in state.floor_turfs)
		if(!state.can_place_fixture(floor_turf))
			continue
		if(needs_wall && !length(get_adjacent_wall_dirs_for_state(state, floor_turf)))
			continue
		var/score = score_fixture_turf(state, floor_turf, anchor_ids, needs_wall)
		if(score > best_score)
			best_score = score
			best_turfs.Cut()
			best_turfs += floor_turf
		else if(score == best_score)
			best_turfs += floor_turf
	if(!length(best_turfs))
		return null
	return state.request.fixture_rng.pick_from(best_turfs)

/datum/world_edit_generator/building_layout/proc/score_fixture_turf(datum/world_edit_building_layout_state/state, turf/target_turf, list/anchor_ids, needs_wall = FALSE)
	var/score = 0
	var/zone_id = state.get_zone(target_turf)
	for(var/anchor_id as anything in anchor_ids)
		if(state.has_anchor(anchor_id, target_turf) || zone_id == "[anchor_id]")
			score += 100
	if(needs_wall)
		score += length(get_adjacent_wall_dirs_for_state(state, target_turf)) * 30
	if(state.has_anchor("door_cone", target_turf))
		score -= 500
	if(state.reserved_lookup[target_turf])
		score -= 200
	if(istype(state.center_turf))
		score -= abs(target_turf.x - state.center_turf.x) + abs(target_turf.y - state.center_turf.y)
	return score

/datum/world_edit_generator/building_layout/proc/place_fixture_at(datum/world_edit_building_layout_state/state, turf/target_turf, slot, dir_to_use, category, major = FALSE, wall_mounted = FALSE)
	if(!state.can_place_fixture(target_turf))
		return FALSE
	if(state.fixture_count >= WORLD_EDIT_BUILDING_MAX_FIXTURE_OBJECTS)
		return FALSE
	var/budget = state.archetype.object_budgets["[category]"]
	if(isnum(budget) && budget > 0 && (state.category_counts["[category]"] || 0) >= budget)
		return FALSE
	var/obj_path = resolve_interior_obj_path(state.config, slot)
	if(!obj_path)
		state.add_warning("Unable to resolve fixture object '[slot]' for archetype [state.archetype.id].")
		return FALSE
	state.object_placements += list(build_object_placement("interior", target_turf, obj_path, dir_to_use))
	state.register_fixture(target_turf, category, major, wall_mounted)
	return TRUE
