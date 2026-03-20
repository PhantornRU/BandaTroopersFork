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

/datum/unit_test/halo_ship_platoons_no_legacy_runtime
	parent_type = /datum/unit_test/halo_contract_test

/datum/unit_test/halo_ship_platoons_no_legacy_runtime/Run()
	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	TEST_ASSERT_NOTNULL(role_authority, "RoleAuthority was unavailable for HALO no-legacy runtime test.")

	var/list/known_ship_platoons = role_authority.get_known_ship_platoon_types()
	TEST_ASSERT(known_ship_platoons.Find(/datum/squad/marine/halo/odst/alpha), "HALO ODST platoon is missing from the active ship platoon registry.")
	for(var/platoon_type in known_ship_platoons)
		var/platoon_path_text = "[platoon_type]"
		if(findtext(platoon_path_text, "/datum/squad/marine/") && findtext(platoon_path_text, "/odst") && !findtext(platoon_path_text, "/halo/odst"))
			TEST_FAIL("Legacy ODST squad path leaked into the active ship platoon registry: [platoon_path_text]")

	for(var/squad_type in role_authority.squads_by_type)
		var/squad_path_text = "[squad_type]"
		if(findtext(squad_path_text, "/datum/squad/marine/") && findtext(squad_path_text, "/odst") && !findtext(squad_path_text, "/halo/odst"))
			TEST_FAIL("Legacy ODST squad path remained loadable after cleanup: [squad_path_text]")

	for(var/role_path in role_authority.roles_by_path)
		var/role_path_text = "[role_path]"
		if(findtext(role_path_text, "/datum/job/marine/") && findtext(role_path_text, "/odst") && !findtext(role_path_text, "/halo/odst"))
			TEST_FAIL("Legacy ODST marine role path remained loadable after cleanup: [role_path_text]")

	var/list/conflict_types = role_authority.get_main_ship_conflicting_family_types()
	for(var/conflict_type in conflict_types)
		var/conflict_path_text = "[conflict_type]"
		if(findtext(conflict_path_text, "/datum/squad/marine/") && findtext(conflict_path_text, "/odst") && !findtext(conflict_path_text, "/halo/odst"))
			TEST_FAIL("Legacy ODST squad still participates in active main-ship conflict filtering: [conflict_path_text]")

	var/list/halo_odst_profile = role_authority.get_ship_platoon_profile(/datum/squad/marine/halo/odst/alpha)
	var/list/halo_odst_role_mappings = halo_odst_profile["role_mappings"]
	TEST_ASSERT_EQUAL(halo_odst_role_mappings[/datum/job/marine/standard/ai/halo/odst], JOB_SQUAD_MARINE, "HALO ODST profile did not point at the namespaced rifleman job path.")
	TEST_ASSERT_EQUAL(length(halo_odst_role_mappings), 7, "HALO ODST profile should expose the seven namespaced ODST ship-role mappings, including the platoon commander.")
	for(var/role_path in halo_odst_role_mappings)
		var/role_path_text = "[role_path]"
		if(!findtext(role_path_text, "/halo/odst"))
			TEST_FAIL("HALO ODST profile contained a non-namespaced role path: [role_path_text]")

/datum/unit_test/halo_ship_platoons_so_preset_override
	parent_type = /datum/unit_test/halo_contract_test

