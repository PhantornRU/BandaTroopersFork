/datum/world_edit_generator/outpost_radius/proc/build_centered_opening_range(center_offset, opening_width, radius)
	if(opening_width <= 0)
		return null
	var/start_offset = center_offset - ((opening_width - 1) / 2)
	if((opening_width % 2) == 0)
		start_offset = center_offset - (opening_width / 2)
	start_offset = max(round(start_offset), -radius)
	var/end_offset = min(start_offset + opening_width - 1, radius)
	start_offset = max(end_offset - opening_width + 1, -radius)
	return list(
		"start" = start_offset,
		"end" = end_offset,
	)

/datum/world_edit_generator/outpost_radius/proc/build_split_pair_opening_ranges(radius, opening_width)
	if(opening_width <= 0)
		return list()
	var/span = (radius * 2) + 1
	if(span < opening_width * 2)
		return list(build_centered_opening_range(0, opening_width, radius))

	var/separation = max(round(radius / 2), 1)
	var/list/left_range = build_centered_opening_range(-separation, opening_width, radius)
	var/list/right_range = build_centered_opening_range(separation, opening_width, radius)
	if(left_range["end"] >= right_range["start"])
		return list(build_centered_opening_range(0, opening_width, radius))
	return list(left_range, right_range)

/datum/world_edit_generator/outpost_radius/proc/build_point_opening_ranges(dir_to_use, radius, list/layout_profile)
	var/list/opening_dirs = get_layout_opening_dirs(layout_profile)
	if(!islist(opening_dirs) || !(dir_to_use in opening_dirs))
		return list()

	var/opening_width = get_layout_opening_width(layout_profile)
	if(opening_width <= 0)
		return list()
	var/slot_mode = get_layout_opening_slot_mode(layout_profile)
	var/slots_per_dir = get_layout_opening_slots_per_dir(layout_profile)
	if(slot_mode == "split_pair" && slots_per_dir >= 2)
		return build_split_pair_opening_ranges(radius, opening_width)
	return list(build_centered_opening_range(0, opening_width, radius))

/datum/world_edit_generator/outpost_radius/proc/is_offset_in_opening_ranges(offset_value, list/opening_ranges)
	if(!islist(opening_ranges))
		return FALSE
	for(var/list/range_data as anything in opening_ranges)
		if(!islist(range_data))
			continue
		if(offset_value >= range_data["start"] && offset_value <= range_data["end"])
			return TRUE
	return FALSE

/datum/world_edit_generator/outpost_radius/proc/is_perimeter_opening_slot(dir_to_use, offset_x, offset_y, list/layout_profile, radius)
	var/list/opening_ranges = build_point_opening_ranges(dir_to_use, radius, layout_profile)
	if(!length(opening_ranges))
		return FALSE

	switch(dir_to_use)
		if(NORTH, SOUTH)
			return is_offset_in_opening_ranges(offset_x, opening_ranges)
		if(EAST, WEST)
			return is_offset_in_opening_ranges(offset_y, opening_ranges)

	return FALSE

/datum/world_edit_generator/outpost_radius/proc/select_barricade_path_for_slot(list/barricade_cycle, slot_index, radius, barricade_pattern = "uniform")
	if(!islist(barricade_cycle) || !length(barricade_cycle))
		return null

	if(length(barricade_cycle) <= 1 || barricade_pattern == "uniform")
		return barricade_cycle[1]

	var/effective_slot_index = slot_index
	if(barricade_pattern == "alternating")
		barricade_pattern = "cycle"
	if(barricade_pattern == "paired")
		effective_slot_index = round((slot_index + 1) / 2)

	var/cycle_index = ((effective_slot_index + max(radius, 1) - 1) % length(barricade_cycle)) + 1
	return barricade_cycle[cycle_index]

/datum/world_edit_generator/outpost_radius/proc/get_primary_material_share_percent(raw_value)
	var/percent = text2num("[raw_value]")
	if(!isnum(percent))
		return 100
	return clamp(round(percent), 0, 100)


/datum/world_edit_generator/outpost_radius/proc/get_folding_barricade_path(barricade_path)
	switch(barricade_path)
		if(/datum/human_ai_defense/barricade/metal)
			return /datum/human_ai_defense/barricade/metal_folding
		if(/datum/human_ai_defense/barricade/metal/wired)
			return /datum/human_ai_defense/barricade/metal_folding/wired
		if(/datum/human_ai_defense/barricade/plasteel)
			return /datum/human_ai_defense/barricade/plasteel_folding
		if(/datum/human_ai_defense/barricade/plasteel/wired)
			return /datum/human_ai_defense/barricade/plasteel_folding/wired
	return null

/datum/world_edit_generator/outpost_radius/proc/get_wired_barricade_path(barricade_path)
	switch(barricade_path)
		if(/datum/human_ai_defense/barricade/metal)
			return /datum/human_ai_defense/barricade/metal/wired
		if(/datum/human_ai_defense/barricade/plasteel)
			return /datum/human_ai_defense/barricade/plasteel/wired
	return null

/datum/world_edit_generator/outpost_radius/proc/build_outpost_slot_key(list/candidate_slot)
	if(!islist(candidate_slot))
		return null

	var/turf/target_turf = candidate_slot["turf"]
	return GLOB.world_edit_helpers.build_turf_dir_slot_key(target_turf, candidate_slot["dir"])

/datum/world_edit_generator/outpost_radius/proc/get_outpost_slot_order_coord(list/candidate_slot)
	if(!islist(candidate_slot))
		return 0

	if(!isnull(candidate_slot["offset_x"]) && !isnull(candidate_slot["offset_y"]))
		switch(candidate_slot["dir"])
			if(NORTH)
				return candidate_slot["offset_x"]
			if(EAST)
				return -candidate_slot["offset_y"]
			if(SOUTH)
				return -candidate_slot["offset_x"]
			if(WEST)
				return candidate_slot["offset_y"]

	var/turf/target_turf = candidate_slot["turf"]
	if(!istype(target_turf))
		return text2num("[candidate_slot["slot_index"]]") || 0

	switch(candidate_slot["dir"])
		if(NORTH)
			return target_turf.x
		if(EAST)
			return -target_turf.y
		if(SOUTH)
			return -target_turf.x
		if(WEST)
			return target_turf.y
	return text2num("[candidate_slot["slot_index"]]") || 0

/datum/world_edit_generator/outpost_radius/proc/build_canonical_outpost_slot_order(list/candidate_slots)
	var/list/ordered_slots = list()
	if(!islist(candidate_slots) || !length(candidate_slots))
		return ordered_slots

	for(var/dir_to_use as anything in list(NORTH, EAST, SOUTH, WEST))
		var/list/dir_candidates = list()
		for(var/list/candidate_slot as anything in candidate_slots)
			if(candidate_slot["dir"] == dir_to_use)
				dir_candidates += list(candidate_slot)

		var/safety_iterations = 0
		var/max_iterations = length(dir_candidates) + 4
		while(length(dir_candidates))
			safety_iterations++
			if(safety_iterations > max_iterations)
				log_world("WORLD EDIT OUTPOST: canonical slot ordering stopped after failing to consume candidates for dir=[dir_to_use].")
				break

			var/list/best_slot = null
			var/best_coord = null
			var/best_slot_index = null
			var/best_index = null
			for(var/i in 1 to length(dir_candidates))
				var/list/candidate_slot = dir_candidates[i]
				if(!islist(candidate_slot))
					continue
				var/coord_value = get_outpost_slot_order_coord(candidate_slot)
				var/current_slot_index = text2num("[candidate_slot["slot_index"]]") || 0
				if(isnull(best_coord) || coord_value < best_coord || (coord_value == best_coord && current_slot_index < best_slot_index))
					best_slot = candidate_slot
					best_coord = coord_value
					best_slot_index = current_slot_index
					best_index = i

			if(!islist(best_slot) || isnull(best_index))
				break

			ordered_slots += list(best_slot)
			dir_candidates.Cut(best_index, best_index + 1)

	return ordered_slots

/datum/world_edit_generator/outpost_radius/proc/get_outpost_slot_opening_distance(list/candidate_slot, list/opening_turfs)
	var/turf/target_turf = islist(candidate_slot) ? candidate_slot["turf"] : null
	if(!istype(target_turf) || !islist(opening_turfs) || !length(opening_turfs))
		return null

	var/min_distance = null
	for(var/turf/opening_turf as anything in opening_turfs)
		if(!istype(opening_turf) || opening_turf.z != target_turf.z)
			continue
		var/distance = max(abs(target_turf.x - opening_turf.x), abs(target_turf.y - opening_turf.y))
		if(isnull(min_distance) || distance < min_distance)
			min_distance = distance

	return min_distance

/datum/world_edit_generator/outpost_radius/proc/build_outpost_pattern_primary_lookup(list/ordered_slots, barricade_pattern)
	var/list/primary_lookup = list()
	if(!islist(ordered_slots) || !length(ordered_slots))
		return primary_lookup

	barricade_pattern = resolve_barricade_pattern(barricade_pattern, null) || "uniform"
	var/index = 1
	for(var/list/slot_data as anything in ordered_slots)
		var/slot_key = slot_data["slot_key"] || build_outpost_slot_key(slot_data)
		if(!length(slot_key))
			index++
			continue

		var/is_primary = TRUE
		switch(barricade_pattern)
			if("paired")
				is_primary = (((round((index + 1) / 2) - 1) % 2) == 0)
			if("alternating")
				is_primary = ((index % 2) == 1)
			else
				is_primary = TRUE

		if(is_primary)
			primary_lookup[slot_key] = TRUE
		index++

	return primary_lookup

/datum/world_edit_generator/outpost_radius/proc/build_outpost_primary_slot_lookup(list/barricade_slots, list/opening_turfs, primary_target_count, list/pattern_primary_lookup = null)
	var/list/primary_lookup = list()
	if(!islist(barricade_slots) || !length(barricade_slots) || primary_target_count <= 0)
		return primary_lookup

	var/list/ordered_slots = build_canonical_outpost_slot_order(barricade_slots)
	while(length(primary_lookup) < primary_target_count)
		var/list/best_slot = null
		var/best_pref_score = null
		var/best_distance = null
		var/best_order = null

		for(var/list/candidate_slot as anything in ordered_slots)
			var/slot_key = candidate_slot["slot_key"] || build_outpost_slot_key(candidate_slot)
			if(!length(slot_key) || primary_lookup[slot_key])
				continue

			var/pref_score = (islist(pattern_primary_lookup) && pattern_primary_lookup[slot_key]) ? 0 : 1
			var/opening_distance = get_outpost_slot_opening_distance(candidate_slot, opening_turfs)
			if(isnull(opening_distance))
				opening_distance = 1000
			var/order_index = candidate_slot["canonical_index"]
			if(isnull(order_index))
				order_index = candidate_slot["slot_index"]
			if(isnull(order_index))
				order_index = 0

			if(isnull(best_pref_score) || pref_score < best_pref_score || (pref_score == best_pref_score && opening_distance < best_distance) || (pref_score == best_pref_score && opening_distance == best_distance && order_index < best_order))
				best_slot = candidate_slot
				best_pref_score = pref_score
				best_distance = opening_distance
				best_order = order_index

		if(!islist(best_slot))
			break

		var/best_slot_key = best_slot["slot_key"] || build_outpost_slot_key(best_slot)
		if(length(best_slot_key))
			primary_lookup[best_slot_key] = TRUE

	return primary_lookup

/datum/world_edit_generator/outpost_radius/proc/resolve_outpost_lane_door_path(door_selection, source_material_path)
	if(ispath(door_selection, /datum/human_ai_defense/barricade))
		return list("path" = door_selection)

	switch("[door_selection]")
		if("none")
			return list("path" = null, "mode" = "none")
		else
			var/folding_path = get_folding_barricade_path(source_material_path)
			if(folding_path)
				return list("path" = folding_path)
			return list("path" = null, "mode" = "unsupported")

/datum/world_edit_generator/outpost_radius/proc/build_outpost_perimeter_result(list/candidate_slots, radius, primary_material_path, secondary_material_path, barricade_pattern, primary_material_share_percent = 100, place_barricade_doors = FALSE, primary_door_path = "follow_material", secondary_door_path = "follow_material", list/wired_slot_lookup = null)
	var/list/result = list(
		"placements" = list(),
		"openings" = list(),
		"blocked_count" = 0,
		"blocked_barricades" = 0,
		"blocked_openings" = 0,
		"opening_count" = 0,
		"planned_opening_count" = 0,
		"door_count" = 0,
		"unsupported_door_openings" = 0,
		"blocked_door_openings" = 0,
		"dominant_barricade_count" = 0,
		"primary_material_count" = 0,
		"secondary_material_count" = 0,
		"wired_conversion_count" = 0,
		"unsupported_wired_conversions" = 0,
	)
	if(!islist(candidate_slots) || !length(candidate_slots))
		return result

	var/list/slot_lookup = list()
	var/list/barricade_slots = list()
	var/list/opening_slots = list()
	var/list/blocked_opening_slots = list()
	var/list/ordered_slots = list()
	var/list/opening_turfs = list()
	var/list/opening_turf_lookup = list()

	for(var/list/candidate_slot as anything in candidate_slots)
		var/turf/target_turf = candidate_slot["turf"]
		var/dir_to_use = candidate_slot["dir"]
		var/slot_key = candidate_slot["slot_key"] || build_outpost_slot_key(candidate_slot)
		if(!length(slot_key) || slot_lookup[slot_key])
			continue
		slot_lookup[slot_key] = TRUE

		var/list/slot_data = candidate_slot.Copy()
		slot_data["slot_key"] = slot_key
		slot_data["slot_index"] = slot_data["slot_index"] || 1
		slot_data["is_opening"] = slot_data["is_opening"] ? TRUE : FALSE
		ordered_slots += list(slot_data)

		if(slot_data["is_opening"])
			result["planned_opening_count"]++
			if(istype(target_turf) && !opening_turf_lookup[target_turf])
				opening_turf_lookup[target_turf] = TRUE
				opening_turfs += target_turf
			if(can_place_barricade_on_turf(target_turf, dir_to_use))
				result["opening_count"]++
				opening_slots += list(slot_data)
				result["openings"] += list(slot_data.Copy())
			else
				result["blocked_count"]++
				result["blocked_openings"]++
				blocked_opening_slots += list(slot_data)
			continue

		if(can_place_barricade_on_turf(target_turf, dir_to_use))
			barricade_slots += list(slot_data)
			continue

		result["blocked_count"]++
		result["blocked_barricades"]++

	var/use_secondary_material = ispath(secondary_material_path, /datum/human_ai_defense/barricade) && secondary_material_path != primary_material_path
	barricade_pattern = resolve_barricade_pattern(barricade_pattern, null) || "uniform"
	if(!use_secondary_material || barricade_pattern == "uniform")
		primary_material_share_percent = 100

	var/list/ordered_barricade_slots = build_canonical_outpost_slot_order(barricade_slots)
	var/canonical_index = 1
	for(var/list/slot_data as anything in ordered_barricade_slots)
		slot_data["canonical_index"] = canonical_index++

	var/list/pattern_primary_lookup = build_outpost_pattern_primary_lookup(ordered_barricade_slots, barricade_pattern)
	var/primary_target_count = clamp(round(length(ordered_barricade_slots) * get_primary_material_share_percent(primary_material_share_percent) / 100), 0, length(ordered_barricade_slots))
	if(!use_secondary_material)
		primary_target_count = length(ordered_barricade_slots)
	var/list/primary_slot_lookup = build_outpost_primary_slot_lookup(ordered_barricade_slots, opening_turfs, primary_target_count, pattern_primary_lookup)
	var/list/opening_pattern_lookup = build_outpost_pattern_primary_lookup(build_canonical_outpost_slot_order(ordered_slots), barricade_pattern)

	if(place_barricade_doors)
		for(var/list/blocked_opening_slot as anything in blocked_opening_slots)
			var/opening_slot_key = blocked_opening_slot["slot_key"] || build_outpost_slot_key(blocked_opening_slot)
			var/use_primary_lane = !use_secondary_material || barricade_pattern == "uniform" || opening_pattern_lookup[opening_slot_key]
			var/source_material_path = use_primary_lane ? primary_material_path : secondary_material_path
			var/door_selection = use_primary_lane ? primary_door_path : secondary_door_path
			var/list/door_resolution = resolve_outpost_lane_door_path(door_selection, source_material_path)
			if(ispath(door_resolution["path"], /datum/human_ai_defense/barricade))
				result["blocked_door_openings"]++

	for(var/list/barricade_slot as anything in ordered_barricade_slots)
		var/slot_key = barricade_slot["slot_key"]
		var/use_primary_lane = !use_secondary_material || primary_slot_lookup[slot_key]
		var/barricade_path = use_primary_lane ? primary_material_path : secondary_material_path
		if(use_primary_lane)
			result["dominant_barricade_count"]++
			result["primary_material_count"]++
		else
			result["secondary_material_count"]++

		if(islist(wired_slot_lookup) && wired_slot_lookup[slot_key])
			var/wired_path = get_wired_barricade_path(barricade_path)
			if(wired_path)
				barricade_path = wired_path
				result["wired_conversion_count"]++
			else
				result["unsupported_wired_conversions"]++

		result["placements"] += list(list(
			"turf" = barricade_slot["turf"],
			"dir" = barricade_slot["dir"],
			"barricade_path" = barricade_path,
			"slot_index" = barricade_slot["slot_index"],
			"canonical_index" = barricade_slot["canonical_index"],
			"uses_primary_material" = use_primary_lane ? TRUE : FALSE,
		))

	if(place_barricade_doors)
		for(var/list/opening_slot as anything in opening_slots)
			var/opening_slot_key = opening_slot["slot_key"] || build_outpost_slot_key(opening_slot)
			var/use_primary_lane = !use_secondary_material || barricade_pattern == "uniform" || opening_pattern_lookup[opening_slot_key]
			var/source_material_path = use_primary_lane ? primary_material_path : secondary_material_path
			var/door_selection = use_primary_lane ? primary_door_path : secondary_door_path
			var/list/door_resolution = resolve_outpost_lane_door_path(door_selection, source_material_path)
			var/folding_barricade_path = door_resolution["path"]
			if(!ispath(folding_barricade_path, /datum/human_ai_defense/barricade))
				if("[door_resolution["mode"]]" == "unsupported")
					result["unsupported_door_openings"]++
				continue

			result["door_count"]++
			result["placements"] += list(list(
				"turf" = opening_slot["turf"],
				"dir" = opening_slot["dir"],
				"barricade_path" = folding_barricade_path,
				"slot_index" = opening_slot["slot_index"],
				"is_barricade_door" = TRUE,
				"source_barricade_path" = source_material_path,
				"uses_primary_material" = use_primary_lane ? TRUE : FALSE,
			))

	return result

