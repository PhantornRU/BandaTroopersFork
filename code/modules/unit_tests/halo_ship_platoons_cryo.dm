/datum/unit_test/halo_ship_platoons_unsc_cryo_preset_mapping
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_unsc_cryo_preset_mapping/Run()
	configure_test_ship_platoon(/datum/squad/marine/halo/unsc/alpha)

	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	TEST_ASSERT_NOTNULL(role_authority, "RoleAuthority was unavailable for HALO UNSC cryo mapping test.")

	var/list/expected_presets = list(
		JOB_SQUAD_MARINE = /datum/equipment_preset/unsc/pfc,
		JOB_SQUAD_MEDIC = /datum/equipment_preset/unsc/medic,
		JOB_SQUAD_RTO = /datum/equipment_preset/unsc/rto,
		JOB_SQUAD_TEAM_LEADER = /datum/equipment_preset/unsc/tl,
		JOB_SQUAD_LEADER = /datum/equipment_preset/unsc/leader,
		JOB_SQUAD_SPECIALIST = /datum/equipment_preset/unsc/spec,
	)
	var/list/expected_titles = list(
		JOB_SQUAD_MARINE = JOB_SQUAD_MARINE_UNSC,
		JOB_SQUAD_MEDIC = JOB_SQUAD_MEDIC_UNSC,
		JOB_SQUAD_RTO = JOB_SQUAD_RTO_UNSC,
		JOB_SQUAD_TEAM_LEADER = JOB_SQUAD_TEAM_LEADER_UNSC,
		JOB_SQUAD_LEADER = JOB_SQUAD_LEADER_UNSC,
		JOB_SQUAD_SPECIALIST = JOB_SQUAD_SPECIALIST_UNSC,
	)
	for(var/role_title in expected_titles)
		TEST_ASSERT_EQUAL(role_authority.get_active_ship_cryo_reinforcement_title(role_title, /datum/squad/marine/halo/unsc/alpha), expected_titles[role_title], "HALO UNSC cryo role-title mapping regressed for [role_title].")
	for(var/role_title in expected_presets)
		TEST_ASSERT_EQUAL(role_authority.get_active_ship_cryo_reinforcement_preset(role_title, /datum/squad/marine/halo/unsc/alpha), expected_presets[role_title], "HALO UNSC cryo preset mapping regressed for [role_title].")

	assert_halo_randomize_assigns_squad("HALO UNSC Cryo Medic", JOB_SQUAD_MEDIC_UNSC, /datum/equipment_preset/unsc/medic, /datum/squad/marine/halo/unsc/alpha)
	assert_halo_randomize_assigns_squad("HALO UNSC Cryo Leader", JOB_SQUAD_LEADER_UNSC, /datum/equipment_preset/unsc/leader, /datum/squad/marine/halo/unsc/alpha)
	assert_halo_randomize_assigns_squad("HALO UNSC Cryo Specialist", JOB_SQUAD_SPECIALIST_UNSC, /datum/equipment_preset/unsc/spec, /datum/squad/marine/halo/unsc/alpha)

