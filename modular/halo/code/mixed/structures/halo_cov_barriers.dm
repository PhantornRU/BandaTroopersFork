/obj/structure/covenant_barricade
	name = "Covenant defensive barrier"
	desc = "Прочный наноламинатный барьер. Почти неуязвим для обычного стрелкового оружия."
	breakable = FALSE
	indestructible = TRUE
	icon = 'icons/halo/obj/structures/cov_barriers.dmi'
	icon_state = "cov_barrier"
	density = TRUE
	var/is_wide = FALSE
	var/wide_overlay_pixel_y = 0
	var/list/obj/structure/blocker/invisible_wall/covenant_barrier/blocker_parts = list()

/obj/structure/covenant_barricade/Destroy()
	QDEL_LIST(blocker_parts)
	return ..()

/obj/structure/covenant_barricade/Initialize()
	. = ..()
	setDir(initial(dir))

/obj/structure/covenant_barricade/update_icon()
	. = ..()
	rebuild_barrier_shape(dir)

/obj/structure/covenant_barricade/setDir(newdir)
	. = ..()
	rebuild_barrier_shape(dir)

/obj/structure/covenant_barricade/vv_edit_var(var_name, var_value)
	if(var_name == NAMEOF(src, dir))
		setDir(var_value)
		datum_flags |= DF_VAR_EDITED
		return TRUE

	return ..()

/obj/structure/covenant_barricade/proc/rebuild_barrier_shape(newdir = dir)
	overlays.Cut()
	bound_width = initial(bound_width)
	bound_height = initial(bound_height)
	apply_wide_visual_offsets(newdir)
	rebuild_wide_blockers(newdir)

	var/image/overlay = image(icon, icon_state = "[initial(icon_state)]_o", dir = newdir, layer = 4.4, pixel_y = wide_overlay_pixel_y)
	overlays += overlay

/obj/structure/covenant_barricade/proc/apply_wide_visual_offsets(newdir = dir)
	pixel_x = initial(pixel_x)
	pixel_y = initial(pixel_y)
	wide_overlay_pixel_y = 0

	if(!is_wide)
		return

	pixel_y = -16

	switch(newdir)
		if(NORTH, SOUTH)
			pixel_x = -16
		if(EAST, WEST)
			wide_overlay_pixel_y = 64

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