/datum/world_edit_generator/outpost_radius/proc/populate_outpost_recipe_metadata(list/metadata, list/config)
	if(!islist(metadata) || !islist(config))
		return

	var/primary_material_share_percent = text2num("[config["primary_material_share_percent"]]")
	if(!isnum(primary_material_share_percent))
		primary_material_share_percent = 100

	metadata["defense_profile"] = config["defense_profile"]
	metadata["layout_variant"] = config["layout_variant"]
	metadata["placement_dir"] = config["placement_dir"]
	metadata["radius"] = config["radius"]
	metadata["opening_width"] = config["opening_width"]
	metadata["primary_material_path"] = config["primary_material_path"]
	metadata["secondary_material_path"] = config["secondary_material_path"]
	metadata["primary_door_path"] = ispath(config["primary_door_path"], /datum/human_ai_defense/barricade) ? "[config["primary_door_path"]]" : "[config["primary_door_path"] || "follow_material"]"
	metadata["secondary_door_path"] = ispath(config["secondary_door_path"], /datum/human_ai_defense/barricade) ? "[config["secondary_door_path"]]" : "[config["secondary_door_path"] || "follow_material"]"
	metadata["barricade_pattern"] = config["barricade_pattern"]
	metadata["primary_material_share_percent"] = primary_material_share_percent
	metadata["place_barricade_doors"] = config["place_barricade_doors"] ? TRUE : FALSE
	metadata["faction"] = config["faction"]
	metadata["turned_on"] = config["turned_on"] ? TRUE : FALSE
	metadata["sentry_layer_profile"] = config["sentry_layer_profile"]
	metadata["sentry_type"] = config["sentry_type"]
	metadata["extra_defense_layer_profile"] = config["extra_defense_layer_profile"]
	metadata["extra_defense_type"] = config["extra_defense_type"]
	metadata["flag_type"] = config["flag_type"]
	metadata["wire_layer_profile"] = config["wire_layer_profile"]
	metadata["wire_offset"] = config["wire_offset"]
	metadata["wire_rows"] = config["wire_rows"]
	metadata["wire_row_step"] = config["wire_row_step"]
	metadata["wire_spacing"] = config["wire_spacing"]
	metadata["wire_concentration_percent"] = config["wire_concentration_percent"]
	metadata["minefield_profile"] = config["minefield_profile"]
	metadata["mine_type"] = config["mine_type"]
	metadata["minefield_offset"] = config["minefield_offset"]
	metadata["minefield_depth"] = config["minefield_depth"]
	metadata["minefield_density_percent"] = config["minefield_density_percent"]
	metadata["minefield_seed"] = config["minefield_seed"]

/datum/world_edit_generator/outpost_radius/proc/build_outpost_anchor_candidate(turf/target_turf, dir_to_use, group_id, source_dir = null, source_turf = null)
	if(!istype(target_turf))
		return null

	return list(
		"turf" = target_turf,
		"dir" = dir_to_use,
		"group" = group_id,
		"source_dir" = source_dir || dir_to_use,
		"source_turf" = source_turf,
	)

/datum/world_edit_generator/outpost_radius/proc/build_outpost_anchor_candidate_key(list/candidate, turf_only = FALSE)
	if(!islist(candidate))
		return null

	var/turf/target_turf = candidate["turf"]
	if(!istype(target_turf))
		return null
	if(turf_only)
		return "[target_turf.x],[target_turf.y],[target_turf.z]"
	return GLOB.world_edit_helpers.build_turf_dir_slot_key(target_turf, candidate["dir"])

/datum/world_edit_generator/outpost_radius/proc/add_outpost_anchor_candidate(list/group, list/lookup, list/candidate, turf_only = FALSE)
	if(!islist(group) || !islist(lookup) || !islist(candidate))
		return

	var/candidate_key = build_outpost_anchor_candidate_key(candidate, turf_only)
	if(!length(candidate_key) || lookup[candidate_key])
		return

	lookup[candidate_key] = TRUE
	group += list(candidate)

/datum/world_edit_generator/outpost_radius/proc/get_outpost_back_dir(placement_dir)
	return get_cardinal_opposite_dir(placement_dir)

/datum/world_edit_generator/outpost_radius/proc/get_outpost_deterministic_percent(turf/target_turf, seed_value = 0, salt = 0)
	if(!istype(target_turf))
		return 100
	var/raw_value = (target_turf.x * 73856093) + (target_turf.y * 19349663) + (target_turf.z * 83492791) + (round(text2num("[seed_value]") || 0) * 4435761) + (round(text2num("[salt]") || 0) * 97531)
	return abs(raw_value) % 100

/datum/world_edit_generator/outpost_radius/proc/get_outpost_layer_candidate_salt(list/candidate, salt_offset = 0)
	if(!islist(candidate))
		return salt_offset
	var/slot_index = round(text2num("[candidate["slot_index"]]") || 0)
	var/layer_depth = round(text2num("[candidate["layer_depth"]]") || 0)
	var/layer_row = round(text2num("[candidate["layer_row"]]") || 0)
	var/dir_value = round(text2num("[candidate["dir"]]") || 0)
	return salt_offset + (slot_index * 31) + (layer_depth * 131) + (layer_row * 197) + dir_value

/datum/world_edit_generator/outpost_radius/proc/get_outpost_layer_candidate_score(list/candidate, seed_value = 0, salt_offset = 0)
	var/turf/target_turf = islist(candidate) ? candidate["turf"] : null
	if(!istype(target_turf))
		return -1
	return get_outpost_deterministic_percent(target_turf, seed_value, get_outpost_layer_candidate_salt(candidate, salt_offset))

/datum/world_edit_generator/outpost_radius/proc/build_outpost_layer_candidate_key(list/candidate)
	var/key = build_outpost_anchor_candidate_key(candidate, TRUE)
	if(!length(key))
		return null
	return "[key]:[candidate["dir"]]:[candidate["layer_depth"]]:[candidate["layer_row"]]:[candidate["slot_index"]]"

/datum/world_edit_generator/outpost_radius/proc/is_outpost_layer_candidate_spaced(list/candidate, list/selected_turfs, min_spacing = 1)
	if(min_spacing <= 1)
		return TRUE
	var/turf/target_turf = islist(candidate) ? candidate["turf"] : null
	if(!istype(target_turf))
		return FALSE
	for(var/turf/selected_turf as anything in selected_turfs)
		if(!istype(selected_turf) || selected_turf.z != target_turf.z)
			continue
		if(max(abs(selected_turf.x - target_turf.x), abs(selected_turf.y - target_turf.y)) < min_spacing)
			return FALSE
	return TRUE

/datum/world_edit_generator/outpost_radius/proc/select_outpost_layer_candidates(list/candidates, seed_value = 0, density_percent = 100, min_spacing = 1, max_fill_percent = 100, salt_offset = 0)
	var/list/selected = list()
	if(!islist(candidates) || !length(candidates))
		return selected

	var/density = clamp(round(text2num("[density_percent]") || 0), 0, 100)
	if(density <= 0)
		return selected

	var/target_count = round(length(candidates) * density / 100)
	if(target_count <= 0)
		target_count = 1
	if(max_fill_percent > 0 && max_fill_percent < 100)
		target_count = min(target_count, max(round(length(candidates) * max_fill_percent / 100), 1))
	target_count = clamp(target_count, 0, length(candidates))
	if(target_count <= 0)
		return selected

	var/list/selected_turfs = list()
	var/list/selected_lookup = list()
	for(var/score_offset in 0 to 99)
		if(length(selected) >= target_count)
			break
		var/score_to_match = 99 - score_offset
		for(var/list/candidate as anything in candidates)
			if(length(selected) >= target_count)
				break
			if(!islist(candidate))
				continue
			var/candidate_key = build_outpost_layer_candidate_key(candidate)
			if(!length(candidate_key) || selected_lookup[candidate_key])
				continue
			if(get_outpost_layer_candidate_score(candidate, seed_value, salt_offset) != score_to_match)
				continue
			if(!is_outpost_layer_candidate_spaced(candidate, selected_turfs, min_spacing))
				continue
			selected_lookup[candidate_key] = TRUE
			selected += list(candidate)
			var/turf/target_turf = candidate["turf"]
			if(istype(target_turf))
				selected_turfs += target_turf

	return selected

/datum/world_edit_generator/outpost_radius/proc/select_outpost_wire_candidates(list/candidates, list/config)
	var/list/spaced_candidates = list()
	if(!islist(candidates) || !islist(config))
		return spaced_candidates

	var/concentration = clamp(round(text2num("[config["wire_concentration_percent"]]") || 0), 0, 100)
	if(concentration <= 0)
		return spaced_candidates

	var/spacing = max(round(text2num("[config["wire_spacing"]]") || 1), 1)
	for(var/list/candidate as anything in candidates)
		if(!islist(candidate))
			continue
		var/slot_index = max(round(text2num("[candidate["slot_index"]]") || 1), 1)
		var/row_index = max(round(text2num("[candidate["layer_row"]]") || 1), 1)
		if(spacing > 1)
			var/phase = get_outpost_layer_candidate_score(candidate, row_index, 300) % spacing
			if(((slot_index + phase - 1) % spacing) != 0)
				continue
		spaced_candidates += list(candidate)

	if(concentration >= 100)
		return spaced_candidates
	return select_outpost_layer_candidates(spaced_candidates, 0, concentration, 1, 100, 400)

/datum/world_edit_generator/outpost_radius/proc/select_outpost_mine_candidates(list/candidates, list/config)
	if(!islist(config))
		return list()
	var/density = clamp(round(text2num("[config["minefield_density_percent"]]") || 0), 0, 100)
	if(density <= 0)
		return list()
	var/min_spacing = density >= 15 ? 2 : 1
	var/max_fill_percent = density >= 100 ? 65 : 85
	return select_outpost_layer_candidates(candidates, config["minefield_seed"], density, min_spacing, max_fill_percent, 700)

/datum/world_edit_generator/outpost_radius/proc/build_opening_standoff_lookup(list/opening_turfs)
	var/list/lookup = list()
	if(!islist(opening_turfs))
		return lookup
	for(var/turf/opening_turf as anything in opening_turfs)
		if(!istype(opening_turf))
			continue
		lookup[opening_turf] = TRUE
		for(var/check_dir as anything in GLOB.alldirs)
			var/turf/adjacent_turf = get_step(opening_turf, check_dir)
			if(istype(adjacent_turf))
				lookup[adjacent_turf] = TRUE
	return lookup

/datum/world_edit_generator/outpost_radius/proc/build_opening_mine_clearance_lookup(list/opening_slots, minefield_offset = 3, minefield_depth = 0)
	var/list/lookup = list()
	if(!islist(opening_slots))
		return lookup

	var/max_distance = max(round(text2num("[minefield_offset]") || 3) + max(round(text2num("[minefield_depth]") || 0), 1) - 1, 1)
	for(var/list/opening_slot as anything in opening_slots)
		if(!islist(opening_slot))
			continue
		var/turf/opening_turf = opening_slot["turf"]
		var/opening_dir = opening_slot["dir"]
		if(!istype(opening_turf) || !GLOB.world_edit_helpers.is_cardinal_dir(opening_dir))
			continue
		for(var/distance in 0 to max_distance)
			var/turf/clearance_turf = GLOB.world_edit_helpers.step_turf(opening_turf, opening_dir, distance)
			if(istype(clearance_turf))
				lookup[clearance_turf] = TRUE
	return lookup

