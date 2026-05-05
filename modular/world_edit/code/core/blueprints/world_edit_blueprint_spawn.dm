/datum/world_edit_blueprint_service/proc/world_edit_is_open_construction_turf_for_blueprint(turf/target_turf)
	if(!istype(target_turf, /turf/open))
		return FALSE

	var/turf/open/open_turf = target_turf
	return open_turf.allow_construction ? TRUE : FALSE

/datum/world_edit_blueprint_service/proc/world_edit_has_dense_blocker_for_blueprint(turf/target_turf)
	return GLOB.world_edit_helpers.has_dense_nonmob_blocker(target_turf)

/datum/world_edit_blueprint_service/proc/world_edit_validate_blueprint_target_turf(turf/target_turf, obj_path, dir_value = SOUTH)
	var/list/rule = world_edit_get_blueprint_type_rule(obj_path)
	if(!world_edit_is_open_construction_turf_for_blueprint(target_turf))
		return "Цель шаблона должна находиться на открытом строительном тайле."

	if(ispath(obj_path, /obj/structure/barricade) || (islist(rule) && "[rule["category"]]" == "barricade"))
		for(var/turf/occupied_turf as anything in world_edit_get_blueprint_occupied_turfs(target_turf, obj_path, dir_value))
			if(!world_edit_is_open_construction_turf_for_blueprint(occupied_turf))
				return "Целевой тайл шаблона должен находиться на открытом строительном тайле."
			if(GLOB.world_edit_helpers.has_dense_nonmob_blocker(occupied_turf, TRUE))
				return "Целевой тайл шаблона заблокирован для баррикады."
			if(GLOB.world_edit_helpers.has_barricade_in_dir(occupied_turf, dir_value))
				return "Целевой тайл шаблона уже содержит баррикаду с этой стороны."
		return null

	if(ispath(obj_path, /obj/structure/machinery/defenses))
		if(world_edit_has_dense_blocker_for_blueprint(target_turf))
			return "Целевой тайл шаблона заблокирован для оборонительной конструкции."
		for(var/obj/structure/machinery/defenses/existing_defense in target_turf)
			return "Целевой тайл шаблона уже содержит оборонительную конструкцию."
		return null

	if(islist(rule) && "[rule["category"]]" == "mine")
		if(world_edit_has_dense_blocker_for_blueprint(target_turf))
			return "Целевой тайл шаблона заблокирован для мины."
		for(var/obj/item/existing_item as anything in target_turf)
			if(istype(existing_item, /obj/item/explosive/mine) || istype(existing_item, /obj/item/device/assembly/prox_sensor/active))
				return "Целевой тайл шаблона уже содержит мину."
		return null

	if(islist(rule) && "[rule["category"]]" == "support_prop")
		if(world_edit_has_dense_blocker_for_blueprint(target_turf))
			return "Целевой тайл шаблона заблокирован для вспомогательного объекта."
		for(var/obj/existing_object as anything in target_turf)
			if(!istype(existing_object, /obj/structure/barricade))
				return "Целевой тайл шаблона уже содержит структуру, отличную от баррикады."
		return null

	return "Шаблон содержит неподдерживаемый тип размещения."

/datum/world_edit_blueprint_service/proc/world_edit_spawn_blueprint_entry(list/placement)
	var/obj_path = placement["obj_path"]
	var/turf/target_turf = placement["turf"]
	var/dir_value = placement["dir"]
	var/list/entry_vars = placement["vars"] || list()
	if(!istype(target_turf) || !ispath(obj_path, /obj))
		return null
	var/list/rule = world_edit_get_blueprint_type_rule(obj_path)

	if(ispath(obj_path, /obj/structure/barricade) || (islist(rule) && "[rule["category"]]" == "barricade"))
		var/obj/barricade_object = new obj_path(target_turf)
		if(istype(barricade_object))
			barricade_object.setDir(dir_value)
		return barricade_object

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

	if(islist(rule) && "[rule["category"]]" == "mine")
		var/obj/item/mine_object = new obj_path(target_turf)
		if(istype(mine_object))
			mine_object.setDir(dir_value)
			if(entry_vars["faction"] && ("iff_signal" in mine_object.vars))
				mine_object.vars["iff_signal"] = entry_vars["faction"]
		return mine_object

	if(islist(rule) && "[rule["category"]]" == "support_prop")
		var/obj/structure/support_object = new obj_path(target_turf)
		if(istype(support_object))
			support_object.setDir(dir_value)
		return support_object

	return null
