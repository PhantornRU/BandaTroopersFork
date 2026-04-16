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
	return build_ui_data_payload()

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
