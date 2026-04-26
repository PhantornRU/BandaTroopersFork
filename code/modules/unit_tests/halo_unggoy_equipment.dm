/datum/unit_test/halo_unggoy_equipment
	priority = TEST_DEFAULT

/datum/unit_test/halo_unggoy_equipment/proc/create_test_human()
	return allocate(/mob/living/carbon/human, run_loc_floor_top_right)

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
