/datum/unit_test/halo_ship_platoons_unsc_medical_vendor_access
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_unsc_medical_vendor_access/Run()
	var/turf/vendor_turf = run_loc_floor_top_right
	var/turf/user_turf = get_step(vendor_turf, SOUTH)
	if(!isfloorturf(user_turf))
		user_turf = get_step(vendor_turf, NORTH)
	TEST_ASSERT(isfloorturf(user_turf), "Failed to find a user turf for HALO medical vendor access testing.")

	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human, user_turf)
	configure_test_human(human, "UNSC Vendor Corpsman", JOB_SQUAD_MEDIC_UNSC, /datum/squad/marine/halo/unsc/alpha)
	TEST_ASSERT_NOTNULL(prepare_test_human_for_squad(human, /datum/equipment_preset/unsc/medic, JOB_SQUAD_MEDIC_UNSC), "Failed to equip an ID onto the HALO medical vendor access test mob.")

	var/obj/structure/machinery/cm_vending/gear/medic_chemical/unsc/chem_vendor = allocate(/obj/structure/machinery/cm_vending/gear/medic_chemical/unsc, vendor_turf)
	TEST_ASSERT(chem_vendor.can_access_to_vend(human, FALSE), "HALO UNSC corpsman lost access to the chemical medic vendor.")

	var/obj/structure/machinery/cm_vending/sorted/medical/unsc/med_vendor = allocate(/obj/structure/machinery/cm_vending/sorted/medical/unsc, vendor_turf)
	med_vendor.req_access = list(ACCESS_MARINE_MEDPREP)
	TEST_ASSERT(med_vendor.can_access_to_vend(human, FALSE), "HALO UNSC corpsman lost access to the medical vendor when medprep access was required.")

	var/list/lifesaver_item = null
	for(var/list/product as anything in med_vendor.get_listed_products(human))
		if(product[3] == /obj/item/storage/belt/medical/lifesaver/unsc)
			lifesaver_item = product
			break

	TEST_ASSERT_NOTNULL(lifesaver_item, "Failed to resolve the Lifesaver Bag listing in the HALO medical vendor.")
	TEST_ASSERT_EQUAL(lifesaver_item[3], /obj/item/storage/belt/medical/lifesaver/unsc, "HALO medical vendor listing regressed away from the UNSC Lifesaver Bag.")

/datum/unit_test/halo_ship_platoons_unsc_specialist_job_locker_access
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_unsc_specialist_job_locker_access/Run()
	var/turf/test_turf = run_loc_floor_top_right
	var/datum/squad/marine/halo/unsc/alpha/squad = allocate(/datum/squad/marine/halo/unsc/alpha)
	var/obj/structure/closet/secure_closet/halo/job_locker/weapons_spec/ft1/locker_ft1 = allocate(/obj/structure/closet/secure_closet/halo/job_locker/weapons_spec/ft1, test_turf)
	var/obj/structure/closet/secure_closet/halo/job_locker/weapons_spec/ft2/locker_ft2 = allocate(/obj/structure/closet/secure_closet/halo/job_locker/weapons_spec/ft2, test_turf)

	var/mob/living/carbon/human/first_specialist = allocate(/mob/living/carbon/human, test_turf)
	configure_test_human(first_specialist, "HALO UNSC Spec One", JOB_SQUAD_SPECIALIST)
	var/obj/item/card/id/first_id = prepare_test_human_for_squad(first_specialist, /datum/equipment_preset/unsc/spec, JOB_SQUAD_SPECIALIST)
	TEST_ASSERT_NOTNULL(first_id, "Failed to equip an ID onto the first HALO UNSC specialist test mob.")

	TEST_ASSERT(squad.put_marine_in_squad(first_specialist), "Failed to insert the first HALO UNSC specialist into a squad for locker access testing.")
	TEST_ASSERT_EQUAL(first_specialist.assigned_fireteam, "SQ1", "The first HALO UNSC specialist was not assigned to SQ1.")
	TEST_ASSERT(first_id.access.Find(ACCESS_SQUAD_ONE), "The first HALO UNSC specialist ID did not receive ACCESS_SQUAD_ONE.")
	TEST_ASSERT(locker_ft1.allowed(first_specialist), "The first HALO UNSC specialist could not access the SQ1 weapons locker after squad insertion.")
	TEST_ASSERT(!locker_ft2.allowed(first_specialist), "The first HALO UNSC specialist incorrectly gained access to the SQ2 weapons locker.")

	var/mob/living/carbon/human/second_specialist = allocate(/mob/living/carbon/human, test_turf)
	configure_test_human(second_specialist, "HALO UNSC Spec Two", JOB_SQUAD_SPECIALIST)
	var/obj/item/card/id/second_id = prepare_test_human_for_squad(second_specialist, /datum/equipment_preset/unsc/spec, JOB_SQUAD_SPECIALIST)
	TEST_ASSERT_NOTNULL(second_id, "Failed to equip an ID onto the second HALO UNSC specialist test mob.")

	TEST_ASSERT(squad.put_marine_in_squad(second_specialist), "Failed to insert the second HALO UNSC specialist into a squad for locker access testing.")
	TEST_ASSERT_EQUAL(second_specialist.assigned_fireteam, "SQ2", "The second HALO UNSC specialist was not assigned to SQ2.")
	TEST_ASSERT(second_id.access.Find(ACCESS_SQUAD_TWO), "The second HALO UNSC specialist ID did not receive ACCESS_SQUAD_TWO.")
	TEST_ASSERT(locker_ft2.allowed(second_specialist), "The second HALO UNSC specialist could not access the SQ2 weapons locker after squad insertion.")
	TEST_ASSERT(!locker_ft1.allowed(second_specialist), "The second HALO UNSC specialist incorrectly gained access to the SQ1 weapons locker.")

	squad.remove_marine_from_squad(second_specialist, second_id)
	squad.remove_marine_from_squad(first_specialist, first_id)

