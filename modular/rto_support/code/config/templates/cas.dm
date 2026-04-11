/datum/rto_support_template/cas
	template_id = "cas"
	allowed_support_profiles = list("uscm", "odst")
	name = "CAS"
	support_resource_mode = RTO_SUPPORT_RESOURCE_MODE_CHARGES
	support_pool_capacity = 3
	support_pool_starting_charges = 3
	support_pool_recharge_interval = 150 SECONDS
	support_pool_recharge_amount = 1
	support_pool_auto_recharge = TRUE
	description = "Точный авиационный пакет с общими 3 зарядами для частых заходов и одного дорогого ракетного залпа."
	role_summary = "Быстрое продавливание: gun run и laser run стоят 1 заряд, rocket barrage сжигает весь пакет за 3 заряда."
	targeting_summary = "Сначала разверните сектор, затем наводите авиаудары в его пределах. Между секторами остаётся только короткий антиспам в 3 секунды."
	restriction_summary = "Требует открытого неба. Пакет восстанавливает 1 заряд каждые 150 секунд и использует лишь 3-секундный локальный lockout между вызовами."
	visibility_zone_type = "Air corridor"
	visibility_zone_radius = 5
	visibility_zone_duration = 60 SECONDS
	visibility_zone_cooldown = 3 SECONDS
	category = "support"
	action_template_types = list(
		/datum/rto_support_action_template/cas_gun_run,
		/datum/rto_support_action_template/cas_laser_run,
		/datum/rto_support_action_template/cas_rocket_barrage,
	)
	visibility_altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH
