/datum/unit_test/halo_ship_platoons
	var/next_ship_exists = FALSE
	var/next_ship_snapshot = null
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
	var/list/tracked_test_humans = null
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

/datum/unit_test/halo_ship_platoons/Run()
	return

/datum/unit_test/halo_ship_platoons/New()
	. = ..()

	next_ship_exists = fexists("data/next_ship.json")
	if(next_ship_exists)
		next_ship_snapshot = file2text("data/next_ship.json")

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
	tracked_test_humans = list()
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

/datum/unit_test/halo_ship_platoons/proc/cleanup_test_human_runtime_state(mob/living/carbon/human/human)
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

/datum/unit_test/halo_ship_platoons/Destroy()
	for(var/mob/living/carbon/human/human as anything in tracked_test_humans)
		if(!QDELETED(human))
			cleanup_test_human_runtime_state(human)

	for(var/mob/living/carbon/human/human as anything in tracked_test_humans)
		if(!QDELETED(human))
			qdel(human)

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

	if(next_ship_exists)
		rustg_file_write(next_ship_snapshot || "", "data/next_ship.json")
	else
		fdel("data/next_ship.json")

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

	tracked_test_humans = null
	tracked_test_squads = null
	tracked_test_atoms = null
	snapshot_squads = null
	snapshot_squads_by_type = null

	return ..()

/datum/unit_test/halo_ship_platoons/proc/isolate_personal_lockers(obj/structure/closet/secure_closet/marine_personal/locker)
	GLOB.personal_closets = locker ? list(locker) : list()

/datum/unit_test/halo_ship_platoons/proc/track_test_atom(atom/tracked_atom)
	if(tracked_atom && !(tracked_atom in tracked_test_atoms))
		tracked_test_atoms += tracked_atom
	return tracked_atom

/datum/unit_test/halo_ship_platoons/proc/configure_test_human(mob/living/carbon/human/human, real_name, job_title, squad_type = null, key_name = null)
	if(human && !(human in tracked_test_humans))
		tracked_test_humans += human
	human.real_name = real_name
	human.name = real_name
	human.job = job_title
	if(squad_type)
		human.assigned_squad = GLOB.RoleAuthority?.squads_by_type[squad_type]
		if(!human.assigned_squad && ispath(squad_type, /datum/squad))
			human.assigned_squad = allocate(squad_type)
	if(key_name)
		human.key = key_name

/datum/unit_test/halo_ship_platoons/proc/prepare_test_human_for_squad(mob/living/carbon/human/human, preset_type = /datum/equipment_preset, preset_assignment = null)
	var/datum/equipment_preset/preset = allocate(preset_type)
	preset.assignment = preset_assignment ? preset_assignment : human.job
	human.assigned_equipment_preset = preset

	var/obj/item/card/id/id = allocate(/obj/item/card/id)
	id.registered_name = human.real_name
	id.access = preset.access ? preset.access.Copy() : list()
	human.equip_to_slot(id, WEAR_ID, TRUE)

	return human.get_idcard()

/datum/unit_test/halo_ship_platoons/proc/configure_test_ship_platoon(platoon_type)
	var/datum/map_config/ship_config = SSmapping?.configs?[SHIP_MAP]
	TEST_ASSERT_NOTNULL(ship_config, "Failed to resolve ship config for platoon test setup.")
	ship_config.platoon = "[platoon_type]"

	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	TEST_ASSERT_NOTNULL(role_authority, "RoleAuthority was unavailable for platoon test setup.")

	var/list/squad_types = typesof(/datum/squad) - /datum/squad
	role_authority.squads = list()
	role_authority.squads_by_type = list()
	for(var/squad_type in squad_types)
		var/datum/squad/squad = new squad_type()
		role_authority.squads += squad
		role_authority.squads_by_type[squad.type] = squad
		tracked_test_squads += squad

/datum/unit_test/halo_ship_platoons/proc/clear_personal_locker_contents(obj/structure/closet/secure_closet/marine_personal/locker)
	for(var/atom/movable/movable as anything in locker.contents)
		movable.forceMove(run_loc_floor_top_right)

/datum/unit_test/halo_ship_platoons/proc/count_personal_locker_contents_by_type(obj/structure/closet/secure_closet/marine_personal/locker, content_type)
	. = 0
	if(!locker || !content_type)
		return

	for(var/atom/movable/movable as anything in locker.contents)
		if(istype(movable, content_type))
			.++

/datum/unit_test/halo_ship_platoons/proc/count_personal_locker_contents_by_exact_type(obj/structure/closet/secure_closet/marine_personal/locker, content_type)
	. = 0
	if(!locker || !content_type)
		return

	for(var/atom/movable/movable as anything in locker.contents)
		if(movable.type == content_type)
			.++

/datum/unit_test/halo_ship_platoons/proc/count_turf_contents_by_exact_type(turf/content_turf, content_type)
	. = 0
	if(!content_turf || !content_type)
		return

	for(var/atom/movable/movable as anything in content_turf)
		if(movable.type == content_type)
			.++
// SS220 EDIT - START - locker replacement fixtures need an optional adjacent floor for linked spawn turf assertions
/datum/unit_test/halo_ship_platoons/proc/get_adjacent_floor_turf(turf/center_turf)
	if(!isfloorturf(center_turf))
		return null

	for(var/cardinal_dir in GLOB.cardinals)
		var/turf/candidate_turf = get_step(center_turf, cardinal_dir)
		if(isfloorturf(candidate_turf))
			return candidate_turf

	return null

/datum/unit_test/halo_ship_platoons/proc/get_mainship_test_turf(require_adjacent_floor = FALSE)
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
// SS220 EDIT - END
/datum/unit_test/halo_ship_platoons/proc/assert_halo_randomize_assigns_squad(real_name, job_title, preset_path, expected_squad_family)
	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	var/list/profile = role_authority?.get_ship_platoon_profile(expected_squad_family)
	var/list/expected_family_types = islist(profile?["family_types"]) ? profile["family_types"] : list(expected_squad_family)

	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	configure_test_human(human, real_name, job_title)
	arm_equipment(human, preset_path, FALSE, TRUE)
	role_authority.randomize_squad(human, TRUE)

	TEST_ASSERT_NOTNULL(human.assigned_squad, "[real_name] did not receive a squad assignment.")
	TEST_ASSERT(expected_family_types.Find(human.assigned_squad.type), "[real_name] joined [human.assigned_squad?.type] instead of one of the expected HALO squad types [english_list(expected_family_types)].")

	var/datum/squad/assigned_squad = human.assigned_squad
	assigned_squad.remove_marine_from_squad(human, human.get_idcard())

