/datum/unit_test/halo_ship_platoons_so_lifecycle_hooks
	parent_type = /datum/unit_test/halo_integration_test

/datum/unit_test/halo_ship_platoons_so_lifecycle_hooks/Run()
	configure_test_ship_platoon(/datum/squad/marine/halo/unsc/alpha)

	TEST_ASSERT(ispath(/datum/equipment_preset/unsc/platco, /datum/equipment_preset/uscm_ship/so), "HALO UNSC Platoon Commander preset no longer inherits the vanilla SO lifecycle hooks.")
	TEST_ASSERT(ispath(/datum/equipment_preset/unsc/platco/lesser_rank, /datum/equipment_preset/unsc/platco), "HALO UNSC lesser-rank Platoon Commander preset no longer inherits the HALO Platoon Commander runtime metadata.")
	TEST_ASSERT(ispath(/datum/equipment_preset/unsc/platco/odst, /datum/equipment_preset/uscm_ship/so), "HALO ODST Platoon Commander preset no longer inherits the vanilla SO lifecycle hooks.")
	TEST_ASSERT(ispath(/datum/equipment_preset/unsc/platco/odst/lesser_rank, /datum/equipment_preset/unsc/platco/odst), "HALO ODST lesser-rank Platoon Commander preset no longer inherits the HALO ODST Platoon Commander runtime metadata.")

	var/datum/squad_name_manager/manager = GLOB.squad_name_manager
	TEST_ASSERT_NOTNULL(manager, "Squad name manager was unavailable for HALO SO lifecycle testing.")
	manager.apply_roundstart_defaults()
	manager.reset_first_platoon_commander()

	var/datum/squad/alpha_squad = manager.get_squad_by_static(SQUAD_MARINE_1)
	TEST_ASSERT_NOTNULL(alpha_squad, "Failed to resolve Alpha squad for HALO SO lifecycle testing.")
	var/rename_result = manager.rename_squad(alpha_squad, "Unit Test Alpha", null, "halo_so_lifecycle_test", TRUE)
	TEST_ASSERT_EQUAL(rename_result, TRUE, "Failed to seed a non-default Alpha squad name before HALO SO latejoin lifecycle testing.")
	TEST_ASSERT_EQUAL(alpha_squad.name, "Unit Test Alpha", "Alpha squad setup for HALO SO lifecycle testing did not take effect.")

	var/mob/living/carbon/human/halo_so = create_test_human("HALO Platoon Commander", JOB_SO_UNSC, null, run_loc_floor_top_right, "halo_so_lifecycle")
	arm_equipment(halo_so, /datum/equipment_preset/unsc/platco, FALSE, TRUE, null, TRUE, TRUE)

	TEST_ASSERT_EQUAL(alpha_squad.name, manager.get_default_name_by_static(SQUAD_MARINE_1), "HALO SO latejoin lifecycle no longer restores the first-platoon-commander squad-name fallback.")

/datum/unit_test/halo_ship_platoons_platoon_commander_preference_handles_job_datum
	parent_type = /datum/unit_test/halo_integration_test

/datum/unit_test/halo_ship_platoons_platoon_commander_preference_handles_job_datum/Run()
	configure_test_ship_platoon(/datum/squad/marine/halo/unsc/alpha)

	var/datum/squad_name_manager/manager = GLOB.squad_name_manager
	TEST_ASSERT_NOTNULL(manager, "Squad name manager was unavailable for HALO Platoon Commander preference regression testing.")
	manager.reset_first_platoon_commander()

	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	TEST_ASSERT_NOTNULL(role_authority, "RoleAuthority was unavailable for HALO Platoon Commander preference regression testing.")
	var/datum/job/so_job = role_authority.roles_by_name[JOB_SO_UNSC]
	TEST_ASSERT_NOTNULL(so_job, "Failed to resolve the HALO UNSC Platoon Commander job datum for preference regression testing.")

	var/mob/living/carbon/human/halo_so = create_test_human("HALO Platoon Commander Pref", JOB_SO_UNSC, null, run_loc_floor_top_right, "halo_so_pref")
	halo_so.job = so_job

	TEST_ASSERT(manager.claim_first_platoon_commander(halo_so), "Platoon Commander preference claim should accept HALO job datums without bad-indexing the default-role map.")

/datum/unit_test/halo_ship_platoons_spawn_resolution_contracts
	parent_type = /datum/unit_test/halo_integration_test

