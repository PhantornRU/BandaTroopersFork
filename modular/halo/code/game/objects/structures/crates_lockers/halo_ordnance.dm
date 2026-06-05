// SS220 EDIT - START: HALO ordnance canister types for fire support supply drops (PR #158)
// Mixed Ammo Drops

/obj/structure/closet/ordnance_canister/dropping/ammo_mix/basic
	name = parent_type::name + " (Basic Mixed Ammo)"

/obj/structure/closet/ordnance_canister/dropping/ammo_mix/basic/Initialize() // We need multiple paths and the system doesn't support that and I'm too lazy to make it do that for one thing.
	. = ..()
	new /obj/item/ammo_box/magazine/unsc/ma5b(src)
	new /obj/item/ammo_box/magazine/unsc/ma5c(src)
	new /obj/item/ammo_box/magazine/unsc/br55(src)
	new /obj/item/ammo_box/magazine/unsc/small/m6c(src)

/obj/structure/closet/ordnance_canister/dropping/ammo_mix/spec
	name = parent_type::name + " (Specialist Mixed Ammo)"

/obj/structure/closet/ordnance_canister/dropping/ammo_mix/spec/Initialize() // well maybe since i'm doing it a few times it should be done but
	. = ..()
	new /obj/item/ammo_magazine/spnkr(src)
	new /obj/item/ammo_magazine/spnkr(src)
	new /obj/item/ammo_magazine/rifle/halo/sniper(src)
	new /obj/item/ammo_magazine/rifle/halo/sniper(src)
	new /obj/item/ammo_magazine/rifle/halo/sniper(src)
	new /obj/item/ammo_magazine/rifle/halo/sniper(src)

/obj/structure/closet/ordnance_canister/dropping/ammo_mix/odst
	name = parent_type::name + " (ODST Mixed Ammo)"

/obj/structure/closet/ordnance_canister/dropping/ammo_mix/odst/Initialize() // I couldn't be arsed to figure it out, sorry
	. = ..()
	new /obj/item/ammo_box/magazine/unsc/ma5b/shredder(src)
	new /obj/item/ammo_box/magazine/unsc/ma5c/shredder(src)
	new /obj/item/ammo_box/magazine/unsc/br55/extended(src)
	new /obj/item/ammo_box/magazine/unsc/small/m6c/socom(src)
	new /obj/item/ammo_box/magazine/misc/unsc/m7_ammo(src)

// Misc. Supplies

/obj/structure/closet/ordnance_canister/dropping/misc/grenades
	name = parent_type::name + " (Mixed Grenades)"

/obj/structure/closet/ordnance_canister/dropping/misc/grenades/Initialize() // I couldn't be arsed to figure it out, sorry
	. = ..()
	new /obj/item/ammo_box/magazine/misc/unsc/grenade(src)
	new /obj/item/ammo_box/magazine/misc/unsc/grenade(src)
	new /obj/item/ammo_box/magazine/misc/unsc/grenade/smoke(src)
	new /obj/item/ammo_box/magazine/misc/unsc/grenade/smoke(src)
	new /obj/item/ammo_box/magazine/misc/unsc/grenade/blast(src)
	new /obj/item/ammo_box/magazine/misc/unsc/grenade/blast(src)

/obj/structure/closet/ordnance_canister/dropping/misc/corpsman_resupply
	name = parent_type::name + " (Corpsman Supplies)"

/obj/structure/closet/ordnance_canister/dropping/misc/corpsman_resupply/Initialize() // We need multiple paths and the system doesn't support that and I'm too lazy to make it do that for one thing.
	. = ..()
	new /obj/item/ammo_box/magazine/misc/unsc/medical_packets(src)
	new /obj/item/storage/firstaid/unsc/corpsman(src)
	new /obj/item/storage/firstaid/unsc/corpsman(src)
	new /obj/item/storage/firstaid/unsc/corpsman(src)
	new /obj/item/storage/firstaid/unsc/corpsman(src)

// SS220 EDIT - END