/datum/unit_test/halo_ship_platoons/proc/assert_halo_preview_preset_equips_job_gear(real_name, preview_role_title)
	var/preset_type = GLOB.RoleAuthority?.get_modular_job_pref_to_gear_preset(preview_role_title)

	TEST_ASSERT_NOTNULL(preset_type, "[real_name] did not resolve a HALO preview preset through the modular preview helper.")

	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	configure_test_human(human, real_name, preview_role_title)
	arm_equipment(human, preset_type, FALSE, FALSE, null, TRUE)

	TEST_ASSERT_NOTNULL(human.get_item_by_slot(WEAR_BODY), "[real_name] preview mannequin lost the equipped uniform/body slot.")
	TEST_ASSERT_NOTNULL(human.get_item_by_slot(WEAR_L_EAR), "[real_name] preview mannequin lost the equipped headset slot.")

/datum/unit_test/halo_ship_platoons/proc/assert_halo_odst_preview_visual_core(real_name, preview_role_title)
	var/preset_type = GLOB.RoleAuthority?.get_modular_job_pref_to_gear_preset(preview_role_title)

	TEST_ASSERT_NOTNULL(preset_type, "[real_name] did not resolve an ODST HALO preview preset through the modular preview helper.")

	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	configure_test_human(human, real_name, preview_role_title)
	arm_equipment(human, preset_type, FALSE, FALSE, null, TRUE)

	TEST_ASSERT(istype(human.get_item_by_slot(WEAR_L_EAR), /obj/item/device/radio/headset/almayer/marine/solardevils/unsc/odst), "[real_name] preview mannequin did not use the ODST headset.")
	TEST_ASSERT(istype(human.get_item_by_slot(WEAR_HEAD), /obj/item/clothing/head/helmet/marine/unsc/odst), "[real_name] preview mannequin did not use the ODST helmet.")
	TEST_ASSERT(istype(human.get_item_by_slot(WEAR_BODY), /obj/item/clothing/under/marine/odst), "[real_name] preview mannequin did not use the ODST uniform.")
	TEST_ASSERT(istype(human.get_item_by_slot(WEAR_JACKET), /obj/item/clothing/suit/marine/unsc/odst), "[real_name] preview mannequin did not use the ODST armor.")

/datum/unit_test/halo_ship_platoons/proc/assert_halo_odst_platoon_commander_preview_officer_core(real_name, preview_role_title)
	var/preset_type = GLOB.RoleAuthority?.get_modular_job_pref_to_gear_preset(preview_role_title)

	TEST_ASSERT_NOTNULL(preset_type, "[real_name] did not resolve an ODST Platoon Commander preview preset through the modular preview helper.")

	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	configure_test_human(human, real_name, preview_role_title)
	arm_equipment(human, preset_type, FALSE, FALSE, null, TRUE)

	TEST_ASSERT(istype(human.get_item_by_slot(WEAR_L_EAR), /obj/item/device/radio/headset/almayer/marine/solardevils/unsc/odst), "[real_name] preview mannequin did not use the ODST headset.")
	TEST_ASSERT(istype(human.get_item_by_slot(WEAR_HEAD), /obj/item/clothing/head/cmcap), "[real_name] preview mannequin did not use the UNSC officer cap.")
	TEST_ASSERT(istype(human.get_item_by_slot(WEAR_BODY), /obj/item/clothing/under/marine/standard), "[real_name] preview mannequin did not use the UNSC officer uniform.")
	TEST_ASSERT(istype(human.get_item_by_slot(WEAR_JACKET), /obj/item/clothing/suit/marine/unsc), "[real_name] preview mannequin did not use the UNSC officer jacket.")

/datum/unit_test/halo_ship_platoons/proc/assert_halo_specialist_assignment_loadout(real_name, preset_path, expected_role_title, expected_squad_family)
	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	var/list/profile = role_authority?.get_ship_platoon_profile(expected_squad_family)
	var/list/expected_family_types = islist(profile?["family_types"]) ? profile["family_types"] : list(expected_squad_family)

	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	configure_test_human(human, real_name, expected_role_title)
	arm_equipment(human, preset_path, FALSE, TRUE)
	role_authority.randomize_squad(human, TRUE)

	var/obj/item/card/id/id = human.get_idcard()
	TEST_ASSERT_EQUAL(human.assigned_equipment_preset?.type, preset_path, "[real_name] did not keep the expected HALO specialist preset.")
	TEST_ASSERT_EQUAL(human.faction, FACTION_UNSC, "[real_name] no longer keeps FACTION_UNSC after HALO specialist equipping.")
	TEST_ASSERT_EQUAL(human.job, expected_role_title, "[real_name] did not keep the expected HALO specialist job.")
	TEST_ASSERT_EQUAL(human.title, expected_role_title, "[real_name] did not keep the expected HALO specialist title.")
	TEST_ASSERT_NOTNULL(id, "[real_name] did not receive an ID card from the HALO specialist preset.")
	TEST_ASSERT_EQUAL(id?.rank, expected_role_title, "[real_name] did not keep the expected HALO specialist rank on the ID metadata.")
	TEST_ASSERT_EQUAL(id?.assignment, expected_role_title, "[real_name] did not keep the expected HALO specialist assignment on the ID metadata.")
	TEST_ASSERT_NULL(human.get_item_by_slot(WEAR_BODY), "[real_name] should keep the HALO specialist baseline naked, but still had a uniform equipped.")
	TEST_ASSERT_NULL(human.get_item_by_slot(WEAR_L_EAR), "[real_name] should keep the HALO specialist baseline naked, but still had a headset equipped.")
	TEST_ASSERT_NULL(human.get_item_by_slot(WEAR_HEAD), "[real_name] should keep the HALO specialist baseline naked, but still had a helmet equipped.")
	TEST_ASSERT_NULL(human.get_item_by_slot(WEAR_JACKET), "[real_name] should keep the HALO specialist baseline naked, but still had armor equipped.")
	TEST_ASSERT_NULL(human.get_item_by_slot(WEAR_BACK), "[real_name] should keep the HALO specialist baseline naked, but still had a back item equipped.")
	TEST_ASSERT_NULL(human.get_item_by_slot(WEAR_J_STORE), "[real_name] should keep the HALO specialist baseline naked, but still had a stored rifle equipped.")
	TEST_ASSERT_NOTNULL(human.assigned_squad, "[real_name] did not receive a squad assignment after HALO specialist randomization.")
	TEST_ASSERT(expected_family_types.Find(human.assigned_squad?.type), "[real_name] joined [human.assigned_squad?.type] instead of one of the expected HALO squad types [english_list(expected_family_types)].")

	var/datum/squad/assigned_squad = human.assigned_squad
	assigned_squad.remove_marine_from_squad(human, id)

