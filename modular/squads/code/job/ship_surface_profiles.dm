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
	var/list/profile = get_ship_platoon_profile(platoon_type)
	var/list/family_types = islist(profile?["family_types"]) ? profile["family_types"] : list(platoon_type)
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

/datum/authority/branch/role/proc/get_ship_surface_target_locker_root_type(canonical_role, target_family)
	switch(target_family)
		if(SHIP_SURFACE_FAMILY_USCM)
			switch(canonical_role)
				if(JOB_SO)
					return /obj/structure/closet/secure_closet/marine_personal/platoon_commander
				if(JOB_SQUAD_MARINE)
					return /obj/structure/closet/secure_closet/marine_personal/rifleman
				if(JOB_SQUAD_MEDIC)
					return /obj/structure/closet/secure_closet/marine_personal/corpsman
				if(JOB_SQUAD_SPECIALIST)
					return /obj/structure/closet/secure_closet/marine_personal/specialist
				if(JOB_SQUAD_RTO)
					return /obj/structure/closet/secure_closet/marine_personal/rto
				if(JOB_SQUAD_TEAM_LEADER)
					return /obj/structure/closet/secure_closet/marine_personal/squad_leader
				if(JOB_SQUAD_LEADER)
					return /obj/structure/closet/secure_closet/marine_personal/platoon_leader
		if(SHIP_SURFACE_FAMILY_UNSC)
			switch(canonical_role)
				if(JOB_SO)
					return /obj/structure/closet/secure_closet/marine_personal/unsc/platoon_commander
				if(JOB_SQUAD_MARINE)
					return /obj/structure/closet/secure_closet/marine_personal/unsc/rifleman
				if(JOB_SQUAD_MEDIC)
					return /obj/structure/closet/secure_closet/marine_personal/unsc/corpsman
				if(JOB_SQUAD_SPECIALIST)
					return /obj/structure/closet/secure_closet/marine_personal/unsc/specialist
				if(JOB_SQUAD_RTO)
					return /obj/structure/closet/secure_closet/marine_personal/unsc/rto
				if(JOB_SQUAD_TEAM_LEADER)
					return /obj/structure/closet/secure_closet/marine_personal/unsc/team_leader
				if(JOB_SQUAD_LEADER)
					return /obj/structure/closet/secure_closet/marine_personal/unsc/squad_leader
		if(SHIP_SURFACE_FAMILY_ODST)
			switch(canonical_role)
				if(JOB_SO)
					return /obj/structure/closet/secure_closet/marine_personal/odst/platoon_commander
				if(JOB_SQUAD_MARINE)
					return /obj/structure/closet/secure_closet/marine_personal/odst/rifleman
				if(JOB_SQUAD_MEDIC)
					return /obj/structure/closet/secure_closet/marine_personal/odst/corpsman
				if(JOB_SQUAD_SPECIALIST)
					return /obj/structure/closet/secure_closet/marine_personal/odst/specialist
				if(JOB_SQUAD_RTO)
					return /obj/structure/closet/secure_closet/marine_personal/odst/rto
				if(JOB_SQUAD_TEAM_LEADER)
					return /obj/structure/closet/secure_closet/marine_personal/odst/team_leader
				if(JOB_SQUAD_LEADER)
					return /obj/structure/closet/secure_closet/marine_personal/odst/squad_leader

	return null

