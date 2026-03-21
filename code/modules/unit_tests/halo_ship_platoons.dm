/datum/unit_test/halo_contract_test

/datum/unit_test/halo_contract_test/Run()
	return

/datum/unit_test/halo_contract_test/proc/get_ship_platoon_family_types(platoon_type)
	var/list/profile = GLOB.RoleAuthority?.get_ship_platoon_profile(platoon_type)
	if(islist(profile?["family_types"]) && length(profile["family_types"]))
		return profile["family_types"]

	return list(platoon_type)

/datum/unit_test/halo_contract_test/proc/holder_has_overlay_state(image/holder, icon_state)
	if(!holder || !icon_state)
		return FALSE

	for(var/image/overlay as anything in holder.overlays)
		if(overlay.icon_state == icon_state)
			return TRUE

	return FALSE

/datum/unit_test/halo_contract_test/proc/assert_halo_role_job_type(job_title, expected_job_type)
	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	TEST_ASSERT_NOTNULL(role_authority, "RoleAuthority was unavailable for HALO role-classification testing.")

	var/datum/job/job_datum = role_authority.roles_by_name[job_title]
	TEST_ASSERT_EQUAL(job_datum?.type, expected_job_type, "[job_title] did not resolve to the preferred HALO job path.")

/datum/unit_test/halo_contract_test/proc/assert_halo_bucket_mapping(job_title, expected_bucket)
	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	TEST_ASSERT_NOTNULL(role_authority, "RoleAuthority was unavailable for HALO bucket-mapping testing.")

	TEST_ASSERT_EQUAL(role_authority.get_job_preference_bucket_key(job_title), expected_bucket, "[job_title] did not resolve to the canonical preference bucket.")
	assert_halo_title_mapping(job_title, expected_bucket)

/datum/unit_test/halo_contract_test/proc/assert_halo_title_mapping(job_title, expected_bucket)
	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	TEST_ASSERT_NOTNULL(role_authority, "RoleAuthority was unavailable for HALO title-mapping contract testing.")

	var/list/title_mappings = role_authority.get_ship_role_title_mappings()
	TEST_ASSERT_EQUAL(title_mappings[job_title], expected_bucket, "[job_title] did not map back to the canonical ship-role bucket.")

/datum/unit_test/halo_contract_test/proc/assert_halo_medic_option_resolution(job_type, option_title, role_title, platoon_type, expected_preset)
	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	TEST_ASSERT_NOTNULL(role_authority, "RoleAuthority was unavailable for HALO medic option-resolution testing.")

	var/datum/job/job_datum = new job_type()
	TEST_ASSERT_NOTNULL(job_datum, "Failed to instantiate the HALO medic job datum for option-resolution testing.")
	var/list/job_options = job_datum.job_options
	TEST_ASSERT(islist(job_options) && job_options[option_title], "Could not find the expected HALO medic option [option_title].")

	job_datum.handle_job_options(option_title)

	var/resolved_preset = job_datum.get_spawn_equip_preset(role_title, role_authority, platoon_type)
	TEST_ASSERT_EQUAL(resolved_preset, expected_preset, "[role_title] option [option_title] resolved to [resolved_preset] instead of [expected_preset].")

/datum/unit_test/halo_contract_test/proc/assert_halo_spawn_preset_resolution(job_title, expected_preset)
	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	TEST_ASSERT_NOTNULL(role_authority, "RoleAuthority was unavailable for HALO spawn-preset resolution testing.")

	var/datum/job/job_datum = role_authority.roles_by_name[job_title]
	TEST_ASSERT_NOTNULL(job_datum, "Failed to resolve the HALO job datum for [job_title].")
	TEST_ASSERT_EQUAL(job_datum.get_spawn_equip_preset(job_title, role_authority), expected_preset, "[job_title] no longer resolves through the HALO preset path.")

