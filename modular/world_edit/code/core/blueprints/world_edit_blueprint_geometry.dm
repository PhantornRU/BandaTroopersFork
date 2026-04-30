/datum/world_edit_blueprint_service/proc/world_edit_build_blueprint_relative_slot_key(obj_path, dx, dy, dz, dir_value)
	var/list/slot_keys = world_edit_build_blueprint_relative_slot_keys(obj_path, dx, dy, dz, dir_value)
	if(!length(slot_keys))
		return null
	return slot_keys[1]

/datum/world_edit_blueprint_service/proc/world_edit_build_blueprint_relative_slot_keys(obj_path, dx, dy, dz, dir_value)
	var/list/slot_keys = list()
	var/list/occupied_offsets = world_edit_get_blueprint_occupied_offsets(obj_path, dir_value)
	if(!length(occupied_offsets))
		return slot_keys

	var/is_directional = ispath(obj_path, /obj/structure/barricade) || world_edit_blueprint_type_is_category(obj_path, "barricade")
	if(is_directional && !(dir_value in GLOB.cardinals))
		return list()

	for(var/list/offset as anything in occupied_offsets)
		if(!islist(offset) || length(offset) < 2)
			continue
		var/occupied_dx = dx + (text2num("[offset[1]]") || 0)
		var/occupied_dy = dy + (text2num("[offset[2]]") || 0)
		if(is_directional)
			slot_keys += "[occupied_dx],[occupied_dy],[dz]:[dir_value]"
		else
			slot_keys += "[occupied_dx],[occupied_dy],[dz]"

	return slot_keys

/datum/world_edit_blueprint_service/proc/world_edit_build_blueprint_target_slot_key(turf/target_turf, obj_path, dir_value)
	var/list/slot_keys = world_edit_build_blueprint_target_slot_keys(target_turf, obj_path, dir_value)
	if(!length(slot_keys))
		return null
	return slot_keys[1]

/datum/world_edit_blueprint_service/proc/world_edit_build_blueprint_target_slot_keys(turf/target_turf, obj_path, dir_value)
	var/list/slot_keys = list()
	if(!istype(target_turf))
		return slot_keys

	var/list/occupied_turfs = world_edit_get_blueprint_occupied_turfs(target_turf, obj_path, dir_value)
	var/is_directional = ispath(obj_path, /obj/structure/barricade) || world_edit_blueprint_type_is_category(obj_path, "barricade")
	for(var/turf/occupied_turf as anything in occupied_turfs)
		if(!istype(occupied_turf))
			continue
		if(is_directional)
			slot_keys += GLOB.world_edit_helpers.build_turf_dir_slot_key(occupied_turf, dir_value)
		else
			slot_keys += "[occupied_turf.x],[occupied_turf.y],[occupied_turf.z]"

	return slot_keys

/datum/world_edit_blueprint_service/proc/world_edit_blueprint_type_is_category(obj_path, category)
	var/list/rule = world_edit_get_blueprint_type_rule(obj_path)
	return islist(rule) && "[rule["category"]]" == "[category]"

/datum/world_edit_blueprint_service/proc/world_edit_get_blueprint_occupied_offsets(obj_path, dir_value)
	var/list/offsets = list(list(0, 0))
	if(!ispath(obj_path, /obj/structure/covenant_barricade/wide))
		return offsets

	switch(dir_value)
		if(NORTH, SOUTH)
			offsets += list(list(-1, 0), list(1, 0))
		if(EAST, WEST)
			offsets += list(list(0, -1), list(0, 1))
	return offsets

/datum/world_edit_blueprint_service/proc/world_edit_get_blueprint_occupied_turfs(turf/target_turf, obj_path, dir_value)
	var/list/occupied_turfs = list()
	if(!istype(target_turf))
		return occupied_turfs

	for(var/list/offset as anything in world_edit_get_blueprint_occupied_offsets(obj_path, dir_value))
		if(!islist(offset) || length(offset) < 2)
			continue
		var/turf/occupied_turf = locate(target_turf.x + (text2num("[offset[1]]") || 0), target_turf.y + (text2num("[offset[2]]") || 0), target_turf.z)
		if(istype(occupied_turf))
			occupied_turfs += occupied_turf
	return occupied_turfs

/datum/world_edit_blueprint_service/proc/world_edit_rotate_blueprint_offset(dx, dy, placement_dir)
	switch(placement_dir)
		if(EAST)
			return list("dx" = dy, "dy" = -dx)
		if(SOUTH)
			return list("dx" = -dx, "dy" = -dy)
		if(WEST)
			return list("dx" = -dy, "dy" = dx)
		else
			return list("dx" = dx, "dy" = dy)

/datum/world_edit_blueprint_service/proc/world_edit_rotate_blueprint_dir(dir_value, placement_dir)
	if(!(dir_value in GLOB.cardinals))
		return dir_value

	switch(placement_dir)
		if(EAST)
			switch(dir_value)
				if(NORTH)
					return EAST
				if(EAST)
					return SOUTH
				if(SOUTH)
					return WEST
				if(WEST)
					return NORTH
		if(SOUTH)
			switch(dir_value)
				if(NORTH)
					return SOUTH
				if(EAST)
					return WEST
				if(SOUTH)
					return NORTH
				if(WEST)
					return EAST
		if(WEST)
			switch(dir_value)
				if(NORTH)
					return WEST
				if(EAST)
					return NORTH
				if(SOUTH)
					return EAST
				if(WEST)
					return SOUTH
	return dir_value
