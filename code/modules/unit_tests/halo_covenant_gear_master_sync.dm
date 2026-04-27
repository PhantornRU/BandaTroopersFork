/datum/unit_test/halo_covenant_gear_master_sync/Run()
	var/expected_unggoy_shoulder_slot = "Unggoy Shoulder"
	var/expected_unggoy_bicep_slot = "Unggoy Bicep"

	var/obj/item/clothing/suit/marine/unggoy/unggoy_harness = allocate(/obj/item/clothing/suit/marine/unggoy/minor, run_loc_floor_bottom_left)
	TEST_ASSERT(expected_unggoy_shoulder_slot in unggoy_harness.valid_accessory_slots, "Unggoy harnesses should accept upstream shoulder accessories.")
	TEST_ASSERT(expected_unggoy_bicep_slot in unggoy_harness.valid_accessory_slots, "Unggoy harnesses should accept upstream bicep accessories.")

	var/obj/item/clothing/accessory/pads/unggoy/bicep/specops_ultra/bicep = allocate(/obj/item/clothing/accessory/pads/unggoy/bicep/specops_ultra, run_loc_floor_bottom_left)
	TEST_ASSERT_EQUAL(bicep.slot, expected_unggoy_bicep_slot, "Unggoy bicep accessory should use the upstream bicep slot contract.")

	var/datum/halo_shield/sangheili/honor_guard/honor_guard_shield = allocate(/datum/halo_shield/sangheili/honor_guard)
	TEST_ASSERT_EQUAL(honor_guard_shield.max_shield_strength, 600, "Honor Guard shields should keep the upstream strength value.")
	TEST_ASSERT_EQUAL(honor_guard_shield.time_to_regen, 10 SECONDS, "Honor Guard shields should keep the upstream regen delay.")

	var/obj/item/storage/backpack/covenant/unggoy/specops/canister/specops_tank = allocate(/obj/item/storage/backpack/covenant/unggoy/specops/canister, run_loc_floor_bottom_left)
	TEST_ASSERT_EQUAL(specops_tank.icon_state, "unggoy_specops_4", "SpecOps Unggoy methane tanks should expose the upstream icon state.")

	var/datum/human_ai_equipment_preset/covenant/specops_sangheili/specops/cloaking/sangheili_ai_preset = allocate(/datum/human_ai_equipment_preset/covenant/specops_sangheili/specops/cloaking)
	TEST_ASSERT_EQUAL(sangheili_ai_preset.faction, FACTION_SPECOPS_SANGHEILI, "SpecOps Sangheili AI presets should use the upstream split faction.")
	TEST_ASSERT_EQUAL(sangheili_ai_preset.path, /datum/equipment_preset/covenant/sangheili/specops/cloaking, "SpecOps Sangheili AI presets should point at the modularized upstream loadout.")

	var/datum/human_ai_equipment_preset/covenant/specops_unggoy/specops_ultra/cloaking/unggoy_ai_preset = allocate(/datum/human_ai_equipment_preset/covenant/specops_unggoy/specops_ultra/cloaking)
	TEST_ASSERT_EQUAL(unggoy_ai_preset.faction, FACTION_SPECOPS_UNGGOY, "SpecOps Unggoy AI presets should use the upstream split faction.")
	TEST_ASSERT_EQUAL(unggoy_ai_preset.path, /datum/equipment_preset/covenant/unggoy/specops_ultra/cloaking, "SpecOps Unggoy AI presets should point at the modularized upstream loadout.")

	var/datum/ammo/energy/halo_plasma/plasma_rifle/plasma_rifle_ammo = allocate(/datum/ammo/energy/halo_plasma/plasma_rifle)
	TEST_ASSERT_EQUAL(plasma_rifle_ammo.shell_speed, AMMO_SPEED_TIER_2, "HALO plasma rifle ammo should keep the upstream AI fire-rate shell speed.")
