/datum/rto_support_template/logistics
	template_id = "logistics"
	allowed_support_profiles = list("uscm")
	name = "Снабжение"
	description = "Пакет снабжения с общими 3 зарядами для винтовочных патронов, нишевых боеприпасов, гранат и полевой обороны."
	role_summary = "Основная масса уходит в винтовочные патроны. Нишевые и утилитарные сбросы сделаны компактнее, чтобы одного пакета хватало на отделение."
	targeting_summary = "Сектор не требуется: отметьте открытую точку посадки через RTO-бинокль и вызывайте груз напрямую."
	restriction_summary = "Нужны открытое небо и открытая площадка. Заряды возвращаются медленно, поэтому ящики коробов и турели лучше тратить осознанно."
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
