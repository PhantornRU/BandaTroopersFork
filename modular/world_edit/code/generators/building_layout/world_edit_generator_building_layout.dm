/datum/world_edit_generator/building_layout
	requires_preview_before_apply = TRUE

/datum/world_edit_generator/building_layout/get_supported_placement_modes()
	return list("single", "repeat")

/datum/world_edit_generator/building_layout/get_supported_placement_shapes()
	return list(
		WORLD_EDIT_SHAPE_POINT,
		WORLD_EDIT_SHAPE_LINE,
		WORLD_EDIT_SHAPE_RECTANGLE,
		WORLD_EDIT_SHAPE_FILLED_RECTANGLE,
		WORLD_EDIT_SHAPE_CIRCLE,
		WORLD_EDIT_SHAPE_RING,
		WORLD_EDIT_SHAPE_ELLIPSE,
		WORLD_EDIT_SHAPE_DIAMOND,
		WORLD_EDIT_SHAPE_TRIANGLE,
		WORLD_EDIT_SHAPE_SECTOR,
		WORLD_EDIT_SHAPE_POLYGON,
		WORLD_EDIT_SHAPE_POLYLINE,
		WORLD_EDIT_SHAPE_CUSTOM_MASK,
		WORLD_EDIT_SHAPE_BRUSH_PATH,
		WORLD_EDIT_SHAPE_SCATTER_CLUSTER,
	)

/datum/world_edit_generator/building_layout/supports_placement_direction()
	return TRUE

/datum/world_edit_generator/building_layout/get_default_placement_direction()
	return NORTH

/datum/world_edit_generator/building_layout/proc/get_building_faction_options()
	return list("colony", "uscm", "unsc", "neutral", "covenant")

/datum/world_edit_generator/building_layout/proc/get_building_archetype_ids()
	var/list/result = list()
	var/list/catalog = get_building_archetype_catalog()
	for(var/archetype_id in catalog)
		result += "[archetype_id]"
	return result

/datum/world_edit_generator/building_layout/proc/get_building_faction_catalog()
	return list(
		"colony" = list(
			"label" = "Colony",
			"wall_path" = "/turf/closed/wall/kutjevo/colony",
			"floor_path" = "/turf/open/floor/interior/wood",
			"door_path" = "/obj/structure/machinery/door/airlock/almayer/generic",
			"window_path" = "/obj/structure/window/framed/colony/reinforced",
			"interior_paths" = list(
				"table" = "/obj/structure/surface/table/woodentable",
				"chair" = "/obj/structure/bed/chair/wood/normal",
				"cabinet" = "/obj/structure/closet/cabinet",
				"bed" = "/obj/structure/bed",
				"rack" = "/obj/structure/surface/rack",
				"crate" = "/obj/structure/closet/crate/supply",
				"console" = "/obj/structure/prop/server_equipment/laptop/on",
				"barrier" = "/obj/structure/barricade/metal",
				"medical_bed" = "/obj/structure/bed/roller/hospital_empty",
				"medical_storage" = "/obj/structure/closet/crate/medical",
				"sleeper" = "/obj/structure/machinery/medical_pod/sleeper",
				"medical_scanner" = "/obj/structure/machinery/medical_pod/bodyscanner",
				"wall_monitor" = "/obj/structure/machinery/body_scanconsole",
				"hydro_tray" = "/obj/structure/machinery/portable_atmospherics/hydroponics",
				"seed_storage" = "/obj/structure/filingcabinet/seeds",
				"water_tank" = "/obj/structure/reagent_dispensers/watertank",
				"fridge" = "/obj/structure/machinery/smartfridge",
				"microwave" = "/obj/structure/machinery/microwave",
				"processor" = "/obj/structure/machinery/processor",
				"sink" = "/obj/structure/sink/kitchen",
				"filing" = "/obj/structure/filingcabinet",
				"security_console" = "/obj/structure/machinery/computer/cameras",
				"security_camera" = "/obj/structure/machinery/camera",
				"brig_cell" = "/obj/structure/machinery/brig_cell",
				"weapon_rack" = "/obj/structure/gun_rack/m41/empty",
				"engineering_machine" = "/obj/structure/machinery/processor",
				"power_console" = "/obj/structure/prop/server_equipment/laptop/on",
				"lab_machine" = "/obj/structure/machinery/medical_pod/bodyscanner",
				"sample_storage" = "/obj/structure/closet/crate/medical",
				"light" = "/obj/structure/machinery/light/small",
				"apc" = "/obj/structure/machinery/power/apc",
				"air_alarm" = "/obj/structure/machinery/alarm",
				"fire_alarm" = "/obj/structure/machinery/firealarm",
				"light_switch" = "/obj/structure/machinery/light_switch",
			),
		),
		"uscm" = list(
			"label" = "USCM",
			"wall_path" = "/turf/closed/wall/almayer",
			"floor_path" = "/turf/open/floor/plating",
			"door_path" = "/obj/structure/machinery/door/airlock/almayer/marine",
			"window_path" = "/obj/structure/window/framed/almayer",
			"interior_paths" = list(
				"table" = "/obj/structure/surface/table/reinforced",
				"chair" = "/obj/structure/bed/chair/office/dark",
				"cabinet" = "/obj/structure/closet/secure_closet/security_empty",
				"bed" = "/obj/structure/bed",
				"rack" = "/obj/structure/surface/rack",
				"crate" = "/obj/structure/closet/crate/supply",
				"console" = "/obj/structure/prop/server_equipment/laptop/on",
				"barrier" = "/obj/structure/barricade/metal",
				"medical_bed" = "/obj/structure/bed/roller/hospital_empty",
				"medical_storage" = "/obj/structure/closet/medical_wall",
				"sleeper" = "/obj/structure/machinery/medical_pod/sleeper",
				"medical_scanner" = "/obj/structure/machinery/medical_pod/bodyscanner",
				"wall_monitor" = "/obj/structure/machinery/body_scanconsole",
				"hydro_tray" = "/obj/structure/machinery/portable_atmospherics/hydroponics",
				"seed_storage" = "/obj/structure/filingcabinet/seeds",
				"water_tank" = "/obj/structure/reagent_dispensers/watertank",
				"fridge" = "/obj/structure/machinery/smartfridge",
				"microwave" = "/obj/structure/machinery/microwave",
				"processor" = "/obj/structure/machinery/processor",
				"sink" = "/obj/structure/sink/kitchen",
				"filing" = "/obj/structure/filingcabinet",
				"security_console" = "/obj/structure/machinery/computer/cameras/almayer_brig",
				"security_camera" = "/obj/structure/machinery/camera/autoname/almayer/brig",
				"brig_cell" = "/obj/structure/machinery/brig_cell",
				"weapon_rack" = "/obj/structure/gun_rack/m41/empty",
				"engineering_machine" = "/obj/structure/machinery/processor",
				"power_console" = "/obj/structure/prop/server_equipment/laptop/on",
				"lab_machine" = "/obj/structure/machinery/medical_pod/bodyscanner",
				"sample_storage" = "/obj/structure/closet/medical_wall",
				"light" = "/obj/structure/machinery/light/small/blue",
				"apc" = "/obj/structure/machinery/power/apc/almayer",
				"air_alarm" = "/obj/structure/machinery/alarm/almayer",
				"fire_alarm" = "/obj/structure/machinery/firealarm",
				"light_switch" = "/obj/structure/machinery/light_switch",
			),
		),
		"unsc" = list(
			"label" = "UNSC",
			"wall_path" = "/turf/closed/wall/unsc",
			"floor_path" = "/turf/open/floor/plating",
			"door_path" = "/obj/structure/machinery/door/airlock/unsc",
			"window_path" = "/obj/structure/window/framed/unsc",
			"interior_paths" = list(
				"table" = "/obj/structure/surface/table/reinforced",
				"chair" = "/obj/structure/bed/chair/vehicle",
				"cabinet" = "/obj/structure/closet/secure_closet/security_empty",
				"bed" = "/obj/structure/bed",
				"rack" = "/obj/structure/gun_rack/m41/empty",
				"crate" = "/obj/structure/closet/crate/supply",
				"console" = "/obj/structure/prop/server_equipment/laptop/on",
				"barrier" = "/obj/structure/barricade/metal",
				"medical_bed" = "/obj/structure/bed/roller/hospital_empty",
				"medical_storage" = "/obj/structure/closet/crate/medical",
				"sleeper" = "/obj/structure/machinery/medical_pod/sleeper",
				"medical_scanner" = "/obj/structure/machinery/medical_pod/bodyscanner",
				"wall_monitor" = "/obj/structure/machinery/body_scanconsole",
				"hydro_tray" = "/obj/structure/machinery/portable_atmospherics/hydroponics",
				"seed_storage" = "/obj/structure/filingcabinet/seeds",
				"water_tank" = "/obj/structure/reagent_dispensers/watertank",
				"fridge" = "/obj/structure/machinery/smartfridge",
				"microwave" = "/obj/structure/machinery/microwave",
				"processor" = "/obj/structure/machinery/processor",
				"sink" = "/obj/structure/sink/kitchen",
				"filing" = "/obj/structure/filingcabinet",
				"security_console" = "/obj/structure/machinery/computer/cameras",
				"security_camera" = "/obj/structure/machinery/camera",
				"brig_cell" = "/obj/structure/machinery/brig_cell",
				"weapon_rack" = "/obj/structure/gun_rack/halo/armory/ma5c/empty",
				"engineering_machine" = "/obj/structure/machinery/processor",
				"power_console" = "/obj/structure/prop/server_equipment/laptop/on",
				"lab_machine" = "/obj/structure/machinery/medical_pod/bodyscanner",
				"sample_storage" = "/obj/structure/closet/crate/medical",
				"light" = "/obj/structure/machinery/light/small/blue",
				"apc" = "/obj/structure/machinery/power/apc",
				"air_alarm" = "/obj/structure/machinery/alarm",
				"fire_alarm" = "/obj/structure/machinery/firealarm",
				"light_switch" = "/obj/structure/machinery/light_switch",
			),
		),
		"neutral" = list(
			"label" = "Neutral",
			"wall_path" = "/turf/closed/wall/wood",
			"floor_path" = "/turf/open/floor/wood",
			"door_path" = "/obj/structure/machinery/door/airlock/hybrisa/generic",
			"window_path" = "/obj/structure/window/framed/hybrisa/colony",
			"interior_paths" = list(
				"table" = "/obj/structure/surface/table/woodentable",
				"chair" = "/obj/structure/bed/chair/wood/normal",
				"cabinet" = "/obj/structure/closet/cabinet/hybrisa/metal",
				"bed" = "/obj/structure/bed",
				"rack" = "/obj/structure/surface/rack",
				"crate" = "/obj/structure/closet/crate/supply",
				"console" = "/obj/structure/prop/server_equipment/laptop/on",
				"barrier" = "/obj/structure/barricade/metal",
				"medical_bed" = "/obj/structure/bed/roller/hospital_empty",
				"medical_storage" = "/obj/structure/closet/crate/medical",
				"sleeper" = "/obj/structure/machinery/medical_pod/sleeper",
				"medical_scanner" = "/obj/structure/machinery/medical_pod/bodyscanner",
				"wall_monitor" = "/obj/structure/machinery/body_scanconsole",
				"hydro_tray" = "/obj/structure/machinery/portable_atmospherics/hydroponics",
				"seed_storage" = "/obj/structure/filingcabinet/seeds",
				"water_tank" = "/obj/structure/reagent_dispensers/watertank",
				"fridge" = "/obj/structure/machinery/smartfridge",
				"microwave" = "/obj/structure/machinery/microwave",
				"processor" = "/obj/structure/machinery/processor",
				"sink" = "/obj/structure/sink/kitchen",
				"filing" = "/obj/structure/filingcabinet",
				"security_console" = "/obj/structure/machinery/computer/cameras",
				"security_camera" = "/obj/structure/machinery/camera",
				"brig_cell" = "/obj/structure/machinery/brig_cell",
				"weapon_rack" = "/obj/structure/gun_rack/m41/empty",
				"engineering_machine" = "/obj/structure/machinery/processor",
				"power_console" = "/obj/structure/prop/server_equipment/laptop/on",
				"lab_machine" = "/obj/structure/machinery/medical_pod/bodyscanner",
				"sample_storage" = "/obj/structure/closet/crate/medical",
				"light" = "/obj/structure/machinery/light/small",
				"apc" = "/obj/structure/machinery/power/apc",
				"air_alarm" = "/obj/structure/machinery/alarm",
				"fire_alarm" = "/obj/structure/machinery/firealarm",
				"light_switch" = "/obj/structure/machinery/light_switch",
			),
		),
		"covenant" = list(
			"label" = "Covenant",
			"wall_path" = "/turf/closed/wall/covenant/lights/hull",
			"floor_path" = "/turf/open/floor/covenant/smooth_plating",
			"door_path" = "/obj/structure/machinery/door/airlock/voi",
			"window_path" = "/obj/structure/covenant_barricade",
			"interior_paths" = list(
				"table" = "/obj/structure/machinery/recharger/covenant",
				"chair" = "/obj/structure/covenant_barricade",
				"cabinet" = "/obj/structure/covenant_barricade",
				"bed" = "/obj/structure/covenant_barricade",
				"rack" = "/obj/structure/covenant_barricade",
				"crate" = "/obj/structure/covenant_barricade",
				"console" = "/obj/structure/machinery/recharger/covenant",
				"barrier" = "/obj/structure/covenant_barricade",
				"medical_bed" = "/obj/structure/covenant_barricade",
				"medical_storage" = "/obj/structure/covenant_barricade",
				"sleeper" = "/obj/structure/covenant_barricade",
				"medical_scanner" = "/obj/structure/covenant_barricade",
				"wall_monitor" = "/obj/structure/machinery/recharger/covenant",
				"hydro_tray" = "/obj/structure/covenant_barricade",
				"seed_storage" = "/obj/structure/covenant_barricade",
				"water_tank" = "/obj/structure/covenant_barricade",
				"fridge" = "/obj/structure/covenant_barricade",
				"microwave" = "/obj/structure/machinery/recharger/covenant",
				"processor" = "/obj/structure/machinery/recharger/covenant",
				"sink" = "/obj/structure/covenant_barricade",
				"filing" = "/obj/structure/covenant_barricade",
				"security_console" = "/obj/structure/machinery/recharger/covenant",
				"security_camera" = "/obj/structure/machinery/recharger/covenant",
				"brig_cell" = "/obj/structure/covenant_barricade",
				"weapon_rack" = "/obj/structure/covenant_barricade",
				"engineering_machine" = "/obj/structure/machinery/recharger/covenant",
				"power_console" = "/obj/structure/machinery/recharger/covenant",
				"lab_machine" = "/obj/structure/machinery/recharger/covenant",
				"sample_storage" = "/obj/structure/covenant_barricade/wide",
				"light" = "/obj/structure/machinery/recharger/covenant",
				"apc" = "/obj/structure/machinery/recharger/covenant",
				"air_alarm" = "/obj/structure/machinery/recharger/covenant",
				"fire_alarm" = "/obj/structure/machinery/recharger/covenant",
				"light_switch" = "/obj/structure/machinery/recharger/covenant",
			),
		),
	)

