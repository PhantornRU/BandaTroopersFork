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

/datum/unit_test/halo_name_localization_halo_passthrough
	parent_type = /datum/unit_test/halo_name_localization

/datum/unit_test/halo_name_localization_halo_passthrough/Run()
	var/obj/item/device/healthanalyzer/halo/halo_scanner = allocate(/obj/item/device/healthanalyzer/halo, run_loc_floor_top_right)

	TEST_ASSERT_EQUAL(halo_scanner.get_display_name_ru(), halo_scanner.name, "HALO items with already-localized source names should keep their current player-facing text until their surfaces migrate to explicit hooks.")

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
