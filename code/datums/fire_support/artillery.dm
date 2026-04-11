/datum/fire_support/mortar
	name = "Фугасный миномёт"
	fire_support_firer = FIRESUPPORT_ARTY
	fire_support_type = FIRESUPPORT_TYPE_HE_MORTAR
	cost = 2
	scatter_range = 6
	impact_quantity = 5
	cooldown_duration = 20 SECONDS
	impact_delay = 0.5 SECONDS
	visual_impact_delay = 0.3 SECONDS
	icon_state = "he_mortar"
	initiate_chat_message = "КООРДИНАТЫ ПОДТВЕРЖДЕНЫ. МИНОМЁТНЫЙ ЗАЛП В ПУТИ."
	initiate_screen_message = list(
		"Артиллерия добавляет порядка туда, где иначе была бы мясорубка.",
		"В мире есть два типа людей: артиллеристы и цели.",
		"Огонь на поражение, приём.",
		"Снаряды уже в пути!",
	)
	initiate_title = "Rhino-1"
	initiate_sound = 'sound/weapons/gun_mortar_travel.ogg'
	portrait_type = "marine_green"
	start_visual = null
	impact_start_visual = /obj/effect/temp_visual/falling_obj
	start_sound = null
	impact_sound = 'sound/weapons/fire_support/mortar_long_whistle.ogg'

/datum/fire_support/mortar/do_impact(turf/target_turf)
	cell_explosion(target_turf, 225, 60, EXPLOSION_FALLOFF_SHAPE_LINEAR, null, create_cause_data("HE mortar"))

/datum/fire_support/mortar/upp
	faction = FACTION_UPP
	fire_support_firer = FIRESUPPORT_ARTY_UPP
	fire_support_type = FIRESUPPORT_TYPE_HE_MORTAR_UPP
	initiate_title = "Katyusha-1"
	portrait_type = "beret_2_red"

/datum/fire_support/mortar/incendiary
	name = "Зажигательный миномёт"
	fire_support_type = FIRESUPPORT_TYPE_INCENDIARY_MORTAR
	icon_state = "incendiary_mortar"
	initiate_chat_message = "КООРДИНАТЫ ПОДТВЕРЖДЕНЫ. ЗАЖИГАТЕЛЬНЫЙ ЗАЛП В ПУТИ."
	initiate_screen_message = list("Координаты подтверждены, зажигательный залп уже в пути!")
	impact_start_visual = /obj/effect/temp_visual/falling_obj/incend
	var/radius = 5
	var/flame_level = BURN_TIME_TIER_5 + 5 //Type B standard, 50 base + 5 from chemfire code.
	var/burn_level = BURN_LEVEL_TIER_2
	var/flameshape = FLAMESHAPE_DEFAULT
	var/fire_type = FIRE_VARIANT_TYPE_B //Armor Shredding Greenfire

/datum/fire_support/mortar/incendiary/do_impact(turf/target_turf)
	cell_explosion(target_turf, 150, 30, EXPLOSION_FALLOFF_SHAPE_LINEAR, null, create_cause_data("Incendiary mortar"))
	flame_radius("Incendiary mortar", radius, target_turf, flame_level, burn_level, flameshape, null, fire_type)

/datum/fire_support/mortar/incendiary/upp
	faction = FACTION_UPP
	fire_support_firer = FIRESUPPORT_ARTY_UPP
	fire_support_type = FIRESUPPORT_TYPE_INCENDIARY_MORTAR_UPP
	initiate_title = "Katyusha-1"
	portrait_type = "beret_2_red"

/datum/fire_support/mortar/flare
	name = "Осветительный миномёт"
	fire_support_type = FIRESUPPORT_TYPE_FLARE_MORTAR
	cost = 1
	impact_quantity = 4
	icon_state = "flare_mortar"
	initiate_chat_message = "КООРДИНАТЫ ПОДТВЕРЖДЕНЫ. ОСВЕТИТЕЛЬНАЯ ПОДДЕРЖКА В ПУТИ."
	initiate_screen_message = "Координаты подтверждены, осветительные мины уже в пути!"
	impact_start_visual = /obj/effect/temp_visual/falling_obj/flare

/datum/fire_support/mortar/flare/do_impact(turf/target_turf)
	new /obj/item/device/flashlight/flare/on/illumination(target_turf)
	playsound(target_turf, 'sound/weapons/gun_flare.ogg', 50, 1, 4)

/datum/fire_support/mortar/flare/upp
	faction = FACTION_UPP
	fire_support_firer = FIRESUPPORT_ARTY_UPP
	fire_support_type = FIRESUPPORT_TYPE_FLARE_MORTAR_UPP
	initiate_title = "Katyusha-1"
	portrait_type = "beret_2_red"

/datum/fire_support/mortar/smoke
	name = "Дымовой миномёт"
	fire_support_type = FIRESUPPORT_TYPE_SMOKE_MORTAR
	cost = 1
	impact_quantity = 4
	icon_state = "smoke_mortar"
	initiate_chat_message = "КООРДИНАТЫ ПОДТВЕРЖДЕНЫ. ДЫМОВОЙ ЗАЛП В ПУТИ."
	initiate_screen_message = "Координаты подтверждены, дымовой залп уже в пути!"
	impact_start_visual = /obj/effect/temp_visual/falling_obj/smoke
	///smoke type created when the grenade is primed
	var/datum/effect_system/smoke_spread/smoketype = /datum/effect_system/smoke_spread/bad
	///radius this smoke grenade will encompass
	var/smokeradius = 5
	///The duration of the smoke
	var/smoke_duration = 40

