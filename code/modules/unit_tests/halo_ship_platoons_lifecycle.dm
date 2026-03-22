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
	TEST_ASSERT_EQUAL(manager.rename_squad(alpha_squad, "Unit Test Alpha", null, "halo_so_lifecycle_test", TRUE), TRUE, "Failed to seed a non-default Alpha squad name before HALO SO latejoin lifecycle testing.")
	TEST_ASSERT_EQUAL(alpha_squad.name, "Unit Test Alpha", "Alpha squad setup for HALO SO lifecycle testing did not take effect.")

	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	TEST_ASSERT_NOTNULL(role_authority, "RoleAuthority was unavailable for HALO Platoon Commander lifecycle testing.")
	var/datum/job/so_job = role_authority.roles_by_name[JOB_SO_UNSC]
	TEST_ASSERT_NOTNULL(so_job, "Failed to resolve the HALO UNSC Platoon Commander job datum for lifecycle testing.")

	var/mob/living/carbon/human/halo_so_pref = create_test_human("HALO Platoon Commander Pref", JOB_SO_UNSC, null, run_loc_floor_bottom_left, "halo_so_pref")
	halo_so_pref.job = so_job
	TEST_ASSERT(manager.claim_first_platoon_commander(halo_so_pref), "Platoon Commander preference claim should accept HALO job datums without bad-indexing the default-role map.")

	var/mob/living/carbon/human/halo_so = create_test_human("HALO Platoon Commander", JOB_SO_UNSC, null, run_loc_floor_top_right, "halo_so_lifecycle")
	arm_equipment(halo_so, /datum/equipment_preset/unsc/platco, FALSE, TRUE, null, TRUE, TRUE)

	TEST_ASSERT_EQUAL(alpha_squad.name, manager.get_default_name_by_static(SQUAD_MARINE_1), "HALO SO latejoin lifecycle no longer restores the first-platoon-commander squad-name fallback.")

/datum/unit_test/halo_ship_platoons_spawn_and_cryo_routing
	parent_type = /datum/unit_test/halo_integration_test

/datum/unit_test/halo_ship_platoons_spawn_and_cryo_routing/Run()
	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	TEST_ASSERT_NOTNULL(role_authority, "RoleAuthority was unavailable for HALO spawn/cryo routing testing.")
	var/datum/emergency_call/cryo_squad/cryo_call = allocate(/datum/emergency_call/cryo_squad)
	TEST_ASSERT_NOTNULL(cryo_call, "Failed to allocate the cryo emergency-call helper for HALO spawn/cryo routing testing.")

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

	var/datum/modular_squad_spawn_result/result = resolver.pick_result_for_step("latejoin", 1, own_squad_keys, other_squad_keys, require_free_pod = FALSE)
	TEST_ASSERT_NOTNULL(result, "Latejoin resolver tier 1 failed to produce a result when a squad landmark existed.")
	TEST_ASSERT_EQUAL(result.landmark, squad_landmark, "Latejoin resolver tier 1 fell through instead of using the squad latejoin landmark.")
	TEST_ASSERT_EQUAL(result.source_tag, "latejoin", "Latejoin resolver regression test produced an unexpected source tag.")
	TEST_ASSERT_EQUAL(result.tier_tag, "tier_1", "Latejoin resolver regression test produced an unexpected tier tag.")

	var/turf/center_turf = get_mainship_test_turf(TRUE)
	TEST_ASSERT(isfloorturf(center_turf), "Failed to resolve test turf for SO spawn roundstart testing.")
	var/turf/holding_turf = run_loc_floor_bottom_left
	TEST_ASSERT(isfloorturf(holding_turf), "Failed to resolve holding turf for SO spawn roundstart testing.")
	var/turf/pod_turf = get_adjacent_floor_turf(center_turf)
	TEST_ASSERT(isfloorturf(pod_turf), "Failed to find adjacent turf for SO spawn roundstart test cryopod.")

	allocate(/obj/effect/landmark/start/bridge, center_turf)
	allocate(/obj/structure/machinery/cryopod, pod_turf)

	var/datum/job/so_job = role_authority.roles_by_name[JOB_SO_UNSC]
	TEST_ASSERT_NOTNULL(so_job, "Failed to resolve JOB_SO_UNSC datum for SO spawn roundstart testing.")

	var/mob/living/carbon/human/so_human = create_test_human("HALO SO Spawn Candidate", JOB_SO_UNSC, null, holding_turf)
	var/list/spawn_candidate = so_human.get_modular_spawn_candidate(so_job, FALSE)

	TEST_ASSERT_NOTNULL(spawn_candidate, "Modular spawn candidate was null for SO roundstart testing.")
	TEST_ASSERT_EQUAL(spawn_candidate["source_tag"], "start_job", "SO spawn candidate source tag was not start_job.")
	TEST_ASSERT_EQUAL(spawn_candidate["tier_tag"], "job", "SO spawn candidate tier tag was not job.")
	TEST_ASSERT_EQUAL(spawn_candidate["no_pod_expected"], FALSE, "SO spawn candidate unexpectedly marked no_pod_expected.")
	TEST_ASSERT(isfloorturf(spawn_candidate["spawn_turf"]), "SO spawn candidate did not resolve to a floor turf.")
	TEST_ASSERT(istype(spawn_candidate["preferred_pod"], /obj/structure/machinery/cryopod), "SO spawn candidate did not resolve to a cryopod.")
	TEST_ASSERT_EQUAL(get_dist(spawn_candidate["spawn_turf"], get_turf(spawn_candidate["preferred_pod"])), 1, "SO spawn candidate did not keep the preferred cryopod cardinally adjacent to its spawn turf.")

	var/mob/living/carbon/human/unsc_medic = create_test_human("HALO Cryo Medic", JOB_SQUAD_MEDIC)
	TEST_ASSERT(cryo_call.apply_profile_cryo_reinforcement(unsc_medic, JOB_SQUAD_MEDIC, JOB_SQUAD_MEDIC, null, FALSE, /datum/squad/marine/halo/unsc/alpha), "HALO UNSC cryo helper failed to apply a supported medic override.")
	assert_halo_smoke_state(unsc_medic, /datum/equipment_preset/unsc/medic, JOB_SQUAD_MEDIC_UNSC)
	assert_assigned_to_platoon_family(unsc_medic, /datum/squad/marine/halo/unsc/alpha, "HALO UNSC cryo medic")
	var/obj/item/card/id/unsc_medic_id = unsc_medic.get_idcard()
	TEST_ASSERT_EQUAL(unsc_medic_id?.faction, FACTION_UNSC, "HALO UNSC cryo application helper did not keep FACTION_UNSC on the medic ID metadata.")

	var/mob/living/carbon/human/unsupported_engineer = create_test_human("Unsupported HALO Engineer", JOB_SQUAD_ENGI)
	TEST_ASSERT(!cryo_call.apply_profile_cryo_reinforcement(unsupported_engineer, JOB_SQUAD_ENGI, JOB_SQUAD_ENGI, /datum/equipment_preset/uscm/engineer_equipped, FALSE, /datum/squad/marine/halo/unsc/alpha), "HALO cryo application helper incorrectly accepted an unsupported engineer profile override.")

