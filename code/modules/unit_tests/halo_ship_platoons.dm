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
		var/player_ckey = ckey(key_name)
		human.ckey = player_ckey
		human.persistent_ckey = player_ckey

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

/datum/unit_test/halo_equip_test/proc/assert_halo_core_wearables(mob/living/carbon/human/human, expect_head = TRUE)
	var/role_label = human?.real_name || "HALO human"
	TEST_ASSERT_NOTNULL(human.get_item_by_slot(WEAR_BODY), "[role_label] should have a uniform equipped in the body slot.")
	TEST_ASSERT_NOTNULL(human.get_item_by_slot(WEAR_JACKET), "[role_label] should have armor equipped in the jacket slot.")
	TEST_ASSERT_NOTNULL(human.get_item_by_slot(WEAR_HANDS), "[role_label] should have gloves equipped in the hands slot.")
	TEST_ASSERT_NOTNULL(human.get_item_by_slot(WEAR_FEET), "[role_label] should have boots equipped in the feet slot.")
	if(expect_head)
		TEST_ASSERT_NOTNULL(human.get_item_by_slot(WEAR_HEAD), "[role_label] should have headgear equipped in the head slot.")

/datum/unit_test/halo_equip_test/proc/assert_halo_specialist_naked_baseline(mob/living/carbon/human/human)
	var/role_label = human?.real_name || "HALO specialist"
	TEST_ASSERT_NULL(human.get_item_by_slot(WEAR_BODY), "[role_label] should keep the HALO specialist baseline naked, but still had a uniform equipped.")
	TEST_ASSERT_NULL(human.get_item_by_slot(WEAR_L_EAR), "[role_label] should keep the HALO specialist baseline naked, but still had a headset equipped.")
	TEST_ASSERT_NULL(human.get_item_by_slot(WEAR_HEAD), "[role_label] should keep the HALO specialist baseline naked, but still had a helmet equipped.")
	TEST_ASSERT_NULL(human.get_item_by_slot(WEAR_JACKET), "[role_label] should keep the HALO specialist baseline naked, but still had armor equipped.")

/datum/unit_test/halo_equip_test/proc/assert_halo_odst_visual_slots(mob/living/carbon/human/human, role_label = human?.real_name || "HALO ODST")
	TEST_ASSERT(istype(human?.get_item_by_slot(WEAR_L_EAR), /obj/item/device/radio/headset/almayer/marine/solardevils/unsc/odst), "[role_label] lost the expected ODST headset in the left ear slot.")
	TEST_ASSERT(istype(human?.get_item_by_slot(WEAR_HEAD), /obj/item/clothing/head/helmet/marine/unsc/odst), "[role_label] lost the expected ODST helmet in the head slot.")
	TEST_ASSERT(istype(human?.get_item_by_slot(WEAR_BODY), /obj/item/clothing/under/marine/odst), "[role_label] lost the expected ODST bodyglove in the uniform slot.")
	TEST_ASSERT(istype(human?.get_item_by_slot(WEAR_JACKET), /obj/item/clothing/suit/marine/unsc/odst), "[role_label] lost the expected ODST armor in the jacket slot.")

/datum/unit_test/halo_integration_test
	parent_type = /datum/unit_test/halo_equip_test
	var/list/snapshot_default_roles = null
	var/list/snapshot_roles_for_mode = null
	var/list/snapshot_personal_closets = null
	var/list/snapshot_custom_items = null
	var/list/snapshot_spawns_by_job = null
	var/list/snapshot_spawns_by_squad_and_job = null
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
	snapshot_spawns_by_job = GLOB.spawns_by_job ? GLOB.spawns_by_job.Copy() : list()
	snapshot_spawns_by_squad_and_job = GLOB.spawns_by_squad_and_job ? GLOB.spawns_by_squad_and_job.Copy() : list()
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
	GLOB.spawns_by_job = snapshot_spawns_by_job ? snapshot_spawns_by_job.Copy() : list()
	GLOB.spawns_by_squad_and_job = snapshot_spawns_by_squad_and_job ? snapshot_spawns_by_squad_and_job.Copy() : list()
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

/datum/unit_test/halo_integration_test/proc/link_personal_locker_to_spawn(obj/structure/closet/secure_closet/marine_personal/locker, turf/spawn_turf)
	if(!locker || !isturf(spawn_turf))
		return

	locker.linked_spawn_turf = spawn_turf
	locker.x_to_linked_spawn_turf = spawn_turf.x - locker.x
	locker.y_to_linked_spawn_turf = spawn_turf.y - locker.y

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

/datum/unit_test/halo_ship_platoons/random_personal_locker_selection_respects_role_and_squad

