/datum/unit_test/halo_ship_platoons
	var/next_ship_exists = FALSE
	var/next_ship_snapshot = null
	var/list/snapshot_default_roles = null
	var/list/snapshot_roles_for_mode = null
	var/list/snapshot_personal_closets = null
	var/list/snapshot_custom_items = null
	var/synthetic_mainship_z = null
	var/synthetic_mainship_prev = null

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

/datum/unit_test/halo_ship_platoons/Destroy()
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

	GLOB.personal_closets = snapshot_personal_closets ? snapshot_personal_closets.Copy() : list()
	GLOB.custom_items = snapshot_custom_items ? snapshot_custom_items.Copy() : list()

	return ..()

/datum/unit_test/halo_ship_platoons/proc/isolate_personal_lockers(obj/structure/closet/secure_closet/marine_personal/locker)
	GLOB.personal_closets = locker ? list(locker) : list()

/datum/unit_test/halo_ship_platoons/proc/configure_test_human(mob/living/carbon/human/human, real_name, job_title, squad_type = null, key_name = null)
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
	TEST_ASSERT_EQUAL(unsc_job?.type, /datum/job/marine/standard/ai/halo/unsc, "UNSC marine title did not resolve to the preferred HALO job path.")
	TEST_ASSERT_EQUAL(odst_job?.type, /datum/job/marine/standard/ai/halo/odst, "ODST marine title did not resolve to the preferred HALO job path.")
	TEST_ASSERT(role_authority.is_marine_equivalent_role(JOB_SQUAD_MARINE_UNSC), "UNSC HALO marine title did not map to a canonical marine bucket.")
	TEST_ASSERT(role_authority.is_marine_equivalent_role(JOB_SQUAD_MARINE_ODST), "ODST HALO marine title did not map to a canonical marine bucket.")
	TEST_ASSERT_EQUAL(role_authority.get_job_preference_bucket_key(JOB_SQUAD_MARINE_UNSC), JOB_SQUAD_MARINE, "UNSC HALO marine title did not resolve to the canonical preference bucket.")
	TEST_ASSERT_EQUAL(role_authority.get_job_preference_bucket_key(JOB_SQUAD_MARINE_ODST), JOB_SQUAD_MARINE, "ODST HALO marine title did not resolve to the canonical preference bucket.")
	TEST_ASSERT_EQUAL(role_authority.get_job_preference_bucket_key(JOB_SQUAD_RTO_ODST), JOB_SQUAD_RTO, "ODST HALO RTO title did not resolve to the canonical preference bucket.")
	TEST_ASSERT_EQUAL(role_authority.get_modular_job_pref_to_gear_preset(JOB_SQUAD_MARINE_UNSC), /datum/equipment_preset/unsc/pfc/equipped, "UNSC HALO marine preview preset did not resolve through the modular helper.")
	TEST_ASSERT_EQUAL(role_authority.get_modular_job_pref_to_gear_preset(JOB_SQUAD_MARINE_ODST), /datum/equipment_preset/unsc/pfc/odst/equipped, "ODST HALO marine preview preset did not resolve through the modular helper.")

	var/list/title_mappings = role_authority.get_ship_role_title_mappings()
	TEST_ASSERT_EQUAL(title_mappings[JOB_SQUAD_MARINE_UNSC], JOB_SQUAD_MARINE, "UNSC HALO marine title did not map back to the canonical marine bucket.")
	TEST_ASSERT_EQUAL(title_mappings[JOB_SQUAD_MARINE_ODST], JOB_SQUAD_MARINE, "ODST HALO marine title did not map back to the canonical marine bucket.")
	TEST_ASSERT_EQUAL(title_mappings[JOB_SQUAD_RTO_ODST], JOB_SQUAD_RTO, "ODST HALO RTO title did not map back to the canonical RTO bucket.")

	role_authority.default_roles = list(
		JOB_SQUAD_MARINE_UNSC = JOB_SQUAD_MARINE,
		JOB_SQUAD_RTO_UNSC = JOB_SQUAD_RTO,
		JOB_SQUAD_MARINE_ODST = JOB_SQUAD_MARINE,
		JOB_SQUAD_RTO_ODST = JOB_SQUAD_RTO,
	)
	role_authority.roles_for_mode = list(
		JOB_SO = role_authority.roles_by_name[JOB_SO],
		JOB_SQUAD_MARINE_UNSC = role_authority.roles_by_name[JOB_SQUAD_MARINE_UNSC],
		JOB_SQUAD_RTO_UNSC = role_authority.roles_by_name[JOB_SQUAD_RTO_UNSC],
		JOB_SQUAD_MARINE_ODST = role_authority.roles_by_name[JOB_SQUAD_MARINE_ODST],
		JOB_SQUAD_RTO_ODST = role_authority.roles_by_name[JOB_SQUAD_RTO_ODST],
	)

	var/list/active_marine_titles = role_authority.get_marine_equivalent_role_titles(TRUE)
	TEST_ASSERT(active_marine_titles.Find(JOB_SQUAD_MARINE_UNSC), "Current-round marine-equivalent title expansion missed UNSC HALO marine.")
	TEST_ASSERT(active_marine_titles.Find(JOB_SQUAD_MARINE_ODST), "Current-round marine-equivalent title expansion missed ODST HALO marine.")
	TEST_ASSERT(!active_marine_titles.Find(JOB_SO), "Current-round marine-equivalent title expansion incorrectly included a non-marine role.")
	var/list/active_non_marine_shipside_titles = role_authority.get_non_marine_shipside_role_titles(TRUE)
	TEST_ASSERT(active_non_marine_shipside_titles.Find(JOB_SO), "Current-round non-marine shipside title expansion missed the active SO role.")
	TEST_ASSERT(!active_non_marine_shipside_titles.Find(JOB_SQUAD_MARINE_UNSC), "Current-round non-marine shipside title expansion incorrectly included the HALO marine title.")
	var/list/all_shipside_titles = role_authority.get_shipside_role_titles()
	TEST_ASSERT(all_shipside_titles.Find(JOB_SQUAD_MARINE_UNSC), "Ship-side role title expansion missed the UNSC HALO marine title.")
	TEST_ASSERT(all_shipside_titles.Find(JOB_SQUAD_MARINE_ODST), "Ship-side role title expansion missed the ODST HALO marine title.")
	TEST_ASSERT(role_authority.is_marine_equivalent_role(JOB_SQUAD_MARINE_UNSC, TRUE), "Active-role marine classification failed for UNSC HALO marine.")
	TEST_ASSERT(role_authority.is_marine_equivalent_role(JOB_SQUAD_MARINE_ODST, TRUE), "Active-role marine classification failed for ODST HALO marine.")
	TEST_ASSERT(role_authority.is_shipside_role(JOB_SQUAD_MARINE_ODST, TRUE), "HALO ODST marine role was not treated as shipside after canonical mapping.")

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

