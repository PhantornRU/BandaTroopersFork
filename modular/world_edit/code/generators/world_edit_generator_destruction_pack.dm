/datum/world_edit_generator/destruction_pack
	requires_preview_before_apply = TRUE

/datum/world_edit_generator/destruction_pack/proc/collect_area_turfs(turf/center_turf, radius)
	var/list/area_turfs = list()
	if(!center_turf)
		return area_turfs

	for(var/turf/target_turf in range(radius, center_turf))
		if(target_turf.z != center_turf.z)
			continue
		area_turfs += target_turf

	return area_turfs

/datum/world_edit_generator/destruction_pack/proc/build_area_lookup(list/area_turfs)
	var/list/area_lookup = list()
	for(var/turf/target_turf as anything in area_turfs)
		area_lookup[target_turf] = TRUE
	return area_lookup

/datum/world_edit_generator/destruction_pack/proc/should_skip_target(atom/movable/target, affect_anchored = FALSE)
	if(!target || QDELETED(target))
		return TRUE
	if(ismob(target))
		return TRUE
	if(target.anchored)
		return TRUE
	if(istype(target, /atom/movable/screen))
		return TRUE
	if(istype(target, /obj/effect/world_edit_persistent_fire))
		return TRUE
	if(istype(target, /obj/structure))
		return TRUE
	if(istype(target, /obj/structure/machinery))
		return TRUE
	if(istype(target, /obj/docking_port))
		return TRUE
	if(length(target.contents))
		return TRUE
	if(ismob(target.loc))
		return TRUE
	if(!isturf(target.loc))
		return TRUE
	return FALSE

/datum/world_edit_generator/destruction_pack/proc/can_relocate_target_to_turf(atom/movable/target, turf/target_turf)
	if(!target || QDELETED(target) || !istype(target_turf))
		return FALSE
	if(target_turf.density)
		return FALSE

	for(var/atom/blocker as anything in target_turf)
		if(blocker == target || QDELETED(blocker))
			continue
		if(ismob(blocker))
			return FALSE
		if(istype(blocker, /obj/structure))
			return FALSE
		if(istype(blocker, /obj/structure/machinery))
			return FALSE
		if(istype(blocker, /obj/docking_port))
			return FALSE
		if(blocker.density)
			return FALSE

	return TRUE

/datum/world_edit_generator/destruction_pack/proc/collect_targets(list/area_turfs, affect_anchored = FALSE)
	var/list/targets = list()
	if(!length(area_turfs))
		return targets
	for(var/turf/target_turf as anything in area_turfs)
		for(var/atom/movable/target as anything in target_turf)
			if(should_skip_target(target, affect_anchored))
				continue
			targets += target
	return targets

/datum/world_edit_generator/destruction_pack/proc/get_persistent_fire_cap()
	return 12

/datum/world_edit_generator/destruction_pack/proc/get_persistent_fire_density_min()
	return 0.05

/datum/world_edit_generator/destruction_pack/proc/get_persistent_fire_density_max()
	return 0.20

/datum/world_edit_generator/destruction_pack/proc/get_persistent_fire_density_default()
	return 0.10

/datum/world_edit_generator/destruction_pack/proc/get_blast_power_min()
	return 100

/datum/world_edit_generator/destruction_pack/proc/get_blast_power_max()
	return 600

/datum/world_edit_generator/destruction_pack/proc/get_blast_power_default()
	return 250

/datum/world_edit_generator/destruction_pack/proc/get_blast_falloff_min()
	return 100

/datum/world_edit_generator/destruction_pack/proc/get_blast_falloff_max()
	return 1200

/datum/world_edit_generator/destruction_pack/proc/get_blast_falloff_default()
	return 600

/datum/world_edit_generator/destruction_pack/proc/build_damage_profile_options()
	return list(
		list(
			"label" = "None",
			"value" = "none",
			"description" = "Only shuffle, scatter, persistent fire, and/or blast are applied.",
		),
		list(
			"label" = "Ruin",
			"value" = "ruin",
			"description" = "Low-severity structural and tile damage. Good for controlled ruin passes.",
		),
		list(
			"label" = "Collapse",
			"value" = "collapse",
			"description" = "Medium-severity structural and tile damage. Good for stronger ruin/collapse passes.",
		),
	)

