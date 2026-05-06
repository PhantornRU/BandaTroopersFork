/datum/world_edit_generator/building_layout/proc/place_building_fixtures(datum/world_edit_building_layout_state/state)
	if(!istype(state) || state.has_errors() || !istype(state.semantic_plan))
		return
	prepare_building_fixture_scale(state)
	for(var/datum/world_edit_building_cluster_spec/cluster_spec as anything in state.semantic_plan.get_cluster_specs("major"))
		place_building_cluster_spec(state, cluster_spec, TRUE)

	var/detail_budget = clamp(round(text2num("[state.config["detail_budget"]]")), 0, 100)
	if(detail_budget <= 0)
		return

	var/list/secondary_specs = state.semantic_plan.get_cluster_specs("secondary")
	var/secondary_limit = min(length(secondary_specs), max(1, round(length(secondary_specs) * detail_budget / 100)))
	var/placed_secondary = 0
	for(var/datum/world_edit_building_cluster_spec/cluster_spec as anything in secondary_specs)
		if(placed_secondary >= secondary_limit)
			break
		if(detail_budget < 100 && !state.request.fixture_rng.chance(max(detail_budget, cluster_spec.priority)))
			continue
		if(place_building_cluster_spec(state, cluster_spec, FALSE))
			placed_secondary++

	if(detail_budget < 65)
		return
	for(var/datum/world_edit_building_cluster_spec/cluster_spec as anything in state.semantic_plan.get_cluster_specs("detail"))
		if(!state.request.fixture_rng.chance(detail_budget))
			continue
		place_building_cluster_spec(state, cluster_spec, FALSE)

/datum/world_edit_generator/building_layout/proc/place_building_cluster_spec(datum/world_edit_building_layout_state/state, datum/world_edit_building_cluster_spec/cluster_spec, major)
	if(!istype(state) || !istype(cluster_spec) || state.fixture_count >= WORLD_EDIT_BUILDING_MAX_FIXTURE_OBJECTS)
		return FALSE
	var/placed = 0
	var/target_count = get_scaled_cluster_target_count(state, cluster_spec)
	switch(cluster_spec.pattern)
		if("run", "counter_line", "staging_group")
			placed = place_fixture_run(state, cluster_spec, target_count)
		else
			var/attempts = 0
			while(placed < target_count && attempts < WORLD_EDIT_BUILDING_MAX_CLUSTER_STEPS && state.fixture_count < WORLD_EDIT_BUILDING_MAX_FIXTURE_OBJECTS)
				attempts++
				var/unit_placed = 0
				switch(cluster_spec.pattern)
					if("table_cluster")
						unit_placed = place_table_cluster(state, cluster_spec)
					if("wall_object")
						unit_placed = place_wall_fixture(state, cluster_spec)
					if("paired_object")
						unit_placed = place_paired_fixture_objects(state, cluster_spec)
					if("object")
						unit_placed = place_fixture_object(state, cluster_spec)
				if(unit_placed <= 0)
					break
				placed += unit_placed
	if(placed > 0)
		state.register_cluster(cluster_spec.id, placed)
	return placed >= max(cluster_spec.min_count, 1)

/datum/world_edit_generator/building_layout/proc/prepare_building_fixture_scale(datum/world_edit_building_layout_state/state)
	state.usable_fixture_area = 0
	for(var/turf/floor_turf as anything in state.floor_turfs)
		if(state.can_place_fixture(floor_turf))
			state.usable_fixture_area++
	state.category_budgets.Cut()
	var/usable_area = max(state.usable_fixture_area, length(state.floor_turfs) - length(state.primary_route_turfs))
	for(var/category as anything in state.archetype.object_budgets)
		var/base_budget = round(text2num("[state.archetype.object_budgets[category]]") || 0)
		if(base_budget <= 0)
			continue
		var/area_bonus = max(0, round((usable_area - 24) / 14))
		state.category_budgets["[category]"] = min(WORLD_EDIT_BUILDING_MAX_FIXTURE_OBJECTS, max(base_budget, base_budget + area_bonus))

