/datum/world_edit_manager/proc/get_history_entries_desc()
	if(!length(history_entries))
		return list()

	var/list/desc_entries = list()
	for(var/i = length(history_entries), i >= 1, i--)
		desc_entries += list(history_entries[i])
	return desc_entries

/datum/world_edit_manager/proc/add_history_entry(generator_id, result_code, created_count, deleted_count, turf/center_turf, params_short, message = "", duration_ms = 0, list/extra_data = null)
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
	if(islist(extra_data))
		for(var/key in extra_data)
			entry[key] = extra_data[key]
	history_entries += list(entry)
	while(length(history_entries) > WORLD_EDIT_HISTORY_LIMIT)
		history_entries.Cut(1, 2)
	return entry

/datum/world_edit_manager/proc/prune_changeset_stack()
	if(!islist(changeset_entries))
		changeset_entries = list()
		return

	while(length(changeset_entries))
		var/datum/world_edit_changeset/changeset = changeset_entries[length(changeset_entries)]
		if(istype(changeset) && !changeset.is_empty())
			break

		changeset_entries.Cut(length(changeset_entries), length(changeset_entries) + 1)
		if(istype(changeset))
			qdel(changeset)

/datum/world_edit_manager/proc/push_changeset(datum/world_edit_changeset/changeset)
	if(!istype(changeset))
		return null
	if(changeset.is_empty())
		qdel(changeset)
		return null

	if(!islist(changeset_entries))
		changeset_entries = list()

	changeset_entries += list(changeset)
	while(length(changeset_entries) > WORLD_EDIT_HISTORY_LIMIT)
		var/datum/world_edit_changeset/old_changeset = changeset_entries[1]
		changeset_entries.Cut(1, 2)
		if(istype(old_changeset))
			qdel(old_changeset)
	return changeset

/datum/world_edit_manager/proc/get_last_changeset()
	prune_changeset_stack()
	if(!length(changeset_entries))
		return null
	return changeset_entries[length(changeset_entries)]

/datum/world_edit_manager/proc/build_changeset_history_meta(datum/world_edit_changeset/changeset)
	var/list/meta = list(
		"undo_policy" = WORLD_EDIT_UNDO_NONE,
		"undo_status" = "not_available",
	)
	if(!istype(changeset))
		return meta

	meta["operation_id"] = changeset.operation_id
	meta["undo_policy"] = changeset.undo_policy
	meta["created_entries"] = length(changeset.created_entries)
	meta["moved_entries"] = length(changeset.moved_entries)
	meta["owned_effect_entries"] = length(changeset.owned_effect_entries)
	meta["undo_status"] = changeset.can_undo() ? "available" : (changeset.can_cleanup_owned_effects() ? "cleanup_available" : "not_available")
	return meta

/datum/world_edit_manager/proc/build_last_changeset_summary()
	var/datum/world_edit_changeset/changeset = get_last_changeset()
	if(!istype(changeset))
		return null

	return list(
		"operation_id" = changeset.operation_id,
		"generator_id" = changeset.generator_id,
		"undo_policy" = changeset.undo_policy,
		"created_entries" = length(changeset.created_entries),
		"moved_entries" = length(changeset.moved_entries),
		"owned_effect_entries" = length(changeset.owned_effect_entries),
		"created_at" = changeset.created_at,
		"can_undo" = changeset.can_undo() ? TRUE : FALSE,
		"can_cleanup" = changeset.can_cleanup_owned_effects() ? TRUE : FALSE,
		"undo_status" = changeset.can_undo() ? "available" : (changeset.can_cleanup_owned_effects() ? "cleanup_available" : "not_available"),
	)

/datum/world_edit_manager/proc/can_undo_last_operation()
	var/datum/world_edit_changeset/changeset = get_last_changeset()
	return changeset?.can_undo() ? TRUE : FALSE

/datum/world_edit_manager/proc/can_cleanup_last_owned_effects()
	var/datum/world_edit_changeset/changeset = get_last_changeset()
	return changeset?.can_cleanup_owned_effects() ? TRUE : FALSE

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