/datum/world_edit_generator/destruction_pack/proc/get_default_damage_profile()
	return "none"

/datum/world_edit_generator/destruction_pack/proc/resolve_damage_profile(value)
	if(isnull(value) || !length("[value]") || "[value]" == "null")
		return get_default_damage_profile()

	var/profile_id = "[value]"
	switch(profile_id)
		if("none", "ruin", "collapse")
			return profile_id
	return null

/datum/world_edit_generator/destruction_pack/proc/get_damage_profile_label(profile_id)
	switch(resolve_damage_profile(profile_id))
		if("ruin")
			return "Ruin"
		if("collapse")
			return "Collapse"
	return "None"

/datum/world_edit_generator/destruction_pack/proc/get_damage_profile_severity(profile_id)
	switch(resolve_damage_profile(profile_id))
		if("ruin")
			return EXPLOSION_THRESHOLD_VLOW
		if("collapse")
			return EXPLOSION_THRESHOLD_LOW
	return 0

/datum/world_edit_generator/destruction_pack/proc/can_place_persistent_fire_on_turf(turf/target_turf)
	if(!istype(target_turf) || target_turf.density)
		return FALSE
	if(locate(/obj/effect/world_edit_persistent_fire) in target_turf)
		return FALSE
	return TRUE

/datum/world_edit_generator/destruction_pack/proc/apply_structural_damage_profile(list/area_turfs, severity, datum/cause_data/cause_data)
	var/damaged_turf_count = 0
	if(!islist(area_turfs) || !length(area_turfs) || severity <= 0)
		return damaged_turf_count

	for(var/turf/target_turf as anything in area_turfs)
		if(!istype(target_turf))
			continue

		target_turf.ex_act(severity, null, cause_data)
		damaged_turf_count++

		for(var/atom/target_atom as anything in target_turf)
			if(QDELETED(target_atom))
				continue
			if(ismob(target_atom))
				continue
			if(istype(target_atom, /obj/effect/world_edit_persistent_fire))
				continue
			target_atom.ex_act(severity, null, cause_data)

	return damaged_turf_count

/datum/world_edit_generator/destruction_pack/proc/build_persistent_fire_entries(list/area_turfs, density)
	var/list/fire_entries = list()
	if(!length(area_turfs) || density <= 0)
		return fire_entries

	var/target_count = round(length(area_turfs) * density)
	target_count = clamp(target_count, 0, get_persistent_fire_cap())
	if(target_count <= 0)
		return fire_entries

	var/list/pool = area_turfs.Copy()
	while(target_count > 0 && length(pool))
		var/turf/target_turf = pick_n_take(pool)
		if(!can_place_persistent_fire_on_turf(target_turf))
			continue

		fire_entries += list(list(
			"kind" = "fire",
			"turf" = target_turf,
		))
		target_count--

	return fire_entries

/datum/world_edit_generator/destruction_pack/proc/build_target_movement_entry(atom/movable/target, list/area_turfs, list/area_lookup, shuffle_enabled, scatter_enabled, scatter_steps)
	if(!target || QDELETED(target))
		return null

	var/turf/source_turf = get_turf(target)
	if(!source_turf)
		return null

	var/list/path_turfs = list()
	var/turf/current_turf = source_turf

	if(shuffle_enabled)
		var/list/shuffle_candidates = list()
		for(var/turf/candidate_turf as anything in area_turfs)
			if(candidate_turf == current_turf)
				continue
			if(!can_relocate_target_to_turf(target, candidate_turf))
				continue
			shuffle_candidates += candidate_turf

		var/turf/shuffle_turf = length(shuffle_candidates) ? pick(shuffle_candidates) : null
		if(shuffle_turf && shuffle_turf != current_turf)
			path_turfs += shuffle_turf
			current_turf = shuffle_turf

	if(scatter_enabled)
		for(var/i in 1 to scatter_steps)
			var/list/step_candidates = list()
			for(var/cardinal_dir in GLOB.cardinals)
				var/turf/next_turf = get_step(current_turf, cardinal_dir)
				if(!next_turf || !area_lookup[next_turf] || next_turf == current_turf)
					continue
				if(!can_relocate_target_to_turf(target, next_turf))
					continue
				step_candidates += next_turf

			var/turf/next_turf = length(step_candidates) ? pick(step_candidates) : null
			if(!next_turf)
				continue

			path_turfs += next_turf
			current_turf = next_turf

	if(!length(path_turfs))
		return null

	return list(
		"kind" = "move",
		"target_ref" = WEAKREF(target),
		"source_turf" = source_turf,
		"path_turfs" = path_turfs,
		"destination_turf" = current_turf,
	)