/datum/world_edit_generator/building_layout/proc/has_building_param(list/params, param_id)
	return islist(params) && ("[param_id]" in params)

/datum/world_edit_generator/building_layout/proc/resolve_building_option(value, list/options, fallback)
	var/value_text = "[value]"
	if(value_text in options)
		return value_text
	return fallback

/datum/world_edit_generator/building_layout/proc/num_param(list/params, param_id, default_value, min_value, max_value)
	var/value = text2num("[islist(params) ? params[param_id] : null]")
	if(!isnum(value))
		value = default_value
	return clamp(round(value), min_value, max_value)

/datum/world_edit_generator/building_layout/proc/ui_num_param(value, default_value, min_value, max_value)
	var/num_value = text2num("[value]")
	if(!isnum(num_value))
		num_value = default_value
	return clamp(round(num_value), min_value, max_value)

/datum/world_edit_generator/building_layout/proc/resolve_building_type_path(path_value, expected_root)
	if(ispath(path_value, expected_root))
		return path_value
	var/resolved_path = text2path("[path_value]")
	if(!ispath(resolved_path, expected_root))
		return null
	return resolved_path

/datum/world_edit_generator/building_layout/proc/merge_building_preset_overrides(list/base_preset, datum/world_edit_building_archetype/archetype)
	var/list/preset = islist(base_preset) ? base_preset.Copy() : list()
	var/list/base_interiors = islist(base_preset?["interior_paths"]) ? base_preset["interior_paths"].Copy() : list()
	preset["interior_paths"] = base_interiors
	if(!istype(archetype) || !islist(archetype.shell_overrides))
		return preset
	for(var/key in archetype.shell_overrides)
		if("[key]" == "interior_paths")
			var/list/interior_overrides = archetype.shell_overrides[key]
			if(islist(interior_overrides))
				for(var/interior_key in interior_overrides)
					base_interiors["[interior_key]"] = interior_overrides[interior_key]
			continue
		preset[key] = archetype.shell_overrides[key]
	return preset

/datum/world_edit_generator/building_layout/proc/add_building_required_slot(list/slots, list/slot_lookup, slot)
	if(!islist(slots) || !islist(slot_lookup) || !length("[slot]"))
		return
	var/slot_key = "[slot]"
	if(slot_lookup[slot_key])
		return
	slots += slot_key
	slot_lookup[slot_key] = TRUE

/datum/world_edit_generator/building_layout/proc/collect_building_required_slots(datum/world_edit_building_archetype/archetype)
	var/list/slots = list()
	var/list/slot_lookup = list()
	if(!istype(archetype))
		return slots
	for(var/datum/world_edit_building_cluster_spec/cluster_spec as anything in archetype.cluster_specs)
		if(!istype(cluster_spec))
			continue
		add_building_required_slot(slots, slot_lookup, cluster_spec.slot)
		var/macro_id = length(cluster_spec.macro_id) ? cluster_spec.macro_id : get_building_macro_id_for_cluster(cluster_spec)
		var/datum/world_edit_building_template_chunk/chunk = get_building_template_chunk(macro_id)
		if(!istype(chunk))
			continue
		for(var/datum/world_edit_building_template_cell/cell as anything in chunk.cells)
			if(istype(cell))
				add_building_required_slot(slots, slot_lookup, cell.slot)
	for(var/infra_slot as anything in list("light", "apc", "air_alarm", "light_switch", "fire_alarm"))
		add_building_required_slot(slots, slot_lookup, infra_slot)
	return slots

/datum/world_edit_generator/building_layout/proc/validate_building_preset_capabilities(list/config, datum/world_edit_building_archetype/archetype)
	if(!islist(config) || !istype(archetype))
		return null
	var/list/missing_slots = list()
	for(var/slot as anything in collect_building_required_slots(archetype))
		if(!resolve_interior_obj_path(config, slot))
			missing_slots += "[slot]"
	if(length(missing_slots))
		return "Shell preset '[config["faction_preset"]]' cannot resolve required building fixture slots for program '[archetype.id]': [english_list(missing_slots)]."
	return null

