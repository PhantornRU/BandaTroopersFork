/datum/unit_test/halo_unggoy_ai/proc/create_unggoy_ai_brain(preset_type)
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	arm_equipment(human, preset_type, FALSE)
	var/datum/component/human_ai/ai_component = human.AddComponent(/datum/component/human_ai)
	if(!ai_component)
		TEST_FAIL("Failed to add a human AI component to the HALO Unggoy test mob.")
		return null
	if(!ai_component.ai_brain)
		TEST_FAIL("Failed to resolve a human AI brain for the HALO Unggoy test mob.")
		return null
	ai_component.ai_brain.appraise_inventory(armor = TRUE)
	if(isgun(human.s_store))
		ai_component.ai_brain.set_primary_weapon(human.s_store)
	return ai_component.ai_brain

/datum/unit_test/halo_unggoy_ai/proc/create_test_projectile(mob/living/carbon/human/firer, ammo_type)
	var/obj/projectile/projectile = allocate(/obj/projectile, run_loc_floor_top_right)
	var/datum/ammo/ammo = allocate(ammo_type)
	projectile.generate_bullet(ammo, 0, 0, firer)
	projectile.starting = get_turf(firer)
	projectile.def_zone = "chest"
	projectile.firer = firer
	return projectile

/datum/unit_test/halo_unggoy_ai/Run()
	return

/datum/unit_test/halo_unggoy_ai/proc/get_first_assoc_key(list/assoc_list)
	for(var/entry as anything in assoc_list)
		return entry

/datum/unit_test/halo_unggoy_ai/proc/set_target_turf(datum/human_ai_brain/brain, distance)
	var/turf/origin = get_turf(brain?.tied_human)
	if(!origin)
		return null

	return locate(origin.x + distance, origin.y, origin.z)

/datum/unit_test/halo_unggoy_ai_equipment_matrix
	parent_type = /datum/unit_test/halo_unggoy_ai

