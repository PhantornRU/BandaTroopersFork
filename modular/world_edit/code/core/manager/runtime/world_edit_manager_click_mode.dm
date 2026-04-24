/datum/world_edit_manager/proc/sync_click_intercept_state()
	if(holder?.click_intercept == src)
		click_intercept_owned = TRUE
		return TRUE

	if(click_intercept_owned || placement_click_active || click_intercept_previous)
		// Losing the intercept must tear down any click/runtime state, otherwise stale
		// previews and armed placement sessions survive until another explicit reset.
		reset_preview_runtime()
	else
		click_intercept_previous = null
		click_intercept_owned = FALSE
		placement_click_active = FALSE
	return FALSE

/datum/world_edit_manager/proc/acquire_click_intercept(mode_name)
	if(!holder)
		return FALSE

	if(holder.click_intercept == src)
		click_intercept_owned = TRUE
		return TRUE

	if(holder.click_intercept && holder.click_intercept != src)
		var/answer = tgui_alert(holder.mob, "Сейчас клики перехватывает другой инструмент ([holder.click_intercept]). Перехватить управление для режима '[mode_name]'?", "Панель размещения: перехват клика", list("Да", "Нет"))
		if(answer != "Да")
			return FALSE
		click_intercept_previous = holder.click_intercept
	else
		click_intercept_previous = null

	holder.click_intercept = src
	click_intercept_owned = TRUE
	return TRUE

/datum/world_edit_manager/proc/stop_click_mode()
	return teardown_preview_session_runtime(TRUE, FALSE, FALSE, TRUE)

/datum/world_edit_manager/proc/clear_active_placement_progress(clear_collector_points = FALSE)
	set_placement_anchor_turf(null)
	set_placement_hover_turf(null)
	reset_placement_collector_state(clear_collector_points)
	clear_placement_confirm_arm()
	return TRUE

/datum/world_edit_manager/proc/refresh_runtime_after_config_change(clear_placement_progress = FALSE, clear_collector_points = FALSE)
	var/should_stop_click_mode = FALSE
	if(sync_click_intercept_state() && placement_click_active && !supports_current_placement_ux())
		should_stop_click_mode = TRUE
	return teardown_preview_session_runtime(TRUE, clear_placement_progress, clear_collector_points, should_stop_click_mode)

/datum/world_edit_manager/proc/has_active_safe_placement_preview()
	var/datum/world_edit_placement_candidate/candidate = get_placement_preview_candidate()
	if(!placement_click_active || !supports_current_placement_ux())
		return FALSE
	return (istype(candidate) && candidate.is_confirm_ready() && is_preview_state_valid()) ? TRUE : FALSE

/datum/world_edit_manager/proc/rebuild_runtime_after_generator_config_change(mob/user, preserve_active_placement = FALSE, clear_placement_progress = FALSE, clear_collector_points = FALSE, preserve_confirm_arm = FALSE)
	if(preserve_active_placement && placement_click_active && supports_current_placement_ux())
		return refresh_active_placement_preview_after_live_config_change(user, preserve_confirm_arm)

	refresh_runtime_after_config_change(clear_placement_progress, clear_collector_points)
	return TRUE

/datum/world_edit_manager/proc/InterceptClickOn(mob/user, params, atom/object)
	if(!sync_click_intercept_state())
		return FALSE
	if(!holder || holder != user?.client)
		return FALSE
	if(!current_generator || !current_definition)
		return FALSE
	if(!check_rights_for(holder, current_definition.required_rights))
		return FALSE
	if(placement_click_active)
		return handle_safe_placement_click(user, params, object)
	if(current_definition.execution_mode != WORLD_EDIT_EXECUTION_CLICK)
		return FALSE
	return current_generator.InterceptClickOn(user, params, object)