/datum/unit_test/halo_ship_platoons/random_personal_locker_selection_respects_role_and_squad/Run()
	configure_test_ship_platoon(/datum/squad/marine/alpha)
	GLOB.squad_name_manager?.apply_roundstart_defaults()

	var/turf/locker_turf = get_mainship_test_turf(TRUE)
	TEST_ASSERT(isfloorturf(locker_turf), "Failed to resolve a locker turf for personal-locker random-selection testing.")
	var/turf/spawn_turf = get_adjacent_floor_turf(locker_turf)
	TEST_ASSERT(isfloorturf(spawn_turf), "Failed to resolve a spawn turf for personal-locker random-selection testing.")

	var/obj/structure/machinery/cryopod/pod = allocate(/obj/structure/machinery/cryopod, locker_turf)
	var/mob/living/carbon/human/medic = create_test_human("Locker Medic", JOB_SQUAD_MEDIC, /datum/squad/marine/alpha, locker_turf)
	pod.go_in_cryopod(medic, TRUE)
	TEST_ASSERT_EQUAL(medic.loc, pod, "Failed to move the medic into the cryopod for linked-locker random-selection testing.")

	var/obj/structure/closet/secure_closet/marine_personal/corpsman/medic_locker_a = allocate(/obj/structure/closet/secure_closet/marine_personal/corpsman, run_loc_floor_top_right)
	var/obj/structure/closet/secure_closet/marine_personal/corpsman/medic_locker_b = allocate(/obj/structure/closet/secure_closet/marine_personal/corpsman, run_loc_floor_top_right)
	var/obj/structure/closet/secure_closet/marine_personal/rifleman/rifleman_locker = allocate(/obj/structure/closet/secure_closet/marine_personal/rifleman, run_loc_floor_bottom_left)
	var/obj/structure/closet/secure_closet/marine_personal/corpsman/other_squad_locker = allocate(/obj/structure/closet/secure_closet/marine_personal/corpsman, run_loc_floor_bottom_left)

	medic_locker_a.squad_type = SQUAD_MARINE_1
	medic_locker_b.squad_type = SQUAD_MARINE_1
	rifleman_locker.squad_type = SQUAD_MARINE_1
	other_squad_locker.squad_type = SQUAD_MARINE_2

	link_personal_locker_to_spawn(medic_locker_a, spawn_turf)
	link_personal_locker_to_spawn(medic_locker_b, spawn_turf)
	link_personal_locker_to_spawn(rifleman_locker, spawn_turf)
	link_personal_locker_to_spawn(other_squad_locker, spawn_turf)

	GLOB.personal_closets = list(rifleman_locker, other_squad_locker, medic_locker_a, medic_locker_b)

	var/datum/equipment_preset/preset = allocate(/datum/equipment_preset)
	var/obj/structure/closet/secure_closet/marine_personal/selected_locker = preset.find_personal_locker_for_player(medic, FALSE)

	TEST_ASSERT(selected_locker == medic_locker_a || selected_locker == medic_locker_b, "Random locker selection returned a locker outside the allowed same-role same-squad candidate pool.")
	TEST_ASSERT_NOTEQUAL(selected_locker, rifleman_locker, "Random locker selection incorrectly returned the rifleman locker for a medic.")
	TEST_ASSERT_NOTEQUAL(selected_locker, other_squad_locker, "Random locker selection incorrectly returned another squad's locker.")

/datum/unit_test/halo_ship_platoons/latejoin_personal_locker_reclaim_respects_role_and_squad

/datum/unit_test/halo_ship_platoons/latejoin_personal_locker_reclaim_respects_role_and_squad/Run()
	configure_test_ship_platoon(/datum/squad/marine/alpha)
	GLOB.squad_name_manager?.apply_roundstart_defaults()

	var/turf/locker_turf = get_mainship_test_turf(TRUE)
	TEST_ASSERT(isfloorturf(locker_turf), "Failed to resolve a locker turf for personal-locker reclaim testing.")
	var/turf/spawn_turf = get_adjacent_floor_turf(locker_turf)
	TEST_ASSERT(isfloorturf(spawn_turf), "Failed to resolve a spawn turf for personal-locker reclaim testing.")

	var/obj/structure/machinery/cryopod/pod = allocate(/obj/structure/machinery/cryopod, locker_turf)
	var/mob/living/carbon/human/medic = create_test_human("Latejoin Medic", JOB_SQUAD_MEDIC, /datum/squad/marine/alpha, locker_turf)
	pod.go_in_cryopod(medic, TRUE)
	TEST_ASSERT_EQUAL(medic.loc, pod, "Failed to move the latejoin medic into the cryopod for personal-locker reclaim testing.")

	var/obj/structure/closet/secure_closet/marine_personal/rifleman/rifleman_reclaim = allocate(/obj/structure/closet/secure_closet/marine_personal/rifleman, run_loc_floor_top_right)
	var/obj/structure/closet/secure_closet/marine_personal/corpsman/other_squad_reclaim = allocate(/obj/structure/closet/secure_closet/marine_personal/corpsman, run_loc_floor_bottom_left)
	var/obj/structure/closet/secure_closet/marine_personal/corpsman/medic_reclaim = allocate(/obj/structure/closet/secure_closet/marine_personal/corpsman, run_loc_floor_top_right)

	rifleman_reclaim.owner = "Old Rifleman"
	other_squad_reclaim.owner = "Old Bravo Medic"
	medic_reclaim.owner = "Old Medic"

	rifleman_reclaim.squad_type = SQUAD_MARINE_1
	other_squad_reclaim.squad_type = SQUAD_MARINE_2
	medic_reclaim.squad_type = SQUAD_MARINE_1

	link_personal_locker_to_spawn(rifleman_reclaim, spawn_turf)
	link_personal_locker_to_spawn(other_squad_reclaim, spawn_turf)
	link_personal_locker_to_spawn(medic_reclaim, spawn_turf)

	GLOB.personal_closets = list(rifleman_reclaim, other_squad_reclaim, medic_reclaim)

	var/datum/equipment_preset/preset = allocate(/datum/equipment_preset)
	var/obj/structure/closet/secure_closet/marine_personal/selected_locker = preset.find_personal_locker_for_player(medic, TRUE)

	TEST_ASSERT_EQUAL(selected_locker, medic_reclaim, "Latejoin reclaim should only use an abandoned locker from the same role and squad.")
	TEST_ASSERT_NOTEQUAL(selected_locker, rifleman_reclaim, "Latejoin reclaim incorrectly accepted a wrong-role locker.")
	TEST_ASSERT_NOTEQUAL(selected_locker, other_squad_reclaim, "Latejoin reclaim incorrectly accepted another squad's locker.")