/datum/unit_test/halo_unggoy_ai_equipment_matrix/Run()
	var/list/preset_matrix = list(
		/datum/equipment_preset/covenant/unggoy/ai/minor_plasma = list("suit" = /obj/item/clothing/suit/marine/unggoy/minor, "belt" = /obj/item/storage/belt/marine/covenant/unggoy/minor),
		/datum/equipment_preset/covenant/unggoy/ai/minor_needler = list("suit" = /obj/item/clothing/suit/marine/unggoy/minor, "belt" = /obj/item/storage/belt/marine/covenant/unggoy/minor),
		/datum/equipment_preset/covenant/unggoy/ai/major_plasma = list("suit" = /obj/item/clothing/suit/marine/unggoy/major, "belt" = /obj/item/storage/belt/marine/covenant/unggoy/major),
		/datum/equipment_preset/covenant/unggoy/ai/major_needler = list("suit" = /obj/item/clothing/suit/marine/unggoy/major, "belt" = /obj/item/storage/belt/marine/covenant/unggoy/major),
		/datum/equipment_preset/covenant/unggoy/ai/heavy_plasma = list("suit" = /obj/item/clothing/suit/marine/unggoy/heavy, "belt" = /obj/item/storage/belt/marine/covenant/unggoy/heavy),
		/datum/equipment_preset/covenant/unggoy/ai/heavy_needler = list("suit" = /obj/item/clothing/suit/marine/unggoy/heavy, "belt" = /obj/item/storage/belt/marine/covenant/unggoy/heavy),
		/datum/equipment_preset/covenant/unggoy/ai/ultra = list("suit" = /obj/item/clothing/suit/marine/unggoy/ultra, "belt" = /obj/item/storage/belt/marine/covenant/unggoy/ultra),
		/datum/equipment_preset/covenant/unggoy/ai/support_medical = list("suit" = /obj/item/clothing/suit/marine/unggoy/major, "belt" = /obj/item/storage/belt/marine/covenant/unggoy/major),
		/datum/equipment_preset/covenant/unggoy/ai/specops_plasma = list("suit" = /obj/item/clothing/suit/marine/stealth/unggoy_specops, "belt" = /obj/item/storage/belt/marine/covenant/unggoy/specops),
		/datum/equipment_preset/covenant/unggoy/ai/specops_needler = list("suit" = /obj/item/clothing/suit/marine/stealth/unggoy_specops, "belt" = /obj/item/storage/belt/marine/covenant/unggoy/specops),
		/datum/equipment_preset/covenant/unggoy/ai/specops_ultra = list("suit" = /obj/item/clothing/suit/marine/stealth/unggoy_specops/ultra, "belt" = /obj/item/storage/belt/marine/covenant/unggoy/specops_ultra),
		/datum/equipment_preset/covenant/unggoy/ai/deacon_command = list("suit" = /obj/item/clothing/suit/marine/unggoy/deacon, "belt" = /obj/item/storage/belt/marine/covenant/unggoy/ultra),
		/datum/equipment_preset/covenant/unggoy/ai/suicide_bomber = list("suit" = /obj/item/clothing/suit/marine/unggoy/minor, "belt" = /obj/item/storage/belt/marine/covenant/unggoy/minor),
	)

	for(var/preset_type as anything in preset_matrix)
		var/datum/human_ai_brain/brain = create_unggoy_ai_brain(preset_type)
		TEST_ASSERT_NOTNULL(brain, "Failed to create a HALO Unggoy AI for [preset_type].")
		var/mob/living/carbon/human/human = brain.tied_human
		var/list/expected = preset_matrix[preset_type]

		TEST_ASSERT_EQUAL(human.species?.name, SPECIES_UNGGOY, "[preset_type] did not set the expected Unggoy species.")
		TEST_ASSERT(istype(human.wear_mask, /obj/item/clothing/mask/gas/unggoy), "[preset_type] did not equip the expected Unggoy rebreather.")
		TEST_ASSERT(istype(human.wear_suit, expected["suit"]), "[preset_type] did not equip the expected HALO armor type.")
		TEST_ASSERT(istype(human.belt, expected["belt"]), "[preset_type] did not equip the expected HALO belt type.")

/datum/unit_test/halo_unggoy_ai_needler_ammo
	parent_type = /datum/unit_test/halo_unggoy_ai

/datum/unit_test/halo_unggoy_ai_needler_ammo/Run()
	var/list/needler_presets = list(
		/datum/equipment_preset/covenant/unggoy/ai/minor_needler,
		/datum/equipment_preset/covenant/unggoy/ai/major_needler,
		/datum/equipment_preset/covenant/unggoy/ai/heavy_needler,
		/datum/equipment_preset/covenant/unggoy/ai/specops_needler,
	)

	for(var/preset_type as anything in needler_presets)
		var/datum/human_ai_brain/brain = create_unggoy_ai_brain(preset_type)
		TEST_ASSERT_NOTNULL(brain, "Failed to create a HALO Unggoy needler AI for [preset_type].")
		var/mob/living/carbon/human/human = brain.tied_human
		TEST_ASSERT(istype(human.s_store, /obj/item/weapon/gun/smg/covenant_needler), "[preset_type] did not equip a needler into suit storage.")

		brain.set_primary_weapon(human.s_store)
		var/obj/item/ammo_magazine/needler_crystal/crystals = brain.weapon_ammo_search(brain.primary_weapon)
		TEST_ASSERT_NOTNULL(crystals, "[preset_type] did not expose needler crystals through the AI ammunition map.")
		TEST_ASSERT(length(brain.equipment_map[HUMAN_AI_AMMUNITION]) >= 1, "[preset_type] did not retain readable ammunition in the AI equipment map.")

/datum/unit_test/halo_unggoy_ai_bomber_overrides
	parent_type = /datum/unit_test/halo_unggoy_ai

