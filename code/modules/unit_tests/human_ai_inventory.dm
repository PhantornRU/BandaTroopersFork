// SS220 EDIT: regression coverage for shared human AI inventory-store null and stale-storage paths
/datum/unit_test/human_ai_inventory
	priority = TEST_DEFAULT

/datum/unit_test/human_ai_inventory/proc/create_human_ai_brain()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	var/datum/component/human_ai/ai_component = human.AddComponent(/datum/component/human_ai)
	if(!ai_component)
		TEST_FAIL("Failed to add a human AI component to the inventory regression test mob.")
		return null
	if(!ai_component.ai_brain)
		TEST_FAIL("Failed to resolve a human AI brain for the inventory regression test mob.")
		return null
	return ai_component.ai_brain

/datum/unit_test/human_ai_inventory/Run()
	return

/datum/unit_test/human_ai_inventory_store_item_null_ref
	parent_type = /datum/unit_test/human_ai_inventory

/datum/unit_test/human_ai_inventory_store_item_null_ref/Run()
	var/datum/human_ai_brain/brain = create_human_ai_brain()
	TEST_ASSERT_NOTNULL(brain, "Failed to create a human AI brain for null store-item regression coverage.")

	brain.store_item(null, "belt", HUMAN_AI_TOOLS)
	TEST_ASSERT_EQUAL(length(brain.equipment_map[HUMAN_AI_TOOLS]), 0, "Null store_item calls should leave the AI tool map untouched.")

/datum/unit_test/human_ai_inventory_store_item_missing_storage
	parent_type = /datum/unit_test/human_ai_inventory

/datum/unit_test/human_ai_inventory_store_item_missing_storage/Run()
	var/datum/human_ai_brain/brain = create_human_ai_brain()
	TEST_ASSERT_NOTNULL(brain, "Failed to create a human AI brain for missing-storage regression coverage.")

	var/mob/living/carbon/human/human = brain.tied_human
	var/obj/item/tool/crowbar/crowbar = allocate(/obj/item/tool/crowbar, run_loc_floor_bottom_left)
	TEST_ASSERT(human.put_in_hands(crowbar, TRUE), "Inventory regression test human failed to hold the crowbar.")

	brain.equipped_items_original_loc[crowbar] = "backpack"
	brain.equipment_map[HUMAN_AI_TOOLS][crowbar] = "backpack"

	brain.store_item(crowbar, "belt", HUMAN_AI_TOOLS)
	TEST_ASSERT(!(crowbar in brain.equipped_items_original_loc), "Failed item stores should clear stale original-slot tracking.")
	TEST_ASSERT(!(crowbar in brain.equipment_map[HUMAN_AI_TOOLS]), "Failed item stores should clear stale equipment-map tracking.")
	TEST_ASSERT(isturf(crowbar.loc), "Failed item stores should drop the held item instead of keeping it in-hand with no storage target.")