/datum/world_edit_generator/building_layout/proc/get_cluster_anchor_area(datum/world_edit_building_layout_state/state, datum/world_edit_building_cluster_spec/cluster_spec)
	var/area = 0
	var/datum/world_edit_building_place_rule/place_rule = resolve_building_place_rule(cluster_spec.slot, cluster_spec.category)
	var/effective_needs_wall = cluster_spec.wall_required || place_rule.needs_wall
	for(var/turf/floor_turf as anything in state.floor_turfs)
		if(!state.can_place_fixture(floor_turf))
			continue
		if(effective_needs_wall && !length(get_adjacent_wall_dirs_for_state(state, floor_turf)))
			continue
		if(!fixture_turf_matches_anchor(state, floor_turf, cluster_spec.anchors))
			continue
		var/fallback_dir = get_cardinal_dir_toward(floor_turf, state.semantic_hub_turf || state.center_turf, SOUTH)
		if(!fixture_turf_satisfies_place_rule(state, floor_turf, place_rule, fallback_dir, effective_needs_wall))
			continue
		area++
	return area

/datum/world_edit_generator/building_layout/proc/get_cluster_area_divisor(datum/world_edit_building_cluster_spec/cluster_spec)
	switch(cluster_spec.pattern)
		if("run")
			return 8
		if("counter_line")
			return 6
		if("staging_group")
			return 10
		if("table_cluster")
			return 28
		if("wall_object", "paired_object")
			return 18
	return 22

/datum/world_edit_generator/building_layout/proc/get_scaled_cluster_target_count(datum/world_edit_building_layout_state/state, datum/world_edit_building_cluster_spec/cluster_spec)
	var/base_count = max(cluster_spec.min_count, cluster_spec.max_count)
	var/anchor_area = get_cluster_anchor_area(state, cluster_spec)
	if(anchor_area <= 0)
		return base_count
	var/divisor = max(get_cluster_area_divisor(cluster_spec), 1)
	var/area_bonus = max(0, round((anchor_area - (base_count * 2)) / divisor))
	if(cluster_spec.phase != "major")
		area_bonus = round(area_bonus * clamp(round(text2num("[state.config["detail_budget"]]") || 0), 0, 100) / 100)
	var/area_cap = max(cluster_spec.min_count, min(WORLD_EDIT_BUILDING_MAX_CLUSTER_STEPS, round(anchor_area / max(cluster_spec.pattern == "table_cluster" ? 5 : 2, 1))))
	return min(area_cap, max(base_count, base_count + area_bonus))

/datum/world_edit_generator/building_layout/proc/place_table_cluster(datum/world_edit_building_layout_state/state, datum/world_edit_building_cluster_spec/cluster_spec)
	var/datum/world_edit_building_place_rule/table_rule = resolve_building_place_rule(cluster_spec.slot, cluster_spec.category)
	var/turf/table_turf = select_fixture_turf(state, cluster_spec.anchors, cluster_spec.wall_required, cluster_spec)
	if(!istype(table_turf))
		return 0
	var/fallback_dir = get_cardinal_dir_toward(table_turf, state.semantic_hub_turf || state.center_turf, SOUTH)
	var/list/table_context = build_building_fixture_place_context(state, table_turf, table_rule, fallback_dir, cluster_spec.wall_required)
	if(!islist(table_context))
		return 0
	var/dir_to_use = table_context["dir"] || fallback_dir
	var/wall_dir = table_context["wall_dir"]
	if(!place_fixture_at(state, table_turf, cluster_spec.slot, dir_to_use, cluster_spec.category, cluster_spec.phase == "major", cluster_spec.wall_required, table_rule, wall_dir))
		return 0
	var/placed_primary = 1
	var/placed_chairs = 0
	var/datum/world_edit_building_place_rule/chair_rule = resolve_building_place_rule("chair", "chair")
	for(var/check_dir in GLOB.cardinals)
		if(placed_chairs >= cluster_spec.chair_count)
			break
		var/turf/chair_turf = get_step(table_turf, check_dir)
		if(!state.can_place_fixture(chair_turf))
			continue
		var/chair_dir = get_cardinal_dir_toward(chair_turf, table_turf, SOUTH)
		if(!building_place_rule_allows_turf(state, chair_turf, chair_rule, chair_dir, null))
			continue
		if(place_fixture_at(state, chair_turf, "chair", chair_dir, "chair", FALSE, FALSE, chair_rule, null))
			placed_chairs++
	return placed_primary

