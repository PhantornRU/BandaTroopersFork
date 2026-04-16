/datum/world_edit_generator/destruction_pack/build_plan(list/params, turf/center_turf_override = null, list/placement_context = null)
	var/datum/world_edit_plan/plan = new
	var/turf/center_turf = center_turf_override || get_turf(manager?.holder?.mob)
	if(!center_turf)
		return plan

	var/radius = text2num("[params["radius"]]") || 3
	var/max_atoms = text2num("[params["max_atoms"]]") || 60
	var/scatter_steps = text2num("[params["scatter_steps"]]") || 2
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
	var/damage_severity = get_damage_profile_severity(damage_profile)
	var/has_move_mode = shuffle_enabled || scatter_enabled
	var/has_high_risk_mode = blast_enabled || damage_profile != "none"
	var/has_non_move_mode = persistent_fire_enabled || has_high_risk_mode
	var/list/area_turfs = collect_area_turfs(center_turf, radius)
	if(!length(area_turfs))
		plan.metadata["error"] = "No valid area turfs were found around the current turf."
		return plan

	var/list/targets = collect_targets(area_turfs, affect_anchored)
	if(has_move_mode && length(targets) > max_atoms && !has_non_move_mode)
		plan.metadata["error"] = "The operation was blocked because [length(targets)] targets exceed the cap of [max_atoms]."
		return plan

	if(!has_move_mode && !persistent_fire_enabled && !has_high_risk_mode)
		plan.metadata["error"] = "Enable at least one mode: shuffle, scatter, blast, ruin, collapse or persistent fire."
		return plan

	var/list/fire_entries = persistent_fire_enabled ? build_persistent_fire_entries(area_turfs, persistent_fire_density) : list()
	var/list/blast_entries = blast_enabled ? list(list(
		"kind" = "blast",
		"center_turf" = center_turf,
		"power" = blast_power,
		"falloff" = blast_falloff,
	)) : list()
	var/list/damage_entries = damage_profile != "none" ? list(list(
		"kind" = "damage",
		"area_turfs" = area_turfs.Copy(),
		"damage_profile" = damage_profile,
		"severity" = damage_severity,
	)) : list()

	if(persistent_fire_enabled && !length(fire_entries) && !has_move_mode && !has_high_risk_mode)
		plan.metadata["error"] = "No valid fire tiles matched the selected area."
		return plan

	var/placement_mode = "single"
	var/placement_shape = WORLD_EDIT_SHAPE_POINT
	var/anchor_count = 1
	if(islist(placement_context))
		if(length("[placement_context["mode"]]"))
			placement_mode = "[placement_context["mode"]]"
		if(length("[placement_context["shape"]]"))
			placement_shape = "[placement_context["shape"]]"
		anchor_count = max(length(placement_context["anchor_turfs"]) || 0, 1)

	plan.affected_turfs = area_turfs.Copy()
	plan.metadata["center_turf"] = center_turf
	plan.metadata["radius"] = radius
	plan.metadata["area_tiles"] = length(area_turfs)
	plan.metadata["placement_mode"] = placement_mode
	plan.metadata["placement_shape"] = placement_shape
	plan.metadata["shape_label"] = GLOB.world_edit_placement_shapes.world_edit_get_placement_shape_label(plan.metadata["placement_shape"])
	plan.metadata["anchor_count"] = anchor_count
	plan.metadata["target_count"] = length(targets)
	plan.metadata["shuffle"] = shuffle_enabled
	plan.metadata["scatter"] = scatter_enabled
	plan.metadata["persistent_fire"] = persistent_fire_enabled
	plan.metadata["persistent_fire_density"] = persistent_fire_density
	plan.metadata["persistent_fire_cap"] = get_persistent_fire_cap()
	plan.metadata["blast"] = blast_enabled
	plan.metadata["blast_power"] = blast_power
	plan.metadata["blast_falloff"] = blast_falloff
	plan.metadata["damage_profile"] = damage_profile
	plan.metadata["damage_profile_label"] = get_damage_profile_label(damage_profile)
	plan.metadata["damage_severity"] = damage_severity
	plan.metadata["seed"] = rand(1, 1000000)
	plan.metadata["heavy_operation"] = (has_move_mode && (length(targets) >= round(max_atoms * 0.75))) || (radius >= 4) || (persistent_fire_enabled && length(fire_entries) >= round(get_persistent_fire_cap() * 0.75)) || has_high_risk_mode
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

		var/list/area_lookup = build_area_lookup(area_turfs)
		for(var/atom/movable/target as anything in targets)
			var/list/move_entry = build_target_movement_entry(target, area_turfs, area_lookup, shuffle_enabled, scatter_enabled, scatter_steps)
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
			damage_count++

	plan.metadata["moved_count"] = moved_count
	plan.metadata["fire_count"] = fire_count
	plan.metadata["blast_count"] = blast_count
	plan.metadata["damage_count"] = damage_count
	plan.metadata["action_count"] = moved_count + fire_count + blast_count + damage_count
	plan.metadata["destructive_action_count"] = blast_count + damage_count

	if(!length(plan.placements) && !length(plan.deletions))
		plan.metadata["error"] = persistent_fire_enabled || has_high_risk_mode ? "No movable targets, fire tiles, blast actions, or damage targets matched the selected area." : "Destruction pack finished with no movable targets that can change position."
	return plan

/datum/world_edit_generator/destruction_pack/build_placement_plan(mob/user, list/params, list/placement_context)
	var/turf/center_turf = placement_context["end_turf"] || placement_context["start_turf"] || get_turf(user)
	if(!istype(center_turf))
		center_turf = get_turf(manager?.holder?.mob)
	return build_plan(params, center_turf, placement_context)

/datum/world_edit_generator/destruction_pack/validate_params(mob/user, list/params)
	var/turf/center_turf = get_turf(user)
	if(!center_turf)
		return "Unable to resolve the anchor turf."

	var/radius = text2num("[params["radius"]]")
	if(!isnum(radius) || radius < 1 || radius > 10)
		return "radius must stay in the range 1..10."

	var/max_atoms = text2num("[params["max_atoms"]]")
	if(!isnum(max_atoms) || max_atoms < 1 || max_atoms > 100)
		return "max_atoms must stay in the range 1..100."

	var/scatter_steps = text2num("[params["scatter_steps"]]")
	if(!isnum(scatter_steps) || scatter_steps < 1 || scatter_steps > 4)
		return "scatter_steps must stay in the range 1..4."

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

	var/list/area_turfs = collect_area_turfs(center_turf, radius)
	if(!length(area_turfs))
		return "No valid area turfs were found around the current turf."

	var/list/targets = collect_targets(area_turfs, FALSE)
	if(has_move_mode && length(targets) > max_atoms && !has_non_move_mode)
		return "The operation was blocked because [length(targets)] targets exceed the cap of [max_atoms]."

	return null