/datum/unit_test/halo_ship_platoons_spawn_resolution_contracts/Run()
	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	TEST_ASSERT_NOTNULL(role_authority, "RoleAuthority was unavailable for HALO spawn resolution testing.")

	configure_test_ship_platoon(/datum/squad/marine/halo/unsc/alpha)

	var/mob/living/carbon/human/unsc_human = create_test_human("HALO UNSC Roundstart Corpsman", JOB_SQUAD_MEDIC_UNSC)
	arm_equipment(unsc_human, /datum/equipment_preset/unsc/medic, FALSE, TRUE)
	role_authority.randomize_squad(unsc_human, TRUE)
	assert_assigned_to_platoon_family(unsc_human, /datum/squad/marine/halo/unsc/alpha, "HALO UNSC roundstart corpsman")
	cleanup_test_squad_membership(unsc_human)

	configure_test_ship_platoon(/datum/squad/marine/halo/odst/alpha)

	var/mob/living/carbon/human/odst_human = create_test_human("HALO ODST Roundstart Specialist", JOB_SQUAD_SPECIALIST_ODST)
	arm_equipment(odst_human, /datum/equipment_preset/unsc/spec/odst, FALSE, TRUE)
	role_authority.randomize_squad(odst_human, TRUE)
	assert_assigned_to_platoon_family(odst_human, /datum/squad/marine/halo/odst/alpha, "HALO ODST roundstart specialist")
	cleanup_test_squad_membership(odst_human)

	configure_test_ship_platoon(/datum/squad/marine/halo/unsc/alpha)

	var/datum/job/job_datum = role_authority.roles_by_name[JOB_SQUAD_MEDIC_UNSC]
	TEST_ASSERT_NOTNULL(job_datum, "Failed to resolve JOB_SQUAD_MEDIC_UNSC datum for HALO latejoin resolver regression test.")

	var/turf/squad_turf = run_loc_floor_top_right
	var/turf/job_turf = get_step(squad_turf, WEST)
	if(!isfloorturf(job_turf))
		job_turf = get_step(squad_turf, EAST)
	if(!isfloorturf(job_turf))
		job_turf = get_step(squad_turf, NORTH)
	if(!isfloorturf(job_turf))
		job_turf = get_step(squad_turf, SOUTH)
	TEST_ASSERT(isfloorturf(job_turf), "Failed to find a fallback turf for HALO latejoin resolver regression test.")

	var/mob/living/carbon/human/latejoin_human = create_test_human("HALO Latejoin Resolver", JOB_SQUAD_MEDIC_UNSC, /datum/squad/marine/halo/unsc/alpha, run_loc_floor_bottom_left)
	TEST_ASSERT_NOTNULL(latejoin_human.assigned_squad, "Failed to assign a HALO squad for latejoin resolver regression test.")

	var/obj/effect/landmark/late_join/squad_landmark = allocate(/obj/effect/landmark/late_join, squad_turf)
	var/obj/effect/landmark/late_join/job_landmark = allocate(/obj/effect/landmark/late_join, job_turf)
	GLOB.latejoin -= squad_landmark
	GLOB.latejoin -= job_landmark

	squad_landmark.job = job_datum.title
	job_landmark.job = job_datum.title
	GLOB.latejoin_by_squad = list(latejoin_human.assigned_squad.name = list(squad_landmark))
	GLOB.latejoin_by_job = list(job_datum.title = list(job_landmark))

	var/datum/modular_squad_spawn_resolver/resolver = new(latejoin_human, job_datum, TRUE)
	var/list/own_squad_keys = resolver.get_own_squad_keys()
	var/list/other_squad_keys = resolver.get_other_squad_keys(own_squad_keys)
	var/list/own_landmarks = resolver.collect_latejoin_landmarks(own_squad_keys, exact_job = TRUE)
	TEST_ASSERT(own_landmarks.Find(squad_landmark), "Latejoin resolver exact squad tier did not collect the squad landmark.")

	var/list/job_landmarks = resolver.collect_latejoin_job_landmarks()
	TEST_ASSERT(job_landmarks.Find(job_landmark), "Latejoin resolver regression test did not expose the job fallback landmark.")

	var/datum/modular_squad_spawn_result/result = resolver.pick_result_for_step("latejoin", 1, own_squad_keys, other_squad_keys, require_free_pod = FALSE)
	TEST_ASSERT_NOTNULL(result, "Latejoin resolver tier 1 failed to produce a result when a squad landmark existed.")
	TEST_ASSERT_EQUAL(result.landmark, squad_landmark, "Latejoin resolver tier 1 fell through instead of using the squad latejoin landmark.")
	TEST_ASSERT_EQUAL(result.source_tag, "latejoin", "Latejoin resolver regression test produced an unexpected source tag.")
	TEST_ASSERT_EQUAL(result.tier_tag, "tier_1", "Latejoin resolver regression test produced an unexpected tier tag.")

	var/turf/center_turf = run_loc_floor_top_right
	TEST_ASSERT_NOTNULL(center_turf, "Failed to resolve test turf for SO spawn roundstart test.")
	var/turf/holding_turf = run_loc_floor_bottom_left
	TEST_ASSERT(isfloorturf(holding_turf), "Failed to resolve holding turf for SO spawn roundstart test.")

	var/turf/pod_turf = get_step(center_turf, WEST)
	if(!isturf(pod_turf))
		pod_turf = get_step(center_turf, EAST)
	if(!isturf(pod_turf))
		pod_turf = get_step(center_turf, NORTH)
	if(!isturf(pod_turf))
		pod_turf = get_step(center_turf, SOUTH)
	TEST_ASSERT_NOTNULL(pod_turf, "Failed to find adjacent turf for SO spawn roundstart test cryopod.")

	allocate(/obj/effect/landmark/start/bridge, center_turf)
	allocate(/obj/structure/machinery/cryopod, pod_turf)

	var/datum/job/so_job = role_authority.roles_by_name[JOB_SO_UNSC]
	TEST_ASSERT_NOTNULL(so_job, "Failed to resolve JOB_SO_UNSC datum for SO spawn roundstart test.")

	var/mob/living/carbon/human/so_human = create_test_human("HALO SO Spawn Candidate", JOB_SO_UNSC, null, holding_turf)
	var/list/spawn_candidate = so_human.get_modular_spawn_candidate(so_job, FALSE)

	TEST_ASSERT_NOTNULL(spawn_candidate, "Modular spawn candidate was null for SO roundstart test.")
	TEST_ASSERT_EQUAL(spawn_candidate["source_tag"], "start_job", "SO spawn candidate source tag was not start_job.")
	TEST_ASSERT_EQUAL(spawn_candidate["tier_tag"], "job", "SO spawn candidate tier tag was not job.")
	TEST_ASSERT_EQUAL(spawn_candidate["no_pod_expected"], FALSE, "SO spawn candidate unexpectedly marked no_pod_expected.")
	TEST_ASSERT(isfloorturf(spawn_candidate["spawn_turf"]), "SO spawn candidate did not resolve to a floor turf.")
	TEST_ASSERT(istype(spawn_candidate["preferred_pod"], /obj/structure/machinery/cryopod), "SO spawn candidate did not resolve to a cryopod.")
	TEST_ASSERT_EQUAL(get_dist(spawn_candidate["spawn_turf"], get_turf(spawn_candidate["preferred_pod"])), 1, "SO spawn candidate did not keep the preferred cryopod cardinally adjacent to its spawn turf.")

