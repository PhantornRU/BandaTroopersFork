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

/datum/world_edit_generator/destruction_pack/proc/shuffle_targets(list/targets, list/area_turfs, list/moved_lookup)
	if(!length(targets) || !length(area_turfs))
		return

	for(var/atom/movable/target as anything in targets)
		if(!target || QDELETED(target))
			continue

		var/turf/current_turf = get_turf(target)
		var/turf/new_turf = pick(area_turfs)
		if(!current_turf || !new_turf || current_turf == new_turf)
			continue

		target.forceMove(new_turf)
		moved_lookup[target] = TRUE

/datum/world_edit_generator/destruction_pack/proc/scatter_targets(list/targets, scatter_steps, list/area_lookup, list/moved_lookup)
	if(!length(targets) || scatter_steps <= 0)
		return

	for(var/atom/movable/target as anything in targets)
		if(!target || QDELETED(target))
			continue

		for(var/i in 1 to scatter_steps)
			var/turf/current_turf = get_turf(target)
			if(!current_turf)
				break

			var/turf/next_turf = get_step(current_turf, pick(GLOB.cardinals))
			if(!next_turf || !area_lookup[next_turf] || next_turf == current_turf)
				continue

			target.forceMove(next_turf)
			moved_lookup[target] = TRUE

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

	var/shuffle_enabled = world_edit_parse_bool(params["shuffle_enabled"])
	var/scatter_enabled = world_edit_parse_bool(params["scatter_enabled"])
	if(!shuffle_enabled && !scatter_enabled)
		return "Enable at least one mode: shuffle or scatter."
	if(world_edit_parse_bool(params["affect_anchored"]))
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
	var/turf/center_turf = get_turf(user)
	if(!center_turf)
		result.message = "Unable to resolve the anchor turf."
		return result

	var/radius = text2num("[params["radius"]]") || 3
	var/affect_anchored = world_edit_parse_bool(params["affect_anchored"])
	var/list/area_turfs = collect_area_turfs(center_turf, radius)
	if(!length(area_turfs))
		result.message = "No valid area turfs were found around the current turf."
		return result
	var/list/targets = collect_targets(area_turfs, affect_anchored)

	result.success = TRUE
	result.preview_images = world_edit_build_turf_preview_images(area_turfs)
	result.meta["radius"] = radius
	result.meta["area_tiles"] = length(area_turfs)
	result.meta["target_count"] = length(targets)
	result.meta["shuffle"] = world_edit_parse_bool(params["shuffle_enabled"])
	result.meta["scatter"] = world_edit_parse_bool(params["scatter_enabled"])
	result.message = "Preview ready: tiles=[length(area_turfs)], movable_targets=[length(targets)]."
	return result

/datum/world_edit_generator/destruction_pack/apply(mob/user, list/params)
	var/datum/world_edit_apply_result/result = new
	var/turf/center_turf = get_turf(user)
	if(!center_turf)
		result.message = "Unable to resolve the anchor turf."
		return result

	var/radius = text2num("[params["radius"]]") || 3
	var/max_atoms = text2num("[params["max_atoms"]]") || 60
	var/scatter_steps = text2num("[params["scatter_steps"]]") || 2
	var/affect_anchored = world_edit_parse_bool(params["affect_anchored"])
	var/shuffle_enabled = world_edit_parse_bool(params["shuffle_enabled"])
	var/scatter_enabled = world_edit_parse_bool(params["scatter_enabled"])
	var/list/area_turfs = collect_area_turfs(center_turf, radius)
	if(!length(area_turfs))
		result.message = "No valid area turfs were found around the current turf."
		return result
	var/list/area_lookup = build_area_lookup(area_turfs)
	var/list/targets = collect_targets(area_turfs, affect_anchored)

	result.center_turf = center_turf
	result.meta["target_count"] = length(targets)
	result.meta["area_tiles"] = length(area_turfs)

	if(!length(targets))
		result.message = "No movable targets matched the selected area."
		return result

	if(length(targets) > max_atoms)
		result.message = "The operation was blocked because [length(targets)] targets exceed the cap of [max_atoms]."
		return result

	var/heavy_operation = (length(targets) >= round(max_atoms * 0.75)) || (radius >= 4)
	if(heavy_operation)
		var/heavy_answer = tgui_alert(user, "This is a heavy destruction pack apply. Confirm the second-stage execution.", "World Edit: Heavy Confirm", list("Execute", "Cancel"))
		if(heavy_answer != "Execute")
			result.message = "Destruction pack was cancelled during the heavy confirmation."
			return result

	var/list/moved_lookup = list()
	if(shuffle_enabled)
		shuffle_targets(targets, area_turfs, moved_lookup)
	if(scatter_enabled)
		scatter_targets(targets, scatter_steps, area_lookup, moved_lookup)

	var/moved_count = length(moved_lookup)
	result.created_count = moved_count
	result.meta["moved_count"] = moved_count
	result.meta["shuffle"] = shuffle_enabled
	result.meta["scatter"] = scatter_enabled

	if(moved_count <= 0)
		result.message = "Destruction pack finished without moving any targets."
		return result

	result.success = TRUE
	result.message = "Destruction pack moved [moved_count] movable targets."
	return result

/datum/world_edit_generator/destruction_pack/get_ui_fields(list/current_params)
	var/scatter_enabled = world_edit_parse_bool(current_params["scatter_enabled"])

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
			"value" = world_edit_parse_bool(current_params["shuffle_enabled"]),
		),
		list(
			"id" = "scatter_enabled",
			"label" = "Scatter Targets",
			"kind" = "boolean",
			"group" = "Modes",
			"description" = "Moves targets step-by-step inside the selected area.",
			"value" = world_edit_parse_bool(current_params["scatter_enabled"]),
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
		list(
			"id" = "affect_anchored",
			"label" = "Affect Anchored",
			"kind" = "boolean",
			"group" = "Limits",
			"description" = "Includes anchored movable objects except blocked machinery classes.",
			"value" = world_edit_parse_bool(current_params["affect_anchored"]),
		),
	)

/datum/world_edit_generator/destruction_pack/set_ui_param(mob/user, list/current_params, param_id, value)
	var/list/new_params = current_params.Copy()

	switch(param_id)
		if("radius")
			new_params[param_id] = clamp(text2num("[value]"), 1, 5)

		if("shuffle_enabled")
			new_params[param_id] = world_edit_parse_bool(value)

		if("scatter_enabled")
			new_params[param_id] = world_edit_parse_bool(value)

		if("scatter_steps")
			new_params[param_id] = clamp(text2num("[value]"), 1, 4)

		if("max_atoms")
			new_params[param_id] = clamp(text2num("[value]"), 1, 100)

		if("affect_anchored")
			new_params[param_id] = world_edit_parse_bool(value)

		else
			return ..()

	return new_params

/datum/world_edit_generator/destruction_pack/get_apply_confirmation_text(list/params)
	return "Apply Destruction Pack at the current turf with radius [params["radius"]]?"

/datum/world_edit_generator/destruction_pack/get_params_short(list/params)
	return "radius=[params["radius"]] shuffle=[params["shuffle_enabled"]] scatter=[params["scatter_enabled"]] steps=[params["scatter_steps"]] max=[params["max_atoms"]]"
