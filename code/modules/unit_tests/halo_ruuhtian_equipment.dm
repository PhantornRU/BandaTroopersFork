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

/datum/unit_test/halo_ruuhtian_preset_coverage
	parent_type = /datum/unit_test/halo_ruuhtian_equipment

/datum/unit_test/halo_ruuhtian_preset_coverage/Run()
	var/list/equipment_presets = list(
		/datum/equipment_preset/covenant/ruuhtian/minor/plasma_pistol,
		/datum/equipment_preset/covenant/ruuhtian/minor/needler,
		/datum/equipment_preset/covenant/ruuhtian/major/needler,
		/datum/equipment_preset/covenant/ruuhtian/major/plasma_rifle,
		/datum/equipment_preset/covenant/ruuhtian/ultra/needler,
		/datum/equipment_preset/covenant/ruuhtian/ultra/plasma_rifle,
		/datum/equipment_preset/covenant/ruuhtian/ultra/carbine,
		/datum/equipment_preset/covenant/ruuhtian/marksman/carbine,
		/datum/equipment_preset/covenant/ruuhtian/sniper/carbine,
	)
	for(var/preset_path as anything in equipment_presets)
		var/mob/living/carbon/human/human = create_test_human()
		arm_equipment(human, preset_path, FALSE)
		TEST_ASSERT_EQUAL(human.species?.name, SPECIES_RUUHTIAN, "[preset_path] did not set Ruuhtian species.")
		TEST_ASSERT(human.w_uniform, "[preset_path] did not equip a uniform.")
		TEST_ASSERT(human.wear_suit, "[preset_path] did not equip armor.")
		TEST_ASSERT(human.get_active_hand() || human.r_store || human.l_store || human.back || human.s_store, "[preset_path] did not equip a weapon or shield.")

	var/list/ai_presets = list(
		/datum/human_ai_equipment_preset/covenant/ruuhtian/minor,
		/datum/human_ai_equipment_preset/covenant/ruuhtian/minor/needler,
		/datum/human_ai_equipment_preset/covenant/ruuhtian/major,
		/datum/human_ai_equipment_preset/covenant/ruuhtian/major/plasma_rifle,
		/datum/human_ai_equipment_preset/covenant/ruuhtian/ultra,
		/datum/human_ai_equipment_preset/covenant/ruuhtian/ultra/plasma_rifle,
		/datum/human_ai_equipment_preset/covenant/ruuhtian/ultra/carbine,
		/datum/human_ai_equipment_preset/covenant/ruuhtian/marksman,
		/datum/human_ai_equipment_preset/covenant/ruuhtian/sniper,
	)
	for(var/ai_preset_path as anything in ai_presets)
		var/datum/human_ai_equipment_preset/ai_preset = new ai_preset_path
		TEST_ASSERT(ispath(ai_preset.path, /datum/equipment_preset), "[ai_preset_path] points to missing equipment preset [ai_preset.path].")

	var/list/squad_presets = list(
		/datum/human_ai_squad_preset/covenant/ruuhtian_pair,
		/datum/human_ai_squad_preset/covenant/ruuhtian_screen_team,
		/datum/human_ai_squad_preset/covenant/ruuhtian_marksman_cell,
		/datum/human_ai_squad_preset/covenant/ruuhtian_patrol_pair,
		/datum/human_ai_squad_preset/covenant/ruuhtian_marksman_overwatch,
		/datum/human_ai_squad_preset/covenant/ruuhtian_sniper_cell,
		/datum/human_ai_squad_preset/covenant/kigyar_unggoy_lance,
	)
	for(var/squad_preset_path as anything in squad_presets)
		var/datum/human_ai_squad_preset/squad_preset = new squad_preset_path
		TEST_ASSERT(length(squad_preset.ai_to_spawn), "[squad_preset_path] has no equipment presets.")
		for(var/equipment_preset_path as anything in squad_preset.ai_to_spawn)
			TEST_ASSERT(ispath(equipment_preset_path, /datum/equipment_preset), "[squad_preset_path] points to missing equipment preset [equipment_preset_path].")
