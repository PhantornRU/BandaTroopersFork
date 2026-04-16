/datum/world_edit_manager/proc/apply_ui_payload(list/data, list/payload)
	if(!islist(data) || !islist(payload))
		return data

	for(var/key in payload)
		data[key] = payload[key]
	return data

/datum/world_edit_manager/proc/build_generator_ui_payload(has_generator, list/ui_fields, requires_preview)
	return list(
		"has_generator" = has_generator ? TRUE : FALSE,
		"current_generator_id" = current_definition?.id,
		"current_generator_name" = current_definition?.name_ru,
		"current_generator_category" = current_definition?.category_ru,
		"current_generator_description" = current_definition?.description_ru,
		"current_generator_execution_mode" = current_definition?.execution_mode,
		"current_generator_required_rights" = current_definition ? rights2text(current_definition.required_rights, " ") : "",
		"current_generator_supports_preview" = current_definition?.supports_preview ? TRUE : FALSE,
		"requires_preview_before_apply" = requires_preview ? TRUE : FALSE,
		"current_params_text" = GLOB.world_edit_logging.params_to_text(current_params, 600),
		"ui_fields" = ui_fields,
		"runtime_status" = current_generator?.get_runtime_status() || list(),
	)

/datum/world_edit_manager/proc/build_placement_ui_payload(click_mode_active, list/placement_modes, list/placement_shapes, list/placement_shape_fields)
	var/placement_supported = length(placement_modes) > 0
	var/placement_shape_supported = length(placement_shapes) > 0
	return list(
		"placement_supported" = placement_supported ? TRUE : FALSE,
		"placement_active" = (placement_click_active && click_mode_active) ? TRUE : FALSE,
		"placement_mode" = get_effective_placement_mode() || "single",
		"placement_mode_options" = placement_modes,
		"placement_shape_supported" = placement_shape_supported ? TRUE : FALSE,
		"placement_shape" = get_effective_placement_shape() || WORLD_EDIT_SHAPE_POINT,
		"placement_shape_options" = placement_shapes,
		"placement_shape_fields" = placement_shape_fields,
		"placement_shape_uses_anchor_pair" = placement_mode_uses_anchor_pair(get_effective_placement_shape()) ? TRUE : FALSE,
		"placement_interaction_kind" = get_placement_interaction_kind(),
		"placement_interaction_label" = get_placement_interaction_label(),
		"placement_shape_rollout_stage" = get_placement_shape_rollout_stage(),
		"placement_collector_point_count" = get_placement_collector_point_count(),
		"placement_collector_min_points" = get_placement_collector_min_points(),
		"placement_collector_max_points" = get_placement_collector_max_points(),
		"placement_collector_origin" = get_placement_collector_origin_text(),
		"placement_collector_points_text" = get_placement_collector_points_text(),
		"placement_collector_summary" = get_placement_collector_summary(),
		"can_finish_placement_collection" = (click_mode_active && is_current_placement_collector() && get_placement_collector_point_count() >= get_placement_collector_min_points()) ? TRUE : FALSE,
		"placement_supports_direction" = supports_current_placement_direction() ? TRUE : FALSE,
		"placement_dir" = GLOB.world_edit_helpers.dir_to_label(get_effective_placement_dir()),
		"placement_dir_uses_facing" = placement_dir_uses_facing ? TRUE : FALSE,
		"placement_dir_options" = build_placement_dir_options(),
		"placement_anchor" = get_placement_anchor_desc(),
		"can_start_placement_mode" = (supports_current_placement_ux() && !click_mode_active) ? TRUE : FALSE,
	)

/datum/world_edit_manager/proc/build_preset_ui_payload()
	return list(
		"can_manage_presets" = can_manage_current_generator_presets(),
		"preset_entries" = get_current_generator_presets(),
	)

/datum/world_edit_manager/proc/build_blueprint_ui_payload()
	return list(
		"blueprint_entries" = get_blueprint_entries_for_ui(),
		"active_blueprint_id" = get_active_blueprint_id(),
		"can_save_blueprint_from_plan" = can_save_blueprint_from_current_plan(),
	)

/datum/world_edit_manager/proc/build_feedback_ui_payload()
	return list(
		"confirm_before_apply" = confirm_before_apply ? TRUE : FALSE,
		"last_ui_error" = last_ui_error || "",
		"preview_valid" = is_preview_state_valid(),
		"preview_success" = last_preview_success,
		"preview_message" = last_preview_message,
		"preview_meta" = last_preview_meta || list(),
		"last_apply_success" = last_apply_success,
		"last_apply_message" = last_apply_message,
		"last_undo_success" = last_undo_success,
		"last_undo_message" = last_undo_message,
		"last_undo_action" = last_undo_action,
		"last_changeset" = build_last_changeset_summary(),
	)

/datum/world_edit_manager/proc/build_actionability_ui_payload(has_generator, requires_preview, click_mode_active)
	var/can_run_preview = has_generator && current_definition?.supports_preview && !click_mode_active
	var/can_run_apply = has_generator && (!requires_preview || is_preview_state_valid()) && !click_mode_active
	return list(
		"click_mode_active" = click_mode_active ? TRUE : FALSE,
		"can_run_preview" = can_run_preview ? TRUE : FALSE,
		"can_run_apply" = can_run_apply ? TRUE : FALSE,
		"can_stop_click_mode" = click_mode_active ? TRUE : FALSE,
		"can_undo_last_operation" = can_undo_last_operation(),
		"can_cleanup_last_owned_effects" = can_cleanup_last_owned_effects(),
		"can_refresh_ui" = has_generator ? TRUE : FALSE,
	)

/datum/world_edit_manager/proc/build_history_ui_payload()
	return list(
		"history_entries" = get_history_entries_desc(),
	)
