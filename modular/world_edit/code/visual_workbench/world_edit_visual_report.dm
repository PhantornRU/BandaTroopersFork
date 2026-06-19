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
	if(length(workflow_run_id))
		out["workflow_run_id"] = workflow_run_id
	return out

/datum/world_edit_visual_case/proc/write_json_file(path, list/value)
	fdel(path)
	rustg_file_write(json_encode(value), path)
	return fexists(path)

/datum/world_edit_visual_case/proc/write_report(list/report_data)
	report_data["errors"] = errors.Copy()
	report_data["warnings"] = warnings.Copy()
	apply_expectations_to_report(report_data)
	if(!islist(report_data["artifacts"]))
		report_data["artifacts"] = list()
	report_data["artifacts"]["report_json"] = "report.json"
	report_data["artifacts"]["progress_json"] = "progress.json"
	write_json_file("[out_dir]/report.json", report_data)

/datum/world_edit_visual_case/proc/apply_expectations_to_report(list/report_data)
	if(!islist(report_data))
		return
	var/hard_error_count = compute_hard_error_count(report_data)
	report_data["hard_error_count"] = hard_error_count

	var/list/expected = islist(expect_config) ? expect_config.Copy() : list()
	var/list/actual = list()
	var/list/diff = list()
	for(var/key as anything in expected)
		var/actual_value = get_expectation_actual_value(key, report_data)
		actual[key] = actual_value
		if(!visual_expectation_values_equal(expected[key], actual_value))
			diff += list(list(
				"key" = "[key]",
				"expected" = expected[key],
				"actual" = actual_value,
			))

	report_data["expectations"] = list(
		"expected" = expected,
		"actual" = actual,
		"diff" = diff,
	)
	report_data["expectation_diff"] = diff
	report_data["passed"] = (!length(diff) && hard_error_count <= 0) ? TRUE : FALSE

/datum/world_edit_visual_case/proc/compute_hard_error_count(list/report_data)
	var/list/report_errors = islist(report_data?["errors"]) ? report_data["errors"] : list()
	var/status = "[report_data?["status"] || ""]"
	var/expected_status = "[expect_config?["status"] || ""]"
	if(status == WORLD_EDIT_VISUAL_STATUS_LOCKED && expected_status == WORLD_EDIT_VISUAL_STATUS_LOCKED)
		return 0
	return length(report_errors)

/datum/world_edit_visual_case/proc/get_expectation_actual_value(key, list/report_data)
	switch("[key]")
		if("status")
			return report_data?["status"]
		if("reason_code")
			return report_data?["reason_code"] || report_data?["error"] || get_first_report_error_code(report_data)
		if("canvas_changed")
			return report_data?["canvas_changed"] ? TRUE : FALSE
		if("direction_honored")
			var/list/direction = report_data?["direction"]
			return direction?["honored"] ? TRUE : FALSE
		if("undo")
			var/list/undo = report_data?["undo"]
			return undo?["status"]
		if("undo_restored")
			var/list/undo = report_data?["undo"]
			return undo?["restored"] ? TRUE : FALSE
		if("hard_error_count")
			return report_data?["hard_error_count"] || 0
	var/list/metrics = report_data?["metrics"]
	if(islist(metrics) && !isnull(metrics[key]))
		return metrics[key]
	return report_data?[key]

/datum/world_edit_visual_case/proc/get_first_report_error_code(list/report_data)
	var/list/report_errors = islist(report_data?["errors"]) ? report_data["errors"] : null
	if(!islist(report_errors) || !length(report_errors))
		return null
	var/list/first_error = report_errors[1]
	if(islist(first_error))
		return first_error["code"]
	return null

