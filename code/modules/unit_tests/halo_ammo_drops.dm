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

/datum/unit_test/proc/assert_template_charge_pool(datum/rto_support_template/template, expected_capacity, expected_starting_charges = null, expected_recharge_interval = null, expected_recharge_amount = 1)
	if(isnull(expected_starting_charges))
		expected_starting_charges = expected_capacity
	TEST_ASSERT_EQUAL(template.support_resource_mode, RTO_SUPPORT_RESOURCE_MODE_CHARGES, "[template.template_id] should use the charge resource model.")
	TEST_ASSERT_EQUAL(template.support_pool_capacity, expected_capacity, "[template.template_id] drifted from its expected charge capacity.")
	TEST_ASSERT_EQUAL(template.support_pool_starting_charges, expected_starting_charges, "[template.template_id] drifted from its expected starting charges.")
	if(!isnull(expected_recharge_interval))
		TEST_ASSERT_EQUAL(template.support_pool_recharge_interval, expected_recharge_interval, "[template.template_id] drifted from its expected recharge interval.")
	TEST_ASSERT_EQUAL(template.support_pool_recharge_amount, expected_recharge_amount, "[template.template_id] drifted from its expected recharge amount.")
	TEST_ASSERT(template.support_pool_auto_recharge, "[template.template_id] should keep auto-recharge enabled by default.")

/datum/unit_test/proc/assert_action_charge_values(datum/rto_support_action_template/action_template, expected_cost, expected_lockout, label)
	TEST_ASSERT_NOTNULL(action_template, "[label] is missing its action template.")
	TEST_ASSERT_EQUAL(action_template.support_pool_cost, expected_cost, "[label] drifted from its expected charge cost.")
	TEST_ASSERT_EQUAL(action_template.personal_lockout, expected_lockout, "[label] drifted from its expected local lockout.")

/datum/unit_test/proc/assert_template_charge_actions(datum/rto_support_template/template, list/expected_values)
	for(var/action_id in expected_values)
		var/list/expected = expected_values[action_id]
		assert_action_charge_values(template.get_action_template(action_id), expected[1], expected[2], "[template.template_id] action [action_id]")

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

/datum/rto_support_action_template/unit_test_charge_light
	action_id = "unit_test_charge_light"
	name = "Charge light"
	description = "Unit test light call."
	fire_support_path = /datum/fire_support/supply_drop
	requires_visibility_zone = FALSE
	allow_closed_turf = FALSE
	support_pool_cost = 1
	personal_lockout = 2 SECONDS

/datum/rto_support_action_template/unit_test_charge_heavy
	action_id = "unit_test_charge_heavy"
	name = "Charge heavy"
	description = "Unit test heavy call."
	fire_support_path = /datum/fire_support/supply_drop
	requires_visibility_zone = FALSE
	allow_closed_turf = FALSE
	support_pool_cost = 3
	personal_lockout = 4 SECONDS

