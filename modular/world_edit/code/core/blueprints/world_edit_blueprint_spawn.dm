/datum/world_edit_blueprint_service/proc/world_edit_is_open_construction_turf_for_blueprint(turf/target_turf)
	if(!istype(target_turf, /turf/open))
		return FALSE

	var/turf/open/open_turf = target_turf
	return open_turf.allow_construction ? TRUE : FALSE

/datum/world_edit_blueprint_service/proc/world_edit_has_dense_blocker_for_blueprint(turf/target_turf)
	return GLOB.world_edit_helpers.has_dense_nonmob_blocker(target_turf)

/datum/world_edit_blueprint_service/proc/world_edit_validate_blueprint_target_turf(turf/target_turf, obj_path, dir_value = SOUTH)
	if(!world_edit_is_open_construction_turf_for_blueprint(target_turf))
		return "Blueprint target must be an open construction turf."

	if(ispath(obj_path, /obj/structure/barricade))
		if(GLOB.world_edit_helpers.has_dense_nonmob_blocker(target_turf, TRUE))
			return "Blueprint target turf is blocked for a barricade."
		if(GLOB.world_edit_helpers.has_barricade_in_dir(target_turf, dir_value))
			return "Blueprint target turf already contains a barricade on that side."
		return null

	if(ispath(obj_path, /obj/structure/machinery/defenses))
		if(world_edit_has_dense_blocker_for_blueprint(target_turf))
			return "Blueprint target turf is blocked for a sentry."
		for(var/obj/structure/machinery/defenses/existing_defense in target_turf)
			return "Blueprint target turf already contains a defense structure."
		return null

	return "Blueprint contains an unsupported placement type."

/datum/world_edit_blueprint_service/proc/world_edit_spawn_blueprint_entry(list/placement)
	var/obj_path = placement["obj_path"]
	var/turf/target_turf = placement["turf"]
	var/dir_value = placement["dir"]
	var/list/entry_vars = placement["vars"] || list()
	if(!istype(target_turf) || !ispath(obj_path, /obj))
		return null

	if(ispath(obj_path, /obj/structure/barricade))
		var/obj/structure/barricade/barricade = new obj_path(target_turf)
		barricade.setDir(dir_value)
		return barricade

	if(ispath(obj_path, /obj/structure/machinery/defenses))
		var/obj/structure/machinery/defenses/defense = new obj_path(target_turf)
		defense.setDir(dir_value)
		defense.placed = TRUE
		if(entry_vars["faction"])
			defense.handle_iff(entry_vars["faction"])
		if(GLOB.world_edit_helpers.parse_bool(entry_vars["turned_on"]))
			defense.power_on()
		else
			defense.power_off()
		return defense

	return null