/datum/unit_test/halo_ship_platoons/proc/cleanup_test_squad_membership(mob/living/carbon/human/human)
	if(!istype(human) || !human.assigned_squad)
		return

	human.assigned_squad.remove_marine_from_squad(human, human.get_idcard())

/datum/unit_test/halo_ship_platoons/proc/assert_halo_id_metadata(mob/living/carbon/human/human, expected_faction, expected_rank, expected_assignment)
	var/role_label = human?.real_name || expected_assignment || expected_rank || expected_faction
	var/obj/item/card/id/id = human?.get_idcard()
	TEST_ASSERT_NOTNULL(id, "[role_label] did not keep an ID card after the HALO flow.")
	TEST_ASSERT_EQUAL(id?.faction, expected_faction, "[role_label] did not keep the expected HALO ID faction.")
	TEST_ASSERT_EQUAL(id?.rank, expected_rank, "[role_label] did not keep the expected HALO ID rank.")
	TEST_ASSERT_EQUAL(id?.assignment, expected_assignment, "[role_label] did not keep the expected HALO ID assignment.")

/datum/unit_test/halo_ship_platoons/proc/assert_halo_final_state(mob/living/carbon/human/human, expected_job, expected_title, expected_faction, expected_preset_type = null, expected_squad_family_types = null)
	var/role_label = human?.real_name || expected_title || expected_job
	TEST_ASSERT_EQUAL(human?.job, expected_job, "[role_label] did not keep the expected HALO runtime job.")
	TEST_ASSERT_EQUAL(human?.title, expected_title, "[role_label] did not keep the expected HALO runtime title.")
	TEST_ASSERT_EQUAL(human?.faction, expected_faction, "[role_label] did not keep the expected HALO mob faction.")

	if(!isnull(expected_preset_type))
		TEST_ASSERT_NOTNULL(human?.assigned_equipment_preset, "[role_label] lost assigned_equipment_preset metadata during the HALO flow.")
		TEST_ASSERT_EQUAL(human?.assigned_equipment_preset?.type, expected_preset_type, "[role_label] did not keep the expected HALO preset identity.")

	assert_halo_id_metadata(human, expected_faction, expected_title, expected_title)

	var/obj/item/card/id/id = human?.get_idcard()
	var/list/preset_access = human?.assigned_equipment_preset?.access
	if(islist(preset_access))
		for(var/access_flag in preset_access)
			TEST_ASSERT(id?.access?.Find(access_flag), "[role_label] lost preset access [access_flag] on the HALO runtime ID metadata.")

	if(!isnull(expected_squad_family_types))
		var/list/family_types = islist(expected_squad_family_types) ? expected_squad_family_types : list(expected_squad_family_types)
		TEST_ASSERT_NOTNULL(human?.assigned_squad, "[role_label] did not receive a HALO squad assignment.")
		TEST_ASSERT(family_types.Find(human?.assigned_squad?.type), "[role_label] joined [human?.assigned_squad?.type] instead of one of the expected HALO squad types [english_list(family_types)].")

/datum/unit_test/halo_ship_platoons/proc/assert_halo_equipment_metadata(real_name, preset_path, expected_role_title)
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	configure_test_human(human, real_name, expected_role_title)
	arm_equipment(human, preset_path, FALSE, TRUE)

	TEST_ASSERT_EQUAL(human.assigned_equipment_preset?.type, preset_path, "[real_name] did not keep the expected HALO preset after arm_equipment().")
	TEST_ASSERT_EQUAL(human.faction, FACTION_UNSC, "[real_name] no longer keeps FACTION_UNSC after arm_equipment().")
	TEST_ASSERT_EQUAL(human.job, expected_role_title, "[real_name] did not keep the expected HALO runtime job after arm_equipment().")
	TEST_ASSERT_EQUAL(human.title, expected_role_title, "[real_name] did not keep the expected HALO runtime title after arm_equipment().")
	assert_halo_id_metadata(human, FACTION_UNSC, expected_role_title, expected_role_title)

/datum/unit_test/halo_ship_platoons/proc/assert_preview_preset_visualizes_loadout(job_title, expected_preview_preset_type, required_slots_or_items)
	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	TEST_ASSERT_NOTNULL(role_authority, "RoleAuthority was unavailable for HALO preview visual testing.")
	role_authority.refresh_main_ship_gamemode_roles()

	var/preview_bucket = role_authority.get_job_preference_bucket_key(job_title) || job_title
	var/datum/preferences/preferences = allocate(/datum/preferences)
	preferences.job_preference_list = list()
	preferences.job_preference_list[preview_bucket] = HIGH_PRIORITY

	var/preset_type = preferences.job_pref_to_gear_preset()
	TEST_ASSERT_EQUAL(preset_type, expected_preview_preset_type, "[job_title] preview preset did not resolve through the real preview helper path.")

	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	configure_test_human(human, "[job_title] Preview", job_title)
	arm_equipment(human, preset_type, FALSE, FALSE, null, TRUE)

	TEST_ASSERT(islist(required_slots_or_items) && length(required_slots_or_items), "[job_title] preview visual assertion requires at least one slot or item check.")
	for(var/required_entry as anything in required_slots_or_items)
		if(isnum(required_entry) || istext(required_entry))
			TEST_ASSERT_NOTNULL(human.get_item_by_slot(required_entry), "[job_title] preview mannequin was missing required slot [required_entry].")
			continue

		if(ispath(required_entry))
			var/found_item = FALSE
			for(var/obj/item/item as anything in human.contents)
				if(istype(item, required_entry))
					found_item = TRUE
					break
			TEST_ASSERT(found_item, "[job_title] preview mannequin was missing required item type [required_entry].")
			continue

		TEST_FAIL("[job_title] preview visual assertion encountered unsupported requirement [required_entry].")

