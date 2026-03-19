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
	var/list/tracked_test_humans = null
	var/list/tracked_test_squads = null
	var/snapshot_ship_platoon = null
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
	tracked_test_humans = list()
	tracked_test_squads = list()
	snapshot_ship_platoon = SSmapping?.configs?[SHIP_MAP]?.platoon
	var/datum/squad_name_manager/manager = GLOB.squad_name_manager
	snapshot_runtime_name_by_static = manager?.runtime_name_by_static ? manager.runtime_name_by_static.Copy() : null
	snapshot_leader_lock_by_static = manager?.leader_lock_by_static ? manager.leader_lock_by_static.Copy() : null
	snapshot_first_platoon_commander_ckey = manager?.first_platoon_commander_ckey
	snapshot_main_platoon_name = GLOB.main_platoon_name
	snapshot_main_platoon_initial_name = GLOB.main_platoon_initial_name

/datum/unit_test/halo_ship_platoons/Destroy()
	for(var/mob/living/carbon/human/human as anything in tracked_test_humans)
		if(!QDELETED(human))
			qdel(human)

	for(var/datum/squad/squad as anything in tracked_test_squads)
		if(!QDELETED(squad))
			qdel(squad)

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
	var/datum/squad_name_manager/manager = GLOB.squad_name_manager
	if(manager)
		manager.runtime_name_by_static = snapshot_runtime_name_by_static ? snapshot_runtime_name_by_static.Copy() : list()
		manager.leader_lock_by_static = snapshot_leader_lock_by_static ? snapshot_leader_lock_by_static.Copy() : list()
		manager.first_platoon_commander_ckey = snapshot_first_platoon_commander_ckey
	GLOB.main_platoon_name = snapshot_main_platoon_name
	GLOB.main_platoon_initial_name = snapshot_main_platoon_initial_name
	if(SSmapping?.configs?[SHIP_MAP])
		SSmapping.configs[SHIP_MAP].platoon = snapshot_ship_platoon

	tracked_test_humans = null
	tracked_test_squads = null
	snapshot_squads = null
	snapshot_squads_by_type = null

	return ..()

/datum/unit_test/halo_ship_platoons/proc/isolate_personal_lockers(obj/structure/closet/secure_closet/marine_personal/locker)
	GLOB.personal_closets = locker ? list(locker) : list()

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

/datum/unit_test/halo_ship_platoons/proc/get_mainship_test_turf()
	for(var/obj/structure/closet/secure_closet/marine_personal/locker as anything in snapshot_personal_closets)
		var/turf/locker_turf = get_turf(locker)
		if(isfloorturf(locker_turf) && is_mainship_level(locker_turf.z))
			return locker_turf

	for(var/obj/structure/closet/secure_closet/marine_personal/locker as anything in GLOB.personal_closets)
		var/turf/locker_turf = get_turf(locker)
		if(isfloorturf(locker_turf) && is_mainship_level(locker_turf.z))
			return locker_turf

	var/turf/mainship_center = SSmapping?.get_mainship_center()
	if(mainship_center && is_mainship_level(mainship_center.z))
		return mainship_center

	var/list/mainship_levels = SSmapping?.levels_by_trait(ZTRAIT_MARINE_MAIN_SHIP)
	if(length(mainship_levels))
		return locate(1, 1, mainship_levels[1])

	var/turf/fallback = run_loc_floor_top_right
	if(!isfloorturf(fallback))
		return null

	var/datum/space_level/level = SSmapping?.get_level(fallback.z)
	if(level && islist(level.traits))
		if(isnull(synthetic_mainship_z))
			synthetic_mainship_z = fallback.z
			synthetic_mainship_prev = level.traits[ZTRAIT_MARINE_MAIN_SHIP]
			level.traits[ZTRAIT_MARINE_MAIN_SHIP] = TRUE

	return fallback

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

/datum/unit_test/halo_ship_platoons/proc/assert_halo_equipment_metadata(real_name, preset_path, expected_role_title)
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	configure_test_human(human, real_name, expected_role_title)
	arm_equipment(human, preset_path, FALSE, TRUE)

	var/obj/item/card/id/id = human.get_idcard()
	TEST_ASSERT_EQUAL(human.assigned_equipment_preset?.type, preset_path, "[real_name] did not keep the expected HALO preset after arm_equipment().")
	TEST_ASSERT_EQUAL(human.faction, FACTION_UNSC, "[real_name] no longer keeps FACTION_UNSC after arm_equipment().")
	TEST_ASSERT_EQUAL(human.job, expected_role_title, "[real_name] did not keep the expected HALO runtime job after arm_equipment().")
	TEST_ASSERT_EQUAL(human.title, expected_role_title, "[real_name] did not keep the expected HALO runtime title after arm_equipment().")
	TEST_ASSERT_NOTNULL(id, "[real_name] did not receive an ID card from the HALO preset.")
	TEST_ASSERT_EQUAL(id?.faction, FACTION_UNSC, "[real_name] did not keep FACTION_UNSC on the equipped ID metadata.")
	TEST_ASSERT_EQUAL(id?.rank, expected_role_title, "[real_name] did not keep the expected HALO rank on the equipped ID metadata.")
	TEST_ASSERT_EQUAL(id?.assignment, expected_role_title, "[real_name] did not keep the expected HALO assignment on the equipped ID metadata.")

