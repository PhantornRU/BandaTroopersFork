/// Avoids requiring a live admin client just to inspect static menu data in unit tests.
/datum/fire_support_menu/unit_test_stub/New(user)
	return

/datum/unit_test/proc/find_custom_ordnance_section(list/sections, section_id)
	if(!islist(sections))
		return null
	for(var/list/section as anything in sections)
		if(section["id"] == section_id)
			return section
	return null

/datum/unit_test/proc/assert_expected_supplies(list/actual_supplies, list/expected_supplies, label)
	TEST_ASSERT_EQUAL(length(actual_supplies), length(expected_supplies), "[label] should expose exactly [length(expected_supplies)] supply entries.")
	for(var/typepath in expected_supplies)
		TEST_ASSERT_EQUAL(actual_supplies[typepath], expected_supplies[typepath], "[label] has an unexpected count for [typepath].")

/datum/unit_test/proc/assert_expected_values(list/actual_values, list/expected_values, label)
	TEST_ASSERT_EQUAL(length(actual_values), length(expected_values), "[label] should expose exactly [length(expected_values)] entries.")
	for(var/index in 1 to length(expected_values))
		TEST_ASSERT_EQUAL(actual_values[index], expected_values[index], "[label] drifted at slot [index].")

/datum/unit_test/proc/assert_template_actions(datum/rto_support_template/template, list/expected_actions, expected_shared_cooldown = null, expected_personal_cooldown = null)
	var/list/action_templates = template.get_action_templates()
	TEST_ASSERT_EQUAL(length(action_templates), length(expected_actions), "[template.template_id] should expose exactly [length(expected_actions)] actions.")

	for(var/action_id in expected_actions)
		var/datum/rto_support_action_template/action_template = template.get_action_template(action_id)
		TEST_ASSERT_NOTNULL(action_template, "[template.template_id] is missing action [action_id].")
		TEST_ASSERT_EQUAL(action_template.fire_support_path, expected_actions[action_id], "[template.template_id] action [action_id] no longer points at the intended fire support payload.")
		if(!isnull(expected_shared_cooldown))
			TEST_ASSERT_EQUAL(action_template.shared_cooldown, expected_shared_cooldown, "[template.template_id] action [action_id] no longer uses the expected shared cooldown.")
		if(!isnull(expected_personal_cooldown))
			TEST_ASSERT_EQUAL(action_template.personal_cooldown, expected_personal_cooldown, "[template.template_id] action [action_id] no longer uses the expected personal cooldown.")
		TEST_ASSERT(!action_template.allow_closed_turf, "[template.template_id] action [action_id] should keep requiring open turf.")

/datum/unit_test/proc/assert_expected_templates(datum/rto_support_controller/controller, list/expected_template_ids, label)
	var/list/actual_template_ids = list()
	for(var/datum/rto_support_template/template as anything in controller.get_available_templates())
		actual_template_ids += template.template_id

	TEST_ASSERT_EQUAL(length(actual_template_ids), length(expected_template_ids), "[label] exposed an unexpected number of templates.")
	for(var/template_id in expected_template_ids)
		TEST_ASSERT(template_id in actual_template_ids, "[label] is missing expected template [template_id].")

	var/list/all_template_ids = list("mortar", "cas", "heavy", "logistics", "medical", "technical", "halo_logistics", "halo_medical", "halo_technical")
	for(var/template_id in all_template_ids)
		if(template_id in expected_template_ids)
			TEST_ASSERT_NOTNULL(controller.find_template(template_id), "[label] could not resolve expected template [template_id].")
		else
			TEST_ASSERT_NULL(controller.find_template(template_id), "[label] unexpectedly resolved template [template_id].")

/datum/unit_test/proc/assert_uscm_only_templates(datum/rto_support_controller/controller)
	for(var/template_id in list("mortar", "cas", "heavy", "logistics", "medical", "technical"))
		TEST_ASSERT_NOTNULL(controller.find_template(template_id), "USCM controller could not resolve standard template [template_id].")
	for(var/template_id in list("halo_logistics", "halo_medical", "halo_technical"))
		TEST_ASSERT_NULL(controller.find_template(template_id), "USCM controller unexpectedly resolved HALO template [template_id].")

/datum/unit_test/proc/assert_has_spotter_trait(mob/living/carbon/human/human, label)
	TEST_ASSERT_NOTNULL(human, "[label] is missing its human test subject.")
	for(var/datum/character_trait/trait as anything in human.traits)
		if(istype(trait, /datum/character_trait/skills/spotter))
			return
	TEST_FAIL("[label] should keep the spotter trait after loadout application.")

/datum/unit_test/halo_support_template_availability

