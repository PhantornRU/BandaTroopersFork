/datum/unit_test/halo_ship_platoons_role_classification
	parent_type = /datum/unit_test/halo_contract_test

/datum/unit_test/halo_ship_platoons_role_classification/Run()
	assert_halo_role_contract(JOB_SQUAD_MARINE_UNSC, /datum/job/marine/standard/ai/halo/unsc, JOB_SQUAD_MARINE, /datum/equipment_preset/unsc/pfc/equipped)
	assert_halo_title_mapping(JOB_SQUAD_MARINE_UNSC, JOB_SQUAD_MARINE)

	assert_halo_role_contract(JOB_SQUAD_MARINE_ODST, /datum/job/marine/standard/ai/halo/odst, JOB_SQUAD_MARINE, /datum/equipment_preset/unsc/pfc/odst/equipped)
	assert_halo_title_mapping(JOB_SQUAD_MARINE_ODST, JOB_SQUAD_MARINE)

	assert_halo_role_contract(JOB_SO_UNSC, /datum/job/command/bridge/ai/halo/unsc, JOB_SO, /datum/equipment_preset/unsc/platco/equipped)
	assert_halo_title_mapping(JOB_SO_UNSC, JOB_SO)

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
