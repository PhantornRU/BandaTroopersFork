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
		options += list(GLOB.world_edit_shape_catalog.build_placement_shape_option(shape_id))
	return options

/datum/world_edit_manager/proc/build_current_placement_shape_fields()
	var/shape_id = get_effective_placement_shape()
	if(!length(shape_id))
		return list()
	return GLOB.world_edit_shape_catalog.build_shape_ui_fields(shape_id, build_effective_generator_params())

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
	return GLOB.world_edit_shape_catalog.get_shape_interaction_kind(shape_id)

/datum/world_edit_manager/proc/get_placement_interaction_label(shape_id = null)
	shape_id = shape_id || get_effective_placement_shape()
	if(!length(shape_id))
		return "Single Click"
	return GLOB.world_edit_shape_catalog.get_shape_interaction_label(shape_id)

/datum/world_edit_manager/proc/get_placement_shape_rollout_stage(shape_id = null)
	shape_id = shape_id || get_effective_placement_shape()
	if(!length(shape_id))
		return "v1"
	return GLOB.world_edit_shape_catalog.get_shape_rollout_stage(shape_id)

/datum/world_edit_manager/proc/get_placement_session()
	if(!istype(placement_session))
		placement_session = new
	return placement_session

/datum/world_edit_manager/proc/sync_placement_session_cache()
	var/datum/world_edit_placement_session/session = get_placement_session()
	placement_anchor_turf = session.anchor_turf
	placement_hover_turf = session.hover_turf
	placement_collector_origin_turf = session.collector_origin_turf
	placement_collector_points = GLOB.world_edit_placement_shapes.world_edit_copy_points(session.collector_points)
	placement_collector_is_closed_candidate = ("[get_effective_placement_shape()]" == WORLD_EDIT_SHAPE_POLYGON && length(placement_collector_points) >= 2) ? TRUE : FALSE
	return session

/datum/world_edit_manager/proc/migrate_legacy_placement_runtime_params()
	var/datum/world_edit_placement_session/session = get_placement_session()
	if(!islist(current_params))
		return session

	if(!istype(session.collector_origin_turf) && !isnull(current_params["shape_points_origin"]))
		var/list/parts = splittext("[current_params["shape_points_origin"]]", ",")
		if(length(parts) >= 3)
			var/x_value = text2num(trim("[parts[1]]"))
			var/y_value = text2num(trim("[parts[2]]"))
			var/z_value = text2num(trim("[parts[3]]"))
			if(isnum(x_value) && isnum(y_value) && isnum(z_value))
				session.collector_origin_turf = locate(x_value, y_value, z_value)

	if(!length(session.collector_points) && !isnull(current_params["shape_points_text"]))
		session.collector_points = GLOB.world_edit_placement_shapes.world_edit_parse_shape_points(current_params["shape_points_text"])

	current_params -= "shape_points_origin"
	current_params -= "shape_points_text"
	sync_placement_session_cache()
	return session

/datum/world_edit_manager/proc/build_effective_generator_params(list/source_params = null, shape_id = null, list/collector_points_override = null)
	var/list/base_params = islist(source_params) ? source_params : current_params
	var/list/effective_params = sanitize_persistent_generator_params(base_params)
	shape_id = shape_id || get_effective_placement_shape()
	if(!length(shape_id))
		return effective_params

	var/list/effective_points = collector_points_override
	if(!islist(effective_points))
		effective_points = get_placement_collector_points()

	if("[shape_id]" in list(
		WORLD_EDIT_SHAPE_POLYGON,
		WORLD_EDIT_SHAPE_POLYLINE,
		WORLD_EDIT_SHAPE_CUSTOM_MASK,
		WORLD_EDIT_SHAPE_BRUSH_PATH
	))
		effective_params["shape_points_text"] = GLOB.world_edit_placement_shapes.world_edit_format_shape_points(effective_points)

	return effective_params

/datum/world_edit_manager/proc/get_placement_preview_candidate()
	var/datum/world_edit_placement_session/session = get_placement_session()
	return session.preview_candidate

/datum/world_edit_manager/proc/set_placement_anchor_turf(turf/anchor_turf)
	var/datum/world_edit_placement_session/session = get_placement_session()
	session.anchor_turf = anchor_turf
	sync_placement_session_cache()
	return anchor_turf

/datum/world_edit_manager/proc/set_placement_hover_turf(turf/hover_turf)
	var/datum/world_edit_placement_session/session = get_placement_session()
	session.hover_turf = hover_turf
	sync_placement_session_cache()
	return hover_turf

/datum/world_edit_manager/proc/get_current_preview_plan()
	var/datum/world_edit_placement_candidate/candidate = get_placement_preview_candidate()
	if(istype(candidate?.plan))
		return candidate.plan
	return current_generator?.current_plan

/datum/world_edit_manager/proc/get_placement_collector_origin_text()
	var/datum/world_edit_placement_session/session = migrate_legacy_placement_runtime_params()
	if(!istype(session.collector_origin_turf))
		return ""
	return "[session.collector_origin_turf.x],[session.collector_origin_turf.y],[session.collector_origin_turf.z]"

