/datum/rto_support_action_template/cas_gun_run
	action_id = "cas_gun_run"
	name = "Gun run"
	description = "Fast cannon pass along a narrow lane."
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
	name = "Laser run"
	description = "Tighter, more deliberate strike pass with lower scatter."
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
	name = "Rocket barrage"
	description = "Heavy rocket pass with the widest footprint in the package."
	scatter = 4
	shared_cooldown = 22 SECONDS
	personal_cooldown = 36 SECONDS
	support_pool_cost = 3
	personal_lockout = 10 SECONDS
	category = "cas"
	icon_state = "rockets"
	fire_support_path = /datum/fire_support/rockets
	altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH
