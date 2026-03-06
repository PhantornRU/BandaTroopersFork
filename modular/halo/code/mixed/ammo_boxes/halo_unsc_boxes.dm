/obj/structure/magazine_box/unsc
	icon = 'icons/halo/obj/items/weapons/guns/ammo_boxes/boxes_and_lids.dmi'
	icon_state = "base"
	text_markings_icon = 'icons/halo/obj/items/weapons/guns/ammo_boxes/text.dmi'
	magazines_icon = 'icons/halo/obj/items/weapons/guns/ammo_boxes/magazines.dmi'

/obj/item/ammo_box/magazine/misc/unsc
	name = "\improper UNSC storage crate"
	desc = "A generic storage crate for the UNSC."
	icon = 'icons/halo/obj/items/weapons/guns/ammo_boxes/boxes_and_lids.dmi'
	magazines_icon = 'icons/halo/obj/items/weapons/guns/ammo_boxes/magazines.dmi'
	deployed_object = /obj/structure/magazine_box/unsc
	icon_state = "base"
	magazine_type = null
	limit_per_tile = 1
	num_of_magazines = 0
	overlay_content = null

/obj/item/ammo_box/magazine/misc/unsc/mre
	name = "\improper UNSC storage crate - (MRE x 14)"
	desc = "A generic storage crate for the UNSC holding MREs."
	icon_state = "base_mre"
	magazine_type = /obj/item/storage/box/mre
	num_of_magazines = 14
	overlay_content = "_mre"

/obj/item/ammo_box/magazine/misc/unsc/mre/empty
	empty = TRUE
