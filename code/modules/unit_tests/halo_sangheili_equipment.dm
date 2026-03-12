/datum/unit_test/halo_sangheili_equipment/proc/create_sangheili(preset_type)
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	arm_equipment(human, preset_type, FALSE)
	return human

/datum/unit_test/halo_sangheili_equipment/proc/count_belt_items(mob/living/carbon/human/human, item_type)
	if(!human || !human.belt)
		return 0

	var/count = 0
	for(var/obj/item/item as anything in human.belt.contents)
		if(istype(item, item_type))
			count++
	return count

/datum/unit_test/halo_sangheili_equipment/proc/create_test_projectile(mob/living/carbon/human/firer, ammo_type)
	var/obj/projectile/projectile = allocate(/obj/projectile, run_loc_floor_top_right)
	var/datum/ammo/ammo = allocate(ammo_type)
	projectile.generate_bullet(ammo, 0, 0, firer)
	projectile.starting = get_turf(firer)
	projectile.def_zone = "chest"
	projectile.firer = firer
	return projectile

/datum/unit_test/halo_sangheili_equipment/Run()
	return

/datum/unit_test/halo_sangheili_equipment_matrix
	parent_type = /datum/unit_test/halo_sangheili_equipment

/datum/unit_test/halo_sangheili_equipment_matrix/Run()
	var/list/preset_matrix = list(
		/datum/equipment_preset/covenant/sangheili/minor = list(
			"helmet" = /obj/item/clothing/head/helmet/marine/sangheili/minor,
			"suit" = /obj/item/clothing/suit/marine/shielded/sangheili/minor,
			"gloves" = /obj/item/clothing/gloves/marine/sangheili/minor,
			"shoes" = /obj/item/clothing/shoes/sangheili/minor,
			"belt" = /obj/item/storage/belt/marine/covenant/sangheili/minor,
		),
		/datum/equipment_preset/covenant/sangheili/major = list(
			"helmet" = /obj/item/clothing/head/helmet/marine/sangheili/major,
			"suit" = /obj/item/clothing/suit/marine/shielded/sangheili/major,
			"gloves" = /obj/item/clothing/gloves/marine/sangheili/major,
			"shoes" = /obj/item/clothing/shoes/sangheili/major,
			"belt" = /obj/item/storage/belt/marine/covenant/sangheili/major,
		),
		/datum/equipment_preset/covenant/sangheili/ultra = list(
			"helmet" = /obj/item/clothing/head/helmet/marine/sangheili/ultra,
			"suit" = /obj/item/clothing/suit/marine/shielded/sangheili/ultra,
			"gloves" = /obj/item/clothing/gloves/marine/sangheili/ultra,
			"shoes" = /obj/item/clothing/shoes/sangheili/ultra,
			"belt" = /obj/item/storage/belt/marine/covenant/sangheili/ultra,
		),
		/datum/equipment_preset/covenant/sangheili/zealot = list(
			"helmet" = /obj/item/clothing/head/helmet/marine/sangheili/zealot,
			"suit" = /obj/item/clothing/suit/marine/shielded/sangheili/zealot,
			"gloves" = /obj/item/clothing/gloves/marine/sangheili/zealot,
			"shoes" = /obj/item/clothing/shoes/sangheili/zealot,
			"belt" = /obj/item/storage/belt/marine/covenant/sangheili/zealot,
		),
	)

	for(var/preset_type as anything in preset_matrix)
		var/mob/living/carbon/human/human = create_sangheili(preset_type)
		var/list/expected = preset_matrix[preset_type]

		TEST_ASSERT_EQUAL(human.species?.name, SPECIES_SANGHEILI, "[preset_type] did not set the expected Sangheili species.")
		TEST_ASSERT(istype(human.head, expected["helmet"]), "[preset_type] did not equip the expected Sangheili helmet.")
		TEST_ASSERT(istype(human.wear_suit, expected["suit"]), "[preset_type] did not equip the expected Sangheili harness.")
		TEST_ASSERT(istype(human.gloves, expected["gloves"]), "[preset_type] did not equip the expected Sangheili gloves.")
		TEST_ASSERT(istype(human.shoes, expected["shoes"]), "[preset_type] did not equip the expected Sangheili greaves.")
		TEST_ASSERT(istype(human.belt, expected["belt"]), "[preset_type] did not equip the expected Sangheili belt.")

/datum/unit_test/halo_sangheili_equipment_item_states
	parent_type = /datum/unit_test/halo_sangheili_equipment

