/datum/map_template/shuttle/mackay_station
	shuttle_id = "unused"
	var/elevator_network

/datum/map_template/shuttle/mackay_station/golf
	name = "Tram Golf"
	shuttle_id = MOBILE_STATION_TRAM_GOLF
	elevator_network = "tram_golf"

/datum/map_template/shuttle/mackay_station/romeo
	name = "Tram Romeo"
	shuttle_id = MOBILE_STATION_TRAM_ROMEO
	elevator_network = "tram_romeo"

/datum/map_template/shuttle/mackay_station/bravo
	name = "Tram Bravo"
	shuttle_id = MOBILE_STATION_TRAM_BRAVO
	elevator_network = "tram_bravo"

/datum/map_template/shuttle/mackay_station/fire_control
	name = "Fire Control Elevator"
	shuttle_id = MOBILE_STATION_FIRE_CONTROL
	elevator_network = "fire_control"

/datum/map_template/shuttle/mackay_station/hangar
	name = "Hangar Elevator"
	shuttle_id = MOBILE_STATION_HANGAR
	elevator_network = "hangar"

/datum/map_template/shuttle/oni_digsite_451
	shuttle_id = "unused"
	var/elevator_network

/datum/map_template/shuttle/oni_digsite_451/digsite_elevator
	name = "Digsite Elevator"
	shuttle_id = MOBILE_DIGSITE_ELEVATOR
	elevator_network = "digsite"

/datum/map_template/shuttle/pelican
	name = "D77H-TCE \"Pelican\" dropship"
	shuttle_id = DROPSHIP_PELICAN

/datum/map_template/shuttle/pelican/post_load(obj/docking_port/mobile/M)
	. = ..()
	for(var/area/shuttle_area as anything in M.shuttle_areas)
		for(var/obj/structure/roof/pelican_roof/roof in shuttle_area)
			roof.refresh_pelican_roof_images()
