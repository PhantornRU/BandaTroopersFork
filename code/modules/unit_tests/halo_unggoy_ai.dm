/datum/unit_test/halo_unggoy_ai/proc/create_unggoy_ai_brain(preset_type)
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	arm_equipment(human, preset_type, FALSE)
	var/datum/component/human_ai/ai_component = human.AddComponent(/datum/component/human_ai)
	if(!ai_component)
		TEST_FAIL("Failed to add a human AI component to the HALO Unggoy test mob.")
		return null
	if(!ai_component.ai_brain)
		TEST_FAIL("Failed to resolve a human AI brain for the HALO Unggoy test mob.")
		return null
	ai_component.ai_brain.appraise_inventory(armor = TRUE)
	return ai_component.ai_brain

/datum/unit_test/halo_unggoy_ai/Run()
	return

/datum/unit_test/halo_unggoy_ai/proc/get_first_assoc_key(list/assoc_list)
	for(var/entry as anything in assoc_list)
		return entry

/datum/unit_test/halo_unggoy_ai_equipment_matrix
	parent_type = /datum/unit_test/halo_unggoy_ai

/datum/unit_test/halo_unggoy_ai_equipment_matrix/Run()
	var/list/preset_matrix = list(
		/datum/equipment_preset/covenant/unggoy/ai/minor_plasma = list("suit" = /obj/item/clothing/suit/marine/unggoy/minor, "belt" = /obj/item/storage/belt/marine/covenant/unggoy/minor),
		/datum/equipment_preset/covenant/unggoy/ai/minor_needler = list("suit" = /obj/item/clothing/suit/marine/unggoy/minor, "belt" = /obj/item/storage/belt/marine/covenant/unggoy/minor),
		/datum/equipment_preset/covenant/unggoy/ai/major_plasma = list("suit" = /obj/item/clothing/suit/marine/unggoy/major, "belt" = /obj/item/storage/belt/marine/covenant/unggoy/major),
		/datum/equipment_preset/covenant/unggoy/ai/major_needler = list("suit" = /obj/item/clothing/suit/marine/unggoy/major, "belt" = /obj/item/storage/belt/marine/covenant/unggoy/major),
		/datum/equipment_preset/covenant/unggoy/ai/heavy_plasma = list("suit" = /obj/item/clothing/suit/marine/unggoy/heavy, "belt" = /obj/item/storage/belt/marine/covenant/unggoy/heavy),
		/datum/equipment_preset/covenant/unggoy/ai/heavy_needler = list("suit" = /obj/item/clothing/suit/marine/unggoy/heavy, "belt" = /obj/item/storage/belt/marine/covenant/unggoy/heavy),
		/datum/equipment_preset/covenant/unggoy/ai/ultra = list("suit" = /obj/item/clothing/suit/marine/unggoy/ultra, "belt" = /obj/item/storage/belt/marine/covenant/unggoy/ultra),
		/datum/equipment_preset/covenant/unggoy/ai/support_medical = list("suit" = /obj/item/clothing/suit/marine/unggoy/major, "belt" = /obj/item/storage/belt/marine/covenant/unggoy/major),
		/datum/equipment_preset/covenant/unggoy/ai/specops_plasma = list("suit" = /obj/item/clothing/suit/marine/stealth/unggoy_specops, "belt" = /obj/item/storage/belt/marine/covenant/unggoy/specops),
		/datum/equipment_preset/covenant/unggoy/ai/specops_needler = list("suit" = /obj/item/clothing/suit/marine/stealth/unggoy_specops, "belt" = /obj/item/storage/belt/marine/covenant/unggoy/specops),
		/datum/equipment_preset/covenant/unggoy/ai/specops_ultra = list("suit" = /obj/item/clothing/suit/marine/stealth/unggoy_specops/ultra, "belt" = /obj/item/storage/belt/marine/covenant/unggoy/specops_ultra),
		/datum/equipment_preset/covenant/unggoy/ai/deacon_command = list("suit" = /obj/item/clothing/suit/marine/unggoy/deacon, "belt" = /obj/item/storage/belt/marine/covenant/unggoy/ultra),
		/datum/equipment_preset/covenant/unggoy/ai/suicide_bomber = list("suit" = /obj/item/clothing/suit/marine/unggoy/minor, "belt" = /obj/item/storage/belt/marine/covenant/unggoy/minor),
	)

	for(var/preset_type as anything in preset_matrix)
		var/datum/human_ai_brain/brain = create_unggoy_ai_brain(preset_type)
		TEST_ASSERT_NOTNULL(brain, "Failed to create a HALO Unggoy AI for [preset_type].")
		var/mob/living/carbon/human/human = brain.tied_human
		var/list/expected = preset_matrix[preset_type]

		TEST_ASSERT_EQUAL(human.species?.name, SPECIES_UNGGOY, "[preset_type] did not set the expected Unggoy species.")
		TEST_ASSERT(istype(human.wear_mask, /obj/item/clothing/mask/gas/unggoy), "[preset_type] did not equip the expected Unggoy rebreather.")
		TEST_ASSERT(istype(human.wear_suit, expected["suit"]), "[preset_type] did not equip the expected HALO armor type.")
		TEST_ASSERT(istype(human.belt, expected["belt"]), "[preset_type] did not equip the expected HALO belt type.")