/datum/fire_support/mortar/smoke/do_impact(turf/target_turf)
	var/datum/effect_system/smoke_spread/smoke = new smoketype()
	playsound(target_turf, 'sound/effects/smoke.ogg', 25, TRUE)
	smoke.set_up(smokeradius, 0, target_turf, smoke_time = smoke_duration)
	smoke.start()

/datum/fire_support/mortar/smoke/upp
	faction = FACTION_UPP
	fire_support_firer = FIRESUPPORT_ARTY_UPP
	fire_support_type = FIRESUPPORT_TYPE_SMOKE_MORTAR_UPP
	initiate_title = "Katyusha-1"
	portrait_type = "beret_2_red"

/datum/fire_support/mortar/smoke/cn
	name = "Миномёт CN-20"
	fire_support_type = FIRESUPPORT_TYPE_NERVE_SMOKE_MORTAR
	cost = 2
	icon_state = "nerve_mortar"
	initiate_chat_message = "КООРДИНАТЫ ПОДТВЕРЖДЕНЫ. ГАЗОВЫЙ ЗАЛП CN-20 В ПУТИ."
	initiate_screen_message = list("Координаты подтверждены, заряд CN-20 уже в пути!")
	smoketype = /datum/effect_system/smoke_spread/cn20
	smoke_duration = 30

/datum/fire_support/mortar/smoke/cn/upp
	faction = FACTION_UPP
	fire_support_firer = FIRESUPPORT_ARTY_UPP
	fire_support_type = FIRESUPPORT_TYPE_NERVE_SMOKE_MORTAR_UPP
	initiate_title = "Katyusha-1"
	portrait_type = "beret_2_red"

/datum/fire_support/mortar/smoke/lsd
	name = "Миномёт LSD"
	fire_support_type = FIRESUPPORT_TYPE_LSD_SMOKE_MORTAR
	cost = 1
	icon_state = "lsd_mortar"
	initiate_chat_message = "КООРДИНАТЫ ПОДТВЕРЖДЕНЫ. ГАЗОВЫЙ ЗАЛП LSD В ПУТИ."
	initiate_screen_message = list("Координаты подтверждены, заряд LSD уже в пути!")
	smoketype = /datum/effect_system/smoke_spread/LSD
	smoke_duration = 30

/datum/fire_support/mortar/smoke/lsd/upp
	faction = FACTION_UPP
	fire_support_firer = FIRESUPPORT_ARTY_UPP
	fire_support_type = FIRESUPPORT_TYPE_LSD_SMOKE_MORTAR_UPP
	initiate_title = "Katyusha-1"
	portrait_type = "beret_2_red"

/datum/fire_support/mortar/mlrs
	name = "Фугасная РСЗО"
	fire_support_type = FIRESUPPORT_TYPE_HE_MLRS
	cost = 3
	scatter_range = 11
	impact_quantity = 35
	cooldown_duration = 20 SECONDS
	impact_delay = 0.2 SECONDS
	visual_impact_delay = 1
	icon_state = "mlrs"
	initiate_chat_message = "КООРДИНАТЫ ПОДТВЕРЖДЕНЫ. ЗАЛП РСЗО В ПУТИ."
	initiate_screen_message = list(
		"По моей команде, открыть адский огонь!",
		"Огонь на поражение, приём.",
		"Полный залп уже в пути!",
		"Сейчас они запляшут под нашу музыку!",
	)
	initiate_title = "Rhino-1"
	initiate_sound = 'sound/weapons/gun_mortar_travel.ogg'
	impact_start_visual = /obj/effect/temp_visual/falling_obj/mlrs
	impact_sound = 'sound/weapons/fire_support/rocket_whistle.ogg'

/datum/fire_support/mortar/mlrs/do_impact(turf/target_turf)
	cell_explosion(target_turf, 125, 40, EXPLOSION_FALLOFF_SHAPE_LINEAR, null, create_cause_data("HE MLRS"))

/datum/fire_support/mortar/mlrs/upp
	faction = FACTION_UPP
	fire_support_firer = FIRESUPPORT_ARTY_UPP
	fire_support_type = FIRESUPPORT_TYPE_HE_MLRS_UPP
	initiate_title = "Katyusha-1"
	portrait_type = "beret_2_red"

/datum/fire_support/mortar/smoke/mlrs_cn
	name = "РСЗО CN-20"
	icon_state = "nerve_mlrs"
	fire_support_type = FIRESUPPORT_TYPE_NERVE_MLRS
	cost = 2
	scatter_range = 11
	impact_quantity = 35
	cooldown_duration = 20 SECONDS
	impact_delay = 0.2 SECONDS
	visual_impact_delay = 1
	icon_state = "mlrs"
	initiate_chat_message = "КООРДИНАТЫ ПОДТВЕРЖДЕНЫ. ЗАЛП РСЗО CN-20 В ПУТИ."
	initiate_title = "Rhino-1"
	initiate_screen_message = list(
		"По моей команде, открыть адский огонь!",
		"Огонь на поражение, приём.",
		"Полный залп уже в пути!",
		"Сейчас они запляшут под нашу музыку!",
	)
	initiate_sound = 'sound/weapons/gun_mortar_travel.ogg'
	impact_start_visual = /obj/effect/temp_visual/falling_obj/mlrs_smoke
	impact_sound = 'sound/weapons/fire_support/rocket_whistle.ogg'
	smoketype = /datum/effect_system/smoke_spread/cn20
	smoke_duration = 30
	smokeradius = 3

/datum/fire_support/mortar/smoke/mlrs_cn/upp
	faction = FACTION_UPP
	fire_support_firer = FIRESUPPORT_ARTY_UPP
	fire_support_type = FIRESUPPORT_TYPE_NERVE_MLRS_UPP
	initiate_title = "Katyusha-1"
	portrait_type = "beret_2_red"