/datum/world_edit_generator/destruction_pack/proc/build_preview_style_catalog()
	return list(
		"move" = list(
			"icon_state" = "greenOverlay",
			"color" = rgb(78, 142, 255),
			"priority" = 10,
		),
		"fire" = list(
			"icon_state" = "greenOverlay",
			"color" = rgb(255, 148, 56),
			"priority" = 20,
		),
		"damage" = list(
			"icon_state" = "greenOverlay",
			"color" = rgb(184, 92, 255),
			"priority" = 30,
		),
		"blast" = list(
			"icon_state" = "greenOverlay",
			"color" = rgb(255, 78, 78),
			"priority" = 40,
		),
	)

/datum/world_edit_generator/destruction_pack/proc/register_preview_style(list/style_lookup, turf/target_turf, list/style_spec)
	if(!islist(style_lookup) || !istype(target_turf) || !islist(style_spec))
		return

	var/list/current_style = style_lookup[target_turf]
	if(islist(current_style) && text2num("[current_style["priority"]]") > text2num("[style_spec["priority"]]"))
		return

	style_lookup[target_turf] = list(
		"icon_state" = "[style_spec["icon_state"] || "greenOverlay"]",
		"color" = style_spec["color"],
		"priority" = text2num("[style_spec["priority"]]") || 0,
	)

/datum/world_edit_generator/destruction_pack/proc/build_plan_preview_images(datum/world_edit_plan/plan)
	var/list/preview_images = list()
	if(!istype(plan))
		return preview_images

	var/list/style_catalog = build_preview_style_catalog()
	var/list/style_lookup = list()

	for(var/list/placement as anything in plan.placements)
		switch("[placement["kind"]]")
			if("move")
				register_preview_style(style_lookup, placement["source_turf"], style_catalog["move"])
				register_preview_style(style_lookup, placement["destination_turf"], style_catalog["move"])
				for(var/turf/path_turf as anything in placement["path_turfs"])
					register_preview_style(style_lookup, path_turf, style_catalog["move"])
			if("fire")
				register_preview_style(style_lookup, placement["turf"], style_catalog["fire"])

	for(var/list/deletion as anything in plan.deletions)
		switch("[deletion["kind"]]")
			if("blast")
				register_preview_style(style_lookup, deletion["center_turf"], style_catalog["blast"])
			if("damage")
				for(var/turf/damage_turf as anything in deletion["area_turfs"])
					register_preview_style(style_lookup, damage_turf, style_catalog["damage"])

	var/list/group_lookup = list()
	for(var/turf/target_turf as anything in style_lookup)
		var/list/style = style_lookup[target_turf]
		if(!istype(target_turf) || !islist(style))
			continue

		var/icon_state = "[style["icon_state"] || "greenOverlay"]"
		var/color = style["color"]
		var/group_key = "[icon_state]::[color]"
		if(!islist(group_lookup[group_key]))
			group_lookup[group_key] = list(
				"turfs" = list(),
				"icon_state" = icon_state,
				"color" = color,
			)
		var/list/group = group_lookup[group_key]
		group["turfs"] += target_turf

	var/list/groups = list()
	for(var/group_key in group_lookup)
		groups += list(group_lookup[group_key])

	return GLOB.world_edit_helpers.build_grouped_turf_preview_images(groups)

/datum/world_edit_generator/destruction_pack/build_plan(list/params)
	var/datum/world_edit_plan/plan = new
	var/turf/center_turf = get_turf(manager?.holder?.mob)
	if(!center_turf)
		return plan

	var/radius = text2num("[params["radius"]]") || 3
	var/max_atoms = text2num("[params["max_atoms"]]") || 60
	var/scatter_steps = text2num("[params["scatter_steps"]]") || 2
	var/affect_anchored = GLOB.world_edit_helpers.parse_bool(params["affect_anchored"])
	var/shuffle_enabled = GLOB.world_edit_helpers.parse_bool(params["shuffle_enabled"])
	var/scatter_enabled = GLOB.world_edit_helpers.parse_bool(params["scatter_enabled"])
	var/persistent_fire_enabled = GLOB.world_edit_helpers.parse_bool(params["persistent_fire_enabled"])
	var/persistent_fire_density = text2num("[params["persistent_fire_density"]]") || get_persistent_fire_density_default()
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

	plan.affected_turfs = area_turfs.Copy()
	plan.metadata["center_turf"] = center_turf
	plan.metadata["radius"] = radius
	plan.metadata["area_tiles"] = length(area_turfs)
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