/datum/unit_test/halo_unggoy_ai_needler_ammo
	parent_type = /datum/unit_test/halo_unggoy_ai

/datum/unit_test/halo_unggoy_ai_needler_ammo/Run()
	var/list/needler_presets = list(
		/datum/equipment_preset/covenant/unggoy/ai/minor_needler,
		/datum/equipment_preset/covenant/unggoy/ai/major_needler,
		/datum/equipment_preset/covenant/unggoy/ai/heavy_needler,
		/datum/equipment_preset/covenant/unggoy/ai/specops_needler,
	)

	for(var/preset_type as anything in needler_presets)
		var/datum/human_ai_brain/brain = create_unggoy_ai_brain(preset_type)
		TEST_ASSERT_NOTNULL(brain, "Failed to create a HALO Unggoy needler AI for [preset_type].")
		var/mob/living/carbon/human/human = brain.tied_human
		TEST_ASSERT(istype(human.s_store, /obj/item/weapon/gun/smg/covenant_needler), "[preset_type] did not equip a needler into suit storage.")

		brain.set_primary_weapon(human.s_store)
		var/obj/item/ammo_magazine/needler_crystal/crystals = brain.weapon_ammo_search(brain.primary_weapon)
		TEST_ASSERT_NOTNULL(crystals, "[preset_type] did not expose needler crystals through the AI ammunition map.")
		TEST_ASSERT(length(brain.equipment_map[HUMAN_AI_AMMUNITION]) >= 1, "[preset_type] did not retain readable ammunition in the AI equipment map.")

/datum/unit_test/halo_unggoy_ai_bomber_overrides
	parent_type = /datum/unit_test/halo_unggoy_ai

/datum/unit_test/halo_unggoy_ai_bomber_overrides/Run()
	var/datum/human_ai_brain/brain = create_unggoy_ai_brain(/datum/equipment_preset/covenant/unggoy/ai/suicide_bomber)
	TEST_ASSERT_NOTNULL(brain, "Failed to create the HALO Unggoy suicide bomber test AI.")
	TEST_ASSERT(brain.halo_suicide_bomber, "Unggoy suicide bomber lost its HALO bomber override.")
	TEST_ASSERT_EQUAL(brain.halo_suicide_prime_range, 5, "Unggoy suicide bomber prime range drifted from the intended HALO value.")
	TEST_ASSERT(brain.ignore_looting, "Unggoy suicide bomber should ignore looting while charging.")
	TEST_ASSERT(!brain.grenading_allowed, "Unggoy suicide bomber should not use the generic grenade-throw action.")
	TEST_ASSERT(brain.halo_unggoy_ignore_panic, "Unggoy suicide bomber should bypass panic-retreat behavior.")

/datum/unit_test/halo_unggoy_ai_panic_behavior
	parent_type = /datum/unit_test/halo_unggoy_ai

/datum/unit_test/halo_unggoy_ai_panic_behavior/Run()
	var/list/panicking_presets = list(
		/datum/equipment_preset/covenant/unggoy/ai/minor_plasma,
		/datum/equipment_preset/covenant/unggoy/ai/major_plasma,
		/datum/equipment_preset/covenant/unggoy/ai/support_medical,
		/datum/equipment_preset/covenant/unggoy/ai/deacon_command,
	)
	var/list/steady_presets = list(
		/datum/equipment_preset/covenant/unggoy/ai/heavy_plasma,
		/datum/equipment_preset/covenant/unggoy/ai/heavy_needler,
		/datum/equipment_preset/covenant/unggoy/ai/ultra,
		/datum/equipment_preset/covenant/unggoy/ai/specops_plasma,
		/datum/equipment_preset/covenant/unggoy/ai/specops_needler,
		/datum/equipment_preset/covenant/unggoy/ai/specops_ultra,
		/datum/equipment_preset/covenant/unggoy/ai/suicide_bomber,
	)

	for(var/preset_type as anything in panicking_presets)
		var/datum/human_ai_brain/brain = create_unggoy_ai_brain(preset_type)
		TEST_ASSERT_NOTNULL(brain, "Failed to create a HALO Unggoy panic-role AI for [preset_type].")
		brain.tied_human.health = brain.tied_human.maxHealth * 0.1
		TEST_ASSERT(brain.halo_unggoy_should_panic(), "[preset_type] should enable HALO panic-retreat when heavily wounded.")

	for(var/preset_type as anything in steady_presets)
		var/datum/human_ai_brain/brain = create_unggoy_ai_brain(preset_type)
		TEST_ASSERT_NOTNULL(brain, "Failed to create a HALO Unggoy steady-role AI for [preset_type].")
		brain.tied_human.health = brain.tied_human.maxHealth * 0.1
		TEST_ASSERT(!brain.halo_unggoy_should_panic(), "[preset_type] should not enable HALO panic-retreat when heavily wounded.")

