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

/datum/unit_test/halo_ship_platoons_screen_alert_unsc_selection
	parent_type = /datum/unit_test/halo_contract_test

/datum/unit_test/halo_ship_platoons_screen_alert_unsc_selection/Run()
	var/datum/screen_alert_save/alert_save = new
	var/list/selectable_factions = alert_save.get_selectable_factions_ui()

	TEST_ASSERT(selectable_factions.Find(FACTION_UNSC), "Screen alerts no longer expose FACTION_UNSC in the selectable faction list.")
	TEST_ASSERT_EQUAL(alert_save.normalize_selected_faction(FACTION_UNSC), FACTION_UNSC, "Screen alerts failed to preserve FACTION_UNSC during faction normalization.")
	TEST_ASSERT_EQUAL(alert_save.normalize_selected_faction(alert_save.get_faction_display_name(FACTION_MARINE)), FACTION_MARINE, "Screen alerts regressed marine display-name normalization while adding UNSC support.")