/datum/unit_test/halo_ship_platoons_cryo_lifecycle_contracts
	parent_type = /datum/unit_test/halo_integration_test

/datum/unit_test/halo_ship_platoons_cryo_lifecycle_contracts/Run()
	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	TEST_ASSERT_NOTNULL(role_authority, "RoleAuthority was unavailable for HALO cryo lifecycle testing.")
	var/datum/emergency_call/cryo_squad/cryo_call = allocate(/datum/emergency_call/cryo_squad)
	TEST_ASSERT_NOTNULL(cryo_call, "Failed to allocate the cryo emergency-call helper for HALO cryo lifecycle testing.")

	configure_test_ship_platoon(/datum/squad/marine/halo/unsc/alpha)

	var/mob/living/carbon/human/unsc_medic = create_test_human("HALO Cryo Medic", JOB_SQUAD_MEDIC)
	TEST_ASSERT(cryo_call.apply_profile_cryo_reinforcement(unsc_medic, JOB_SQUAD_MEDIC, JOB_SQUAD_MEDIC, null, FALSE, /datum/squad/marine/halo/unsc/alpha), "HALO UNSC cryo helper failed to apply a supported medic override.")
	assert_halo_smoke_state(unsc_medic, /datum/equipment_preset/unsc/medic, JOB_SQUAD_MEDIC_UNSC)
	assert_assigned_to_platoon_family(unsc_medic, /datum/squad/marine/halo/unsc/alpha, "HALO UNSC cryo medic")
	var/obj/item/card/id/unsc_medic_id = unsc_medic.get_idcard()
	TEST_ASSERT_EQUAL(unsc_medic_id?.faction, FACTION_UNSC, "HALO UNSC cryo application helper did not keep FACTION_UNSC on the medic ID metadata.")

	var/mob/living/carbon/human/unsupported_engineer = create_test_human("Unsupported HALO Engineer", JOB_SQUAD_ENGI)
	TEST_ASSERT(!cryo_call.apply_profile_cryo_reinforcement(unsupported_engineer, JOB_SQUAD_ENGI, JOB_SQUAD_ENGI, /datum/equipment_preset/uscm/engineer_equipped, FALSE, /datum/squad/marine/halo/unsc/alpha), "HALO cryo application helper incorrectly accepted an unsupported engineer profile override.")

	var/mob/living/carbon/human/title_human = create_test_human("HALO Title Override Specialist", JOB_SQUAD_SPECIALIST_UNSC)
	arm_equipment(title_human, /datum/equipment_preset/unsc/spec, FALSE, TRUE)
	var/obj/item/card/id/title_id = title_human.get_idcard()
	TEST_ASSERT_NOTNULL(title_id, "HALO title-independence test did not receive an ID card from the specialist preset.")

	title_human.title = "Custom HALO Display Title"
	role_authority.randomize_squad(title_human, TRUE)

	assert_assigned_to_platoon_family(title_human, /datum/squad/marine/halo/unsc/alpha, "HALO custom-title specialist")
	TEST_ASSERT_EQUAL(title_id?.assignment, JOB_SQUAD_SPECIALIST_UNSC, "Changing the HALO display title altered specialist ID assignment metadata.")
	TEST_ASSERT_EQUAL(title_id?.rank, JOB_SQUAD_SPECIALIST_UNSC, "Changing the HALO display title altered specialist ID rank metadata.")
	TEST_ASSERT_NOTEQUAL(title_id?.assignment, "[title_human.assigned_squad?.name] [JOB_SQUAD_SPECIALIST_UNSC]", "HALO specialist ID assignment regressed back to a squad-prefixed display label.")
	if(title_human.assigned_fireteam == "SQ1")
		TEST_ASSERT(title_id.access.Find(ACCESS_SQUAD_ONE), "Changing the HALO display title altered SQ1 access routing for the specialist ID.")
	else if(title_human.assigned_fireteam == "SQ2")
		TEST_ASSERT(title_id.access.Find(ACCESS_SQUAD_TWO), "Changing the HALO display title altered SQ2 access routing for the specialist ID.")
	else
		TEST_FAIL("HALO title-independence test assigned the specialist to an unexpected fireteam.")
	cleanup_test_squad_membership(title_human)

	var/mob/living/carbon/human/cryo_title_human = create_test_human("HALO Title Override Corpsman", JOB_SQUAD_MEDIC_UNSC)
	arm_equipment(cryo_title_human, /datum/equipment_preset/unsc/medic, FALSE, TRUE)
	cryo_title_human.title = "Custom HALO Cryo Display Title"
	cryo_title_human.assigned_squad = null

	var/obj/item/card/id/cryo_id = cryo_title_human.get_idcard()
	TEST_ASSERT_NOTNULL(cryo_id, "HALO title-independence cryo subcase did not receive an ID card from the medic preset.")

	cryo_call.finalize_profile_cryo_reinforcement(cryo_title_human)
	assert_assigned_to_platoon_family(cryo_title_human, /datum/squad/marine/halo/unsc/alpha, "HALO custom-title cryo corpsman")
	TEST_ASSERT_EQUAL(cryo_id?.assignment, JOB_SQUAD_MEDIC_UNSC, "Changing the HALO display title altered cryo medic ID assignment metadata.")
	TEST_ASSERT_EQUAL(cryo_id?.rank, JOB_SQUAD_MEDIC_UNSC, "Changing the HALO display title altered cryo medic ID rank metadata.")

	configure_test_ship_platoon(/datum/squad/marine/halo/odst/alpha)

	var/mob/living/carbon/human/odst_medic = create_test_human("HALO ODST Cryo Medic", JOB_SQUAD_MEDIC)
	TEST_ASSERT(cryo_call.apply_profile_cryo_reinforcement(odst_medic, JOB_SQUAD_MEDIC, JOB_SQUAD_MEDIC, null, FALSE, /datum/squad/marine/halo/odst/alpha), "HALO ODST cryo helper failed to apply a supported medic override.")
	assert_halo_smoke_state(odst_medic, /datum/equipment_preset/unsc/medic/odst, JOB_SQUAD_MEDIC_ODST)
	assert_assigned_to_platoon_family(odst_medic, /datum/squad/marine/halo/odst/alpha, "HALO ODST cryo medic")

