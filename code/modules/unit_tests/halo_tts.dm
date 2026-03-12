/datum/unit_test/halo_tts/proc/create_halo_human()
	return allocate(/mob/living/carbon/human, run_loc_floor_top_right)

/datum/unit_test/halo_tts_shortlists/Run()
	var/list/sangheili_packs = halo_get_tts_seed_packs(SPECIES_SANGHEILI)
	var/list/unggoy_packs = halo_get_tts_seed_packs(SPECIES_UNGGOY)

	TEST_ASSERT_EQUAL(halo_get_default_tts_seed(SPECIES_SANGHEILI), "Alarak", "Sangheili default TTS seed drifted away from the approved shortlist.")
	TEST_ASSERT_EQUAL(halo_get_default_tts_seed(SPECIES_UNGGOY), "Dobby", "Unggoy default TTS seed drifted away from the approved shortlist.")
	TEST_ASSERT(islist(sangheili_packs), "Sangheili TTS packs were not registered.")
	TEST_ASSERT(islist(unggoy_packs), "Unggoy TTS packs were not registered.")
	TEST_ASSERT_EQUAL(length(sangheili_packs["Pack A (Recommended)"]), 3, "Sangheili Pack A should expose exactly three canonical fallback seeds.")
	TEST_ASSERT_EQUAL(length(unggoy_packs["Pack A (Recommended)"]), 3, "Unggoy Pack A should expose exactly three canonical fallback seeds.")
	TEST_ASSERT_EQUAL(sangheili_packs["Pack A (Recommended)"][1], "Alarak", "Sangheili Pack A should lead with Alarak.")
	TEST_ASSERT_EQUAL(unggoy_packs["Pack A (Recommended)"][1], "Dobby", "Unggoy Pack A should lead with Dobby.")

/datum/unit_test/halo_tts_species_defaults
	parent_type = /datum/unit_test/halo_tts

/datum/unit_test/halo_tts_species_defaults/Run()
	var/mob/living/carbon/human/sangheili = create_halo_human()
	var/mob/living/carbon/human/unggoy = create_halo_human()

	TEST_ASSERT(sangheili.set_species(SPECIES_SANGHEILI), "Failed to apply the Sangheili species in the HALO TTS default test.")
	TEST_ASSERT(unggoy.set_species(SPECIES_UNGGOY), "Failed to apply the Unggoy species in the HALO TTS default test.")
	TEST_ASSERT_EQUAL(sangheili.tts_seed?.name, "Alarak", "Sangheili species application no longer assigns the approved default TTS seed.")
	TEST_ASSERT_EQUAL(unggoy.tts_seed?.name, "Dobby", "Unggoy species application no longer assigns the approved default TTS seed.")

/datum/unit_test/halo_tts_preset_defaults
	parent_type = /datum/unit_test/halo_tts

/datum/unit_test/halo_tts_preset_defaults/Run()
	var/mob/living/carbon/human/sangheili = create_halo_human()
	var/mob/living/carbon/human/unggoy = create_halo_human()

	arm_equipment(sangheili, /datum/equipment_preset/covenant/sangheili/minor, FALSE)
	arm_equipment(unggoy, /datum/equipment_preset/covenant/unggoy/minor, FALSE)

	TEST_ASSERT_EQUAL(sangheili.tts_seed?.name, "Alarak", "Sangheili equipment presets no longer restore the approved default TTS seed after load.")
	TEST_ASSERT_EQUAL(unggoy.tts_seed?.name, "Dobby", "Unggoy equipment presets no longer restore the approved default TTS seed after load.")
