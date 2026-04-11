/datum/rto_support_template/cas
	template_id = "cas"
	allowed_support_profiles = list("uscm", "odst")
	name = "CAS"
	support_resource_mode = RTO_SUPPORT_RESOURCE_MODE_CHARGES
	support_pool_capacity = 3
	support_pool_starting_charges = 3
	support_pool_recharge_interval = 240 SECONDS
	support_pool_recharge_amount = 1
	support_pool_auto_recharge = TRUE
	support_package_lockout = 10 SECONDS
	description = "Precision air package with a shared 3-charge reserve for repeated strike runs and one expensive rocket pass."
	role_summary = "Gun and laser runs cost 1 charge. The rocket run spends the entire package and should be reserved for high-value moments."
	targeting_summary = "Deploy the sector first, then guide air strikes through it. Sector redeploy remains only a short anti-spam step."
	restriction_summary = "Requires open sky. Recovery is much slower than mortar, and every strike now pauses the whole package before the next call."
	visibility_zone_type = "Air corridor"
	visibility_zone_radius = 5
	visibility_zone_duration = 60 SECONDS
	visibility_zone_cooldown = 3 SECONDS
	category = "support"
	action_template_types = list(
		/datum/rto_support_action_template/cas_gun_run,
		/datum/rto_support_action_template/cas_laser_run,
		/datum/rto_support_action_template/cas_rocket_barrage,
	)
	visibility_altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH
	support_action_icon_state = "gau"