/datum/unit_test/halo_ship_platoons/proc/assert_halo_runtime_identity(mob/living/carbon/human/human, expected_role_title, expected_faction = FACTION_UNSC)
	var/obj/item/card/id/id = human.get_idcard()
	TEST_ASSERT_NOTNULL(human.assigned_equipment_preset, "[human?.real_name || expected_role_title] lost assigned_equipment_preset metadata during HALO runtime flow.")
	TEST_ASSERT_EQUAL(human.job, expected_role_title, "[human?.real_name || expected_role_title] did not keep the expected HALO runtime job.")
	TEST_ASSERT_EQUAL(human.title, expected_role_title, "[human?.real_name || expected_role_title] did not keep the expected HALO runtime title.")
	TEST_ASSERT_EQUAL(human.faction, expected_faction, "[human?.real_name || expected_role_title] did not keep the expected HALO mob faction.")
	TEST_ASSERT_NOTNULL(id, "[human?.real_name || expected_role_title] did not keep an ID card after the HALO runtime flow.")
	TEST_ASSERT_EQUAL(id?.assignment, expected_role_title, "[human?.real_name || expected_role_title] did not keep the expected HALO ID assignment.")
	TEST_ASSERT_EQUAL(id?.rank, expected_role_title, "[human?.real_name || expected_role_title] did not keep the expected HALO ID rank.")
	TEST_ASSERT_EQUAL(id?.faction, expected_faction, "[human?.real_name || expected_role_title] did not keep the expected HALO ID faction.")

	var/list/preset_access = human.assigned_equipment_preset?.access
	if(islist(preset_access))
		for(var/access_flag in preset_access)
			TEST_ASSERT(id?.access?.Find(access_flag), "[human?.real_name || expected_role_title] lost preset access [access_flag] on the HALO runtime ID metadata.")

/datum/unit_test/halo_ship_platoons/proc/assert_halo_runtime_squad_family(mob/living/carbon/human/human, expected_role_title)
	var/list/family_types = GLOB.RoleAuthority?.get_halo_job_family_types(expected_role_title)
	TEST_ASSERT_NOTNULL(human.assigned_squad, "[human?.real_name || expected_role_title] did not receive a HALO squad assignment.")
	TEST_ASSERT(family_types?.Find(human.assigned_squad?.type), "[human?.real_name || expected_role_title] joined [human.assigned_squad?.type] instead of the expected HALO squad family.")

/datum/unit_test/halo_ship_platoons/proc/assert_halo_preview_preset_equips_job_gear(real_name, preview_role_title)
	var/preset_type = GLOB.RoleAuthority?.get_modular_job_pref_to_gear_preset(preview_role_title)

	TEST_ASSERT_NOTNULL(preset_type, "[real_name] did not resolve a HALO preview preset through the modular preview helper.")

	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	configure_test_human(human, real_name, preview_role_title)
	arm_equipment(human, preset_type, FALSE, FALSE, null, TRUE)

	TEST_ASSERT_NOTNULL(human.get_item_by_slot(WEAR_BODY), "[real_name] preview mannequin lost the equipped uniform/body slot.")
	TEST_ASSERT_NOTNULL(human.get_item_by_slot(WEAR_L_EAR), "[real_name] preview mannequin lost the equipped headset slot.")

/datum/unit_test/halo_ship_platoons/proc/assert_halo_specialist_roundstart_loadout(real_name, preset_path, expected_role_title, expected_squad_family)
	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	var/list/profile = role_authority?.get_ship_platoon_profile(expected_squad_family)
	var/list/expected_family_types = islist(profile?["family_types"]) ? profile["family_types"] : list(expected_squad_family)

	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	configure_test_human(human, real_name, expected_role_title)
	arm_equipment(human, preset_path, FALSE, TRUE)
	role_authority.randomize_squad(human, TRUE)

	var/obj/item/card/id/id = human.get_idcard()
	TEST_ASSERT_EQUAL(human.assigned_equipment_preset?.type, preset_path, "[real_name] did not keep the expected HALO specialist roundstart preset.")
	TEST_ASSERT_EQUAL(human.faction, FACTION_UNSC, "[real_name] no longer keeps FACTION_UNSC after HALO specialist roundstart equipping.")
	TEST_ASSERT_EQUAL(human.job, expected_role_title, "[real_name] did not keep the expected HALO specialist runtime job.")
	TEST_ASSERT_EQUAL(human.title, expected_role_title, "[real_name] did not keep the expected HALO specialist runtime title.")
	TEST_ASSERT_NOTNULL(id, "[real_name] did not receive an ID card from the HALO specialist roundstart preset.")
	TEST_ASSERT_EQUAL(id?.rank, expected_role_title, "[real_name] did not keep the expected HALO specialist rank on the ID metadata.")
	TEST_ASSERT_EQUAL(id?.assignment, expected_role_title, "[real_name] did not keep the expected HALO specialist assignment on the ID metadata.")
	TEST_ASSERT_NULL(human.get_item_by_slot(WEAR_BODY), "[real_name] should keep the HALO specialist roundstart baseline naked, but still had a uniform equipped.")
	TEST_ASSERT_NULL(human.get_item_by_slot(WEAR_L_EAR), "[real_name] should keep the HALO specialist roundstart baseline naked, but still had a headset equipped.")
	TEST_ASSERT_NULL(human.get_item_by_slot(WEAR_HEAD), "[real_name] should keep the HALO specialist roundstart baseline naked, but still had a helmet equipped.")
	TEST_ASSERT_NULL(human.get_item_by_slot(WEAR_JACKET), "[real_name] should keep the HALO specialist roundstart baseline naked, but still had armor equipped.")
	TEST_ASSERT_NULL(human.get_item_by_slot(WEAR_BACK), "[real_name] should keep the HALO specialist roundstart baseline naked, but still had a back item equipped.")
	TEST_ASSERT_NULL(human.get_item_by_slot(WEAR_J_STORE), "[real_name] should keep the HALO specialist roundstart baseline naked, but still had a stored rifle equipped.")
	TEST_ASSERT_NOTNULL(human.assigned_squad, "[real_name] did not receive a squad assignment after HALO specialist roundstart randomization.")
	TEST_ASSERT(expected_family_types.Find(human.assigned_squad?.type), "[real_name] joined [human.assigned_squad?.type] instead of one of the expected HALO squad types [english_list(expected_family_types)].")

	var/datum/squad/assigned_squad = human.assigned_squad
	assigned_squad.remove_marine_from_squad(human, id)

