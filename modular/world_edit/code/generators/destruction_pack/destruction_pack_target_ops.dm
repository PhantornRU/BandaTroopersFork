/datum/world_edit_generator/destruction_pack/proc/get_chebyshev_distance(turf/source_turf, turf/target_turf)
	if(!istype(source_turf) || !istype(target_turf) || source_turf.z != target_turf.z)
		return WORLD_EDIT_PLACEMENT_MAX_TOTAL_PLACEMENTS
	return max(abs(source_turf.x - target_turf.x), abs(source_turf.y - target_turf.y))

/datum/world_edit_generator/destruction_pack/proc/get_influence_band(normalized_weight)
	if(normalized_weight >= 0.67)
		return "core"
	if(normalized_weight >= 0.34)
		return "mid"
	return "outer"

/datum/world_edit_generator/destruction_pack/proc/build_shape_center_turf(list/seed_turfs)
	if(!islist(seed_turfs) || !length(seed_turfs))
		return null

	var/turf/reference_turf = seed_turfs[1]
	if(!istype(reference_turf))
		return null

	var/min_x = reference_turf.x
	var/max_x = reference_turf.x
	var/min_y = reference_turf.y
	var/max_y = reference_turf.y
	for(var/turf/seed_turf as anything in seed_turfs)
		if(!istype(seed_turf))
			continue
		min_x = min(min_x, seed_turf.x)
		max_x = max(max_x, seed_turf.x)
		min_y = min(min_y, seed_turf.y)
		max_y = max(max_y, seed_turf.y)

	var/turf/center_turf = locate(round((min_x + max_x) / 2), round((min_y + max_y) / 2), reference_turf.z)
	if(istype(center_turf))
		return center_turf

	return seed_turfs[clamp(round((length(seed_turfs) + 1) / 2), 1, length(seed_turfs))]

/datum/world_edit_generator/destruction_pack/proc/build_influence_map(list/seed_turfs, radius, list/radius_policy = null)
	var/list/result = list(
		"turfs" = list(),
		"lookup" = list(),
		"seed_turfs" = list(),
		"band_counts" = list(
			"core" = 0,
			"mid" = 0,
			"outer" = 0,
		),
	)
	if(!islist(seed_turfs) || !length(seed_turfs) || radius < 1)
		return result

	var/turf/reference_turf = null
	var/list/unique_seed_lookup = list()
	var/list/unique_seed_turfs = result["seed_turfs"]
	for(var/turf/seed_turf as anything in seed_turfs)
		if(!istype(seed_turf))
			continue
		if(!istype(reference_turf))
			reference_turf = seed_turf
		if(seed_turf.z != reference_turf.z)
			continue
		if(unique_seed_lookup[seed_turf])
			continue
		unique_seed_lookup[seed_turf] = TRUE
		unique_seed_turfs += seed_turf

	if(!length(unique_seed_turfs))
		return result

	var/list/raw_candidate_lookup = list()
	var/list/raw_candidate_turfs = list()
	for(var/turf/seed_turf as anything in unique_seed_turfs)
		for(var/turf/target_turf in range(radius, seed_turf))
			if(target_turf.z != seed_turf.z)
				continue

			var/distance = get_chebyshev_distance(seed_turf, target_turf)
			if(distance > radius || raw_candidate_lookup[target_turf])
				continue

			raw_candidate_lookup[target_turf] = TRUE
			raw_candidate_turfs += target_turf

	var/list/filtered_turfs = GLOB.world_edit_helpers.filter_radius_candidate_turfs(
		unique_seed_turfs,
		raw_candidate_turfs,
		raw_candidate_turfs,
		radius_policy,
		unique_seed_turfs,
	)
	var/list/filtered_lookup = list()
	for(var/turf/filtered_turf as anything in filtered_turfs)
		if(istype(filtered_turf))
			filtered_lookup[filtered_turf] = TRUE

	var/list/influence_lookup = result["lookup"]
	for(var/turf/seed_turf as anything in unique_seed_turfs)
		for(var/turf/target_turf in range(radius, seed_turf))
			if(target_turf.z != seed_turf.z)
				continue

			var/distance = get_chebyshev_distance(seed_turf, target_turf)
			if(distance > radius || !filtered_lookup[target_turf])
				continue

			var/list/existing_info = influence_lookup[target_turf]
			if(islist(existing_info) && distance >= text2num("[existing_info["distance"]]"))
				continue

			var/normalized_weight = (radius - distance + 1) / (radius + 1)
			influence_lookup[target_turf] = list(
				"distance" = distance,
				"normalized_weight" = normalized_weight,
				"band" = get_influence_band(normalized_weight),
				"seed_turf" = seed_turf,
			)

	var/list/influence_turfs = result["turfs"]
	var/list/band_counts = result["band_counts"]
	for(var/turf/influence_turf as anything in influence_lookup)
		var/list/influence_info = influence_lookup[influence_turf]
		var/band = "[influence_info["band"]]"
		influence_turfs += influence_turf
		band_counts[band] = (band_counts[band] || 0) + 1

	result["center_turf"] = build_shape_center_turf(unique_seed_turfs)
	result["shape_seed_count"] = length(unique_seed_turfs)
	result["shape_footprint_count"] = length(unique_seed_turfs)
	result["influence_tile_count"] = length(influence_turfs)
	result["radius_policy"] = islist(radius_policy) ? radius_policy.Copy() : GLOB.world_edit_helpers.get_world_edit_radius_policy(radius_policy)
	return result

