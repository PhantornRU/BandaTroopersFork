/// RTO base preset override for skills and controller initialization.
/datum/equipment_preset/uscm/rto/load_gear(mob/living/carbon/human/new_human)
	. = ..()
	ensure_rto_support_controller(new_human)
	try_relocate_rto_to_squad_spawn(new_human)

/// Equipped RTO preset override with the dedicated binocular kit only.
/datum/equipment_preset/uscm/rto/equipped/load_gear(mob/living/carbon/human/new_human)
	GLOB.character_traits[/datum/character_trait/skills/spotter].apply_trait(new_human)
	add_forecon_uniform(new_human)
	add_combat_gloves(new_human)
	new_human.equip_to_slot_or_del(new /obj/item/clothing/accessory/ranks/marine/e5(new_human), WEAR_ACCESSORY)
	new_human.equip_to_slot_or_del(new /obj/item/storage/backpack/marine/satchel/rto(new_human), WEAR_BACK)
	new_human.equip_to_slot_or_del(new /obj/item/storage/pouch/firstaid/full(new_human), WEAR_R_STORE)
	new_human.equip_to_slot_or_del(new /obj/item/storage/pouch/firstaid/full/alternate(new_human), WEAR_L_STORE)
	new_human.equip_to_slot_or_del(new /obj/item/reagent_container/food/drinks/flask/marine(new_human), WEAR_IN_ACCESSORY)
	new_human.equip_to_slot_or_del(new /obj/item/storage/box/mre/fsr(new_human), WEAR_IN_ACCESSORY)
	new_human.equip_to_slot_or_del(new /obj/item/tool/crowbar/tactical(new_human), WEAR_IN_ACCESSORY)
	equip_rto_binocular_kit(new_human)
	new_human.equip_to_slot_or_del(new /obj/item/clothing/shoes/marine/knife(new_human), WEAR_FEET)
	new_human.equip_to_slot_or_del(new /obj/item/device/radio/headset/almayer/marine/solardevils/forecon(new_human), WEAR_L_EAR)
	new_human.equip_to_slot_or_del(new /obj/item/clothing/suit/marine/rto/forecon(new_human), WEAR_JACKET)
	new_human.equip_to_slot_or_del(new /obj/item/device/overwatch_camera(new_human), WEAR_R_EAR)

	spawn_random_hat(new_human)
	add_uscm_goggles(new_human)
	ensure_rto_support_controller(new_human)
	try_relocate_rto_to_squad_spawn(new_human)

/// Locker override with the dedicated RTO binocular kit only.
/obj/structure/closet/secure_closet/marine_personal/rto/spawn_gear()
	new /obj/item/clothing/under/marine(src)
	new /obj/item/clothing/shoes/marine/knife(src)
	new /obj/item/device/radio/headset/almayer/marine/solardevils(src)
	need_check_content = TRUE
	build_rto_support_binocular_kit(src)
	new /obj/item/storage/box/flare/signal(src)
	new /obj/item/storage/box/flare/signal(src)

/proc/equip_rto_binocular_kit(mob/living/carbon/human/new_human)
	if(!istype(new_human))
		return FALSE

	var/obj/item/storage/pouch/sling/rto/pouch = build_rto_support_binocular_kit(new_human)
	if(!pouch)
		return FALSE
	if(new_human.equip_to_slot_if_possible(pouch, WEAR_L_STORE, disable_warning = TRUE))
		return TRUE
	if(new_human.equip_to_slot_if_possible(pouch, WEAR_R_STORE, disable_warning = TRUE))
		return TRUE
	if(new_human.equip_to_slot_if_possible(pouch, WEAR_IN_BACK, disable_warning = TRUE))
		return TRUE
	if(new_human.put_in_any_hand_if_possible(pouch, disable_warning = TRUE))
		return TRUE
	pouch.forceMove(get_turf(new_human))
	return TRUE

/proc/try_relocate_rto_to_squad_spawn(mob/living/carbon/human/new_human)
	if(!istype(new_human) || new_human.job != JOB_SQUAD_RTO || !new_human.assigned_squad)
		return FALSE
	if(!is_mainship_level(new_human.z))
		return FALSE

	var/obj/structure/closet/secure_closet/marine_personal/rto/matching_locker
	for(var/obj/structure/closet/secure_closet/marine_personal/rto/locker in GLOB.personal_closets)
		if(!locker.linked_spawn_turf)
			continue
		if(!locker.is_correct_squad(new_human))
			continue
		matching_locker = locker
		break

	if(!matching_locker?.linked_spawn_turf)
		return FALSE
	if(get_turf(new_human) == matching_locker.linked_spawn_turf)
		return FALSE
	if(matching_locker.linked_spawn_turf.density)
		return FALSE

	for(var/atom/movable/movable as anything in matching_locker.linked_spawn_turf)
		if(movable.density)
			return FALSE

	new_human.forceMove(matching_locker.linked_spawn_turf)
	return TRUE
