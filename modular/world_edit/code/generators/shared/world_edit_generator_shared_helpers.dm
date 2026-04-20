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
			return "Север"
		if(EAST)
			return "Восток"
		if(SOUTH)
			return "Юг"
		if(WEST)
			return "Запад"
	return "Север"

/datum/world_edit_helpers/proc/dir_to_ui_value(direction)
	switch(direction)
		if(NORTH)
			return "north"
		if(EAST)
			return "east"
		if(SOUTH)
			return "south"
		if(WEST)
			return "west"
	return "north"

/datum/world_edit_helpers/proc/dir_from_label(label, fallback_dir = NORTH)
	var/normalized_label = lowertext(trim("[label]"))
	switch(normalized_label)
		if("north")
			return NORTH
		if("east")
			return EAST
		if("south")
			return SOUTH
		if("west")
			return WEST
	switch("[label]")
		if("North")
			return NORTH
		if("Север")
			return NORTH
		if("East")
			return EAST
		if("Восток")
			return EAST
		if("South")
			return SOUTH
		if("Юг")
			return SOUTH
		if("West")
			return WEST
		if("Запад")
			return WEST
	return fallback_dir

/datum/world_edit_helpers/proc/turf_to_text(turf/target_turf)
	if(!istype(target_turf))
		return ""
	return "[target_turf.x],[target_turf.y],[target_turf.z]"

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

/datum/world_edit_helpers/proc/get_world_edit_radius_policy(list/params)
	var/list/policy = list(
		"only_clear_tiles" = TRUE,
		"only_reachable_tiles" = FALSE,
		"treat_windows_as_blockers" = TRUE,
	)
	if(!islist(params))
		return policy

	var/only_clear_raw = params[WORLD_EDIT_RADIUS_POLICY_ONLY_CLEAR_TILES]
	var/only_reachable_raw = params[WORLD_EDIT_RADIUS_POLICY_ONLY_REACHABLE_TILES]
	var/windows_blockers_raw = params[WORLD_EDIT_RADIUS_POLICY_WINDOWS_BLOCKERS]

	policy["only_clear_tiles"] = isnull(only_clear_raw) ? TRUE : parse_bool(only_clear_raw)
	policy["only_reachable_tiles"] = isnull(only_reachable_raw) ? FALSE : parse_bool(only_reachable_raw)
	policy["treat_windows_as_blockers"] = isnull(windows_blockers_raw) ? TRUE : parse_bool(windows_blockers_raw)
	if(policy["only_reachable_tiles"])
		policy["only_clear_tiles"] = TRUE

	return policy

/datum/world_edit_helpers/proc/is_radius_turf_center_blocked(turf/checking_turf, treat_windows_as_blockers = TRUE)
	if(!checking_turf || checking_turf.density)
		return TRUE

	for(var/atom/blocker as anything in checking_turf)
		if(ismob(blocker))
			continue
		if(istype(blocker, /obj/structure/window))
			if(treat_windows_as_blockers)
				return TRUE
			continue
		if(!blocker.density)
			continue
		if(blocker.flags_atom & ON_BORDER)
			continue
		return TRUE

	return FALSE

/datum/world_edit_helpers/proc/get_adjacent_radius_turfs(turf/current_turf, treat_windows_as_blockers = TRUE)
	var/list/adjacent_turfs = list()
	if(!current_turf)
		return adjacent_turfs

	if(!treat_windows_as_blockers)
		return current_turf.AdjacentTurfs()

	for(var/turf/adjacent_turf as anything in current_turf.AdjacentTurfs())
		if(is_radius_turf_center_blocked(adjacent_turf, TRUE))
			continue
		adjacent_turfs += adjacent_turf

	return adjacent_turfs