/datum/unit_test/halo_unggoy_ai_bomber_overrides/Run()
	var/datum/human_ai_brain/brain = create_unggoy_ai_brain(/datum/equipment_preset/covenant/unggoy/ai/suicide_bomber)
	TEST_ASSERT_NOTNULL(brain, "Failed to create the HALO Unggoy suicide bomber test AI.")
	TEST_ASSERT(brain.halo_suicide_bomber, "Unggoy suicide bomber lost its HALO bomber override.")
	TEST_ASSERT_EQUAL(brain.halo_suicide_prime_range, 5, "Unggoy suicide bomber prime range drifted from the intended HALO value.")
	TEST_ASSERT(brain.ignore_looting, "Unggoy suicide bomber should ignore looting while charging.")
	TEST_ASSERT(!brain.grenading_allowed, "Unggoy suicide bomber should not use the generic grenade-throw action.")
	TEST_ASSERT(brain.halo_unggoy_ignore_panic, "Unggoy suicide bomber should bypass panic-retreat behavior.")
	TEST_ASSERT(!brain.halo_unggoy_overheat_retreat, "Unggoy suicide bomber should remain exempt from the HALO overheat-retreat behavior.")

/datum/unit_test/halo_unggoy_ai_panic_behavior
	parent_type = /datum/unit_test/halo_unggoy_ai

/datum/unit_test/halo_unggoy_ai_panic_behavior/Run()
	var/list/panicking_presets = list(
		/datum/equipment_preset/covenant/unggoy/ai/minor_plasma,
		/datum/equipment_preset/covenant/unggoy/ai/major_plasma,
		/datum/equipment_preset/covenant/unggoy/ai/support_medical,
		/datum/equipment_preset/covenant/unggoy/ai/deacon_command,
	)
	var/list/steady_presets = list(
		/datum/equipment_preset/covenant/unggoy/ai/heavy_plasma,
		/datum/equipment_preset/covenant/unggoy/ai/heavy_needler,
		/datum/equipment_preset/covenant/unggoy/ai/ultra,
		/datum/equipment_preset/covenant/unggoy/ai/specops_plasma,
		/datum/equipment_preset/covenant/unggoy/ai/specops_needler,
		/datum/equipment_preset/covenant/unggoy/ai/specops_ultra,
		/datum/equipment_preset/covenant/unggoy/ai/suicide_bomber,
	)

	for(var/preset_type as anything in panicking_presets)
		var/datum/human_ai_brain/brain = create_unggoy_ai_brain(preset_type)
		TEST_ASSERT_NOTNULL(brain, "Failed to create a HALO Unggoy panic-role AI for [preset_type].")
		brain.tied_human.health = brain.tied_human.maxHealth * 0.1
		TEST_ASSERT(brain.halo_unggoy_should_panic(), "[preset_type] should enable HALO panic-retreat when heavily wounded.")

	for(var/preset_type as anything in steady_presets)
		var/datum/human_ai_brain/brain = create_unggoy_ai_brain(preset_type)
		TEST_ASSERT_NOTNULL(brain, "Failed to create a HALO Unggoy steady-role AI for [preset_type].")
		brain.tied_human.health = brain.tied_human.maxHealth * 0.1
		TEST_ASSERT(!brain.halo_unggoy_should_panic(), "[preset_type] should not enable HALO panic-retreat when heavily wounded.")

/datum/unit_test/halo_unggoy_ai_overheat_retreat
	parent_type = /datum/unit_test/halo_unggoy_ai