/datum/unit_test/halo_support_template_availability/Run()
	var/list/expected_unsc_template_ids = list("mortar", "halo_logistics", "halo_medical", "halo_technical")
	var/list/expected_odst_template_ids = list("cas", "heavy", "halo_logistics", "halo_medical", "halo_technical")

	var/mob/living/carbon/human/halo_human = allocate(/mob/living/carbon/human)
	halo_human.job = JOB_SQUAD_RTO_UNSC
	var/datum/rto_support_controller/halo_controller = allocate(/datum/rto_support_controller, halo_human)
	assert_expected_templates(halo_controller, expected_unsc_template_ids, "UNSC HALO RTO")

	var/mob/living/carbon/human/odst_human = allocate(/mob/living/carbon/human)
	odst_human.job = JOB_SQUAD_RTO_ODST
	var/datum/rto_support_controller/odst_controller = allocate(/datum/rto_support_controller, odst_human)
	assert_expected_templates(odst_controller, expected_odst_template_ids, "ODST HALO RTO")

	var/mob/living/carbon/human/uscm_human = allocate(/mob/living/carbon/human)
	uscm_human.job = JOB_SQUAD_RTO
	var/datum/rto_support_controller/uscm_controller = allocate(/datum/rto_support_controller, uscm_human)

	var/list/uscm_templates = uscm_controller.get_available_templates()
	for(var/template_id in list("halo_logistics", "halo_medical", "halo_technical"))
		for(var/datum/rto_support_template/template as anything in uscm_templates)
			TEST_ASSERT(template.template_id != template_id, "Standard USCM RTO unexpectedly received the [template_id] template.")
		TEST_ASSERT_NULL(uscm_controller.find_template(template_id), "Standard USCM RTO could resolve the [template_id] template.")
	assert_uscm_only_templates(uscm_controller)

/datum/unit_test/halo_support_uscm_rto_base_loadout

/datum/unit_test/halo_support_uscm_rto_base_loadout/Run()
	var/mob/living/carbon/human/uscm_human = allocate(/mob/living/carbon/human)
	uscm_human.job = JOB_SQUAD_RTO
	var/datum/equipment_preset/uscm/rto/uscm_preset = allocate(/datum/equipment_preset/uscm/rto)
	uscm_preset.load_gear(uscm_human)

	assert_has_spotter_trait(uscm_human, "USCM RTO base preset")
	TEST_ASSERT_NOTNULL(uscm_human.get_rto_support_controller(), "USCM RTO base preset should initialize the support controller.")

/datum/unit_test/halo_support_binocular_variants

/datum/unit_test/halo_support_binocular_variants/Run()
	var/mob/living/carbon/human/unsc_human = allocate(/mob/living/carbon/human)
	unsc_human.job = JOB_SQUAD_RTO_UNSC
	var/datum/equipment_preset/unsc/rto/equipped/unsc_preset = allocate(/datum/equipment_preset/unsc/rto/equipped)
	unsc_preset.load_gear(unsc_human)
	var/obj/item/storage/pouch/sling/rto/halo/unsc/unsc_pouch = locate(/obj/item/storage/pouch/sling/rto/halo/unsc) in unsc_human.contents_recursive()
	var/obj/item/device/binoculars/rto/halo/unsc/unsc_binoculars = locate(/obj/item/device/binoculars/rto/halo/unsc) in unsc_human.contents_recursive()
	var/obj/item/device/binoculars/range/designator/unsc_designator = locate(/obj/item/device/binoculars/range/designator) in unsc_human.contents_recursive()

	TEST_ASSERT_NOTNULL(unsc_pouch, "UNSC RTO equipped preset did not receive the HALO UNSC sling pouch.")
	TEST_ASSERT_NOTNULL(unsc_binoculars, "UNSC RTO equipped preset did not receive the HALO UNSC binocular variant.")
	TEST_ASSERT_NULL(unsc_designator, "UNSC RTO equipped preset still carries a legacy designator.")

	var/mob/living/carbon/human/odst_human = allocate(/mob/living/carbon/human)
	odst_human.job = JOB_SQUAD_RTO_ODST
	var/datum/equipment_preset/unsc/rto/odst/equipped/odst_preset = allocate(/datum/equipment_preset/unsc/rto/odst/equipped)
	odst_preset.load_gear(odst_human)
	var/obj/item/storage/pouch/sling/rto/halo/odst/odst_pouch = locate(/obj/item/storage/pouch/sling/rto/halo/odst) in odst_human.contents_recursive()
	var/obj/item/device/binoculars/rto/halo/odst/odst_binoculars = locate(/obj/item/device/binoculars/rto/halo/odst) in odst_human.contents_recursive()
	var/obj/item/device/binoculars/range/designator/odst_designator = locate(/obj/item/device/binoculars/range/designator) in odst_human.contents_recursive()

	TEST_ASSERT_NOTNULL(odst_pouch, "ODST RTO equipped preset did not receive the HALO ODST sling pouch.")
	TEST_ASSERT_NOTNULL(odst_binoculars, "ODST RTO equipped preset did not receive the HALO ODST binocular variant.")
	TEST_ASSERT_NULL(odst_designator, "ODST RTO equipped preset still carries a legacy designator.")

/datum/unit_test/halo_support_locker_kit

