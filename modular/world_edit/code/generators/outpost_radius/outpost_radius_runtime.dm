/datum/world_edit_generator/outpost_radius/proc/is_open_construction_turf(turf/target_turf)
	if(!istype(target_turf, /turf/open))
		return FALSE

	var/turf/open/open_turf = target_turf
	if(!open_turf.allow_construction)
		return FALSE

	return TRUE

/datum/world_edit_generator/outpost_radius/proc/has_dense_blocker(turf/target_turf, ignore_barricades = FALSE)
	return GLOB.world_edit_helpers.has_dense_nonmob_blocker(target_turf, ignore_barricades)

/datum/world_edit_generator/outpost_radius/proc/outpost_path_passable(turf/target_turf, treat_windows_as_blockers = TRUE)
	if(!is_open_construction_turf(target_turf))
		return FALSE

	for(var/atom/blocker as anything in target_turf)
		if(ismob(blocker))
			continue
		if(istype(blocker, /obj/structure/window))
			if(treat_windows_as_blockers)
				return FALSE
			continue
		if(!blocker.density)
			continue
		return FALSE

	return TRUE

/datum/world_edit_generator/outpost_radius/proc/outpost_footprint_tile_allowed(turf/target_turf, list/radius_policy = null)
	return istype(target_turf)

/datum/world_edit_generator/outpost_radius/proc/get_outpost_placement_target_label(shape_id)
	return "[shape_id]" == WORLD_EDIT_SHAPE_POINT ? "точка размещения" : "контур размещения"

/datum/world_edit_generator/outpost_radius/proc/can_place_barricade_on_turf(turf/target_turf, dir_to_use)
	if(!is_open_construction_turf(target_turf))
		return FALSE
	if(!GLOB.world_edit_helpers.is_cardinal_dir(dir_to_use))
		return FALSE
	if(has_dense_blocker(target_turf, TRUE))
		return FALSE
	if(GLOB.world_edit_helpers.has_barricade_in_dir(target_turf, dir_to_use))
		return FALSE
	return TRUE

/datum/world_edit_generator/outpost_radius/proc/can_place_sentry_on_turf(turf/target_turf)
	if(!is_open_construction_turf(target_turf))
		return FALSE
	if(has_dense_blocker(target_turf))
		return FALSE
	for(var/obj/structure/machinery/defenses/existing_defense in target_turf)
		return FALSE
	return TRUE

/datum/world_edit_generator/outpost_radius/proc/spawn_defense_path(turf/target_turf, dir_to_spawn, defense_path, faction = null, turned_on = FALSE)
	if(!target_turf)
		return null
	if(!ispath(defense_path, /datum/human_ai_defense))
		return null

	var/datum/human_ai_defense/defense_definition = new defense_path()
	var/obj_path = defense_definition.path_to_spawn || GLOB.world_edit_blueprints.world_edit_resolve_defense_spawn_path(defense_path)
	var/list/existing_lookup = list()
	if(ispath(obj_path, /obj))
		for(var/obj/existing as anything in target_turf)
			if(istype(existing, obj_path))
				existing_lookup[existing] = TRUE

	defense_definition.spawn_object(target_turf, dir_to_spawn, faction, turned_on)

	var/obj/created_object
	if(ispath(obj_path, /obj))
		for(var/obj/candidate as anything in target_turf)
			if(!istype(candidate, obj_path) || existing_lookup[candidate])
				continue
			created_object = candidate
			break

	qdel(defense_definition)
	return created_object

/datum/world_edit_generator/outpost_radius/proc/register_perimeter_slot(list/result, turf/target_turf, dir_to_use, slot_index, offset_x, offset_y, radius, list/layout_profile, list/barricade_cycle, barricade_pattern)
	if(!islist(result))
		return

	var/list/placements = result["placements"]
	var/list/openings = result["openings"]
	if(is_perimeter_opening_slot(dir_to_use, offset_x, offset_y, layout_profile))
		result["planned_opening_count"]++
		if(can_place_barricade_on_turf(target_turf, dir_to_use))
			result["opening_count"]++
			openings += list(list(
				"turf" = target_turf,
				"dir" = dir_to_use,
				"slot_index" = slot_index,
			))
		else
			result["blocked_count"]++
			result["blocked_openings"]++
		return

	if(can_place_barricade_on_turf(target_turf, dir_to_use))
		placements += list(list(
			"turf" = target_turf,
			"dir" = dir_to_use,
			"barricade_path" = select_barricade_path_for_slot(barricade_cycle, slot_index, radius, barricade_pattern),
			"slot_index" = slot_index,
		))
		return

	result["blocked_count"]++
	result["blocked_barricades"]++