/datum/unit_test/halo_sangheili_equipment_item_states/Run()
	var/list/item_state_matrix = list(
		/obj/item/clothing/head/helmet/marine/sangheili/major = "sanghelmet_major",
		/obj/item/clothing/head/helmet/marine/sangheili/ultra = "sanghelmet_ultra",
		/obj/item/clothing/head/helmet/marine/sangheili/zealot = "sanghelmet_zealot",
		/obj/item/clothing/gloves/marine/sangheili = "sanggauntlets_minor",
		/obj/item/clothing/gloves/marine/sangheili/major = "sanggauntlets_major",
		/obj/item/clothing/gloves/marine/sangheili/ultra = "sanggauntlets_ultra",
		/obj/item/clothing/gloves/marine/sangheili/zealot = "sanggauntlets_zealot",
		/obj/item/clothing/shoes/sangheili/major = "sangboots_major",
		/obj/item/clothing/shoes/sangheili/ultra = "sangboots_ultra",
		/obj/item/clothing/shoes/sangheili/zealot = "sangboots_zealot",
		/obj/item/clothing/suit/marine/shielded/sangheili/major = "sang_major",
		/obj/item/clothing/suit/marine/shielded/sangheili/ultra = "sang_ultra",
		/obj/item/clothing/suit/marine/shielded/sangheili/zealot = "sang_zealot",
	)

	for(var/item_type as anything in item_state_matrix)
		var/obj/item/item = allocate(item_type, run_loc_floor_top_right)
		TEST_ASSERT_EQUAL(item.item_state, item_state_matrix[item_type], "[item_type] lost the expected onmob item_state.")

/datum/unit_test/halo_sangheili_player_rank_utility
	parent_type = /datum/unit_test/halo_sangheili_equipment

/datum/unit_test/halo_sangheili_player_rank_utility/Run()
	var/list/utility_matrix = list(
		/datum/equipment_preset/covenant/sangheili/minor = list("bicaridine" = 0, "oxycodone" = 0, "grenades" = 0),
		/datum/equipment_preset/covenant/sangheili/major = list("bicaridine" = 1, "oxycodone" = 0, "grenades" = 0),
		/datum/equipment_preset/covenant/sangheili/ultra = list("bicaridine" = 1, "oxycodone" = 1, "grenades" = 1),
		/datum/equipment_preset/covenant/sangheili/zealot = list("bicaridine" = 1, "oxycodone" = 1, "grenades" = 1),
	)

	for(var/preset_type as anything in utility_matrix)
		var/mob/living/carbon/human/human = create_sangheili(preset_type)
		var/list/expected = utility_matrix[preset_type]

		TEST_ASSERT_EQUAL(count_belt_items(human, /obj/item/reagent_container/hypospray/autoinjector/bicaridine/halo), expected["bicaridine"], "[preset_type] drifted from the intended Sangheili bicaridine count.")
		TEST_ASSERT_EQUAL(count_belt_items(human, /obj/item/reagent_container/hypospray/autoinjector/oxycodone/halo), expected["oxycodone"], "[preset_type] drifted from the intended Sangheili oxycodone count.")
		TEST_ASSERT_EQUAL(count_belt_items(human, /obj/item/explosive/grenade/high_explosive/covenant/plasma), expected["grenades"], "[preset_type] drifted from the intended Sangheili plasma grenade count.")

/datum/unit_test/halo_sangheili_ai_rank_utility
	parent_type = /datum/unit_test/halo_sangheili_equipment

/datum/unit_test/halo_sangheili_ai_rank_utility/Run()
	var/list/utility_matrix = list(
		/datum/equipment_preset/covenant/sangheili/ai/minor_plasma = list(
			"weapon" = /obj/item/weapon/gun/energy/plasma/plasma_rifle,
			"carbine_mags" = 0,
			"bicaridine" = 0,
			"oxycodone" = 0,
			"grenades" = 0,
		),
		/datum/equipment_preset/covenant/sangheili/ai/major_carbine = list(
			"weapon" = /obj/item/weapon/gun/rifle/covenant_carbine,
			"carbine_mags" = 5,
			"bicaridine" = 1,
			"oxycodone" = 0,
			"grenades" = 0,
		),
		/datum/equipment_preset/covenant/sangheili/ai/ultra_plasma = list(
			"weapon" = /obj/item/weapon/gun/energy/plasma/plasma_rifle,
			"carbine_mags" = 0,
			"bicaridine" = 1,
			"oxycodone" = 1,
			"grenades" = 1,
		),
		/datum/equipment_preset/covenant/sangheili/ai/zealot_command = list(
			"weapon" = /obj/item/weapon/gun/energy/plasma/plasma_rifle,
			"carbine_mags" = 0,
			"bicaridine" = 1,
			"oxycodone" = 1,
			"grenades" = 1,
		),
	)

	for(var/preset_type as anything in utility_matrix)
		var/mob/living/carbon/human/human = create_sangheili(preset_type)
		var/list/expected = utility_matrix[preset_type]

		TEST_ASSERT(istype(human.s_store, expected["weapon"]), "[preset_type] no longer equips its expected primary weapon into suit storage.")
		TEST_ASSERT_EQUAL(count_belt_items(human, /obj/item/ammo_magazine/carbine), expected["carbine_mags"], "[preset_type] drifted from the intended Sangheili carbine magazine count.")
		TEST_ASSERT_EQUAL(count_belt_items(human, /obj/item/reagent_container/hypospray/autoinjector/bicaridine/halo), expected["bicaridine"], "[preset_type] drifted from the intended Sangheili bicaridine count.")
		TEST_ASSERT_EQUAL(count_belt_items(human, /obj/item/reagent_container/hypospray/autoinjector/oxycodone/halo), expected["oxycodone"], "[preset_type] drifted from the intended Sangheili oxycodone count.")
		TEST_ASSERT_EQUAL(count_belt_items(human, /obj/item/explosive/grenade/high_explosive/covenant/plasma), expected["grenades"], "[preset_type] drifted from the intended Sangheili plasma grenade count.")

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