/datum/unit_test/halo_ship_platoons_odst_specialist_job_locker_access
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_odst_specialist_job_locker_access/Run()
	var/turf/test_turf = run_loc_floor_top_right
	var/datum/squad/marine/halo/odst/alpha/squad = allocate(/datum/squad/marine/halo/odst/alpha)
	var/obj/structure/closet/secure_closet/halo/job_locker/weapons_spec/ft1/locker_ft1 = allocate(/obj/structure/closet/secure_closet/halo/job_locker/weapons_spec/ft1, test_turf)

	var/mob/living/carbon/human/specialist = allocate(/mob/living/carbon/human, test_turf)
	configure_test_human(specialist, "HALO ODST Spec One", JOB_SQUAD_SPECIALIST)
	var/obj/item/card/id/id = prepare_test_human_for_squad(specialist, /datum/equipment_preset/unsc/spec/odst, JOB_SQUAD_SPECIALIST)
	TEST_ASSERT_NOTNULL(id, "Failed to equip an ID onto the HALO ODST specialist test mob.")

	TEST_ASSERT(squad.put_marine_in_squad(specialist), "Failed to insert the HALO ODST specialist into a squad for locker access testing.")
	TEST_ASSERT_EQUAL(specialist.assigned_fireteam, "SQ1", "The HALO ODST specialist was not assigned to SQ1.")
	TEST_ASSERT(id.access.Find(ACCESS_SQUAD_ONE), "The HALO ODST specialist ID did not receive ACCESS_SQUAD_ONE.")
	TEST_ASSERT(locker_ft1.allowed(specialist), "The HALO ODST specialist could not access the SQ1 weapons locker after squad insertion.")

	squad.remove_marine_from_squad(specialist, id)

/datum/unit_test/halo_ship_platoons_unsc_specialist_personal_locker_roundstart
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_unsc_specialist_personal_locker_roundstart/Run()
	var/datum/equipment_preset/preset = allocate(/datum/equipment_preset)
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	configure_test_human(human, "HALO UNSC Spec Roundstart", JOB_SQUAD_SPECIALIST, /datum/squad/marine/halo/unsc/alpha)
	TEST_ASSERT_NOTNULL(human.assigned_squad, "Failed to resolve UNSC HALO alpha squad for roundstart locker test.")

	var/obj/structure/closet/secure_closet/marine_personal/unsc/alpha/specialist/locker = allocate(/obj/structure/closet/secure_closet/marine_personal/unsc/alpha/specialist)
	isolate_personal_lockers(locker)

	TEST_ASSERT(preset.try_handle_personal_locker_vanity(human, null, FALSE), "Roundstart locker handling returned FALSE for HALO UNSC specialist.")
	TEST_ASSERT_EQUAL(locker.owner, human.real_name, "HALO UNSC specialist personal locker was not claimed on roundstart.")
	TEST_ASSERT(findtext(locker.name, human.real_name), "HALO UNSC specialist personal locker name was not personalized on roundstart.")
	TEST_ASSERT(locker.allowed(human), "Claimed HALO UNSC specialist personal locker did not open for its owner.")
	TEST_ASSERT(count_personal_locker_contents_by_type(locker, /obj/item/clothing/under/marine) >= 1, "HALO UNSC specialist personal locker lost its baseline uniform on roundstart claim.")
	TEST_ASSERT(count_personal_locker_contents_by_type(locker, /obj/item/device/radio/headset/almayer/marine/solardevils/unsc) >= 1, "HALO UNSC specialist personal locker lost its baseline headset on roundstart claim.")

/datum/unit_test/halo_ship_platoons_unsc_specialist_personal_locker_latejoin
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_unsc_specialist_personal_locker_latejoin/Run()
	var/datum/equipment_preset/preset = allocate(/datum/equipment_preset)
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	configure_test_human(human, "HALO UNSC Spec Latejoin", JOB_SQUAD_SPECIALIST, /datum/squad/marine/halo/unsc/alpha)
	TEST_ASSERT_NOTNULL(human.assigned_squad, "Failed to resolve UNSC HALO alpha squad for latejoin locker test.")

	var/obj/structure/closet/secure_closet/marine_personal/unsc/alpha/specialist/locker = allocate(/obj/structure/closet/secure_closet/marine_personal/unsc/alpha/specialist)
	isolate_personal_lockers(locker)

	TEST_ASSERT(preset.try_handle_personal_locker_vanity(human, null, TRUE), "Latejoin locker handling returned FALSE for HALO UNSC specialist.")
	TEST_ASSERT_EQUAL(locker.owner, human.real_name, "HALO UNSC specialist personal locker was not claimed on latejoin.")
	TEST_ASSERT(findtext(locker.name, human.real_name), "HALO UNSC specialist personal locker name was not personalized on latejoin.")
	TEST_ASSERT(locker.allowed(human), "Claimed HALO UNSC specialist personal locker did not open for its owner on latejoin.")

