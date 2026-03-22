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

	var/datum/human_ai_brain/ultra_plasma_close = create_sangheili_ai_brain(/datum/equipment_preset/covenant/sangheili/ai/ultra_plasma)
	TEST_ASSERT_NOTNULL(ultra_plasma_close, "Failed to create the HALO Ultra plasma AI for close-range sword switching tests.")
	ultra_plasma_close.in_combat = TRUE
	ultra_plasma_close.target_turf = set_target_turf(ultra_plasma_close, ultra_plasma_close.halo_sangheili_unarmed_commit_range)
	TEST_ASSERT_NOTNULL(ultra_plasma_close.target_turf, "Failed to allocate a close-range target turf for the HALO sword-switch action-weight test.")
	TEST_ASSERT(GLOB.AI_actions[/datum/ai_action/sangheili_sword_charge].get_weight(ultra_plasma_close) > 0, "Mixed HALO Sangheili should switch to the sword when a target is too close even if the firearm is still usable.")

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

/datum/unit_test/halo_sangheili_ai_wakeup_rethink
	parent_type = /datum/unit_test/halo_sangheili_equipment

/datum/unit_test/halo_sangheili_ai_wakeup_rethink/Run()
	var/datum/human_ai_brain/brain = create_sangheili_ai_brain(/datum/equipment_preset/covenant/sangheili/ai/minor_plasma)
	TEST_ASSERT_NOTNULL(brain, "Failed to create the HALO Sangheili AI for wake-up rethink testing.")

	brain.action_blacklist = list(/datum/ai_action/throw_back_nade) // SS220 EDIT: keep the wake-up regression focused on the nearby-item rethink instead of the throw-back follow-up action
	brain.nearby_item_search_interval = 10 SECONDS
	TEST_ASSERT(brain.should_run_nearby_item_search(), "The HALO Sangheili wake-up test should consume the nearby-item scan throttle once during setup.")
	TEST_ASSERT(!brain.should_run_nearby_item_search(), "The HALO Sangheili wake-up test should confirm the nearby-item scan throttle is active before standing up.")

	var/turf/grenade_turf = set_target_turf(brain, 1)
	TEST_ASSERT(isfloorturf(grenade_turf), "Failed to allocate an adjacent grenade turf for the HALO Sangheili wake-up rethink test.")
	var/obj/item/explosive/grenade/grenade = allocate(/obj/item/explosive/grenade, grenade_turf)
	grenade.active = TRUE
	grenade.fuse_type = TIMED_FUSE
	brain.active_grenade_found = null

	brain.tied_human.set_body_position(LYING_DOWN)
	var/queued_tick = world.time
	brain.on_body_position_change(brain.tied_human, STANDING_UP, LYING_DOWN)
	TEST_ASSERT_EQUAL(brain.wake_rethink_queued_at, queued_tick, "Standing back up should queue exactly one wake rethink for the current tick.")
	brain.run_wake_rethink(queued_tick)

	TEST_ASSERT_EQUAL(brain.active_grenade_found, grenade, "Standing back up should invalidate nearby-item throttling and immediately rediscover an adjacent live grenade.")

/datum/unit_test/halo_sangheili_ai_hardcrit_rest_guard
	parent_type = /datum/unit_test/halo_sangheili_equipment

/datum/unit_test/halo_sangheili_ai_hardcrit_rest_guard/Run()
	var/datum/human_ai_brain/brain = create_sangheili_ai_brain(/datum/equipment_preset/covenant/sangheili/ai/minor_plasma)
	TEST_ASSERT_NOTNULL(brain, "Failed to create the HALO Sangheili AI for hardcrit-rest testing.")

	var/mob/living/carbon/human/human = brain.tied_human
	TEST_ASSERT_NOTNULL(human, "The HALO Sangheili hardcrit-rest test requires a tied human.")
	TEST_ASSERT(!human.resting, "The HALO Sangheili hardcrit-rest test should begin with the AI standing normally.")

	new /datum/effects/crit/human(human)
	brain.process(0)
	TEST_ASSERT(human.resting, "HALO Sangheili AI should enter resting while hardcrit remains active.")

	var/datum/effects/crit/crit_effect = locate(/datum/effects/crit) in human.effects_list
	TEST_ASSERT_NOTNULL(crit_effect, "The HALO Sangheili hardcrit-rest test failed to apply the crit effect.")
	qdel(crit_effect)
	human.SetKnockDown(0)
	human.SetStun(0)

	brain.process(0)
	TEST_ASSERT(!human.resting, "HALO Sangheili AI should resume normal standing behavior once hardcrit ends.")

