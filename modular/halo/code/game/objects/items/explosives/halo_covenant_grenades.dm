/obj/item/explosive/grenade/high_explosive/covenant
	icon = 'icons/halo/obj/items/weapons/grenades.dmi'
	icon_state = "m9"
	item_state = "m9"
	arm_sound = 'sound/weapons/grenade.ogg'
	falloff_mode = EXPLOSION_FALLOFF_SHAPE_EXPONENTIAL_HALF
	shrapnel_count = 0

/obj/item/explosive/grenade/high_explosive/covenant/plasma
	name = "Type-1 plasma grenade"
	desc = "A Covenant plasma grenade adapted for AI shock charges. It detonates in a brief, violent burst of superheated plasma."
	desc_lore = "This temporary implementation uses the available Halo grenade sprite until dedicated Covenant grenade art is ported."
	det_time = 40
	dangerous = TRUE
	explosion_power = 90
	explosion_falloff = 24
