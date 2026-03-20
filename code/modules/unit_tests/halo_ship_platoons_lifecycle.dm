/datum/unit_test/halo_ship_platoons_so_lifecycle_hooks
	parent_type = /datum/unit_test/halo_integration_test

/datum/unit_test/halo_ship_platoons_so_lifecycle_hooks/Run()
	configure_test_ship_platoon(/datum/squad/marine/halo/unsc/alpha)
	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	TEST_ASSERT_NOTNULL(role_authority, "RoleAuthority was unavailable for HALO SO lifecycle testing.")
	role_authority.squads_by_type[/datum/squad/marine/alpha] = role_authority.squads_by_type[/datum/squad/marine/halo/unsc/alpha]
	role_authority.squads_by_type[/datum/squad/marine/bravo] = role_authority.squads_by_type[/datum/squad/marine/halo/unsc/bravo]
	role_authority.squads_by_type[/datum/squad/marine/charlie] = role_authority.squads_by_type[/datum/squad/marine/halo/unsc/charlie]
	role_authority.squads_by_type[/datum/squad/marine/delta] = role_authority.squads_by_type[/datum/squad/marine/halo/unsc/delta]

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

	var/mob/living/carbon/human/halo_so = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	configure_test_human(halo_so, "HALO Platoon Commander", JOB_SO_UNSC, null, "halo_so_lifecycle")
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

	var/mob/living/carbon/human/halo_so = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	configure_test_human(halo_so, "HALO Platoon Commander Pref", JOB_SO_UNSC, null, "halo_so_pref")
	halo_so.job = so_job

	TEST_ASSERT(manager.claim_first_platoon_commander(halo_so), "Platoon Commander preference claim should accept HALO job datums without bad-indexing the default-role map.")
