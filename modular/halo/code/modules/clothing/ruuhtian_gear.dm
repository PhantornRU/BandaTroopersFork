/obj/item/clothing/under/marine/covenant/ruuhtian
	name = "\improper Ruuhtian undersuit"
	desc = "A flexible undersuit made to fit Kig-Yar Ruuhtian body armor."
	icon = 'icons/halo/obj/items/clothing/covenant/under.dmi'
	icon_state = "ruuhtian_undersuit"
	item_state = "ruuhtian_undersuit"
	worn_state = "ruuhtian_undersuit"
	flags_jumpsuit = null
	drop_sound = "armorequip"
	allowed_species_list = list(SPECIES_RUUHTIAN)
	item_state_slots = list()
	item_icons = list(
		WEAR_BODY = 'icons/halo/mob/humans/onmob/clothing/ruuhtian/uniforms.dmi',
		WEAR_L_HAND = 'icons/halo/mob/humans/onmob/items_lefthand_halo.dmi',
		WEAR_R_HAND = 'icons/halo/mob/humans/onmob/items_righthand_halo.dmi'
	)

/obj/item/clothing/suit/marine/ruuhtian
	name = "Ruuhtian combat harness"
	desc = "A combat harness made to fit a Ruuhtian."
	slowdown = SLOWDOWN_ARMOR_LIGHT
	icon = 'icons/halo/obj/items/clothing/covenant/armor.dmi'
	icon_state = "ruuhtian_minor"
	item_state = "ruuhtian_minor"
	item_icons = list(
		WEAR_JACKET = 'icons/halo/mob/humans/onmob/clothing/ruuhtian/armor.dmi'
	)
	allowed_species_list = list(SPECIES_RUUHTIAN)
	flags_atom = NO_SNOW_TYPE|NO_NAME_OVERRIDE

/obj/item/clothing/suit/marine/ruuhtian/minor
	name = "Ruuhtian Minor combat harness"
	desc = "Standard issue combat harness issued to Kig-Yar warriors."

/obj/item/clothing/suit/marine/ruuhtian/major
	name = "Ruuhtian Major combat harness"
	desc = "Standard issue combat harness issued to veteran Kig-Yar warriors."
	icon_state = "ruuhtian_major"
	item_state = "ruuhtian_major"

/obj/item/clothing/suit/marine/ruuhtian/ultra
	name = "Ruuhtian Ultra combat harness"
	desc = "Reinforced combat harness issued to elite Kig-Yar warriors."
	icon_state = "ruuhtian_ultra"
	item_state = "ruuhtian_ultra"
	armor_melee = CLOTHING_ARMOR_HIGH
	armor_bullet = CLOTHING_ARMOR_HIGH
	armor_laser = CLOTHING_ARMOR_MEDIUMHIGH
	armor_bomb = CLOTHING_ARMOR_MEDIUM
	armor_bio = CLOTHING_ARMOR_MEDIUMHIGH
	armor_rad = CLOTHING_ARMOR_MEDIUM
	armor_internaldamage = CLOTHING_ARMOR_MEDIUMHIGH

/obj/item/clothing/gloves/marine/ruuhtian
	name = "\improper Ruuhtian vambrace"
	desc = "A forearm-mounted armor brace and utility mount sized for a Ruuhtian."
	icon = 'icons/halo/obj/items/clothing/covenant/gloves.dmi'
	icon_state = "ruuhtian_vambrace"
	item_state = "ruuhtian_vambrace"
	item_icons = list(
		WEAR_HANDS = 'icons/halo/mob/humans/onmob/clothing/ruuhtian/gloves.dmi'
	)
	allowed_species_list = list(SPECIES_RUUHTIAN)
	armor_melee = CLOTHING_ARMOR_MEDIUMLOW
	armor_bullet = CLOTHING_ARMOR_MEDIUMLOW
	armor_laser = CLOTHING_ARMOR_MEDIUMLOW

/obj/item/clothing/head/helmet/marine/ruuhtian
	name = "\improper Ruuhtian helmet"
	desc = "A Kig-Yar helmet with Covenant comms and visual link hardware."
	icon = 'icons/halo/obj/items/clothing/covenant/helmets.dmi'
	icon_state = "ruuhtian_minor"
	item_state = "ruuhtian_minor"
	item_icons = list(
		WEAR_HEAD = 'icons/halo/mob/humans/onmob/clothing/ruuhtian/hat.dmi'
	)
	allowed_species_list = list(SPECIES_RUUHTIAN)
	flags_marine_helmet = NO_FLAGS
	flags_inventory = NO_FLAGS
	flags_inv_hide = NO_FLAGS
	flags_atom = NO_NAME_OVERRIDE|NO_SNOW_TYPE
	built_in_visors = list()
	armor_melee = CLOTHING_ARMOR_MEDIUMLOW
	armor_bullet = CLOTHING_ARMOR_MEDIUMLOW
	armor_laser = CLOTHING_ARMOR_MEDIUMLOW