/datum/unit_test/halo_unggoy_ai_overheat_retreat/Run()
	var/datum/human_ai_brain/leader = create_unggoy_ai_brain(/datum/equipment_preset/covenant/unggoy/ai/major_plasma)
	var/datum/human_ai_brain/member = create_unggoy_ai_brain(/datum/equipment_preset/covenant/unggoy/ai/minor_plasma)
	TEST_ASSERT_NOTNULL(leader, "Failed to create the HALO Unggoy leader AI for overheat testing.")
	TEST_ASSERT_NOTNULL(member, "Failed to create the HALO Unggoy member AI for overheat testing.")

	var/datum/human_ai_squad/squad = SShuman_ai.create_new_squad()
	squad.add_to_squad(leader)
	squad.add_to_squad(member)
	squad.set_squad_leader(leader)

	member.in_combat = TRUE
	member.target_turf = set_target_turf(member, 3)
	TEST_ASSERT_NOTNULL(member.target_turf, "Failed to allocate an Unggoy overheat target turf.")
	var/obj/item/weapon/gun/energy/plasma/member_plasma = member.primary_weapon
	COOLDOWN_START(member_plasma, cooldown, 5 SECONDS)

	TEST_ASSERT(member.halo_unggoy_should_retreat_on_overheat(), "A plasma-armed Unggoy should retreat while its Covenant weapon cools.")
	TEST_ASSERT(member.halo_unggoy_should_hold_anchor_on_overheat(), "A leader-supported Unggoy should keep local cohesion during overheat retreat.")
	TEST_ASSERT(!member.halo_unggoy_should_flee_on_overheat(), "A leader-supported Unggoy should not use the leaderless overheat flee branch.")

	squad.set_squad_leader(null)
	TEST_ASSERT(member.halo_unggoy_should_retreat_on_overheat(), "Leaderless Unggoy should still retreat while their weapon cools.")
	TEST_ASSERT(member.halo_unggoy_should_flee_on_overheat(), "Leaderless Unggoy should use the HALO flee branch during overheat retreat.")

	COOLDOWN_RESET(member_plasma, cooldown)
	COOLDOWN_RESET(member_plasma, manual_cooldown)
	TEST_ASSERT(!member.halo_unggoy_should_retreat_on_overheat(), "Unggoy overheat retreat should end immediately after the plasma cooldown finishes.")

	var/datum/human_ai_brain/bomber = create_unggoy_ai_brain(/datum/equipment_preset/covenant/unggoy/ai/suicide_bomber)
	TEST_ASSERT_NOTNULL(bomber, "Failed to create the HALO Unggoy bomber AI for overheat testing.")
	bomber.in_combat = TRUE
	bomber.target_turf = set_target_turf(bomber, 3)
	TEST_ASSERT_NOTNULL(bomber.target_turf, "Failed to allocate an Unggoy bomber overheat target turf.")
	TEST_ASSERT(!bomber.halo_unggoy_should_retreat_on_overheat(), "Unggoy suicide bombers should remain exempt from overheat retreat.")

	qdel(squad)

/datum/unit_test/halo_unggoy_ai_adjacent_move_shortcut
	parent_type = /datum/unit_test/halo_unggoy_ai

/datum/unit_test/halo_unggoy_ai_adjacent_move_shortcut/Run()
	var/datum/human_ai_brain/brain = create_unggoy_ai_brain(/datum/equipment_preset/covenant/unggoy/ai/minor_plasma)
	TEST_ASSERT_NOTNULL(brain, "Failed to create the HALO Unggoy AI for adjacent-move shortcut testing.")

	var/turf/origin = run_loc_floor_bottom_left
	var/turf/adjacent_turf = get_step(origin, EAST)
	TEST_ASSERT(isfloorturf(origin), "The unit-test origin turf for adjacent-move shortcut testing was not a floor ([origin]).")
	TEST_ASSERT(isfloorturf(adjacent_turf), "The adjacent destination turf for adjacent-move shortcut testing was not a floor ([adjacent_turf]).")

	brain.tied_human.forceMove(origin)
	brain.ai_move_delay = 0
	brain.current_path = list(run_loc_floor_top_right)
	brain.current_path_target = run_loc_floor_top_right

	TEST_ASSERT(brain.move_to_next_turf(adjacent_turf), "Adjacent HALO AI movement should use the cheap direct-step path instead of failing.")
	TEST_ASSERT_EQUAL(get_turf(brain.tied_human), adjacent_turf, "Adjacent HALO AI movement did not move the human onto the requested turf.")
	TEST_ASSERT_NULL(brain.current_path, "Adjacent HALO AI movement should clear stale path data after a direct step.")
	TEST_ASSERT_NULL(brain.current_path_target, "Adjacent HALO AI movement should clear the stale path target after a direct step.")

