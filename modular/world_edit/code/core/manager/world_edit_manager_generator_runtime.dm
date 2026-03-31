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
	reset_placement_runtime(TRUE)
	placement_dir = current_generator?.get_default_placement_direction() || NORTH
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

/datum/world_edit_manager/proc/build_safe_placement_anchor_turfs(mode, turf/start_turf, turf/end_turf)
	if("[mode]" == "line")
		return world_edit_collect_line_turfs(start_turf, end_turf)
	if("[mode]" == "rectangle")
		return world_edit_collect_rectangle_turfs(start_turf, end_turf)
	if(!end_turf)
		return list()
	return list(end_turf)

/datum/world_edit_manager/proc/build_safe_placement_preview_message(datum/world_edit_plan/plan)
	var/list/metadata = plan?.metadata || list()
	var/list/placements = plan?.placements || list()
	var/anchor_count = metadata["anchor_count"] || 1
	var/entry_count = metadata["entry_count"] || length(placements)
	var/mode = metadata["placement_mode"] || get_effective_placement_mode() || "single"
	var/message = "Placement preview ready: mode=[mode], anchors=[anchor_count], entries=[entry_count]."
	if(metadata["placement_dir_label"])
		message = "Placement preview ready: mode=[mode], anchors=[anchor_count], entries=[entry_count], dir=[metadata["placement_dir_label"]]."
	return message

/datum/world_edit_manager/proc/build_safe_placement_confirm_text(datum/world_edit_plan/plan)
	var/list/metadata = plan?.metadata || list()
	var/list/placements = plan?.placements || list()
	var/anchor_count = metadata["anchor_count"] || 1
	var/entry_count = metadata["entry_count"] || length(placements)
	var/mode = metadata["placement_mode"] || get_effective_placement_mode() || "single"
	var/dir_suffix = ""
	if(metadata["placement_dir_label"])
		dir_suffix = ", dir=[metadata["placement_dir_label"]]"
	return "Apply [current_definition?.name_ru || current_definition?.id] placement? mode=[mode], anchors=[anchor_count], entries=[entry_count][dir_suffix]."

/datum/world_edit_manager/proc/record_apply_result(mob/user, datum/world_edit_apply_result/result, duration_ds)
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

	return result

/datum/world_edit_manager/proc/start_safe_placement_mode(mob/user)
	if(!holder || !check_rights_for(holder, R_EVENT|R_DEBUG))
		return fail_apply(user, "Недостаточно прав для placement mode World Edit.")
	if(!current_generator || !current_definition)
		return fail_apply(user, "Сначала выберите генератор.")
	if(!supports_current_placement_ux())
		return fail_apply(user, "Для текущего генератора safe placement UX в этой фазе недоступен.")

	var/placement_error_text = current_generator.validate_params(user, current_params)
	if(placement_error_text)
		return fail_apply(user, placement_error_text)
	if(!acquire_click_intercept("Safe Placement"))
		return fail_apply(user, "Перехват клика не активирован.")

	placement_click_active = TRUE
	placement_anchor_turf = null
	clear_preview_plan_state()
	sync_click_intercept_state()

	var/mode = get_effective_placement_mode() || "single"
	var/dir_suffix = supports_current_placement_direction() ? " DIR=[world_edit_dir_to_label(get_effective_placement_dir())]." : "."
	if(placement_mode_uses_anchor_pair(mode))
		to_chat(user, SPAN_NOTICE("Placement mode active: first LMB sets anchor, second LMB previews and applies. MMB resets the pending anchor[dir_suffix]"))
	else
		to_chat(user, SPAN_NOTICE("Placement mode active: LMB previews and applies at the clicked turf. MMB resets the pending anchor[dir_suffix]"))
	return TRUE