/datum/unit_test/halo_ship_platoons/bravo_runtime_rename_labels

/datum/unit_test/halo_ship_platoons/bravo_runtime_rename_labels/Run()
	configure_test_ship_platoon(/datum/squad/marine/alpha)

	var/datum/squad_name_manager/manager = GLOB.squad_name_manager
	TEST_ASSERT_NOTNULL(manager, "Squad name manager was unavailable for Bravo runtime rename label testing.")
	manager.apply_roundstart_defaults()

	var/datum/squad/bravo_squad = manager.get_squad_by_static(SQUAD_MARINE_2)
	TEST_ASSERT_NOTNULL(bravo_squad, "Failed to resolve Bravo squad for runtime rename label testing.")

	var/obj/item/device/radio/headset/almayer/marine/bravo/bravo_headset = track_test_atom(allocate(/obj/item/device/radio/headset/almayer/marine/bravo, run_loc_floor_top_right))
	var/obj/item/device/encryptionkey/bravo/bravo_key = track_test_atom(allocate(/obj/item/device/encryptionkey/bravo, run_loc_floor_top_right))
	TEST_ASSERT_NOTNULL(bravo_headset, "Failed to allocate Bravo headset for runtime rename label testing.")
	TEST_ASSERT_NOTNULL(bravo_key, "Failed to allocate Bravo encryption key for runtime rename label testing.")

	TEST_ASSERT_EQUAL(manager.rename_squad(bravo_squad, "Vanguard", null, "unit_test_runtime_label", TRUE), TRUE, "Bravo runtime rename failed during label regression test.")
	TEST_ASSERT_EQUAL(bravo_squad.name, "Vanguard", "Bravo runtime rename did not update the squad datum name.")
	TEST_ASSERT_EQUAL(bravo_headset.name, "marine vanguard radio headset", "Bravo headset label did not refresh to the runtime squad name.")
	TEST_ASSERT_EQUAL(bravo_headset.desc, "This is used by Vanguard squad members. When worn, grants access to Squad Leader tracker. Click tracker with empty hand to open Squad Info window.", "Bravo headset description did not refresh to the runtime squad name.")
	TEST_ASSERT_EQUAL(bravo_key.name, "\improper Vanguard Squad Radio Encryption Key", "Bravo encryption key label did not refresh to the runtime squad name.")

/datum/unit_test/halo_ship_platoons/odst_leader_assignment_labels

/datum/unit_test/halo_ship_platoons/odst_leader_assignment_labels/Run()
	configure_test_ship_platoon(/datum/squad/marine/halo/odst/alpha)

	var/datum/squad_name_manager/manager = GLOB.squad_name_manager
	TEST_ASSERT_NOTNULL(manager, "Squad name manager was unavailable for ODST assignment label testing.")
	manager.apply_roundstart_defaults()

	var/datum/squad/alpha_squad = manager.get_squad_by_static(SQUAD_MARINE_1)
	TEST_ASSERT_NOTNULL(alpha_squad, "Failed to resolve Alpha squad for ODST assignment label testing.")
	TEST_ASSERT_EQUAL(alpha_squad.type, /datum/squad/marine/halo/odst/alpha, "ODST assignment label testing did not resolve the HALO ODST Alpha squad.")

	var/mob/living/carbon/human/leader = create_test_human("ODST Leader Assignment", JOB_SQUAD_LEADER_ODST)
	var/obj/item/card/id/leader_id = prepare_test_human_for_squad(leader, /datum/equipment_preset/unsc/leader/odst, JOB_SQUAD_LEADER_ODST)
	TEST_ASSERT(alpha_squad.put_marine_in_squad(leader, leader_id), "Failed to place the ODST leader into Alpha squad for assignment label testing.")

	var/expected_default_assignment = "[alpha_squad.name] [alpha_squad.get_role_label(JOB_SQUAD_LEADER)]"
	TEST_ASSERT_EQUAL(leader_id.assignment, expected_default_assignment, "ODST leader default assignment did not use the runtime squad label.")

	TEST_ASSERT_EQUAL(manager.rename_squad(alpha_squad, "Vanguard", null, "unit_test_odst_assignment", TRUE), TRUE, "ODST assignment label rename failed during runtime label testing.")
	var/expected_runtime_assignment = "[alpha_squad.name] [alpha_squad.get_role_label(JOB_SQUAD_LEADER)]"
	TEST_ASSERT_EQUAL(leader_id.assignment, expected_runtime_assignment, "ODST leader runtime assignment did not refresh to the renamed squad label.")

/datum/unit_test/halo_ship_platoons/odst_equipped_slots/Run()
	configure_test_ship_platoon(/datum/squad/marine/halo/odst/alpha)

	var/mob/living/carbon/human/human = create_test_human("ODST Equipped Slots", JOB_SQUAD_MARINE_ODST)
	arm_equipment(human, /datum/equipment_preset/unsc/pfc/odst/equipped, FALSE, TRUE)

	assert_halo_smoke_state(human, /datum/equipment_preset/unsc/pfc/odst/equipped, JOB_SQUAD_MARINE_ODST)
	assert_halo_odst_visual_slots(human, "ODST equipped smoke")

