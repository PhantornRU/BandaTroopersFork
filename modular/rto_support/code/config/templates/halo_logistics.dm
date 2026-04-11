/datum/rto_support_template/halo
	allowed_support_profiles = list("halo", "unsc", "odst")
	requires_visibility_zone = FALSE
	visibility_zone_name = ""
	visibility_zone_type = ""
	visibility_zone_radius = 0
	visibility_zone_duration = 0
	visibility_zone_cooldown = 0
	category = "support"
	visibility_altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH
	visibility_action_icon_state = "designator_swap_mortar"

/datum/rto_support_template/halo_logistics
	parent_type = /datum/rto_support_template/halo
	template_id = "halo_logistics"
	name = "HALO Logistics"
	support_resource_mode = RTO_SUPPORT_RESOURCE_MODE_CHARGES
	support_pool_capacity = 3
	support_pool_starting_charges = 3
	support_pool_recharge_interval = 120 SECONDS
	support_pool_recharge_amount = 1
	support_pool_auto_recharge = TRUE
	description = "UNSC-only HALO logistics package with a shared 3-charge ammo reserve for frontline resupply."
	role_summary = "Calls down tailored HALO ammo crates for riflemen, marksmen, breachers, heavy weapons specialists and grenadiers at 1 charge each."
	targeting_summary = "No visibility zone required: arm a HALO support drop, designate an open landing point with RTO binoculars, and recover one charge every 120 seconds."
	restriction_summary = "Available only to HALO RTO roles. All HALO logistics drops require open sky and use only a 3-second local anti-spam lockout."
	action_template_types = list(
		/datum/rto_support_action_template/halo_rifle_ammo_drop,
		/datum/rto_support_action_template/halo_marksman_ammo_drop,
		/datum/rto_support_action_template/halo_pdw_ammo_drop,
		/datum/rto_support_action_template/halo_shotgun_ammo_drop,
		/datum/rto_support_action_template/halo_sniper_ammo_drop,
		/datum/rto_support_action_template/halo_spnkr_ammo_drop,
		/datum/rto_support_action_template/halo_grenadier_ammo_drop,
	)
