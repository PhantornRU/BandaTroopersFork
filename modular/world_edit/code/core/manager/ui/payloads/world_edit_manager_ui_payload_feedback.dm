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
	)

/datum/world_edit_manager/proc/build_history_ui_payload()
	return list(
		"history_entries" = get_history_entries_desc(),
	)
