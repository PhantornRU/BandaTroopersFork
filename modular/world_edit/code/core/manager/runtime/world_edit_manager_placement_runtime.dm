/datum/world_edit_manager/proc/build_safe_placement_preview_message(datum/world_edit_plan/plan)
	if(islist(plan?.metadata))
		plan.metadata["collector_point_count"] = plan.metadata["collector_preview_point_count"] || plan.metadata["collector_point_count"]
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

/datum/world_edit_manager/proc/sanitize_preview_feedback_meta(list/meta)
	if(!islist(meta))
		return list()

	var/list/safe_meta = meta.Copy()
	var/turf/shape_origin_turf = safe_meta["shape_origin_turf"]
	var/turf/requested_end_turf = safe_meta["requested_end_turf"]
	var/turf/resolved_end_turf = safe_meta["resolved_end_turf"]
	var/turf/seed_turf = safe_meta["seed_turf"]
	if(istype(shape_origin_turf))
		safe_meta["shape_origin"] = GLOB.world_edit_helpers.turf_to_text(shape_origin_turf)
	if(istype(requested_end_turf))
		safe_meta["requested_end"] = GLOB.world_edit_helpers.turf_to_text(requested_end_turf)
	if(istype(resolved_end_turf))
		safe_meta["resolved_end"] = GLOB.world_edit_helpers.turf_to_text(resolved_end_turf)
	if(istype(seed_turf))
		safe_meta["seed"] = GLOB.world_edit_helpers.turf_to_text(seed_turf)
	safe_meta -= "shape_result"
	safe_meta -= "shape_origin_turf"
	safe_meta -= "requested_end_turf"
	safe_meta -= "resolved_end_turf"
	safe_meta -= "seed_turf"
	return safe_meta

/datum/world_edit_manager/proc/build_shape_contract_from_plan_metadata(datum/world_edit_plan/plan)
	var/list/metadata = plan?.metadata
	if(!islist(metadata))
		return null

	var/shape_id = metadata["placement_shape"] || metadata["shape_id"]
	var/list/shape_result = metadata["shape_result"]
	if(!length("[shape_id]") || !islist(shape_result) || !length(shape_result))
		return null
	return GLOB.world_edit_shape_geometry.build_shape_contract_from_result(shape_id, shape_result)

/datum/world_edit_manager/proc/build_safe_placement_plan_from_shape_result(mob/user, shape_id, list/shape_result, turf/start_turf, turf/end_turf, list/shape_metadata_override = null)
	var/datum/world_edit_shape_contract/shape_contract = GLOB.world_edit_shape_geometry.build_shape_contract_from_result(shape_id, shape_result)
	if(islist(shape_metadata_override))
		if(!islist(shape_contract.metadata))
			shape_contract.metadata = list()
		for(var/key in shape_metadata_override)
			shape_contract.metadata[key] = shape_metadata_override[key]

	var/list/placement_context = list(
		"mode" = get_effective_placement_mode() || "single",
		"shape" = shape_contract.shape_id,
		"shape_contract" = shape_contract,
		"shape_metadata" = shape_contract.copy_metadata(),
		"anchor_turfs" = shape_contract.copy_anchor_turfs(),
		"start_turf" = start_turf,
		"end_turf" = end_turf,
		"shape_origin_turf" = start_turf,
		"seed_turf" = start_turf,
		"requested_end_turf" = end_turf,
		"resolved_end_turf" = end_turf,
		"direction" = get_effective_placement_dir(),
	)
	var/datum/world_edit_plan/plan = current_generator?.build_plan_from_shape_contract(user, shape_contract, build_effective_generator_params(null, shape_id), placement_context)
	current_generator?.stamp_plan_shape_metadata(plan, shape_contract, placement_context)
	return plan

/datum/world_edit_manager/proc/get_safe_placement_generator_effect_turfs(datum/world_edit_plan/plan)
	if(!istype(plan))
		return list()

	var/list/metadata = plan.metadata
	if(islist(metadata) && islist(metadata["generator_effect_turfs"]))
		return GLOB.world_edit_placement_shapes.world_edit_unique_turf_list(metadata["generator_effect_turfs"])
	return GLOB.world_edit_placement_shapes.world_edit_unique_turf_list(plan.affected_turfs)

