/datum/unit_test/personal_name_localization
	priority = TEST_DEFAULT

/datum/unit_test/personal_name_localization/proc/assert_no_latin_script(name_value, context)
	TEST_ASSERT(istext(name_value), "[context] should resolve to text.")
	TEST_ASSERT(length_char(name_value) >= 1, "[context] should not be empty.")

	for(var/index in 1 to length_char(name_value))
		var/codepoint = text2ascii_char(name_value, index)
		if((codepoint >= 65 && codepoint <= 90) || (codepoint >= 97 && codepoint <= 122) || (codepoint >= 192 && codepoint <= 687))
			TEST_FAIL("[context] still contains Latin-script output: [name_value]")

/datum/unit_test/personal_name_localization/proc/create_test_human()
	return allocate(/mob/living/carbon/human, run_loc_floor_top_right)

/datum/unit_test/personal_name_localization/Run()
	return

/datum/unit_test/personal_name_localization_banks
	parent_type = /datum/unit_test/personal_name_localization

/datum/unit_test/personal_name_localization_banks/Run()
	var/list/samples = list(
		"human first name" = pick(GLOB.first_names_male),
		"human surname" = pick(GLOB.last_names),
		"UPP first name" = pick(GLOB.first_names_male_upp),
		"PMC first name" = pick(GLOB.first_names_female_pmc),
		"japanese first name" = ss220_pick_japanese_first_name(MALE),
		"japanese surname" = ss220_pick_japanese_last_name(),
		"chinese first name" = ss220_pick_chinese_first_name(FEMALE),
		"chinese surname" = ss220_pick_chinese_last_name(),
		"monkey name" = pick(GLOB.monkey_names),
		"weapon surname" = pick(GLOB.weapon_surnames),
		"sangheili first name" = pick(GLOB.first_names_sangheili),
		"unggoy surname" = pick(GLOB.last_names_unggoy),
	)

	for(var/context as anything in samples)
		assert_no_latin_script(samples[context], context)

/datum/unit_test/personal_name_localization_random_name
	parent_type = /datum/unit_test/personal_name_localization

/datum/unit_test/personal_name_localization_random_name/Run()
	assert_no_latin_script(random_name(MALE), "random_name(MALE)")
	assert_no_latin_script(random_name(FEMALE), "random_name(FEMALE)")

/datum/unit_test/personal_name_localization_synth_generators
	parent_type = /datum/unit_test/personal_name_localization

/datum/unit_test/personal_name_localization_synth_generators/Run()
	var/mob/living/carbon/human/base_synth_human = create_test_human()
	var/datum/equipment_preset/synth/base_synth = allocate(/datum/equipment_preset/synth)
	base_synth.load_name(base_synth_human, FALSE)
	TEST_ASSERT_EQUAL(base_synth_human.real_name, "Дэвид", "Default synth fallback personal name should stay localized.")
	assert_no_latin_script(base_synth_human.real_name, "default synth fallback name")

	var/mob/living/carbon/human/working_joe_human = create_test_human()
	var/datum/equipment_preset/synth/working_joe/working_joe = allocate(/datum/equipment_preset/synth/working_joe)
	working_joe.load_name(working_joe_human, FALSE)
	TEST_ASSERT(findtext(working_joe_human.real_name, JOB_WORKING_JOE_RU), "Working Joe generator should use the localized synth designation.")
	assert_no_latin_script(working_joe_human.real_name, "Working Joe generated name")

	var/mob/living/carbon/human/security_android_human = create_test_human()
	var/datum/equipment_preset/synth/working_joe/security_android/security_android = allocate(/datum/equipment_preset/synth/working_joe/security_android)
	security_android.load_name(security_android_human, FALSE)
	TEST_ASSERT(findtext(security_android_human.real_name, "Андроид охраны"), "Security Android generator should use the localized synth designation.")
	assert_no_latin_script(security_android_human.real_name, "Security Android generated name")

	var/mob/living/carbon/human/upp_joe_human = create_test_human()
	var/datum/equipment_preset/synth/working_joe/upp/combat/upp_joe = allocate(/datum/equipment_preset/synth/working_joe/upp/combat)
	upp_joe.load_name(upp_joe_human, FALSE)
	TEST_ASSERT(findtext(upp_joe_human.real_name, JOB_UPP_JOE_RU), "UPP Joe generator should use the localized synth designation.")
	assert_no_latin_script(upp_joe_human.real_name, "UPP Joe generated name")

/datum/unit_test/personal_name_localization_halo_species
	parent_type = /datum/unit_test/personal_name_localization

/datum/unit_test/personal_name_localization_halo_species/Run()
	var/mob/living/carbon/human/sangheili = create_test_human()
	var/mob/living/carbon/human/unggoy = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)

	arm_equipment(sangheili, /datum/equipment_preset/covenant/sangheili/minor, FALSE)
	arm_equipment(unggoy, /datum/equipment_preset/covenant/unggoy/minor, FALSE)

	assert_no_latin_script(sangheili.real_name, "HALO Sangheili generated name")
	assert_no_latin_script(unggoy.real_name, "HALO Unggoy generated name")
