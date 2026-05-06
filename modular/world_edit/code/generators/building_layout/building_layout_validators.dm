/datum/world_edit_generator/building_layout/proc/get_building_cluster_primary_category(cluster_id)
	switch("[cluster_id]")
		if("bed_niche")
			return "bed"
		if("dining_pair", "workbench_run", "inspection_table", "checkpoint_counter", "treatment_table")
			return "table"
		if("personal_storage", "tool_storage", "security_storage")
			return "cabinet"
		if("window_seat", "visitor_chair", "waiting_chair")
			return "chair"
		if("parts_rack_run", "rack_run")
			return "rack"
		if("operator_console")
			return "console"
		if("storage_loading_axis", "crate_stack")
			return "crate"
		if("triage_bed_cluster")
			return "medical_bed"
		if("med_storage_wall")
			return "medical_storage"
	return null

/datum/world_edit_generator/building_layout/proc/validate_and_repair_building_layout_state(datum/world_edit_building_layout_state/state)
	if(!istype(state))
		return
	validate_building_layout_state(state)
	if(!state.has_errors())
		return

	for(var/attempt in 1 to WORLD_EDIT_BUILDING_MAX_REPAIR_ATTEMPTS)
		var/repaired_this_pass = FALSE
		for(var/cluster_id as anything in state.archetype.major_clusters)
			var/primary_category = get_building_cluster_primary_category(cluster_id)
			if(length("[primary_category]") && (state.category_counts["[primary_category]"] || 0) > 0)
				continue
			if(place_building_cluster(state, "[cluster_id]", TRUE))
				repaired_this_pass = TRUE
		validate_building_layout_state(state)
		if(!state.has_errors() || !repaired_this_pass)
			break

/datum/world_edit_generator/building_layout/proc/validate_building_layout_state(datum/world_edit_building_layout_state/state)
	if(!istype(state))
		return
	state.errors.Cut()

	if(!istype(state.archetype))
		state.add_error("Building archetype is unavailable.")
		return
	if(!length(state.footprint) || !length(state.floor_turfs))
		state.add_error("Building layout has no usable footprint or floor turfs.")
	if(!istype(state.front_door_turf) || !length(state.door_turfs))
		state.add_error("Building layout has no entry door.")

	for(var/zone_id as anything in state.archetype.mandatory_zones)
		if(!length(state.get_zone_turfs(zone_id)))
			state.add_error("Mandatory zone '[zone_id]' was not produced for archetype [state.archetype.id].")

	validate_building_door_buffers(state)
	validate_building_windows(state)
	validate_building_reserved_lanes(state)
	validate_building_fixture_surface(state)
	validate_building_fixture_reachability(state)
	validate_building_privacy_rules(state)
	validate_building_major_clusters(state)
	validate_building_archetype_specifics(state)

/datum/world_edit_generator/building_layout/proc/validate_building_door_buffers(datum/world_edit_building_layout_state/state)
	for(var/turf/door_turf as anything in state.door_turfs)
		if(!istype(door_turf))
			state.add_error("Building door placement contains an invalid turf.")
			continue
		var/door_dir = state.door_dirs[door_turf] || get_outward_dir(door_turf, state.footprint_lookup, (state.bounds["min_x"] + state.bounds["max_x"]) / 2, (state.bounds["min_y"] + state.bounds["max_y"]) / 2, state.placement_dir)
		var/turf/inward_turf = get_step(door_turf, turn(door_dir, 180))
		if(!state.floor_lookup[inward_turf])
			state.add_error("Door at [GLOB.world_edit_helpers.turf_to_text(door_turf)] has no interior buffer.")
		if(state.fixture_lookup[inward_turf])
			state.add_error("Door buffer at [GLOB.world_edit_helpers.turf_to_text(inward_turf)] is blocked by a fixture.")

/datum/world_edit_generator/building_layout/proc/validate_building_windows(datum/world_edit_building_layout_state/state)
	var/list/door_lookup = GLOB.world_edit_placement_shapes.world_edit_build_turf_lookup(state.door_turfs)
	for(var/turf/window_turf as anything in state.window_turfs)
		if(!state.boundary_lookup[window_turf])
			state.add_error("Window placement must stay on exterior boundary.")
		if(door_lookup[window_turf])
			state.add_error("Window placement overlaps a door.")
		if(!boundary_turf_has_outside_dir(window_turf, state.footprint_lookup, get_outward_dir(window_turf, state.footprint_lookup, (state.bounds["min_x"] + state.bounds["max_x"]) / 2, (state.bounds["min_y"] + state.bounds["max_y"]) / 2, state.placement_dir)))
			state.add_error("Window placement has no exterior side.")

/datum/world_edit_generator/building_layout/proc/validate_building_reserved_lanes(datum/world_edit_building_layout_state/state)
	for(var/turf/reserved_turf as anything in state.floor_turfs)
		if(!state.reserved_lookup[reserved_turf])
			continue
		if(state.fixture_lookup[reserved_turf])
			state.add_error("Primary lane at [GLOB.world_edit_helpers.turf_to_text(reserved_turf)] is blocked by a fixture.")