/datum/world_edit_helpers/proc/filter_radius_candidate_turfs(list/start_turfs, list/candidate_turfs, list/traversal_turfs = null, list/radius_policy = null, list/pinned_turfs = null)
	var/list/result = list()
	var/list/result_lookup = list()
	var/list/policy = islist(radius_policy) ? radius_policy : get_world_edit_radius_policy(radius_policy)
	var/only_clear_tiles = !!policy["only_clear_tiles"]
	var/only_reachable_tiles = !!policy["only_reachable_tiles"]
	var/treat_windows_as_blockers = !!policy["treat_windows_as_blockers"]
	var/list/start_lookup = list()
	var/list/pinned_lookup = list()
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

	if(islist(pinned_turfs))
		for(var/turf/pinned_turf as anything in pinned_turfs)
			if(!istype(pinned_turf))
				continue
			if(isnull(z_level))
				z_level = pinned_turf.z
			if(pinned_turf.z != z_level || pinned_lookup[pinned_turf])
				continue
			pinned_lookup[pinned_turf] = TRUE
			if(!result_lookup[pinned_turf])
				result_lookup[pinned_turf] = TRUE
				result += pinned_turf

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
			if(!pinned_lookup[candidate_turf] && (only_clear_tiles || only_reachable_tiles) && is_radius_turf_center_blocked(candidate_turf, treat_windows_as_blockers))
				continue
			filtered_candidate_lookup[candidate_turf] = TRUE
			filtered_candidates += candidate_turf
			if(!only_reachable_tiles && !result_lookup[candidate_turf])
				result_lookup[candidate_turf] = TRUE
				result += candidate_turf

	if(!only_reachable_tiles)
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
		if((only_clear_tiles || only_reachable_tiles) && is_radius_turf_center_blocked(traversal_turf, treat_windows_as_blockers))
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
		if(filtered_candidate_lookup[current_turf] && !result_lookup[current_turf])
			result_lookup[current_turf] = TRUE
			result += current_turf

		for(var/turf/adjacent_turf as anything in get_adjacent_radius_turfs(current_turf, treat_windows_as_blockers))
			if(!traversal_lookup[adjacent_turf] || visited_lookup[adjacent_turf])
				continue
			visited_lookup[adjacent_turf] = TRUE
			open_turfs += adjacent_turf

	return result

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

/datum/world_edit_helpers/proc/build_turf_preview_images(list/turfs, icon_state = "greenOverlay", color = null, alpha = null)
	var/list/images = list()
	if(!length(turfs))
		return images

	for(var/turf/target_turf as anything in turfs)
		var/image/overlay = image('icons/turf/overlays.dmi', target_turf, icon_state)
		overlay.plane = ABOVE_LIGHTING_PLANE
		if(!isnull(color))
			overlay.color = color
		if(isnum(alpha))
			overlay.alpha = clamp(round(alpha), 0, 255)
		images += overlay

	return images

/datum/world_edit_helpers/proc/build_grouped_turf_preview_images(list/groups)
	var/list/images = list()
	if(!islist(groups) || !length(groups))
		return images

	for(var/list/group as anything in groups)
		if(!islist(group))
			continue

		var/list/turfs = group["turfs"]
		var/icon_state = length("[group["icon_state"]]") ? "[group["icon_state"]]" : "greenOverlay"
		var/color = group["color"]
		var/alpha = group["alpha"]
		images += build_turf_preview_images(turfs, icon_state, color, alpha)

	return images

/datum/world_edit_helpers/proc/build_grouped_turf_preview_signature(list/groups)
	if(!islist(groups) || !length(groups))
		return md5("<empty>")

	var/list/signature_chunks = list()
	for(var/list/group as anything in groups)
		if(!islist(group))
			continue

		var/list/group_chunks = list()
		group_chunks += length("[group["icon_state"]]") ? "[group["icon_state"]]" : "greenOverlay"
		group_chunks += isnull(group["color"]) ? "" : "[group["color"]]"

		var/alpha = group["alpha"]
		group_chunks += isnum(alpha) ? "[clamp(round(alpha), 0, 255)]" : ""

		var/list/turf_chunks = list()
		var/list/turfs = group["turfs"]
		if(islist(turfs))
			for(var/turf/target_turf as anything in turfs)
				if(!istype(target_turf))
					continue
				turf_chunks += turf_to_text(target_turf)
		group_chunks += jointext(turf_chunks, ";")
		signature_chunks += jointext(group_chunks, "|")

	return md5(jointext(signature_chunks, "||"))

/datum/world_edit_helpers/proc/get_grouped_turf_preview_render_token(list/groups, render_token = null)
	if(length("[render_token]"))
		return "[render_token]"

	if(islist(groups))
		var/groups_render_token = groups["preview_render_token"]
		if(length("[groups_render_token]"))
			return "[groups_render_token]"

	return null

/datum/world_edit_helpers/proc/apply_turf_preview(datum/world_edit_manager/manager, list/turfs, icon_state = "greenOverlay", color = null, alpha = null)
	if(!manager || !manager.holder)
		return

	manager.clear_preview_images()
	var/list/images = build_turf_preview_images(turfs, icon_state, color, alpha)

	if(length(images))
		manager.holder.images += images
		manager.preview_images = images.Copy()

/datum/world_edit_helpers/proc/apply_grouped_turf_preview(datum/world_edit_manager/manager, list/groups, render_token = null)
	if(!manager || !manager.holder)
		return

	var/groups_signature = get_grouped_turf_preview_render_token(groups, render_token)
	if(!length("[groups_signature]"))
		groups_signature = build_grouped_turf_preview_signature(groups)
	if(manager.preview_groups_signature == groups_signature)
		return

	manager.clear_preview_images()
	var/list/images = build_grouped_turf_preview_images(groups)
	if(length(images))
		manager.holder.images += images
		manager.preview_images = images.Copy()
	manager.preview_groups_signature = groups_signature