/datum/world_edit_generator/building_layout/proc/normalize_building_params(list/params)
	var/list/config = list()
	var/default_archetype_id = resolve_layout_variant_archetype_alias(params)
	config["archetype_id"] = resolve_building_archetype_option(islist(params) ? params["archetype_id"] : null, default_archetype_id)
	var/datum/world_edit_building_archetype/archetype = get_building_archetype(config["archetype_id"])
	if(!istype(archetype))
		config["error"] = "Unable to resolve building program '[config["archetype_id"]]'."
		return config

	config["half_width"] = num_param(params, "half_width", 4, 2, 8)
	config["half_depth"] = num_param(params, "half_depth", 4, 2, 8)
	config["window_density"] = num_param(params, "window_density", archetype.window_bias, 0, 100)
	config["detail_budget"] = num_param(params, "detail_budget", has_building_param(params, "interior_density") ? num_param(params, "interior_density", archetype.detail_bias, 0, 100) : archetype.detail_bias, 0, 100)
	config["building_seed"] = num_param(params, "building_seed", WORLD_EDIT_BUILDING_AUTO_SEED, 0, 999999999)
	config["back_exit"] = GLOB.world_edit_helpers.parse_bool(islist(params) ? params["back_exit"] : null) ? TRUE : FALSE
	config["respect_blockers"] = isnull(islist(params) ? params["respect_blockers"] : null) ? TRUE : GLOB.world_edit_helpers.parse_bool(params["respect_blockers"])
	config["replace_blocked_turfs"] = GLOB.world_edit_helpers.parse_bool(islist(params) ? params["replace_blocked_turfs"] : null) ? TRUE : FALSE

	var/default_shell_preset = length("[archetype.suggested_shell_preset]") ? archetype.suggested_shell_preset : "colony"
	config["faction_preset"] = resolve_building_option(islist(params) ? params["faction_preset"] : null, get_building_faction_options(), default_shell_preset)
	var/list/catalog = get_building_faction_catalog()
	var/list/base_preset = catalog[config["faction_preset"]] || catalog[default_shell_preset] || catalog["colony"]
	var/list/preset = merge_building_preset_overrides(base_preset, archetype)
	config["preset"] = preset
	config["wall_type"] = resolve_building_type_path(preset["wall_path"], /turf)
	config["floor_type"] = resolve_building_type_path(preset["floor_path"], /turf)
	config["door_type"] = resolve_building_type_path(preset["door_path"], /obj)
	config["window_type"] = resolve_building_type_path(preset["window_path"], /obj)
	config["interior_paths"] = islist(preset["interior_paths"]) ? preset["interior_paths"].Copy() : list()
	if(!config["wall_type"] || !config["floor_type"] || !config["door_type"] || !config["window_type"])
		config["error"] = "Unable to resolve one or more shell type paths for preset '[config["faction_preset"]]' and building program '[config["archetype_id"]]'."
	if(!config["error"])
		config["error"] = validate_building_preset_capabilities(config, archetype)
	return config

/datum/world_edit_generator/building_layout/get_ui_fields(list/current_params)
	var/list/config = normalize_building_params(current_params)
	return list(
		list(
			"id" = "archetype_id",
			"label" = "Building program",
			"kind" = "select",
			"group" = "Program",
			"value" = config["archetype_id"],
			"options" = get_building_archetype_options(),
		),
		list(
			"id" = "faction_preset",
			"label" = "Shell preset",
			"kind" = "select",
			"group" = "Shell",
			"value" = config["faction_preset"],
			"options" = list(
				list("label" = "Colony", "value" = "colony"),
				list("label" = "USCM", "value" = "uscm"),
				list("label" = "UNSC", "value" = "unsc"),
				list("label" = "Neutral", "value" = "neutral"),
				list("label" = "Covenant", "value" = "covenant"),
			),
		),
		list(
			"id" = "building_seed",
			"label" = "Seed",
			"kind" = "number",
			"group" = "Program",
			"value" = config["building_seed"],
			"min" = 0,
			"max" = 999999999,
			"step" = 1,
		),
		list(
			"id" = "half_width",
			"label" = "Half width",
			"kind" = "number",
			"group" = "Size",
			"value" = config["half_width"],
			"min" = 2,
			"max" = 8,
			"step" = 1,
		),
		list(
			"id" = "half_depth",
			"label" = "Half depth",
			"kind" = "number",
			"group" = "Size",
			"value" = config["half_depth"],
			"min" = 2,
			"max" = 8,
			"step" = 1,
		),
		list(
			"id" = "window_density",
			"label" = "Windows",
			"kind" = "number",
			"group" = "Shell",
			"value" = config["window_density"],
			"min" = 0,
			"max" = 100,
			"step" = 10,
		),
		list(
			"id" = "detail_budget",
			"label" = "Details",
			"kind" = "number",
			"group" = "Interior",
			"value" = config["detail_budget"],
			"min" = 0,
			"max" = 100,
			"step" = 10,
		),
		list(
			"id" = "back_exit",
			"label" = "Back exit",
			"kind" = "boolean",
			"group" = "Shell",
			"value" = config["back_exit"],
		),
		list(
			"id" = "respect_blockers",
			"label" = "Respect blockers",
			"kind" = "boolean",
			"group" = "Safety",
			"value" = config["respect_blockers"],
		),
		list(
			"id" = "replace_blocked_turfs",
			"label" = "Replace blocked turfs",
			"kind" = "boolean",
			"group" = "Safety",
			"value" = config["replace_blocked_turfs"],
		),
	)

/datum/world_edit_generator/building_layout/set_ui_param(mob/user, list/current_params, param_id, value)
	if(!islist(current_params))
		current_params = list()
	var/list/new_params = current_params.Copy()
	switch("[param_id]")
		if("archetype_id")
			new_params[param_id] = resolve_building_archetype_option(value, "living")
		if("faction_preset")
			new_params[param_id] = resolve_building_option(value, get_building_faction_options(), "colony")
		if("half_width")
			new_params[param_id] = ui_num_param(value, 4, 2, 8)
		if("half_depth")
			new_params[param_id] = ui_num_param(value, 4, 2, 8)
		if("window_density")
			new_params[param_id] = ui_num_param(value, 40, 0, 100)
		if("detail_budget")
			new_params[param_id] = ui_num_param(value, 60, 0, 100)
		if("building_seed")
			new_params[param_id] = ui_num_param(value, WORLD_EDIT_BUILDING_AUTO_SEED, 0, 999999999)
		if("back_exit", "respect_blockers", "replace_blocked_turfs")
			new_params[param_id] = GLOB.world_edit_helpers.parse_bool(value) ? TRUE : FALSE
		else
			new_params[param_id] = value
	return new_params

/datum/world_edit_generator/building_layout/get_params_short(list/params)
	var/list/config = normalize_building_params(params)
	return "program=[config["archetype_id"]] shell=[config["faction_preset"]] seed=[config["building_seed"]] effective_seed=[config["effective_seed"]] size=[config["half_width"]]x[config["half_depth"]] windows=[config["window_density"]] details=[config["detail_budget"]] back=[config["back_exit"]] strict_blockers=[config["respect_blockers"]] replace_blocked=[config["replace_blocked_turfs"]] shape=[manager?.get_effective_placement_shape() || WORLD_EDIT_SHAPE_POINT] dir=[GLOB.world_edit_helpers.dir_to_label(manager?.get_effective_placement_dir() || NORTH)]"

/datum/world_edit_generator/building_layout/proc/get_building_shape_error(shape_id, list/config)
	switch("[shape_id]")
		if(
			WORLD_EDIT_SHAPE_POINT,
			WORLD_EDIT_SHAPE_LINE,
			WORLD_EDIT_SHAPE_RECTANGLE,
			WORLD_EDIT_SHAPE_FILLED_RECTANGLE,
			WORLD_EDIT_SHAPE_CIRCLE,
			WORLD_EDIT_SHAPE_RING,
			WORLD_EDIT_SHAPE_ELLIPSE,
			WORLD_EDIT_SHAPE_DIAMOND,
			WORLD_EDIT_SHAPE_TRIANGLE,
			WORLD_EDIT_SHAPE_SECTOR,
			WORLD_EDIT_SHAPE_POLYGON,
			WORLD_EDIT_SHAPE_POLYLINE,
			WORLD_EDIT_SHAPE_CUSTOM_MASK,
			WORLD_EDIT_SHAPE_BRUSH_PATH,
			WORLD_EDIT_SHAPE_SCATTER_CLUSTER
		)
			return null
	return "Placement shape '[shape_id]' is not supported by building layout."

/datum/world_edit_generator/building_layout/validate_params(mob/user, list/params)
	var/list/config = normalize_building_params(params)
	if(config["error"])
		return "[config["error"]]"
	var/shape_id = manager?.get_effective_placement_shape() || WORLD_EDIT_SHAPE_POINT
	var/shape_error = get_building_shape_error(shape_id, config)
	if(length("[shape_error]"))
		return shape_error
	return null

/datum/world_edit_generator/building_layout/get_shape_support_error(shape_id, list/anchor_turfs, list/params, list/placement_context)
	var/list/config = normalize_building_params(params)
	if(config["error"])
		return "[config["error"]]"
	return get_building_shape_error(shape_id, config)

/datum/world_edit_generator/building_layout/proc/turf_coord_key(turf/target_turf)
	if(!istype(target_turf))
		return ""
	return "[target_turf.x],[target_turf.y],[target_turf.z]"

/datum/world_edit_generator/building_layout/proc/fill_turf_bounds(list/raw_turfs)
	var/list/result = list()
	var/list/result_lookup = list()
	if(!islist(raw_turfs) || !length(raw_turfs))
		return result

	var/min_x = null
	var/max_x = null
	var/min_y = null
	var/max_y = null
	var/z_level = null
	for(var/turf/source_turf as anything in raw_turfs)
		if(!istype(source_turf))
			continue
		if(isnull(z_level))
			z_level = source_turf.z
		if(source_turf.z != z_level)
			continue
		if(isnull(min_x) || source_turf.x < min_x)
			min_x = source_turf.x
		if(isnull(max_x) || source_turf.x > max_x)
			max_x = source_turf.x
		if(isnull(min_y) || source_turf.y < min_y)
			min_y = source_turf.y
		if(isnull(max_y) || source_turf.y > max_y)
			max_y = source_turf.y

	if(isnull(min_x) || isnull(min_y) || isnull(z_level))
		return result

	for(var/y in min_y to max_y)
		for(var/x in min_x to max_x)
			var/turf/target_turf = locate(x, y, z_level)
			GLOB.world_edit_placement_shapes.world_edit_add_turf_unique(result, result_lookup, target_turf, z_level)
	return result

