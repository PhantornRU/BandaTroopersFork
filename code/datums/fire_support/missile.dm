/datum/fire_support/missile
	name = "Ракетный удар"
	fire_support_firer = FIRESUPPORT_CAS
	fire_support_type = FIRESUPPORT_TYPE_MISSILE
	scatter_range = 1
	cost = 4
	icon_state = "missile"
	initiate_chat_message = "ЦЕЛЬ ПРИНЯТА. РАКЕТА В ПУТИ."
	initiate_screen_message = list(
		"Цель на лазере, одна ракета пошла.",
		"Надеюсь, цель того стоит. Отправляю одну.",
		"Один большой взрыв уже в пути.",
		"Ракета в пути, всем пригнуться.",
		)
	initiate_sound = 'sound/effects/IncomingRocket.ogg'
	start_visual = null
	start_sound = null
	impact_start_visual = /obj/effect/temp_visual/falling_obj/keeper

/datum/fire_support/missile/do_impact(turf/target_turf)
	cell_explosion(target_turf, 450, 80, EXPLOSION_FALLOFF_SHAPE_EXPONENTIAL, null, create_cause_data("LGM strike"))
	for(var/obj/vehicle/multitile/vic in target_turf)
		vic.take_damage_type(1e8, "LGM")
		vic.take_damage_type(1e8, "LGM")
		vic.healthcheck() // JUST DIE
		playsound(vic, 'sound/effects/meteorimpact.ogg', 50)
		vic.at_munition_interior_explosion_effect(1200, 400, cause_data = create_cause_data("LGM strike"))
		vic.interior_crash_effect()

/datum/fire_support/missile/upp
	faction = FACTION_UPP
	fire_support_firer = FIRESUPPORT_CAS_UPP
	fire_support_type = FIRESUPPORT_TYPE_MISSILE_UPP
	portrait_type = "pilot_red"
	initiate_title = "Pig-1"

/datum/fire_support/missile/napalm
	name = "Напалмовый удар"
	fire_support_type = FIRESUPPORT_TYPE_NAPALM_MISSILE
	cost = 3
	icon_state = "napalm_missile"
	initiate_chat_message = "ЦЕЛЬ ПРИНЯТА. НАПАЛМОВАЯ РАКЕТА В ПУТИ."
	impact_start_visual = /obj/effect/temp_visual/falling_obj/napalm

/datum/fire_support/missile/napalm/do_impact(turf/target_turf)
	cell_explosion(target_turf, 150, 20, EXPLOSION_FALLOFF_SHAPE_LINEAR, null, create_cause_data("Napalm missile"))
	fire_spread(target_turf, create_cause_data("Napalm missile"), 6, 60, 30, "#EE6515")

/datum/fire_support/missile/napalm/upp
	faction = FACTION_UPP
	fire_support_firer = FIRESUPPORT_CAS_UPP
	fire_support_type = FIRESUPPORT_TYPE_NAPALM_MISSILE_UPP
	portrait_type = "pilot_red"
	initiate_title = "Pig-1"

/datum/fire_support/missile/smoke
	name = "Дымовая ракета"
	fire_support_type = FIRESUPPORT_TYPE_SMOKE_MISSILE
	cost = 2
	icon_state = "smoke_missile"
	initiate_chat_message = "ЦЕЛЬ ПРИНЯТА. ДЫМОВАЯ РАКЕТА В ПУТИ."
	impact_start_visual = /obj/effect/temp_visual/falling_obj/banshee
	///smoke type created when the grenade is primed
	var/datum/effect_system/smoke_spread/smoketype = /datum/effect_system/smoke_spread/bad
	///radius this smoke grenade will encompass
	var/smokeradius = 12
	///The duration of the smoke
	var/smoke_duration = 40

/datum/fire_support/missile/smoke/do_impact(turf/target_turf)
	var/datum/effect_system/smoke_spread/smoke = new smoketype()
	playsound(target_turf, 'sound/effects/smoke.ogg', 25, TRUE)
	smoke.set_up(smokeradius, 0, target_turf, smoke_time = smoke_duration)
	smoke.start()

/datum/fire_support/missile/smoke/upp
	faction = FACTION_UPP
	fire_support_firer = FIRESUPPORT_CAS_UPP
	fire_support_type = FIRESUPPORT_TYPE_SMOKE_MISSILE_UPP
	portrait_type = "pilot_red"
	initiate_title = "Pig-1"

/datum/fire_support/missile/smoke/nerve
	name = "Ракета CN-20"
	fire_support_type = FIRESUPPORT_TYPE_NERVE_MISSILE_UPP
	cost = 3
	icon_state = "nerve_missile"
	initiate_screen_message = list("Газ CN-20 уже в пути!")
	smoketype = /datum/effect_system/smoke_spread/cn20
	smoke_duration = 30

/datum/fire_support/missile/smoke/nerve/upp
	faction = FACTION_UPP
	fire_support_firer = FIRESUPPORT_CAS_UPP
	fire_support_type = FIRESUPPORT_TYPE_NERVE_MISSILE_UPP
	portrait_type = "pilot_red"
	initiate_title = "Pig-1"

/datum/fire_support/missile/smoke/lsd
	name = "Ракета LSD"
	fire_support_type = FIRESUPPORT_TYPE_LSD_MISSILE_UPP
	cost = 2
	icon_state = "lsd_missile"
	initiate_screen_message = list("Заряд LSD уже в пути!")
	smoketype = /datum/effect_system/smoke_spread/LSD
	smoke_duration = 30

/datum/fire_support/missile/smoke/lsd/upp
	faction = FACTION_UPP
	fire_support_firer = FIRESUPPORT_CAS_UPP
	fire_support_type = FIRESUPPORT_TYPE_LSD_MISSILE_UPP
	portrait_type = "pilot_red"
	initiate_title = "Pig-1"
