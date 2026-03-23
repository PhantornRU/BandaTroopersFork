/// Additional USCM support variants used by the modular RTO package.
/datum/fire_support/supply_drop/grenade_crate
	name = "Grenade crate drop"
	fire_support_type = "rto_grenade_crate_drop"
	icon_state = "ammo"
	delivered = /obj/structure/largecrate/supply/explosives/grenades/less

/datum/fire_support/supply_drop/sentry_ammo
	name = "Sentry ammo drop"
	fire_support_type = "rto_sentry_ammo_drop"
	icon_state = "ammo"
	delivered = /obj/structure/largecrate/supply/ammo/sentry

/datum/fire_support/supply_drop/medical_medkits
	name = "Medkits drop"
	fire_support_type = "rto_medkits_drop"
	icon_state = "medic"
	delivered = /obj/structure/largecrate/supply/medicine/medkits

/datum/fire_support/supply_drop/medical_blood
	name = "Blood reserve drop"
	fire_support_type = "rto_blood_drop"
	icon_state = "medic"
	delivered = /obj/structure/largecrate/supply/medicine/blood

/datum/fire_support/supply_drop/medical_iv
	name = "IV stand drop"
	fire_support_type = "rto_iv_drop"
	icon_state = "medic"
	delivered = /obj/structure/largecrate/supply/medicine/iv

/datum/fire_support/supply_drop/medical_optable
	name = "Operation table drop"
	fire_support_type = "rto_optable_drop"
	icon_state = "medic"
	delivered = /obj/structure/largecrate/supply/medicine/optable

/datum/fire_support/supply_drop/technical_fortification
	name = "Fortification drop"
	fire_support_type = "rto_technical_fortification_drop"
	icon_state = "build"
	delivered = /obj/structure/largecrate/supply/supplies/rto/technical_fortification

/datum/fire_support/supply_drop/technical_power
	name = "Power drop"
	fire_support_type = "rto_technical_power_drop"
	icon_state = "build"
	delivered = /obj/structure/largecrate/supply/supplies/rto/technical_power

/datum/fire_support/supply_drop/technical_recon
	name = "Recon utility drop"
	fire_support_type = "rto_technical_recon_drop"
	icon_state = "build"
	delivered = /obj/structure/largecrate/supply/supplies/rto/technical_recon

/datum/fire_support/supply_drop/technical_powerloader
	name = "Powerloader drop"
	fire_support_type = "rto_technical_powerloader_drop"
	icon_state = "build"
	delivered = /obj/structure/largecrate/supply/powerloader

/obj/structure/largecrate/supply/supplies/rto
	name = "RTO technical crate"
	desc = "A crate containing modular technical support supplies."
	icon_state = "chest"

/obj/structure/largecrate/supply/supplies/rto/technical_fortification
	name = "technical fortification crate"
	desc = "A crate containing metal, plasteel and sandbags for quick field defenses."
	supplies = list(
		/obj/item/stack/sheet/metal/large_stack = 2,
		/obj/item/stack/sheet/plasteel/medium_stack = 1,
		/obj/item/stack/sandbags/large_stack = 2,
	)

/obj/structure/largecrate/supply/supplies/rto/technical_power
	name = "technical power crate"
	desc = "A crate containing generator, floodlights and support consumables."
	supplies = list(
		/obj/structure/machinery/power/port_gen/pacman = 1,
		/obj/structure/machinery/floodlight = 2,
		/obj/item/stack/cable_coil/yellow = 3,
		/obj/item/stack/sheet/mineral/phoron/medium_stack = 1,
	)

/obj/structure/largecrate/supply/supplies/rto/technical_recon
	name = "technical recon crate"
	desc = "A crate containing detectors, signal gear and tactical utility tools."
	supplies = list(
		/obj/item/device/motiondetector = 2,
		/obj/item/storage/box/flare/signal = 1,
		/obj/item/map/current_map = 1,
		/obj/item/device/flashlight/combat = 1,
	)
