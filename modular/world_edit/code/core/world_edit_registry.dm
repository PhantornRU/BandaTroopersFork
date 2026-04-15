/// Generator definitions exposed by the active World Edit runtime surface.
/datum/world_edit_generator_definition
	var/id = ""
	var/name_ru = ""
	var/category_ru = "General"
	var/description_ru = ""
	var/required_rights = R_DEBUG
	var/supports_preview = TRUE
	var/execution_mode = WORLD_EDIT_EXECUTION_BATCH
	var/generator_type = /datum/world_edit_generator
	var/list/default_params = list()
	var/status = WORLD_EDIT_STATUS_DRAFT

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
		"family" = "metal_perimeter",
		"layout_variant" = "crossroads",
		"opening_width" = "profile",
		"radius" = 4,
		"barricade_path" = /datum/human_ai_defense/barricade/metal,
		"barricade_pattern" = "profile",
		"place_sentries" = FALSE,
		"guard_mode" = "layout",
		"sentry_path" = /datum/human_ai_defense/defense/sentry/uscm,
		"faction" = FACTION_MARINE,
		"turned_on" = TRUE
	)
	status = WORLD_EDIT_STATUS_READY

/datum/world_edit_generator_definition/destruction_pack
	id = "destruction_pack"
	name_ru = "Destruction Pack"
	category_ru = "Destruction"
	description_ru = "Limited radius-based shuffle/scatter/fire/blast/ruin/collapse pack for movable atoms."
	required_rights = R_DEBUG
	supports_preview = TRUE
	execution_mode = WORLD_EDIT_EXECUTION_BATCH
	generator_type = /datum/world_edit_generator/destruction_pack
	default_params = list(
		"radius" = 3,
		"shuffle_enabled" = TRUE,
		"scatter_enabled" = FALSE,
		"scatter_steps" = 2,
		"persistent_fire_enabled" = FALSE,
		"persistent_fire_density" = 10,
		"blast_enabled" = FALSE,
		"blast_power" = 250,
		"blast_falloff" = 600,
		"damage_profile" = "none",
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

GLOBAL_DATUM_INIT(world_edit_registry, /datum/world_edit_registry_service, new)

/datum/world_edit_registry_service
	var/list/definitions_by_id = list()

/datum/world_edit_registry_service/New()
	. = ..()
	definitions_by_id = build_generator_definition_index()

/datum/world_edit_registry_service/proc/build_generator_definition_index()
	. = list()
	for(var/definition_type in subtypesof(/datum/world_edit_generator_definition))
		var/datum/world_edit_generator_definition/definition = new definition_type()

		if(!definition.id)
			CRASH("World Edit: generator [definition_type] is missing id.")
		if(!definition.name_ru)
			CRASH("World Edit: generator [definition.id] is missing name_ru.")
		if(!ispath(definition.generator_type, /datum/world_edit_generator))
			CRASH("World Edit: generator [definition.id] has an invalid generator_type ([definition.generator_type]).")
		if(.[definition.id])
			CRASH("World Edit: duplicate generator id detected ([definition.id]).")

		.[definition.id] = definition

/datum/world_edit_registry_service/proc/get_generator_definition(id)
	if(!id)
		return null
	return definitions_by_id[id]
