/datum/world_edit_manager/proc/is_safe_placement_mode_active()
	return (sync_click_intercept_state() && placement_click_active) ? TRUE : FALSE

/datum/world_edit_manager/proc/get_supported_placement_modes()
	var/list/modes = current_generator?.get_supported_placement_modes()
	if(!islist(modes))
		return list()
	return modes.Copy()

/datum/world_edit_manager/proc/get_supported_placement_shapes()
	var/list/shapes = current_generator?.get_supported_placement_shapes()
	if(!islist(shapes))
		return list()
	return shapes.Copy()

/datum/world_edit_manager/proc/supports_current_placement_ux()
	return (length(get_supported_placement_modes()) || length(get_supported_placement_shapes())) ? TRUE : FALSE

/datum/world_edit_manager/proc/supports_current_placement_shapes()
	return length(get_supported_placement_shapes()) ? TRUE : FALSE

/datum/world_edit_manager/proc/supports_current_placement_direction()
	return current_generator?.supports_placement_direction() ? TRUE : FALSE

/datum/world_edit_manager/proc/resolve_supported_placement_mode(requested_mode = null)
	var/list/modes = get_supported_placement_modes()
	if(!length(modes))
		return null

	if(length("[requested_mode]") && (requested_mode in modes))
		return "[requested_mode]"
	return "[modes[1]]"

/datum/world_edit_manager/proc/resolve_supported_placement_shape(requested_shape = null)
	var/list/shapes = get_supported_placement_shapes()
	if(!length(shapes))
		return null

	if(length("[requested_shape]") && (requested_shape in shapes))
		return "[requested_shape]"

	var/default_shape = current_generator?.get_default_placement_shape()
	if(length("[default_shape]") && (default_shape in shapes))
		return "[default_shape]"
	return "[shapes[1]]"

/datum/world_edit_manager/proc/resolve_supported_placement_dir(requested_dir = null)
	var/default_dir = current_generator?.get_default_placement_direction() || NORTH
	if(requested_dir in GLOB.cardinals)
		return requested_dir
	return default_dir

/datum/world_edit_manager/proc/apply_shared_placement_prefs_to_current_generator()
	placement_mode = resolve_supported_placement_mode(placement_shared_mode) || "single"
	placement_shape = resolve_supported_placement_shape(placement_shared_shape) || WORLD_EDIT_SHAPE_POINT
	placement_dir = resolve_supported_placement_dir(placement_shared_dir)
	placement_dir_uses_facing = placement_shared_dir_uses_facing ? TRUE : FALSE
	return TRUE

/datum/world_edit_manager/proc/get_effective_placement_mode()
	var/resolved_mode = resolve_supported_placement_mode(placement_mode)
	if(!length("[resolved_mode]"))
		placement_mode = "single"
		return null

	placement_mode = resolved_mode
	return placement_mode

/datum/world_edit_manager/proc/get_effective_placement_shape()
	var/resolved_shape = resolve_supported_placement_shape(placement_shape)
	if(!length("[resolved_shape]"))
		placement_shape = WORLD_EDIT_SHAPE_POINT
		return null

	placement_shape = resolved_shape
	return placement_shape

/datum/world_edit_manager/proc/get_effective_placement_dir()
	placement_dir = resolve_supported_placement_dir(placement_dir)
	if(placement_dir_uses_facing)
		var/current_facing_dir = holder?.mob?.dir
		if(current_facing_dir in GLOB.cardinals)
			return current_facing_dir
	return placement_dir

/datum/world_edit_manager/proc/build_placement_mode_options()
	var/list/options = list()
	for(var/mode in get_supported_placement_modes())
		var/list/entry = list("value" = "[mode]")
		switch("[mode]")
			if("single")
				entry["label"] = "Single"
				entry["description"] = "One placement and exit."
			if("repeat")
				entry["label"] = "Repeat"
				entry["description"] = "Keep placement mode active after each apply."
			else
				entry["label"] = "[mode]"
		options += list(entry)
	return options

/datum/world_edit_manager/proc/build_placement_shape_options()
	var/list/options = list()
	for(var/shape_id in get_supported_placement_shapes())
		options += list(GLOB.world_edit_placement_shapes.world_edit_build_placement_shape_option(shape_id))
	return options

/datum/world_edit_manager/proc/build_current_placement_shape_fields()
	var/shape_id = get_effective_placement_shape()
	if(!length(shape_id))
		return list()
	return GLOB.world_edit_placement_shapes.world_edit_build_shape_ui_fields(shape_id, current_params)

/datum/world_edit_manager/proc/build_placement_dir_options()
	return list(
		list("label" = "North", "value" = "North"),
		list("label" = "East", "value" = "East"),
		list("label" = "South", "value" = "South"),
		list("label" = "West", "value" = "West"),
	)

/datum/world_edit_manager/proc/placement_mode_uses_anchor_pair(mode = null)
	var/shape_id = mode || get_effective_placement_shape()
	return (get_placement_interaction_kind(shape_id) == "anchor_pair") ? TRUE : FALSE

/datum/world_edit_manager/proc/get_placement_interaction_kind(shape_id = null)
	shape_id = shape_id || get_effective_placement_shape()
	if(!length(shape_id))
		return "single"
	return GLOB.world_edit_placement_shapes.world_edit_get_shape_interaction_kind(shape_id)

