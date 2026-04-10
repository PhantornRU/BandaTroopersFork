/datum/rto_support_template/heavy
	template_id = "heavy"
	allowed_support_profiles = list("uscm", "odst")
	name = "Heavy Strike"
	support_resource_mode = RTO_SUPPORT_RESOURCE_MODE_CHARGES
	support_pool_capacity = 3
	support_pool_starting_charges = 3
	support_pool_recharge_interval = 240 SECONDS
	support_pool_recharge_amount = 1
	support_pool_auto_recharge = TRUE
	description = "Редкий тяжёлый пакет с малым разбросом, длинным окном удара и умеренно долгими интервалами между вызовами."
	role_summary = "Редкие и дорогие тяжёлые удары по приоритетным целям."
	targeting_summary = "Сначала разверните длинное окно сектора, затем подтверждайте тяжёлый удар по уже разведанной точке."
	restriction_summary = "Требует открытого неба и длинного, но дорогого окна работы с интервалами в среднем 10-20 секунд между ударами."
	visibility_zone_type = "Strike window"
	visibility_zone_radius = 4
	visibility_zone_duration = 80 SECONDS
	visibility_zone_cooldown = 1600 SECONDS
	category = "support"
	action_template_types = list(
		/datum/rto_support_action_template/heavy_missile,
		/datum/rto_support_action_template/heavy_napalm,
	)
	visibility_altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH
