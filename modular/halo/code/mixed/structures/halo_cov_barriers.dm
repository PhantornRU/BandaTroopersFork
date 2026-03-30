/obj/structure/covenant_barricade
	name = "Covenant defensive barrier"
	desc = "Прочный наноламинатный барьер. Почти неуязвим для обычного стрелкового оружия."
	breakable = FALSE
	indestructible = TRUE
	icon = 'icons/halo/obj/structures/cov_barriers.dmi'
	icon_state = "cov_barrier"
	density = TRUE
	var/is_wide = FALSE
	var/pixel_adjustment = 0
	var/list/obj/structure/blocker/invisible_wall/covenant_barrier/blocker_parts = list()

/obj/structure/covenant_barricade/Destroy()
	QDEL_LIST(blocker_parts)
	UnregisterSignal(src, COMSIG_ATOM_DIR_CHANGE)
	return ..()

/obj/structure/covenant_barricade/Initialize()
	. = ..()
	rebuild_barrier_shape(dir)
	RegisterSignal(src, COMSIG_ATOM_DIR_CHANGE, PROC_REF(update_dirs))

/obj/structure/covenant_barricade/update_icon()
	. = ..()
	rebuild_barrier_shape(dir)

/obj/structure/covenant_barricade/proc/update_dirs(atom/movable/source, olddir, newdir)
	SIGNAL_HANDLER
	rebuild_barrier_shape(newdir)

/obj/structure/covenant_barricade/proc/rebuild_barrier_shape(newdir = dir)
	overlays.Cut()
	pixel_adjustment = 0
	bound_width = initial(bound_width)
	bound_height = initial(bound_height)
	rebuild_wide_blockers(newdir)

	if(is_wide && (newdir == WEST || newdir == EAST))
		pixel_adjustment = 64

	var/image/overlay = image(icon, icon_state = "[initial(icon_state)]_o", layer = 4.4, pixel_y = pixel_adjustment)
	overlays += overlay

/obj/structure/covenant_barricade/proc/rebuild_wide_blockers(newdir = dir)
	QDEL_LIST(blocker_parts)
	if(!is_wide)
		return

	var/list/side_dirs = list()
	switch(newdir)
		if(NORTH, SOUTH)
			side_dirs = list(EAST, WEST)
		if(EAST, WEST)
			side_dirs = list(NORTH, SOUTH)

	for(var/side_dir in side_dirs)
		var/turf/blocker_turf = get_step(src, side_dir)
		if(!isturf(blocker_turf))
			continue

		var/obj/structure/blocker/invisible_wall/covenant_barrier/blocker = new(blocker_turf)
		blocker.linked_barrier = src
		blocker.desc = desc
		blocker_parts += blocker

/obj/structure/covenant_barricade/wide
	name = "Covenant triptych barrier"
	icon_state = "cov_triplebarrier"
	is_wide = TRUE

/obj/structure/covenant_barricade/north
	dir = NORTH

/obj/structure/covenant_barricade/east
	dir = EAST

/obj/structure/covenant_barricade/south
	dir = SOUTH

/obj/structure/covenant_barricade/west
	dir = WEST

/obj/structure/covenant_barricade/wide/north
	dir = NORTH

/obj/structure/covenant_barricade/wide/east
	dir = EAST

/obj/structure/covenant_barricade/wide/south
	dir = SOUTH

/obj/structure/covenant_barricade/wide/west
	dir = WEST

/obj/structure/blocker/invisible_wall/covenant_barrier
	name = "Covenant barrier field"
	desc = "The shielded edges of a Covenant barrier block the path."
	invisibility = INVISIBILITY_MAXIMUM
	var/obj/structure/covenant_barricade/linked_barrier
