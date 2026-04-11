/datum/rto_support_template/halo
	allowed_support_profiles = list("halo", "unsc", "odst")
	requires_visibility_zone = FALSE
	visibility_zone_name = ""
	visibility_zone_type = ""
	visibility_zone_radius = 0
	visibility_zone_duration = 0
	category = "support"
	visibility_altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH
	visibility_action_icon_state = "designator_mortar"

/datum/rto_support_template/halo_logistics
	parent_type = /datum/rto_support_template/halo
	template_id = "halo_logistics"
	name = "UNSC Logistics"
	support_resource_mode = RTO_SUPPORT_RESOURCE_MODE_CHARGES
	support_pool_capacity = 3
	support_pool_starting_charges = 3
	support_pool_recharge_interval = 165 SECONDS
	support_pool_recharge_amount = 1
	support_pool_auto_recharge = TRUE
	support_package_lockout = 6 SECONDS
	description = "UNSC logistics package with a shared 3-charge reserve for rifle ammo, specialist top-offs, and grenade support."
	role_summary = "Rifle resupply carries the bulk. Specialist crates stay lighter so the package can sustain a whole fireteam instead of one niche loadout."
	targeting_summary = "No visibility sector required: mark an open landing point with RTO binoculars and call the drop directly."
	restriction_summary = "Available to UNSC and ODST RTO roles. Every drop needs open sky and the package recovers slower than USCM logistics."
	action_template_types = list(
		/datum/rto_support_action_template/halo_rifle_ammo_drop,
		/datum/rto_support_action_template/halo_marksman_ammo_drop,
		/datum/rto_support_action_template/halo_pdw_ammo_drop,
		/datum/rto_support_action_template/halo_shotgun_ammo_drop,
		/datum/rto_support_action_template/halo_sniper_ammo_drop,
		/datum/rto_support_action_template/halo_spnkr_ammo_drop,
		/datum/rto_support_action_template/halo_grenadier_ammo_drop,
	)
	support_action_icon_state = "ammo"
