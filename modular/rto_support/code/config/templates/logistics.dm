/datum/rto_support_template/logistics
	template_id = "logistics"
	allowed_support_profiles = list("uscm")
	name = "Logistics"
	description = "Frontline resupply package with a shared 3-charge reserve for rifle ammo, specialist top-offs, explosives, and field defenses."
	role_summary = "Rifle ammo carries the main mass. Specialist and utility drops stay compact so one package can keep a whole squad running."
	targeting_summary = "No visibility sector required: mark an open landing point with RTO binoculars and call the drop directly."
	restriction_summary = "Requires open sky and open ground. Charges recover slowly, so use the heavy rifle boxes and turret drops deliberately."
	support_resource_mode = RTO_SUPPORT_RESOURCE_MODE_CHARGES
	support_pool_capacity = 3
	support_pool_starting_charges = 3
	support_pool_recharge_interval = 150 SECONDS
	support_pool_recharge_amount = 1
	support_pool_auto_recharge = TRUE
	support_package_lockout = 5 SECONDS
	requires_visibility_zone = FALSE
	visibility_zone_name = ""
	visibility_zone_type = ""
	visibility_zone_radius = 0
	visibility_zone_duration = 0
	category = "support"
	action_template_types = list(
		/datum/rto_support_action_template/logistics_rifle_mag_drop,
		/datum/rto_support_action_template/logistics_rifle_box_drop,
		/datum/rto_support_action_template/logistics_shotgun_ammo_drop,
		/datum/rto_support_action_template/logistics_smg_ammo_drop,
		/datum/rto_support_action_template/logistics_sidearm_ammo_drop,
		/datum/rto_support_action_template/logistics_mine_crate,
		/datum/rto_support_action_template/logistics_mini_sentry,
		/datum/rto_support_action_template/logistics_full_sentry,
		/datum/rto_support_action_template/logistics_grenade_drop,
		/datum/rto_support_action_template/logistics_sentry_ammo_drop,
	)
	visibility_altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH
	visibility_action_icon_state = "designator_mortar"
	support_action_icon_state = "ammo"
