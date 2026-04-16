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
