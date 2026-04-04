/datum/unit_test/halo_tts/proc/create_halo_human()
	return allocate(/mob/living/carbon/human, run_loc_floor_top_right)

/datum/unit_test/halo_tts/proc/assert_seed_pack(list/packs, pack_name, list/expected_seed_names)
	var/list/actual_seed_names = packs[pack_name]
	TEST_ASSERT(islist(actual_seed_names), "[pack_name] was not registered.")
	TEST_ASSERT_EQUAL(length(actual_seed_names), length(expected_seed_names), "[pack_name] drifted from the canonical shortlist size.")

	for(var/index in 1 to length(expected_seed_names))
		TEST_ASSERT_EQUAL(actual_seed_names[index], expected_seed_names[index], "[pack_name] drifted at slot [index].")

/datum/unit_test/halo_tts/proc/assert_registered_seed(seed_name, expected_gender)
	var/datum/tts_seed/seed = SStts220.tts_seeds[seed_name]
	TEST_ASSERT_NOTNULL(seed, "Approved HALO TTS seed [seed_name] is missing from the registry.")
	TEST_ASSERT_EQUAL(seed.gender, expected_gender, "Approved HALO TTS seed [seed_name] drifted away from the expected gender bucket.")

/datum/unit_test/halo_tts/Run()
	return

/datum/unit_test/halo_tts_shortlists
	parent_type = /datum/unit_test/halo_tts

/datum/unit_test/halo_tts_shortlists/Run()
	var/list/sangheili_packs = halo_get_tts_seed_packs(SPECIES_SANGHEILI)
	var/list/unggoy_packs = halo_get_tts_seed_packs(SPECIES_UNGGOY)

	TEST_ASSERT_EQUAL(halo_get_default_tts_seed(SPECIES_SANGHEILI), "Alarak", "Sangheili default TTS seed drifted away from the approved shortlist.")
	TEST_ASSERT_EQUAL(halo_get_default_tts_seed(SPECIES_UNGGOY), "Dobby", "Unggoy default TTS seed drifted away from the approved shortlist.")
	TEST_ASSERT(islist(sangheili_packs), "Sangheili TTS packs were not registered.")
	TEST_ASSERT(islist(unggoy_packs), "Unggoy TTS packs were not registered.")
	assert_seed_pack(sangheili_packs, "Pack A (Recommended)", list("Alarak", "Arthas", "Malganis"))
	assert_seed_pack(sangheili_packs, "Pack B", list("Arthas", "Alarak", "Sion"))
	assert_seed_pack(unggoy_packs, "Pack A (Recommended)", list("Dobby", "Ziggs", "Twitch"))
	assert_seed_pack(unggoy_packs, "Pack B", list("Ziggs", "Twitch", "Gazlowe"))
	assert_seed_pack(unggoy_packs, "Pack C", list("Dobby", "Gazlowe", "Cicero"))

	assert_registered_seed("Alarak", "Мужской")
	assert_registered_seed("Arthas", "Мужской")
	assert_registered_seed("Malganis", "Мужской")
	assert_registered_seed("Sion", "Мужской")
	assert_registered_seed("Dobby", "Мужской")
	assert_registered_seed("Ziggs", "Мужской")
	assert_registered_seed("Twitch", "Мужской")
	assert_registered_seed("Gazlowe", "Мужской")
	assert_registered_seed("Cicero", "Любой")

	TEST_ASSERT(halo_get_default_tts_seed(SPECIES_UNGGOY) != "Grunt", "Unggoy default TTS seed regressed to the rejected Grunt profile.")
	TEST_ASSERT(halo_get_default_tts_seed(SPECIES_UNGGOY) != "Donkey", "Unggoy default TTS seed regressed to the rejected Donkey profile.")
	TEST_ASSERT(halo_get_default_tts_seed(SPECIES_SANGHEILI) != "Diablo", "Sangheili default TTS seed regressed to the rejected Diablo profile.")
	TEST_ASSERT(halo_get_default_tts_seed(SPECIES_SANGHEILI) != "Cho", "Sangheili default TTS seed regressed to the rejected Cho profile.")
	TEST_ASSERT(halo_get_default_tts_seed(SPECIES_SANGHEILI) != "Darth_Vader", "Sangheili default TTS seed regressed to the rejected Darth_Vader profile.")
	TEST_ASSERT(halo_get_default_tts_seed(SPECIES_SANGHEILI) != "Davy_Jones", "Sangheili default TTS seed regressed to the rejected Davy_Jones profile.")

/datum/unit_test/halo_tts_species_defaults
	parent_type = /datum/unit_test/halo_tts

