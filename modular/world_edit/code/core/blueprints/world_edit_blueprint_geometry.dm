/datum/world_edit_blueprint_service/proc/world_edit_build_blueprint_relative_slot_key(obj_path, dx, dy, dz, dir_value)
	if(ispath(obj_path, /obj/structure/barricade) || world_edit_blueprint_type_is_category(obj_path, "barricade"))
		if(!(dir_value in GLOB.cardinals))
			return null
		return "[dx],[dy],[dz]:[dir_value]"
	return "[dx],[dy],[dz]"

/datum/world_edit_blueprint_service/proc/world_edit_build_blueprint_target_slot_key(turf/target_turf, obj_path, dir_value)
	if(!istype(target_turf))
		return null
	if(ispath(obj_path, /obj/structure/barricade) || world_edit_blueprint_type_is_category(obj_path, "barricade"))
		return GLOB.world_edit_helpers.build_turf_dir_slot_key(target_turf, dir_value)
	return "[target_turf.x],[target_turf.y],[target_turf.z]"

/datum/world_edit_blueprint_service/proc/world_edit_blueprint_type_is_category(obj_path, category)
	var/list/rule = world_edit_get_blueprint_type_rule(obj_path)
	return islist(rule) && "[rule["category"]]" == "[category]"

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