/datum/unit_test/halo_support_locker_kit/Run()
	var/obj/structure/closet/secure_closet/marine_personal/unsc/rto/unsc_locker = allocate(/obj/structure/closet/secure_closet/marine_personal/unsc/rto)
	var/obj/item/storage/pouch/sling/rto/halo/unsc/unsc_locker_pouch = locate(/obj/item/storage/pouch/sling/rto/halo/unsc) in unsc_locker.contents_recursive()
	var/obj/item/device/binoculars/rto/halo/unsc/unsc_locker_binoculars = locate(/obj/item/device/binoculars/rto/halo/unsc) in unsc_locker.contents_recursive()
	var/obj/item/device/binoculars/fire_support/uscm/unsc_legacy_binoculars = locate(/obj/item/device/binoculars/fire_support/uscm) in unsc_locker.contents_recursive()
	TEST_ASSERT_NOTNULL(unsc_locker_pouch, "UNSC RTO locker did not spawn the HALO UNSC sling pouch.")
	TEST_ASSERT_NOTNULL(unsc_locker_binoculars, "UNSC RTO locker did not spawn the HALO UNSC binocular variant.")
	TEST_ASSERT_NULL(unsc_legacy_binoculars, "UNSC RTO locker should not spawn the legacy USCM fire-support binocular.")

	var/obj/structure/closet/secure_closet/marine_personal/odst/rto/odst_locker = allocate(/obj/structure/closet/secure_closet/marine_personal/odst/rto)
	var/obj/item/storage/pouch/sling/rto/halo/odst/odst_locker_pouch = locate(/obj/item/storage/pouch/sling/rto/halo/odst) in odst_locker.contents_recursive()
	var/obj/item/device/binoculars/rto/halo/odst/odst_locker_binoculars = locate(/obj/item/device/binoculars/rto/halo/odst) in odst_locker.contents_recursive()
	var/obj/item/device/binoculars/fire_support/uscm/odst_legacy_binoculars = locate(/obj/item/device/binoculars/fire_support/uscm) in odst_locker.contents_recursive()
	TEST_ASSERT_NOTNULL(odst_locker_pouch, "ODST RTO locker did not spawn the HALO ODST sling pouch.")
	TEST_ASSERT_NOTNULL(odst_locker_binoculars, "ODST RTO locker did not spawn the HALO ODST binocular variant.")
	TEST_ASSERT_NULL(odst_legacy_binoculars, "ODST RTO locker should not spawn the legacy USCM fire-support binocular.")

/datum/unit_test/halo_support_template_wiring