/datum/world_edit_generator/outpost_radius/proc/collect_perimeter_placements(turf/center_turf, radius, list/layout_profile, list/barricade_cycle, barricade_pattern, list/radius_policy = null, list/traversal_turfs = null)
	var/list/result = list(
		"placements" = list(),
		"blocked_count" = 0,
		"blocked_barricades" = 0,
		"blocked_openings" = 0,
		"opening_count" = 0,
		"planned_opening_count" = 0,
		"openings" = list(),
		"preview_turfs" = list(),
		"preview_lookup" = list(),
		"policy_filtered_count" = 0,
	)
	if(!center_turf)
		return result
	var/slot_index = 0
	var/list/raw_slots = list()

	for(var/offset_x in -radius to radius)
		slot_index++
		var/turf/top_turf = locate(center_turf.x + offset_x, center_turf.y + radius, center_turf.z)
		raw_slots += list(list(
			"turf" = top_turf,
			"dir" = NORTH,
			"slot_index" = slot_index,
			"offset_x" = offset_x,
			"offset_y" = radius,
		))

		slot_index++
		var/turf/bottom_turf = locate(center_turf.x + offset_x, center_turf.y - radius, center_turf.z)
		raw_slots += list(list(
			"turf" = bottom_turf,
			"dir" = SOUTH,
			"slot_index" = slot_index,
			"offset_x" = offset_x,
			"offset_y" = -radius,
		))

	for(var/offset_y in -radius to radius)
		slot_index++
		var/turf/right_turf = locate(center_turf.x + radius, center_turf.y + offset_y, center_turf.z)
		raw_slots += list(list(
			"turf" = right_turf,
			"dir" = EAST,
			"slot_index" = slot_index,
			"offset_x" = radius,
			"offset_y" = offset_y,
		))

		slot_index++
		var/turf/left_turf = locate(center_turf.x - radius, center_turf.y + offset_y, center_turf.z)
		raw_slots += list(list(
			"turf" = left_turf,
			"dir" = WEST,
			"slot_index" = slot_index,
			"offset_x" = -radius,
			"offset_y" = offset_y,
		))

	var/list/effective_traversal_turfs = islist(traversal_turfs) ? traversal_turfs : build_point_radius_area_turfs(center_turf, radius)
	var/list/filtered_slots = filter_outpost_slots_by_radius_policy(list(center_turf), raw_slots, effective_traversal_turfs, radius_policy)
	result["policy_filtered_count"] = max(length(raw_slots) - length(filtered_slots), 0)
	for(var/list/candidate_slot as anything in filtered_slots)
		var/turf/preview_turf = candidate_slot["turf"]
		if(istype(preview_turf) && !result["preview_lookup"][preview_turf])
			result["preview_lookup"][preview_turf] = TRUE
			result["preview_turfs"] += preview_turf
		register_perimeter_slot(
			result,
			candidate_slot["turf"],
			candidate_slot["dir"],
			candidate_slot["slot_index"],
			candidate_slot["offset_x"],
			candidate_slot["offset_y"],
			radius,
			layout_profile,
			barricade_cycle,
			barricade_pattern,
		)

	return result

