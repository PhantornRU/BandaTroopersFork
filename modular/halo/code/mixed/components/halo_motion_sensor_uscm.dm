/mob/living/carbon/human/proc/halo_add_uscm_motion_sensor()
	for(var/slot in list(WEAR_HEAD, WEAR_EYES, WEAR_JACKET, WEAR_BACK, WEAR_R_EAR, WEAR_L_EAR))
		var/obj/item/worn_item = get_item_by_slot(slot)
		if(!worn_item || QDELETED(worn_item))
			continue
		worn_item.AddComponent(/datum/component/halo_motion_sensor_manager, FACTION_MARINE)
		return TRUE
	return FALSE

/datum/equipment_preset/uscm/smartgunner_equipped/load_gear(mob/living/carbon/human/new_human)
	. = ..()
	new_human.halo_add_uscm_motion_sensor()

/datum/equipment_preset/uscm/tl_equipped/load_gear(mob/living/carbon/human/new_human)
	. = ..()
	new_human.halo_add_uscm_motion_sensor()

/datum/equipment_preset/uscm/leader_equipped/load_gear(mob/living/carbon/human/new_human)
	. = ..()
	new_human.halo_add_uscm_motion_sensor()

/datum/equipment_preset/uscm_ship/so_equipped/load_gear(mob/living/carbon/human/new_human)
	. = ..()
	new_human.halo_add_uscm_motion_sensor()