/datum/world_edit_generator/destruction_pack/proc/build_area_lookup(list/area_turfs)
	var/list/area_lookup = list()
	for(var/turf/target_turf as anything in area_turfs)
		area_lookup[target_turf] = TRUE
	return area_lookup

/datum/world_edit_generator/destruction_pack/proc/build_plan_seed(list/params, list/seed_turfs)
	var/seed = 17
	seed = (seed * 37) + (text2num("[params["radius"]]") || 0)
	seed = (seed * 37) + (text2num("[params["max_atoms"]]") || 0)
	seed = (seed * 37) + (text2num("[params["scatter_steps"]]") || 0)
	seed = (seed * 37) + (GLOB.world_edit_helpers.parse_bool(params["shuffle_enabled"]) ? 1 : 0)
	seed = (seed * 37) + (GLOB.world_edit_helpers.parse_bool(params["scatter_enabled"]) ? 1 : 0)
	seed = (seed * 37) + (GLOB.world_edit_helpers.parse_bool(params["persistent_fire_enabled"]) ? 1 : 0)
	seed = (seed * 37) + (GLOB.world_edit_helpers.parse_bool(params["blast_enabled"]) ? 1 : 0)
	seed = (seed * 37) + normalize_persistent_fire_density_percent(params["persistent_fire_density"])
	seed = (seed * 37) + (text2num("[params["blast_power"]]") || 0)
	seed = (seed * 37) + (text2num("[params["blast_falloff"]]") || 0)
	seed = (seed * 37) + (resolve_damage_profile(params["damage_profile"]) == "collapse" ? 2 : resolve_damage_profile(params["damage_profile"]) == "ruin" ? 1 : 0)
	seed = mix_text_plan_seed(seed, resolve_persistent_fire_mode(params["persistent_fire_mode"]) || get_default_persistent_fire_mode())
	seed = mix_text_plan_seed(seed, resolve_persistent_fire_color_id(params["persistent_fire_color"]) || get_default_persistent_fire_color_id())
	seed = mix_text_plan_seed(seed, trim(sanitize_text(params["persistent_fire_custom_color"], "")))

	for(var/turf/seed_turf as anything in seed_turfs)
		if(!istype(seed_turf))
			continue
		seed = (seed * 131) + (seed_turf.x * 17) + (seed_turf.y * 19) + (seed_turf.z * 23)

	return round(abs(seed))

/datum/world_edit_generator/destruction_pack/proc/mix_text_plan_seed(seed, value)
	var/text_value = "[value]"
	if(!length(text_value) || text_value == "null")
		return seed

	for(var/i in 1 to length(text_value))
		seed = (seed * 131) + text2ascii(text_value, i)
	return seed

/datum/world_edit_generator/destruction_pack/proc/get_deterministic_turf_score(plan_seed, turf/target_turf, salt = 0)
	if(!istype(target_turf))
		return 0

	var/value = round(abs(plan_seed))
	value ^= (round(abs(salt)) * 1013904223)
	value ^= (target_turf.x * 374761393)
	value ^= (target_turf.y * 668265263)
	value ^= (target_turf.z * 2147483647)
	value ^= (value >> 13)
	value *= 1274126177
	value ^= (value >> 16)
	value = round(abs(value))
	return ((value % 1000000) + 1) / 1000001