/datum/world_edit_generator/outpost_radius/proc/collect_sentry_placements(turf/center_turf, radius, list/layout_profile, list/radius_policy = null, list/traversal_turfs = null)
	var/list/result = list(
		"placements" = list(),
		"blocked_count" = 0,
		"preview_turfs" = list(),
		"preview_lookup" = list(),
		"policy_filtered_count" = 0,
	)
	if(!center_turf)
		return result
	var/list/placements = result["placements"]
	var/inner_radius = max(radius - 1, 1)
	var/list/guard_dirs = get_layout_guard_dirs(layout_profile)
	var/list/effective_traversal_turfs = islist(traversal_turfs) ? traversal_turfs : build_point_radius_area_turfs(center_turf, radius)
	var/list/raw_candidate_turfs = list()
	var/list/raw_candidate_lookup = list()
	var/list/guard_candidates = list()

	for(var/dir_to_guard as anything in guard_dirs)
		var/list/candidates = list()
		for(var/list/candidate as anything in build_sentry_guard_candidates(dir_to_guard, inner_radius))
			var/turf/target_turf = locate(center_turf.x + candidate["dx"], center_turf.y + candidate["dy"], center_turf.z)
			var/list/candidate_entry = list(
				"turf" = target_turf,
				"dir" = candidate["dir"],
				"opening_dir" = dir_to_guard,
			)
			candidates += list(candidate_entry)
			if(istype(target_turf) && !raw_candidate_lookup[target_turf])
				raw_candidate_lookup[target_turf] = TRUE
				raw_candidate_turfs += target_turf
		guard_candidates += list(candidates)

	var/list/allowed_sentry_lookup = list()
	for(var/turf/allowed_turf as anything in filter_outpost_candidate_turfs(list(center_turf), raw_candidate_turfs, effective_traversal_turfs, radius_policy, list(center_turf)))
		if(raw_candidate_lookup[allowed_turf])
			allowed_sentry_lookup[allowed_turf] = TRUE
	result["policy_filtered_count"] = max(length(raw_candidate_turfs) - length(allowed_sentry_lookup), 0)

	var/guard_index = 1
	for(var/dir_to_guard as anything in guard_dirs)
		var/list/candidates = guard_candidates[guard_index++]
		var/placed = FALSE
		var/turf/preview_turf = null
		for(var/list/candidate as anything in candidates)
			var/turf/target_turf = candidate["turf"]
			if(!istype(target_turf) || !allowed_sentry_lookup[target_turf])
				continue
			if(!istype(preview_turf))
				preview_turf = target_turf
			if(!can_place_sentry_on_turf(target_turf))
				continue

			placements += list(list(
				"turf" = target_turf,
				"dir" = candidate["dir"],
				"opening_dir" = dir_to_guard,
			))
			placed = TRUE
			break

		if(istype(preview_turf) && !result["preview_lookup"][preview_turf])
			result["preview_lookup"][preview_turf] = TRUE
			result["preview_turfs"] += preview_turf
		if(!placed)
			result["blocked_count"]++

	return result