/datum/rto_support_template/unit_test_charges
	template_id = "unit_test_charges"
	name = "Unit Test Charges"
	description = "Synthetic charge-based template for runtime tests."
	role_summary = "Unit test package."
	targeting_summary = "No sector required."
	requires_visibility_zone = FALSE
	visibility_zone_name = ""
	visibility_zone_type = ""
	visibility_zone_radius = 0
	visibility_zone_duration = 0
	visibility_zone_cooldown = 0
	support_resource_mode = RTO_SUPPORT_RESOURCE_MODE_CHARGES
	support_pool_capacity = 3
	support_pool_starting_charges = 3
	support_pool_recharge_interval = 30 SECONDS
	support_pool_recharge_amount = 1
	support_pool_auto_recharge = TRUE
	action_template_types = list(
		/datum/rto_support_action_template/unit_test_charge_light,
		/datum/rto_support_action_template/unit_test_charge_heavy,
	)

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
	assert_template_charge_pool(logistics_template, 3, 3, 120 SECONDS, 1)
	assert_template_charge_actions(logistics_template, list(
		"halo_rifle_ammo_drop" = list(1, 3 SECONDS),
		"halo_marksman_ammo_drop" = list(1, 3 SECONDS),
		"halo_pdw_ammo_drop" = list(1, 3 SECONDS),
		"halo_shotgun_ammo_drop" = list(1, 3 SECONDS),
		"halo_sniper_ammo_drop" = list(1, 3 SECONDS),
		"halo_spnkr_ammo_drop" = list(1, 3 SECONDS),
		"halo_grenadier_ammo_drop" = list(1, 3 SECONDS),
	))

	var/datum/rto_support_template/halo_medical/medical_template = allocate(/datum/rto_support_template/halo_medical)
	assert_template_actions(medical_template, list(
		"halo_medical_packets_drop" = /datum/fire_support/supply_drop/halo/medical_packets,
		"halo_corpsman_kit_drop" = /datum/fire_support/supply_drop/halo/corpsman_kit,
		"halo_biofoam_reserve_drop" = /datum/fire_support/supply_drop/halo/biofoam_reserve,
	), 240 SECONDS, 600 SECONDS)
	assert_template_charge_pool(medical_template, 3, 3, 120 SECONDS, 1)
	assert_template_charge_actions(medical_template, list(
		"halo_medical_packets_drop" = list(1, 3 SECONDS),
		"halo_corpsman_kit_drop" = list(1, 3 SECONDS),
		"halo_biofoam_reserve_drop" = list(1, 3 SECONDS),
	))

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
	assert_template_charge_pool(technical_template, 3, 3, 120 SECONDS, 1)
	TEST_ASSERT_EQUAL(technical_template.get_action_template("halo_toolbox_drop").shared_cooldown, 360 SECONDS, "HALO engineering-derived technical drops should keep doubled engineering shared cooldowns.")
	TEST_ASSERT_EQUAL(technical_template.get_action_template("halo_signal_drop").shared_cooldown, 240 SECONDS, "HALO command-derived technical drops should keep doubled command shared cooldowns.")
	assert_template_charge_actions(technical_template, list(
		"halo_toolbox_drop" = list(2, 3 SECONDS),
		"halo_fortification_drop" = list(2, 3 SECONDS),
		"halo_breaching_drop" = list(2, 3 SECONDS),
		"halo_vehicle_service_drop" = list(2, 3 SECONDS),
		"halo_signal_drop" = list(1, 3 SECONDS),
		"halo_recon_drop" = list(1, 3 SECONDS),
		"halo_rto_command_drop" = list(1, 3 SECONDS),
	))

	var/datum/rto_support_template/logistics/uscm_logistics_template = allocate(/datum/rto_support_template/logistics)
	assert_template_actions(uscm_logistics_template, list(
		"logistics_rifle_mag_drop" = /datum/fire_support/supply_drop/uscm/rifle,
		"logistics_rifle_box_drop" = /datum/fire_support/supply_drop/uscm/rifle_box,
		"logistics_shotgun_ammo_drop" = /datum/fire_support/supply_drop/uscm/shotgun/compact,
		"logistics_smg_ammo_drop" = /datum/fire_support/supply_drop/uscm/smg/compact,
		"logistics_sidearm_ammo_drop" = /datum/fire_support/supply_drop/uscm/sidearm/compact,
		"logistics_mine_crate" = /datum/fire_support/supply_drop/mine_crate,
		"logistics_mini_sentry" = /datum/fire_support/sentry_drop/mini,
		"logistics_full_sentry" = /datum/fire_support/sentry_drop/full,
		"logistics_grenade_drop" = /datum/fire_support/supply_drop/grenade_crate,
		"logistics_sentry_ammo_drop" = /datum/fire_support/supply_drop/sentry_ammo,
	))
	assert_template_charge_pool(uscm_logistics_template, 3, 3, 120 SECONDS, 1)
	TEST_ASSERT_EQUAL(uscm_logistics_template.get_action_template("logistics_rifle_mag_drop").shared_cooldown, 240 SECONDS, "USCM rifle magazine drop should keep the standard logistics cooldown.")
	TEST_ASSERT_EQUAL(uscm_logistics_template.get_action_template("logistics_rifle_box_drop").support_pool_cost, 2, "USCM bulk rifle ammo should remain the heavy ammo option in logistics.")
	TEST_ASSERT_EQUAL(uscm_logistics_template.get_action_template("logistics_mine_crate").shared_cooldown, 180 SECONDS, "USCM mine crate drop should use doubled shared cooldown.")
	TEST_ASSERT_EQUAL(uscm_logistics_template.get_action_template("logistics_full_sentry").shared_cooldown, 360 SECONDS, "USCM full sentry drop should use doubled shared cooldown.")
	assert_template_charge_actions(uscm_logistics_template, list(
		"logistics_rifle_mag_drop" = list(1, 3 SECONDS),
		"logistics_rifle_box_drop" = list(2, 3 SECONDS),
		"logistics_shotgun_ammo_drop" = list(1, 3 SECONDS),
		"logistics_smg_ammo_drop" = list(1, 3 SECONDS),
		"logistics_sidearm_ammo_drop" = list(1, 3 SECONDS),
		"logistics_mine_crate" = list(1, 3 SECONDS),
		"logistics_mini_sentry" = list(1, 3 SECONDS),
		"logistics_full_sentry" = list(2, 3 SECONDS),
		"logistics_grenade_drop" = list(1, 3 SECONDS),
		"logistics_sentry_ammo_drop" = list(1, 3 SECONDS),
	))

	var/datum/rto_support_template/medical/uscm_medical_template = allocate(/datum/rto_support_template/medical)
	assert_template_actions(uscm_medical_template, list(
		"medical_medkits_drop" = /datum/fire_support/supply_drop/medical_medkits,
		"medical_blood_drop" = /datum/fire_support/supply_drop/medical_blood,
		"medical_iv_drop" = /datum/fire_support/supply_drop/medical_iv,
		"medical_optable_drop" = /datum/fire_support/supply_drop/medical_optable,
	))
	assert_template_charge_pool(uscm_medical_template, 3, 3, 120 SECONDS, 1)
	TEST_ASSERT_EQUAL(uscm_medical_template.get_action_template("medical_medkits_drop").shared_cooldown, 240 SECONDS, "USCM medical drops should use doubled shared cooldowns.")
	TEST_ASSERT_EQUAL(uscm_medical_template.get_action_template("medical_optable_drop").shared_cooldown, 360 SECONDS, "USCM operation table drop should keep the longer shared cooldown.")
	assert_template_charge_actions(uscm_medical_template, list(
		"medical_medkits_drop" = list(1, 3 SECONDS),
		"medical_blood_drop" = list(1, 3 SECONDS),
		"medical_iv_drop" = list(1, 3 SECONDS),
		"medical_optable_drop" = list(2, 3 SECONDS),
	))

	var/datum/rto_support_template/technical/uscm_technical_template = allocate(/datum/rto_support_template/technical)
	assert_template_actions(uscm_technical_template, list(
		"technical_fortification_drop" = /datum/fire_support/supply_drop/technical_fortification,
		"technical_power_drop" = /datum/fire_support/supply_drop/technical_power,
		"technical_recon_drop" = /datum/fire_support/supply_drop/technical_recon,
		"technical_powerloader_drop" = /datum/fire_support/supply_drop/technical_powerloader,
	), 0, 0)
	assert_template_charge_pool(uscm_technical_template, 3, 3, 120 SECONDS, 1)
	TEST_ASSERT_EQUAL(uscm_technical_template.get_action_template("technical_recon_drop").shared_cooldown, 240 SECONDS, "USCM technical recon drop should use the medium shared cooldown.")
	TEST_ASSERT_EQUAL(uscm_technical_template.get_action_template("technical_powerloader_drop").shared_cooldown, 360 SECONDS, "USCM powerloader drop should use the longer technical shared cooldown.")
	assert_template_charge_actions(uscm_technical_template, list(
		"technical_fortification_drop" = list(2, 3 SECONDS),
		"technical_power_drop" = list(2, 3 SECONDS),
		"technical_recon_drop" = list(1, 3 SECONDS),
		"technical_powerloader_drop" = list(2, 3 SECONDS),
	))

	var/datum/rto_support_template/mortar/mortar_template = allocate(/datum/rto_support_template/mortar)
	assert_template_actions(mortar_template, list(
		"mortar_he" = /datum/fire_support/mortar/rto_single,
		"mortar_smoke" = /datum/fire_support/mortar/smoke/rto_single,
		"mortar_incendiary" = /datum/fire_support/mortar/incendiary/rto_single,
	), 0, 0)
	assert_template_charge_pool(mortar_template, 5, 5, 75 SECONDS, 1)
	TEST_ASSERT_EQUAL(mortar_template.get_action_template("mortar_he").shared_cooldown, 4 SECONDS, "Mortar HE should keep its original shared cooldown.")
	TEST_ASSERT_EQUAL(mortar_template.get_action_template("mortar_smoke").shared_cooldown, 3 SECONDS, "Mortar smoke should keep its original shared cooldown.")
	TEST_ASSERT_EQUAL(mortar_template.get_action_template("mortar_incendiary").shared_cooldown, 6 SECONDS, "Mortar incendiary should keep its original shared cooldown.")
	TEST_ASSERT_EQUAL(mortar_template.visibility_zone_cooldown, 3 SECONDS, "Mortar should use a short anti-spam sector cooldown.")
	assert_template_charge_actions(mortar_template, list(
		"mortar_he" = list(1, 3 SECONDS),
		"mortar_smoke" = list(1, 3 SECONDS),
		"mortar_incendiary" = list(2, 3 SECONDS),
	))

	var/datum/rto_support_template/cas/cas_template = allocate(/datum/rto_support_template/cas)
	assert_template_actions(cas_template, list(
		"cas_gun_run" = /datum/fire_support/gau,
		"cas_laser_run" = /datum/fire_support/laser,
		"cas_rocket_barrage" = /datum/fire_support/rockets,
	), 0, 0)
	assert_template_charge_pool(cas_template, 3, 3, 150 SECONDS, 1)
	TEST_ASSERT_EQUAL(cas_template.get_action_template("cas_gun_run").shared_cooldown, 12 SECONDS, "CAS gun run should keep its original shared cooldown.")
	TEST_ASSERT_EQUAL(cas_template.get_action_template("cas_laser_run").shared_cooldown, 16 SECONDS, "CAS laser run should keep its original shared cooldown.")
	TEST_ASSERT_EQUAL(cas_template.get_action_template("cas_rocket_barrage").shared_cooldown, 22 SECONDS, "CAS rocket barrage should keep its original shared cooldown.")
	TEST_ASSERT_EQUAL(cas_template.visibility_zone_cooldown, 3 SECONDS, "CAS should use a short anti-spam sector cooldown.")
	assert_template_charge_actions(cas_template, list(
		"cas_gun_run" = list(1, 3 SECONDS),
		"cas_laser_run" = list(1, 3 SECONDS),
		"cas_rocket_barrage" = list(3, 3 SECONDS),
	))

	var/datum/rto_support_template/heavy/heavy_template = allocate(/datum/rto_support_template/heavy)
	assert_template_actions(heavy_template, list(
		"heavy_missile" = /datum/fire_support/missile,
		"heavy_napalm" = /datum/fire_support/missile/napalm,
	), 0, 0)
	assert_template_charge_pool(heavy_template, 3, 3, 180 SECONDS, 1)
	TEST_ASSERT_EQUAL(heavy_template.get_action_template("heavy_missile").shared_cooldown, 18 SECONDS, "Heavy missile strike should keep its original shared cooldown.")
	TEST_ASSERT_EQUAL(heavy_template.get_action_template("heavy_napalm").shared_cooldown, 16 SECONDS, "Heavy napalm strike should keep its original shared cooldown.")
	TEST_ASSERT_EQUAL(heavy_template.visibility_zone_cooldown, 3 SECONDS, "Heavy strike should use a short anti-spam sector cooldown.")
	assert_template_charge_actions(heavy_template, list(
		"heavy_missile" = list(1, 3 SECONDS),
		"heavy_napalm" = list(3, 3 SECONDS),
	))