/datum/unit_test/halo_ship_platoons_leader_hud_icon
	parent_type = /datum/unit_test/halo_integration_test

/datum/unit_test/halo_ship_platoons_leader_hud_icon/Run()
	var/datum/faction/unsc/faction = allocate(/datum/faction/unsc)
	var/image/unsc_holder = image(null)
	var/image/odst_holder = image(null)

	var/mob/living/carbon/human/unsc_leader = create_test_human("HALO UNSC Section Leader", JOB_SQUAD_LEADER_UNSC)
	var/datum/squad/marine/halo/unsc/bravo/unsc_section = allocate(/datum/squad/marine/halo/unsc/bravo)
	var/unsc_lead_icon = unsc_section.lead_icon || "leader"
	unsc_leader.assigned_squad = unsc_section
	unsc_section.squad_leader = unsc_leader
	faction.modify_hud_holder(unsc_holder, unsc_leader)
	TEST_ASSERT(holder_has_overlay_state(unsc_holder, "hudsquad_[unsc_lead_icon]"), "HALO UNSC Section leader did not receive the leader HUD overlay.")

	var/mob/living/carbon/human/odst_leader = create_test_human("HALO ODST Section Leader", JOB_SQUAD_LEADER_ODST)
	var/datum/squad/marine/halo/odst/bravo/odst_section = allocate(/datum/squad/marine/halo/odst/bravo)
	var/odst_lead_icon = odst_section.lead_icon || "leader"
	odst_leader.assigned_squad = odst_section
	odst_section.squad_leader = odst_leader
	faction.modify_hud_holder(odst_holder, odst_leader)
	TEST_ASSERT(holder_has_overlay_state(odst_holder, "hudsquad_[odst_lead_icon]"), "HALO ODST Section leader did not receive the leader HUD overlay.")

/datum/unit_test/halo_ship_platoons_surface_access_contracts
	parent_type = /datum/unit_test/halo_integration_test