/datum/world_edit_generator/destruction_pack/validate_params(mob/user, list/params)
	var/turf/center_turf = get_turf(user)
	if(!center_turf)
		return "Unable to resolve the anchor turf."

	var/radius = text2num("[params["radius"]]")
	if(!isnum(radius) || radius < 1 || radius > 5)
		return "radius must stay in the range 1..5."

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
		var/persistent_fire_density = text2num("[params["persistent_fire_density"]]")
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

/datum/world_edit_generator/destruction_pack/preview(mob/user, list/params)
	var/datum/world_edit_preview_result/result = new
	clear_built_plan()
	var/datum/world_edit_plan/plan = build_plan(params)
	if(!istype(plan))
		result.message = "Unable to build the destruction plan."
		return result
	if(!length(plan.placements) && !length(plan.deletions))
		result.message = plan.metadata["error"] || "No movable targets, fire tiles, blast actions, or damage targets matched the selected area."
		return result

	current_plan = plan
	result.success = TRUE
	result.preview_images = build_plan_preview_images(plan)
	result.meta = plan.metadata.Copy()
	result.message = "Preview ready: tiles=[plan.metadata["area_tiles"]], movable_targets=[plan.metadata["target_count"]], planned_moves=[plan.metadata["moved_count"]], fire_tiles=[plan.metadata["fire_count"]], blasts=[plan.metadata["blast_count"]], damage=[plan.metadata["damage_profile_label"] || "None"], undo=[plan.metadata["undo_policy"] || WORLD_EDIT_UNDO_NONE]."
	return result