/datum/world_edit_manager/proc/render_safe_placement_preview(datum/world_edit_placement_candidate/candidate)
	store_placement_preview_candidate(candidate)
	GLOB.world_edit_helpers.apply_grouped_turf_preview(src, get_placement_preview_groups())

/datum/world_edit_manager/proc/render_plan_preview_with_placement_layers(mob/user, datum/world_edit_plan/plan, list/effective_params = null)
	if(!supports_current_placement_ux() || !istype(plan))
		return FALSE

	var/list/plan_metadata = islist(plan.metadata) ? plan.metadata : list()
	var/shape_id = plan_metadata["placement_shape"] || get_effective_placement_shape() || WORLD_EDIT_SHAPE_POINT
	shape_id = "[shape_id]"
	if(!length(shape_id))
		return FALSE

	var/placement_dir = text2num("[plan_metadata["placement_dir"]]")
	if(!(placement_dir in GLOB.cardinals))
		placement_dir = supports_current_placement_direction() ? get_effective_placement_dir() : NORTH

	var/list/params_to_use = islist(effective_params) ? effective_params.Copy() : build_effective_generator_params(null, shape_id)
	var/datum/world_edit_shape_contract/shape_contract = build_shape_contract_from_plan_metadata(plan)
	var/turf/shape_origin_turf = plan_metadata["shape_origin_turf"] || plan_metadata["center_turf"] || get_turf(user)
	var/turf/requested_end_turf = plan_metadata["requested_end_turf"] || plan_metadata["resolved_end_turf"] || plan_metadata["center_turf"] || shape_origin_turf
	var/turf/resolved_end_turf = plan_metadata["resolved_end_turf"] || requested_end_turf
	var/turf/seed_turf = plan_metadata["seed_turf"] || shape_origin_turf
	if(!istype(shape_contract))
		if(!istype(shape_origin_turf))
			return FALSE
		var/list/shape_result = GLOB.world_edit_placement_shapes.world_edit_build_shape_turfs(shape_id, shape_origin_turf, resolved_end_turf, params_to_use, placement_dir)
		if(!islist(shape_result))
			return FALSE
		var/shape_error = "[shape_result["error"]]"
		if(length(shape_error))
			return FALSE
		shape_contract = GLOB.world_edit_shape_geometry.build_shape_contract_from_result(shape_id, shape_result)
	if(!istype(shape_contract))
		return FALSE

	var/datum/world_edit_preview_model/preview_model = GLOB.world_edit_shape_preview.build_shape_preview(shape_contract)
	preview_model.generator_effect_turfs = get_safe_placement_generator_effect_turfs(plan)
	var/placement_mode = "[plan_metadata["placement_mode"] || get_effective_placement_mode() || "single"]"

	var/datum/world_edit_placement_candidate/candidate = new
	candidate.shape_contract = shape_contract
	candidate.preview_model = preview_model
	current_generator.stamp_plan_shape_metadata(plan, shape_contract, candidate.placement_context)
	candidate.plan = plan
	candidate.runtime_params = params_to_use.Copy()
	candidate.placement_context = list(
		"mode" = placement_mode,
		"shape" = shape_id,
		"shape_contract" = shape_contract,
		"shape_metadata" = shape_contract.copy_metadata(),
		"anchor_turfs" = shape_contract.copy_anchor_turfs(),
		"start_turf" = shape_origin_turf,
		"end_turf" = resolved_end_turf,
		"shape_origin_turf" = shape_origin_turf,
		"seed_turf" = seed_turf,
		"requested_end_turf" = requested_end_turf,
		"resolved_end_turf" = resolved_end_turf,
		"direction" = placement_dir,
	)
	render_safe_placement_preview(candidate)
	return TRUE

/datum/world_edit_manager/proc/set_safe_placement_preview_feedback(success, message, list/meta = null, mark_valid = FALSE)
	last_preview_success = success ? TRUE : FALSE
	last_preview_message = "[message]"
	last_preview_meta = sanitize_preview_feedback_meta(meta)
	if(success)
		last_ui_error = ""
	if(mark_valid)
		mark_preview_state()
	else
		invalidate_preview_state()

