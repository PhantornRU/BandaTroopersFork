/// Блок legacy-паритета:
/// в этом файле дублируются ключевые алгоритмы из существующих инструментов,
/// чтобы новый модуль World Edit мог работать автономно и не менять legacy-код.

/proc/world_edit_get_fortify_level_presets()
	return list(
		"Wood" = list("cade" = /obj/structure/barricade/wooden, "folding" = null),
		"Sandbag" = list("cade" = /obj/structure/barricade/sandbags/full, "folding" = null),
		"Sandbag (Wired)" = list("cade" = /obj/structure/barricade/sandbags/wired, "folding" = null),
		"Metal" = list("cade" = /obj/structure/barricade/metal, "folding" = /obj/structure/barricade/plasteel/metal),
		"Metal (Wired)" = list("cade" = /obj/structure/barricade/metal/wired, "folding" = /obj/structure/barricade/plasteel/metal/wired),
		"Plasteel" = list("cade" = /obj/structure/barricade/metal/plasteel, "folding" = /obj/structure/barricade/plasteel),
		"Plasteel (Wired)" = list("cade" = /obj/structure/barricade/metal/plasteel/wired, "folding" = /obj/structure/barricade/plasteel/wired),
	)

/proc/world_edit_has_barricade_in_dir(turf/scan_turf, dir_to_check)
	for(var/obj/structure/barricade/existing_cade in scan_turf)
		if(existing_cade.dir == dir_to_check)
			return TRUE
	return FALSE

/proc/world_edit_has_preview_placement(list/placements, turf/target_turf, dir_to_check)
	for(var/list/entry as anything in placements)
		if(entry["turf"] == target_turf && entry["dir"] == dir_to_check)
			return TRUE
	return FALSE

/proc/world_edit_recursive_room_preview(turf/start_turf, turf/scan_turf, list/turf_list, list/placements, folding_cade_type, tile_scan_limit, scan_radius, respect_windows, respect_doors)
	if(length(turf_list) > tile_scan_limit)
		return FALSE
	if(scan_radius > 0 && get_dist(start_turf, scan_turf) > scan_radius)
		return TRUE
	if(istype(scan_turf, /turf/closed))
		return TRUE
	if(scan_turf in turf_list)
		return TRUE

	if(respect_doors && locate(/obj/structure/machinery/door) in scan_turf)
		return TRUE
	if(respect_windows && ((locate(/obj/structure/window_frame) in scan_turf) || (locate(/obj/structure/window) in scan_turf)))
		return TRUE

	turf_list += scan_turf
	for(var/cardinal in GLOB.cardinals)
		var/turf/nearby_turf = get_step(scan_turf, cardinal)
		if(!nearby_turf)
			continue
		if(scan_radius > 0 && get_dist(start_turf, nearby_turf) > scan_radius)
			continue

		if(respect_windows && ((locate(/obj/structure/window_frame) in nearby_turf) || (locate(/obj/structure/window) in nearby_turf)))
			if(!world_edit_has_preview_placement(placements, scan_turf, cardinal))
				placements += list(list(
					"turf" = scan_turf,
					"dir" = cardinal,
					"is_folding" = FALSE
				))

		if(folding_cade_type && respect_doors && (locate(/obj/structure/machinery/door) in nearby_turf))
			if(!world_edit_has_preview_placement(placements, scan_turf, cardinal))
				placements += list(list(
					"turf" = scan_turf,
					"dir" = cardinal,
					"is_folding" = TRUE
				))

		if(!world_edit_recursive_room_preview(start_turf, nearby_turf, turf_list, placements, folding_cade_type, tile_scan_limit, scan_radius, respect_windows, respect_doors))
			return FALSE
	return TRUE

/proc/world_edit_collect_room_fortify_preview(turf/start_turf, folding_cade_type, tile_scan_limit = 195, scan_radius = 12, respect_windows = TRUE, respect_doors = TRUE)
	var/list/turf_list = list()
	var/list/placements = list()
	var/success = world_edit_recursive_room_preview(start_turf, start_turf, turf_list, placements, folding_cade_type, tile_scan_limit, scan_radius, respect_windows, respect_doors)
	return list(
		"success" = success,
		"tiles" = turf_list,
		"placements" = placements
	)