/datum/unit_test/halo_support_template_wiring/Run()
	var/datum/rto_support_template/halo_logistics/logistics_template = allocate(/datum/rto_support_template/halo_logistics)
	assert_template_actions(logistics_template, list(
		"halo_rifle_ammo_drop" = /datum/fire_support/supply_drop/halo/rifle,
		"halo_marksman_ammo_drop" = /datum/fire_support/supply_drop/halo/marksman,
		"halo_pdw_ammo_drop" = /datum/fire_support/supply_drop/halo/pdw,
		"halo_shotgun_ammo_drop" = /datum/fire_support/supply_drop/halo/shotgun,
		"halo_sniper_ammo_drop" = /datum/fire_support/supply_drop/halo/sniper,
		"halo_spnkr_ammo_drop" = /datum/fire_support/supply_drop/halo/spnkr,
		"halo_grenadier_ammo_drop" = /datum/fire_support/supply_drop/halo/grenadier,
	), 240 SECONDS, 600 SECONDS)

	var/datum/rto_support_template/halo_medical/medical_template = allocate(/datum/rto_support_template/halo_medical)
	assert_template_actions(medical_template, list(
		"halo_medical_packets_drop" = /datum/fire_support/supply_drop/halo/medical_packets,
		"halo_corpsman_kit_drop" = /datum/fire_support/supply_drop/halo/corpsman_kit,
		"halo_biofoam_reserve_drop" = /datum/fire_support/supply_drop/halo/biofoam_reserve,
	), 240 SECONDS, 600 SECONDS)

	var/datum/rto_support_template/halo_technical/technical_template = allocate(/datum/rto_support_template/halo_technical)
	var/list/technical_action_templates = technical_template.get_action_templates()
	TEST_ASSERT_EQUAL(length(technical_action_templates), 7, "halo_technical should expose exactly seven actions.")
	assert_template_actions(technical_template, list(
		"halo_toolbox_drop" = /datum/fire_support/supply_drop/halo/toolbox,
		"halo_fortification_drop" = /datum/fire_support/supply_drop/halo/fortification,
		"halo_breaching_drop" = /datum/fire_support/supply_drop/halo/breaching,
		"halo_vehicle_service_drop" = /datum/fire_support/supply_drop/halo/vehicle_service,
		"halo_signal_drop" = /datum/fire_support/supply_drop/halo/signal,
		"halo_recon_drop" = /datum/fire_support/supply_drop/halo/recon,
		"halo_rto_command_drop" = /datum/fire_support/supply_drop/halo/rto_command,
	))
	TEST_ASSERT_EQUAL(technical_template.get_action_template("halo_toolbox_drop").shared_cooldown, 360 SECONDS, "HALO engineering-derived technical drops should keep doubled engineering shared cooldowns.")
	TEST_ASSERT_EQUAL(technical_template.get_action_template("halo_signal_drop").shared_cooldown, 240 SECONDS, "HALO command-derived technical drops should keep doubled command shared cooldowns.")

	var/datum/rto_support_template/logistics/uscm_logistics_template = allocate(/datum/rto_support_template/logistics)
	assert_template_actions(uscm_logistics_template, list(
		"logistics_supply" = /datum/fire_support/supply_drop,
		"logistics_mine_crate" = /datum/fire_support/supply_drop/mine_crate,
		"logistics_mini_sentry" = /datum/fire_support/sentry_drop/mini,
		"logistics_full_sentry" = /datum/fire_support/sentry_drop/full,
		"logistics_grenade_drop" = /datum/fire_support/supply_drop/grenade_crate,
		"logistics_sentry_ammo_drop" = /datum/fire_support/supply_drop/sentry_ammo,
	))
	TEST_ASSERT_EQUAL(uscm_logistics_template.get_action_template("logistics_supply").shared_cooldown, 240 SECONDS, "USCM logistics supply drop should use doubled shared cooldown.")
	TEST_ASSERT_EQUAL(uscm_logistics_template.get_action_template("logistics_mine_crate").shared_cooldown, 180 SECONDS, "USCM mine crate drop should use doubled shared cooldown.")
	TEST_ASSERT_EQUAL(uscm_logistics_template.get_action_template("logistics_full_sentry").shared_cooldown, 360 SECONDS, "USCM full sentry drop should use doubled shared cooldown.")

	var/datum/rto_support_template/medical/uscm_medical_template = allocate(/datum/rto_support_template/medical)
	assert_template_actions(uscm_medical_template, list(
		"medical_medkits_drop" = /datum/fire_support/supply_drop/medical_medkits,
		"medical_blood_drop" = /datum/fire_support/supply_drop/medical_blood,
		"medical_iv_drop" = /datum/fire_support/supply_drop/medical_iv,
		"medical_optable_drop" = /datum/fire_support/supply_drop/medical_optable,
	))
	TEST_ASSERT_EQUAL(uscm_medical_template.get_action_template("medical_medkits_drop").shared_cooldown, 240 SECONDS, "USCM medical drops should use doubled shared cooldowns.")
	TEST_ASSERT_EQUAL(uscm_medical_template.get_action_template("medical_optable_drop").shared_cooldown, 360 SECONDS, "USCM operation table drop should keep the longer shared cooldown.")

	var/datum/rto_support_template/technical/uscm_technical_template = allocate(/datum/rto_support_template/technical)
	assert_template_actions(uscm_technical_template, list(
		"technical_fortification_drop" = /datum/fire_support/supply_drop/technical_fortification,
		"technical_power_drop" = /datum/fire_support/supply_drop/technical_power,
		"technical_recon_drop" = /datum/fire_support/supply_drop/technical_recon,
		"technical_powerloader_drop" = /datum/fire_support/supply_drop/technical_powerloader,
	), 0, 0)
	TEST_ASSERT_EQUAL(uscm_technical_template.get_action_template("technical_recon_drop").shared_cooldown, 240 SECONDS, "USCM technical recon drop should use the medium shared cooldown.")
	TEST_ASSERT_EQUAL(uscm_technical_template.get_action_template("technical_powerloader_drop").shared_cooldown, 360 SECONDS, "USCM powerloader drop should use the longer technical shared cooldown.")

	var/datum/rto_support_template/mortar/mortar_template = allocate(/datum/rto_support_template/mortar)
	assert_template_actions(mortar_template, list(
		"mortar_he" = /datum/fire_support/mortar/rto_single,
		"mortar_smoke" = /datum/fire_support/mortar/smoke/rto_single,
		"mortar_incendiary" = /datum/fire_support/mortar/incendiary/rto_single,
	), 0, 0)
	TEST_ASSERT_EQUAL(mortar_template.get_action_template("mortar_he").shared_cooldown, 4 SECONDS, "Mortar HE should keep its original shared cooldown.")
	TEST_ASSERT_EQUAL(mortar_template.get_action_template("mortar_smoke").shared_cooldown, 3 SECONDS, "Mortar smoke should keep its original shared cooldown.")
	TEST_ASSERT_EQUAL(mortar_template.get_action_template("mortar_incendiary").shared_cooldown, 6 SECONDS, "Mortar incendiary should keep its original shared cooldown.")
	TEST_ASSERT_EQUAL(mortar_template.visibility_zone_cooldown, 600 SECONDS, "Mortar should use doubled visibility zone cooldown.")

	var/datum/rto_support_template/cas/cas_template = allocate(/datum/rto_support_template/cas)
	assert_template_actions(cas_template, list(
		"cas_gun_run" = /datum/fire_support/gau,
		"cas_laser_run" = /datum/fire_support/laser,
		"cas_rocket_barrage" = /datum/fire_support/rockets,
	), 0, 0)
	TEST_ASSERT_EQUAL(cas_template.get_action_template("cas_gun_run").shared_cooldown, 12 SECONDS, "CAS gun run should keep its original shared cooldown.")
	TEST_ASSERT_EQUAL(cas_template.get_action_template("cas_laser_run").shared_cooldown, 16 SECONDS, "CAS laser run should keep its original shared cooldown.")
	TEST_ASSERT_EQUAL(cas_template.get_action_template("cas_rocket_barrage").shared_cooldown, 22 SECONDS, "CAS rocket barrage should keep its original shared cooldown.")
	TEST_ASSERT_EQUAL(cas_template.visibility_zone_cooldown, 1000 SECONDS, "CAS should use doubled visibility zone cooldown.")

	var/datum/rto_support_template/heavy/heavy_template = allocate(/datum/rto_support_template/heavy)
	assert_template_actions(heavy_template, list(
		"heavy_missile" = /datum/fire_support/missile,
		"heavy_napalm" = /datum/fire_support/missile/napalm,
	), 0, 0)
	TEST_ASSERT_EQUAL(heavy_template.get_action_template("heavy_missile").shared_cooldown, 18 SECONDS, "Heavy missile strike should keep its original shared cooldown.")
	TEST_ASSERT_EQUAL(heavy_template.get_action_template("heavy_napalm").shared_cooldown, 16 SECONDS, "Heavy napalm strike should keep its original shared cooldown.")
	TEST_ASSERT_EQUAL(heavy_template.visibility_zone_cooldown, 1600 SECONDS, "Heavy strike should use doubled visibility zone cooldown.")

