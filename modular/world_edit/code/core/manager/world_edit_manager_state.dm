/datum/world_edit_manager/proc/get_history_entries_desc()
	if(!length(history_entries))
		return list()

	var/list/desc_entries = list()
	for(var/i = length(history_entries), i >= 1, i--)
		desc_entries += list(history_entries[i])
	return desc_entries

/datum/world_edit_manager/proc/add_history_entry(generator_id, result_code, created_count, deleted_count, turf/center_turf, params_short, message = "", duration_ms = 0, list/extra_data = null)
	var/list/entry = list(
		"time" = time_stamp(),
		"generator_id" = generator_id,
		"result" = result_code,
		"created_count" = created_count,
		"deleted_count" = deleted_count,
		"center_turf" = center_turf ? "[center_turf.x],[center_turf.y],[center_turf.z]" : "n/a",
		"params_short" = params_short,
		"message" = message,
		"duration_ms" = duration_ms
	)
	if(islist(extra_data))
		for(var/key in extra_data)
			entry[key] = extra_data[key]
	history_entries += list(entry)
	while(length(history_entries) > WORLD_EDIT_HISTORY_LIMIT)
		history_entries.Cut(1, 2)
	return entry

/datum/world_edit_manager/proc/prune_changeset_stack()
	if(!islist(changeset_entries))
		changeset_entries = list()
		return

	while(length(changeset_entries))
		var/datum/world_edit_changeset/changeset = changeset_entries[length(changeset_entries)]
		if(istype(changeset) && !changeset.is_empty())
			break

		changeset_entries.Cut(length(changeset_entries), length(changeset_entries) + 1)
		if(istype(changeset))
			qdel(changeset)

/datum/world_edit_manager/proc/push_changeset(datum/world_edit_changeset/changeset)
	if(!istype(changeset))
		return null
	if(changeset.is_empty())
		qdel(changeset)
		return null

	if(!islist(changeset_entries))
		changeset_entries = list()

	changeset_entries += list(changeset)
	while(length(changeset_entries) > WORLD_EDIT_HISTORY_LIMIT)
		var/datum/world_edit_changeset/old_changeset = changeset_entries[1]
		changeset_entries.Cut(1, 2)
		if(istype(old_changeset))
			qdel(old_changeset)
	return changeset

/datum/world_edit_manager/proc/get_last_changeset()
	prune_changeset_stack()
	if(!length(changeset_entries))
		return null
	return changeset_entries[length(changeset_entries)]

/datum/world_edit_manager/proc/build_changeset_history_meta(datum/world_edit_changeset/changeset)
	var/list/meta = list(
		"undo_policy" = WORLD_EDIT_UNDO_NONE,
		"undo_status" = "not_available",
	)
	if(!istype(changeset))
		return meta

	meta["operation_id"] = changeset.operation_id
	meta["undo_policy"] = changeset.undo_policy
	meta["created_entries"] = length(changeset.created_entries)
	meta["moved_entries"] = length(changeset.moved_entries)
	meta["owned_effect_entries"] = length(changeset.owned_effect_entries)
	meta["undo_status"] = changeset.can_undo() ? "available" : (changeset.can_cleanup_owned_effects() ? "cleanup_available" : "not_available")
	return meta

/datum/world_edit_manager/proc/build_last_changeset_summary()
	var/datum/world_edit_changeset/changeset = get_last_changeset()
	if(!istype(changeset))
		return null

	return list(
		"operation_id" = changeset.operation_id,
		"generator_id" = changeset.generator_id,
		"undo_policy" = changeset.undo_policy,
		"created_entries" = length(changeset.created_entries),
		"moved_entries" = length(changeset.moved_entries),
		"owned_effect_entries" = length(changeset.owned_effect_entries),
		"created_at" = changeset.created_at,
		"can_undo" = changeset.can_undo() ? TRUE : FALSE,
		"can_cleanup" = changeset.can_cleanup_owned_effects() ? TRUE : FALSE,
		"undo_status" = changeset.can_undo() ? "available" : (changeset.can_cleanup_owned_effects() ? "cleanup_available" : "not_available"),
	)