/datum/unit_test/halo_ship_platoons/proc/assert_halo_medic_job_option(real_name, job_type, role_title, option_title, expected_preset, expected_squad_family)
	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	var/datum/job/job_datum = new job_type()
	var/list/job_options = job_datum?.job_options
	TEST_ASSERT_NOTNULL(job_datum, "[real_name] failed to instantiate the HALO medic job datum for option testing.")
	TEST_ASSERT(islist(job_options) && job_options[option_title], "[real_name] could not find the expected HALO medic option [option_title].")

	job_datum.handle_job_options(option_title)

	var/resolved_preset = job_datum.get_spawn_equip_preset(role_title, role_authority, expected_squad_family)
	TEST_ASSERT_EQUAL(resolved_preset, expected_preset, "[real_name] resolved to [resolved_preset] instead of the expected HALO medic preset [expected_preset].")
	TEST_ASSERT(!ispath(resolved_preset, /datum/equipment_preset/uscm/medic), "[real_name] regressed back to a vanilla USCM medic preset through HALO rank-option handling.")

	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	configure_test_human(human, real_name, role_title)
	arm_equipment(human, resolved_preset, FALSE, TRUE)
	role_authority.randomize_squad(human, TRUE)

	assert_halo_runtime_identity(human, role_title)
	assert_halo_runtime_squad_family(human, role_title)

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

	assert_halo_preview_preset_equips_job_gear("HALO Preview UNSC Platoon Commander", JOB_SO_UNSC)
	assert_halo_preview_preset_equips_job_gear("HALO Preview ODST Platoon Commander", JOB_SO_ODST)
	assert_halo_preview_preset_equips_job_gear("HALO Preview UNSC Corpsman", JOB_SQUAD_MEDIC_UNSC)
	assert_halo_preview_preset_equips_job_gear("HALO Preview UNSC RTO", JOB_SQUAD_RTO_UNSC)
	assert_halo_preview_preset_equips_job_gear("HALO Preview UNSC FTL", JOB_SQUAD_TEAM_LEADER_UNSC)
	assert_halo_preview_preset_equips_job_gear("HALO Preview UNSC Squad Leader", JOB_SQUAD_LEADER_UNSC)
	assert_halo_preview_preset_equips_job_gear("HALO Preview UNSC Specialist", JOB_SQUAD_SPECIALIST_UNSC)
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
	TEST_ASSERT_EQUAL(length(halo_odst_role_mappings), 6, "HALO ODST profile should expose exactly the six namespaced ODST marine role mappings.")
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

/datum/unit_test/halo_ship_platoons_cryo_application_flow
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_cryo_application_flow/Run()
	configure_test_ship_platoon(/datum/squad/marine/halo/unsc/alpha)

	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	TEST_ASSERT_NOTNULL(role_authority, "RoleAuthority was unavailable for HALO cryo application-flow test.")
	var/datum/emergency_call/cryo_squad/cryo_call = allocate(/datum/emergency_call/cryo_squad)
	TEST_ASSERT_NOTNULL(cryo_call, "Failed to allocate the cryo emergency-call helper for HALO cryo application-flow testing.")
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
	TEST_ASSERT_EQUAL(halo_medic.get_idcard()?.faction, FACTION_UNSC, "HALO UNSC cryo application helper did not keep FACTION_UNSC on the medic ID metadata.")

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

	var/datum/squad/assigned_squad = human.assigned_squad
	assigned_squad.remove_marine_from_squad(human, id)

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

/datum/unit_test/halo_ship_platoons_so_latejoin_runtime_semantics
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_so_latejoin_runtime_semantics/Run()
	configure_test_ship_platoon(/datum/squad/marine/halo/unsc/alpha)

	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	TEST_ASSERT_NOTNULL(role_authority, "RoleAuthority was unavailable for HALO SO latejoin runtime testing.")
	var/datum/job/job_datum = role_authority.roles_by_name[JOB_SO_UNSC]
	TEST_ASSERT_NOTNULL(job_datum, "Failed to resolve JOB_SO_UNSC datum for HALO SO latejoin runtime testing.")

	var/turf/spawn_turf = run_loc_floor_top_right
	TEST_ASSERT(isfloorturf(spawn_turf), "Failed to resolve a floor turf for HALO SO latejoin runtime testing.")
	var/turf/pod_turf = get_step(spawn_turf, WEST)
	if(!isfloorturf(pod_turf))
		pod_turf = get_step(spawn_turf, EAST)
	if(!isfloorturf(pod_turf))
		pod_turf = get_step(spawn_turf, NORTH)
	if(!isfloorturf(pod_turf))
		pod_turf = get_step(spawn_turf, SOUTH)
	TEST_ASSERT(isfloorturf(pod_turf), "Failed to resolve a cryopod turf for HALO SO latejoin runtime testing.")

	var/obj/effect/landmark/late_join/job_landmark = allocate(/obj/effect/landmark/late_join, spawn_turf)
	job_landmark.job = job_datum.title
	GLOB.latejoin = list(job_landmark)
	GLOB.latejoin_by_job = list(job_datum.title = list(job_landmark))
	allocate(/obj/structure/machinery/cryopod, pod_turf)

	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	configure_test_human(human, "HALO Latejoin Platoon Commander", JOB_SO_UNSC)
	role_authority.equip_role(human, job_datum, TRUE)

	assert_halo_runtime_identity(human, JOB_SO_UNSC)
	TEST_ASSERT_EQUAL(human.assigned_equipment_preset?.type, /datum/equipment_preset/unsc/platco, "HALO SO latejoin runtime path did not keep the HALO Platoon Commander preset.")
	assert_halo_runtime_squad_family(human, JOB_SO_UNSC)
	TEST_ASSERT(istype(human.loc, /obj/structure/machinery/cryopod), "HALO SO latejoin runtime path did not complete the modular cryopod spawn flow.")

	var/leader_entry = GLOB.marine_leaders[JOB_SO]
	if(islist(leader_entry))
		var/list/leader_list = leader_entry
		TEST_ASSERT(leader_list.Find(human), "HALO SO latejoin runtime path did not keep the Platoon Commander registered as a marine leader.")
	else
		TEST_ASSERT_EQUAL(leader_entry, human, "HALO SO latejoin runtime path did not keep the Platoon Commander registered as a marine leader.")