/datum/world_edit_generator/destruction_pack/apply(mob/user, list/params)
	var/datum/world_edit_apply_result/result = new
	var/datum/world_edit_plan/plan = current_plan
	if(!istype(plan))
		result.message = "Run preview first to build the destruction plan."
		return result
	if(!length(plan.placements) && !length(plan.deletions))
		result.message = plan.metadata["error"] || "No movable targets, fire tiles, blast actions, or damage targets matched the selected area."
		return result

	var/moved_count = 0
	var/fire_count = 0
	var/blast_count = 0
	var/damage_count = 0
	var/skipped_runtime = 0
	var/datum/world_edit_changeset/changeset = new /datum/world_edit_changeset(definition?.id || "destruction_pack", WORLD_EDIT_UNDO_PARTIAL, list(
		"center_turf" = plan.metadata["center_turf"],
		"shuffle" = plan.metadata["shuffle"],
		"scatter" = plan.metadata["scatter"],
		"persistent_fire" = plan.metadata["persistent_fire"],
		"blast" = plan.metadata["blast"],
		"damage_profile" = plan.metadata["damage_profile"],
	))
	changeset.undo_policy = plan.metadata["undo_policy"] || WORLD_EDIT_UNDO_NONE
	var/datum/cause_data/cause_data = create_cause_data("world edit destruction pack", manager?.holder)
	for(var/list/placement as anything in plan.placements)
		if(placement["kind"] == "fire")
			var/turf/target_turf = placement["turf"]
			if(!can_place_persistent_fire_on_turf(target_turf))
				skipped_runtime++
				continue

			var/obj/effect/world_edit_persistent_fire/fire = new /obj/effect/world_edit_persistent_fire(target_turf)
			if(!istype(fire))
				skipped_runtime++
				continue
			fire.set_world_edit_owner(changeset.operation_id, definition?.id)
			changeset.add_owned_effect(fire, changeset.operation_id, target_turf, list(
				"kind" = "persistent_fire",
			))
			fire_count++
			continue

		if(placement["kind"] != "move")
			continue

		var/datum/weakref/target_ref = placement["target_ref"]
		var/atom/movable/target = target_ref?.resolve()
		if(!istype(target, /atom/movable) || QDELETED(target))
			skipped_runtime++
			continue
		if(should_skip_target(target, FALSE))
			skipped_runtime++
			continue

		var/turf/source_turf = placement["source_turf"]
		if(get_turf(target) != source_turf)
			skipped_runtime++
			continue

		var/list/path_turfs = placement["path_turfs"]
		if(!length(path_turfs))
			skipped_runtime++
			continue

		var/moved_this_target = FALSE
		for(var/turf/next_turf as anything in path_turfs)
			if(!next_turf || next_turf == get_turf(target))
				continue
			if(!can_relocate_target_to_turf(target, next_turf))
				continue
			target.forceMove(next_turf)
			moved_this_target = TRUE

		if(moved_this_target)
			moved_count++
			changeset.add_moved(target, source_turf, get_turf(target), list(
				"shuffle" = plan.metadata["shuffle"],
				"scatter" = plan.metadata["scatter"],
			))
		else
			skipped_runtime++

	for(var/list/deletion as anything in plan.deletions)
		if(deletion["kind"] == "blast")
			var/turf/blast_turf = deletion["center_turf"]
			if(!istype(blast_turf))
				skipped_runtime++
				continue
			cell_explosion(blast_turf, deletion["power"], deletion["falloff"], EXPLOSION_FALLOFF_SHAPE_LINEAR, null, cause_data)
			blast_count++
			continue

		if(deletion["kind"] == "damage")
			var/list/damage_area_turfs = deletion["area_turfs"]
			var/severity = text2num("[deletion["severity"]]") || 0
			if(!islist(damage_area_turfs) || !length(damage_area_turfs) || severity <= 0)
				skipped_runtime++
				continue
			damage_count += apply_structural_damage_profile(damage_area_turfs, severity, cause_data)
			continue

		skipped_runtime++

	var/total_actions = moved_count + fire_count + blast_count + damage_count

	result.center_turf = plan.metadata["center_turf"]
	result.created_count = total_actions
	result.deleted_count = blast_count + damage_count
	result.meta = plan.metadata.Copy()
	result.meta["moved_count"] = moved_count
	result.meta["fire_count"] = fire_count
	result.meta["blast_count"] = blast_count
	result.meta["damage_count"] = damage_count
	result.meta["action_count"] = total_actions
	result.meta["skipped_runtime"] = skipped_runtime

	if(total_actions <= 0)
		result.message = plan.metadata["error"] || "Destruction pack finished without applying any moves, fire tiles, blasts, or damage profiles."
		return result

	result.success = TRUE
	result.changeset = changeset
	var/list/summaries = list()
	if(moved_count > 0)
		summaries += "[moved_count] moved targets"
	if(fire_count > 0)
		summaries += "[fire_count] owned fire tiles"
	if(blast_count > 0)
		summaries += "[blast_count] blasts"
	if(damage_count > 0)
		summaries += "[damage_count] damaged turfs"
	var/summary_text = jointext(summaries, ", ")
	if(!length(summary_text))
		summary_text = "no-op"
	result.message = "Destruction pack applied: [summary_text]. Undo=[changeset.undo_policy]."
	return result

/datum/world_edit_generator/destruction_pack/get_runtime_status()
	var/list/params = manager?.current_params || list()
	var/shuffle_enabled = GLOB.world_edit_helpers.parse_bool(params["shuffle_enabled"])
	var/scatter_enabled = GLOB.world_edit_helpers.parse_bool(params["scatter_enabled"])
	var/persistent_fire_enabled = GLOB.world_edit_helpers.parse_bool(params["persistent_fire_enabled"])
	var/blast_enabled = GLOB.world_edit_helpers.parse_bool(params["blast_enabled"])
	var/damage_profile = resolve_damage_profile(params["damage_profile"])

	return list(
		list("label" = "Move mode", "value" = (shuffle_enabled || scatter_enabled) ? "active" : "off"),
		list("label" = "Persistent fire", "value" = persistent_fire_enabled ? "active" : "off"),
		list("label" = "Blast", "value" = blast_enabled ? "active" : "off"),
		list("label" = "Damage profile", "value" = get_damage_profile_label(damage_profile)),
		list("label" = "Fire cap", "value" = "[get_persistent_fire_cap()] tiles"),
	)