/datum/unit_test/halo_ship_platoons/odst_preview_dummy_slots/Run()
	configure_test_ship_platoon(/datum/squad/marine/halo/odst/alpha)

	var/datum/preferences/prefs = new
	prefs.job_preference_list = list(JOB_SQUAD_MARINE = HIGH_PRIORITY)
	prefs.preview_dummy = create_test_human("ODST Preview Dummy", JOB_SQUAD_MARINE_ODST)

	var/preset_type = prefs.job_pref_to_gear_preset()
	TEST_ASSERT_EQUAL(preset_type, /datum/equipment_preset/unsc/pfc/odst/equipped, "ODST preference preview no longer resolves to the equipped ODST rifleman preset on the active platoon.")

	prefs.clear_equipment()
	prefs.preview_dummy.set_species()
	prefs.copy_appearance_to(prefs.preview_dummy)
	prefs.preview_dummy.update_body()
	prefs.preview_dummy.update_hair()
	arm_equipment(prefs.preview_dummy, preset_type, FALSE, FALSE, prefs.owner, prefs.show_job_gear)

	assert_halo_odst_visual_slots(prefs.preview_dummy, "ODST preview dummy")
	prefs.preview_dummy = null

/datum/unit_test/halo_ship_platoons/odst_manual_equip_without_hud_slots/Run()
	var/mob/living/carbon/human/human = create_test_human("ODST Manual Equip", JOB_SQUAD_MARINE_ODST)
	var/obj/item/clothing/under/marine/odst/odst_uniform = allocate(/obj/item/clothing/under/marine/odst, run_loc_floor_top_right)

	TEST_ASSERT_NULL(human.hud_used, "Manual equip fallback test expected a fresh test human without a populated HUD datum.")
	TEST_ASSERT(human.has_limb_for_slot(WEAR_BODY), "Manual equip fallback test expected a fresh test human to report the body slot as limb-valid before equipping.")
	TEST_ASSERT(human.equip_to_slot_if_possible(odst_uniform, WEAR_BODY, 1, 0, 0, 0), "ODST manual uniform equip should succeed even when the human HUD slot cache is unavailable.")
	TEST_ASSERT_EQUAL(odst_uniform.loc, human, "ODST manual uniform equip should move the item into the human contents before asserting the wearable slot state.")
	TEST_ASSERT_EQUAL(human.w_uniform, odst_uniform, "ODST manual uniform equip should populate the direct human uniform slot var after the HUD-slot fallback.")
	TEST_ASSERT_EQUAL(human.get_item_by_slot(WEAR_BODY), odst_uniform, "ODST manual uniform equip did not populate the body slot after the HUD-slot fallback.")

/datum/unit_test/halo_ship_platoons/halo_species_restricted_clothing_contract/Run()
	var/mob/living/carbon/human/human = create_test_human("HALO Human Restriction", JOB_SQUAD_MARINE_ODST)
	var/mob/living/carbon/human/sangheili = create_test_human("HALO Sangheili Restriction", JOB_SQUAD_MARINE)
	var/obj/item/clothing/head/helmet/marine/sangheili/minor/sangheili_helmet = allocate(/obj/item/clothing/head/helmet/marine/sangheili/minor, run_loc_floor_top_right)

	human.create_hud()
	sangheili.create_hud()
	sangheili.set_species(SPECIES_SANGHEILI)

	TEST_ASSERT(!sangheili_helmet.mob_can_equip(human, WEAR_HEAD, TRUE), "Species-restricted Sangheili clothing unexpectedly allowed a human wearer after the HALO clothing compat change.")
	TEST_ASSERT(sangheili_helmet.mob_can_equip(sangheili, WEAR_HEAD, TRUE), "Species-restricted Sangheili clothing no longer allows the intended Sangheili wearer after the HALO clothing compat change.")

// SS220 EDIT - START: cover HALO medic routing/vendor access and player-side locker claims
/datum/unit_test/halo_ship_platoons_halo_medic_fireteam_assignment
	parent_type = /datum/unit_test/halo_integration_test

/datum/unit_test/halo_ship_platoons_halo_medic_fireteam_assignment/Run()
	configure_test_ship_platoon(/datum/squad/marine/halo/unsc/alpha)

	var/datum/squad/alpha_squad = GLOB.RoleAuthority?.squads_by_type[/datum/squad/marine/halo/unsc/alpha]
	TEST_ASSERT_NOTNULL(alpha_squad, "Failed to resolve the HALO UNSC Alpha squad for medic routing testing.")

	var/mob/living/carbon/human/medic_one = create_test_human("HALO Medic One", JOB_SQUAD_MEDIC_UNSC)
	arm_equipment(medic_one, /datum/equipment_preset/unsc/medic, FALSE, TRUE)
	var/obj/item/card/id/medic_one_id = medic_one.get_idcard()
	TEST_ASSERT_NOTNULL(medic_one_id, "Failed to prepare an ID card for the first HALO medic routing test.")
	TEST_ASSERT(alpha_squad.put_marine_in_squad(medic_one, medic_one_id), "Failed to place the first HALO medic into the squad for routing testing.")
	TEST_ASSERT_EQUAL(medic_one.assigned_fireteam, "SQ1", "The first HALO medic was not assigned to SQ1.")
	TEST_ASSERT(medic_one_id.access.Find(alpha_squad.squad_one_access), "The first HALO medic did not receive SQ1 access.")

	var/mob/living/carbon/human/medic_two = create_test_human("HALO Medic Two", JOB_SQUAD_MEDIC_UNSC)
	arm_equipment(medic_two, /datum/equipment_preset/unsc/medic, FALSE, TRUE)
	var/obj/item/card/id/medic_two_id = medic_two.get_idcard()
	TEST_ASSERT_NOTNULL(medic_two_id, "Failed to prepare an ID card for the second HALO medic routing test.")
	TEST_ASSERT(alpha_squad.put_marine_in_squad(medic_two, medic_two_id), "Failed to place the second HALO medic into the squad for routing testing.")
	TEST_ASSERT_EQUAL(medic_two.assigned_fireteam, "SQ2", "The second HALO medic was not assigned to SQ2.")
	TEST_ASSERT(medic_two_id.access.Find(alpha_squad.squad_two_access), "The second HALO medic did not receive SQ2 access.")

