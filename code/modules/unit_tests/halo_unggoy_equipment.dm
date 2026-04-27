/datum/unit_test/halo_unggoy_equipment
	priority = TEST_DEFAULT

/datum/unit_test/halo_unggoy_equipment/proc/create_test_human()
	return allocate(/mob/living/carbon/human, run_loc_floor_top_right)

/datum/unit_test/halo_unggoy_equipment/proc/assert_complete_unggoy_kit(mob/living/carbon/human/human, label, expect_primary_weapon = TRUE)
	TEST_ASSERT_EQUAL(human.species?.name, SPECIES_UNGGOY, "[label] should set the expected Unggoy species.")
	TEST_ASSERT(human.w_uniform, "[label] did not equip an Unggoy uniform.")
	TEST_ASSERT(human.wear_suit, "[label] did not equip an Unggoy harness.")
	TEST_ASSERT(human.belt, "[label] did not equip a belt.")
	TEST_ASSERT(human.get_item_by_slot(WEAR_L_EAR), "[label] did not equip a Covenant headset.")
	TEST_ASSERT(human.head || human.wear_mask, "[label] did not equip any breathing gear or head protection.")
	TEST_ASSERT(human.back, "[label] did not equip a methane tank/backpack.")
	TEST_ASSERT(human.gloves, "[label] did not equip gloves/bracers.")
	TEST_ASSERT(human.shoes, "[label] did not equip foot guards.")
	if(expect_primary_weapon)
		TEST_ASSERT(human.r_store || human.l_store || human.get_active_hand(), "[label] did not equip a primary weapon.")

/datum/unit_test/halo_unggoy_equipment/Run()
	return

/datum/unit_test/halo_unggoy_latest_pr97_variants
	parent_type = /datum/unit_test/halo_unggoy_equipment

/datum/unit_test/halo_unggoy_latest_pr97_variants/Run()
	var/obj/item/clothing/suit/marine/unggoy/base_harness = allocate(/obj/item/clothing/suit/marine/unggoy)
	TEST_ASSERT("Unggoy Bicep" in base_harness.valid_accessory_slots, "Unggoy harness should accept the upstream PR97 bicep accessory slot.")
	TEST_ASSERT("Unggoy Shoulder" in base_harness.valid_accessory_slots, "Unggoy harness should accept the upstream PR97 shoulder accessory slot.")
	TEST_ASSERT("Unggoy Bicep" in base_harness.restricted_accessory_slots, "Unggoy harness should restrict the bicep accessory slot to compatible accessories.")
	TEST_ASSERT("Unggoy Shoulder" in base_harness.restricted_accessory_slots, "Unggoy harness should restrict the shoulder accessory slot to compatible accessories.")

	var/obj/item/clothing/suit/marine/unggoy/heavy/heavy_harness = allocate(/obj/item/clothing/suit/marine/unggoy/heavy)
	TEST_ASSERT_EQUAL(heavy_harness.armor_bomb, CLOTHING_ARMOR_VERYHIGH, "Unggoy heavy harness bomb armor drifted from the latest upstream PR97 value.")

	var/mob/living/carbon/human/minor = create_test_human()
	arm_equipment(minor, /datum/equipment_preset/covenant/unggoy/minor/plasma_pistol, FALSE)

	TEST_ASSERT_EQUAL(minor.species?.name, SPECIES_UNGGOY, "Unggoy minor plasma-pistol preset should set the expected Unggoy species.")
	TEST_ASSERT(istype(minor.wear_suit, /obj/item/clothing/suit/marine/unggoy/minor), "Unggoy minor plasma-pistol preset did not equip the expected minor harness.")
	TEST_ASSERT(istype(minor.r_store, /obj/item/weapon/gun/energy/plasma/plasma_pistol), "Unggoy minor plasma-pistol preset did not equip the expected plasma pistol.")

	var/mob/living/carbon/human/heavy = create_test_human()
	arm_equipment(heavy, /datum/equipment_preset/covenant/unggoy/heavy/plasma_rifle, FALSE)

	TEST_ASSERT_EQUAL(heavy.species?.name, SPECIES_UNGGOY, "Unggoy heavy plasma-rifle preset should set the expected Unggoy species.")
	TEST_ASSERT(istype(heavy.wear_suit, /obj/item/clothing/suit/marine/unggoy/heavy), "Unggoy heavy plasma-rifle preset did not equip the expected heavy harness.")
	TEST_ASSERT(istype(heavy.r_store, /obj/item/weapon/gun/energy/plasma/plasma_rifle), "Unggoy heavy plasma-rifle preset did not equip the expected plasma rifle.")