/datum/authority/branch/role/proc/get_ship_surface_target_locker_type(canonical_role, squad_type, target_family)
	if(!squad_type)
		return get_ship_surface_target_locker_root_type(canonical_role, target_family)

	switch(target_family)
		if(SHIP_SURFACE_FAMILY_USCM)
			switch(canonical_role)
				if(JOB_SQUAD_MARINE)
					switch(squad_type)
						if(SQUAD_MARINE_1) return /obj/structure/closet/secure_closet/marine_personal/rifleman/s1
						if(SQUAD_MARINE_2) return /obj/structure/closet/secure_closet/marine_personal/rifleman/s2
						if(SQUAD_MARINE_3) return /obj/structure/closet/secure_closet/marine_personal/rifleman/s3
						if(SQUAD_MARINE_4) return /obj/structure/closet/secure_closet/marine_personal/rifleman/s4
				if(JOB_SQUAD_MEDIC)
					switch(squad_type)
						if(SQUAD_MARINE_1) return /obj/structure/closet/secure_closet/marine_personal/corpsman/s1
						if(SQUAD_MARINE_2) return /obj/structure/closet/secure_closet/marine_personal/corpsman/s2
						if(SQUAD_MARINE_3) return /obj/structure/closet/secure_closet/marine_personal/corpsman/s3
						if(SQUAD_MARINE_4) return /obj/structure/closet/secure_closet/marine_personal/corpsman/s4
				if(JOB_SQUAD_SPECIALIST)
					switch(squad_type)
						if(SQUAD_MARINE_1) return /obj/structure/closet/secure_closet/marine_personal/specialist/s1
						if(SQUAD_MARINE_2) return /obj/structure/closet/secure_closet/marine_personal/specialist/s2
						if(SQUAD_MARINE_3) return /obj/structure/closet/secure_closet/marine_personal/specialist/s3
						if(SQUAD_MARINE_4) return /obj/structure/closet/secure_closet/marine_personal/specialist/s4
				if(JOB_SQUAD_RTO)
					switch(squad_type)
						if(SQUAD_MARINE_1) return /obj/structure/closet/secure_closet/marine_personal/rto/s1
						if(SQUAD_MARINE_2) return /obj/structure/closet/secure_closet/marine_personal/rto/s2
						if(SQUAD_MARINE_3) return /obj/structure/closet/secure_closet/marine_personal/rto/s3
						if(SQUAD_MARINE_4) return /obj/structure/closet/secure_closet/marine_personal/rto/s4
				if(JOB_SQUAD_TEAM_LEADER)
					switch(squad_type)
						if(SQUAD_MARINE_1) return /obj/structure/closet/secure_closet/marine_personal/squad_leader/s1
						if(SQUAD_MARINE_2) return /obj/structure/closet/secure_closet/marine_personal/squad_leader/s2
						if(SQUAD_MARINE_3) return /obj/structure/closet/secure_closet/marine_personal/squad_leader/s3
						if(SQUAD_MARINE_4) return /obj/structure/closet/secure_closet/marine_personal/squad_leader/s4
				if(JOB_SQUAD_LEADER)
					switch(squad_type)
						if(SQUAD_MARINE_1) return /obj/structure/closet/secure_closet/marine_personal/platoon_leader/s1
						if(SQUAD_MARINE_2) return /obj/structure/closet/secure_closet/marine_personal/platoon_leader/s2
						if(SQUAD_MARINE_3) return /obj/structure/closet/secure_closet/marine_personal/platoon_leader/s3
						if(SQUAD_MARINE_4) return /obj/structure/closet/secure_closet/marine_personal/platoon_leader/s4
		if(SHIP_SURFACE_FAMILY_UNSC)
			switch(canonical_role)
				if(JOB_SQUAD_MARINE)
					switch(squad_type)
						if(SQUAD_MARINE_1) return /obj/structure/closet/secure_closet/marine_personal/unsc/alpha/rifleman
						if(SQUAD_MARINE_2) return /obj/structure/closet/secure_closet/marine_personal/unsc/bravo/rifleman
						if(SQUAD_MARINE_3) return /obj/structure/closet/secure_closet/marine_personal/unsc/charlie/rifleman
						if(SQUAD_MARINE_4) return /obj/structure/closet/secure_closet/marine_personal/unsc/delta/rifleman
				if(JOB_SQUAD_MEDIC)
					switch(squad_type)
						if(SQUAD_MARINE_1) return /obj/structure/closet/secure_closet/marine_personal/unsc/alpha/corpsman
						if(SQUAD_MARINE_2) return /obj/structure/closet/secure_closet/marine_personal/unsc/bravo/corpsman
						if(SQUAD_MARINE_3) return /obj/structure/closet/secure_closet/marine_personal/unsc/charlie/corpsman
						if(SQUAD_MARINE_4) return /obj/structure/closet/secure_closet/marine_personal/unsc/delta/corpsman
				if(JOB_SQUAD_SPECIALIST)
					switch(squad_type)
						if(SQUAD_MARINE_1) return /obj/structure/closet/secure_closet/marine_personal/unsc/alpha/specialist
						if(SQUAD_MARINE_2) return /obj/structure/closet/secure_closet/marine_personal/unsc/bravo/specialist
						if(SQUAD_MARINE_3) return /obj/structure/closet/secure_closet/marine_personal/unsc/charlie/specialist
						if(SQUAD_MARINE_4) return /obj/structure/closet/secure_closet/marine_personal/unsc/delta/specialist
				if(JOB_SQUAD_RTO)
					switch(squad_type)
						if(SQUAD_MARINE_1) return /obj/structure/closet/secure_closet/marine_personal/unsc/alpha/rto
						if(SQUAD_MARINE_2) return /obj/structure/closet/secure_closet/marine_personal/unsc/bravo/rto
						if(SQUAD_MARINE_3) return /obj/structure/closet/secure_closet/marine_personal/unsc/charlie/rto
						if(SQUAD_MARINE_4) return /obj/structure/closet/secure_closet/marine_personal/unsc/delta/rto
				if(JOB_SQUAD_TEAM_LEADER)
					switch(squad_type)
						if(SQUAD_MARINE_1) return /obj/structure/closet/secure_closet/marine_personal/unsc/alpha/team_leader
						if(SQUAD_MARINE_2) return /obj/structure/closet/secure_closet/marine_personal/unsc/bravo/team_leader
						if(SQUAD_MARINE_3) return /obj/structure/closet/secure_closet/marine_personal/unsc/charlie/team_leader
						if(SQUAD_MARINE_4) return /obj/structure/closet/secure_closet/marine_personal/unsc/delta/team_leader
				if(JOB_SQUAD_LEADER)
					switch(squad_type)
						if(SQUAD_MARINE_1) return /obj/structure/closet/secure_closet/marine_personal/unsc/alpha/squad_leader
						if(SQUAD_MARINE_2) return /obj/structure/closet/secure_closet/marine_personal/unsc/bravo/squad_leader
						if(SQUAD_MARINE_3) return /obj/structure/closet/secure_closet/marine_personal/unsc/charlie/squad_leader
						if(SQUAD_MARINE_4) return /obj/structure/closet/secure_closet/marine_personal/unsc/delta/squad_leader
		if(SHIP_SURFACE_FAMILY_ODST)
			switch(canonical_role)
				if(JOB_SQUAD_MARINE)
					switch(squad_type)
						if(SQUAD_MARINE_1) return /obj/structure/closet/secure_closet/marine_personal/odst/alpha/rifleman
						if(SQUAD_MARINE_2) return /obj/structure/closet/secure_closet/marine_personal/odst/bravo/rifleman
						if(SQUAD_MARINE_3) return /obj/structure/closet/secure_closet/marine_personal/odst/charlie/rifleman
						if(SQUAD_MARINE_4) return /obj/structure/closet/secure_closet/marine_personal/odst/delta/rifleman
				if(JOB_SQUAD_MEDIC)
					switch(squad_type)
						if(SQUAD_MARINE_1) return /obj/structure/closet/secure_closet/marine_personal/odst/alpha/corpsman
						if(SQUAD_MARINE_2) return /obj/structure/closet/secure_closet/marine_personal/odst/bravo/corpsman
						if(SQUAD_MARINE_3) return /obj/structure/closet/secure_closet/marine_personal/odst/charlie/corpsman
						if(SQUAD_MARINE_4) return /obj/structure/closet/secure_closet/marine_personal/odst/delta/corpsman
				if(JOB_SQUAD_SPECIALIST)
					switch(squad_type)
						if(SQUAD_MARINE_1) return /obj/structure/closet/secure_closet/marine_personal/odst/alpha/specialist
						if(SQUAD_MARINE_2) return /obj/structure/closet/secure_closet/marine_personal/odst/bravo/specialist
						if(SQUAD_MARINE_3) return /obj/structure/closet/secure_closet/marine_personal/odst/charlie/specialist
						if(SQUAD_MARINE_4) return /obj/structure/closet/secure_closet/marine_personal/odst/delta/specialist
				if(JOB_SQUAD_RTO)
					switch(squad_type)
						if(SQUAD_MARINE_1) return /obj/structure/closet/secure_closet/marine_personal/odst/alpha/rto
						if(SQUAD_MARINE_2) return /obj/structure/closet/secure_closet/marine_personal/odst/bravo/rto
						if(SQUAD_MARINE_3) return /obj/structure/closet/secure_closet/marine_personal/odst/charlie/rto
						if(SQUAD_MARINE_4) return /obj/structure/closet/secure_closet/marine_personal/odst/delta/rto
				if(JOB_SQUAD_TEAM_LEADER)
					switch(squad_type)
						if(SQUAD_MARINE_1) return /obj/structure/closet/secure_closet/marine_personal/odst/alpha/team_leader
						if(SQUAD_MARINE_2) return /obj/structure/closet/secure_closet/marine_personal/odst/bravo/team_leader
						if(SQUAD_MARINE_3) return /obj/structure/closet/secure_closet/marine_personal/odst/charlie/team_leader
						if(SQUAD_MARINE_4) return /obj/structure/closet/secure_closet/marine_personal/odst/delta/team_leader
				if(JOB_SQUAD_LEADER)
					switch(squad_type)
						if(SQUAD_MARINE_1) return /obj/structure/closet/secure_closet/marine_personal/odst/alpha/squad_leader
						if(SQUAD_MARINE_2) return /obj/structure/closet/secure_closet/marine_personal/odst/bravo/squad_leader
						if(SQUAD_MARINE_3) return /obj/structure/closet/secure_closet/marine_personal/odst/charlie/squad_leader
						if(SQUAD_MARINE_4) return /obj/structure/closet/secure_closet/marine_personal/odst/delta/squad_leader

	return null

