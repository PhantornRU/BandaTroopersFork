/datum/rto_support_action_template/cas_gun_run
	action_id = "cas_gun_run"
	name = "Пушечный заход"
	description = "Быстрый пушечный проход вдоль узкого коридора."
	scatter = 3
	shared_cooldown = 12 SECONDS
	personal_cooldown = 16 SECONDS
	support_pool_cost = 1
	personal_lockout = 10 SECONDS
	category = "cas"
	icon_state = "gau"
	fire_support_path = /datum/fire_support/gau
	altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH

/datum/rto_support_action_template/cas_laser_run
	action_id = "cas_laser_run"
	name = "Лазерный заход"
	description = "Более точный и выверенный ударный заход с меньшим разбросом."
	scatter = 2
	shared_cooldown = 16 SECONDS
	personal_cooldown = 22 SECONDS
	support_pool_cost = 1
	personal_lockout = 10 SECONDS
	category = "cas"
	icon_state = "laser"
	fire_support_path = /datum/fire_support/laser
	altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH

/datum/rto_support_action_template/cas_rocket_barrage
	action_id = "cas_rocket_barrage"
	name = "Ракетный заход"
	description = "Тяжёлый ракетный проход с самым широким покрытием в пакете."
	scatter = 4
	shared_cooldown = 22 SECONDS
	personal_cooldown = 36 SECONDS
	support_pool_cost = 3
	personal_lockout = 10 SECONDS
	category = "cas"
	icon_state = "rockets"
	fire_support_path = /datum/fire_support/rockets
	altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH
