/datum/world_edit_manager/proc/build_preview_params_signature(list/source_params = null)
	var/datum/world_edit_placement_session/session = get_placement_session()
	var/raw_shape_id = resolve_supported_placement_shape(placement_shape)
	var/shape_id = length("[raw_shape_id]") ? "[raw_shape_id]" : (length("[placement_shape]") ? "[placement_shape]" : WORLD_EDIT_SHAPE_POINT)
	if(!length(shape_id))
		shape_id = WORLD_EDIT_SHAPE_POINT

	var/list/session_points = islist(session.collector_points) ? GLOB.world_edit_placement_shapes.world_edit_copy_points(session.collector_points) : list()
	var/list/effective_params = build_generator_params_for_shape(source_params, shape_id, session_points)
	var/raw_mode = resolve_supported_placement_mode(placement_mode)
	var/effective_mode = length("[raw_mode]") ? "[raw_mode]" : (length("[placement_mode]") ? "[placement_mode]" : "single")
	if(!length(effective_mode))
		effective_mode = "single"

	var/effective_dir = resolve_supported_placement_dir(placement_dir)
	if(placement_dir_uses_facing)
		var/current_facing_dir = holder?.mob?.dir
		if(current_facing_dir in GLOB.cardinals)
			effective_dir = current_facing_dir

	var/points_text = ""
	if(shape_id in list(
		WORLD_EDIT_SHAPE_POLYGON,
		WORLD_EDIT_SHAPE_POLYLINE,
		WORLD_EDIT_SHAPE_CUSTOM_MASK,
		WORLD_EDIT_SHAPE_BRUSH_PATH
	))
		points_text = GLOB.world_edit_placement_shapes.world_edit_format_shape_points(session_points)

	var/anchor_desc = GLOB.world_edit_helpers.turf_to_text(session.anchor_turf)
	var/origin_desc = GLOB.world_edit_helpers.turf_to_text(session.collector_origin_turf)
	var/hover_desc = GLOB.world_edit_helpers.turf_to_text(session.hover_turf)
	var/seed_desc = ""
	var/requested_desc = ""
	var/resolved_desc = ""
	var/datum/world_edit_placement_candidate/preview_candidate = session.preview_candidate
	if(istype(preview_candidate) && islist(preview_candidate.placement_context))
		seed_desc = GLOB.world_edit_helpers.turf_to_text(preview_candidate.placement_context["seed_turf"])
		requested_desc = GLOB.world_edit_helpers.turf_to_text(preview_candidate.placement_context["requested_end_turf"])
		resolved_desc = GLOB.world_edit_helpers.turf_to_text(preview_candidate.placement_context["resolved_end_turf"] || preview_candidate.placement_context["end_turf"])

	return "[GLOB.world_edit_logging.params_to_text(effective_params, 400)]::mode=[effective_mode]::shape=[shape_id]::dir=[effective_dir]::points=[points_text]::anchor=[anchor_desc]::origin=[origin_desc]::hover=[hover_desc]::seed=[seed_desc]::requested=[requested_desc]::resolved=[resolved_desc]"

/datum/world_edit_manager/proc/mark_preview_state()
	preview_valid = TRUE
	preview_generator_id = current_definition?.id
	preview_params_signature = build_preview_params_signature()

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
	current_generator?.cleanup_preview(holder?.mob)
