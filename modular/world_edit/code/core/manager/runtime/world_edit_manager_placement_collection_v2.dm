/datum/world_edit_manager/proc/update_placement_collector_runtime_state_v2(mob/user, turf/preview_turf, message_prefix = "", silent = FALSE, hover_only = FALSE)
	var/shape_id = get_effective_placement_shape()
	var/min_points = get_placement_collector_min_points(shape_id)
	var/turf/origin_turf = get_placement_collector_origin_turf() || placement_anchor_turf || preview_turf
	var/list/committed_points = get_placement_collector_points()
	var/list/preview_points = GLOB.world_edit_placement_shapes.world_edit_copy_points(committed_points)
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

	var/list/preview_params = sanitize_persistent_generator_params(current_params)
	preview_params["shape_points_text"] = GLOB.world_edit_placement_shapes.world_edit_format_shape_points(preview_points)
	var/preview_point_count = length(preview_points)
	var/list/collector_meta = list(
		"collector_point_count" = length(committed_points),
		"collector_preview_point_count" = preview_point_count,
		"collector_min_points" = min_points,
		"collector_points_text" = preview_params["shape_points_text"] || "",
		"collector_origin" = get_placement_collector_origin_text() || "",
		"collector_hover" = hover_only ? TRUE : FALSE,
	)

	clear_preview_plan_state()
	set_placement_anchor_turf(origin_turf)
	set_placement_hover_turf(preview_turf)

	var/datum/world_edit_shape_contract/shape_contract = GLOB.world_edit_shape_geometry.build_shape_contract(shape_id, origin_turf, preview_turf, preview_params, supports_current_placement_direction() ? get_effective_placement_dir() : NORTH)
	if(!islist(shape_contract.metadata))
		shape_contract.metadata = list()
	for(var/key in collector_meta)
		shape_contract.metadata[key] = collector_meta[key]
	var/datum/world_edit_preview_model/preview_model = GLOB.world_edit_shape_preview.build_shape_preview(shape_contract)
	var/datum/world_edit_placement_candidate/preview_candidate = new
	preview_candidate.hover_only = hover_only ? TRUE : FALSE
	preview_candidate.shape_contract = shape_contract
	preview_candidate.preview_model = preview_model
	preview_candidate.collector_state_summary = collector_meta.Copy()
	preview_candidate.runtime_params = preview_params.Copy()
	preview_candidate.placement_context = list(
		"mode" = get_effective_placement_mode() || "single",
		"shape" = shape_contract.shape_id,
		"shape_contract" = shape_contract,
		"shape_metadata" = shape_contract.copy_metadata(),
		"anchor_turfs" = shape_contract.copy_anchor_turfs(),
		"start_turf" = origin_turf,
		"end_turf" = preview_turf,
		"direction" = supports_current_placement_direction() ? get_effective_placement_dir() : NORTH,
	)

	if(shape_contract.error)
		render_safe_placement_preview(preview_candidate)
		set_safe_placement_preview_feedback(FALSE, "[message_prefix][shape_contract.error]", shape_contract.metadata, FALSE)
		if(!silent)
			to_chat(user, SPAN_WARNING(last_preview_message))
		return FALSE

	if(preview_point_count < min_points)
		render_safe_placement_preview(preview_candidate)
		set_safe_placement_preview_feedback(FALSE, "[message_prefix]Точек собрано: [preview_point_count]/[min_points].", shape_contract.metadata, FALSE)
		if(!silent)
			to_chat(user, SPAN_NOTICE(last_preview_message))
		return FALSE

	var/datum/world_edit_placement_candidate/candidate = resolve_placement_candidate(user, origin_turf, preview_turf, preview_params, hover_only, collector_meta, collector_meta)
	render_safe_placement_preview(candidate)
	var/failure_message = candidate.get_failure_message()
	if(length("[failure_message]"))
		set_safe_placement_preview_feedback(FALSE, "[message_prefix][failure_message]", candidate.plan?.metadata || candidate.shape_contract?.metadata, FALSE)
		if(!silent)
			to_chat(user, SPAN_WARNING(last_preview_message))
		return FALSE

	set_safe_placement_preview_feedback(TRUE, "[message_prefix][build_safe_placement_preview_message(candidate.plan)]", candidate.plan.metadata, hover_only ? FALSE : TRUE)
	if(!silent)
		to_chat(user, SPAN_NOTICE(last_preview_message))
	return TRUE

/datum/world_edit_manager/proc/finish_placement_collection_v2(mob/user, turf/preview_turf = null)
	var/shape_id = get_effective_placement_shape()
	if(get_placement_interaction_kind(shape_id) != "collector")
		return FALSE
	if(get_placement_collector_point_count() < get_placement_collector_min_points(shape_id))
		to_chat(user, SPAN_WARNING("Нужно как минимум [get_placement_collector_min_points(shape_id)] точек, чтобы завершить контур."))
		return TRUE

	preview_turf = preview_turf || placement_hover_turf || get_placement_collector_origin_turf() || placement_anchor_turf || get_turf(user)
	if(!istype(preview_turf))
		to_chat(user, SPAN_WARNING("Не задана исходная точка контура."))
		return TRUE

	if(!update_placement_collector_runtime_state_v2(user, preview_turf, "Завершение контура. ", FALSE, FALSE))
		return TRUE
	return apply_safe_placement_current_plan(user)
