/datum/world_edit_building_archetype
	var/id = ""
	var/label = ""
	var/suggested_shell_preset = "colony"
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

/datum/world_edit_building_archetype/living_small
	id = "living_small"
	label = "Living module"
	suggested_shell_preset = "colony"
	footprint_family = "RECT"
	primary_zone = "common"
	mandatory_zones = list("entry_buffer", "common", "sleep_privacy", "storage_service")
	major_clusters = list("bed_niche", "dining_pair", "bed_niche")
	secondary_clusters = list("personal_storage", "side_table", "window_seat")
	object_budgets = list("bed" = 2, "table" = 3, "chair" = 5, "cabinet" = 3, "rack" = 2)
	window_bias = 55
	detail_bias = 65

/datum/world_edit_building_archetype/workshop_small
	id = "workshop_small"
	label = "Workshop"
	suggested_shell_preset = "uscm"
	footprint_family = "L"
	primary_zone = "main_work"
	mandatory_zones = list("entry_buffer", "main_work", "parts_storage", "service_wall")
	major_clusters = list("workbench_run", "parts_rack_run", "central_assembly_table")
	secondary_clusters = list("operator_console", "tool_storage", "parts_crate_stack", "inspection_chair")
	object_budgets = list("table" = 5, "chair" = 4, "rack" = 5, "cabinet" = 3, "console" = 1, "crate" = 3)
	window_bias = 25
	detail_bias = 75

/datum/world_edit_building_archetype/storage_small
	id = "storage_small"
	label = "Storage"
	suggested_shell_preset = "uscm"
	footprint_family = "T"
	primary_zone = "loading_axis"
	mandatory_zones = list("entry_buffer", "loading_axis", "rack_zone", "staging")
	major_clusters = list("rack_run", "storage_loading_axis", "rack_run")
	secondary_clusters = list("crate_stack", "inspection_table", "staging_crate_pair")
	object_budgets = list("rack" = 8, "cabinet" = 4, "crate" = 6, "table" = 1)
	window_bias = 15
	detail_bias = 80

/datum/world_edit_building_archetype/checkpoint_small
	id = "checkpoint_small"
	label = "Checkpoint"
	suggested_shell_preset = "uscm"
	footprint_family = "WEDGE"
	primary_zone = "secure_side"
	mandatory_zones = list("public_side", "counter_line", "secure_side", "observation")
	major_clusters = list("checkpoint_counter", "operator_console")
	secondary_clusters = list("security_storage", "visitor_chair", "barricade_line")
	object_budgets = list("table" = 3, "chair" = 3, "rack" = 2, "cabinet" = 2, "console" = 1, "barrier" = 2)
	window_bias = 20
	detail_bias = 65

/datum/world_edit_building_archetype/medbay_small
	id = "medbay_small"
	label = "Medbay"
	suggested_shell_preset = "uscm"
	footprint_family = "L"
	primary_zone = "treatment"
	mandatory_zones = list("entry_buffer", "triage", "treatment", "med_storage")
	major_clusters = list("triage_bed_cluster", "med_storage_wall", "treatment_table")
	secondary_clusters = list("waiting_chair", "triage_seating", "med_side_storage")
	object_budgets = list("medical_bed" = 3, "medical_storage" = 3, "table" = 2, "chair" = 4, "cabinet" = 2)
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

/datum/world_edit_generator/building_layout/proc/get_building_archetype_aliases()
	return list(
		"colony_living_small" = "living_small",
		"uscm_workshop_small" = "workshop_small",
		"uscm_storage_small" = "storage_small",
		"uscm_checkpoint_wedge" = "checkpoint_small",
		"storage_t" = "storage_small",
		"checkpoint_wedge" = "checkpoint_small",
	)

/datum/world_edit_generator/building_layout/proc/canonicalize_building_archetype_id(archetype_id)
	var/archetype_text = "[archetype_id]"
	var/list/aliases = get_building_archetype_aliases()
	return "[aliases[archetype_text] || archetype_text]"

/datum/world_edit_generator/building_layout/proc/get_building_archetype(archetype_id)
	var/list/catalog = get_building_archetype_catalog()
	var/datum/world_edit_building_archetype/archetype = catalog[canonicalize_building_archetype_id(archetype_id)]
	if(!istype(archetype))
		return catalog["living_small"]
	return archetype

/datum/world_edit_generator/building_layout/proc/resolve_building_archetype_option(value, fallback = "living_small")
	var/list/options = get_building_archetype_ids()
	var/canonical_value = canonicalize_building_archetype_id(value)
	if(canonical_value in options)
		return canonical_value
	var/canonical_fallback = canonicalize_building_archetype_id(fallback)
	if(canonical_fallback in options)
		return canonical_fallback
	return "living_small"

/datum/world_edit_generator/building_layout/proc/resolve_layout_variant_archetype_alias(list/params)
	var/layout_variant = "[islist(params) ? params["layout_variant"] : null]"
	var/faction_preset = "[islist(params) ? params["faction_preset"] : null]"
	switch(layout_variant)
		if("workshop")
			return "workshop_small"
		if("storage")
			return "storage_small"
		if("checkpoint")
			return "checkpoint_small"
		if("office")
			return faction_preset == "uscm" ? "checkpoint_small" : "living_small"
	return "living_small"