/datum/unit_test/halo_contract_test/proc/assert_assigned_to_platoon_family(mob/living/carbon/human/human, platoon_type, context)
	var/list/family_types = get_ship_platoon_family_types(platoon_type)
	TEST_ASSERT_NOTNULL(human?.assigned_squad, "[context] did not receive a squad assignment.")
	TEST_ASSERT(family_types.Find(human.assigned_squad?.type), "[context] joined [human.assigned_squad?.type] instead of one of the expected HALO squad types [english_list(family_types)].")

/datum/unit_test/halo_equip_test
	parent_type = /datum/unit_test/halo_contract_test
	var/list/tracked_test_humans = null

/datum/unit_test/halo_equip_test/Run()
	return

/datum/unit_test/halo_equip_test/New()
	. = ..()
	tracked_test_humans = list()

/datum/unit_test/halo_equip_test/proc/track_test_human(mob/living/carbon/human/human)
	if(human && !(human in tracked_test_humans))
		tracked_test_humans += human
	return human

/datum/unit_test/halo_equip_test/proc/create_test_human(real_name, job_title, squad_type = null, turf/spawn_turf = run_loc_floor_top_right, key_name = null)
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human, spawn_turf)
	configure_test_human(human, real_name, job_title, squad_type, key_name)
	return human

/datum/unit_test/halo_equip_test/proc/cleanup_test_human_runtime_state(mob/living/carbon/human/human)
	if(!istype(human))
		return

	human.clear_modular_spawn_candidate_cache()
	SSround_recording?.recorder?.stop_tracking(human)

	var/datum/squad/assigned_squad = human.assigned_squad
	if(assigned_squad)
		if(human in assigned_squad.marines_list)
			assigned_squad.forget_marine_in_squad(human)
		else
			if(assigned_squad.squad_leader == human)
				assigned_squad.squad_leader = null

			if(islist(assigned_squad.fireteam_leaders))
				for(var/fireteam_key in assigned_squad.fireteam_leaders)
					if(assigned_squad.fireteam_leaders[fireteam_key] == human)
						assigned_squad.fireteam_leaders[fireteam_key] = null

			assigned_squad.personnel_deleted(human, TRUE)
			human.assigned_squad = null
			human.assigned_fireteam = null

	if(islist(GLOB.marine_leaders))
		for(var/leader_key in GLOB.marine_leaders.Copy())
			var/leader_entry = GLOB.marine_leaders[leader_key]
			if(islist(leader_entry))
				leader_entry -= human
				if(!length(leader_entry))
					GLOB.marine_leaders -= leader_key
			else if(leader_entry == human)
				GLOB.marine_leaders -= leader_key

	if(SStracking)
		var/tracking_group = SStracking.mobs_in_processing?[human]
		if(tracking_group)
			SStracking.stop_tracking(tracking_group, human)

		SStracking.stop_misc_tracking(human)
		for(var/leader_group in SStracking.leaders.Copy())
			if(SStracking.leaders[leader_group] == human)
				SStracking.delete_leader(leader_group)

/datum/unit_test/halo_equip_test/Destroy()
	for(var/mob/living/carbon/human/human as anything in tracked_test_humans)
		if(!QDELETED(human))
			cleanup_test_human_runtime_state(human)

	for(var/mob/living/carbon/human/human as anything in tracked_test_humans)
		if(!QDELETED(human))
			qdel(human)

	tracked_test_humans = null
	return ..()

/datum/unit_test/halo_equip_test/proc/configure_test_human(mob/living/carbon/human/human, real_name, job_title, squad_type = null, key_name = null)
	if(human)
		track_test_human(human)
	human.real_name = real_name
	human.name = real_name
	human.job = job_title
	if(squad_type)
		human.assigned_squad = GLOB.RoleAuthority?.squads_by_type[squad_type]
		if(!human.assigned_squad && ispath(squad_type, /datum/squad))
			human.assigned_squad = allocate(squad_type)
	if(key_name)
		human.key = key_name

