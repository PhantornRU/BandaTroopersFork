/datum/rto_support_action_template/technical
	shared_cooldown = 240 SECONDS
	personal_cooldown = 600 SECONDS
	category = "technical"
	icon_state = "build"
	requires_visibility_zone = FALSE
	altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH
	allow_closed_turf = FALSE

/datum/rto_support_action_template/technical_fortification_drop
	parent_type = /datum/rto_support_action_template/technical
	action_id = "technical_fortification_drop"
	name = "Fortification drop"
	description = "Drops sheets and sandbags for quick defensive buildouts."
	shared_cooldown = 360 SECONDS
	personal_cooldown = 780 SECONDS
	fire_support_path = /datum/fire_support/supply_drop/technical_fortification

/datum/rto_support_action_template/technical_power_drop
	parent_type = /datum/rto_support_action_template/technical
	action_id = "technical_power_drop"
	name = "Power drop"
	description = "Drops generator and floodlight support for technical staging."
	shared_cooldown = 360 SECONDS
	personal_cooldown = 780 SECONDS
	fire_support_path = /datum/fire_support/supply_drop/technical_power

/datum/rto_support_action_template/technical_recon_drop
	parent_type = /datum/rto_support_action_template/technical
	action_id = "technical_recon_drop"
	name = "Recon utility drop"
	description = "Drops detectors, signal gear and map tools for coordination work."
	fire_support_path = /datum/fire_support/supply_drop/technical_recon

/datum/rto_support_action_template/technical_powerloader_drop
	parent_type = /datum/rto_support_action_template/technical
	action_id = "technical_powerloader_drop"
	name = "Powerloader drop"
	description = "Drops a work loader crate for cargo, engineering and fortification tasks."
	shared_cooldown = 360 SECONDS
	personal_cooldown = 780 SECONDS
	fire_support_path = /datum/fire_support/supply_drop/technical_powerloader
