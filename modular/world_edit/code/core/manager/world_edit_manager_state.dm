/datum/world_edit_manager/proc/get_history_entries_desc()
	if(!length(history_entries))
		return list()

	var/list/desc_entries = list()
	for(var/i = length(history_entries), i >= 1, i--)
		desc_entries += list(history_entries[i])
	return desc_entries

/datum/world_edit_manager/proc/add_history_entry(generator_id, result_code, created_count, deleted_count, turf/center_turf, params_short, message = "", duration_ms = 0)
	var/list/entry = list(
		"time" = time_stamp(),
		"generator_id" = generator_id,
		"result" = result_code,
		"created_count" = created_count,
		"deleted_count" = deleted_count,
		"center_turf" = center_turf ? "[center_turf.x],[center_turf.y],[center_turf.z]" : "n/a",
		"params_short" = params_short,
		"message" = message,
		"duration_ms" = duration_ms
	)
	history_entries += list(entry)
	while(length(history_entries) > WORLD_EDIT_HISTORY_LIMIT)
		history_entries.Cut(1, 2)

/datum/world_edit_manager/proc/mark_preview_state()
	preview_valid = TRUE
	preview_generator_id = current_definition?.id
	preview_params_signature = world_edit_params_to_text(current_params, 400)

/datum/world_edit_manager/proc/invalidate_preview_state()
	preview_valid = FALSE
	preview_generator_id = null
	preview_params_signature = null

/datum/world_edit_manager/proc/is_preview_state_valid()
	if(!preview_valid)
		return FALSE
	if(preview_generator_id != current_definition?.id)
		return FALSE
	if(preview_params_signature != world_edit_params_to_text(current_params, 400))
		return FALSE
	return TRUE

/datum/world_edit_manager/proc/clear_preview_images()
	if(holder && length(preview_images))
		holder.images -= preview_images
	preview_images = list()
	current_generator?.cleanup_preview(holder?.mob)

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

/datum/world_edit_manager/proc/InterceptClickOn(mob/user, params, atom/object)
	if(!click_intercept_owned)
		return FALSE
	if(!holder || holder != user?.client)
		return FALSE
	if(!current_generator || !current_definition)
		return FALSE
	if(!check_rights_for(holder, current_definition.required_rights))
		return FALSE
	if(current_definition.execution_mode != WORLD_EDIT_EXECUTION_CLICK)
		return FALSE
	return current_generator.InterceptClickOn(user, params, object)