/datum/unit_test/halo_ship_platoons_surface_access_contracts/Run()
	var/turf/vendor_turf = run_loc_floor_top_right
	var/turf/user_turf = get_step(vendor_turf, SOUTH)
	if(!isfloorturf(user_turf))
		user_turf = get_step(vendor_turf, NORTH)
	TEST_ASSERT(isfloorturf(user_turf), "Failed to find a user turf for HALO medical vendor access testing.")

	var/mob/living/carbon/human/vendor_human = create_test_human("UNSC Vendor Corpsman", JOB_SQUAD_MEDIC_UNSC, /datum/squad/marine/halo/unsc/alpha, user_turf)
	TEST_ASSERT_NOTNULL(prepare_test_human_for_squad(vendor_human, /datum/equipment_preset/unsc/medic, JOB_SQUAD_MEDIC_UNSC), "Failed to equip an ID onto the HALO medical vendor access test mob.")

	var/obj/structure/machinery/cm_vending/gear/medic_chemical/unsc/chem_vendor = allocate(/obj/structure/machinery/cm_vending/gear/medic_chemical/unsc, vendor_turf)
	TEST_ASSERT(chem_vendor.can_access_to_vend(vendor_human, FALSE), "HALO UNSC corpsman lost access to the chemical medic vendor.")

	var/obj/structure/machinery/cm_vending/sorted/medical/unsc/med_vendor = allocate(/obj/structure/machinery/cm_vending/sorted/medical/unsc, vendor_turf)
	med_vendor.req_access = list(ACCESS_MARINE_MEDPREP)
	TEST_ASSERT(med_vendor.can_access_to_vend(vendor_human, FALSE), "HALO UNSC corpsman lost access to the medical vendor when medprep access was required.")

	var/list/lifesaver_item = null
	for(var/list/product as anything in med_vendor.get_listed_products(vendor_human))
		if(product[3] == /obj/item/storage/belt/medical/lifesaver/unsc)
			lifesaver_item = product
			break

	TEST_ASSERT_NOTNULL(lifesaver_item, "Failed to resolve the Lifesaver Bag listing in the HALO medical vendor.")
	TEST_ASSERT_EQUAL(lifesaver_item[3], /obj/item/storage/belt/medical/lifesaver/unsc, "HALO medical vendor listing regressed away from the UNSC Lifesaver Bag.")

	var/turf/test_turf = run_loc_floor_top_right
	var/datum/squad/marine/halo/unsc/alpha/squad = allocate(/datum/squad/marine/halo/unsc/alpha)
	var/obj/structure/closet/secure_closet/halo/job_locker/weapons_spec/ft1/locker_ft1 = allocate(/obj/structure/closet/secure_closet/halo/job_locker/weapons_spec/ft1, test_turf)
	var/obj/structure/closet/secure_closet/halo/job_locker/weapons_spec/ft2/locker_ft2 = allocate(/obj/structure/closet/secure_closet/halo/job_locker/weapons_spec/ft2, test_turf)

	var/mob/living/carbon/human/first_specialist = create_test_human("HALO UNSC Spec One", JOB_SQUAD_SPECIALIST, null, test_turf)
	var/obj/item/card/id/first_id = prepare_test_human_for_squad(first_specialist, /datum/equipment_preset/unsc/spec, JOB_SQUAD_SPECIALIST)
	TEST_ASSERT_NOTNULL(first_id, "Failed to equip an ID onto the first HALO UNSC specialist test mob.")
	TEST_ASSERT(squad.put_marine_in_squad(first_specialist), "Failed to insert the first HALO UNSC specialist into a squad for locker access testing.")
	TEST_ASSERT_EQUAL(first_specialist.assigned_fireteam, "SQ1", "The first HALO UNSC specialist was not assigned to SQ1.")
	TEST_ASSERT(first_id.access.Find(ACCESS_SQUAD_ONE), "The first HALO UNSC specialist ID did not receive ACCESS_SQUAD_ONE.")
	TEST_ASSERT(locker_ft1.allowed(first_specialist), "The first HALO UNSC specialist could not access the SQ1 weapons locker after squad insertion.")
	TEST_ASSERT(!locker_ft2.allowed(first_specialist), "The first HALO UNSC specialist incorrectly gained access to the SQ2 weapons locker.")

	var/mob/living/carbon/human/second_specialist = create_test_human("HALO UNSC Spec Two", JOB_SQUAD_SPECIALIST, null, test_turf)
	var/obj/item/card/id/second_id = prepare_test_human_for_squad(second_specialist, /datum/equipment_preset/unsc/spec, JOB_SQUAD_SPECIALIST)
	TEST_ASSERT_NOTNULL(second_id, "Failed to equip an ID onto the second HALO UNSC specialist test mob.")
	TEST_ASSERT(squad.put_marine_in_squad(second_specialist), "Failed to insert the second HALO UNSC specialist into a squad for locker access testing.")
	TEST_ASSERT_EQUAL(second_specialist.assigned_fireteam, "SQ2", "The second HALO UNSC specialist was not assigned to SQ2.")
	TEST_ASSERT(second_id.access.Find(ACCESS_SQUAD_TWO), "The second HALO UNSC specialist ID did not receive ACCESS_SQUAD_TWO.")
	TEST_ASSERT(locker_ft2.allowed(second_specialist), "The second HALO UNSC specialist could not access the SQ2 weapons locker after squad insertion.")
	TEST_ASSERT(!locker_ft1.allowed(second_specialist), "The second HALO UNSC specialist incorrectly gained access to the SQ1 weapons locker.")

/datum/unit_test/halo_ship_platoons_personal_locker_contracts
	parent_type = /datum/unit_test/halo_integration_test

