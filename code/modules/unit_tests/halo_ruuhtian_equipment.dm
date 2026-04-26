/datum/unit_test/halo_ruuhtian_equipment
	priority = TEST_DEFAULT

/datum/unit_test/halo_ruuhtian_equipment/proc/create_test_human()
	return allocate(/mob/living/carbon/human, run_loc_floor_top_right)

/datum/unit_test/halo_ruuhtian_equipment/Run()
	return

/datum/unit_test/halo_ruuhtian_minor_equipment
	parent_type = /datum/unit_test/halo_ruuhtian_equipment

/datum/unit_test/halo_ruuhtian_minor_equipment/Run()
	var/mob/living/carbon/human/human = create_test_human()

	arm_equipment(human, /datum/equipment_preset/covenant/ruuhtian/minor, FALSE)

	TEST_ASSERT_EQUAL(human.species?.name, SPECIES_RUUHTIAN, "Kig-Yar preset should set the expected Ruuhtian species.")
	TEST_ASSERT(istype(human.wear_suit, /obj/item/clothing/suit/marine/ruuhtian/minor), "Kig-Yar preset did not equip the expected minor harness.")
	TEST_ASSERT(istype(human.belt, /obj/item/storage/belt/marine/covenant/ruuhtian/minor), "Kig-Yar preset did not equip the expected Ruuhtian belt.")
	TEST_ASSERT(istype(human.l_store, /obj/item/weapon/shield/riot/covenant), "Kig-Yar preset did not equip the expected point defense gauntlet.")

	var/obj/item/clothing/suit/marine/ruuhtian/minor/harness = human.wear_suit
	TEST_ASSERT_EQUAL(harness.armor_melee, CLOTHING_ARMOR_MEDIUMHIGH, "Ruuhtian harness melee armor drifted from the expected medium-high baseline.")
	TEST_ASSERT_EQUAL(harness.armor_bullet, CLOTHING_ARMOR_MEDIUMHIGH, "Ruuhtian harness bullet armor drifted from the expected medium-high baseline.")
	TEST_ASSERT_EQUAL(harness.armor_laser, CLOTHING_ARMOR_MEDIUMHIGH, "Ruuhtian harness laser armor drifted from the expected medium-high baseline.")
