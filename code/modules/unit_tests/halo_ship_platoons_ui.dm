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
	unsc_human.mind = new /datum/mind("halo_orbit_marine", "halo_orbit_marine")
	var/mob/living/carbon/human/unsc_crew_human = create_test_human("UNSC Orbit Crew", JOB_UNSC_CREW, /datum/squad/marine/halo/unsc/alpha, run_loc_floor_bottom_right, "halo_orbit_crew")
	unsc_crew_human.faction = FACTION_UNSC
	unsc_crew_human.faction_group = list(FACTION_UNSC)
	unsc_crew_human.mind = new /datum/mind("halo_orbit_crew", "halo_orbit_crew")

	var/datum/orbit_menu/menu = new(observer)
	TEST_ASSERT_NOTNULL(menu, "Failed to allocate the orbit menu for HALO grouping testing.")

	var/list/static_data = menu.ui_static_data(observer)
	var/list/marines = static_data["marines"]
	var/list/humans = static_data["humans"]
	var/list/npcs = static_data["npcs"]
	var/target_ref = REF(unsc_human)
	var/crew_ref = REF(unsc_crew_human)
	var/list/marine_entry = null
	var/list/human_entry = null
	var/list/npc_entry = null
	var/list/crew_marine_entry = null
	var/list/crew_human_entry = null

	for(var/list/entry as anything in marines)
		if(entry["ref"] == target_ref)
			marine_entry = entry
		if(entry["ref"] == crew_ref)
			crew_marine_entry = entry

	for(var/list/entry as anything in humans)
		if(entry["ref"] == target_ref)
			human_entry = entry
		if(entry["ref"] == crew_ref)
			crew_human_entry = entry

	for(var/list/entry as anything in npcs)
		if(entry["ref"] == target_ref)
			npc_entry = entry
			break

	var/fallback_bucket = npc_entry ? "npcs" : (human_entry ? "humans" : "missing")
	TEST_ASSERT_NOTNULL(marine_entry, "HALO UNSC marine-equivalent roles no longer appear in the marine orbit section. Orbit bucket=[fallback_bucket].")
	TEST_ASSERT_NULL(human_entry, "HALO UNSC marine-equivalent roles incorrectly fall back to the generic human orbit section.")
	TEST_ASSERT_NULL(npc_entry, "HALO UNSC marine-equivalent roles incorrectly fall back to the NPC orbit section.")
	TEST_ASSERT_EQUAL(marine_entry["squad_static"], "Alpha", "HALO orbit grouping no longer exports the static squad marker for marine-equivalent roles.")
	TEST_ASSERT_EQUAL(marine_entry["squad_runtime"], unsc_human.assigned_squad?.name, "HALO orbit grouping no longer exports the runtime squad name for marine-equivalent roles.")
	TEST_ASSERT_NULL(crew_marine_entry, "HALO shipboard crew with a squad assignment should not be promoted into the marine orbit section.")
	TEST_ASSERT_NOTNULL(crew_human_entry, "HALO shipboard crew with a squad assignment should remain in the generic human orbit section.")

	qdel(menu)
