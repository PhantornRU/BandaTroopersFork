/datum/rto_support_action_template/logistics_rifle_mag_drop
	action_id = "logistics_rifle_mag_drop"
	name = "Ящик винтовочных магазинов"
	description = "Сбрасывает основной ящик снабжения с двадцатью магазинами M41A для стрелковой линии."
	scatter = 1
	shared_cooldown = 240 SECONDS
	personal_cooldown = 600 SECONDS
	support_pool_cost = 1
	personal_lockout = 5 SECONDS
	category = "logistics"
	icon_state = "ammo"
	fire_support_path = /datum/fire_support/supply_drop/uscm/rifle
	requires_visibility_zone = FALSE
	altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH
	allow_closed_turf = FALSE

/datum/rto_support_action_template/logistics_rifle_box_drop
	action_id = "logistics_rifle_box_drop"
	name = "Ящик винтовочных коробов"
	description = "Сбрасывает четыре короба по 600 патронов M41A для длительного огня или быстрой набивки магазинов."
	scatter = 1
	shared_cooldown = 300 SECONDS
	personal_cooldown = 660 SECONDS
	support_pool_cost = 2
	personal_lockout = 5 SECONDS
	category = "logistics"
	icon_state = "ammo"
	fire_support_path = /datum/fire_support/supply_drop/uscm/rifle_box
	requires_visibility_zone = FALSE
	altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH
	allow_closed_turf = FALSE

/datum/rto_support_action_template/logistics_shotgun_ammo_drop
	action_id = "logistics_shotgun_ammo_drop"
	name = "Ящик дробовых патронов"
	description = "Сбрасывает компактный запас пулевых патронов под одного бричера, а не под всё отделение."
	scatter = 1
	shared_cooldown = 180 SECONDS
	personal_cooldown = 420 SECONDS
	support_pool_cost = 1
	personal_lockout = 5 SECONDS
	category = "logistics"
	icon_state = "ammo"
	fire_support_path = /datum/fire_support/supply_drop/uscm/shotgun/compact
	requires_visibility_zone = FALSE
	altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH
	allow_closed_turf = FALSE

/datum/rto_support_action_template/logistics_smg_ammo_drop
	action_id = "logistics_smg_ammo_drop"
	name = "Ящик боеприпасов M39"
	description = "Сбрасывает компактный запас для M39, не съедая слишком много логистического объёма."
	scatter = 1
	shared_cooldown = 180 SECONDS
	personal_cooldown = 420 SECONDS
	support_pool_cost = 1
	personal_lockout = 5 SECONDS
	category = "logistics"
	icon_state = "ammo"
	fire_support_path = /datum/fire_support/supply_drop/uscm/smg/compact
	requires_visibility_zone = FALSE
	altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH
	allow_closed_turf = FALSE

/datum/rto_support_action_template/logistics_sidearm_ammo_drop
	action_id = "logistics_sidearm_ammo_drop"
	name = "Боеприпасы вторичного оружия"
	description = "Сбрасывает умеренный запас для пистолетов и резервного оружия, не конкурируя с винтовочным снабжением."
	scatter = 1
	shared_cooldown = 180 SECONDS
	personal_cooldown = 420 SECONDS
	support_pool_cost = 1
	personal_lockout = 5 SECONDS
	category = "logistics"
	icon_state = "ammo"
	fire_support_path = /datum/fire_support/supply_drop/uscm/sidearm/compact
	requires_visibility_zone = FALSE
	altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH
	allow_closed_turf = FALSE

/datum/rto_support_action_template/logistics_mine_crate
	action_id = "logistics_mine_crate"
	name = "Ящик мин"
	description = "Сбрасывает запас противопехотных мин для быстрого укрепления позиции."
	scatter = 1
	shared_cooldown = 240 SECONDS
	personal_cooldown = 480 SECONDS
	support_pool_cost = 1
	personal_lockout = 5 SECONDS
	category = "logistics"
	icon_state = "ammo"
	fire_support_path = /datum/fire_support/supply_drop/mine_crate
	requires_visibility_zone = FALSE
	altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH
	allow_closed_turf = FALSE

/datum/rto_support_action_template/logistics_mini_sentry
	action_id = "logistics_mini_sentry"
	name = "Мини-турель"
	description = "Сбрасывает быстроразворачиваемую мини-турель с ограниченным боезапасом."
	scatter = 1
	shared_cooldown = 240 SECONDS
	personal_cooldown = 540 SECONDS
	support_pool_cost = 1
	personal_lockout = 5 SECONDS
	category = "logistics"
	icon_state = "sentry"
	fire_support_path = /datum/fire_support/sentry_drop/mini
	requires_visibility_zone = FALSE
	altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH
	allow_closed_turf = FALSE

/datum/rto_support_action_template/logistics_full_sentry
	action_id = "logistics_full_sentry"
	name = "Полноразмерная турель"
	description = "Сбрасывает полноразмерную турель. Это самый тяжёлый оборонительный вызов пакета и он тратит 2 заряда."
	scatter = 1
	shared_cooldown = 360 SECONDS
	personal_cooldown = 780 SECONDS
	support_pool_cost = 2
	personal_lockout = 5 SECONDS
	category = "logistics"
	icon_state = "sentry"
	fire_support_path = /datum/fire_support/sentry_drop/full
	requires_visibility_zone = FALSE
	altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH
	allow_closed_turf = FALSE

/datum/rto_support_action_template/logistics_grenade_drop
	action_id = "logistics_grenade_drop"
	name = "Ящик гранат"
	description = "Сбрасывает сбалансированный запас гранат для пролома, зачистки помещений и экстренной обороны."
	scatter = 1
	shared_cooldown = 210 SECONDS
	personal_cooldown = 450 SECONDS
	support_pool_cost = 1
	personal_lockout = 5 SECONDS
	category = "logistics"
	icon_state = "ammo"
	fire_support_path = /datum/fire_support/supply_drop/grenade_crate
	requires_visibility_zone = FALSE
	altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH
	allow_closed_turf = FALSE

/datum/rto_support_action_template/logistics_sentry_ammo_drop
	action_id = "logistics_sentry_ammo_drop"
	name = "Боеприпасы для турели"
	description = "Сбрасывает ящик патронов для турели, чтобы поддерживать уже развёрнутые орудия без вызова новой установки."
	scatter = 1
	shared_cooldown = 240 SECONDS
	personal_cooldown = 540 SECONDS
	support_pool_cost = 1
	personal_lockout = 5 SECONDS
	category = "logistics"
	icon_state = "ammo"
	fire_support_path = /datum/fire_support/supply_drop/sentry_ammo
	requires_visibility_zone = FALSE
	altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH
	allow_closed_turf = FALSE
