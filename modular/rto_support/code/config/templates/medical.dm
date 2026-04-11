/datum/rto_support_template/medical
	template_id = "medical"
	allowed_support_profiles = list("uscm")
	name = "Medical"
	description = "Utility package for casualty sustain, transfusion support and emergency surgery setup."
	role_summary = "Calls down frontline medical support crates for triage and stabilization."
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
		/datum/rto_support_action_template/medical_medkits_drop,
		/datum/rto_support_action_template/medical_blood_drop,
		/datum/rto_support_action_template/medical_iv_drop,
		/datum/rto_support_action_template/medical_optable_drop,
	)
	visibility_altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH
	visibility_action_icon_state = "designator_swap_mortar"
