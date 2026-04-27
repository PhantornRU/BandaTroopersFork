// SS220 EDIT: unit coverage for modular HALO Bumblebee shuttle and UNSC motion sensor wiring.
/datum/unit_test/halo_motion_sensor_wiring
/datum/unit_test/halo_motion_sensor_wiring/Run()
	var/obj/item/clothing/head/helmet/marine/unsc/unsc_helmet = allocate(/obj/item/clothing/head/helmet/marine/unsc)
	var/obj/item/clothing/head/helmet/marine/unsc/odst/odst_helmet = allocate(/obj/item/clothing/head/helmet/marine/unsc/odst)
	var/datum/map_template/shuttle/bumblebee_west/bumblebee_template = allocate(/datum/map_template/shuttle/bumblebee_west)
	var/obj/docking_port/stationary/escape_pod/bumblebee/bumblebee_dock = allocate(/obj/docking_port/stationary/escape_pod/bumblebee)

	TEST_ASSERT_NOTNULL(unsc_helmet.GetComponent(/datum/component/halo_motion_sensor_manager), "UNSC helmets should receive the modular HALO motion sensor manager.")
	TEST_ASSERT_NOTNULL(odst_helmet.GetComponent(/datum/component/halo_motion_sensor_manager), "UNSC ODST helmets should inherit the modular HALO motion sensor manager.")
	TEST_ASSERT_EQUAL(bumblebee_template.shuttle_id, "bumblebee_west", "Bumblebee west shuttle template lost its upstream shuttle id.")
	TEST_ASSERT_EQUAL(bumblebee_dock.roundstart_template, /datum/map_template/shuttle/bumblebee_west, "Bumblebee escape pod dock should load the Bumblebee west roundstart template.")