/datum/unit_test/halo_support_two_slot_lifecycle

/datum/unit_test/halo_support_two_slot_lifecycle/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	human.job = JOB_SQUAD_RTO
	var/datum/rto_support_controller/controller = allocate(/datum/rto_support_controller, human)

	TEST_ASSERT_EQUAL(controller.get_max_selected_templates(), 2, "Default RTO package slot count should stay at two.")
	TEST_ASSERT_EQUAL(controller.get_selection_reset_delay_minutes(), 60, "Default RTO package reset delay should stay at sixty minutes.")
	TEST_ASSERT(controller.select_template("logistics"), "First package selection should succeed.")
	TEST_ASSERT_EQUAL(length(controller.get_selected_templates()), 1, "First package selection should occupy one slot.")
	TEST_ASSERT(controller.selection_started_at > 0, "First package selection should start the reset timer.")
	TEST_ASSERT(controller.get_selection_reset_ready_in() > 0, "Reset timer should be active after the first selection.")
	TEST_ASSERT_EQUAL(controller.selection_reset_available_at - controller.selection_started_at, 60 MINUTES, "Default package reset timer should use the expected delay.")
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
	TEST_ASSERT_EQUAL(controller.get_solo_visibility_zone_cooldown("mortar"), 3 SECONDS, "Mortar should expose the short anti-spam sector cooldown.")
	TEST_ASSERT(!controller.uses_single_template_zone_discount("mortar"), "Zero-cooldown sectors should not expose a solo cooldown bonus.")
	TEST_ASSERT_EQUAL(controller.get_effective_visibility_zone_cooldown("mortar"), 3 SECONDS, "Single selected zone package should use the short anti-spam sector cooldown.")

	var/list/ui_entries = controller.build_preset_ui_data()
	var/list/mortar_entry = null
	for(var/list/entry as anything in ui_entries)
		if(entry["template_id"] == "mortar")
			mortar_entry = entry
			break
	TEST_ASSERT_NOTNULL(mortar_entry, "Preset menu should expose mortar template data for the solo cooldown preview.")
	TEST_ASSERT_EQUAL(mortar_entry["visibility_zone_cooldown"], 3, "Preset menu should show the short mortar sector anti-spam cooldown.")
	TEST_ASSERT_EQUAL(mortar_entry["visibility_zone_cooldown_solo"], 3, "Preset menu should show the same short mortar sector cooldown without a solo bonus.")
	TEST_ASSERT_EQUAL(mortar_entry["visibility_zone_cooldown_current"], 3, "Preset menu should show the active short mortar sector cooldown.")
	TEST_ASSERT(!mortar_entry["solo_zone_cooldown_active"], "Preset menu should not mark a solo sector bonus as active.")

	var/datum/rto_support_template/mortar/mortar_template = controller.get_selected_template("mortar")
	controller.active_zone = allocate(/datum/rto_visibility_zone, human, run_loc_floor_bottom_left, mortar_template)
	controller.clear_active_zone()
	TEST_ASSERT_EQUAL(controller.zone_shared_cooldown_until, 0, "Clearing a solo-selected mortar sector should not apply a shared zone cooldown.")
	TEST_ASSERT_EQUAL(controller.get_remaining_zone_cooldown("mortar"), 3 SECONDS, "Clearing a solo-selected mortar sector should apply only the short personal anti-spam cooldown.")

	var/mob/living/carbon/human/two_slot_human = allocate(/mob/living/carbon/human)
	two_slot_human.job = JOB_SQUAD_RTO
	var/datum/rto_support_controller/two_slot_controller = allocate(/datum/rto_support_controller, two_slot_human)

	TEST_ASSERT(two_slot_controller.select_template("mortar"), "Two-slot zone discount test should select mortar first.")
	TEST_ASSERT(two_slot_controller.select_template("logistics"), "Two-slot zone discount test should fill the second slot.")
	TEST_ASSERT(!two_slot_controller.uses_single_template_zone_discount("mortar"), "Selecting a second package should not create a solo cooldown bonus.")
	TEST_ASSERT_EQUAL(two_slot_controller.get_effective_visibility_zone_cooldown("mortar"), 3 SECONDS, "Two selected packages should still keep the short sector anti-spam cooldown.")

	var/datum/rto_support_template/mortar/two_slot_mortar_template = two_slot_controller.get_selected_template("mortar")
	two_slot_controller.active_zone = allocate(/datum/rto_visibility_zone, two_slot_human, run_loc_floor_bottom_left, two_slot_mortar_template)
	two_slot_controller.clear_active_zone()
	TEST_ASSERT_EQUAL(two_slot_controller.zone_shared_cooldown_until, 0, "Clearing a sector with two selected packages should not apply a shared zone cooldown.")
	TEST_ASSERT_EQUAL(two_slot_controller.get_remaining_zone_cooldown("mortar"), 3 SECONDS, "Clearing a sector with two selected packages should apply only the short personal anti-spam cooldown.")

/datum/unit_test/halo_support_package_shared_charges

/datum/unit_test/halo_support_package_shared_charges/Run()
	var/datum/game_rule_state/rules = GLOB.game_rule_state
	rules.reset_rto_rules()

	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	human.job = JOB_SQUAD_RTO
	var/datum/rto_support_controller/controller = allocate(/datum/rto_support_controller, human)

	TEST_ASSERT(controller.select_template("logistics"), "Logistics package selection should succeed.")
	TEST_ASSERT(controller.select_template("medical"), "Medical package selection should succeed.")

	var/datum/rto_support_template/logistics/logistics_template = controller.get_selected_template("logistics")
	var/datum/rto_support_template/medical/medical_template = controller.get_selected_template("medical")
	var/datum/rto_support_action_template/logistics_rifle_mag_drop/supply_action = logistics_template.get_action_template("logistics_rifle_mag_drop")
	var/datum/rto_support_action_template/logistics_full_sentry/full_sentry_action = logistics_template.get_action_template("logistics_full_sentry")
	var/datum/rto_support_resource_pool_state/logistics_pool = controller.get_support_pool(logistics_template, TRUE)

	TEST_ASSERT_EQUAL(controller.get_support_pool_current_charges(logistics_template), 3, "Logistics package should start with the configured shared charges.")
	TEST_ASSERT(controller.can_arm_action(supply_action.action_id, logistics_template.template_id), "Light logistics support should be available with a full pool.")
	TEST_ASSERT(controller.can_arm_action(full_sentry_action.action_id, logistics_template.template_id), "Heavy logistics support should be available with a full pool.")
	TEST_ASSERT(controller.apply_action_resource_consumption(logistics_template, supply_action), "Spending one logistics charge should succeed.")
	TEST_ASSERT_EQUAL(controller.get_support_pool_current_charges(logistics_template), 2, "Light logistics support should consume exactly one shared charge.")
	TEST_ASSERT(controller.can_arm_action(full_sentry_action.action_id, logistics_template.template_id), "Heavy logistics support should still be available while the pool can pay its weighted cost.")
	TEST_ASSERT(controller.can_arm_action("logistics_shotgun_ammo_drop", "logistics"), "Another light logistics action should still be available after spending one shared charge.")
	TEST_ASSERT(controller.apply_action_resource_consumption(logistics_template, supply_action), "A second logistics light action should still spend one charge successfully.")
	TEST_ASSERT_EQUAL(controller.get_support_pool_current_charges(logistics_template), 1, "Two light logistics actions should leave one shared charge.")
	TEST_ASSERT(!controller.can_arm_action(full_sentry_action.action_id, logistics_template.template_id), "Heavy logistics support should be blocked once the pool drops below its weighted cost.")
	TEST_ASSERT(controller.can_arm_action("medical_medkits_drop", "medical"), "Logistics charges should not block another selected package.")

	logistics_pool.next_recharge_at = world.time
	TEST_ASSERT_EQUAL(controller.get_support_pool_current_charges(logistics_template), 2, "Logistics charge pool should recharge by one charge on its next tick.")

	var/mob/living/carbon/human/mortar_human = allocate(/mob/living/carbon/human)
	mortar_human.job = JOB_SQUAD_RTO
	var/datum/rto_support_controller/mortar_controller = allocate(/datum/rto_support_controller, mortar_human)

	TEST_ASSERT(mortar_controller.select_template("mortar"), "Mortar package selection should succeed.")
	var/datum/rto_support_template/mortar/mortar_template = mortar_controller.get_selected_template("mortar")
	var/datum/rto_support_action_template/mortar_incendiary/incendiary_action = mortar_template.get_action_template("mortar_incendiary")
	var/datum/rto_support_action_template/mortar_he/he_action = mortar_template.get_action_template("mortar_he")
	var/datum/rto_support_action_template/mortar_smoke/smoke_action = mortar_template.get_action_template("mortar_smoke")

	TEST_ASSERT_EQUAL(mortar_controller.get_support_pool_current_charges(mortar_template), 5, "Mortar package should start with the configured shared charges.")
	TEST_ASSERT(mortar_controller.apply_action_resource_consumption(mortar_template, incendiary_action), "Weighted mortar incendiary shot should spend charges successfully.")
	TEST_ASSERT_EQUAL(mortar_controller.get_support_pool_current_charges(mortar_template), 3, "Incendiary mortar should spend two shared charges.")
	TEST_ASSERT(mortar_controller.can_arm_action(he_action.action_id, mortar_template.template_id), "Mortar HE should stay available after a heavier sibling consumes charges.")
	TEST_ASSERT(mortar_controller.can_arm_action(incendiary_action.action_id, mortar_template.template_id), "Mortar incendiary should stay available while its weighted cost can still be paid.")
	TEST_ASSERT(mortar_controller.apply_action_resource_consumption(mortar_template, he_action), "Mortar HE should spend one charge successfully.")
	TEST_ASSERT_EQUAL(mortar_controller.get_support_pool_current_charges(mortar_template), 2, "Mortar HE should spend one shared charge.")
	TEST_ASSERT(mortar_controller.apply_action_resource_consumption(mortar_template, smoke_action), "Mortar smoke should spend one charge successfully.")
	TEST_ASSERT_EQUAL(mortar_controller.get_support_pool_current_charges(mortar_template), 1, "Mortar smoke should spend one shared charge.")
	TEST_ASSERT(!mortar_controller.can_arm_action(incendiary_action.action_id, mortar_template.template_id), "Mortar incendiary should be blocked once the remaining pool can no longer pay its weighted cost.")

	var/mob/living/carbon/human/cas_human = allocate(/mob/living/carbon/human)
	cas_human.job = JOB_SQUAD_RTO
	var/datum/rto_support_controller/cas_controller = allocate(/datum/rto_support_controller, cas_human)

	TEST_ASSERT(cas_controller.select_template("cas"), "CAS package selection should succeed.")
	var/datum/rto_support_template/cas/cas_template = cas_controller.get_selected_template("cas")
	var/datum/rto_support_action_template/cas_gun_run/cas_gun_action = cas_template.get_action_template("cas_gun_run")
	var/datum/rto_support_action_template/cas_rocket_barrage/cas_rocket_action = cas_template.get_action_template("cas_rocket_barrage")

	TEST_ASSERT(cas_controller.can_arm_action(cas_rocket_action.action_id, cas_template.template_id), "Heavy CAS strike should be available with a full pool.")
	TEST_ASSERT(cas_controller.apply_action_resource_consumption(cas_template, cas_gun_action), "Light CAS strike should spend one charge successfully.")
	TEST_ASSERT_EQUAL(cas_controller.get_support_pool_current_charges(cas_template), 2, "Light CAS strike should leave two charges in the shared pool.")
	TEST_ASSERT_EQUAL(cas_controller.get_remaining_action_cooldown(cas_gun_action.action_id), 3 SECONDS, "CAS anti-spam lockout should not exceed three seconds.")
	TEST_ASSERT(!cas_controller.can_arm_action(cas_rocket_action.action_id, cas_template.template_id), "Heavy CAS strike should be blocked once a light strike has consumed part of the full-price pool.")

