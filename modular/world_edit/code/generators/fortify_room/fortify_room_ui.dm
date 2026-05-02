/datum/world_edit_generator/fortify_room/proc/get_default_fortify_preset_id()
	return "legacy_metal"

/datum/world_edit_generator/fortify_room/proc/resolve_fortify_preset_id(raw_value)
	var/value_text = lowertext(trim("[raw_value]"))
	if(value_text in list(
		"legacy_wood",
		"legacy_sandbag",
		"legacy_sandbag_wired",
		"legacy_metal",
		"legacy_metal_wired",
		"legacy_plasteel",
		"legacy_plasteel_wired",
		"custom",
	))
		return value_text
	return null

/datum/world_edit_generator/fortify_room/proc/resolve_fortify_material_family(raw_value, door_family = FALSE)
	var/value_text = lowertext(trim("[raw_value]"))
	if(door_family)
		if(value_text in list("metal", "plasteel"))
			return value_text
		return null
	if(value_text in list("wood", "sandbag", "metal", "plasteel"))
		return value_text
	return null

/datum/world_edit_generator/fortify_room/proc/resolve_fortify_door_policy(raw_value)
	var/value_text = lowertext(trim("[raw_value]"))
	if(value_text in list("auto", "custom"))
		return value_text
	return null

/datum/world_edit_generator/fortify_room/proc/get_fortify_preset_recipe(preset_id)
	var/static/list/preset_recipes = list(
		"legacy_wood" = list(
			"material_family" = "wood",
			"material_wired" = FALSE,
		),
		"legacy_sandbag" = list(
			"material_family" = "sandbag",
			"material_wired" = FALSE,
		),
		"legacy_sandbag_wired" = list(
			"material_family" = "sandbag",
			"material_wired" = TRUE,
		),
		"legacy_metal" = list(
			"material_family" = "metal",
			"material_wired" = FALSE,
		),
		"legacy_metal_wired" = list(
			"material_family" = "metal",
			"material_wired" = TRUE,
		),
		"legacy_plasteel" = list(
			"material_family" = "plasteel",
			"material_wired" = FALSE,
		),
		"legacy_plasteel_wired" = list(
			"material_family" = "plasteel",
			"material_wired" = TRUE,
		),
	)
	return preset_recipes[preset_id]

/datum/world_edit_generator/fortify_room/proc/is_fortify_foldable_material(material_family)
	return "[material_family]" in list("metal", "plasteel")

/datum/world_edit_generator/fortify_room/proc/get_fortify_auto_door_family(material_family)
	return is_fortify_foldable_material(material_family) ? "[material_family]" : null

/datum/world_edit_generator/fortify_room/proc/apply_fortify_auto_door_defaults(list/params)
	if(!islist(params))
		return params

	var/auto_door_family = get_fortify_auto_door_family(params["material_family"])
	params["door_material_family"] = auto_door_family || "metal"
	params["door_wired"] = auto_door_family ? (GLOB.world_edit_helpers.parse_bool(params["material_wired"]) ? TRUE : FALSE) : FALSE
	return params

/datum/world_edit_generator/fortify_room/proc/normalize_fortify_params(list/params)
	var/list/normalized = islist(params) ? params.Copy() : list()
	var/preset_id = resolve_fortify_preset_id(normalized["preset_id"])
	if(!preset_id)
		preset_id = get_default_fortify_preset_id()

	if(preset_id != "custom")
		var/list/preset_recipe = get_fortify_preset_recipe(preset_id)
		normalized["preset_id"] = preset_id
		normalized["material_family"] = preset_recipe["material_family"] || "metal"
		normalized["material_wired"] = GLOB.world_edit_helpers.parse_bool(preset_recipe["material_wired"]) ? TRUE : FALSE
		normalized["door_policy"] = "auto"
		apply_fortify_auto_door_defaults(normalized)
	else
		var/material_family = resolve_fortify_material_family(normalized["material_family"]) || "metal"
		var/material_wired = GLOB.world_edit_helpers.parse_bool(normalized["material_wired"]) ? TRUE : FALSE
		var/door_policy = resolve_fortify_door_policy(normalized["door_policy"]) || "auto"
		var/door_material_family = resolve_fortify_material_family(normalized["door_material_family"], TRUE) || "metal"
		var/door_wired = GLOB.world_edit_helpers.parse_bool(normalized["door_wired"]) ? TRUE : FALSE

		normalized["preset_id"] = "custom"
		normalized["material_family"] = material_family
		normalized["material_wired"] = material_wired
		normalized["door_policy"] = door_policy
		normalized["door_material_family"] = door_material_family
		normalized["door_wired"] = door_wired
		if(door_policy == "auto")
			apply_fortify_auto_door_defaults(normalized)

	var/requested_cap = round(text2num("[normalized["room_tile_cap"]]"))
	if(!isnum(requested_cap) || requested_cap <= 0)
		requested_cap = WORLD_EDIT_FORTIFY_ROOM_TILE_CAP_DEFAULT
	normalized["room_tile_cap"] = clamp(requested_cap, WORLD_EDIT_FORTIFY_ROOM_TILE_CAP_MIN, WORLD_EDIT_FORTIFY_ROOM_TILE_CAP_MAX)

	normalized["treat_windows_as_boundary"] = isnull(normalized["treat_windows_as_boundary"]) ? TRUE : (GLOB.world_edit_helpers.parse_bool(normalized["treat_windows_as_boundary"]) ? TRUE : FALSE)
	normalized["fortify_windows"] = isnull(normalized["fortify_windows"]) ? TRUE : (GLOB.world_edit_helpers.parse_bool(normalized["fortify_windows"]) ? TRUE : FALSE)
	normalized["treat_doors_as_boundary"] = isnull(normalized["treat_doors_as_boundary"]) ? TRUE : (GLOB.world_edit_helpers.parse_bool(normalized["treat_doors_as_boundary"]) ? TRUE : FALSE)
	return normalized

