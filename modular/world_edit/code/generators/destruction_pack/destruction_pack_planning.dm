/datum/world_edit_generator/destruction_pack/build_plan(list/params, turf/center_turf_override = null, list/placement_context = null)
	var/list/effective_context = islist(placement_context) ? placement_context.Copy() : list()
	var/list/anchor_turfs = effective_context["anchor_turfs"]
	if(!islist(anchor_turfs) || !length(anchor_turfs))
		var/datum/world_edit_plan/error_plan = new
		var/turf/anchor_turf = center_turf_override || get_turf(manager?.holder?.mob)
		if(!istype(anchor_turf))
			error_plan.metadata["error"] = "Unable to resolve the anchor turf."
			return error_plan

		var/shape_id = manager?.get_effective_placement_shape() || WORLD_EDIT_SHAPE_POINT
		var/list/shape_result = GLOB.world_edit_placement_shapes.world_edit_build_shape_turfs(
			shape_id,
			anchor_turf,
			null,
			params,
			manager?.supports_current_placement_direction() ? manager?.get_effective_placement_dir() : NORTH,
		)
		if(shape_result["error"])
			error_plan.metadata["error"] = "[shape_result["error"]]"
			return error_plan

		anchor_turfs = shape_result["turfs"] || list(anchor_turf)
		var/shape_support_error = get_shape_support_error(shape_id, anchor_turfs, params, list(
			"mode" = manager?.get_effective_placement_mode() || "single",
			"shape" = shape_id,
			"shape_metadata" = shape_result["metadata"] || list(),
			"anchor_turfs" = anchor_turfs,
			"start_turf" = anchor_turf,
			"end_turf" = anchor_turf,
			"direction" = manager?.get_effective_placement_dir() || NORTH,
		))
		if(length("[shape_support_error]"))
			error_plan.metadata["error"] = "[shape_support_error]"
			return error_plan

		effective_context = list(
			"mode" = manager?.get_effective_placement_mode() || "single",
			"shape" = shape_id,
			"shape_metadata" = shape_result["metadata"] || list(),
			"anchor_turfs" = anchor_turfs,
			"start_turf" = anchor_turf,
			"end_turf" = anchor_turf,
			"direction" = manager?.get_effective_placement_dir() || NORTH,
		)

	return build_placement_plan(manager?.holder?.mob, params, effective_context)

/datum/world_edit_generator/destruction_pack/evaluate_shape_contract(datum/world_edit_shape_contract/shape_contract, list/params, list/placement_context)
	var/radius = text2num("[params["radius"]]") || 0
	var/list/radius_policy = GLOB.world_edit_helpers.get_world_edit_radius_policy(params)
	if(radius < 1 || radius > WORLD_EDIT_DESTRUCTION_RADIUS_MAX)
		return list(
			"support_class" = "full",
			"error" = "radius must stay in the range 1..[WORLD_EDIT_DESTRUCTION_RADIUS_MAX].",
			"metadata" = list("shape_support_class" = "full"),
		)

	var/list/influence_map = build_influence_map(shape_contract?.copy_anchor_turfs() || placement_context["anchor_turfs"], radius, radius_policy)
	if(!length(influence_map["seed_turfs"]))
		return list(
			"support_class" = "full",
			"error" = "Unable to resolve the destruction footprint.",
			"metadata" = list("shape_support_class" = "full"),
		)
	if(!length(influence_map["turfs"]))
		return list(
			"support_class" = "full",
			"error" = "No valid area turfs were found around the selected footprint.",
			"metadata" = list("shape_support_class" = "full"),
		)

	return list(
		"support_class" = "full",
		"error" = null,
		"metadata" = list("shape_support_class" = "full"),
	)