/datum/world_edit_manager/proc/can_undo_last_operation()
	var/datum/world_edit_changeset/changeset = get_last_changeset()
	return changeset?.can_undo() ? TRUE : FALSE

/datum/world_edit_manager/proc/can_cleanup_last_owned_effects()
	var/datum/world_edit_changeset/changeset = get_last_changeset()
	return changeset?.can_cleanup_owned_effects() ? TRUE : FALSE

/datum/world_edit_manager/proc/mark_preview_state()
	preview_valid = TRUE
	preview_generator_id = current_definition?.id
	preview_params_signature = "[GLOB.world_edit_logging.params_to_text(current_params, 400)]::mode=[get_effective_placement_mode()]::shape=[get_effective_placement_shape()]::dir=[get_effective_placement_dir()]"

/datum/world_edit_manager/proc/invalidate_preview_state()
	preview_valid = FALSE
	preview_generator_id = null
	preview_params_signature = null

/datum/world_edit_manager/proc/is_preview_state_valid()
	if(!preview_valid)
		return FALSE
	if(preview_generator_id != current_definition?.id)
		return FALSE
	if(preview_params_signature != "[GLOB.world_edit_logging.params_to_text(current_params, 400)]::mode=[get_effective_placement_mode()]::shape=[get_effective_placement_shape()]::dir=[get_effective_placement_dir()]")
		return FALSE
	return TRUE

/datum/world_edit_manager/proc/sanitize_persistent_generator_params(list/source_params)
	var/list/sanitized = islist(source_params) ? source_params.Copy() : list()
	sanitized -= "shape_points_origin"
	sanitized -= "shape_points_text"
	return sanitized

/datum/world_edit_manager/proc/preserve_active_placement_runtime_params(list/target_params)
	if(!islist(target_params))
		target_params = list()
	if(!islist(current_params))
		return target_params

	if(!isnull(current_params["shape_points_origin"]))
		target_params["shape_points_origin"] = current_params["shape_points_origin"]
	if(!isnull(current_params["shape_points_text"]))
		target_params["shape_points_text"] = current_params["shape_points_text"]
	return target_params

/datum/world_edit_manager/proc/build_current_generator_context_snapshot()
	if(!current_definition?.id)
		return null

	return list(
		"params" = sanitize_persistent_generator_params(current_params),
		"placement_mode" = placement_mode,
		"placement_shape" = placement_shape,
		"placement_dir" = placement_dir,
		"placement_dir_uses_facing" = placement_dir_uses_facing,
	)

/datum/world_edit_manager/proc/save_current_generator_context()
	if(!current_definition?.id)
		return FALSE
	if(!islist(generator_context_cache))
		generator_context_cache = list()

	generator_context_cache[current_definition.id] = build_current_generator_context_snapshot()
	return TRUE

/datum/world_edit_manager/proc/restore_generator_context(generator_id)
	if(!length("[generator_id]") || !islist(generator_context_cache))
		return FALSE

	var/list/snapshot = generator_context_cache["[generator_id]"]
	if(!islist(snapshot))
		return FALSE

	var/list/snapshot_params = snapshot["params"]
	current_params = sanitize_persistent_generator_params(snapshot_params)

	if(length("[snapshot["placement_mode"]]"))
		placement_mode = "[snapshot["placement_mode"]]"
	if(length("[snapshot["placement_shape"]]"))
		placement_shape = "[snapshot["placement_shape"]]"

	var/snapshot_dir = text2num("[snapshot["placement_dir"]]")
	if(snapshot_dir in GLOB.cardinals)
		placement_dir = snapshot_dir
	placement_dir_uses_facing = GLOB.world_edit_helpers.parse_bool(snapshot["placement_dir_uses_facing"])

	get_effective_placement_mode()
	get_effective_placement_shape()
	get_effective_placement_dir()
	return TRUE

