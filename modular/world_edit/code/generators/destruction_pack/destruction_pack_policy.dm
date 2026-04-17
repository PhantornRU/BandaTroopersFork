/datum/world_edit_generator/destruction_pack/proc/get_persistent_fire_cap()
	return WORLD_EDIT_DESTRUCTION_PERSISTENT_FIRE_CAP

/datum/world_edit_generator/destruction_pack/proc/get_persistent_fire_density_min()
	return 1

/datum/world_edit_generator/destruction_pack/proc/get_persistent_fire_density_max()
	return 100

/datum/world_edit_generator/destruction_pack/proc/get_persistent_fire_density_default()
	return 10

/datum/world_edit_generator/destruction_pack/proc/get_blast_power_min()
	return 100

/datum/world_edit_generator/destruction_pack/proc/get_blast_power_max()
	return 5000

/datum/world_edit_generator/destruction_pack/proc/get_blast_power_default()
	return 250

/datum/world_edit_generator/destruction_pack/proc/get_blast_falloff_min()
	return 100

/datum/world_edit_generator/destruction_pack/proc/get_blast_falloff_max()
	return 10000

/datum/world_edit_generator/destruction_pack/proc/get_blast_falloff_default()
	return 600

/datum/world_edit_generator/destruction_pack/proc/coerce_persistent_fire_density_percent(value)
	var/density = text2num("[value]")
	if(!isnum(density))
		return null
	if(density > 0 && density <= 1)
		density *= 100
	return density

/datum/world_edit_generator/destruction_pack/proc/normalize_persistent_fire_density_percent(value)
	var/density = coerce_persistent_fire_density_percent(value)
	if(!isnum(density))
		return get_persistent_fire_density_default()
	return clamp(round(density), get_persistent_fire_density_min(), get_persistent_fire_density_max())

/datum/world_edit_generator/destruction_pack/proc/build_damage_profile_options()
	return list(
		list(
			"label" = "None",
			"value" = "none",
			"description" = "Only shuffle, scatter, persistent fire, and/or blast are applied.",
		),
		list(
			"label" = "Ruin",
			"value" = "ruin",
			"description" = "Low-severity structural and tile damage. Only the core influence band is affected.",
		),
		list(
			"label" = "Collapse",
			"value" = "collapse",
			"description" = "Stronger structural damage. The core band collapses and the mid band receives ruin damage.",
		),
	)

/datum/world_edit_generator/destruction_pack/proc/get_default_damage_profile()
	return "none"

/datum/world_edit_generator/destruction_pack/proc/resolve_damage_profile(value)
	if(isnull(value) || !length("[value]") || "[value]" == "null")
		return get_default_damage_profile()

	var/profile_id = "[value]"
	switch(profile_id)
		if("none", "ruin", "collapse")
			return profile_id
	return null

/datum/world_edit_generator/destruction_pack/proc/get_damage_profile_label(profile_id)
	switch(resolve_damage_profile(profile_id))
		if("ruin")
			return "Ruin"
		if("collapse")
			return "Collapse"
	return "None"

/datum/world_edit_generator/destruction_pack/proc/get_damage_profile_severity(profile_id)
	switch(resolve_damage_profile(profile_id))
		if("ruin")
			return EXPLOSION_THRESHOLD_VLOW
		if("collapse")
			return EXPLOSION_THRESHOLD_LOW
	return 0

/datum/world_edit_generator/destruction_pack/proc/can_place_persistent_fire_on_turf(turf/target_turf)
	if(!istype(target_turf) || target_turf.density)
		return FALSE
	if(locate(/obj/effect/world_edit_persistent_fire) in target_turf)
		return FALSE
	return TRUE

/datum/world_edit_generator/destruction_pack/proc/build_damage_entries(list/influence_turfs, list/influence_lookup, damage_profile)
	var/list/damage_entries = list()
	var/resolved_profile = resolve_damage_profile(damage_profile)
	if(resolved_profile == "none" || !length(influence_turfs))
		return damage_entries

	var/list/core_turfs = list()
	var/list/mid_turfs = list()
	for(var/turf/influence_turf as anything in influence_turfs)
		var/list/influence_info = islist(influence_lookup) ? influence_lookup[influence_turf] : null
		var/band = islist(influence_info) ? "[influence_info["band"]]" : ""
		switch(resolved_profile)
			if("ruin")
				if(band == "core")
					core_turfs += influence_turf
			if("collapse")
				if(band == "core")
					core_turfs += influence_turf
				else if(band == "mid")
					mid_turfs += influence_turf

	if(length(core_turfs))
		damage_entries += list(list(
			"kind" = "damage",
			"area_turfs" = core_turfs.Copy(),
			"damage_profile" = resolved_profile,
			"severity" = get_damage_profile_severity(resolved_profile),
			"band" = "core",
		))
	if(length(mid_turfs))
		damage_entries += list(list(
			"kind" = "damage",
			"area_turfs" = mid_turfs.Copy(),
			"damage_profile" = "ruin",
			"severity" = get_damage_profile_severity("ruin"),
			"band" = "mid",
		))

	return damage_entries

