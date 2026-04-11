/datum/rto_support_template/mortar
	template_id = "mortar"
	allowed_support_profiles = list("uscm", "unsc")
	name = "Минометы"
	support_resource_mode = RTO_SUPPORT_RESOURCE_MODE_CHARGES
	support_pool_capacity = 5
	support_pool_starting_charges = 5
	support_pool_recharge_interval = 105 SECONDS
	support_pool_recharge_amount = 1
	support_pool_auto_recharge = TRUE
	support_package_lockout = 6 SECONDS
	description = "Частый огневой пакет с общими 5 зарядами для фугасных, дымовых и зажигательных мин."
	role_summary = "Фугас и дым стоят 1 заряд. Зажигательная мина стоит 2 и лучше подходит для перекрытия зон, а не для постоянного давления."
	targeting_summary = "Сначала разверните сектор, затем работайте минами внутри него. Повторная постановка сектора остаётся короткой."
	restriction_summary = "Лучше всего работает как постоянное давление из заранее подготовленного сектора. Заряды возвращаются медленно, поэтому темп приходится обменивать на выносливость."
	visibility_zone_type = "Подсветка"
	visibility_zone_radius = 7
	visibility_zone_duration = 30 SECONDS
	visibility_zone_cooldown = 3 SECONDS
	category = "support"
	action_template_types = list(
		/datum/rto_support_action_template/mortar_he,
		/datum/rto_support_action_template/mortar_smoke,
		/datum/rto_support_action_template/mortar_incendiary,
	)
	visibility_support_path = /datum/fire_support/rto_visibility/illumination
	visibility_altitude_requirement = RTO_SUPPORT_ALTITUDE_ANY
	support_action_icon_state = "he_mortar"
