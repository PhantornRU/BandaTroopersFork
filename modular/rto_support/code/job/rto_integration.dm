/// RTO base preset override for skills and controller initialization.
/datum/equipment_preset/uscm/rto/load_gear(mob/living/carbon/human/new_human)
	. = ..()
	GLOB.character_traits[/datum/character_trait/skills/spotter].apply_trait(new_human)
	ensure_rto_support_controller(new_human)

/// Equipped RTO preset override with the dedicated binoculars.
/datum/equipment_preset/uscm/rto/equipped/load_gear(mob/living/carbon/human/new_human)
	. = ..()
	add_forecon_uniform(new_human)
	add_combat_gloves(new_human)
	new_human.equip_to_slot_or_del(new /obj/item/clothing/accessory/ranks/marine/e5(new_human), WEAR_ACCESSORY)
	new_human.equip_to_slot_or_del(new /obj/item/storage/backpack/marine/satchel/rto(new_human), WEAR_BACK)
	new_human.equip_to_slot_or_del(new /obj/item/storage/pouch/firstaid/full(new_human), WEAR_R_STORE)
	new_human.equip_to_slot_or_del(new /obj/item/storage/pouch/firstaid/full/alternate(new_human), WEAR_L_STORE)
	new_human.equip_to_slot_or_del(new /obj/item/reagent_container/food/drinks/flask/marine(new_human), WEAR_IN_ACCESSORY)
	new_human.equip_to_slot_or_del(new /obj/item/storage/box/mre/fsr(new_human), WEAR_IN_ACCESSORY)
	new_human.equip_to_slot_or_del(new /obj/item/tool/crowbar/tactical(new_human), WEAR_IN_ACCESSORY)
	new_human.equip_to_slot_or_del(new /obj/item/device/binoculars/rto(new_human), WEAR_IN_BACK)
	new_human.equip_to_slot_or_del(new /obj/item/clothing/shoes/marine/knife(new_human), WEAR_FEET)
	new_human.equip_to_slot_or_del(new /obj/item/device/radio/headset/almayer/marine/solardevils/forecon(new_human), WEAR_L_EAR)
	new_human.equip_to_slot_or_del(new /obj/item/clothing/suit/marine/rto/forecon(new_human), WEAR_JACKET)
	new_human.equip_to_slot_or_del(new /obj/item/device/overwatch_camera(new_human), WEAR_R_EAR)

	spawn_random_hat(new_human)
	add_uscm_goggles(new_human)
	ensure_rto_support_controller(new_human)

/// Locker override with the dedicated RTO binoculars.
/obj/structure/closet/secure_closet/marine_personal/rto/spawn_gear()
	. = ..()
	new /obj/item/device/binoculars/rto(src)
	new /obj/item/storage/box/flare/signal(src)
	new /obj/item/storage/box/flare/signal(src)
