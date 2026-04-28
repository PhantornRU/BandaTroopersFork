/atom/proc/superstrength_interaction(mob/living/carbon/human/user)
	return FALSE

/mob/living/carbon/human/proc/check_energy_shield(damage = 0, attack_text = "the attack")
	if(damage <= 0)
		return 0
	if(istype(wear_suit, /obj/item/clothing/suit/marine/shielded))
		var/obj/item/clothing/suit/marine/shielded/shield_harness = wear_suit
		var/residual_damage = shield_harness.take_damage(damage, src)
		if(residual_damage < damage)
			visible_message(SPAN_NOTICE("[src]'s energy shield shimmers from [attack_text]."), SPAN_DANGER("Your energy shield shimmers from [attack_text]!"))
		return residual_damage
	return damage

/mob/living/carbon/human/proc/armor_degrade(damage = 0)
	if(istype(wear_suit, /obj/item/clothing/suit/marine/unsc/mjolnir))
		var/obj/item/clothing/suit/marine/unsc/mjolnir/mjolnir_armor = wear_suit
		if(mjolnir_armor.armor_status > 0)
			var/armor_loss = max(damage * 0.005, 0.05)
			mjolnir_armor.armor_status = max(mjolnir_armor.armor_status - armor_loss, 0)
			mjolnir_armor.armor_check()
			return TRUE
	return FALSE
