/datum/world_edit_building_archetype
	var/id = ""
	var/label = ""
	var/default_faction = "colony"
	var/footprint_family = "RECT"
	var/primary_zone = "main"
	var/entry_zone = "entry_buffer"
	var/list/mandatory_zones = list()
	var/list/major_clusters = list()
	var/list/secondary_clusters = list()
	var/list/object_budgets = list()
	var/list/shell_overrides = list()
	var/window_bias = 40
	var/detail_bias = 60

/datum/world_edit_building_archetype/proc/build_option()
	return list("label" = label, "value" = id)

/datum/world_edit_building_archetype/colony_living_small
	id = "colony_living_small"
	label = "Colony: living module"
	default_faction = "colony"
	footprint_family = "RECT"
	primary_zone = "common"
	mandatory_zones = list("entry_buffer", "common", "sleep_privacy", "storage_service")
	major_clusters = list("bed_niche", "dining_pair")
	secondary_clusters = list("personal_storage", "window_seat")
	object_budgets = list("bed" = 2, "table" = 2, "chair" = 4, "cabinet" = 3, "rack" = 2)
	window_bias = 55
	detail_bias = 65

/datum/world_edit_building_archetype/uscm_workshop_small
	id = "uscm_workshop_small"
	label = "USCM: workshop"
	default_faction = "uscm"
	footprint_family = "L"
	primary_zone = "main_work"
	mandatory_zones = list("entry_buffer", "main_work", "parts_storage", "service_wall")
	major_clusters = list("workbench_run", "parts_rack_run")
	secondary_clusters = list("operator_console", "tool_storage")
	object_budgets = list("table" = 4, "chair" = 2, "rack" = 5, "cabinet" = 3, "console" = 1, "crate" = 3)
	shell_overrides = list("floor_path" = "/turf/open/floor/almayer/uscm")
	window_bias = 25
	detail_bias = 75

/datum/world_edit_building_archetype/uscm_storage_small
	id = "uscm_storage_small"
	label = "USCM: storage"
	default_faction = "uscm"
	footprint_family = "T"
	primary_zone = "loading_axis"
	mandatory_zones = list("entry_buffer", "loading_axis", "rack_zone", "staging")
	major_clusters = list("storage_loading_axis", "rack_run")
	secondary_clusters = list("crate_stack", "inspection_table")
	object_budgets = list("rack" = 8, "cabinet" = 4, "crate" = 5, "table" = 1)
	shell_overrides = list("floor_path" = "/turf/open/floor/almayer/uscm")
	window_bias = 15
	detail_bias = 80

/datum/world_edit_building_archetype/uscm_checkpoint_wedge
	id = "uscm_checkpoint_wedge"
	label = "USCM: checkpoint"
	default_faction = "uscm"
	footprint_family = "WEDGE"
	primary_zone = "secure_side"
	mandatory_zones = list("public_side", "counter_line", "secure_side", "observation")
	major_clusters = list("checkpoint_counter", "operator_console")
	secondary_clusters = list("security_storage", "visitor_chair", "barricade_line")
	object_budgets = list("table" = 3, "chair" = 3, "rack" = 2, "cabinet" = 2, "console" = 1, "barrier" = 2)
	shell_overrides = list(
		"wall_path" = "/turf/closed/wall/almayer/reinforced",
		"floor_path" = "/turf/open/floor/almayer/uscm",
	)
	window_bias = 20
	detail_bias = 65

/datum/world_edit_building_archetype/medbay_small
	id = "medbay_small"
	label = "Medbay: small"
	default_faction = "uscm"
	footprint_family = "L"
	primary_zone = "treatment"
	mandatory_zones = list("entry_buffer", "triage", "treatment", "med_storage")
	major_clusters = list("triage_bed_cluster", "med_storage_wall")
	secondary_clusters = list("treatment_table", "waiting_chair")
	object_budgets = list("medical_bed" = 3, "medical_storage" = 3, "table" = 2, "chair" = 3, "cabinet" = 2)
	shell_overrides = list(
		"wall_path" = "/turf/closed/wall/almayer/white",
		"floor_path" = "/turf/open/floor/whiteblue",
		"door_path" = "/obj/structure/machinery/door/airlock/almayer/medical",
		"window_path" = "/obj/structure/window/framed/hybrisa/colony/hospital",
	)
	window_bias = 35
	detail_bias = 70

/datum/world_edit_generator/building_layout/proc/get_building_archetype_catalog()
	. = list()
	for(var/archetype_type in subtypesof(/datum/world_edit_building_archetype))
		var/datum/world_edit_building_archetype/archetype = new archetype_type()
		if(!length(archetype.id))
			continue
		.[archetype.id] = archetype

/datum/world_edit_generator/building_layout/proc/get_building_archetype_options()
	var/list/options = list()
	var/list/catalog = get_building_archetype_catalog()
	for(var/archetype_id in catalog)
		var/datum/world_edit_building_archetype/archetype = catalog[archetype_id]
		options += list(archetype.build_option())
	return options

/datum/world_edit_generator/building_layout/proc/get_building_archetype(archetype_id)
	var/list/catalog = get_building_archetype_catalog()
	var/datum/world_edit_building_archetype/archetype = catalog["[archetype_id]"]
	if(!istype(archetype))
		return catalog["colony_living_small"]
	return archetype

/datum/world_edit_generator/building_layout/proc/resolve_layout_variant_archetype_alias(list/params)
	var/layout_variant = "[islist(params) ? params["layout_variant"] : null]"
	var/faction_preset = "[islist(params) ? params["faction_preset"] : null]"
	switch(layout_variant)
		if("workshop")
			return "uscm_workshop_small"
		if("storage")
			return "uscm_storage_small"
		if("checkpoint")
			return "uscm_checkpoint_wedge"
		if("office")
			return faction_preset == "uscm" ? "uscm_checkpoint_wedge" : "colony_living_small"
	return "colony_living_small"