/datum/world_edit_generator/building_layout/proc/inflate_turf_footprint(list/raw_turfs, radius = 1)
	var/list/result = list()
	var/list/result_lookup = list()
	if(!islist(raw_turfs) || !length(raw_turfs))
		return result
	radius = max(round(radius), 0)
	var/z_level = null
	for(var/turf/source_turf as anything in raw_turfs)
		if(!istype(source_turf))
			continue
		if(isnull(z_level))
			z_level = source_turf.z
		if(source_turf.z != z_level)
			continue
		for(var/dx in -radius to radius)
			for(var/dy in -radius to radius)
				var/turf/target_turf = locate(source_turf.x + dx, source_turf.y + dy, source_turf.z)
				GLOB.world_edit_placement_shapes.world_edit_add_turf_unique(result, result_lookup, target_turf, z_level)
	return result

/datum/world_edit_generator/building_layout/proc/add_scatter_connection_turf(list/result, list/result_lookup, turf/source_turf, z_level)
	if(!istype(source_turf) || isnull(z_level) || source_turf.z != z_level)
		return
	for(var/dx in -1 to 1)
		for(var/dy in -1 to 1)
			var/turf/target_turf = locate(source_turf.x + dx, source_turf.y + dy, source_turf.z)
			GLOB.world_edit_placement_shapes.world_edit_add_turf_unique(result, result_lookup, target_turf, z_level)

/datum/world_edit_generator/building_layout/proc/add_scatter_connection_line(list/result, list/result_lookup, turf/start_turf, turf/end_turf, z_level)
	if(!istype(start_turf) || !istype(end_turf) || isnull(z_level) || start_turf.z != z_level || end_turf.z != z_level)
		return
	var/current_x = start_turf.x
	var/current_y = start_turf.y
	var/safety = WORLD_EDIT_BUILDING_MAX_FOOTPRINT_TURFS
	while(current_x != end_turf.x && safety-- > 0)
		current_x += current_x < end_turf.x ? 1 : -1
		add_scatter_connection_turf(result, result_lookup, locate(current_x, current_y, z_level), z_level)
	while(current_y != end_turf.y && safety-- > 0)
		current_y += current_y < end_turf.y ? 1 : -1
		add_scatter_connection_turf(result, result_lookup, locate(current_x, current_y, z_level), z_level)

/datum/world_edit_generator/building_layout/proc/build_scatter_compound_footprint(list/raw_turfs)
	var/list/source_turfs = GLOB.world_edit_placement_shapes.world_edit_unique_turf_list(raw_turfs)
	var/list/result = list()
	var/list/result_lookup = list()
	if(!length(source_turfs))
		return result
	var/z_level = null
	var/turf/previous_turf = null
	for(var/turf/source_turf as anything in source_turfs)
		if(!istype(source_turf))
			continue
		if(isnull(z_level))
			z_level = source_turf.z
		if(source_turf.z != z_level)
			continue
		add_scatter_connection_turf(result, result_lookup, source_turf, z_level)
		if(istype(previous_turf))
			add_scatter_connection_line(result, result_lookup, previous_turf, source_turf, z_level)
		previous_turf = source_turf
	return GLOB.world_edit_placement_shapes.world_edit_unique_turf_list(result)

/datum/world_edit_generator/building_layout/proc/build_explicit_shape_footprint(datum/world_edit_shape_contract/shape_contract, list/raw_turfs, list/placement_context)
	var/shape_id = "[shape_contract?.shape_id || placement_context["shape"] || WORLD_EDIT_SHAPE_POINT]"
	var/list/footprint = GLOB.world_edit_placement_shapes.world_edit_unique_turf_list(raw_turfs)
	if(!length(footprint))
		return footprint

	switch(shape_id)
		if(WORLD_EDIT_SHAPE_RECTANGLE)
			if(shape_contract?.is_closed && !shape_contract?.is_filled)
				footprint = fill_turf_bounds(footprint)
		if(WORLD_EDIT_SHAPE_POLYGON)
			if(shape_contract?.is_closed && !shape_contract?.is_filled)
				var/list/metadata = istype(shape_contract) ? shape_contract.copy_metadata() : placement_context["shape_metadata"]
				if(!islist(metadata))
					metadata = list()
				var/list/points = metadata["normalized_points"]
				var/turf/origin_turf = placement_context["shape_origin_turf"] || placement_context["start_turf"] || get_shape_placement_seed_turf(shape_contract, placement_context)
				if(istype(origin_turf) && islist(points) && length(points) >= 3)
					footprint = GLOB.world_edit_placement_shapes.world_edit_collect_polygon_turfs(origin_turf, points, TRUE)
		if(WORLD_EDIT_SHAPE_LINE, WORLD_EDIT_SHAPE_POLYLINE)
			footprint = inflate_turf_footprint(footprint, 1)
		if(WORLD_EDIT_SHAPE_SCATTER_CLUSTER)
			footprint = build_scatter_compound_footprint(footprint)

	return GLOB.world_edit_placement_shapes.world_edit_unique_turf_list(footprint)

/datum/world_edit_generator/building_layout/proc/select_building_context_center_turf(list/raw_turfs)
	if(!islist(raw_turfs) || !length(raw_turfs))
		return null
	var/min_x = null
	var/max_x = null
	var/min_y = null
	var/max_y = null
	var/z_level = null
	for(var/turf/source_turf as anything in raw_turfs)
		if(!istype(source_turf))
			continue
		if(isnull(z_level))
			z_level = source_turf.z
		if(source_turf.z != z_level)
			continue
		if(isnull(min_x) || source_turf.x < min_x)
			min_x = source_turf.x
		if(isnull(max_x) || source_turf.x > max_x)
			max_x = source_turf.x
		if(isnull(min_y) || source_turf.y < min_y)
			min_y = source_turf.y
		if(isnull(max_y) || source_turf.y > max_y)
			max_y = source_turf.y
	if(isnull(min_x) || isnull(min_y) || isnull(z_level))
		return null
	var/center_x = round((min_x + max_x) / 2)
	var/center_y = round((min_y + max_y) / 2)
	return locate(center_x, center_y, z_level)

/datum/world_edit_generator/building_layout/proc/resolve_shape_footprint(datum/world_edit_shape_contract/shape_contract, list/config, list/params, list/placement_context)
	var/list/result = list("footprint" = list())
	var/shape_id = "[shape_contract?.shape_id || placement_context["shape"] || WORLD_EDIT_SHAPE_POINT]"
	var/shape_error = get_building_shape_error(shape_id, config)
	if(length("[shape_error]"))
		result["error"] = shape_error
		return result

	var/list/raw_turfs = shape_contract?.copy_anchor_turfs() || placement_context["anchor_turfs"]
	var/turf/seed_turf = get_shape_placement_seed_turf(shape_contract, placement_context)
	if(shape_id != WORLD_EDIT_SHAPE_POINT && !istype(seed_turf))
		seed_turf = select_building_context_center_turf(raw_turfs)
	if(!istype(seed_turf))
		result["error"] = "Unable to resolve building center turf."
		return result
	if(shape_id != WORLD_EDIT_SHAPE_POINT)
		var/list/explicit_footprint = build_explicit_shape_footprint(shape_contract, raw_turfs, placement_context)
		if(!length(explicit_footprint))
			result["error"] = "Unable to resolve explicit building shape footprint."
			return result
		config["placement_shape_used_as_seed_only"] = FALSE
		config["explicit_placement_shape_footprint"] = TRUE
		config["footprint_source"] = "explicit_shape"
		config["placement_shape_id"] = shape_id
		config["footprint_family"] = uppertext("[shape_id]")
		config["footprint_mask_score"] = 0
		config["footprint_mask_candidate_count"] = 1
		result["footprint"] = explicit_footprint
		result["footprint_family"] = uppertext("[shape_id]")
		return result
	config["placement_shape_used_as_seed_only"] = TRUE
	config["footprint_source"] = "point_size"
	config["placement_shape_id"] = shape_id
	return build_point_building_footprint(seed_turf, config, placement_context)

/datum/world_edit_generator/building_layout/proc/validate_footprint(list/footprint, list/config)
	var/list/result = list()
	footprint = GLOB.world_edit_placement_shapes.world_edit_unique_turf_list(footprint)
	result["footprint"] = footprint
	if(!length(footprint))
		result["error"] = "Building footprint is empty."
		return result
	if(length(footprint) > WORLD_EDIT_BUILDING_MAX_FOOTPRINT_TURFS)
		result["error"] = "Building footprint exceeds cap ([WORLD_EDIT_BUILDING_MAX_FOOTPRINT_TURFS])."
		return result

	var/z_level = null
	var/min_x = null
	var/max_x = null
	var/min_y = null
	var/max_y = null
	for(var/turf/target_turf as anything in footprint)
		if(!istype(target_turf))
			result["error"] = "Building footprint contains an invalid turf."
			return result
		if(isnull(z_level))
			z_level = target_turf.z
		if(target_turf.z != z_level)
			result["error"] = "Building footprint must stay on one z-level."
			return result
		if(isnull(min_x) || target_turf.x < min_x)
			min_x = target_turf.x
		if(isnull(max_x) || target_turf.x > max_x)
			max_x = target_turf.x
		if(isnull(min_y) || target_turf.y < min_y)
			min_y = target_turf.y
		if(isnull(max_y) || target_turf.y > max_y)
			max_y = target_turf.y

	var/width = max_x - min_x + 1
	var/height = max_y - min_y + 1
	if(width < 3 || height < 3)
		result["error"] = "Building footprint requires at least a 3x3 area."
		return result

	var/list/footprint_lookup = GLOB.world_edit_placement_shapes.world_edit_build_turf_lookup(footprint)
	var/list/visited_lookup = list()
	var/list/queue = list(footprint[1])
	visited_lookup[footprint[1]] = TRUE
	var/index = 1
	while(index <= length(queue))
		var/turf/current_turf = queue[index++]
		for(var/check_dir in GLOB.cardinals)
			var/turf/nearby_turf = get_step(current_turf, check_dir)
			if(!footprint_lookup[nearby_turf] || visited_lookup[nearby_turf])
				continue
			visited_lookup[nearby_turf] = TRUE
			queue += nearby_turf
	if(length(queue) != length(footprint))
		result["error"] = "Building footprint must be connected."
		return result

	if(config["respect_blockers"])
		for(var/turf/check_turf as anything in footprint)
			var/blocker_error = get_footprint_blocker_error(check_turf)
			if(length("[blocker_error]"))
				result["error"] = blocker_error
				return result

	var/list/boundary = GLOB.world_edit_placement_shapes.world_edit_collect_boundary_turfs(footprint)
	if(length(boundary) < 3)
		result["error"] = "Unable to resolve building exterior boundary."
		return result

	var/list/boundary_lookup = GLOB.world_edit_placement_shapes.world_edit_build_turf_lookup(boundary)
	var/list/interior = list()
	for(var/turf/interior_turf as anything in footprint)
		if(boundary_lookup[interior_turf])
			continue
		interior += interior_turf

	result["bounds"] = list("min_x" = min_x, "max_x" = max_x, "min_y" = min_y, "max_y" = max_y, "width" = width, "height" = height, "z" = z_level)
	result["boundary"] = boundary
	result["interior"] = interior
	result["footprint_lookup"] = footprint_lookup
	return result