/datum/world_edit_manager/proc/resolve_placement_candidate(mob/user, turf/start_turf, turf/end_turf, list/runtime_params = null, hover_only = FALSE, list/shape_metadata_override = null, list/collector_state_summary = null, shape_id_override = null, turf/requested_end_turf = null, turf/seed_turf = null, turf/shape_origin_turf = null)
	var/datum/world_edit_placement_candidate/candidate = new
	candidate.hover_only = hover_only ? TRUE : FALSE
	if(!current_generator)
		candidate.resolve_error = "Генератор не активен."
		return candidate

	var/shape_id = shape_id_override || get_effective_placement_shape() || WORLD_EDIT_SHAPE_POINT
	var/effective_direction = supports_current_placement_direction() ? get_effective_placement_dir() : NORTH
	var/list/effective_params = islist(runtime_params) ? runtime_params.Copy() : build_effective_generator_params(null, shape_id)
	candidate.runtime_params = effective_params.Copy()

	var/datum/world_edit_shape_contract/shape_contract = GLOB.world_edit_shape_geometry.build_shape_contract(shape_id, start_turf, end_turf, effective_params, effective_direction)
	candidate.shape_contract = shape_contract
	if(islist(shape_metadata_override))
		if(!islist(shape_contract.metadata))
			shape_contract.metadata = list()
		for(var/key in shape_metadata_override)
			shape_contract.metadata[key] = shape_metadata_override[key]
	if(islist(collector_state_summary))
		candidate.collector_state_summary = collector_state_summary.Copy()
		if(!islist(shape_contract.metadata))
			shape_contract.metadata = list()
		for(var/key in collector_state_summary)
			shape_contract.metadata[key] = collector_state_summary[key]

	candidate.preview_model = GLOB.world_edit_shape_preview.build_shape_preview(shape_contract)
	candidate.placement_context = list(
		"mode" = get_effective_placement_mode() || "single",
		"shape" = shape_contract.shape_id,
		"shape_contract" = shape_contract,
		"shape_metadata" = shape_contract.copy_metadata(),
		"anchor_turfs" = shape_contract.copy_anchor_turfs(),
		"start_turf" = start_turf,
		"end_turf" = end_turf,
		"shape_origin_turf" = shape_origin_turf || start_turf,
		"seed_turf" = seed_turf || shape_origin_turf || start_turf,
		"requested_end_turf" = requested_end_turf || end_turf,
		"resolved_end_turf" = end_turf,
		"direction" = effective_direction,
	)

	if(shape_contract.error)
		candidate.resolve_error = "[shape_contract.error]"
		return candidate
	if(!length(shape_contract.anchor_turfs))
		candidate.resolve_error = "Недопустимый контур размещения."
		return candidate

	var/list/support_result = current_generator.evaluate_shape_contract(shape_contract, effective_params, candidate.placement_context)
	if(islist(support_result))
		var/list/support_metadata = support_result["metadata"]
		if(islist(support_metadata))
			for(var/key in support_metadata)
				shape_contract.metadata[key] = support_metadata[key]
			candidate.placement_context["shape_metadata"] = shape_contract.copy_metadata()
		candidate.support_error = support_result["error"]
	else
		candidate.support_error = support_result
	if(length("[candidate.support_error]"))
		return candidate

	var/datum/world_edit_plan/plan = current_generator.build_plan_from_shape_contract(user, shape_contract, effective_params, candidate.placement_context)
	if(!istype(plan))
		candidate.resolve_error = "Не удалось построить план размещения."
		return candidate
	candidate.plan = plan
	if(plan.metadata["error"])
		candidate.resolve_error = "[plan.metadata["error"]]"
		return candidate
	if(!length(plan.placements) && !length(plan.deletions))
		candidate.resolve_error = "План размещения пуст."
		return candidate
	if(istype(candidate.preview_model))
		candidate.preview_model.generator_effect_turfs = get_safe_placement_generator_effect_turfs(plan)
	return candidate

/datum/world_edit_manager/proc/can_attempt_outpost_endpoint_clamp(shape_id, turf/start_turf, turf/requested_end_turf, turf/segment_start_turf = null)
	if(!istype(current_generator, /datum/world_edit_generator/outpost_radius))
		return FALSE
	if(!istype(start_turf) || !istype(requested_end_turf))
		return FALSE

	var/interaction_kind = get_placement_interaction_kind(shape_id)
	if(!(interaction_kind in list("anchor_pair", "collector")))
		return FALSE

	segment_start_turf = segment_start_turf || start_turf
	if(!istype(segment_start_turf) || segment_start_turf == requested_end_turf)
		return FALSE
	return TRUE