/datum/unit_test/halo_ship_platoons_cryo_helper_contracts
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_cryo_helper_contracts/Run()
	configure_test_ship_platoon(/datum/squad/marine/halo/unsc/alpha)

	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	TEST_ASSERT_NOTNULL(role_authority, "RoleAuthority was unavailable for HALO cryo helper-contract test.")
	var/datum/emergency_call/cryo_squad/cryo_call = allocate(/datum/emergency_call/cryo_squad)
	TEST_ASSERT_NOTNULL(cryo_call, "Failed to allocate the cryo emergency-call helper for HALO cryo helper-contract testing.")
	TEST_ASSERT(cryo_call.profile_cryo_role_is_supported(JOB_SQUAD_MEDIC, /datum/squad/marine/halo/unsc/alpha), "HALO cryo helper incorrectly treated the supported medic override as unsupported.")
	TEST_ASSERT(!cryo_call.profile_cryo_role_is_supported(JOB_SQUAD_ENGI, /datum/squad/marine/halo/unsc/alpha), "HALO cryo helper incorrectly accepted an unsupported engineer override.")
	TEST_ASSERT(!cryo_call.profile_cryo_role_is_supported(JOB_SQUAD_SMARTGUN, /datum/squad/marine/halo/unsc/alpha), "HALO cryo helper incorrectly accepted an unsupported smartgunner override.")

	var/mob/living/carbon/human/halo_medic = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	configure_test_human(halo_medic, "HALO Cryo Medic", JOB_SQUAD_MEDIC)
	TEST_ASSERT(role_authority.apply_active_ship_cryo_reinforcement(halo_medic, JOB_SQUAD_MEDIC, JOB_SQUAD_MEDIC, null, FALSE, /datum/squad/marine/halo/unsc/alpha), "HALO UNSC cryo application helper failed to apply a supported medic override.")
	TEST_ASSERT_EQUAL(halo_medic.job, JOB_SQUAD_MEDIC_UNSC, "HALO UNSC cryo application helper did not apply the effective profile title.")
	TEST_ASSERT_EQUAL(halo_medic.title, JOB_SQUAD_MEDIC_UNSC, "HALO UNSC cryo application helper did not keep the effective HALO title metadata.")
	TEST_ASSERT_EQUAL(halo_medic.assigned_equipment_preset?.type, /datum/equipment_preset/unsc/medic, "HALO UNSC cryo application helper did not apply the effective HALO medic preset.")
	TEST_ASSERT_NOTNULL(halo_medic.assigned_squad, "HALO UNSC cryo application helper did not randomize the medic into a squad.")
	var/list/unsc_family_types = role_authority.get_halo_job_family_types(JOB_SQUAD_MEDIC_UNSC)
	TEST_ASSERT(unsc_family_types.Find(halo_medic.assigned_squad?.type), "HALO UNSC cryo application helper assigned the medic outside the HALO UNSC squad family.")
	TEST_ASSERT_EQUAL(halo_medic.faction, FACTION_UNSC, "HALO UNSC cryo application helper did not equip the effective profile preset.")
	var/obj/item/card/id/halo_medic_id = halo_medic.get_idcard()
	TEST_ASSERT_EQUAL(halo_medic_id?.faction, FACTION_UNSC, "HALO UNSC cryo application helper did not keep FACTION_UNSC on the medic ID metadata.")

	var/mob/living/carbon/human/unsupported_engineer = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	configure_test_human(unsupported_engineer, "Unsupported HALO Engineer", JOB_SQUAD_ENGI)
	TEST_ASSERT(!role_authority.apply_active_ship_cryo_reinforcement(unsupported_engineer, JOB_SQUAD_ENGI, JOB_SQUAD_ENGI, /datum/equipment_preset/uscm/engineer_equipped, FALSE, /datum/squad/marine/halo/unsc/alpha), "HALO cryo application helper incorrectly accepted an unsupported engineer profile override.")

	var/mob/living/carbon/human/unsupported_smartgunner = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	configure_test_human(unsupported_smartgunner, "Unsupported HALO Smartgunner", JOB_SQUAD_SMARTGUN)
	TEST_ASSERT(!role_authority.apply_active_ship_cryo_reinforcement(unsupported_smartgunner, JOB_SQUAD_SMARTGUN, JOB_SQUAD_SMARTGUN, /datum/equipment_preset/uscm/smartgunner_equipped, FALSE, /datum/squad/marine/halo/unsc/alpha), "HALO cryo application helper incorrectly accepted an unsupported smartgunner profile override.")

/datum/unit_test/halo_ship_platoons_halo_preset_faction_resolution
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_halo_preset_faction_resolution/Run()
	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	TEST_ASSERT_NOTNULL(role_authority, "RoleAuthority was unavailable for HALO preset faction-resolution testing.")

	var/datum/job/unsc_rifleman_job = role_authority.roles_by_name[JOB_SQUAD_MARINE_UNSC]
	var/datum/job/unsc_medic_job = role_authority.roles_by_name[JOB_SQUAD_MEDIC_UNSC]
	var/datum/job/odst_rifleman_job = role_authority.roles_by_name[JOB_SQUAD_MARINE_ODST]
	var/datum/job/odst_medic_job = role_authority.roles_by_name[JOB_SQUAD_MEDIC_ODST]

	TEST_ASSERT_EQUAL(unsc_rifleman_job?.get_spawn_equip_preset(), /datum/equipment_preset/unsc/pfc, "UNSC rifleman no longer resolves through the HALO preset path.")
	TEST_ASSERT_EQUAL(unsc_medic_job?.get_spawn_equip_preset(), /datum/equipment_preset/unsc/medic, "UNSC Corpsman no longer resolves through the HALO preset path.")
	TEST_ASSERT_EQUAL(odst_rifleman_job?.get_spawn_equip_preset(), /datum/equipment_preset/unsc/pfc/odst, "ODST rifleman no longer resolves through the HALO preset path.")
	TEST_ASSERT_EQUAL(odst_medic_job?.get_spawn_equip_preset(), /datum/equipment_preset/unsc/medic/odst, "ODST Corpsman no longer resolves through the HALO preset path.")

	assert_halo_equipment_metadata("UNSC Rifleman", /datum/equipment_preset/unsc/pfc/equipped, JOB_SQUAD_MARINE_UNSC)
	assert_halo_equipment_metadata("UNSC Corpsman", /datum/equipment_preset/unsc/medic/equipped, JOB_SQUAD_MEDIC_UNSC)
	assert_halo_equipment_metadata("ODST Rifleman", /datum/equipment_preset/unsc/pfc/odst/equipped, JOB_SQUAD_MARINE_ODST)
	assert_halo_equipment_metadata("ODST Corpsman", /datum/equipment_preset/unsc/medic/odst/equipped, JOB_SQUAD_MEDIC_ODST)

