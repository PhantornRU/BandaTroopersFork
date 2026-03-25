#define SHIP_SURFACE_FAMILY_USCM "uscm"
#define SHIP_SURFACE_FAMILY_UNSC "unsc"
#define SHIP_SURFACE_FAMILY_ODST "odst"

#define SHIP_SURFACE_KIND_LOCKER "locker"
#define SHIP_SURFACE_KIND_VENDOR "vendor"

#define SHIP_SURFACE_VENDOR_SQUAD_PREP_UNIFORM "squad_prep_uniform"
#define SHIP_SURFACE_VENDOR_SQUAD_PREP_GUNS "squad_prep_guns"
#define SHIP_SURFACE_VENDOR_MEDIC_CLOTHING "medic_clothing"
#define SHIP_SURFACE_VENDOR_MEDIC_CHEMICAL "medic_chemical"
#define SHIP_SURFACE_VENDOR_MEDBAY_BASIC "medbay_basic"
#define SHIP_SURFACE_VENDOR_MARINE_FOOD "marine_food"
#define SHIP_SURFACE_VENDOR_MARINE_FOOD_ALT "marine_food_alt"

/datum/authority/branch/role/proc/get_ship_surface_family(platoon_type)
	platoon_type = normalize_ship_platoon_type(platoon_type)
	switch(platoon_type)
		if(/datum/squad/marine/alpha, /datum/squad/marine/bravo, /datum/squad/marine/charlie, /datum/squad/marine/delta)
			return SHIP_SURFACE_FAMILY_USCM
		if(/datum/squad/marine/halo/unsc/alpha, /datum/squad/marine/halo/unsc/bravo, /datum/squad/marine/halo/unsc/charlie, /datum/squad/marine/halo/unsc/delta)
			return SHIP_SURFACE_FAMILY_UNSC
		if(/datum/squad/marine/halo/odst/alpha, /datum/squad/marine/halo/odst/bravo, /datum/squad/marine/halo/odst/charlie, /datum/squad/marine/halo/odst/delta)
			return SHIP_SURFACE_FAMILY_ODST

	return null

/datum/authority/branch/role/proc/get_active_ship_surface_family(platoon_type = get_active_ship_platoon_type())
	return get_ship_surface_family(platoon_type)

/datum/authority/branch/role/proc/get_ship_surface_squad_marker_for_platoon_type(platoon_type)
	switch(platoon_type)
		if(/datum/squad/marine/alpha, /datum/squad/marine/halo/unsc/alpha, /datum/squad/marine/halo/odst/alpha)
			return SQUAD_MARINE_1
		if(/datum/squad/marine/bravo, /datum/squad/marine/halo/unsc/bravo, /datum/squad/marine/halo/odst/bravo)
			return SQUAD_MARINE_2
		if(/datum/squad/marine/charlie, /datum/squad/marine/halo/unsc/charlie, /datum/squad/marine/halo/odst/charlie)
			return SQUAD_MARINE_3
		if(/datum/squad/marine/delta, /datum/squad/marine/halo/unsc/delta, /datum/squad/marine/halo/odst/delta)
			return SQUAD_MARINE_4

	return null

/datum/authority/branch/role/proc/get_ship_surface_related_squad_markers(platoon_type)
	var/datum/modular_ship_platoon_profile/profile = get_ship_platoon_profile_datum(platoon_type)
	var/list/family_types = profile ? profile.get_family_types() : list(platoon_type)
	. = list()

	for(var/family_type in family_types)
		var/squad_marker = get_ship_surface_squad_marker_for_platoon_type(family_type)
		if(!squad_marker || (squad_marker in .))
			continue
		. += squad_marker

/datum/authority/branch/role/proc/is_ship_surface_supported_squad_marker(squad_marker, list/covered_squad_markers)
	if(!squad_marker)
		return TRUE
	if(!islist(covered_squad_markers))
		return FALSE

	return !!covered_squad_markers.Find(squad_marker)

/datum/authority/branch/role/proc/get_ship_surface_key(atom/fixture)
	if(istype(fixture, /obj/structure/closet/secure_closet/marine_personal/unsc_crew))
		return null

	if(istype(fixture, /obj/structure/closet/secure_closet/marine_personal))
		var/obj/structure/closet/secure_closet/marine_personal/locker = fixture
		var/canonical_role = get_job_preference_bucket_key(locker.job) || locker.job
		switch(canonical_role)
			if(JOB_SO, JOB_SQUAD_MARINE, JOB_SQUAD_MEDIC, JOB_SQUAD_SPECIALIST, JOB_SQUAD_RTO, JOB_SQUAD_TEAM_LEADER, JOB_SQUAD_LEADER)
				return list(
					"kind" = SHIP_SURFACE_KIND_LOCKER,
					"role" = canonical_role,
					"squad_type" = locker.squad_type
				)
		return null

	if(fixture.type == /obj/structure/machinery/cm_vending/sorted/uniform_supply/squad_prep || istype(fixture, /obj/structure/machinery/cm_vending/sorted/uniform_supply/squad_prep/unsc))
		return list("kind" = SHIP_SURFACE_KIND_VENDOR, "vendor_key" = SHIP_SURFACE_VENDOR_SQUAD_PREP_UNIFORM)

	if(fixture.type == /obj/structure/machinery/cm_vending/sorted/cargo_guns/squad || istype(fixture, /obj/structure/machinery/cm_vending/sorted/cargo_guns/squad/unsc))
		return list("kind" = SHIP_SURFACE_KIND_VENDOR, "vendor_key" = SHIP_SURFACE_VENDOR_SQUAD_PREP_GUNS)

	if(fixture.type == /obj/structure/machinery/cm_vending/clothing/medic || istype(fixture, /obj/structure/machinery/cm_vending/clothing/medic/unsc))
		return list("kind" = SHIP_SURFACE_KIND_VENDOR, "vendor_key" = SHIP_SURFACE_VENDOR_MEDIC_CLOTHING)

	if(fixture.type == /obj/structure/machinery/cm_vending/gear/medic_chemical || istype(fixture, /obj/structure/machinery/cm_vending/gear/medic_chemical/unsc))
		return list("kind" = SHIP_SURFACE_KIND_VENDOR, "vendor_key" = SHIP_SURFACE_VENDOR_MEDIC_CHEMICAL)

	if(istype(fixture, /obj/structure/machinery/cm_vending/sorted/medical/unsc) || fixture.type == /obj/structure/machinery/cm_vending/sorted/medical/marinemed)
		return list("kind" = SHIP_SURFACE_KIND_VENDOR, "vendor_key" = SHIP_SURFACE_VENDOR_MEDBAY_BASIC)

	if(istype(fixture, /obj/structure/machinery/cm_vending/sorted/marine_food/unsc/alt))
		return list("kind" = SHIP_SURFACE_KIND_VENDOR, "vendor_key" = SHIP_SURFACE_VENDOR_MARINE_FOOD_ALT)

	if(istype(fixture, /obj/structure/machinery/cm_vending/sorted/marine_food/unsc) || fixture.type == /obj/structure/machinery/cm_vending/sorted/marine_food)
		return list("kind" = SHIP_SURFACE_KIND_VENDOR, "vendor_key" = SHIP_SURFACE_VENDOR_MARINE_FOOD)

	return null
