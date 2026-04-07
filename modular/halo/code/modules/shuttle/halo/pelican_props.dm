/obj/structure/platform/pelican
	name = "tandem seat steps"
	icon = 'icons/halo/obj/structures/pelican_structures.dmi'
	icon_state = "platform"
	dir = WEST
	plane = FLOOR_PLANE

/obj/structure/prop/pelican_holotank
	name = "pelican holotank"
	desc = "A small holotank capable of projecting a hologram, and rarely the avatar of an AI."
	icon = 'icons/halo/obj/structures/pelican_structures.dmi'
	icon_state = "holotank"

/obj/structure/roof/pelican_roof
	icon = 'icons/halo/obj/structures/pelican.dmi'
	icon_state = "pelican"
	indestructible = TRUE
	unslashable = TRUE
	unacidable = TRUE
	lazy_nodes = FALSE
	mouse_opacity = FALSE
	plane = 900
	alpha = 255
	pixel_y = -413
	pixel_x = -320

/obj/structure/roof/pelican_roof/ex_act(severity, direction)
	return

/obj/structure/roof/pelican_roof/Initialize()
	. = ..()
	var/image/old_normal_image = normal_image
	var/image/old_under_image = under_image
	normal_image = image(icon, src, "cutout-alt2", layer = layer)
	under_image = image(icon, src, "cutout", layer = layer)
	under_image.plane = 900
	normal_image.plane = 900
	under_image.alpha = 75
	refresh_pelican_roof_images(old_normal_image, old_under_image)

/obj/structure/roof/pelican_roof/proc/refresh_pelican_roof_images(image/old_normal_image = null, image/old_under_image = null)
	for(var/mob/player as anything in GLOB.player_list)
		if(!player?.client)
			continue
		if(old_normal_image)
			player.client.images -= old_normal_image
		if(old_under_image)
			player.client.images -= old_under_image
		player.client.images -= normal_image
		player.client.images -= under_image
		add_default_image(SSdcs, player)

	if(!istype(linked_master, /datum/roof_master_node/pelican))
		return

	var/datum/roof_master_node/pelican/master = linked_master
	for(var/mob/dead/observer/ghost as anything in master.observers_under)
		master.add_observer_client(ghost)


/obj/effect/roof_node/pelican
	icon = 'icons/halo/landmarks.dmi'
	icon_state = "roof"