/datum/world_edit_generator/fortify_room/proc/build_fortify_preset_options()
	return list(
		list("label" = "Legacy Wood", "value" = "legacy_wood"),
		list("label" = "Legacy Sandbag", "value" = "legacy_sandbag"),
		list("label" = "Legacy Sandbag Wired", "value" = "legacy_sandbag_wired"),
		list("label" = "Legacy Metal", "value" = "legacy_metal"),
		list("label" = "Legacy Metal Wired", "value" = "legacy_metal_wired"),
		list("label" = "Legacy Plasteel", "value" = "legacy_plasteel"),
		list("label" = "Legacy Plasteel Wired", "value" = "legacy_plasteel_wired"),
		list("label" = "Custom", "value" = "custom"),
	)

/datum/world_edit_generator/fortify_room/proc/build_fortify_material_options(door_family = FALSE)
	var/list/options = list()
	if(!door_family)
		options += list(
			list("label" = "Wood", "value" = "wood"),
			list("label" = "Sandbag", "value" = "sandbag"),
		)
	options += list(
		list("label" = "Metal", "value" = "metal"),
		list("label" = "Plasteel", "value" = "plasteel"),
	)
	return options

/datum/world_edit_generator/fortify_room/proc/build_fortify_door_policy_options()
	return list(
		list("label" = "Auto", "value" = "auto"),
		list("label" = "Custom", "value" = "custom"),
	)

/datum/world_edit_generator/fortify_room/get_ui_fields(list/current_params)
	var/list/params = normalize_fortify_params(current_params)
	var/custom_doors = "[params["door_policy"]]" == "custom"

	return list(
		list(
			"id" = "preset_id",
			"label" = "Preset",
			"kind" = "select",
			"group" = "Config",
			"value" = params["preset_id"],
			"options" = build_fortify_preset_options(),
		),
		list(
			"id" = "material_family",
			"label" = "Material",
			"kind" = "select",
			"group" = "Config",
			"value" = params["material_family"],
			"options" = build_fortify_material_options(),
		),
		list(
			"id" = "material_wired",
			"label" = "Wired",
			"kind" = "boolean",
			"group" = "Config",
			"value" = params["material_wired"],
		),
		list(
			"id" = "door_policy",
			"label" = "Door Policy",
			"kind" = "select",
			"group" = "Config",
			"value" = params["door_policy"],
			"options" = build_fortify_door_policy_options(),
		),
		list(
			"id" = "door_material_family",
			"label" = "Door Material",
			"kind" = "select",
			"group" = "Config",
			"value" = params["door_material_family"],
			"options" = build_fortify_material_options(TRUE),
			"visible" = custom_doors,
		),
		list(
			"id" = "door_wired",
			"label" = "Door Wired",
			"kind" = "boolean",
			"group" = "Config",
			"value" = params["door_wired"],
			"visible" = custom_doors,
		),
		list(
			"id" = "room_tile_cap",
			"label" = "Room Cap",
			"kind" = "number",
			"group" = "Bounds",
			"value" = params["room_tile_cap"],
			"min" = WORLD_EDIT_FORTIFY_ROOM_TILE_CAP_MIN,
			"max" = WORLD_EDIT_FORTIFY_ROOM_TILE_CAP_MAX,
			"step" = 1,
		),
		list(
			"id" = "treat_windows_as_boundary",
			"label" = "Windows Are Boundary",
			"kind" = "boolean",
			"group" = "Bounds",
			"value" = params["treat_windows_as_boundary"],
		),
		list(
			"id" = "fortify_windows",
			"label" = "Fortify Windows",
			"kind" = "boolean",
			"group" = "Bounds",
			"value" = params["fortify_windows"],
		),
		list(
			"id" = "treat_doors_as_boundary",
			"label" = "Doors Are Boundary",
			"kind" = "boolean",
			"group" = "Bounds",
			"value" = params["treat_doors_as_boundary"],
		),
	)