/datum/unit_test/halo_support_charge_pool_runtime

/datum/unit_test/halo_support_charge_pool_runtime/Run()
	var/datum/game_rule_state/rules = GLOB.game_rule_state
	rules.reset_rto_rules()

	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	human.job = JOB_SQUAD_RTO
	var/datum/rto_support_controller/controller = allocate(/datum/rto_support_controller, human)
	var/datum/rto_support_template/unit_test_charges/template = allocate(/datum/rto_support_template/unit_test_charges)
	controller.selected_templates += template
	controller.ensure_runtime()

	var/datum/rto_support_resource_pool_state/pool = controller.get_support_pool(template.template_id, TRUE)
	var/datum/rto_support_action_template/light_action = template.get_action_template("unit_test_charge_light")
	var/datum/rto_support_action_template/heavy_action = template.get_action_template("unit_test_charge_heavy")

	TEST_ASSERT_NOTNULL(pool, "Charge-based template should create a runtime pool.")
	TEST_ASSERT_EQUAL(controller.get_template_support_resource_mode(template), RTO_SUPPORT_RESOURCE_MODE_CHARGES, "Charge-based template should resolve to charge runtime mode.")
	TEST_ASSERT_EQUAL(controller.get_support_pool_current_charges(template), 3, "Newly created charge pool should start at configured charges.")
	TEST_ASSERT_EQUAL(controller.get_support_pool_capacity(template), 3, "Charge pool should expose the configured capacity.")
	TEST_ASSERT(controller.can_arm_action(heavy_action.action_id, template.template_id), "Heavy action should be armable with a full pool.")
	TEST_ASSERT(controller.apply_action_resource_consumption(template, light_action), "Light action should consume charge pool resource.")
	TEST_ASSERT_EQUAL(controller.get_support_pool_current_charges(template), 2, "Light action should spend one shared charge.")
	TEST_ASSERT_EQUAL(controller.get_remaining_action_cooldown(light_action.action_id), 2 SECONDS, "Charge-based action should apply the configured local lockout.")

	var/list/heavy_state = controller.build_support_action_state(heavy_action.action_id, template.template_id)
	TEST_ASSERT(heavy_state["is_disabled"], "Heavy action should become unavailable after spending a lighter shared charge.")
	TEST_ASSERT_EQUAL(heavy_state["pool_current_charges"], 2, "Support action state should expose remaining charges.")
	TEST_ASSERT_EQUAL(heavy_state["pool_cost"], 3, "Support action state should expose the required charge cost.")
	TEST_ASSERT(!heavy_state["pool_has_enough_charges"], "Support action state should mark heavy action as underfunded.")

	pool.next_recharge_at = world.time
	TEST_ASSERT_EQUAL(controller.get_support_pool_current_charges(template), 3, "Charge pool should recharge when its next tick is reached.")

	controller.apply_action_resource_consumption(template, heavy_action)
	TEST_ASSERT_EQUAL(controller.get_support_pool_current_charges(template), 0, "Heavy action should consume the full shared pool in the synthetic test.")
	rules.rto_charge_manual_only = TRUE
	controller.apply_rules_update()
	pool.next_recharge_at = world.time
	TEST_ASSERT_EQUAL(controller.get_support_pool_current_charges(template), 0, "Manual-only mode should stop automatic charge recharge.")

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
	TEST_ASSERT_EQUAL(controller.get_remaining_zone_shared_cooldown(), 0, "Clearing a sector should still not start a shared zone cooldown.")
	TEST_ASSERT_EQUAL(controller.get_remaining_zone_cooldown("mortar"), 3 SECONDS, "Clearing a sector should start only the short personal anti-spam cooldown for the source package.")
	TEST_ASSERT_EQUAL(controller.get_remaining_zone_cooldown("cas"), 0, "A different package should not inherit the source package personal zone cooldown.")
	TEST_ASSERT(!controller.can_deploy_zone("mortar"), "The source package should respect its short personal anti-spam cooldown before redeploying.")
	TEST_ASSERT(controller.can_deploy_zone("cas"), "A different sector package should be immediately redeployable after the active zone is cleared.")