/datum/authority/branch/role/proc/get_ship_surface_target_vendor_type(vendor_key, target_family)
	switch(target_family)
		if(SHIP_SURFACE_FAMILY_USCM)
			switch(vendor_key)
				if(SHIP_SURFACE_VENDOR_SQUAD_PREP_UNIFORM)
					return /obj/structure/machinery/cm_vending/sorted/uniform_supply/squad_prep
				if(SHIP_SURFACE_VENDOR_SQUAD_PREP_GUNS)
					return /obj/structure/machinery/cm_vending/sorted/cargo_guns/squad
				if(SHIP_SURFACE_VENDOR_MEDIC_CLOTHING)
					return /obj/structure/machinery/cm_vending/clothing/medic
				if(SHIP_SURFACE_VENDOR_MEDIC_CHEMICAL)
					return /obj/structure/machinery/cm_vending/gear/medic_chemical
				if(SHIP_SURFACE_VENDOR_MEDBAY_BASIC)
					return /obj/structure/machinery/cm_vending/sorted/medical/marinemed
				if(SHIP_SURFACE_VENDOR_MARINE_FOOD, SHIP_SURFACE_VENDOR_MARINE_FOOD_ALT)
					return /obj/structure/machinery/cm_vending/sorted/marine_food
		if(SHIP_SURFACE_FAMILY_UNSC)
			switch(vendor_key)
				if(SHIP_SURFACE_VENDOR_SQUAD_PREP_UNIFORM)
					return /obj/structure/machinery/cm_vending/sorted/uniform_supply/squad_prep/unsc
				if(SHIP_SURFACE_VENDOR_SQUAD_PREP_GUNS)
					return /obj/structure/machinery/cm_vending/sorted/cargo_guns/squad/unsc
				if(SHIP_SURFACE_VENDOR_MEDIC_CLOTHING)
					return /obj/structure/machinery/cm_vending/clothing/medic/unsc
				if(SHIP_SURFACE_VENDOR_MEDIC_CHEMICAL)
					return /obj/structure/machinery/cm_vending/gear/medic_chemical/unsc
				if(SHIP_SURFACE_VENDOR_MEDBAY_BASIC)
					return /obj/structure/machinery/cm_vending/sorted/medical/unsc
				if(SHIP_SURFACE_VENDOR_MARINE_FOOD)
					return /obj/structure/machinery/cm_vending/sorted/marine_food/unsc
				if(SHIP_SURFACE_VENDOR_MARINE_FOOD_ALT)
					return /obj/structure/machinery/cm_vending/sorted/marine_food/unsc/alt
		if(SHIP_SURFACE_FAMILY_ODST)
			switch(vendor_key)
				if(SHIP_SURFACE_VENDOR_SQUAD_PREP_UNIFORM)
					return /obj/structure/machinery/cm_vending/sorted/uniform_supply/squad_prep/unsc/odst
				if(SHIP_SURFACE_VENDOR_SQUAD_PREP_GUNS)
					return /obj/structure/machinery/cm_vending/sorted/cargo_guns/squad/unsc/odst
				if(SHIP_SURFACE_VENDOR_MEDIC_CLOTHING)
					return /obj/structure/machinery/cm_vending/clothing/medic/unsc/odst
				if(SHIP_SURFACE_VENDOR_MEDIC_CHEMICAL)
					return /obj/structure/machinery/cm_vending/gear/medic_chemical/unsc/odst
				if(SHIP_SURFACE_VENDOR_MEDBAY_BASIC)
					return /obj/structure/machinery/cm_vending/sorted/medical/unsc/odst
				if(SHIP_SURFACE_VENDOR_MARINE_FOOD)
					return /obj/structure/machinery/cm_vending/sorted/marine_food/unsc/odst
				if(SHIP_SURFACE_VENDOR_MARINE_FOOD_ALT)
					return /obj/structure/machinery/cm_vending/sorted/marine_food/unsc/odst/alt

	return null

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

