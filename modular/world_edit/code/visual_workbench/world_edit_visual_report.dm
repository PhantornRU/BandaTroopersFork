/*
 * Report construction for all terminal case states.
 *
 * Reports are the primary machine-readable contract of the workbench. A locked
 * shape, generator validation failure, missing post-emit validation report, and
 * successful apply all flow through the same schema so CI/review tools can
 * compare cases without scraping logs.
 */
/datum/world_edit_visual_case/proc/add_error(code, message, stage, turf/T = null, list/details = null)
	var/list/error = list(
		"code" = "[code]",
		"message" = "[message]",
		"severity" = "error",
		"stage" = "[stage]",
	)
	if(istype(T))
		error["x"] = T.x
		error["y"] = T.y
		error["z"] = T.z
	if(islist(details))
		error["details"] = details
	errors += list(error)
	return error

/datum/world_edit_visual_case/proc/add_warning(message)
	warnings += "[message]"

/datum/world_edit_visual_case/proc/base_report(status, stage)
	var/list/out = list(
		"schema" = "world_edit_visual_report/v1",
		"case_id" = id,
		"generator" = generator_id,
		"status" = status,
		"stage" = stage,
		"seed" = seed,
		"program" = generator_config?["archetype_id"] || generator_config?["program"],
		"shape" = shape_config?["id"],
		"style" = generator_config?["faction_preset"],
		"errors" = errors.Copy(),
		"warnings" = warnings.Copy(),
		"metrics" = list(),
		"artifacts" = list(),
	)
	var/list/profile = profiler?.to_json_list()
	if(islist(profile))
		out["profile"] = profile
	return out

/datum/world_edit_visual_case/proc/write_json_file(path, list/value)
	fdel(path)
	rustg_file_write(json_encode(value), path)
	return fexists(path)

/datum/world_edit_visual_case/proc/write_report(list/report_data)
	report_data["errors"] = errors.Copy()
	report_data["warnings"] = warnings.Copy()
	if(!islist(report_data["artifacts"]))
		report_data["artifacts"] = list()
	report_data["artifacts"]["report_json"] = "report.json"
	report_data["artifacts"]["progress_json"] = "progress.json"
	write_json_file("[out_dir]/report.json", report_data)

/datum/world_edit_visual_case/proc/mark_semantic_artifacts(list/report_data)
	if(!istype(canvas))
		return
	if(!islist(report_data["artifacts"]))
		report_data["artifacts"] = list()
	report_data["artifacts"]["semantic_json"] = "semantic.json"
	report_data["artifacts"]["semantic_png"] = "semantic.png"

/datum/world_edit_visual_case/proc/finish_locked(list/support)
	profiler.end_total()
	// Locked is a successful workbench outcome, not a crash. It means the real
	// generator refused the request before preview/apply, so canvas_changed must
	// remain false and the reason must stay visible in both report and PNG.
	add_error(support["reason_code"] || support["lock_code"] || "shape.locked", support["reason"] || "Shape is locked for this generator.", WORLD_EDIT_VISUAL_STAGE_SUPPORT_CHECK)
	var/list/out = base_report(WORLD_EDIT_VISUAL_STATUS_LOCKED, WORLD_EDIT_VISUAL_STAGE_SUPPORT_CHECK)
	out["locked"] = TRUE
	out["reason_code"] = support["reason_code"] || support["lock_code"]
	out["reason"] = support["reason"]
	out["canvas_changed"] = FALSE
	out["metrics"] = list("generated_turf_count" = 0, "generated_object_count" = 0, "post_emit_validation_error_count" = 0)
	mark_semantic_artifacts(out)
	export_semantic_json(out)
	write_report(out)
	return out

/datum/world_edit_visual_case/proc/finish_error(stage, error, list/details = null)
	profiler.end_total()
	// Generator failures are preserved as errors with their original stage. The
	// visualizer must not reinterpret them into supported output.
	add_error(error, error, stage, null, details)
	var/list/out = base_report(WORLD_EDIT_VISUAL_STATUS_ERROR, stage)
	out["error"] = error
	if(islist(details))
		out["details"] = details
	out["canvas_changed"] = canvas?.has_changed() ? TRUE : FALSE
	mark_semantic_artifacts(out)
	export_semantic_json(out)
	write_report(out)
	return out

/datum/world_edit_visual_case/proc/finish_supported(list/preview, list/apply, list/post_emit, list/export_result)
	profiler.end_total()
	var/list/out = base_report(WORLD_EDIT_VISUAL_STATUS_SUPPORTED, WORLD_EDIT_VISUAL_STAGE_POST_EMIT_VALIDATE)
	out["canvas_changed"] = canvas?.has_changed() ? TRUE : FALSE
	out["metrics"] = merge_metrics(preview, apply, post_emit)
	out["direction"] = build_direction_report(preview)
	out["rooms"] = preview?["rooms"] || list()
	out["routes"] = preview?["routes"] || list()
	out["artifacts"] = islist(export_result?["artifacts"]) ? export_result["artifacts"] : list()
	mark_semantic_artifacts(out)
	export_semantic_json(out)
	write_report(out)
	return out

/datum/world_edit_visual_case/proc/merge_metrics(list/preview, list/apply, list/post_emit)
	var/list/metrics = list()
	var/list/meta = preview?["metadata"]
	if(islist(meta))
		var/list/keys = list(
			"footprint_count",
			"wall_count",
			"floor_count",
			"door_count",
			"interior_object_count",
			"reserved_walk_blocked_count",
			"semantic_credit_without_emitted_slots_count",
			"mandatory_pattern_failure_count",
			"post_emit_validation_error_count",
			"forbidden_fallback_count",
			"raw_category_credit_count",
			"scatter_signature_credit_count",
		)
		for(var/key as anything in keys)
			metrics[key] = meta[key] || 0
		metrics["generated_turf_count"] = meta["footprint_count"] || 0
		metrics["generated_object_count"] = (meta["door_count"] || 0) + (meta["window_count"] || 0) + (meta["interior_object_count"] || 0)
	if(islist(apply))
		metrics["changed_turf_count"] = apply["changed_turf_count"] || 0
		metrics["created_object_count"] = apply["created_object_count"] || 0
	if(islist(post_emit))
		for(var/key as anything in post_emit)
			if(findtext("[key]", "_count"))
				metrics[key] = post_emit[key]
	return metrics

/datum/world_edit_visual_case/proc/build_direction_report(list/preview)
	var/list/meta = preview?["metadata"]
	return list(
		"requested" = meta?["requested_direction_label"],
		"actual_entry_direction" = meta?["actual_entry_direction_label"],
		"honored" = meta?["direction_honored"] ? TRUE : FALSE,
		"fallback_reason" = meta?["direction_fallback_reason"],
	)
