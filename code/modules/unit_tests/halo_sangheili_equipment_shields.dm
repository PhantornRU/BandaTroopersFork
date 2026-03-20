/datum/unit_test/halo_sangheili_shield_flicker
	parent_type = /datum/unit_test/halo_sangheili_equipment

/datum/unit_test/halo_sangheili_shield_flicker/Run()
	var/mob/living/carbon/human/human = create_sangheili(/datum/equipment_preset/covenant/sangheili/minor)
	human.face_dir(EAST)
	var/obj/item/clothing/suit/marine/shielded/sangheili/harness = human.wear_suit
	TEST_ASSERT_NOTNULL(harness, "Failed to equip a Sangheili shield harness for the flicker test.")

	var/overlays_before = length(human.overlays)
	harness.take_damage(5, human)
	TEST_ASSERT(length(human.overlays) > overlays_before, "Sangheili shield damage no longer adds the onmob flicker overlay.")

/datum/unit_test/halo_sangheili_shield_processing_lifecycle
	parent_type = /datum/unit_test/halo_sangheili_equipment

/datum/unit_test/halo_sangheili_shield_processing_lifecycle/Run()
	var/mob/living/carbon/human/human = create_sangheili(/datum/equipment_preset/covenant/sangheili/minor)
	var/obj/item/clothing/suit/marine/shielded/sangheili/harness = human.wear_suit
	TEST_ASSERT_NOTNULL(harness, "Failed to equip a Sangheili shield harness for the processing lifecycle test.")

	harness.update_shield_runtime_state()
	TEST_ASSERT(!(harness in SSfastobj.processing), "An idle Sangheili shield harness should not stay in SSfastobj while fully charged.")

	harness.take_damage(10, human)
	TEST_ASSERT(harness in SSfastobj.processing, "A damaged Sangheili shield harness should enter SSfastobj while it is recovering.")

	harness.shield_strength = harness.max_shield_strength
	harness.shield_broken = FALSE
	COOLDOWN_RESET(harness, time_to_regen)
	harness.update_shield_runtime_state()
	TEST_ASSERT(!(harness in SSfastobj.processing), "A fully recovered Sangheili shield harness should leave SSfastobj once it becomes idle again.")

/datum/unit_test/halo_sangheili_shield_idle_death_shutdown
	parent_type = /datum/unit_test/halo_sangheili_equipment

/datum/unit_test/halo_sangheili_shield_idle_death_shutdown/Run()
	var/mob/living/carbon/human/human = create_sangheili(/datum/equipment_preset/covenant/sangheili/minor)
	var/obj/item/clothing/suit/marine/shielded/sangheili/harness = human.wear_suit
	TEST_ASSERT_NOTNULL(harness, "Failed to equip a Sangheili shield harness for the idle death shutdown test.")

	harness.shield_strength = harness.max_shield_strength
	harness.shield_broken = FALSE
	COOLDOWN_RESET(harness, time_to_regen)
	harness.update_shield_runtime_state()
	TEST_ASSERT(!(harness in SSfastobj.processing), "A fully charged Sangheili shield harness should be idle before the death shutdown regression check.")

	human.death(create_cause_data("unit test"))

	TEST_ASSERT_EQUAL(human.stat, DEAD, "The Sangheili test subject should be dead for the idle death shutdown regression check.")
	TEST_ASSERT(!harness.shield_enabled, "A dead Sangheili should have its shield harness disabled immediately even while idle.")
	TEST_ASSERT_EQUAL(harness.shield_strength, 0, "A dead Sangheili should lose its remaining shield strength immediately.")
	TEST_ASSERT(!(harness in SSfastobj.processing), "A dead Sangheili idle harness should not enter or remain in SSfastobj.")
	TEST_ASSERT_EQUAL(harness.intercept_projectile_damage(human, 20), 20, "A dead Sangheili idle harness should not absorb projectile damage.")

/datum/unit_test/halo_sangheili_shield_processing_death_shutdown
	parent_type = /datum/unit_test/halo_sangheili_equipment

/datum/unit_test/halo_sangheili_shield_processing_death_shutdown/Run()
	var/mob/living/carbon/human/human = create_sangheili(/datum/equipment_preset/covenant/sangheili/minor)
	var/obj/item/clothing/suit/marine/shielded/sangheili/harness = human.wear_suit
	TEST_ASSERT_NOTNULL(harness, "Failed to equip a Sangheili shield harness for the processing death shutdown test.")

	harness.take_damage(10, human)
	TEST_ASSERT(harness in SSfastobj.processing, "A damaged Sangheili shield harness should be processing before the death shutdown regression check.")

	human.death(create_cause_data("unit test"))

	TEST_ASSERT_EQUAL(human.stat, DEAD, "The Sangheili test subject should be dead for the processing death shutdown regression check.")
	TEST_ASSERT(!harness.shield_enabled, "A dead Sangheili should have its processing shield harness disabled immediately.")
	TEST_ASSERT_EQUAL(harness.shield_strength, 0, "A dead Sangheili processing harness should drop to zero shield strength immediately.")
	TEST_ASSERT(!(harness in SSfastobj.processing), "A dead Sangheili processing harness should leave SSfastobj immediately.")
	TEST_ASSERT_EQUAL(harness.intercept_projectile_damage(human, 20), 20, "A dead Sangheili processing harness should not absorb projectile damage.")