/datum/unit_test/halo_ship_platoons_odst_specialist_personal_locker_roundstart
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_odst_specialist_personal_locker_roundstart/Run()
	var/datum/equipment_preset/preset = allocate(/datum/equipment_preset)
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	configure_test_human(human, "HALO ODST Spec Roundstart", JOB_SQUAD_SPECIALIST, /datum/squad/marine/halo/odst/alpha)
	TEST_ASSERT_NOTNULL(human.assigned_squad, "Failed to resolve ODST HALO alpha squad for roundstart locker test.")

	var/obj/structure/closet/secure_closet/marine_personal/odst/alpha/specialist/locker = allocate(/obj/structure/closet/secure_closet/marine_personal/odst/alpha/specialist)
	isolate_personal_lockers(locker)

	TEST_ASSERT(preset.try_handle_personal_locker_vanity(human, null, FALSE), "Roundstart locker handling returned FALSE for HALO ODST specialist.")
	TEST_ASSERT_EQUAL(locker.owner, human.real_name, "HALO ODST specialist personal locker was not claimed on roundstart.")
	TEST_ASSERT(locker.allowed(human), "Claimed HALO ODST specialist personal locker did not open for its owner.")
	TEST_ASSERT(count_personal_locker_contents_by_type(locker, /obj/item/device/radio/headset/almayer/marine/solardevils/unsc/odst) >= 1, "HALO ODST specialist personal locker lost its baseline headset on roundstart claim.")

/datum/unit_test/halo_ship_platoons_personal_locker_empty_first_claim_refill
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_personal_locker_empty_first_claim_refill/Run()
	var/datum/equipment_preset/preset = allocate(/datum/equipment_preset)
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	configure_test_human(human, "HALO Empty Locker Claim", JOB_SQUAD_SPECIALIST, /datum/squad/marine/halo/unsc/alpha)

	var/obj/structure/closet/secure_closet/marine_personal/unsc/alpha/specialist/locker = allocate(/obj/structure/closet/secure_closet/marine_personal/unsc/alpha/specialist)
	isolate_personal_lockers(locker)
	clear_personal_locker_contents(locker)
	TEST_ASSERT_EQUAL(length(locker.contents), 0, "Failed to empty HALO specialist personal locker before first-claim refill test.")

	TEST_ASSERT(preset.try_handle_personal_locker_vanity(human, null, FALSE), "Locker handling returned FALSE for empty first-claim refill test.")
	TEST_ASSERT(count_personal_locker_contents_by_type(locker, /obj/item/clothing/under/marine) >= 1, "Empty HALO specialist locker was not refilled with baseline uniform on first claim.")
	TEST_ASSERT(count_personal_locker_contents_by_type(locker, /obj/item/device/radio/headset/almayer/marine/solardevils/unsc) >= 1, "Empty HALO specialist locker was not refilled with baseline headset on first claim.")

/datum/unit_test/halo_ship_platoons_personal_locker_nonempty_first_claim_no_duplicate
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_personal_locker_nonempty_first_claim_no_duplicate/Run()
	var/datum/equipment_preset/preset = allocate(/datum/equipment_preset)
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	configure_test_human(human, "HALO Nonempty Locker Claim", JOB_SQUAD_SPECIALIST, /datum/squad/marine/halo/unsc/alpha)

	var/obj/structure/closet/secure_closet/marine_personal/unsc/alpha/specialist/locker = allocate(/obj/structure/closet/secure_closet/marine_personal/unsc/alpha/specialist)
	isolate_personal_lockers(locker)

	var/uniforms_before = count_personal_locker_contents_by_type(locker, /obj/item/clothing/under/marine)
	var/headsets_before = count_personal_locker_contents_by_type(locker, /obj/item/device/radio/headset/almayer/marine/solardevils/unsc)
	var/shoes_before = count_personal_locker_contents_by_type(locker, /obj/item/clothing/shoes/marine/knife)

	TEST_ASSERT(preset.try_handle_personal_locker_vanity(human, null, FALSE), "Locker handling returned FALSE for non-empty first-claim duplication test.")
	TEST_ASSERT_EQUAL(count_personal_locker_contents_by_type(locker, /obj/item/clothing/under/marine), uniforms_before, "Non-empty HALO specialist locker duplicated baseline uniform on first claim.")
	TEST_ASSERT_EQUAL(count_personal_locker_contents_by_type(locker, /obj/item/device/radio/headset/almayer/marine/solardevils/unsc), headsets_before, "Non-empty HALO specialist locker duplicated baseline headset on first claim.")
	TEST_ASSERT_EQUAL(count_personal_locker_contents_by_type(locker, /obj/item/clothing/shoes/marine/knife), shoes_before, "Non-empty HALO specialist locker duplicated baseline shoes on first claim.")

