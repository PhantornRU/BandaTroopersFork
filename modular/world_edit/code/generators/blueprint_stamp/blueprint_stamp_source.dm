/datum/world_edit_generator/blueprint_stamp/proc/resolve_shape_anchor_turf(mob/user)
	var/shape_id = manager?.get_effective_placement_shape() || WORLD_EDIT_SHAPE_POINT
	if(manager?.get_placement_interaction_kind(shape_id) == "collector")
		var/turf/collector_origin = manager?.get_placement_collector_origin_turf()
		if(istype(collector_origin))
			return collector_origin
	var/turf/anchor_turf = manager?.placement_anchor_turf
	if(istype(anchor_turf))
		return anchor_turf
	return get_turf(user)

/datum/world_edit_generator/blueprint_stamp/validate_params(mob/user, list/params)
	var/blueprint_id = sanitize_filename("[params["blueprint_id"]]")
	if(!length(blueprint_id))
		return "Сначала загрузите шаблон из серверной библиотеки."

	var/list/load_result = manager?.load_blueprint_definition_by_id(blueprint_id)
	if(load_result["error"])
		return "[load_result["error"]]"

	return null

/datum/world_edit_generator/blueprint_stamp/proc/load_active_blueprint(list/params)
	var/blueprint_id = sanitize_filename("[params["blueprint_id"]]")
	if(!length(blueprint_id))
		return list("error" = "Сначала загрузите шаблон из серверной библиотеки.")
	return manager?.load_blueprint_definition_by_id(blueprint_id) || list("error" = "Данные шаблона недоступны.")

/datum/world_edit_generator/blueprint_stamp/proc/get_blueprint_footprint_dimensions(list/blueprint)
	var/list/bounds = islist(blueprint) ? blueprint["bounds"] : null
	if(!islist(bounds))
		return list("width" = 1, "height" = 1)

	var/min_x = text2num("[bounds["min_x"]]")
	var/max_x = text2num("[bounds["max_x"]]")
	var/min_y = text2num("[bounds["min_y"]]")
	var/max_y = text2num("[bounds["max_y"]]")
	var/width = max(max_x - min_x + 1, 1)
	var/height = max(max_y - min_y + 1, 1)
	return list(
		"width" = width,
		"height" = height,
	)

/datum/world_edit_generator/blueprint_stamp/proc/get_default_stamp_spacing(list/blueprint)
	var/list/dimensions = get_blueprint_footprint_dimensions(blueprint)
	return max(text2num("[dimensions["width"]]"), text2num("[dimensions["height"]]"), 1)

/datum/world_edit_generator/blueprint_stamp/proc/get_effective_stamp_spacing(list/params, list/blueprint)
	var/default_spacing = get_default_stamp_spacing(blueprint)
	var/requested_spacing = text2num("[params["stamp_spacing"]]")
	if(!isnum(requested_spacing) || requested_spacing <= 0)
		return default_spacing
	return clamp(round(requested_spacing), 1, WORLD_EDIT_PLACEMENT_MAX_ANCHORS)

/datum/world_edit_generator/blueprint_stamp/proc/apply_stamp_spacing(list/anchor_turfs, list/params, list/blueprint)
	if(!islist(anchor_turfs) || !length(anchor_turfs))
		return list()

	var/spacing = get_effective_stamp_spacing(params, blueprint)
	return GLOB.world_edit_placement_shapes.world_edit_apply_spacing_to_turfs(anchor_turfs, spacing)
