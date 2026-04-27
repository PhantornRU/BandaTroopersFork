/datum/rto_support_action_template/medical
	shared_cooldown = 240 SECONDS
	personal_cooldown = 600 SECONDS
	support_pool_cost = 1
	personal_lockout = 6 SECONDS
	category = "medical"
	icon_state = "medic"
	requires_visibility_zone = FALSE
	altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH
	allow_closed_turf = FALSE

/datum/rto_support_action_template/medical_medkits_drop
	parent_type = /datum/rto_support_action_template/medical
	action_id = "medical_medkits_drop"
	name = "Ящик меднаборов"
	description = "Сбрасывает полевой медицинский ящик с базовыми средствами для стабилизации раненых."
	fire_support_path = /datum/fire_support/supply_drop/medical_medkits

/datum/rto_support_action_template/medical_blood_drop
	parent_type = /datum/rto_support_action_template/medical
	action_id = "medical_blood_drop"
	name = "Резерв крови"
	description = "Сбрасывает запас крови для долгой стабилизации тяжёлых раненых."
	fire_support_path = /datum/fire_support/supply_drop/medical_blood

/datum/rto_support_action_template/medical_iv_drop
	parent_type = /datum/rto_support_action_template/medical
	action_id = "medical_iv_drop"
	name = "Стойка с капельницами"
	description = "Сбрасывает стойки с капельницами для триажа и тыловых точек лечения."
	fire_support_path = /datum/fire_support/supply_drop/medical_iv

/datum/rto_support_action_template/medical_optable_drop
	parent_type = /datum/rto_support_action_template/medical
	action_id = "medical_optable_drop"
	name = "Полевой операционный стол"
	description = "Сбрасывает хирургический комплект для развёртывания импровизированной операционной."
	shared_cooldown = 360 SECONDS
	personal_cooldown = 780 SECONDS
	support_pool_cost = 2
	personal_lockout = 6 SECONDS
	fire_support_path = /datum/fire_support/supply_drop/medical_optable
