/datum/world_edit_manager/proc/build_collector_runtime_preview_params(list/base_params, list/preview_points)
	return build_generator_params_for_shape(base_params, get_effective_placement_shape(), preview_points)

/datum/world_edit_manager/proc/resolve_outpost_collector_candidate(mob/user, shape_id, turf/origin_turf, turf/preview_turf, list/preview_points, list/collector_meta, hover_only = FALSE)
	var/list/preview_params = build_collector_runtime_preview_params(current_params, preview_points)
	var/datum/world_edit_placement_candidate/candidate = resolve_placement_candidate(
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
	)
	if(!istype(candidate) || candidate.is_preview_ready() || !istype(current_generator, /datum/world_edit_generator/outpost_radius))
		return candidate
	if(!islist(preview_points) || length(preview_points) < get_placement_collector_min_points(shape_id))
		return candidate

	var/list/first_point = preview_points[1]
	if(!hover_only && collector_first_point_click_finishes(shape_id) && islist(first_point))
		var/turf/first_point_turf = locate(origin_turf.x + text2num("[first_point["x"]]"), origin_turf.y + text2num("[first_point["y"]]"), origin_turf.z)
		if(first_point_turf == preview_turf)
			return candidate

	var/turf/segment_start_turf = origin_turf
	if(length(preview_points) >= 2)
		var/list/previous_point = preview_points[length(preview_points) - 1]
		if(islist(previous_point))
			segment_start_turf = locate(origin_turf.x + text2num("[previous_point["x"]]"), origin_turf.y + text2num("[previous_point["y"]]"), origin_turf.z)
	if(!istype(segment_start_turf) || segment_start_turf == preview_turf)
		return candidate

	var/list/segment_turfs = GLOB.world_edit_helpers.collect_line_turfs(segment_start_turf, preview_turf)
	if(!islist(segment_turfs) || length(segment_turfs) <= 1)
		return candidate

	for(var/i = length(segment_turfs) - 1, i >= 1, i--)
		var/turf/clamped_preview_turf = segment_turfs[i]
		if(!istype(clamped_preview_turf) || clamped_preview_turf == preview_turf || clamped_preview_turf == segment_start_turf)
			continue

		var/list/clamped_points = GLOB.world_edit_placement_shapes.world_edit_copy_points(preview_points)
		var/list/last_point = clamped_points[length(clamped_points)]
		if(!islist(last_point))
			continue
		last_point["x"] = clamped_preview_turf.x - origin_turf.x
		last_point["y"] = clamped_preview_turf.y - origin_turf.y

		var/list/clamped_meta = collector_meta.Copy()
		clamped_meta["collector_points_text"] = GLOB.world_edit_placement_shapes.world_edit_format_shape_points(clamped_points)
		var/list/clamped_params = build_collector_runtime_preview_params(current_params, clamped_points)
		var/datum/world_edit_placement_candidate/clamped_candidate = resolve_placement_candidate(
			user,
			origin_turf,
			clamped_preview_turf,
			clamped_params,
			hover_only,
			clamped_meta,
			clamped_meta,
			shape_id,
			preview_turf,
			origin_turf,
			origin_turf,
		)
		if(!istype(clamped_candidate) || !clamped_candidate.is_preview_ready())
			continue
		clamped_candidate.collector_state_summary = clamped_meta.Copy()
		if(!islist(clamped_candidate.placement_context))
			clamped_candidate.placement_context = list()
		clamped_candidate.placement_context["clamp_reason"] = "endpoint"
		clamped_candidate.placement_context["requested_end_turf"] = preview_turf
		clamped_candidate.placement_context["resolved_end_turf"] = clamped_preview_turf
		stamp_placement_plan_shape_metadata(clamped_candidate.plan, clamped_candidate.shape_contract, clamped_candidate.placement_context)
		return clamped_candidate

	return candidate