/datum/world_edit_generator/destruction_pack/proc/build_blast_centers(list/seed_turfs, turf/center_turf, radius, plan_seed)
	var/list/centers = list()
	if(!islist(seed_turfs) || !length(seed_turfs) || radius < 1)
		return centers

	if(!istype(center_turf))
		center_turf = build_shape_center_turf(seed_turfs)
	if(!istype(center_turf))
		return centers

	centers += center_turf

	var/requires_secondary_centers = FALSE
	for(var/turf/seed_turf as anything in seed_turfs)
		if(get_chebyshev_distance(center_turf, seed_turf) > radius)
			requires_secondary_centers = TRUE
			break
	if(!requires_secondary_centers)
		return centers

	while(length(centers) < 6)
		var/turf/best_candidate = null
		var/best_score = -1
		for(var/turf/candidate_turf as anything in seed_turfs)
			if(!istype(candidate_turf))
				continue

			var/min_distance_to_existing = WORLD_EDIT_PLACEMENT_MAX_TOTAL_PLACEMENTS
			for(var/turf/existing_center as anything in centers)
				min_distance_to_existing = min(min_distance_to_existing, get_chebyshev_distance(candidate_turf, existing_center))

			if(min_distance_to_existing <= radius * 2)
				continue

			var/score = (min_distance_to_existing * 100) + get_deterministic_turf_score(plan_seed, candidate_turf, length(centers))
			if(score <= best_score)
				continue

			best_score = score
			best_candidate = candidate_turf

		if(!istype(best_candidate))
			break

		centers += best_candidate

	return centers

/datum/world_edit_generator/destruction_pack/proc/build_blast_entries(list/seed_turfs, turf/center_turf, radius, blast_power, blast_falloff, plan_seed)
	var/list/blast_entries = list()
	var/list/blast_centers = build_blast_centers(seed_turfs, center_turf, radius, plan_seed)
	var/index = 0
	for(var/turf/blast_center as anything in blast_centers)
		index++
		var/effective_power = index == 1 ? blast_power : max(1, round(blast_power * 0.6))
		var/effective_falloff = index == 1 ? blast_falloff : max(1, round(blast_falloff * 0.75))
		blast_entries += list(list(
			"kind" = "blast",
			"center_turf" = blast_center,
			"power" = effective_power,
			"falloff" = effective_falloff,
			"blast_index" = index,
		))

	return blast_entries

/datum/world_edit_generator/destruction_pack/proc/apply_structural_damage_profile(list/area_turfs, severity, datum/cause_data/cause_data)
	var/damaged_turf_count = 0
	if(!islist(area_turfs) || !length(area_turfs) || severity <= 0)
		return damaged_turf_count

	for(var/turf/target_turf as anything in area_turfs)
		if(!istype(target_turf))
			continue

		target_turf.ex_act(severity, null, cause_data)
		damaged_turf_count++

		for(var/atom/target_atom as anything in target_turf)
			if(QDELETED(target_atom))
				continue
			if(ismob(target_atom))
				continue
			if(istype(target_atom, /obj/effect/world_edit_persistent_fire))
				continue
			target_atom.ex_act(severity, null, cause_data)

	return damaged_turf_count

/datum/world_edit_generator/destruction_pack/proc/build_persistent_fire_entries(list/influence_turfs, list/influence_lookup, density, plan_seed)
	var/list/fire_entries = list()
	if(!length(influence_turfs) || density <= 0)
		return fire_entries

	var/density_ratio = density / 100
	var/target_count = round(length(influence_turfs) * density_ratio)
	target_count = clamp(target_count, 0, get_persistent_fire_cap())
	if(target_count <= 0)
		return fire_entries

	var/list/pool = list()
	for(var/turf/target_turf as anything in influence_turfs)
		if(can_place_persistent_fire_on_turf(target_turf))
			pool += target_turf

	while(target_count > 0 && length(pool))
		var/turf/selected_turf = pick_weighted_turf(pool, influence_lookup, plan_seed, 1000 + length(fire_entries))
		if(!istype(selected_turf))
			break

		pool -= selected_turf
		fire_entries += list(list(
			"kind" = "fire",
			"turf" = selected_turf,
		))
		target_count--

	return fire_entries

/datum/world_edit_generator/destruction_pack/proc/build_target_movement_entry(atom/movable/target, list/area_turfs, list/influence_lookup, shuffle_enabled, scatter_enabled, scatter_steps, plan_seed, salt = 0)
	if(!target || QDELETED(target))
		return null

	var/turf/source_turf = get_turf(target)
	if(!source_turf)
		return null

	var/source_weight = get_influence_weight_for_turf(influence_lookup, source_turf)
	if(source_weight <= 0)
		return null
	if(get_deterministic_turf_score(plan_seed, source_turf, salt) > source_weight)
		return null

	var/list/path_turfs = list()
	var/turf/current_turf = source_turf

	if(shuffle_enabled)
		var/list/shuffle_candidates = list()
		for(var/turf/candidate_turf as anything in area_turfs)
			if(candidate_turf == current_turf)
				continue
			if(!can_relocate_target_to_turf(target, candidate_turf))
				continue
			shuffle_candidates += candidate_turf

		var/turf/shuffle_turf = pick_weighted_turf(shuffle_candidates, influence_lookup, plan_seed, salt + 100)
		if(shuffle_turf && shuffle_turf != current_turf)
			path_turfs += shuffle_turf
			current_turf = shuffle_turf

	if(scatter_enabled)
		for(var/i in 1 to scatter_steps)
			var/list/step_candidates = list()
			for(var/cardinal_dir in GLOB.cardinals)
				var/turf/next_turf = get_step(current_turf, cardinal_dir)
				if(!next_turf || !influence_lookup[next_turf] || next_turf == current_turf)
					continue
				if(!can_relocate_target_to_turf(target, next_turf))
					continue
				step_candidates += next_turf

			var/turf/next_turf = pick_weighted_turf(step_candidates, influence_lookup, plan_seed, salt + (200 * i))
			if(!next_turf)
				continue

			path_turfs += next_turf
			current_turf = next_turf

	if(!length(path_turfs))
		return null

	return list(
		"kind" = "move",
		"target_ref" = WEAKREF(target),
		"source_turf" = source_turf,
		"path_turfs" = path_turfs,
		"destination_turf" = current_turf,
	)