/datum/unit_test/halo_support_payload_contents

/datum/unit_test/halo_support_payload_contents/Run()
	var/list/crate_expectations = list(
		/obj/structure/largecrate/supply/ammo/halo/rifle = list(
			/obj/item/ammo_box/magazine/unsc/ma5c = 2,
			/obj/item/ammo_box/magazine/unsc/ma5b = 2,
			/obj/item/ammo_box/magazine/unsc/br55 = 2,
		),
		/obj/structure/largecrate/supply/ammo/halo/marksman = list(
			/obj/item/ammo_magazine/rifle/halo/dmr = 5,
		),
		/obj/structure/largecrate/supply/ammo/halo/pdw = list(
			/obj/item/ammo_magazine/smg/halo/m7 = 4,
			/obj/item/ammo_box/magazine/unsc/small/m6c = 2,
			/obj/item/ammo_magazine/pistol/halo/m6d = 2,
		),
		/obj/structure/largecrate/supply/ammo/halo/shotgun = list(
			/obj/item/ammo_magazine/shotgun/slug/unsc = 3,
		),
		/obj/structure/largecrate/supply/ammo/halo/sniper = list(
			/obj/item/ammo_magazine/rifle/halo/sniper = 5,
		),
		/obj/structure/largecrate/supply/ammo/halo/spnkr = list(
			/obj/item/ammo_magazine/spnkr = 2,
		),
		/obj/structure/largecrate/supply/ammo/halo/grenadier = list(
			/obj/item/ammo_box/magazine/misc/unsc/grenade/launchable = 2,
			/obj/item/ammo_box/magazine/misc/unsc/grenade = 2,
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
		/obj/structure/largecrate/supply/ammo/m41a = list(
			/obj/item/ammo_magazine/rifle = 20,
		),
		/obj/structure/largecrate/supply/ammo/m41a_box = list(
			/obj/item/ammo_box/rounds = 4,
		),
		/obj/structure/largecrate/supply/ammo/shotgun/half = list(
			/obj/item/ammo_magazine/shotgun/slugs = 3,
		),
		/obj/structure/largecrate/supply/ammo/m39/half = list(
			/obj/item/ammo_magazine/smg/m39 = 6,
		),
		/obj/structure/largecrate/supply/ammo/pistol/half = list(
			/obj/item/ammo_magazine/revolver = 4,
			/obj/item/ammo_magazine/pistol = 8,
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
		"Винтовочные боеприпасы" = /datum/fire_support/supply_drop/halo/rifle,
		"Боеприпасы марксмана" = /datum/fire_support/supply_drop/halo/marksman,
		"Боеприпасы вторичного оружия" = /datum/fire_support/supply_drop/halo/pdw,
		"Дробовые патроны" = /datum/fire_support/supply_drop/halo/shotgun,
		"Снайперские боеприпасы" = /datum/fire_support/supply_drop/halo/sniper,
		"Боеприпасы SPNKr" = /datum/fire_support/supply_drop/halo/spnkr,
		"Боеприпасы гренадера" = /datum/fire_support/supply_drop/halo/grenadier,
		"Медицинские пакеты" = /datum/fire_support/supply_drop/halo/medical_packets,
		"Набор корпусмана" = /datum/fire_support/supply_drop/halo/corpsman_kit,
		"Резерв биопены" = /datum/fire_support/supply_drop/halo/biofoam_reserve,
		"Инженерный комплект" = /datum/fire_support/supply_drop/halo/toolbox,
		"Комплект укреплений" = /datum/fire_support/supply_drop/halo/fortification,
		"Набор для пролома" = /datum/fire_support/supply_drop/halo/breaching,
		"Комплект обслуживания техники" = /datum/fire_support/supply_drop/halo/vehicle_service,
		"Сигнальный комплект" = /datum/fire_support/supply_drop/halo/signal,
		"Разведывательный комплект" = /datum/fire_support/supply_drop/halo/recon,
		"Командный комплект RTO" = /datum/fire_support/supply_drop/halo/rto_command,
	)
	var/list/expected_sections = list(
		"halo_logistics" = list(
			"title" = "Десантное снабжение",
			"options" = list(
				"Винтовочные боеприпасы",
				"Боеприпасы марксмана",
				"Боеприпасы вторичного оружия",
				"Дробовые патроны",
				"Снайперские боеприпасы",
				"Боеприпасы SPNKr",
				"Боеприпасы гренадера",
			),
		),
		"halo_medical" = list(
			"title" = "Десантная медицина",
			"options" = list(
				"Медицинские пакеты",
				"Набор корпусмана",
				"Резерв биопены",
			),
		),
		"halo_technical" = list(
			"title" = "Десантная техподдержка",
			"options" = list(
				"Инженерный комплект",
				"Комплект укреплений",
				"Набор для пролома",
				"Комплект обслуживания техники",
				"Сигнальный комплект",
				"Разведывательный комплект",
				"Командный комплект RTO",
			),
		),
	)

	var/datum/fire_support_menu/menu = allocate(/datum/fire_support_menu/unit_test_stub)
	var/list/static_data = menu.ui_static_data(null)
	var/list/custom_sections = static_data["custom_ordnance_sections"]

	TEST_ASSERT(length(custom_sections) >= 3, "GM fire support menu should expose the HALO custom ordnance sections.")

	for(var/label in expected_routing)
		TEST_ASSERT(label in static_data["ordnance_options"], "GM fire support menu did not expose [label] in the full ordnance list.")
		TEST_ASSERT(!(label in static_data["misc_ordnance_options"]), "GM fire support menu should not duplicate [label] in legacy misc ordnance options.")
		TEST_ASSERT_EQUAL(menu.resolve_custom_fire_support(label), expected_routing[label], "[label] no longer resolves to the intended HALO payload.")

	for(var/section_id in expected_sections)
		var/list/section = find_custom_ordnance_section(custom_sections, section_id)
		TEST_ASSERT_NOTNULL(section, "GM fire support menu is missing the [section_id] custom section.")
		TEST_ASSERT_EQUAL(section["title"], expected_sections[section_id]["title"], "[section_id] custom section has an unexpected title.")
		assert_expected_values(section["options"], expected_sections[section_id]["options"], "[section_id] custom ordnance section")

/datum/unit_test/uscm_support_admin_bridge

/datum/unit_test/uscm_support_admin_bridge/Run()
	var/list/expected_routing = list(
		"USCM Rifle Ammo Drop" = /datum/fire_support/supply_drop/uscm/rifle,
		"USCM Rifle Box Ammo Drop" = /datum/fire_support/supply_drop/uscm/rifle_box,
		"USCM Shotgun Ammo Drop" = /datum/fire_support/supply_drop/uscm/shotgun,
		"USCM SMG Ammo Drop" = /datum/fire_support/supply_drop/uscm/smg,
		"USCM Sidearm Ammo Drop" = /datum/fire_support/supply_drop/uscm/sidearm,
		"USCM M56D Ammo Drop" = /datum/fire_support/supply_drop/uscm/m56d,
		"USCM Sentry Ammo Drop" = /datum/fire_support/supply_drop/uscm/sentry,
	)
	var/list/expected_section = list(
		"title" = "USCM Ammo Drops",
		"options" = list(
			"USCM Rifle Ammo Drop",
			"USCM Rifle Box Ammo Drop",
			"USCM Shotgun Ammo Drop",
			"USCM SMG Ammo Drop",
			"USCM Sidearm Ammo Drop",
			"USCM M56D Ammo Drop",
			"USCM Sentry Ammo Drop",
		),
	)

	var/datum/fire_support_menu/menu = allocate(/datum/fire_support_menu/unit_test_stub)
	var/list/static_data = menu.ui_static_data(null)
	var/list/custom_sections = static_data["custom_ordnance_sections"]
	var/list/uscm_section = find_custom_ordnance_section(custom_sections, "uscm_ammo_drops")

	TEST_ASSERT(length(custom_sections) >= 4, "GM fire support menu should expose the USCM ammo section alongside HALO custom ordnance sections.")
	TEST_ASSERT_NOTNULL(uscm_section, "GM fire support menu is missing the USCM ammo custom section.")
	TEST_ASSERT_EQUAL(uscm_section["title"], expected_section["title"], "USCM ammo custom section has an unexpected title.")
	assert_expected_values(uscm_section["options"], expected_section["options"], "USCM ammo custom ordnance section")

	for(var/label in expected_routing)
		TEST_ASSERT(label in static_data["ordnance_options"], "GM fire support menu did not expose [label] in the full ordnance list.")
		TEST_ASSERT(!(label in static_data["misc_ordnance_options"]), "GM fire support menu should not duplicate [label] in legacy misc ordnance options.")
		TEST_ASSERT_EQUAL(menu.resolve_custom_fire_support(label), expected_routing[label], "[label] no longer resolves to the intended USCM payload.")
