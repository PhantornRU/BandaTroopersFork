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
	return TRUE

/datum/world_edit_manager/proc/clear_generator_context(generator_id = null)
	if(!islist(generator_context_cache))
		generator_context_cache = list()
	if(isnull(generator_id) || !length("[generator_id]"))
		generator_context_cache = list()
		return

	generator_context_cache["[generator_id]"] = null
