/datum/unit_test/halo_ship_platoons_announcement_routing
	parent_type = /datum/unit_test/halo_equip_test

/datum/unit_test/halo_ship_platoons_announcement_routing/Run()
	var/mob/living/carbon/human/unsc_human = create_test_human("UNSC Listener", JOB_SQUAD_MARINE_UNSC)
	unsc_human.faction = FACTION_UNSC
	unsc_human.faction_group = list(FACTION_UNSC)
	TEST_ASSERT(unsc_human.matches_faction_announcement_target(FACTION_UNSC, FALSE), "UNSC listener no longer matches direct UNSC faction announcements.")
	TEST_ASSERT(unsc_human.matches_faction_announcement_target(FACTION_MARINE, FALSE), "UNSC listener no longer matches shared marine/UNSC announcement routing.")

	var/mob/living/carbon/human/covenant_human = create_test_human("Covenant Listener", JOB_SQUAD_MARINE)
	covenant_human.faction = FACTION_COVENANT
	TEST_ASSERT(!covenant_human.matches_faction_announcement_target(FACTION_MARINE, FALSE), "Covenant listener incorrectly matched marine-targeted announcements.")

	TEST_ASSERT(istype(GLOB.tts_announcers[TTS_COVENANT_ANNOUNCER_KEY], /datum/announcer/covenant), "Covenant announcements no longer resolve through the shared announcer registry.")
	TEST_ASSERT(istype(GLOB.tts_announcers[TTS_YAUTJA_ANNOUNCER_KEY], /datum/announcer/yautja), "Yautja announcements no longer resolve through the shared announcer registry.")

/datum/unit_test/halo_ship_platoons_orbit_marine_equivalent_grouping
	parent_type = /datum/unit_test/halo_integration_test

/datum/unit_test/halo_ship_platoons_orbit_marine_equivalent_grouping/Run()
	configure_test_ship_platoon(/datum/squad/marine/halo/unsc/alpha)

	var/mob/dead/observer/observer = track_test_atom(allocate(/mob/dead/observer, run_loc_floor_top_right))
	TEST_ASSERT_NOTNULL(observer, "Failed to allocate an observer for HALO orbit grouping testing.")

	var/mob/living/carbon/human/unsc_human = create_test_human("UNSC Orbit Marine", JOB_SQUAD_MARINE_UNSC, /datum/squad/marine/halo/unsc/alpha, run_loc_floor_bottom_left, "halo_orbit_marine")
	unsc_human.faction = FACTION_UNSC
	unsc_human.faction_group = list(FACTION_UNSC)

	var/datum/orbit_menu/menu = new(observer)
	TEST_ASSERT_NOTNULL(menu, "Failed to allocate the orbit menu for HALO grouping testing.")

	var/list/static_data = menu.ui_static_data(observer)
	var/list/marines = static_data["marines"]
	var/list/humans = static_data["humans"]
	var/target_ref = REF(unsc_human)
	var/list/marine_entry = null
	var/list/human_entry = null

	for(var/list/entry as anything in marines)
		if(entry["ref"] == target_ref)
			marine_entry = entry
			break

	for(var/list/entry as anything in humans)
		if(entry["ref"] == target_ref)
			human_entry = entry
			break

	TEST_ASSERT_NOTNULL(marine_entry, "HALO UNSC marine-equivalent roles no longer appear in the marine orbit section.")
	TEST_ASSERT_NULL(human_entry, "HALO UNSC marine-equivalent roles incorrectly fall back to the generic human orbit section.")
	TEST_ASSERT_EQUAL(marine_entry["squad_static"], "Alpha", "HALO orbit grouping no longer exports the static squad marker for marine-equivalent roles.")
	TEST_ASSERT_EQUAL(marine_entry["squad_runtime"], unsc_human.assigned_squad?.name, "HALO orbit grouping no longer exports the runtime squad name for marine-equivalent roles.")

	qdel(menu)
