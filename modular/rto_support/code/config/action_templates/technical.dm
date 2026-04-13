/datum/rto_support_action_template/technical
	shared_cooldown = 240 SECONDS
	personal_cooldown = 600 SECONDS
	support_pool_cost = 1
	personal_lockout = 7 SECONDS
	category = "technical"
	icon_state = "build"
	requires_visibility_zone = FALSE
	altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH
	allow_closed_turf = FALSE

/datum/rto_support_action_template/technical_fortification_drop
	parent_type = /datum/rto_support_action_template/technical
	action_id = "technical_fortification_drop"
	name = "Комплект укреплений"
	description = "Сбрасывает листы и мешки с песком для быстрого построения обороны."
	shared_cooldown = 360 SECONDS
	personal_cooldown = 780 SECONDS
	support_pool_cost = 2
	personal_lockout = 7 SECONDS
	fire_support_path = /datum/fire_support/supply_drop/technical_fortification

/datum/rto_support_action_template/technical_power_drop
	parent_type = /datum/rto_support_action_template/technical
	action_id = "technical_power_drop"
	name = "Энергетический комплект"
	description = "Сбрасывает генератор и прожекторы для инженерного развёртывания."
	shared_cooldown = 360 SECONDS
	personal_cooldown = 780 SECONDS
	support_pool_cost = 2
	personal_lockout = 7 SECONDS
	fire_support_path = /datum/fire_support/supply_drop/technical_power

/datum/rto_support_action_template/technical_recon_drop
	parent_type = /datum/rto_support_action_template/technical
	action_id = "technical_recon_drop"
	name = "Разведывательный комплект"
	description = "Сбрасывает детекторы, сигнальные средства и картографические инструменты для координации."
	fire_support_path = /datum/fire_support/supply_drop/technical_recon

/datum/rto_support_action_template/technical_powerloader_drop
	parent_type = /datum/rto_support_action_template/technical
	action_id = "technical_powerloader_drop"
	name = "Силовой погрузчик"
	description = "Сбрасывает рабочий погрузчик для грузовых, инженерных и фортификационных задач."
	shared_cooldown = 360 SECONDS
	personal_cooldown = 780 SECONDS
	support_pool_cost = 2
	personal_lockout = 7 SECONDS
	fire_support_path = /datum/fire_support/supply_drop/technical_powerloader