/datum/world_edit_generator/building_layout/proc/get_footprint_blocker_error(turf/target_turf)
	if(!istype(target_turf))
		return "Footprint contains an invalid turf."
	if(target_turf.density)
		return "Footprint intersects dense turf [GLOB.world_edit_helpers.turf_to_text(target_turf)]."
	for(var/atom/movable/blocker as anything in target_turf)
		if(ismob(blocker))
			continue
		if(blocker.density)
			return "Footprint intersects dense object at [GLOB.world_edit_helpers.turf_to_text(target_turf)]."
	return null

/datum/world_edit_generator/building_layout/proc/get_dir_component_x(direction)
	switch(direction)
		if(EAST)
			return 1
		if(WEST)
			return -1
	return 0

/datum/world_edit_generator/building_layout/proc/get_dir_component_y(direction)
	switch(direction)
		if(NORTH)
			return 1
		if(SOUTH)
			return -1
	return 0

/datum/world_edit_generator/building_layout/proc/get_projection_for_dir(turf/target_turf, center_x, center_y, direction)
	if(!istype(target_turf))
		return -999999
	return ((target_turf.x - center_x) * get_dir_component_x(direction)) + ((target_turf.y - center_y) * get_dir_component_y(direction))

/datum/world_edit_generator/building_layout/proc/get_lateral_distance_for_dir(turf/target_turf, center_x, center_y, direction)
	if(direction in list(NORTH, SOUTH))
		return abs(target_turf.x - center_x)
	return abs(target_turf.y - center_y)

/datum/world_edit_generator/building_layout/proc/get_side_axis_positive_dir(direction)
	if(direction in list(NORTH, SOUTH))
		return EAST
	return NORTH

/datum/world_edit_generator/building_layout/proc/get_side_axis_negative_dir(direction)
	if(direction in list(NORTH, SOUTH))
		return WEST
	return SOUTH

/datum/world_edit_generator/building_layout/proc/boundary_turf_has_outside_dir(turf/target_turf, list/footprint_lookup, direction)
	if(!istype(target_turf) || !islist(footprint_lookup))
		return FALSE
	var/turf/nearby_turf = get_step(target_turf, direction)
	return !footprint_lookup[nearby_turf]

/datum/world_edit_generator/building_layout/proc/get_side_run_length(turf/target_turf, list/side_lookup, direction)
	if(!istype(target_turf) || !islist(side_lookup) || !side_lookup[target_turf])
		return 0
	var/run_length = 1
	var/positive_dir = get_side_axis_positive_dir(direction)
	var/negative_dir = get_side_axis_negative_dir(direction)
	var/turf/check_turf = get_step(target_turf, positive_dir)
	while(side_lookup[check_turf])
		run_length++
		check_turf = get_step(check_turf, positive_dir)
	check_turf = get_step(target_turf, negative_dir)
	while(side_lookup[check_turf])
		run_length++
		check_turf = get_step(check_turf, negative_dir)
	return run_length

/datum/world_edit_generator/building_layout/proc/select_boundary_turf_for_dir(list/boundary, center_x, center_y, direction, list/excluded_lookup = null, list/footprint_lookup = null)
	var/list/side_lookup = list()
	if(islist(footprint_lookup))
		for(var/turf/boundary_turf as anything in boundary)
			if(!istype(boundary_turf) || (islist(excluded_lookup) && excluded_lookup[boundary_turf]))
				continue
			if(boundary_turf_has_outside_dir(boundary_turf, footprint_lookup, direction))
				side_lookup[boundary_turf] = TRUE

	var/turf/best_turf = null
	var/best_score = -999999999
	for(var/turf/boundary_turf as anything in boundary)
		if(!istype(boundary_turf) || (islist(excluded_lookup) && excluded_lookup[boundary_turf]))
			continue
		var/projection = get_projection_for_dir(boundary_turf, center_x, center_y, direction)
		var/lateral = get_lateral_distance_for_dir(boundary_turf, center_x, center_y, direction)
		var/exact_side = side_lookup[boundary_turf]
		var/run_length = exact_side ? get_side_run_length(boundary_turf, side_lookup, direction) : 0
		var/score = (projection * 100) - (lateral * 10)
		if(exact_side)
			score += 100000
		if(run_length >= 3)
			score += 30000 + (min(run_length, 8) * 1000)
		else if(run_length)
			score += run_length * 500
		if(islist(footprint_lookup) && is_corner_boundary_turf(boundary_turf, footprint_lookup))
			score -= 20000
		if(!istype(best_turf) || score > best_score)
			best_turf = boundary_turf
			best_score = score
	return best_turf

/datum/world_edit_generator/building_layout/proc/get_outward_dir(turf/target_turf, list/footprint_lookup, center_x, center_y, preferred_dir = NORTH)
	if(!istype(target_turf))
		return preferred_dir
	var/list/outside_dirs = list()
	for(var/check_dir in GLOB.cardinals)
		var/turf/nearby_turf = get_step(target_turf, check_dir)
		if(footprint_lookup[nearby_turf])
			continue
		outside_dirs += check_dir
	if(!length(outside_dirs))
		return preferred_dir
	if(preferred_dir in outside_dirs)
		return preferred_dir

	var/best_dir = outside_dirs[1]
	var/best_score = -999999
	for(var/outside_dir in outside_dirs)
		var/score = (get_dir_component_x(outside_dir) * (target_turf.x - center_x)) + (get_dir_component_y(outside_dir) * (target_turf.y - center_y))
		if(score > best_score)
			best_score = score
			best_dir = outside_dir
	return best_dir

/datum/world_edit_generator/building_layout/proc/is_corner_boundary_turf(turf/target_turf, list/footprint_lookup)
	if(!istype(target_turf) || !islist(footprint_lookup))
		return FALSE
	var/outside_count = 0
	for(var/check_dir in GLOB.cardinals)
		var/turf/nearby_turf = get_step(target_turf, check_dir)
		if(!footprint_lookup[nearby_turf])
			outside_count++
	return outside_count >= 2

/datum/world_edit_generator/building_layout/proc/append_unique_turf(list/target_list, list/target_lookup, turf/target_turf)
	if(!istype(target_turf) || target_lookup[target_turf])
		return FALSE
	target_list += target_turf
	target_lookup[target_turf] = TRUE
	return TRUE

/datum/world_edit_generator/building_layout/proc/build_turf_placement(kind, turf/target_turf, turf_path)
	return list(
		"kind" = kind,
		"turf" = target_turf,
		"x" = target_turf.x,
		"y" = target_turf.y,
		"z" = target_turf.z,
		"turf_path" = turf_path,
	)

/datum/world_edit_generator/building_layout/proc/build_object_placement(kind, turf/target_turf, obj_path, dir_to_use)
	return list(
		"kind" = kind,
		"turf" = target_turf,
		"x" = target_turf.x,
		"y" = target_turf.y,
		"z" = target_turf.z,
		"obj_path" = obj_path,
		"dir" = dir_to_use,
	)

/datum/world_edit_generator/building_layout/proc/get_cardinal_dir_toward(turf/source_turf, turf/target_turf, fallback_dir = SOUTH)
	if(!istype(source_turf) || !istype(target_turf))
		return fallback_dir
	var/dx = target_turf.x - source_turf.x
	var/dy = target_turf.y - source_turf.y
	if(abs(dx) >= abs(dy) && dx)
		return dx > 0 ? EAST : WEST
	if(dy)
		return dy > 0 ? NORTH : SOUTH
	return fallback_dir

/datum/world_edit_generator/building_layout/proc/select_center_floor_turf(list/floor_turfs, center_x, center_y)
	var/turf/best_turf = null
	var/best_distance = 999999
	for(var/turf/floor_turf as anything in floor_turfs)
		if(!istype(floor_turf))
			continue
		var/distance = abs(floor_turf.x - center_x) + abs(floor_turf.y - center_y)
		if(!istype(best_turf) || distance < best_distance)
			best_turf = floor_turf
			best_distance = distance
	return best_turf

/datum/world_edit_generator/building_layout/proc/build_reserved_path(turf/start_turf, turf/end_turf, list/floor_lookup)
	var/list/reserved = list()
	if(!istype(start_turf) || !istype(end_turf) || !islist(floor_lookup))
		return reserved

	var/list/queue = list(start_turf)
	var/list/visited = list()
	var/list/previous = list()
	visited[start_turf] = TRUE
	var/index = 1
	while(index <= length(queue))
		var/turf/current_turf = queue[index++]
		if(current_turf == end_turf)
			break
		for(var/check_dir in GLOB.cardinals)
			var/turf/nearby_turf = get_step(current_turf, check_dir)
			if(!floor_lookup[nearby_turf] || visited[nearby_turf])
				continue
			visited[nearby_turf] = TRUE
			previous[nearby_turf] = current_turf
			queue += nearby_turf

	if(!visited[end_turf])
		return list(start_turf, end_turf)

	var/turf/path_turf = end_turf
	while(istype(path_turf))
		reserved.Insert(1, path_turf)
		if(path_turf == start_turf)
			break
		path_turf = previous[path_turf]
	return reserved