/proc/world_edit_apply_room_fortify(turf/start_turf, cade_type, folding_cade_type, tile_scan_limit = 195, scan_radius = 12, respect_windows = TRUE, respect_doors = TRUE)
	var/list/preview_data = world_edit_collect_room_fortify_preview(start_turf, folding_cade_type, tile_scan_limit, scan_radius, respect_windows, respect_doors)
	var/list/turf_list = preview_data["tiles"]
	var/list/placements = preview_data["placements"]
	var/success = preview_data["success"]

	if(!success)
		return list(
			"success" = FALSE,
			"tiles_scanned" = length(turf_list),
			"placements_created" = 0
		)

	var/placements_created = 0
	for(var/list/entry as anything in placements)
		var/turf/placement_turf = entry["turf"]
		var/placement_dir = entry["dir"]
		var/is_folding = entry["is_folding"]

		if(world_edit_has_barricade_in_dir(placement_turf, placement_dir))
			continue

		if(is_folding)
			var/obj/structure/barricade/plasteel/folding_cade = new folding_cade_type(placement_turf)
			folding_cade.setDir(placement_dir)
			folding_cade.open(folding_cade) // Закрываем как в legacy-версии
		else
			var/obj/structure/barricade/cade = new cade_type(placement_turf)
			cade.setDir(placement_dir)

		placements_created++

	return list(
		"success" = TRUE,
		"tiles_scanned" = length(turf_list),
		"placements_created" = placements_created
	)

/// Каталог защит строится через рефлексию по /datum/human_ai_defense.
/proc/world_edit_build_defense_catalog()
	var/list/catalog = list()
	for(var/defense_type in subtypesof(/datum/human_ai_defense))
		if(!defense_type::name)
			continue

		var/category = defense_type::category || "default"
		if(!catalog[category])
			catalog[category] = list()

		catalog[category] += list(list(
			"name" = defense_type::name,
			"path" = defense_type,
			"description" = defense_type::desc,
			"uses_faction" = defense_type::uses_faction,
			"uses_turned_on" = defense_type::uses_turned_on,
		))
	return catalog

/proc/world_edit_spawn_defense_by_path(turf/loc_to_spawn, dir_to_spawn, defense_path, faction, turned_on)
	if(!ispath(defense_path, /datum/human_ai_defense))
		return FALSE

	var/datum/human_ai_defense/defense_object = new defense_path()
	defense_object.spawn_object(loc_to_spawn, dir_to_spawn, faction, turned_on)
	return TRUE

/proc/world_edit_get_breach_charge_dict()
	return list(
		/obj/item/explosive/plastic::name = /obj/item/explosive/plastic,
		/obj/item/explosive/plastic/breaching_charge::name = /obj/item/explosive/plastic/breaching_charge,
		/obj/item/explosive/plastic/breaching_charge/rubber::name = /obj/item/explosive/plastic/breaching_charge/rubber,
		/obj/item/explosive/plastic/breaching_charge/plasma::name = /obj/item/explosive/plastic/breaching_charge/plasma,
	)

/proc/world_edit_get_breach_direction_dict()
	return list(
		"North" = NORTH,
		"East" = EAST,
		"South" = SOUTH,
		"West" = WEST,
	)

/proc/world_edit_get_breach_allowed_profiles()
	return list(
		"Стандартный" = list(
			/turf/closed/wall,
			/obj/effect,
			/obj/structure/machinery,
			/obj/structure/closet,
			/obj/structure/window,
		),
		"Только стены" = list(
			/turf/closed/wall,
		),
		"Стены и окна" = list(
			/turf/closed/wall,
			/obj/structure/window,
		)
	)

/proc/world_edit_place_breach_charge(mob/user, atom/object, charge_path, place_dir, list/allowed_types)
	if(!is_type_in_list(object, allowed_types))
		return FALSE

	var/obj/item/explosive/plastic/new_c4 = new charge_path(get_turf(object))
	new_c4.plant_target = object
	new_c4.cause_data = create_cause_data(initial(new_c4.name), user)
	new_c4.icon_state = new_c4.overlay_image
	new_c4.layer = BELOW_MOB_LAYER
	new_c4.setDir(place_dir)

	if(!istype(object, /obj/structure/window) && !istype(object, /turf/closed))
		object.contents += new_c4
		new_c4.overlay = image('icons/obj/items/assemblies.dmi', new_c4.overlay_image)
		new_c4.overlay.layer = ABOVE_XENO_LAYER
		object.overlays += new_c4.overlay

	new_c4.active = TRUE
	addtimer(CALLBACK(new_c4, TYPE_PROC_REF(/obj/item/explosive/plastic, prime)), new_c4.timer SECONDS)
	return TRUE
