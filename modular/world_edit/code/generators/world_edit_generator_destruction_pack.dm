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
	var/list/area_turfs = collect_area_turfs(center_turf, radius)
	if(!length(area_turfs))
		plan.metadata["error"] = "No valid area turfs were found around the current turf."
		return plan

	var/list/targets = collect_targets(area_turfs, affect_anchored)
	if(length(targets) > max_atoms)
		plan.metadata["error"] = "The operation was blocked because [length(targets)] targets exceed the cap of [max_atoms]."
		return plan

	plan.affected_turfs = area_turfs.Copy()
	plan.metadata["center_turf"] = center_turf
	plan.metadata["radius"] = radius
	plan.metadata["area_tiles"] = length(area_turfs)
	plan.metadata["target_count"] = length(targets)
	plan.metadata["shuffle"] = shuffle_enabled
	plan.metadata["scatter"] = scatter_enabled
	plan.metadata["seed"] = rand(1, 1000000)
	plan.metadata["heavy_operation"] = (length(targets) >= round(max_atoms * 0.75)) || (radius >= 4)

	if(!length(targets))
		plan.metadata["error"] = "No movable targets matched the selected area."
		return plan

	var/list/area_lookup = build_area_lookup(area_turfs)
	for(var/atom/movable/target as anything in targets)
		var/list/move_entry = build_target_movement_entry(target, area_turfs, area_lookup, shuffle_enabled, scatter_enabled, scatter_steps)
		if(move_entry)
			plan.placements += list(move_entry)

	if(!length(plan.placements))
		plan.metadata["error"] = "Destruction pack finished with no movable targets that can change position."

	plan.metadata["moved_count"] = length(plan.placements)
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
	if(!shuffle_enabled && !scatter_enabled)
		return "Enable at least one mode: shuffle or scatter."
	if(GLOB.world_edit_helpers.parse_bool(params["affect_anchored"]))
		return "Anchored targets are disabled in the strict MVP safety pass."

	var/list/area_turfs = collect_area_turfs(center_turf, radius)
	if(!length(area_turfs))
		return "No valid area turfs were found around the current turf."

	var/list/targets = collect_targets(area_turfs, FALSE)
	if(length(targets) > max_atoms)
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
		result.message = plan.metadata["error"] || "No movable targets matched the selected area."
		return result

	current_plan = plan
	result.success = TRUE
	result.preview_images = GLOB.world_edit_helpers.build_turf_preview_images(plan.affected_turfs)
	result.meta = plan.metadata.Copy()
	result.message = "Preview ready: tiles=[plan.metadata["area_tiles"]], movable_targets=[plan.metadata["target_count"]], planned_moves=[plan.metadata["moved_count"]]."
	return result

/datum/world_edit_generator/destruction_pack/apply(mob/user, list/params)
	var/datum/world_edit_apply_result/result = new
	var/datum/world_edit_plan/plan = current_plan
	if(!istype(plan))
		result.message = "Run preview first to build the destruction plan."
		return result
	if(!length(plan.placements) && !length(plan.deletions))
		result.message = plan.metadata["error"] || "No movable targets matched the selected area."
		return result
	if(plan.metadata["heavy_operation"])
		var/heavy_answer = tgui_alert(user, "This is a heavy destruction pack apply. Confirm the second-stage execution.", "World Edit: Heavy Confirm", list("Execute", "Cancel"))
		if(heavy_answer != "Execute")
			result.message = "Destruction pack was cancelled during the heavy confirmation."
			return result

	var/moved_count = 0
	var/skipped_runtime = 0
	var/datum/world_edit_changeset/changeset = new /datum/world_edit_changeset(definition?.id || "destruction_pack", WORLD_EDIT_UNDO_PARTIAL, list(
		"center_turf" = plan.metadata["center_turf"],
		"shuffle" = plan.metadata["shuffle"],
		"scatter" = plan.metadata["scatter"],
	))
	for(var/list/placement as anything in plan.placements)
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

	result.center_turf = plan.metadata["center_turf"]
	result.created_count = moved_count
	result.meta = plan.metadata.Copy()
	result.meta["moved_count"] = moved_count
	result.meta["skipped_runtime"] = skipped_runtime

	if(moved_count <= 0)
		result.message = "Destruction pack finished without moving any targets."
		return result

	result.success = TRUE
	result.changeset = changeset
	result.message = "Destruction pack moved [moved_count] movable targets."
	return result

/datum/world_edit_generator/destruction_pack/get_ui_fields(list/current_params)
	var/scatter_enabled = GLOB.world_edit_helpers.parse_bool(current_params["scatter_enabled"])

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
			"description" = "Hard cap for movable targets processed by one apply.",
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

		if("max_atoms")
			new_params[param_id] = clamp(text2num("[value]"), 1, 100)

		if("affect_anchored")
			new_params[param_id] = GLOB.world_edit_helpers.parse_bool(value)

		else
			return ..()

	return new_params

/datum/world_edit_generator/destruction_pack/get_apply_confirmation_text(list/params)
	return "Apply Destruction Pack at the current turf with radius [params["radius"]]?"

/datum/world_edit_generator/destruction_pack/get_params_short(list/params)
	return "radius=[params["radius"]] shuffle=[params["shuffle_enabled"]] scatter=[params["scatter_enabled"]] steps=[params["scatter_steps"]] max=[params["max_atoms"]]"