/datum/world_edit_generator/outpost_radius/proc/build_outpost_plan(turf/center_turf, list/params)
	var/datum/world_edit_plan/plan = new
	if(!center_turf)
		return plan

	var/list/config = params
	if(!islist(config) || !config["family_profile"])
		config = resolve_outpost_configuration(params)
	if(config["error"])
		plan.metadata["error"] = "[config["error"]]"
		return plan

	var/radius = config["radius"]
	var/list/family_profile = config["family_profile"]
	var/list/layout_profile = config["layout_profile"]
	var/place_sentries = config["place_sentries"]
	var/list/barricade_cycle = config["barricade_cycle"]
	var/faction = config["faction"]
	var/turned_on = config["turned_on"]
	var/barricade_path = config["barricade_path"]
	var/sentry_path = config["sentry_path"]
	var/list/radius_policy = islist(config["radius_policy"]) ? config["radius_policy"] : GLOB.world_edit_helpers.get_world_edit_radius_policy(config)
	var/list/traversal_turfs = build_point_radius_area_turfs(center_turf, radius)

	var/list/perimeter_data = collect_perimeter_placements(center_turf, radius, layout_profile, barricade_cycle, config["barricade_pattern"], radius_policy, traversal_turfs)
	var/list/sentry_data = place_sentries ? collect_sentry_placements(center_turf, radius, layout_profile, radius_policy, traversal_turfs) : list(
		"placements" = list(),
		"blocked_count" = 0,
		"policy_filtered_count" = 0,
	)

	var/list/preview_turf_lookup = list()
	for(var/turf/preview_turf as anything in perimeter_data["preview_turfs"])
		if(istype(preview_turf))
			preview_turf_lookup[preview_turf] = TRUE
	for(var/turf/preview_turf as anything in sentry_data["preview_turfs"])
		if(istype(preview_turf))
			preview_turf_lookup[preview_turf] = TRUE
	for(var/list/placement as anything in perimeter_data["placements"])
		var/turf/target_turf = placement["turf"]
		if(!target_turf)
			continue
		preview_turf_lookup[target_turf] = TRUE
		plan.placements += list(list(
			"kind" = "barricade",
			"turf" = target_turf,
			"dir" = placement["dir"],
			"defense_path" = placement["barricade_path"] || barricade_path,
		))
	for(var/list/placement as anything in sentry_data["placements"])
		var/turf/target_turf = placement["turf"]
		if(!target_turf)
			continue
		preview_turf_lookup[target_turf] = TRUE
		plan.placements += list(list(
			"kind" = "sentry",
			"turf" = target_turf,
			"dir" = placement["dir"],
			"defense_path" = sentry_path,
			"faction" = faction,
			"turned_on" = turned_on,
		))

	for(var/turf/preview_turf as anything in preview_turf_lookup)
		plan.affected_turfs += preview_turf

	var/expected_openings = get_layout_expected_opening_count(layout_profile)
	var/list/opening_dirs = get_layout_opening_dirs(layout_profile)
	var/required_openings = expected_openings
	// Opening geometry is validated upstream; blocked opening tiles should not invalidate point placement.
	expected_openings = 0
	if(length(opening_dirs) && (perimeter_data["opening_count"] || 0) < expected_openings)
		plan.metadata["error"] = "Выбранная точка размещения не поддерживает обязательные проходы форпоста при текущей политике блокировок радиуса."
		return plan
	if(!length(plan.placements))
		plan.metadata["error"] = "Не удалось построить ни одного допустимого размещения форпоста для выбранной точки размещения при текущей политике блокировок радиуса."
		return plan

	plan.metadata["center_turf"] = center_turf
	plan.metadata["radius"] = radius
	plan.metadata["radius_only_clear_tiles"] = radius_policy["only_clear_tiles"]
	plan.metadata["radius_only_reachable_tiles"] = radius_policy["only_reachable_tiles"]
	plan.metadata["radius_windows_blockers"] = radius_policy["treat_windows_as_blockers"]
	plan.metadata["family"] = config["family"]
	plan.metadata["family_label"] = family_profile["label"]
	plan.metadata["family_description"] = family_profile["description"]
	plan.metadata["layout_variant"] = config["layout_variant"]
	plan.metadata["layout_label"] = layout_profile["label"]
	plan.metadata["layout_description"] = layout_profile["description"]
	plan.metadata["opening_width"] = config["opening_width"]
	plan.metadata["guard_mode"] = config["guard_mode"]
	plan.metadata["barricade_pattern"] = config["barricade_pattern"]
	plan.metadata["barricade_count"] = length(perimeter_data["placements"])
	plan.metadata["sentry_count"] = length(sentry_data["placements"])
	plan.metadata["opening_count"] = perimeter_data["opening_count"]
	plan.metadata["opening_dirs"] = format_opening_dirs(get_layout_opening_dirs(layout_profile))
	plan.metadata["blocked_barricades"] = perimeter_data["blocked_barricades"]
	plan.metadata["blocked_openings"] = max(required_openings - min(perimeter_data["planned_opening_count"] || 0, required_openings), 0) + (perimeter_data["blocked_openings"] || 0)
	plan.metadata["blocked_perimeter"] = perimeter_data["blocked_count"]
	plan.metadata["blocked_sentries"] = sentry_data["blocked_count"]
	plan.metadata["policy_filtered_perimeter"] = perimeter_data["policy_filtered_count"] || 0
	plan.metadata["policy_filtered_sentries"] = sentry_data["policy_filtered_count"] || 0
	return plan

