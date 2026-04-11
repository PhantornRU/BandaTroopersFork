/datum/rto_support_action_template/mortar_he
	action_id = "mortar_he"
	name = "HE mortar"
	description = "Reliable single HE round for pressure on a precise point."
	scatter = 4
	shared_cooldown = 4 SECONDS
	personal_cooldown = 8 SECONDS
	support_pool_cost = 1
	personal_lockout = 6 SECONDS
	category = "mortar"
	icon_state = "he_mortar"
	fire_support_path = /datum/fire_support/mortar/rto_single

/datum/rto_support_action_template/mortar_smoke
	action_id = "mortar_smoke"
	name = "Smoke mortar"
	description = "Fast single smoke round for screening pushes, retreats, and revives."
	scatter = 3
	shared_cooldown = 3 SECONDS
	personal_cooldown = 5 SECONDS
	support_pool_cost = 1
	personal_lockout = 6 SECONDS
	category = "mortar"
	icon_state = "smoke_mortar"
	fire_support_path = /datum/fire_support/mortar/smoke/rto_single

/datum/rto_support_action_template/mortar_incendiary
	action_id = "mortar_incendiary"
	name = "Incendiary mortar"
	description = "Single incendiary round for denial of narrow lanes and stubborn holds."
	scatter = 4
	shared_cooldown = 6 SECONDS
	personal_cooldown = 10 SECONDS
	support_pool_cost = 2
	personal_lockout = 6 SECONDS
	category = "mortar"
	icon_state = "incendiary_mortar"
	fire_support_path = /datum/fire_support/mortar/incendiary/rto_single