/datum/unit_test/halo_ship_platoons/proc/assert_halo_medic_job_option(real_name, job_type, role_title, option_title, expected_preset, expected_squad_family)
	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	var/datum/job/job_datum = new job_type()
	var/list/job_options = job_datum?.job_options
	TEST_ASSERT_NOTNULL(job_datum, "[real_name] failed to instantiate the HALO medic job datum for option testing.")
	TEST_ASSERT(islist(job_options) && job_options[option_title], "[real_name] could not find the expected HALO medic option [option_title].")

	job_datum.handle_job_options(option_title)

	var/resolved_preset = job_datum.get_spawn_equip_preset(role_title, role_authority, expected_squad_family)
	TEST_ASSERT_EQUAL(resolved_preset, expected_preset, "[real_name] resolved to [resolved_preset] instead of the expected HALO medic preset [expected_preset].")
	var/list/vanilla_medic_presets = list(
		/datum/equipment_preset/uscm/medic,
		/datum/equipment_preset/uscm/medic/lance_corporal,
		/datum/equipment_preset/uscm/medic/pfc,
		/datum/equipment_preset/uscm/medic/private,
	)
	TEST_ASSERT(!(resolved_preset in vanilla_medic_presets), "[real_name] regressed back to an exact vanilla USCM medic preset through HALO rank-option handling.") // SS220 EDIT: exact-path check avoids false positives from HALO presets inheriting vanilla medic hooks

	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	configure_test_human(human, real_name, role_title)
	arm_equipment(human, resolved_preset, FALSE, TRUE)
	role_authority.randomize_squad(human, TRUE)

	assert_halo_final_state(human, role_title, role_title, FACTION_UNSC, resolved_preset, role_authority.get_halo_job_family_types(role_title))

// Layer 1: helper / mapping / guardrail contracts. These tests validate resolver and mapping behavior,
// not full runtime end-to-end correctness through roundstart, latejoin, cryo, or preview mannequin flows.
/datum/unit_test/halo_ship_platoons/proc/holder_has_overlay_state(image/holder, icon_state)
	if(!holder || !icon_state)
		return FALSE

	for(var/image/overlay as anything in holder.overlays)
		if(overlay.icon_state == icon_state)
			return TRUE

	return FALSE
/datum/unit_test/halo_ship_platoons_allowed_platoons_override
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_allowed_platoons_override/Run()
	var/datum/map_config/ship_config = load_map_config("maps/unsc_stalwart_frigate.json", maptype = SHIP_MAP)
	TEST_ASSERT_NOTNULL(ship_config, "Failed to load HALO ship config for allowed_platoons override test.")
	TEST_ASSERT(ship_config.MakeNextMap(SHIP_MAP, list("platoon" = "/datum/squad/marine/halo/odst/alpha")), "Failed to persist ship platoon override to data/next_ship.json.")

	var/datum/map_config/next_ship_config = load_map_config("data/next_ship.json", error_if_missing = FALSE, maptype = SHIP_MAP)
	TEST_ASSERT_NOTNULL(next_ship_config, "Failed to load generated next_ship.json after ship platoon override.")
	TEST_ASSERT_EQUAL(next_ship_config.platoon, "/datum/squad/marine/halo/odst/alpha", "Ship platoon override was not written to next_ship.json.")
	TEST_ASSERT(next_ship_config.allowed_platoons.Find("/datum/squad/marine/halo/unsc/alpha"), "Original allowed_platoons list lost the UNSC option after override.")
	TEST_ASSERT(next_ship_config.allowed_platoons.Find("/datum/squad/marine/halo/odst/alpha"), "Original allowed_platoons list lost the ODST option after override.")

/datum/unit_test/halo_ship_platoons_role_classification
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_role_classification/Run()
	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	TEST_ASSERT_NOTNULL(role_authority, "RoleAuthority was unavailable for HALO ship platoon role classification test.")
	var/datum/job/unsc_job = role_authority.roles_by_name[JOB_SQUAD_MARINE_UNSC]
	var/datum/job/odst_job = role_authority.roles_by_name[JOB_SQUAD_MARINE_ODST]
	var/datum/job/unsc_medic_job = role_authority.roles_by_name[JOB_SQUAD_MEDIC_UNSC]
	var/datum/job/odst_medic_job = role_authority.roles_by_name[JOB_SQUAD_MEDIC_ODST]
	TEST_ASSERT_EQUAL(unsc_job?.type, /datum/job/marine/standard/ai/halo/unsc, "UNSC marine title did not resolve to the preferred HALO job path.")
	TEST_ASSERT_EQUAL(odst_job?.type, /datum/job/marine/standard/ai/halo/odst, "ODST marine title did not resolve to the preferred HALO job path.")
	TEST_ASSERT_EQUAL(unsc_medic_job?.type, /datum/job/marine/medic/ai/halo/unsc, "UNSC corpsman title did not resolve to the preferred HALO medic job path.")
	TEST_ASSERT_EQUAL(odst_medic_job?.type, /datum/job/marine/medic/ai/halo/odst, "ODST corpsman title did not resolve to the preferred HALO medic job path.")
	TEST_ASSERT(role_authority.is_marine_equivalent_role(JOB_SQUAD_MARINE_UNSC), "UNSC HALO marine title did not map to a canonical marine bucket.")
	TEST_ASSERT(role_authority.is_marine_equivalent_role(JOB_SQUAD_MARINE_ODST), "ODST HALO marine title did not map to a canonical marine bucket.")
	TEST_ASSERT_EQUAL(role_authority.get_job_preference_bucket_key(JOB_SQUAD_MARINE_UNSC), JOB_SQUAD_MARINE, "UNSC HALO marine title did not resolve to the canonical preference bucket.")
	TEST_ASSERT_EQUAL(role_authority.get_job_preference_bucket_key(JOB_SQUAD_MARINE_ODST), JOB_SQUAD_MARINE, "ODST HALO marine title did not resolve to the canonical preference bucket.")
	TEST_ASSERT_EQUAL(role_authority.get_job_preference_bucket_key(JOB_SQUAD_RTO_ODST), JOB_SQUAD_RTO, "ODST HALO RTO title did not resolve to the canonical preference bucket.")
	TEST_ASSERT_EQUAL(role_authority.get_job_preference_bucket_key(JOB_SO_UNSC), JOB_SO, "UNSC HALO Platoon Commander title did not resolve to the canonical SO bucket.")
	TEST_ASSERT_EQUAL(role_authority.get_job_preference_bucket_key(JOB_SO_ODST), JOB_SO, "ODST HALO Platoon Commander title did not resolve to the canonical SO bucket.")
	TEST_ASSERT_EQUAL(role_authority.get_modular_job_pref_to_gear_preset(JOB_SO_UNSC), /datum/equipment_preset/unsc/platco/equipped, "UNSC HALO Platoon Commander preview preset did not resolve through the modular helper.")
	TEST_ASSERT_EQUAL(role_authority.get_modular_job_pref_to_gear_preset(JOB_SO_ODST), /datum/equipment_preset/unsc/platco/odst/equipped, "ODST HALO Platoon Commander preview preset did not resolve through the modular helper.")
	TEST_ASSERT_EQUAL(role_authority.get_modular_job_pref_to_gear_preset(JOB_SQUAD_MARINE_UNSC), /datum/equipment_preset/unsc/pfc/equipped, "UNSC HALO marine preview preset did not resolve through the modular helper.")
	TEST_ASSERT_EQUAL(role_authority.get_modular_job_pref_to_gear_preset(JOB_SQUAD_MEDIC_UNSC), /datum/equipment_preset/unsc/medic/equipped, "UNSC HALO corpsman preview preset did not resolve through the modular helper.")
	TEST_ASSERT_EQUAL(role_authority.get_modular_job_pref_to_gear_preset(JOB_SQUAD_RTO_UNSC), /datum/equipment_preset/unsc/rto/equipped, "UNSC HALO RTO preview preset did not resolve through the modular helper.")
	TEST_ASSERT_EQUAL(role_authority.get_modular_job_pref_to_gear_preset(JOB_SQUAD_TEAM_LEADER_UNSC), /datum/equipment_preset/unsc/tl/equipped, "UNSC HALO fireteam leader preview preset did not resolve through the modular helper.")
	TEST_ASSERT_EQUAL(role_authority.get_modular_job_pref_to_gear_preset(JOB_SQUAD_LEADER_UNSC), /datum/equipment_preset/unsc/leader/equipped, "UNSC HALO squad-leader preview preset did not resolve through the modular helper.")
	TEST_ASSERT_EQUAL(role_authority.get_modular_job_pref_to_gear_preset(JOB_SQUAD_SPECIALIST_UNSC), /datum/equipment_preset/unsc/spec/equipped_spnkr, "UNSC HALO specialist preview preset did not resolve through the modular helper.")
	TEST_ASSERT_EQUAL(role_authority.get_modular_job_pref_to_gear_preset(JOB_SQUAD_MARINE_ODST), /datum/equipment_preset/unsc/pfc/odst/equipped, "ODST HALO marine preview preset did not resolve through the modular helper.")
	TEST_ASSERT_EQUAL(role_authority.get_modular_job_pref_to_gear_preset(JOB_SQUAD_MEDIC_ODST), /datum/equipment_preset/unsc/medic/odst/equipped, "ODST HALO corpsman preview preset did not resolve through the role-specific helper.")
	TEST_ASSERT_EQUAL(role_authority.get_modular_job_pref_to_gear_preset(JOB_SQUAD_RTO_ODST), /datum/equipment_preset/unsc/rto/odst/equipped, "ODST HALO RTO preview preset did not resolve through the role-specific helper.")
	TEST_ASSERT_EQUAL(role_authority.get_modular_job_pref_to_gear_preset(JOB_SQUAD_TEAM_LEADER_ODST), /datum/equipment_preset/unsc/tl/odst/equipped, "ODST HALO fireteam leader preview preset did not resolve through the role-specific helper.")
	TEST_ASSERT_EQUAL(role_authority.get_modular_job_pref_to_gear_preset(JOB_SQUAD_LEADER_ODST), /datum/equipment_preset/unsc/leader/odst/equipped, "ODST HALO section leader preview preset did not resolve through the role-specific helper.")
	TEST_ASSERT_EQUAL(role_authority.get_modular_job_pref_to_gear_preset(JOB_SQUAD_SPECIALIST_ODST), /datum/equipment_preset/unsc/spec/odst/equipped_spnkr, "ODST HALO specialist preview preset did not resolve through the role-specific helper.")
	// Preview helper-path mapping stays covered here; actual mannequin visual outcome lives in
	// /datum/unit_test/halo_ship_platoons_preview_visual_state.
	assert_halo_preview_preset_equips_job_gear("HALO Preview UNSC Platoon Commander", JOB_SO_UNSC)
	assert_halo_preview_preset_equips_job_gear("HALO Preview ODST Platoon Commander", JOB_SO_ODST)
	assert_halo_preview_preset_equips_job_gear("HALO Preview UNSC Corpsman", JOB_SQUAD_MEDIC_UNSC)
	assert_halo_preview_preset_equips_job_gear("HALO Preview UNSC RTO", JOB_SQUAD_RTO_UNSC)
	assert_halo_preview_preset_equips_job_gear("HALO Preview UNSC FTL", JOB_SQUAD_TEAM_LEADER_UNSC)
	assert_halo_preview_preset_equips_job_gear("HALO Preview UNSC Squad Leader", JOB_SQUAD_LEADER_UNSC)
	assert_halo_preview_preset_equips_job_gear("HALO Preview UNSC Specialist", JOB_SQUAD_SPECIALIST_UNSC)
	assert_halo_odst_platoon_commander_preview_officer_core("HALO Preview ODST Platoon Commander", JOB_SO_ODST)
	assert_halo_odst_preview_visual_core("HALO Preview ODST Corpsman", JOB_SQUAD_MEDIC_ODST)
	assert_halo_odst_preview_visual_core("HALO Preview ODST RTO", JOB_SQUAD_RTO_ODST)
	assert_halo_odst_preview_visual_core("HALO Preview ODST FTL", JOB_SQUAD_TEAM_LEADER_ODST)
	assert_halo_odst_preview_visual_core("HALO Preview ODST Squad Leader", JOB_SQUAD_LEADER_ODST)
	assert_halo_odst_preview_visual_core("HALO Preview ODST Specialist", JOB_SQUAD_SPECIALIST_ODST)
	assert_halo_equipment_metadata("UNSC Platoon Commander", /datum/equipment_preset/unsc/platco/equipped, JOB_SO_UNSC)
	assert_halo_equipment_metadata("ODST Platoon Commander", /datum/equipment_preset/unsc/platco/odst/equipped, JOB_SO_ODST)

	var/list/title_mappings = role_authority.get_ship_role_title_mappings()
	TEST_ASSERT_EQUAL(title_mappings[JOB_SO_UNSC], JOB_SO, "UNSC HALO Platoon Commander title did not map back to the canonical SO bucket.")
	TEST_ASSERT_EQUAL(title_mappings[JOB_SO_ODST], JOB_SO, "ODST HALO Platoon Commander title did not map back to the canonical SO bucket.")
	TEST_ASSERT_EQUAL(title_mappings[JOB_SQUAD_MARINE_UNSC], JOB_SQUAD_MARINE, "UNSC HALO marine title did not map back to the canonical marine bucket.")
	TEST_ASSERT_EQUAL(title_mappings[JOB_SQUAD_MARINE_ODST], JOB_SQUAD_MARINE, "ODST HALO marine title did not map back to the canonical marine bucket.")
	TEST_ASSERT_EQUAL(title_mappings[JOB_SQUAD_RTO_ODST], JOB_SQUAD_RTO, "ODST HALO RTO title did not map back to the canonical RTO bucket.")

	role_authority.default_roles = list(
		JOB_SO_UNSC = JOB_SO,
		JOB_SO_ODST = JOB_SO,
		JOB_SQUAD_MARINE_UNSC = JOB_SQUAD_MARINE,
		JOB_SQUAD_RTO_UNSC = JOB_SQUAD_RTO,
		JOB_SQUAD_MARINE_ODST = JOB_SQUAD_MARINE,
		JOB_SQUAD_RTO_ODST = JOB_SQUAD_RTO,
	)
	role_authority.roles_for_mode = list(
		JOB_SO_UNSC = role_authority.roles_by_name[JOB_SO_UNSC],
		JOB_SQUAD_MARINE_UNSC = role_authority.roles_by_name[JOB_SQUAD_MARINE_UNSC],
		JOB_SQUAD_RTO_UNSC = role_authority.roles_by_name[JOB_SQUAD_RTO_UNSC],
		JOB_SQUAD_MARINE_ODST = role_authority.roles_by_name[JOB_SQUAD_MARINE_ODST],
		JOB_SQUAD_RTO_ODST = role_authority.roles_by_name[JOB_SQUAD_RTO_ODST],
	)

	var/list/active_marine_titles = role_authority.get_marine_equivalent_role_titles(TRUE)
	TEST_ASSERT(active_marine_titles.Find(JOB_SQUAD_MARINE_UNSC), "Current-round marine-equivalent title expansion missed UNSC HALO marine.")
	TEST_ASSERT(active_marine_titles.Find(JOB_SQUAD_MARINE_ODST), "Current-round marine-equivalent title expansion missed ODST HALO marine.")
	TEST_ASSERT(!active_marine_titles.Find(JOB_SO_UNSC), "Current-round marine-equivalent title expansion incorrectly included the HALO Platoon Commander.")
	var/list/active_non_marine_shipside_titles = role_authority.get_non_marine_shipside_role_titles(TRUE)
	TEST_ASSERT(active_non_marine_shipside_titles.Find(JOB_SO_UNSC), "Current-round non-marine shipside title expansion missed the active HALO Platoon Commander role.")
	TEST_ASSERT(!active_non_marine_shipside_titles.Find(JOB_SQUAD_MARINE_UNSC), "Current-round non-marine shipside title expansion incorrectly included the HALO marine title.")
	var/list/all_shipside_titles = role_authority.get_shipside_role_titles()
	TEST_ASSERT(all_shipside_titles.Find(JOB_SO_UNSC), "Ship-side role title expansion missed the UNSC HALO Platoon Commander title.")
	TEST_ASSERT(all_shipside_titles.Find(JOB_SO_ODST), "Ship-side role title expansion missed the ODST HALO Platoon Commander title.")
	TEST_ASSERT(all_shipside_titles.Find(JOB_SQUAD_MARINE_UNSC), "Ship-side role title expansion missed the UNSC HALO marine title.")
	TEST_ASSERT(all_shipside_titles.Find(JOB_SQUAD_MARINE_ODST), "Ship-side role title expansion missed the ODST HALO marine title.")
	TEST_ASSERT(role_authority.is_marine_equivalent_role(JOB_SQUAD_MARINE_UNSC, TRUE), "Active-role marine classification failed for UNSC HALO marine.")
	TEST_ASSERT(role_authority.is_marine_equivalent_role(JOB_SQUAD_MARINE_ODST, TRUE), "Active-role marine classification failed for ODST HALO marine.")
	TEST_ASSERT(role_authority.is_shipside_role(JOB_SO_UNSC, TRUE), "HALO UNSC Platoon Commander role was not treated as shipside after canonical mapping.")
	TEST_ASSERT(role_authority.is_shipside_role(JOB_SQUAD_MARINE_ODST, TRUE), "HALO ODST marine role was not treated as shipside after canonical mapping.")

/datum/unit_test/halo_ship_platoons_halo_medic_job_options
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_halo_medic_job_options/Run()
	configure_test_ship_platoon(/datum/squad/marine/halo/unsc/alpha)
	assert_halo_medic_job_option("HALO UNSC Corpsman Corporal Option", /datum/job/marine/medic/ai/halo/unsc, JOB_SQUAD_MEDIC_UNSC, "Corporal", /datum/equipment_preset/unsc/medic, /datum/squad/marine/halo/unsc/alpha)
	assert_halo_medic_job_option("HALO UNSC Corpsman LCPL Option", /datum/job/marine/medic/ai/halo/unsc, JOB_SQUAD_MEDIC_UNSC, "Lance Corporal", /datum/equipment_preset/unsc/medic/lesser_rank, /datum/squad/marine/halo/unsc/alpha)
	assert_halo_medic_job_option("HALO UNSC Corpsman PFC Option", /datum/job/marine/medic/ai/halo/unsc, JOB_SQUAD_MEDIC_UNSC, "Private First Class", /datum/equipment_preset/unsc/medic/pfc, /datum/squad/marine/halo/unsc/alpha)
	assert_halo_medic_job_option("HALO UNSC Corpsman Private Option", /datum/job/marine/medic/ai/halo/unsc, JOB_SQUAD_MEDIC_UNSC, "Private", /datum/equipment_preset/unsc/medic/private, /datum/squad/marine/halo/unsc/alpha)

	configure_test_ship_platoon(/datum/squad/marine/halo/odst/alpha)
	assert_halo_medic_job_option("HALO ODST Corpsman Corporal Option", /datum/job/marine/medic/ai/halo/odst, JOB_SQUAD_MEDIC_ODST, "Corporal", /datum/equipment_preset/unsc/medic/odst, /datum/squad/marine/halo/odst/alpha)
	assert_halo_medic_job_option("HALO ODST Corpsman LCPL Option", /datum/job/marine/medic/ai/halo/odst, JOB_SQUAD_MEDIC_ODST, "Lance Corporal", /datum/equipment_preset/unsc/medic/odst/lesser_rank, /datum/squad/marine/halo/odst/alpha)
	assert_halo_medic_job_option("HALO ODST Corpsman PFC Option", /datum/job/marine/medic/ai/halo/odst, JOB_SQUAD_MEDIC_ODST, "Private First Class", /datum/equipment_preset/unsc/medic/odst/pfc, /datum/squad/marine/halo/odst/alpha)
	assert_halo_medic_job_option("HALO ODST Corpsman Private Option", /datum/job/marine/medic/ai/halo/odst, JOB_SQUAD_MEDIC_ODST, "Private", /datum/equipment_preset/unsc/medic/odst/private, /datum/squad/marine/halo/odst/alpha)