/datum/world_edit_generator/building_layout/proc/build_reserved_paths(list/door_turfs, turf/center_turf, list/floor_lookup)
	var/list/reserved = list()
	var/list/reserved_lookup = list()
	if(!islist(door_turfs) || !istype(center_turf) || !islist(floor_lookup))
		return reserved
	for(var/turf/door_turf as anything in door_turfs)
		if(!istype(door_turf))
			continue
		var/list/door_path = build_reserved_path(door_turf, center_turf, floor_lookup)
		for(var/turf/path_turf as anything in door_path)
			append_unique_turf(reserved, reserved_lookup, path_turf)
		for(var/check_dir in GLOB.cardinals)
			var/turf/nearby_turf = get_step(door_turf, check_dir)
			if(floor_lookup[nearby_turf])
				append_unique_turf(reserved, reserved_lookup, nearby_turf)
	return reserved

/datum/world_edit_generator/building_layout/proc/resolve_interior_obj_path(list/config, slot)
	var/list/interior_paths = islist(config) ? config["interior_paths"] : null
	var/path_value = islist(interior_paths) ? interior_paths["[slot]"] : null
	if(isnull(path_value))
		switch("[slot]")
			if("medical_bed")
				path_value = interior_paths?["bed"]
			if("medical_storage", "crate")
				path_value = interior_paths?["cabinet"]
			if("hydro_tray", "sleeper", "medical_scanner", "wall_monitor", "fridge", "microwave", "processor", "sink", "security_console", "security_camera", "brig_cell", "weapon_rack", "water_tank", "seed_storage", "engineering_machine", "power_console", "lab_machine")
				path_value = interior_paths?["table"]
			if("fridge", "filing", "sample_storage")
				path_value = interior_paths?["cabinet"]
			if("wall_monitor", "security_console", "console", "power_console")
				path_value = interior_paths?["table"]
			if("light", "apc", "air_alarm", "fire_alarm", "light_switch")
				path_value = interior_paths?["[slot]"] || interior_paths?["console"] || interior_paths?["table"]
			else
				path_value = interior_paths?["table"]
	return resolve_building_type_path(path_value, /obj)

/datum/world_edit_generator/building_layout/proc/build_building_candidate_request(datum/world_edit_building_request/base_request, footprint_family, attempt_index)
	var/datum/world_edit_building_request/request = new
	request.config = base_request.config.Copy()
	request.config["forced_footprint_family"] = uppertext("[footprint_family]")
	request.config["layout_candidate_index"] = attempt_index
	request.config["layout_candidate_family"] = uppertext("[footprint_family]")
	request.archetype = base_request.archetype
	request.effective_seed = base_request.effective_seed
	var/candidate_seed = build_stage_seed(base_request.effective_seed, "candidate_[attempt_index]_[footprint_family]")
	request.program_rng = new /datum/world_edit_building_prng(build_stage_seed(candidate_seed, "program"))
	request.geometry_rng = new /datum/world_edit_building_prng(build_stage_seed(candidate_seed, "geometry"))
	request.fixture_rng = new /datum/world_edit_building_prng(build_stage_seed(candidate_seed, "fixtures"))
	request.facade_rng = new /datum/world_edit_building_prng(build_stage_seed(candidate_seed, "facade"))
	request.microvariation_rng = new /datum/world_edit_building_prng(build_stage_seed(candidate_seed, "microvariation"))
	return request

/datum/world_edit_generator/building_layout/proc/build_building_layout_candidate_state(datum/world_edit_building_request/request, datum/world_edit_shape_contract/shape_contract, list/params, list/placement_context)
	var/list/footprint_result = resolve_shape_footprint(shape_contract, request.config, params, placement_context)
	if(footprint_result["error"])
		request.config["layout_candidate_error"] = "[footprint_result["error"]]"
		return null
	var/list/validated = validate_footprint(footprint_result["footprint"], request.config)
	if(validated["error"])
		request.config["layout_candidate_error"] = "[validated["error"]]"
		return null

	var/datum/world_edit_building_layout_state/state = build_building_layout_state(request, shape_contract, placement_context, validated)
	extract_building_anchors(state)
	run_building_semantic_slot_preflight(state)
	place_building_infrastructure(state)
	place_building_fixtures(state)
	apply_building_facade_rules(state)
	validate_and_repair_building_layout_state(state)
	apply_building_microvariation_if_available(state)
	apply_building_layout_macro_overlays(state)
	calculate_building_style_metrics(state)
	state.layout_candidate_score = score_building_layout_candidate(state)
	return state

/datum/world_edit_generator/building_layout/proc/calculate_building_style_metrics(datum/world_edit_building_layout_state/state)
	if(!istype(state))
		return
	var/list/expected_categories = list()
	var/list/object_budgets = islist(state.semantic_plan?.object_budgets) ? state.semantic_plan.object_budgets : state.archetype?.object_budgets
	if(islist(object_budgets))
		for(var/category as anything in object_budgets)
			if((round(text2num("[object_budgets[category]]") || 0)) > 0)
				expected_categories["[category]"] = TRUE
	if(islist(state.semantic_plan?.category_minimums))
		for(var/category as anything in state.semantic_plan.category_minimums)
			if((round(text2num("[state.semantic_plan.category_minimums[category]]") || 0)) > 0)
				expected_categories["[category]"] = TRUE

	var/covered_categories = 0
	for(var/category as anything in expected_categories)
		if((state.category_counts["[category]"] || 0) > 0)
			covered_categories++
	state.category_coverage_score = length(expected_categories) ? round(covered_categories * 100 / length(expected_categories)) : 100

	var/highest_category_count = 0
	for(var/category as anything in state.category_counts)
		highest_category_count = max(highest_category_count, round(text2num("[state.category_counts[category]]") || 0))
	state.repeat_index = state.fixture_count > 0 ? round(highest_category_count * 100 / state.fixture_count) : 0

	state.repetition_conflict_count = 0
	var/list/repeat_penalties = islist(state.semantic_plan?.repeat_penalties) ? state.semantic_plan.repeat_penalties : list()
	for(var/category as anything in repeat_penalties)
		var/list/repeat_rule = islist(repeat_penalties[category]) ? repeat_penalties[category] : list()
		var/soft_percent = round(text2num("[repeat_rule["soft_percent"]]") || 55)
		var/category_count = round(text2num("[state.category_counts["[category]"]]") || 0)
		if(state.fixture_count > 0 && category_count > 0 && round(category_count * 100 / state.fixture_count) > soft_percent)
			state.repetition_conflict_count++

	var/list/style_budget = islist(state.semantic_plan?.style_budget) ? state.semantic_plan.style_budget : list()
	var/max_repeat_index = round(text2num("[style_budget["max_repeat_index"]]") || 55)
	var/repeat_penalty = max(0, state.repeat_index - max_repeat_index)
	state.style_score = clamp(state.category_coverage_score - repeat_penalty, 0, 100)
	calculate_building_quality_metrics(state)

/datum/world_edit_generator/building_layout/proc/calculate_building_quality_metrics(datum/world_edit_building_layout_state/state)
	if(!istype(state))
		return
	var/list/style_budget = islist(state.semantic_plan?.style_budget) ? state.semantic_plan.style_budget : list()
	var/list/reachable = build_building_reachable_floor_lookup(state)
	var/reachable_floor = 0
	for(var/turf/floor_turf as anything in state.floor_turfs)
		if(reachable[floor_turf])
			reachable_floor++
	state.connectivity_score = length(state.floor_turfs) ? round(reachable_floor * 100 / length(state.floor_turfs)) : 0

	var/usable_area = max(state.usable_fixture_area, length(state.floor_turfs) - length(state.primary_route_turfs), 1)
	var/fixture_density = round(state.fixture_count * 100 / usable_area)
	var/ideal_density = round(text2num("[style_budget["ideal_fixture_density"]]") || 38)
	var/max_density_delta = max(ideal_density, 1)
	state.fixture_density_score = clamp(100 - round(abs(fixture_density - ideal_density) * 100 / max_density_delta), 0, 100)

	state.visibility_privacy_score = clamp(100 - (state.privacy_violation_count * 18) - (state.window_conflict_count * 10) - (state.facade_conflict_count * 8), 0, 100)
	state.space_distribution_score = clamp(100 - state.empty_floor_ratio + min(length(state.solved_regions), 8) * 4, 0, 100)

/datum/world_edit_generator/building_layout/proc/score_building_layout_candidate(datum/world_edit_building_layout_state/state)
	if(!istype(state))
		return -999999999
	var/score = 0
	var/error_count = length(state.errors)
	if(!error_count)
		score += 50000
	else
		score -= error_count * 20000
	score += state.signature_score * 120
	score += state.style_score * 45
	score += state.connectivity_score * 35
	score += state.fixture_density_score * 20
	score += state.visibility_privacy_score * 25
	score += state.space_distribution_score * 15
	if(state.signature_max_score > 0 && state.signature_score >= state.semantic_plan?.min_signature_score)
		score += 2500
	score += length(state.divider_plans) * 900
	score += min(length(state.internal_wall_turfs), 32) * 90
	score += length(state.solved_regions) * 120
	score += min(state.region_claim_count, 80) * 45
	score += min(state.rectangular_region_candidate_count, 80) * 22
	score += state.nested_room_count * 800
	score += state.template_chunk_count * 650
	score += state.infrastructure_count * 220
	score += min(state.semantic_slot_capacity_count, 80) * 35
	score += min(state.microvariation_count, 24) * 20
	score += round(text2num("[state.config["footprint_mask_score"]]") || 0)
	score += length(state.primary_route_turfs) * 15
	score -= state.empty_floor_ratio * 35
	if(state.repeat_index > 75)
		score -= (state.repeat_index - 75) * 80
	score -= state.privacy_violation_count * 1800
	score -= state.reachability_failure_count * 1400
	score -= state.repetition_conflict_count * 500
	score -= state.degraded_region_fallback_count * 2500
	score -= state.semantic_slot_shortage_count * 18000
	score -= state.semantic_slot_fallback_count * 3500
	score -= state.semantic_slot_reservation_conflict_count * 12000
	score -= (state.fixture_conflict_count + state.route_conflict_count + state.window_conflict_count + state.facade_conflict_count) * 900
	if("[state.config["footprint_family"]]" != "RECT")
		score += 1800
	if(state.empty_floor_ratio <= 60)
		score += 800
	var/list/major_specs = state.semantic_plan?.get_cluster_specs("major")
	if(islist(major_specs) && state.major_fixture_count >= length(major_specs))
		score += 1000
	return score

