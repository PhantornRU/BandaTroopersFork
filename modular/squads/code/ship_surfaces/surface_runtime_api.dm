/datum/authority/branch/role/proc/get_ship_surface_target_type(list/surface_key, target_family)
	if(!islist(surface_key) || !target_family)
		return null

	var/surface_kind = surface_key["kind"]
	if(surface_kind == SHIP_SURFACE_KIND_LOCKER)
		return get_ship_surface_target_locker_type(surface_key["role"], surface_key["squad_type"], target_family)
	if(surface_kind == SHIP_SURFACE_KIND_VENDOR)
		return get_ship_surface_target_vendor_type(surface_key["vendor_key"], target_family)

	return null

/datum/authority/branch/role/proc/copy_ship_surface_transform(obj/source, obj/target)
	target.dir = source.dir
	target.pixel_x = source.pixel_x
	target.pixel_y = source.pixel_y
	target.pixel_z = source.pixel_z
	target.density = source.density
	target.anchored = source.anchored
	target.layer = source.layer
	target.plane = source.plane

/datum/authority/branch/role/proc/replace_ship_surface_fixture(atom/fixture, target_family, list/covered_squad_markers = null)
	if(!fixture || !target_family)
		return null

	var/list/surface_key = get_ship_surface_key(fixture)
	if(!islist(surface_key))
		return null

	if(surface_key["kind"] == SHIP_SURFACE_KIND_LOCKER && !is_ship_surface_supported_squad_marker(surface_key["squad_type"], covered_squad_markers))
		return null

	var/target_type = get_ship_surface_target_type(surface_key, target_family)
	if(!target_type || fixture.type == target_type)
		return null

	if(istype(fixture, /obj/structure/closet/secure_closet/marine_personal))
		return replace_ship_surface_locker(fixture, target_type)

	if(istype(fixture, /obj/structure/machinery/cm_vending))
		return replace_ship_surface_vendor(fixture, target_type)

	return null

/datum/authority/branch/role/proc/collect_main_ship_surface_fixtures(fixture_root_type, list/fixture_registry = null)
	. = list()

	var/use_registry = islist(fixture_registry) && length(fixture_registry)
	if(use_registry)
		for(var/atom/fixture as anything in fixture_registry)
			if(QDELETED(fixture) || !istype(fixture, fixture_root_type) || !is_mainship_level(fixture.z))
				continue
			if(get_ship_surface_key(fixture))
				. += fixture
		return

	for(var/atom/fixture as anything in world)
		if(QDELETED(fixture) || !istype(fixture, fixture_root_type) || !is_mainship_level(fixture.z))
			continue
		if(get_ship_surface_key(fixture))
			. += fixture

/datum/authority/branch/role/proc/apply_main_ship_surface_profile(platoon_type = get_active_ship_platoon_type())
	var/target_family = get_ship_surface_family(platoon_type)
	if(!target_family)
		return FALSE

	var/list/covered_squad_markers = get_ship_surface_related_squad_markers(platoon_type)
	var/list/lockers_to_check = collect_main_ship_surface_fixtures(/obj/structure/closet/secure_closet/marine_personal, GLOB.personal_closets)

	for(var/obj/structure/closet/secure_closet/marine_personal/locker as anything in lockers_to_check)
		if(QDELETED(locker))
			continue
		replace_ship_surface_fixture(locker, target_family, covered_squad_markers)

	var/list/vendors_to_check = collect_main_ship_surface_fixtures(/obj/structure/machinery/cm_vending, GLOB.cm_vending_machines)

	for(var/obj/structure/machinery/cm_vending/vendor as anything in vendors_to_check)
		if(QDELETED(vendor))
			continue
		replace_ship_surface_fixture(vendor, target_family, covered_squad_markers)

	return TRUE