/datum/world_edit_generator/outpost_radius/build_plan_from_shape_contract(mob/user, datum/world_edit_shape_contract/shape_contract, list/params, list/placement_context)
	var/datum/world_edit_plan/plan = new
	var/list/anchor_turfs = shape_contract?.copy_anchor_turfs() || placement_context["anchor_turfs"]
	if(!islist(anchor_turfs) || !length(anchor_turfs))
		plan.metadata["error"] = "Не удалось определить опорный тайл."
		return plan

	var/list/config = resolve_outpost_configuration(params)
	if(config["error"])
		plan.metadata["error"] = "[config["error"]]"
		return plan

	var/shape_id = "[shape_contract?.shape_id || placement_context["shape"] || manager?.get_effective_placement_shape() || WORLD_EDIT_SHAPE_POINT]"
	var/effective_shape_id = get_outpost_effective_shape_id(shape_id, shape_contract, placement_context, anchor_turfs)
	plan.metadata["shape_effective_id"] = effective_shape_id
	plan.metadata["family"] = config["family"]
	plan.metadata["family_label"] = config["family_profile"]["label"]
	plan.metadata["family_description"] = config["family_profile"]["description"]
	plan.metadata["layout_variant"] = config["layout_variant"]
	plan.metadata["layout_label"] = config["layout_profile"]["label"]
	plan.metadata["layout_description"] = config["layout_profile"]["description"]
	plan.metadata["opening_width"] = config["opening_width"]
	plan.metadata["guard_mode"] = config["guard_mode"]
	plan.metadata["barricade_pattern"] = config["barricade_pattern"]
	plan.metadata["opening_dirs"] = format_opening_dirs(get_layout_opening_dirs(config["layout_profile"]))

	if(effective_shape_id != WORLD_EDIT_SHAPE_POINT)
		var/datum/world_edit_plan/shape_plan = build_shape_aware_perimeter_plan(anchor_turfs, config, placement_context)
		if(shape_plan.metadata["error"])
			plan.metadata["error"] = "[shape_plan.metadata["error"]]"
			return plan

		plan.placements = shape_plan.placements.Copy()
		plan.affected_turfs = shape_plan.affected_turfs.Copy()
		for(var/key in shape_plan.metadata)
			plan.metadata[key] = shape_plan.metadata[key]
		finalize_shared_placement_plan_metadata(plan, shape_contract, placement_context)
		return plan

	var/list/occupied_lookup = list()
	var/list/preview_lookup = list()
	var/total_barricades = 0
	var/total_sentries = 0
	var/total_blocked_barricades = 0
	var/total_openings = 0
	var/total_blocked_openings = 0
	var/total_blocked_sentries = 0
	for(var/turf/anchor_turf as anything in anchor_turfs)
		if(!istype(anchor_turf))
			continue
		var/datum/world_edit_plan/anchor_plan = build_outpost_plan(anchor_turf, config)
		if(anchor_plan.metadata["error"])
			plan.metadata["error"] = "[anchor_plan.metadata["error"]]"
			return plan
		for(var/list/placement as anything in anchor_plan.placements)
			var/turf/target_turf = placement["turf"]
			if(!istype(target_turf))
				continue
			var/placement_key
			if(placement["kind"] == "barricade")
				placement_key = GLOB.world_edit_helpers.build_turf_dir_slot_key(target_turf, placement["dir"])
			else
				placement_key = "[target_turf.x],[target_turf.y],[target_turf.z]:[placement["kind"]]"
			if(!length(placement_key))
				continue
			if(occupied_lookup[placement_key])
				plan.metadata["error"] = "Запрошенный контур форпоста пересекается сам с собой."
				plan.metadata["blocked_turf"] = "[target_turf.x],[target_turf.y],[target_turf.z]"
				return plan
			occupied_lookup[placement_key] = TRUE
			preview_lookup[target_turf] = TRUE
			plan.placements += list(placement.Copy())
		if(length(plan.placements) > WORLD_EDIT_PLACEMENT_MAX_TOTAL_PLACEMENTS)
			plan.metadata["error"] = "Запрошенное размещение форпоста превышает безопасный лимит ([WORLD_EDIT_PLACEMENT_MAX_TOTAL_PLACEMENTS])."
			return plan

		total_barricades += anchor_plan.metadata["barricade_count"] || 0
		total_sentries += anchor_plan.metadata["sentry_count"] || 0
		total_blocked_barricades += anchor_plan.metadata["blocked_barricades"] || 0
		total_openings += anchor_plan.metadata["opening_count"] || 0
		total_blocked_openings += anchor_plan.metadata["blocked_openings"] || 0
		total_blocked_sentries += anchor_plan.metadata["blocked_sentries"] || 0

	for(var/turf/preview_turf as anything in preview_lookup)
		plan.affected_turfs += preview_turf

	var/turf/center_turf = placement_context["end_turf"]
	if(!istype(center_turf))
		center_turf = anchor_turfs[clamp(round((length(anchor_turfs) + 1) / 2), 1, length(anchor_turfs))]

	plan.metadata["center_turf"] = center_turf
	plan.metadata["radius"] = config["radius"]
	plan.metadata["barricade_count"] = total_barricades
	plan.metadata["sentry_count"] = total_sentries
	plan.metadata["blocked_barricades"] = total_blocked_barricades
	plan.metadata["blocked_sentries"] = total_blocked_sentries
	plan.metadata["family"] = config["family"]
	plan.metadata["family_label"] = config["family_profile"]["label"]
	plan.metadata["family_description"] = config["family_profile"]["description"]
	plan.metadata["layout_variant"] = config["layout_variant"]
	plan.metadata["layout_label"] = config["layout_profile"]["label"]
	plan.metadata["layout_description"] = config["layout_profile"]["description"]
	plan.metadata["opening_width"] = config["opening_width"]
	plan.metadata["guard_mode"] = config["guard_mode"]
	plan.metadata["barricade_pattern"] = config["barricade_pattern"]
	plan.metadata["opening_count"] = total_openings
	plan.metadata["blocked_openings"] = total_blocked_openings
	finalize_shared_placement_plan_metadata(plan, shape_contract, placement_context)
	return plan