/datum/unit_test/halo_ship_platoons_unsc_cryo_corpsman_runtime
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_unsc_cryo_corpsman_runtime/Run()
	configure_test_ship_platoon(/datum/squad/marine/halo/unsc/alpha)

	var/datum/emergency_call/cryo_squad/cryo_call = allocate(/datum/emergency_call/cryo_squad)
	TEST_ASSERT_NOTNULL(cryo_call, "Failed to allocate the cryo helper for HALO corpsman runtime testing.")

	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	configure_test_human(human, "HALO Runtime Corpsman", JOB_SQUAD_MEDIC)
	TEST_ASSERT(cryo_call.apply_profile_cryo_reinforcement(human, JOB_SQUAD_MEDIC, JOB_SQUAD_MEDIC, null, FALSE, /datum/squad/marine/halo/unsc/alpha), "HALO corpsman runtime cryo path rejected the supported profile override.")

	assert_halo_runtime_identity(human, JOB_SQUAD_MEDIC_UNSC)
	TEST_ASSERT_EQUAL(human.assigned_equipment_preset?.type, /datum/equipment_preset/unsc/medic, "HALO corpsman runtime cryo path did not keep the HALO base corpsman preset.")
	assert_halo_runtime_squad_family(human, JOB_SQUAD_MEDIC_UNSC)

/datum/unit_test/halo_ship_platoons_unsc_cryo_specialist_runtime
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_unsc_cryo_specialist_runtime/Run()
	configure_test_ship_platoon(/datum/squad/marine/halo/unsc/alpha)

	var/datum/emergency_call/cryo_squad/cryo_call = allocate(/datum/emergency_call/cryo_squad)
	TEST_ASSERT_NOTNULL(cryo_call, "Failed to allocate the cryo helper for HALO specialist runtime testing.")

	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	configure_test_human(human, "HALO Runtime Specialist", JOB_SQUAD_SPECIALIST)
	TEST_ASSERT(cryo_call.apply_profile_cryo_reinforcement(human, JOB_SQUAD_SPECIALIST, JOB_SQUAD_SPECIALIST, /datum/equipment_preset/uscm/specialist_equipped, FALSE, /datum/squad/marine/halo/unsc/alpha), "HALO specialist runtime cryo path rejected the supported profile override.")

	assert_halo_runtime_identity(human, JOB_SQUAD_SPECIALIST_UNSC)
	TEST_ASSERT_EQUAL(human.assigned_equipment_preset?.type, /datum/equipment_preset/unsc/spec, "HALO specialist runtime cryo path did not keep the HALO base specialist preset.")
	assert_halo_runtime_squad_family(human, JOB_SQUAD_SPECIALIST_UNSC)
	TEST_ASSERT(!istype(human.get_item_by_slot(WEAR_BACK), /obj/item/weapon/gun/halo_launcher/spnkr), "HALO specialist runtime cryo path still spawned the specialist fully equipped instead of using the unequipped HALO preset flow.")

/datum/unit_test/halo_ship_platoons_unsc_cryo_squad_leader_runtime
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_unsc_cryo_squad_leader_runtime/Run()
	configure_test_ship_platoon(/datum/squad/marine/halo/unsc/alpha)

	var/datum/emergency_call/cryo_squad/cryo_call = allocate(/datum/emergency_call/cryo_squad)
	TEST_ASSERT_NOTNULL(cryo_call, "Failed to allocate the cryo helper for HALO squad-leader runtime testing.")

	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	configure_test_human(human, "HALO Runtime Squad Leader", JOB_SQUAD_LEADER)
	TEST_ASSERT(cryo_call.apply_profile_cryo_reinforcement(human, JOB_SQUAD_LEADER, JOB_SQUAD_LEADER, null, FALSE, /datum/squad/marine/halo/unsc/alpha), "HALO squad-leader runtime cryo path rejected the supported profile override.")

	assert_halo_runtime_identity(human, JOB_SQUAD_LEADER_UNSC)
	TEST_ASSERT_EQUAL(human.assigned_equipment_preset?.type, /datum/equipment_preset/unsc/leader, "HALO squad-leader runtime cryo path did not keep the HALO base squad-leader preset.")
	assert_halo_runtime_squad_family(human, JOB_SQUAD_LEADER_UNSC)
	TEST_ASSERT(human.assigned_squad?.squad_leader == human, "HALO squad-leader runtime cryo path did not restore the normal squad leader assignment state.")
	var/datum/faction/faction_datum = get_faction(human.faction)
	var/image/holder = human.hud_list[faction_datum?.hud_type]
	var/has_leader_hud_overlay = FALSE
	for(var/image/overlay as anything in holder?.overlays)
		if(overlay?.icon_state == "hudsquad_leader_a")
			has_leader_hud_overlay = TRUE
			break
	TEST_ASSERT(has_leader_hud_overlay, "HALO squad-leader runtime cryo path did not rebuild the leader HUD indicator state.")

