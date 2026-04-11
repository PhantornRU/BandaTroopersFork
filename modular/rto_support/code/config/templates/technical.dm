/datum/rto_support_template/technical
	template_id = "technical"
	allowed_support_profiles = list("uscm")
	name = "Техподдержка"
	description = "Пакет технической поддержки с общими 3 зарядами для укреплений, энергоснабжения, разведывательных средств и грузовых работ."
	role_summary = "Тяжёлые инженерные сбросы стоят 2 заряда. Более лёгкие разведывательные и координационные вызовы держат пакет гибким."
	targeting_summary = "Сектор не требуется: отметьте открытую точку посадки через RTO-бинокль и вызывайте груз напрямую."
	restriction_summary = "Нужны открытое небо и открытая площадка. Техподдержка пополняется медленно и дольше готовится к следующему вызову, чем снабжение."
	support_resource_mode = RTO_SUPPORT_RESOURCE_MODE_CHARGES
	support_pool_capacity = 3
	support_pool_starting_charges = 3
	support_pool_recharge_interval = 195 SECONDS
	support_pool_recharge_amount = 1
	support_pool_auto_recharge = TRUE
	support_package_lockout = 7 SECONDS
	requires_visibility_zone = FALSE
	visibility_zone_name = ""
	visibility_zone_type = ""
	visibility_zone_radius = 0
	visibility_zone_duration = 0
	category = "support"
	action_template_types = list(
		/datum/rto_support_action_template/technical_fortification_drop,
		/datum/rto_support_action_template/technical_power_drop,
		/datum/rto_support_action_template/technical_recon_drop,
		/datum/rto_support_action_template/technical_powerloader_drop,
	)
	visibility_altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH
	visibility_action_icon_state = "designator_mortar"
	support_action_icon_state = "build"
