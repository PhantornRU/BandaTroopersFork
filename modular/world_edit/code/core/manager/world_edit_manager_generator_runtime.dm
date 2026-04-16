/datum/world_edit_manager/proc/build_available_generator_categories(include_non_ready = FALSE)
	var/list/by_category = list()
	for(var/id in GLOB.world_edit_registry.definitions_by_id)
		var/datum/world_edit_generator_definition/definition = GLOB.world_edit_registry.definitions_by_id[id]
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

/datum/world_edit_manager/proc/ensure_default_generator_selected()
	if(current_definition && current_generator)
		return TRUE

	var/list/categories = build_available_generator_categories()
	for(var/list/category as anything in categories)
		var/list/generators = category["generators"]
		if(!islist(generators) || !length(generators))
			continue

		for(var/list/generator_entry as anything in generators)
			if(set_generator_by_id(generator_entry["id"]))
				return TRUE

	return FALSE

/datum/world_edit_manager/proc/set_generator_by_id(generator_id, preserve_click_mode = FALSE)
	var/datum/world_edit_generator_definition/definition = GLOB.world_edit_registry.get_generator_definition(generator_id)
	if(!definition)
		return FALSE
	if(definition.status != WORLD_EDIT_STATUS_READY)
		return FALSE
	if(!check_rights_for(holder, definition.required_rights))
		return FALSE

	var/keep_active_placement = preserve_click_mode && is_safe_placement_mode_active()

	if(current_definition?.id)
		save_current_generator_context()

	if(keep_active_placement)
		clear_preview_plan_state()
		reset_apply_feedback()
		last_ui_error = ""
		current_generator?.disable_click_mode()
	else
		reset_generator_runtime()
	detach_current_generator()

	current_definition = definition
	current_generator = new definition.generator_type()
	current_generator.attach(src, definition)
	current_params = definition.default_params?.Copy() || list()
	reset_placement_runtime(TRUE)
	restore_generator_context(definition.id)
	apply_shared_placement_prefs_to_current_generator()
	if(keep_active_placement)
		if(sync_click_intercept_state() && supports_current_placement_ux())
			placement_click_active = click_intercept_owned ? TRUE : FALSE
		else
			stop_click_mode()
	return TRUE

/datum/world_edit_manager/proc/reset_current_generator()
	var/current_generator_id = current_definition?.id
	if(current_generator_id)
		clear_generator_context(current_generator_id)
	reset_generator_runtime()
	detach_current_generator()

/datum/world_edit_manager/proc/configure_current_generator(mob/user)
	if(!holder || !check_rights_for(holder, R_DEBUG))
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

	if(is_safe_placement_mode_active())
		new_params = preserve_active_placement_runtime_params(new_params)

	current_params = new_params
	save_current_generator_context()
	last_ui_error = ""
	refresh_runtime_after_config_change()
	to_chat(user, SPAN_NOTICE("Параметры генератора обновлены."))

/datum/world_edit_manager/proc/build_safe_placement_anchor_turfs(shape_id, turf/start_turf, turf/end_turf)
	return GLOB.world_edit_placement_shapes.world_edit_build_shape_turfs(shape_id, start_turf, end_turf, current_params, supports_current_placement_direction() ? get_effective_placement_dir() : NORTH)

/datum/world_edit_manager/proc/get_placement_collector_absolute_turfs(turf/origin_turf)
	var/list/turfs = list()
	if(!istype(origin_turf))
		return turfs

	for(var/list/point as anything in get_placement_collector_points())
		var/target_x = origin_turf.x + text2num("[point["x"]]")
		var/target_y = origin_turf.y + text2num("[point["y"]]")
		var/turf/target_turf = locate(target_x, target_y, origin_turf.z)
		if(istype(target_turf))
			turfs += target_turf
	return turfs

/datum/world_edit_manager/proc/update_placement_collector_runtime_state(mob/user, turf/preview_turf, message_prefix = "")
	var/shape_id = get_effective_placement_shape()
	var/min_points = get_placement_collector_min_points(shape_id)
	var/point_count = get_placement_collector_point_count()
	var/turf/origin_turf = get_placement_collector_origin_turf() || placement_anchor_turf || preview_turf
	var/list/collector_turfs = get_placement_collector_absolute_turfs(origin_turf)

	clear_preview_plan_state()
	last_preview_meta = list(
		"collector_point_count" = point_count,
		"collector_min_points" = min_points,
		"collector_points_text" = current_params["shape_points_text"] || "",
		"collector_origin" = get_placement_collector_origin_text() || "",
	)

	if(point_count < min_points)
		last_preview_success = FALSE
		last_preview_message = "[message_prefix]Собрано точек: [point_count]/[min_points]."
		invalidate_preview_state()
		if(length(collector_turfs))
			GLOB.world_edit_helpers.apply_turf_preview(src, collector_turfs)
		to_chat(user, SPAN_NOTICE(last_preview_message))
		return FALSE

	var/list/shape_result = build_safe_placement_anchor_turfs(shape_id, origin_turf, preview_turf)
	if(shape_result["error"])
		last_preview_success = FALSE
		last_preview_message = "[shape_result["error"]]"
		last_preview_meta = shape_result["metadata"] || list()
		invalidate_preview_state()
		if(length(collector_turfs))
			GLOB.world_edit_helpers.apply_turf_preview(src, collector_turfs)
		to_chat(user, SPAN_WARNING(last_preview_message))
		return FALSE

	var/list/anchor_turfs = shape_result["turfs"]
	if(!length(anchor_turfs))
		last_preview_success = FALSE
		last_preview_message = "Не удалось построить корректный контур размещения."
		last_preview_meta = shape_result["metadata"] || list()
		invalidate_preview_state()
		to_chat(user, SPAN_WARNING(last_preview_message))
		return FALSE

	clear_preview_plan_state()
	var/list/shape_metadata = shape_result["metadata"]
	if(!islist(shape_metadata))
		shape_metadata = list()
	var/list/collector_shape_metadata = shape_metadata.Copy()
	collector_shape_metadata["collector_point_count"] = point_count
	collector_shape_metadata["collector_origin"] = get_placement_collector_origin_text() || ""
	var/datum/world_edit_plan/plan = current_generator.build_placement_plan(user, current_params, list(
		"mode" = get_effective_placement_mode() || "single",
		"shape" = shape_id,
		"shape_metadata" = collector_shape_metadata,
		"anchor_turfs" = anchor_turfs,
		"start_turf" = origin_turf,
		"end_turf" = preview_turf,
		"direction" = get_effective_placement_dir(),
	))
	if(!istype(plan))
		last_preview_success = FALSE
		last_preview_message = "Не удалось собрать план размещения."
		last_preview_meta = list()
		invalidate_preview_state()
		to_chat(user, SPAN_WARNING(last_preview_message))
		return FALSE
	if(plan.metadata["error"])
		last_preview_success = FALSE
		last_preview_message = "[plan.metadata["error"]]"
		last_preview_meta = plan.metadata.Copy()
		invalidate_preview_state()
		to_chat(user, SPAN_WARNING(last_preview_message))
		return FALSE
	if(!length(plan.placements) && !length(plan.deletions))
		last_preview_success = FALSE
		last_preview_message = "Контур размещения не содержит допустимых действий."
		last_preview_meta = plan.metadata.Copy()
		invalidate_preview_state()
		to_chat(user, SPAN_WARNING(last_preview_message))
		return FALSE

	current_generator.current_plan = plan
	last_preview_success = TRUE
	last_preview_message = build_safe_placement_preview_message(plan)
	last_preview_meta = plan.metadata.Copy()
	preview_images = GLOB.world_edit_helpers.build_turf_preview_images(plan.affected_turfs)
	if(length(preview_images))
		holder.images += preview_images
	mark_preview_state()
	to_chat(user, SPAN_NOTICE(last_preview_message))
	return TRUE