/datum/unit_test/halo_support_two_slot_lifecycle

/datum/unit_test/halo_support_two_slot_lifecycle/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	human.job = JOB_SQUAD_RTO
	var/datum/rto_support_controller/controller = allocate(/datum/rto_support_controller, human)

	TEST_ASSERT(controller.select_template("logistics"), "First package selection should succeed.")
	TEST_ASSERT_EQUAL(length(controller.get_selected_templates()), 1, "First package selection should occupy one slot.")
	TEST_ASSERT(controller.selection_started_at > 0, "First package selection should start the reset timer.")
	TEST_ASSERT(controller.get_selection_reset_ready_in() > 0, "Reset timer should be active after the first selection.")
	TEST_ASSERT(controller.select_template("medical"), "Second unique package selection should succeed.")
	TEST_ASSERT_EQUAL(length(controller.get_selected_templates()), 2, "Second package selection should occupy the second slot.")
	TEST_ASSERT(!controller.select_template("technical"), "A third package should not fit into the two-slot selection model.")
	TEST_ASSERT(!controller.select_template("logistics"), "Selecting a duplicate package should fail.")
	TEST_ASSERT(!controller.can_reset_templates(), "Package reset should remain locked before the timer expires.")

	controller.selection_reset_available_at = world.time
	TEST_ASSERT(controller.can_reset_templates(), "Package reset should unlock once the reset timer expires.")
	TEST_ASSERT(controller.reset_templates(), "Package reset should clear both slots.")
	TEST_ASSERT_EQUAL(length(controller.get_selected_templates()), 0, "Reset should clear all selected packages.")
	TEST_ASSERT_EQUAL(controller.selection_started_at, 0, "Reset should clear the selection start timestamp.")
	TEST_ASSERT(controller.select_template("technical"), "Packages should be selectable again after a full reset.")

/datum/unit_test/halo_support_single_package_zone_discount

