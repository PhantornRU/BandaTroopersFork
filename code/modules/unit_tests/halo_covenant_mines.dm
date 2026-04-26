// SS220 EDIT: unit coverage for modular HALO Covenant mine and breaching-charge wiring.
/datum/unit_test/halo_covenant_mine_wiring
/datum/unit_test/halo_covenant_mine_wiring/Run()
	var/obj/item/explosive/mine/covenant/plasma/plasma_mine = allocate(/obj/item/explosive/mine/covenant/plasma)
	var/obj/item/explosive/mine/covenant/needle_mine/needle_mine = allocate(/obj/item/explosive/mine/covenant/needle_mine)
	var/obj/item/explosive/plastic/breaching_charge/plasma/halo/plasma_charge = allocate(/obj/item/explosive/plastic/breaching_charge/plasma/halo)
	var/datum/human_ai_breach_placer/placer = allocate(/datum/human_ai_breach_placer)
	var/datum/human_ai_defense/mine/covenant/plasma/plasma_defense = allocate(/datum/human_ai_defense/mine/covenant/plasma)
	var/datum/human_ai_defense/mine/covenant/needle/needle_defense = allocate(/datum/human_ai_defense/mine/covenant/needle)

	TEST_ASSERT_NOTNULL(placer, "Failed to instantiate the Human AI breach placer for Covenant charge wiring coverage.")
	TEST_ASSERT_EQUAL(plasma_mine.has_tripwire, FALSE, "Covenant plasma mines should stay proximity-triggered without a tripwire.")
	TEST_ASSERT_EQUAL(needle_mine.has_tripwire, FALSE, "Covenant needle mines should stay proximity-triggered without a tripwire.")
	TEST_ASSERT_EQUAL(plasma_defense.path_to_spawn, /obj/item/explosive/mine/covenant/plasma/active, "Defense creator plasma entry no longer points at the active Covenant mine.")
	TEST_ASSERT_EQUAL(needle_defense.path_to_spawn, /obj/item/explosive/mine/covenant/needle_mine/active, "Defense creator needle entry no longer points at the active Covenant mine.")
	TEST_ASSERT_EQUAL(placer.charge_dict[/obj/item/explosive/plastic/breaching_charge/plasma/halo::name], /obj/item/explosive/plastic/breaching_charge/plasma/halo, "Human AI breach placer lost the Covenant plasma charge option.")
	TEST_ASSERT(istype(plasma_charge, /obj/item/explosive/plastic/breaching_charge/plasma), "Covenant plasma charge should keep the shared plasma breaching-charge behavior.")