/datum/unit_test/halo_ship_platoons_personal_locker_custom_item_routing
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_personal_locker_custom_item_routing/Run()
	var/turf/mainship_turf = get_mainship_test_turf()
	TEST_ASSERT_NOTNULL(mainship_turf, "Failed to resolve a mainship turf for HALO personal-locker custom-item routing test.")

	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human, mainship_turf)
	configure_test_human(human, "HALO Custom Item Route", JOB_SQUAD_SPECIALIST, /datum/squad/marine/halo/unsc/alpha, "locker_custom_tester")

	var/obj/structure/closet/secure_closet/marine_personal/unsc/alpha/specialist/locker = allocate(/obj/structure/closet/secure_closet/marine_personal/unsc/alpha/specialist, mainship_turf)
	locker.owner = human.real_name
	isolate_personal_lockers(locker)

	GLOB.custom_items = list("locker_custom_tester:/obj/item/device/flashlight")
	EquipCustomItems(human)

	TEST_ASSERT(locate(/obj/item/device/flashlight) in locker.contents, "Custom item routing failed to place an item into the claimed HALO personal locker.")

/datum/unit_test/halo_ship_platoons_specialist_job_locker_allowlist
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_specialist_job_locker_allowlist/Run()
	var/obj/structure/closet/secure_closet/halo/job_locker/weapons_spec/locker = allocate(/obj/structure/closet/secure_closet/halo/job_locker/weapons_spec)
	var/list/allowed_specialist_jobs = locker.get_allowed_specialist_jobs()

	TEST_ASSERT(allowed_specialist_jobs.Find(JOB_SQUAD_SPECIALIST), "Specialist job locker allowlist lost the canonical specialist title.")
	TEST_ASSERT(allowed_specialist_jobs.Find(JOB_SQUAD_SPECIALIST_UNSC), "Specialist job locker allowlist lost the HALO UNSC specialist title.")
	TEST_ASSERT(allowed_specialist_jobs.Find(JOB_SQUAD_SPECIALIST_ODST), "Specialist job locker allowlist lost the HALO ODST specialist title.")

/datum/unit_test/halo_ship_platoons_ship_surface_registry
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_ship_surface_registry/Run()
	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	TEST_ASSERT_NOTNULL(role_authority, "RoleAuthority was unavailable for ship surface registry test.")

	TEST_ASSERT_EQUAL(role_authority.get_ship_surface_family(/datum/squad/marine/alpha), "uscm", "USCM platoon did not resolve to the USCM ship surface family.")
	TEST_ASSERT_EQUAL(role_authority.get_ship_surface_family(/datum/squad/marine/halo/unsc/alpha), "unsc", "UNSC platoon did not resolve to the UNSC ship surface family.")
	TEST_ASSERT_EQUAL(role_authority.get_ship_surface_family(/datum/squad/marine/halo/odst/alpha), "odst", "ODST platoon did not resolve to the ODST ship surface family.")

	var/list/halo_markers = role_authority.get_ship_surface_related_squad_markers(/datum/squad/marine/halo/unsc/alpha)
	TEST_ASSERT_EQUAL(length(halo_markers), 4, "HALO ship surface coverage did not include all related Alpha/Bravo/Charlie/Delta squads.")
	TEST_ASSERT(halo_markers.Find(SQUAD_MARINE_1), "HALO ship surface coverage missed Alpha.")
	TEST_ASSERT(halo_markers.Find(SQUAD_MARINE_2), "HALO ship surface coverage missed Bravo.")
	TEST_ASSERT(halo_markers.Find(SQUAD_MARINE_3), "HALO ship surface coverage missed Charlie.")
	TEST_ASSERT(halo_markers.Find(SQUAD_MARINE_4), "HALO ship surface coverage missed Delta.")

	var/obj/structure/closet/secure_closet/marine_personal/unsc/alpha/team_leader/ftl_locker = allocate(/obj/structure/closet/secure_closet/marine_personal/unsc/alpha/team_leader)
	var/list/ftl_key = role_authority.get_ship_surface_key(ftl_locker)
	TEST_ASSERT_NOTNULL(ftl_key, "HALO FTL locker did not resolve to a ship surface key.")
	TEST_ASSERT_EQUAL(role_authority.get_ship_surface_target_type(ftl_key, "uscm"), /obj/structure/closet/secure_closet/marine_personal/squad_leader/s1, "HALO team leader locker did not map back to the USCM fireteam-leader locker.")

	var/obj/structure/closet/secure_closet/marine_personal/unsc/alpha/squad_leader/sl_locker = allocate(/obj/structure/closet/secure_closet/marine_personal/unsc/alpha/squad_leader)
	var/list/sl_key = role_authority.get_ship_surface_key(sl_locker)
	TEST_ASSERT_NOTNULL(sl_key, "HALO squad leader locker did not resolve to a ship surface key.")
	TEST_ASSERT_EQUAL(role_authority.get_ship_surface_target_type(sl_key, "uscm"), /obj/structure/closet/secure_closet/marine_personal/platoon_leader/s1, "HALO squad leader locker did not map back to the USCM platoon-leader locker.")

	var/obj/structure/closet/secure_closet/marine_personal/unsc_crew/crew_locker = allocate(/obj/structure/closet/secure_closet/marine_personal/unsc_crew)
	TEST_ASSERT_NULL(role_authority.get_ship_surface_key(crew_locker), "UNSC crew lockers should stay out of marine ship surface replacement scope.")

	var/obj/structure/machinery/cm_vending/sorted/medical/unsc/med_vendor = allocate(/obj/structure/machinery/cm_vending/sorted/medical/unsc)
	TEST_ASSERT_EQUAL(role_authority.get_ship_surface_target_type(role_authority.get_ship_surface_key(med_vendor), "odst"), /obj/structure/machinery/cm_vending/sorted/medical/unsc/odst, "UNSC medbay vendor did not map to the ODST medbay subtype.")

	var/obj/structure/machinery/cm_vending/clothing/medic/unsc/medic_vendor = allocate(/obj/structure/machinery/cm_vending/clothing/medic/unsc)
	TEST_ASSERT_EQUAL(role_authority.get_ship_surface_target_type(role_authority.get_ship_surface_key(medic_vendor), "odst"), /obj/structure/machinery/cm_vending/clothing/medic/unsc/odst, "UNSC medic clothing vendor did not map to the ODST medic subtype.")

	var/obj/structure/machinery/cm_vending/gear/medic_chemical/unsc/chem_vendor = allocate(/obj/structure/machinery/cm_vending/gear/medic_chemical/unsc)
	TEST_ASSERT_EQUAL(role_authority.get_ship_surface_target_type(role_authority.get_ship_surface_key(chem_vendor), "odst"), /obj/structure/machinery/cm_vending/gear/medic_chemical/unsc/odst, "UNSC medic chemical vendor did not map to the ODST medic chemical subtype.")

	var/obj/structure/machinery/cm_vending/sorted/marine_food/unsc/alt/food_vendor = allocate(/obj/structure/machinery/cm_vending/sorted/marine_food/unsc/alt)
	TEST_ASSERT_EQUAL(role_authority.get_ship_surface_target_type(role_authority.get_ship_surface_key(food_vendor), "uscm"), /obj/structure/machinery/cm_vending/sorted/marine_food, "UNSC alternate food vendor did not map back to the USCM food vendor.")