/datum/unit_test/halo_sangheili_shield_full_absorb
	parent_type = /datum/unit_test/halo_sangheili_equipment

/datum/unit_test/halo_sangheili_shield_full_absorb/Run()
	var/mob/living/carbon/human/human = create_sangheili(/datum/equipment_preset/covenant/sangheili/minor)
	human.face_dir(EAST)
	var/obj/item/clothing/suit/marine/shielded/sangheili/harness = human.wear_suit
	TEST_ASSERT_NOTNULL(harness, "Failed to equip a Sangheili shield harness for the bullet absorb test.")

	harness.sync_projectile_damage_signal()
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

	harness.sync_projectile_damage_signal()
	harness.shield_strength = 5
	harness.shield_broken = FALSE
	var/list/projectile_damage_data = list(
		"damage_result" = 12,
		"ammo_flags" = NONE,
		"projectile" = null,
		"organ" = null,
		"cancel_bullet_act" = FALSE,
	)

	SEND_SIGNAL(human, COMSIG_HUMAN_PROJECTILE_DAMAGE, projectile_damage_data)

	TEST_ASSERT_EQUAL(projectile_damage_data["damage_result"], 7, "Sangheili shield partial absorb no longer returns the expected residual damage.")
	TEST_ASSERT(!projectile_damage_data["cancel_bullet_act"], "Sangheili shield partial absorb should not cancel the downstream bullet act.")
	TEST_ASSERT_EQUAL(harness.shield_strength, 0, "Sangheili shield partial absorb should deplete the remaining shield strength.")
	TEST_ASSERT(harness.shield_broken, "Sangheili shield partial absorb should overload and break the harness when the shield reaches zero.")

/datum/unit_test/halo_sangheili_shield_signal_cleanup
	parent_type = /datum/unit_test/halo_sangheili_equipment

/datum/unit_test/halo_sangheili_shield_signal_cleanup/Run()
	var/mob/living/carbon/human/human = create_sangheili(/datum/equipment_preset/covenant/sangheili/minor)
	var/obj/item/clothing/suit/marine/shielded/sangheili/harness = human.wear_suit
	TEST_ASSERT_NOTNULL(harness, "Failed to equip a Sangheili shield harness for the signal cleanup test.")

	harness.sync_projectile_damage_signal()
	TEST_ASSERT_NOTNULL(harness.shield_signal_owner, "Sangheili shield harness failed to register its projectile damage signal while worn.")

	human.u_equip(harness, run_loc_floor_top_right)
	harness.sync_projectile_damage_signal()

	var/starting_shield = harness.shield_strength
	var/list/projectile_damage_data = list(
		"damage_result" = 15,
		"ammo_flags" = NONE,
		"projectile" = null,
		"organ" = null,
		"cancel_bullet_act" = FALSE,
	)

	SEND_SIGNAL(human, COMSIG_HUMAN_PROJECTILE_DAMAGE, projectile_damage_data)

	TEST_ASSERT_NULL(harness.shield_signal_owner, "Sangheili shield harness kept its projectile damage signal after being unequipped.")
	TEST_ASSERT_EQUAL(projectile_damage_data["damage_result"], 15, "An unequipped Sangheili harness should not still absorb projectile damage.")
	TEST_ASSERT(!projectile_damage_data["cancel_bullet_act"], "An unequipped Sangheili harness should not cancel projectile damage.")
	TEST_ASSERT_EQUAL(harness.shield_strength, starting_shield, "An unequipped Sangheili harness should not mutate its shield pool on human projectile signals.")
