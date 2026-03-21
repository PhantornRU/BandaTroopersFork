/datum/unit_test/halo_ship_platoons_role_classification
	parent_type = /datum/unit_test/halo_contract_test

/datum/unit_test/halo_ship_platoons_role_classification/Run()
	assert_halo_role_contract(JOB_SQUAD_MARINE_UNSC, /datum/job/marine/standard/ai/halo/unsc, JOB_SQUAD_MARINE, /datum/equipment_preset/unsc/pfc/equipped)
	assert_halo_title_mapping(JOB_SQUAD_MARINE_UNSC, JOB_SQUAD_MARINE)

	assert_halo_role_contract(JOB_SQUAD_MARINE_ODST, /datum/job/marine/standard/ai/halo/odst, JOB_SQUAD_MARINE, /datum/equipment_preset/unsc/pfc/odst/equipped)
	assert_halo_title_mapping(JOB_SQUAD_MARINE_ODST, JOB_SQUAD_MARINE)

	assert_halo_role_contract(JOB_SO_UNSC, /datum/job/command/bridge/ai/halo/unsc, JOB_SO, /datum/equipment_preset/unsc/platco/equipped)
	assert_halo_title_mapping(JOB_SO_UNSC, JOB_SO)

/datum/unit_test/halo_ship_platoons_spawn_preset_resolution
	parent_type = /datum/unit_test/halo_contract_test

/datum/unit_test/halo_ship_platoons_spawn_preset_resolution/Run()
	assert_halo_spawn_preset_resolution(JOB_SQUAD_MARINE_UNSC, /datum/equipment_preset/unsc/pfc)
	assert_halo_spawn_preset_resolution(JOB_SQUAD_MEDIC_UNSC, /datum/equipment_preset/unsc/medic)
	assert_halo_spawn_preset_resolution(JOB_SQUAD_MARINE_ODST, /datum/equipment_preset/unsc/pfc/odst)
	assert_halo_spawn_preset_resolution(JOB_SQUAD_MEDIC_ODST, /datum/equipment_preset/unsc/medic/odst)

/datum/unit_test/halo_ship_platoons_so_preset_override_contract
	parent_type = /datum/unit_test/halo_contract_test

/datum/unit_test/halo_ship_platoons_so_preset_override_contract/Run()
	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	TEST_ASSERT_NOTNULL(role_authority, "RoleAuthority was unavailable for HALO SO preset override testing.")

	TEST_ASSERT_EQUAL(role_authority.get_active_ship_spawn_preset_override(JOB_SO, /datum/equipment_preset/uscm_ship/so, /datum/squad/marine/halo/unsc/alpha), /datum/equipment_preset/unsc/platco, "HALO UNSC SO override did not resolve to the expected preset.")
	TEST_ASSERT_EQUAL(role_authority.get_active_ship_spawn_preset_override(JOB_SO, /datum/equipment_preset/uscm_ship/so, /datum/squad/marine/halo/odst/alpha), /datum/equipment_preset/unsc/platco/odst, "HALO ODST SO override did not resolve to the expected preset.")

/datum/unit_test/halo_ship_platoons_cryo_profile_resolution
	parent_type = /datum/unit_test/halo_contract_test

/datum/unit_test/halo_ship_platoons_cryo_profile_resolution/Run()
	assert_halo_cryo_profile_resolution(JOB_SO, /datum/squad/marine/halo/unsc/alpha, JOB_SO_UNSC, /datum/equipment_preset/unsc/platco)
	assert_halo_cryo_profile_resolution(JOB_SQUAD_MEDIC, /datum/squad/marine/halo/unsc/alpha, JOB_SQUAD_MEDIC_UNSC, /datum/equipment_preset/unsc/medic)
	assert_halo_cryo_profile_resolution(JOB_SO, /datum/squad/marine/halo/odst/alpha, JOB_SO_ODST, /datum/equipment_preset/unsc/platco/odst)
	assert_halo_cryo_profile_resolution(JOB_SQUAD_MEDIC, /datum/squad/marine/halo/odst/alpha, JOB_SQUAD_MEDIC_ODST, /datum/equipment_preset/unsc/medic/odst)

/datum/unit_test/halo_ship_platoons_modular_spawn_opt_contracts
	parent_type = /datum/unit_test/halo_contract_test