/datum/unit_test/halo_support_single_package_zone_discount/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	human.job = JOB_SQUAD_RTO
	var/datum/rto_support_controller/controller = allocate(/datum/rto_support_controller, human)

	TEST_ASSERT(controller.select_template("mortar"), "Single-package zone discount test should select mortar first.")
	TEST_ASSERT_EQUAL(controller.get_solo_visibility_zone_cooldown("mortar"), 300 SECONDS, "Mortar solo sector cooldown preview should be half of the configured cooldown.")
	TEST_ASSERT(controller.uses_single_template_zone_discount("mortar"), "Single selected zone package should activate the solo sector cooldown bonus.")
	TEST_ASSERT_EQUAL(controller.get_effective_visibility_zone_cooldown("mortar"), 300 SECONDS, "Single selected zone package should use the reduced sector cooldown.")

	var/list/ui_entries = controller.build_preset_ui_data()
	var/list/mortar_entry = null
	for(var/list/entry as anything in ui_entries)
		if(entry["template_id"] == "mortar")
			mortar_entry = entry
			break
	TEST_ASSERT_NOTNULL(mortar_entry, "Preset menu should expose mortar template data for the solo cooldown preview.")
	TEST_ASSERT_EQUAL(mortar_entry["visibility_zone_cooldown"], 600, "Preset menu should keep showing the full configured mortar sector cooldown.")
	TEST_ASSERT_EQUAL(mortar_entry["visibility_zone_cooldown_solo"], 300, "Preset menu should show the reduced solo mortar sector cooldown.")
	TEST_ASSERT_EQUAL(mortar_entry["visibility_zone_cooldown_current"], 300, "Preset menu should show the currently active solo mortar sector cooldown.")
	TEST_ASSERT(mortar_entry["solo_zone_cooldown_active"], "Preset menu should mark the solo sector cooldown bonus as active.")

	var/datum/rto_support_template/mortar/mortar_template = controller.get_selected_template("mortar")
	controller.active_zone = allocate(/datum/rto_visibility_zone, human, run_loc_floor_bottom_left, mortar_template)
	controller.clear_active_zone()
	TEST_ASSERT_EQUAL(controller.zone_shared_cooldown_until, world.time + 300 SECONDS, "Clearing a solo-selected mortar sector should apply the reduced shared zone cooldown.")
	TEST_ASSERT_EQUAL(controller.zone_cooldowns_by_template["mortar"], world.time + 300 SECONDS, "Clearing a solo-selected mortar sector should apply the reduced personal zone cooldown.")

	var/mob/living/carbon/human/two_slot_human = allocate(/mob/living/carbon/human)
	two_slot_human.job = JOB_SQUAD_RTO
	var/datum/rto_support_controller/two_slot_controller = allocate(/datum/rto_support_controller, two_slot_human)

	TEST_ASSERT(two_slot_controller.select_template("mortar"), "Two-slot zone discount test should select mortar first.")
	TEST_ASSERT(two_slot_controller.select_template("logistics"), "Two-slot zone discount test should fill the second slot.")
	TEST_ASSERT(!two_slot_controller.uses_single_template_zone_discount("mortar"), "Selecting a second package should disable the solo sector cooldown bonus.")
	TEST_ASSERT_EQUAL(two_slot_controller.get_effective_visibility_zone_cooldown("mortar"), 600 SECONDS, "Two selected packages should restore the full mortar sector cooldown.")

	var/datum/rto_support_template/mortar/two_slot_mortar_template = two_slot_controller.get_selected_template("mortar")
	two_slot_controller.active_zone = allocate(/datum/rto_visibility_zone, two_slot_human, run_loc_floor_bottom_left, two_slot_mortar_template)
	two_slot_controller.clear_active_zone()
	TEST_ASSERT_EQUAL(two_slot_controller.zone_shared_cooldown_until, world.time + 600 SECONDS, "Clearing a sector with two selected packages should apply the full shared zone cooldown.")
	TEST_ASSERT_EQUAL(two_slot_controller.zone_cooldowns_by_template["mortar"], world.time + 600 SECONDS, "Clearing a sector with two selected packages should apply the full personal zone cooldown.")

/datum/unit_test/halo_support_package_shared_cooldowns

/datum/unit_test/halo_support_package_shared_cooldowns/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	human.job = JOB_SQUAD_RTO
	var/datum/rto_support_controller/controller = allocate(/datum/rto_support_controller, human)

	TEST_ASSERT(controller.select_template("logistics"), "Logistics package selection should succeed.")
	TEST_ASSERT(controller.select_template("medical"), "Medical package selection should succeed.")

	controller.shared_cooldowns_by_template["logistics"] = world.time + 50
	TEST_ASSERT(!controller.can_arm_action("logistics_supply", "logistics"), "Package shared cooldown should block the triggering logistics action.")
	TEST_ASSERT(!controller.can_arm_action("logistics_grenade_drop", "logistics"), "Package shared cooldown should also block sibling logistics actions.")
	TEST_ASSERT(controller.can_arm_action("medical_medkits_drop", "medical"), "Package shared cooldown should not block another selected package.")

/datum/unit_test/halo_support_zone_ownership

/datum/unit_test/halo_support_zone_ownership/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	human.job = JOB_SQUAD_RTO
	var/datum/rto_support_controller/controller = allocate(/datum/rto_support_controller, human)

	TEST_ASSERT(controller.select_template("mortar"), "Mortar package selection should succeed.")
	TEST_ASSERT(controller.select_template("cas"), "CAS package selection should succeed.")

	var/datum/rto_support_template/mortar_template = controller.get_selected_template("mortar")
	controller.active_zone = allocate(/datum/rto_visibility_zone, human, run_loc_floor_bottom_left, mortar_template)

	TEST_ASSERT(controller.can_arm_action("mortar_he", "mortar"), "A package should be able to arm zone-based support inside its own active sector.")
	TEST_ASSERT(!controller.can_arm_action("cas_gun_run", "cas"), "Another package should not be able to reuse a foreign active sector.")
	TEST_ASSERT(!controller.can_deploy_zone("cas"), "A second sector should not deploy while another package sector is active.")

	controller.clear_active_zone()
	TEST_ASSERT(controller.get_remaining_zone_shared_cooldown() > 0, "Clearing a sector should start the shared zone cooldown.")
	TEST_ASSERT(controller.get_remaining_zone_cooldown("mortar") > 0, "Clearing a sector should start the personal zone cooldown for the source package.")
	TEST_ASSERT_EQUAL(controller.get_remaining_zone_cooldown("cas"), 0, "A different package should not inherit the source package personal zone cooldown.")

/datum/unit_test/halo_support_payload_contents

