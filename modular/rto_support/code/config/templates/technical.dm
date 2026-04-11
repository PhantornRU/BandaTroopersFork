/datum/rto_support_template/technical
	template_id = "technical"
	allowed_support_profiles = list("uscm")
	name = "Technical"
	description = "Shared 3-charge utility package for fortification, power staging, recon tools, and cargo support."
	role_summary = "Heavy engineering drops cost 2 charges. Lighter recon and coordination drops let the package stay flexible between pushes."
	targeting_summary = "No visibility sector required: mark an open landing point with RTO binoculars and call the drop directly."
	restriction_summary = "Requires open sky and open ground. Technical support recharges slowly and uses a longer package anti-spam lock than logistics."
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
