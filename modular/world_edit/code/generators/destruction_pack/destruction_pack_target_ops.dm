/datum/world_edit_generator/destruction_pack/proc/collect_area_turfs(turf/center_turf, radius)
	var/list/area_turfs = list()
	if(!center_turf)
		return area_turfs

	for(var/turf/target_turf in range(radius, center_turf))
		if(target_turf.z != center_turf.z)
			continue
		area_turfs += target_turf

	return area_turfs

/datum/world_edit_generator/destruction_pack/proc/build_area_lookup(list/area_turfs)
	var/list/area_lookup = list()
	for(var/turf/target_turf as anything in area_turfs)
		area_lookup[target_turf] = TRUE
	return area_lookup

/datum/world_edit_generator/destruction_pack/proc/should_skip_target(atom/movable/target, affect_anchored = FALSE)
	if(!target || QDELETED(target))
		return TRUE
	if(ismob(target))
		return TRUE
	if(target.anchored)
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