/datum/world_edit_generator/building_layout/proc/place_fixture_run(datum/world_edit_building_layout_state/state, datum/world_edit_building_cluster_spec/cluster_spec, target_count)
	var/placed = 0
	var/attempts = 0
	var/datum/world_edit_building_place_rule/place_rule = resolve_building_place_rule(cluster_spec.slot, cluster_spec.category)
	while(placed < target_count && attempts < WORLD_EDIT_BUILDING_MAX_CLUSTER_STEPS && state.fixture_count < WORLD_EDIT_BUILDING_MAX_FIXTURE_OBJECTS)
		attempts++
		var/turf/start_turf = select_fixture_turf(state, cluster_spec.anchors, cluster_spec.wall_required, cluster_spec)
		if(!istype(start_turf))
			break
		var/fallback_dir = get_cardinal_dir_toward(start_turf, state.semantic_hub_turf || state.center_turf, SOUTH)
		var/list/place_context = build_building_fixture_place_context(state, start_turf, place_rule, fallback_dir, cluster_spec.wall_required)
		if(!islist(place_context))
			break
		var/wall_dir = place_context["wall_dir"]
		var/dir_to_use = place_context["dir"] || fallback_dir
		if(!place_fixture_at(state, start_turf, cluster_spec.slot, dir_to_use, cluster_spec.category, cluster_spec.phase == "major" && placed <= 0, cluster_spec.wall_required, place_rule, wall_dir))
			break
		placed++
		var/list/run_dirs = get_fixture_run_dirs(state, wall_dir)
		for(var/run_dir as anything in run_dirs)
			if(placed >= target_count)
				break
			placed = extend_fixture_run(state, start_turf, run_dir, cluster_spec, dir_to_use, wall_dir, place_rule, placed, target_count)
	return placed

/datum/world_edit_generator/building_layout/proc/fixture_turf_matches_anchor(datum/world_edit_building_layout_state/state, turf/target_turf, list/anchor_ids)
	if(!istype(state) || !istype(target_turf))
		return FALSE
	if(!islist(anchor_ids) || !length(anchor_ids))
		return TRUE
	var/zone_id = state.get_zone(target_turf)
	var/has_semantic_zone_anchor = FALSE
	for(var/anchor_id as anything in anchor_ids)
		var/datum/world_edit_building_zone_spec/anchor_zone_spec = state.semantic_plan?.get_zone_spec("[anchor_id]")
		if(istype(anchor_zone_spec))
			has_semantic_zone_anchor = TRUE
			if(zone_id == "[anchor_id]" || state.has_anchor("[anchor_id]", target_turf))
				return TRUE
	if(has_semantic_zone_anchor)
		return FALSE
	for(var/anchor_id as anything in anchor_ids)
		if(zone_id == "[anchor_id]" || state.has_anchor("[anchor_id]", target_turf))
			return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/place_paired_fixture_objects(datum/world_edit_building_layout_state/state, datum/world_edit_building_cluster_spec/cluster_spec)
	var/datum/world_edit_building_place_rule/place_rule = resolve_building_place_rule(cluster_spec.slot, cluster_spec.category)
	var/turf/primary_turf = select_fixture_turf(state, cluster_spec.anchors, cluster_spec.wall_required, cluster_spec)
	if(!istype(primary_turf))
		return 0
	var/fallback_dir = get_cardinal_dir_toward(primary_turf, state.semantic_hub_turf || state.center_turf, SOUTH)
	var/list/place_context = build_building_fixture_place_context(state, primary_turf, place_rule, fallback_dir, cluster_spec.wall_required)
	if(!islist(place_context))
		return 0
	var/wall_dir = place_context["wall_dir"]
	var/dir_to_use = place_context["dir"] || fallback_dir
	if(!place_fixture_at(state, primary_turf, cluster_spec.slot, dir_to_use, cluster_spec.category, cluster_spec.phase == "major", cluster_spec.wall_required, place_rule, wall_dir))
		return 0
	var/placed = 1
	var/target_count = clamp(cluster_spec.max_count, 2, 2)
	while(placed < target_count)
		var/turf/best_pair_turf = null
		var/best_pair_score = -999999999
		for(var/check_dir in GLOB.cardinals)
			var/turf/pair_turf = get_step(primary_turf, check_dir)
			if(!state.can_place_fixture(pair_turf))
				continue
			if(!fixture_turf_matches_anchor(state, pair_turf, cluster_spec.anchors))
				continue
			if(cluster_spec.wall_required && (isnull(wall_dir) || !state.wall_lookup[get_step(pair_turf, wall_dir)]))
				continue
			if(!building_place_rule_allows_turf(state, pair_turf, place_rule, dir_to_use, wall_dir))
				continue
			var/pair_score = score_fixture_turf(state, pair_turf, cluster_spec.anchors, cluster_spec.wall_required || place_rule.needs_wall, cluster_spec, place_rule)
			if(check_dir == turn(dir_to_use, 90) || check_dir == turn(dir_to_use, -90))
				pair_score += 40
			if(!istype(best_pair_turf) || pair_score > best_pair_score)
				best_pair_turf = pair_turf
				best_pair_score = pair_score
		if(!istype(best_pair_turf))
			break
		if(!place_fixture_at(state, best_pair_turf, cluster_spec.slot, dir_to_use, cluster_spec.category, FALSE, cluster_spec.wall_required, place_rule, wall_dir))
			break
		placed++
	return placed

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