/datum/unit_test/halo_equip_test/proc/prepare_test_human_for_squad(mob/living/carbon/human/human, preset_type = /datum/equipment_preset, preset_assignment = null)
	var/datum/equipment_preset/preset = allocate(preset_type)
	preset.assignment = preset_assignment ? preset_assignment : human.job
	human.assigned_equipment_preset = preset

	var/obj/item/card/id/id = allocate(/obj/item/card/id)
	id.registered_name = human.real_name
	id.access = preset.access ? preset.access.Copy() : list()
	human.equip_to_slot(id, WEAR_ID, TRUE)

	return human.get_idcard()

/datum/unit_test/halo_equip_test/proc/cleanup_test_squad_membership(mob/living/carbon/human/human)
	if(!istype(human) || !human.assigned_squad)
		return

	human.assigned_squad.remove_marine_from_squad(human, human.get_idcard())

/datum/unit_test/halo_equip_test/proc/assert_halo_smoke_state(mob/living/carbon/human/human, expected_preset_type, expected_job, expected_title = expected_job, expected_faction = FACTION_UNSC)
	var/role_label = human?.real_name || expected_title || expected_job
	TEST_ASSERT_EQUAL(human?.assigned_equipment_preset?.type, expected_preset_type, "[role_label] did not keep the expected HALO preset identity.")
	TEST_ASSERT_EQUAL(human?.job, expected_job, "[role_label] did not keep the expected HALO runtime job.")
	TEST_ASSERT_EQUAL(human?.title, expected_title, "[role_label] did not keep the expected HALO runtime title.")
	TEST_ASSERT_EQUAL(human?.faction, expected_faction, "[role_label] did not keep the expected HALO mob faction.")

/datum/unit_test/halo_equip_test/proc/assert_halo_specialist_naked_baseline(mob/living/carbon/human/human)
	var/role_label = human?.real_name || "HALO specialist"
	TEST_ASSERT_NULL(human.get_item_by_slot(WEAR_BODY), "[role_label] should keep the HALO specialist baseline naked, but still had a uniform equipped.")
	TEST_ASSERT_NULL(human.get_item_by_slot(WEAR_L_EAR), "[role_label] should keep the HALO specialist baseline naked, but still had a headset equipped.")
	TEST_ASSERT_NULL(human.get_item_by_slot(WEAR_HEAD), "[role_label] should keep the HALO specialist baseline naked, but still had a helmet equipped.")
	TEST_ASSERT_NULL(human.get_item_by_slot(WEAR_JACKET), "[role_label] should keep the HALO specialist baseline naked, but still had armor equipped.")

/datum/unit_test/halo_integration_test
	parent_type = /datum/unit_test/halo_equip_test
	var/list/snapshot_default_roles = null
	var/list/snapshot_roles_for_mode = null
	var/list/snapshot_personal_closets = null
	var/list/snapshot_custom_items = null
	var/list/snapshot_latejoin = null
	var/list/snapshot_latejoin_by_squad = null
	var/list/snapshot_latejoin_by_job = null
	var/list/snapshot_squads = null
	var/list/snapshot_squads_by_type = null
	var/list/snapshot_next_map_configs = null
	var/list/tracked_test_squads = null
	var/list/tracked_test_atoms = null
	var/snapshot_ship_platoon = null
	var/snapshot_ship_map_name = null
	var/snapshot_ship_map_path = null
	var/list/snapshot_ship_allowed_platoons = null
	var/synthetic_mainship_z = null
	var/synthetic_mainship_prev = null
	var/list/snapshot_runtime_name_by_static = null
	var/list/snapshot_leader_lock_by_static = null
	var/snapshot_first_platoon_commander_ckey = null
	var/snapshot_main_platoon_name = null
	var/snapshot_main_platoon_initial_name = null

/datum/unit_test/halo_integration_test/Run()
	return

