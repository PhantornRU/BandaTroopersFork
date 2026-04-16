/datum/world_edit_manager/tgui_interact(mob/user, datum/tgui/ui)
	if(!holder || QDELETED(holder) || holder != user?.client)
		return
	if(!check_rights_for(holder, R_DEBUG))
		return
	ensure_default_generator_selected()

	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "WorldEditPanel")
		ui.open()

/datum/world_edit_manager/ui_state(mob/user)
	return GLOB.admin_state

/datum/world_edit_manager/ui_close(mob/user)
	. = ..()
	reset_preview_runtime()

/datum/world_edit_manager/ui_static_data(mob/user)
	if(!holder || holder != user?.client || !check_rights_for(holder, R_DEBUG))
		return list()

	var/list/data = list()
	data["categories"] = build_available_generator_categories()
	return data

/datum/world_edit_manager/ui_data(mob/user)
	if(!holder || holder != user?.client || !check_rights_for(holder, R_DEBUG))
		return list()

	ensure_preset_cache_loaded()
	ensure_blueprint_cache_loaded()
	ensure_default_generator_selected()

	var/list/data = list()
	var/has_generator = (current_definition && current_generator) ? TRUE : FALSE
	var/list/ui_fields = get_normalized_ui_fields()
	var/requires_preview = current_generator?.requires_preview_before_apply ? TRUE : FALSE
	var/list/placement_modes = build_placement_mode_options()
	var/list/placement_shapes = build_placement_shape_options()
	var/list/placement_shape_fields = build_current_placement_shape_fields()
	var/placement_supported = length(placement_modes) > 0
	var/placement_shape_supported = length(placement_shapes) > 0
	var/click_mode_active = sync_click_intercept_state()
	var/can_run_preview = has_generator && current_definition?.supports_preview && !click_mode_active
	var/can_run_apply = has_generator && (!requires_preview || is_preview_state_valid()) && !click_mode_active

	data["has_generator"] = has_generator
	data["current_generator_id"] = current_definition?.id
	data["current_generator_name"] = current_definition?.name_ru
	data["current_generator_category"] = current_definition?.category_ru
	data["current_generator_description"] = current_definition?.description_ru
	data["current_generator_execution_mode"] = current_definition?.execution_mode
	data["current_generator_required_rights"] = current_definition ? rights2text(current_definition.required_rights, " ") : ""
	data["current_generator_supports_preview"] = current_definition?.supports_preview ? TRUE : FALSE
	data["requires_preview_before_apply"] = requires_preview

	data["current_params_text"] = GLOB.world_edit_logging.params_to_text(current_params, 600)
	data["ui_fields"] = ui_fields
	data["runtime_status"] = current_generator?.get_runtime_status() || list()
	data["placement_supported"] = placement_supported ? TRUE : FALSE
	data["placement_active"] = (placement_click_active && click_mode_active) ? TRUE : FALSE
	data["placement_mode"] = get_effective_placement_mode() || "single"
	data["placement_mode_options"] = placement_modes
	data["placement_shape_supported"] = placement_shape_supported ? TRUE : FALSE
	data["placement_shape"] = get_effective_placement_shape() || WORLD_EDIT_SHAPE_POINT
	data["placement_shape_options"] = placement_shapes
	data["placement_shape_fields"] = placement_shape_fields
	data["placement_shape_uses_anchor_pair"] = placement_mode_uses_anchor_pair(get_effective_placement_shape()) ? TRUE : FALSE
	data["placement_interaction_kind"] = get_placement_interaction_kind()
	data["placement_interaction_label"] = get_placement_interaction_label()
	data["placement_shape_rollout_stage"] = get_placement_shape_rollout_stage()
	data["placement_collector_point_count"] = get_placement_collector_point_count()
	data["placement_collector_min_points"] = get_placement_collector_min_points()
	data["placement_collector_max_points"] = get_placement_collector_max_points()
	data["placement_collector_origin"] = get_placement_collector_origin_text()
	data["placement_collector_points_text"] = get_placement_collector_points_text()
	data["placement_collector_summary"] = get_placement_collector_summary()
	data["can_finish_placement_collection"] = (click_mode_active && is_current_placement_collector() && get_placement_collector_point_count() >= get_placement_collector_min_points()) ? TRUE : FALSE
	data["placement_supports_direction"] = supports_current_placement_direction() ? TRUE : FALSE
	data["placement_dir"] = GLOB.world_edit_helpers.dir_to_label(get_effective_placement_dir())
	data["placement_dir_uses_facing"] = placement_dir_uses_facing ? TRUE : FALSE
	data["placement_dir_options"] = build_placement_dir_options()
	data["placement_anchor"] = get_placement_anchor_desc()
	data["can_start_placement_mode"] = (supports_current_placement_ux() && !click_mode_active) ? TRUE : FALSE
	data["can_manage_presets"] = can_manage_current_generator_presets()
	data["preset_entries"] = get_current_generator_presets()
	data["blueprint_entries"] = get_blueprint_entries_for_ui()
	data["active_blueprint_id"] = get_active_blueprint_id()
	data["can_save_blueprint_from_plan"] = can_save_blueprint_from_current_plan()
	data["confirm_before_apply"] = confirm_before_apply ? TRUE : FALSE
	data["last_ui_error"] = last_ui_error || ""

	data["preview_valid"] = is_preview_state_valid()
	data["preview_success"] = last_preview_success
	data["preview_message"] = last_preview_message
	data["preview_meta"] = last_preview_meta || list()

	data["last_apply_success"] = last_apply_success
	data["last_apply_message"] = last_apply_message
	data["last_undo_success"] = last_undo_success
	data["last_undo_message"] = last_undo_message
	data["last_undo_action"] = last_undo_action
	data["last_changeset"] = build_last_changeset_summary()

	data["click_mode_active"] = click_mode_active ? TRUE : FALSE
	data["can_run_preview"] = can_run_preview ? TRUE : FALSE
	data["can_run_apply"] = can_run_apply ? TRUE : FALSE
	data["can_stop_click_mode"] = click_mode_active ? TRUE : FALSE
	data["can_undo_last_operation"] = can_undo_last_operation()
	data["can_cleanup_last_owned_effects"] = can_cleanup_last_owned_effects()
	data["can_refresh_ui"] = has_generator ? TRUE : FALSE
	data["history_entries"] = get_history_entries_desc()
	return data

/datum/world_edit_manager/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	if(!holder || holder != ui.user?.client)
		return
	if(!check_rights_for(holder, R_DEBUG))
		return
	if(handle_generator_ui_action(ui.user, action, params))
		return TRUE
	if(handle_preset_ui_action(ui.user, action, params))
		return TRUE
	if(handle_blueprint_ui_action(ui.user, action, params))
		return TRUE
	if(handle_placement_ui_action(ui.user, action, params))
		return TRUE
	if(handle_runtime_ui_action(ui.user, action, params))
		return TRUE
	return FALSE