/datum/unit_test/halo_ship_platoons_cryo_followup_preserves_unsc_context
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_cryo_followup_preserves_unsc_context/Run()
	configure_test_ship_platoon(/datum/squad/marine/halo/unsc/alpha)

	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	configure_test_human(human, "HALO Cryo Followup", JOB_SQUAD_MEDIC_UNSC)
	arm_equipment(human, /datum/equipment_preset/unsc/medic, FALSE, TRUE)
	human.assigned_squad = null

	var/datum/emergency_call/cryo_squad/cryo_call = allocate(/datum/emergency_call/cryo_squad)
	cryo_call.finalize_profile_cryo_reinforcement(human)

	TEST_ASSERT_EQUAL(human.job, JOB_SQUAD_MEDIC_UNSC, "Cryo follow-up handling regressed the HALO corpsman title back to a canonical USCM role.")
	TEST_ASSERT_EQUAL(human.title, JOB_SQUAD_MEDIC_UNSC, "Cryo follow-up handling regressed the HALO corpsman assignment metadata back to a canonical USCM role.")
	TEST_ASSERT_EQUAL(human.faction, FACTION_UNSC, "Cryo follow-up handling regressed the HALO corpsman faction metadata.")
	TEST_ASSERT_EQUAL(human.assigned_equipment_preset?.type, /datum/equipment_preset/unsc/medic, "Cryo follow-up handling regressed the HALO corpsman preset metadata.")
	TEST_ASSERT_NOTNULL(human.assigned_squad, "Cryo follow-up handling did not restore squad assignment for a HALO corpsman.")
	var/list/unsc_family_types = GLOB.RoleAuthority.get_halo_job_family_types(JOB_SQUAD_MEDIC_UNSC)
	TEST_ASSERT(unsc_family_types.Find(human.assigned_squad?.type), "Cryo follow-up handling assigned the HALO corpsman outside the UNSC squad family.")
