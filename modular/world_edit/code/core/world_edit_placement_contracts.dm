/datum/world_edit_shape_contract
	var/shape_id = WORLD_EDIT_SHAPE_POINT
	var/shape_label = "Точка"
	var/interaction_kind = "single"
	var/is_closed = FALSE
	var/is_filled = FALSE
	var/degenerate_kind = null
	var/preview_kind = "shape"
	var/error = null
	var/list/anchor_turfs = list()
	var/list/metadata = list()
	var/list/raw_result = list()

/datum/world_edit_shape_contract/proc/copy_metadata()
	return islist(metadata) ? metadata.Copy() : list()

/datum/world_edit_shape_contract/proc/copy_anchor_turfs()
	return islist(anchor_turfs) ? anchor_turfs.Copy() : list()

/datum/world_edit_shape_contract/proc/as_shape_result()
	var/list/result = islist(raw_result) ? raw_result.Copy() : list()
	result["shape_id"] = shape_id
	result["shape_label"] = shape_label
	result["interaction_kind"] = interaction_kind
	result["is_closed"] = is_closed ? TRUE : FALSE
	result["is_filled"] = is_filled ? TRUE : FALSE
	result["degenerate_kind"] = degenerate_kind
	result["preview_kind"] = preview_kind
	result["error"] = error
	result["turfs"] = copy_anchor_turfs()
	result["metadata"] = copy_metadata()
	return result

/datum/world_edit_preview_model
	var/list/anchor_turfs = list()
	var/list/vertex_turfs = list()
	var/list/edge_turfs = list()
	var/list/closure_turfs = list()
	var/list/final_turfs = list()
	var/list/guide_turfs = list()
	var/list/generator_effect_turfs = list()
	var/list/generator_preview_object_specs = list()
	var/preview_render_token = null
	var/hover_preview_mode = null

/datum/world_edit_preview_model/proc/as_preview_layers()
	return list(
		"anchor_turfs" = islist(anchor_turfs) ? anchor_turfs.Copy() : list(),
		"vertex_turfs" = islist(vertex_turfs) ? vertex_turfs.Copy() : list(),
		"edge_turfs" = islist(edge_turfs) ? edge_turfs.Copy() : list(),
		"closure_turfs" = islist(closure_turfs) ? closure_turfs.Copy() : list(),
		"final_turfs" = islist(final_turfs) ? final_turfs.Copy() : list(),
		"guide_turfs" = islist(guide_turfs) ? guide_turfs.Copy() : list(),
		"generator_effect_turfs" = islist(generator_effect_turfs) ? generator_effect_turfs.Copy() : list(),
		"generator_preview_object_specs" = islist(generator_preview_object_specs) ? generator_preview_object_specs.Copy() : list(),
		"preview_render_token" = preview_render_token,
		"hover_preview_mode" = hover_preview_mode,
	)

/datum/world_edit_placement_candidate
	var/datum/world_edit_shape_contract/shape_contract
	var/datum/world_edit_preview_model/preview_model
	var/datum/world_edit_plan/plan
	var/support_error = null
	var/resolve_error = null
	var/hover_only = FALSE
	var/list/collector_state_summary = list()
	var/list/runtime_params = list()
	var/list/placement_context = list()
	var/preview_render_token = null

/datum/world_edit_placement_candidate/proc/is_preview_ready()
	if(length("[resolve_error]"))
		return FALSE
	if(length("[support_error]"))
		return FALSE
	if(!istype(plan))
		return FALSE
	if(plan.metadata["error"])
		return FALSE
	return (length(plan.placements) || length(plan.deletions)) ? TRUE : FALSE

/datum/world_edit_placement_candidate/proc/is_preview_plan_deferred()
	var/list/metadata = plan?.metadata || shape_contract?.metadata
	return GLOB.world_edit_helpers.parse_bool(metadata["preview_plan_deferred"])

/datum/world_edit_placement_candidate/proc/is_deferred_preview_ready()
	if(hover_only)
		return FALSE
	if(istype(plan))
		return FALSE
	if(length("[resolve_error]"))
		return FALSE
	if(length("[support_error]"))
		return FALSE
	return is_preview_plan_deferred()

/datum/world_edit_placement_candidate/proc/is_confirm_ready()
	if(is_preview_ready())
		return TRUE
	return is_deferred_preview_ready()