/datum/world_edit_visual_case/proc/visual_expectation_values_equal(expected, actual)
	if(isnull(expected) || isnull(actual))
		return isnull(expected) && isnull(actual)
	if(isnum(expected) || isnum(actual))
		return round(text2num("[expected]") * 1000) == round(text2num("[actual]") * 1000)
	return "[expected]" == "[actual]"

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
		out["metrics"] = merge_metrics(details, null, null)
		attach_building_diagnostics(out, details)
	out["canvas_changed"] = canvas?.has_changed() ? TRUE : FALSE
	mark_semantic_artifacts(out)
	export_semantic_json(out)
	write_report(out)
	return out

/datum/world_edit_visual_case/proc/finish_supported(list/preview, list/apply, list/post_emit, list/export_result, list/undo_result = null)
	profiler.end_total()
	var/list/out = base_report(WORLD_EDIT_VISUAL_STATUS_SUPPORTED, WORLD_EDIT_VISUAL_STAGE_POST_EMIT_VALIDATE)
	out["canvas_changed"] = canvas?.has_changed() ? TRUE : FALSE
	out["metrics"] = merge_metrics(preview, apply, post_emit)
	apply_undo_metrics(out["metrics"], undo_result)
	out["direction"] = build_direction_report(preview)
	out["undo"] = islist(undo_result) ? undo_result.Copy() : list("status" = "not_run", "restored" = FALSE)
	out["rooms"] = preview?["rooms"] || list()
	out["routes"] = preview?["routes"] || list()
	attach_building_diagnostics(out, preview)
	if(islist(post_emit))
		if(islist(post_emit["route_blocking_samples"]))
			out["route_blocking_samples"] = post_emit["route_blocking_samples"].Copy()
		if(islist(post_emit["door_cone_blocking_samples"]))
			out["door_cone_blocking_samples"] = post_emit["door_cone_blocking_samples"].Copy()
	out["artifacts"] = islist(export_result?["artifacts"]) ? export_result["artifacts"] : list()
	mark_semantic_artifacts(out)
	write_report(out)
	return out

/datum/world_edit_visual_case/proc/apply_undo_metrics(list/metrics, list/undo_result)
	if(!islist(metrics) || !islist(undo_result))
		return
	metrics["undo_reverted_count"] = undo_result["reverted_count"] || 0
	metrics["undo_skipped_count"] = undo_result["skipped_count"] || 0
	metrics["undo_restored"] = undo_result["restored"] ? TRUE : FALSE

/datum/world_edit_visual_case/proc/visual_metadata_has_building_metrics(list/meta)
	if(!islist(meta))
		return FALSE
	return !isnull(meta["template_chunk_count"]) || !isnull(meta["footprint_count"]) || islist(meta["template_reject_reason_counts"])

/datum/world_edit_visual_case/proc/select_visual_best_layout_candidate_report(list/candidate_reports)
	if(!islist(candidate_reports) || !length(candidate_reports))
		return null
	var/list/best_report = null
	var/best_score = -999999999
	for(var/list/report as anything in candidate_reports)
		if(!islist(report))
			continue
		var/score = round(text2num("[report["score"]]") || -999999999)
		if(!islist(best_report) || score > best_score)
			best_report = report
			best_score = score
	return best_report

/datum/world_edit_visual_case/proc/get_visual_building_metric_source(list/source)
	var/list/meta = source?["metadata"]
	if(!islist(meta))
		return null
	if(visual_metadata_has_building_metrics(meta))
		return meta
	var/list/selected_report = meta["selected_candidate_report"]
	if(islist(selected_report))
		return selected_report
	var/list/failed_diagnostics = meta["failed_candidate_diagnostics"]
	if(islist(failed_diagnostics))
		return failed_diagnostics
	return select_visual_best_layout_candidate_report(meta["layout_candidate_reports"])