/datum/unit_test/halo_ship_platoons_ship_surface_locker_replacement
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_ship_surface_locker_replacement/Run()
	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	TEST_ASSERT_NOTNULL(role_authority, "RoleAuthority was unavailable for locker ship surface replacement test.")

	var/turf/mainship_turf = get_mainship_test_turf(TRUE) // SS220 EDIT: locker replacement fixture needs an adjacent floor for linked spawn routing
	TEST_ASSERT_NOTNULL(mainship_turf, "Failed to resolve a mainship turf for locker ship surface replacement test.")

	var/turf/linked_turf = get_adjacent_floor_turf(mainship_turf) // SS220 EDIT: helper keeps the test fixture aligned with linked turf requirements
	TEST_ASSERT(isfloorturf(linked_turf), "Failed to resolve linked spawn turf for locker ship surface replacement test.")

	var/obj/structure/closet/secure_closet/marine_personal/unsc/alpha/rifleman/source_locker = allocate(/obj/structure/closet/secure_closet/marine_personal/unsc/alpha/rifleman, mainship_turf)
	source_locker.pixel_x = 11
	source_locker.pixel_y = -6
	source_locker.dir = WEST
	source_locker.density = FALSE
	source_locker.owner = "Mapper Locker"
	source_locker.x_to_linked_spawn_turf = linked_turf.x - source_locker.x
	source_locker.y_to_linked_spawn_turf = linked_turf.y - source_locker.y
	source_locker.linked_spawn_turf = linked_turf

	TEST_ASSERT(count_personal_locker_contents_by_exact_type(source_locker, /obj/item/device/radio/headset/almayer/marine/solardevils/unsc) >= 1, "UNSC locker baseline headset was missing before ship surface replacement test.")
	var/obj/item/device/flashlight/mapper_item = allocate(/obj/item/device/flashlight, source_locker)
	TEST_ASSERT(mapper_item in source_locker.contents, "Failed to seed mapper-added content into the source locker before replacement.")

	var/obj/structure/closet/secure_closet/marine_personal/target_locker = role_authority.replace_ship_surface_fixture(
		source_locker,
		"odst",
		role_authority.get_ship_surface_related_squad_markers(/datum/squad/marine/halo/odst/alpha)
	)
	track_test_atom(target_locker)

	TEST_ASSERT_NOTNULL(target_locker, "Locker ship surface replacement did not produce a target locker.")
	TEST_ASSERT_EQUAL(target_locker.type, /obj/structure/closet/secure_closet/marine_personal/odst/alpha/rifleman, "UNSC Alpha rifleman locker did not swap into the ODST Alpha rifleman locker.")
	TEST_ASSERT_EQUAL(target_locker.pixel_x, 11, "Locker ship surface replacement did not preserve pixel_x.")
	TEST_ASSERT_EQUAL(target_locker.pixel_y, -6, "Locker ship surface replacement did not preserve pixel_y.")
	TEST_ASSERT_EQUAL(target_locker.dir, WEST, "Locker ship surface replacement did not preserve direction.")
	TEST_ASSERT_EQUAL(target_locker.density, FALSE, "Locker ship surface replacement did not preserve density.")
	TEST_ASSERT_EQUAL(target_locker.owner, "Mapper Locker", "Locker ship surface replacement did not preserve locker owner metadata.")
	TEST_ASSERT_EQUAL(target_locker.x_to_linked_spawn_turf, linked_turf.x - mainship_turf.x, "Locker ship surface replacement did not preserve linked spawn X offset.")
	TEST_ASSERT_EQUAL(target_locker.y_to_linked_spawn_turf, linked_turf.y - mainship_turf.y, "Locker ship surface replacement did not preserve linked spawn Y offset.")
	TEST_ASSERT_EQUAL(target_locker.linked_spawn_turf, linked_turf, "Locker ship surface replacement did not preserve linked spawn turf.")
	TEST_ASSERT(mapper_item in target_locker.contents, "Locker ship surface replacement lost mapper-added contents.")
	TEST_ASSERT_EQUAL(count_personal_locker_contents_by_exact_type(target_locker, /obj/item/device/radio/headset/almayer/marine/solardevils/unsc), 0, "Locker ship surface replacement incorrectly carried over the exact UNSC baseline headset into the ODST locker.")
	TEST_ASSERT(count_personal_locker_contents_by_exact_type(target_locker, /obj/item/device/radio/headset/almayer/marine/solardevils/unsc/odst) >= 1, "Locker ship surface replacement did not keep the ODST baseline headset.")
	TEST_ASSERT_EQUAL(count_turf_contents_by_exact_type(mainship_turf, /obj/item/device/radio/headset/almayer/marine/solardevils/unsc), 0, "Locker ship surface replacement spilled the exact UNSC baseline headset onto the turf.")
	TEST_ASSERT_EQUAL(count_turf_contents_by_exact_type(mainship_turf, /obj/item/clothing/under/marine), 0, "Locker ship surface replacement spilled the exact UNSC baseline uniform onto the turf.")
	TEST_ASSERT_EQUAL(count_turf_contents_by_exact_type(mainship_turf, /obj/item/clothing/shoes/marine/knife), 0, "Locker ship surface replacement spilled the shared baseline knife onto the turf.")

