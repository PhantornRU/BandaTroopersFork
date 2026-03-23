/datum/rto_support_action_template/logistics_supply
	action_id = "logistics_supply"
	name = "Supply drop"
	description = "Drops a general-purpose supply crate for frontline resupply."
	scatter = 1
	shared_cooldown = 240 SECONDS
	personal_cooldown = 600 SECONDS
	category = "logistics"
	icon_state = "ammo"
	fire_support_path = /datum/fire_support/supply_drop
	requires_visibility_zone = FALSE
	altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH
	allow_closed_turf = FALSE

/datum/rto_support_action_template/logistics_mine_crate
	action_id = "logistics_mine_crate"
	name = "Mine crate drop"
	description = "Drops anti-personnel mine reserves for rapid position prep."
	scatter = 1
	shared_cooldown = 180 SECONDS
	personal_cooldown = 420 SECONDS
	category = "logistics"
	icon_state = "ammo"
	fire_support_path = /datum/fire_support/supply_drop/mine_crate
	requires_visibility_zone = FALSE
	altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH
	allow_closed_turf = FALSE

/datum/rto_support_action_template/logistics_mini_sentry
	action_id = "logistics_mini_sentry"
	name = "Mini-sentry drop"
	description = "Drops a rapid-deploy mini sentry with a limited ammunition load."
	scatter = 1
	shared_cooldown = 240 SECONDS
	personal_cooldown = 540 SECONDS
	category = "logistics"
	icon_state = "sentry"
	fire_support_path = /datum/fire_support/sentry_drop/mini
	requires_visibility_zone = FALSE
	altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH
	allow_closed_turf = FALSE

/datum/rto_support_action_template/logistics_full_sentry
	action_id = "logistics_full_sentry"
	name = "Full sentry drop"
	description = "Drops a full sentry pod with the longest logistics cooldown in the package."
	scatter = 1
	shared_cooldown = 360 SECONDS
	personal_cooldown = 780 SECONDS
	category = "logistics"
	icon_state = "sentry"
	fire_support_path = /datum/fire_support/sentry_drop/full
	requires_visibility_zone = FALSE
	altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH
	allow_closed_turf = FALSE

/datum/rto_support_action_template/logistics_grenade_drop
	action_id = "logistics_grenade_drop"
	name = "Grenade crate drop"
	description = "Drops a crate of M40 grenades for breaching and emergency defense."
	scatter = 1
	shared_cooldown = 180 SECONDS
	personal_cooldown = 420 SECONDS
	category = "logistics"
	icon_state = "ammo"
	fire_support_path = /datum/fire_support/supply_drop/grenade_crate
	requires_visibility_zone = FALSE
	altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH
	allow_closed_turf = FALSE

/datum/rto_support_action_template/logistics_sentry_ammo_drop
	action_id = "logistics_sentry_ammo_drop"
	name = "Sentry ammo drop"
	description = "Drops a sentry ammunition crate to keep deployed guns fed."
	scatter = 1
	shared_cooldown = 240 SECONDS
	personal_cooldown = 540 SECONDS
	category = "logistics"
	icon_state = "ammo"
	fire_support_path = /datum/fire_support/supply_drop/sentry_ammo
	requires_visibility_zone = FALSE
	altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH
	allow_closed_turf = FALSE