/datum/unit_test/halo_sangheili_ai_mixed_sword_close_switch
	parent_type = /datum/unit_test/halo_sangheili_equipment

/datum/unit_test/halo_sangheili_ai_mixed_sword_close_switch/Run()
	var/datum/human_ai_brain/ultra_plasma = create_sangheili_ai_brain(/datum/equipment_preset/covenant/sangheili/ai/ultra_plasma)
	TEST_ASSERT_NOTNULL(ultra_plasma, "Failed to create the HALO mixed Sangheili AI for close-range sword switching testing.")
	TEST_ASSERT(ultra_plasma.halo_sangheili_runtime, "HALO mixed Sangheili AI should mark itself for HALO sword runtime behavior.")
	TEST_ASSERT_NOTNULL(ultra_plasma.halo_sangheili_find_sword(), "HALO mixed Sangheili should spawn with a recoverable sword before testing close-range switching.")

	var/obj/item/weapon/gun/original_primary = ultra_plasma.primary_weapon
	TEST_ASSERT_NOTNULL(original_primary, "The HALO mixed Sangheili close-range sword-switch test requires an initial primary firearm.")

	ultra_plasma.in_combat = TRUE
	ultra_plasma.target_turf = set_target_turf(ultra_plasma, ultra_plasma.halo_sangheili_unarmed_commit_range)
	TEST_ASSERT_NOTNULL(ultra_plasma.target_turf, "Failed to allocate a close-range target turf for HALO mixed Sangheili sword switching.")

	var/datum/ai_action/sangheili_sword_charge/charge_action = new(ultra_plasma)
	charge_action.trigger_action()

	var/mob/living/carbon/human/human = ultra_plasma.tied_human
	var/obj/item/weapon/covenant/energy_sword/sword = ultra_plasma.halo_sangheili_drawn_sword
	TEST_ASSERT_NOTNULL(sword, "Mixed HALO Sangheili should draw the sword automatically when the target is too close.")

	TEST_ASSERT(ultra_plasma.halo_sangheili_melee_committed, "Mixed HALO Sangheili should enter melee mode after drawing the sword for a close target.")
	TEST_ASSERT_NULL(ultra_plasma.primary_weapon, "Mixed HALO Sangheili should park the firearm while fighting with the sword.")
	TEST_ASSERT_EQUAL(ultra_plasma.halo_sangheili_committed_primary_weapon, original_primary, "The parked HALO Sangheili firearm was not preserved for later restoration.")
	TEST_ASSERT(ultra_plasma.ignore_looting, "Mixed HALO Sangheili should stop looking for replacement loot while the sword is out.")
	TEST_ASSERT(ultra_plasma.tried_reload, "Mixed HALO Sangheili should unlock the generic melee movement flow while sword-committed.")
	TEST_ASSERT(/datum/ai_action/fire_at_target in ultra_plasma.action_blacklist, "Mixed HALO Sangheili should suppress firearm firing actions while the sword is active.")
	TEST_ASSERT(/datum/ai_action/select_primary in ultra_plasma.action_blacklist, "Mixed HALO Sangheili should suppress firearm reselection while the sword is active.")
	TEST_ASSERT_EQUAL(sword.loc, human, "The active HALO Sangheili sword should remain in the wielder's possession.")

	qdel(charge_action)

/datum/unit_test/halo_sangheili_ai_mixed_sword_return_to_ranged
	parent_type = /datum/unit_test/halo_sangheili_equipment

