/datum/rto_support_template/heavy
	template_id = "heavy"
	allowed_support_profiles = list("uscm", "odst")
	name = "Heavy Strike"
	support_resource_mode = RTO_SUPPORT_RESOURCE_MODE_CHARGES
	support_pool_capacity = 3
	support_pool_starting_charges = 3
	support_pool_recharge_interval = 300 SECONDS
	support_pool_recharge_amount = 1
	support_pool_auto_recharge = TRUE
	support_package_lockout = 14 SECONDS
	description = "Rare heavy package with a shared 3-charge reserve for precision missile work and a full napalm strike."
	role_summary = "Missile strike costs 1 charge. Napalm spends all 3 and now carries the longest package anti-spam lock in the RTO lineup."
	targeting_summary = "Deploy the strike sector first, then confirm the hit inside it. Sector redeploy remains short and only prevents rapid re-placing."
	restriction_summary = "Requires open sky. Heavy support recharges the slowest and is meant for decisive calls, not routine pressure."
	visibility_zone_type = "Strike window"
	visibility_zone_radius = 4
	visibility_zone_duration = 80 SECONDS
	visibility_zone_cooldown = 3 SECONDS
	category = "support"
	action_template_types = list(
		/datum/rto_support_action_template/heavy_missile,
		/datum/rto_support_action_template/heavy_napalm,
	)
	visibility_altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH
	support_action_icon_state = "missile"
