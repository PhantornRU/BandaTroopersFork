/datum/world_edit_manager/proc/build_ui_data_payload()
	var/has_generator = (current_definition && current_generator) ? TRUE : FALSE
	var/list/ui_fields = get_normalized_ui_fields()
	var/requires_preview = current_generator?.requires_preview_before_apply ? TRUE : FALSE
	var/list/placement_modes = build_placement_mode_options()
	var/list/placement_shapes = build_placement_shape_options()
	var/list/placement_shape_fields = build_current_placement_shape_fields()
	var/click_mode_active = sync_click_intercept_state()
	var/list/data = list()

	apply_ui_payload(data, build_generator_ui_payload(has_generator, ui_fields, requires_preview))
	apply_ui_payload(data, build_placement_ui_payload(click_mode_active, placement_modes, placement_shapes, placement_shape_fields))
	apply_ui_payload(data, build_preset_ui_payload())
	apply_ui_payload(data, build_blueprint_ui_payload())
	apply_ui_payload(data, build_feedback_ui_payload())
	apply_ui_payload(data, build_actionability_ui_payload(has_generator, requires_preview, click_mode_active))
	apply_ui_payload(data, build_history_ui_payload())
	return data