/datum/unit_test/halo_ship_platoons_halo_medic_vendor_roles
	parent_type = /datum/unit_test/halo_integration_test

/datum/unit_test/halo_ship_platoons_halo_medic_vendor_roles/Run()
	configure_test_ship_platoon(/datum/squad/marine/halo/unsc/alpha)

	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	TEST_ASSERT_NOTNULL(role_authority, "RoleAuthority was unavailable for HALO medic vendor routing testing.")

	var/obj/structure/machinery/cm_vending/clothing/medic/unsc/clothing_vendor = allocate(/obj/structure/machinery/cm_vending/clothing/medic/unsc, run_loc_floor_top_right)
	var/obj/structure/machinery/cm_vending/gear/medic_chemical/unsc/chemical_vendor = allocate(/obj/structure/machinery/cm_vending/gear/medic_chemical/unsc, run_loc_floor_top_right)

	TEST_ASSERT(clothing_vendor.vendor_role.Find(JOB_SQUAD_MEDIC), "HALO medic clothing vendor lost base medic access.")
	TEST_ASSERT(clothing_vendor.vendor_role.Find(JOB_SQUAD_MEDIC_UNSC), "HALO medic clothing vendor does not accept UNSC corpsmen.")
	TEST_ASSERT(clothing_vendor.vendor_role.Find(JOB_SQUAD_MEDIC_ODST), "HALO medic clothing vendor does not accept ODST corpsmen.")

	TEST_ASSERT(chemical_vendor.vendor_role.Find(JOB_SQUAD_MEDIC), "HALO medic chemical vendor lost base medic access.")
	TEST_ASSERT(chemical_vendor.vendor_role.Find(JOB_SQUAD_MEDIC_UNSC), "HALO medic chemical vendor does not accept UNSC corpsmen.")
	TEST_ASSERT(chemical_vendor.vendor_role.Find(JOB_SQUAD_MEDIC_ODST), "HALO medic chemical vendor does not accept ODST corpsmen.")

	var/has_biofoam = FALSE
	for(var/list/entry as anything in GLOB.cm_vending_chemical_medic_halo)
		if(entry[1] == "halo medical bottle (biofoam)" && entry[3] == /obj/item/reagent_container/glass/beaker/unsc/biofoam)
			has_biofoam = TRUE
			break

	TEST_ASSERT(has_biofoam, "HALO medic chemical vendor list no longer includes a biofoam medical bottle.")

	var/obj/structure/machinery/cm_vending/sorted/medical/marinemed/source_medical_vendor = track_test_atom(allocate(/obj/structure/machinery/cm_vending/sorted/medical/marinemed, run_loc_floor_top_right))
	TEST_ASSERT_NOTNULL(source_medical_vendor, "Failed to allocate the source medbay vendor for HALO ship-surface replacement testing.")

	var/unsc_family = role_authority.get_ship_surface_family(/datum/squad/marine/halo/unsc/alpha)
	TEST_ASSERT_NOTNULL(unsc_family, "Failed to resolve the HALO UNSC ship-surface family key for medbay vendor replacement testing.")

	var/obj/structure/machinery/cm_vending/sorted/medical/unsc/medical_vendor = role_authority.replace_ship_surface_fixture(source_medical_vendor, unsc_family)
	track_test_atom(medical_vendor)
	TEST_ASSERT_NOTNULL(medical_vendor, "HALO medbay vendor replacement did not produce a UNSC target vendor.")
	TEST_ASSERT_EQUAL(medical_vendor.type, /obj/structure/machinery/cm_vending/sorted/medical/unsc, "Marine medbay vendor did not swap into the HALO UNSC medbay vendor.")
	TEST_ASSERT(length(medical_vendor.listed_products) > 0, "HALO UNSC medical vendor replacement initialized with an empty product list.")

	var/has_syringe = FALSE
	for(var/list/entry as anything in medical_vendor.listed_products)
		if(length(entry) >= 3 && entry[3] == /obj/item/reagent_container/syringe/halo)
			has_syringe = TRUE
			break

	TEST_ASSERT(has_syringe, "HALO UNSC medical vendor lost its syringe stock after zero-scale normalization.")

/datum/unit_test/halo_ship_platoons_halo_job_locker_claims
	parent_type = /datum/unit_test/halo_integration_test

