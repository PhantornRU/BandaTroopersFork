/datum/world_edit_manager/proc/build_safe_placement_preview_message(datum/world_edit_plan/plan)
	var/list/metadata = plan?.metadata || list()
	var/list/placements = plan?.placements || list()
	var/anchor_count = metadata["anchor_count"] || 1
	var/entry_count = metadata["entry_count"] || length(placements)
	var/collector_point_count = metadata["collector_preview_point_count"] || metadata["collector_point_count"]
	var/mode = metadata["placement_mode"] || get_effective_placement_mode() || "single"
	var/mode_label = mode == "single" ? "один раз" : mode == "repeat" ? "повтор" : "[mode]"
	var/shape_label = metadata["shape_label"] || GLOB.world_edit_placement_shapes.world_edit_get_placement_shape_label(metadata["placement_shape"] || get_effective_placement_shape() || WORLD_EDIT_SHAPE_POINT)
	var/message = "Предпросмотр размещения готов: форма=[shape_label], режим=[mode_label], опор=[anchor_count], действий=[entry_count]."
	if(collector_point_count)
		message += " Точек в сборе=[collector_point_count]."
	if(metadata["placement_dir_label"])
		message = "Предпросмотр размещения готов: форма=[shape_label], режим=[mode_label], опор=[anchor_count], действий=[entry_count], направление=[metadata["placement_dir_label"]]."
		if(collector_point_count)
			message += " Точек в сборе=[collector_point_count]."
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

/datum/world_edit_manager/proc/should_use_placement_layer_preview(datum/world_edit_plan/plan)
	if(!supports_current_placement_ux() || !istype(plan))
		return FALSE
	if(!current_generator?.should_render_preview_via_placement_layers(plan))
		return FALSE
	var/datum/world_edit_shape_contract/shape_contract = build_shape_contract_from_plan_metadata(plan)
	return istype(shape_contract, /datum/world_edit_shape_contract) ? TRUE : FALSE

/datum/world_edit_manager/proc/build_placement_candidate_from_plan(datum/world_edit_plan/plan, list/effective_params = null, mob/user = null)
	if(!supports_current_placement_ux() || !istype(plan))
		return null

	var/list/plan_metadata = islist(plan.metadata) ? plan.metadata : list()
	var/raw_shape_id = plan_metadata["placement_shape"] || resolve_supported_placement_shape(placement_shape) || placement_shape
	var/shape_id = length("[raw_shape_id]") ? "[raw_shape_id]" : WORLD_EDIT_SHAPE_POINT
	if(!length(shape_id))
		return null

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
		return null

	var/raw_placement_mode = plan_metadata["placement_mode"] || get_effective_placement_mode()
	var/placement_mode = length("[raw_placement_mode]") ? "[raw_placement_mode]" : "single"
	var/list/placement_context = build_placement_context(shape_contract, shape_origin_turf, resolved_end_turf, requested_end_turf, seed_turf, shape_origin_turf, placement_dir, placement_mode)
	stamp_placement_plan_shape_metadata(plan, shape_contract, placement_context)
	return build_placement_candidate(shape_contract, placement_context, plan, params_to_use)

/datum/world_edit_manager/proc/update_placement_context_shape_metadata(list/placement_context, datum/world_edit_shape_contract/shape_contract)
	if(!islist(placement_context) || !istype(shape_contract))
		return placement_context

	placement_context["shape"] = shape_contract.shape_id
	placement_context["shape_contract"] = shape_contract
	placement_context["shape_metadata"] = shape_contract.copy_metadata()
	placement_context["anchor_turfs"] = shape_contract.copy_anchor_turfs()
	return placement_context