/datum/unit_test/halo_sangheili_ai_mixed_sword_return_to_ranged/Run()
	var/datum/human_ai_brain/ultra_plasma = create_sangheili_ai_brain(/datum/equipment_preset/covenant/sangheili/ai/ultra_plasma)
	TEST_ASSERT_NOTNULL(ultra_plasma, "Failed to create the HALO mixed Sangheili AI for ranged-restore testing.")

	var/obj/item/weapon/gun/original_primary = ultra_plasma.primary_weapon
	TEST_ASSERT_NOTNULL(original_primary, "The HALO mixed Sangheili ranged-restore test requires an initial primary firearm.")

	ultra_plasma.in_combat = TRUE
	ultra_plasma.target_turf = set_target_turf(ultra_plasma, ultra_plasma.halo_sangheili_unarmed_commit_range)
	TEST_ASSERT_NOTNULL(ultra_plasma.target_turf, "Failed to allocate a close-range target turf for HALO mixed Sangheili ranged-restore testing.")

	var/datum/ai_action/sangheili_sword_charge/charge_action = new(ultra_plasma)
	charge_action.trigger_action()

	var/mob/living/carbon/human/human = ultra_plasma.tied_human
	var/obj/item/weapon/covenant/energy_sword/sword = ultra_plasma.halo_sangheili_drawn_sword
	TEST_ASSERT_NOTNULL(sword, "The HALO mixed Sangheili ranged-restore test requires the sword to be drawn first.")

	ultra_plasma.target_turf = set_target_turf(ultra_plasma, ultra_plasma.halo_sangheili_sword_charge_range + 2)
	TEST_ASSERT_NOTNULL(ultra_plasma.target_turf, "Failed to allocate a far target turf for HALO mixed Sangheili ranged-restore testing.")

	var/result = charge_action.trigger_action()
	TEST_ASSERT_EQUAL(result, ONGOING_ACTION_COMPLETED, "The HALO sword charge action should complete once the target moves back out of sword range.")

	TEST_ASSERT(!ultra_plasma.halo_sangheili_melee_committed, "Mixed HALO Sangheili should leave melee mode once the enemy is far away again.")
	TEST_ASSERT_EQUAL(ultra_plasma.primary_weapon, original_primary, "Mixed HALO Sangheili should restore its parked firearm when returning to ranged combat.")
	TEST_ASSERT(!ultra_plasma.ignore_looting, "Mixed HALO Sangheili should restore its original looting behavior after leaving sword mode.")
	TEST_ASSERT(!ultra_plasma.action_blacklist || !(/datum/ai_action/fire_at_target in ultra_plasma.action_blacklist), "Mixed HALO Sangheili should remove firearm action suppression after leaving sword mode.")
	TEST_ASSERT(!sword.activated, "HALO Sangheili should deactivate the sword when switching back to ranged combat.")
	TEST_ASSERT_NOTEQUAL(sword.loc, human, "HALO Sangheili should no longer keep the sword in hand once ranged combat resumes.")

	ultra_plasma.target_turf = null
	ultra_plasma.lose_target()
	TEST_ASSERT(!ultra_plasma.halo_sangheili_should_sword_charge(), "Mixed HALO Sangheili should not remain in sword mode without a live melee target.")

	qdel(charge_action)

/datum/unit_test/halo_sangheili_ai_terminal_sword_persistence
	parent_type = /datum/unit_test/halo_sangheili_equipment

/datum/unit_test/halo_sangheili_ai_terminal_sword_persistence/Run()
	var/datum/human_ai_brain/ultra_plasma = create_sangheili_ai_brain(/datum/equipment_preset/covenant/sangheili/ai/ultra_plasma)
	TEST_ASSERT_NOTNULL(ultra_plasma, "Failed to create the HALO mixed Sangheili AI for terminal sword persistence testing.")

	var/obj/item/weapon/gun/original_primary = ultra_plasma.primary_weapon
	TEST_ASSERT_NOTNULL(original_primary, "The HALO terminal sword persistence test requires an initial firearm to remove.")

	ultra_plasma.in_combat = TRUE
	ultra_plasma.target_turf = set_target_turf(ultra_plasma, ultra_plasma.halo_sangheili_unarmed_commit_range)
	TEST_ASSERT_NOTNULL(ultra_plasma.target_turf, "Failed to allocate a close-range target turf for HALO terminal sword persistence testing.")

	var/datum/ai_action/sangheili_sword_charge/charge_action = new(ultra_plasma)
	charge_action.trigger_action()

	var/mob/living/carbon/human/human = ultra_plasma.tied_human
	var/obj/item/weapon/covenant/energy_sword/sword = ultra_plasma.halo_sangheili_drawn_sword
	TEST_ASSERT_NOTNULL(sword, "The HALO terminal sword persistence test requires the sword to be drawn first.")

	qdel(original_primary)
	ultra_plasma.halo_sangheili_committed_primary_weapon = null
	ultra_plasma.target_turf = set_target_turf(ultra_plasma, ultra_plasma.halo_sangheili_sword_charge_range + 2)
	TEST_ASSERT_NOTNULL(ultra_plasma.target_turf, "Failed to allocate a far target turf for HALO terminal sword persistence testing.")

	charge_action.trigger_action()
	ultra_plasma.exit_combat()

	TEST_ASSERT_NULL(ultra_plasma.primary_weapon, "HALO no-gun Sangheili should not restore a missing firearm when keeping the sword out.")
	TEST_ASSERT(!ultra_plasma.halo_sangheili_melee_committed, "HALO no-gun Sangheili should clear melee-commit bookkeeping when combat ends.")
	TEST_ASSERT_EQUAL(sword.loc, human, "HALO no-gun Sangheili should keep the sword in hand when there is no ranged fallback.")
	TEST_ASSERT(sword.activated, "HALO no-gun Sangheili should keep the sword active instead of deactivating it on teardown.")

	qdel(charge_action)