/datum/unit_test/halo_ship_platoons_so_preset_override/Run()
	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	TEST_ASSERT_NOTNULL(role_authority, "RoleAuthority was unavailable for HALO SO preset override test.")
	var/datum/job/so_job = role_authority.roles_by_name[JOB_SO]
	var/datum/job/unsc_so_job = role_authority.roles_by_name[JOB_SO_UNSC]
	var/datum/job/odst_so_job = role_authority.roles_by_name[JOB_SO_ODST]
	TEST_ASSERT_NOTNULL(so_job, "SO job was unavailable for HALO preset-resolution helper test.")
	TEST_ASSERT_NOTNULL(unsc_so_job, "UNSC HALO Platoon Commander job was unavailable for HALO preset-resolution helper test.")
	TEST_ASSERT_NOTNULL(odst_so_job, "ODST HALO Platoon Commander job was unavailable for HALO preset-resolution helper test.")
	TEST_ASSERT_EQUAL(so_job.get_spawn_equip_preset(JOB_SO, role_authority, /datum/squad/marine/halo/unsc/alpha), /datum/equipment_preset/unsc/platco, "HALO UNSC SO job helper did not reuse the shared preset-resolution contract.")
	TEST_ASSERT_EQUAL(so_job.get_spawn_equip_preset(JOB_SO, role_authority, /datum/squad/marine/halo/odst/alpha), /datum/equipment_preset/unsc/platco/odst, "HALO ODST SO job helper did not reuse the shared preset-resolution contract.")
	TEST_ASSERT_EQUAL(unsc_so_job.get_spawn_equip_preset(JOB_SO_UNSC, role_authority, /datum/squad/marine/halo/unsc/alpha), /datum/equipment_preset/unsc/platco, "Explicit HALO UNSC Platoon Commander job did not keep its own HALO preset.")
	TEST_ASSERT_EQUAL(odst_so_job.get_spawn_equip_preset(JOB_SO_ODST, role_authority, /datum/squad/marine/halo/odst/alpha), /datum/equipment_preset/unsc/platco/odst, "Explicit HALO ODST Platoon Commander job did not keep its own HALO preset.")
	TEST_ASSERT_EQUAL(role_authority.get_active_ship_spawn_preset_override(JOB_SO, /datum/equipment_preset/uscm_ship/so, /datum/squad/marine/halo/unsc/alpha), /datum/equipment_preset/unsc/platco, "HALO UNSC SO override did not resolve to the UNSC Platoon Commander preset.")
	TEST_ASSERT_EQUAL(role_authority.get_active_ship_spawn_preset_override(JOB_SO, /datum/equipment_preset/uscm_ship/so/lesser_rank, /datum/squad/marine/halo/unsc/alpha), /datum/equipment_preset/unsc/platco/lesser_rank, "HALO UNSC lesser-rank SO override did not resolve to the UNSC lesser-rank Platoon Commander preset.")
	TEST_ASSERT_EQUAL(role_authority.get_active_ship_spawn_preset_override(JOB_SO, /datum/equipment_preset/uscm_ship/so, /datum/squad/marine/halo/odst/alpha), /datum/equipment_preset/unsc/platco/odst, "HALO ODST SO override did not resolve to the ODST Platoon Commander preset.")
	TEST_ASSERT_EQUAL(role_authority.get_active_ship_spawn_preset_override(JOB_SO, /datum/equipment_preset/uscm_ship/so/lesser_rank, /datum/squad/marine/halo/odst/alpha), /datum/equipment_preset/unsc/platco/odst/lesser_rank, "HALO ODST lesser-rank SO override did not resolve to the ODST lesser-rank Platoon Commander preset.")
	TEST_ASSERT_NULL(role_authority.get_active_ship_spawn_preset_override(JOB_SO, /datum/equipment_preset/uscm_ship/so, /datum/squad/marine/alpha), "Vanilla USCM SO preset should not be overridden outside ship profiles that define an override.")
	TEST_ASSERT_NULL(role_authority.get_active_ship_cryo_reinforcement_preset(JOB_SQUAD_MEDIC, /datum/squad/marine/alpha), "Vanilla USCM cryo roles should not receive profile-specific reinforcement presets.")
	TEST_ASSERT_NULL(role_authority.get_active_ship_cryo_reinforcement_title(JOB_SQUAD_MEDIC, /datum/squad/marine/alpha), "Vanilla USCM cryo roles should not receive profile-specific reinforcement titles.")