/datum/unit_test/halo_ship_platoons_squad_label_contracts
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_squad_label_contracts/Run()
	var/datum/squad/marine/alpha/marine_squad = allocate(/datum/squad/marine/alpha)
	TEST_ASSERT_EQUAL(marine_squad.get_role_label(JOB_SQUAD_LEADER), "Squad Leader", "Marine squad leader label regressed.")
	TEST_ASSERT_EQUAL(marine_squad.get_role_label(JOB_SQUAD_TEAM_LEADER), "Group Leader", "Marine group leader label regressed.")
	TEST_ASSERT_EQUAL(marine_squad.get_sub_squad_label(), "Group", "Marine sub-squad label regressed.")
	TEST_ASSERT_EQUAL(marine_squad.get_squad_info_rank_token(JOB_SQUAD_TEAM_LEADER), "GrpLdr", "Marine TL squad-info token regressed.")
	TEST_ASSERT_EQUAL(marine_squad.get_squad_info_rank_token(JOB_SQUAD_LEADER), "SqLdr", "Marine leader squad-info token regressed.")
	TEST_ASSERT_EQUAL(marine_squad.get_role_comm_restore_title(JOB_SQUAD_TEAM_LEADER), "GrpLdr", "Marine TL comm-title restoration regressed.")
	TEST_ASSERT_EQUAL(marine_squad.get_role_comm_restore_title(JOB_SQUAD_LEADER), "SqLdr", "Marine leader comm-title restoration regressed.")
	TEST_ASSERT_NULL(marine_squad.get_role_comm_restore_title(JOB_SQUAD_LEADER, TRUE), "Marine leader comm-title restoration should stay suppressed when the leader died.")

	var/datum/squad/marine/upp/upp_squad = allocate(/datum/squad/marine/upp)
	TEST_ASSERT_EQUAL(upp_squad.get_role_label(JOB_SQUAD_LEADER), "Platoon Sergeant", "UPP leader label regressed.")
	TEST_ASSERT_EQUAL(upp_squad.get_role_label(JOB_SQUAD_TEAM_LEADER), "Squad Sergeant", "UPP sublead label regressed.")
	TEST_ASSERT_EQUAL(upp_squad.get_squad_info_rank_token(JOB_SQUAD_LEADER), "SctSgt", "UPP leader squad-info token regressed.")

	var/datum/squad/marine/pmc/pmc_squad = allocate(/datum/squad/marine/pmc)
	TEST_ASSERT_EQUAL(pmc_squad.get_role_label(JOB_SQUAD_LEADER), "Operations Leader", "PMC leader label regressed.")
	TEST_ASSERT_EQUAL(pmc_squad.get_role_label(JOB_SQUAD_TEAM_LEADER), "Team Leader", "PMC sublead label regressed.")

	var/datum/squad/marine/rmc/rmc_squad = allocate(/datum/squad/marine/rmc)
	TEST_ASSERT_EQUAL(rmc_squad.get_role_label(JOB_SQUAD_LEADER), "Troop Commander", "RMC leader label regressed.")
	TEST_ASSERT_EQUAL(rmc_squad.get_role_label(JOB_SQUAD_TEAM_LEADER), "Section Leader", "RMC sublead label regressed.")

/datum/unit_test/halo_ship_platoons_tracker_target_resolution
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_tracker_target_resolution/Run()
	var/datum/squad/marine/alpha/squad = allocate(/datum/squad/marine/alpha)
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	configure_test_human(human, "Tracker Marine", JOB_SQUAD_MARINE)
	squad.marines_list += human
	squad.count = 1
	human.assigned_squad = squad

	var/obj/item/device/radio/headset/headset = allocate(/obj/item/device/radio/headset)
	headset.tracking_options = list(
		"Primary Lead" = TRACKER_SL,
		"Support Lead" = TRACKER_FTL,
	)
	headset.forceMove(human)

	TEST_ASSERT(headset.set_tracker_target(TRACKER_SL), "Headset failed to accept tracker selection by tracker id.")
	TEST_ASSERT_EQUAL(headset.locate_setting, TRACKER_SL, "Headset did not store TRACKER_SL after tracker-id selection.")

	squad.assign_fireteam("SQ1", human, FALSE)
	TEST_ASSERT_EQUAL(headset.locate_setting, TRACKER_FTL, "Assigning a marine to a fireteam no longer targets TRACKER_FTL by tracker id.")

	squad.unassign_fireteam(human, FALSE)
	TEST_ASSERT_EQUAL(headset.locate_setting, TRACKER_SL, "Removing a marine from a fireteam no longer targets TRACKER_SL by tracker id.")

/datum/unit_test/halo_ship_platoons_spec_kit_access
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_spec_kit_access/Run()
	var/turf/test_turf = run_loc_floor_top_right
	var/obj/item/spec_kit/specialist_kit = allocate(/obj/item/spec_kit, test_turf)
	var/obj/item/spec_kit/rifleman/rifleman_kit = allocate(/obj/item/spec_kit/rifleman, test_turf)

	var/mob/living/carbon/human/unsc_specialist = allocate(/mob/living/carbon/human, test_turf)
	configure_test_human(unsc_specialist, "HALO UNSC Spec Kit User", JOB_SQUAD_SPECIALIST_UNSC)
	TEST_ASSERT(specialist_kit.can_use(unsc_specialist), "HALO UNSC specialist could not use the specialist kit through canonical role matching.")
	TEST_ASSERT(!rifleman_kit.can_use(unsc_specialist), "HALO UNSC specialist incorrectly gained rifleman kit access.")

	var/mob/living/carbon/human/odst_specialist = allocate(/mob/living/carbon/human, test_turf)
	configure_test_human(odst_specialist, "HALO ODST Spec Kit User", JOB_SQUAD_SPECIALIST_ODST)
	TEST_ASSERT(specialist_kit.can_use(odst_specialist), "HALO ODST specialist could not use the specialist kit through canonical role matching.")

	var/mob/living/carbon/human/unsc_rifleman = allocate(/mob/living/carbon/human, test_turf)
	configure_test_human(unsc_rifleman, "HALO UNSC Rifleman Kit User", JOB_SQUAD_MARINE_UNSC)
	TEST_ASSERT(rifleman_kit.can_use(unsc_rifleman), "HALO UNSC rifleman could not use the rifleman kit through canonical role matching.")
	TEST_ASSERT(!specialist_kit.can_use(unsc_rifleman), "HALO UNSC rifleman incorrectly gained specialist kit access.")

	var/mob/living/carbon/human/odst_rifleman = allocate(/mob/living/carbon/human, test_turf)
	configure_test_human(odst_rifleman, "HALO ODST Rifleman Kit User", JOB_SQUAD_MARINE_ODST)
	TEST_ASSERT(rifleman_kit.can_use(odst_rifleman), "HALO ODST rifleman could not use the rifleman kit through canonical role matching.")