/datum/world_edit_manager/proc/get_placement_collector_origin_turf()
	var/datum/world_edit_placement_session/session = migrate_legacy_placement_runtime_params()
	return session.collector_origin_turf

/datum/world_edit_manager/proc/set_placement_collector_origin_turf(turf/origin_turf)
	var/datum/world_edit_placement_session/session = get_placement_session()
	session.collector_origin_turf = origin_turf
	if(islist(current_params))
		current_params -= "shape_points_origin"
	sync_placement_session_cache()
	if(!istype(origin_turf))
		return ""
	return "[origin_turf.x],[origin_turf.y],[origin_turf.z]"

/datum/world_edit_manager/proc/clear_placement_collector_origin()
	var/datum/world_edit_placement_session/session = get_placement_session()
	session.collector_origin_turf = null
	if(islist(current_params))
		current_params -= "shape_points_origin"
	sync_placement_session_cache()

/datum/world_edit_manager/proc/get_placement_collector_points()
	var/datum/world_edit_placement_session/session = migrate_legacy_placement_runtime_params()
	var/list/points = islist(session.collector_points) ? session.collector_points : list()
	placement_collector_points = GLOB.world_edit_placement_shapes.world_edit_copy_points(points)
	placement_collector_is_closed_candidate = ("[get_effective_placement_shape()]" == WORLD_EDIT_SHAPE_POLYGON && length(placement_collector_points) >= 2) ? TRUE : FALSE
	return GLOB.world_edit_placement_shapes.world_edit_copy_points(placement_collector_points)

/datum/world_edit_manager/proc/get_placement_collector_point_count()
	var/list/points = get_placement_collector_points()
	return length(points)

/datum/world_edit_manager/proc/get_placement_collector_min_points(shape_id = null)
	shape_id = shape_id || get_effective_placement_shape()
	if(!length(shape_id))
		return 1
	return GLOB.world_edit_shape_catalog.get_shape_collector_min_points(shape_id)

/datum/world_edit_manager/proc/get_placement_collector_max_points(shape_id = null)
	shape_id = shape_id || get_effective_placement_shape()
	if(!length(shape_id))
		return WORLD_EDIT_PLACEMENT_MAX_CUSTOM_POINTS
	return GLOB.world_edit_shape_catalog.get_shape_collector_max_points(shape_id)

/datum/world_edit_manager/proc/is_current_placement_collector(shape_id = null)
	return (get_placement_interaction_kind(shape_id) == "collector") ? TRUE : FALSE

/datum/world_edit_manager/proc/set_placement_collector_points(list/points)
	var/datum/world_edit_placement_session/session = get_placement_session()
	session.collector_points = islist(points) ? GLOB.world_edit_placement_shapes.world_edit_copy_points(points) : list()
	if(islist(current_params))
		current_params -= "shape_points_text"
	sync_placement_session_cache()
	return GLOB.world_edit_placement_shapes.world_edit_format_shape_points(session.collector_points)

/datum/world_edit_manager/proc/clear_placement_collector_points()
	var/datum/world_edit_placement_session/session = get_placement_session()
	session.collector_points = list()
	if(islist(current_params))
		current_params -= "shape_points_text"
	sync_placement_session_cache()

/datum/world_edit_manager/proc/get_placement_collector_points_text()
	return GLOB.world_edit_placement_shapes.world_edit_format_shape_points(get_placement_collector_points())

/datum/world_edit_manager/proc/reset_placement_collector_state(clear_points = FALSE)
	clear_placement_collector_origin()
	if(clear_points)
		clear_placement_collector_points()

/datum/world_edit_manager/proc/get_placement_collector_summary()
	var/shape_id = get_effective_placement_shape()
	var/shape_label = GLOB.world_edit_shape_catalog.get_placement_shape_label(shape_id)
	var/min_points = get_placement_collector_min_points(shape_id)
	var/max_points = get_placement_collector_max_points(shape_id)
	var/point_count = get_placement_collector_point_count()
	var/origin_desc = get_placement_collector_origin_text()
	if(!length(origin_desc))
		origin_desc = "none"
	return "Collector [shape_label]: points=[point_count]/[max_points], min=[min_points], origin=[origin_desc]"

/datum/world_edit_manager/proc/clear_placement_shape_preview_state()
	var/datum/world_edit_placement_session/session = get_placement_session()
	session.preview_candidate = null
	session.hover_turf = null
	placement_preview_shape_result = list()
	placement_preview_anchor_turfs = list()
	placement_preview_vertex_turfs = list()
	placement_preview_edge_turfs = list()
	placement_preview_closure_turfs = list()
	placement_preview_final_turfs = list()
	placement_preview_guide_turfs = list()
	placement_preview_generator_effect_turfs = list()
	placement_hover_turf = null