/datum/world_edit_manager/proc/finish_placement_collection(mob/user, turf/preview_turf = null)
	var/shape_id = get_effective_placement_shape()
	if(get_placement_interaction_kind(shape_id) != "collector")
		return FALSE
	if(get_placement_collector_point_count() < get_placement_collector_min_points(shape_id))
		to_chat(user, SPAN_WARNING("Для завершения сбора нужно минимум [get_placement_collector_min_points(shape_id)] точек."))
		return TRUE

	preview_turf = preview_turf || get_placement_collector_origin_turf() || placement_anchor_turf || get_turf(user)
	if(!istype(preview_turf))
		to_chat(user, SPAN_WARNING("Точка начала сбора не задана; сначала добавьте хотя бы одну точку."))
		return TRUE

	if(!update_placement_collector_runtime_state(user, preview_turf, "Завершение сбора. "))
		return TRUE

	var/datum/world_edit_plan/collector_plan = current_generator?.current_plan
	if(!istype(collector_plan) || !is_preview_state_valid())
		to_chat(user, SPAN_WARNING("Собранный контур ещё не готов к применению."))
		return TRUE

	if(confirm_before_apply)
		var/confirm_text = build_safe_placement_confirm_text(collector_plan)
		var/answer = tgui_alert(user, confirm_text, "World Edit: Подтверждение размещения", list("Подтвердить", "Отмена"))
		if(answer != "Подтвердить")
			return TRUE

	var/mode = get_effective_placement_mode()
	var/start_ds = world.time
	var/datum/world_edit_apply_result/collector_result = current_generator.apply(user, current_params)
	if(!istype(collector_result))
		clear_preview_plan_state()
		return fail_apply(user, "Генератор вернул некорректный результат применения.")

	record_apply_result(user, collector_result, world.time - start_ds)
	clear_preview_plan_state()
	reset_placement_collector_state(TRUE)
	placement_anchor_turf = null
	if(mode == "single")
		stop_click_mode()
	else if(collector_result.success)
		sync_click_intercept_state()
		placement_click_active = click_intercept_owned ? TRUE : FALSE
		to_chat(user, SPAN_NOTICE("Сбор остаётся активным и готов к следующему контуру."))
	return TRUE

/datum/world_edit_manager/proc/build_safe_placement_preview_message(datum/world_edit_plan/plan)
	var/list/metadata = plan?.metadata || list()
	var/list/placements = plan?.placements || list()
	var/anchor_count = metadata["anchor_count"] || 1
	var/entry_count = metadata["entry_count"] || length(placements)
	var/mode = metadata["placement_mode"] || get_effective_placement_mode() || "single"
	var/mode_label = mode == "single" ? "один раз" : mode == "repeat" ? "повтор" : "[mode]"
	var/shape_label = metadata["shape_label"] || GLOB.world_edit_placement_shapes.world_edit_get_placement_shape_label(metadata["placement_shape"] || get_effective_placement_shape() || WORLD_EDIT_SHAPE_POINT)
	var/message = "Предпросмотр размещения готов: форма=[shape_label], режим=[mode_label], опор=[anchor_count], действий=[entry_count]."
	if(metadata["collector_point_count"])
		message += " Точек в сборе=[metadata["collector_point_count"]]."
	if(metadata["placement_dir_label"])
		message = "Предпросмотр размещения готов: форма=[shape_label], режим=[mode_label], опор=[anchor_count], действий=[entry_count], направление=[metadata["placement_dir_label"]]."
		if(metadata["collector_point_count"])
			message += " Точек в сборе=[metadata["collector_point_count"]]."
	return message