/datum/world_edit_manager/proc/clear_generator_context(generator_id = null)
	if(!islist(generator_context_cache))
		generator_context_cache = list()
	if(isnull(generator_id) || !length("[generator_id]"))
		generator_context_cache = list()
		return

	generator_context_cache["[generator_id]"] = null

/datum/world_edit_manager/proc/clear_preview_images()
	if(holder && length(preview_images))
		holder.images -= preview_images
	preview_images = list()
	current_generator?.cleanup_preview(holder?.mob)

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

/datum/world_edit_manager/proc/get_effective_placement_mode()
	var/list/modes = get_supported_placement_modes()
	if(!length(modes))
		placement_mode = "single"
		return null

	if(!(placement_mode in modes))
		placement_mode = "[modes[1]]"
	return placement_mode

/datum/world_edit_manager/proc/get_effective_placement_shape()
	var/list/shapes = get_supported_placement_shapes()
	if(!length(shapes))
		placement_shape = WORLD_EDIT_SHAPE_POINT
		return null

	if(!(placement_shape in shapes))
		placement_shape = "[shapes[1]]"
	return placement_shape

/datum/world_edit_manager/proc/get_effective_placement_dir()
	var/default_dir = current_generator?.get_default_placement_direction() || NORTH
	if(!(placement_dir in GLOB.cardinals))
		placement_dir = default_dir
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
		placement_mode = "single"
		placement_shape = current_generator?.get_default_placement_shape() || WORLD_EDIT_SHAPE_POINT
		placement_dir = current_generator?.get_default_placement_direction() || NORTH
		placement_dir_uses_facing = TRUE

/datum/world_edit_manager/proc/sync_click_intercept_state()
	if(holder?.click_intercept == src)
		click_intercept_owned = TRUE
		return TRUE

	click_intercept_owned = FALSE
	placement_click_active = FALSE
	return FALSE

/datum/world_edit_manager/proc/acquire_click_intercept(mode_name)
	if(!holder)
		return FALSE

	if(holder.click_intercept == src)
		click_intercept_owned = TRUE
		return TRUE

	if(holder.click_intercept && holder.click_intercept != src)
		var/answer = tgui_alert(holder.mob, "Сейчас клики перехватывает другой инструмент ([holder.click_intercept]). Перехватить управление для режима '[mode_name]'?", "World Edit: Перехват клика", list("Да", "Нет"))
		if(answer != "Да")
			return FALSE
		click_intercept_previous = holder.click_intercept
	else
		click_intercept_previous = null

	holder.click_intercept = src
	click_intercept_owned = TRUE
	return TRUE

/datum/world_edit_manager/proc/stop_click_mode()
	current_generator?.disable_click_mode()
	reset_placement_runtime()

	if(!click_intercept_owned || !holder)
		click_intercept_previous = null
		click_intercept_owned = FALSE
		return

	if(holder.click_intercept == src)
		if(click_intercept_previous && !QDELETED(click_intercept_previous))
			holder.click_intercept = click_intercept_previous
		else
			holder.click_intercept = null

	click_intercept_previous = null
	click_intercept_owned = FALSE

/datum/world_edit_manager/proc/refresh_runtime_after_config_change(clear_placement_progress = FALSE, clear_collector_points = FALSE)
	clear_preview_plan_state()
	if(clear_placement_progress)
		placement_anchor_turf = null
		reset_placement_collector_state(clear_collector_points)

	if(sync_click_intercept_state() && placement_click_active && !supports_current_placement_ux())
		stop_click_mode()

/datum/world_edit_manager/proc/InterceptClickOn(mob/user, params, atom/object)
	if(!sync_click_intercept_state())
		return FALSE
	if(!holder || holder != user?.client)
		return FALSE
	if(!current_generator || !current_definition)
		return FALSE
	if(!check_rights_for(holder, current_definition.required_rights))
		return FALSE
	if(placement_click_active)
		return handle_safe_placement_click(user, params, object)
	if(current_definition.execution_mode != WORLD_EDIT_EXECUTION_CLICK)
		return FALSE
	return current_generator.InterceptClickOn(user, params, object)