/datum/authority/branch/role/proc/replace_ship_surface_locker(obj/structure/closet/secure_closet/marine_personal/source_locker, target_type)
	if(!istype(source_locker) || !target_type)
		return null

	var/turf/locker_turf = get_turf(source_locker)
	if(!isturf(locker_turf))
		return null

	var/obj/structure/closet/secure_closet/marine_personal/target_locker = new target_type(locker_turf)
	copy_ship_surface_transform(source_locker, target_locker)
	target_locker.owner = source_locker.owner
	target_locker.opened = source_locker.opened
	target_locker.welded = source_locker.welded
	target_locker.locked = source_locker.locked
	target_locker.broken = source_locker.broken
	target_locker.has_cryo_gear = source_locker.has_cryo_gear
	if(!source_locker.has_cryo_gear)
		var/list/generated_contents = target_locker.generated_spawn_gear_contents ? target_locker.generated_spawn_gear_contents.Copy() : list()
		for(var/atom/movable/generated_item as anything in generated_contents)
			generated_item.forceMove(locker_turf)
			qdel(generated_item)
		target_locker.generated_spawn_gear_contents = list()
	target_locker.x_to_linked_spawn_turf = source_locker.x_to_linked_spawn_turf
	target_locker.y_to_linked_spawn_turf = source_locker.y_to_linked_spawn_turf
	if(target_locker.x_to_linked_spawn_turf || target_locker.y_to_linked_spawn_turf)
		target_locker.linked_spawn_turf = locate(target_locker.x + target_locker.x_to_linked_spawn_turf, target_locker.y + target_locker.y_to_linked_spawn_turf, target_locker.z)
	else
		target_locker.linked_spawn_turf = source_locker.linked_spawn_turf

	var/list/preserved_contents = source_locker.get_preserved_contents_for_ship_surface_swap()
	for(var/atom/movable/movable as anything in preserved_contents)
		movable.forceMove(target_locker)

	var/list/discarded_generated_contents = source_locker.generated_spawn_gear_contents ? source_locker.generated_spawn_gear_contents.Copy() : list()
	for(var/atom/movable/generated_item as anything in discarded_generated_contents)
		if(QDELETED(generated_item) || generated_item.loc != source_locker)
			continue
		qdel(generated_item)
	source_locker.generated_spawn_gear_contents = list()
	target_locker.update_icon()
	qdel(source_locker)
	return target_locker

