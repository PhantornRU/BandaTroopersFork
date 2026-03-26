/datum/unit_test/halo_current_map_resolution
	var/list/snapshot_configs

/datum/unit_test/halo_current_map_resolution/New()
	. = ..()
	snapshot_configs = islist(SSmapping?.configs) ? SSmapping.configs.Copy() : null

/datum/unit_test/halo_current_map_resolution/Destroy()
	SSmapping.configs = snapshot_configs ? snapshot_configs.Copy() : null
	return ..()

/datum/unit_test/halo_current_map_resolution/proc/assert_current_map_matches(obj/item/map/current_map/actual, obj/item/map/expected, label)
	TEST_ASSERT_EQUAL(actual.name, expected.name, "[label] name did not match the JSON-configured map item.")
	TEST_ASSERT_EQUAL(actual.desc, expected.desc, "[label] description did not match the JSON-configured map item.")
	TEST_ASSERT_EQUAL(actual.desc_lore, expected.desc_lore, "[label] lore description did not match the JSON-configured map item.")
	TEST_ASSERT_EQUAL(actual.html_link, expected.html_link, "[label] html_link did not match the JSON-configured map item.")
	TEST_ASSERT_EQUAL(actual.color, expected.color, "[label] color did not match the JSON-configured map item.")

/datum/unit_test/halo_current_map_resolution/Run()
	var/datum/map_config/mackay_ground = load_map_config("maps/mackay_station.json")
	var/datum/map_config/oni_ground = load_map_config("maps/oni_digsite_451.json")
	var/datum/map_config/mackay_ship = load_map_config("maps/mackay_station_shipmap.json", maptype = SHIP_MAP)

	TEST_ASSERT_NOTNULL(mackay_ground, "Failed to load Mackay Station ground map config.")
	TEST_ASSERT_NOTNULL(oni_ground, "Failed to load ONI Digsite 451 ground map config.")
	TEST_ASSERT_NOTNULL(mackay_ship, "Failed to load Mackay Station ship map config.")

	SSmapping.configs = list(GROUND_MAP = mackay_ground, SHIP_MAP = mackay_ship)
	var/obj/item/map/current_map/mackay_current = allocate(/obj/item/map/current_map)
	var/obj/item/map/mackay_station/expected_mackay = allocate(/obj/item/map/mackay_station)
	assert_current_map_matches(mackay_current, expected_mackay, "Mackay Station")

	SSmapping.configs = list(GROUND_MAP = oni_ground, SHIP_MAP = mackay_ship)
	var/obj/item/map/current_map/oni_current = allocate(/obj/item/map/current_map)
	var/obj/item/map/oni_digsite_451/expected_oni = allocate(/obj/item/map/oni_digsite_451)
	assert_current_map_matches(oni_current, expected_oni, "ONI Digsite 451")

	TEST_ASSERT(!mackay_current.should_suppress_missing_map_runtime(mackay_ground), "Ground map fallback suppression incorrectly treated Mackay Station as a ship map.")

	SSmapping.configs = list(GROUND_MAP = mackay_ship, SHIP_MAP = mackay_ship)
	TEST_ASSERT(mackay_current.should_suppress_missing_map_runtime(mackay_ship), "Ship map fallback suppression no longer recognized matching ground/ship configs.")