/datum/world_edit_generator/fortify_room/set_ui_param(mob/user, list/current_params, param_id, value)
	var/list/new_params = normalize_fortify_params(current_params)

	switch(param_id)
		if("preset_id")
			var/preset_id = resolve_fortify_preset_id(value)
			if(!preset_id)
				return "Invalid fortify preset."
			if(preset_id == "custom")
				new_params["preset_id"] = "custom"
				return new_params

			var/list/preset_recipe = get_fortify_preset_recipe(preset_id)
			new_params["preset_id"] = preset_id
			new_params["material_family"] = preset_recipe["material_family"] || "metal"
			new_params["material_wired"] = GLOB.world_edit_helpers.parse_bool(preset_recipe["material_wired"]) ? TRUE : FALSE
			new_params["door_policy"] = "auto"
			apply_fortify_auto_door_defaults(new_params)
			return new_params

		if("material_family")
			var/material_family = resolve_fortify_material_family(value)
			if(!material_family)
				return "Invalid fortify material."
			new_params["material_family"] = material_family
			new_params["preset_id"] = "custom"
			if("[new_params["door_policy"]]" == "auto")
				apply_fortify_auto_door_defaults(new_params)
			return new_params

		if("material_wired")
			new_params["material_wired"] = GLOB.world_edit_helpers.parse_bool(value) ? TRUE : FALSE
			new_params["preset_id"] = "custom"
			if("[new_params["door_policy"]]" == "auto")
				apply_fortify_auto_door_defaults(new_params)
			return new_params

		if("door_policy")
			var/door_policy = resolve_fortify_door_policy(value)
			if(!door_policy)
				return "Invalid fortify door policy."
			new_params["door_policy"] = door_policy
			new_params["preset_id"] = "custom"
			if(door_policy == "auto")
				apply_fortify_auto_door_defaults(new_params)
			else if(!resolve_fortify_material_family(new_params["door_material_family"], TRUE))
				new_params["door_material_family"] = "metal"
			return new_params

		if("door_material_family")
			var/door_material_family = resolve_fortify_material_family(value, TRUE)
			if(!door_material_family)
				return "Invalid fortify door material."
			new_params["preset_id"] = "custom"
			new_params["door_policy"] = "custom"
			new_params["door_material_family"] = door_material_family
			return new_params

		if("door_wired")
			new_params["preset_id"] = "custom"
			new_params["door_policy"] = "custom"
			new_params["door_wired"] = GLOB.world_edit_helpers.parse_bool(value) ? TRUE : FALSE
			return new_params

		if("room_tile_cap")
			new_params["room_tile_cap"] = clamp(round(text2num("[value]")), WORLD_EDIT_FORTIFY_ROOM_TILE_CAP_MIN, WORLD_EDIT_FORTIFY_ROOM_TILE_CAP_MAX)
			return new_params

		if("treat_windows_as_boundary", "fortify_windows", "treat_doors_as_boundary")
			new_params[param_id] = GLOB.world_edit_helpers.parse_bool(value) ? TRUE : FALSE
			return new_params

		else
			return ..()

/datum/world_edit_generator/fortify_room/get_apply_confirmation_text(list/params)
	var/list/config = resolve_fortify_configuration(params)
	if(config["error"])
		return "Apply Fortify Room?"
	return "Apply Fortify Room? material=[config["material_family"]], wired=[config["material_wired"]], cap=[config["room_tile_cap"]]."

/datum/world_edit_generator/fortify_room/get_params_short(list/params)
	var/list/config = resolve_fortify_configuration(params)
	return "preset=[config["preset_id"]] material=[config["material_family"]] wired=[config["material_wired"]] doors=[config["door_policy"]] door_material=[config["door_material_family"]] door_wired=[config["door_wired"]] cap=[config["room_tile_cap"]] windows_boundary=[config["treat_windows_as_boundary"]] fortify_windows=[config["fortify_windows"]] doors_boundary=[config["treat_doors_as_boundary"]] shape=[WORLD_EDIT_SHAPE_POINT] mode=[manager?.get_effective_placement_mode() || "single"]"