/datum/unit_test/halo_ship_platoons_title_independence
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_title_independence/Run()
	configure_test_ship_platoon(/datum/squad/marine/halo/unsc/alpha)

	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	TEST_ASSERT_NOTNULL(role_authority, "RoleAuthority was unavailable for HALO title-independence testing.")
	var/datum/emergency_call/cryo_squad/cryo_call = allocate(/datum/emergency_call/cryo_squad)
	TEST_ASSERT_NOTNULL(cryo_call, "HALO title-independence test could not allocate the cryo helper.")

	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	configure_test_human(human, "HALO Title Override Specialist", JOB_SQUAD_SPECIALIST_UNSC)
	arm_equipment(human, /datum/equipment_preset/unsc/spec, FALSE, TRUE)

	var/obj/item/card/id/id = human.get_idcard()
	TEST_ASSERT_NOTNULL(id, "HALO title-independence test did not receive an ID card from the specialist preset.")

	human.title = "Custom HALO Display Title"
	role_authority.randomize_squad(human, TRUE)

	TEST_ASSERT_NOTNULL(human.assigned_squad, "Changing the HALO display title prevented squad assignment.")
	var/list/unsc_family_types = role_authority.get_halo_job_family_types(JOB_SQUAD_SPECIALIST_UNSC)
	TEST_ASSERT(unsc_family_types.Find(human.assigned_squad?.type), "Changing the HALO display title altered profile routing outside the UNSC squad family.")
	TEST_ASSERT_EQUAL(id?.assignment, JOB_SQUAD_SPECIALIST_UNSC, "Changing the HALO display title altered specialist ID assignment metadata.")
	TEST_ASSERT_EQUAL(id?.rank, JOB_SQUAD_SPECIALIST_UNSC, "Changing the HALO display title altered specialist ID rank metadata.")
	TEST_ASSERT_NOTEQUAL(id?.assignment, "[human.assigned_squad?.name] [JOB_SQUAD_SPECIALIST_UNSC]", "HALO specialist ID assignment regressed back to a squad-prefixed display label.")

	if(human.assigned_fireteam == "SQ1")
		TEST_ASSERT(id.access.Find(ACCESS_SQUAD_ONE), "Changing the HALO display title altered SQ1 access routing for the specialist ID.")
	else if(human.assigned_fireteam == "SQ2")
		TEST_ASSERT(id.access.Find(ACCESS_SQUAD_TWO), "Changing the HALO display title altered SQ2 access routing for the specialist ID.")
	else
		TEST_FAIL("HALO title-independence test assigned the specialist to an unexpected fireteam.")

	cleanup_test_squad_membership(human)

	var/mob/living/carbon/human/cryo_human = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	configure_test_human(cryo_human, "HALO Title Override Corpsman", JOB_SQUAD_MEDIC_UNSC)
	arm_equipment(cryo_human, /datum/equipment_preset/unsc/medic, FALSE, TRUE)
	cryo_human.title = "Custom HALO Cryo Display Title"
	cryo_human.assigned_squad = null

	var/obj/item/card/id/cryo_id = cryo_human.get_idcard()
	TEST_ASSERT_NOTNULL(cryo_id, "HALO title-independence cryo subcase did not receive an ID card from the medic preset.")

	cryo_call.finalize_profile_cryo_reinforcement(cryo_human)

	TEST_ASSERT_NOTNULL(cryo_human.assigned_squad, "Changing the HALO display title prevented cryo follow-up squad restoration.")
	TEST_ASSERT(unsc_family_types.Find(cryo_human.assigned_squad?.type), "Changing the HALO display title altered cryo follow-up routing outside the UNSC squad family.")
	TEST_ASSERT_EQUAL(cryo_id?.assignment, JOB_SQUAD_MEDIC_UNSC, "Changing the HALO display title altered cryo medic ID assignment metadata.")
	TEST_ASSERT_EQUAL(cryo_id?.rank, JOB_SQUAD_MEDIC_UNSC, "Changing the HALO display title altered cryo medic ID rank metadata.")

/datum/unit_test/halo_ship_platoons_odst_cryo_preset_mapping
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_odst_cryo_preset_mapping/Run()
	configure_test_ship_platoon(/datum/squad/marine/halo/odst/alpha)

	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	TEST_ASSERT_NOTNULL(role_authority, "RoleAuthority was unavailable for HALO ODST cryo mapping test.")

	var/list/expected_presets = list(
		JOB_SQUAD_MARINE = /datum/equipment_preset/unsc/pfc/odst,
		JOB_SQUAD_MEDIC = /datum/equipment_preset/unsc/medic/odst,
		JOB_SQUAD_RTO = /datum/equipment_preset/unsc/rto/odst,
		JOB_SQUAD_TEAM_LEADER = /datum/equipment_preset/unsc/tl/odst,
		JOB_SQUAD_LEADER = /datum/equipment_preset/unsc/leader/odst,
		JOB_SQUAD_SPECIALIST = /datum/equipment_preset/unsc/spec/odst,
	)
	var/list/expected_titles = list(
		JOB_SQUAD_MARINE = JOB_SQUAD_MARINE_ODST,
		JOB_SQUAD_MEDIC = JOB_SQUAD_MEDIC_ODST,
		JOB_SQUAD_RTO = JOB_SQUAD_RTO_ODST,
		JOB_SQUAD_TEAM_LEADER = JOB_SQUAD_TEAM_LEADER_ODST,
		JOB_SQUAD_LEADER = JOB_SQUAD_LEADER_ODST,
		JOB_SQUAD_SPECIALIST = JOB_SQUAD_SPECIALIST_ODST,
	)
	for(var/role_title in expected_titles)
		TEST_ASSERT_EQUAL(role_authority.get_active_ship_cryo_reinforcement_title(role_title, /datum/squad/marine/halo/odst/alpha), expected_titles[role_title], "HALO ODST cryo role-title mapping regressed for [role_title].")
	for(var/role_title in expected_presets)
		TEST_ASSERT_EQUAL(role_authority.get_active_ship_cryo_reinforcement_preset(role_title, /datum/squad/marine/halo/odst/alpha), expected_presets[role_title], "HALO ODST cryo preset mapping regressed for [role_title].")

	assert_halo_randomize_assigns_squad("HALO ODST Cryo Medic", JOB_SQUAD_MEDIC_ODST, /datum/equipment_preset/unsc/medic/odst, /datum/squad/marine/halo/odst/alpha)
	assert_halo_randomize_assigns_squad("HALO ODST Cryo Leader", JOB_SQUAD_LEADER_ODST, /datum/equipment_preset/unsc/leader/odst, /datum/squad/marine/halo/odst/alpha)
	assert_halo_randomize_assigns_squad("HALO ODST Cryo Specialist", JOB_SQUAD_SPECIALIST_ODST, /datum/equipment_preset/unsc/spec/odst, /datum/squad/marine/halo/odst/alpha)

