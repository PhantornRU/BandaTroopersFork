/datum/unit_test/halo_name_localization
	priority = TEST_DEFAULT

/datum/unit_test/halo_name_localization/Run()
	return

/datum/unit_test/halo_name_localization_translation_helper
	parent_type = /datum/unit_test/halo_name_localization

/datum/unit_test/halo_name_localization_translation_helper/Run()
	var/obj/structure/machinery/optable/operating_table = allocate(/obj/structure/machinery/optable, run_loc_floor_top_right)
	TEST_ASSERT_EQUAL(operating_table.name, "Operating Table", "Operating table canonical name drifted, update the localized-name helper test fixture.")

	var/localized_name = operating_table.get_display_name_ru()
	var/expected_name = get_display_name_ru_initial(operating_table.name, NOMINATIVE, operating_table.name)

	TEST_ASSERT_EQUAL(localized_name, expected_name, "Localized display-name helper no longer matches translation-data lookup for English canonical names.")
	TEST_ASSERT_NOTEQUAL(localized_name, operating_table.name, "Localized display-name helper should differ from canonical English name when translation data exists.")

/datum/unit_test/halo_name_localization_runtime_name
	parent_type = /datum/unit_test/halo_name_localization

/datum/unit_test/halo_name_localization_runtime_name/Run()
	var/obj/structure/machinery/door/airlock/unsc/halo_airlock = allocate(/obj/structure/machinery/door/airlock/unsc, run_loc_floor_top_right)

	TEST_ASSERT_NOTEQUAL(halo_airlock.name, initial(halo_airlock.name), "HALO-tagged objects should apply their localized runtime name instead of keeping the canonical English source name.")
	TEST_ASSERT_EQUAL(halo_airlock.name, halo_airlock.get_display_name_ru(), "HALO-tagged objects should expose the localized runtime name through the standard display-name helper.")

/datum/unit_test/halo_name_localization_non_halo_passthrough
	parent_type = /datum/unit_test/halo_name_localization

/datum/unit_test/halo_name_localization_non_halo_passthrough/Run()
	var/obj/item/circuitboard/airlock/airlock_board = allocate(/obj/item/circuitboard/airlock, run_loc_floor_top_right)

	TEST_ASSERT_EQUAL(airlock_board.name, initial(airlock_board.name), "Non-HALO translation entries should not rewrite canonical runtime names globally.")

/datum/unit_test/halo_name_localization_examine_surface
	parent_type = /datum/unit_test/halo_name_localization

/datum/unit_test/halo_name_localization_examine_surface/Run()
	var/obj/structure/machinery/door/airlock/unsc/halo_airlock = allocate(/obj/structure/machinery/door/airlock/unsc, run_loc_floor_top_right)
	var/list/examine_strings = halo_airlock.get_examine_text(null)

	TEST_ASSERT(length(examine_strings) >= 1, "Localized HALO examine output should contain at least one line.")
	TEST_ASSERT(findtext(examine_strings[1], halo_airlock.name), "Localized HALO examine output should show the translated display name.")
	TEST_ASSERT(!findtext(examine_strings[1], "That's"), "Localized HALO examine output should not fall back to the raw English article line.")

/datum/unit_test/halo_name_localization_vendor_hook
	parent_type = /datum/unit_test/halo_name_localization

/datum/unit_test/halo_name_localization_vendor_hook/Run()
	var/list/entries = list(
		list("halo essential medical supplies", -1, null, null),
		list("halo health analyzer", 1, /obj/item/device/healthanalyzer/halo, VENDOR_ITEM_REGULAR),
		list("halo medical bottle (peridaxon)", 1, /obj/item/reagent_container/glass/beaker/unsc/peridaxon, VENDOR_ITEM_REGULAR),
	)

	translate_vendor_entries_to_ru(entries)

	TEST_ASSERT_EQUAL(entries[1][1], "ПРЕДМЕТЫ ПЕРВОЙ НЕОБХОДИМОСТИ", "HALO vendor category entries should route through translation_data and keep their current Russian display text.")
	TEST_ASSERT_EQUAL(entries[2][1], "Анализатор здоровья", "HALO vendor item entries should use the explicit vendor translation hook instead of canonical English keys.")
	TEST_ASSERT_EQUAL(entries[3][1], "Медицинский флакон (перидаксон)", "HALO vendor bottle entries should keep their existing Russian wording after translation.")
