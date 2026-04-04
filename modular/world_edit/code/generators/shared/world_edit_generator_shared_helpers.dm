GLOBAL_DATUM_INIT(world_edit_helpers, /datum/world_edit_helpers, new)

/datum/world_edit_helpers

/datum/world_edit_helpers/proc/parse_bool(value)
	if(isnull(value))
		return FALSE
	if(isnum(value))
		return value ? TRUE : FALSE

	var/value_text = lowertext("[value]")
	return value_text in list("1", "true", "yes", "on", "да")

/datum/world_edit_helpers/proc/dir_to_label(direction)
	switch(direction)
		if(NORTH)
			return "North"
		if(EAST)
			return "East"
		if(SOUTH)
			return "South"
		if(WEST)
			return "West"
	return "North"

/datum/world_edit_helpers/proc/dir_from_label(label, fallback_dir = NORTH)
	switch("[label]")
		if("North")
			return NORTH
		if("East")
			return EAST
		if("South")
			return SOUTH
		if("West")
			return WEST
	return fallback_dir

/datum/world_edit_helpers/proc/is_cardinal_dir(direction)
	return direction in GLOB.cardinals

/datum/world_edit_helpers/proc/build_turf_dir_slot_key(turf/target_turf, direction)
	if(!istype(target_turf) || !is_cardinal_dir(direction))
		return null
	return "[target_turf.x],[target_turf.y],[target_turf.z]:[direction]"

/datum/world_edit_helpers/proc/has_barricade_in_dir(turf/target_turf, direction)
	if(!istype(target_turf) || !is_cardinal_dir(direction))
		return FALSE

	for(var/obj/structure/barricade/existing_barricade in target_turf)
		if(existing_barricade.dir == direction)
			return TRUE

	return FALSE

/datum/world_edit_helpers/proc/has_dense_nonmob_blocker(turf/target_turf, ignore_barricades = FALSE)
	if(!target_turf)
		return TRUE

	for(var/atom/movable/blocker as anything in target_turf)
		if(ismob(blocker))
			continue
		if(ignore_barricades && istype(blocker, /obj/structure/barricade))
			continue
		if(blocker.density)
			return TRUE

	return FALSE

/datum/world_edit_helpers/proc/collect_line_turfs(turf/start_turf, turf/end_turf)
	var/list/turfs = list()
	if(!start_turf || !end_turf || start_turf.z != end_turf.z)
		return turfs

	var/x0 = start_turf.x
	var/y0 = start_turf.y
	var/x1 = end_turf.x
	var/y1 = end_turf.y
	var/dx = abs(x1 - x0)
	var/dy = abs(y1 - y0)
	var/sx = x0 < x1 ? 1 : -1
	var/sy = y0 < y1 ? 1 : -1
	var/err = dx - dy

	while(TRUE)
		var/turf/current_turf = locate(x0, y0, start_turf.z)
		if(current_turf)
			turfs += current_turf
		if(x0 == x1 && y0 == y1)
			break

		var/e2 = err * 2
		if(e2 > -dy)
			err -= dy
			x0 += sx
		if(e2 < dx)
			err += dx
			y0 += sy

	return turfs

/datum/world_edit_helpers/proc/collect_rectangle_turfs(turf/start_turf, turf/end_turf)
	var/list/turfs = list()
	if(!start_turf || !end_turf || start_turf.z != end_turf.z)
		return turfs

	var/min_x = min(start_turf.x, end_turf.x)
	var/max_x = max(start_turf.x, end_turf.x)
	var/min_y = min(start_turf.y, end_turf.y)
	var/max_y = max(start_turf.y, end_turf.y)
	var/z_level = start_turf.z

	for(var/y in min_y to max_y)
		for(var/x in min_x to max_x)
			var/turf/target_turf = locate(x, y, z_level)
			if(target_turf)
				turfs += target_turf

	return turfs

/datum/world_edit_helpers/proc/step_turf(turf/start_turf, direction, steps = 1)
	var/turf/current_turf = start_turf
	for(var/i in 1 to steps)
		current_turf = get_step(current_turf, direction)
		if(!current_turf)
			return null
	return current_turf

/datum/world_edit_helpers/proc/build_turf_preview_images(list/turfs, icon_state = "greenOverlay")
	var/list/images = list()
	if(!length(turfs))
		return images

	for(var/turf/target_turf as anything in turfs)
		var/image/overlay = image('icons/turf/overlays.dmi', target_turf, icon_state)
		overlay.plane = ABOVE_LIGHTING_PLANE
		images += overlay

	return images

/datum/world_edit_helpers/proc/apply_turf_preview(datum/world_edit_manager/manager, list/turfs, icon_state = "greenOverlay")
	if(!manager || !manager.holder)
		return

	manager.clear_preview_images()
	var/list/images = build_turf_preview_images(turfs, icon_state)

	if(length(images))
		manager.holder.images += images
		manager.preview_images = images.Copy()