/datum/unit_test/halo_ship_platoons_assignment_contracts
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_assignment_contracts/Run()
	configure_test_ship_platoon(/datum/squad/marine/halo/unsc/alpha)
	assert_halo_randomize_assigns_squad("HALO UNSC Roundstart Platoon Commander", JOB_SO_UNSC, /datum/equipment_preset/unsc/platco, /datum/squad/marine/halo/unsc/alpha)
	assert_halo_randomize_assigns_squad("HALO UNSC Roundstart Corpsman", JOB_SQUAD_MEDIC_UNSC, /datum/equipment_preset/unsc/medic, /datum/squad/marine/halo/unsc/alpha)
	assert_halo_randomize_assigns_squad("HALO UNSC Roundstart Section Leader", JOB_SQUAD_LEADER_UNSC, /datum/equipment_preset/unsc/leader, /datum/squad/marine/halo/unsc/alpha)
	assert_halo_randomize_assigns_squad("HALO UNSC Roundstart RTO", JOB_SQUAD_RTO_UNSC, /datum/equipment_preset/unsc/rto, /datum/squad/marine/halo/unsc/alpha)
	assert_halo_randomize_assigns_squad("HALO UNSC Roundstart FTL", JOB_SQUAD_TEAM_LEADER_UNSC, /datum/equipment_preset/unsc/tl, /datum/squad/marine/halo/unsc/alpha)
	assert_halo_specialist_assignment_loadout("HALO UNSC Roundstart Specialist", /datum/equipment_preset/unsc/spec, JOB_SQUAD_SPECIALIST_UNSC, /datum/squad/marine/halo/unsc/alpha)

	configure_test_ship_platoon(/datum/squad/marine/halo/odst/alpha)
	assert_halo_randomize_assigns_squad("HALO ODST Roundstart Platoon Commander", JOB_SO_ODST, /datum/equipment_preset/unsc/platco/odst, /datum/squad/marine/halo/odst/alpha)
	assert_halo_randomize_assigns_squad("HALO ODST Roundstart Corpsman", JOB_SQUAD_MEDIC_ODST, /datum/equipment_preset/unsc/medic/odst, /datum/squad/marine/halo/odst/alpha)
	assert_halo_randomize_assigns_squad("HALO ODST Roundstart Section Leader", JOB_SQUAD_LEADER_ODST, /datum/equipment_preset/unsc/leader/odst, /datum/squad/marine/halo/odst/alpha)
	assert_halo_randomize_assigns_squad("HALO ODST Roundstart RTO", JOB_SQUAD_RTO_ODST, /datum/equipment_preset/unsc/rto/odst, /datum/squad/marine/halo/odst/alpha)
	assert_halo_randomize_assigns_squad("HALO ODST Roundstart FTL", JOB_SQUAD_TEAM_LEADER_ODST, /datum/equipment_preset/unsc/tl/odst, /datum/squad/marine/halo/odst/alpha)
	assert_halo_specialist_assignment_loadout("HALO ODST Roundstart Specialist", /datum/equipment_preset/unsc/spec/odst, JOB_SQUAD_SPECIALIST_ODST, /datum/squad/marine/halo/odst/alpha)


