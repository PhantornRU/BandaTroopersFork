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
	description = "UNSC-only HALO logistics package built around frontline ammunition resupply."
	role_summary = "Calls down tailored HALO ammo crates for riflemen, marksmen, breachers, heavy weapons specialists and grenadiers."
	targeting_summary = "No visibility zone required: arm a HALO support drop and designate an open landing point with RTO binoculars."
	restriction_summary = "Available only to HALO RTO roles. All HALO logistics drops require open sky and share one family cooldown."
	action_template_types = list(
		/datum/rto_support_action_template/halo_rifle_ammo_drop,
		/datum/rto_support_action_template/halo_marksman_ammo_drop,
		/datum/rto_support_action_template/halo_pdw_ammo_drop,
		/datum/rto_support_action_template/halo_shotgun_ammo_drop,
		/datum/rto_support_action_template/halo_sniper_ammo_drop,
		/datum/rto_support_action_template/halo_spnkr_ammo_drop,
		/datum/rto_support_action_template/halo_grenadier_ammo_drop,
	)