/datum/world_edit_generator/outpost_radius/build_placement_plan(mob/user, list/params, list/placement_context)
	var/datum/world_edit_shape_contract/shape_contract = build_shape_contract_from_placement_context(placement_context["shape"], placement_context["anchor_turfs"], placement_context)
	return build_plan_from_shape_contract(user, shape_contract, params, placement_context)

/datum/world_edit_generator/outpost_radius/build_plan(list/params)
	var/turf/anchor_turf = get_turf(manager?.holder?.mob)
	var/list/shape_result = GLOB.world_edit_placement_shapes.world_edit_build_shape_turfs(manager?.get_effective_placement_shape() || WORLD_EDIT_SHAPE_POINT, anchor_turf, null, params, manager?.get_effective_placement_dir() || NORTH)
	if(shape_result["error"])
		var/datum/world_edit_plan/error_plan = new
		error_plan.metadata["error"] = "[shape_result["error"]]"
		return error_plan
	return build_placement_plan(manager?.holder?.mob, params, list(
		"mode" = manager?.get_effective_placement_mode() || "single",
		"shape" = manager?.get_effective_placement_shape() || WORLD_EDIT_SHAPE_POINT,
		"shape_metadata" = shape_result["metadata"] || list(),
		"anchor_turfs" = shape_result["turfs"] || list(anchor_turf),
		"end_turf" = anchor_turf,
	))

/datum/world_edit_generator/outpost_radius/validate_params(mob/user, list/params)
	var/list/config = resolve_outpost_configuration(params)
	if(config["error"])
		return "[config["error"]]"

	var/radius = config["radius"]
	if(!isnum(radius) || radius < 1 || radius > WORLD_EDIT_OUTPOST_RADIUS_MAX)
		return "Радиус должен быть в диапазоне 1..[WORLD_EDIT_OUTPOST_RADIUS_MAX]."

	var/place_sentries = config["place_sentries"]
	if(place_sentries)
		if(radius < 2)
			return "При включённых турелях радиус должен быть не меньше 2."

		if(!(config["faction"] in valid_factions))
			return "Выбрана недопустимая фракция для турелей."

	return null