/datum/unit_test/halo_ship_platoons_roundstart_assignment_parity
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_roundstart_assignment_parity/Run()
	configure_test_ship_platoon(/datum/squad/marine/halo/unsc/alpha)
	assert_halo_randomize_assigns_squad("HALO UNSC Roundstart Platoon Commander", JOB_SO_UNSC, /datum/equipment_preset/unsc/platco, /datum/squad/marine/halo/unsc/alpha)
	assert_halo_randomize_assigns_squad("HALO UNSC Roundstart Corpsman", JOB_SQUAD_MEDIC_UNSC, /datum/equipment_preset/unsc/medic, /datum/squad/marine/halo/unsc/alpha)
	assert_halo_randomize_assigns_squad("HALO UNSC Roundstart Section Leader", JOB_SQUAD_LEADER_UNSC, /datum/equipment_preset/unsc/leader, /datum/squad/marine/halo/unsc/alpha)
	assert_halo_randomize_assigns_squad("HALO UNSC Roundstart RTO", JOB_SQUAD_RTO_UNSC, /datum/equipment_preset/unsc/rto, /datum/squad/marine/halo/unsc/alpha)
	assert_halo_randomize_assigns_squad("HALO UNSC Roundstart FTL", JOB_SQUAD_TEAM_LEADER_UNSC, /datum/equipment_preset/unsc/tl, /datum/squad/marine/halo/unsc/alpha)
	assert_halo_specialist_roundstart_loadout("HALO UNSC Roundstart Specialist", /datum/equipment_preset/unsc/spec, JOB_SQUAD_SPECIALIST_UNSC, /datum/squad/marine/halo/unsc/alpha)

	configure_test_ship_platoon(/datum/squad/marine/halo/odst/alpha)
	assert_halo_randomize_assigns_squad("HALO ODST Roundstart Platoon Commander", JOB_SO_ODST, /datum/equipment_preset/unsc/platco/odst, /datum/squad/marine/halo/odst/alpha)
	assert_halo_randomize_assigns_squad("HALO ODST Roundstart Corpsman", JOB_SQUAD_MEDIC_ODST, /datum/equipment_preset/unsc/medic/odst, /datum/squad/marine/halo/odst/alpha)
	assert_halo_randomize_assigns_squad("HALO ODST Roundstart Section Leader", JOB_SQUAD_LEADER_ODST, /datum/equipment_preset/unsc/leader/odst, /datum/squad/marine/halo/odst/alpha)
	assert_halo_randomize_assigns_squad("HALO ODST Roundstart RTO", JOB_SQUAD_RTO_ODST, /datum/equipment_preset/unsc/rto/odst, /datum/squad/marine/halo/odst/alpha)
	assert_halo_randomize_assigns_squad("HALO ODST Roundstart FTL", JOB_SQUAD_TEAM_LEADER_ODST, /datum/equipment_preset/unsc/tl/odst, /datum/squad/marine/halo/odst/alpha)
	assert_halo_specialist_roundstart_loadout("HALO ODST Roundstart Specialist", /datum/equipment_preset/unsc/spec/odst, JOB_SQUAD_SPECIALIST_ODST, /datum/squad/marine/halo/odst/alpha)

/datum/unit_test/halo_ship_platoons_unsc_specialist_job_locker_access
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_unsc_specialist_job_locker_access/Run()
	var/turf/test_turf = run_loc_floor_top_right
	var/datum/squad/marine/halo/unsc/alpha/squad = allocate(/datum/squad/marine/halo/unsc/alpha)
	var/obj/structure/closet/secure_closet/halo/job_locker/weapons_spec/ft1/locker_ft1 = allocate(/obj/structure/closet/secure_closet/halo/job_locker/weapons_spec/ft1, test_turf)
	var/obj/structure/closet/secure_closet/halo/job_locker/weapons_spec/ft2/locker_ft2 = allocate(/obj/structure/closet/secure_closet/halo/job_locker/weapons_spec/ft2, test_turf)

	var/mob/living/carbon/human/first_specialist = allocate(/mob/living/carbon/human, test_turf)
	configure_test_human(first_specialist, "HALO UNSC Spec One", JOB_SQUAD_SPECIALIST)
	var/obj/item/card/id/first_id = prepare_test_human_for_squad(first_specialist, /datum/equipment_preset/unsc/spec, JOB_SQUAD_SPECIALIST)
	TEST_ASSERT_NOTNULL(first_id, "Failed to equip an ID onto the first HALO UNSC specialist test mob.")

	TEST_ASSERT(squad.put_marine_in_squad(first_specialist), "Failed to insert the first HALO UNSC specialist into a squad for locker access testing.")
	TEST_ASSERT_EQUAL(first_specialist.assigned_fireteam, "SQ1", "The first HALO UNSC specialist was not assigned to SQ1.")
	TEST_ASSERT(first_id.access.Find(ACCESS_SQUAD_ONE), "The first HALO UNSC specialist ID did not receive ACCESS_SQUAD_ONE.")
	TEST_ASSERT(locker_ft1.allowed(first_specialist), "The first HALO UNSC specialist could not access the SQ1 weapons locker after squad insertion.")
	TEST_ASSERT(!locker_ft2.allowed(first_specialist), "The first HALO UNSC specialist incorrectly gained access to the SQ2 weapons locker.")

	var/mob/living/carbon/human/second_specialist = allocate(/mob/living/carbon/human, test_turf)
	configure_test_human(second_specialist, "HALO UNSC Spec Two", JOB_SQUAD_SPECIALIST)
	var/obj/item/card/id/second_id = prepare_test_human_for_squad(second_specialist, /datum/equipment_preset/unsc/spec, JOB_SQUAD_SPECIALIST)
	TEST_ASSERT_NOTNULL(second_id, "Failed to equip an ID onto the second HALO UNSC specialist test mob.")

	TEST_ASSERT(squad.put_marine_in_squad(second_specialist), "Failed to insert the second HALO UNSC specialist into a squad for locker access testing.")
	TEST_ASSERT_EQUAL(second_specialist.assigned_fireteam, "SQ2", "The second HALO UNSC specialist was not assigned to SQ2.")
	TEST_ASSERT(second_id.access.Find(ACCESS_SQUAD_TWO), "The second HALO UNSC specialist ID did not receive ACCESS_SQUAD_TWO.")
	TEST_ASSERT(locker_ft2.allowed(second_specialist), "The second HALO UNSC specialist could not access the SQ2 weapons locker after squad insertion.")
	TEST_ASSERT(!locker_ft1.allowed(second_specialist), "The second HALO UNSC specialist incorrectly gained access to the SQ1 weapons locker.")

	squad.remove_marine_from_squad(second_specialist, second_id)
	squad.remove_marine_from_squad(first_specialist, first_id)

