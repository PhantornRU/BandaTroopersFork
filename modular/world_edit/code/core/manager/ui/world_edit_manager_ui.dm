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
