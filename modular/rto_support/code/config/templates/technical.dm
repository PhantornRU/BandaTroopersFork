/datum/rto_support_template/technical
	template_id = "technical"
	allowed_support_profiles = list("uscm")
	name = "Technical"
	description = "Utility package for fortification, power staging, recon tools and cargo-handling support."
	role_summary = "Combines engineer and command-adjacent support into one technical package."
	targeting_summary = "No visibility zone required: designate an open landing point with RTO binoculars."
	restriction_summary = "All drops require open sky and open ground."
	support_resource_mode = RTO_SUPPORT_RESOURCE_MODE_CHARGES
	support_pool_capacity = 3
	support_pool_starting_charges = 3
	support_pool_recharge_interval = 120 SECONDS
	support_pool_recharge_amount = 1
	support_pool_auto_recharge = TRUE
	requires_visibility_zone = FALSE
	visibility_zone_name = ""
	visibility_zone_type = ""
	visibility_zone_radius = 0
	visibility_zone_duration = 0
	visibility_zone_cooldown = 0
	category = "support"
	action_template_types = list(
		/datum/rto_support_action_template/technical_fortification_drop,
		/datum/rto_support_action_template/technical_power_drop,
		/datum/rto_support_action_template/technical_recon_drop,
		/datum/rto_support_action_template/technical_powerloader_drop,
	)
	visibility_altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH
	visibility_action_icon_state = "designator_swap_mortar"
