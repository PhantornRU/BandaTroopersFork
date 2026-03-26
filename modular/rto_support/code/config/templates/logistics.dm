/datum/rto_support_template/logistics
	template_id = "logistics"
	allowed_support_profiles = list("uscm")
	name = "Logistics"
	description = "Utility package for direct resupply, explosives and deployable defenses without a visibility sector."
	role_summary = "Sustains the line with crates, sentries and emergency ammunition."
	targeting_summary = "No visibility zone required: arm the drop and designate an open landing point with RTO binoculars."
	restriction_summary = "All drops require open sky and an open target tile."
	requires_visibility_zone = FALSE
	visibility_zone_name = ""
	visibility_zone_type = ""
	visibility_zone_radius = 0
	visibility_zone_duration = 0
	visibility_zone_cooldown = 0
	category = "support"
	action_template_types = list(
		/datum/rto_support_action_template/logistics_supply,
		/datum/rto_support_action_template/logistics_mine_crate,
		/datum/rto_support_action_template/logistics_mini_sentry,
		/datum/rto_support_action_template/logistics_full_sentry,
		/datum/rto_support_action_template/logistics_grenade_drop,
		/datum/rto_support_action_template/logistics_sentry_ammo_drop,
	)
	visibility_altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH
	visibility_action_icon_state = "designator_swap_mortar"