/datum/authority/branch/role/proc/replace_ship_surface_vendor(obj/structure/machinery/cm_vending/source_vendor, target_type)
	if(!istype(source_vendor) || !target_type)
		return null

	var/turf/vendor_turf = get_turf(source_vendor)
	if(!isturf(vendor_turf))
		return null

	var/obj/structure/machinery/cm_vending/target_vendor = new target_type(vendor_turf)
	copy_ship_surface_transform(source_vendor, target_vendor)

	for(var/atom/movable/movable as anything in source_vendor.contents)
		movable.forceMove(target_vendor)

	qdel(source_vendor)
	return target_vendor

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

#undef SHIP_SURFACE_FAMILY_USCM
#undef SHIP_SURFACE_FAMILY_UNSC
#undef SHIP_SURFACE_FAMILY_ODST

#undef SHIP_SURFACE_KIND_LOCKER
#undef SHIP_SURFACE_KIND_VENDOR

#undef SHIP_SURFACE_VENDOR_SQUAD_PREP_UNIFORM
#undef SHIP_SURFACE_VENDOR_SQUAD_PREP_GUNS
#undef SHIP_SURFACE_VENDOR_MEDIC_CLOTHING
#undef SHIP_SURFACE_VENDOR_MEDIC_CHEMICAL
#undef SHIP_SURFACE_VENDOR_MEDBAY_BASIC
#undef SHIP_SURFACE_VENDOR_MARINE_FOOD
#undef SHIP_SURFACE_VENDOR_MARINE_FOOD_ALT