/datum/unit_test/halo_ship_platoons_odst_specialist_job_locker_access
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_odst_specialist_job_locker_access/Run()
	var/turf/test_turf = run_loc_floor_top_right
	var/datum/squad/marine/halo/odst/alpha/squad = allocate(/datum/squad/marine/halo/odst/alpha)
	var/obj/structure/closet/secure_closet/halo/job_locker/weapons_spec/ft1/locker_ft1 = allocate(/obj/structure/closet/secure_closet/halo/job_locker/weapons_spec/ft1, test_turf)

	var/mob/living/carbon/human/specialist = allocate(/mob/living/carbon/human, test_turf)
	configure_test_human(specialist, "HALO ODST Spec One", JOB_SQUAD_SPECIALIST)
	var/obj/item/card/id/id = prepare_test_human_for_squad(specialist, /datum/equipment_preset/unsc/spec/odst, JOB_SQUAD_SPECIALIST)
	TEST_ASSERT_NOTNULL(id, "Failed to equip an ID onto the HALO ODST specialist test mob.")

	TEST_ASSERT(squad.put_marine_in_squad(specialist), "Failed to insert the HALO ODST specialist into a squad for locker access testing.")
	TEST_ASSERT_EQUAL(specialist.assigned_fireteam, "SQ1", "The HALO ODST specialist was not assigned to SQ1.")
	TEST_ASSERT(id.access.Find(ACCESS_SQUAD_ONE), "The HALO ODST specialist ID did not receive ACCESS_SQUAD_ONE.")
	TEST_ASSERT(locker_ft1.allowed(specialist), "The HALO ODST specialist could not access the SQ1 weapons locker after squad insertion.")

	squad.remove_marine_from_squad(specialist, id)

/datum/unit_test/halo_ship_platoons_unsc_specialist_personal_locker_roundstart
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_unsc_specialist_personal_locker_roundstart/Run()
	var/datum/equipment_preset/preset = allocate(/datum/equipment_preset)
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	configure_test_human(human, "HALO UNSC Spec Roundstart", JOB_SQUAD_SPECIALIST, /datum/squad/marine/halo/unsc/alpha)
	TEST_ASSERT_NOTNULL(human.assigned_squad, "Failed to resolve UNSC HALO alpha squad for roundstart locker test.")

	var/obj/structure/closet/secure_closet/marine_personal/unsc/alpha/specialist/locker = allocate(/obj/structure/closet/secure_closet/marine_personal/unsc/alpha/specialist)
	isolate_personal_lockers(locker)

	TEST_ASSERT(preset.try_handle_personal_locker_vanity(human, null, FALSE), "Roundstart locker handling returned FALSE for HALO UNSC specialist.")
	TEST_ASSERT_EQUAL(locker.owner, human.real_name, "HALO UNSC specialist personal locker was not claimed on roundstart.")
	TEST_ASSERT(findtext(locker.name, human.real_name), "HALO UNSC specialist personal locker name was not personalized on roundstart.")
	TEST_ASSERT(locker.allowed(human), "Claimed HALO UNSC specialist personal locker did not open for its owner.")
	TEST_ASSERT(count_personal_locker_contents_by_type(locker, /obj/item/clothing/under/marine) >= 1, "HALO UNSC specialist personal locker lost its baseline uniform on roundstart claim.")
	TEST_ASSERT(count_personal_locker_contents_by_type(locker, /obj/item/device/radio/headset/almayer/marine/solardevils/unsc/rockhoppers) >= 1, "HALO UNSC specialist personal locker lost its baseline headset on roundstart claim.")

/datum/unit_test/halo_ship_platoons_unsc_specialist_personal_locker_latejoin
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_unsc_specialist_personal_locker_latejoin/Run()
	var/datum/equipment_preset/preset = allocate(/datum/equipment_preset)
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	configure_test_human(human, "HALO UNSC Spec Latejoin", JOB_SQUAD_SPECIALIST, /datum/squad/marine/halo/unsc/alpha)
	TEST_ASSERT_NOTNULL(human.assigned_squad, "Failed to resolve UNSC HALO alpha squad for latejoin locker test.")

	var/obj/structure/closet/secure_closet/marine_personal/unsc/alpha/specialist/locker = allocate(/obj/structure/closet/secure_closet/marine_personal/unsc/alpha/specialist)
	isolate_personal_lockers(locker)

	TEST_ASSERT(preset.try_handle_personal_locker_vanity(human, null, TRUE), "Latejoin locker handling returned FALSE for HALO UNSC specialist.")
	TEST_ASSERT_EQUAL(locker.owner, human.real_name, "HALO UNSC specialist personal locker was not claimed on latejoin.")
	TEST_ASSERT(findtext(locker.name, human.real_name), "HALO UNSC specialist personal locker name was not personalized on latejoin.")
	TEST_ASSERT(locker.allowed(human), "Claimed HALO UNSC specialist personal locker did not open for its owner on latejoin.")

/datum/unit_test/halo_ship_platoons_odst_specialist_personal_locker_roundstart
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_odst_specialist_personal_locker_roundstart/Run()
	var/datum/equipment_preset/preset = allocate(/datum/equipment_preset)
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	configure_test_human(human, "HALO ODST Spec Roundstart", JOB_SQUAD_SPECIALIST, /datum/squad/marine/halo/odst/alpha)
	TEST_ASSERT_NOTNULL(human.assigned_squad, "Failed to resolve ODST HALO alpha squad for roundstart locker test.")

	var/obj/structure/closet/secure_closet/marine_personal/odst/alpha/specialist/locker = allocate(/obj/structure/closet/secure_closet/marine_personal/odst/alpha/specialist)
	isolate_personal_lockers(locker)

	TEST_ASSERT(preset.try_handle_personal_locker_vanity(human, null, FALSE), "Roundstart locker handling returned FALSE for HALO ODST specialist.")
	TEST_ASSERT_EQUAL(locker.owner, human.real_name, "HALO ODST specialist personal locker was not claimed on roundstart.")
	TEST_ASSERT(locker.allowed(human), "Claimed HALO ODST specialist personal locker did not open for its owner.")
	TEST_ASSERT(count_personal_locker_contents_by_type(locker, /obj/item/device/radio/headset/almayer/marine/solardevils/unsc/ferrymen) >= 1, "HALO ODST specialist personal locker lost its baseline headset on roundstart claim.")