/datum/unit_test/halo_ship_platoons_personal_locker_contracts/Run()
	configure_test_ship_platoon(/datum/squad/marine/halo/unsc/alpha)

	var/datum/equipment_preset/preset = allocate(/datum/equipment_preset)

	var/mob/living/carbon/human/unsc_human = create_test_human("HALO UNSC Spec Roundstart", JOB_SQUAD_SPECIALIST, /datum/squad/marine/halo/unsc/alpha)
	var/obj/structure/closet/secure_closet/marine_personal/unsc/alpha/specialist/unsc_locker = allocate(/obj/structure/closet/secure_closet/marine_personal/unsc/alpha/specialist)
	isolate_personal_lockers(unsc_locker)
	TEST_ASSERT(preset.try_handle_personal_locker_vanity(unsc_human, null, FALSE), "Roundstart locker handling returned FALSE for HALO UNSC specialist.")
	TEST_ASSERT_EQUAL(unsc_locker.owner, unsc_human.real_name, "HALO UNSC specialist personal locker was not claimed on roundstart.")
	TEST_ASSERT(findtext(unsc_locker.name, unsc_human.real_name), "HALO UNSC specialist personal locker name was not personalized on roundstart.")
	TEST_ASSERT(unsc_locker.allowed(unsc_human), "Claimed HALO UNSC specialist personal locker did not open for its owner.")
	TEST_ASSERT(count_personal_locker_contents_by_type(unsc_locker, /obj/item/clothing/under/marine) >= 1, "HALO UNSC specialist personal locker lost its baseline uniform on roundstart claim.")
	TEST_ASSERT(count_personal_locker_contents_by_type(unsc_locker, /obj/item/device/radio/headset/almayer/marine/solardevils/unsc) >= 1, "HALO UNSC specialist personal locker lost its baseline headset on roundstart claim.")

	configure_test_ship_platoon(/datum/squad/marine/halo/odst/alpha)

	var/mob/living/carbon/human/odst_human = create_test_human("HALO ODST Spec Latejoin", JOB_SQUAD_SPECIALIST, /datum/squad/marine/halo/odst/alpha)
	var/obj/structure/closet/secure_closet/marine_personal/odst/alpha/specialist/odst_locker = allocate(/obj/structure/closet/secure_closet/marine_personal/odst/alpha/specialist)
	isolate_personal_lockers(odst_locker)
	TEST_ASSERT(preset.try_handle_personal_locker_vanity(odst_human, null, TRUE), "Latejoin locker handling returned FALSE for HALO ODST specialist.")
	TEST_ASSERT_EQUAL(odst_locker.owner, odst_human.real_name, "HALO ODST specialist personal locker was not claimed on latejoin.")
	TEST_ASSERT(odst_locker.allowed(odst_human), "Claimed HALO ODST specialist personal locker did not open for its owner on latejoin.")
	TEST_ASSERT(count_personal_locker_contents_by_type(odst_locker, /obj/item/device/radio/headset/almayer/marine/solardevils/unsc/odst) >= 1, "HALO ODST specialist personal locker lost its baseline headset on latejoin claim.")

	configure_test_ship_platoon(/datum/squad/marine/halo/unsc/alpha)

	var/mob/living/carbon/human/empty_claim_human = create_test_human("HALO Empty Locker Claim", JOB_SQUAD_SPECIALIST, /datum/squad/marine/halo/unsc/alpha)
	var/obj/structure/closet/secure_closet/marine_personal/unsc/alpha/specialist/empty_locker = allocate(/obj/structure/closet/secure_closet/marine_personal/unsc/alpha/specialist)
	isolate_personal_lockers(empty_locker)
	clear_personal_locker_contents(empty_locker)
	TEST_ASSERT_EQUAL(length(empty_locker.contents), 0, "Failed to empty HALO specialist personal locker before first-claim refill test.")
	TEST_ASSERT(preset.try_handle_personal_locker_vanity(empty_claim_human, null, FALSE), "Locker handling returned FALSE for empty first-claim refill test.")
	TEST_ASSERT(count_personal_locker_contents_by_type(empty_locker, /obj/item/clothing/under/marine) >= 1, "Empty HALO specialist locker was not refilled with baseline uniform on first claim.")
	TEST_ASSERT(count_personal_locker_contents_by_type(empty_locker, /obj/item/device/radio/headset/almayer/marine/solardevils/unsc) >= 1, "Empty HALO specialist locker was not refilled with baseline headset on first claim.")

	var/mob/living/carbon/human/nonempty_claim_human = create_test_human("HALO Nonempty Locker Claim", JOB_SQUAD_SPECIALIST, /datum/squad/marine/halo/unsc/alpha)
	var/obj/structure/closet/secure_closet/marine_personal/unsc/alpha/specialist/nonempty_locker = allocate(/obj/structure/closet/secure_closet/marine_personal/unsc/alpha/specialist)
	isolate_personal_lockers(nonempty_locker)
	var/uniforms_before = count_personal_locker_contents_by_type(nonempty_locker, /obj/item/clothing/under/marine)
	var/headsets_before = count_personal_locker_contents_by_type(nonempty_locker, /obj/item/device/radio/headset/almayer/marine/solardevils/unsc)
	var/shoes_before = count_personal_locker_contents_by_type(nonempty_locker, /obj/item/clothing/shoes/marine/knife)
	TEST_ASSERT(preset.try_handle_personal_locker_vanity(nonempty_claim_human, null, FALSE), "Locker handling returned FALSE for non-empty first-claim duplication test.")
	TEST_ASSERT_EQUAL(count_personal_locker_contents_by_type(nonempty_locker, /obj/item/clothing/under/marine), uniforms_before, "Non-empty HALO specialist locker duplicated baseline uniform on first claim.")
	TEST_ASSERT_EQUAL(count_personal_locker_contents_by_type(nonempty_locker, /obj/item/device/radio/headset/almayer/marine/solardevils/unsc), headsets_before, "Non-empty HALO specialist locker duplicated baseline headset on first claim.")
	TEST_ASSERT_EQUAL(count_personal_locker_contents_by_type(nonempty_locker, /obj/item/clothing/shoes/marine/knife), shoes_before, "Non-empty HALO specialist locker duplicated baseline shoes on first claim.")

	var/turf/mainship_turf = get_mainship_test_turf()
	TEST_ASSERT_NOTNULL(mainship_turf, "Failed to resolve a mainship turf for HALO personal-locker custom-item routing test.")

	var/mob/living/carbon/human/custom_item_human = create_test_human("HALO Custom Item Route", JOB_SQUAD_SPECIALIST, /datum/squad/marine/halo/unsc/alpha, mainship_turf, "locker_custom_tester")
	var/obj/structure/closet/secure_closet/marine_personal/unsc/alpha/specialist/custom_item_locker = allocate(/obj/structure/closet/secure_closet/marine_personal/unsc/alpha/specialist, mainship_turf)
	custom_item_locker.owner = custom_item_human.real_name
	isolate_personal_lockers(custom_item_locker)

	GLOB.custom_items = list("locker_custom_tester:/obj/item/device/flashlight")
	EquipCustomItems(custom_item_human)

	TEST_ASSERT(locate(/obj/item/device/flashlight) in custom_item_locker.contents, "Custom item routing failed to place an item into the claimed HALO personal locker.")