/datum/unit_test/halo_support_payload_contents/Run()
	var/list/crate_expectations = list(
		/obj/structure/largecrate/supply/ammo/halo/rifle = list(
			/obj/item/ammo_box/magazine/unsc/ma5c = 1,
			/obj/item/ammo_box/magazine/unsc/ma5b = 1,
			/obj/item/ammo_box/magazine/unsc/br55 = 1,
			/obj/item/ammo_box/magazine/unsc/small/m6c = 1,
		),
		/obj/structure/largecrate/supply/ammo/halo/marksman = list(
			/obj/item/ammo_magazine/rifle/halo/dmr = 4,
			/obj/item/ammo_magazine/pistol/halo/m6d = 2,
		),
		/obj/structure/largecrate/supply/ammo/halo/pdw = list(
			/obj/item/ammo_magazine/smg/halo/m7 = 6,
			/obj/item/ammo_box/magazine/unsc/small/m6c = 2,
		),
		/obj/structure/largecrate/supply/ammo/halo/shotgun = list(
			/obj/item/ammo_magazine/shotgun/buckshot/unsc = 6,
		),
		/obj/structure/largecrate/supply/ammo/halo/sniper = list(
			/obj/item/ammo_magazine/rifle/halo/sniper = 8,
		),
		/obj/structure/largecrate/supply/ammo/halo/spnkr = list(
			/obj/item/ammo_magazine/spnkr = 4,
		),
		/obj/structure/largecrate/supply/ammo/halo/grenadier = list(
			/obj/item/ammo_box/magazine/misc/unsc/grenade/launchable = 2,
			/obj/item/ammo_box/magazine/misc/unsc/grenade = 1,
		),
		/obj/structure/largecrate/supply/medicine/halo/medical_packets = list(
			/obj/item/ammo_box/magazine/misc/unsc/medical_packets = 4,
			/obj/item/storage/syringe_case/unsc/morphine/full = 2,
		),
		/obj/structure/largecrate/supply/medicine/halo/corpsman_kit = list(
			/obj/item/storage/firstaid/unsc/corpsman = 2,
			/obj/item/storage/belt/medical/lifesaver/unsc/full = 1,
			/obj/item/storage/pouch/medkit/unsc/full = 1,
		),
		/obj/structure/largecrate/supply/medicine/halo/biofoam_reserve = list(
			/obj/item/reagent_container/hypospray/autoinjector/primeable/biofoam = 4,
			/obj/item/reagent_container/hypospray/autoinjector/primeable/biofoam/antidote = 2,
			/obj/item/storage/syringe_case/unsc/burnguard = 2,
		),
		/obj/structure/largecrate/supply/supplies/halo/toolbox = list(
			/obj/item/storage/toolbox/traxus/big = 2,
			/obj/item/storage/box/kit/engineering_supply_kit = 1,
			/obj/item/storage/backpack/marine/engineerpack/welder_chestrig = 1,
		),
		/obj/structure/largecrate/supply/supplies/halo/fortification = list(
			/obj/item/stack/sandbags_empty/half = 2,
			/obj/item/stack/sheet/plasteel/med_large_stack = 1,
			/obj/item/stack/folding_barricade/three = 1,
			/obj/item/storage/box/explosive_mines = 1,
		),
		/obj/structure/largecrate/supply/explosives/halo/breaching = list(
			/obj/item/explosive/plastic = 4,
			/obj/item/explosive/plastic/breaching_charge = 2,
			/obj/item/tool/shovel/etool/folded = 1,
			/obj/item/tool/crowbar = 1,
			/obj/item/clothing/glasses/welding = 1,
		),
		/obj/structure/largecrate/supply/supplies/halo/vehicle_service = list(
			/obj/item/storage/toolbox/traxus/big = 1,
			/obj/item/tool/weldingtool = 2,
			/obj/item/tool/weldpack/minitank = 1,
			/obj/item/tool/extinguisher/mini = 1,
			/obj/item/stack/sheet/metal/large_stack = 1,
			/obj/item/stack/sheet/plasteel/med_large_stack = 1,
			/obj/item/cell/high = 1,
		),
		/obj/structure/largecrate/supply/supplies/halo/signal = list(
			/obj/item/storage/box/flare = 2,
			/obj/item/storage/box/flare/signal = 1,
			/obj/item/storage/pouch/flare/full = 1,
			/obj/item/weapon/gun/flare = 1,
		),
		/obj/structure/largecrate/supply/supplies/halo/recon = list(
			/obj/item/device/binoculars/range/monocular = 2,
			/obj/item/device/motiondetector = 1,
			/obj/item/map/current_map = 1,
			/obj/item/device/flashlight/combat = 1,
		),
		/obj/structure/largecrate/supply/supplies/halo/rto_command = list(
			/obj/item/storage/backpack/marine/satchel/rto/unsc = 1,
			/obj/item/device/binoculars/range/designator = 1,
			/obj/item/storage/pouch/radio = 1,
			/obj/item/device/radio = 2,
			/obj/item/device/encryptionkey/jtac = 1,
			/obj/item/storage/box/flare/signal = 1,
		),
		/obj/structure/largecrate/supply/supplies/rto/technical_fortification = list(
			/obj/item/stack/sheet/metal/large_stack = 2,
			/obj/item/stack/sheet/plasteel/medium_stack = 1,
			/obj/item/stack/sandbags/large_stack = 2,
		),
		/obj/structure/largecrate/supply/supplies/rto/technical_power = list(
			/obj/structure/machinery/power/port_gen/pacman = 1,
			/obj/structure/machinery/floodlight = 2,
			/obj/item/stack/cable_coil/yellow = 3,
			/obj/item/stack/sheet/mineral/phoron/medium_stack = 1,
		),
		/obj/structure/largecrate/supply/supplies/rto/technical_recon = list(
			/obj/item/device/motiondetector = 2,
			/obj/item/storage/box/flare/signal = 1,
			/obj/item/map/current_map = 1,
			/obj/item/device/flashlight/combat = 1,
		),
	)

	for(var/crate_path in crate_expectations)
		var/obj/structure/largecrate/supply/crate = allocate(crate_path)
		assert_expected_supplies(crate.supplies, crate_expectations[crate_path], "[crate_path]")