/datum/world_edit_generator/building_layout/proc/build_building_layout_candidate_report(datum/world_edit_building_layout_state/state, footprint_family, attempt_index, score_override = null, error_message = null)
	var/list/report = list(
		"attempt" = attempt_index,
		"family" = uppertext("[footprint_family]"),
		"score" = isnull(score_override) && istype(state) ? state.layout_candidate_score : score_override,
	)
	if(istype(state))
		report["errors"] = state.errors.Copy()
		report["error_count"] = length(state.errors)
		report["signature_score"] = state.signature_score
		report["style_score"] = state.style_score
		report["category_coverage_score"] = state.category_coverage_score
		report["repeat_index"] = state.repeat_index
		report["privacy_violation_count"] = state.privacy_violation_count
		report["reachability_failure_count"] = state.reachability_failure_count
		report["repetition_conflict_count"] = state.repetition_conflict_count
		report["fixture_density_score"] = state.fixture_density_score
		report["connectivity_score"] = state.connectivity_score
		report["visibility_privacy_score"] = state.visibility_privacy_score
		report["space_distribution_score"] = state.space_distribution_score
		report["empty_floor_ratio"] = state.empty_floor_ratio
		report["divider_plan_count"] = length(state.divider_plans)
		report["internal_wall_count"] = length(state.internal_wall_turfs)
		report["semantic_region_claim_count"] = state.region_claim_count
		report["semantic_region_claim_reports"] = state.region_claim_reports.Copy()
		report["rectangular_region_candidate_count"] = state.rectangular_region_candidate_count
		report["nested_room_count"] = state.nested_room_count
		report["template_chunk_count"] = state.template_chunk_count
		report["template_chunk_cell_count"] = state.template_chunk_cell_count
		report["infrastructure_count"] = state.infrastructure_count
		report["semantic_slot_capacity_count"] = state.semantic_slot_capacity_count
		report["semantic_slot_shortage_count"] = state.semantic_slot_shortage_count
		report["semantic_slot_fallback_count"] = state.semantic_slot_fallback_count
		report["semantic_slot_reports"] = state.semantic_slot_reports.Copy()
		report["semantic_requirement_counts"] = state.semantic_requirement_counts.Copy()
		report["semantic_requirement_minimums"] = state.semantic_requirement_minimums.Copy()
		report["semantic_slot_reservation_count"] = length(state.semantic_slot_reservation_by_turf)
		report["semantic_slot_reservation_conflict_count"] = state.semantic_slot_reservation_conflict_count
		report["degraded_region_fallback_count"] = state.degraded_region_fallback_count
		report["degraded_region_reports"] = state.degraded_region_reports.Copy()
		report["microvariation_count"] = state.microvariation_count
		report["footprint_mask_score"] = state.config["footprint_mask_score"]
		report["footprint_mask_candidate_count"] = state.config["footprint_mask_candidate_count"]
		report["major_fixture_count"] = state.major_fixture_count
		report["footprint_count"] = length(state.footprint)
	else
		report["errors"] = list("[error_message]")
		report["error_count"] = 1
	return report

/datum/world_edit_generator/building_layout/build_plan_from_shape_contract(mob/user, datum/world_edit_shape_contract/shape_contract, list/params, list/placement_context)
	var/datum/world_edit_plan/plan = new
	var/datum/world_edit_building_request/request = build_building_request(params, shape_contract, placement_context)
	if(request.config["error"])
		plan.metadata["error"] = "[request.config["error"]]"
		finalize_shared_placement_plan_metadata(plan, shape_contract, placement_context)
		return plan
	if(shape_contract?.error)
		plan.metadata["error"] = "[shape_contract.error]"
		finalize_shared_placement_plan_metadata(plan, shape_contract, placement_context)
		return plan

	var/shape_id = "[shape_contract?.shape_id || placement_context["shape"] || WORLD_EDIT_SHAPE_POINT]"
	var/list/candidate_families = (shape_id != WORLD_EDIT_SHAPE_POINT) ? list(uppertext("[shape_id]")) : get_ordered_building_footprint_candidate_families(request.config)
	var/list/candidate_reports = list()
	var/datum/world_edit_building_layout_state/best_state = null
	var/best_score = -999999999
	var/attempt_index = 0
	for(var/footprint_family as anything in candidate_families)
		attempt_index++
		var/datum/world_edit_building_request/candidate_request = build_building_candidate_request(request, footprint_family, attempt_index)
		var/datum/world_edit_building_layout_state/candidate_state = build_building_layout_candidate_state(candidate_request, shape_contract, params, placement_context)
		if(!istype(candidate_state))
			var/error_message = candidate_request.config["layout_candidate_error"] || "Candidate layout failed before semantic state."
			candidate_reports += list(build_building_layout_candidate_report(null, footprint_family, attempt_index, -999999999 + attempt_index, error_message))
			continue
		candidate_reports += list(build_building_layout_candidate_report(candidate_state, footprint_family, attempt_index))
		if(!istype(best_state) || candidate_state.layout_candidate_score > best_score)
			best_state = candidate_state
			best_score = candidate_state.layout_candidate_score

	if(!istype(best_state))
		plan.metadata["error"] = "Unable to build any building layout candidate."
		plan.metadata["layout_candidate_reports"] = candidate_reports
		plan.metadata["layout_candidate_count"] = length(candidate_reports)
		finalize_shared_placement_plan_metadata(plan, shape_contract, placement_context)
		return plan

	best_state.config["layout_candidate_reports"] = candidate_reports
	best_state.config["layout_candidate_count"] = length(candidate_reports)
	best_state.config["layout_candidate_score"] = best_score
	return emit_building_layout_plan(best_state, shape_contract, placement_context)

/datum/world_edit_generator/building_layout/build_placement_plan(mob/user, list/params, list/placement_context)
	var/datum/world_edit_shape_contract/shape_contract = build_shape_contract_from_placement_context(placement_context["shape"], placement_context["anchor_turfs"], placement_context)
	return build_plan_from_shape_contract(user, shape_contract, params, placement_context)

/datum/world_edit_generator/building_layout/build_plan(list/params)
	var/turf/anchor_turf = manager?.placement_anchor_turf
	if(!istype(anchor_turf))
		anchor_turf = get_turf(manager?.holder?.mob)
	var/datum/world_edit_plan/error_plan
	if(!istype(anchor_turf))
		error_plan = new
		error_plan.metadata["error"] = "Unable to resolve building anchor turf."
		return error_plan

	var/shape_id = manager?.get_effective_placement_shape() || WORLD_EDIT_SHAPE_POINT
	var/placement_dir = manager?.get_effective_placement_dir() || NORTH
	var/list/shape_result = GLOB.world_edit_placement_shapes.world_edit_build_shape_turfs(shape_id, anchor_turf, null, params, placement_dir)
	if(shape_result["error"])
		error_plan = new
		error_plan.metadata["error"] = "[shape_result["error"]]"
		return error_plan
	return build_placement_plan(manager?.holder?.mob, params, list(
		"mode" = manager?.get_effective_placement_mode() || "single",
		"shape" = shape_id,
		"shape_metadata" = shape_result["metadata"] || list(),
		"anchor_turfs" = shape_result["turfs"] || list(anchor_turf),
		"start_turf" = anchor_turf,
		"end_turf" = anchor_turf,
		"shape_origin_turf" = anchor_turf,
		"seed_turf" = anchor_turf,
		"requested_end_turf" = anchor_turf,
		"resolved_end_turf" = anchor_turf,
		"direction" = placement_dir,
	))

/datum/world_edit_generator/building_layout/proc/build_building_preview_spec_from_placement(list/placement)
	if(!islist(placement))
		return null
	var/kind = "[placement["kind"]]"
	var/turf/target_turf = placement["turf"]
	if(!istype(target_turf))
		return null
	if(kind in list("floor", "wall"))
		var/turf_path = placement["turf_path"]
		if(!ispath(turf_path, /turf))
			return null
		var/turf/preview_turf = turf_path
		var/list/turf_spec = GLOB.world_edit_helpers.build_world_edit_preview_object_spec(
			target_turf,
			initial(preview_turf.icon),
			initial(preview_turf.icon_state),
			SOUTH,
			initial(preview_turf.layer),
			initial(preview_turf.plane),
			0,
			0,
			kind == "floor" ? 210 : 235
		)
		if(islist(turf_spec))
			turf_spec["kind"] = kind
		return turf_spec
	if(kind in list("door", "window", "interior", "microvariation"))
		var/obj_path = placement["obj_path"]
		if(!ispath(obj_path, /obj))
			return null
		var/list/object_spec = GLOB.world_edit_helpers.build_world_edit_atom_preview_spec(obj_path, target_turf, placement["dir"])
		if(islist(object_spec))
			object_spec["kind"] = kind
		return object_spec
	return null

/datum/world_edit_generator/building_layout/build_plan_preview_object_specs(datum/world_edit_plan/plan, list/runtime_params = null, list/placement_context = null, hover_only = FALSE)
	var/list/specs = list()
	if(!istype(plan))
		return specs
	var/spec_limit = hover_only ? WORLD_EDIT_BUILDING_MAX_HOVER_PREVIEW_OBJECT_SPECS : WORLD_EDIT_BUILDING_MAX_PREVIEW_OBJECT_SPECS
	for(var/list/placement as anything in plan.placements)
		if(length(specs) >= spec_limit)
			break
		var/list/spec = build_building_preview_spec_from_placement(placement)
		if(islist(spec))
			specs += list(spec)
	return specs

/datum/world_edit_generator/building_layout/should_render_preview_via_placement_layers(datum/world_edit_plan/plan)
	return istype(plan) ? TRUE : FALSE

