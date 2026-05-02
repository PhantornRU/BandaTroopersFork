/area/shuttle/pelican
	name = "\improper D77H-TCE \"Pelican\" dropship"
	icon_state = "shuttlered"
	base_muffle = MUFFLE_HIGH
	soundscape_interval = 30
	is_landing_zone = TRUE
	ceiling = CEILING_REINFORCED_METAL

/area/shuttle/pelican/Enter(atom/movable/O, atom/oldloc)
	if(istype(O, /obj/structure/barricade))
		return FALSE
	return TRUE

/area/shuttle/pelican/Entered(atom/movable/O, atom/oldloc)
	. = ..()
	if(!isobserver(O))
		return

	var/turf/target_turf = get_turf(O)
	if(!is_pelican_observer_view_turf(target_turf))
		return

	for(var/obj/effect/roof_node/pelican/roof_node in src)
		if(!istype(roof_node.linked_master, /datum/roof_master_node/pelican))
			continue
		var/datum/roof_master_node/pelican/master = roof_node.linked_master
		master.add_observer_under_roof(O)
		return
