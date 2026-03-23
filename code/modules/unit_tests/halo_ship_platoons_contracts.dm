/datum/unit_test/halo_ship_platoons_role_classification
	parent_type = /datum/unit_test/halo_contract_test

/datum/unit_test/halo_ship_platoons_role_classification/Run()
	assert_halo_role_job_type(JOB_SQUAD_MARINE_UNSC, /datum/job/marine/standard/ai/halo/unsc)
	assert_halo_role_job_type(JOB_SQUAD_MARINE_ODST, /datum/job/marine/standard/ai/halo/odst)
	assert_halo_role_job_type(JOB_SO_UNSC, /datum/job/command/bridge/ai/halo/unsc)

/datum/unit_test/halo_ship_platoons_bucket_mapping
	parent_type = /datum/unit_test/halo_contract_test

/datum/unit_test/halo_ship_platoons_bucket_mapping/Run()
	assert_halo_bucket_mapping(JOB_SQUAD_MARINE_UNSC, JOB_SQUAD_MARINE)
	assert_halo_bucket_mapping(JOB_SQUAD_MARINE_ODST, JOB_SQUAD_MARINE)
	assert_halo_bucket_mapping(JOB_SO_UNSC, JOB_SO)

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

/datum/unit_test/halo_ship_platoons_no_legacy_runtime_paths
	parent_type = /datum/unit_test/halo_contract_test

/datum/unit_test/halo_ship_platoons_no_legacy_runtime_paths/Run()
	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	TEST_ASSERT_NOTNULL(role_authority, "RoleAuthority was unavailable for HALO runtime-path contract testing.")

	var/list/odst_family_types = role_authority.get_halo_job_family_types(JOB_SQUAD_MARINE_ODST)
	TEST_ASSERT(islist(odst_family_types) && length(odst_family_types) == 4, "HALO ODST runtime family should stay on the four-squad family profile.")
	TEST_ASSERT(odst_family_types.Find(/datum/squad/marine/halo/odst/alpha), "HALO ODST runtime family lost Alpha.")
	TEST_ASSERT(odst_family_types.Find(/datum/squad/marine/halo/odst/bravo), "HALO ODST runtime family lost Bravo.")
	TEST_ASSERT(odst_family_types.Find(/datum/squad/marine/halo/odst/charlie), "HALO ODST runtime family lost Charlie.")
	TEST_ASSERT(odst_family_types.Find(/datum/squad/marine/halo/odst/delta), "HALO ODST runtime family lost Delta.")
	TEST_ASSERT(!odst_family_types.Find(/datum/squad/marine/alpha), "HALO ODST runtime family regressed to legacy non-HALO squad paths.")

	TEST_ASSERT_EQUAL(role_authority.get_ship_surface_family(/datum/squad/marine/halo/unsc/alpha), "unsc", "UNSC platoon did not resolve to the UNSC ship surface family.")
	TEST_ASSERT_EQUAL(role_authority.get_ship_surface_family(/datum/squad/marine/halo/odst/alpha), "odst", "ODST platoon did not resolve to the ODST ship surface family.")

	var/list/halo_markers = role_authority.get_ship_surface_related_squad_markers(/datum/squad/marine/halo/unsc/alpha)
	TEST_ASSERT_EQUAL(length(halo_markers), 4, "HALO ship surface coverage did not include all related Alpha/Bravo/Charlie/Delta squads.")
	TEST_ASSERT(halo_markers.Find(SQUAD_MARINE_1), "HALO ship surface coverage missed Alpha.")
	TEST_ASSERT(halo_markers.Find(SQUAD_MARINE_2), "HALO ship surface coverage missed Bravo.")
	TEST_ASSERT(halo_markers.Find(SQUAD_MARINE_3), "HALO ship surface coverage missed Charlie.")
	TEST_ASSERT(halo_markers.Find(SQUAD_MARINE_4), "HALO ship surface coverage missed Delta.")

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