/datum/unit_test/halo_tts_species_defaults/Run()
	var/mob/living/carbon/human/sangheili = create_halo_human()
	var/mob/living/carbon/human/unggoy = create_halo_human()

	TEST_ASSERT(sangheili.set_species(SPECIES_SANGHEILI), "Failed to apply the Sangheili species in the HALO TTS default test.")
	TEST_ASSERT(unggoy.set_species(SPECIES_UNGGOY), "Failed to apply the Unggoy species in the HALO TTS default test.")
	TEST_ASSERT_EQUAL(sangheili.species?.name, SPECIES_SANGHEILI, "Sangheili species.name must remain the canonical lookup id.")
	TEST_ASSERT_EQUAL(unggoy.species?.name, SPECIES_UNGGOY, "Unggoy species.name must remain the canonical lookup id.")
	TEST_ASSERT_EQUAL(sangheili.species?.get_display_name(), "Сангхейли", "Sangheili lost its localized display label.")
	TEST_ASSERT_EQUAL(unggoy.species?.get_display_name(), "Унггой", "Unggoy lost its localized display label.")
	TEST_ASSERT_EQUAL(sangheili.get_blood_color(), /datum/species/sangheili::blood_color, "Sangheili species application should restore covenant blood color instead of human red.")
	TEST_ASSERT_EQUAL(unggoy.get_blood_color(), /datum/species/unggoy::blood_color, "Unggoy species application should restore covenant blood color instead of human red.")
	TEST_ASSERT_EQUAL(sangheili.blood_type, "S*", "Sangheili species application should override the default human blood type.")
	TEST_ASSERT_EQUAL(unggoy.blood_type, "S*", "Unggoy species application should override the default human blood type.")
	TEST_ASSERT_EQUAL(sangheili.tts_seed?.name, "Alarak", "Sangheili species application no longer assigns the approved default TTS seed.")
	TEST_ASSERT_EQUAL(unggoy.tts_seed?.name, "Dobby", "Unggoy species application no longer assigns the approved default TTS seed.")

/datum/unit_test/halo_tts_preset_defaults
	parent_type = /datum/unit_test/halo_tts

/datum/unit_test/halo_tts_preset_defaults/Run()
	var/mob/living/carbon/human/sangheili = create_halo_human()
	var/mob/living/carbon/human/unggoy = create_halo_human()

	arm_equipment(sangheili, /datum/equipment_preset/covenant/sangheili/minor, FALSE)
	arm_equipment(unggoy, /datum/equipment_preset/covenant/unggoy/minor, FALSE)

	TEST_ASSERT_EQUAL(sangheili.species?.name, SPECIES_SANGHEILI, "Sangheili HALO presets should no longer fall back to a human species.")
	TEST_ASSERT_EQUAL(unggoy.species?.name, SPECIES_UNGGOY, "Unggoy HALO presets should no longer fall back to a human species.")
	TEST_ASSERT(istype(sangheili.wear_suit, /obj/item/clothing/suit/marine/shielded/sangheili/minor), "Sangheili HALO presets regressed to a naked human and lost covenant armor equip.")
	TEST_ASSERT(istype(unggoy.wear_mask, /obj/item/clothing/mask/gas/unggoy), "Unggoy HALO presets regressed to a naked human and lost the covenant rebreather equip.")
	TEST_ASSERT_EQUAL(sangheili.get_blood_color(), /datum/species/sangheili::blood_color, "Sangheili HALO presets should preserve covenant blood color.")
	TEST_ASSERT_EQUAL(unggoy.get_blood_color(), /datum/species/unggoy::blood_color, "Unggoy HALO presets should preserve covenant blood color.")
	TEST_ASSERT_EQUAL(sangheili.tts_seed?.name, "Alarak", "Sangheili equipment presets no longer restore the approved default TTS seed after load.")
	TEST_ASSERT_EQUAL(unggoy.tts_seed?.name, "Dobby", "Unggoy equipment presets no longer restore the approved default TTS seed after load.")

/datum/unit_test/halo_tts_species_subtypes
	parent_type = /datum/unit_test/halo_tts

/datum/unit_test/halo_tts_species_subtypes/Run()
	var/mob/living/carbon/human/sangheili = allocate(/mob/living/carbon/human/sangheili, run_loc_floor_top_right)
	var/mob/living/carbon/human/unggoy = allocate(/mob/living/carbon/human/unggoy, run_loc_floor_bottom_left)

	TEST_ASSERT_EQUAL(sangheili.species?.name, SPECIES_SANGHEILI, "The direct /mob/living/carbon/human/sangheili subtype should spawn with the Sangheili species.")
	TEST_ASSERT_EQUAL(unggoy.species?.name, SPECIES_UNGGOY, "The direct /mob/living/carbon/human/unggoy subtype should spawn with the Unggoy species.")
	TEST_ASSERT_EQUAL(sangheili.get_blood_color(), /datum/species/sangheili::blood_color, "The direct Sangheili subtype should not keep the default human blood color.")
	TEST_ASSERT_EQUAL(unggoy.get_blood_color(), /datum/species/unggoy::blood_color, "The direct Unggoy subtype should not keep the default human blood color.")
	TEST_ASSERT_EQUAL(sangheili.blood_type, "S*", "The direct Sangheili subtype should inherit the covenant blood type.")
	TEST_ASSERT_EQUAL(unggoy.blood_type, "S*", "The direct Unggoy subtype should inherit the covenant blood type.")