/datum/unit_test/halo_ship_platoons_personal_locker_empty_first_claim_refill
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_personal_locker_empty_first_claim_refill/Run()
	var/datum/equipment_preset/preset = allocate(/datum/equipment_preset)
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	configure_test_human(human, "HALO Empty Locker Claim", JOB_SQUAD_SPECIALIST, /datum/squad/marine/halo/unsc/alpha)

	var/obj/structure/closet/secure_closet/marine_personal/unsc/alpha/specialist/locker = allocate(/obj/structure/closet/secure_closet/marine_personal/unsc/alpha/specialist)
	isolate_personal_lockers(locker)
	clear_personal_locker_contents(locker)
	TEST_ASSERT_EQUAL(length(locker.contents), 0, "Failed to empty HALO specialist personal locker before first-claim refill test.")

	TEST_ASSERT(preset.try_handle_personal_locker_vanity(human, null, FALSE), "Locker handling returned FALSE for empty first-claim refill test.")
	TEST_ASSERT(count_personal_locker_contents_by_type(locker, /obj/item/clothing/under/marine) >= 1, "Empty HALO specialist locker was not refilled with baseline uniform on first claim.")
	TEST_ASSERT(count_personal_locker_contents_by_type(locker, /obj/item/device/radio/headset/almayer/marine/solardevils/unsc/rockhoppers) >= 1, "Empty HALO specialist locker was not refilled with baseline headset on first claim.")

/datum/unit_test/halo_ship_platoons_personal_locker_nonempty_first_claim_no_duplicate
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_personal_locker_nonempty_first_claim_no_duplicate/Run()
	var/datum/equipment_preset/preset = allocate(/datum/equipment_preset)
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	configure_test_human(human, "HALO Nonempty Locker Claim", JOB_SQUAD_SPECIALIST, /datum/squad/marine/halo/unsc/alpha)

	var/obj/structure/closet/secure_closet/marine_personal/unsc/alpha/specialist/locker = allocate(/obj/structure/closet/secure_closet/marine_personal/unsc/alpha/specialist)
	isolate_personal_lockers(locker)

	var/uniforms_before = count_personal_locker_contents_by_type(locker, /obj/item/clothing/under/marine)
	var/headsets_before = count_personal_locker_contents_by_type(locker, /obj/item/device/radio/headset/almayer/marine/solardevils/unsc/rockhoppers)
	var/shoes_before = count_personal_locker_contents_by_type(locker, /obj/item/clothing/shoes/marine/knife)

	TEST_ASSERT(preset.try_handle_personal_locker_vanity(human, null, FALSE), "Locker handling returned FALSE for non-empty first-claim duplication test.")
	TEST_ASSERT_EQUAL(count_personal_locker_contents_by_type(locker, /obj/item/clothing/under/marine), uniforms_before, "Non-empty HALO specialist locker duplicated baseline uniform on first claim.")
	TEST_ASSERT_EQUAL(count_personal_locker_contents_by_type(locker, /obj/item/device/radio/headset/almayer/marine/solardevils/unsc/rockhoppers), headsets_before, "Non-empty HALO specialist locker duplicated baseline headset on first claim.")
	TEST_ASSERT_EQUAL(count_personal_locker_contents_by_type(locker, /obj/item/clothing/shoes/marine/knife), shoes_before, "Non-empty HALO specialist locker duplicated baseline shoes on first claim.")

/datum/unit_test/halo_ship_platoons_personal_locker_custom_item_routing
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_personal_locker_custom_item_routing/Run()
	var/turf/mainship_turf = get_mainship_test_turf()
	TEST_ASSERT_NOTNULL(mainship_turf, "Failed to resolve a mainship turf for HALO personal-locker custom-item routing test.")

	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human, mainship_turf)
	configure_test_human(human, "HALO Custom Item Route", JOB_SQUAD_SPECIALIST, /datum/squad/marine/halo/unsc/alpha, "locker_custom_tester")

	var/obj/structure/closet/secure_closet/marine_personal/unsc/alpha/specialist/locker = allocate(/obj/structure/closet/secure_closet/marine_personal/unsc/alpha/specialist, mainship_turf)
	locker.owner = human.real_name
	isolate_personal_lockers(locker)

	GLOB.custom_items = list("locker_custom_tester:/obj/item/device/flashlight")
	EquipCustomItems(human)

	TEST_ASSERT(locate(/obj/item/device/flashlight) in locker.contents, "Custom item routing failed to place an item into the claimed HALO personal locker.")

/datum/unit_test/halo_ship_platoons_specialist_job_locker_allowlist
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_specialist_job_locker_allowlist/Run()
	var/obj/structure/closet/secure_closet/halo/job_locker/weapons_spec/locker = allocate(/obj/structure/closet/secure_closet/halo/job_locker/weapons_spec)
	var/list/allowed_specialist_jobs = locker.get_allowed_specialist_jobs()

	TEST_ASSERT(allowed_specialist_jobs.Find(JOB_SQUAD_SPECIALIST), "Specialist job locker allowlist lost the canonical specialist title.")
	TEST_ASSERT(allowed_specialist_jobs.Find(JOB_SQUAD_SPECIALIST_UNSC), "Specialist job locker allowlist lost the HALO UNSC specialist title.")
	TEST_ASSERT(allowed_specialist_jobs.Find(JOB_SQUAD_SPECIALIST_ODST), "Specialist job locker allowlist lost the HALO ODST specialist title.")

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

