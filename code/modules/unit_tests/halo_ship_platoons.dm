/datum/unit_test/halo_ship_platoons
	var/next_ship_exists = FALSE
	var/next_ship_snapshot = null
	var/list/snapshot_default_roles = null
	var/list/snapshot_roles_for_mode = null
	var/list/snapshot_personal_closets = null
	var/list/snapshot_custom_items = null

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
	return null

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
	TEST_ASSERT_EQUAL(role_authority.roles_by_name[JOB_SQUAD_MARINE_UNSC]?.type, /datum/job/marine/standard/ai/halo/unsc, "UNSC marine title did not resolve to the preferred HALO job path.")
	TEST_ASSERT_EQUAL(role_authority.roles_by_name[JOB_SQUAD_MARINE_ODST]?.type, /datum/job/marine/standard/ai/halo/odst, "ODST marine title did not resolve to the preferred HALO job path.")
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
