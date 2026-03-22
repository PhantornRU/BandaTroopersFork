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

/datum/unit_test/proc/assert_template_actions(datum/rto_support_template/template, list/expected_actions, expected_shared_cooldown, expected_personal_cooldown)
	var/list/action_templates = template.get_action_templates()
	TEST_ASSERT_EQUAL(length(action_templates), length(expected_actions), "[template.template_id] should expose exactly [length(expected_actions)] actions.")

	for(var/action_id in expected_actions)
		var/datum/rto_support_action_template/action_template = template.get_action_template(action_id)
		TEST_ASSERT_NOTNULL(action_template, "[template.template_id] is missing action [action_id].")
		TEST_ASSERT_EQUAL(action_template.fire_support_path, expected_actions[action_id], "[template.template_id] action [action_id] no longer points at the intended fire support payload.")
		TEST_ASSERT_EQUAL(action_template.shared_cooldown, expected_shared_cooldown, "[template.template_id] action [action_id] no longer uses the expected shared cooldown.")
		TEST_ASSERT_EQUAL(action_template.personal_cooldown, expected_personal_cooldown, "[template.template_id] action [action_id] no longer uses the expected personal cooldown.")
		TEST_ASSERT(!action_template.allow_closed_turf, "[template.template_id] action [action_id] should keep requiring open turf.")

/datum/unit_test/halo_support_template_availability
	name = "HALO UNSC support: template availability"

/datum/unit_test/halo_support_template_availability/Run()
	var/list/expected_template_ids = list("halo_logistics", "halo_medical", "halo_engineering", "halo_command")

	var/mob/living/carbon/human/halo_human = allocate(/mob/living/carbon/human)
	halo_human.job = JOB_SQUAD_RTO_UNSC
	var/datum/rto_support_controller/halo_controller = allocate(/datum/rto_support_controller, halo_human)

	var/list/halo_templates = halo_controller.get_available_templates()
	for(var/template_id in expected_template_ids)
		var/has_template = FALSE
		for(var/datum/rto_support_template/template as anything in halo_templates)
			if(template.template_id == template_id)
				has_template = TRUE
				break
		TEST_ASSERT(has_template, "HALO RTO did not receive the [template_id] template.")
		TEST_ASSERT_NOTNULL(halo_controller.find_template(template_id), "HALO controller could not resolve the [template_id] template.")

	var/mob/living/carbon/human/uscm_human = allocate(/mob/living/carbon/human)
	uscm_human.job = JOB_SQUAD_RTO
	var/datum/rto_support_controller/uscm_controller = allocate(/datum/rto_support_controller, uscm_human)

	var/list/uscm_templates = uscm_controller.get_available_templates()
	for(var/template_id in expected_template_ids)
		for(var/datum/rto_support_template/template as anything in uscm_templates)
			TEST_ASSERT(template.template_id != template_id, "Standard USCM RTO unexpectedly received the [template_id] template.")
		TEST_ASSERT_NULL(uscm_controller.find_template(template_id), "Standard USCM RTO could resolve the [template_id] template.")

/datum/unit_test/halo_support_template_wiring
	name = "HALO UNSC support: template wiring"

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
	), 120 SECONDS, 600 SECONDS)

	var/datum/rto_support_template/halo_medical/medical_template = allocate(/datum/rto_support_template/halo_medical)
	assert_template_actions(medical_template, list(
		"halo_medical_packets_drop" = /datum/fire_support/supply_drop/halo/medical_packets,
		"halo_corpsman_kit_drop" = /datum/fire_support/supply_drop/halo/corpsman_kit,
		"halo_biofoam_reserve_drop" = /datum/fire_support/supply_drop/halo/biofoam_reserve,
	), 120 SECONDS, 600 SECONDS)

	var/datum/rto_support_template/halo_engineering/engineering_template = allocate(/datum/rto_support_template/halo_engineering)
	assert_template_actions(engineering_template, list(
		"halo_toolbox_drop" = /datum/fire_support/supply_drop/halo/toolbox,
		"halo_fortification_drop" = /datum/fire_support/supply_drop/halo/fortification,
		"halo_breaching_drop" = /datum/fire_support/supply_drop/halo/breaching,
		"halo_vehicle_service_drop" = /datum/fire_support/supply_drop/halo/vehicle_service,
	), 180 SECONDS, 780 SECONDS)

	var/datum/rto_support_template/halo_command/command_template = allocate(/datum/rto_support_template/halo_command)
	assert_template_actions(command_template, list(
		"halo_signal_drop" = /datum/fire_support/supply_drop/halo/signal,
		"halo_recon_drop" = /datum/fire_support/supply_drop/halo/recon,
		"halo_rto_command_drop" = /datum/fire_support/supply_drop/halo/rto_command,
	), 120 SECONDS, 600 SECONDS)

/datum/unit_test/halo_support_payload_contents
	name = "HALO UNSC support: payload contents"

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
	)

	for(var/crate_path in crate_expectations)
		var/obj/structure/largecrate/crate = allocate(crate_path)
		assert_expected_supplies(crate.supplies, crate_expectations[crate_path], "[crate_path]")

/datum/unit_test/halo_support_admin_bridge
	name = "HALO UNSC support: admin bridge"

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
		"halo_engineering" = list(
			"title" = "HALO Engineering",
			"options" = list(
				"HALO Toolbox Drop",
				"HALO Fortification Drop",
				"HALO Breaching Drop",
				"HALO Vehicle Service Drop",
			),
		),
		"halo_command" = list(
			"title" = "HALO Command",
			"options" = list(
				"HALO Signal Drop",
				"HALO Recon Drop",
				"HALO RTO Command Drop",
			),
		),
	)

	var/datum/fire_support_menu/menu = allocate(/datum/fire_support_menu/unit_test_stub)
	var/list/static_data = menu.ui_static_data(null)
	var/list/custom_sections = static_data["custom_ordnance_sections"]

	TEST_ASSERT_EQUAL(length(custom_sections), 4, "GM fire support menu should expose exactly four HALO custom ordnance sections.")

	for(var/label in expected_routing)
		TEST_ASSERT(label in static_data["ordnance_options"], "GM fire support menu did not expose [label] in the full ordnance list.")
		TEST_ASSERT(!(label in static_data["misc_ordnance_options"]), "GM fire support menu should not duplicate [label] in legacy misc ordnance options.")
		TEST_ASSERT_EQUAL(menu.resolve_custom_fire_support(label), expected_routing[label], "[label] no longer resolves to the intended HALO payload.")

	for(var/section_id in expected_sections)
		var/list/section = find_custom_ordnance_section(custom_sections, section_id)
		TEST_ASSERT_NOTNULL(section, "GM fire support menu is missing the [section_id] custom section.")
		TEST_ASSERT_EQUAL(section["title"], expected_sections[section_id]["title"], "[section_id] custom section has an unexpected title.")
		assert_expected_values(section["options"], expected_sections[section_id]["options"], "[section_id] custom ordnance section")
