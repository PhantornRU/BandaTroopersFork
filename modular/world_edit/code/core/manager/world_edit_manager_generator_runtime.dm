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
		return null

	var/start_ds = world.time
	var/datum/world_edit_apply_result/result = current_generator.apply(user, current_params)
	if(!istype(result))
		return fail_apply(user, "Генератор вернул некорректный результат применения.")

	var/duration_ds = world.time - start_ds
	var/turf/center_turf = result.center_turf || get_turf(user)
	var/params_short = current_generator.get_params_short(current_params)
	var/result_code = result.success ? "ok" : "error"
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
		duration_ds * 100
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
