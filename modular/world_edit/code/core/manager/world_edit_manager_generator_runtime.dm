/datum/world_edit_manager/proc/build_available_generator_categories(include_non_ready = FALSE)
	var/list/by_category = list()
	for(var/id in GLOB.world_edit_generator_definitions_by_id)
		var/datum/world_edit_generator_definition/definition = GLOB.world_edit_generator_definitions_by_id[id]
		if(!include_non_ready && definition.status != WORLD_EDIT_STATUS_READY)
			continue
		if(!check_rights_for(holder, definition.required_rights))
			continue

		var/category_name = definition.category_ru || "Общее"
		if(!by_category[category_name])
			by_category[category_name] = list()

		by_category[category_name] += list(list(
			"id" = definition.id,
			"name_ru" = definition.name_ru,
			"description_ru" = definition.description_ru,
			"execution_mode" = definition.execution_mode,
			"required_rights" = rights2text(definition.required_rights, " "),
			"supports_preview" = definition.supports_preview ? TRUE : FALSE,
			"status" = definition.status,
		))

	var/list/result = list()
	var/list/category_names = list()
	for(var/category_name in by_category)
		category_names += category_name
	category_names = sortList(category_names)

	for(var/category_name in category_names)
		var/list/entries = by_category[category_name]
		var/list/name_to_entry = list()
		var/list/sort_keys = list()
		for(var/list/entry as anything in entries)
			var/sort_key = "[entry["name_ru"]]#[entry["id"]]"
			sort_keys += sort_key
			name_to_entry[sort_key] = entry
		sort_keys = sortList(sort_keys)

		var/list/sorted_entries = list()
		for(var/sort_key in sort_keys)
			sorted_entries += list(name_to_entry[sort_key])

		result += list(list(
			"category" = category_name,
			"generators" = sorted_entries
		))

	return result

/datum/world_edit_manager/proc/set_generator_by_id(generator_id)
	reset_generator_runtime()
	detach_current_generator()

	var/datum/world_edit_generator_definition/definition = world_edit_get_generator_definition(generator_id)
	if(!definition)
		return FALSE
	if(definition.status != WORLD_EDIT_STATUS_READY)
		return FALSE
	if(!check_rights_for(holder, definition.required_rights))
		return FALSE

	current_definition = definition
	current_generator = new definition.generator_type()
	current_generator.attach(src, definition)
	current_params = definition.default_params?.Copy() || list()
	return TRUE

/datum/world_edit_manager/proc/reset_current_generator()
	reset_generator_runtime()
	detach_current_generator()

/datum/world_edit_manager/proc/configure_current_generator(mob/user)
	if(!holder || !check_rights_for(holder, R_EVENT|R_DEBUG))
		return
	if(!current_generator || !current_definition)
		to_chat(user, SPAN_WARNING("Сначала выберите генератор."))
		return
	if(!check_rights_for(holder, current_definition.required_rights))
		to_chat(user, SPAN_WARNING("Недостаточно прав для настройки этого генератора."))
		return

	var/list/new_params = current_generator.configure_params(user, current_params)
	if(isnull(new_params))
		return
	if(!islist(new_params))
		to_chat(user, SPAN_WARNING("Генератор вернул некорректный набор параметров."))
		return

	current_params = new_params
	last_ui_error = ""
	reset_preview_runtime()
	to_chat(user, SPAN_NOTICE("Параметры генератора обновлены."))

/datum/world_edit_manager/proc/run_preview(mob/user)
	if(!holder || !check_rights_for(holder, R_EVENT|R_DEBUG))
		return fail_preview(user, "Недостаточно прав для предпросмотра World Edit.")
	if(!current_generator || !current_definition)
		return fail_preview(user, "Сначала выберите генератор.")
	if(!current_definition.supports_preview)
		return fail_preview(user, "Для этого генератора предпросмотр не поддерживается.")
	if(!check_rights_for(holder, current_definition.required_rights))
		return fail_preview(user, "Недостаточно прав для предпросмотра этого генератора.")

	var/error_text = current_generator.validate_params(user, current_params)
	if(error_text)
		return fail_preview(user, error_text)

	clear_preview_images()
	var/datum/world_edit_preview_result/result = current_generator.preview(user, current_params)
	if(!istype(result))
		return fail_preview(user, "Генератор вернул некорректный результат предпросмотра.")

	if(length(result.preview_images))
		holder.images += result.preview_images
		preview_images = result.preview_images.Copy()

	last_preview_success = result.success ? TRUE : FALSE
	last_preview_message = result.message
	last_preview_meta = islist(result.meta) ? result.meta.Copy() : list()

	if(result.success)
		mark_preview_state()
		to_chat(user, SPAN_NOTICE(result.message))
	else
		invalidate_preview_state()
		to_chat(user, SPAN_WARNING(result.message))

	return result

