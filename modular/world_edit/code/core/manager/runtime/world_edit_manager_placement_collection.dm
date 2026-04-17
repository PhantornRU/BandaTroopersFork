/datum/world_edit_manager/proc/build_safe_placement_anchor_turfs(shape_id, turf/start_turf, turf/end_turf)
	return GLOB.world_edit_placement_shapes.world_edit_build_shape_turfs(shape_id, start_turf, end_turf, current_params, supports_current_placement_direction() ? get_effective_placement_dir() : NORTH)

/datum/world_edit_manager/proc/build_safe_placement_anchor_turfs_with_params(shape_id, turf/start_turf, turf/end_turf, list/source_params)
	return GLOB.world_edit_placement_shapes.world_edit_build_shape_turfs(shape_id, start_turf, end_turf, source_params, supports_current_placement_direction() ? get_effective_placement_dir() : NORTH)

/datum/world_edit_manager/proc/get_safe_placement_shape_support_error(shape_id, list/anchor_turfs, turf/start_turf, turf/end_turf, list/shape_metadata = null)
	if(!current_generator || !length("[shape_id]"))
		return null
	if(!islist(anchor_turfs) || !length(anchor_turfs))
		return null

	var/list/effective_shape_metadata = islist(shape_metadata) ? shape_metadata.Copy() : list()
	return current_generator.get_shape_support_error("[shape_id]", anchor_turfs, current_params, list(
		"mode" = get_effective_placement_mode() || "single",
		"shape" = "[shape_id]",
		"shape_metadata" = effective_shape_metadata,
		"anchor_turfs" = anchor_turfs,
		"start_turf" = start_turf,
		"end_turf" = end_turf,
		"direction" = get_effective_placement_dir(),
	))

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
	return update_placement_collector_runtime_state_v2(user, preview_turf, message_prefix, FALSE, FALSE)

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
	var/shape_support_error = get_safe_placement_shape_support_error(shape_id, anchor_turfs, origin_turf, preview_turf, collector_shape_metadata)
	if(length("[shape_support_error]"))
		last_preview_success = FALSE
		last_preview_message = "[shape_support_error]"
		last_preview_meta = collector_shape_metadata.Copy()
		invalidate_preview_state()
		to_chat(user, SPAN_WARNING(last_preview_message))
		return FALSE
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
	return finish_placement_collection_v2(user, preview_turf)

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