/datum/unit_test/halo_ai_projectile_low_fx
	parent_type = /datum/unit_test/halo_unggoy_ai

/datum/unit_test/halo_ai_projectile_low_fx/Run()
	var/mob/living/carbon/human/firer = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	firer.mob_flags |= AI_CONTROLLED
	target.mob_flags |= AI_CONTROLLED

	var/obj/projectile/plasma_projectile = create_test_projectile(firer, /datum/ammo/energy/halo_plasma/plasma_rifle)
	TEST_ASSERT(halo_should_skip_projectile_impact_fx(plasma_projectile, target), "AI-only HALO plasma combat should enter the low-FX projectile impact path.")

	var/obj/projectile/ballistic_projectile = create_test_projectile(firer, /datum/ammo/bullet/rifle)
	TEST_ASSERT(!halo_should_skip_projectile_impact_fx(ballistic_projectile, target), "Non-HALO rifle rounds should not enter the HALO low-FX projectile impact path.")

	target.mob_flags &= ~AI_CONTROLLED
	TEST_ASSERT(!halo_should_skip_projectile_impact_fx(plasma_projectile, target), "A non-AI target should keep the regular HALO projectile impact FX path.")

/datum/unit_test/halo_unggoy_ai_firearm_appraisals
	parent_type = /datum/unit_test/halo_unggoy_ai

/datum/unit_test/halo_unggoy_ai_firearm_appraisals/Run()
	var/obj/item/weapon/gun/energy/plasma/plasma_pistol/plasma_pistol = allocate(/obj/item/weapon/gun/energy/plasma/plasma_pistol, run_loc_floor_top_right)
	var/obj/item/weapon/gun/energy/plasma/plasma_rifle/plasma_rifle = allocate(/obj/item/weapon/gun/energy/plasma/plasma_rifle, run_loc_floor_top_right)
	var/obj/item/weapon/gun/smg/covenant_needler/needler = allocate(/obj/item/weapon/gun/smg/covenant_needler, run_loc_floor_top_right)

	TEST_ASSERT_EQUAL(get_firearm_appraisal(plasma_pistol)?.type, /datum/firearm_appraisal/halo_plasma_pistol, "Plasma pistol lost its HALO-specific firearm appraisal.")
	TEST_ASSERT_EQUAL(get_firearm_appraisal(plasma_rifle)?.type, /datum/firearm_appraisal/halo_plasma_rifle, "Plasma rifle lost its HALO-specific firearm appraisal.")
	TEST_ASSERT_EQUAL(get_firearm_appraisal(needler)?.type, /datum/firearm_appraisal/halo_needler, "Needler lost its HALO-specific firearm appraisal.")

/datum/unit_test/halo_unggoy_ai_speech_profiles
	parent_type = /datum/unit_test/halo_unggoy_ai

/datum/unit_test/halo_unggoy_ai_speech_profiles/Run()
	var/datum/human_ai_brain/minor = create_unggoy_ai_brain(/datum/equipment_preset/covenant/unggoy/ai/minor_plasma)
	var/datum/human_ai_brain/support = create_unggoy_ai_brain(/datum/equipment_preset/covenant/unggoy/ai/support_medical)
	var/datum/human_ai_brain/bomber = create_unggoy_ai_brain(/datum/equipment_preset/covenant/unggoy/ai/suicide_bomber)
	TEST_ASSERT_NOTNULL(minor, "Failed to create the HALO Unggoy minor AI for speech-profile testing.")
	TEST_ASSERT_NOTNULL(support, "Failed to create the HALO Unggoy support AI for speech-profile testing.")
	TEST_ASSERT_NOTNULL(bomber, "Failed to create the HALO Unggoy bomber AI for speech-profile testing.")

	assert_human_ai_localized_lines(minor.enter_combat_lines, "Unggoy minor enter_combat_lines")
	assert_human_ai_localized_lines(support.need_healing_lines, "Unggoy support need_healing_lines")
	assert_human_ai_localized_lines(bomber.enter_combat_lines, "Unggoy bomber enter_combat_lines")

	TEST_ASSERT(minor.enter_combat_lines.Find("Начальник, помоги!"), "Unggoy AI lost its baseline panic-flavored speech lines.")
	TEST_ASSERT(support.need_healing_lines.Find("Не дайте мне умереть, я же медик!"), "Unggoy support AI lost its medical-role speech lines.")
	TEST_ASSERT(bomber.enter_combat_lines.Find("Я вас с собой заберу!"), "Unggoy bomber AI lost its suicide-role speech lines.")

