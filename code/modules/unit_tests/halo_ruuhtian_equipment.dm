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

	var/obj/item/weapon/shield/riot/covenant/gauntlet = human.l_store
	TEST_ASSERT_EQUAL(gauntlet.readied_block, 150, "Ruuhtian point defense gauntlet readied block drifted from the upstream PR97 baseline.")
	TEST_ASSERT_EQUAL(gauntlet.passive_block, 100, "Ruuhtian point defense gauntlet passive block drifted from the upstream PR97 baseline.")

/datum/unit_test/halo_ruuhtian_latest_pr97_variants
	parent_type = /datum/unit_test/halo_ruuhtian_equipment

/datum/unit_test/halo_ruuhtian_latest_pr97_variants/Run()
	var/datum/equipment_preset/covenant/ruuhtian/marksman/marksman_preset = new
	TEST_ASSERT_EQUAL(marksman_preset.assignment, "Marksman", "Ruuhtian marksman preset did not use the dedicated marksman assignment.")

	var/mob/living/carbon/human/sniper = create_test_human()
	arm_equipment(sniper, /datum/equipment_preset/covenant/ruuhtian/sniper/carbine, FALSE)

	TEST_ASSERT_EQUAL(sniper.species?.name, SPECIES_RUUHTIAN, "Ruuhtian sniper preset should set the expected Ruuhtian species.")
	TEST_ASSERT(istype(sniper.head, /obj/item/clothing/head/helmet/marine/ruuhtian/sniper), "Ruuhtian sniper preset did not equip the expected sniper helmet.")
	TEST_ASSERT(istype(sniper.r_store, /obj/item/weapon/gun/rifle/covenant_carbine), "Ruuhtian sniper preset did not equip the expected covenant carbine.")

	var/datum/human_ai_equipment_preset/covenant/ruuhtian/sniper/ai_sniper = new
	TEST_ASSERT_EQUAL(ai_sniper.path, /datum/equipment_preset/covenant/ruuhtian/sniper/carbine, "Ruuhtian sniper AI preset did not point to the latest PR97 carbine loadout.")
