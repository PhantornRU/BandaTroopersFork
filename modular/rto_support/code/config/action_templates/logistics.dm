/datum/rto_support_action_template/logistics_rifle_mag_drop
	action_id = "logistics_rifle_mag_drop"
	name = "Rifle magazine drop"
	description = "Drops the main squad resupply case with twenty M41A magazines for the frontline rifle line."
	scatter = 1
	shared_cooldown = 240 SECONDS
	personal_cooldown = 600 SECONDS
	support_pool_cost = 1
	personal_lockout = 5 SECONDS
	category = "logistics"
	icon_state = "ammo"
	fire_support_path = /datum/fire_support/supply_drop/uscm/rifle
	requires_visibility_zone = FALSE
	altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH
	allow_closed_turf = FALSE

/datum/rto_support_action_template/logistics_rifle_box_drop
	action_id = "logistics_rifle_box_drop"
	name = "Bulk rifle ammo drop"
	description = "Drops four 600-round M41A ammo boxes for sustained squad fire or fast magazine refills."
	scatter = 1
	shared_cooldown = 300 SECONDS
	personal_cooldown = 660 SECONDS
	support_pool_cost = 2
	personal_lockout = 5 SECONDS
	category = "logistics"
	icon_state = "ammo"
	fire_support_path = /datum/fire_support/supply_drop/uscm/rifle_box
	requires_visibility_zone = FALSE
	altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH
	allow_closed_turf = FALSE

/datum/rto_support_action_template/logistics_shotgun_ammo_drop
	action_id = "logistics_shotgun_ammo_drop"
	name = "Shotgun ammo drop"
	description = "Drops a small slug-only breacher resupply meant for one shotgun specialist instead of the full squad."
	scatter = 1
	shared_cooldown = 180 SECONDS
	personal_cooldown = 420 SECONDS
	support_pool_cost = 1
	personal_lockout = 5 SECONDS
	category = "logistics"
	icon_state = "ammo"
	fire_support_path = /datum/fire_support/supply_drop/uscm/shotgun/compact
	requires_visibility_zone = FALSE
	altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH
	allow_closed_turf = FALSE

/datum/rto_support_action_template/logistics_smg_ammo_drop
	action_id = "logistics_smg_ammo_drop"
	name = "SMG ammo drop"
	description = "Drops a compact M39 top-off for close-range specialists without overcommitting logistics mass."
	scatter = 1
	shared_cooldown = 180 SECONDS
	personal_cooldown = 420 SECONDS
	support_pool_cost = 1
	personal_lockout = 5 SECONDS
	category = "logistics"
	icon_state = "ammo"
	fire_support_path = /datum/fire_support/supply_drop/uscm/smg/compact
	requires_visibility_zone = FALSE
	altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH
	allow_closed_turf = FALSE

/datum/rto_support_action_template/logistics_sidearm_ammo_drop
	action_id = "logistics_sidearm_ammo_drop"
	name = "Secondary weapon ammo drop"
	description = "Drops a balanced reserve for sidearms and backup weapons without competing with rifle resupply volume."
	scatter = 1
	shared_cooldown = 180 SECONDS
	personal_cooldown = 420 SECONDS
	support_pool_cost = 1
	personal_lockout = 5 SECONDS
	category = "logistics"
	icon_state = "ammo"
	fire_support_path = /datum/fire_support/supply_drop/uscm/sidearm/compact
	requires_visibility_zone = FALSE
	altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH
	allow_closed_turf = FALSE

/datum/rto_support_action_template/logistics_mine_crate
	action_id = "logistics_mine_crate"
	name = "Mine crate drop"
	description = "Drops anti-personnel mine reserves for rapid position prep."
	scatter = 1
	shared_cooldown = 240 SECONDS
	personal_cooldown = 480 SECONDS
	support_pool_cost = 1
	personal_lockout = 5 SECONDS
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
	support_pool_cost = 1
	personal_lockout = 5 SECONDS
	category = "logistics"
	icon_state = "sentry"
	fire_support_path = /datum/fire_support/sentry_drop/mini
	requires_visibility_zone = FALSE
	altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH
	allow_closed_turf = FALSE

/datum/rto_support_action_template/logistics_full_sentry
	action_id = "logistics_full_sentry"
	name = "Full sentry drop"
	description = "Drops a full sentry pod. This is the heaviest defensive logistics call and spends 2 shared charges."
	scatter = 1
	shared_cooldown = 360 SECONDS
	personal_cooldown = 780 SECONDS
	support_pool_cost = 2
	personal_lockout = 5 SECONDS
	category = "logistics"
	icon_state = "sentry"
	fire_support_path = /datum/fire_support/sentry_drop/full
	requires_visibility_zone = FALSE
	altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH
	allow_closed_turf = FALSE

/datum/rto_support_action_template/logistics_grenade_drop
	action_id = "logistics_grenade_drop"
	name = "Grenade crate drop"
	description = "Drops a balanced grenade reserve for breaching, room clearing, and emergency defense."
	scatter = 1
	shared_cooldown = 210 SECONDS
	personal_cooldown = 450 SECONDS
	support_pool_cost = 1
	personal_lockout = 5 SECONDS
	category = "logistics"
	icon_state = "ammo"
	fire_support_path = /datum/fire_support/supply_drop/grenade_crate
	requires_visibility_zone = FALSE
	altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH
	allow_closed_turf = FALSE

/datum/rto_support_action_template/logistics_sentry_ammo_drop
	action_id = "logistics_sentry_ammo_drop"
	name = "Sentry ammo drop"
	description = "Drops a sentry ammunition crate to keep deployed guns firing without spending a heavier defensive call."
	scatter = 1
	shared_cooldown = 240 SECONDS
	personal_cooldown = 540 SECONDS
	support_pool_cost = 1
	personal_lockout = 5 SECONDS
	category = "logistics"
	icon_state = "ammo"
	fire_support_path = /datum/fire_support/supply_drop/sentry_ammo
	requires_visibility_zone = FALSE
	altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH
	allow_closed_turf = FALSE