/datum/unit_test/halo_ship_platoons_ship_surface_platoon_commander_locker_replacement
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_ship_surface_platoon_commander_locker_replacement/Run()
	configure_test_ship_platoon(/datum/squad/marine/halo/unsc/alpha)

	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	TEST_ASSERT_NOTNULL(role_authority, "RoleAuthority was unavailable for HALO platoon commander locker replacement testing.")

	var/turf/mainship_turf = get_mainship_test_turf()
	TEST_ASSERT_NOTNULL(mainship_turf, "Failed to resolve a mainship turf for HALO platoon commander locker replacement testing.")
	var/turf/linked_turf = locate(mainship_turf.x + 1, mainship_turf.y, mainship_turf.z)
	TEST_ASSERT_NOTNULL(linked_turf, "Failed to resolve a linked turf for HALO platoon commander locker replacement testing.")

	var/obj/structure/closet/secure_closet/marine_personal/unsc/platoon_commander/source_locker = allocate(/obj/structure/closet/secure_closet/marine_personal/unsc/platoon_commander, mainship_turf)
	isolate_personal_lockers(source_locker)
	track_test_atom(source_locker)
	source_locker.pixel_x = 7
	source_locker.pixel_y = -3
	source_locker.dir = EAST
	source_locker.owner = "Mapper Platoon Commander Locker"
	source_locker.x_to_linked_spawn_turf = linked_turf.x - source_locker.x
	source_locker.y_to_linked_spawn_turf = linked_turf.y - source_locker.y
	source_locker.linked_spawn_turf = linked_turf

	TEST_ASSERT(count_personal_locker_contents_by_exact_type(source_locker, /obj/item/device/radio/headset/almayer/marine/solardevils/pltco/unsc) >= 1, "UNSC platoon commander locker baseline headset was missing before ship surface replacement test.")

	var/obj/structure/closet/secure_closet/marine_personal/target_locker = role_authority.replace_ship_surface_fixture(
		source_locker,
		"odst",
		role_authority.get_ship_surface_related_squad_markers(/datum/squad/marine/halo/odst/alpha)
	)
	track_test_atom(target_locker)

	TEST_ASSERT_NOTNULL(target_locker, "Platoon commander locker ship surface replacement did not produce a target locker.")
	TEST_ASSERT_EQUAL(target_locker.type, /obj/structure/closet/secure_closet/marine_personal/odst/platoon_commander, "UNSC platoon commander locker did not swap into the ODST platoon commander locker.")
	TEST_ASSERT_EQUAL(target_locker.pixel_x, 7, "Platoon commander locker ship surface replacement did not preserve pixel_x.")
	TEST_ASSERT_EQUAL(target_locker.pixel_y, -3, "Platoon commander locker ship surface replacement did not preserve pixel_y.")
	TEST_ASSERT_EQUAL(target_locker.dir, EAST, "Platoon commander locker ship surface replacement did not preserve direction.")
	TEST_ASSERT_EQUAL(target_locker.owner, "Mapper Platoon Commander Locker", "Platoon commander locker ship surface replacement did not preserve locker owner metadata.")
	TEST_ASSERT_EQUAL(target_locker.linked_spawn_turf, linked_turf, "Platoon commander locker ship surface replacement did not preserve linked spawn turf.")
	TEST_ASSERT_EQUAL(count_personal_locker_contents_by_exact_type(target_locker, /obj/item/device/radio/headset/almayer/marine/solardevils/pltco/unsc), 0, "Platoon commander locker ship surface replacement incorrectly carried over the exact UNSC command headset into the ODST locker.")
	TEST_ASSERT(count_personal_locker_contents_by_exact_type(target_locker, /obj/item/device/radio/headset/almayer/marine/solardevils/pltco/odst) >= 1, "Platoon commander locker ship surface replacement did not keep the ODST command headset.")

/datum/unit_test/halo_ship_platoons_ship_surface_base_platoon_commander_locker_replacement
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_ship_surface_base_platoon_commander_locker_replacement/Run()
	configure_test_ship_platoon(/datum/squad/marine/halo/unsc/alpha)

	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	TEST_ASSERT_NOTNULL(role_authority, "RoleAuthority was unavailable for base platoon commander locker replacement testing.")

	var/turf/mainship_turf = get_mainship_test_turf()
	TEST_ASSERT_NOTNULL(mainship_turf, "Failed to resolve a mainship turf for base platoon commander locker replacement testing.")

	var/obj/structure/closet/secure_closet/marine_personal/platoon_commander/source_locker = allocate(/obj/structure/closet/secure_closet/marine_personal/platoon_commander, mainship_turf)
	isolate_personal_lockers(source_locker)
	track_test_atom(source_locker)

	var/list/surface_key = role_authority.get_ship_surface_key(source_locker)
	TEST_ASSERT(islist(surface_key), "Base platoon commander locker did not produce a ship surface key.")
	TEST_ASSERT_EQUAL(surface_key["kind"], "locker", "Base platoon commander locker did not register as a locker ship surface fixture.")
	TEST_ASSERT_EQUAL(surface_key["role"], JOB_SO, "Base platoon commander locker did not normalize to the canonical SO role.")

	var/obj/structure/closet/secure_closet/marine_personal/target_locker = role_authority.replace_ship_surface_fixture(
		source_locker,
		"unsc",
		role_authority.get_ship_surface_related_squad_markers(/datum/squad/marine/halo/unsc/alpha)
	)
	track_test_atom(target_locker)

	TEST_ASSERT_NOTNULL(target_locker, "Base platoon commander locker ship surface replacement did not produce a target locker.")
	TEST_ASSERT_EQUAL(target_locker.type, /obj/structure/closet/secure_closet/marine_personal/unsc/platoon_commander, "Base platoon commander locker did not swap into the UNSC platoon commander locker.")
	TEST_ASSERT(count_personal_locker_contents_by_exact_type(target_locker, /obj/item/device/radio/headset/almayer/marine/solardevils/pltco/unsc) >= 1, "Base platoon commander locker replacement did not yield the UNSC command headset.")

/datum/unit_test/halo_ship_platoons_ship_surface_fixture_collection_contracts
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_ship_surface_fixture_collection_contracts/Run()
	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	TEST_ASSERT_NOTNULL(role_authority, "RoleAuthority was unavailable for ship surface fixture-collection testing.")

	var/turf/mainship_turf = get_mainship_test_turf()
	TEST_ASSERT_NOTNULL(mainship_turf, "Failed to resolve a mainship turf for ship surface fixture-collection testing.")

	var/obj/structure/closet/secure_closet/marine_personal/platoon_commander/registry_locker = allocate(/obj/structure/closet/secure_closet/marine_personal/platoon_commander, mainship_turf)
	var/obj/structure/closet/secure_closet/marine_personal/platoon_commander/world_only_locker = allocate(/obj/structure/closet/secure_closet/marine_personal/platoon_commander, mainship_turf)
	var/obj/structure/closet/secure_closet/marine_personal/unsc_crew/crew_locker = allocate(/obj/structure/closet/secure_closet/marine_personal/unsc_crew, mainship_turf)
	var/list/registry_lockers = role_authority.collect_main_ship_surface_fixtures(/obj/structure/closet/secure_closet/marine_personal, list(registry_locker, crew_locker))
	TEST_ASSERT(registry_lockers.Find(registry_locker), "Ship surface fixture collection failed to keep a registry-listed locker candidate.")
	TEST_ASSERT(!registry_lockers.Find(world_only_locker), "Ship surface fixture collection should not fall back to world scan while a locker registry is present.")
	TEST_ASSERT(!registry_lockers.Find(crew_locker), "Ship surface fixture collection incorrectly included a non-replaceable UNSC crew locker.")

	var/list/fallback_lockers = role_authority.collect_main_ship_surface_fixtures(/obj/structure/closet/secure_closet/marine_personal, list())
	TEST_ASSERT(fallback_lockers.Find(registry_locker), "Ship surface fixture world fallback missed a replaceable locker.")
	TEST_ASSERT(fallback_lockers.Find(world_only_locker), "Ship surface fixture world fallback missed a locker that only exists in the world.")
	TEST_ASSERT(!fallback_lockers.Find(crew_locker), "Ship surface fixture world fallback incorrectly included a non-replaceable crew locker.")

	var/obj/structure/machinery/cm_vending/sorted/medical/unsc/registry_vendor = allocate(/obj/structure/machinery/cm_vending/sorted/medical/unsc, mainship_turf)
	var/obj/structure/machinery/cm_vending/sorted/marine_food/unsc/world_only_vendor = allocate(/obj/structure/machinery/cm_vending/sorted/marine_food/unsc, mainship_turf)
	var/list/registry_vendors = role_authority.collect_main_ship_surface_fixtures(/obj/structure/machinery/cm_vending, list(registry_vendor))
	TEST_ASSERT(registry_vendors.Find(registry_vendor), "Ship surface fixture collection failed to keep a registry-listed vendor candidate.")
	TEST_ASSERT(!registry_vendors.Find(world_only_vendor), "Ship surface fixture collection should not fall back to world scan while a vendor registry is present.")

	var/list/fallback_vendors = role_authority.collect_main_ship_surface_fixtures(/obj/structure/machinery/cm_vending, list())
	TEST_ASSERT(fallback_vendors.Find(registry_vendor), "Ship surface fixture world fallback missed a replaceable vendor.")
	TEST_ASSERT(fallback_vendors.Find(world_only_vendor), "Ship surface fixture world fallback missed a vendor that only exists in the world.")

/datum/unit_test/halo_ship_platoons_sync_pending_same_ship_platoon_for_round_start
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_sync_pending_same_ship_platoon_for_round_start/Run()
	configure_test_ship_platoon(/datum/squad/marine/halo/unsc/alpha)

	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	TEST_ASSERT_NOTNULL(role_authority, "RoleAuthority was unavailable for pending same-ship platoon sync testing.")

	var/datum/map_config/current_ship_config = SSmapping?.configs?[SHIP_MAP]
	TEST_ASSERT_NOTNULL(current_ship_config, "Failed to resolve the current ship config for pending same-ship platoon sync testing.")

	var/datum/map_config/pending_ship_config = load_map_config("maps/unsc_stalwart_frigate.json", maptype = SHIP_MAP)
	TEST_ASSERT_NOTNULL(pending_ship_config, "Failed to load the HALO ship config for pending same-ship platoon sync testing.")
	current_ship_config.map_name = pending_ship_config.map_name // SS220 EDIT: same-ship sync only applies when the loaded ship already matches the queued ship
	current_ship_config.map_path = pending_ship_config.map_path // SS220 EDIT: fixture must mirror the loaded Stalwart config before testing same-map platoon sync
	pending_ship_config.platoon = "/datum/squad/marine/halo/odst/alpha"
	SSmapping.next_map_configs = list(SHIP_MAP = pending_ship_config)

	TEST_ASSERT(role_authority.sync_pending_same_ship_platoon_for_round_start(), "Pending same-ship platoon sync did not accept the queued ODST override for the loaded Stalwart Frigate.")
	TEST_ASSERT_EQUAL(current_ship_config.platoon, "/datum/squad/marine/halo/odst/alpha", "Pending same-ship platoon sync did not update the current ship config to the queued ODST profile.")

/datum/unit_test/halo_ship_platoons_ship_surface_vendor_replacement
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_ship_surface_vendor_replacement/Run()
	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	TEST_ASSERT_NOTNULL(role_authority, "RoleAuthority was unavailable for vendor ship surface replacement test.")

	var/turf/mainship_turf = get_mainship_test_turf()
	TEST_ASSERT_NOTNULL(mainship_turf, "Failed to resolve a mainship turf for vendor ship surface replacement test.")

	var/obj/structure/machinery/cm_vending/sorted/marine_food/unsc/alt/source_vendor = allocate(/obj/structure/machinery/cm_vending/sorted/marine_food/unsc/alt, mainship_turf)
	source_vendor.pixel_x = -10
	source_vendor.pixel_y = 4
	source_vendor.dir = SOUTH
	source_vendor.density = FALSE
	source_vendor.listed_products = list(list("BOGUS", 1, /obj/item/device/flashlight, VENDOR_ITEM_REGULAR))

	var/obj/item/device/flashlight/mapper_item = allocate(/obj/item/device/flashlight, source_vendor)
	TEST_ASSERT(mapper_item in source_vendor.contents, "Failed to seed mapper-added content into the source vendor before replacement.")

	var/obj/structure/machinery/cm_vending/target_vendor = role_authority.replace_ship_surface_fixture(
		source_vendor,
		"odst",
		role_authority.get_ship_surface_related_squad_markers(/datum/squad/marine/halo/odst/alpha)
	)
	track_test_atom(target_vendor)

	TEST_ASSERT_NOTNULL(target_vendor, "Vendor ship surface replacement did not produce a target vendor.")
	TEST_ASSERT_EQUAL(target_vendor.type, /obj/structure/machinery/cm_vending/sorted/marine_food/unsc/odst/alt, "UNSC alternate food vendor did not swap into the ODST alternate food vendor.")
	TEST_ASSERT_EQUAL(target_vendor.pixel_x, -10, "Vendor ship surface replacement did not preserve pixel_x.")
	TEST_ASSERT_EQUAL(target_vendor.pixel_y, 4, "Vendor ship surface replacement did not preserve pixel_y.")
	TEST_ASSERT_EQUAL(target_vendor.dir, SOUTH, "Vendor ship surface replacement did not preserve direction.")
	TEST_ASSERT_EQUAL(target_vendor.density, FALSE, "Vendor ship surface replacement did not preserve density.")
	TEST_ASSERT(mapper_item in target_vendor.contents, "Vendor ship surface replacement lost mapper-added contents.")
	TEST_ASSERT(length(target_vendor.listed_products) == 0 || target_vendor.listed_products[1][1] != "BOGUS", "Vendor ship surface replacement incorrectly copied source listed_products into the new vendor.")