/datum/unit_test/halo_ship_platoons_so_spawn_roundstart
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_so_spawn_roundstart/Run()
	var/turf/center_turf = run_loc_floor_top_right
	TEST_ASSERT_NOTNULL(center_turf, "Failed to resolve test turf for SO spawn roundstart test.")

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

	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human, center_turf)
	tracked_test_humans += human
	var/list/spawn_candidate = human.get_modular_spawn_candidate(job_datum, FALSE)

	TEST_ASSERT_NOTNULL(spawn_candidate, "Modular spawn candidate was null for SO roundstart test.")
	TEST_ASSERT_EQUAL(spawn_candidate["source_tag"], "start_job", "SO spawn candidate source tag was not start_job.")
	TEST_ASSERT_EQUAL(spawn_candidate["tier_tag"], "job", "SO spawn candidate tier tag was not job.")
	TEST_ASSERT_EQUAL(spawn_candidate["no_pod_expected"], FALSE, "SO spawn candidate unexpectedly marked no_pod_expected.")
	TEST_ASSERT(isfloorturf(spawn_candidate["spawn_turf"]), "SO spawn candidate did not resolve to a floor turf.")
	TEST_ASSERT(istype(spawn_candidate["preferred_pod"], /obj/structure/machinery/cryopod), "SO spawn candidate did not resolve to a cryopod.")
	TEST_ASSERT_EQUAL(get_dist(spawn_candidate["spawn_turf"], get_turf(spawn_candidate["preferred_pod"])), 1, "SO spawn candidate did not keep the preferred cryopod cardinally adjacent to its spawn turf.")

	human.forceMove(spawn_candidate["spawn_turf"])
	var/obj/structure/machinery/cryopod/expected_pod = spawn_candidate["preferred_pod"]
	TEST_ASSERT(human.try_enter_nearby_free_cryopod(job_datum, expected_pod), "SO failed to enter preferred cryopod on roundstart.")
	TEST_ASSERT_EQUAL(human.loc, expected_pod, "SO did not end up inside the resolver-selected cryopod.")

/mob/living/carbon/human/modular_spawn_probe
	var/tmp/modular_spawn_called = FALSE

/mob/living/carbon/human/modular_spawn_probe/get_modular_spawn_candidate(datum/job/job_datum, late_join = FALSE)
	modular_spawn_called = TRUE
	return ..()

/datum/unit_test/halo_ship_platoons_so_roundstart_callers
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_so_roundstart_callers/Run()
	var/turf/center_turf = run_loc_floor_top_right
	TEST_ASSERT_NOTNULL(center_turf, "Failed to resolve test turf for SO roundstart caller test.")

	var/turf/pod_turf = get_step(center_turf, WEST)
	if(!isturf(pod_turf))
		pod_turf = get_step(center_turf, EAST)
	if(!isturf(pod_turf))
		pod_turf = get_step(center_turf, NORTH)
	if(!isturf(pod_turf))
		pod_turf = get_step(center_turf, SOUTH)
	TEST_ASSERT_NOTNULL(pod_turf, "Failed to find adjacent turf for SO roundstart caller test cryopod.")

	allocate(/obj/effect/landmark/start/bridge, center_turf)
	allocate(/obj/structure/machinery/cryopod, pod_turf)

	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	TEST_ASSERT_NOTNULL(role_authority, "RoleAuthority was unavailable for SO roundstart caller test.")
	var/datum/job/job_datum = role_authority.roles_by_name[JOB_SO_UNSC]
	TEST_ASSERT_NOTNULL(job_datum, "Failed to resolve JOB_SO_UNSC datum for SO roundstart caller test.")

	var/mob/living/carbon/human/modular_spawn_probe/job_human = allocate(/mob/living/carbon/human/modular_spawn_probe, center_turf)
	tracked_test_humans += job_human
	job_datum.equip_job(job_human)
	TEST_ASSERT(job_human.modular_spawn_called, "equip_job did not request modular spawn candidate for roundstart SO.")

	var/mob/living/carbon/human/modular_spawn_probe/role_human = allocate(/mob/living/carbon/human/modular_spawn_probe, center_turf)
	tracked_test_humans += role_human
	role_authority.equip_role(role_human, job_datum, FALSE)
	TEST_ASSERT(role_human.modular_spawn_called, "role_authority equip_role did not request modular spawn candidate for roundstart SO.")

/datum/unit_test/halo_ship_platoons_non_so_roundstart_callers
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_non_so_roundstart_callers/Run()
	var/turf/center_turf = run_loc_floor_top_right
	TEST_ASSERT_NOTNULL(center_turf, "Failed to resolve test turf for non-SO roundstart caller test.")

	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	TEST_ASSERT_NOTNULL(role_authority, "RoleAuthority was unavailable for non-SO roundstart caller test.")
	var/datum/job/job_datum = role_authority.roles_by_name[JOB_DROPSHIP_PILOT]
	TEST_ASSERT_NOTNULL(job_datum, "Failed to resolve JOB_DROPSHIP_PILOT datum for non-SO roundstart caller test.")
	TEST_ASSERT(!job_datum.uses_modular_job_landmark_spawn(), "Non-SO regression test picked a job that is now unexpectedly opted into modular non-squad spawn resolution.")

	var/mob/living/carbon/human/modular_spawn_probe/job_human = allocate(/mob/living/carbon/human/modular_spawn_probe, center_turf)
	tracked_test_humans += job_human
	job_datum.equip_job(job_human)
	TEST_ASSERT(!job_human.modular_spawn_called, "equip_job unexpectedly requested modular spawn candidate for a non-SO non-squad job.")

	var/mob/living/carbon/human/modular_spawn_probe/role_human = allocate(/mob/living/carbon/human/modular_spawn_probe, center_turf)
	tracked_test_humans += role_human
	role_authority.equip_role(role_human, job_datum, FALSE)
	TEST_ASSERT(!role_human.modular_spawn_called, "role_authority equip_role unexpectedly requested modular spawn candidate for a non-SO non-squad job.")
