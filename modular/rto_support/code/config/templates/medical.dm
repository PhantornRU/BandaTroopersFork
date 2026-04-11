/datum/rto_support_template/medical
	template_id = "medical"
	allowed_support_profiles = list("uscm")
	name = "Медицина"
	description = "Пакет медицинской поддержки с общими 3 зарядами для триажа, переливания и развёртывания экстренной хирургии."
	role_summary = "Держит медиков в строю под давлением: стандартные медицинские сбросы стоят 1 заряд, операционный стол стоит 2."
	targeting_summary = "Сектор не требуется: отметьте открытую точку посадки через RTO-бинокль и вызывайте груз напрямую."
	restriction_summary = "Нужны открытое небо и открытая площадка. Пакет восстанавливается медленнее снабжения и имеет более длинную паузу между вызовами."
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
