/datum/rto_support_template/heavy
	template_id = "heavy"
	name = "Heavy Strike"
	description = "Редкие тяжёлые удары с малым разбросом и самыми длинными кулдаунами среди ударных пакетов."
	role_summary = "Редкие и дорогие тяжёлые удары по приоритетным целям."
	targeting_summary = "Сначала разверните короткий сектор, затем подтверждайте тяжёлый удар по уже разведанной точке."
	restriction_summary = "Требует открытого неба и короткого, но дорогого окна работы."
	visibility_zone_type = "Strike window"
	visibility_zone_radius = 4
	visibility_zone_duration = 350 SECONDS
	visibility_zone_cooldown = 600 SECONDS
	category = "support"
	action_template_types = list(
		/datum/rto_support_action_template/heavy_missile,
		/datum/rto_support_action_template/heavy_napalm,
	)
	visibility_altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH
