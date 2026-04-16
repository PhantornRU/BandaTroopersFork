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

/datum/world_edit_manager/proc/clear_preview_images()
	if(holder && length(preview_images))
		holder.images -= preview_images
	preview_images = list()
	current_generator?.cleanup_preview(holder?.mob)