/datum/world_edit_generator/destruction_pack/get_ui_fields(list/current_params)
	var/scatter_enabled = GLOB.world_edit_helpers.parse_bool(current_params["scatter_enabled"])
	var/persistent_fire_enabled = GLOB.world_edit_helpers.parse_bool(current_params["persistent_fire_enabled"])
	var/blast_enabled = GLOB.world_edit_helpers.parse_bool(current_params["blast_enabled"])
	var/damage_profile = resolve_damage_profile(current_params["damage_profile"])

	return list(
		list(
			"id" = "radius",
			"label" = "Radius",
			"kind" = "number",
			"group" = "Area",
			"description" = "Square radius around the current turf.",
			"validate_hint" = "Allowed range: 1..5",
			"value" = text2num("[current_params["radius"]]") || 3,
			"min" = 1,
			"max" = 5,
			"step" = 1,
		),
		list(
			"id" = "shuffle_enabled",
			"label" = "Shuffle Targets",
			"kind" = "boolean",
			"group" = "Modes",
			"description" = "Randomly reassigns movable targets to tiles within the preview area.",
			"value" = GLOB.world_edit_helpers.parse_bool(current_params["shuffle_enabled"]),
		),
		list(
			"id" = "scatter_enabled",
			"label" = "Scatter Targets",
			"kind" = "boolean",
			"group" = "Modes",
			"description" = "Moves targets step-by-step inside the selected area.",
			"value" = GLOB.world_edit_helpers.parse_bool(current_params["scatter_enabled"]),
		),
		list(
			"id" = "persistent_fire_enabled",
			"label" = "Persistent Fire",
			"kind" = "boolean",
			"group" = "Fire",
			"description" = "Creates owned persistent fire tiles inside the selected area. Cleanup is available from the owned-effects stack. Hard cap: [get_persistent_fire_cap()] tiles.",
			"value" = persistent_fire_enabled,
		),
		list(
			"id" = "persistent_fire_density",
			"label" = "Fire Density",
			"kind" = "number",
			"group" = "Fire",
			"description" = "Fraction of open candidate tiles used for persistent fire before the hard cap is applied.",
			"validate_hint" = "Allowed range: [get_persistent_fire_density_min()]..[get_persistent_fire_density_max()]",
			"value" = text2num("[current_params["persistent_fire_density"]]") || get_persistent_fire_density_default(),
			"min" = get_persistent_fire_density_min(),
			"max" = get_persistent_fire_density_max(),
			"step" = 0.01,
			"disabled" = !persistent_fire_enabled,
		),
		list(
			"id" = "blast_enabled",
			"label" = "Blast",
			"kind" = "boolean",
			"group" = "Blast",
			"description" = "Triggers a controlled cell explosion at the selected center after movement and fire placement. This disables undo for the operation.",
			"value" = blast_enabled,
		),
		list(
			"id" = "blast_power",
			"label" = "Blast Power",
			"kind" = "number",
			"group" = "Blast",
			"description" = "Explosion strength for the controlled blast.",
			"validate_hint" = "Allowed range: [get_blast_power_min()]..[get_blast_power_max()]",
			"value" = text2num("[current_params["blast_power"]]") || get_blast_power_default(),
			"min" = get_blast_power_min(),
			"max" = get_blast_power_max(),
			"step" = 10,
			"disabled" = !blast_enabled,
		),
		list(
			"id" = "blast_falloff",
			"label" = "Blast Falloff",
			"kind" = "number",
			"group" = "Blast",
			"description" = "Explosion falloff for the controlled blast.",
			"validate_hint" = "Allowed range: [get_blast_falloff_min()]..[get_blast_falloff_max()]",
			"value" = text2num("[current_params["blast_falloff"]]") || get_blast_falloff_default(),
			"min" = get_blast_falloff_min(),
			"max" = get_blast_falloff_max(),
			"step" = 10,
			"disabled" = !blast_enabled,
		),
		list(
			"id" = "damage_profile",
			"label" = "Damage Profile",
			"kind" = "select",
			"group" = "Damage",
			"description" = "Applies structural and tile damage directly to the selected area without a blast curve. This disables undo for the operation.",
			"value" = damage_profile,
			"options" = build_damage_profile_options(),
		),
		list(
			"id" = "scatter_steps",
			"label" = "Scatter Steps",
			"kind" = "number",
			"group" = "Modes",
			"description" = "Number of random movement steps when scatter is enabled.",
			"validate_hint" = "Allowed range: 1..4",
			"value" = text2num("[current_params["scatter_steps"]]") || 2,
			"min" = 1,
			"max" = 4,
			"step" = 1,
			"visible" = scatter_enabled,
			"disabled" = !scatter_enabled,
		),
		list(
			"id" = "max_atoms",
			"label" = "Max Targets",
			"kind" = "number",
			"group" = "Limits",
			"description" = "Hard cap for movable targets processed by one apply when shuffle or scatter is enabled.",
			"validate_hint" = "Allowed range: 1..100",
			"value" = text2num("[current_params["max_atoms"]]") || 60,
			"min" = 1,
			"max" = 100,
			"step" = 1,
		),
	)