/datum/world_edit_generator/building_layout/proc/validate_building_fixture_surface(datum/world_edit_building_layout_state/state)
	for(var/list/placement as anything in state.object_placements)
		var/turf/target_turf = placement["turf"]
		if(!state.floor_lookup[target_turf])
			state.add_error("Fixture placement must target a floor turf.")
		if(state.wall_lookup[target_turf])
			state.add_error("Fixture placement overlaps a wall turf.")
		if(state.door_dirs[target_turf])
			state.add_error("Fixture placement overlaps a door turf.")
	for(var/turf/wall_fixture_turf as anything in state.wall_fixture_turfs)
		if(!length(get_adjacent_wall_dirs_for_state(state, wall_fixture_turf)))
			state.add_error("Wall fixture has no adjacent wall.")

/datum/world_edit_generator/building_layout/proc/build_building_reachable_floor_lookup(datum/world_edit_building_layout_state/state)
	var/list/reachable = list()
	if(!istype(state))
		return reachable
	var/list/queue = list()
	for(var/turf/door_turf as anything in state.door_turfs)
		if(state.floor_lookup[door_turf])
			queue += door_turf
			reachable[door_turf] = TRUE
		var/door_dir = state.door_dirs[door_turf] || state.placement_dir
		var/turf/inward_turf = get_step(door_turf, turn(door_dir, 180))
		if(state.floor_lookup[inward_turf] && !reachable[inward_turf])
			queue += inward_turf
			reachable[inward_turf] = TRUE
	var/index = 1
	while(index <= length(queue))
		var/turf/current_turf = queue[index++]
		for(var/check_dir in GLOB.cardinals)
			var/turf/nearby_turf = get_step(current_turf, check_dir)
			if(!state.floor_lookup[nearby_turf] || reachable[nearby_turf])
				continue
			reachable[nearby_turf] = TRUE
			queue += nearby_turf
	return reachable

/datum/world_edit_generator/building_layout/proc/validate_building_fixture_reachability(datum/world_edit_building_layout_state/state)
	var/list/reachable = build_building_reachable_floor_lookup(state)
	for(var/turf/fixture_turf as anything in state.major_fixture_turfs)
		if(reachable[fixture_turf])
			continue
		var/has_adjacent_reachable_floor = FALSE
		for(var/check_dir in GLOB.cardinals)
			if(reachable[get_step(fixture_turf, check_dir)])
				has_adjacent_reachable_floor = TRUE
				break
		if(!has_adjacent_reachable_floor)
			state.add_error("Major fixture at [GLOB.world_edit_helpers.turf_to_text(fixture_turf)] is not reachable from an entry.")

/datum/world_edit_generator/building_layout/proc/validate_building_privacy_rules(datum/world_edit_building_layout_state/state)
	if(state.archetype.id != "colony_living_small")
		return
	for(var/turf/private_turf as anything in state.get_zone_turfs("sleep_privacy"))
		if(state.has_anchor("door_cone", private_turf))
			state.add_error("Living privacy zone overlaps an entry door cone.")
		for(var/check_dir in GLOB.cardinals)
			var/turf/nearby_turf = get_step(private_turf, check_dir)
			if(state.has_anchor("door_cone", nearby_turf))
				state.add_error("Living privacy zone is directly exposed to an entry door cone.")
				break

/datum/world_edit_generator/building_layout/proc/validate_building_major_clusters(datum/world_edit_building_layout_state/state)
	for(var/cluster_id as anything in state.archetype.major_clusters)
		var/primary_category = get_building_cluster_primary_category(cluster_id)
		if(!length("[primary_category]"))
			continue
		if((state.category_counts["[primary_category]"] || 0) <= 0)
			state.add_error("Major cluster '[cluster_id]' did not place required category '[primary_category]'.")

/datum/world_edit_generator/building_layout/proc/validate_building_archetype_specifics(datum/world_edit_building_layout_state/state)
	switch(state.archetype.id)
		if("colony_living_small")
			if((state.category_counts["bed"] || 0) < 1)
				state.add_error("Living module requires at least one bed.")
			if((state.category_counts["table"] || 0) < 1)
				state.add_error("Living module requires a dining/work table.")
		if("uscm_workshop_small")
			if((state.category_counts["table"] || 0) < 1)
				state.add_error("Workshop requires a workbench.")
			if((state.category_counts["rack"] || 0) < 2)
				state.add_error("Workshop requires a rack run.")
		if("uscm_storage_small")
			if((state.category_counts["rack"] || 0) < 2)
				state.add_error("Storage requires a rack run.")
			if((state.category_counts["crate"] || 0) < 1)
				state.add_error("Storage requires a loading crate.")
		if("uscm_checkpoint_wedge")
			if((state.category_counts["table"] || 0) < 2)
				state.add_error("Checkpoint requires a counter line.")
			if((state.category_counts["console"] || 0) < 1)
				state.add_error("Checkpoint requires an operator console.")
		if("medbay_small")
			if((state.category_counts["medical_bed"] || 0) < 1)
				state.add_error("Medbay requires a treatment bed.")
			if((state.category_counts["medical_storage"] || 0) < 1)
				state.add_error("Medbay requires medical storage.")
