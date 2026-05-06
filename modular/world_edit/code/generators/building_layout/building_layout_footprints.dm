/datum/world_edit_building_footprint_mask
	var/width = 0
	var/depth = 0
	var/list/cells = list()

/datum/world_edit_building_footprint_mask/New(_width, _depth)
	. = ..()
	width = max(round(text2num("[_width]") || 0), 1)
	depth = max(round(text2num("[_depth]") || 0), 1)
	cells = list()

/datum/world_edit_building_footprint_mask/proc/cell_key(x, y)
	return "[round(x)],[round(y)]"

/datum/world_edit_building_footprint_mask/proc/set_cell(x, y, enabled = TRUE)
	x = round(x)
	y = round(y)
	if(x < 1 || x > width || y < 1 || y > depth)
		return FALSE
	if(enabled)
		cells[cell_key(x, y)] = TRUE
	else
		cells.Remove(cell_key(x, y))
	return TRUE

/datum/world_edit_building_footprint_mask/proc/has_cell(x, y)
	return cells[cell_key(x, y)] ? TRUE : FALSE

/datum/world_edit_building_footprint_mask/proc/cell_count()
	return length(cells)

/datum/world_edit_building_footprint_mask/proc/add_rect(x1, y1, x2, y2)
	x1 = clamp(round(x1), 1, width)
	x2 = clamp(round(x2), 1, width)
	y1 = clamp(round(y1), 1, depth)
	y2 = clamp(round(y2), 1, depth)
	if(x2 < x1)
		var/tmp_x = x1
		x1 = x2
		x2 = tmp_x
	if(y2 < y1)
		var/tmp_y = y1
		y1 = y2
		y2 = tmp_y
	for(var/x in x1 to x2)
		for(var/y in y1 to y2)
			set_cell(x, y, TRUE)

/datum/world_edit_building_footprint_mask/proc/sub_rect(x1, y1, x2, y2)
	x1 = clamp(round(x1), 1, width)
	x2 = clamp(round(x2), 1, width)
	y1 = clamp(round(y1), 1, depth)
	y2 = clamp(round(y2), 1, depth)
	if(x2 < x1)
		var/tmp_x = x1
		x1 = x2
		x2 = tmp_x
	if(y2 < y1)
		var/tmp_y = y1
		y1 = y2
		y2 = tmp_y
	for(var/x in x1 to x2)
		for(var/y in y1 to y2)
			set_cell(x, y, FALSE)

/datum/world_edit_building_footprint_mask/proc/to_turfs(turf/center_turf, placement_dir)
	var/list/result = list()
	var/list/result_lookup = list()
	if(!istype(center_turf))
		return result
	var/center_x = round((width + 1) / 2)
	var/center_y = round((depth + 1) / 2)
	for(var/x in 1 to width)
		for(var/y in 1 to depth)
			if(!has_cell(x, y))
				continue
			var/lateral_offset = x - center_x
			var/depth_offset = center_y - y
			var/target_x = center_turf.x
			var/target_y = center_turf.y
			switch(placement_dir)
				if(NORTH)
					target_x += lateral_offset
					target_y += depth_offset
				if(SOUTH)
					target_x += lateral_offset
					target_y -= depth_offset
				if(EAST)
					target_x += depth_offset
					target_y += lateral_offset
				if(WEST)
					target_x -= depth_offset
					target_y += lateral_offset
				else
					target_x += lateral_offset
					target_y += depth_offset
			var/turf/target_turf = locate(target_x, target_y, center_turf.z)
			GLOB.world_edit_placement_shapes.world_edit_add_turf_unique(result, result_lookup, target_turf, center_turf.z)
	return result

/datum/world_edit_generator/building_layout/proc/build_point_building_footprint(turf/seed_turf, list/config, list/placement_context)
	var/list/result = list("footprint" = list())
	if(!istype(seed_turf))
		result["error"] = "Unable to resolve building center turf."
		return result
	var/width = (round(text2num("[config["half_width"]]") || 4) * 2) + 1
	var/depth = (round(text2num("[config["half_depth"]]") || 4) * 2) + 1
	var/placement_dir = text2num("[placement_context["direction"]]")
	if(!(placement_dir in GLOB.cardinals))
		placement_dir = manager?.get_effective_placement_dir() || NORTH
	var/family = select_building_footprint_family(config, width, depth)
	var/datum/world_edit_building_prng/rng = new /datum/world_edit_building_prng(build_stage_seed(config["effective_seed"] || config["building_seed"] || 1, "footprint"))
	var/datum/world_edit_building_footprint_mask/mask = build_building_footprint_mask(family, width, depth, rng)
	if(!istype(mask) || mask.cell_count() < 9)
		family = "RECT"
		mask = build_building_footprint_mask(family, width, depth, rng)
	config["footprint_family"] = family
	result["footprint_family"] = family
	result["footprint"] = mask.to_turfs(seed_turf, placement_dir)
	return result

/datum/world_edit_generator/building_layout/proc/select_building_footprint_family(list/config, width, depth)
	var/datum/world_edit_building_archetype/archetype = get_building_archetype(config["archetype_id"])
	var/list/families = istype(archetype) && islist(archetype.footprint_families) ? archetype.footprint_families : list("RECT")
	var/list/eligible = list()
	for(var/family as anything in families)
		var/family_id = uppertext("[family]")
		if(can_build_footprint_family(family_id, width, depth))
			eligible += family_id
	if(!length(eligible))
		return "RECT"
	var/datum/world_edit_building_prng/rng = new /datum/world_edit_building_prng(build_stage_seed(config["effective_seed"] || config["building_seed"] || 1, "footprint_family"))
	return rng.pick_from(eligible) || "RECT"