/datum/world_edit_placement_candidate/proc/is_ready_for_apply()
	if(hover_only)
		return FALSE
	return is_preview_ready()

/datum/world_edit_placement_candidate/proc/get_failure_message()
	if(length("[resolve_error]"))
		return "[resolve_error]"
	if(length("[support_error]"))
		return "[support_error]"
	if(plan?.metadata["error"])
		return "[plan.metadata["error"]]"
	return null

/datum/world_edit_placement_session
	var/turf/anchor_turf
	var/turf/hover_turf
	var/turf/collector_origin_turf
	var/list/collector_points = list()
	var/collector_points_text = ""
	var/collector_points_revision = 0
	var/preview_context_revision = 0
	var/datum/world_edit_placement_candidate/preview_candidate
	var/datum/world_edit_placement_candidate/last_resolved_candidate
	var/last_resolved_candidate_params_signature = null
	var/last_resolved_candidate_attempt_signature = null
	var/turf/last_resolved_candidate_end_turf
	var/last_resolved_candidate_hover_only = FALSE
	var/hover_object_preview_next_allowed_ds = 0
	var/turf/confirm_arm_turf
	var/confirm_arm_signature = null
	var/preview_locked = FALSE

/datum/world_edit_generator/proc/build_shape_contract_from_placement_context(shape_id, list/anchor_turfs, list/placement_context)
	if(islist(placement_context))
		var/datum/world_edit_shape_contract/existing_contract = placement_context["shape_contract"]
		if(istype(existing_contract))
			return existing_contract

	var/datum/world_edit_shape_contract/shape_contract = new
	shape_contract.shape_id = "[shape_id || placement_context["shape"] || WORLD_EDIT_SHAPE_POINT]"
	shape_contract.shape_label = GLOB.world_edit_shape_catalog.get_placement_shape_label(shape_contract.shape_id)
	shape_contract.interaction_kind = GLOB.world_edit_shape_catalog.get_shape_interaction_kind(shape_contract.shape_id)
	shape_contract.preview_kind = GLOB.world_edit_shape_catalog.get_shape_preview_kind(shape_contract.shape_id)
	shape_contract.anchor_turfs = GLOB.world_edit_placement_shapes.world_edit_unique_turf_list(anchor_turfs)
	var/list/source_shape_metadata = islist(placement_context) ? placement_context["shape_metadata"] : null
	var/list/shape_metadata = islist(source_shape_metadata) ? source_shape_metadata.Copy() : list()
	shape_contract.metadata = shape_metadata
	shape_contract.is_closed = GLOB.world_edit_helpers.parse_bool(shape_metadata["is_closed"])
	shape_contract.is_filled = GLOB.world_edit_helpers.parse_bool(shape_metadata["is_filled"])
	shape_contract.degenerate_kind = shape_metadata["degenerate_kind"]
	return shape_contract

/datum/world_edit_generator/proc/evaluate_shape_contract(datum/world_edit_shape_contract/shape_contract, list/params, list/placement_context)
	if(!istype(shape_contract))
		return list(
			"support_class" = "unsupported",
			"error" = "Не удалось определить контракт формы размещения.",
			"metadata" = list(),
		)

	return list(
		"support_class" = "full",
		"error" = get_shape_support_error(shape_contract.shape_id, shape_contract.copy_anchor_turfs(), params, placement_context),
		"metadata" = list(),
	)

/datum/world_edit_generator/proc/build_plan_from_shape_contract(mob/user, datum/world_edit_shape_contract/shape_contract, list/params, list/placement_context)
	var/datum/world_edit_plan/plan = build_placement_plan(user, params, placement_context)
	finalize_shared_placement_plan_metadata(plan, shape_contract, placement_context)
	return plan

/datum/world_edit_generator/proc/apply_built_plan(mob/user, list/params, datum/world_edit_plan/plan)
	return apply_plan(user, params, plan)

/datum/world_edit_generator/proc/apply_plan(mob/user, list/params, datum/world_edit_plan/plan)
	var/datum/world_edit_apply_result/result = new
	if(!istype(plan))
		result.message = "Готовый план размещения недоступен."
		return result

	result.message = "Генераторы размещения должны переопределять apply_plan() для безопасного размещения."
	return result
