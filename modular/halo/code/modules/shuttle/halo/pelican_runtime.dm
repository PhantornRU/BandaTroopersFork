/turf/open/space/transit/dropship/pelican
	shuttle_tag = DROPSHIP_PELICAN
	dir = SOUTH

/obj/docking_port/mobile/marine_dropship/pelican
	name = "D77H-TCE \"Pelican\" dropship"
	id = DROPSHIP_PELICAN
	width = 21
	height = 25
	dwidth = 10
	dheight = 12

/obj/docking_port/mobile/marine_dropship/pelican/get_transit_path_type()
	return /turf/open/space/transit/dropship/pelican

/obj/docking_port/stationary/marine_dropship/pelican_lz
	name = "Pelican LZ"
	auto_open = TRUE
	height = 25
	width = 21
	dheight = 12
	dwidth = 10

/obj/docking_port/stationary/marine_dropship/pelican_lz/hangar
	name = "Dark Was The Night Hangar Bay"
	roundstart_template = /datum/map_template/shuttle/pelican

/obj/structure/machinery/computer/shuttle/dropship/flight/pelican
	icon = 'icons/halo/obj/structures/machinery/64x64computer.dmi'
	icon_state = "pelican_drive"

/obj/structure/machinery/computer/dropship_weapons/pelican
	name = "\improper D77H-TCE \"Pelican\" dropship weapons controls"
	icon = 'icons/halo/obj/structures/machinery/64x64computer.dmi'
	icon_state = "pelican_shooty"
	req_one_access = list(ACCESS_MARINE_LEADER, ACCESS_MARINE_DROPSHIP, ACCESS_WY_FLIGHT)
	firemission_envelope = new /datum/cas_fire_envelope/uscm_dropship()
	shuttle_tag = DROPSHIP_PELICAN
