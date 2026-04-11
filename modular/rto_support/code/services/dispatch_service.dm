/// Adapter that translates prepared requests into actual fire support execution.
/datum/rto_support_dispatch_service

/// Dispatches a prepared request through the adapter layer.
/datum/rto_support_dispatch_service/proc/dispatch_request(datum/rto_support_request/request)
	if(!request?.is_valid())
		return FALSE

	var/path_to_dispatch = request.dispatch_path
	if(!path_to_dispatch)
		path_to_dispatch = request.action_template?.fire_support_path
	if(!path_to_dispatch)
		return FALSE

	var/datum/fire_support/fire_support = new path_to_dispatch
	fire_support.enable_firesupport()
	fire_support.faction = request.owner.faction
	fire_support.scatter_range = request.scatter_override
	if(request.display_name)
		fire_support.name = request.display_name
	configure_announcement_throttle(request, fire_support)
	apply_request_flavor(request, fire_support)

	spawn_request_marker(request, fire_support)

	// The base fire support datums are singleton-oriented, so request-local instances
	// need explicit cleanup after their timers and delayed impacts are complete.
	QDEL_IN(fire_support, max(1 MINUTES, fire_support.cooldown_duration + fire_support.delay_to_impact))

	if(request.request_kind == RTO_SUPPORT_REQUEST_SUPPORT && request.announce_to_ghosts)
		notify_ghosts(
			header = "Поддержка RTO",
			message = "[format_request_owner_name(request)] вызывает [format_request_display_name(request)] по пакету [format_request_template_name(request)] в точке [request.target_turf.x],[request.target_turf.y],[request.target_turf.z].",
			source = request.target_turf,
			action = NOTIFY_JUMP
		)

	fire_support.initiate_fire_support(request.target_turf, request.owner)
	return TRUE

/datum/rto_support_dispatch_service/proc/configure_announcement_throttle(datum/rto_support_request/request, datum/fire_support/fire_support)
	if(!request || !fire_support)
		return FALSE

	fire_support.announcement_throttle_key = "rto_screen_announcement"
	fire_support.announcement_throttle_duration = 15 SECONDS
	return TRUE

/datum/rto_support_dispatch_service/proc/format_request_owner_name(datum/rto_support_request/request)
	if(!request?.owner)
		return "Неизвестный RTO"
	return request.owner.real_name || request.owner.name || "Неизвестный RTO"

/datum/rto_support_dispatch_service/proc/format_request_template_name(datum/rto_support_request/request)
	var/template_id = request?.template?.template_id
	switch(template_id)
		if("logistics")
			return "Логистика"
		if("medical")
			return "Медицина"
		if("technical")
			return "Техподдержка"
		if("mortar")
			return "Минометы"
		if("cas")
			return "Штурмовая авиация"
		if("heavy")
			return "Тяжелый удар"
		if("halo_logistics")
			return "Десантное снабжение"
		if("halo_medical")
			return "Десантная медицина"
		if("halo_technical")
			return "Десантная техподдержка"
		if("halo_command")
			return "Десантное командование"
		if("halo_engineering")
			return "Десантная инженерия"
	return request?.template?.name || "неизвестный пакет"

/datum/rto_support_dispatch_service/proc/format_request_display_name(datum/rto_support_request/request)
	var/action_id = request?.action_template?.action_id
	switch(action_id)
		if("logistics_rifle_mag_drop")
			return "ящик винтовочных магазинов"
		if("logistics_rifle_box_drop")
			return "ящик винтовочных патронных коробов"
		if("logistics_shotgun_ammo_drop")
			return "ящик дробовых патронов"
		if("logistics_smg_ammo_drop")
			return "ящик боеприпасов для M39"
		if("logistics_sidearm_ammo_drop")
			return "ящик боезапаса вторичного оружия"
		if("logistics_mine_crate")
			return "ящик мин"
		if("logistics_mini_sentry")
			return "мини-турель"
		if("logistics_full_sentry")
			return "полноразмерная турель"
		if("logistics_grenade_drop")
			return "ящик гранат"
		if("logistics_sentry_ammo_drop")
			return "ящик патронов для турели"
		if("medical_medkits_drop")
			return "ящик меднаборов"
		if("medical_blood_drop")
			return "резерв крови"
		if("medical_iv_drop")
			return "стойка с капельницами"
		if("medical_optable_drop")
			return "полевой операционный стол"
		if("technical_fortification_drop")
			return "ящик укреплений"
		if("technical_power_drop")
			return "энергетический комплект"
		if("technical_recon_drop")
			return "разведывательный комплект"
		if("technical_powerloader_drop")
			return "силовой погрузчик"
		if("halo_rifle_ammo_drop")
			return "ящик винтовочных боеприпасов"
		if("halo_marksman_ammo_drop")
			return "ящик боеприпасов марксмана"
		if("halo_pdw_ammo_drop")
			return "ящик боезапаса вторичного оружия"
		if("halo_shotgun_ammo_drop")
			return "ящик дробовых патронов"
		if("halo_sniper_ammo_drop")
			return "ящик снайперских боеприпасов"
		if("halo_spnkr_ammo_drop")
			return "ящик боеприпасов SPNKr"
		if("halo_grenadier_ammo_drop")
			return "ящик гранатометных боеприпасов"
		if("halo_medical_packets_drop")
			return "ящик медицинских пакетов"
		if("halo_corpsman_kit_drop")
			return "набор корпусмана"
		if("halo_biofoam_reserve_drop")
			return "резерв биопены"
		if("halo_toolbox_drop")
			return "инженерный комплект"
		if("halo_fortification_drop")
			return "комплект укреплений"
		if("halo_breaching_drop")
			return "набор для пролома"
		if("halo_vehicle_service_drop")
			return "комплект обслуживания техники"
		if("halo_signal_drop")
			return "сигнальный комплект"
		if("halo_recon_drop")
			return "разведывательный комплект"
		if("halo_rto_command_drop")
			return "командный комплект RTO"
		if("mortar_he")
			return "фугасная мина"
		if("mortar_smoke")
			return "дымовая мина"
		if("mortar_incendiary")
			return "зажигательная мина"
		if("cas_gun_run")
			return "пушечный заход"
		if("cas_laser_run")
			return "лазерный заход"
		if("cas_rocket_barrage")
			return "ракетный заход"
		if("heavy_missile")
			return "ракетный удар"
		if("heavy_napalm")
			return "напалмовый удар"
	return request?.display_name || request?.action_template?.name || request?.template?.name || "неизвестную поддержку"