/datum/unit_test/halo_integration_test/New()
	. = ..()

	if(GLOB.RoleAuthority)
		snapshot_default_roles = GLOB.RoleAuthority.default_roles ? GLOB.RoleAuthority.default_roles.Copy() : null
		snapshot_roles_for_mode = GLOB.RoleAuthority.roles_for_mode ? GLOB.RoleAuthority.roles_for_mode.Copy() : null

	snapshot_personal_closets = GLOB.personal_closets ? GLOB.personal_closets.Copy() : list()
	snapshot_custom_items = GLOB.custom_items ? GLOB.custom_items.Copy() : list()
	snapshot_latejoin = GLOB.latejoin ? GLOB.latejoin.Copy() : list()
	snapshot_latejoin_by_squad = GLOB.latejoin_by_squad ? GLOB.latejoin_by_squad.Copy() : list()
	snapshot_latejoin_by_job = GLOB.latejoin_by_job ? GLOB.latejoin_by_job.Copy() : list()
	snapshot_squads = GLOB.RoleAuthority?.squads ? GLOB.RoleAuthority.squads.Copy() : list()
	snapshot_squads_by_type = GLOB.RoleAuthority?.squads_by_type ? GLOB.RoleAuthority.squads_by_type.Copy() : list()
	snapshot_next_map_configs = SSmapping?.next_map_configs ? SSmapping.next_map_configs.Copy() : null
	tracked_test_squads = list()
	tracked_test_atoms = list()
	snapshot_ship_platoon = SSmapping?.configs?[SHIP_MAP]?.platoon
	snapshot_ship_map_name = SSmapping?.configs?[SHIP_MAP]?.map_name
	snapshot_ship_map_path = SSmapping?.configs?[SHIP_MAP]?.map_path
	snapshot_ship_allowed_platoons = SSmapping?.configs?[SHIP_MAP]?.allowed_platoons ? SSmapping.configs[SHIP_MAP].allowed_platoons.Copy() : null
	var/datum/squad_name_manager/manager = GLOB.squad_name_manager
	snapshot_runtime_name_by_static = manager?.runtime_name_by_static ? manager.runtime_name_by_static.Copy() : null
	snapshot_leader_lock_by_static = manager?.leader_lock_by_static ? manager.leader_lock_by_static.Copy() : null
	snapshot_first_platoon_commander_ckey = manager?.first_platoon_commander_ckey
	snapshot_main_platoon_name = GLOB.main_platoon_name
	snapshot_main_platoon_initial_name = GLOB.main_platoon_initial_name

/datum/unit_test/halo_integration_test/Destroy()
	var/result = ..()

	for(var/datum/squad/squad as anything in tracked_test_squads)
		if(!QDELETED(squad))
			qdel(squad)

	for(var/atom/atom as anything in tracked_test_atoms)
		if(!QDELETED(atom))
			qdel(atom)

	if(synthetic_mainship_z)
		var/datum/space_level/level = SSmapping?.get_level(synthetic_mainship_z)
		if(level && islist(level.traits))
			level.traits[ZTRAIT_MARINE_MAIN_SHIP] = synthetic_mainship_prev
		synthetic_mainship_z = null
		synthetic_mainship_prev = null

	if(GLOB.RoleAuthority)
		GLOB.RoleAuthority.default_roles = snapshot_default_roles ? snapshot_default_roles.Copy() : list()
		GLOB.RoleAuthority.roles_for_mode = snapshot_roles_for_mode ? snapshot_roles_for_mode.Copy() : list()
		GLOB.RoleAuthority.squads = snapshot_squads ? snapshot_squads.Copy() : list()
		GLOB.RoleAuthority.squads_by_type = snapshot_squads_by_type ? snapshot_squads_by_type.Copy() : list()

	GLOB.personal_closets = snapshot_personal_closets ? snapshot_personal_closets.Copy() : list()
	GLOB.custom_items = snapshot_custom_items ? snapshot_custom_items.Copy() : list()
	GLOB.latejoin = snapshot_latejoin ? snapshot_latejoin.Copy() : list()
	GLOB.latejoin_by_squad = snapshot_latejoin_by_squad ? snapshot_latejoin_by_squad.Copy() : list()
	GLOB.latejoin_by_job = snapshot_latejoin_by_job ? snapshot_latejoin_by_job.Copy() : list()
	if(SSmapping)
		SSmapping.next_map_configs = snapshot_next_map_configs ? snapshot_next_map_configs.Copy() : null
	var/datum/squad_name_manager/manager = GLOB.squad_name_manager
	if(manager)
		manager.runtime_name_by_static = snapshot_runtime_name_by_static ? snapshot_runtime_name_by_static.Copy() : list()
		manager.leader_lock_by_static = snapshot_leader_lock_by_static ? snapshot_leader_lock_by_static.Copy() : list()
		manager.first_platoon_commander_ckey = snapshot_first_platoon_commander_ckey
	GLOB.main_platoon_name = snapshot_main_platoon_name
	GLOB.main_platoon_initial_name = snapshot_main_platoon_initial_name
	if(SSmapping?.configs?[SHIP_MAP])
		SSmapping.configs[SHIP_MAP].platoon = snapshot_ship_platoon
		SSmapping.configs[SHIP_MAP].map_name = snapshot_ship_map_name
		SSmapping.configs[SHIP_MAP].map_path = snapshot_ship_map_path
		SSmapping.configs[SHIP_MAP].allowed_platoons = snapshot_ship_allowed_platoons ? snapshot_ship_allowed_platoons.Copy() : null

	tracked_test_squads = null
	tracked_test_atoms = null
	snapshot_squads = null
	snapshot_squads_by_type = null

	return result