/datum/world_edit_generator/outpost_radius/proc/build_outpost_anchor_map(list/footprint_turfs, list/perimeter_slots, list/opening_slots, placement_dir, list/config = null)
	var/list/anchor_map = list(
		"perimeter_slots" = list(),
		"opening_slots" = list(),
		"opening_flanks" = list(),
		"guard_slots" = list(),
		"corner_slots" = list(),
		"outer_approach_slots" = list(),
		"exterior_wire_slots" = list(),
		"exterior_opening_wire_slots" = list(),
		"exterior_mine_slots" = list(),
		"exterior_opening_mine_slots" = list(),
		"rear_slots" = list(),
	)
	if(!islist(footprint_turfs))
		footprint_turfs = list()
	if(!islist(perimeter_slots))
		perimeter_slots = list()
	if(!islist(opening_slots))
		opening_slots = list()

	var/list/opening_turfs = list()
	var/list/opening_turf_lookup = list()
	var/list/opening_slot_lookup = list()
	var/list/group_lookups = list()
	for(var/group_id in anchor_map)
		group_lookups[group_id] = list()

	for(var/list/perimeter_slot as anything in perimeter_slots)
		add_outpost_anchor_candidate(anchor_map["perimeter_slots"], group_lookups["perimeter_slots"], perimeter_slot.Copy())

	for(var/list/opening_slot as anything in opening_slots)
		var/list/opening_candidate = opening_slot.Copy()
		add_outpost_anchor_candidate(anchor_map["opening_slots"], group_lookups["opening_slots"], opening_candidate.Copy())
		var/opening_slot_key = build_outpost_slot_key(opening_candidate)
		if(length(opening_slot_key))
			opening_slot_lookup[opening_slot_key] = TRUE

		var/turf/opening_turf = opening_candidate["turf"]
		if(istype(opening_turf) && !opening_turf_lookup[opening_turf])
			opening_turf_lookup[opening_turf] = TRUE
			opening_turfs += opening_turf

		var/opening_dir = opening_candidate["dir"]
		var/turf/source_turf = opening_candidate["source_turf"]
		if(!istype(source_turf))
			source_turf = GLOB.world_edit_helpers.step_turf(opening_turf, get_cardinal_opposite_dir(opening_dir), 1)
		var/turf/inward_turf = GLOB.world_edit_helpers.step_turf(opening_turf, get_cardinal_opposite_dir(opening_dir), 1)
		var/list/guard_candidate = build_outpost_anchor_candidate(inward_turf, opening_dir, "guard_slots", opening_dir, opening_turf)
		add_outpost_anchor_candidate(anchor_map["guard_slots"], group_lookups["guard_slots"], guard_candidate, TRUE)

		var/turf/approach_turf = GLOB.world_edit_helpers.step_turf(opening_turf, opening_dir, 1)
		var/list/approach_candidate = build_outpost_anchor_candidate(approach_turf, opening_dir, "outer_approach_slots", opening_dir, opening_turf)
		add_outpost_anchor_candidate(anchor_map["outer_approach_slots"], group_lookups["outer_approach_slots"], approach_candidate, TRUE)

		for(var/flank_turn as anything in list(90, -90))
			var/flank_dir = turn(opening_dir, flank_turn)
			var/turf/flank_turf = GLOB.world_edit_helpers.step_turf(source_turf, flank_dir, 1)
			var/turf/overlay_turf = GLOB.world_edit_helpers.step_turf(opening_turf, flank_dir, 1)
			var/list/flank_candidate = build_outpost_anchor_candidate(flank_turf, opening_dir, "opening_flanks", opening_dir, opening_turf)
			if(islist(flank_candidate) && istype(overlay_turf))
				flank_candidate["overlay_slot_key"] = GLOB.world_edit_helpers.build_turf_dir_slot_key(overlay_turf, opening_dir)
			add_outpost_anchor_candidate(anchor_map["opening_flanks"], group_lookups["opening_flanks"], flank_candidate, TRUE)

	var/list/footprint_lookup = build_turf_lookup(footprint_turfs)
	var/wire_rows = islist(config) ? max(round(text2num("[config["wire_rows"]]") || 0), 0) : 0
	var/wire_offset = islist(config) ? max(round(text2num("[config["wire_offset"]]") || 3), 1) : 3
	var/wire_row_step = islist(config) ? max(round(text2num("[config["wire_row_step"]]") || 1), 1) : 1
	var/minefield_depth = islist(config) ? max(round(text2num("[config["minefield_depth"]]") || 0), 0) : 0
	var/minefield_offset = islist(config) ? max(round(text2num("[config["minefield_offset"]]") || 3), 1) : 3
	var/list/opening_standoff_lookup = build_opening_standoff_lookup(opening_turfs)
	var/list/opening_mine_clearance_lookup = build_opening_mine_clearance_lookup(opening_slots, minefield_offset, minefield_depth)
	for(var/turf/standoff_turf as anything in opening_standoff_lookup)
		if(istype(standoff_turf))
			opening_mine_clearance_lookup[standoff_turf] = TRUE
	var/list/pending_wire_candidates = list()
	var/list/pending_mine_candidates = list()
	for(var/list/perimeter_slot as anything in perimeter_slots)
		var/turf/perimeter_turf = perimeter_slot["turf"]
		var/perimeter_dir = perimeter_slot["dir"]
		if(!istype(perimeter_turf) || !GLOB.world_edit_helpers.is_cardinal_dir(perimeter_dir))
			continue
		var/perimeter_slot_key = build_outpost_slot_key(perimeter_slot)
		var/is_opening_slot = (perimeter_slot["is_opening"] || opening_slot_lookup[perimeter_slot_key]) ? TRUE : FALSE

		if(wire_rows > 0)
			for(var/wire_row in 1 to wire_rows)
				var/wire_distance = wire_offset + ((wire_row - 1) * wire_row_step)
				var/turf/wire_turf = GLOB.world_edit_helpers.step_turf(perimeter_turf, perimeter_dir, wire_distance)
				var/list/wire_candidate = build_outpost_anchor_candidate(wire_turf, perimeter_dir, "exterior_wire_slots", perimeter_dir, perimeter_turf)
				if(islist(wire_candidate))
					wire_candidate["layer_offset"] = wire_distance
					wire_candidate["layer_row"] = wire_row
					wire_candidate["slot_index"] = perimeter_slot["slot_index"]
					wire_candidate["is_opening_slot"] = is_opening_slot
					pending_wire_candidates += list(wire_candidate)

		if(minefield_depth > 0)
			for(var/mine_depth in 1 to minefield_depth)
				var/mine_distance = minefield_offset + mine_depth - 1
				var/turf/mine_turf = GLOB.world_edit_helpers.step_turf(perimeter_turf, perimeter_dir, mine_distance)
				if(footprint_lookup[mine_turf] || opening_mine_clearance_lookup[mine_turf])
					continue
				var/list/mine_candidate = build_outpost_anchor_candidate(mine_turf, perimeter_dir, "exterior_mine_slots", perimeter_dir, perimeter_turf)
				if(islist(mine_candidate))
					mine_candidate["layer_offset"] = mine_distance
					mine_candidate["layer_depth"] = mine_depth
					mine_candidate["slot_index"] = perimeter_slot["slot_index"]
					mine_candidate["is_opening_slot"] = is_opening_slot
					pending_mine_candidates += list(mine_candidate)

	for(var/list/wire_candidate as anything in select_outpost_wire_candidates(pending_wire_candidates, config))
		add_outpost_anchor_candidate(anchor_map["exterior_wire_slots"], group_lookups["exterior_wire_slots"], wire_candidate, TRUE)
		if(wire_candidate["is_opening_slot"])
			var/list/opening_wire_candidate = wire_candidate.Copy()
			opening_wire_candidate["group"] = "exterior_opening_wire_slots"
			add_outpost_anchor_candidate(anchor_map["exterior_opening_wire_slots"], group_lookups["exterior_opening_wire_slots"], opening_wire_candidate, TRUE)

	for(var/list/mine_candidate as anything in select_outpost_mine_candidates(pending_mine_candidates, config))
		add_outpost_anchor_candidate(anchor_map["exterior_mine_slots"], group_lookups["exterior_mine_slots"], mine_candidate, TRUE)
		if(mine_candidate["is_opening_slot"])
			var/list/opening_mine_candidate = mine_candidate.Copy()
			opening_mine_candidate["group"] = "exterior_opening_mine_slots"
			add_outpost_anchor_candidate(anchor_map["exterior_opening_mine_slots"], group_lookups["exterior_opening_mine_slots"], opening_mine_candidate, TRUE)

	var/list/source_lookup = list()
	for(var/list/perimeter_slot as anything in perimeter_slots)
		var/turf/source_turf = perimeter_slot["source_turf"]
		if(!istype(source_turf))
			continue
		var/source_key = "[source_turf.x],[source_turf.y],[source_turf.z]"
		if(!islist(source_lookup[source_key]))
			source_lookup[source_key] = list()
		source_lookup[source_key] += list(perimeter_slot)

	for(var/source_key in source_lookup)
		var/list/source_slots = source_lookup[source_key]
		if(!islist(source_slots) || length(source_slots) < 2)
			continue
		for(var/list/perimeter_slot as anything in source_slots)
			var/turf/source_turf = perimeter_slot["source_turf"]
			var/list/corner_candidate = build_outpost_anchor_candidate(source_turf, perimeter_slot["dir"], "corner_slots", perimeter_slot["dir"], perimeter_slot["turf"])
			add_outpost_anchor_candidate(anchor_map["corner_slots"], group_lookups["corner_slots"], corner_candidate)

	var/rear_dir = get_outpost_back_dir(placement_dir)
	var/rear_metric = null
	for(var/turf/footprint_turf as anything in footprint_turfs)
		if(!istype(footprint_turf))
			continue

		var/current_metric = 0
		switch(rear_dir)
			if(NORTH)
				current_metric = footprint_turf.y
			if(SOUTH)
				current_metric = -footprint_turf.y
			if(EAST)
				current_metric = footprint_turf.x
			if(WEST)
				current_metric = -footprint_turf.x

		if(isnull(rear_metric) || current_metric < rear_metric)
			rear_metric = current_metric

	for(var/turf/footprint_turf as anything in footprint_turfs)
		if(!istype(footprint_turf))
			continue

		var/current_metric = 0
		switch(rear_dir)
			if(NORTH)
				current_metric = footprint_turf.y
			if(SOUTH)
				current_metric = -footprint_turf.y
			if(EAST)
				current_metric = footprint_turf.x
			if(WEST)
				current_metric = -footprint_turf.x
		if(current_metric != rear_metric)
			continue

		var/list/rear_candidate = build_outpost_anchor_candidate(footprint_turf, placement_dir, "rear_slots", rear_dir, null)
		add_outpost_anchor_candidate(anchor_map["rear_slots"], group_lookups["rear_slots"], rear_candidate, TRUE)

	return anchor_map

/datum/world_edit_generator/outpost_radius/proc/build_wired_anchor_lookup(list/anchor_map, list/wired_groups = null)
	var/list/wired_lookup = list()
	if(!islist(anchor_map) || !islist(wired_groups))
		return wired_lookup

	for(var/group_id as anything in wired_groups)
		var/list/group_entries = anchor_map["[group_id]"]
		if(!islist(group_entries))
			continue
		for(var/list/group_entry as anything in group_entries)
			var/slot_key = group_entry["overlay_slot_key"] || build_outpost_slot_key(group_entry)
			if(length(slot_key))
				wired_lookup[slot_key] = TRUE

	return wired_lookup

/datum/world_edit_generator/outpost_radius/proc/build_outpost_reserved_turf_lookup(list/placements)
	var/list/reserved_lookup = list()
	if(!islist(placements))
		return reserved_lookup

	for(var/list/placement as anything in placements)
		var/turf/target_turf = placement["turf"]
		if(istype(target_turf))
			reserved_lookup[target_turf] = TRUE
	return reserved_lookup

/datum/world_edit_generator/outpost_radius/proc/outpost_defense_profile_needs_anchor_map(list/defense_profile)
	if(!islist(defense_profile))
		return FALSE
	return (length(defense_profile["wired_groups"]) || length(defense_profile["defense_rules"])) ? TRUE : FALSE

/datum/world_edit_generator/outpost_radius/proc/build_outpost_defense_placements(list/anchor_map, list/defense_profile, list/reserved_turf_lookup = null, default_faction = null, default_turned_on = FALSE)
	var/list/result = list(
		"placements" = list(),
		"blocked_sentries" = 0,
		"blocked_wire_objects" = 0,
		"blocked_mines" = 0,
		"blocked_extra_defenses" = 0,
		"sentry_count" = 0,
		"wire_object_count" = 0,
		"mine_count" = 0,
		"extra_defense_count" = 0,
	)
	if(!islist(anchor_map) || !islist(defense_profile))
		return result

	var/list/occupied_lookup = islist(reserved_turf_lookup) ? reserved_turf_lookup.Copy() : list()
	var/list/defense_rules = islist(defense_profile["defense_rules"]) ? defense_profile["defense_rules"] : list()
	for(var/list/rule as anything in defense_rules)
		var/group_id = "[rule["group"]]"
		var/list/group_candidates = anchor_map[group_id]
		if(!islist(group_candidates) || !length(group_candidates))
			continue

		var/limit = max(round(text2num("[rule["limit"]]") || 0), 1)
		var/placed_count = 0
		for(var/list/candidate as anything in group_candidates)
			if(placed_count >= limit)
				break

			var/turf/target_turf = candidate["turf"]
			if(!istype(target_turf) || occupied_lookup[target_turf])
				continue

			var/defense_path = rule["defense_path"]
			var/dir_to_use = candidate["dir"]
			if(!can_place_outpost_support_on_turf(target_turf, defense_path, dir_to_use))
				continue

			var/kind = "[rule["kind"]]"
			var/faction = "[default_faction || defense_profile["faction"] || rule["faction"]]"
			var/placement_turned_on = isnull(rule["turned_on"]) ? GLOB.world_edit_helpers.parse_bool(default_turned_on) : GLOB.world_edit_helpers.parse_bool(rule["turned_on"])
			result["placements"] += list(list(
				"kind" = kind,
				"turf" = target_turf,
				"dir" = dir_to_use,
				"defense_path" = defense_path,
				"faction" = length(faction) ? faction : null,
				"turned_on" = placement_turned_on ? TRUE : FALSE,
			))
			occupied_lookup[target_turf] = TRUE
			placed_count++

			switch(kind)
				if("sentry")
					result["sentry_count"]++
				if("wire_object")
					result["wire_object_count"]++
				if("mine")
					result["mine_count"]++
				if("extra_defense")
					result["extra_defense_count"]++

		var/blocked_count = max(min(limit, length(group_candidates)) - placed_count, 0)
		switch("[rule["kind"]]")
			if("sentry")
				result["blocked_sentries"] += blocked_count
			if("wire_object")
				result["blocked_wire_objects"] += blocked_count
			if("mine")
				result["blocked_mines"] += blocked_count
			if("extra_defense")
				result["blocked_extra_defenses"] += blocked_count

	return result

/datum/world_edit_generator/outpost_radius/proc/build_turf_lookup(list/turfs)
	var/list/lookup = list()
	if(!islist(turfs))
		return lookup

	for(var/turf/target_turf as anything in turfs)
		if(istype(target_turf))
			lookup[target_turf] = TRUE

	return lookup

/datum/world_edit_generator/outpost_radius/proc/build_turf_bounds(list/turfs)
	var/list/bounds = list(
		"min_x" = null,
		"max_x" = null,
		"min_y" = null,
		"max_y" = null,
		"center_x" = 0,
		"center_y" = 0,
		"z" = null,
	)
	if(!islist(turfs) || !length(turfs))
		return bounds

	for(var/turf/target_turf as anything in turfs)
		if(!istype(target_turf))
			continue
		if(isnull(bounds["min_x"]) || target_turf.x < bounds["min_x"])
			bounds["min_x"] = target_turf.x
		if(isnull(bounds["max_x"]) || target_turf.x > bounds["max_x"])
			bounds["max_x"] = target_turf.x
		if(isnull(bounds["min_y"]) || target_turf.y < bounds["min_y"])
			bounds["min_y"] = target_turf.y
		if(isnull(bounds["max_y"]) || target_turf.y > bounds["max_y"])
			bounds["max_y"] = target_turf.y
		if(isnull(bounds["z"]))
			bounds["z"] = target_turf.z

	if(!isnull(bounds["min_x"]) && !isnull(bounds["max_x"]))
		bounds["center_x"] = (bounds["min_x"] + bounds["max_x"]) / 2
	if(!isnull(bounds["min_y"]) && !isnull(bounds["max_y"]))
		bounds["center_y"] = (bounds["min_y"] + bounds["max_y"]) / 2

	return bounds

