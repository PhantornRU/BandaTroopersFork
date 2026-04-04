// SS220 EDIT - START: BT-specific regression coverage for medic ladders and self-splint behavior
/datum/skills/medical_regressions_self_splint
	name = "Medical Regression Test Skills"
	skills = list(
		SKILL_MEDICAL = SKILL_MEDICAL_MASTER,
	)

/datum/unit_test/medical_regressions/proc/assert_preset_skill_levels(preset_type, expected_medical, expected_surgery)
	var/datum/equipment_preset/preset = allocate(preset_type)
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)

	preset.load_skills(human)

	TEST_ASSERT_NOTNULL(human.skills, "[preset_type] did not apply a skill datum.")
	TEST_ASSERT_EQUAL(human.skills.get_skill_level(SKILL_MEDICAL), expected_medical, "[preset_type] medical skill level regressed.")
	TEST_ASSERT_EQUAL(human.skills.get_skill_level(SKILL_SURGERY), expected_surgery, "[preset_type] surgery skill level regressed.")

/datum/unit_test/medical_regressions/proc/prepare_self_splint_target(limb_name, active_left_hand = FALSE)
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/obj/item/stack/medical/splint/splint = allocate(/obj/item/stack/medical/splint, run_loc_floor_bottom_left)
	var/obj/limb/limb = human.get_limb(limb_name)

	TEST_ASSERT_NOTNULL(limb, "Expected [limb_name] limb to exist.")

	human.skills = allocate(/datum/skills/medical_regressions_self_splint)

	limb.fracture(100)
	TEST_ASSERT(limb.status & LIMB_BROKEN, "[limb_name] should be fractured before the splint test starts.")

	human.hand = active_left_hand
	TEST_ASSERT(human.put_in_active_hand(splint), "Failed to place a splint in the active hand for [limb_name].")
	human.zone_selected = limb_name

	return list("human" = human, "splint" = splint, "limb" = limb)

/datum/unit_test/medical_regressions_corpsman_skills
	parent_type = /datum/unit_test/medical_regressions

/datum/unit_test/medical_regressions_corpsman_skills/Run()
	assert_preset_skill_levels(/datum/equipment_preset/uscm/medic, SKILL_MEDICAL_DOCTOR, SKILL_SURGERY_TRAINED)
	assert_preset_skill_levels(/datum/equipment_preset/uscm/medic_equipped, SKILL_MEDICAL_DOCTOR, SKILL_SURGERY_TRAINED)
	assert_preset_skill_levels(/datum/equipment_preset/uscm/cbrn/medic, SKILL_MEDICAL_MASTER, SKILL_SURGERY_EXPERT)
	assert_preset_skill_levels(/datum/equipment_preset/uscm/forecon/corpsman, SKILL_MEDICAL_DOCTOR, SKILL_SURGERY_TRAINED)
	assert_preset_skill_levels(/datum/equipment_preset/survivor/forecon/corpsman, SKILL_MEDICAL_DOCTOR, SKILL_SURGERY_TRAINED)
	assert_preset_skill_levels(/datum/equipment_preset/uscm/marsoc/medic, SKILL_MEDICAL_MASTER, SKILL_SURGERY_EXPERT)
	assert_preset_skill_levels(/datum/equipment_preset/unsc/medic, SKILL_MEDICAL_DOCTOR, SKILL_SURGERY_TRAINED)
	assert_preset_skill_levels(/datum/equipment_preset/unsc/medic/odst, SKILL_MEDICAL_MASTER, SKILL_SURGERY_EXPERT)
	assert_preset_skill_levels(/datum/equipment_preset/oni/security/corpsman, SKILL_MEDICAL_DOCTOR, SKILL_SURGERY_TRAINED)
	assert_preset_skill_levels(/datum/equipment_preset/usasf/corpsman, SKILL_MEDICAL_DOCTOR, SKILL_SURGERY_TRAINED)
	assert_preset_skill_levels(/datum/equipment_preset/pmc/medic, SKILL_MEDICAL_MASTER, SKILL_SURGERY_EXPERT)
	assert_preset_skill_levels(/datum/equipment_preset/uscm/pmc/med, SKILL_MEDICAL_MASTER, SKILL_SURGERY_EXPERT)
	assert_preset_skill_levels(/datum/equipment_preset/contractor/duty/medic, SKILL_MEDICAL_MASTER, SKILL_SURGERY_EXPERT)
	assert_preset_skill_levels(/datum/equipment_preset/contractor/covert/medic, SKILL_MEDICAL_MASTER, SKILL_SURGERY_EXPERT)
	assert_preset_skill_levels(/datum/equipment_preset/mercenary/sentinel/medic, SKILL_MEDICAL_MASTER, SKILL_SURGERY_EXPERT)
	assert_preset_skill_levels(/datum/equipment_preset/other/elite_merc/medic, SKILL_MEDICAL_MASTER, SKILL_SURGERY_EXPERT)

/datum/unit_test/medical_regressions_self_splint_leg
	parent_type = /datum/unit_test/medical_regressions

/datum/unit_test/medical_regressions_self_splint_leg/Run()
	var/list/context = prepare_self_splint_target("l_leg")
	var/mob/living/carbon/human/human = context["human"]
	var/obj/item/stack/medical/splint/splint = context["splint"]
	var/obj/limb/limb = context["limb"]

	splint.attack(human, human, human)
	sleep(6 SECONDS)

	TEST_ASSERT(limb.status & LIMB_SPLINTED, "A human should be able to self-splint a fractured leg.")

/datum/unit_test/medical_regressions_self_splint_offhand_arm
	parent_type = /datum/unit_test/medical_regressions

/datum/unit_test/medical_regressions_self_splint_offhand_arm/Run()
	var/list/context = prepare_self_splint_target("r_arm", TRUE)
	var/mob/living/carbon/human/human = context["human"]
	var/obj/item/stack/medical/splint/splint = context["splint"]
	var/obj/limb/limb = context["limb"]

	splint.attack(human, human, human)
	sleep(6 SECONDS)

	TEST_ASSERT(limb.status & LIMB_SPLINTED, "A human should be able to self-splint the opposite arm with their free hand.")

/datum/unit_test/medical_regressions_self_splint_active_arm_block
	parent_type = /datum/unit_test/medical_regressions

/datum/unit_test/medical_regressions_self_splint_active_arm_block/Run()
	var/list/context = prepare_self_splint_target("r_arm")
	var/mob/living/carbon/human/human = context["human"]
	var/obj/item/stack/medical/splint/splint = context["splint"]
	var/obj/limb/limb = context["limb"]

	splint.attack(human, human, human)
	sleep(world.tick_lag)

	TEST_ASSERT(!(limb.status & LIMB_SPLINTED), "Self-splinting the arm currently holding the splint should stay blocked.")
// SS220 EDIT - END