/datum/unit_test/halo_unggoy_ai_squad_compositions
	parent_type = /datum/unit_test/halo_unggoy_ai

/datum/unit_test/halo_unggoy_ai_squad_compositions/Run()
	var/list/leader_matrix = list(
		/datum/human_ai_squad_preset/covenant/unggoy_fireteam = /datum/equipment_preset/covenant/unggoy/ai/major_plasma,
		/datum/human_ai_squad_preset/covenant/unggoy_assault_team = /datum/equipment_preset/covenant/unggoy/ai/major_needler,
		/datum/human_ai_squad_preset/covenant/unggoy_heavy_team = /datum/equipment_preset/covenant/unggoy/ai/ultra,
		/datum/human_ai_squad_preset/covenant/unggoy_support_team = /datum/equipment_preset/covenant/unggoy/ai/deacon_command,
		/datum/human_ai_squad_preset/covenant/unggoy_at_team = /datum/equipment_preset/covenant/unggoy/ai/ultra,
		/datum/human_ai_squad_preset/covenant/unggoy_specops_cell = /datum/equipment_preset/covenant/unggoy/ai/specops_ultra,
		/datum/human_ai_squad_preset/covenant/covenant_lance = /datum/equipment_preset/covenant/sangheili/ai/minor_plasma,
		/datum/human_ai_squad_preset/covenant/covenant_heavy_lance = /datum/equipment_preset/covenant/sangheili/ai/ultra_plasma,
		/datum/human_ai_squad_preset/covenant/covenant_at_lance = /datum/equipment_preset/covenant/sangheili/ai/zealot_command,
		/datum/human_ai_squad_preset/covenant/sangheili_pair = /datum/equipment_preset/covenant/sangheili/ai/minor_plasma,
		/datum/human_ai_squad_preset/covenant/sangheili_fireteam = /datum/equipment_preset/covenant/sangheili/ai/major_carbine,
		/datum/human_ai_squad_preset/covenant/sangheili_elite_team = /datum/equipment_preset/covenant/sangheili/ai/ultra_plasma,
		/datum/human_ai_squad_preset/covenant/sangheili_sword_pair = /datum/equipment_preset/covenant/sangheili/ai/ultra_sword,
		/datum/human_ai_squad_preset/covenant/sangheili_zealot_strike_cell = /datum/equipment_preset/covenant/sangheili/ai/zealot_sword,
	)

	for(var/preset_type as anything in leader_matrix)
		var/datum/human_ai_squad_preset/preset = allocate(preset_type)
		var/first_entry = get_first_assoc_key(preset.ai_to_spawn)
		TEST_ASSERT_EQUAL(first_entry, leader_matrix[preset_type], "[preset_type] no longer exposes its intended squad leader as the first spawned unit.")

	for(var/squad_type in subtypesof(/datum/human_ai_squad_preset/covenant))
		var/datum/human_ai_squad_preset/preset = allocate(squad_type)
		for(var/equipment_path as anything in preset.ai_to_spawn)
			TEST_ASSERT(!findtext("[equipment_path]", "anti_tank_temp"), "[squad_type] still references the retired temporary anti-tank Unggoy role.")
			if(findtext("[squad_type]", "/sangheili_"))
				TEST_ASSERT(findtext("[equipment_path]", "/sangheili/"), "[squad_type] should only contain Sangheili equipment presets.")