/datum/world_edit_generator/outpost_radius/proc/get_outpost_budget_error(budget_kind, actual, limit)
	return "Запрошенный форпост слишком большой для безопасного предпросмотра ([budget_kind]: [actual]/[limit]). Уменьшите радиус или контур."

/datum/world_edit_generator/outpost_radius/proc/stamp_outpost_budget_metadata(list/metadata, budget_kind, actual, limit)
	if(!islist(metadata))
		return
	metadata["budget_kind"] = "[budget_kind]"
	metadata["budget_actual"] = actual
	metadata["budget_limit"] = limit

/datum/world_edit_generator/outpost_radius/proc/get_outpost_scan_tile_count(list/shape_bounds, radius)
	if(!islist(shape_bounds) || isnull(shape_bounds["min_x"]) || isnull(shape_bounds["max_x"]) || isnull(shape_bounds["min_y"]) || isnull(shape_bounds["max_y"]))
		return 0
	radius = max(round(radius), 1)
	return ((shape_bounds["max_x"] - shape_bounds["min_x"] + 1) + (radius * 2)) * ((shape_bounds["max_y"] - shape_bounds["min_y"] + 1) + (radius * 2))

/datum/world_edit_generator/outpost_radius/proc/normalize_outpost_footprint(list/raw_turfs, shape_id, turf/seed_turf = null)
	var/list/result = list(
		"turfs" = list(),
		"lookup" = list(),
		"z" = null,
		"error" = null,
		"budget_kind" = null,
		"budget_actual" = 0,
		"budget_limit" = 0,
	)
	if(!islist(raw_turfs) || !length(raw_turfs))
		result["error"] = "Не удалось определить контур формы."
		return result

	var/list/lookup = list()
	var/list/normalized_turfs = list()
	var/z_level = null
	for(var/turf/source_turf as anything in raw_turfs)
		if(!istype(source_turf))
			continue
		if(isnull(z_level))
			z_level = source_turf.z
		if(source_turf.z != z_level)
			result["error"] = "Форпост поддерживает только контур на одном Z-уровне."
			return result
		if(lookup[source_turf])
			continue
		lookup[source_turf] = TRUE
		normalized_turfs += source_turf

	if(!length(normalized_turfs))
		result["error"] = "Не удалось определить контур формы."
		return result
	if(length(normalized_turfs) > WORLD_EDIT_OUTPOST_MAX_FOOTPRINT_TURFS)
		result["budget_kind"] = "footprint"
		result["budget_actual"] = length(normalized_turfs)
		result["budget_limit"] = WORLD_EDIT_OUTPOST_MAX_FOOTPRINT_TURFS
		result["error"] = get_outpost_budget_error("footprint", length(normalized_turfs), WORLD_EDIT_OUTPOST_MAX_FOOTPRINT_TURFS)
		return result

	if(istype(seed_turf) && !lookup[seed_turf])
		seed_turf = normalized_turfs[1]

	result["turfs"] = normalized_turfs
	result["lookup"] = lookup
	result["z"] = z_level
	return result

/datum/world_edit_generator/outpost_radius/proc/build_shape_chebyshev_distance_map(list/footprint_turfs, radius, list/footprint_lookup, list/shape_bounds, list/distance_cache = null)
	var/list/result = list(
		"error" = null,
		"distances" = islist(distance_cache) ? distance_cache : list(),
		"area_turfs" = list(),
		"shell_turfs" = list(),
		"shell_lookup" = list(),
		"scan_tile_count" = 0,
	)
	if(!islist(footprint_turfs) || !length(footprint_turfs))
		result["error"] = "Не удалось определить контур формы."
		return result

	radius = max(round(radius), 1)
	var/z_level = shape_bounds["z"]
	if(isnull(z_level))
		result["error"] = "Не удалось определить Z-уровень контура формы."
		return result

	var/scan_tile_count = get_outpost_scan_tile_count(shape_bounds, radius)
	result["scan_tile_count"] = scan_tile_count
	if(scan_tile_count > WORLD_EDIT_OUTPOST_MAX_SCAN_TURFS)
		result["error"] = get_outpost_budget_error("scan", scan_tile_count, WORLD_EDIT_OUTPOST_MAX_SCAN_TURFS)
		result["budget_kind"] = "scan"
		result["budget_actual"] = scan_tile_count
		result["budget_limit"] = WORLD_EDIT_OUTPOST_MAX_SCAN_TURFS
		return result

	var/min_x = shape_bounds["min_x"] - radius
	var/max_x = shape_bounds["max_x"] + radius
	var/min_y = shape_bounds["min_y"] - radius
	var/max_y = shape_bounds["max_y"] + radius
	var/list/distances = result["distances"]
	var/list/open_turfs = list()
	for(var/turf/footprint_turf as anything in footprint_turfs)
		if(!istype(footprint_turf) || footprint_turf.z != z_level)
			continue
		distances[footprint_turf] = 0
		open_turfs += footprint_turf

	var/search_index = 1
	while(search_index <= length(open_turfs))
		var/turf/current_turf = open_turfs[search_index++]
		var/current_distance = text2num("[distances[current_turf]]")
		if(current_distance >= radius)
			continue
		for(var/check_dir in GLOB.alldirs)
			var/turf/neighbor_turf = get_step(current_turf, check_dir)
			if(!istype(neighbor_turf) || neighbor_turf.z != z_level)
				continue
			if(neighbor_turf.x < min_x || neighbor_turf.x > max_x || neighbor_turf.y < min_y || neighbor_turf.y > max_y)
				continue
			if(!isnull(distances[neighbor_turf]))
				continue
			distances[neighbor_turf] = current_distance + 1
			open_turfs += neighbor_turf

	var/list/area_turfs = result["area_turfs"]
	var/list/shell_turfs = result["shell_turfs"]
	var/list/shell_lookup = result["shell_lookup"]
	for(var/turf/known_turf as anything in distances)
		if(!istype(known_turf))
			continue
		area_turfs += known_turf
		if(distances[known_turf] == radius && !footprint_lookup[known_turf])
			shell_lookup[known_turf] = TRUE
			shell_turfs += known_turf

	return result

/datum/world_edit_generator/outpost_radius/proc/build_point_radius_area_turfs(turf/center_turf, radius)
	var/list/area_turfs = list()
	if(!istype(center_turf))
		return area_turfs

	radius = max(round(radius), 1)
	for(var/turf/target_turf in range(radius, center_turf))
		if(!istype(target_turf) || target_turf.z != center_turf.z)
			continue
		if(max(abs(target_turf.x - center_turf.x), abs(target_turf.y - center_turf.y)) > radius)
			continue
		area_turfs += target_turf

	return area_turfs

/datum/world_edit_generator/outpost_radius/proc/build_shape_radius_area_turfs(list/footprint_turfs, radius, list/footprint_lookup, list/shape_bounds, list/distance_cache = null)
	var/list/distance_data = build_shape_chebyshev_distance_map(footprint_turfs, radius, footprint_lookup, shape_bounds, distance_cache)
	if(distance_data["error"])
		return list()
	return distance_data["area_turfs"]

/datum/world_edit_generator/outpost_radius/proc/filter_outpost_candidate_turfs(list/start_turfs, list/candidate_turfs, list/traversal_turfs, list/radius_policy, list/pinned_turfs = null, list/pinned_lookup_override = null, list/approach_line_cache = null, list/approach_result_cache = null)
	var/list/result = list()
	var/list/result_lookup = list()
	var/list/policy = islist(radius_policy) ? radius_policy : GLOB.world_edit_helpers.get_world_edit_radius_policy(radius_policy)
	var/only_clear_tiles = !!policy["only_clear_tiles"]
	var/only_reachable_tiles = !!policy["only_reachable_tiles"]
	var/treat_windows_as_blockers = !!policy["treat_windows_as_blockers"]
	var/list/start_lookup = list()
	var/list/pinned_lookup = islist(pinned_lookup_override) ? pinned_lookup_override : list()
	var/z_level = null

	if(islist(start_turfs))
		for(var/turf/start_turf as anything in start_turfs)
			if(!istype(start_turf))
				continue
			if(isnull(z_level))
				z_level = start_turf.z
			if(start_turf.z != z_level || start_lookup[start_turf])
				continue
			start_lookup[start_turf] = TRUE

	var/list/pinned_source = islist(pinned_lookup_override) ? pinned_lookup_override : pinned_turfs
	if(islist(pinned_source))
		for(var/turf/pinned_turf as anything in pinned_source)
			if(!istype(pinned_turf))
				continue
			if(isnull(z_level))
				z_level = pinned_turf.z
			if(pinned_turf.z != z_level || pinned_lookup[pinned_turf])
				continue
			if(!islist(pinned_lookup_override))
				pinned_lookup[pinned_turf] = TRUE
			if(!result_lookup[pinned_turf])
				result_lookup[pinned_turf] = TRUE
				result += pinned_turf

	if(!length(start_lookup))
		for(var/turf/pinned_turf as anything in pinned_lookup)
			start_lookup[pinned_turf] = TRUE

	var/list/filtered_candidate_lookup = list()
	var/list/filtered_candidates = list()
	if(islist(candidate_turfs))
		for(var/turf/candidate_turf as anything in candidate_turfs)
			if(!istype(candidate_turf))
				continue
			if(isnull(z_level))
				z_level = candidate_turf.z
			if(candidate_turf.z != z_level || filtered_candidate_lookup[candidate_turf])
				continue
			filtered_candidate_lookup[candidate_turf] = TRUE
			filtered_candidates += candidate_turf
			if(!only_clear_tiles && !only_reachable_tiles && !result_lookup[candidate_turf])
				result_lookup[candidate_turf] = TRUE
				result += candidate_turf

	if(!only_clear_tiles && !only_reachable_tiles)
		return result

	if(!only_reachable_tiles)
		for(var/turf/candidate_turf as anything in filtered_candidates)
			if(result_lookup[candidate_turf])
				continue

			var/is_allowed = FALSE
			for(var/turf/start_turf as anything in start_lookup)
				if(has_clear_outpost_approach(start_turf, candidate_turf, treat_windows_as_blockers, pinned_lookup, approach_line_cache, approach_result_cache))
					is_allowed = TRUE
					break

			if(!is_allowed)
				continue

			result_lookup[candidate_turf] = TRUE
			result += candidate_turf

		return result

	var/list/traversal_lookup = list()
	var/list/raw_traversal_turfs = islist(traversal_turfs) ? traversal_turfs : filtered_candidates
	for(var/turf/traversal_turf as anything in raw_traversal_turfs)
		if(!istype(traversal_turf))
			continue
		if(isnull(z_level))
			z_level = traversal_turf.z
		if(traversal_turf.z != z_level || traversal_lookup[traversal_turf])
			continue
		if((only_clear_tiles || only_reachable_tiles) && !outpost_path_passable(traversal_turf, treat_windows_as_blockers))
			continue
		traversal_lookup[traversal_turf] = TRUE

	var/list/visited_lookup = list()
	var/list/open_turfs = list()
	for(var/turf/start_turf as anything in start_lookup)
		if(!istype(start_turf) || visited_lookup[start_turf])
			continue
		visited_lookup[start_turf] = TRUE
		open_turfs += start_turf

	var/search_index = 1
	while(search_index <= length(open_turfs))
		var/turf/current_turf = open_turfs[search_index++]
		for(var/check_dir in GLOB.cardinals)
			var/turf/adjacent_turf = get_step(current_turf, check_dir)
			if(!traversal_lookup[adjacent_turf] || visited_lookup[adjacent_turf])
				continue
			visited_lookup[adjacent_turf] = TRUE
			open_turfs += adjacent_turf

	for(var/turf/candidate_turf as anything in filtered_candidates)
		if(result_lookup[candidate_turf] || !is_outpost_candidate_reachable_from_seed(candidate_turf, visited_lookup))
			continue
		result_lookup[candidate_turf] = TRUE
		result += candidate_turf

	return result

/datum/world_edit_generator/outpost_radius/proc/filter_outpost_slots_by_radius_policy(list/start_turfs, list/candidate_slots, list/traversal_turfs, list/radius_policy, list/pinned_turfs = null, list/pinned_lookup_override = null, list/approach_line_cache = null, list/approach_result_cache = null)
	if(!islist(candidate_slots) || !length(candidate_slots))
		return list()

	var/list/candidate_turfs = list()
	var/list/candidate_turf_lookup = list()
	for(var/list/candidate_slot as anything in candidate_slots)
		var/turf/target_turf = candidate_slot["turf"]
		if(!istype(target_turf) || candidate_turf_lookup[target_turf])
			continue
		candidate_turf_lookup[target_turf] = TRUE
		candidate_turfs += target_turf

	var/list/allowed_turfs = filter_outpost_candidate_turfs(start_turfs, candidate_turfs, traversal_turfs, radius_policy, pinned_turfs || start_turfs, pinned_lookup_override, approach_line_cache, approach_result_cache)
	var/list/allowed_lookup = build_turf_lookup(allowed_turfs)
	var/list/filtered_slots = list()
	for(var/list/candidate_slot as anything in candidate_slots)
		var/turf/target_turf = candidate_slot["turf"]
		if(allowed_lookup[target_turf])
			filtered_slots += list(candidate_slot)

	return filtered_slots

/datum/world_edit_generator/outpost_radius/proc/resolve_outpost_shape_seed_turf(list/footprint_turfs, list/placement_context)
	var/turf/seed_turf = get_shape_placement_seed_turf(null, placement_context)
	if(istype(seed_turf))
		return seed_turf
	if(islist(footprint_turfs) && length(footprint_turfs))
		return footprint_turfs[1]
	return null

/datum/world_edit_generator/outpost_radius/proc/build_outpost_approach_line_cache_key(turf/start_turf, turf/target_turf)
	if(!istype(start_turf) || !istype(target_turf))
		return null
	return "[REF(start_turf)]>[REF(target_turf)]"

/datum/world_edit_generator/outpost_radius/proc/build_outpost_approach_result_cache_key(turf/start_turf, turf/target_turf, treat_windows_as_blockers, list/pinned_lookup = null)
	var/line_key = build_outpost_approach_line_cache_key(start_turf, target_turf)
	if(!length(line_key))
		return null
	var/pinned_lookup_ref = islist(pinned_lookup) ? "[REF(pinned_lookup)]" : ""
	return "[line_key]|[treat_windows_as_blockers ? 1 : 0]|[pinned_lookup_ref]"