/datum/unit_test/halo_support_admin_bridge

/datum/unit_test/halo_support_admin_bridge/Run()
	var/list/expected_routing = list(
		"HALO Rifle Ammo Drop" = /datum/fire_support/supply_drop/halo/rifle,
		"HALO Marksman Ammo Drop" = /datum/fire_support/supply_drop/halo/marksman,
		"HALO PDW Ammo Drop" = /datum/fire_support/supply_drop/halo/pdw,
		"HALO Shotgun Ammo Drop" = /datum/fire_support/supply_drop/halo/shotgun,
		"HALO Sniper Ammo Drop" = /datum/fire_support/supply_drop/halo/sniper,
		"HALO SPNKr Ammo Drop" = /datum/fire_support/supply_drop/halo/spnkr,
		"HALO Grenadier Ammo Drop" = /datum/fire_support/supply_drop/halo/grenadier,
		"HALO Medical Packets Drop" = /datum/fire_support/supply_drop/halo/medical_packets,
		"HALO Corpsman Kit Drop" = /datum/fire_support/supply_drop/halo/corpsman_kit,
		"HALO Biofoam Reserve Drop" = /datum/fire_support/supply_drop/halo/biofoam_reserve,
		"HALO Toolbox Drop" = /datum/fire_support/supply_drop/halo/toolbox,
		"HALO Fortification Drop" = /datum/fire_support/supply_drop/halo/fortification,
		"HALO Breaching Drop" = /datum/fire_support/supply_drop/halo/breaching,
		"HALO Vehicle Service Drop" = /datum/fire_support/supply_drop/halo/vehicle_service,
		"HALO Signal Drop" = /datum/fire_support/supply_drop/halo/signal,
		"HALO Recon Drop" = /datum/fire_support/supply_drop/halo/recon,
		"HALO RTO Command Drop" = /datum/fire_support/supply_drop/halo/rto_command,
	)
	var/list/expected_sections = list(
		"halo_logistics" = list(
			"title" = "HALO Logistics",
			"options" = list(
				"HALO Rifle Ammo Drop",
				"HALO Marksman Ammo Drop",
				"HALO PDW Ammo Drop",
				"HALO Shotgun Ammo Drop",
				"HALO Sniper Ammo Drop",
				"HALO SPNKr Ammo Drop",
				"HALO Grenadier Ammo Drop",
			),
		),
		"halo_medical" = list(
			"title" = "HALO Medical",
			"options" = list(
				"HALO Medical Packets Drop",
				"HALO Corpsman Kit Drop",
				"HALO Biofoam Reserve Drop",
			),
		),
		"halo_technical" = list(
			"title" = "HALO Technical",
			"options" = list(
				"HALO Toolbox Drop",
				"HALO Fortification Drop",
				"HALO Breaching Drop",
				"HALO Vehicle Service Drop",
				"HALO Signal Drop",
				"HALO Recon Drop",
				"HALO RTO Command Drop",
			),
		),
	)

	var/datum/fire_support_menu/menu = allocate(/datum/fire_support_menu/unit_test_stub)
	var/list/static_data = menu.ui_static_data(null)
	var/list/custom_sections = static_data["custom_ordnance_sections"]

	TEST_ASSERT_EQUAL(length(custom_sections), 3, "GM fire support menu should expose exactly three HALO custom ordnance sections.")

	for(var/label in expected_routing)
		TEST_ASSERT(label in static_data["ordnance_options"], "GM fire support menu did not expose [label] in the full ordnance list.")
		TEST_ASSERT(!(label in static_data["misc_ordnance_options"]), "GM fire support menu should not duplicate [label] in legacy misc ordnance options.")
		TEST_ASSERT_EQUAL(menu.resolve_custom_fire_support(label), expected_routing[label], "[label] no longer resolves to the intended HALO payload.")

	for(var/section_id in expected_sections)
		var/list/section = find_custom_ordnance_section(custom_sections, section_id)
		TEST_ASSERT_NOTNULL(section, "GM fire support menu is missing the [section_id] custom section.")
		TEST_ASSERT_EQUAL(section["title"], expected_sections[section_id]["title"], "[section_id] custom section has an unexpected title.")
		assert_expected_values(section["options"], expected_sections[section_id]["options"], "[section_id] custom ordnance section")
