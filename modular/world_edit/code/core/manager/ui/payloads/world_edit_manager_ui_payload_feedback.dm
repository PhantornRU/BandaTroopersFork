/datum/world_edit_manager/proc/build_feedback_ui_payload()
	append_runtime_trace("ui_feedback:preview_valid:start")
	var/preview_valid = is_preview_state_valid()
	append_runtime_trace("ui_feedback:preview_valid:done", "value=[preview_valid]")
	append_runtime_trace("ui_feedback:runtime_status:start")
	var/list/runtime_status = build_runtime_status_entries()
	append_runtime_trace("ui_feedback:runtime_status:done", "count=[length(runtime_status)]")
	var/list/runtime_trace = build_runtime_trace_payload()
	append_runtime_trace("ui_feedback:last_changeset:start")
	var/list/last_changeset = build_last_changeset_summary()
	append_runtime_trace("ui_feedback:last_changeset:done", "present=[last_changeset ? TRUE : FALSE]")
	return list(
		"confirm_before_apply" = confirm_before_apply ? TRUE : FALSE,
		"last_ui_error" = last_ui_error || "",
		"preview_valid" = preview_valid,
		"preview_success" = last_preview_success,
		"preview_message" = last_preview_message,
		"preview_meta" = last_preview_meta || list(),
		"runtime_status" = runtime_status,
		"runtime_trace" = runtime_trace,
		"last_apply_success" = last_apply_success,
		"last_apply_message" = last_apply_message,
		"last_undo_success" = last_undo_success,
		"last_undo_message" = last_undo_message,
		"last_changeset" = last_changeset,
	)

/datum/world_edit_manager/proc/build_actionability_ui_payload(has_generator, requires_preview, click_mode_active)
	append_runtime_trace("ui_actionability:start")
	var/can_run_preview = has_generator && current_definition?.supports_preview && !click_mode_active
	var/can_run_apply = has_generator && (!requires_preview || is_preview_state_valid()) && !click_mode_active
	var/list/payload = list(
		"click_mode_active" = click_mode_active ? TRUE : FALSE,
		"can_run_preview" = can_run_preview ? TRUE : FALSE,
		"can_run_apply" = can_run_apply ? TRUE : FALSE,
		"can_stop_click_mode" = click_mode_active ? TRUE : FALSE,
		"can_undo_last_operation" = can_undo_last_operation(),
		"can_cleanup_last_owned_effects" = can_cleanup_last_owned_effects(),
	)
	append_runtime_trace("ui_actionability:done", "can_apply=[can_run_apply] can_undo=[payload["can_undo_last_operation"]] can_cleanup=[payload["can_cleanup_last_owned_effects"]]")
	return payload

/datum/world_edit_manager/proc/build_history_ui_payload()
	append_runtime_trace("ui_history:start")
	var/list/history_entries = get_history_entries_desc()
	append_runtime_trace("ui_history:done", "count=[length(history_entries)]")
	return list(
		"history_entries" = history_entries,
	)