/datum/world_edit_generator/outpost_radius/proc/has_clear_outpost_approach(turf/start_turf, turf/target_turf, treat_windows_as_blockers, list/pinned_lookup = null, list/approach_line_cache = null, list/approach_result_cache = null)
	if(!istype(start_turf) || !istype(target_turf) || start_turf.z != target_turf.z)
		return FALSE

	var/result_cache_key = build_outpost_approach_result_cache_key(start_turf, target_turf, treat_windows_as_blockers, pinned_lookup)
	if(length(result_cache_key) && islist(approach_result_cache) && !isnull(approach_result_cache[result_cache_key]))
		return approach_result_cache[result_cache_key]

	var/line_cache_key = build_outpost_approach_line_cache_key(start_turf, target_turf)
	var/list/line_turfs = length(line_cache_key) && islist(approach_line_cache) ? approach_line_cache[line_cache_key] : null
	if(!islist(line_turfs))
		line_turfs = GLOB.world_edit_helpers.collect_line_turfs(start_turf, target_turf)
		if(length(line_cache_key) && islist(approach_line_cache))
			approach_line_cache[line_cache_key] = line_turfs
	if(!length(line_turfs))
		if(length(result_cache_key) && islist(approach_result_cache))
			approach_result_cache[result_cache_key] = FALSE
		return FALSE

	for(var/turf/line_turf as anything in line_turfs)
		if(!istype(line_turf))
			continue
		if(line_turf == start_turf || line_turf == target_turf)
			continue
		if(islist(pinned_lookup) && pinned_lookup[line_turf])
			continue
		if(!outpost_path_passable(line_turf, treat_windows_as_blockers))
			if(length(result_cache_key) && islist(approach_result_cache))
				approach_result_cache[result_cache_key] = FALSE
			return FALSE

	if(length(result_cache_key) && islist(approach_result_cache))
		approach_result_cache[result_cache_key] = TRUE
	return TRUE

/datum/world_edit_generator/outpost_radius/proc/is_outpost_candidate_reachable_from_seed(turf/candidate_turf, list/reachable_lookup)
	if(!istype(candidate_turf) || !islist(reachable_lookup))
		return FALSE
	if(reachable_lookup[candidate_turf])
		return TRUE

	for(var/check_dir in GLOB.cardinals)
		if(reachable_lookup[get_step(candidate_turf, check_dir)])
			return TRUE

	return FALSE

/datum/world_edit_generator/outpost_radius/proc/get_outpost_radius_policy_error(shape_id, suffix = "")
	var/target_label = get_outpost_placement_target_label(shape_id)
	var/prefix = ("[shape_id]" == WORLD_EDIT_SHAPE_POINT) ? "Выбранная" : "Выбранный"
	var/error_message = "[prefix] [target_label] не поддерживает обязательные проходы форпоста"
	if(length("[suffix]"))
		error_message += " [suffix]"
	return "[error_message]."

/datum/world_edit_generator/outpost_radius/proc/validate_outpost_footprint_radius_policy(list/footprint_turfs, turf/seed_turf, list/radius_policy, shape_id)
	var/list/policy = islist(radius_policy) ? radius_policy : GLOB.world_edit_helpers.get_world_edit_radius_policy(radius_policy)
	var/only_clear_tiles = !!policy["only_clear_tiles"]
	var/only_reachable_tiles = !!policy["only_reachable_tiles"]
	if(!only_clear_tiles && !only_reachable_tiles)
		return null
	if(!islist(footprint_turfs) || !length(footprint_turfs))
		return "Не удалось определить контур формы."

	var/list/footprint_lookup = build_turf_lookup(footprint_turfs)
	for(var/turf/footprint_turf as anything in footprint_turfs)
		if(!istype(footprint_turf))
			continue
		if(!outpost_footprint_tile_allowed(footprint_turf, policy))
			return get_outpost_radius_policy_error(shape_id, "при текущей политике блокировок радиуса")

	if(!only_reachable_tiles)
		return null

	if(!istype(seed_turf) || !footprint_lookup[seed_turf])
		return get_outpost_radius_policy_error(shape_id, "при текущей политике блокировок радиуса")

	var/list/visited_lookup = list()
	visited_lookup[seed_turf] = TRUE
	var/list/open_turfs = list(seed_turf)
	var/search_index = 1
	while(search_index <= length(open_turfs))
		var/turf/current_turf = open_turfs[search_index++]
		for(var/check_dir in GLOB.cardinals)
			var/turf/neighbor_turf = get_step(current_turf, check_dir)
			if(!footprint_lookup[neighbor_turf] || visited_lookup[neighbor_turf])
				continue
			if(!outpost_path_passable(neighbor_turf, policy["treat_windows_as_blockers"]))
				continue
			visited_lookup[neighbor_turf] = TRUE
			open_turfs += neighbor_turf

	for(var/turf/footprint_turf as anything in footprint_turfs)
		if(!visited_lookup[footprint_turf])
			return get_outpost_radius_policy_error(shape_id, "при текущей политике блокировок радиуса")

	return null

/datum/world_edit_generator/outpost_radius/proc/get_outpost_shape_support_class(shape_id)
	if("[shape_id]" in GLOB.world_edit_placement_shapes.world_edit_get_supported_shape_ids())
		return "full"
	return "unsupported"

/datum/world_edit_generator/outpost_radius/proc/get_outpost_effective_shape_id(shape_id, datum/world_edit_shape_contract/shape_contract = null, list/placement_context = null, list/footprint_turfs = null)
	var/effective_shape_id = "[shape_id || shape_contract?.shape_id || placement_context["shape"] || WORLD_EDIT_SHAPE_POINT]"
	if(effective_shape_id == WORLD_EDIT_SHAPE_POINT)
		return WORLD_EDIT_SHAPE_POINT

	var/degenerate_kind = ""
	if(istype(shape_contract))
		degenerate_kind = "[shape_contract.degenerate_kind]"
		if(!length(degenerate_kind) && islist(shape_contract.metadata))
			degenerate_kind = "[shape_contract.metadata["degenerate_kind"]]"
	if(!length(degenerate_kind) && islist(placement_context))
		var/list/shape_metadata = placement_context["shape_metadata"]
		if(islist(shape_metadata))
			degenerate_kind = "[shape_metadata["degenerate_kind"]]"

	if(degenerate_kind == "point")
		return WORLD_EDIT_SHAPE_POINT
	if(islist(footprint_turfs) && length(footprint_turfs) <= 1)
		return WORLD_EDIT_SHAPE_POINT
	return effective_shape_id

/datum/world_edit_generator/outpost_radius/proc/count_shape_connected_components(list/footprint_turfs)
	if(!islist(footprint_turfs) || !length(footprint_turfs))
		return 0

	var/list/lookup = build_turf_lookup(footprint_turfs)
	var/list/unvisited = lookup.Copy()
	var/component_count = 0
	for(var/turf/start_turf as anything in footprint_turfs)
		if(!istype(start_turf) || !unvisited[start_turf])
			continue
		component_count++
		var/list/open_list = list(start_turf)
		unvisited[start_turf] = FALSE
		while(length(open_list))
			var/turf/current_turf = open_list[length(open_list)]
			open_list.Cut(length(open_list), length(open_list) + 1)
			for(var/check_dir in GLOB.alldirs)
				var/turf/neighbor_turf = get_step(current_turf, check_dir)
				if(!lookup[neighbor_turf] || !unvisited[neighbor_turf])
					continue
				unvisited[neighbor_turf] = FALSE
				open_list += neighbor_turf
	return component_count

/datum/world_edit_generator/outpost_radius/proc/split_outpost_footprint_components(list/footprint_turfs)
	var/list/components = list()
	if(!islist(footprint_turfs) || !length(footprint_turfs))
		return components

	var/list/lookup = build_turf_lookup(footprint_turfs)
	var/list/unvisited = lookup.Copy()
	for(var/turf/start_turf as anything in footprint_turfs)
		if(!istype(start_turf) || !unvisited[start_turf])
			continue
		var/list/component = list()
		var/list/open_list = list(start_turf)
		unvisited[start_turf] = FALSE
		while(length(open_list))
			var/turf/current_turf = open_list[length(open_list)]
			open_list.Cut(length(open_list), length(open_list) + 1)
			component += current_turf
			for(var/check_dir in GLOB.alldirs)
				var/turf/neighbor_turf = get_step(current_turf, check_dir)
				if(!lookup[neighbor_turf] || !unvisited[neighbor_turf])
					continue
				unvisited[neighbor_turf] = FALSE
				open_list += neighbor_turf
		if(length(component))
			components += list(component)
	return components

/datum/world_edit_generator/outpost_radius/proc/get_outpost_shape_support_validation_error(shape_id, list/footprint_turfs, list/placement_context = null)
	var/support_class = get_outpost_shape_support_class(shape_id)
	var/shape_label = GLOB.world_edit_placement_shapes.world_edit_get_placement_shape_label(shape_id)
	switch(support_class)
		if("unsupported")
			return "Форма [shape_label] временно не поддерживается стабильным planner v1 форпоста."

	return null

/datum/world_edit_generator/outpost_radius/proc/get_cardinal_opposite_dir(dir_to_flip)
	switch(dir_to_flip)
		if(NORTH)
			return SOUTH
		if(SOUTH)
			return NORTH
		if(EAST)
			return WEST
		if(WEST)
			return EAST
	return dir_to_flip

/datum/world_edit_generator/outpost_radius/proc/build_shape_shell_turfs(list/footprint_turfs, radius, list/footprint_lookup, list/shape_bounds, list/distance_cache = null)
	var/list/result = list(
		"turfs" = list(),
		"lookup" = list(),
	)
	var/list/distance_data = build_shape_chebyshev_distance_map(footprint_turfs, radius, footprint_lookup, shape_bounds, distance_cache)
	if(distance_data["error"])
		return result

	result["turfs"] = distance_data["shell_turfs"]
	result["lookup"] = distance_data["shell_lookup"]
	return result

/datum/world_edit_generator/outpost_radius/proc/build_shape_shell_slot_dirs(turf/target_turf, radius, list/footprint_turfs, list/shell_lookup, list/distance_cache = null)
	var/list/slot_dirs = list()
	if(!istype(target_turf) || !islist(shell_lookup))
		return slot_dirs

	for(var/dir_to_use as anything in GLOB.cardinals)
		var/turf/neighbor_turf = get_step(target_turf, dir_to_use)
		if(shell_lookup[neighbor_turf])
			continue

		var/neighbor_distance = islist(distance_cache) ? distance_cache[neighbor_turf] : null
		if(isnull(neighbor_distance) || neighbor_distance > radius)
			slot_dirs += dir_to_use

	return slot_dirs

/datum/world_edit_generator/outpost_radius/proc/score_shape_opening_slot(list/candidate_slot, list/shape_bounds)
	var/turf/source_turf = candidate_slot["turf"]
	if(!istype(source_turf))
		source_turf = candidate_slot["source_turf"]
	var/dir_to_use = candidate_slot["dir"]
	if(!istype(source_turf))
		return 0

	switch(dir_to_use)
		if(NORTH)
			return ((shape_bounds["max_y"] - source_turf.y) * 100000) + (abs(source_turf.x - shape_bounds["center_x"]) * 1000) + source_turf.x
		if(SOUTH)
			return ((source_turf.y - shape_bounds["min_y"]) * 100000) + (abs(source_turf.x - shape_bounds["center_x"]) * 1000) + source_turf.x
		if(EAST)
			return ((shape_bounds["max_x"] - source_turf.x) * 100000) + (abs(source_turf.y - shape_bounds["center_y"]) * 1000) + source_turf.y
		if(WEST)
			return ((source_turf.x - shape_bounds["min_x"]) * 100000) + (abs(source_turf.y - shape_bounds["center_y"]) * 1000) + source_turf.y

	return 0

/datum/world_edit_generator/outpost_radius/proc/get_shape_slot_cross_axis(list/candidate_slot, list/shape_bounds)
	var/turf/source_turf = candidate_slot["turf"]
	if(!istype(source_turf))
		source_turf = candidate_slot["source_turf"]
	var/dir_to_use = candidate_slot["dir"]
	if(!istype(source_turf))
		return 0

	switch(dir_to_use)
		if(NORTH, SOUTH)
			return source_turf.x - shape_bounds["center_x"]
		if(EAST, WEST)
			return source_turf.y - shape_bounds["center_y"]
	return 0

/datum/world_edit_generator/outpost_radius/proc/select_best_shape_slots(list/candidate_slots, slots_to_select, list/shape_bounds, list/selected_lookup)
	var/list/selected_slots = list()
	if(!islist(candidate_slots) || !length(candidate_slots))
		return selected_slots

	for(var/i in 1 to max(round(text2num("[slots_to_select]") || 0), 0))
		var/list/best_slot = null
		var/best_score = null
		for(var/list/candidate_slot as anything in candidate_slots)
			var/slot_key = GLOB.world_edit_helpers.build_turf_dir_slot_key(candidate_slot["turf"], candidate_slot["dir"])
			if(!length(slot_key) || selected_lookup[slot_key])
				continue
			var/score = score_shape_opening_slot(candidate_slot, shape_bounds)
			if(isnull(best_score) || score < best_score)
				best_score = score
				best_slot = candidate_slot

		if(!islist(best_slot))
			break

		var/best_slot_key = GLOB.world_edit_helpers.build_turf_dir_slot_key(best_slot["turf"], best_slot["dir"])
		if(length(best_slot_key))
			selected_lookup[best_slot_key] = TRUE
		selected_slots += list(best_slot)

	return selected_slots

/datum/world_edit_generator/outpost_radius/proc/build_shape_perimeter_candidates(list/footprint_turfs, radius, list/footprint_lookup, list/shape_bounds, list/distance_cache = null)
	var/list/candidates = list()
	var/list/candidate_lookup = list()
	if(!islist(footprint_turfs) || !length(footprint_turfs))
		return candidates

	radius = max(round(radius), 1)
	var/list/shell_data = build_shape_shell_turfs(footprint_turfs, radius, footprint_lookup, shape_bounds, distance_cache)
	var/list/shell_turfs = shell_data["turfs"]
	var/list/shell_lookup = shell_data["lookup"]
	for(var/turf/target_turf as anything in shell_turfs)
		if(!istype(target_turf))
			continue

		var/list/slot_dirs = build_shape_shell_slot_dirs(target_turf, radius, footprint_turfs, shell_lookup, distance_cache)
		for(var/dir_to_use as anything in slot_dirs)
			var/candidate_key = GLOB.world_edit_helpers.build_turf_dir_slot_key(target_turf, dir_to_use)
			if(!length(candidate_key) || candidate_lookup[candidate_key])
				continue

			candidate_lookup[candidate_key] = TRUE
			candidates += list(list(
				"source_turf" = GLOB.world_edit_helpers.step_turf(target_turf, get_cardinal_opposite_dir(dir_to_use), 1),
				"turf" = target_turf,
				"dir" = dir_to_use,
				"slot_index" = length(candidates) + 1,
			))
			if(length(candidates) > WORLD_EDIT_OUTPOST_MAX_CANDIDATE_SLOTS)
				return candidates

	return candidates

/datum/world_edit_generator/outpost_radius/proc/select_shape_direction_slots(list/candidate_slots, list/target_dirs, slots_per_dir, list/shape_bounds, slot_mode = "centered")
	var/list/selected_slots = list()
	if(!islist(candidate_slots) || !length(candidate_slots))
		return selected_slots
	if(!islist(target_dirs) || !length(target_dirs))
		return selected_slots

	var/slots_to_select = max(round(text2num("[slots_per_dir]") || 0), 0)
	if(slots_to_select <= 0)
		return selected_slots
	var/list/selected_lookup = list()
	for(var/dir_to_use as anything in target_dirs)
		var/list/dir_candidates = list()
		var/list/negative_candidates = list()
		var/list/positive_candidates = list()
		for(var/list/candidate_slot as anything in candidate_slots)
			if(candidate_slot["dir"] != dir_to_use)
				continue
			dir_candidates += list(candidate_slot)
			var/cross_axis = get_shape_slot_cross_axis(candidate_slot, shape_bounds)
			if(cross_axis < 0)
				negative_candidates += list(candidate_slot)
			else if(cross_axis > 0)
				positive_candidates += list(candidate_slot)

		if(slot_mode == "split_pair" && slots_to_select >= 2 && length(negative_candidates) && length(positive_candidates))
			var/dir_selected_before = length(selected_slots)
			var/negative_count = round(slots_to_select / 2)
			var/positive_count = slots_to_select - negative_count
			selected_slots += select_best_shape_slots(negative_candidates, negative_count, shape_bounds, selected_lookup)
			selected_slots += select_best_shape_slots(positive_candidates, positive_count, shape_bounds, selected_lookup)
			var/missing_count = slots_to_select - (length(selected_slots) - dir_selected_before)
			if(missing_count > 0)
				selected_slots += select_best_shape_slots(dir_candidates, missing_count, shape_bounds, selected_lookup)
			continue

		selected_slots += select_best_shape_slots(dir_candidates, slots_to_select, shape_bounds, selected_lookup)

	return selected_slots

