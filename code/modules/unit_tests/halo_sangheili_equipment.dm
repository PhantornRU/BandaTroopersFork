/datum/unit_test/halo_sangheili_equipment/proc/create_sangheili(preset_type)
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	arm_equipment(human, preset_type, FALSE)
	return human

/datum/unit_test/halo_sangheili_equipment/proc/create_sangheili_ai_brain(preset_type)
	var/mob/living/carbon/human/human = create_sangheili(preset_type)
	var/datum/component/human_ai/ai_component = human.AddComponent(/datum/component/human_ai)
	if(!ai_component)
		TEST_FAIL("Failed to add a human AI component to the HALO Sangheili test mob.")
		return null
	if(!ai_component.ai_brain)
		TEST_FAIL("Failed to resolve a human AI brain for the HALO Sangheili test mob.")
		return null
	ai_component.ai_brain.appraise_inventory(armor = TRUE)
	if(isgun(human.s_store))
		ai_component.ai_brain.set_primary_weapon(human.s_store)
	return ai_component.ai_brain

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

/datum/unit_test/halo_sangheili_equipment/proc/set_target_turf(datum/human_ai_brain/brain, distance)
	var/turf/origin = get_turf(brain?.tied_human)
	if(!origin)
		return null

	return locate(origin.x + distance, origin.y, origin.z)

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
		/datum/equipment_preset/covenant/sangheili/minor = list("bicaridine" = 0, "oxycodone" = 0, "grenades" = 0, "swords" = 0),
		/datum/equipment_preset/covenant/sangheili/major = list("bicaridine" = 1, "oxycodone" = 0, "grenades" = 0, "swords" = 0),
		/datum/equipment_preset/covenant/sangheili/ultra = list("bicaridine" = 1, "oxycodone" = 1, "grenades" = 1, "swords" = 1),
		/datum/equipment_preset/covenant/sangheili/zealot = list("bicaridine" = 1, "oxycodone" = 1, "grenades" = 1, "swords" = 1),
	)

	for(var/preset_type as anything in utility_matrix)
		var/mob/living/carbon/human/human = create_sangheili(preset_type)
		var/list/expected = utility_matrix[preset_type]

		TEST_ASSERT_EQUAL(count_belt_items(human, /obj/item/reagent_container/hypospray/autoinjector/bicaridine/halo), expected["bicaridine"], "[preset_type] drifted from the intended Sangheili bicaridine count.")
		TEST_ASSERT_EQUAL(count_belt_items(human, /obj/item/reagent_container/hypospray/autoinjector/oxycodone/halo), expected["oxycodone"], "[preset_type] drifted from the intended Sangheili oxycodone count.")
		TEST_ASSERT_EQUAL(count_belt_items(human, /obj/item/explosive/grenade/high_explosive/covenant/plasma), expected["grenades"], "[preset_type] drifted from the intended Sangheili plasma grenade count.")
		TEST_ASSERT_EQUAL(count_belt_items(human, /obj/item/weapon/covenant/energy_sword), expected["swords"], "[preset_type] drifted from the intended Sangheili energy sword count.")

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
			"swords" = 0,
		),
		/datum/equipment_preset/covenant/sangheili/ai/major_carbine = list(
			"weapon" = /obj/item/weapon/gun/rifle/covenant_carbine,
			"carbine_mags" = 5,
			"bicaridine" = 1,
			"oxycodone" = 0,
			"grenades" = 0,
			"swords" = 0,
		),
		/datum/equipment_preset/covenant/sangheili/ai/ultra_plasma = list(
			"weapon" = /obj/item/weapon/gun/energy/plasma/plasma_rifle,
			"carbine_mags" = 0,
			"bicaridine" = 1,
			"oxycodone" = 1,
			"grenades" = 1,
			"swords" = 1,
		),
		/datum/equipment_preset/covenant/sangheili/ai/zealot_command = list(
			"weapon" = /obj/item/weapon/gun/energy/plasma/plasma_rifle,
			"carbine_mags" = 0,
			"bicaridine" = 1,
			"oxycodone" = 1,
			"grenades" = 1,
			"swords" = 1,
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
		TEST_ASSERT_EQUAL(count_belt_items(human, /obj/item/weapon/covenant/energy_sword), expected["swords"], "[preset_type] drifted from the intended Sangheili energy sword count.")

/datum/unit_test/halo_sangheili_ai_sword_presets
	parent_type = /datum/unit_test/halo_sangheili_equipment

/datum/unit_test/halo_sangheili_ai_sword_presets/Run()
	var/list/sword_presets = list(
		/datum/equipment_preset/covenant/sangheili/ai/ultra_sword,
		/datum/equipment_preset/covenant/sangheili/ai/zealot_sword,
	)

	for(var/preset_type as anything in sword_presets)
		var/datum/human_ai_brain/brain = create_sangheili_ai_brain(preset_type)
		TEST_ASSERT_NOTNULL(brain, "Failed to create a HALO Sangheili sword AI for [preset_type].")
		var/mob/living/carbon/human/human = brain.tied_human
		var/obj/item/weapon/gun/energy/plasma/plasma_rifle/loose_plasma = allocate(/obj/item/weapon/gun/energy/plasma/plasma_rifle, get_turf(human))

		TEST_ASSERT_NULL(human.s_store, "[preset_type] should not keep a firearm in suit storage.")
		TEST_ASSERT_EQUAL(count_belt_items(human, /obj/item/weapon/covenant/energy_sword), 1, "[preset_type] should equip exactly one energy sword in the belt.")
		TEST_ASSERT(brain.halo_sangheili_has_sword, "[preset_type] lost its HALO sword-bearing metadata.")
		TEST_ASSERT(brain.halo_sangheili_sword_only, "[preset_type] should commit to the sword-only behavior tree.")
		TEST_ASSERT(brain.ignore_looting, "[preset_type] should ignore looting to remain sword-only.")
		TEST_ASSERT_NOTNULL(loose_plasma, "Failed to allocate a dropped plasma rifle for the ignore_looting Sangheili test.")
		brain.item_search(range(1, human))
		TEST_ASSERT(!length(brain.to_pickup), "[preset_type] should not queue dropped firearms while ignore_looting is enabled.")

/datum/unit_test/halo_sangheili_ai_mixed_sword_flags
	parent_type = /datum/unit_test/halo_sangheili_equipment

/datum/unit_test/halo_sangheili_ai_mixed_sword_flags/Run()
	var/list/mixed_presets = list(
		/datum/equipment_preset/covenant/sangheili/ai/ultra_plasma,
		/datum/equipment_preset/covenant/sangheili/ai/zealot_command,
	)

	for(var/preset_type as anything in mixed_presets)
		var/datum/human_ai_brain/brain = create_sangheili_ai_brain(preset_type)
		TEST_ASSERT_NOTNULL(brain, "Failed to create a HALO mixed Sangheili AI for [preset_type].")
		var/mob/living/carbon/human/human = brain.tied_human

		TEST_ASSERT(istype(human.s_store, /obj/item/weapon/gun), "[preset_type] should retain its primary firearm.")
		TEST_ASSERT(brain.halo_sangheili_has_sword, "[preset_type] should expose the HALO sword-bearing metadata.")
		TEST_ASSERT(!brain.halo_sangheili_sword_only, "[preset_type] should remain a mixed ranged/melee archetype.")

/datum/unit_test/halo_sangheili_ai_action_weights
	parent_type = /datum/unit_test/halo_sangheili_equipment

/datum/unit_test/halo_sangheili_ai_action_weights/Run()
	var/datum/human_ai_brain/ultra_plasma = create_sangheili_ai_brain(/datum/equipment_preset/covenant/sangheili/ai/ultra_plasma)
	TEST_ASSERT_NOTNULL(ultra_plasma, "Failed to create the HALO Ultra plasma AI for action-weight testing.")
	ultra_plasma.in_combat = TRUE
	ultra_plasma.target_turf = set_target_turf(ultra_plasma, 4)
	TEST_ASSERT_NOTNULL(ultra_plasma.target_turf, "Failed to allocate an Ultra plasma target turf for action-weight testing.")
	var/obj/item/weapon/gun/energy/plasma/ultra_plasma_weapon = ultra_plasma.primary_weapon
	COOLDOWN_START(ultra_plasma_weapon, cooldown, 5 SECONDS)
	TEST_ASSERT(GLOB.AI_actions[/datum/ai_action/sangheili_sword_charge].get_weight(ultra_plasma) > 0, "An overheated Ultra plasma AI should prefer the HALO sword charge when the target is nearby.")
	TEST_ASSERT_EQUAL(GLOB.AI_actions[/datum/ai_action/sangheili_overheat_response].get_weight(ultra_plasma), 0, "Sword-bearing Sangheili should not take the generic overheat fallback while sword charge is available.")

	var/datum/human_ai_brain/ultra_sword = create_sangheili_ai_brain(/datum/equipment_preset/covenant/sangheili/ai/ultra_sword)
	TEST_ASSERT_NOTNULL(ultra_sword, "Failed to create the HALO Ultra sword AI for action-weight testing.")
	ultra_sword.in_combat = TRUE
	ultra_sword.target_turf = set_target_turf(ultra_sword, 4)
	TEST_ASSERT_NOTNULL(ultra_sword.target_turf, "Failed to allocate an Ultra sword target turf for action-weight testing.")
	TEST_ASSERT(GLOB.AI_actions[/datum/ai_action/sangheili_sword_charge].get_weight(ultra_sword) > 0, "Sword-only Sangheili should always favor the HALO sword charge when a target exists.")

	var/datum/human_ai_brain/minor_plasma = create_sangheili_ai_brain(/datum/equipment_preset/covenant/sangheili/ai/minor_plasma)
	TEST_ASSERT_NOTNULL(minor_plasma, "Failed to create the HALO Minor plasma AI for action-weight testing.")
	minor_plasma.in_combat = TRUE
	minor_plasma.target_turf = set_target_turf(minor_plasma, 2)
	TEST_ASSERT_NOTNULL(minor_plasma.target_turf, "Failed to allocate a Minor plasma target turf for action-weight testing.")
	var/obj/item/weapon/gun/energy/plasma/minor_plasma_weapon = minor_plasma.primary_weapon
	COOLDOWN_START(minor_plasma_weapon, cooldown, 5 SECONDS)
	TEST_ASSERT(GLOB.AI_actions[/datum/ai_action/sangheili_overheat_response].get_weight(minor_plasma) > 0, "A non-sword Sangheili should use the HALO overheat fallback while its plasma weapon cools.")

/datum/unit_test/halo_sangheili_ai_speech_profiles
	parent_type = /datum/unit_test/halo_sangheili_equipment

/datum/unit_test/halo_sangheili_ai_speech_profiles/Run()
	var/datum/human_ai_brain/major = create_sangheili_ai_brain(/datum/equipment_preset/covenant/sangheili/ai/major_carbine)
	var/datum/human_ai_brain/zealot_sword = create_sangheili_ai_brain(/datum/equipment_preset/covenant/sangheili/ai/zealot_sword)
	TEST_ASSERT_NOTNULL(major, "Failed to create the HALO Sangheili major AI for speech-profile testing.")
	TEST_ASSERT_NOTNULL(zealot_sword, "Failed to create the HALO Sangheili zealot sword AI for speech-profile testing.")

	assert_human_ai_localized_lines(major.enter_combat_lines, "Sangheili major enter_combat_lines")
	assert_human_ai_localized_lines(major.need_healing_lines, "Sangheili major need_healing_lines")
	assert_human_ai_localized_lines(zealot_sword.enter_combat_lines, "Sangheili zealot sword enter_combat_lines")

	TEST_ASSERT(major.enter_combat_lines.Find("Покажите честь в бою."), "Sangheili major AI lost its HALO-formal base speech profile.")
	TEST_ASSERT(major.enter_combat_lines.Find("По моему слову."), "Sangheili major AI lost its rank-specific speech lines.")
	TEST_ASSERT(zealot_sword.enter_combat_lines.Find("Во имя Священного Круга!"), "Sangheili zealot AI lost its zealot-specific speech lines.")
	TEST_ASSERT(zealot_sword.enter_combat_lines.Find("Клинки к бою!"), "Sword-only Sangheili lost its sword-charge speech lines.")

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
