/datum/world_edit_manager/proc/build_collector_runtime_preview_params(list/base_params, list/preview_points, preview_points_text = null)
	return build_generator_params_for_shape(base_params, get_effective_placement_shape(), preview_points, preview_points_text)

/datum/world_edit_manager/proc/get_collector_preview_segment_start_turf(turf/origin_turf, list/preview_points)
	var/turf/segment_start_turf = origin_turf
	if(length(preview_points) >= 2)
		var/list/previous_point = preview_points[length(preview_points) - 1]
		if(islist(previous_point))
			segment_start_turf = locate(origin_turf.x + text2num("[previous_point["x"]]"), origin_turf.y + text2num("[previous_point["y"]]"), origin_turf.z)
	return segment_start_turf

/datum/world_edit_manager/proc/update_placement_collector_runtime_state(mob/user, turf/preview_turf, message_prefix = "", silent = FALSE, hover_only = FALSE, list/committed_points_override = null)
	var/shape_id = get_effective_placement_shape()
	var/min_points = get_placement_collector_min_points(shape_id)
	var/turf/origin_turf = get_placement_collector_origin_turf() || placement_anchor_turf || preview_turf
	var/list/committed_points = islist(committed_points_override) ? GLOB.world_edit_placement_shapes.world_edit_copy_points(committed_points_override) : get_placement_collector_points_snapshot()
	var/list/preview_points = islist(committed_points) ? GLOB.world_edit_placement_shapes.world_edit_copy_points(committed_points) : list()
	if(!istype(origin_turf))
		return FALSE

	if(hover_only && istype(preview_turf))
		var/list/hover_point = list(
			"x" = preview_turf.x - origin_turf.x,
			"y" = preview_turf.y - origin_turf.y,
		)
		var/append_hover_point = TRUE
		if("[shape_id]" == WORLD_EDIT_SHAPE_CUSTOM_MASK)
			for(var/list/existing_point as anything in preview_points)
				if(GLOB.world_edit_placement_shapes.world_edit_points_match(existing_point, hover_point))
					append_hover_point = FALSE
					break
		else if(length(preview_points))
			var/list/last_preview_point = preview_points[length(preview_points)]
			append_hover_point = !GLOB.world_edit_placement_shapes.world_edit_points_match(last_preview_point, hover_point)
		if(append_hover_point)
			preview_points += list(hover_point)

	var/preview_points_text = GLOB.world_edit_placement_shapes.world_edit_format_shape_points(preview_points)
	var/list/preview_params = build_collector_runtime_preview_params(current_params, preview_points, preview_points_text)
	var/preview_point_count = length(preview_points)
	var/list/collector_meta = list(
		"collector_point_count" = length(committed_points),
		"collector_preview_point_count" = preview_point_count,
		"collector_min_points" = min_points,
		"collector_points_text" = preview_points_text,
		"collector_origin" = get_placement_collector_origin_text() || "",
		"collector_hover" = hover_only ? TRUE : FALSE,
	)

	set_placement_anchor_turf(origin_turf)
	set_placement_hover_turf(preview_turf)

	var/datum/world_edit_shape_contract/shape_contract = GLOB.world_edit_shape_geometry.build_shape_contract(shape_id, origin_turf, preview_turf, preview_params, supports_current_placement_direction() ? get_effective_placement_dir() : NORTH)
	if(!islist(shape_contract.metadata))
		shape_contract.metadata = list()
	for(var/key in collector_meta)
		shape_contract.metadata[key] = collector_meta[key]
	if(shape_contract.error)
		var/list/placement_context = build_placement_context(shape_contract, origin_turf, preview_turf, preview_turf, origin_turf, origin_turf)
		var/datum/world_edit_placement_candidate/preview_candidate = build_placement_candidate(shape_contract, placement_context, null, preview_params, hover_only, collector_meta)
		render_safe_placement_preview(preview_candidate)
		set_safe_placement_preview_feedback(FALSE, "[message_prefix][shape_contract.error]", shape_contract.metadata, FALSE)
		if(!silent)
			to_chat(user, SPAN_WARNING(last_preview_message))
		return FALSE

	if(preview_point_count < min_points)
		var/list/placement_context = build_placement_context(shape_contract, origin_turf, preview_turf, preview_turf, origin_turf, origin_turf)
		var/datum/world_edit_placement_candidate/preview_candidate = build_placement_candidate(shape_contract, placement_context, null, preview_params, hover_only, collector_meta)
		render_safe_placement_preview(preview_candidate)
		set_safe_placement_preview_feedback(FALSE, "[message_prefix]Точек собрано: [preview_point_count]/[min_points].", shape_contract.metadata, FALSE)
		if(!silent)
			to_chat(user, SPAN_NOTICE(last_preview_message))
		return FALSE

	var/turf/segment_start_turf = get_collector_preview_segment_start_turf(origin_turf, preview_points)
	var/datum/world_edit_placement_candidate/candidate = resolve_placement_candidate_with_optional_endpoint_clamp(
		user,
		origin_turf,
		preview_turf,
		preview_params,
		hover_only,
		collector_meta,
		collector_meta,
		shape_id,
		preview_turf,
		origin_turf,
		origin_turf,
		segment_start_turf,
	)
	render_safe_placement_preview(candidate)
	var/failure_message = candidate.get_failure_message()
	var/preview_ready_for_stage = hover_only ? !length("[failure_message]") : candidate.is_confirm_ready()
	if(length("[failure_message]") || !preview_ready_for_stage)
		if(!length("[failure_message]"))
			failure_message = "Предпросмотр размещения ещё не готов."
		set_safe_placement_preview_feedback(FALSE, "[message_prefix][failure_message]", candidate.plan?.metadata || candidate.shape_contract?.metadata, FALSE)
		if(!silent)
			to_chat(user, SPAN_WARNING(last_preview_message))
		return FALSE

	var/list/preview_feedback_meta = candidate.plan?.metadata || candidate.shape_contract?.metadata || list()
	set_safe_placement_preview_feedback(TRUE, "[message_prefix][build_safe_placement_preview_message(candidate.plan, preview_feedback_meta)]", preview_feedback_meta, hover_only ? FALSE : TRUE)
	if(!silent)
		to_chat(user, SPAN_NOTICE(last_preview_message))
	return TRUE

/datum/world_edit_manager/proc/finish_placement_collection(mob/user, turf/preview_turf = null)
	if(!prepare_finished_placement_collection_preview(user, preview_turf))
		return TRUE
	if(!arm_safe_placement_preview_for_confirm(user))
		to_chat(user, SPAN_WARNING("Предпросмотр размещения ещё не готов."))
	return TRUE

/datum/world_edit_manager/proc/prepare_finished_placement_collection_preview(mob/user, turf/preview_turf = null)
	var/shape_id = get_effective_placement_shape()
	if(get_placement_interaction_kind(shape_id) != "collector")
		return FALSE
	if(get_placement_collector_point_count() < get_placement_collector_min_points(shape_id))
		to_chat(user, SPAN_WARNING("Нужно как минимум [get_placement_collector_min_points(shape_id)] точек, чтобы завершить контур."))
		return FALSE

	preview_turf = preview_turf || placement_hover_turf || get_placement_collector_origin_turf() || placement_anchor_turf || get_turf(user)
	if(!istype(preview_turf))
		to_chat(user, SPAN_WARNING("Не задана исходная точка контура."))
		return FALSE
	return update_placement_collector_runtime_state(user, preview_turf, "Завершение контура. ", FALSE, FALSE)