/datum/world_edit_generator/outpost_radius/proc/build_outpost_shape_analysis(list/footprint_turfs, list/params, list/placement_context = null)
	var/list/analysis = list(
		"error" = null,
		"config" = null,
		"footprint_turfs" = list(),
		"footprint_lookup" = list(),
		"shape_bounds" = list(),
		"seed_turf" = null,
		"traversal_turfs" = list(),
		"candidate_slots" = list(),
		"filtered_candidate_slots" = list(),
		"perimeter_slots" = list(),
		"opening_slots" = list(),
		"opening_slot_keys" = list(),
		"opening_lookup" = list(),
		"opening_slots_by_dir" = list(),
		"anchor_map" = list(),
		"opening_dirs" = list(),
		"distance_cache" = list(),
		"approach_line_cache" = list(),
		"approach_result_cache" = list(),
	)
	if(!islist(footprint_turfs) || !length(footprint_turfs))
		analysis["error"] = "Не удалось определить контур формы."
		return analysis

	var/list/config = params
	if(!islist(config) || !islist(config["layout_profile"]))
		config = resolve_outpost_configuration(params, placement_context)
	if(config["error"])
		analysis["error"] = "[config["error"]]"
		return analysis

	var/list/normalized_footprint = normalize_outpost_footprint(footprint_turfs, islist(placement_context) ? (placement_context["shape"] || WORLD_EDIT_SHAPE_POINT) : WORLD_EDIT_SHAPE_POINT)
	if(normalized_footprint["error"])
		analysis["error"] = "[normalized_footprint["error"]]"
		analysis["budget_kind"] = normalized_footprint["budget_kind"]
		analysis["budget_actual"] = normalized_footprint["budget_actual"]
		analysis["budget_limit"] = normalized_footprint["budget_limit"]
		return analysis
	var/list/footprint_lookup = normalized_footprint["lookup"]
	var/list/unique_footprint_turfs = normalized_footprint["turfs"]

	var/list/shape_bounds = build_turf_bounds(unique_footprint_turfs)
	var/turf/seed_turf = resolve_outpost_shape_seed_turf(unique_footprint_turfs, placement_context)
	if(!istype(seed_turf))
		seed_turf = unique_footprint_turfs[1]
	var/list/distance_cache = list()
	var/list/approach_line_cache = list()
	var/list/approach_result_cache = list()
	var/list/distance_data = build_shape_chebyshev_distance_map(unique_footprint_turfs, config["radius"], footprint_lookup, shape_bounds, distance_cache)
	if(distance_data["error"])
		analysis["error"] = "[distance_data["error"]]"
		analysis["budget_kind"] = distance_data["budget_kind"]
		analysis["budget_actual"] = distance_data["budget_actual"]
		analysis["budget_limit"] = distance_data["budget_limit"]
		return analysis
	var/list/traversal_turfs = distance_data["area_turfs"]
	var/list/candidate_slots = build_shape_perimeter_candidates(unique_footprint_turfs, config["radius"], footprint_lookup, shape_bounds, distance_cache)
	if(length(candidate_slots) > WORLD_EDIT_OUTPOST_MAX_CANDIDATE_SLOTS)
		analysis["error"] = get_outpost_budget_error("candidate_slots", length(candidate_slots), WORLD_EDIT_OUTPOST_MAX_CANDIDATE_SLOTS)
		analysis["budget_kind"] = "candidate_slots"
		analysis["budget_actual"] = length(candidate_slots)
		analysis["budget_limit"] = WORLD_EDIT_OUTPOST_MAX_CANDIDATE_SLOTS
		return analysis
	var/list/filtered_candidate_slots = filter_outpost_slots_by_radius_policy(list(seed_turf), candidate_slots, traversal_turfs, config["radius_policy"], unique_footprint_turfs, footprint_lookup, approach_line_cache, approach_result_cache)
	var/list/layout_profile = islist(config["layout_profile"]) ? config["layout_profile"] : list(
		"opening_dirs" = list(NORTH, EAST, SOUTH, WEST),
		"opening_width" = max(text2num("[config["opening_width"]]"), 0),
		"opening_slots_per_dir" = 1,
		"opening_slot_mode" = "centered",
	)
	config["layout_profile"] = layout_profile
	var/list/opening_dirs = get_layout_opening_dirs(layout_profile)
	var/opening_tiles_per_dir = get_layout_total_opening_tiles_per_dir(layout_profile)
	var/list/opening_slots = length(opening_dirs) ? select_shape_direction_slots(filtered_candidate_slots, opening_dirs, opening_tiles_per_dir, shape_bounds, get_layout_opening_slot_mode(layout_profile)) : list()
	var/list/opening_slot_keys = list()
	var/list/opening_lookup = list()
	var/list/opening_slots_by_dir = list()
	for(var/list/opening_slot as anything in opening_slots)
		var/opening_slot_key = GLOB.world_edit_helpers.build_turf_dir_slot_key(opening_slot["turf"], opening_slot["dir"])
		if(!length(opening_slot_key) || opening_lookup[opening_slot_key])
			continue
		opening_lookup[opening_slot_key] = TRUE
		opening_slot_keys += opening_slot_key
		var/opening_dir = opening_slot["dir"]
		if(GLOB.world_edit_helpers.is_cardinal_dir(opening_dir))
			opening_slots_by_dir["[opening_dir]"] = (opening_slots_by_dir["[opening_dir]"] || 0) + 1

	var/list/perimeter_slots = list()
	for(var/list/candidate_slot as anything in filtered_candidate_slots)
		var/list/slot_data = candidate_slot.Copy()
		var/slot_key = build_outpost_slot_key(slot_data)
		slot_data["slot_key"] = slot_key
		slot_data["is_opening"] = length(slot_key) && opening_lookup[slot_key] ? TRUE : FALSE
		perimeter_slots += list(slot_data)

	var/list/anchor_map = config["needs_anchor_map"] ? build_outpost_anchor_map(unique_footprint_turfs, perimeter_slots, opening_slots, config["placement_dir"], config) : list()

	analysis["config"] = config
	analysis["footprint_turfs"] = unique_footprint_turfs
	analysis["footprint_lookup"] = footprint_lookup
	analysis["shape_bounds"] = shape_bounds
	analysis["seed_turf"] = seed_turf
	analysis["traversal_turfs"] = traversal_turfs
	analysis["candidate_slots"] = candidate_slots
	analysis["filtered_candidate_slots"] = filtered_candidate_slots
	analysis["perimeter_slots"] = perimeter_slots
	analysis["opening_slots"] = opening_slots
	analysis["opening_slot_keys"] = opening_slot_keys
	analysis["opening_lookup"] = opening_lookup
	analysis["opening_slots_by_dir"] = opening_slots_by_dir
	analysis["anchor_map"] = anchor_map
	analysis["opening_dirs"] = opening_dirs
	analysis["distance_cache"] = distance_cache
	analysis["approach_line_cache"] = approach_line_cache
	analysis["approach_result_cache"] = approach_result_cache
	analysis["scan_tile_count"] = distance_data["scan_tile_count"]
	analysis["budget_kind"] = null
	analysis["budget_actual"] = 0
	analysis["budget_limit"] = 0
	return analysis

/datum/world_edit_generator/outpost_radius/proc/build_shape_aware_perimeter_plan(list/footprint_turfs, list/params, list/placement_context = null, list/shape_analysis = null)
	var/datum/world_edit_plan/plan = new
	shape_analysis = islist(shape_analysis) ? shape_analysis : build_outpost_shape_analysis(footprint_turfs, params, placement_context)
	if(!islist(shape_analysis))
		plan.metadata["error"] = "Не удалось определить контур формы."
		return plan
	if(shape_analysis["error"])
		plan.metadata["error"] = "[shape_analysis["error"]]"
		if(shape_analysis["budget_kind"])
			stamp_outpost_budget_metadata(plan.metadata, shape_analysis["budget_kind"], shape_analysis["budget_actual"], shape_analysis["budget_limit"])
		return plan

	var/list/config = shape_analysis["config"]
	footprint_turfs = shape_analysis["footprint_turfs"]
	var/list/shape_bounds = shape_analysis["shape_bounds"]
	var/list/defense_profile = islist(config["defense_profile_data"]) ? config["defense_profile_data"] : get_outpost_defense_profile("none")
	var/radius = config["radius"]
	var/list/radius_policy = islist(config["radius_policy"]) ? config["radius_policy"] : GLOB.world_edit_helpers.get_world_edit_radius_policy(config)
	var/turf/seed_turf = shape_analysis["seed_turf"]
	var/list/candidate_slots = shape_analysis["filtered_candidate_slots"]
	if(!length(candidate_slots))
		plan.metadata["error"] = "Выбранный контур размещения не позволяет построить оболочку периметра при текущей политике блокировок радиуса."
		return plan
	var/list/shape_opening_dirs = islist(shape_analysis["opening_dirs"]) ? shape_analysis["opening_dirs"] : null
	var/list/layout_profile = islist(config["layout_profile"]) ? config["layout_profile"] : list(
		"label" = config["layout_variant"] || "shape_layout",
		"description" = "",
		"opening_dirs" = islist(shape_opening_dirs) ? shape_opening_dirs.Copy() : list(),
		"opening_width" = max(text2num("[config["opening_width"]]"), 0),
		"opening_slots_per_dir" = 1,
		"opening_slot_mode" = "centered",
	)
	var/list/opening_dirs = shape_analysis["opening_dirs"]
	var/list/perimeter_slots = shape_analysis["perimeter_slots"]
	var/list/anchor_map = shape_analysis["anchor_map"]
	var/list/wired_lookup = config["needs_anchor_map"] ? build_wired_anchor_lookup(anchor_map, defense_profile["wired_groups"]) : list()

	var/list/preview_turf_lookup = list()

	for(var/list/candidate_slot as anything in candidate_slots)
		var/turf/target_turf = candidate_slot["turf"]
		if(!istype(target_turf))
			continue
		preview_turf_lookup[target_turf] = TRUE

	var/list/perimeter_data = build_outpost_perimeter_result(
		perimeter_slots,
		radius,
		config["primary_material_path"],
		config["secondary_material_path"],
		config["barricade_pattern"],
		config["primary_material_share_percent"],
		config["place_barricade_doors"],
		config["primary_door_path"],
		config["secondary_door_path"],
		wired_lookup,
	)
	for(var/list/placement as anything in perimeter_data["placements"])
		plan.placements += list(list(
			"kind" = "barricade",
			"turf" = placement["turf"],
			"dir" = placement["dir"],
			"defense_path" = placement["barricade_path"] || config["primary_material_path"],
			"is_barricade_door" = placement["is_barricade_door"] ? TRUE : FALSE,
			"source_barricade_path" = placement["source_barricade_path"],
		))

	var/list/reserved_turf_lookup = build_outpost_reserved_turf_lookup(plan.placements)
	var/list/defense_data = build_outpost_defense_placements(anchor_map, defense_profile, reserved_turf_lookup, config["faction"], config["turned_on"])
	for(var/list/placement as anything in defense_data["placements"])
		var/turf/defense_turf = placement["turf"]
		if(istype(defense_turf))
			preview_turf_lookup[defense_turf] = TRUE
			reserved_turf_lookup[defense_turf] = TRUE
		plan.placements += list(placement.Copy())

	var/total_openings = perimeter_data["opening_count"] || 0
	var/total_blocked_openings = perimeter_data["blocked_openings"] || 0
	var/expected_openings = get_layout_expected_opening_count(layout_profile)
	if(expected_openings > total_openings)
		total_blocked_openings += expected_openings - total_openings
	if(length(plan.placements) > WORLD_EDIT_PLACEMENT_MAX_TOTAL_PLACEMENTS)
		plan.metadata["error"] = "Запрошенное размещение форпоста превышает безопасный лимит ([WORLD_EDIT_PLACEMENT_MAX_TOTAL_PLACEMENTS])."
		return plan

	for(var/turf/preview_turf as anything in preview_turf_lookup)
		plan.affected_turfs += preview_turf

	var/turf/center_turf = locate(round((shape_bounds["min_x"] + shape_bounds["max_x"]) / 2), round((shape_bounds["min_y"] + shape_bounds["max_y"]) / 2), shape_bounds["z"])
	if(!istype(center_turf))
		center_turf = footprint_turfs[clamp(round((length(footprint_turfs) + 1) / 2), 1, length(footprint_turfs))]

	plan.metadata["center_turf"] = center_turf
	plan.metadata["planner_version"] = WORLD_EDIT_OUTPOST_PLANNER_VERSION
	plan.metadata["radius"] = radius
	plan.metadata["radius_only_clear_tiles"] = radius_policy["only_clear_tiles"]
	plan.metadata["radius_only_reachable_tiles"] = radius_policy["only_reachable_tiles"]
	plan.metadata["radius_windows_blockers"] = radius_policy["treat_windows_as_blockers"]
	plan.metadata["shape_mode"] = "footprint_offset"
	plan.metadata["seed_turf"] = seed_turf
	plan.metadata["shape_footprint_count"] = length(footprint_turfs)
	plan.metadata["shape_scan_tile_count"] = shape_analysis["scan_tile_count"] || 0
	plan.metadata["shape_candidate_slot_count"] = length(shape_analysis["candidate_slots"])
	stamp_outpost_budget_metadata(plan.metadata, "scan", shape_analysis["scan_tile_count"] || 0, WORLD_EDIT_OUTPOST_MAX_SCAN_TURFS)
	plan.metadata["base_shape_turfs"] = footprint_turfs.Copy()
	plan.metadata["anchor_count"] = length(footprint_turfs)
	populate_outpost_recipe_metadata(plan.metadata, config)
	plan.metadata["defense_profile_label"] = defense_profile["label"]
	plan.metadata["defense_profile_description"] = defense_profile["description"]
	plan.metadata["tactical_profile_label"] = defense_profile["label"]
	plan.metadata["tactical_profile_description"] = defense_profile["description"]
	plan.metadata["layout_label"] = layout_profile["label"]
	plan.metadata["layout_description"] = layout_profile["description"]
	plan.metadata["barricade_count"] = length(perimeter_data["placements"])
	plan.metadata["sentry_count"] = defense_data["sentry_count"] || 0
	plan.metadata["wire_object_count"] = defense_data["wire_object_count"] || 0
	plan.metadata["mine_count"] = defense_data["mine_count"] || 0
	plan.metadata["extra_defense_count"] = defense_data["extra_defense_count"] || 0
	plan.metadata["opening_count"] = total_openings
	plan.metadata["opening_dirs"] = format_opening_dirs(opening_dirs)
	plan.metadata["blocked_barricades"] = perimeter_data["blocked_barricades"] || 0
	plan.metadata["blocked_openings"] = total_blocked_openings
	plan.metadata["blocked_perimeter"] = (perimeter_data["blocked_count"] || 0) + max(expected_openings - total_openings, 0)
	plan.metadata["blocked_sentries"] = defense_data["blocked_sentries"] || 0
	plan.metadata["blocked_wire_objects"] = defense_data["blocked_wire_objects"] || 0
	plan.metadata["blocked_mines"] = defense_data["blocked_mines"] || 0
	plan.metadata["blocked_extra_defenses"] = defense_data["blocked_extra_defenses"] || 0
	plan.metadata["door_count"] = perimeter_data["door_count"] || 0
	plan.metadata["unsupported_door_openings"] = perimeter_data["unsupported_door_openings"] || 0
	plan.metadata["blocked_door_openings"] = perimeter_data["blocked_door_openings"] || 0
	plan.metadata["dominant_barricade_count"] = perimeter_data["dominant_barricade_count"] || 0
	plan.metadata["primary_material_count"] = perimeter_data["primary_material_count"] || 0
	plan.metadata["secondary_material_count"] = perimeter_data["secondary_material_count"] || 0
	plan.metadata["wired_conversion_count"] = perimeter_data["wired_conversion_count"] || 0
	plan.metadata["unsupported_wired_conversions"] = perimeter_data["unsupported_wired_conversions"] || 0
	plan.metadata["generator_effect_turfs"] = plan.affected_turfs.Copy()
	return plan

