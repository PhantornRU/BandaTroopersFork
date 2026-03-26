/datum/rto_support_action_template/medical
	shared_cooldown = 240 SECONDS
	personal_cooldown = 600 SECONDS
	category = "medical"
	icon_state = "medic"
	requires_visibility_zone = FALSE
	altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH
	allow_closed_turf = FALSE

/datum/rto_support_action_template/medical_medkits_drop
	parent_type = /datum/rto_support_action_template/medical
	action_id = "medical_medkits_drop"
	name = "Medkits drop"
	description = "Drops a field first-aid crate with general trauma supplies."
	fire_support_path = /datum/fire_support/supply_drop/medical_medkits

/datum/rto_support_action_template/medical_blood_drop
	parent_type = /datum/rto_support_action_template/medical
	action_id = "medical_blood_drop"
	name = "Blood reserve drop"
	description = "Drops emergency blood bags for prolonged casualty stabilization."
	fire_support_path = /datum/fire_support/supply_drop/medical_blood

/datum/rto_support_action_template/medical_iv_drop
	parent_type = /datum/rto_support_action_template/medical
	action_id = "medical_iv_drop"
	name = "IV stand drop"
	description = "Drops IV stands for triage and rear-line treatment points."
	fire_support_path = /datum/fire_support/supply_drop/medical_iv

/datum/rto_support_action_template/medical_optable_drop
	parent_type = /datum/rto_support_action_template/medical
	action_id = "medical_optable_drop"
	name = "Operation table drop"
	description = "Drops a surgical setup for improvised field operating stations."
	shared_cooldown = 360 SECONDS
	personal_cooldown = 780 SECONDS
	fire_support_path = /datum/fire_support/supply_drop/medical_optable