/datum/unit_test/halo_integration_test/proc/isolate_personal_lockers(obj/structure/closet/secure_closet/marine_personal/locker)
	GLOB.personal_closets = locker ? list(locker) : list()

/datum/unit_test/halo_integration_test/proc/track_test_atom(atom/tracked_atom)
	if(tracked_atom && !(tracked_atom in tracked_test_atoms))
		tracked_test_atoms += tracked_atom
	return tracked_atom

/datum/unit_test/halo_integration_test/proc/map_static_squad_aliases_to_family(platoon_type)
	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	if(!role_authority)
		return

	var/list/family_types = get_ship_platoon_family_types(platoon_type)
	if(length(family_types) < 4)
		return

	var/list/static_types = list(
		/datum/squad/marine/alpha,
		/datum/squad/marine/bravo,
		/datum/squad/marine/charlie,
		/datum/squad/marine/delta,
	)

	for(var/i = 1 to 4)
		var/family_type = family_types[i]
		if(role_authority.squads_by_type[family_type])
			role_authority.squads_by_type[static_types[i]] = role_authority.squads_by_type[family_type]

/datum/unit_test/halo_integration_test/proc/configure_test_ship_platoon(platoon_type)
	var/datum/map_config/ship_config = SSmapping?.configs?[SHIP_MAP]
	TEST_ASSERT_NOTNULL(ship_config, "Failed to resolve ship config for platoon test setup.")
	ship_config.platoon = "[platoon_type]"

	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	TEST_ASSERT_NOTNULL(role_authority, "RoleAuthority was unavailable for platoon test setup.")

	var/list/squad_types = list(
		/datum/squad/marine/alpha,
		/datum/squad/marine/bravo,
		/datum/squad/marine/charlie,
		/datum/squad/marine/delta,
		/datum/squad/marine/halo/unsc/alpha,
		/datum/squad/marine/halo/unsc/bravo,
		/datum/squad/marine/halo/unsc/charlie,
		/datum/squad/marine/halo/unsc/delta,
		/datum/squad/marine/halo/odst/alpha,
		/datum/squad/marine/halo/odst/bravo,
		/datum/squad/marine/halo/odst/charlie,
		/datum/squad/marine/halo/odst/delta,
		/datum/squad/marine/cryo,
	)
	role_authority.squads = list()
	role_authority.squads_by_type = list()
	for(var/squad_type as anything in squad_types)
		var/datum/squad/squad = new squad_type()
		role_authority.squads += squad
		role_authority.squads_by_type[squad.type] = squad
		tracked_test_squads += squad

	map_static_squad_aliases_to_family(platoon_type)