/datum/world_edit_generator/building_layout/should_skip_plan_build_for_hover_only_placement(datum/world_edit_shape_contract/shape_contract, list/runtime_params = null, list/placement_context = null)
	return TRUE

/datum/world_edit_generator/building_layout/should_build_hover_object_preview_plan(datum/world_edit_shape_contract/shape_contract, list/runtime_params = null, list/placement_context = null)
	return FALSE

/datum/world_edit_generator/building_layout/get_hover_object_preview_anchor_limit()
	return 2

/datum/world_edit_generator/building_layout/preview(mob/user, list/params)
	var/datum/world_edit_preview_result/result = new
	clear_built_plan()

	var/datum/world_edit_plan/plan = build_plan(params)
	if(!istype(plan))
		result.message = "Unable to build building plan."
		return result
	if(plan.metadata["error"])
		result.message = "[plan.metadata["error"]]"
		return result
	if(!length(plan.placements))
		result.message = "Building plan is empty."
		return result

	current_plan = plan
	result.success = TRUE
	if(!manager?.should_use_placement_layer_preview(plan))
		result.preview_images = GLOB.world_edit_helpers.build_turf_preview_images(plan.affected_turfs)
		result.preview_images += GLOB.world_edit_helpers.build_preview_images_from_specs(build_plan_preview_object_specs(plan, params))
	result.meta = plan.metadata.Copy()
	result.message = "Building preview ready: program=[plan.metadata["archetype_id"]], shape=[plan.metadata["placement_shape_id"]], source=[plan.metadata["footprint_source"]], family=[plan.metadata["footprint_family"]], candidates=[plan.metadata["layout_candidate_count"]], score=[plan.metadata["layout_candidate_score"]], signature=[plan.metadata["signature_score"]]/100, slots=[plan.metadata["semantic_slot_capacity_count"]] shortage=[plan.metadata["semantic_slot_shortage_count"]] fallback=[plan.metadata["semantic_slot_fallback_count"]], reservations=[plan.metadata["semantic_slot_reservation_count"]] conflicts=[plan.metadata["semantic_slot_reservation_conflict_count"]], rects=[plan.metadata["rectangular_region_candidate_count"]], claims=[plan.metadata["semantic_region_claim_count"]], nested=[plan.metadata["nested_room_count"]], chunks=[plan.metadata["template_chunk_count"]], infra=[plan.metadata["infrastructure_count"]], detail=[plan.metadata["microvariation_count"]], footprint=[plan.metadata["footprint_count"]], walls=[plan.metadata["wall_count"]], doors=[plan.metadata["door_count"]], windows=[plan.metadata["window_count"]], interior=[plan.metadata["interior_object_count"]], empty=[plan.metadata["empty_floor_ratio"]]%."
	return result

/datum/world_edit_generator/building_layout/apply(mob/user, list/params)
	return apply_plan(user, params, current_plan)

/datum/world_edit_generator/building_layout/proc/runtime_target_turf(list/placement)
	var/x_value = text2num("[placement["x"]]")
	var/y_value = text2num("[placement["y"]]")
	var/z_value = text2num("[placement["z"]]")
	return locate(x_value, y_value, z_value)

/datum/world_edit_generator/building_layout/proc/placement_coord_key(list/placement)
	if(!islist(placement))
		return null
	return "[placement["x"]],[placement["y"]],[placement["z"]]"

/datum/world_edit_generator/building_layout/proc/has_runtime_object_blocker(turf/target_turf, obj_path = null)
	if(!istype(target_turf))
		return TRUE
	if(target_turf.density && !GLOB.world_edit_blueprints.world_edit_can_place_blueprint_wall_detail(target_turf, obj_path))
		return TRUE
	for(var/atom/movable/blocker as anything in target_turf)
		if(ismob(blocker))
			continue
		if(blocker.density)
			return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/get_runtime_footprint_blocker_error(datum/world_edit_plan/plan)
	if(!istype(plan))
		return "Building plan is unavailable."
	var/list/checked_lookup = list()
	for(var/list/placement as anything in plan.placements)
		var/kind = "[placement["kind"]]"
		if(!(kind in list("floor", "wall", "door", "window", "interior", "microvariation")))
			continue
		var/key = placement_coord_key(placement)
		if(checked_lookup[key])
			continue
		checked_lookup[key] = TRUE
		var/turf/check_turf = runtime_target_turf(placement)
		var/blocker_error = get_footprint_blocker_error(check_turf)
		if(length("[blocker_error]"))
			return blocker_error
	return null

/datum/world_edit_generator/building_layout/apply_plan(mob/user, list/params, datum/world_edit_plan/plan)
	var/datum/world_edit_apply_result/result = new
	if(!istype(plan))
		result.message = "Run building preview first."
		return result
	if(plan.metadata["error"])
		result.message = "[plan.metadata["error"]]"
		return result

	var/list/config = normalize_building_params(params)
	if(config["respect_blockers"])
		var/runtime_blocker_error = get_runtime_footprint_blocker_error(plan)
		if(length("[runtime_blocker_error]"))
			result.message = "[runtime_blocker_error]"
			return result

	var/datum/world_edit_changeset/changeset = new /datum/world_edit_changeset(definition?.id || "building_layout", WORLD_EDIT_UNDO_FULL, list(
		"center_turf" = plan.metadata["center_turf"],
		"archetype_id" = plan.metadata["archetype_id"],
		"faction_preset" = plan.metadata["faction_preset"],
		"effective_seed" = plan.metadata["effective_seed"],
		"placement_mode" = plan.metadata["placement_mode"],
		"placement_dir" = plan.metadata["placement_dir"],
	))

	var/changed_turf_count = 0
	var/created_object_count = 0
	var/skipped_runtime = 0
	var/list/skipped_turf_lookup = list()
	var/replace_blocked_turfs = config["replace_blocked_turfs"]
	for(var/list/placement as anything in plan.placements)
		var/kind = "[placement["kind"]]"
		if(!(kind in list("floor", "wall")))
			continue
		var/turf/target_turf = runtime_target_turf(placement)
		var/coord_key = placement_coord_key(placement)
		var/turf_path = placement["turf_path"]
		if(!istype(target_turf) || !ispath(turf_path, /turf))
			skipped_runtime++
			if(length("[coord_key]"))
				skipped_turf_lookup[coord_key] = TRUE
			continue
		if(!replace_blocked_turfs && get_footprint_blocker_error(target_turf))
			skipped_runtime++
			if(length("[coord_key]"))
				skipped_turf_lookup[coord_key] = TRUE
			continue
		if(target_turf.type == turf_path)
			continue
		var/old_type = target_turf.type
		var/old_baseturfs = islist(target_turf.baseturfs) ? target_turf.baseturfs.Copy() : target_turf.baseturfs
		var/turf/new_turf = target_turf.ChangeTurf(turf_path)
		if(!istype(new_turf) || new_turf.type != turf_path)
			skipped_runtime++
			continue
		changed_turf_count++
		changeset.add_changed_turf(new_turf, old_type, turf_path, old_baseturfs, list("kind" = kind))

	for(var/list/placement as anything in plan.placements)
		var/kind = "[placement["kind"]]"
		if(!(kind in list("door", "window", "interior", "microvariation")))
			continue
		var/turf/target_turf = runtime_target_turf(placement)
		var/coord_key = placement_coord_key(placement)
		var/obj_path = placement["obj_path"]
		if(!istype(target_turf) || !ispath(obj_path, /obj))
			skipped_runtime++
			continue
		if(skipped_turf_lookup[coord_key])
			skipped_runtime++
			continue
		if(has_runtime_object_blocker(target_turf, obj_path))
			skipped_runtime++
			continue
		var/obj/created_object = new obj_path(target_turf)
		if(!created_object)
			skipped_runtime++
			continue
		var/dir_to_use = text2num("[placement["dir"]]")
		if(dir_to_use in GLOB.cardinals)
			created_object.setDir(dir_to_use)
		created_object_count++
		changeset.add_created(created_object, target_turf, list(
			"kind" = kind,
			"obj_path" = obj_path,
			"dir" = dir_to_use,
		))

	result.center_turf = plan.metadata["center_turf"]
	result.created_count = created_object_count
	result.meta = islist(plan.metadata) ? plan.metadata.Copy() : list()
	result.meta["changed_turf_count"] = changed_turf_count
	result.meta["created_object_count"] = created_object_count
	result.meta["skipped_runtime"] = skipped_runtime
	if(changed_turf_count <= 0 && created_object_count <= 0)
		result.message = "Building made no changes: runtime skipped=[skipped_runtime]."
		return result

	result.success = TRUE
	result.changeset = changeset
	result.message = "Building applied: turfs=[changed_turf_count], objects=[created_object_count], skipped=[skipped_runtime]."
	return result

#undef WORLD_EDIT_BUILDING_MAX_FOOTPRINT_TURFS
#undef WORLD_EDIT_BUILDING_MAX_PREVIEW_OBJECT_SPECS
#undef WORLD_EDIT_BUILDING_MAX_HOVER_PREVIEW_OBJECT_SPECS
#undef WORLD_EDIT_BUILDING_MAX_WINDOWS
#undef WORLD_EDIT_BUILDING_MAX_FIXTURE_OBJECTS
#undef WORLD_EDIT_BUILDING_MAX_CLUSTER_STEPS
#undef WORLD_EDIT_BUILDING_MAX_VALIDATION_ERRORS
#undef WORLD_EDIT_BUILDING_MAX_REPAIR_ATTEMPTS
#undef WORLD_EDIT_BUILDING_MAX_REGION_ASSIGNMENT_STEPS
#undef WORLD_EDIT_BUILDING_MAX_REGION_ASSIGNMENT_BRANCHES
#undef WORLD_EDIT_BUILDING_MAX_DIVIDER_RUN_ATTEMPTS
#undef WORLD_EDIT_BUILDING_MAX_ROOM_IN_ROOM_CANDIDATES
#undef WORLD_EDIT_BUILDING_AUTO_SEED
#undef WORLD_EDIT_BUILDING_HASH_MOD