/datum/world_edit_manager/proc/build_safe_placement_confirm_text(datum/world_edit_plan/plan)
	var/list/metadata = plan?.metadata || list()
	var/list/placements = plan?.placements || list()
	var/anchor_count = metadata["anchor_count"] || 1
	var/entry_count = metadata["entry_count"] || length(placements)
	var/mode = metadata["placement_mode"] || get_effective_placement_mode() || "single"
	var/mode_label = mode == "single" ? "один раз" : mode == "repeat" ? "повтор" : "[mode]"
	var/shape_label = metadata["shape_label"] || GLOB.world_edit_placement_shapes.world_edit_get_placement_shape_label(metadata["placement_shape"] || get_effective_placement_shape() || WORLD_EDIT_SHAPE_POINT)
	var/dir_suffix = ""
	if(metadata["placement_dir_label"])
		dir_suffix = ", направление=[metadata["placement_dir_label"]]"
	return "Применить размещение [current_definition?.name_ru || current_definition?.id]? форма=[shape_label], режим=[mode_label], опор=[anchor_count], действий=[entry_count][dir_suffix]."

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

	GLOB.world_edit_logging.log_operation(
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
	if(!holder || !check_rights_for(holder, R_DEBUG))
		return fail_apply(user, "Недостаточно прав для режима размещения World Edit.")
	if(!current_generator || !current_definition)
		return fail_apply(user, "Сначала выберите генератор.")
	if(!supports_current_placement_ux())
		return fail_apply(user, "Для текущего генератора безопасный режим размещения сейчас недоступен.")

	var/shape_id = get_effective_placement_shape() || WORLD_EDIT_SHAPE_POINT
	var/interaction_kind = get_placement_interaction_kind(shape_id)
	var/placement_error_text = null
	if(interaction_kind != "collector")
		placement_error_text = current_generator.validate_params(user, current_params)
	if(placement_error_text)
		return fail_apply(user, placement_error_text)
	if(!acquire_click_intercept("Safe Placement"))
		return fail_apply(user, "Перехват клика не активирован.")

	placement_click_active = TRUE
	placement_anchor_turf = null
	clear_preview_plan_state()
	sync_click_intercept_state()

	var/shape_label = GLOB.world_edit_placement_shapes.world_edit_get_placement_shape_label(shape_id)
	var/dir_suffix = supports_current_placement_direction() ? " Направление: [GLOB.world_edit_helpers.dir_to_label(get_effective_placement_dir())]." : "."
	if(interaction_kind == "anchor_pair")
		to_chat(user, SPAN_NOTICE("Режим размещения для [shape_label] активен: первый ЛКМ ставит опорную точку, второй ЛКМ строит предпросмотр и применяет результат. СКМ сбрасывает опорную точку.[dir_suffix]"))
	else if(interaction_kind == "collector")
		to_chat(user, SPAN_NOTICE("Режим размещения для [shape_label] активен: ЛКМ добавляет точки, СКМ удаляет последнюю точку, а ПКМ или кнопка завершения подтверждают и применяют результат после валидации контура.[dir_suffix]"))
	else if(interaction_kind == "param_only")
		to_chat(user, SPAN_NOTICE("Режим размещения для [shape_label] активен: ЛКМ использует выбранный тайл как опорную точку и строит контур по текущим параметрам формы. Интерактивный сбор точек в этом режиме не используется.[dir_suffix]"))
	else
		to_chat(user, SPAN_NOTICE("Режим размещения для [shape_label] активен: ЛКМ строит предпросмотр и применяет результат по выбранному тайлу. СКМ сбрасывает опорную точку.[dir_suffix]"))
	return TRUE

/datum/world_edit_manager/proc/handle_safe_placement_click(mob/user, params, atom/object)
	if(!placement_click_active || !supports_current_placement_ux())
		return FALSE

	var/list/modifiers = params2list(params)
	var/turf/clicked_turf = get_turf(object)
	if(!clicked_turf)
		return TRUE
	var/mode = get_effective_placement_mode()
	var/shape_id = get_effective_placement_shape()
	var/interaction_kind = get_placement_interaction_kind(shape_id)

	if(LAZYACCESS(modifiers, MIDDLE_CLICK))
		var/list/collector_points = get_placement_collector_points()
		if(interaction_kind == "collector")
			if(!length(collector_points))
				placement_anchor_turf = null
				clear_placement_collector_origin()
				clear_placement_collector_points()
				clear_preview_plan_state()
				to_chat(user, SPAN_NOTICE("Сбор очищен."))
				return TRUE

			collector_points.Cut(length(collector_points), length(collector_points) + 1)
			set_placement_collector_points(collector_points)
			if(length(collector_points))
				placement_anchor_turf = get_placement_collector_origin_turf()
				update_placement_collector_runtime_state(user, clicked_turf, "Последняя точка удалена. ")
			else
				placement_anchor_turf = null
				clear_placement_collector_origin()
				clear_placement_collector_points()
				clear_preview_plan_state()
				last_preview_success = FALSE
				last_preview_message = "Сбор очищен."
				last_preview_meta = list()
				invalidate_preview_state()
				to_chat(user, SPAN_NOTICE(last_preview_message))
			return TRUE

		placement_anchor_turf = null
		clear_preview_plan_state()
		to_chat(user, SPAN_NOTICE("Опорная точка очищена."))
		return TRUE

	if(LAZYACCESS(modifiers, RIGHT_CLICK))
		if(interaction_kind == "collector")
			return finish_placement_collection(user, clicked_turf)
		return TRUE

	if(!LAZYACCESS(modifiers, LEFT_CLICK))
		return TRUE
	if(!length(mode) || !length(shape_id))
		return TRUE

	if(interaction_kind == "collector")
		var/list/collector_points = get_placement_collector_points()
		var/turf/origin_turf = get_placement_collector_origin_turf()
		if(!length(collector_points))
			placement_anchor_turf = clicked_turf
			set_placement_collector_origin_turf(clicked_turf)
			set_placement_collector_points(list(list("x" = 0, "y" = 0)))
			update_placement_collector_runtime_state(user, clicked_turf, "Сбор начат. ")
			return TRUE

		if(!istype(origin_turf))
			origin_turf = placement_anchor_turf || clicked_turf
			set_placement_collector_origin_turf(origin_turf)
			placement_anchor_turf = origin_turf

		var/new_x = clicked_turf.x - origin_turf.x
		var/new_y = clicked_turf.y - origin_turf.y
		var/new_key = "[new_x],[new_y]"
		var/max_points = get_placement_collector_max_points(shape_id)
		for(var/list/existing_point as anything in collector_points)
			var/existing_x = text2num("[existing_point["x"]]")
			var/existing_y = text2num("[existing_point["y"]]")
			if("[existing_x],[existing_y]" == new_key)
				to_chat(user, SPAN_NOTICE("Эта точка уже добавлена в сбор."))
				return TRUE
		if(length(collector_points) >= max_points)
			to_chat(user, SPAN_WARNING("Достигнут безопасный лимит в [max_points] точек. Завершите сбор или удалите последнюю точку."))
			return TRUE

		collector_points += list(list("x" = new_x, "y" = new_y))
		placement_anchor_turf = origin_turf
		set_placement_collector_points(collector_points)
		update_placement_collector_runtime_state(user, clicked_turf, "Сбор обновлён. ")
		return TRUE

	if(interaction_kind == "anchor_pair" && !placement_anchor_turf)
		placement_anchor_turf = clicked_turf
		clear_preview_plan_state()
		GLOB.world_edit_helpers.apply_turf_preview(src, list(clicked_turf))
		to_chat(user, SPAN_NOTICE("Опорная точка выбрана: [clicked_turf.x],[clicked_turf.y],[clicked_turf.z]. Теперь укажите вторую точку."))
		return TRUE

	var/turf/start_turf = (interaction_kind == "anchor_pair") ? placement_anchor_turf : clicked_turf
	var/turf/end_turf = clicked_turf
	placement_anchor_turf = null

	var/list/shape_result = build_safe_placement_anchor_turfs(shape_id, start_turf, end_turf)
	var/list/anchor_turfs = shape_result["turfs"]
	if(shape_result["error"])
		last_preview_success = FALSE
		last_preview_message = "[shape_result["error"]]"
		last_preview_meta = shape_result["metadata"] || list()
		invalidate_preview_state()
		to_chat(user, SPAN_WARNING(last_preview_message))
		return TRUE
	if(!length(anchor_turfs))
		last_preview_success = FALSE
		last_preview_message = "Не удалось построить корректный контур размещения."
		last_preview_meta = shape_result["metadata"] || list()
		invalidate_preview_state()
		to_chat(user, SPAN_WARNING(last_preview_message))
		return TRUE

	clear_preview_plan_state()
	var/datum/world_edit_plan/plan = current_generator.build_placement_plan(user, current_params, list(
		"mode" = mode,
		"shape" = shape_id,
		"shape_metadata" = shape_result["metadata"] || list(),
		"anchor_turfs" = anchor_turfs,
		"start_turf" = start_turf,
		"end_turf" = end_turf,
		"direction" = get_effective_placement_dir(),
	))
	if(!istype(plan))
		last_preview_success = FALSE
		last_preview_message = "Не удалось собрать план размещения."
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
		last_preview_message = "Контур размещения не содержит допустимых действий."
		last_preview_meta = plan.metadata.Copy()
		invalidate_preview_state()
		to_chat(user, SPAN_WARNING(last_preview_message))
		return TRUE

	current_generator.current_plan = plan
	last_preview_success = TRUE
	last_preview_message = build_safe_placement_preview_message(plan)
	last_preview_meta = plan.metadata.Copy()
	preview_images = GLOB.world_edit_helpers.build_turf_preview_images(plan.affected_turfs)
	if(length(preview_images))
		holder.images += preview_images
	mark_preview_state()
	to_chat(user, SPAN_NOTICE(last_preview_message))

	if(confirm_before_apply)
		var/confirm_text = build_safe_placement_confirm_text(plan)
		var/answer = tgui_alert(user, confirm_text, "World Edit: Подтверждение размещения", list("Подтвердить", "Отмена"))
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
		to_chat(user, SPAN_NOTICE("Режим размещения остаётся активным."))
	return TRUE

/datum/world_edit_manager/proc/run_preview(mob/user)
	if(!holder || !check_rights_for(holder, R_DEBUG))
		return fail_preview(user, "Недостаточно прав для предпросмотра World Edit.")
	if(!current_generator || !current_definition)
		return fail_preview(user, "Сначала выберите генератор.")
	if(!current_definition.supports_preview)
		return fail_preview(user, "Для этого генератора предпросмотр не поддерживается.")
	if(!check_rights_for(holder, current_definition.required_rights))
		return fail_preview(user, "Недостаточно прав для предпросмотра этого генератора.")

	if(click_intercept_owned)
		return fail_preview(user, "Остановите активный режим размещения перед обычным предпросмотром.")

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
	if(!holder || !check_rights_for(holder, R_DEBUG))
		return fail_apply(user, "Недостаточно прав для применения World Edit.")
	if(!current_generator || !current_definition)
		return fail_apply(user, "Сначала выберите генератор.")
	if(!check_rights_for(holder, current_definition.required_rights))
		return fail_apply(user, "Недостаточно прав для применения этого генератора.")

	var/error_text = current_generator.validate_params(user, current_params)
	if(error_text)
		return fail_apply(user, error_text)

	if(current_generator.requires_preview_before_apply && !is_preview_state_valid())
		return fail_apply(user, "Предпросмотр не готов.")

	if(click_intercept_owned)
		return fail_apply(user, "Остановите активный режим размещения перед обычным применением.")

	if(confirm_before_apply)
		var/confirm_text = current_generator.get_apply_confirmation_text(current_params)
		var/answer = tgui_alert(user, confirm_text, "World Edit: Подтверждение", list("Подтвердить", "Отмена"))
		if(answer != "Подтвердить")
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
	if(!holder || !check_rights_for(holder, R_DEBUG))
		return fail_undo_action(user, "undo", "Недостаточно прав для отката World Edit.")

	var/datum/world_edit_changeset/changeset = get_last_changeset()
	if(!istype(changeset))
		return fail_undo_action(user, "undo", "В текущей сессии нет операции для отката.")
	if(!changeset.can_undo())
		return fail_undo_action(user, "undo", "Последняя операция не поддерживает откат на этой стадии.")

	var/list/undo_result = GLOB.world_edit_changesets.revert_changeset(changeset)
	var/reverted_count = text2num("[undo_result["reverted_count"]]") || 0
	var/skipped_count = text2num("[undo_result["skipped_count"]]") || 0
	var/outcome = "[undo_result["outcome"] || "none"]"
	var/message = "Откат [changeset.generator_id] ([changeset.undo_policy]): восстановлено=[reverted_count], пропущено=[skipped_count], итог=[outcome]."
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

	GLOB.world_edit_logging.log_operation(holder, "undo_last_operation", 0, center_turf, 0, reverted_count, 0, result_code, params_short)
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
	if(!holder || !check_rights_for(holder, R_DEBUG))
		return fail_undo_action(user, "cleanup", "Недостаточно прав для очистки связанных эффектов.")

	var/datum/world_edit_changeset/changeset = get_last_changeset()
	if(!istype(changeset))
		return fail_undo_action(user, "cleanup", "В текущей сессии нет операции для очистки связанных эффектов.")
	if(!changeset.can_cleanup_owned_effects())
		return fail_undo_action(user, "cleanup", "Последняя операция не содержит связанных эффектов для очистки.")

	var/list/cleanup_result = GLOB.world_edit_changesets.cleanup_changeset_owned_effects(changeset)
	var/removed_count = text2num("[cleanup_result["reverted_count"]]") || 0
	var/skipped_count = text2num("[cleanup_result["skipped_count"]]") || 0
	var/outcome = "[cleanup_result["outcome"] || "none"]"
	var/message = "Очистка связанных эффектов для [changeset.generator_id]: удалено=[removed_count], пропущено=[skipped_count], итог=[outcome]."
	var/turf/center_turf = changeset.metadata["center_turf"] || get_turf(user)
	var/params_short = "source=[changeset.generator_id]; operation_id=[changeset.operation_id]"
	var/result_code = (outcome == "full") ? "cleanup_ok" : ((outcome == "partial") ? "cleanup_partial" : "cleanup_skipped")

	changeset.owned_effect_entries = list()
	prune_changeset_stack()
	reset_preview_runtime()

	last_undo_action = "cleanup"
	last_undo_success = removed_count > 0 ? TRUE : FALSE
	last_undo_message = message

	GLOB.world_edit_logging.log_operation(holder, "cleanup_last_owned_effects", 0, center_turf, 0, removed_count, 0, result_code, params_short)
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
