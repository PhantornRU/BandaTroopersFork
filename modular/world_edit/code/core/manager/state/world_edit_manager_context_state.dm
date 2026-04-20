/datum/world_edit_manager/proc/sanitize_persistent_generator_params(list/source_params)
	var/list/sanitized = islist(source_params) ? source_params.Copy() : list()
	sanitized -= "shape_points_origin"
	sanitized -= "shape_points_text"
	return sanitized

/datum/world_edit_manager/proc/build_current_generator_context_snapshot()
	if(!current_definition?.id)
		return null
	current_params = sanitize_persistent_generator_params(current_params)
	bump_preview_params_revision()

	return list(
		"params" = current_params.Copy(),
		"placement_mode" = length("[placement_mode]") ? "[placement_mode]" : "single",
		"placement_shape" = length("[placement_shape]") ? "[placement_shape]" : WORLD_EDIT_SHAPE_POINT,
		"placement_dir" = placement_dir || NORTH,
		"placement_dir_uses_facing" = placement_dir_uses_facing ? TRUE : FALSE,
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

	if("placement_mode" in snapshot)
		var/raw_mode = snapshot["placement_mode"]
		if(current_generator)
			placement_mode = resolve_supported_placement_mode(raw_mode) || resolve_supported_placement_mode() || "single"
		else
			placement_mode = length("[raw_mode]") ? "[raw_mode]" : "single"

	if("placement_shape" in snapshot)
		var/raw_shape = snapshot["placement_shape"]
		if(current_generator)
			placement_shape = resolve_supported_placement_shape(raw_shape) || resolve_supported_placement_shape() || WORLD_EDIT_SHAPE_POINT
		else
			placement_shape = length("[raw_shape]") ? "[raw_shape]" : WORLD_EDIT_SHAPE_POINT

	if("placement_dir" in snapshot)
		var/raw_dir = snapshot["placement_dir"]
		if(current_generator)
			placement_dir = resolve_supported_placement_dir(raw_dir)
		else
			placement_dir = raw_dir || NORTH

	if("placement_dir_uses_facing" in snapshot)
		placement_dir_uses_facing = GLOB.world_edit_helpers.parse_bool(snapshot["placement_dir_uses_facing"])

	sync_shared_placement_prefs()
	return TRUE

/datum/world_edit_manager/proc/sync_shared_placement_prefs()
	placement_shared_mode = length("[placement_mode]") ? "[placement_mode]" : "single"
	placement_shared_shape = length("[placement_shape]") ? "[placement_shape]" : WORLD_EDIT_SHAPE_POINT
	placement_shared_dir = placement_dir || NORTH
	placement_shared_dir_uses_facing = placement_dir_uses_facing ? TRUE : FALSE
	return TRUE

/datum/world_edit_manager/proc/clear_generator_context(generator_id = null)
	if(!islist(generator_context_cache))
		generator_context_cache = list()
	if(isnull(generator_id) || !length("[generator_id]"))
		generator_context_cache = list()
		return

	generator_context_cache["[generator_id]"] = null