/datum/world_edit_manager/proc/resolve_placement_candidate_with_optional_outpost_clamp(mob/user, turf/start_turf, turf/end_turf, list/runtime_params = null, hover_only = FALSE, list/shape_metadata_override = null, list/collector_state_summary = null, shape_id_override = null, turf/requested_end_turf = null, turf/seed_turf = null, turf/shape_origin_turf = null, turf/segment_start_turf = null)
	var/requested_shape_id = shape_id_override || get_effective_placement_shape() || WORLD_EDIT_SHAPE_POINT
	var/turf/requested_turf = requested_end_turf || end_turf
	var/datum/world_edit_placement_candidate/candidate = resolve_placement_candidate(
		user,
		start_turf,
		end_turf,
		runtime_params,
		hover_only,
		shape_metadata_override,
		collector_state_summary,
		requested_shape_id,
		requested_turf,
		seed_turf,
		shape_origin_turf,
	)
	if(!istype(candidate))
		return candidate
	if(candidate.is_preview_ready())
		return candidate
	if(!can_attempt_outpost_endpoint_clamp(requested_shape_id, start_turf, requested_turf, segment_start_turf))
		return candidate

	segment_start_turf = segment_start_turf || start_turf
	var/list/segment_turfs = GLOB.world_edit_helpers.collect_line_turfs(segment_start_turf, requested_turf)
	if(!islist(segment_turfs) || length(segment_turfs) <= 1)
		return candidate

	for(var/i = length(segment_turfs) - 1, i >= 1, i--)
		var/turf/clamped_end_turf = segment_turfs[i]
		if(!istype(clamped_end_turf) || clamped_end_turf == requested_turf || clamped_end_turf == segment_start_turf)
			continue

		var/datum/world_edit_placement_candidate/clamped_candidate = resolve_placement_candidate(
			user,
			start_turf,
			clamped_end_turf,
			runtime_params,
			hover_only,
			shape_metadata_override,
			collector_state_summary,
			requested_shape_id,
			requested_turf,
			seed_turf,
			shape_origin_turf,
		)
		if(!istype(clamped_candidate) || !clamped_candidate.is_preview_ready())
			continue
		if(!islist(clamped_candidate.placement_context))
			clamped_candidate.placement_context = list()
		clamped_candidate.placement_context["clamp_reason"] = "endpoint"
		clamped_candidate.placement_context["requested_end_turf"] = requested_turf
		clamped_candidate.placement_context["resolved_end_turf"] = clamped_end_turf
		current_generator?.stamp_plan_shape_metadata(clamped_candidate.plan, clamped_candidate.shape_contract, clamped_candidate.placement_context)
		return clamped_candidate

	return candidate

/datum/world_edit_manager/proc/evaluate_safe_placement_preview(mob/user, shape_id, turf/start_turf, turf/end_turf, list/shape_metadata_override = null, message_prefix = "", silent = FALSE, hover_only = FALSE)
	clear_preview_plan_state()
	set_placement_hover_turf(end_turf)
	var/datum/world_edit_placement_candidate/candidate = resolve_placement_candidate_with_optional_outpost_clamp(user, start_turf, end_turf, build_effective_generator_params(null, shape_id), hover_only, shape_metadata_override, null, shape_id, end_turf, start_turf, start_turf, start_turf)
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

/datum/world_edit_manager/proc/apply_resolved_placement_candidate(mob/user, datum/world_edit_placement_candidate/candidate = null, force_confirm = FALSE, cancel_placement_on_confirm_reject = FALSE)
	candidate = candidate || get_placement_preview_candidate()
	if(!istype(candidate) || !candidate.is_ready_for_apply() || !is_preview_state_valid())
		to_chat(user, SPAN_WARNING("Предпросмотр размещения ещё не готов."))
		return TRUE

	var/datum/world_edit_plan/plan = candidate.plan
	if(force_confirm || confirm_before_apply)
		var/turf/confirm_turf = islist(candidate.placement_context) ? (candidate.placement_context["resolved_end_turf"] || candidate.placement_context["end_turf"]) : null
		var/confirm_text = build_safe_placement_confirm_text(plan)
		set_placement_preview_locked(TRUE, confirm_turf)
		var/answer = tgui_alert(user, confirm_text, "Панель размещения: подтверждение", list("Подтвердить", "Отмена"))
		if(answer != "Подтвердить")
			set_placement_preview_locked(FALSE, confirm_turf)
			if(cancel_placement_on_confirm_reject)
				return cancel_safe_placement_mode(user, "Размещение отменено пользователем.")
			return TRUE

	set_placement_preview_locked(FALSE)
	var/mode = get_effective_placement_mode()
	var/start_ds = world.time
	var/datum/world_edit_apply_result/result = current_generator.apply_built_plan(user, candidate.runtime_params, plan)
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
		if(is_current_placement_collector())
			set_placement_anchor_turf(get_placement_collector_origin_turf())
			set_placement_hover_turf(placement_anchor_turf)
		else
			set_placement_anchor_turf(null)
			set_placement_hover_turf(null)
		to_chat(user, SPAN_NOTICE("Режим размещения остаётся активным."))
	return TRUE

