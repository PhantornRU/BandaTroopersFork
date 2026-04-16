/datum/world_edit_generator/destruction_pack/proc/get_persistent_fire_cap()
	return 12

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
			"description" = "Low-severity structural and tile damage. Good for controlled ruin passes.",
		),
		list(
			"label" = "Collapse",
			"value" = "collapse",
			"description" = "Medium-severity structural and tile damage. Good for stronger ruin/collapse passes.",
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

/datum/world_edit_generator/destruction_pack/proc/build_persistent_fire_entries(list/area_turfs, density)
	var/list/fire_entries = list()
	if(!length(area_turfs) || density <= 0)
		return fire_entries

	var/density_ratio = density / 100
	var/target_count = round(length(area_turfs) * density_ratio)
	target_count = clamp(target_count, 0, get_persistent_fire_cap())
	if(target_count <= 0)
		return fire_entries

	var/list/pool = area_turfs.Copy()
	while(target_count > 0 && length(pool))
		var/turf/target_turf = pick_n_take(pool)
		if(!can_place_persistent_fire_on_turf(target_turf))
			continue

		fire_entries += list(list(
			"kind" = "fire",
			"turf" = target_turf,
		))
		target_count--

	return fire_entries

/datum/world_edit_generator/destruction_pack/proc/build_target_movement_entry(atom/movable/target, list/area_turfs, list/area_lookup, shuffle_enabled, scatter_enabled, scatter_steps)
	if(!target || QDELETED(target))
		return null

	var/turf/source_turf = get_turf(target)
	if(!source_turf)
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

		var/turf/shuffle_turf = length(shuffle_candidates) ? pick(shuffle_candidates) : null
		if(shuffle_turf && shuffle_turf != current_turf)
			path_turfs += shuffle_turf
			current_turf = shuffle_turf

	if(scatter_enabled)
		for(var/i in 1 to scatter_steps)
			var/list/step_candidates = list()
			for(var/cardinal_dir in GLOB.cardinals)
				var/turf/next_turf = get_step(current_turf, cardinal_dir)
				if(!next_turf || !area_lookup[next_turf] || next_turf == current_turf)
					continue
				if(!can_relocate_target_to_turf(target, next_turf))
					continue
				step_candidates += next_turf

			var/turf/next_turf = length(step_candidates) ? pick(step_candidates) : null
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