/datum/unit_test/halo_ship_platoons_unsc_medical_vendor_access
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_unsc_medical_vendor_access/Run()
	var/turf/vendor_turf = run_loc_floor_top_right
	var/turf/user_turf = get_step(vendor_turf, SOUTH)
	if(!isfloorturf(user_turf))
		user_turf = get_step(vendor_turf, NORTH)
	TEST_ASSERT(isfloorturf(user_turf), "Failed to find a user turf for HALO medical vendor access testing.")

	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human, user_turf)
	configure_test_human(human, "UNSC Vendor Corpsman", JOB_SQUAD_MEDIC_UNSC, /datum/squad/marine/halo/unsc/alpha)
	TEST_ASSERT_NOTNULL(prepare_test_human_for_squad(human, /datum/equipment_preset/unsc/medic, JOB_SQUAD_MEDIC_UNSC), "Failed to equip an ID onto the HALO medical vendor access test mob.")

	var/obj/structure/machinery/cm_vending/gear/medic_chemical/unsc/chem_vendor = allocate(/obj/structure/machinery/cm_vending/gear/medic_chemical/unsc, vendor_turf)
	TEST_ASSERT(chem_vendor.can_access_to_vend(human, FALSE), "HALO UNSC corpsman lost access to the chemical medic vendor.")

	var/obj/structure/machinery/cm_vending/sorted/medical/unsc/med_vendor = allocate(/obj/structure/machinery/cm_vending/sorted/medical/unsc, vendor_turf)
	med_vendor.req_access = list(ACCESS_MARINE_MEDPREP)
	TEST_ASSERT(med_vendor.can_access_to_vend(human, FALSE), "HALO UNSC corpsman lost access to the medical vendor when medprep access was required.")

	var/list/lifesaver_item = null
	for(var/list/product as anything in med_vendor.get_listed_products(human))
		if(product[3] == /obj/item/storage/belt/medical/lifesaver/unsc)
			lifesaver_item = product
			break

	TEST_ASSERT_NOTNULL(lifesaver_item, "Failed to resolve the Lifesaver Bag listing in the HALO medical vendor.")
	med_vendor.vendor_successful_vend(lifesaver_item, human)

	var/obj/item/storage/belt/medical/lifesaver/unsc/lifesaver_bag = human.l_hand
	if(!istype(lifesaver_bag))
		lifesaver_bag = human.r_hand
	if(!istype(lifesaver_bag))
		lifesaver_bag = locate(/obj/item/storage/belt/medical/lifesaver/unsc) in human
	if(!istype(lifesaver_bag))
		lifesaver_bag = locate(/obj/item/storage/belt/medical/lifesaver/unsc) in vendor_turf
	if(!istype(lifesaver_bag))
		lifesaver_bag = locate(/obj/item/storage/belt/medical/lifesaver/unsc) in user_turf
	TEST_ASSERT_NOTNULL(lifesaver_bag, "HALO medical vendor failed to hand over the Lifesaver Bag to the corpsman.")

