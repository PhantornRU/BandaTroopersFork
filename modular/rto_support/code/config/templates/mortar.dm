/datum/rto_support_template/mortar
	template_id = "mortar"
	allowed_support_profiles = list("uscm", "unsc")
	name = "Mortar"
	support_resource_mode = RTO_SUPPORT_RESOURCE_MODE_CHARGES
	support_pool_capacity = 5
	support_pool_starting_charges = 5
	support_pool_recharge_interval = 75 SECONDS
	support_pool_recharge_amount = 1
	support_pool_auto_recharge = TRUE
	description = "Частый боевой пакет с общими 5 зарядами для одиночных HE, дымовых и зажигательных мин."
	role_summary = "Давление, дым и отсечение проходов: HE и дым стоят 1 заряд, зажигательная мина стоит 2."
	targeting_summary = "Сначала разверните сектор, затем вызывайте мины внутри него. Между постановкой секторов действует только короткий антиспам в 3 секунды."
	restriction_summary = "Лучше всего работает как частая утилита по заранее выбранной зоне: пакет восстанавливает 1 заряд каждые 75 секунд и использует 3-секундный локальный lockout между вызовами."
	visibility_zone_type = "Illumination"
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