/datum/world_edit_generator/building_layout/proc/extend_fixture_run(datum/world_edit_building_layout_state/state, turf/start_turf, run_dir, datum/world_edit_building_cluster_spec/cluster_spec, dir_to_use, wall_dir, datum/world_edit_building_place_rule/place_rule, placed, target_count)
	var/turf/current_turf = start_turf
	var/steps = 0
	while(placed < target_count && steps < WORLD_EDIT_BUILDING_MAX_CLUSTER_STEPS && state.fixture_count < WORLD_EDIT_BUILDING_MAX_FIXTURE_OBJECTS)
		steps++
		current_turf = get_step(current_turf, run_dir)
		if(!state.can_place_fixture(current_turf))
			break
		if(!fixture_turf_matches_anchor(state, current_turf, cluster_spec.anchors))
			break
		if(cluster_spec.wall_required && isnull(wall_dir))
			break
		if(!isnull(wall_dir) && !state.wall_lookup[get_step(current_turf, wall_dir)])
			break
		if(!building_place_rule_allows_turf(state, current_turf, place_rule, dir_to_use, wall_dir))
			break
		if(!place_fixture_at(state, current_turf, cluster_spec.slot, dir_to_use, cluster_spec.category, FALSE, cluster_spec.wall_required, place_rule, wall_dir))
			break
		placed++
	return placed

/datum/world_edit_generator/building_layout/proc/place_wall_fixture(datum/world_edit_building_layout_state/state, datum/world_edit_building_cluster_spec/cluster_spec)
	var/datum/world_edit_building_place_rule/place_rule = resolve_building_place_rule(cluster_spec.slot, cluster_spec.category)
	var/turf/target_turf = select_fixture_turf(state, cluster_spec.anchors, TRUE, cluster_spec)
	if(!istype(target_turf))
		return 0
	var/fallback_dir = get_cardinal_dir_toward(target_turf, state.semantic_hub_turf || state.center_turf, SOUTH)
	var/list/place_context = build_building_fixture_place_context(state, target_turf, place_rule, fallback_dir, TRUE)
	if(!islist(place_context))
		return 0
	var/wall_dir = place_context["wall_dir"]
	var/dir_to_use = place_context["dir"] || fallback_dir
	if(!place_fixture_at(state, target_turf, cluster_spec.slot, dir_to_use, cluster_spec.category, cluster_spec.phase == "major", TRUE, place_rule, wall_dir))
		return 0
	return 1

/datum/world_edit_generator/building_layout/proc/place_fixture_object(datum/world_edit_building_layout_state/state, datum/world_edit_building_cluster_spec/cluster_spec)
	var/datum/world_edit_building_place_rule/place_rule = resolve_building_place_rule(cluster_spec.slot, cluster_spec.category)
	var/turf/target_turf = select_fixture_turf(state, cluster_spec.anchors, cluster_spec.wall_required, cluster_spec)
	if(!istype(target_turf))
		return 0
	var/fallback_dir = get_cardinal_dir_toward(target_turf, state.semantic_hub_turf || state.center_turf, SOUTH)
	var/list/place_context = build_building_fixture_place_context(state, target_turf, place_rule, fallback_dir, cluster_spec.wall_required)
	if(!islist(place_context))
		return 0
	var/wall_dir = place_context["wall_dir"]
	var/dir_to_use = place_context["dir"] || fallback_dir
	if(!place_fixture_at(state, target_turf, cluster_spec.slot, dir_to_use, cluster_spec.category, cluster_spec.phase == "major", cluster_spec.wall_required, place_rule, wall_dir))
		return 0
	return 1