/datum/world_edit_generator/destruction_pack/build_plan_from_shape_contract(mob/user, datum/world_edit_shape_contract/shape_contract, list/params, list/placement_context)
	var/datum/world_edit_plan/plan = new
	var/list/anchor_turfs = shape_contract?.copy_anchor_turfs() || placement_context["anchor_turfs"]
	if(!islist(anchor_turfs) || !length(anchor_turfs))
		plan.metadata["error"] = "Unable to resolve the anchor turf."
		return plan

	var/radius = clamp(text2num("[params["radius"]]") || 3, 1, WORLD_EDIT_DESTRUCTION_RADIUS_MAX)
	var/max_atoms = clamp(text2num("[params["max_atoms"]]") || 60, 1, WORLD_EDIT_DESTRUCTION_MAX_ATOMS)
	var/scatter_steps = clamp(text2num("[params["scatter_steps"]]") || 2, 1, WORLD_EDIT_DESTRUCTION_MAX_SCATTER_STEPS)
	var/list/radius_policy = GLOB.world_edit_helpers.get_world_edit_radius_policy(params)
	var/affect_anchored = GLOB.world_edit_helpers.parse_bool(params["affect_anchored"])
	var/shuffle_enabled = GLOB.world_edit_helpers.parse_bool(params["shuffle_enabled"])
	var/scatter_enabled = GLOB.world_edit_helpers.parse_bool(params["scatter_enabled"])
	var/persistent_fire_enabled = GLOB.world_edit_helpers.parse_bool(params["persistent_fire_enabled"])
	var/persistent_fire_density = normalize_persistent_fire_density_percent(params["persistent_fire_density"])
	var/blast_enabled = GLOB.world_edit_helpers.parse_bool(params["blast_enabled"])
	var/blast_power = text2num("[params["blast_power"]]") || get_blast_power_default()
	var/blast_falloff = text2num("[params["blast_falloff"]]") || get_blast_falloff_default()
	var/damage_profile = resolve_damage_profile(params["damage_profile"])
	if(isnull(damage_profile))
		plan.metadata["error"] = "Invalid damage profile selected."
		return plan

	var/has_move_mode = shuffle_enabled || scatter_enabled
	var/has_high_risk_mode = blast_enabled || damage_profile != "none"
	var/has_non_move_mode = persistent_fire_enabled || has_high_risk_mode

	var/list/influence_map = build_influence_map(anchor_turfs, radius, radius_policy)
	var/list/influence_turfs = influence_map["turfs"] || list()
	var/list/influence_lookup = influence_map["lookup"] || list()
	var/list/seed_turfs = influence_map["seed_turfs"] || list()
	if(!length(influence_turfs))
		plan.metadata["error"] = "No valid area turfs were found around the selected footprint."
		return plan

	var/turf/center_turf = influence_map["center_turf"] || placement_context["end_turf"] || placement_context["start_turf"] || get_turf(user)
	if(!istype(center_turf))
		center_turf = seed_turfs[1]

	var/list/targets = collect_targets(influence_turfs, affect_anchored)
	if(has_move_mode && length(targets) > max_atoms && !has_non_move_mode)
		plan.metadata["error"] = "The operation was blocked because [length(targets)] targets exceed the cap of [max_atoms]."
		return plan

	if(!has_move_mode && !persistent_fire_enabled && !has_high_risk_mode)
		plan.metadata["error"] = "Enable at least one mode: shuffle, scatter, blast, ruin, collapse or persistent fire."
		return plan

	var/plan_seed = build_plan_seed(params, seed_turfs)
	var/list/fire_entries = persistent_fire_enabled ? build_persistent_fire_entries(influence_turfs, influence_lookup, persistent_fire_density, plan_seed) : list()
	var/list/blast_entries = blast_enabled ? build_blast_entries(seed_turfs, center_turf, radius, blast_power, blast_falloff, plan_seed) : list()
	var/list/damage_entries = build_damage_entries(influence_turfs, influence_lookup, damage_profile, plan_seed)

	if(persistent_fire_enabled && !length(fire_entries) && !has_move_mode && !has_high_risk_mode)
		plan.metadata["error"] = "No valid fire tiles matched the selected area."
		return plan

	var/list/band_counts = influence_map["band_counts"] || list()

	plan.affected_turfs = influence_turfs.Copy()
	plan.metadata["center_turf"] = center_turf
	plan.metadata["radius"] = radius
	plan.metadata["radius_only_clear_tiles"] = radius_policy["only_clear_tiles"]
	plan.metadata["radius_only_reachable_tiles"] = radius_policy["only_reachable_tiles"]
	plan.metadata["radius_windows_blockers"] = radius_policy["treat_windows_as_blockers"]
	plan.metadata["area_tiles"] = length(influence_turfs)
	plan.metadata["influence_tile_count"] = length(influence_turfs)
	plan.metadata["seed_count"] = length(seed_turfs)
	plan.metadata["shape_seed_count"] = influence_map["shape_seed_count"] || length(seed_turfs)
	plan.metadata["shape_footprint_count"] = influence_map["shape_footprint_count"] || length(seed_turfs)
	plan.metadata["falloff_model"] = "nearest_seed_nonstacking"
	plan.metadata["core_tile_count"] = band_counts["core"] || 0
	plan.metadata["mid_tile_count"] = band_counts["mid"] || 0
	plan.metadata["outer_tile_count"] = band_counts["outer"] || 0
	plan.metadata["target_count"] = length(targets)
	plan.metadata["shuffle"] = shuffle_enabled
	plan.metadata["scatter"] = scatter_enabled
	plan.metadata["persistent_fire"] = persistent_fire_enabled
	plan.metadata["persistent_fire_density"] = persistent_fire_density
	plan.metadata["persistent_fire_cap"] = get_persistent_fire_cap()
	plan.metadata["blast"] = blast_enabled
	plan.metadata["blast_power"] = blast_power
	plan.metadata["blast_falloff"] = blast_falloff
	plan.metadata["blast_center_count"] = length(blast_entries)
	plan.metadata["damage_profile"] = damage_profile
	plan.metadata["damage_profile_label"] = get_damage_profile_label(damage_profile)
	plan.metadata["seed"] = plan_seed
	plan.metadata["heavy_operation"] = (has_move_mode && (length(targets) >= round(max_atoms * 0.75))) || (radius >= 4) || (persistent_fire_enabled && length(fire_entries) >= round(get_persistent_fire_cap() * 0.75)) || has_high_risk_mode || length(blast_entries) > 1
	plan.metadata["undo_policy"] = has_high_risk_mode ? WORLD_EDIT_UNDO_NONE : ((has_move_mode || persistent_fire_enabled) ? WORLD_EDIT_UNDO_PARTIAL : WORLD_EDIT_UNDO_NONE)
	plan.metadata["move_requested"] = has_move_mode
	plan.metadata["move_skipped"] = FALSE

	if(has_move_mode)
		if(length(targets) > max_atoms)
			plan.metadata["move_skipped"] = TRUE
			plan.metadata["move_skip_reason"] = "target_cap"
			targets = list()
		if(!length(targets) && !has_non_move_mode)
			plan.metadata["error"] = "No movable targets matched the selected area."
			return plan
		if(!length(targets) && has_non_move_mode)
			plan.metadata["move_skipped"] = TRUE
			plan.metadata["move_skip_reason"] = "no_targets"

		var/target_index = 0
		for(var/atom/movable/target as anything in targets)
			target_index++
			var/list/move_entry = build_target_movement_entry(target, influence_turfs, influence_lookup, shuffle_enabled, scatter_enabled, scatter_steps, plan_seed, target_index)
			if(move_entry)
				plan.placements += list(move_entry)

	if(length(fire_entries))
		plan.placements += fire_entries
	if(length(blast_entries))
		plan.deletions += blast_entries
	if(length(damage_entries))
		plan.deletions += damage_entries

	var/moved_count = 0
	var/fire_count = 0
	var/blast_count = 0
	var/damage_count = 0
	for(var/list/placement as anything in plan.placements)
		if(placement["kind"] == "move")
			moved_count++
		if(placement["kind"] == "fire")
			fire_count++
	for(var/list/deletion as anything in plan.deletions)
		if(deletion["kind"] == "blast")
			blast_count++
		if(deletion["kind"] == "damage")
			damage_count += length(deletion["area_turfs"]) || 0

	plan.metadata["moved_count"] = moved_count
	plan.metadata["fire_count"] = fire_count
	plan.metadata["blast_count"] = blast_count
	plan.metadata["damage_count"] = damage_count
	plan.metadata["action_count"] = moved_count + fire_count + blast_count + damage_count
	plan.metadata["destructive_action_count"] = blast_count + damage_count

	if(!length(plan.placements) && !length(plan.deletions))
		plan.metadata["error"] = persistent_fire_enabled || has_high_risk_mode ? "No movable targets, fire tiles, blast actions, or damage targets matched the selected area." : "Destruction pack finished with no movable targets that can change position."
	finalize_shared_placement_plan_metadata(plan, shape_contract, placement_context)
	return plan