/datum/unit_test/halo_ship_platoons_ship_surface_replacement_contracts
	parent_type = /datum/unit_test/halo_integration_test

/datum/unit_test/halo_ship_platoons_ship_surface_replacement_contracts/Run()
	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	TEST_ASSERT_NOTNULL(role_authority, "RoleAuthority was unavailable for ship surface replacement testing.")

	var/turf/mainship_turf = get_mainship_test_turf(TRUE)
	TEST_ASSERT_NOTNULL(mainship_turf, "Failed to resolve a mainship turf for ship surface replacement testing.")

	var/turf/linked_turf = get_adjacent_floor_turf(mainship_turf)
	TEST_ASSERT(isfloorturf(linked_turf), "Failed to resolve linked spawn turf for ship surface replacement testing.")

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

	configure_test_ship_platoon(/datum/squad/marine/halo/unsc/alpha)

	var/obj/structure/closet/secure_closet/marine_personal/unsc/platoon_commander/source_pc_locker = allocate(/obj/structure/closet/secure_closet/marine_personal/unsc/platoon_commander, mainship_turf)
	source_pc_locker.pixel_x = 7
	source_pc_locker.pixel_y = -3
	source_pc_locker.dir = EAST
	source_pc_locker.owner = "Mapper Platoon Commander Locker"
	source_pc_locker.x_to_linked_spawn_turf = linked_turf.x - source_pc_locker.x
	source_pc_locker.y_to_linked_spawn_turf = linked_turf.y - source_pc_locker.y
	source_pc_locker.linked_spawn_turf = linked_turf
	TEST_ASSERT(count_personal_locker_contents_by_exact_type(source_pc_locker, /obj/item/device/radio/headset/almayer/marine/solardevils/pltco/unsc) >= 1, "UNSC platoon commander locker baseline headset was missing before ship surface replacement test.")

	var/obj/structure/closet/secure_closet/marine_personal/target_pc_locker = role_authority.replace_ship_surface_fixture(
		source_pc_locker,
		"odst",
		role_authority.get_ship_surface_related_squad_markers(/datum/squad/marine/halo/odst/alpha)
	)
	track_test_atom(target_pc_locker)

	TEST_ASSERT_NOTNULL(target_pc_locker, "Platoon commander locker ship surface replacement did not produce a target locker.")
	TEST_ASSERT_EQUAL(target_pc_locker.type, /obj/structure/closet/secure_closet/marine_personal/odst/platoon_commander, "UNSC platoon commander locker did not swap into the ODST platoon commander locker.")
	TEST_ASSERT_EQUAL(target_pc_locker.pixel_x, 7, "Platoon commander locker ship surface replacement did not preserve pixel_x.")
	TEST_ASSERT_EQUAL(target_pc_locker.pixel_y, -3, "Platoon commander locker ship surface replacement did not preserve pixel_y.")
	TEST_ASSERT_EQUAL(target_pc_locker.dir, EAST, "Platoon commander locker ship surface replacement did not preserve direction.")
	TEST_ASSERT_EQUAL(target_pc_locker.owner, "Mapper Platoon Commander Locker", "Platoon commander locker ship surface replacement did not preserve locker owner metadata.")
	TEST_ASSERT_EQUAL(target_pc_locker.linked_spawn_turf, linked_turf, "Platoon commander locker ship surface replacement did not preserve linked spawn turf.")
	TEST_ASSERT_EQUAL(count_personal_locker_contents_by_exact_type(target_pc_locker, /obj/item/device/radio/headset/almayer/marine/solardevils/pltco/unsc), 0, "Platoon commander locker ship surface replacement incorrectly carried over the exact UNSC command headset into the ODST locker.")
	TEST_ASSERT(count_personal_locker_contents_by_exact_type(target_pc_locker, /obj/item/device/radio/headset/almayer/marine/solardevils/pltco/odst) >= 1, "Platoon commander locker ship surface replacement did not keep the ODST command headset.")

	var/obj/structure/closet/secure_closet/marine_personal/platoon_commander/base_pc_locker = allocate(/obj/structure/closet/secure_closet/marine_personal/platoon_commander, mainship_turf)
	var/list/surface_key = role_authority.get_ship_surface_key(base_pc_locker)
	TEST_ASSERT(islist(surface_key), "Base platoon commander locker did not produce a ship surface key.")
	TEST_ASSERT_EQUAL(surface_key["kind"], "locker", "Base platoon commander locker did not register as a locker ship surface fixture.")
	TEST_ASSERT_EQUAL(surface_key["role"], JOB_SO, "Base platoon commander locker did not normalize to the canonical SO role.")

	var/obj/structure/closet/secure_closet/marine_personal/target_base_pc_locker = role_authority.replace_ship_surface_fixture(
		base_pc_locker,
		"unsc",
		role_authority.get_ship_surface_related_squad_markers(/datum/squad/marine/halo/unsc/alpha)
	)
	track_test_atom(target_base_pc_locker)

	TEST_ASSERT_NOTNULL(target_base_pc_locker, "Base platoon commander locker ship surface replacement did not produce a target locker.")
	TEST_ASSERT_EQUAL(target_base_pc_locker.type, /obj/structure/closet/secure_closet/marine_personal/unsc/platoon_commander, "Base platoon commander locker did not swap into the UNSC platoon commander locker.")
	TEST_ASSERT(count_personal_locker_contents_by_exact_type(target_base_pc_locker, /obj/item/device/radio/headset/almayer/marine/solardevils/pltco/unsc) >= 1, "Base platoon commander locker replacement did not yield the UNSC command headset.")

	var/obj/structure/machinery/cm_vending/sorted/marine_food/unsc/alt/source_vendor = allocate(/obj/structure/machinery/cm_vending/sorted/marine_food/unsc/alt, mainship_turf)
	source_vendor.pixel_x = -10
	source_vendor.pixel_y = 4
	source_vendor.dir = SOUTH
	source_vendor.density = FALSE
	source_vendor.listed_products = list(list("BOGUS", 1, /obj/item/device/flashlight, VENDOR_ITEM_REGULAR))
	var/obj/item/device/flashlight/vendor_mapper_item = allocate(/obj/item/device/flashlight, source_vendor)
	TEST_ASSERT(vendor_mapper_item in source_vendor.contents, "Failed to seed mapper-added content into the source vendor before replacement.")

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
	TEST_ASSERT(vendor_mapper_item in target_vendor.contents, "Vendor ship surface replacement lost mapper-added contents.")
	TEST_ASSERT(length(target_vendor.listed_products) == 0 || target_vendor.listed_products[1][1] != "BOGUS", "Vendor ship surface replacement incorrectly copied source listed_products into the new vendor.")

