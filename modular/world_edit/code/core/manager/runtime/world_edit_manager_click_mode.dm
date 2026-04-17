/datum/world_edit_manager/proc/sync_click_intercept_state()
	if(holder?.click_intercept == src)
		click_intercept_owned = TRUE
		return TRUE

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
		var/answer = tgui_alert(holder.mob, "Сейчас клики перехватывает другой инструмент ([holder.click_intercept]). Перехватить управление для режима '[mode_name]'?", "World Edit: Перехват клика", list("Да", "Нет"))
		if(answer != "Да")
			return FALSE
		click_intercept_previous = holder.click_intercept
	else
		click_intercept_previous = null

	holder.click_intercept = src
	click_intercept_owned = TRUE
	return TRUE

/datum/world_edit_manager/proc/stop_click_mode()
	current_generator?.disable_click_mode()
	reset_placement_runtime()

	if(!click_intercept_owned || !holder)
		click_intercept_previous = null
		click_intercept_owned = FALSE
		return

	if(holder.click_intercept == src)
		if(click_intercept_previous && !QDELETED(click_intercept_previous))
			holder.click_intercept = click_intercept_previous
		else
			holder.click_intercept = null

	click_intercept_previous = null
	click_intercept_owned = FALSE

/datum/world_edit_manager/proc/refresh_runtime_after_config_change(clear_placement_progress = FALSE, clear_collector_points = FALSE)
	clear_preview_plan_state()
	if(clear_placement_progress)
		placement_anchor_turf = null
		reset_placement_collector_state(clear_collector_points)

	if(sync_click_intercept_state() && placement_click_active && !supports_current_placement_ux())
		stop_click_mode()

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
		return handle_safe_placement_click_v2(user, params, object)
	if(current_definition.execution_mode != WORLD_EDIT_EXECUTION_CLICK)
		return FALSE
	return current_generator.InterceptClickOn(user, params, object)