/datum/world_edit_generator/outpost_radius/preview(mob/user, list/params)
	var/datum/world_edit_preview_result/result = new
	clear_built_plan()
	var/datum/world_edit_plan/plan = build_plan(params)
	if(!istype(plan))
		result.message = "Не удалось построить план форпоста."
		return result
	if(plan.metadata["error"])
		result.message = "[plan.metadata["error"]]"
		return result
	if(!length(plan.placements) && !length(plan.deletions))
		result.message = "Для выбранной точки размещения не найдено допустимых размещений форпоста."
		return result

	current_plan = plan
	result.success = TRUE
	result.preview_images = GLOB.world_edit_helpers.build_turf_preview_images(plan.affected_turfs)
	result.meta = plan.metadata.Copy()
	result.message = "Предпросмотр готов: профиль=[plan.metadata["family_label"] || "Стандарт"], вариант=[plan.metadata["layout_label"] || "Крест"], опор=[plan.metadata["anchor_count"] || 1], проходов=[plan.metadata["opening_count"] || 0], баррикад=[plan.metadata["barricade_count"]], турелей=[plan.metadata["sentry_count"]], заблокировано=[(plan.metadata["blocked_barricades"] || 0) + (plan.metadata["blocked_openings"] || 0) + (plan.metadata["blocked_sentries"] || 0)]."
	return result

/datum/world_edit_generator/outpost_radius/apply(mob/user, list/params)
	return apply_plan(user, params, current_plan)

/datum/world_edit_generator/outpost_radius/apply_plan(mob/user, list/params, datum/world_edit_plan/plan)
	var/datum/world_edit_apply_result/result = new
	if(!istype(plan))
		result.message = "Сначала выполните предпросмотр, чтобы построить план форпоста."
		return result
	if(plan.metadata["error"])
		result.message = "[plan.metadata["error"]]"
		return result
	if(!length(plan.placements) && !length(plan.deletions))
		result.message = "Применение форпоста завершилось без допустимых размещений."
		return result
	var/turf/center_turf = plan.metadata["center_turf"]
	var/created_barricades = 0
	var/created_sentries = 0
	var/skipped_runtime = 0
	var/datum/world_edit_changeset/changeset = new /datum/world_edit_changeset(definition?.id || "outpost_radius", WORLD_EDIT_UNDO_FULL, list(
		"center_turf" = center_turf,
		"anchor_count" = plan.metadata["anchor_count"] || 1,
		"placement_mode" = plan.metadata["placement_mode"] || "single",
	))

	for(var/list/placement as anything in plan.placements)
		var/turf/target_turf = placement["turf"]
		var/placement_kind = placement["kind"]
		var/defense_path = placement["defense_path"]
		if(!target_turf || !ispath(defense_path, /datum/human_ai_defense))
			skipped_runtime++
			continue
		if(placement_kind == "barricade")
			if(!can_place_barricade_on_turf(target_turf, placement["dir"]))
				skipped_runtime++
				continue
			var/obj/created_object = spawn_defense_path(target_turf, placement["dir"], defense_path)
			if(created_object)
				created_barricades++
				changeset.add_created(created_object, target_turf, list("kind" = placement_kind))
			else
				skipped_runtime++
			continue
		if(placement_kind != "sentry")
			skipped_runtime++
			continue
		if(!can_place_sentry_on_turf(target_turf))
			skipped_runtime++
			continue
		var/obj/created_sentry = spawn_defense_path(target_turf, placement["dir"], defense_path, placement["faction"], placement["turned_on"])
		if(created_sentry)
			created_sentries++
			changeset.add_created(created_sentry, target_turf, list("kind" = placement_kind))
		else
			skipped_runtime++

	result.center_turf = center_turf
	result.created_count = created_barricades + created_sentries
	result.meta["barricade_count"] = created_barricades
	result.meta["sentry_count"] = created_sentries
	result.meta["skipped_runtime"] = skipped_runtime

	if(result.created_count <= 0)
		result.message = "Применение форпоста завершилось без созданных объектов."
		return result

	result.success = TRUE
	result.changeset = changeset
	result.message = "Форпост создан: профиль=[plan.metadata["family_label"] || "Стандарт"], вариант=[plan.metadata["layout_label"] || "Крест"], опор=[plan.metadata["anchor_count"] || 1], баррикад=[created_barricades], турелей=[created_sentries], пропущено=[skipped_runtime]."
	return result