/datum/unit_test/halo_ship_platoons_announcement_routing
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_announcement_routing/Run()
	var/mob/living/carbon/human/unsc_human = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	configure_test_human(unsc_human, "UNSC Listener", JOB_SQUAD_MARINE_UNSC)
	unsc_human.faction = FACTION_UNSC
	unsc_human.faction_group = list(FACTION_UNSC)
	TEST_ASSERT(unsc_human.matches_faction_announcement_target(FACTION_UNSC, FALSE), "UNSC listener no longer matches direct UNSC faction announcements.")
	TEST_ASSERT(unsc_human.matches_faction_announcement_target(FACTION_MARINE, FALSE), "UNSC listener no longer matches shared marine/UNSC announcement routing.")

	var/mob/living/carbon/human/covenant_human = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	configure_test_human(covenant_human, "Covenant Listener", JOB_SQUAD_MARINE)
	covenant_human.faction = FACTION_COVENANT
	TEST_ASSERT(!covenant_human.matches_faction_announcement_target(FACTION_MARINE, FALSE), "Covenant listener incorrectly matched marine-targeted announcements.")

	TEST_ASSERT(istype(GLOB.tts_announcers[TTS_COVENANT_ANNOUNCER_KEY], /datum/announcer/covenant), "Covenant announcements no longer resolve through the shared announcer registry.")
	TEST_ASSERT(istype(GLOB.tts_announcers[TTS_YAUTJA_ANNOUNCER_KEY], /datum/announcer/yautja), "Yautja announcements no longer resolve through the shared announcer registry.")

/datum/unit_test/halo_ship_platoons_screen_alert_unsc_selection
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_screen_alert_unsc_selection/Run()
	var/datum/screen_alert_save/alert_save = new
	var/list/selectable_factions = alert_save.get_selectable_factions_ui()

	TEST_ASSERT(selectable_factions.Find(FACTION_UNSC), "Screen alerts no longer expose FACTION_UNSC in the selectable faction list.")
	TEST_ASSERT_EQUAL(alert_save.normalize_selected_faction(FACTION_UNSC), FACTION_UNSC, "Screen alerts failed to preserve FACTION_UNSC during faction normalization.")
	TEST_ASSERT_EQUAL(alert_save.normalize_selected_faction(alert_save.get_faction_display_name(FACTION_MARINE)), FACTION_MARINE, "Screen alerts regressed marine display-name normalization while adding UNSC support.")

/datum/unit_test/halo_ship_platoons_leader_hud_icon
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_leader_hud_icon/Run()
	var/datum/faction/unsc/faction = allocate(/datum/faction/unsc)
	var/image/unsc_holder = image(null)
	var/image/odst_holder = image(null)

	var/mob/living/carbon/human/unsc_leader = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	var/datum/squad/marine/halo/unsc/bravo/unsc_section = allocate(/datum/squad/marine/halo/unsc/bravo)
	var/unsc_lead_icon = unsc_section.lead_icon || "leader"
	configure_test_human(unsc_leader, "HALO UNSC Section Leader", JOB_SQUAD_LEADER_UNSC)
	unsc_leader.assigned_squad = unsc_section
	unsc_section.squad_leader = unsc_leader
	faction.modify_hud_holder(unsc_holder, unsc_leader)
	TEST_ASSERT(holder_has_overlay_state(unsc_holder, "hudsquad_[unsc_lead_icon]"), "HALO UNSC Section leader did not receive the leader HUD overlay.")

	var/mob/living/carbon/human/odst_leader = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	var/datum/squad/marine/halo/odst/bravo/odst_section = allocate(/datum/squad/marine/halo/odst/bravo)
	var/odst_lead_icon = odst_section.lead_icon || "leader"
	configure_test_human(odst_leader, "HALO ODST Section Leader", JOB_SQUAD_LEADER_ODST)
	odst_leader.assigned_squad = odst_section
	odst_section.squad_leader = odst_leader
	faction.modify_hud_holder(odst_holder, odst_leader)
	TEST_ASSERT(holder_has_overlay_state(odst_holder, "hudsquad_[odst_lead_icon]"), "HALO ODST Section leader did not receive the leader HUD overlay.")

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
