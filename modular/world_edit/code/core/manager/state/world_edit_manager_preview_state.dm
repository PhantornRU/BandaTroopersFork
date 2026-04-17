/datum/world_edit_manager/proc/build_preview_params_signature(list/source_params = null)
	var/list/effective_params = build_effective_generator_params(source_params)
	var/shape_id = get_effective_placement_shape()
	var/points_text = ""
	if("[shape_id]" in list(
		WORLD_EDIT_SHAPE_POLYGON,
		WORLD_EDIT_SHAPE_POLYLINE,
		WORLD_EDIT_SHAPE_CUSTOM_MASK,
		WORLD_EDIT_SHAPE_BRUSH_PATH
	))
		points_text = get_placement_collector_points_text()
	return "[GLOB.world_edit_logging.params_to_text(effective_params, 400)]::mode=[get_effective_placement_mode()]::shape=[shape_id]::dir=[get_effective_placement_dir()]::points=[points_text]"

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
