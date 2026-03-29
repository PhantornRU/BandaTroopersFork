/// Описание генератора в реестре World Edit.
/datum/world_edit_generator_definition
	var/id = ""
	var/name_ru = ""
	var/category_ru = "Общее"
	var/description_ru = ""
	var/required_rights = R_DEBUG
	var/supports_preview = TRUE
	var/execution_mode = WORLD_EDIT_EXECUTION_BATCH
	var/generator_type = /datum/world_edit_generator
	var/list/default_params = list()
	var/status = WORLD_EDIT_STATUS_DRAFT

/datum/world_edit_generator_definition/fortify_room
	id = "fortify_room"
	name_ru = "Укрепление комнаты"
	category_ru = "Комнаты"
	description_ru = "Массовая установка баррикад по границе комнаты с ограничением скана."
	required_rights = R_DEBUG
	supports_preview = TRUE
	execution_mode = WORLD_EDIT_EXECUTION_BATCH
	generator_type = /datum/world_edit_generator/fortify_room
	default_params = list(
		"fortification_level" = "Metal",
		"tile_scan_limit" = 195,
		"scan_radius" = 12,
		"respect_windows" = TRUE,
		"respect_doors" = TRUE
	)
	status = WORLD_EDIT_STATUS_DEPRECATED

/datum/world_edit_generator_definition/defense_grid
	id = "defense_grid"
	name_ru = "Сетка обороны"
	category_ru = "Оборона"
	description_ru = "Пакетная установка оборонительных объектов через каталог human_ai_defense."
	required_rights = R_DEBUG
	supports_preview = TRUE
	execution_mode = WORLD_EDIT_EXECUTION_BATCH
	generator_type = /datum/world_edit_generator/defense_grid
	default_params = list(
		"defense_path" = null,
		"faction" = FACTION_MARINE,
		"turned_on" = TRUE,
		"placement_direction" = "Default",
		"batch_count" = 1,
		"batch_step" = 1
	)
	status = WORLD_EDIT_STATUS_DEPRECATED

/datum/world_edit_generator_definition/breach_layout
	id = "breach_layout"
	name_ru = "Схема бреш-зарядов"
	category_ru = "Проломы"
	description_ru = "Click-режим для расстановки бреш-зарядов с выбором типа и направления."
	required_rights = R_DEBUG
	supports_preview = TRUE
	execution_mode = WORLD_EDIT_EXECUTION_CLICK
	generator_type = /datum/world_edit_generator/breach_layout
	default_params = list(
		"charge_type" = /obj/item/explosive/plastic,
		"direction" = NORTH,
		"allowed_profile" = "Стандартный"
	)
	status = WORLD_EDIT_STATUS_DEPRECATED

/datum/world_edit_generator_definition/barricade_builder
	id = "barricade_builder"
	name_ru = "Построитель баррикад"
	category_ru = "Баррикады"
	description_ru = "Click-генератор постановки баррикад формами point/line/rectangle с настройкой DIR."
	required_rights = R_DEBUG
	supports_preview = TRUE
	execution_mode = WORLD_EDIT_EXECUTION_CLICK
	generator_type = /datum/world_edit_generator/barricade_builder
	default_params = list(
		"barricade_path" = /datum/human_ai_defense/barricade/metal,
		"shape_mode" = "point",
		"dir_mode" = "auto",
		"fixed_dir" = NORTH,
		"replace_existing_same_dir" = FALSE,
		"max_tiles" = 40
	)
	status = WORLD_EDIT_STATUS_DEPRECATED

/datum/world_edit_generator_definition/chaos_demolition
	id = "chaos_demolition"
	name_ru = "Хаос-разрушение"
	category_ru = "Разрушение"
	description_ru = "Click-генератор перемешивания movable-объектов с опциональным взрывом и persistent fire."
	required_rights = R_DEBUG
	supports_preview = TRUE
	execution_mode = WORLD_EDIT_EXECUTION_CLICK
	generator_type = /datum/world_edit_generator/chaos_demolition
	default_params = list(
		"radius" = 3,
		"shuffle_enabled" = TRUE,
		"scatter_enabled" = FALSE,
		"scatter_steps" = 2,
		"explode_enabled" = FALSE,
		"explosion_power" = 250,
		"explosion_falloff" = 600,
		"persistent_fire_enabled" = FALSE,
		"persistent_fire_density" = 0.15,
		"max_atoms" = 120,
		"affect_anchored" = FALSE
	)
	status = WORLD_EDIT_STATUS_DEPRECATED