/datum/world_edit_manager/proc/run_apply(mob/user)
	if(!holder || !check_rights_for(holder, R_EVENT|R_DEBUG))
		return fail_apply(user, "Недостаточно прав для применения World Edit.")
	if(!current_generator || !current_definition)
		return fail_apply(user, "Сначала выберите генератор.")
	if(!check_rights_for(holder, current_definition.required_rights))
		return fail_apply(user, "Недостаточно прав для применения этого генератора.")

	var/error_text = current_generator.validate_params(user, current_params)
	if(error_text)
		return fail_apply(user, error_text)

	if(current_generator.requires_preview_before_apply && !is_preview_state_valid())
		return fail_apply(user, "Для этого генератора обязательно выполнить предпросмотр с текущими параметрами.")

	var/confirm_text = current_generator.get_apply_confirmation_text(current_params)
	var/answer = tgui_alert(user, confirm_text, "World Edit: Подтверждение", list("Подтвердить", "Отмена"))
	if(answer != "Подтвердить")
		if(current_definition.execution_mode != WORLD_EDIT_EXECUTION_CLICK)
			reset_preview_runtime()
		return null

	var/start_ds = world.time
	var/datum/world_edit_apply_result/result = current_generator.apply(user, current_params)
	if(!istype(result))
		return fail_apply(user, "Генератор вернул некорректный результат применения.")

	var/duration_ds = world.time - start_ds
	var/turf/center_turf = result.center_turf || get_turf(user)
	var/params_short = current_generator.get_params_short(current_params)
	var/result_code = result.success ? "ok" : "error"
	var/datum/world_edit_changeset/changeset
	if(result.success && istype(result.changeset))
		changeset = result.changeset
		if(!length(changeset.generator_id))
			changeset.generator_id = current_definition.id
		if(!islist(changeset.metadata))
			changeset.metadata = list()
		if(center_turf && !changeset.metadata["center_turf"])
			changeset.metadata["center_turf"] = center_turf
		changeset = push_changeset(changeset)

	world_edit_log_operation(
		holder,
		current_definition.id,
		current_definition.required_rights,
		center_turf,
		result.created_count,
		result.deleted_count,
		duration_ds,
		result_code,
		params_short
	)
	add_history_entry(
		current_definition.id,
		result_code,
		result.created_count,
		result.deleted_count,
		center_turf,
		params_short,
		result.message,
		duration_ds * 100,
		build_changeset_history_meta(changeset)
	)

	last_apply_success = result.success ? TRUE : FALSE
	last_apply_message = result.message

	if(result.success)
		to_chat(user, SPAN_NOTICE(result.message))
	else
		to_chat(user, SPAN_WARNING(result.message))

	if(current_definition.execution_mode != WORLD_EDIT_EXECUTION_CLICK)
		reset_preview_runtime()

	return result

/datum/world_edit_manager/proc/fail_preview(mob/user, message)
	clear_preview_images()
	last_preview_success = FALSE
	last_preview_message = message
	last_preview_meta = list()
	invalidate_preview_state()
	to_chat(user, SPAN_WARNING(message))
	return null

/datum/world_edit_manager/proc/fail_apply(mob/user, message)
	last_apply_success = FALSE
	last_apply_message = message
	to_chat(user, SPAN_WARNING(message))
	return null

/datum/world_edit_manager/proc/fail_undo_action(mob/user, action_kind, message)
	last_undo_action = action_kind
	last_undo_success = FALSE
	last_undo_message = message
	to_chat(user, SPAN_WARNING(message))
	return FALSE