/datum/world_edit_generator/building_layout/proc/can_build_footprint_family(family_id, width, depth)
	width = round(width)
	depth = round(depth)
	switch(uppertext("[family_id]"))
		if("RECT")
			return width >= 5 && depth >= 5
		if("L", "T", "WEDGE", "NESTED")
			return width >= 7 && depth >= 7
		if("U", "COMPOUND")
			return width >= 9 && depth >= 9
		if("RING")
			return width >= 9 && depth >= 9
	return FALSE

/datum/world_edit_generator/building_layout/proc/build_building_footprint_mask(family_id, width, depth, datum/world_edit_building_prng/rng)
	family_id = uppertext("[family_id]")
	var/datum/world_edit_building_footprint_mask/mask = new(width, depth)
	switch(family_id)
		if("L")
			build_l_footprint_mask(mask, rng)
		if("T")
			build_t_footprint_mask(mask, rng)
		if("U")
			build_u_footprint_mask(mask, rng)
		if("WEDGE")
			build_wedge_footprint_mask(mask, rng)
		if("RING")
			build_ring_footprint_mask(mask, rng)
		if("NESTED")
			build_nested_footprint_mask(mask, rng)
		if("COMPOUND")
			build_compound_footprint_mask(mask, rng)
		else
			mask.add_rect(1, 1, width, depth)
	return mask

/datum/world_edit_generator/building_layout/proc/build_l_footprint_mask(datum/world_edit_building_footprint_mask/mask, datum/world_edit_building_prng/rng)
	mask.add_rect(1, 1, mask.width, mask.depth)
	var/cut_width = max(2, round(mask.width / 3))
	var/cut_depth = max(2, round(mask.depth / 3))
	var/cut_right = !istype(rng) || rng.chance(50)
	if(cut_right)
		mask.sub_rect(mask.width - cut_width + 1, mask.depth - cut_depth + 1, mask.width, mask.depth)
	else
		mask.sub_rect(1, mask.depth - cut_depth + 1, cut_width, mask.depth)

/datum/world_edit_generator/building_layout/proc/build_t_footprint_mask(datum/world_edit_building_footprint_mask/mask, datum/world_edit_building_prng/rng)
	var/spine_width = max(3, round(mask.width / 3))
	if(!(spine_width % 2))
		spine_width++
	var/center_x = round((mask.width + 1) / 2)
	var/half_spine = round((spine_width - 1) / 2)
	var/back_band = max(2, round(mask.depth / 3))
	mask.add_rect(center_x - half_spine, 1, center_x + half_spine, mask.depth)
	mask.add_rect(1, mask.depth - back_band + 1, mask.width, mask.depth)

/datum/world_edit_generator/building_layout/proc/build_u_footprint_mask(datum/world_edit_building_footprint_mask/mask, datum/world_edit_building_prng/rng)
	var/wing_width = max(2, round(mask.width / 4))
	var/back_band = max(2, round(mask.depth / 3))
	mask.add_rect(1, 1, wing_width, mask.depth)
	mask.add_rect(mask.width - wing_width + 1, 1, mask.width, mask.depth)
	mask.add_rect(1, mask.depth - back_band + 1, mask.width, mask.depth)

/datum/world_edit_generator/building_layout/proc/build_wedge_footprint_mask(datum/world_edit_building_footprint_mask/mask, datum/world_edit_building_prng/rng)
	var/center_x = round((mask.width + 1) / 2)
	var/max_half = round((mask.width - 1) / 2)
	for(var/y in 1 to mask.depth)
		var/taper = round(((y - 1) * max(1, round(mask.width / 4))) / max(mask.depth - 1, 1))
		var/row_half = max(1, max_half - taper)
		mask.add_rect(center_x - row_half, y, center_x + row_half, y)

/datum/world_edit_generator/building_layout/proc/build_ring_footprint_mask(datum/world_edit_building_footprint_mask/mask, datum/world_edit_building_prng/rng)
	mask.add_rect(1, 1, mask.width, mask.depth)
	var/thickness = max(2, min(round(mask.width / 4), round(mask.depth / 4)))
	mask.sub_rect(thickness + 1, thickness + 1, mask.width - thickness, mask.depth - thickness)

/datum/world_edit_generator/building_layout/proc/build_nested_footprint_mask(datum/world_edit_building_footprint_mask/mask, datum/world_edit_building_prng/rng)
	mask.add_rect(1, 1, mask.width, mask.depth)
	var/notch_depth = max(1, round(mask.depth / 5))
	var/notch_width = max(2, round(mask.width / 4))
	if(istype(rng) && rng.chance(50))
		mask.sub_rect(1, 1, notch_width, notch_depth)
	else
		mask.sub_rect(mask.width - notch_width + 1, 1, mask.width, notch_depth)

/datum/world_edit_generator/building_layout/proc/build_compound_footprint_mask(datum/world_edit_building_footprint_mask/mask, datum/world_edit_building_prng/rng)
	var/spine_width = max(3, round(mask.width / 3))
	if(!(spine_width % 2))
		spine_width++
	var/center_x = round((mask.width + 1) / 2)
	var/half_spine = round((spine_width - 1) / 2)
	var/block_width = max(3, round(mask.width / 3))
	var/block_depth = max(3, round(mask.depth / 2))
	mask.add_rect(center_x - half_spine, 1, center_x + half_spine, mask.depth)
	mask.add_rect(1, 1, block_width, block_depth)
	mask.add_rect(mask.width - block_width + 1, mask.depth - block_depth + 1, mask.width, mask.depth)
