/datum/rto_support_action_template/halo/engineering
	parent_type = /datum/rto_support_action_template/halo
	shared_cooldown = 360 SECONDS
	personal_cooldown = 780 SECONDS
	support_pool_cost = 2
	personal_lockout = 8 SECONDS
	category = "engineering"
	icon_state = "build"

/datum/rto_support_action_template/halo_toolbox_drop
	parent_type = /datum/rto_support_action_template/halo/engineering
	action_id = "halo_toolbox_drop"
	name = "Инженерный комплект"
	description = "Сбрасывает инженерные инструменты, расходники и снаряжение для полевого ремонта."
	fire_support_path = /datum/fire_support/supply_drop/halo/toolbox

/datum/rto_support_action_template/halo_fortification_drop
	parent_type = /datum/rto_support_action_template/halo/engineering
	action_id = "halo_fortification_drop"
	name = "Комплект укреплений"
	description = "Сбрасывает мешки с песком, пласталь, складные баррикады и оборонительные мины."
	fire_support_path = /datum/fire_support/supply_drop/halo/fortification

/datum/rto_support_action_template/halo_breaching_drop
	parent_type = /datum/rto_support_action_template/halo/engineering
	action_id = "halo_breaching_drop"
	name = "Комплект пролома"
	description = "Сбрасывает подрывные заряды, взрывпакеты и инструмент для форсированного входа."
	fire_support_path = /datum/fire_support/supply_drop/halo/breaching

/datum/rto_support_action_template/halo_vehicle_service_drop
	parent_type = /datum/rto_support_action_template/halo/engineering
	action_id = "halo_vehicle_service_drop"
	name = "Комплект обслуживания техники"
	description = "Сбрасывает полевой ремонтный и энергетический запас для экипажей техники."
	fire_support_path = /datum/fire_support/supply_drop/halo/vehicle_service