/datum/world_edit_manager/proc/apply_safe_placement_current_plan(mob/user, force_confirm = FALSE, cancel_placement_on_confirm_reject = FALSE)
	return apply_resolved_placement_candidate(user, get_placement_preview_candidate(), force_confirm, cancel_placement_on_confirm_reject)

/datum/world_edit_manager/proc/cancel_safe_placement_mode(mob/user, message = "Режим размещения остановлен.", cancel_reason = null)
	var/reason_text = length("[cancel_reason]") ? "[cancel_reason]" : ""
	reset_preview_runtime()
	if(!user)
		return TRUE
	if(length(reason_text))
		to_chat(user, SPAN_WARNING("Размещение отменено: [reason_text]"))
	else if(length("[message]"))
		to_chat(user, SPAN_NOTICE(message))
	return TRUE

/datum/world_edit_manager/proc/handle_safe_placement_right_click(mob/user, turf/preview_turf = null)
	var/shape_id = get_effective_placement_shape()
	var/interaction_kind = get_placement_interaction_kind(shape_id)

	if(interaction_kind == "collector")
		if(get_placement_collector_point_count() < get_placement_collector_min_points(shape_id))
			return cancel_safe_placement_mode(user, null, "Недостаточно точек для завершения контура.")

		preview_turf = preview_turf || placement_hover_turf || get_placement_collector_origin_turf() || placement_anchor_turf || get_turf(user)
		if(!istype(preview_turf))
			return cancel_safe_placement_mode(user, null, "Не удалось определить точку предпросмотра.")

		if(!update_placement_collector_runtime_state_v2(user, preview_turf, "", TRUE, FALSE))
			return cancel_safe_placement_mode(user, null, last_preview_message || "Не удалось завершить контур.")
		return apply_safe_placement_current_plan(user, TRUE, TRUE)

	if(interaction_kind == "anchor_pair")
		if(!istype(placement_anchor_turf))
			return cancel_safe_placement_mode(user)
		preview_turf = preview_turf || placement_hover_turf || placement_anchor_turf
		if(!istype(preview_turf))
			return cancel_safe_placement_mode(user, null, "Не удалось определить точку предпросмотра.")
		if(!evaluate_safe_placement_preview(user, shape_id, placement_anchor_turf, preview_turf, null, "", TRUE, FALSE))
			return cancel_safe_placement_mode(user, null, last_preview_message || "Не удалось подготовить размещение.")
		return apply_safe_placement_current_plan(user, TRUE, TRUE)

	if(interaction_kind == "single" || interaction_kind == "param_only")
		preview_turf = preview_turf || placement_hover_turf
		if(!istype(preview_turf))
			return cancel_safe_placement_mode(user, null, "Не удалось определить точку предпросмотра.")
		if(!evaluate_safe_placement_preview(user, shape_id, preview_turf, preview_turf, null, "", TRUE, FALSE))
			return cancel_safe_placement_mode(user, null, last_preview_message || "Не удалось подготовить размещение.")
		return apply_safe_placement_current_plan(user, TRUE, TRUE)

	return cancel_safe_placement_mode(user)