/datum/unit_test/halo_ship_platoons_halo_job_locker_claims/Run()
	var/mob/living/carbon/human/spec = create_test_human("HALO Locker Spec", JOB_SQUAD_SPECIALIST_UNSC)
	spec.mind = new /datum/mind("halo_locker_spec", "halo_locker_spec")
	var/obj/item/card/id/spec_id = allocate(/obj/item/card/id)
	spec_id.access = list(ACCESS_MARINE_SPECPREP, ACCESS_SQUAD_ONE)
	spec.equip_to_slot(spec_id, WEAR_ID, TRUE)

	TEST_ASSERT(spec.claim_halo_job_locker(), "Failed to claim the HALO job locker on the player side.")
	TEST_ASSERT(spec.has_claimed_halo_job_locker(), "Player-side HALO job locker claim was not persisted.")
	TEST_ASSERT(spec.get_halo_job_locker_claim_holder() == spec.mind, "HALO job locker claim was not stored on the mind when a mind was available.")

	var/obj/structure/closet/secure_closet/halo/job_locker/weapons_spec/locker = allocate(/obj/structure/closet/secure_closet/halo/job_locker/weapons_spec/ft1, run_loc_floor_top_right)
	var/contents_before = length(locker.contents)
	locker.togglelock(spec)
	TEST_ASSERT_EQUAL(length(locker.contents), contents_before, "A claimed HALO player was still able to trigger a second HALO job locker.")

	var/mob/living/carbon/human/fallback_spec = create_test_human("HALO Locker Fallback Spec", JOB_SQUAD_SPECIALIST_UNSC)
	fallback_spec.mind = null
	var/obj/item/card/id/fallback_id = allocate(/obj/item/card/id)
	fallback_id.access = list(ACCESS_MARINE_SPECPREP)
	fallback_spec.equip_to_slot(fallback_id, WEAR_ID, TRUE)

	TEST_ASSERT(fallback_spec.claim_halo_job_locker(), "Failed to claim the HALO job locker on the mob fallback path.")
	TEST_ASSERT(fallback_spec.has_claimed_halo_job_locker(), "Mob fallback HALO job locker claim was not persisted.")
	TEST_ASSERT(fallback_spec.get_halo_job_locker_claim_holder() == fallback_spec, "HALO job locker fallback claim was not stored on the mob when no mind was available.")

/datum/unit_test/halo_ship_platoons_halo_job_locker_owner_binding
	parent_type = /datum/unit_test/halo_integration_test

/datum/unit_test/halo_ship_platoons_halo_job_locker_owner_binding/Run()
	var/mob/living/carbon/human/spec_one = create_test_human("HALO Locker Spec One", JOB_SQUAD_SPECIALIST_UNSC)
	spec_one.mind = new /datum/mind("halo_locker_spec_one", "halo_locker_spec_one")
	var/obj/item/card/id/spec_one_id = allocate(/obj/item/card/id)
	spec_one_id.access = list(ACCESS_MARINE_SPECPREP, ACCESS_SQUAD_ONE)
	spec_one.equip_to_slot(spec_one_id, WEAR_ID, TRUE)

	var/obj/structure/closet/secure_closet/halo/job_locker/weapons_spec/ft1/locker_one = allocate(/obj/structure/closet/secure_closet/halo/job_locker/weapons_spec/ft1, run_loc_floor_top_right)
	TEST_ASSERT(locker_one.claim_selected_kit(spec_one, /obj/item/storage/unsc_speckit/spnkr), "Failed to bind a HALO specialist locker to the first specialist.")
	TEST_ASSERT(spec_one.has_claimed_halo_job_locker(), "Claiming a HALO specialist locker did not persist the first specialist claim.")
	TEST_ASSERT(locker_one.get_claim_holder() == spec_one.mind, "The first specialist locker was not bound to the claimant's mind.")
	TEST_ASSERT(locate(/obj/item/storage/unsc_speckit/spnkr) in get_turf(locker_one), "The selected HALO specialist kit was not dumped onto the locker turf after the locker auto-opened.")
	TEST_ASSERT(!locker_one.locked, "Claiming a HALO specialist locker should auto-unlock it.")
	TEST_ASSERT(locker_one.opened, "Claiming a HALO specialist locker should auto-open it.")

	var/mob/living/carbon/human/spec_two = create_test_human("HALO Locker Spec Two", JOB_SQUAD_SPECIALIST_UNSC)
	spec_two.mind = new /datum/mind("halo_locker_spec_two", "halo_locker_spec_two")
	var/obj/item/card/id/spec_two_id = allocate(/obj/item/card/id)
	spec_two_id.access = list(ACCESS_MARINE_SPECPREP, ACCESS_SQUAD_ONE, ACCESS_SQUAD_TWO)
	spec_two.equip_to_slot(spec_two_id, WEAR_ID, TRUE)

	locker_one.attack_hand(spec_two)
	TEST_ASSERT(locker_one.opened, "A second specialist was able to close another player's claimed HALO locker.")

	var/obj/structure/closet/secure_closet/halo/job_locker/weapons_spec/ft2/locker_two = allocate(/obj/structure/closet/secure_closet/halo/job_locker/weapons_spec/ft2, run_loc_floor_top_right)
	TEST_ASSERT(locker_two.claim_selected_kit(spec_two, /obj/item/storage/unsc_speckit/srs99), "A second specialist could not claim their own HALO locker after the first specialist claimed a different one.")
	TEST_ASSERT(spec_two.has_claimed_halo_job_locker(), "The second specialist claim was not persisted on their own HALO locker.")

/datum/unit_test/halo_ship_platoons/halo_squad_armory_button_access
	parent_type = /datum/unit_test/halo_integration_test