/datum/unit_test/halo_ship_platoons_modular_spawn_opt_contracts/Run()
	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	TEST_ASSERT_NOTNULL(role_authority, "RoleAuthority was unavailable for HALO modular spawn opt testing.")

	var/datum/job/so_job = role_authority.roles_by_name[JOB_SO_UNSC]
	TEST_ASSERT_NOTNULL(so_job, "Failed to resolve JOB_SO_UNSC for modular spawn opt testing.")
	TEST_ASSERT(so_job.uses_modular_job_landmark_spawn(), "HALO SO should remain opted into modular job-landmark spawn resolution.")

	var/datum/job/pilot_job = role_authority.roles_by_name[JOB_DROPSHIP_PILOT]
	TEST_ASSERT_NOTNULL(pilot_job, "Failed to resolve JOB_DROPSHIP_PILOT for modular spawn opt testing.")
	TEST_ASSERT(!pilot_job.uses_modular_job_landmark_spawn(), "Non-SO regression test picked a job that is now unexpectedly opted into modular non-squad spawn resolution.")

/datum/unit_test/halo_ship_platoons_ship_surface_contracts
	parent_type = /datum/unit_test/halo_contract_test

/datum/unit_test/halo_ship_platoons_ship_surface_contracts/Run()
	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	TEST_ASSERT_NOTNULL(role_authority, "RoleAuthority was unavailable for ship surface contract testing.")

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

	var/obj/structure/machinery/cm_vending/sorted/marine_food/unsc/alt/food_vendor = allocate(/obj/structure/machinery/cm_vending/sorted/marine_food/unsc/alt)
	TEST_ASSERT_EQUAL(role_authority.get_ship_surface_target_type(role_authority.get_ship_surface_key(food_vendor), "uscm"), /obj/structure/machinery/cm_vending/sorted/marine_food, "UNSC alternate food vendor did not map back to the USCM food vendor.")

/datum/unit_test/halo_ship_platoons_specialist_job_locker_allowlist
	parent_type = /datum/unit_test/halo_contract_test

/datum/unit_test/halo_ship_platoons_specialist_job_locker_allowlist/Run()
	var/obj/structure/closet/secure_closet/halo/job_locker/weapons_spec/locker = allocate(/obj/structure/closet/secure_closet/halo/job_locker/weapons_spec)
	var/list/allowed_specialist_jobs = locker.get_allowed_specialist_jobs()

	TEST_ASSERT(allowed_specialist_jobs.Find(JOB_SQUAD_SPECIALIST), "Specialist job locker allowlist lost the canonical specialist title.")
	TEST_ASSERT(allowed_specialist_jobs.Find(JOB_SQUAD_SPECIALIST_UNSC), "Specialist job locker allowlist lost the HALO UNSC specialist title.")
	TEST_ASSERT(allowed_specialist_jobs.Find(JOB_SQUAD_SPECIALIST_ODST), "Specialist job locker allowlist lost the HALO ODST specialist title.")

/datum/unit_test/halo_ship_platoons_unsc_medic_option_resolution
	parent_type = /datum/unit_test/halo_contract_test

/datum/unit_test/halo_ship_platoons_unsc_medic_option_resolution/Run()
	assert_halo_medic_option_resolution(/datum/job/marine/medic/ai/halo/unsc, "Corporal", JOB_SQUAD_MEDIC_UNSC, /datum/squad/marine/halo/unsc/alpha, /datum/equipment_preset/unsc/medic)
	assert_halo_medic_option_resolution(/datum/job/marine/medic/ai/halo/unsc, "Private", JOB_SQUAD_MEDIC_UNSC, /datum/squad/marine/halo/unsc/alpha, /datum/equipment_preset/unsc/medic/private)

/datum/unit_test/halo_ship_platoons_odst_medic_option_resolution
	parent_type = /datum/unit_test/halo_contract_test

/datum/unit_test/halo_ship_platoons_odst_medic_option_resolution/Run()
	assert_halo_medic_option_resolution(/datum/job/marine/medic/ai/halo/odst, "Corporal", JOB_SQUAD_MEDIC_ODST, /datum/squad/marine/halo/odst/alpha, /datum/equipment_preset/unsc/medic/odst)
	assert_halo_medic_option_resolution(/datum/job/marine/medic/ai/halo/odst, "Private", JOB_SQUAD_MEDIC_ODST, /datum/squad/marine/halo/odst/alpha, /datum/equipment_preset/unsc/medic/odst/private)
