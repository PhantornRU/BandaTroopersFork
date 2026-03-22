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