/datum/unit_test/halo_ship_platoons_ship_surface_fixture_collection_contracts
	parent_type = /datum/unit_test/halo_integration_test

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
	parent_type = /datum/unit_test/halo_integration_test

/datum/unit_test/halo_ship_platoons_sync_pending_same_ship_platoon_for_round_start/Run()
	configure_test_ship_platoon(/datum/squad/marine/halo/unsc/alpha)

	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	TEST_ASSERT_NOTNULL(role_authority, "RoleAuthority was unavailable for pending same-ship platoon sync testing.")

	var/datum/map_config/current_ship_config = SSmapping?.configs?[SHIP_MAP]
	TEST_ASSERT_NOTNULL(current_ship_config, "Failed to resolve the current ship config for pending same-ship platoon sync testing.")

	var/datum/map_config/pending_ship_config = load_map_config("maps/unsc_stalwart_frigate.json", maptype = SHIP_MAP)
	TEST_ASSERT_NOTNULL(pending_ship_config, "Failed to load the HALO ship config for pending same-ship platoon sync testing.")
	current_ship_config.map_name = pending_ship_config.map_name
	current_ship_config.map_path = pending_ship_config.map_path
	pending_ship_config.platoon = "/datum/squad/marine/halo/odst/alpha"
	SSmapping.next_map_configs = list(SHIP_MAP = pending_ship_config)

	TEST_ASSERT(role_authority.sync_pending_same_ship_platoon_for_round_start(), "Pending same-ship platoon sync did not accept the queued ODST override for the loaded Stalwart Frigate.")
	TEST_ASSERT_EQUAL(current_ship_config.platoon, "/datum/squad/marine/halo/odst/alpha", "Pending same-ship platoon sync did not update the current ship config to the queued ODST profile.")