/datum/world_edit_manager/proc/build_placement_context(datum/world_edit_shape_contract/shape_contract, turf/start_turf, turf/end_turf, turf/requested_end_turf = null, turf/seed_turf = null, turf/shape_origin_turf = null, direction_override = null, mode_override = null)
	if(!istype(shape_contract))
		return list()

	var/effective_direction = isnull(direction_override) ? (supports_current_placement_direction() ? get_effective_placement_dir() : NORTH) : direction_override
	return list(
		"mode" = mode_override || get_effective_placement_mode() || "single",
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

/datum/world_edit_manager/proc/apply_shape_contract_runtime_metadata(datum/world_edit_shape_contract/shape_contract, list/shape_metadata_override = null, list/collector_state_summary = null)
	if(!istype(shape_contract))
		return null
	if(!islist(shape_contract.metadata))
		shape_contract.metadata = list()
	if(islist(shape_metadata_override))
		for(var/key in shape_metadata_override)
			shape_contract.metadata[key] = shape_metadata_override[key]
	if(islist(collector_state_summary))
		for(var/key in collector_state_summary)
			shape_contract.metadata[key] = collector_state_summary[key]
	return shape_contract

/datum/world_edit_manager/proc/build_shape_contract_attempt_signature(datum/world_edit_shape_contract/shape_contract)
	if(!istype(shape_contract))
		return null
	if(length("[shape_contract.error]"))
		return "__error__:[shape_contract.shape_id]:[shape_contract.error]"

	var/list/anchor_turfs = shape_contract.anchor_turfs
	if(!islist(anchor_turfs) || !length(anchor_turfs))
		return "__empty__:[shape_contract.shape_id]:[shape_contract.degenerate_kind]"

	var/list/signature_chunks = list(
		"[shape_contract.shape_id]",
		"[shape_contract.degenerate_kind]",
		"[length(anchor_turfs)]",
	)
	for(var/turf/anchor_turf as anything in anchor_turfs)
		if(!istype(anchor_turf))
			continue
		signature_chunks += "[anchor_turf.x],[anchor_turf.y],[anchor_turf.z]"
	return jointext(signature_chunks, ";")

/datum/world_edit_manager/proc/clear_last_resolved_placement_candidate_cache()
	var/datum/world_edit_placement_session/session = placement_session
	if(!istype(session))
		return FALSE

	session.last_resolved_candidate = null
	session.last_resolved_candidate_params_signature = null
	session.last_resolved_candidate_attempt_signature = null
	session.last_resolved_candidate_end_turf = null
	session.last_resolved_candidate_hover_only = FALSE
	return TRUE

/datum/world_edit_manager/proc/reset_runtime_diagnostics()
	runtime_diagnostics = list(
		"started_at_ds" = world.time,
		"hover_preview_requests" = 0,
		"hover_resolve_calls" = 0,
		"hover_plan_skips" = 0,
		"preview_plan_defers" = 0,
		"click_resolve_calls" = 0,
		"deferred_apply_plan_builds" = 0,
		"resolve_cache_hits" = 0,
		"resolve_cache_misses" = 0,
		"outpost_clamp_attempts" = 0,
		"outpost_clamp_successes" = 0,
		"outpost_clamp_hover_skips" = 0,
		"preview_render_calls" = 0,
		"preview_render_skips" = 0,
		"preview_image_rebuilds" = 0,
		"preview_images_last" = 0,
		"preview_images_peak" = 0,
	)
	return runtime_diagnostics

/datum/world_edit_manager/proc/get_runtime_diagnostics()
	if(!islist(runtime_diagnostics) || !length(runtime_diagnostics))
		reset_runtime_diagnostics()
	return runtime_diagnostics

/datum/world_edit_manager/proc/increment_runtime_diagnostic(counter_id, amount = 1)
	if(!length("[counter_id]"))
		return 0

	var/list/diagnostics = get_runtime_diagnostics()
	var/current_value = text2num("[diagnostics[counter_id]]")
	current_value += amount
	diagnostics[counter_id] = current_value
	return current_value

/datum/world_edit_manager/proc/set_runtime_diagnostic_peak(counter_id, value)
	if(!length("[counter_id]"))
		return 0

	var/list/diagnostics = get_runtime_diagnostics()
	var/current_value = text2num("[diagnostics[counter_id]]")
	var/next_value = max(current_value, value)
	diagnostics[counter_id] = next_value
	return next_value

/datum/world_edit_manager/proc/build_runtime_status_entries()
	var/list/entries = list()
	var/list/diagnostics = get_runtime_diagnostics()
	var/list/generator_entries = current_generator?.get_runtime_status()
	var/has_placement_activity = FALSE
	for(var/counter_id in list(
		"hover_preview_requests",
		"hover_resolve_calls",
		"hover_plan_skips",
		"preview_plan_defers",
		"click_resolve_calls",
		"deferred_apply_plan_builds",
		"resolve_cache_hits",
		"resolve_cache_misses",
		"outpost_clamp_attempts",
		"outpost_clamp_successes",
		"outpost_clamp_hover_skips",
		"preview_render_calls",
		"preview_render_skips",
		"preview_image_rebuilds",
	))
		if(text2num("[diagnostics[counter_id]]") > 0)
			has_placement_activity = TRUE
			break

	if(supports_current_placement_ux() && has_placement_activity)
		var/started_at_ds = diagnostics["started_at_ds"] || world.time
		var/hover_preview_requests = diagnostics["hover_preview_requests"] || 0
		var/hover_resolve_calls = diagnostics["hover_resolve_calls"] || 0
		var/hover_plan_skips = diagnostics["hover_plan_skips"] || 0
		var/preview_plan_defers = diagnostics["preview_plan_defers"] || 0
		var/click_resolve_calls = diagnostics["click_resolve_calls"] || 0
		var/deferred_apply_plan_builds = diagnostics["deferred_apply_plan_builds"] || 0
		var/resolve_cache_hits = diagnostics["resolve_cache_hits"] || 0
		var/resolve_cache_misses = diagnostics["resolve_cache_misses"] || 0
		var/outpost_clamp_attempts = diagnostics["outpost_clamp_attempts"] || 0
		var/outpost_clamp_successes = diagnostics["outpost_clamp_successes"] || 0
		var/outpost_clamp_hover_skips = diagnostics["outpost_clamp_hover_skips"] || 0
		var/preview_image_rebuilds = diagnostics["preview_image_rebuilds"] || 0
		var/preview_render_skips = diagnostics["preview_render_skips"] || 0
		var/preview_images_last = diagnostics["preview_images_last"] || 0
		var/preview_images_peak = diagnostics["preview_images_peak"] || 0
		var/elapsed_seconds = round(max(0, world.time - started_at_ds) / 10, 1)
		entries += list(
			list("label" = "Session", "value" = "[elapsed_seconds]s"),
			list("label" = "Hover preview", "value" = "[hover_preview_requests]"),
			list("label" = "Hover resolve", "value" = "[hover_resolve_calls]"),
			list("label" = "Hover plan skip", "value" = "[hover_plan_skips]"),
			list("label" = "Preview defer", "value" = "[preview_plan_defers]"),
			list("label" = "Click resolve", "value" = "[click_resolve_calls]"),
			list("label" = "Apply plan", "value" = "[deferred_apply_plan_builds]"),
			list("label" = "Cache", "value" = "[resolve_cache_hits]/[resolve_cache_misses]"),
			list("label" = "Clamp tries", "value" = "[outpost_clamp_attempts]"),
			list("label" = "Clamp ok", "value" = "[outpost_clamp_successes]"),
			list("label" = "Clamp hover skip", "value" = "[outpost_clamp_hover_skips]"),
			list("label" = "Render rebuilds", "value" = "[preview_image_rebuilds]"),
			list("label" = "Render skips", "value" = "[preview_render_skips]"),
			list("label" = "Images", "value" = "[preview_images_last]/[preview_images_peak]"),
		)

	if(islist(generator_entries))
		for(var/list/entry as anything in generator_entries)
			if(!islist(entry))
				continue
			var/label = "[entry["label"]]"
			if(!length(label))
				continue
			entries += list(list(
				"label" = label,
				"value" = "[entry["value"]]",
			))
	return entries

/datum/world_edit_manager/proc/get_last_resolved_placement_candidate(list/effective_params, datum/world_edit_shape_contract/shape_contract, turf/resolved_end_turf, hover_only = FALSE, turf/requested_end_turf = null, turf/seed_turf = null, turf/shape_origin_turf = null, list/collector_state_summary = null)
	var/datum/world_edit_placement_session/session = placement_session
	if(!istype(session))
		return null

	var/datum/world_edit_placement_candidate/candidate = session.last_resolved_candidate
	if(!istype(candidate) || !istype(resolved_end_turf))
		return null
	if(session.last_resolved_candidate_hover_only != (hover_only ? TRUE : FALSE))
		return null

	var/params_signature = build_preview_params_signature(effective_params, FALSE)
	if(session.last_resolved_candidate_params_signature != params_signature)
		return null

	var/attempt_signature = build_shape_contract_attempt_signature(shape_contract)
	if(session.last_resolved_candidate_attempt_signature != attempt_signature)
		return null
	if(session.last_resolved_candidate_end_turf != resolved_end_turf)
		return null

	candidate.hover_only = hover_only ? TRUE : FALSE
	increment_runtime_diagnostic(hover_only ? "hover_resolve_calls" : "click_resolve_calls")
	candidate.runtime_params = islist(effective_params) ? effective_params.Copy() : list()
	candidate.shape_contract = shape_contract
	if(islist(collector_state_summary))
		candidate.collector_state_summary = collector_state_summary.Copy()
	if(!islist(candidate.placement_context))
		candidate.placement_context = list()
	candidate.placement_context["requested_end_turf"] = requested_end_turf || resolved_end_turf
	candidate.placement_context["resolved_end_turf"] = resolved_end_turf
	if(istype(seed_turf))
		candidate.placement_context["seed_turf"] = seed_turf
	if(istype(shape_origin_turf))
		candidate.placement_context["shape_origin_turf"] = shape_origin_turf
	update_placement_context_shape_metadata(candidate.placement_context, shape_contract)
	if(istype(candidate.plan))
		stamp_placement_plan_shape_metadata(candidate.plan, shape_contract, candidate.placement_context)
	return candidate

/datum/world_edit_manager/proc/cache_last_resolved_placement_candidate(datum/world_edit_placement_candidate/candidate, datum/world_edit_shape_contract/shape_contract = null)
	var/datum/world_edit_placement_session/session = placement_session
	if(!istype(session) || !istype(candidate) || !candidate.is_preview_ready())
		return FALSE

	var/turf/resolved_end_turf = islist(candidate.placement_context) ? (candidate.placement_context["resolved_end_turf"] || candidate.placement_context["end_turf"]) : null
	if(!istype(resolved_end_turf))
		return FALSE

	session.last_resolved_candidate = candidate
	session.last_resolved_candidate_params_signature = build_preview_params_signature(candidate.runtime_params, FALSE)
	session.last_resolved_candidate_attempt_signature = build_shape_contract_attempt_signature(shape_contract || candidate.shape_contract)
	session.last_resolved_candidate_end_turf = resolved_end_turf
	session.last_resolved_candidate_hover_only = candidate.hover_only ? TRUE : FALSE
	return TRUE

/datum/world_edit_manager/proc/build_placement_preview_turf_signature(list/turfs)
	if(!islist(turfs) || !length(turfs))
		return "<empty>"

	var/list/turf_chunks = list()
	for(var/turf/target_turf as anything in turfs)
		if(!istype(target_turf))
			continue
		turf_chunks += GLOB.world_edit_helpers.turf_to_text(target_turf)

	if(!length(turf_chunks))
		return "<empty>"
	return md5(jointext(turf_chunks, ";"))

/datum/world_edit_manager/proc/build_placement_preview_layer_render_token(list/turfs, icon_state, color = null, alpha = null)
	var/turf_count = islist(turfs) ? length(turfs) : 0
	var/turf_signature = build_placement_preview_turf_signature(turfs)
	var/list/token_chunks = list(
		length("[icon_state]") ? "[icon_state]" : "greenOverlay",
		isnull(color) ? "" : "[color]",
		isnum(alpha) ? "[clamp(round(alpha), 0, 255)]" : "",
		"[turf_count]",
		turf_signature,
	)
	return jointext(token_chunks, "|")

/datum/world_edit_manager/proc/build_placement_preview_render_token(datum/world_edit_preview_model/preview_model)
	if(!istype(preview_model))
		return null

	var/object_preview_signature = GLOB.world_edit_helpers.build_preview_spec_signature(preview_model.generator_preview_object_specs)
	return jointext(list(
		build_placement_preview_layer_render_token(preview_model.anchor_turfs, "blueOverlay", "#78C8FF", 255),
		build_placement_preview_layer_render_token(preview_model.vertex_turfs, "blueOverlay", "#B8F3FF", 210),
		build_placement_preview_layer_render_token(preview_model.edge_turfs, "greenOverlay", "#4DE1C1", 190),
		build_placement_preview_layer_render_token(preview_model.closure_turfs, "redOverlay", "#FFB347", 180),
		build_placement_preview_layer_render_token(preview_model.final_turfs, "greenOverlay", "#8BFFB5", 120),
		build_placement_preview_layer_render_token(preview_model.guide_turfs, "blueOverlay", "#D7B8FF", 150),
		build_placement_preview_layer_render_token(preview_model.generator_effect_turfs, "redOverlay", "#FF6B6B", 110),
		object_preview_signature,
	), "||")

/datum/world_edit_manager/proc/build_placement_candidate(datum/world_edit_shape_contract/shape_contract, list/placement_context, datum/world_edit_plan/plan = null, list/runtime_params = null, hover_only = FALSE, list/collector_state_summary = null)
	if(!istype(shape_contract))
		return null

	var/datum/world_edit_placement_candidate/candidate = new
	candidate.hover_only = hover_only ? TRUE : FALSE
	candidate.shape_contract = shape_contract
	candidate.preview_model = GLOB.world_edit_shape_preview.build_shape_preview(shape_contract)
	candidate.plan = plan
	candidate.runtime_params = islist(runtime_params) ? runtime_params.Copy() : list()
	candidate.placement_context = islist(placement_context) ? placement_context.Copy() : list()
	update_placement_context_shape_metadata(candidate.placement_context, shape_contract)
	if(islist(collector_state_summary))
		candidate.collector_state_summary = collector_state_summary.Copy()
	if(istype(candidate.preview_model))
		if(istype(plan))
			candidate.preview_model.generator_effect_turfs = get_safe_placement_generator_effect_turfs(plan)
			candidate.preview_model.generator_preview_object_specs = current_generator?.build_plan_preview_object_specs(plan, candidate.runtime_params, candidate.placement_context, hover_only)
		candidate.preview_render_token = build_placement_preview_render_token(candidate.preview_model)
		candidate.preview_model.preview_render_token = candidate.preview_render_token
	return candidate

/datum/world_edit_manager/proc/stamp_placement_plan_shape_metadata(datum/world_edit_plan/plan, datum/world_edit_shape_contract/shape_contract, list/placement_context)
	if(!istype(plan))
		return null

	current_generator?.stamp_plan_shape_metadata(plan, shape_contract, placement_context)
	update_placement_context_shape_metadata(placement_context, shape_contract)
	return plan

/datum/world_edit_manager/proc/populate_resolved_placement_candidate_plan(mob/user, datum/world_edit_placement_candidate/candidate, list/effective_params = null, hover_only = FALSE)
	if(!istype(candidate) || !current_generator)
		return candidate
	if(length("[candidate.support_error]") || length("[candidate.resolve_error]") || istype(candidate.plan))
		return candidate

	var/datum/world_edit_shape_contract/shape_contract = candidate.shape_contract
	if(!istype(shape_contract))
		candidate.resolve_error = "Не удалось определить контур размещения."
		return candidate

	if(!islist(candidate.placement_context))
		candidate.placement_context = list()
	update_placement_context_shape_metadata(candidate.placement_context, shape_contract)

	var/list/runtime_params = islist(effective_params) ? effective_params.Copy() : (islist(candidate.runtime_params) ? candidate.runtime_params.Copy() : list())
	candidate.runtime_params = runtime_params.Copy()

	var/list/support_result = current_generator.evaluate_shape_contract(shape_contract, runtime_params, candidate.placement_context)
	var/datum/world_edit_plan/prebuilt_plan = null
	if(islist(support_result))
		var/list/support_metadata = support_result["metadata"]
		if(islist(support_metadata))
			for(var/key in support_metadata)
				shape_contract.metadata[key] = support_metadata[key]
			update_placement_context_shape_metadata(candidate.placement_context, shape_contract)
		candidate.support_error = support_result["error"]
		prebuilt_plan = support_result["plan"]
	else
		candidate.support_error = support_result
	if(length("[candidate.support_error]"))
		return candidate

	var/datum/world_edit_plan/plan = istype(prebuilt_plan) ? prebuilt_plan : current_generator.build_plan_from_shape_contract(user, shape_contract, runtime_params, candidate.placement_context)
	if(!istype(plan))
		candidate.resolve_error = "Не удалось построить план размещения."
		return candidate

	candidate.plan = plan
	current_generator.finalize_shared_placement_plan_metadata(plan, shape_contract, candidate.placement_context)
	if(plan.metadata["error"])
		candidate.resolve_error = "[plan.metadata["error"]]"
		return candidate
	if(!length(plan.placements) && !length(plan.deletions))
		candidate.resolve_error = "План размещения пуст."
		return candidate
	if(istype(candidate.preview_model))
		candidate.preview_model.generator_effect_turfs = get_safe_placement_generator_effect_turfs(plan)
		candidate.preview_model.generator_preview_object_specs = current_generator?.build_plan_preview_object_specs(plan, runtime_params, candidate.placement_context, hover_only)
		candidate.preview_render_token = build_placement_preview_render_token(candidate.preview_model)
		candidate.preview_model.preview_render_token = candidate.preview_render_token
	return candidate

/datum/world_edit_manager/proc/build_safe_placement_plan_from_shape_result(mob/user, shape_id, list/shape_result, turf/start_turf, turf/end_turf, list/shape_metadata_override = null)
	var/datum/world_edit_shape_contract/shape_contract = GLOB.world_edit_shape_geometry.build_shape_contract_from_result(shape_id, shape_result)
	if(islist(shape_metadata_override))
		if(!islist(shape_contract.metadata))
			shape_contract.metadata = list()
		for(var/key in shape_metadata_override)
			shape_contract.metadata[key] = shape_metadata_override[key]

	var/list/placement_context = build_placement_context(shape_contract, start_turf, end_turf, end_turf, start_turf, start_turf, get_effective_placement_dir())
	var/datum/world_edit_plan/plan = current_generator?.build_plan_from_shape_contract(user, shape_contract, build_effective_generator_params(null, shape_id), placement_context)
	stamp_placement_plan_shape_metadata(plan, shape_contract, placement_context)
	return plan

/datum/world_edit_manager/proc/get_safe_placement_generator_effect_turfs(datum/world_edit_plan/plan)
	if(!istype(plan))
		return list()

	var/list/metadata = plan.metadata
	if(islist(metadata) && islist(metadata["generator_effect_turfs"]))
		return GLOB.world_edit_placement_shapes.world_edit_unique_turf_list(metadata["generator_effect_turfs"])
	return GLOB.world_edit_placement_shapes.world_edit_unique_turf_list(plan.affected_turfs)

/datum/world_edit_manager/proc/render_safe_placement_preview(datum/world_edit_placement_candidate/candidate)
	increment_runtime_diagnostic("preview_render_calls")
	store_placement_preview_candidate(candidate)
	if(!holder)
		return
	var/render_token = length("[placement_preview_render_token]") ? "[placement_preview_render_token]" : null
	if(preview_groups_signature == render_token && length("[render_token]"))
		increment_runtime_diagnostic("preview_render_skips")
		return

	clear_preview_images()
	var/list/images = GLOB.world_edit_helpers.build_grouped_turf_preview_images(get_placement_preview_groups())
	var/list/object_specs = candidate?.preview_model?.generator_preview_object_specs
	if(islist(object_specs) && length(object_specs))
		images += GLOB.world_edit_helpers.build_preview_images_from_specs(object_specs)
	increment_runtime_diagnostic("preview_image_rebuilds")
	get_runtime_diagnostics()["preview_images_last"] = length(images)
	set_runtime_diagnostic_peak("preview_images_peak", length(images))
	if(length(images))
		holder.images += images
		preview_images = images.Copy()
	preview_groups_signature = render_token || GLOB.world_edit_helpers.build_grouped_turf_preview_signature(get_placement_preview_groups())

/datum/world_edit_manager/proc/render_plan_preview_with_placement_layers(mob/user, datum/world_edit_plan/plan, list/effective_params = null)
	var/datum/world_edit_placement_candidate/candidate = build_placement_candidate_from_plan(plan, effective_params, user)
	if(!istype(candidate))
		return FALSE
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

/datum/world_edit_manager/proc/resolve_placement_candidate_from_shape_contract(mob/user, datum/world_edit_shape_contract/shape_contract, turf/start_turf, turf/end_turf, list/effective_params, effective_direction, hover_only = FALSE, list/shape_metadata_override = null, list/collector_state_summary = null, turf/requested_end_turf = null, turf/seed_turf = null, turf/shape_origin_turf = null)
	var/datum/world_edit_placement_candidate/candidate = new
	candidate.hover_only = hover_only ? TRUE : FALSE
	increment_runtime_diagnostic(hover_only ? "hover_resolve_calls" : "click_resolve_calls")
	if(!istype(shape_contract))
		candidate.resolve_error = "Не удалось построить контракт формы для размещения."
		return candidate

	apply_shape_contract_runtime_metadata(shape_contract, shape_metadata_override, collector_state_summary)
	var/datum/world_edit_placement_candidate/cached_candidate = get_last_resolved_placement_candidate(
		effective_params,
		shape_contract,
		end_turf,
		hover_only,
		requested_end_turf || end_turf,
		seed_turf,
		shape_origin_turf,
		collector_state_summary,
	)
	if(istype(cached_candidate))
		increment_runtime_diagnostic("resolve_cache_hits")
		return cached_candidate
	increment_runtime_diagnostic("resolve_cache_misses")

	var/list/placement_context = build_placement_context(shape_contract, start_turf, end_turf, requested_end_turf || end_turf, seed_turf, shape_origin_turf, effective_direction)
	candidate = build_placement_candidate(shape_contract, placement_context, null, effective_params, hover_only, collector_state_summary)
	if(!istype(candidate))
		candidate = new
		candidate.hover_only = hover_only ? TRUE : FALSE
		candidate.resolve_error = "Не удалось подготовить кандидата размещения."
		return candidate

	if(shape_contract.error)
		candidate.resolve_error = "[shape_contract.error]"
		return candidate
	if(!length(shape_contract.anchor_turfs))
		candidate.resolve_error = "Недопустимый контур размещения."
		return candidate

	if(current_generator?.should_skip_plan_build_for_safe_preview(shape_contract, effective_params, candidate.placement_context, hover_only))
		increment_runtime_diagnostic("preview_plan_defers")
		if(hover_only)
			increment_runtime_diagnostic("hover_plan_skips")
		return candidate

	populate_resolved_placement_candidate_plan(user, candidate, effective_params, hover_only)
	if(istype(candidate.plan) || length("[candidate.get_failure_message()]"))
		cache_last_resolved_placement_candidate(candidate, shape_contract)
		return candidate

	var/list/support_result = current_generator.evaluate_shape_contract(shape_contract, effective_params, candidate.placement_context)
	var/datum/world_edit_plan/prebuilt_plan = null
	if(islist(support_result))
		var/list/support_metadata = support_result["metadata"]
		if(islist(support_metadata))
			for(var/key in support_metadata)
				shape_contract.metadata[key] = support_metadata[key]
			update_placement_context_shape_metadata(candidate.placement_context, shape_contract)
		candidate.support_error = support_result["error"]
		prebuilt_plan = support_result["plan"]
	else
		candidate.support_error = support_result
	if(length("[candidate.support_error]"))
		return candidate

	var/datum/world_edit_plan/plan = istype(prebuilt_plan) ? prebuilt_plan : current_generator.build_plan_from_shape_contract(user, shape_contract, effective_params, candidate.placement_context)
	if(!istype(plan))
		candidate.resolve_error = "Не удалось построить план размещения."
		return candidate
	candidate.plan = plan
	current_generator.finalize_shared_placement_plan_metadata(plan, shape_contract, candidate.placement_context)
	if(plan.metadata["error"])
		candidate.resolve_error = "[plan.metadata["error"]]"
		return candidate
	if(!length(plan.placements) && !length(plan.deletions))
		candidate.resolve_error = "План размещения пуст."
		return candidate
	if(istype(candidate.preview_model))
		candidate.preview_model.generator_effect_turfs = get_safe_placement_generator_effect_turfs(plan)
		candidate.preview_model.generator_preview_object_specs = current_generator?.build_plan_preview_object_specs(plan, effective_params, candidate.placement_context, hover_only)
		candidate.preview_render_token = build_placement_preview_render_token(candidate.preview_model)
		candidate.preview_model.preview_render_token = candidate.preview_render_token
	cache_last_resolved_placement_candidate(candidate, shape_contract)
	return candidate

/datum/world_edit_manager/proc/resolve_placement_candidate(mob/user, turf/start_turf, turf/end_turf, list/runtime_params = null, hover_only = FALSE, list/shape_metadata_override = null, list/collector_state_summary = null, shape_id_override = null, turf/requested_end_turf = null, turf/seed_turf = null, turf/shape_origin_turf = null)
	if(!current_generator)
		var/datum/world_edit_placement_candidate/candidate = new
		candidate.hover_only = hover_only ? TRUE : FALSE
		candidate.resolve_error = "Генератор не активен."
		return candidate

	var/shape_id = shape_id_override || get_effective_placement_shape() || WORLD_EDIT_SHAPE_POINT
	var/effective_direction = supports_current_placement_direction() ? get_effective_placement_dir() : NORTH
	var/list/effective_params = islist(runtime_params) ? runtime_params.Copy() : build_effective_generator_params(null, shape_id)
	var/datum/world_edit_shape_contract/shape_contract = GLOB.world_edit_shape_geometry.build_shape_contract(shape_id, start_turf, end_turf, effective_params, effective_direction)
	return resolve_placement_candidate_from_shape_contract(user, shape_contract, start_turf, end_turf, effective_params, effective_direction, hover_only, shape_metadata_override, collector_state_summary, requested_end_turf, seed_turf, shape_origin_turf)

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
	var/can_attempt_clamp = can_attempt_outpost_endpoint_clamp(requested_shape_id, start_turf, requested_turf, segment_start_turf)
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
	// Hover previews must stay cheap: endpoint clamp can retry many shorter shapes and
	// explode into repeated full plan builds while the cursor is moving.
	if(hover_only)
		if(can_attempt_clamp)
			increment_runtime_diagnostic("outpost_clamp_hover_skips")
		return candidate
	if(!can_attempt_clamp)
		return candidate

	segment_start_turf = segment_start_turf || start_turf
	var/list/segment_turfs = GLOB.world_edit_helpers.collect_line_turfs(segment_start_turf, requested_turf)
	if(!islist(segment_turfs) || length(segment_turfs) <= 1)
		return candidate

	var/effective_direction = supports_current_placement_direction() ? get_effective_placement_dir() : NORTH
	var/list/effective_params = islist(runtime_params) ? runtime_params.Copy() : build_effective_generator_params(null, requested_shape_id)
	var/list/attempted_signatures = list()
	for(var/i = length(segment_turfs) - 1, i >= 1, i--)
		var/turf/clamped_end_turf = segment_turfs[i]
		if(!istype(clamped_end_turf) || clamped_end_turf == requested_turf || clamped_end_turf == segment_start_turf)
			continue

		var/datum/world_edit_shape_contract/clamped_shape_contract = GLOB.world_edit_shape_geometry.build_shape_contract(requested_shape_id, start_turf, clamped_end_turf, effective_params, effective_direction)
		var/attempt_signature = build_shape_contract_attempt_signature(clamped_shape_contract)
		if(length(attempt_signature))
			if(attempted_signatures[attempt_signature])
				continue
			attempted_signatures[attempt_signature] = TRUE

		increment_runtime_diagnostic("outpost_clamp_attempts")
		var/datum/world_edit_placement_candidate/clamped_candidate = resolve_placement_candidate_from_shape_contract(
			user,
			clamped_shape_contract,
			start_turf,
			clamped_end_turf,
			effective_params,
			effective_direction,
			hover_only,
			shape_metadata_override,
			collector_state_summary,
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
		stamp_placement_plan_shape_metadata(clamped_candidate.plan, clamped_candidate.shape_contract, clamped_candidate.placement_context)
		increment_runtime_diagnostic("outpost_clamp_successes")
		return clamped_candidate

	return candidate

/datum/world_edit_manager/proc/evaluate_safe_placement_preview(mob/user, shape_id, turf/start_turf, turf/end_turf, list/shape_metadata_override = null, message_prefix = "", silent = FALSE, hover_only = FALSE)
	set_placement_hover_turf(end_turf)
	if(hover_only)
		increment_runtime_diagnostic("hover_preview_requests")
	var/list/effective_params = build_effective_generator_params(null, shape_id)
	var/datum/world_edit_placement_candidate/candidate = resolve_placement_candidate_with_optional_outpost_clamp(user, start_turf, end_turf, effective_params, hover_only, shape_metadata_override, null, shape_id, end_turf, start_turf, start_turf, start_turf)
	render_safe_placement_preview(candidate)
	var/failure_message = candidate.get_failure_message()
	if(length("[failure_message]"))
		set_safe_placement_preview_feedback(FALSE, "[message_prefix][failure_message]", candidate.plan?.metadata || candidate.shape_contract?.metadata, FALSE)
		if(!silent)
			to_chat(user, SPAN_WARNING(last_preview_message))
		return FALSE

	var/list/preview_feedback_meta = candidate.plan?.metadata || candidate.shape_contract?.metadata || list()
	set_safe_placement_preview_feedback(TRUE, "[message_prefix][build_safe_placement_preview_message(candidate.plan)]", preview_feedback_meta, hover_only ? FALSE : TRUE)
	if(!silent)
		to_chat(user, SPAN_NOTICE(last_preview_message))
	return TRUE

/datum/world_edit_manager/proc/apply_resolved_placement_candidate(mob/user, datum/world_edit_placement_candidate/candidate = null, force_confirm = FALSE, cancel_placement_on_confirm_reject = FALSE)
	candidate = candidate || get_placement_preview_candidate()
	if(istype(candidate) && !candidate.hover_only && !istype(candidate.plan) && current_generator?.should_skip_plan_build_for_safe_preview(candidate.shape_contract, candidate.runtime_params, candidate.placement_context, FALSE))
		increment_runtime_diagnostic("deferred_apply_plan_builds")
		populate_resolved_placement_candidate_plan(user, candidate, candidate.runtime_params, FALSE)
		if(length("[candidate.get_failure_message()]"))
			render_safe_placement_preview(candidate)
			set_safe_placement_preview_feedback(FALSE, "[candidate.get_failure_message()]", candidate.plan?.metadata || candidate.shape_contract?.metadata, FALSE)
			to_chat(user, SPAN_WARNING(last_preview_message))
			return TRUE
		cache_last_resolved_placement_candidate(candidate, candidate.shape_contract)
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
			arm_placement_confirm_for_turf(confirm_turf, candidate)
			return TRUE

	set_placement_preview_locked(FALSE)
	var/mode = get_effective_placement_mode()
	var/start_ds = world.time
	var/datum/world_edit_apply_result/result = current_generator.apply_built_plan(user, candidate.runtime_params, plan)
	if(!istype(result))
		teardown_preview_session_runtime()
		return fail_apply(user, "Генератор вернул некорректный результат применения.")

	record_apply_result(user, result, world.time - start_ds)
	teardown_preview_session_runtime()
	if(mode == "single")
		if(result.success)
			teardown_preview_session_runtime(TRUE, FALSE, FALSE, TRUE)
		else
			sync_click_intercept_state()
			placement_click_active = click_intercept_owned ? TRUE : FALSE
	else if(result.success)
		sync_click_intercept_state()
		placement_click_active = click_intercept_owned ? TRUE : FALSE
		teardown_preview_session_runtime(FALSE, TRUE, is_current_placement_collector())
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

/datum/world_edit_manager/proc/show_anchor_pair_preview(turf/anchor_turf, shape_id)
	teardown_preview_session_runtime()
	set_placement_anchor_turf(anchor_turf)
	set_placement_hover_turf(anchor_turf)
	var/list/effective_params = build_effective_generator_params(null, shape_id)
	var/datum/world_edit_shape_contract/shape_contract = GLOB.world_edit_shape_geometry.build_shape_contract(shape_id, anchor_turf, anchor_turf, effective_params, supports_current_placement_direction() ? get_effective_placement_dir() : NORTH)
	var/list/placement_context = build_placement_context(shape_contract, anchor_turf, anchor_turf, anchor_turf, anchor_turf, anchor_turf)
	var/datum/world_edit_placement_candidate/candidate = build_placement_candidate(shape_contract, placement_context, null, effective_params, TRUE)
	render_safe_placement_preview(candidate)

/datum/world_edit_manager/proc/rebuild_active_safe_placement_preview(mob/user, shape_id = null, turf/preview_turf = null, silent = TRUE, hover_only = TRUE, allow_anchor_placeholder = FALSE)
	shape_id = shape_id || get_effective_placement_shape()
	if(!length("[shape_id]"))
		return FALSE

	var/interaction_kind = get_placement_interaction_kind(shape_id)
	switch(interaction_kind)
		if("anchor_pair")
			if(!istype(placement_anchor_turf))
				return FALSE
			var/turf/effective_preview_turf = preview_turf || placement_hover_turf
			if(!istype(effective_preview_turf) || effective_preview_turf == placement_anchor_turf)
				if(!allow_anchor_placeholder)
					if(!istype(effective_preview_turf))
						return FALSE
					return evaluate_safe_placement_preview(user, shape_id, placement_anchor_turf, effective_preview_turf, null, "", silent, hover_only)
				if(istype(effective_preview_turf) && evaluate_safe_placement_preview(user, shape_id, placement_anchor_turf, effective_preview_turf, null, "", silent, hover_only))
					return TRUE
				show_anchor_pair_preview(placement_anchor_turf, shape_id)
				return TRUE
			return evaluate_safe_placement_preview(user, shape_id, placement_anchor_turf, effective_preview_turf, null, "", silent, hover_only)
		if("collector")
			if(!length(get_placement_collector_points()))
				return FALSE
			var/turf/effective_preview_turf = preview_turf || placement_hover_turf || get_placement_collector_origin_turf() || placement_anchor_turf
			if(!istype(effective_preview_turf))
				return FALSE
			return update_placement_collector_runtime_state(user, effective_preview_turf, "", silent, hover_only)
		if("single", "param_only")
			var/turf/effective_preview_turf = preview_turf || placement_hover_turf || placement_anchor_turf
			if(!istype(effective_preview_turf))
				return FALSE
			return evaluate_safe_placement_preview(user, shape_id, effective_preview_turf, effective_preview_turf, null, "", silent, hover_only)
	return FALSE

/datum/world_edit_manager/proc/handle_safe_placement_hover(mob/user, turf/hover_turf)
	if(!placement_click_active || !supports_current_placement_ux())
		return FALSE
	if(is_placement_preview_locked())
		return TRUE
	if(!istype(hover_turf))
		return FALSE
	if(holder != user?.client)
		return FALSE
	if(is_placement_confirm_armed_for_turf())
		return TRUE
	var/datum/world_edit_placement_candidate/current_candidate = get_placement_preview_candidate()
	var/current_candidate_signature = islist(current_candidate?.placement_context) ? current_candidate.placement_context["preview_signature"] : null
	if(hover_turf == placement_hover_turf && istype(current_candidate) && current_candidate.hover_only && current_candidate_signature == placement_preview_signature)
		return TRUE

	return rebuild_active_safe_placement_preview(user, null, hover_turf, TRUE, TRUE, FALSE)

/datum/world_edit_manager/proc/collector_first_point_click_finishes(shape_id)
	switch("[shape_id]")
		if(WORLD_EDIT_SHAPE_POLYGON, WORLD_EDIT_SHAPE_POLYLINE, WORLD_EDIT_SHAPE_BRUSH_PATH)
			return TRUE
	return FALSE

/datum/world_edit_manager/proc/collector_repeated_last_point_finishes(shape_id)
	switch("[shape_id]")
		if(WORLD_EDIT_SHAPE_POLYGON, WORLD_EDIT_SHAPE_POLYLINE, WORLD_EDIT_SHAPE_CUSTOM_MASK, WORLD_EDIT_SHAPE_BRUSH_PATH)
			return TRUE
	return FALSE

/datum/world_edit_manager/proc/reset_safe_placement_attempt(mob/user, message = "Текущая попытка размещения отменена.")
	teardown_preview_session_runtime(TRUE, TRUE, FALSE)
	set_safe_placement_preview_feedback(FALSE, "[message]", list(), FALSE)
	if(user)
		to_chat(user, SPAN_NOTICE(last_preview_message))
	return TRUE

/datum/world_edit_manager/proc/reset_safe_placement_collection_attempt(mob/user, message = "Сбор точек очищен.")
	teardown_preview_session_runtime(TRUE, TRUE, TRUE)
	set_safe_placement_preview_feedback(FALSE, "[message]", list(), FALSE)
	if(user)
		to_chat(user, SPAN_NOTICE(last_preview_message))
	return TRUE

/datum/world_edit_manager/proc/should_reset_failed_anchor_pair_same_tile_click(turf/start_turf, turf/clicked_turf)
	if(!istype(start_turf) || !istype(clicked_turf))
		return FALSE
	if(clicked_turf != start_turf)
		return FALSE
	if(is_placement_confirm_armed_for_turf(clicked_turf))
		return FALSE
	return TRUE

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

/datum/world_edit_manager/proc/handle_safe_placement_click(mob/user, params, atom/object)
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
			update_placement_collector_runtime_state(user, clicked_turf, "Сбор начат. ", FALSE, FALSE)
			return TRUE

		if(!istype(origin_turf))
			origin_turf = placement_anchor_turf || clicked_turf
			set_placement_collector_origin_turf(origin_turf)
			set_placement_anchor_turf(origin_turf)
		if(handle_repeated_safe_placement_confirm_click(user, clicked_turf))
			return TRUE

		var/new_x = clicked_turf.x - origin_turf.x
		var/new_y = clicked_turf.y - origin_turf.y
		var/new_key = "[new_x],[new_y]"
		var/list/first_point = length(collector_points) ? collector_points[1] : null
		var/first_point_key = null
		if(islist(first_point))
			first_point_key = "[text2num("[first_point["x"]]")],[text2num("[first_point["y"]]")]"
		var/list/last_point = length(collector_points) ? collector_points[length(collector_points)] : null
		var/last_point_key = null
		if(islist(last_point))
			last_point_key = "[text2num("[last_point["x"]]")],[text2num("[last_point["y"]]")]"
		if(length(first_point_key) && new_key == first_point_key && collector_first_point_click_finishes(shape_id) && length(collector_points) >= get_placement_collector_min_points(shape_id))
			set_placement_anchor_turf(origin_turf)
			set_placement_hover_turf(clicked_turf)
			if(!prepare_finished_placement_collection_preview(user, clicked_turf))
				return TRUE
			arm_safe_placement_preview_for_confirm(user)
			return TRUE
		if(length(last_point_key) && new_key == last_point_key)
			if(length(collector_points) >= get_placement_collector_min_points(shape_id) && collector_repeated_last_point_finishes(shape_id))
				set_placement_anchor_turf(origin_turf)
				set_placement_hover_turf(clicked_turf)
				if(!prepare_finished_placement_collection_preview(user, clicked_turf))
					return TRUE
				arm_safe_placement_preview_for_confirm(user)
				return TRUE
			to_chat(user, SPAN_NOTICE("Эта точка уже последняя в контуре. Добавьте новую точку или завершите сбор."))
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
			if(!update_placement_collector_runtime_state(user, clicked_turf, "Сбор обновлён. ", FALSE, FALSE, proposed_points))
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
		update_placement_collector_runtime_state(user, clicked_turf, "Сбор обновлён. ", FALSE, FALSE)
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
			if(should_reset_failed_anchor_pair_same_tile_click(start_turf, clicked_turf))
				return reset_safe_placement_attempt(user, "Текущая попытка размещения отменена: конечная точка совпала с опорной.")
		return TRUE

	arm_safe_placement_preview_for_confirm(user)
	return TRUE

/datum/world_edit_manager/proc/start_safe_placement_mode(mob/user)
	if(!holder || !check_rights_for(holder, R_DEBUG))
		return fail_apply(user, "Недостаточно прав для режима размещения в панели редактирования мира.")
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
	teardown_preview_session_runtime(TRUE, TRUE, TRUE)
	sync_click_intercept_state()

	var/shape_label = GLOB.world_edit_placement_shapes.world_edit_get_placement_shape_label(shape_id)
	var/dir_suffix = supports_current_placement_direction() ? " Направление: [GLOB.world_edit_helpers.dir_to_label(get_effective_placement_dir())]." : "."
	if(interaction_kind == "anchor_pair")
		to_chat(user, SPAN_NOTICE("Режим размещения для [shape_label] активен: первый ЛКМ ставит опорную точку, второй ЛКМ строит предпросмотр, повторный ЛКМ по тому же тайлу открывает подтверждение. Если контур из той же опорной точки невалиден, повторный ЛКМ по ней сбрасывает текущую попытку.[dir_suffix]"))
	else if(interaction_kind == "collector")
		to_chat(user, SPAN_NOTICE("Режим размещения для [shape_label] активен: ЛКМ добавляет точки, повторный ЛКМ по последней точке строит финальный предпросмотр, клик по первой точке тоже может замкнуть контур там, где это поддерживается, повторный ЛКМ по тому же тайлу открывает подтверждение. Кнопка завершения тоже работает.[dir_suffix]"))
	else if(interaction_kind == "param_only")
		to_chat(user, SPAN_NOTICE("Режим размещения для [shape_label] активен: ЛКМ использует выбранный тайл как опорную точку и строит контур по текущим параметрам формы, повторный ЛКМ по тому же тайлу открывает подтверждение. Интерактивный сбор точек в этом режиме не используется.[dir_suffix]"))
	else
		to_chat(user, SPAN_NOTICE("Режим размещения для [shape_label] активен: ЛКМ закрепляет предпросмотр по выбранному тайлу, повторный ЛКМ по тому же тайлу открывает подтверждение.[dir_suffix]"))
	return TRUE
