/datum/rto_support_template/medical
	template_id = "medical"
	allowed_support_profiles = list("uscm")
	name = "Medical"
	description = "Shared 3-charge sustain package for triage, transfusion support, and emergency surgery setup."
	role_summary = "Keeps corpsmen working under pressure: common treatment drops cost 1 charge, the operating table costs 2."
	targeting_summary = "No visibility sector required: mark an open landing point with RTO binoculars and call the drop directly."
	restriction_summary = "Requires open sky and open ground. This package recovers slower than logistics and uses a longer package anti-spam lock."
	support_resource_mode = RTO_SUPPORT_RESOURCE_MODE_CHARGES
	support_pool_capacity = 3
	support_pool_starting_charges = 3
	support_pool_recharge_interval = 180 SECONDS
	support_pool_recharge_amount = 1
	support_pool_auto_recharge = TRUE
	support_package_lockout = 6 SECONDS
	requires_visibility_zone = FALSE
	visibility_zone_name = ""
	visibility_zone_type = ""
	visibility_zone_radius = 0
	visibility_zone_duration = 0
	category = "support"
	action_template_types = list(
		/datum/rto_support_action_template/medical_medkits_drop,
		/datum/rto_support_action_template/medical_blood_drop,
		/datum/rto_support_action_template/medical_iv_drop,
		/datum/rto_support_action_template/medical_optable_drop,
	)
	visibility_altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH
	visibility_action_icon_state = "designator_mortar"
	support_action_icon_state = "medic"
