/datum/unit_test/halo_ship_platoons_unsc_equip_smoke
	parent_type = /datum/unit_test/halo_equip_test

/datum/unit_test/halo_ship_platoons_unsc_equip_smoke/Run()
	var/mob/living/carbon/human/human = create_test_human("HALO UNSC Corpsman Smoke", JOB_SQUAD_MEDIC_UNSC)
	arm_equipment(human, /datum/equipment_preset/unsc/medic, FALSE, TRUE)

	assert_halo_smoke_state(human, /datum/equipment_preset/unsc/medic, JOB_SQUAD_MEDIC_UNSC)

/datum/unit_test/halo_ship_platoons_odst_equip_smoke
	parent_type = /datum/unit_test/halo_equip_test

/datum/unit_test/halo_ship_platoons_odst_equip_smoke/Run()
	var/mob/living/carbon/human/human = create_test_human("HALO ODST Rifleman Smoke", JOB_SQUAD_MARINE_ODST)
	arm_equipment(human, /datum/equipment_preset/unsc/pfc/odst, FALSE, TRUE)

	assert_halo_smoke_state(human, /datum/equipment_preset/unsc/pfc/odst, JOB_SQUAD_MARINE_ODST)

/datum/unit_test/halo_ship_platoons_so_override_smoke
	parent_type = /datum/unit_test/halo_equip_test

/datum/unit_test/halo_ship_platoons_so_override_smoke/Run()
	var/override_preset = GLOB.RoleAuthority?.get_active_ship_spawn_preset_override(JOB_SO, /datum/equipment_preset/uscm_ship/so, /datum/squad/marine/halo/unsc/alpha)
	TEST_ASSERT_EQUAL(override_preset, /datum/equipment_preset/unsc/platco, "HALO UNSC SO smoke did not resolve the expected override preset.")

	var/mob/living/carbon/human/human = create_test_human("HALO UNSC Platoon Commander Smoke", JOB_SO_UNSC)
	arm_equipment(human, override_preset, FALSE, TRUE)

	assert_halo_smoke_state(human, /datum/equipment_preset/unsc/platco, JOB_SO_UNSC)

/datum/unit_test/halo_ship_platoons_specialist_smoke
	parent_type = /datum/unit_test/halo_equip_test

/datum/unit_test/halo_ship_platoons_specialist_smoke/Run()
	var/mob/living/carbon/human/human = create_test_human("HALO UNSC Specialist Smoke", JOB_SQUAD_SPECIALIST_UNSC)
	arm_equipment(human, /datum/equipment_preset/unsc/spec, FALSE, TRUE)

	assert_halo_smoke_state(human, /datum/equipment_preset/unsc/spec, JOB_SQUAD_SPECIALIST_UNSC)
	assert_halo_specialist_naked_baseline(human)