/datum/world_edit_manager/proc/get_placement_interaction_label(shape_id = null)
	shape_id = shape_id || get_effective_placement_shape()
	if(!length(shape_id))
		return "Single Click"
	return GLOB.world_edit_placement_shapes.world_edit_get_shape_interaction_label(shape_id)

/datum/world_edit_manager/proc/get_placement_shape_rollout_stage(shape_id = null)
	shape_id = shape_id || get_effective_placement_shape()
	if(!length(shape_id))
		return "v1"
	return GLOB.world_edit_placement_shapes.world_edit_get_shape_rollout_stage(shape_id)

/datum/world_edit_manager/proc/get_placement_collector_origin_text()
	if(!islist(current_params))
		return ""
	var/origin_text = current_params["shape_points_origin"]
	if(isnull(origin_text))
		return ""
	return "[origin_text]"

/datum/world_edit_manager/proc/get_placement_collector_origin_turf()
	var/list/parts = splittext(get_placement_collector_origin_text(), ",")
	if(length(parts) < 3)
		return null

	var/x_value = text2num(trim("[parts[1]]"))
	var/y_value = text2num(trim("[parts[2]]"))
	var/z_value = text2num(trim("[parts[3]]"))
	if(!isnum(x_value) || !isnum(y_value) || !isnum(z_value))
		return null
	return locate(x_value, y_value, z_value)

/datum/world_edit_manager/proc/set_placement_collector_origin_turf(turf/origin_turf)
	if(!islist(current_params))
		current_params = list()
	if(!istype(origin_turf))
		current_params -= "shape_points_origin"
		return ""

	current_params["shape_points_origin"] = "[origin_turf.x],[origin_turf.y],[origin_turf.z]"
	return current_params["shape_points_origin"]

/datum/world_edit_manager/proc/clear_placement_collector_origin()
	if(!islist(current_params))
		return
	current_params -= "shape_points_origin"

/datum/world_edit_manager/proc/get_placement_collector_points()
	return GLOB.world_edit_placement_shapes.world_edit_parse_shape_points(current_params["shape_points_text"])

/datum/world_edit_manager/proc/get_placement_collector_point_count()
	var/list/points = get_placement_collector_points()
	return length(points)

/datum/world_edit_manager/proc/get_placement_collector_min_points(shape_id = null)
	shape_id = shape_id || get_effective_placement_shape()
	if(!length(shape_id))
		return 1
	return GLOB.world_edit_placement_shapes.world_edit_get_shape_collector_min_points(shape_id)

/datum/world_edit_manager/proc/get_placement_collector_max_points(shape_id = null)
	shape_id = shape_id || get_effective_placement_shape()
	if(!length(shape_id))
		return WORLD_EDIT_PLACEMENT_MAX_CUSTOM_POINTS
	return GLOB.world_edit_placement_shapes.world_edit_get_shape_collector_max_points(shape_id)

/datum/world_edit_manager/proc/is_current_placement_collector(shape_id = null)
	return (get_placement_interaction_kind(shape_id) == "collector") ? TRUE : FALSE

/datum/world_edit_manager/proc/set_placement_collector_points(list/points)
	if(!islist(current_params))
		current_params = list()
	current_params["shape_points_text"] = GLOB.world_edit_placement_shapes.world_edit_format_shape_points(points)
	return current_params["shape_points_text"]

/datum/world_edit_manager/proc/clear_placement_collector_points()
	if(!islist(current_params))
		return
	current_params -= "shape_points_text"

/datum/world_edit_manager/proc/get_placement_collector_points_text()
	if(!islist(current_params))
		return ""
	var/points_text = current_params["shape_points_text"]
	if(isnull(points_text))
		return ""
	return "[points_text]"

/datum/world_edit_manager/proc/reset_placement_collector_state(clear_points = FALSE)
	if(!islist(current_params))
		return
	current_params -= "shape_points_origin"
	if(clear_points)
		clear_placement_collector_points()

/datum/world_edit_manager/proc/get_placement_collector_summary()
	var/shape_id = get_effective_placement_shape()
	var/shape_label = GLOB.world_edit_placement_shapes.world_edit_get_placement_shape_label(shape_id)
	var/min_points = get_placement_collector_min_points(shape_id)
	var/max_points = get_placement_collector_max_points(shape_id)
	var/point_count = get_placement_collector_point_count()
	var/origin_desc = get_placement_collector_origin_text()
	if(!length(origin_desc))
		origin_desc = "none"
	return "Collector [shape_label]: points=[point_count]/[max_points], min=[min_points], origin=[origin_desc]"

/datum/world_edit_manager/proc/get_placement_anchor_desc()
	if(!placement_anchor_turf)
		return ""
	return "[placement_anchor_turf.x],[placement_anchor_turf.y],[placement_anchor_turf.z]"

/datum/world_edit_manager/proc/reset_placement_runtime(reset_config = FALSE)
	placement_click_active = FALSE
	placement_anchor_turf = null
	reset_placement_collector_state()

	if(reset_config)
		placement_mode = resolve_supported_placement_mode() || "single"
		placement_shape = resolve_supported_placement_shape() || WORLD_EDIT_SHAPE_POINT
		placement_dir = resolve_supported_placement_dir()
		placement_dir_uses_facing = TRUE