/datum/world_edit_generator/destruction_pack/proc/get_influence_weight_for_turf(list/influence_lookup, turf/target_turf)
	var/list/influence_info = islist(influence_lookup) ? influence_lookup[target_turf] : null
	if(!islist(influence_info))
		return 0
	return text2num("[influence_info["normalized_weight"]]") || 0

/datum/world_edit_generator/destruction_pack/proc/get_balanced_influence_selection_weight(normalized_weight)
	normalized_weight = clamp(normalized_weight, 0, 1)
	if(normalized_weight <= 0)
		return 0
	return max(sqrt(normalized_weight), 0.2)

/datum/world_edit_generator/destruction_pack/proc/pick_weighted_turf(list/candidates, list/influence_lookup, plan_seed, salt = 0)
	if(!length(candidates))
		return null

	var/turf/best_turf = null
	var/best_score = -1
	var/index = 0
	for(var/turf/candidate_turf as anything in candidates)
		if(!istype(candidate_turf))
			continue

		index++
		var/weight = get_balanced_influence_selection_weight(get_influence_weight_for_turf(influence_lookup, candidate_turf))
		if(weight <= 0)
			continue

		var/random_roll = max(get_deterministic_turf_score(plan_seed, candidate_turf, salt + index), 0.0001)
		var/score = random_roll ** (1 / weight)
		if(score <= best_score)
			continue

		best_score = score
		best_turf = candidate_turf

	return best_turf

/datum/world_edit_generator/destruction_pack/proc/build_weighted_turf_subset(list/candidates, list/influence_lookup, fill_ratio, plan_seed, salt = 0)
	var/list/selected_turfs = list()
	if(!islist(candidates) || !length(candidates) || fill_ratio <= 0)
		return selected_turfs
	if(fill_ratio >= 1)
		return candidates.Copy()

	var/target_count = clamp(round(length(candidates) * fill_ratio), 1, length(candidates))
	var/list/pool = candidates.Copy()
	while(length(selected_turfs) < target_count && length(pool))
		var/turf/selected_turf = pick_weighted_turf(pool, influence_lookup, plan_seed, salt + (length(selected_turfs) * 97))
		if(!istype(selected_turf))
			break
		pool -= selected_turf
		selected_turfs += selected_turf
	return selected_turfs

/datum/world_edit_generator/destruction_pack/proc/should_skip_target(atom/movable/target, affect_anchored = FALSE)
	if(!target || QDELETED(target))
		return TRUE
	if(ismob(target))
		return TRUE
	if(target.anchored && !affect_anchored)
		return TRUE
	if(istype(target, /atom/movable/screen))
		return TRUE
	if(istype(target, /obj/effect/world_edit_persistent_fire))
		return TRUE
	if(istype(target, /obj/structure))
		return TRUE
	if(istype(target, /obj/structure/machinery))
		return TRUE
	if(istype(target, /obj/docking_port))
		return TRUE
	if(length(target.contents))
		return TRUE
	if(ismob(target.loc))
		return TRUE
	if(!isturf(target.loc))
		return TRUE
	return FALSE

/datum/world_edit_generator/destruction_pack/proc/can_relocate_target_to_turf(atom/movable/target, turf/target_turf)
	if(!target || QDELETED(target) || !istype(target_turf))
		return FALSE
	if(target_turf.density)
		return FALSE

	for(var/atom/blocker as anything in target_turf)
		if(blocker == target || QDELETED(blocker))
			continue
		if(ismob(blocker))
			return FALSE
		if(istype(blocker, /obj/structure))
			return FALSE
		if(istype(blocker, /obj/structure/machinery))
			return FALSE
		if(istype(blocker, /obj/docking_port))
			return FALSE
		if(blocker.density)
			return FALSE

	return TRUE

/datum/world_edit_generator/destruction_pack/proc/collect_targets(list/area_turfs, affect_anchored = FALSE)
	var/list/targets = list()
	if(!length(area_turfs))
		return targets
	for(var/turf/target_turf as anything in area_turfs)
		for(var/atom/movable/target as anything in target_turf)
			if(should_skip_target(target, affect_anchored))
				continue
			targets += target
	return targets