/datum/unit_test/halo_unggoy_normalized_root_presets
	parent_type = /datum/unit_test/halo_unggoy_equipment

/datum/unit_test/halo_unggoy_normalized_root_presets/Run()
	var/list/root_presets = list(
		/datum/equipment_preset/covenant/unggoy/minor = /obj/item/weapon/gun/energy/plasma/plasma_pistol,
		/datum/equipment_preset/covenant/unggoy/major = /obj/item/weapon/gun/energy/plasma/plasma_pistol,
		/datum/equipment_preset/covenant/unggoy/heavy = /obj/item/weapon/gun/energy/plasma/plasma_rifle,
		/datum/equipment_preset/covenant/unggoy/ultra = /obj/item/weapon/gun/energy/plasma/plasma_rifle,
		/datum/equipment_preset/covenant/unggoy/specops = /obj/item/weapon/gun/energy/plasma/plasma_rifle,
		/datum/equipment_preset/covenant/unggoy/specops/lesser = /obj/item/weapon/gun/energy/plasma/plasma_rifle,
		/datum/equipment_preset/covenant/unggoy/specops_ultra = /obj/item/weapon/gun/energy/plasma/plasma_rifle,
		/datum/equipment_preset/covenant/unggoy/deacon = /obj/item/weapon/gun/energy/plasma/plasma_pistol,
	)

	for(var/preset_path as anything in root_presets)
		var/mob/living/carbon/human/human = create_test_human()
		arm_equipment(human, preset_path, FALSE)
		assert_complete_unggoy_kit(human, "[preset_path]")
		var/expected_weapon_path = root_presets[preset_path]
		TEST_ASSERT(istype(human.r_store, expected_weapon_path), "[preset_path] drifted from the normalized default weapon [expected_weapon_path].")

/datum/unit_test/halo_unggoy_normalized_ai_presets
	parent_type = /datum/unit_test/halo_unggoy_equipment

/datum/unit_test/halo_unggoy_normalized_ai_presets/Run()
	var/list/ai_presets = list(
		/datum/equipment_preset/covenant/unggoy/ai/minor_plasma = /obj/item/weapon/gun/energy/plasma/plasma_pistol,
		/datum/equipment_preset/covenant/unggoy/ai/major_plasma = /obj/item/weapon/gun/energy/plasma/plasma_pistol,
		/datum/equipment_preset/covenant/unggoy/ai/heavy_plasma = /obj/item/weapon/gun/energy/plasma/plasma_rifle,
		/datum/equipment_preset/covenant/unggoy/ai/ultra = /obj/item/weapon/gun/energy/plasma/plasma_rifle,
		/datum/equipment_preset/covenant/unggoy/ai/support_medical = /obj/item/weapon/gun/energy/plasma/plasma_pistol,
		/datum/equipment_preset/covenant/unggoy/ai/specops_plasma = /obj/item/weapon/gun/energy/plasma/plasma_rifle,
		/datum/equipment_preset/covenant/unggoy/ai/specops_ultra = /obj/item/weapon/gun/energy/plasma/plasma_rifle,
		/datum/equipment_preset/covenant/unggoy/ai/deacon_command = /obj/item/weapon/gun/energy/plasma/plasma_pistol,
	)

	for(var/preset_path as anything in ai_presets)
		var/mob/living/carbon/human/human = create_test_human()
		arm_equipment(human, preset_path, FALSE)
		assert_complete_unggoy_kit(human, "[preset_path]")
		var/expected_weapon_path = ai_presets[preset_path]
		TEST_ASSERT(istype(human.r_store, expected_weapon_path), "[preset_path] drifted from the normalized AI weapon [expected_weapon_path].")

	var/mob/living/carbon/human/suicide_bomber = create_test_human()
	arm_equipment(suicide_bomber, /datum/equipment_preset/covenant/unggoy/ai/suicide_bomber, FALSE)
	assert_complete_unggoy_kit(suicide_bomber, "/datum/equipment_preset/covenant/unggoy/ai/suicide_bomber", FALSE)