/datum/unit_test/halo_ship_platoons/halo_squad_armory_button_access/Run()
	configure_test_ship_platoon(/datum/squad/marine/halo/unsc/alpha)

	var/obj/structure/machinery/door_control/squad_armory/bravo/button = allocate(/obj/structure/machinery/door_control/squad_armory/bravo, run_loc_floor_top_right)
	TEST_ASSERT_NOTNULL(button, "Failed to allocate the HALO squad armory button for access testing.")

	var/datum/squad/bravo_squad = button.get_target_squad()
	TEST_ASSERT_NOTNULL(bravo_squad, "The HALO squad armory button did not resolve its Bravo squad target.")
	bravo_squad.usable = TRUE

	var/mob/living/carbon/human/so_human = create_test_human("HALO Armory SO", JOB_SO_UNSC)
	TEST_ASSERT(button.allowed(so_human), "A HALO platoon commander should be allowed to open an available squad armory button.")

	var/mob/living/carbon/human/bravo_leader = create_test_human("HALO Bravo Leader", JOB_SQUAD_LEADER_UNSC, /datum/squad/marine/halo/unsc/bravo)
	TEST_ASSERT(button.allowed(bravo_leader), "The matching HALO squad leader should be allowed to open their squad armory button.")

	var/mob/living/carbon/human/alpha_leader = create_test_human("HALO Alpha Leader", JOB_SQUAD_LEADER_UNSC, /datum/squad/marine/halo/unsc/alpha)
	TEST_ASSERT(!button.allowed(alpha_leader), "A different HALO squad leader should not be allowed to open another squad's armory button.")

	bravo_squad.usable = FALSE

	var/mob/living/carbon/human/captain_human = create_test_human("HALO Armory Captain", JOB_CO)
	var/obj/item/card/id/captain_id = allocate(/obj/item/card/id)
	captain_id.access = list(ACCESS_MARINE_CO)
	captain_human.equip_to_slot(captain_id, WEAR_ID, TRUE)
	var/mob/living/carbon/human/colonel_human = create_test_human("HALO Armory Colonel", JOB_COLONEL)

	TEST_ASSERT(button.allowed(captain_human), "Captain access should be able to open an unavailable squad armory button.")
	TEST_ASSERT(button.allowed(colonel_human), "A high-command role above the commanding officer should be able to open an unavailable squad armory button.")
	TEST_ASSERT(!button.allowed(so_human), "A HALO platoon commander should not bypass the captain-only fallback on an unavailable squad armory button.")
	TEST_ASSERT(!button.allowed(bravo_leader), "A HALO squad leader should not bypass the captain-only fallback on an unavailable squad armory button.")

/datum/unit_test/halo_ship_platoons/halo_platoon_commander_lockers_include_command_uniform
	parent_type = /datum/unit_test/halo_integration_test

/datum/unit_test/halo_ship_platoons/halo_platoon_commander_lockers_include_command_uniform/Run()
	var/obj/structure/closet/secure_closet/marine_personal/unsc/platoon_commander/unsc_locker = allocate(/obj/structure/closet/secure_closet/marine_personal/unsc/platoon_commander, run_loc_floor_top_right)
	var/obj/structure/closet/secure_closet/marine_personal/odst/platoon_commander/odst_locker = allocate(/obj/structure/closet/secure_closet/marine_personal/odst/platoon_commander, run_loc_floor_bottom_left)

	TEST_ASSERT_EQUAL(count_personal_locker_contents_by_exact_type(unsc_locker, /obj/item/clothing/under/marine/crew/command), 1, "The UNSC platoon commander locker should contain the HALO command uniform.")
	TEST_ASSERT_EQUAL(count_personal_locker_contents_by_exact_type(odst_locker, /obj/item/clothing/under/marine/crew/command), 1, "The ODST platoon commander locker should contain the HALO command uniform.")

/datum/unit_test/halo_ship_platoons/halo_unsc_crew_headsets_and_access
	parent_type = /datum/unit_test/halo_integration_test