/datum/world_edit_manager/proc/show_anchor_pair_preview(turf/anchor_turf, shape_id)
	clear_preview_plan_state()
	set_placement_anchor_turf(anchor_turf)
	set_placement_hover_turf(anchor_turf)
	var/datum/world_edit_shape_contract/shape_contract = GLOB.world_edit_shape_geometry.build_shape_contract(shape_id, anchor_turf, anchor_turf, build_effective_generator_params(null, shape_id), supports_current_placement_direction() ? get_effective_placement_dir() : NORTH)
	var/datum/world_edit_preview_model/preview_model = GLOB.world_edit_shape_preview.build_shape_preview(shape_contract)
	var/datum/world_edit_placement_candidate/candidate = new
	candidate.hover_only = TRUE
	candidate.shape_contract = shape_contract
	candidate.preview_model = preview_model
	candidate.placement_context = list(
		"mode" = get_effective_placement_mode() || "single",
		"shape" = shape_contract.shape_id,
		"shape_contract" = shape_contract,
		"shape_metadata" = shape_contract.copy_metadata(),
		"anchor_turfs" = shape_contract.copy_anchor_turfs(),
		"start_turf" = anchor_turf,
		"end_turf" = anchor_turf,
		"shape_origin_turf" = anchor_turf,
		"seed_turf" = anchor_turf,
		"requested_end_turf" = anchor_turf,
		"resolved_end_turf" = anchor_turf,
		"direction" = supports_current_placement_direction() ? get_effective_placement_dir() : NORTH,
	)
	render_safe_placement_preview(candidate)

/datum/world_edit_manager/proc/handle_safe_placement_hover(mob/user, turf/hover_turf)
	if(!placement_click_active || !supports_current_placement_ux())
		return FALSE
	if(is_placement_preview_locked())
		return TRUE
	if(!istype(hover_turf))
		return FALSE
	if(holder != user?.client)
		return FALSE

	var/shape_id = get_effective_placement_shape()
	var/interaction_kind = get_placement_interaction_kind(shape_id)
	if(interaction_kind == "anchor_pair")
		if(!istype(placement_anchor_turf))
			return FALSE
		evaluate_safe_placement_preview(user, shape_id, placement_anchor_turf, hover_turf, null, "", TRUE, TRUE)
		return TRUE
	if(interaction_kind == "collector")
		if(!length(get_placement_collector_points()))
			return FALSE
		update_placement_collector_runtime_state_v2(user, hover_turf, "", TRUE, TRUE)
		return TRUE
	if(interaction_kind == "single" || interaction_kind == "param_only")
		evaluate_safe_placement_preview(user, shape_id, hover_turf, hover_turf, null, "", TRUE, TRUE)
		return TRUE
	return FALSE

/datum/world_edit_manager/proc/collector_first_point_click_finishes(shape_id)
	switch("[shape_id]")
		if(WORLD_EDIT_SHAPE_POLYGON, WORLD_EDIT_SHAPE_POLYLINE, WORLD_EDIT_SHAPE_BRUSH_PATH)
			return TRUE
	return FALSE

/datum/world_edit_manager/proc/arm_safe_placement_preview_for_confirm(mob/user, turf/confirm_turf = null)
	if(!arm_placement_confirm_for_turf(confirm_turf))
		return FALSE
	if(user)
		to_chat(user, SPAN_NOTICE("Предпросмотр закреплён. Нажмите ещё раз по этому тайлу для подтверждения."))
	return TRUE

/datum/world_edit_manager/proc/handle_repeated_safe_placement_confirm_click(mob/user, turf/confirm_turf = null)
	if(!is_placement_confirm_armed_for_turf(confirm_turf))
		return FALSE
	clear_placement_confirm_arm()
	return apply_safe_placement_current_plan(user, TRUE)