/datum/world_edit_generator/destruction_pack/build_placement_plan(mob/user, list/params, list/placement_context)
	var/datum/world_edit_shape_contract/shape_contract = build_shape_contract_from_placement_context(placement_context["shape"], placement_context["anchor_turfs"], placement_context)
	return build_plan_from_shape_contract(user, shape_contract, params, placement_context)

/datum/world_edit_generator/destruction_pack/get_shape_support_error(shape_id, list/anchor_turfs, list/params, list/placement_context)
	var/datum/world_edit_shape_contract/shape_contract = build_shape_contract_from_placement_context(shape_id, anchor_turfs, placement_context)
	var/list/support_result = evaluate_shape_contract(shape_contract, params, placement_context)
	return support_result["error"]

/datum/world_edit_generator/destruction_pack/validate_params(mob/user, list/params)
	var/radius = text2num("[params["radius"]]")
	if(!isnum(radius) || radius < 1 || radius > WORLD_EDIT_DESTRUCTION_RADIUS_MAX)
		return "radius must stay in the range 1..[WORLD_EDIT_DESTRUCTION_RADIUS_MAX]."

	var/max_atoms = text2num("[params["max_atoms"]]")
	if(!isnum(max_atoms) || max_atoms < 1 || max_atoms > WORLD_EDIT_DESTRUCTION_MAX_ATOMS)
		return "max_atoms must stay in the range 1..[WORLD_EDIT_DESTRUCTION_MAX_ATOMS]."

	var/scatter_steps = text2num("[params["scatter_steps"]]")
	if(!isnum(scatter_steps) || scatter_steps < 1 || scatter_steps > WORLD_EDIT_DESTRUCTION_MAX_SCATTER_STEPS)
		return "scatter_steps must stay in the range 1..[WORLD_EDIT_DESTRUCTION_MAX_SCATTER_STEPS]."

	var/shuffle_enabled = GLOB.world_edit_helpers.parse_bool(params["shuffle_enabled"])
	var/scatter_enabled = GLOB.world_edit_helpers.parse_bool(params["scatter_enabled"])
	var/persistent_fire_enabled = GLOB.world_edit_helpers.parse_bool(params["persistent_fire_enabled"])
	var/blast_enabled = GLOB.world_edit_helpers.parse_bool(params["blast_enabled"])
	var/damage_profile = resolve_damage_profile(params["damage_profile"])
	if(isnull(damage_profile))
		return "Invalid damage profile selected."

	var/has_move_mode = shuffle_enabled || scatter_enabled
	var/has_non_move_mode = persistent_fire_enabled || blast_enabled || damage_profile != "none"
	if(!has_move_mode && !has_non_move_mode)
		return "Enable at least one mode: shuffle, scatter, blast, ruin, collapse or persistent fire."
	if(has_move_mode && GLOB.world_edit_helpers.parse_bool(params["affect_anchored"]))
		return "Anchored targets are disabled in the strict MVP safety pass."

	if(persistent_fire_enabled)
		var/persistent_fire_density = coerce_persistent_fire_density_percent(params["persistent_fire_density"])
		if(!isnum(persistent_fire_density) || persistent_fire_density < get_persistent_fire_density_min() || persistent_fire_density > get_persistent_fire_density_max())
			return "persistent_fire_density must stay in the range [get_persistent_fire_density_min()]..[get_persistent_fire_density_max()]."

	if(blast_enabled)
		var/blast_power = text2num("[params["blast_power"]]")
		if(!isnum(blast_power) || blast_power < get_blast_power_min() || blast_power > get_blast_power_max())
			return "blast_power must stay in the range [get_blast_power_min()]..[get_blast_power_max()]."
		var/blast_falloff = text2num("[params["blast_falloff"]]")
		if(!isnum(blast_falloff) || blast_falloff < get_blast_falloff_min() || blast_falloff > get_blast_falloff_max())
			return "blast_falloff must stay in the range [get_blast_falloff_min()]..[get_blast_falloff_max()]."

	return null