/datum/world_edit_manager/proc/undo_last_operation(mob/user)
	if(!holder || !check_rights_for(holder, R_EVENT|R_DEBUG))
		return fail_undo_action(user, "undo", "Недостаточно прав для undo World Edit.")

	var/datum/world_edit_changeset/changeset = get_last_changeset()
	if(!istype(changeset))
		return fail_undo_action(user, "undo", "В session нет записанной операции для undo.")
	if(!changeset.can_undo())
		return fail_undo_action(user, "undo", "Последняя записанная операция не поддерживает undo в этой фазе.")

	var/list/undo_result = world_edit_revert_changeset(changeset)
	var/reverted_count = text2num("[undo_result["reverted_count"]]") || 0
	var/skipped_count = text2num("[undo_result["skipped_count"]]") || 0
	var/outcome = "[undo_result["outcome"] || "none"]"
	var/message = "Undo [changeset.generator_id] ([changeset.undo_policy]): reverted=[reverted_count], skipped=[skipped_count], outcome=[outcome]."
	var/turf/center_turf = changeset.metadata["center_turf"] || get_turf(user)
	var/params_short = "source=[changeset.generator_id]; operation_id=[changeset.operation_id]; policy=[changeset.undo_policy]"
	var/result_code = (outcome == "full") ? "undo_ok" : ((outcome == "partial") ? "undo_partial" : "undo_skipped")

	changeset.created_entries = list()
	changeset.moved_entries = list()
	prune_changeset_stack()
	reset_preview_runtime()

	last_undo_action = "undo"
	last_undo_success = reverted_count > 0 ? TRUE : FALSE
	last_undo_message = message

	world_edit_log_operation(holder, "undo_last_operation", 0, center_turf, 0, reverted_count, 0, result_code, params_short)
	add_history_entry(
		"undo_last_operation",
		result_code,
		0,
		reverted_count,
		center_turf,
		params_short,
		message,
		0,
		list(
			"undo_policy" = changeset.undo_policy,
			"undo_status" = outcome,
			"reverted_count" = reverted_count,
			"skipped_count" = skipped_count,
			"source_operation_id" = changeset.operation_id,
			"source_generator_id" = changeset.generator_id,
		)
	)

	if(reverted_count > 0)
		to_chat(user, SPAN_NOTICE(message))
	else
		to_chat(user, SPAN_WARNING(message))

	return undo_result

/datum/world_edit_manager/proc/cleanup_last_owned_effects(mob/user)
	if(!holder || !check_rights_for(holder, R_EVENT|R_DEBUG))
		return fail_undo_action(user, "cleanup", "Недостаточно прав для cleanup owned effects.")

	var/datum/world_edit_changeset/changeset = get_last_changeset()
	if(!istype(changeset))
		return fail_undo_action(user, "cleanup", "В session нет записанной операции для cleanup owned effects.")
	if(!changeset.can_cleanup_owned_effects())
		return fail_undo_action(user, "cleanup", "Последняя записанная операция не содержит owned effects для cleanup.")

	var/list/cleanup_result = world_edit_cleanup_changeset_owned_effects(changeset)
	var/removed_count = text2num("[cleanup_result["reverted_count"]]") || 0
	var/skipped_count = text2num("[cleanup_result["skipped_count"]]") || 0
	var/outcome = "[cleanup_result["outcome"] || "none"]"
	var/message = "Cleanup owned effects for [changeset.generator_id]: removed=[removed_count], skipped=[skipped_count], outcome=[outcome]."
	var/turf/center_turf = changeset.metadata["center_turf"] || get_turf(user)
	var/params_short = "source=[changeset.generator_id]; operation_id=[changeset.operation_id]"
	var/result_code = (outcome == "full") ? "cleanup_ok" : ((outcome == "partial") ? "cleanup_partial" : "cleanup_skipped")

	changeset.owned_effect_entries = list()
	prune_changeset_stack()
	reset_preview_runtime()

	last_undo_action = "cleanup"
	last_undo_success = removed_count > 0 ? TRUE : FALSE
	last_undo_message = message

	world_edit_log_operation(holder, "cleanup_last_owned_effects", 0, center_turf, 0, removed_count, 0, result_code, params_short)
	add_history_entry(
		"cleanup_last_owned_effects",
		result_code,
		0,
		removed_count,
		center_turf,
		params_short,
		message,
		0,
		list(
			"undo_policy" = changeset.undo_policy,
			"undo_status" = outcome,
			"reverted_count" = removed_count,
			"skipped_count" = skipped_count,
			"source_operation_id" = changeset.operation_id,
			"source_generator_id" = changeset.generator_id,
		)
	)

	if(removed_count > 0)
		to_chat(user, SPAN_NOTICE(message))
	else
		to_chat(user, SPAN_WARNING(message))

	return cleanup_result
