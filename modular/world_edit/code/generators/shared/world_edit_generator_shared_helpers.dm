/// Нормализует любые значения в булев флаг.
/proc/world_edit_parse_bool(value)
	if(isnull(value))
		return FALSE
	if(isnum(value))
		return value ? TRUE : FALSE

	var/value_text = lowertext("[value]")
	return value_text in list("1", "true", "yes", "on", "да")

/// Преобразует cardinal DIR в строку для UI.
/proc/world_edit_dir_to_label(direction)
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

/// Преобразует строку из UI в cardinal DIR.
/proc/world_edit_dir_from_label(label, fallback_dir = NORTH)
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

/// Возвращает список турфов линии (Bresenham) между двумя точками.
/proc/world_edit_collect_line_turfs(turf/start_turf, turf/end_turf)
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

/// Двигается от тайла на указанное количество шагов в заданном направлении.
/proc/world_edit_step_turf(turf/start_turf, direction, steps = 1)
	var/turf/current_turf = start_turf
	for(var/i in 1 to steps)
		current_turf = get_step(current_turf, direction)
		if(!current_turf)
			return null
	return current_turf

/// Возвращает список image-overlay для предпросмотра на наборе тайлов.
/proc/world_edit_build_turf_preview_images(list/turfs, icon_state = "greenOverlay")
	var/list/images = list()
	if(!length(turfs))
		return images

	for(var/turf/target_turf as anything in turfs)
		var/image/overlay = image('icons/turf/overlays.dmi', target_turf, icon_state)
		overlay.plane = ABOVE_LIGHTING_PLANE
		images += overlay

	return images

/// Рисует стандартный preview на турфах через image-overlay.
/proc/world_edit_apply_turf_preview(datum/world_edit_manager/manager, list/turfs, icon_state = "greenOverlay")
	if(!manager || !manager.holder)
		return

	manager.clear_preview_images()
	var/list/images = world_edit_build_turf_preview_images(turfs, icon_state)

	if(length(images))
		manager.holder.images += images
		manager.preview_images = images.Copy()