/datum/unit_test/halo_unggoy_ai_firearm_appraisals
	parent_type = /datum/unit_test/halo_unggoy_ai

/datum/unit_test/halo_unggoy_ai_firearm_appraisals/Run()
	var/obj/item/weapon/gun/energy/plasma/plasma_pistol/plasma_pistol = allocate(/obj/item/weapon/gun/energy/plasma/plasma_pistol, run_loc_floor_top_right)
	var/obj/item/weapon/gun/energy/plasma/plasma_rifle/plasma_rifle = allocate(/obj/item/weapon/gun/energy/plasma/plasma_rifle, run_loc_floor_top_right)
	var/obj/item/weapon/gun/smg/covenant_needler/needler = allocate(/obj/item/weapon/gun/smg/covenant_needler, run_loc_floor_top_right)

	TEST_ASSERT_EQUAL(get_firearm_appraisal(plasma_pistol)?.type, /datum/firearm_appraisal/halo_plasma_pistol, "Plasma pistol lost its HALO-specific firearm appraisal.")
	TEST_ASSERT_EQUAL(get_firearm_appraisal(plasma_rifle)?.type, /datum/firearm_appraisal/halo_plasma_rifle, "Plasma rifle lost its HALO-specific firearm appraisal.")
	TEST_ASSERT_EQUAL(get_firearm_appraisal(needler)?.type, /datum/firearm_appraisal/halo_needler, "Needler lost its HALO-specific firearm appraisal.")

/datum/unit_test/halo_unggoy_ai_squad_compositions
	parent_type = /datum/unit_test/halo_unggoy_ai

/datum/unit_test/halo_unggoy_ai_squad_compositions/Run()
	var/list/leader_matrix = list(
		/datum/human_ai_squad_preset/covenant/unggoy_fireteam = /datum/equipment_preset/covenant/unggoy/ai/major_plasma,
		/datum/human_ai_squad_preset/covenant/unggoy_assault_team = /datum/equipment_preset/covenant/unggoy/ai/major_needler,
		/datum/human_ai_squad_preset/covenant/unggoy_heavy_team = /datum/equipment_preset/covenant/unggoy/ai/ultra,
		/datum/human_ai_squad_preset/covenant/unggoy_support_team = /datum/equipment_preset/covenant/unggoy/ai/deacon_command,
		/datum/human_ai_squad_preset/covenant/unggoy_at_team = /datum/equipment_preset/covenant/unggoy/ai/ultra,
		/datum/human_ai_squad_preset/covenant/unggoy_specops_cell = /datum/equipment_preset/covenant/unggoy/ai/specops_ultra,
		/datum/human_ai_squad_preset/covenant/covenant_lance = /datum/equipment_preset/covenant/sangheili/ai/minor_plasma,
		/datum/human_ai_squad_preset/covenant/covenant_heavy_lance = /datum/equipment_preset/covenant/sangheili/ai/ultra_plasma,
		/datum/human_ai_squad_preset/covenant/covenant_at_lance = /datum/equipment_preset/covenant/sangheili/ai/zealot_command,
	)

	for(var/preset_type as anything in leader_matrix)
		var/datum/human_ai_squad_preset/preset = allocate(preset_type)
		var/first_entry = get_first_assoc_key(preset.ai_to_spawn)
		TEST_ASSERT_EQUAL(first_entry, leader_matrix[preset_type], "[preset_type] no longer exposes its intended squad leader as the first spawned unit.")

	for(var/squad_type in subtypesof(/datum/human_ai_squad_preset/covenant))
		var/datum/human_ai_squad_preset/preset = allocate(squad_type)
		for(var/equipment_path as anything in preset.ai_to_spawn)
			TEST_ASSERT(!findtext("[equipment_path]", "anti_tank_temp"), "[squad_type] still references the retired temporary anti-tank Unggoy role.")