/datum/unit_test/halo_sangheili_shield_full_absorb
	parent_type = /datum/unit_test/halo_sangheili_equipment

/datum/unit_test/halo_sangheili_shield_full_absorb/Run()
	var/mob/living/carbon/human/human = create_sangheili(/datum/equipment_preset/covenant/sangheili/minor)
	human.face_dir(EAST)
	var/obj/item/clothing/suit/marine/shielded/sangheili/harness = human.wear_suit
	TEST_ASSERT_NOTNULL(harness, "Failed to equip a Sangheili shield harness for the bullet absorb test.")

	var/starting_shield = harness.shield_strength
	var/starting_brute = human.getBruteLoss()
	var/starting_fire = human.getFireLoss()
	var/overlays_before = length(human.overlays)
	var/obj/projectile/projectile = create_test_projectile(human, /datum/ammo/energy/halo_plasma/plasma_pistol/overcharge)

	human.bullet_act(projectile)

	TEST_ASSERT(harness.shield_strength < starting_shield, "Sangheili harness did not absorb any projectile damage.")
	TEST_ASSERT_EQUAL(human.getBruteLoss(), starting_brute, "A fully shielded projectile hit should not inflict brute damage through an intact Sangheili shield.")
	TEST_ASSERT_EQUAL(human.getFireLoss(), starting_fire, "A fully shielded projectile hit should not inflict burn damage through an intact Sangheili shield.")
	TEST_ASSERT(length(human.overlays) > overlays_before, "A fully shielded projectile hit should still show the Sangheili shield flicker.")

/datum/unit_test/halo_sangheili_shield_partial_absorb
	parent_type = /datum/unit_test/halo_sangheili_equipment

/datum/unit_test/halo_sangheili_shield_partial_absorb/Run()
	var/mob/living/carbon/human/human = create_sangheili(/datum/equipment_preset/covenant/sangheili/minor)
	var/obj/item/clothing/suit/marine/shielded/sangheili/harness = human.wear_suit
	TEST_ASSERT_NOTNULL(harness, "Failed to equip a Sangheili shield harness for the partial absorb test.")

	harness.shield_strength = 5
	harness.shield_broken = FALSE
	var/residual_damage = harness.intercept_projectile_damage(human, 12)

	TEST_ASSERT_EQUAL(residual_damage, 7, "Sangheili shield partial absorb no longer returns the expected residual damage.")
	TEST_ASSERT_EQUAL(harness.shield_strength, 0, "Sangheili shield partial absorb should deplete the remaining shield strength.")
	TEST_ASSERT(harness.shield_broken, "Sangheili shield partial absorb should overload and break the harness when the shield reaches zero.")

/datum/unit_test/halo_sangheili_shield_signal_cleanup
	parent_type = /datum/unit_test/halo_sangheili_equipment

/datum/unit_test/halo_sangheili_shield_signal_cleanup/Run()
	var/mob/living/carbon/human/human = create_sangheili(/datum/equipment_preset/covenant/sangheili/minor)
	var/obj/item/clothing/suit/marine/shielded/sangheili/harness = human.wear_suit
	TEST_ASSERT_NOTNULL(harness, "Failed to equip a Sangheili shield harness for the signal cleanup test.")

	harness.take_damage(5, human)
	TEST_ASSERT(harness in SSfastobj.processing, "A worn Sangheili harness should begin processing after taking shield damage.")

	human.u_equip(harness, run_loc_floor_top_right)
	harness.update_shield_runtime_state()

	var/starting_shield = harness.shield_strength
	var/residual_damage = harness.intercept_projectile_damage(human, 15)

	TEST_ASSERT(!(harness in SSfastobj.processing), "An unequipped Sangheili harness should leave SSfastobj immediately.")
	TEST_ASSERT_EQUAL(residual_damage, 15, "An unequipped Sangheili harness should not still absorb projectile damage.")
	TEST_ASSERT_EQUAL(harness.shield_strength, starting_shield, "An unequipped Sangheili harness should not mutate its shield pool on human projectile signals.")