/datum/world_edit_generator/outpost_radius/proc/get_outpost_param_or_default(list/params, list/defaults, param_id)
	if(islist(params) && !isnull(params[param_id]) && length("[params[param_id]]") && "[params[param_id]]" != "null")
		return params[param_id]
	if(islist(defaults))
		return defaults[param_id]
	return null

/datum/world_edit_generator/outpost_radius/proc/resolve_bounded_outpost_number(value, default_value, min_value, max_value)
	var/number_value = text2num("[value]")
	if(!isnum(number_value))
		number_value = default_value
	return clamp(round(number_value), min_value, max_value)

/datum/world_edit_generator/outpost_radius/proc/get_outpost_profile_layer_defaults(profile_id)
	var/list/defaults = list(
		"faction" = FACTION_MARINE,
		"turned_on" = TRUE,
		"sentry_layer_profile" = "none",
		"sentry_type" = /datum/human_ai_defense/defense/sentry/uscm,
		"sentry_guard_limit" = 2,
		"sentry_rear_limit" = 2,
		"sentry_corner_limit" = 4,
		"extra_defense_layer_profile" = "none",
		"extra_defense_type" = /datum/human_ai_defense/defense/tesla,
		"extra_defense_limit" = 1,
		"flag_type" = "none",
		"wire_layer_profile" = "none",
		"wire_offset" = 3,
		"wire_rows" = 1,
		"wire_row_step" = 1,
		"wire_spacing" = 2,
		"wire_concentration_percent" = 70,
		"wire_limit" = WORLD_EDIT_PLACEMENT_MAX_TOTAL_PLACEMENTS,
		"minefield_profile" = "none",
		"mine_type" = /datum/human_ai_defense/mine/claymore,
		"minefield_offset" = 3,
		"minefield_depth" = 3,
		"minefield_density_percent" = 35,
		"minefield_seed" = 0,
		"mine_limit" = WORLD_EDIT_PLACEMENT_MAX_TOTAL_PLACEMENTS,
	)

	switch("[profile_id]")
		if("outrider_camp")
			defaults["sentry_layer_profile"] = "guard"
			defaults["sentry_type"] = /datum/human_ai_defense/defense/sentry/uscm/mini
			defaults["sentry_guard_limit"] = 1
			defaults["wire_layer_profile"] = "openings"
			defaults["wire_spacing"] = 3
			defaults["wire_concentration_percent"] = 45
			defaults["wire_limit"] = 4
		if("lane_fort")
			defaults["sentry_layer_profile"] = "guard"
			defaults["sentry_type"] = /datum/human_ai_defense/defense/sentry/uscm/shotgun
			defaults["wire_layer_profile"] = "openings"
			defaults["wire_spacing"] = 2
			defaults["wire_concentration_percent"] = 70
			defaults["wire_limit"] = 8
			defaults["minefield_profile"] = "light"
			defaults["mine_type"] = /datum/human_ai_defense/mine/claymore
			defaults["minefield_depth"] = 2
			defaults["minefield_density_percent"] = 25
			defaults["mine_limit"] = 6
		if("fallback_redoubt")
			defaults["sentry_layer_profile"] = "rear"
			defaults["sentry_type"] = /datum/human_ai_defense/defense/sentry/uscm
			defaults["sentry_rear_limit"] = 2
			defaults["wire_layer_profile"] = "openings"
			defaults["wire_spacing"] = 3
			defaults["wire_concentration_percent"] = 60
			defaults["wire_limit"] = 6
			defaults["minefield_profile"] = "light"
			defaults["mine_type"] = /datum/human_ai_defense/mine/prox_sensor
			defaults["minefield_depth"] = 2
			defaults["minefield_density_percent"] = 20
			defaults["mine_limit"] = 5
			defaults["flag_type"] = /datum/human_ai_defense/defense/flag/uscm/range
		if("pocket_defense")
			defaults["sentry_layer_profile"] = "guard"
			defaults["sentry_type"] = /datum/human_ai_defense/defense/sentry/uscm/shotgun
			defaults["sentry_guard_limit"] = 2
			defaults["extra_defense_layer_profile"] = "rear"
			defaults["extra_defense_type"] = /datum/human_ai_defense/defense/tesla/stun
			defaults["extra_defense_limit"] = 1
			defaults["wire_layer_profile"] = "openings"
			defaults["wire_spacing"] = 2
			defaults["wire_concentration_percent"] = 85
			defaults["wire_limit"] = 6
			defaults["minefield_profile"] = "light"
			defaults["mine_type"] = /datum/human_ai_defense/mine/sebb
			defaults["minefield_depth"] = 2
			defaults["minefield_density_percent"] = 30
			defaults["mine_limit"] = 4
		if("crossfire_hub")
			defaults["sentry_layer_profile"] = "corners"
			defaults["sentry_type"] = /datum/human_ai_defense/defense/sentry/uscm/dmr
			defaults["sentry_corner_limit"] = 4
			defaults["extra_defense_layer_profile"] = "rear"
			defaults["extra_defense_type"] = /datum/human_ai_defense/defense/bell_tower/md
			defaults["extra_defense_limit"] = 1
			defaults["wire_layer_profile"] = "openings"
			defaults["wire_spacing"] = 2
			defaults["wire_concentration_percent"] = 65
			defaults["wire_limit"] = 6
			defaults["minefield_profile"] = "medium"
			defaults["mine_type"] = /datum/human_ai_defense/mine/m760ap
			defaults["minefield_depth"] = 3
			defaults["minefield_density_percent"] = 35
			defaults["mine_limit"] = 8
		if("anti_vehicle_stop")
			defaults["sentry_layer_profile"] = "guard_corners"
			defaults["sentry_type"] = /datum/human_ai_defense/defense/sentry/uscm/dmr
			defaults["sentry_guard_limit"] = 2
			defaults["sentry_corner_limit"] = 2
			defaults["extra_defense_layer_profile"] = "rear"
			defaults["extra_defense_type"] = /datum/human_ai_defense/defense/tesla
			defaults["extra_defense_limit"] = 1
			defaults["wire_layer_profile"] = "perimeter"
			defaults["wire_rows"] = 2
			defaults["wire_row_step"] = 2
			defaults["wire_spacing"] = 2
			defaults["wire_concentration_percent"] = 85
			defaults["wire_limit"] = 18
			defaults["minefield_profile"] = "dense"
			defaults["mine_type"] = /datum/human_ai_defense/mine/m760ap/strong
			defaults["minefield_depth"] = 4
			defaults["minefield_density_percent"] = 65
			defaults["mine_limit"] = 14
		if("forward_medical_cover")
			defaults["sentry_layer_profile"] = "rear"
			defaults["sentry_type"] = /datum/human_ai_defense/defense/sentry/uscm/mini
			defaults["sentry_rear_limit"] = 1
			defaults["wire_layer_profile"] = "openings"
			defaults["wire_spacing"] = 4
			defaults["wire_concentration_percent"] = 35
			defaults["wire_limit"] = 3
			defaults["flag_type"] = /datum/human_ai_defense/defense/flag/uscm

	return defaults

/datum/world_edit_generator/outpost_radius/proc/add_outpost_layer_rule(list/rules, kind, group_id, limit, defense_path, turned_on = null)
	if(!islist(rules) || !length("[kind]") || !length("[group_id]") || !ispath(defense_path, /datum/human_ai_defense))
		return

	var/list/rule = list(
		"kind" = "[kind]",
		"group" = "[group_id]",
		"limit" = max(round(text2num("[limit]") || 0), 1),
		"defense_path" = defense_path,
	)
	if(!isnull(turned_on))
		rule["turned_on"] = turned_on ? TRUE : FALSE
	rules += list(rule)

/datum/world_edit_generator/outpost_radius/proc/build_outpost_effective_defense_profile(list/config, list/base_profile)
	var/list/base_wired_groups = islist(base_profile) && islist(base_profile["wired_groups"]) ? base_profile["wired_groups"] : null
	var/list/profile = list(
		"label" = islist(base_profile) ? (base_profile["label"] || "Custom") : "Custom",
		"description" = islist(base_profile) ? (base_profile["description"] || "") : "",
		"defense_rules" = list(),
		"wired_groups" = isnull(base_wired_groups) ? list() : base_wired_groups.Copy(),
	)
	var/list/rules = profile["defense_rules"]
	var/turned_on = GLOB.world_edit_helpers.parse_bool(config["turned_on"])
	var/sentry_type = config["sentry_type"]
	var/extra_defense_type = config["extra_defense_type"]
	var/flag_type = config["flag_type"]
	var/mine_type = config["mine_type"]
	var/sentry_guard_limit = max(round(text2num("[config["sentry_guard_limit"]]") || 2), 1)
	var/sentry_rear_limit = max(round(text2num("[config["sentry_rear_limit"]]") || 2), 1)
	var/sentry_corner_limit = max(round(text2num("[config["sentry_corner_limit"]]") || 4), 1)
	var/extra_defense_limit = max(round(text2num("[config["extra_defense_limit"]]") || 1), 1)
	var/wire_limit = max(round(text2num("[config["wire_limit"]]") || WORLD_EDIT_PLACEMENT_MAX_TOTAL_PLACEMENTS), 1)
	var/mine_limit = max(round(text2num("[config["mine_limit"]]") || WORLD_EDIT_PLACEMENT_MAX_TOTAL_PLACEMENTS), 1)

	switch("[config["sentry_layer_profile"]]")
		if("guard")
			add_outpost_layer_rule(rules, "sentry", "guard_slots", sentry_guard_limit, sentry_type, turned_on)
		if("rear")
			add_outpost_layer_rule(rules, "sentry", "rear_slots", sentry_rear_limit, sentry_type, turned_on)
		if("corners")
			add_outpost_layer_rule(rules, "sentry", "corner_slots", sentry_corner_limit, sentry_type, turned_on)
		if("guard_corners")
			add_outpost_layer_rule(rules, "sentry", "guard_slots", sentry_guard_limit, sentry_type, turned_on)
			add_outpost_layer_rule(rules, "sentry", "corner_slots", sentry_corner_limit, sentry_type, turned_on)

	switch("[config["extra_defense_layer_profile"]]")
		if("rear")
			add_outpost_layer_rule(rules, "extra_defense", "rear_slots", extra_defense_limit, extra_defense_type, turned_on)
		if("corners")
			add_outpost_layer_rule(rules, "extra_defense", "corner_slots", extra_defense_limit, extra_defense_type, turned_on)

	if(ispath(flag_type, /datum/human_ai_defense/defense/flag))
		add_outpost_layer_rule(rules, "extra_defense", "rear_slots", 1, flag_type, turned_on)

	switch("[config["wire_layer_profile"]]")
		if("openings")
			add_outpost_layer_rule(rules, "wire_object", "exterior_opening_wire_slots", wire_limit, /datum/human_ai_defense/misc_defences/razorwire)
		if("perimeter")
			add_outpost_layer_rule(rules, "wire_object", "exterior_wire_slots", wire_limit, /datum/human_ai_defense/misc_defences/razorwire)

	if("[config["minefield_profile"]]" != "none")
		add_outpost_layer_rule(rules, "mine", "exterior_mine_slots", mine_limit, mine_type)

	return profile