/datum/rto_support_dispatch_service/proc/apply_request_flavor(datum/rto_support_request/request, datum/fire_support/fire_support)
	if(!request || !fire_support)
		return FALSE

	if(istype(fire_support, /datum/fire_support/supply_drop))
		return apply_supply_drop_request_flavor(request, fire_support)
	if(istype(fire_support, /datum/fire_support/sentry_drop))
		return apply_sentry_drop_request_flavor(request, fire_support)
	return apply_combat_request_flavor(request, fire_support)

/datum/rto_support_dispatch_service/proc/apply_supply_drop_request_flavor(datum/rto_support_request/request, datum/fire_support/fire_support)
	var/owner_name = format_request_owner_name(request)
	var/template_name = format_request_template_name(request)
	var/display_name = format_request_display_name(request)

	fire_support.name = "Сброс припасов: [display_name]"
	fire_support.initiate_chat_message = "[owner_name], пакет [template_name]: сброс [display_name] подтвержден. Груз уже идет к точке."
	fire_support.initiate_screen_message = list(
		"[owner_name] запрашивает [display_name] по пакету [template_name]. Контейнер уже в пути.",
		"Пакет [template_name]: подтверждаю [display_name]. Освободите площадку под груз.",
		"[display_name] для [owner_name] подтвержден. Следите за зоной падения.",
		"Запрос [owner_name] принят. [display_name] скоро коснется земли.",
		"Логистика по пакету [template_name] работает. [display_name] сбрасывается прямо сейчас.",
		"[owner_name] вызывает [display_name]. Грузовой контейнер заходит на точку.",
	)
	return TRUE

/datum/rto_support_dispatch_service/proc/apply_sentry_drop_request_flavor(datum/rto_support_request/request, datum/fire_support/fire_support)
	var/owner_name = format_request_owner_name(request)
	var/template_name = format_request_template_name(request)
	var/display_name = format_request_display_name(request)

	fire_support.name = "Сброс оборудования: [display_name]"
	fire_support.initiate_chat_message = "[owner_name], пакет [template_name]: [display_name] подтвержден. Модуль спускается на позицию."
	fire_support.initiate_screen_message = list(
		"[owner_name] запрашивает [display_name] по пакету [template_name]. Модуль уже в пути.",
		"Пакет [template_name]: выполняю [display_name]. Освободите площадку под капсулу.",
		"[display_name] для [owner_name] подтвержден. Не стойте под капсулой.",
		"Запрос [owner_name] принят. [display_name] развертывается на указанной точке.",
		"Поддержка по пакету [template_name] выполняется. [display_name] скоро коснется земли.",
		"[owner_name] вызывает [display_name]. Следите за зоной посадки.",
	)
	return TRUE

/datum/rto_support_dispatch_service/proc/apply_combat_request_flavor(datum/rto_support_request/request, datum/fire_support/fire_support)
	var/owner_name = format_request_owner_name(request)
	var/template_name = format_request_template_name(request)
	var/display_name = format_request_display_name(request)

	fire_support.name = "[template_name]: [display_name]"
	fire_support.initiate_chat_message = "[owner_name], пакет [template_name]: [display_name] подтвержден."
	fire_support.initiate_screen_message = list(
		"[owner_name] подтверждает [display_name] по пакету [template_name]. Удар уже идет.",
		"Пакет [template_name]: [display_name] принят. Работайте от обозначенной точки.",
		"[display_name] по запросу [owner_name] уже в пути.",
		"Запрос [owner_name] принят. [display_name] заходит на цель.",
	)
	return TRUE

/datum/rto_support_dispatch_service/proc/spawn_request_marker(datum/rto_support_request/request, datum/fire_support/fire_support)
	if(!request?.target_turf)
		return null

	var/marker_style = request.target_marker_style
	if(!length(marker_style))
		marker_style = request.request_kind == RTO_SUPPORT_REQUEST_VISIBILITY ? RTO_SUPPORT_MARKER_SLOW_BLINK : RTO_SUPPORT_MARKER_STATIC

	var/duration = request.target_marker_duration
	if(duration <= 0)
		duration = max(1 SECONDS, fire_support?.delay_to_impact || 1 SECONDS)

	return create_request_marker(request.target_turf, marker_style, duration)

/datum/rto_support_dispatch_service/proc/create_request_marker(turf/target_turf, marker_style = RTO_SUPPORT_MARKER_STATIC, duration = 10)
	if(!target_turf || QDELETED(target_turf))
		return null

	switch(marker_style)
		if(RTO_SUPPORT_MARKER_SLOW_BLINK)
			return new /obj/effect/overlay/rto_laser_marker/slow_blink(target_turf, duration)
		if(RTO_SUPPORT_MARKER_COORDINATE)
			return new /obj/effect/overlay/rto_laser_marker/coordinate(target_turf, duration)
		else
			return new /obj/effect/overlay/rto_laser_marker/static(target_turf, duration)