/datum/unit_test/halo_ship_platoons_latejoin_resolver_prefers_squad_bucket
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_latejoin_resolver_prefers_squad_bucket/Run()
	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	TEST_ASSERT_NOTNULL(role_authority, "RoleAuthority was unavailable for HALO latejoin resolver regression test.")

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

	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	configure_test_human(human, "HALO Latejoin Resolver", JOB_SQUAD_MEDIC_UNSC, /datum/squad/marine/halo/unsc/alpha)
	TEST_ASSERT_NOTNULL(human.assigned_squad, "Failed to assign a HALO squad for latejoin resolver regression test.")

	var/obj/effect/landmark/late_join/squad_landmark = allocate(/obj/effect/landmark/late_join, squad_turf)
	var/obj/effect/landmark/late_join/job_landmark = allocate(/obj/effect/landmark/late_join, job_turf)
	GLOB.latejoin -= squad_landmark
	GLOB.latejoin -= job_landmark

	squad_landmark.job = job_datum.title
	job_landmark.job = job_datum.title
	GLOB.latejoin_by_squad = list(human.assigned_squad.name = list(squad_landmark))
	GLOB.latejoin_by_job = list(job_datum.title = list(job_landmark))

	var/datum/modular_squad_spawn_resolver/resolver = new(human, job_datum, TRUE)
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

/datum/unit_test/halo_ship_platoons_so_spawn_candidate_contracts
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_so_spawn_candidate_contracts/Run()
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

	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	TEST_ASSERT_NOTNULL(role_authority, "RoleAuthority was unavailable for SO spawn roundstart test.")
	var/datum/job/job_datum = role_authority.roles_by_name[JOB_SO_UNSC]
	TEST_ASSERT_NOTNULL(job_datum, "Failed to resolve JOB_SO_UNSC datum for SO spawn roundstart test.")

	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human, holding_turf)
	tracked_test_humans += human
	var/list/spawn_candidate = human.get_modular_spawn_candidate(job_datum, FALSE)

	TEST_ASSERT_NOTNULL(spawn_candidate, "Modular spawn candidate was null for SO roundstart test.")
	TEST_ASSERT_EQUAL(spawn_candidate["source_tag"], "start_job", "SO spawn candidate source tag was not start_job.")
	TEST_ASSERT_EQUAL(spawn_candidate["tier_tag"], "job", "SO spawn candidate tier tag was not job.")
	TEST_ASSERT_EQUAL(spawn_candidate["no_pod_expected"], FALSE, "SO spawn candidate unexpectedly marked no_pod_expected.")
	TEST_ASSERT(isfloorturf(spawn_candidate["spawn_turf"]), "SO spawn candidate did not resolve to a floor turf.")
	TEST_ASSERT(istype(spawn_candidate["preferred_pod"], /obj/structure/machinery/cryopod), "SO spawn candidate did not resolve to a cryopod.")
	TEST_ASSERT_EQUAL(get_dist(spawn_candidate["spawn_turf"], get_turf(spawn_candidate["preferred_pod"])), 1, "SO spawn candidate did not keep the preferred cryopod cardinally adjacent to its spawn turf.")

/datum/unit_test/halo_ship_platoons_so_modular_spawn_opt_in
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_so_modular_spawn_opt_in/Run()
	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	TEST_ASSERT_NOTNULL(role_authority, "RoleAuthority was unavailable for SO modular-spawn opt-in testing.")
	var/datum/job/job_datum = role_authority.roles_by_name[JOB_SO_UNSC]
	TEST_ASSERT_NOTNULL(job_datum, "Failed to resolve JOB_SO_UNSC datum for SO modular-spawn opt-in testing.")
	TEST_ASSERT(job_datum.uses_modular_job_landmark_spawn(), "HALO SO should remain opted into modular job-landmark spawn resolution.")

/datum/unit_test/halo_ship_platoons_non_so_modular_spawn_opt_out
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_non_so_modular_spawn_opt_out/Run()
	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	TEST_ASSERT_NOTNULL(role_authority, "RoleAuthority was unavailable for non-SO modular-spawn opt-out testing.")
	var/datum/job/job_datum = role_authority.roles_by_name[JOB_DROPSHIP_PILOT]
	TEST_ASSERT_NOTNULL(job_datum, "Failed to resolve JOB_DROPSHIP_PILOT datum for non-SO modular-spawn opt-out testing.")
	TEST_ASSERT(!job_datum.uses_modular_job_landmark_spawn(), "Non-SO regression test picked a job that is now unexpectedly opted into modular non-squad spawn resolution.")