/datum/world_edit_visual_case/proc/attach_building_diagnostics(list/report_data, list/source)
	if(!islist(report_data))
		return
	var/list/meta = get_visual_building_metric_source(source)
	if(!islist(meta))
		return
	var/list/diagnostics = list(
		"template_chunk_count" = meta["template_chunk_count"] || 0,
		"template_chunk_cell_count" = meta["template_chunk_cell_count"] || 0,
		"template_reject_reason_counts" = islist(meta["template_reject_reason_counts"]) ? meta["template_reject_reason_counts"] : list(),
		"template_reject_reports" = islist(meta["template_reject_reports"]) ? meta["template_reject_reports"] : list(),
		"template_reject_report_count" = meta["template_reject_report_count"] || 0,
		"template_cluster_reports" = islist(meta["template_cluster_reports"]) ? meta["template_cluster_reports"] : list(),
		"template_cluster_report_count" = meta["template_cluster_report_count"] || 0,
		"route_blocking_samples" = islist(meta["route_blocking_samples"]) ? meta["route_blocking_samples"] : list(),
		"door_cone_blocking_samples" = islist(meta["door_cone_blocking_samples"]) ? meta["door_cone_blocking_samples"] : list(),
		"placed_requirement_counts" = islist(meta["placed_requirement_counts"]) ? meta["placed_requirement_counts"] : list(),
		"semantic_requirement_counts" = islist(meta["semantic_requirement_counts"]) ? meta["semantic_requirement_counts"] : list(),
		"semantic_requirement_minimums" = islist(meta["semantic_requirement_minimums"]) ? meta["semantic_requirement_minimums"] : list(),
	)
	report_data["building_diagnostics"] = diagnostics
	report_data["template_reject_reports"] = diagnostics["template_reject_reports"]
	report_data["template_cluster_reports"] = diagnostics["template_cluster_reports"]
	report_data["placed_requirement_counts"] = diagnostics["placed_requirement_counts"]
	report_data["semantic_requirement_counts"] = diagnostics["semantic_requirement_counts"]

/datum/world_edit_visual_case/proc/merge_metrics(list/preview, list/apply, list/post_emit)
	var/list/metrics = list()
	var/list/meta = get_visual_building_metric_source(preview)
	if(islist(meta))
		var/list/keys = list(
			"footprint_count",
			"wall_count",
			"floor_count",
			"door_count",
			"interior_object_count",
			"room_count",
			"target_room_count",
			"room_count_divider_count",
			"room_count_satisfied",
			"room_count_gap",
			"reserved_walk_blocked_count",
			"semantic_credit_without_emitted_slots_count",
			"mandatory_pattern_failure_count",
			"post_emit_validation_error_count",
			"counter_wrong_facing_count",
			"direction_fallback_count",
			"forbidden_fallback_count",
			"raw_category_credit_count",
			"scatter_signature_credit_count",
		)
		for(var/key as anything in keys)
			metrics[key] = meta[key] || 0
		metrics["template_chunk_count"] = meta["template_chunk_count"] || 0
		metrics["template_chunk_cell_count"] = meta["template_chunk_cell_count"] || 0
		metrics["template_reject_reason_counts"] = islist(meta["template_reject_reason_counts"]) ? meta["template_reject_reason_counts"] : list()
		metrics["template_reject_report_count"] = meta["template_reject_report_count"] || 0
		metrics["template_cluster_report_count"] = meta["template_cluster_report_count"] || 0
		metrics["placed_requirement_counts"] = islist(meta["placed_requirement_counts"]) ? meta["placed_requirement_counts"] : list()
		metrics["semantic_requirement_counts"] = islist(meta["semantic_requirement_counts"]) ? meta["semantic_requirement_counts"] : list()
		metrics["semantic_requirement_minimums"] = islist(meta["semantic_requirement_minimums"]) ? meta["semantic_requirement_minimums"] : list()
		metrics["generated_turf_count"] = meta["footprint_count"] || 0
		metrics["generated_object_count"] = (meta["door_count"] || 0) + (meta["window_count"] || 0) + (meta["interior_object_count"] || 0)
		metrics["has_interior_objects"] = round(text2num("[meta["interior_object_count"]]") || 0) > 0
		metrics["has_template_chunks"] = round(text2num("[meta["template_chunk_count"]]") || 0) > 0
		metrics["has_room_count_dividers"] = round(text2num("[meta["room_count_divider_count"]]") || 0) > 0
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