/datum/world_edit_manager/proc/handle_safe_placement_click_v2(mob/user, params, atom/object)
	if(!placement_click_active || !supports_current_placement_ux())
		return FALSE
	if(is_placement_preview_locked())
		return TRUE

	var/list/modifiers = params2list(params)
	var/turf/clicked_turf = get_turf(object)
	if(!clicked_turf)
		return TRUE

	var/shape_id = get_effective_placement_shape()
	var/interaction_kind = get_placement_interaction_kind(shape_id)
	if(!length(shape_id))
		return TRUE

	if(LAZYACCESS(modifiers, MIDDLE_CLICK))
		var/list/collector_points = get_placement_collector_points()
		if(interaction_kind == "collector")
			if(!length(collector_points))
				set_placement_anchor_turf(null)
				set_placement_hover_turf(null)
				clear_placement_collector_origin()
				clear_placement_collector_points()
				clear_preview_plan_state()
				to_chat(user, SPAN_NOTICE("Сбор точек очищен."))
				return TRUE

			collector_points.Cut(length(collector_points), length(collector_points) + 1)
			set_placement_collector_points(collector_points)
			if(length(collector_points))
				var/turf/undo_preview_turf = get_placement_collector_last_absolute_turf(get_placement_collector_origin_turf())
				set_placement_anchor_turf(get_placement_collector_origin_turf())
				set_placement_hover_turf(undo_preview_turf)
				update_placement_collector_runtime_state_v2(user, undo_preview_turf, "Последняя точка удалена. ", FALSE, FALSE)
			else
				set_placement_anchor_turf(null)
				set_placement_hover_turf(null)
				clear_placement_collector_origin()
				clear_placement_collector_points()
				clear_preview_plan_state()
				set_safe_placement_preview_feedback(FALSE, "Сбор точек очищен.", list(), FALSE)
				to_chat(user, SPAN_NOTICE(last_preview_message))
			return TRUE

		set_placement_anchor_turf(null)
		set_placement_hover_turf(null)
		clear_preview_plan_state()
		to_chat(user, SPAN_NOTICE("Опорная точка сброшена."))
		return TRUE

	if(LAZYACCESS(modifiers, RIGHT_CLICK))
		return TRUE

	if(!LAZYACCESS(modifiers, LEFT_CLICK))
		return TRUE

	if(interaction_kind == "collector")
		var/list/collector_points = get_placement_collector_points()
		var/turf/origin_turf = get_placement_collector_origin_turf()
		if(!length(collector_points))
			set_placement_anchor_turf(clicked_turf)
			set_placement_hover_turf(clicked_turf)
			set_placement_collector_origin_turf(clicked_turf)
			set_placement_collector_points(list(list("x" = 0, "y" = 0)))
			update_placement_collector_runtime_state_v2(user, clicked_turf, "Сбор начат. ", FALSE, FALSE)
			return TRUE

		if(!istype(origin_turf))
			origin_turf = placement_anchor_turf || clicked_turf
			set_placement_collector_origin_turf(origin_turf)
			set_placement_anchor_turf(origin_turf)

		var/new_x = clicked_turf.x - origin_turf.x
		var/new_y = clicked_turf.y - origin_turf.y
		var/new_key = "[new_x],[new_y]"
		var/list/first_point = length(collector_points) ? collector_points[1] : null
		var/first_point_key = null
		if(islist(first_point))
			first_point_key = "[text2num("[first_point["x"]]")],[text2num("[first_point["y"]]")]"
		if(length(first_point_key) && new_key == first_point_key && collector_first_point_click_finishes(shape_id) && length(collector_points) >= get_placement_collector_min_points(shape_id))
			set_placement_anchor_turf(origin_turf)
			set_placement_hover_turf(clicked_turf)
			if(handle_repeated_safe_placement_confirm_click(user, clicked_turf))
				return TRUE
			if(!prepare_finished_placement_collection_preview_v2(user, clicked_turf))
				return TRUE
			arm_safe_placement_preview_for_confirm(user, clicked_turf)
			return TRUE
		var/max_points = get_placement_collector_max_points(shape_id)
		if("[shape_id]" == WORLD_EDIT_SHAPE_CUSTOM_MASK)
			for(var/list/existing_point as anything in collector_points)
				var/existing_x = text2num("[existing_point["x"]]")
				var/existing_y = text2num("[existing_point["y"]]")
				if("[existing_x],[existing_y]" == new_key)
					to_chat(user, SPAN_NOTICE("Эта точка уже есть в маске."))
					return TRUE
		if(length(collector_points) >= max_points)
			to_chat(user, SPAN_WARNING("Достигнут безопасный лимит: [max_points] точек."))
			return TRUE

		var/list/proposed_points = GLOB.world_edit_placement_shapes.world_edit_copy_points(collector_points)
		proposed_points += list(list("x" = new_x, "y" = new_y))
		if(istype(current_generator, /datum/world_edit_generator/outpost_radius) && length(proposed_points) >= get_placement_collector_min_points(shape_id))
			set_placement_anchor_turf(origin_turf)
			set_placement_hover_turf(clicked_turf)
			if(!update_placement_collector_runtime_state_v2(user, clicked_turf, "Сбор обновлён. ", FALSE, FALSE, proposed_points))
				return TRUE

			var/datum/world_edit_placement_candidate/collector_candidate = get_placement_preview_candidate()
			var/list/resolved_points = null
			if(istype(collector_candidate?.shape_contract) && islist(collector_candidate.shape_contract.metadata))
				resolved_points = collector_candidate.shape_contract.metadata["normalized_points"]
			if(!islist(resolved_points) || !length(resolved_points))
				resolved_points = proposed_points
			var/turf/resolved_preview_turf = islist(collector_candidate?.placement_context) ? (collector_candidate.placement_context["resolved_end_turf"] || clicked_turf) : clicked_turf
			set_placement_anchor_turf(origin_turf)
			set_placement_hover_turf(resolved_preview_turf)
			set_placement_collector_points(resolved_points)
			mark_preview_state()
			return TRUE

		collector_points = proposed_points
		set_placement_anchor_turf(origin_turf)
		set_placement_hover_turf(clicked_turf)
		set_placement_collector_points(collector_points)
		update_placement_collector_runtime_state_v2(user, clicked_turf, "Сбор обновлён. ", FALSE, FALSE)
		return TRUE

	if(interaction_kind == "anchor_pair" && !istype(placement_anchor_turf))
		show_anchor_pair_preview(clicked_turf, shape_id)
		to_chat(user, SPAN_NOTICE("Опорная точка выбрана: [clicked_turf.x],[clicked_turf.y],[clicked_turf.z]."))
		return TRUE

	var/turf/start_turf = (interaction_kind == "anchor_pair") ? placement_anchor_turf : clicked_turf
	var/turf/end_turf = clicked_turf
	if(interaction_kind == "anchor_pair")
		set_placement_hover_turf(clicked_turf)

	if(handle_repeated_safe_placement_confirm_click(user, clicked_turf))
		return TRUE

	if(!evaluate_safe_placement_preview(user, shape_id, start_turf, end_turf, null, "", FALSE, FALSE))
		if(interaction_kind == "anchor_pair")
			set_placement_anchor_turf(start_turf)
		return TRUE

	arm_safe_placement_preview_for_confirm(user, clicked_turf)
	return TRUE

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
		placement_error_text = current_generator.validate_params(user, build_effective_generator_params(null, shape_id))
	if(placement_error_text)
		return fail_apply(user, placement_error_text)
	if(!acquire_click_intercept("Безопасное размещение"))
		return fail_apply(user, "Перехват клика не активирован.")

	placement_click_active = TRUE
	set_placement_anchor_turf(null)
	var/datum/world_edit_placement_session/session = get_placement_session()
	session.active_shape = shape_id
	session.active_mode = get_effective_placement_mode() || "single"
	clear_preview_plan_state()
	sync_click_intercept_state()

	var/shape_label = GLOB.world_edit_placement_shapes.world_edit_get_placement_shape_label(shape_id)
	var/dir_suffix = supports_current_placement_direction() ? " Направление: [GLOB.world_edit_helpers.dir_to_label(get_effective_placement_dir())]." : "."
	if(interaction_kind == "anchor_pair")
		to_chat(user, SPAN_NOTICE("Режим размещения для [shape_label] активен: первый ЛКМ ставит опорную точку, второй ЛКМ строит предпросмотр, повторный ЛКМ по тому же тайлу открывает подтверждение. СКМ сбрасывает опорную точку.[dir_suffix]"))
	else if(interaction_kind == "collector")
		to_chat(user, SPAN_NOTICE("Режим размещения для [shape_label] активен: ЛКМ добавляет точки, клик по первой точке строит финальный предпросмотр, повторный ЛКМ по тому же тайлу открывает подтверждение. СКМ удаляет последнюю точку, кнопка завершения тоже работает.[dir_suffix]"))
	else if(interaction_kind == "param_only")
		to_chat(user, SPAN_NOTICE("Режим размещения для [shape_label] активен: ЛКМ использует выбранный тайл как опорную точку и строит контур по текущим параметрам формы, повторный ЛКМ по тому же тайлу открывает подтверждение. Интерактивный сбор точек в этом режиме не используется.[dir_suffix]"))
	else
		to_chat(user, SPAN_NOTICE("Режим размещения для [shape_label] активен: ЛКМ закрепляет предпросмотр по выбранному тайлу, повторный ЛКМ по тому же тайлу открывает подтверждение. СКМ сбрасывает опорную точку.[dir_suffix]"))
	return TRUE

/datum/world_edit_manager/proc/handle_safe_placement_click(mob/user, params, atom/object)
	return handle_safe_placement_click_v2(user, params, object)