/datum/world_edit_manager/proc/handle_safe_placement_click(mob/user, params, atom/object)
	if(!placement_click_active || !supports_current_placement_ux())
		return FALSE

	var/list/modifiers = params2list(params)
	if(LAZYACCESS(modifiers, MIDDLE_CLICK))
		placement_anchor_turf = null
		clear_preview_plan_state()
		to_chat(user, SPAN_NOTICE("Pending placement anchor cleared."))
		return TRUE

	if(!LAZYACCESS(modifiers, LEFT_CLICK))
		return TRUE

	var/turf/clicked_turf = get_turf(object)
	if(!clicked_turf)
		return TRUE

	var/mode = get_effective_placement_mode()
	if(!length(mode))
		return TRUE

	if(placement_mode_uses_anchor_pair(mode) && !placement_anchor_turf)
		placement_anchor_turf = clicked_turf
		clear_preview_plan_state()
		world_edit_apply_turf_preview(src, list(clicked_turf))
		to_chat(user, SPAN_NOTICE("Placement anchor set: [clicked_turf.x],[clicked_turf.y],[clicked_turf.z]. Select the second point."))
		return TRUE

	var/turf/start_turf = placement_mode_uses_anchor_pair(mode) ? placement_anchor_turf : clicked_turf
	var/turf/end_turf = clicked_turf
	placement_anchor_turf = null

	var/list/anchor_turfs = build_safe_placement_anchor_turfs(mode, start_turf, end_turf)
	if(!length(anchor_turfs))
		last_preview_success = FALSE
		last_preview_message = "Unable to build a valid placement footprint."
		last_preview_meta = list()
		invalidate_preview_state()
		to_chat(user, SPAN_WARNING(last_preview_message))
		return TRUE
	if(length(anchor_turfs) > WORLD_EDIT_PLACEMENT_MAX_ANCHORS)
		last_preview_success = FALSE
		last_preview_message = "Requested footprint exceeds the safe anchor cap ([WORLD_EDIT_PLACEMENT_MAX_ANCHORS])."
		last_preview_meta = list()
		invalidate_preview_state()
		to_chat(user, SPAN_WARNING(last_preview_message))
		return TRUE

	clear_preview_plan_state()
	var/datum/world_edit_plan/plan = current_generator.build_placement_plan(user, current_params, list(
		"mode" = mode,
		"anchor_turfs" = anchor_turfs,
		"start_turf" = start_turf,
		"end_turf" = end_turf,
		"direction" = get_effective_placement_dir(),
	))
	if(!istype(plan))
		last_preview_success = FALSE
		last_preview_message = "Unable to build the placement plan."
		last_preview_meta = list()
		invalidate_preview_state()
		to_chat(user, SPAN_WARNING(last_preview_message))
		return TRUE
	if(plan.metadata["error"])
		last_preview_success = FALSE
		last_preview_message = "[plan.metadata["error"]]"
		last_preview_meta = plan.metadata.Copy()
		invalidate_preview_state()
		to_chat(user, SPAN_WARNING(last_preview_message))
		return TRUE
	if(!length(plan.placements) && !length(plan.deletions))
		last_preview_success = FALSE
		last_preview_message = "Placement footprint contains no valid actions."
		last_preview_meta = plan.metadata.Copy()
		invalidate_preview_state()
		to_chat(user, SPAN_WARNING(last_preview_message))
		return TRUE

	current_generator.current_plan = plan
	last_preview_success = TRUE
	last_preview_message = build_safe_placement_preview_message(plan)
	last_preview_meta = plan.metadata.Copy()
	preview_images = world_edit_build_turf_preview_images(plan.affected_turfs)
	if(length(preview_images))
		holder.images += preview_images
	mark_preview_state()
	to_chat(user, SPAN_NOTICE(last_preview_message))

	var/confirm_text = build_safe_placement_confirm_text(plan)
	var/answer = tgui_alert(user, confirm_text, "World Edit: Placement Confirm", list("Подтвердить", "Отмена"))
	if(answer != "Подтвердить")
		clear_preview_plan_state()
		return TRUE

	var/start_ds = world.time
	var/datum/world_edit_apply_result/result = current_generator.apply(user, current_params)
	if(!istype(result))
		clear_preview_plan_state()
		return fail_apply(user, "Генератор вернул некорректный результат применения.")

	record_apply_result(user, result, world.time - start_ds)
	clear_preview_plan_state()
	if(mode == "single")
		stop_click_mode()
	else if(result.success)
		sync_click_intercept_state()
		placement_click_active = click_intercept_owned ? TRUE : FALSE
		to_chat(user, SPAN_NOTICE("Placement mode remains active."))
	return TRUE

/datum/world_edit_manager/proc/run_preview(mob/user)
	if(!holder || !check_rights_for(holder, R_EVENT|R_DEBUG))
		return fail_preview(user, "Недостаточно прав для предпросмотра World Edit.")
	if(!current_generator || !current_definition)
		return fail_preview(user, "Сначала выберите генератор.")
	if(!current_definition.supports_preview)
		return fail_preview(user, "Для этого генератора предпросмотр не поддерживается.")
	if(!check_rights_for(holder, current_definition.required_rights))
		return fail_preview(user, "Недостаточно прав для предпросмотра этого генератора.")

	if(click_intercept_owned)
		return fail_preview(user, "Остановите активный click/placement mode перед обычным preview.")

	var/error_text = current_generator.validate_params(user, current_params)
	if(error_text)
		return fail_preview(user, error_text)

	clear_preview_plan_state()
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

	if(click_intercept_owned)
		return fail_apply(user, "Остановите активный click/placement mode перед обычным apply.")

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

	record_apply_result(user, result, world.time - start_ds)

	if(current_definition.execution_mode != WORLD_EDIT_EXECUTION_CLICK)
		reset_preview_runtime()

	return result

/datum/world_edit_manager/proc/fail_preview(mob/user, message)
	clear_preview_plan_state()
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