/datum/world_edit_generator_definition/structure_chunk
	id = "structure_chunk"
	name_ru = "Фрагмент структуры"
	category_ru = "Шаблоны"
	description_ru = "Обертка над существующей загрузкой map template с предпросмотром зоны."
	required_rights = R_EVENT
	supports_preview = TRUE
	execution_mode = WORLD_EDIT_EXECUTION_BATCH
	generator_type = /datum/world_edit_generator/structure_chunk
	default_params = list(
		"template_name" = "",
		"centered" = TRUE,
		"delete_atoms" = FALSE
	)
	status = WORLD_EDIT_STATUS_DEPRECATED

/datum/world_edit_generator_definition/outpost_radius
	id = "outpost_radius"
	name_ru = "Outpost Radius"
	category_ru = "Construction"
	description_ru = "Safe radius-based perimeter outpost builder."
	required_rights = R_EVENT
	supports_preview = TRUE
	execution_mode = WORLD_EDIT_EXECUTION_BATCH
	generator_type = /datum/world_edit_generator/outpost_radius
	default_params = list(
		"radius" = 4,
		"barricade_path" = /datum/human_ai_defense/barricade/metal,
		"place_sentries" = FALSE,
		"sentry_path" = /datum/human_ai_defense/defense/sentry/uscm,
		"faction" = FACTION_MARINE,
		"turned_on" = TRUE
	)
	status = WORLD_EDIT_STATUS_READY

/datum/world_edit_generator_definition/destruction_pack
	id = "destruction_pack"
	name_ru = "Destruction Pack"
	category_ru = "Destruction"
	description_ru = "Limited radius-based shuffle/scatter pack for movable atoms."
	required_rights = R_DEBUG
	supports_preview = TRUE
	execution_mode = WORLD_EDIT_EXECUTION_BATCH
	generator_type = /datum/world_edit_generator/destruction_pack
	default_params = list(
		"radius" = 3,
		"shuffle_enabled" = TRUE,
		"scatter_enabled" = FALSE,
		"scatter_steps" = 2,
		"max_atoms" = 60,
		"affect_anchored" = FALSE
	)
	status = WORLD_EDIT_STATUS_READY

/datum/world_edit_generator_definition/blueprint_stamp
	id = "blueprint_stamp"
	name_ru = "Blueprint Stamp"
	category_ru = "Blueprints"
	description_ru = "Safe structure stamping from the World Edit Blueprint Lite library."
	required_rights = R_EVENT
	supports_preview = TRUE
	execution_mode = WORLD_EDIT_EXECUTION_BATCH
	generator_type = /datum/world_edit_generator/blueprint_stamp
	default_params = list(
		"blueprint_id" = "",
	)
	status = WORLD_EDIT_STATUS_READY

GLOBAL_LIST_INIT(world_edit_generator_definitions_by_id, world_edit_build_generator_definition_index())

/proc/world_edit_build_generator_definition_index()
	. = list()
	for(var/definition_type in subtypesof(/datum/world_edit_generator_definition))
		var/datum/world_edit_generator_definition/definition = new definition_type()

		if(!definition.id)
			CRASH("World Edit: генератор [definition_type] не содержит id.")
		if(!definition.name_ru)
			CRASH("World Edit: генератор [definition.id] не содержит name_ru.")
		if(!ispath(definition.generator_type, /datum/world_edit_generator))
			CRASH("World Edit: генератор [definition.id] содержит неверный generator_type ([definition.generator_type]).")
		if(.[definition.id])
			CRASH("World Edit: найден дублирующийся id генератора ([definition.id]).")

		.[definition.id] = definition

/proc/world_edit_get_generator_definition(id)
	if(!id)
		return null
	return GLOB.world_edit_generator_definitions_by_id[id]