/datum/unit_test/halo_integration_test/proc/clear_personal_locker_contents(obj/structure/closet/secure_closet/marine_personal/locker)
	for(var/atom/movable/movable as anything in locker.contents)
		movable.forceMove(run_loc_floor_top_right)

/datum/unit_test/halo_integration_test/proc/count_personal_locker_contents_by_type(obj/structure/closet/secure_closet/marine_personal/locker, content_type)
	. = 0
	if(!locker || !content_type)
		return

	for(var/atom/movable/movable as anything in locker.contents)
		if(istype(movable, content_type))
			.++

/datum/unit_test/halo_integration_test/proc/count_personal_locker_contents_by_exact_type(obj/structure/closet/secure_closet/marine_personal/locker, content_type)
	. = 0
	if(!locker || !content_type)
		return

	for(var/atom/movable/movable as anything in locker.contents)
		if(movable.type == content_type)
			.++

/datum/unit_test/halo_integration_test/proc/count_turf_contents_by_exact_type(turf/content_turf, content_type)
	. = 0
	if(!content_turf || !content_type)
		return

	for(var/atom/movable/movable as anything in content_turf)
		if(movable.type == content_type)
			.++

/datum/unit_test/halo_integration_test/proc/get_adjacent_floor_turf(turf/center_turf)
	if(!isfloorturf(center_turf))
		return null

	for(var/cardinal_dir in GLOB.cardinals)
		var/turf/candidate_turf = get_step(center_turf, cardinal_dir)
		if(isfloorturf(candidate_turf))
			return candidate_turf

	return null

/datum/unit_test/halo_integration_test/proc/get_mainship_test_turf(require_adjacent_floor = FALSE)
	for(var/obj/structure/closet/secure_closet/marine_personal/locker as anything in snapshot_personal_closets)
		var/turf/locker_turf = get_turf(locker)
		if(require_adjacent_floor && !get_adjacent_floor_turf(locker_turf))
			continue
		if(isfloorturf(locker_turf) && is_mainship_level(locker_turf.z))
			return locker_turf

	for(var/obj/structure/closet/secure_closet/marine_personal/locker as anything in GLOB.personal_closets)
		var/turf/locker_turf = get_turf(locker)
		if(require_adjacent_floor && !get_adjacent_floor_turf(locker_turf))
			continue
		if(isfloorturf(locker_turf) && is_mainship_level(locker_turf.z))
			return locker_turf

	var/turf/mainship_center = SSmapping?.get_mainship_center()
	if(require_adjacent_floor && !get_adjacent_floor_turf(mainship_center))
		mainship_center = null
	if(isfloorturf(mainship_center) && is_mainship_level(mainship_center.z))
		return mainship_center

	var/list/mainship_levels = SSmapping?.levels_by_trait(ZTRAIT_MARINE_MAIN_SHIP)
	if(length(mainship_levels))
		var/turf/mainship_level_turf = locate(1, 1, mainship_levels[1])
		if(isfloorturf(mainship_level_turf))
			if(!require_adjacent_floor || get_adjacent_floor_turf(mainship_level_turf))
				return mainship_level_turf

	var/turf/fallback = run_loc_floor_top_right
	if(!isfloorturf(fallback))
		return null
	if(require_adjacent_floor && !get_adjacent_floor_turf(fallback))
		return null

	var/datum/space_level/level = SSmapping?.get_level(fallback.z)
	if(level && islist(level.traits))
		if(isnull(synthetic_mainship_z))
			synthetic_mainship_z = fallback.z
			synthetic_mainship_prev = level.traits[ZTRAIT_MARINE_MAIN_SHIP]
			level.traits[ZTRAIT_MARINE_MAIN_SHIP] = TRUE

	return fallback

/datum/unit_test/halo_ship_platoons
	parent_type = /datum/unit_test/halo_integration_test
