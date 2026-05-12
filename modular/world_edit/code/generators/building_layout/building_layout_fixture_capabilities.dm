/datum/world_edit_building_fixture_provider
	var/id = ""
	var/slot = ""
	var/obj_path = null
	var/source = ""
	var/list/provides_slots = list()
	var/list/provides_categories = list()
	var/functional = TRUE
	var/decorative_only = FALSE
	var/reason_if_not_functional = ""

/datum/world_edit_building_fixture_provider/proc/provides_required_slot(required_slot)
	if(!functional || decorative_only)
		return FALSE
	return "[required_slot]" in provides_slots

/datum/world_edit_generator/building_layout/proc/build_building_fixture_path_report(list/config, slot)
	var/list/interior_paths = islist(config) ? config["interior_paths"] : null
	var/slot_key = "[slot]"
	var/path_value = islist(interior_paths) ? interior_paths[slot_key] : null
	var/source = "direct"
	if(isnull(path_value))
		source = "fallback"
		switch(slot_key)
			if("medical_bed")
				path_value = interior_paths?["bed"]
			if("medical_storage", "crate")
				path_value = interior_paths?["cabinet"]
			if("hydro_tray", "sleeper", "medical_scanner", "wall_monitor", "fridge", "microwave", "processor", "sink", "toilet", "security_console", "security_camera", "brig_cell", "weapon_rack", "water_tank", "seed_storage", "engineering_machine", "power_console", "lab_machine")
				path_value = interior_paths?["table"]
			if("fridge", "filing", "sample_storage")
				path_value = interior_paths?["cabinet"]
			if("wall_monitor", "security_console", "console", "power_console")
				path_value = interior_paths?["table"]
			if("light", "apc", "air_alarm", "fire_alarm", "light_switch")
				path_value = interior_paths?[slot_key] || interior_paths?["console"] || interior_paths?["table"]
			else
				path_value = interior_paths?["table"]
	var/resolved_path = resolve_building_type_path(path_value, /obj)
	return list(
		"path" = resolved_path,
		"source" = source,
		"raw_path" = path_value,
	)

/datum/world_edit_generator/building_layout/proc/build_legacy_fixture_provider(slot, obj_path, source = "direct")
	if(!obj_path)
		return null
	var/slot_key = "[slot]"
	var/datum/world_edit_building_fixture_provider/provider = new
	provider.id = "legacy:[slot_key]:[obj_path]"
	provider.slot = slot_key
	provider.obj_path = obj_path
	provider.source = "[source]"
	provider.provides_slots = list(slot_key)
	provider.functional = TRUE
	if("[source]" == "fallback")
		provider.functional = FALSE
		provider.decorative_only = TRUE
		provider.provides_slots = list()
		provider.reason_if_not_functional = "slot '[slot_key]' resolves through a generic fallback instead of a functional provider"
	if("[obj_path]" in list(
		"/obj/structure/covenant_barricade",
		"/obj/structure/covenant_barricade/wide",
		"/obj/structure/machinery/recharger/covenant"
	))
		provider.functional = FALSE
		provider.decorative_only = TRUE
		provider.provides_slots = list()
		provider.reason_if_not_functional = "path '[obj_path]' is a decorative placeholder and does not provide required slot '[slot_key]'"
	return provider

/datum/world_edit_generator/building_layout/proc/resolve_fixture_provider(list/config, slot)
	var/list/path_report = build_building_fixture_path_report(config, slot)
	return build_legacy_fixture_provider(slot, path_report["path"], path_report["source"])

