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

/obj/structure/covenant_barricade/Destroy()
	UnregisterSignal(src, COMSIG_ATOM_DIR_CHANGE)
	return ..()

/obj/structure/covenant_barricade/Initialize()
	. = ..()
	update_dirs(src, dir, dir)
	RegisterSignal(src, COMSIG_ATOM_DIR_CHANGE, PROC_REF(update_dirs))

/obj/structure/covenant_barricade/update_icon()
	. = ..()
	update_dirs(src, dir, dir)

/obj/structure/covenant_barricade/proc/update_dirs(atom/movable/source, olddir, newdir)
	SIGNAL_HANDLER

	overlays.Cut()
	pixel_adjustment = 0
	if(is_wide)
		switch(newdir)
			if(NORTH, SOUTH)
				bound_width = 64
				bound_height = 32
			if(EAST, WEST)
				bound_width = 32
				bound_height = 64

	if(is_wide && (newdir == WEST || newdir == EAST))
		pixel_adjustment = 64

	var/image/overlay = image(icon, icon_state = "[initial(icon_state)]_o", layer = 4.4, pixel_y = pixel_adjustment)
	overlays += overlay

/obj/structure/covenant_barricade/wide
	name = "Covenant triptych barrier"
	icon_state = "cov_triplebarrier"
	is_wide = TRUE
