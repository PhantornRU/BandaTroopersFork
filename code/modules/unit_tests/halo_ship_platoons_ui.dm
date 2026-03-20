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

// Layer 3: preview / mannequin coverage through the real preview resolver path.
/datum/unit_test/halo_ship_platoons_preview_visual_state
	parent_type = /datum/unit_test/halo_ship_platoons

/datum/unit_test/halo_ship_platoons_preview_visual_state/Run()
	configure_test_ship_platoon(/datum/squad/marine/halo/unsc/alpha)
	assert_preview_preset_visualizes_loadout(JOB_SQUAD_MARINE_UNSC, /datum/equipment_preset/unsc/pfc/equipped, list(WEAR_BODY, WEAR_L_EAR, WEAR_HEAD, WEAR_JACKET))
	assert_preview_preset_visualizes_loadout(JOB_SQUAD_MEDIC_UNSC, /datum/equipment_preset/unsc/medic/equipped, list(WEAR_BODY, WEAR_L_EAR, WEAR_HEAD, WEAR_JACKET))
	assert_preview_preset_visualizes_loadout(JOB_SQUAD_RTO_UNSC, /datum/equipment_preset/unsc/rto/equipped, list(WEAR_BODY, WEAR_L_EAR, WEAR_HEAD, WEAR_JACKET))
	assert_preview_preset_visualizes_loadout(JOB_SQUAD_TEAM_LEADER_UNSC, /datum/equipment_preset/unsc/tl/equipped, list(WEAR_BODY, WEAR_L_EAR, WEAR_HEAD, WEAR_JACKET))
	assert_preview_preset_visualizes_loadout(JOB_SQUAD_LEADER_UNSC, /datum/equipment_preset/unsc/leader/equipped, list(WEAR_BODY, WEAR_L_EAR, WEAR_HEAD, WEAR_JACKET))
	assert_preview_preset_visualizes_loadout(JOB_SQUAD_SPECIALIST_UNSC, /datum/equipment_preset/unsc/spec/equipped_spnkr, list(WEAR_BODY, WEAR_L_EAR, WEAR_HEAD, WEAR_JACKET, /obj/item/weapon/gun/halo_launcher/spnkr))
	assert_preview_preset_visualizes_loadout(JOB_SO_UNSC, /datum/equipment_preset/unsc/platco/equipped, list(WEAR_BODY, WEAR_L_EAR, WEAR_HEAD, WEAR_JACKET))

	configure_test_ship_platoon(/datum/squad/marine/halo/odst/alpha)
	assert_preview_preset_visualizes_loadout(JOB_SQUAD_MEDIC_ODST, /datum/equipment_preset/unsc/medic/odst/equipped, list(
		/obj/item/device/radio/headset/almayer/marine/solardevils/unsc/odst,
		/obj/item/clothing/head/helmet/marine/unsc/odst,
		/obj/item/clothing/under/marine/odst,
		/obj/item/clothing/suit/marine/unsc/odst,
	))
	assert_preview_preset_visualizes_loadout(JOB_SQUAD_LEADER_ODST, /datum/equipment_preset/unsc/leader/odst/equipped, list(
		/obj/item/device/radio/headset/almayer/marine/solardevils/unsc/odst,
		/obj/item/clothing/head/helmet/marine/unsc/odst,
		/obj/item/clothing/under/marine/odst,
		/obj/item/clothing/suit/marine/unsc/odst,
	))
	assert_preview_preset_visualizes_loadout(JOB_SQUAD_SPECIALIST_ODST, /datum/equipment_preset/unsc/spec/odst/equipped_spnkr, list(
		/obj/item/device/radio/headset/almayer/marine/solardevils/unsc/odst,
		/obj/item/clothing/head/helmet/marine/unsc/odst,
		/obj/item/clothing/under/marine/odst,
		/obj/item/clothing/suit/marine/unsc/odst,
		/obj/item/weapon/gun/halo_launcher/spnkr,
	))
	assert_preview_preset_visualizes_loadout(JOB_SO_ODST, /datum/equipment_preset/unsc/platco/odst/equipped, list(
		/obj/item/device/radio/headset/almayer/marine/solardevils/unsc/odst,
		/obj/item/clothing/head/cmcap,
		/obj/item/clothing/under/marine/standard,
		/obj/item/clothing/suit/marine/unsc,
	))