/datum/world_edit_manager/proc/update_placement_collector_runtime_state(mob/user, turf/preview_turf, message_prefix = "", silent = FALSE, hover_only = FALSE, list/committed_points_override = null)
	var/shape_id = get_effective_placement_shape()
	var/min_points = get_placement_collector_min_points(shape_id)
	var/turf/origin_turf = get_placement_collector_origin_turf() || placement_anchor_turf || preview_turf
	var/list/committed_points = islist(committed_points_override) ? GLOB.world_edit_placement_shapes.world_edit_copy_points(committed_points_override) : get_placement_collector_points()
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

	var/list/preview_params = build_collector_runtime_preview_params(current_params, preview_points)
	var/preview_point_count = length(preview_points)
	var/list/collector_meta = list(
		"collector_point_count" = length(committed_points),
		"collector_preview_point_count" = preview_point_count,
		"collector_min_points" = min_points,
		"collector_points_text" = preview_params["shape_points_text"] || "",
		"collector_origin" = get_placement_collector_origin_text() || "",
		"collector_hover" = hover_only ? TRUE : FALSE,
	)

	teardown_preview_session_runtime()
	set_placement_anchor_turf(origin_turf)
	set_placement_hover_turf(preview_turf)

	var/datum/world_edit_shape_contract/shape_contract = GLOB.world_edit_shape_geometry.build_shape_contract(shape_id, origin_turf, preview_turf, preview_params, supports_current_placement_direction() ? get_effective_placement_dir() : NORTH)
	if(!islist(shape_contract.metadata))
		shape_contract.metadata = list()
	for(var/key in collector_meta)
		shape_contract.metadata[key] = collector_meta[key]
	var/list/placement_context = build_placement_context(shape_contract, origin_turf, preview_turf, preview_turf, origin_turf, origin_turf)
	var/datum/world_edit_placement_candidate/preview_candidate = build_placement_candidate(shape_contract, placement_context, null, preview_params, hover_only, collector_meta)

	if(shape_contract.error)
		render_safe_placement_preview(preview_candidate)
		set_safe_placement_preview_feedback(FALSE, "[message_prefix][shape_contract.error]", shape_contract.metadata, FALSE)
		if(!silent)
			to_chat(user, SPAN_WARNING(last_preview_message))
		return FALSE

	if(preview_point_count < min_points)
		render_safe_placement_preview(preview_candidate)
		set_safe_placement_preview_feedback(FALSE, "[message_prefix]РўРѕС‡РµРє СЃРѕР±СЂР°РЅРѕ: [preview_point_count]/[min_points].", shape_contract.metadata, FALSE)
		if(!silent)
			to_chat(user, SPAN_NOTICE(last_preview_message))
		return FALSE

	var/datum/world_edit_placement_candidate/candidate = resolve_outpost_collector_candidate(user, shape_id, origin_turf, preview_turf, preview_points, collector_meta, hover_only)
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

/datum/world_edit_manager/proc/finish_placement_collection(mob/user, turf/preview_turf = null)
	if(!prepare_finished_placement_collection_preview(user, preview_turf))
		return TRUE
	arm_safe_placement_preview_for_confirm(user)
	return TRUE

/datum/world_edit_manager/proc/prepare_finished_placement_collection_preview(mob/user, turf/preview_turf = null)
	var/shape_id = get_effective_placement_shape()
	if(get_placement_interaction_kind(shape_id) != "collector")
		return FALSE
	if(get_placement_collector_point_count() < get_placement_collector_min_points(shape_id))
		to_chat(user, SPAN_WARNING("РќСѓР¶РЅРѕ РєР°Рє РјРёРЅРёРјСѓРј [get_placement_collector_min_points(shape_id)] С‚РѕС‡РµРє, С‡С‚РѕР±С‹ Р·Р°РІРµСЂС€РёС‚СЊ РєРѕРЅС‚СѓСЂ."))
		return FALSE

	preview_turf = preview_turf || placement_hover_turf || get_placement_collector_origin_turf() || placement_anchor_turf || get_turf(user)
	if(!istype(preview_turf))
		to_chat(user, SPAN_WARNING("РќРµ Р·Р°РґР°РЅР° РёСЃС…РѕРґРЅР°СЏ С‚РѕС‡РєР° РєРѕРЅС‚СѓСЂР°."))
		return FALSE

	return update_placement_collector_runtime_state(user, preview_turf, "Р—Р°РІРµСЂС€РµРЅРёРµ РєРѕРЅС‚СѓСЂР°. ", FALSE, FALSE)