/datum/world_edit_generator/destruction_pack/set_ui_param(mob/user, list/current_params, param_id, value)
	var/list/new_params = current_params.Copy()

	switch(param_id)
		if("radius")
			new_params[param_id] = clamp(text2num("[value]"), 1, 5)

		if("shuffle_enabled")
			new_params[param_id] = GLOB.world_edit_helpers.parse_bool(value)

		if("scatter_enabled")
			new_params[param_id] = GLOB.world_edit_helpers.parse_bool(value)

		if("scatter_steps")
			new_params[param_id] = clamp(text2num("[value]"), 1, 4)

		if("persistent_fire_enabled")
			new_params[param_id] = GLOB.world_edit_helpers.parse_bool(value)
			if(new_params[param_id] && isnull(new_params["persistent_fire_density"]))
				new_params["persistent_fire_density"] = get_persistent_fire_density_default()

		if("persistent_fire_density")
			new_params[param_id] = clamp(text2num("[value]"), get_persistent_fire_density_min(), get_persistent_fire_density_max())

		if("blast_enabled")
			new_params[param_id] = GLOB.world_edit_helpers.parse_bool(value)
			if(new_params[param_id] && isnull(new_params["blast_power"]))
				new_params["blast_power"] = get_blast_power_default()
			if(new_params[param_id] && isnull(new_params["blast_falloff"]))
				new_params["blast_falloff"] = get_blast_falloff_default()

		if("blast_power")
			new_params[param_id] = clamp(text2num("[value]"), get_blast_power_min(), get_blast_power_max())

		if("blast_falloff")
			new_params[param_id] = clamp(text2num("[value]"), get_blast_falloff_min(), get_blast_falloff_max())

		if("damage_profile")
			var/profile_id = resolve_damage_profile(value)
			if(!profile_id)
				return "Invalid damage profile selected."
			new_params[param_id] = profile_id

		if("max_atoms")
			new_params[param_id] = clamp(text2num("[value]"), 1, 100)

		if("affect_anchored")
			new_params[param_id] = GLOB.world_edit_helpers.parse_bool(value)

		else
			return ..()

	return new_params

/datum/world_edit_generator/destruction_pack/get_apply_confirmation_text(list/params)
	var/fire_enabled = GLOB.world_edit_helpers.parse_bool(params["persistent_fire_enabled"])
	var/blast_enabled = GLOB.world_edit_helpers.parse_bool(params["blast_enabled"])
	var/damage_profile = get_damage_profile_label(params["damage_profile"])
	var/undo_policy = (blast_enabled || resolve_damage_profile(params["damage_profile"]) != "none") ? WORLD_EDIT_UNDO_NONE : WORLD_EDIT_UNDO_PARTIAL
	return "Применить разрушение зоны? Радиус [params["radius"]], перемещение=[params["shuffle_enabled"]], разброс=[params["scatter_enabled"]], огонь=[fire_enabled ? "да" : "нет"], взрыв=[blast_enabled ? "да" : "нет"], урон=[damage_profile], откат=[undo_policy]."

/datum/world_edit_generator/destruction_pack/get_params_short(list/params)
	var/fire_density = text2num("[params["persistent_fire_density"]]") || get_persistent_fire_density_default()
	return "radius=[params["radius"]] shuffle=[params["shuffle_enabled"]] scatter=[params["scatter_enabled"]] fire=[params["persistent_fire_enabled"]] density=[fire_density] blast=[params["blast_enabled"]] blast_power=[params["blast_power"]] blast_falloff=[params["blast_falloff"]] damage=[params["damage_profile"]] steps=[params["scatter_steps"]] max=[params["max_atoms"]]"