/datum/unit_test/halo_ship_platoons_surfaces_and_pending_sync
	parent_type = /datum/unit_test/halo_integration_test

/datum/unit_test/halo_ship_platoons_surfaces_and_pending_sync/Run()
	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	TEST_ASSERT_NOTNULL(role_authority, "RoleAuthority was unavailable for HALO ship-surface lifecycle testing.")

	configure_test_ship_platoon(/datum/squad/marine/halo/unsc/alpha)

	var/turf/mainship_turf = get_mainship_test_turf(TRUE)
	TEST_ASSERT(isfloorturf(mainship_turf), "Failed to resolve a floor turf for HALO ship-surface lifecycle testing.")
	var/turf/adjacent_turf = get_adjacent_floor_turf(mainship_turf)
	TEST_ASSERT(isfloorturf(adjacent_turf), "Failed to resolve an adjacent floor turf for HALO ship-surface lifecycle testing.")

	var/obj/structure/closet/secure_closet/marine_personal/unsc/alpha/rifleman/source_locker = allocate(/obj/structure/closet/secure_closet/marine_personal/unsc/alpha/rifleman, mainship_turf)
	source_locker.pixel_x = 11
	source_locker.pixel_y = -6
	source_locker.dir = WEST
	source_locker.density = FALSE
	source_locker.owner = "Mapper Locker"
	source_locker.x_to_linked_spawn_turf = adjacent_turf.x - source_locker.x
	source_locker.y_to_linked_spawn_turf = adjacent_turf.y - source_locker.y
	source_locker.linked_spawn_turf = adjacent_turf
	var/obj/item/device/flashlight/mapper_item = allocate(/obj/item/device/flashlight, source_locker)

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
	TEST_ASSERT_EQUAL(target_locker.owner, "Mapper Locker", "Locker ship surface replacement did not preserve locker owner metadata.")
	TEST_ASSERT_EQUAL(target_locker.linked_spawn_turf, adjacent_turf, "Locker ship surface replacement did not preserve linked spawn turf.")
	TEST_ASSERT(mapper_item in target_locker.contents, "Locker ship surface replacement lost mapper-added contents.")
	TEST_ASSERT_EQUAL(count_personal_locker_contents_by_exact_type(target_locker, /obj/item/device/radio/headset/almayer/marine/solardevils/unsc), 0, "Locker ship surface replacement incorrectly carried over the exact UNSC baseline headset into the ODST locker.")
	TEST_ASSERT(count_personal_locker_contents_by_exact_type(target_locker, /obj/item/device/radio/headset/almayer/marine/solardevils/unsc/odst) >= 1, "Locker ship surface replacement did not keep the ODST baseline headset.")

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
