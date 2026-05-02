/datum/world_edit_manager/proc/build_preview_signature_params_hash(list/source_params = null)
	var/list/base_params = islist(source_params) ? source_params : current_params
	if(!islist(source_params) || base_params == current_params)
		if(cached_params_hash_revision == params_revision && length(cached_params_hash))
			return cached_params_hash
		var/list/sanitized_params = sanitize_persistent_generator_params(base_params)
		cached_params_hash = GLOB.world_edit_logging.params_hash(sanitized_params)
		cached_params_hash_revision = params_revision
		return cached_params_hash
	return GLOB.world_edit_logging.params_hash(sanitize_persistent_generator_params(base_params))

/datum/world_edit_manager/proc/bump_preview_params_revision()
	params_revision = (params_revision || 0) + 1
	cached_params_hash = null
	cached_params_hash_revision = -1
	return params_revision

/datum/world_edit_manager/proc/build_preview_params_signature(list/source_params = null, include_context_revision = TRUE)
	var/datum/world_edit_placement_session/session = get_placement_session()
	var/raw_shape_id = resolve_supported_placement_shape(placement_shape)
	var/shape_id = length("[raw_shape_id]") ? "[raw_shape_id]" : (length("[placement_shape]") ? "[placement_shape]" : WORLD_EDIT_SHAPE_POINT)
	if(!length(shape_id))
		shape_id = WORLD_EDIT_SHAPE_POINT

	var/params_hash = build_preview_signature_params_hash(source_params)
	var/raw_mode = resolve_supported_placement_mode(placement_mode)
	var/effective_mode = length("[raw_mode]") ? "[raw_mode]" : (length("[placement_mode]") ? "[placement_mode]" : "single")
	if(!length(effective_mode))
		effective_mode = "single"

	var/effective_dir = resolve_supported_placement_dir(placement_dir)
	if(placement_dir_uses_facing)
		var/current_facing_dir = holder?.mob?.dir
		if(current_facing_dir in GLOB.cardinals)
			effective_dir = current_facing_dir

	var/blueprint_revision = ""
	if(current_definition?.id == "blueprint_stamp")
		blueprint_revision = get_active_blueprint_revision()

	var/context_revision = include_context_revision ? (session.preview_context_revision || 0) : 0
	return "params_hash=[params_hash]::mode=[effective_mode]::shape=[shape_id]::dir=[effective_dir]::collector_rev=[session.collector_points_revision || 0]::context_rev=[context_revision]::blueprint_rev=[blueprint_revision]"

/datum/world_edit_manager/proc/mark_preview_state()
	preview_valid = TRUE
	preview_generator_id = current_definition?.id
	preview_params_signature = placement_preview_signature || build_preview_params_signature()

/datum/world_edit_manager/proc/invalidate_preview_state()
	preview_valid = FALSE
	preview_generator_id = null
	preview_params_signature = null

/datum/world_edit_manager/proc/is_preview_state_valid()
	if(!preview_valid)
		return FALSE
	if(preview_generator_id != current_definition?.id)
		return FALSE
	if(preview_params_signature != build_preview_params_signature())
		return FALSE
	return TRUE

/datum/world_edit_manager/proc/clear_preview_images()
	if(holder && length(preview_images))
		holder.images -= preview_images
	preview_images = list()
	preview_groups_signature = null
	current_generator?.cleanup_preview(holder?.mob)