/datum/unit_test/halo_ship_platoons/halo_unsc_crew_headsets_and_access/Run()
	configure_test_ship_platoon(/datum/squad/marine/halo/unsc/alpha)

	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	TEST_ASSERT_NOTNULL(role_authority, "RoleAuthority was unavailable for HALO shipboard headset testing.")
	var/datum/equipment_preset/unsc_crew/generic/crew_preset = new
	var/datum/equipment_preset/unsc_crew/command/xo/cpt/captain_preset = new
	var/datum/equipment_preset/unsc_crew/flight/officer/flight_preset = new
	var/crew_title = crew_preset.assignment || crew_preset.rank
	var/captain_title = captain_preset.assignment || captain_preset.rank
	var/flight_title = flight_preset.assignment || flight_preset.rank
	var/crew_headset_type = /obj/item/device/radio/headset/almayer/marine/solardevils/unsc/crew
	var/unsc_command_headset_type = /obj/item/device/radio/headset/almayer/marine/solardevils/unsc/command
	var/odst_command_headset_type = /obj/item/device/radio/headset/almayer/marine/solardevils/unsc/command/odst
	var/main_platoon_channel = GLOB.main_platoon_name
	TEST_ASSERT_NOTNULL(main_platoon_channel, "HALO shipboard headset test could not resolve the active platoon channel label.")

	TEST_ASSERT_EQUAL(role_authority.get_active_halo_shipboard_headset_type(crew_title), crew_headset_type, "HALO UNSC crew roles no longer resolve to the shared crew headset type.")
	TEST_ASSERT_EQUAL(role_authority.get_active_halo_shipboard_headset_type(captain_title), unsc_command_headset_type, "HALO UNSC command roles no longer resolve to the shared command headset type.")

	var/mob/living/carbon/human/crewman = create_test_human("HALO UNSC Crewman", crew_title)
	arm_equipment(crewman, /datum/equipment_preset/unsc_crew/generic, FALSE, TRUE)
	var/obj/item/device/radio/headset/crew_headset = crewman.get_type_in_ears(/obj/item/device/radio/headset)
	TEST_ASSERT(istype(crew_headset, crew_headset_type), "HALO UNSC crewman did not receive the crew headset variant with squad channels.")
	TEST_ASSERT(crew_headset.channels[main_platoon_channel], "HALO UNSC crewman headset does not expose the active platoon channel.")
	TEST_ASSERT_EQUAL(crew_headset.frequency, 1501, "HALO UNSC crewman headset lost the expected UNSC shipboard frequency.")

	var/mob/living/carbon/human/captain = create_test_human("HALO UNSC Captain", captain_title)
	arm_equipment(captain, /datum/equipment_preset/unsc_crew/command/xo/cpt, FALSE, TRUE)
	var/obj/item/device/radio/headset/captain_headset = captain.get_type_in_ears(/obj/item/device/radio/headset)
	var/obj/item/card/id/captain_id = captain.get_idcard()
	TEST_ASSERT(istype(captain_headset, unsc_command_headset_type), "HALO UNSC captain did not receive the command-capable crew headset variant.")
	TEST_ASSERT(captain_headset.channels[main_platoon_channel], "HALO UNSC captain headset does not expose the active platoon channel.")
	TEST_ASSERT(captain_headset.channels[RADIO_CHANNEL_COMMAND], "HALO UNSC captain headset lost command channel access.")
	TEST_ASSERT(captain_id?.access.Find(ACCESS_MARINE_CO), "HALO UNSC captain lost ACCESS_MARINE_CO.")
	TEST_ASSERT(captain_id?.access.Find(ACCESS_MARINE_DROPSHIP), "HALO UNSC captain lost dropship/weapons access.")

	var/mob/living/carbon/human/flight_officer = create_test_human("HALO UNSC Flight Officer", flight_title)
	arm_equipment(flight_officer, /datum/equipment_preset/unsc_crew/flight/officer, FALSE, TRUE)
	var/obj/item/device/radio/headset/flight_headset = flight_officer.get_type_in_ears(/obj/item/device/radio/headset)
	var/obj/item/card/id/flight_id = flight_officer.get_idcard()
	TEST_ASSERT(istype(flight_headset, unsc_command_headset_type), "HALO UNSC flight officer did not receive the command-capable crew headset variant.")
	TEST_ASSERT(flight_headset.channels[main_platoon_channel], "HALO UNSC flight officer headset does not expose the active platoon channel.")
	TEST_ASSERT(flight_id?.access.Find(ACCESS_MARINE_DROPSHIP), "HALO UNSC flight officer lost dropship access.")

	configure_test_ship_platoon(/datum/squad/marine/halo/odst/alpha)
	TEST_ASSERT_EQUAL(role_authority.get_active_halo_shipboard_headset_type(captain_title), odst_command_headset_type, "HALO ODST command roles no longer resolve to the shared ODST command headset type.")

	var/mob/living/carbon/human/odst_captain = create_test_human("HALO ODST Captain", captain_title)
	arm_equipment(odst_captain, /datum/equipment_preset/unsc_crew/command/xo/cpt, FALSE, TRUE)
	var/obj/item/device/radio/headset/odst_headset = odst_captain.get_type_in_ears(/obj/item/device/radio/headset)
	TEST_ASSERT(istype(odst_headset, odst_command_headset_type), "HALO ODST ship profile did not swap shipboard command headset to the ODST variant.")
	TEST_ASSERT_EQUAL(odst_headset.frequency, 1503, "HALO ODST ship profile did not keep the expected ODST shipboard frequency.")

/datum/unit_test/halo_ship_platoons/zombie_species_transition_restores_intrinsics
	parent_type = /datum/unit_test/halo_integration_test

/datum/unit_test/halo_ship_platoons/zombie_species_transition_restores_intrinsics/Run()
	var/mob/living/carbon/human/zombie = create_test_human("HALO Zombie Spawn", JOB_SQUAD_MARINE)

	var/obj/item/clothing/head/helmet/marine/helmet = allocate(/obj/item/clothing/head/helmet/marine, run_loc_floor_top_right)
	var/obj/item/clothing/gloves/marine/gloves = allocate(/obj/item/clothing/gloves/marine, run_loc_floor_top_right)
	var/obj/item/clothing/glasses/sunglasses/sunglasses = allocate(/obj/item/clothing/glasses/sunglasses, run_loc_floor_top_right)
	var/obj/item/clothing/mask/gas/mask = allocate(/obj/item/clothing/mask/gas, run_loc_floor_top_right)

	zombie.equip_to_slot_or_del(helmet, WEAR_HEAD, TRUE)
	zombie.equip_to_slot_or_del(gloves, WEAR_HANDS, TRUE)
	zombie.equip_to_slot_or_del(sunglasses, WEAR_EYES, TRUE)
	zombie.equip_to_slot_or_del(mask, WEAR_FACE, TRUE)

	zombie.strip_weapons()
	qdel(zombie.gloves)
	if(zombie.glasses && !istype(zombie.glasses, /obj/item/clothing/glasses/zombie_eyes))
		qdel(zombie.glasses)
	qdel(zombie.wear_mask)
	zombie.set_species(SPECIES_ZOMBIE)

	TEST_ASSERT(istype(zombie.l_hand, /obj/item/weapon/zombie_claws), "Zombie species transition no longer restores the intrinsic left claw.")
	TEST_ASSERT(istype(zombie.r_hand, /obj/item/weapon/zombie_claws), "Zombie species transition no longer restores the intrinsic right claw.")
	TEST_ASSERT_EQUAL(zombie.r_hand.icon_state, "claw_r", "Zombie species transition no longer restores the right claw icon state.")
	TEST_ASSERT(istype(zombie.glasses, /obj/item/clothing/glasses/zombie_eyes), "Zombie species transition no longer restores zombie eyes after stripping eyewear.")
	TEST_ASSERT_NULL(zombie.gloves, "Zombie species transition should strip gloves from the resulting zombie.")
	TEST_ASSERT_NULL(zombie.wear_mask, "Zombie species transition should strip masks from the resulting zombie.")