/datum/unit_test/halo_ship_platoons_rifleman_only_gating
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_rifleman_only_gating/Run()
	var/turf/test_turf = run_loc_floor_top_right
	var/obj/item/pamphlet/skill/spotter/spotter_pamphlet = allocate(/obj/item/pamphlet/skill/spotter, test_turf)
	var/obj/item/pamphlet/skill/loader/loader_pamphlet = allocate(/obj/item/pamphlet/skill/loader, test_turf)
	var/datum/character_trait/biology/hardcore/hardcore_trait = allocate(/datum/character_trait/biology/hardcore)
	var/datum/equipment_preset/preset = allocate(/datum/equipment_preset)

	var/mob/living/carbon/human/unsc_rifleman = allocate(/mob/living/carbon/human, test_turf)
	configure_test_human(unsc_rifleman, "HALO UNSC Rifleman Gating", JOB_SQUAD_MARINE_UNSC)
	TEST_ASSERT_NOTNULL(prepare_test_human_for_squad(unsc_rifleman, /datum/equipment_preset/unsc/pfc, JOB_SQUAD_MARINE_UNSC), "Failed to equip an ID onto the HALO UNSC rifleman gating test mob.")
	TEST_ASSERT(spotter_pamphlet.can_use(unsc_rifleman), "HALO UNSC rifleman could not use the Spotter pamphlet through canonical role matching.")
	TEST_ASSERT(loader_pamphlet.can_use(unsc_rifleman), "HALO UNSC rifleman could not use the Loader pamphlet through canonical role matching.")
	hardcore_trait.apply_trait(unsc_rifleman, preset)
	TEST_ASSERT(HAS_TRAIT(unsc_rifleman, TRAIT_HARDCORE), "HALO UNSC rifleman did not receive the Hardcore trait through canonical role matching.")

	var/mob/living/carbon/human/odst_rifleman = allocate(/mob/living/carbon/human, test_turf)
	configure_test_human(odst_rifleman, "HALO ODST Rifleman Gating", JOB_SQUAD_MARINE_ODST)
	TEST_ASSERT_NOTNULL(prepare_test_human_for_squad(odst_rifleman, /datum/equipment_preset/unsc/pfc/odst, JOB_SQUAD_MARINE_ODST), "Failed to equip an ID onto the HALO ODST rifleman gating test mob.")
	TEST_ASSERT(spotter_pamphlet.can_use(odst_rifleman), "HALO ODST rifleman could not use the Spotter pamphlet through canonical role matching.")
	TEST_ASSERT(loader_pamphlet.can_use(odst_rifleman), "HALO ODST rifleman could not use the Loader pamphlet through canonical role matching.")

	var/mob/living/carbon/human/unsc_specialist = allocate(/mob/living/carbon/human, test_turf)
	configure_test_human(unsc_specialist, "HALO UNSC Specialist Gating", JOB_SQUAD_SPECIALIST_UNSC)
	TEST_ASSERT_NOTNULL(prepare_test_human_for_squad(unsc_specialist, /datum/equipment_preset/unsc/spec, JOB_SQUAD_SPECIALIST_UNSC), "Failed to equip an ID onto the HALO UNSC specialist gating test mob.")
	TEST_ASSERT(!spotter_pamphlet.can_use(unsc_specialist), "HALO UNSC specialist incorrectly gained Spotter pamphlet access.")
	TEST_ASSERT(!loader_pamphlet.can_use(unsc_specialist), "HALO UNSC specialist incorrectly gained Loader pamphlet access.")
	hardcore_trait.apply_trait(unsc_specialist, preset)
	TEST_ASSERT(!HAS_TRAIT(unsc_specialist, TRAIT_HARDCORE), "HALO UNSC specialist incorrectly received the Hardcore trait.")

	qdel(hardcore_trait)
	qdel(preset)

/datum/unit_test/halo_ship_platoons_no_legacy_runtime
	parent_type = /datum/unit_test/halo_ship_platoons

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
	parent_type = /datum/unit_test/halo_ship_platoons

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

/datum/unit_test/halo_ship_platoons_so_faction
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_so_faction/Run()
	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	TEST_ASSERT_NOTNULL(role_authority, "RoleAuthority was unavailable for HALO SO faction test.")

	var/mob/living/carbon/human/halo_so = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	configure_test_human(halo_so, "HALO SO", JOB_SO_UNSC)
	arm_equipment(halo_so, role_authority.get_active_ship_spawn_preset_override(JOB_SO, /datum/equipment_preset/uscm_ship/so, /datum/squad/marine/halo/unsc/alpha), FALSE, TRUE)
	TEST_ASSERT_EQUAL(halo_so.faction, FACTION_UNSC, "HALO UNSC SO did not inherit FACTION_UNSC from the override preset.")
	TEST_ASSERT_EQUAL(halo_so.job, JOB_SO_UNSC, "HALO UNSC SO did not keep the explicit HALO Platoon Commander runtime title.")

	var/mob/living/carbon/human/vanilla_so = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	configure_test_human(vanilla_so, "Vanilla SO", JOB_SO)
	arm_equipment(vanilla_so, /datum/equipment_preset/uscm_ship/so, FALSE, TRUE)
	TEST_ASSERT(vanilla_so.faction != FACTION_UNSC, "Vanilla USCM SO incorrectly inherited FACTION_UNSC without a HALO platoon override.")

/datum/unit_test/halo_ship_platoons_so_lifecycle_hooks
	parent_type = /datum/unit_test/halo_ship_platoons

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
	parent_type = /datum/unit_test/halo_ship_platoons

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
