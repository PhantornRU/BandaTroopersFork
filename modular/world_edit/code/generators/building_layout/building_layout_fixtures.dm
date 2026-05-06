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
			return place_table_cluster(state, list("common", "focus_ring", "focus_center"), major, 2)
		if("personal_storage")
			return place_fixture_run(state, "cabinet", list("storage_service", "privacy_zone", "wall_anchor"), 2, major, TRUE)
		if("side_table")
			return place_table_cluster(state, list("common", "window_band", "focus_ring"), major, 1)
		if("window_seat")
			return place_fixture_object(state, "chair", list("window_band", "common"), FALSE, major)
		if("workbench_run")
			return place_fixture_run(state, "table", list("service_strip", "work_cluster", "wall_anchor"), 3, major, TRUE)
		if("parts_rack_run")
			return place_fixture_run(state, "rack", list("parts_storage", "service_strip", "wall_anchor"), 4, major, TRUE)
		if("central_assembly_table")
			return place_table_cluster(state, list("main_work", "work_cluster", "focus_ring"), major, 2)
		if("operator_console")
			return place_wall_fixture(state, "console", list("observation", "counter_back", "service_strip", "wall_anchor"), major)
		if("tool_storage")
			return place_fixture_run(state, "cabinet", list("service_strip", "wall_anchor"), 2, major, TRUE)
		if("parts_crate_stack")
			return place_fixture_run(state, "crate", list("parts_storage", "main_work", "work_cluster"), 2, major, FALSE)
		if("inspection_chair")
			return place_fixture_object(state, "chair", list("main_work", "work_cluster"), FALSE, major)
		if("storage_loading_axis")
			return place_fixture_object(state, "crate", list("staging", "rack_zone"), FALSE, major)
		if("rack_run")
			return place_fixture_run(state, "rack", list("rack_zone", "wall_anchor"), 4, major, TRUE)
		if("crate_stack")
			return place_fixture_run(state, "crate", list("staging", "rack_zone"), 3, major, FALSE)
		if("inspection_table")
			return place_fixture_object(state, "table", list("staging", "loading_axis"), FALSE, major)
		if("staging_crate_pair")
			return place_fixture_run(state, "crate", list("staging", "loading_axis"), 2, major, FALSE)
		if("checkpoint_counter")
			return place_fixture_run(state, "table", list("counter_line", "counter_front"), 3, major, FALSE)
		if("security_storage")
			return place_wall_fixture(state, "cabinet", list("secure_side", "observation", "wall_anchor"), major)
		if("visitor_chair")
			return place_fixture_object(state, "chair", list("public_side"), FALSE, major)
		if("barricade_line")
			return place_fixture_run(state, "barrier", list("entry_buffer", "public_side"), 2, major)
		if("triage_bed_cluster")
			return place_fixture_run(state, "medical_bed", list("treatment", "triage"), 2, major, FALSE)
		if("med_storage_wall")
			return place_fixture_run(state, "medical_storage", list("med_storage", "service_strip", "wall_anchor"), 3, major, TRUE)
		if("treatment_table")
			return place_fixture_object(state, "table", list("treatment"), FALSE, major)
		if("waiting_chair")
			return place_fixture_object(state, "chair", list("triage", "entry_buffer"), FALSE, major)
		if("triage_seating")
			return place_fixture_run(state, "chair", list("triage", "entry_buffer", "window_band"), 2, major, FALSE)
		if("med_side_storage")
			return place_wall_fixture(state, "cabinet", list("med_storage", "service_strip", "wall_anchor"), major)
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

/datum/world_edit_generator/building_layout/proc/place_fixture_run(datum/world_edit_building_layout_state/state, slot, list/anchors, target_count, major, needs_wall = null)
	var/wall_run = isnull(needs_wall) ? (slot in list("rack", "cabinet", "medical_storage")) : needs_wall
	var/placed = 0
	var/attempts = 0
	while(placed < target_count && attempts < WORLD_EDIT_BUILDING_MAX_CLUSTER_STEPS && state.fixture_count < WORLD_EDIT_BUILDING_MAX_FIXTURE_OBJECTS)
		attempts++
		var/turf/start_turf = select_fixture_turf(state, anchors, wall_run)
		if(!istype(start_turf))
			break
		var/list/wall_dirs = get_adjacent_wall_dirs_for_state(state, start_turf)
		var/wall_dir = length(wall_dirs) ? wall_dirs[1] : null
		var/dir_to_use = wall_dir ? turn(wall_dir, 180) : get_cardinal_dir_toward(start_turf, state.center_turf, SOUTH)
		if(!place_fixture_at(state, start_turf, slot, dir_to_use, slot, major && placed <= 0, wall_run))
			break
		placed++
		var/list/run_dirs = get_fixture_run_dirs(state, wall_dir)
		for(var/run_dir as anything in run_dirs)
			if(placed >= target_count)
				break
			placed = extend_fixture_run(state, start_turf, run_dir, slot, dir_to_use, placed, target_count, wall_run)
	return placed > 0

/datum/world_edit_generator/building_layout/proc/get_fixture_run_dirs(datum/world_edit_building_layout_state/state, wall_dir)
	var/list/run_dirs = list()
	if(wall_dir)
		run_dirs += turn(wall_dir, 90)
		run_dirs += turn(wall_dir, -90)
	else if(state.placement_dir in list(NORTH, SOUTH))
		run_dirs += EAST
		run_dirs += WEST
	else
		run_dirs += NORTH
		run_dirs += SOUTH
	return run_dirs

/datum/world_edit_generator/building_layout/proc/extend_fixture_run(datum/world_edit_building_layout_state/state, turf/start_turf, run_dir, slot, dir_to_use, placed, target_count, wall_run)
	var/turf/current_turf = start_turf
	var/steps = 0
	while(placed < target_count && steps < WORLD_EDIT_BUILDING_MAX_CLUSTER_STEPS && state.fixture_count < WORLD_EDIT_BUILDING_MAX_FIXTURE_OBJECTS)
		steps++
		current_turf = get_step(current_turf, run_dir)
		if(!state.can_place_fixture(current_turf))
			break
		if(wall_run && !state.wall_lookup[get_step(current_turf, turn(dir_to_use, 180))])
			break
		if(!place_fixture_at(state, current_turf, slot, dir_to_use, slot, FALSE, wall_run))
			break
		placed++
	return placed

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