/datum/world_edit_generator/building_layout/proc/select_fixture_turf(datum/world_edit_building_layout_state/state, list/anchor_ids, needs_wall = FALSE, datum/world_edit_building_cluster_spec/cluster_spec = null)
	var/list/best_turfs = list()
	var/best_score = -999999999
	var/datum/world_edit_building_place_rule/place_rule = resolve_building_place_rule(cluster_spec?.slot, cluster_spec?.category)
	var/effective_needs_wall = needs_wall || place_rule.needs_wall
	for(var/turf/floor_turf as anything in state.floor_turfs)
		if(!state.can_place_fixture(floor_turf))
			continue
		if(effective_needs_wall && !length(get_adjacent_wall_dirs_for_state(state, floor_turf)))
			continue
		if(!fixture_turf_matches_anchor(state, floor_turf, anchor_ids))
			continue
		var/fallback_dir = get_cardinal_dir_toward(floor_turf, state.semantic_hub_turf || state.center_turf, SOUTH)
		if(!fixture_turf_satisfies_place_rule(state, floor_turf, place_rule, fallback_dir, effective_needs_wall))
			continue
		var/score = score_fixture_turf(state, floor_turf, anchor_ids, effective_needs_wall, cluster_spec, place_rule)
		if(score > best_score)
			best_score = score
			best_turfs.Cut()
			best_turfs += floor_turf
		else if(score == best_score)
			best_turfs += floor_turf
	if(!length(best_turfs))
		return null
	return state.request.fixture_rng.pick_from(best_turfs)

/datum/world_edit_generator/building_layout/proc/score_fixture_turf(datum/world_edit_building_layout_state/state, turf/target_turf, list/anchor_ids, needs_wall = FALSE, datum/world_edit_building_cluster_spec/cluster_spec = null, datum/world_edit_building_place_rule/place_rule = null)
	var/score = 0
	if(!istype(place_rule))
		place_rule = resolve_building_place_rule(cluster_spec?.slot, cluster_spec?.category)
	var/zone_id = state.get_zone(target_turf)
	for(var/anchor_id as anything in anchor_ids)
		if(state.has_anchor(anchor_id, target_turf) || zone_id == "[anchor_id]")
			score += 120
	if(needs_wall)
		score += length(get_adjacent_wall_dirs_for_state(state, target_turf)) * 35
	if(state.has_anchor("door_cone", target_turf))
		score -= 1000
	if(state.reserved_lookup[target_turf])
		score -= 500
	if(cluster_spec)
		score += cluster_spec.priority
		if(zone_id in cluster_spec.anchors)
			score += 80
	score += place_rule.priority_bonus
	var/clearance = 0
	for(var/check_dir in GLOB.cardinals)
		var/turf/nearby_turf = get_step(target_turf, check_dir)
		if(state.floor_lookup[nearby_turf] && !state.fixture_lookup[nearby_turf] && !state.wall_lookup[nearby_turf])
			clearance++
	score += clearance * 8
	if(istype(state.semantic_hub_turf))
		score -= abs(target_turf.x - state.semantic_hub_turf.x) + abs(target_turf.y - state.semantic_hub_turf.y)
	return score

/datum/world_edit_generator/building_layout/proc/place_fixture_at(datum/world_edit_building_layout_state/state, turf/target_turf, slot, dir_to_use, category, major = FALSE, wall_mounted = FALSE, datum/world_edit_building_place_rule/place_rule = null, wall_dir = null)
	if(!state.can_place_fixture(target_turf))
		return FALSE
	if(state.fixture_count >= WORLD_EDIT_BUILDING_MAX_FIXTURE_OBJECTS)
		return FALSE
	if(!istype(place_rule))
		place_rule = resolve_building_place_rule(slot, category)
	if(wall_mounted && isnull(wall_dir))
		var/list/wall_dirs = get_adjacent_wall_dirs_for_state(state, target_turf)
		for(var/check_wall_dir as anything in wall_dirs)
			if(resolve_building_place_rule_dir(check_wall_dir, place_rule.dir_mode) == dir_to_use)
				wall_dir = check_wall_dir
				break
	if(wall_mounted && isnull(wall_dir))
		return FALSE
	if(!building_place_rule_allows_turf(state, target_turf, place_rule, dir_to_use, wall_dir))
		return FALSE
	var/budget = state.get_category_budget(category)
	if(isnum(budget) && budget > 0 && (state.category_counts["[category]"] || 0) >= budget)
		return FALSE
	var/obj_path = resolve_interior_obj_path(state.config, slot)
	if(!obj_path)
		state.add_warning("Unable to resolve fixture object '[slot]' for program [state.archetype.id].")
		return FALSE
	state.object_placements += list(build_object_placement("interior", target_turf, obj_path, dir_to_use))
	state.register_fixture(target_turf, category, major, wall_mounted)
	return TRUE
