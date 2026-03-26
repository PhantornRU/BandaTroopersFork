/obj/structure/largecrate/supply/ammo/halo
	name = "HALO ammunition case"
	desc = "A HALO ammunition case containing UNSC combat resupply."
	icon_state = "secure_crate_strapped"

/obj/structure/largecrate/supply/ammo/halo/rifle
	name = "HALO rifle ammunition case"
	desc = "A HALO ammunition case containing mixed rifle ammunition for UNSC line troops."
	supplies = list(
		/obj/item/ammo_box/magazine/unsc/ma5c = 1,
		/obj/item/ammo_box/magazine/unsc/ma5b = 1,
		/obj/item/ammo_box/magazine/unsc/br55 = 1,
		/obj/item/ammo_box/magazine/unsc/small/m6c = 1,
	)

/obj/structure/largecrate/supply/ammo/halo/marksman
	name = "HALO marksman ammunition case"
	desc = "A HALO ammunition case containing DMR and sidearm magazines for UNSC marksmen."
	supplies = list(
		/obj/item/ammo_magazine/rifle/halo/dmr = 4,
		/obj/item/ammo_magazine/pistol/halo/m6d = 2,
	)

/obj/structure/largecrate/supply/ammo/halo/pdw
	name = "HALO PDW ammunition case"
	desc = "A HALO ammunition case containing M7 magazines and sidearm ammunition."
	supplies = list(
		/obj/item/ammo_magazine/smg/halo/m7 = 6,
		/obj/item/ammo_box/magazine/unsc/small/m6c = 2,
	)

/obj/structure/largecrate/supply/ammo/halo/shotgun
	name = "HALO shotgun ammunition case"
	desc = "A HALO ammunition case containing UNSC buckshot magazines."
	supplies = list(/obj/item/ammo_magazine/shotgun/buckshot/unsc = 6)

/obj/structure/largecrate/supply/ammo/halo/sniper
	name = "HALO sniper ammunition case"
	desc = "A HALO ammunition case containing SRS99 magazines."
	supplies = list(/obj/item/ammo_magazine/rifle/halo/sniper = 8)

/obj/structure/largecrate/supply/ammo/halo/spnkr
	name = "HALO SPNKr ammunition case"
	desc = "A HALO ammunition case containing SPNKr rocket tubes."
	supplies = list(/obj/item/ammo_magazine/spnkr = 4)

/obj/structure/largecrate/supply/ammo/halo/grenadier
	name = "HALO grenadier ammunition case"
	desc = "A HALO ammunition case containing 40mm grenades and fragmentation grenades."
	supplies = list(
		/obj/item/ammo_box/magazine/misc/unsc/grenade/launchable = 2,
		/obj/item/ammo_box/magazine/misc/unsc/grenade = 1,
	)

/obj/structure/largecrate/supply/medicine/halo
	name = "HALO medical case"
	desc = "A HALO medical case containing UNSC field treatment supplies."
	icon_state = "secure_crate_strapped"

/obj/structure/largecrate/supply/medicine/halo/medical_packets
	name = "HALO medical packets case"
	desc = "A HALO medical case containing trauma packets and morphine reserve."
	supplies = list(
		/obj/item/ammo_box/magazine/misc/unsc/medical_packets = 4,
		/obj/item/storage/syringe_case/unsc/morphine/full = 2,
	)

/obj/structure/largecrate/supply/medicine/halo/corpsman_kit
	name = "HALO corpsman kit case"
	desc = "A HALO medical case containing a corpsman sustain kit."
	supplies = list(
		/obj/item/storage/firstaid/unsc/corpsman = 2,
		/obj/item/storage/belt/medical/lifesaver/unsc/full = 1,
		/obj/item/storage/pouch/medkit/unsc/full = 1,
	)

/obj/structure/largecrate/supply/medicine/halo/biofoam_reserve
	name = "HALO biofoam reserve case"
	desc = "A HALO medical case containing biofoam injectors and burn treatment reserves."
	supplies = list(
		/obj/item/reagent_container/hypospray/autoinjector/primeable/biofoam = 4,
		/obj/item/reagent_container/hypospray/autoinjector/primeable/biofoam/antidote = 2,
		/obj/item/storage/syringe_case/unsc/burnguard = 2,
	)

/obj/structure/largecrate/supply/supplies/halo
	name = "HALO support case"
	desc = "A HALO support case containing UNSC field supplies."
	icon_state = "secure_crate_strapped"

/obj/structure/largecrate/supply/supplies/halo/toolbox
	name = "HALO toolbox support case"
	desc = "A HALO support case containing engineering tools and repair load-bearing gear."
	supplies = list(
		/obj/item/storage/toolbox/traxus/big = 2,
		/obj/item/storage/box/kit/engineering_supply_kit = 1,
		/obj/item/storage/backpack/marine/engineerpack/welder_chestrig = 1,
	)

/obj/structure/largecrate/supply/supplies/halo/fortification
	name = "HALO fortification case"
	desc = "A HALO support case containing field fortification materials and defensive mines."
	supplies = list(
		/obj/item/stack/sandbags_empty/half = 2,
		/obj/item/stack/sheet/plasteel/med_large_stack = 1,
		/obj/item/stack/folding_barricade/three = 1,
		/obj/item/storage/box/explosive_mines = 1,
	)

/obj/structure/largecrate/supply/supplies/halo/vehicle_service
	name = "HALO vehicle service case"
	desc = "A HALO support case containing field repair and power supplies for UNSC vehicles."
	supplies = list(
		/obj/item/storage/toolbox/traxus/big = 1,
		/obj/item/tool/weldingtool = 2,
		/obj/item/tool/weldpack/minitank = 1,
		/obj/item/tool/extinguisher/mini = 1,
		/obj/item/stack/sheet/metal/large_stack = 1,
		/obj/item/stack/sheet/plasteel/med_large_stack = 1,
		/obj/item/cell/high = 1,
	)

/obj/structure/largecrate/supply/supplies/halo/signal
	name = "HALO signal case"
	desc = "A HALO support case containing flare and signaling gear."
	supplies = list(
		/obj/item/storage/box/flare = 2,
		/obj/item/storage/box/flare/signal = 1,
		/obj/item/storage/pouch/flare/full = 1,
		/obj/item/weapon/gun/flare = 1,
	)

/obj/structure/largecrate/supply/supplies/halo/recon
	name = "HALO recon case"
	desc = "A HALO support case containing reconnaissance and navigation gear."
	supplies = list(
		/obj/item/device/binoculars/range/monocular = 2,
		/obj/item/device/motiondetector = 1,
		/obj/item/map/current_map = 1,
		/obj/item/device/flashlight/combat = 1,
	)

/obj/structure/largecrate/supply/supplies/halo/rto_command
	name = "HALO RTO command case"
	desc = "A HALO support case containing communications and JTAC coordination gear."
	supplies = list(
		/obj/item/storage/backpack/marine/satchel/rto/unsc = 1,
		/obj/item/device/binoculars/range/designator = 1,
		/obj/item/storage/pouch/radio = 1,
		/obj/item/device/radio = 2,
		/obj/item/device/encryptionkey/jtac = 1,
		/obj/item/storage/box/flare/signal = 1,
	)

/obj/structure/largecrate/supply/explosives/halo
	name = "HALO explosives case"
	desc = "A HALO explosives case containing breaching equipment."
	icon_state = "secure_crate_strapped"

/obj/structure/largecrate/supply/explosives/halo/breaching
	name = "HALO breaching case"
	desc = "A HALO explosives case containing plastic explosives and entry tools."
	supplies = list(
		/obj/item/explosive/plastic = 4,
		/obj/item/explosive/plastic/breaching_charge = 2,
		/obj/item/tool/shovel/etool/folded = 1,
		/obj/item/tool/crowbar = 1,
		/obj/item/clothing/glasses/welding = 1,
	)