/datum/world_edit_manager/proc/store_placement_preview_candidate(datum/world_edit_placement_candidate/candidate)
	clear_placement_shape_preview_state()
	var/datum/world_edit_placement_session/session = get_placement_session()
	session.preview_candidate = candidate
	if(!istype(candidate))
		return

	session.hover_turf = islist(candidate.placement_context) ? candidate.placement_context["end_turf"] : null
	placement_hover_turf = session.hover_turf
	if(istype(candidate.shape_contract))
		placement_preview_shape_result = candidate.shape_contract.as_shape_result()
	if(istype(candidate.preview_model))
		placement_preview_anchor_turfs = islist(candidate.preview_model.anchor_turfs) ? candidate.preview_model.anchor_turfs.Copy() : list()
		placement_preview_vertex_turfs = islist(candidate.preview_model.vertex_turfs) ? candidate.preview_model.vertex_turfs.Copy() : list()
		placement_preview_edge_turfs = islist(candidate.preview_model.edge_turfs) ? candidate.preview_model.edge_turfs.Copy() : list()
		placement_preview_closure_turfs = islist(candidate.preview_model.closure_turfs) ? candidate.preview_model.closure_turfs.Copy() : list()
		placement_preview_final_turfs = islist(candidate.preview_model.final_turfs) ? candidate.preview_model.final_turfs.Copy() : list()
		placement_preview_guide_turfs = islist(candidate.preview_model.guide_turfs) ? candidate.preview_model.guide_turfs.Copy() : list()
		placement_preview_generator_effect_turfs = islist(candidate.preview_model.generator_effect_turfs) ? candidate.preview_model.generator_effect_turfs.Copy() : list()

/datum/world_edit_manager/proc/store_placement_shape_preview_result(list/shape_result)
	if(!islist(shape_result))
		return clear_placement_shape_preview_state()

	var/datum/world_edit_shape_contract/shape_contract = GLOB.world_edit_shape_geometry.build_shape_contract_from_result(shape_result["shape_id"] || get_effective_placement_shape(), shape_result)
	var/datum/world_edit_preview_model/preview_model = GLOB.world_edit_shape_preview.build_shape_preview(shape_contract)
	var/datum/world_edit_placement_candidate/candidate = new
	candidate.shape_contract = shape_contract
	candidate.preview_model = preview_model
	store_placement_preview_candidate(candidate)

/datum/world_edit_manager/proc/set_placement_preview_generator_effect_turfs(list/turfs)
	placement_preview_generator_effect_turfs = GLOB.world_edit_placement_shapes.world_edit_unique_turf_list(turfs)
	var/datum/world_edit_placement_candidate/candidate = get_placement_preview_candidate()
	if(istype(candidate?.preview_model))
		candidate.preview_model.generator_effect_turfs = placement_preview_generator_effect_turfs.Copy()

/datum/world_edit_manager/proc/get_placement_preview_groups()
	return list(
		list(
			"turfs" = placement_preview_anchor_turfs,
			"icon_state" = "blueOverlay",
			"color" = "#78C8FF",
			"alpha" = 255,
		),
		list(
			"turfs" = placement_preview_vertex_turfs,
			"icon_state" = "blueOverlay",
			"color" = "#B8F3FF",
			"alpha" = 210,
		),
		list(
			"turfs" = placement_preview_edge_turfs,
			"icon_state" = "greenOverlay",
			"color" = "#4DE1C1",
			"alpha" = 190,
		),
		list(
			"turfs" = placement_preview_closure_turfs,
			"icon_state" = "redOverlay",
			"color" = "#FFB347",
			"alpha" = 180,
		),
		list(
			"turfs" = placement_preview_final_turfs,
			"icon_state" = "greenOverlay",
			"color" = "#8BFFB5",
			"alpha" = 120,
		),
		list(
			"turfs" = placement_preview_guide_turfs,
			"icon_state" = "blueOverlay",
			"color" = "#D7B8FF",
			"alpha" = 150,
		),
		list(
			"turfs" = placement_preview_generator_effect_turfs,
			"icon_state" = "redOverlay",
			"color" = "#FF6B6B",
			"alpha" = 110,
		),
	)

/datum/world_edit_manager/proc/get_placement_anchor_desc()
	if(!placement_anchor_turf)
		return ""
	return "[placement_anchor_turf.x],[placement_anchor_turf.y],[placement_anchor_turf.z]"

/datum/world_edit_manager/proc/reset_placement_runtime(reset_config = FALSE, clear_points = TRUE)
	var/datum/world_edit_placement_session/session = get_placement_session()
	placement_click_active = FALSE
	session.anchor_turf = null
	session.hover_turf = null
	session.preview_candidate = null
	session.active_shape = null
	session.active_mode = null
	clear_placement_shape_preview_state()
	reset_placement_collector_state(clear_points)
	sync_placement_session_cache()

	if(reset_config)
		placement_mode = resolve_supported_placement_mode() || "single"
		placement_shape = resolve_supported_placement_shape() || WORLD_EDIT_SHAPE_POINT
		placement_dir = resolve_supported_placement_dir()
		placement_dir_uses_facing = TRUE