/datum/world_edit_generator/outpost_radius/proc/resolve_outpost_configuration(list/params, list/placement_context = null)
	var/list/config = list()
	for(var/legacy_param in list("family", "guard_mode", "sentry_profile", "sentry_path", "barricade_path", "barricade_concentration_percent"))
		if(!isnull(params[legacy_param]) && length("[params[legacy_param]]") && "[params[legacy_param]]" != "null")
			config["error"] = "Устаревший параметр форпоста '[legacy_param]' больше не поддерживается."
			return config
	if(GLOB.world_edit_helpers.parse_bool(params["place_sentries"]))
		config["error"] = "Устаревший параметр форпоста 'place_sentries' больше не поддерживается."
		return config

	var/defense_profile_id = resolve_outpost_defense_profile_id(params["defense_profile"])
	if(!defense_profile_id)
		config["error"] = "Некорректный тактический профиль форпоста."
		return config

	var/list/defense_profile = get_outpost_defense_profile(defense_profile_id)
	if(!islist(defense_profile))
		config["error"] = "Некорректный тактический профиль форпоста."
		return config

	var/list/profile_layer_defaults = get_outpost_profile_layer_defaults(defense_profile_id)

	var/layout_id = resolve_outpost_layout_id(params["layout_variant"])
	if(!layout_id)
		config["error"] = "Некорректная схема форпоста."
		return config

	var/list/layout_profile = get_outpost_layout_profile(layout_id)
	if(!islist(layout_profile))
		config["error"] = "Некорректная схема форпоста."
		return config

	var/opening_width = resolve_opening_width(get_outpost_param_or_default(params, profile_layer_defaults, "opening_width"), layout_profile)
	if(isnull(opening_width))
		config["error"] = "Некорректная ширина проходов форпоста."
		return config

	var/barricade_pattern = resolve_barricade_pattern(get_outpost_param_or_default(params, profile_layer_defaults, "barricade_pattern"))
	if(isnull(barricade_pattern))
		config["error"] = "Некорректный шаблон материалов периметра."
		return config

	var/placement_dir = get_outpost_effective_placement_dir(placement_context)
	var/list/effective_layout_profile = layout_profile.Copy()
	effective_layout_profile["opening_dirs"] = get_layout_opening_dirs(layout_profile, placement_dir)
	effective_layout_profile["opening_width"] = opening_width
	effective_layout_profile["opening_slot_mode"] = get_layout_opening_slot_mode(layout_profile)
	effective_layout_profile["opening_slots_per_dir"] = get_layout_opening_slots_per_dir(layout_profile)

	var/radius = text2num("[get_outpost_param_or_default(params, profile_layer_defaults, "radius")]") || 4
	if(!isnum(radius) || radius < 1 || radius > WORLD_EDIT_OUTPOST_RADIUS_MAX)
		config["error"] = "Радиус форпоста должен оставаться в поддерживаемом диапазоне."
		return config
	opening_width = clamp(round(opening_width), 0, (radius * 2) + 1)
	effective_layout_profile["opening_width"] = opening_width

	var/primary_material_share_percent = get_primary_material_share_percent(get_outpost_param_or_default(params, profile_layer_defaults, "primary_material_share_percent"))
	var/place_barricade_doors = GLOB.world_edit_helpers.parse_bool(get_outpost_param_or_default(params, profile_layer_defaults, "place_barricade_doors"))
	var/list/radius_policy = GLOB.world_edit_helpers.get_world_edit_radius_policy(params)
	var/primary_material_path = resolve_whitelisted_type(get_outpost_param_or_default(params, profile_layer_defaults, "primary_material_path"), allowed_barricade_types, /datum/human_ai_defense/barricade, /datum/human_ai_defense/barricade/metal)
	if(!primary_material_path)
		config["error"] = "Некорректный основной материал периметра."
		return config

	var/secondary_material_path = resolve_whitelisted_type(get_outpost_param_or_default(params, profile_layer_defaults, "secondary_material_path"), allowed_barricade_types, /datum/human_ai_defense/barricade, primary_material_path)
	if(!secondary_material_path)
		secondary_material_path = primary_material_path
	if(barricade_pattern == "uniform")
		secondary_material_path = primary_material_path
		primary_material_share_percent = 100

	var/primary_door_path = resolve_outpost_door_selection(get_outpost_param_or_default(params, profile_layer_defaults, "primary_door_path"))
	if(isnull(primary_door_path))
		config["error"] = "Некорректный материал основной двери."
		return config
	var/secondary_door_path = resolve_outpost_door_selection(get_outpost_param_or_default(params, profile_layer_defaults, "secondary_door_path"))
	if(isnull(secondary_door_path))
		config["error"] = "Некорректный материал вспомогательной двери."
		return config
	if(barricade_pattern == "uniform")
		secondary_door_path = primary_door_path

	var/faction = resolve_outpost_faction(get_outpost_param_or_default(params, profile_layer_defaults, "faction"), FACTION_MARINE)
	if(isnull(faction))
		config["error"] = "Selected outpost faction is not allowed."
		return config
	var/turned_on = GLOB.world_edit_helpers.parse_bool(get_outpost_param_or_default(params, profile_layer_defaults, "turned_on"))

	var/sentry_layer_profile = resolve_id_option(get_outpost_param_or_default(params, profile_layer_defaults, "sentry_layer_profile"), list("none", "guard", "rear", "corners", "guard_corners"), "none")
	if(isnull(sentry_layer_profile))
		config["error"] = "Selected sentry layer profile is not allowed."
		return config
	var/sentry_type = resolve_whitelisted_type(get_outpost_param_or_default(params, profile_layer_defaults, "sentry_type"), allowed_sentry_types, /datum/human_ai_defense/defense/sentry, /datum/human_ai_defense/defense/sentry/uscm)
	if(!sentry_type)
		config["error"] = "Selected sentry type is not allowed."
		return config

	var/extra_defense_layer_profile = resolve_id_option(get_outpost_param_or_default(params, profile_layer_defaults, "extra_defense_layer_profile"), list("none", "rear", "corners"), "none")
	if(isnull(extra_defense_layer_profile))
		config["error"] = "Selected extra defense layer profile is not allowed."
		return config
	var/extra_defense_type = resolve_whitelisted_type(get_outpost_param_or_default(params, profile_layer_defaults, "extra_defense_type"), allowed_extra_defense_types, /datum/human_ai_defense/defense, /datum/human_ai_defense/defense/tesla)
	if(!extra_defense_type)
		config["error"] = "Selected extra defense type is not allowed."
		return config

	var/flag_type = resolve_optional_whitelisted_type(get_outpost_param_or_default(params, profile_layer_defaults, "flag_type"), allowed_flag_types, /datum/human_ai_defense/defense/flag, profile_layer_defaults["flag_type"])
	if(isnull(flag_type))
		config["error"] = "Selected flag type is not allowed."
		return config

	var/sentry_guard_limit = resolve_bounded_outpost_number(get_outpost_param_or_default(params, profile_layer_defaults, "sentry_guard_limit"), 2, 1, 8)
	var/sentry_rear_limit = resolve_bounded_outpost_number(get_outpost_param_or_default(params, profile_layer_defaults, "sentry_rear_limit"), 2, 1, 8)
	var/sentry_corner_limit = resolve_bounded_outpost_number(get_outpost_param_or_default(params, profile_layer_defaults, "sentry_corner_limit"), 4, 1, 8)
	var/extra_defense_limit = resolve_bounded_outpost_number(get_outpost_param_or_default(params, profile_layer_defaults, "extra_defense_limit"), 1, 1, 8)

	var/wire_layer_profile = resolve_id_option(get_outpost_param_or_default(params, profile_layer_defaults, "wire_layer_profile"), list("none", "openings", "perimeter"), "none")
	if(isnull(wire_layer_profile))
		config["error"] = "Selected wire layer profile is not allowed."
		return config
	var/wire_offset = resolve_bounded_outpost_number(get_outpost_param_or_default(params, profile_layer_defaults, "wire_offset"), 3, 1, 12)
	var/wire_rows = resolve_bounded_outpost_number(get_outpost_param_or_default(params, profile_layer_defaults, "wire_rows"), 1, 0, 8)
	var/wire_row_step = resolve_bounded_outpost_number(get_outpost_param_or_default(params, profile_layer_defaults, "wire_row_step"), 1, 1, 6)
	var/wire_spacing = resolve_bounded_outpost_number(get_outpost_param_or_default(params, profile_layer_defaults, "wire_spacing"), 2, 1, 12)
	var/wire_concentration_percent = resolve_bounded_outpost_number(get_outpost_param_or_default(params, profile_layer_defaults, "wire_concentration_percent"), 70, 0, 100)
	var/wire_limit = resolve_bounded_outpost_number(get_outpost_param_or_default(params, profile_layer_defaults, "wire_limit"), WORLD_EDIT_PLACEMENT_MAX_TOTAL_PLACEMENTS, 1, WORLD_EDIT_PLACEMENT_MAX_TOTAL_PLACEMENTS)

	var/minefield_profile = resolve_id_option(get_outpost_param_or_default(params, profile_layer_defaults, "minefield_profile"), list("none", "light", "medium", "dense"), "none")
	if(isnull(minefield_profile))
		config["error"] = "Selected minefield profile is not allowed."
		return config
	var/mine_type = resolve_whitelisted_type(get_outpost_param_or_default(params, profile_layer_defaults, "mine_type"), allowed_mine_types, /datum/human_ai_defense/mine, /datum/human_ai_defense/mine/claymore)
	if(!mine_type)
		config["error"] = "Selected mine type is not allowed."
		return config
	var/minefield_offset = resolve_bounded_outpost_number(get_outpost_param_or_default(params, profile_layer_defaults, "minefield_offset"), 3, 1, 12)
	var/minefield_depth = resolve_bounded_outpost_number(get_outpost_param_or_default(params, profile_layer_defaults, "minefield_depth"), 3, 0, 8)
	var/minefield_density_percent = resolve_bounded_outpost_number(get_outpost_param_or_default(params, profile_layer_defaults, "minefield_density_percent"), 35, 0, 100)
	var/minefield_seed = resolve_bounded_outpost_number(get_outpost_param_or_default(params, profile_layer_defaults, "minefield_seed"), 0, 0, 999999)
	var/mine_limit = resolve_bounded_outpost_number(get_outpost_param_or_default(params, profile_layer_defaults, "mine_limit"), WORLD_EDIT_PLACEMENT_MAX_TOTAL_PLACEMENTS, 1, WORLD_EDIT_PLACEMENT_MAX_TOTAL_PLACEMENTS)

	config["defense_profile"] = defense_profile_id
	config["base_defense_profile_data"] = defense_profile
	config["layout_variant"] = layout_id
	config["layout_profile"] = effective_layout_profile
	config["placement_dir"] = placement_dir
	config["opening_width"] = opening_width
	config["radius"] = radius
	config["radius_policy"] = radius_policy
	config["barricade_pattern"] = barricade_pattern
	config["primary_material_path"] = primary_material_path
	config["secondary_material_path"] = secondary_material_path
	config["primary_material_share_percent"] = primary_material_share_percent
	config["place_barricade_doors"] = place_barricade_doors
	config["primary_door_path"] = primary_door_path
	config["secondary_door_path"] = secondary_door_path
	config["faction"] = faction
	config["turned_on"] = turned_on
	config["sentry_layer_profile"] = sentry_layer_profile
	config["sentry_type"] = sentry_type
	config["sentry_guard_limit"] = sentry_guard_limit
	config["sentry_rear_limit"] = sentry_rear_limit
	config["sentry_corner_limit"] = sentry_corner_limit
	config["extra_defense_layer_profile"] = extra_defense_layer_profile
	config["extra_defense_type"] = extra_defense_type
	config["extra_defense_limit"] = extra_defense_limit
	config["flag_type"] = flag_type
	config["wire_layer_profile"] = wire_layer_profile
	config["wire_offset"] = wire_offset
	config["wire_rows"] = wire_rows
	config["wire_row_step"] = wire_row_step
	config["wire_spacing"] = wire_spacing
	config["wire_concentration_percent"] = wire_concentration_percent
	config["wire_limit"] = wire_limit
	config["minefield_profile"] = minefield_profile
	config["mine_type"] = mine_type
	config["minefield_offset"] = minefield_offset
	config["minefield_depth"] = minefield_depth
	config["minefield_density_percent"] = minefield_density_percent
	config["minefield_seed"] = minefield_seed
	config["mine_limit"] = mine_limit
	config["defense_profile_data"] = build_outpost_effective_defense_profile(config, defense_profile)
	config["needs_anchor_map"] = outpost_defense_profile_needs_anchor_map(config["defense_profile_data"])
	return config

/datum/world_edit_generator/outpost_radius/proc/build_outpost_exact_plan_context(datum/world_edit_shape_contract/shape_contract, list/params, list/placement_context)
	var/shape_id = "[shape_contract?.shape_id || placement_context["shape"] || WORLD_EDIT_SHAPE_POINT]"
	var/list/anchor_turfs = shape_contract?.copy_anchor_turfs() || placement_context["anchor_turfs"]
	var/effective_shape_id = shape_id
	var/support_class = get_outpost_shape_support_class(effective_shape_id)
	var/list/support_metadata = list(
		"planner_version" = WORLD_EDIT_OUTPOST_PLANNER_VERSION,
		"shape_support_class" = support_class,
		"shape_requested_id" = shape_id,
		"shape_effective_id" = effective_shape_id,
	)
	var/list/context = list(
		"shape_id" = shape_id,
		"support_class" = support_class,
		"support_metadata" = support_metadata,
		"effective_shape_id" = effective_shape_id,
		"config" = null,
		"footprint_turfs" = list(),
		"footprint_components" = list(),
		"seed_turf" = null,
		"shape_analysis" = null,
		"error" = null,
	)
	if(!islist(anchor_turfs) || !length(anchor_turfs))
		context["error"] = "Не удалось определить контур формы."
		return context

	var/list/config = resolve_outpost_configuration(params, placement_context)
	if(config["error"])
		context["error"] = "[config["error"]]"
		return context
	var/initial_support_error = get_outpost_shape_support_validation_error(shape_id, anchor_turfs, placement_context)
	if(length("[initial_support_error]"))
		context["error"] = initial_support_error
		return context

	var/list/normalized_footprint = normalize_outpost_footprint(anchor_turfs, shape_id)
	if(normalized_footprint["error"])
		context["error"] = "[normalized_footprint["error"]]"
		if(normalized_footprint["budget_kind"])
			stamp_outpost_budget_metadata(support_metadata, normalized_footprint["budget_kind"], normalized_footprint["budget_actual"], normalized_footprint["budget_limit"])
		return context
	var/list/footprint_turfs = normalized_footprint["turfs"]
	var/list/footprint_components = split_outpost_footprint_components(footprint_turfs)
	if(!length(footprint_components))
		footprint_components = list(footprint_turfs)

	effective_shape_id = get_outpost_effective_shape_id(shape_id, shape_contract, placement_context, footprint_turfs)
	support_class = get_outpost_shape_support_class(effective_shape_id)
	support_metadata["shape_support_class"] = support_class
	support_metadata["shape_effective_id"] = effective_shape_id

	var/turf/seed_turf = resolve_outpost_shape_seed_turf(footprint_turfs, placement_context)
	if(!istype(seed_turf))
		seed_turf = footprint_turfs[1]

	var/support_validation_error = get_outpost_shape_support_validation_error(effective_shape_id, footprint_turfs, placement_context)
	if(length("[support_validation_error]"))
		context["error"] = support_validation_error
		return context

	context["support_class"] = support_class
	context["effective_shape_id"] = effective_shape_id
	context["config"] = config
	context["footprint_turfs"] = footprint_turfs
	context["footprint_components"] = footprint_components
	context["seed_turf"] = seed_turf
	if(effective_shape_id == WORLD_EDIT_SHAPE_POINT)
		return context
	if(length(footprint_components) > 1)
		return context

	var/list/shape_analysis = build_outpost_shape_analysis(footprint_turfs, config, placement_context)
	if(shape_analysis["error"])
		context["error"] = "[shape_analysis["error"]]"
		if(shape_analysis["budget_kind"])
			stamp_outpost_budget_metadata(support_metadata, shape_analysis["budget_kind"], shape_analysis["budget_actual"], shape_analysis["budget_limit"])
		return context

	var/list/candidate_slots = shape_analysis["filtered_candidate_slots"]
	if(!length(candidate_slots))
		context["error"] = get_outpost_radius_policy_error(effective_shape_id)
		return context

	var/list/opening_dirs = shape_analysis["opening_dirs"]
	if(length(opening_dirs))
		var/list/opening_slots_by_dir = shape_analysis["opening_slots_by_dir"]
		var/required_opening_tiles_per_dir = get_layout_total_opening_tiles_per_dir(config["layout_profile"])
		for(var/opening_dir as anything in opening_dirs)
			if((opening_slots_by_dir["[opening_dir]"] || 0) < required_opening_tiles_per_dir)
				context["error"] = get_outpost_radius_policy_error(effective_shape_id)
				return context

	context["shape_analysis"] = shape_analysis
	return context

/datum/world_edit_generator/outpost_radius/evaluate_shape_contract(datum/world_edit_shape_contract/shape_contract, list/params, list/placement_context)
	var/list/plan_context = build_outpost_exact_plan_context(shape_contract, params, placement_context)
	var/support_class = plan_context["support_class"] || get_outpost_shape_support_class(shape_contract?.shape_id || WORLD_EDIT_SHAPE_POINT)
	var/list/raw_support_metadata = plan_context["support_metadata"]
	var/list/support_metadata = islist(raw_support_metadata) ? raw_support_metadata.Copy() : list()
	if(length("[plan_context["error"]]"))
		return list(
			"support_class" = support_class,
			"error" = "[plan_context["error"]]",
			"metadata" = support_metadata,
		)

	var/datum/world_edit_plan/plan = build_outpost_exact_plan_from_context(shape_contract, placement_context, plan_context)
	if(!istype(plan))
		return list(
			"support_class" = support_class,
			"error" = "Не удалось построить план форпоста.",
			"metadata" = support_metadata,
		)
	if(plan.metadata["error"])
		return list(
			"support_class" = support_class,
			"error" = "[plan.metadata["error"]]",
			"metadata" = support_metadata,
		)
	return list(
		"support_class" = support_class,
		"error" = null,
		"plan" = plan,
		"metadata" = support_metadata,
	)

/datum/world_edit_generator/outpost_radius/get_shape_support_error(shape_id, list/anchor_turfs, list/params, list/placement_context)
	var/datum/world_edit_shape_contract/shape_contract = build_shape_contract_from_placement_context(shape_id, anchor_turfs, placement_context)
	var/list/plan_context = build_outpost_exact_plan_context(shape_contract, params, placement_context)
	return plan_context["error"]