/obj/item/clothing/head/helmet/marine/ruuhtian/better
	name = "\improper Ruuhtian reinforced helmet"
	icon_state = "ruuhtian_major"
	item_state = "ruuhtian_major"
	armor_melee = CLOTHING_ARMOR_MEDIUM
	armor_bullet = CLOTHING_ARMOR_MEDIUM
	armor_laser = CLOTHING_ARMOR_MEDIUM

/obj/item/clothing/head/helmet/marine/ruuhtian/sniper
	name = "\improper Ruuhtian sniper helmet"
	icon_state = "ruuhtian_sniper"
	item_state = "ruuhtian_sniper"

/obj/item/clothing/head/helmet/marine/ruuhtian/marksman
	name = "\improper Ruuhtian marksman helmet"
	icon_state = "ruuhtian_marksman"
	item_state = "ruuhtian_marksman"

/obj/item/clothing/head/helmet/marine/ruuhtian/headset
	name = "\improper Ruuhtian command headset"
	icon_state = "ruuhtian_headset"
	item_state = "ruuhtian_headset"

/obj/item/clothing/shoes/ruuhtian
	name = "\improper Ruuhtian combat greaves"
	desc = "Light armored greaves sized for Ruuhtian legs."
	icon = 'icons/halo/obj/items/clothing/covenant/shoes.dmi'
	icon_state = "ruuhtian_minor"
	item_state = "ruuhtian_minor"
	drop_sound = "armorequip"
	item_icons = list(
		WEAR_FEET = 'icons/halo/mob/humans/onmob/clothing/ruuhtian/shoes.dmi'
	)
	allowed_species_list = list(SPECIES_RUUHTIAN)
	armor_melee = CLOTHING_ARMOR_MEDIUMLOW
	armor_bullet = CLOTHING_ARMOR_MEDIUMLOW
	armor_laser = CLOTHING_ARMOR_MEDIUMLOW

/obj/item/clothing/shoes/ruuhtian/minor
	name = "\improper Ruuhtian Minor combat greaves"
	icon_state = "ruuhtian_minor"
	item_state = "ruuhtian_minor"

/obj/item/clothing/shoes/ruuhtian/major
	name = "\improper Ruuhtian Major combat greaves"
	icon_state = "ruuhtian_major"
	item_state = "ruuhtian_major"

/obj/item/clothing/shoes/ruuhtian/ultra
	name = "\improper Ruuhtian Ultra combat greaves"
	icon_state = "ruuhtian_ultra"
	item_state = "ruuhtian_ultra"
	armor_melee = CLOTHING_ARMOR_MEDIUM
	armor_bullet = CLOTHING_ARMOR_MEDIUM
	armor_laser = CLOTHING_ARMOR_MEDIUM

/obj/item/storage/belt/marine/covenant/ruuhtian
	name = "\improper Ruuhtian combat belt"
	desc = "Modular belt for a Ruuhtian's personal weapons and field equipment."
	icon_state = "ruuhtian_minor"
	item_state = "ruuhtian_minor"
	storage_slots = 9
	item_icons = list(
		WEAR_WAIST = 'icons/halo/mob/humans/onmob/clothing/ruuhtian/belts.dmi'
	)

/obj/item/storage/belt/marine/covenant/ruuhtian/minor
	name = "\improper Ruuhtian Minor combat belt"
	icon_state = "ruuhtian_minor"
	item_state = "ruuhtian_minor"

/obj/item/storage/belt/marine/covenant/ruuhtian/major
	name = "\improper Ruuhtian Major combat belt"
	icon_state = "ruuhtian_major"
	item_state = "ruuhtian_major"

/obj/item/storage/belt/marine/covenant/ruuhtian/ultra
	name = "\improper Ruuhtian Ultra combat belt"
	icon_state = "ruuhtian_ultra"
	item_state = "ruuhtian_ultra"

/obj/item/weapon/shield/riot/covenant
	name = "Ruuhtian point defense gauntlet"
	desc = "A wrist-mounted Kig-Yar energy barrier projector."
	icon = 'icons/halo/obj/items/ruuhtian_shield.dmi'
	icon_state = "gauntlet"
	base_icon_state = "gauntlet"
	item_state = "gauntlet"
	readied_block = 150
	passive_block = 100
	item_icons = list(
		WEAR_L_HAND = 'icons/halo/mob/humans/onmob/items_lefthand_halo.dmi',
		WEAR_R_HAND = 'icons/halo/mob/humans/onmob/items_righthand_halo.dmi'
	)
