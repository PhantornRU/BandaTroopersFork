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

	var/list/preview_params = islist(current_params) ? current_params.Copy() : list()
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
	placement_anchor_turf = origin_turf
	placement_hover_turf = preview_turf

	var/list/shape_result = build_safe_placement_anchor_turfs_with_params(shape_id, origin_turf, preview_turf, preview_params)
	var/list/shape_metadata = islist(shape_result["metadata"]) ? shape_result["metadata"].Copy() : list()
	for(var/key in collector_meta)
		shape_metadata[key] = collector_meta[key]

	if(shape_result["error"])
		render_safe_placement_preview(shape_result, null)
		set_safe_placement_preview_feedback(FALSE, "[message_prefix][shape_result["error"]]", shape_metadata, FALSE)
		if(!silent)
			to_chat(user, SPAN_WARNING(last_preview_message))
		return FALSE

	if(preview_point_count < min_points)
		render_safe_placement_preview(shape_result, null)
		set_safe_placement_preview_feedback(FALSE, "[message_prefix]Collected points: [length(committed_points)]/[min_points].", shape_metadata, FALSE)
		if(!silent)
			to_chat(user, SPAN_NOTICE(last_preview_message))
		return FALSE

	var/list/anchor_turfs = shape_result["turfs"]
	var/shape_support_error = current_generator?.get_shape_support_error("[shape_id]", anchor_turfs, preview_params, list(
		"mode" = get_effective_placement_mode() || "single",
		"shape" = "[shape_id]",
		"shape_metadata" = shape_metadata,
		"anchor_turfs" = anchor_turfs,
		"start_turf" = origin_turf,
		"end_turf" = preview_turf,
		"direction" = get_effective_placement_dir(),
	))
	if(length("[shape_support_error]"))
		render_safe_placement_preview(shape_result, null)
		set_safe_placement_preview_feedback(FALSE, "[message_prefix][shape_support_error]", shape_metadata, FALSE)
		if(!silent)
			to_chat(user, SPAN_WARNING(last_preview_message))
		return FALSE

	var/datum/world_edit_plan/plan = current_generator?.build_placement_plan(user, preview_params, list(
		"mode" = get_effective_placement_mode() || "single",
		"shape" = shape_id,
		"shape_metadata" = shape_metadata,
		"anchor_turfs" = anchor_turfs,
		"start_turf" = origin_turf,
		"end_turf" = preview_turf,
		"direction" = get_effective_placement_dir(),
	))
	if(!istype(plan))
		render_safe_placement_preview(shape_result, null)
		set_safe_placement_preview_feedback(FALSE, "[message_prefix]Failed to build placement plan.", shape_metadata, FALSE)
		if(!silent)
			to_chat(user, SPAN_WARNING(last_preview_message))
		return FALSE
	if(plan.metadata["error"])
		render_safe_placement_preview(shape_result, null)
		set_safe_placement_preview_feedback(FALSE, "[message_prefix][plan.metadata["error"]]", plan.metadata, FALSE)
		if(!silent)
			to_chat(user, SPAN_WARNING(last_preview_message))
		return FALSE
	if(!length(plan.placements) && !length(plan.deletions))
		render_safe_placement_preview(shape_result, null)
		set_safe_placement_preview_feedback(FALSE, "[message_prefix]Placement plan is empty.", plan.metadata, FALSE)
		if(!silent)
			to_chat(user, SPAN_WARNING(last_preview_message))
		return FALSE

	render_safe_placement_preview(shape_result, plan)
	if(!hover_only)
		current_generator.current_plan = plan
		set_safe_placement_preview_feedback(TRUE, "[message_prefix][build_safe_placement_preview_message(plan)]", plan.metadata, TRUE)
	else
		set_safe_placement_preview_feedback(TRUE, "[message_prefix][build_safe_placement_preview_message(plan)]", plan.metadata, FALSE)
	if(!silent)
		to_chat(user, SPAN_NOTICE(last_preview_message))
	return TRUE

/datum/world_edit_manager/proc/finish_placement_collection_v2(mob/user, turf/preview_turf = null)
	var/shape_id = get_effective_placement_shape()
	if(get_placement_interaction_kind(shape_id) != "collector")
		return FALSE
	if(get_placement_collector_point_count() < get_placement_collector_min_points(shape_id))
		to_chat(user, SPAN_WARNING("Need at least [get_placement_collector_min_points(shape_id)] points to finish the collection."))
		return TRUE

	preview_turf = preview_turf || placement_hover_turf || get_placement_collector_origin_turf() || placement_anchor_turf || get_turf(user)
	if(!istype(preview_turf))
		to_chat(user, SPAN_WARNING("Collector origin is not set."))
		return TRUE

	if(!update_placement_collector_runtime_state_v2(user, preview_turf, "Finishing collection. ", FALSE, FALSE))
		return TRUE
	return apply_safe_placement_current_plan(user)
