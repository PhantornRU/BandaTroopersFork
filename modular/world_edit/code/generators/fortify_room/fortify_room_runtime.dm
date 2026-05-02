/datum/world_edit_generator/fortify_room/proc/get_fortify_barricade_path(material_family, material_wired)
	switch("[material_family]")
		if("wood")
			return /obj/structure/barricade/wooden
		if("sandbag")
			return material_wired ? /obj/structure/barricade/sandbags/wired : /obj/structure/barricade/sandbags/full
		if("metal")
			return material_wired ? /obj/structure/barricade/metal/wired : /obj/structure/barricade/metal
		if("plasteel")
			return material_wired ? /obj/structure/barricade/metal/plasteel/wired : /obj/structure/barricade/metal/plasteel
	return null

/datum/world_edit_generator/fortify_room/proc/get_fortify_door_path(material_family, material_wired)
	switch("[material_family]")
		if("metal")
			return material_wired ? /obj/structure/barricade/plasteel/metal/wired : /obj/structure/barricade/plasteel/metal
		if("plasteel")
			return material_wired ? /obj/structure/barricade/plasteel/wired : /obj/structure/barricade/plasteel
	return null

/datum/world_edit_generator/fortify_room/proc/resolve_fortify_configuration(list/params)
	var/list/config = normalize_fortify_params(params)
	config["main_barricade_path"] = get_fortify_barricade_path(config["material_family"], GLOB.world_edit_helpers.parse_bool(config["material_wired"]))
	if(!ispath(config["main_barricade_path"], /obj/structure/barricade))
		config["error"] = "Fortify Room could not resolve the requested barricade material."
		return config

	var/door_policy = "[config["door_policy"]]"
	var/door_material_family = resolve_fortify_material_family(config["door_material_family"], TRUE) || "metal"
	var/door_wired = GLOB.world_edit_helpers.parse_bool(config["door_wired"]) ? TRUE : FALSE
	if(door_policy == "auto")
		door_material_family = get_fortify_auto_door_family(config["material_family"])
		door_wired = door_material_family ? (GLOB.world_edit_helpers.parse_bool(config["material_wired"]) ? TRUE : FALSE) : FALSE
	config["door_material_family"] = door_material_family || "metal"
	config["door_wired"] = door_wired ? TRUE : FALSE
	config["door_barricade_path"] = door_material_family ? get_fortify_door_path(door_material_family, door_wired) : null
	return config

/datum/world_edit_generator/fortify_room/proc/normalize_fortify_anchor_turfs(list/raw_anchor_turfs)
	return GLOB.world_edit_placement_shapes.world_edit_unique_turf_list(raw_anchor_turfs)

/datum/world_edit_generator/fortify_room/proc/resolve_fortify_anchor_turf(mob/user)
	var/turf/anchor_turf = manager?.placement_anchor_turf
	if(istype(anchor_turf))
		return anchor_turf
	return get_turf(user)

/datum/world_edit_generator/fortify_room/proc/fortify_turf_has_door(turf/target_turf)
	if(!istype(target_turf))
		return FALSE
	for(var/obj/structure/machinery/door/test_door in target_turf)
		return TRUE
	return FALSE

/datum/world_edit_generator/fortify_room/proc/fortify_turf_has_window_boundary(turf/target_turf)
	if(!istype(target_turf))
		return FALSE
	for(var/obj/structure/window/test_window in target_turf)
		return TRUE
	for(var/obj/structure/window_frame/test_window_frame in target_turf)
		return TRUE
	return FALSE

/datum/world_edit_generator/fortify_room/proc/get_fortify_boundary_kind(turf/target_turf, list/config)
	if(!istype(target_turf))
		return "invalid"
	if(istype(target_turf, /turf/closed))
		return "closed"
	if(GLOB.world_edit_helpers.parse_bool(config["treat_doors_as_boundary"]) && fortify_turf_has_door(target_turf))
		return "door"
	if(GLOB.world_edit_helpers.parse_bool(config["treat_windows_as_boundary"]) && fortify_turf_has_window_boundary(target_turf))
		return "window"
	return null

/datum/world_edit_generator/fortify_room/proc/build_fortify_seed_error(boundary_kind)
	switch("[boundary_kind]")
		if("closed")
			return "Choose an open interior turf for Fortify Room."
		if("door", "window")
			return "Choose an interior turf instead of a room boundary."
	return "Fortify Room could not resolve a valid seed turf."

/datum/world_edit_generator/fortify_room/proc/build_fortify_boundary_slot(turf/source_turf, dir_to_use, boundary_kind, list/config, list/global_slot_lookup = null)
	var/list/result = list(
		"added" = FALSE,
		"skipped_existing" = FALSE,
	)
	if(!istype(source_turf) || !GLOB.world_edit_helpers.is_cardinal_dir(dir_to_use))
		return result

	if(!islist(global_slot_lookup))
		global_slot_lookup = list()

	var/obj_path = null
	var/kind = null
	switch("[boundary_kind]")
		if("window")
			if(!GLOB.world_edit_helpers.parse_bool(config["fortify_windows"]))
				return result
			obj_path = config["main_barricade_path"]
			kind = "window_barricade"
		if("door")
			obj_path = config["door_barricade_path"]
			kind = "door_barricade"
		else
			return result

	if(!ispath(obj_path, /obj/structure/barricade))
		return result

	var/slot_key = GLOB.world_edit_helpers.build_turf_dir_slot_key(source_turf, dir_to_use)
	if(!length(slot_key) || global_slot_lookup[slot_key])
		return result
	global_slot_lookup[slot_key] = TRUE

	if(GLOB.world_edit_helpers.has_barricade_in_dir(source_turf, dir_to_use))
		result["skipped_existing"] = TRUE
		return result

	result["added"] = TRUE
	result["placement"] = list(
		"kind" = kind,
		"boundary_kind" = boundary_kind,
		"turf" = source_turf,
		"dir" = dir_to_use,
		"obj_path" = obj_path,
		"slot_key" = slot_key,
	)
	return result

/datum/world_edit_generator/fortify_room/proc/collect_fortify_room_scan(turf/seed_turf, list/config, list/global_room_lookup = null, list/global_slot_lookup = null)
	var/list/result = list(
		"room_turfs" = list(),
		"placements" = list(),
		"room_tile_count" = 0,
		"window_slot_count" = 0,
		"door_slot_count" = 0,
		"skipped_existing_count" = 0,
		"cap_hit" = FALSE,
	)
	if(!istype(seed_turf))
		result["error"] = build_fortify_seed_error("invalid")
		return result
	if(!islist(global_room_lookup))
		global_room_lookup = list()
	if(!islist(global_slot_lookup))
		global_slot_lookup = list()
	if(global_room_lookup[seed_turf])
		return result

	var/boundary_kind = get_fortify_boundary_kind(seed_turf, config)
	if(length("[boundary_kind]"))
		result["error"] = build_fortify_seed_error(boundary_kind)
		return result

	var/list/queue = list(seed_turf)
	var/list/queued_lookup = list()
	queued_lookup[seed_turf] = TRUE
	var/queue_index = 1
	var/room_tile_count = 0
	var/window_slot_count = 0
	var/door_slot_count = 0
	var/skipped_existing_count = 0
	var/list/room_turfs = list()
	var/list/placements = list()
	var/room_tile_cap = text2num("[config["room_tile_cap"]]") || WORLD_EDIT_FORTIFY_ROOM_TILE_CAP_DEFAULT
	var/cap_hit = FALSE

	while(queue_index <= length(queue))
		if(room_tile_count >= room_tile_cap)
			cap_hit = TRUE
			break

		var/turf/current_turf = queue[queue_index++]
		if(!istype(current_turf) || global_room_lookup[current_turf])
			continue

		global_room_lookup[current_turf] = TRUE
		room_turfs += current_turf
		room_tile_count++

		for(var/dir_to_use in GLOB.cardinals)
			var/turf/nearby_turf = get_step(current_turf, dir_to_use)
			if(!istype(nearby_turf))
				continue

			var/neighbor_boundary_kind = get_fortify_boundary_kind(nearby_turf, config)
			if(length("[neighbor_boundary_kind]"))
				var/list/slot_result = build_fortify_boundary_slot(current_turf, dir_to_use, neighbor_boundary_kind, config, global_slot_lookup)
				if(slot_result["added"])
					placements += list(slot_result["placement"])
					if(neighbor_boundary_kind == "window")
						window_slot_count++
					else if(neighbor_boundary_kind == "door")
						door_slot_count++
				else if(slot_result["skipped_existing"])
					skipped_existing_count++
				continue

			if(queued_lookup[nearby_turf] || global_room_lookup[nearby_turf])
				continue

			queued_lookup[nearby_turf] = TRUE
			queue += nearby_turf

	result["room_turfs"] = room_turfs
	result["placements"] = placements
	result["room_tile_count"] = room_tile_count
	result["window_slot_count"] = window_slot_count
	result["door_slot_count"] = door_slot_count
	result["skipped_existing_count"] = skipped_existing_count
	result["cap_hit"] = cap_hit ? TRUE : FALSE
	return result

/datum/world_edit_generator/fortify_room/validate_params(mob/user, list/params)
	var/list/config = resolve_fortify_configuration(params)
	if(config["error"])
		return "[config["error"]]"
	return null

/datum/world_edit_generator/fortify_room/build_plan_from_shape_contract(mob/user, datum/world_edit_shape_contract/shape_contract, list/params, list/placement_context)
	var/datum/world_edit_plan/plan = new
	var/requested_shape_id = "[shape_contract?.shape_id || placement_context["shape"] || WORLD_EDIT_SHAPE_POINT]"
	if(requested_shape_id != WORLD_EDIT_SHAPE_POINT)
		plan.metadata["error"] = "Fortify Room supports only point placement."
		return plan

	var/list/config = resolve_fortify_configuration(params)
	if(config["error"])
		plan.metadata["error"] = "[config["error"]]"
		return plan
	if(GLOB.world_edit_helpers.parse_bool(placement_context["hover_object_preview"]))
		config["room_tile_cap"] = min(text2num("[config["room_tile_cap"]]") || WORLD_EDIT_FORTIFY_ROOM_TILE_CAP_DEFAULT, WORLD_EDIT_FORTIFY_ROOM_HOVER_TILE_CAP)

	var/list/anchor_turfs = normalize_fortify_anchor_turfs(shape_contract?.copy_anchor_turfs() || placement_context["anchor_turfs"])
	if(!length(anchor_turfs))
		var/turf/fallback_seed = get_shape_placement_seed_turf(shape_contract, placement_context)
		if(istype(fallback_seed))
			anchor_turfs += fallback_seed
	if(!length(anchor_turfs))
		plan.metadata["error"] = build_fortify_seed_error("invalid")
		return plan

	var/list/affected_lookup = list()
	var/list/global_room_lookup = list()
	var/list/global_slot_lookup = list()
	var/room_tile_count = 0
	var/window_slot_count = 0
	var/door_slot_count = 0
	var/skipped_existing_count = 0
	var/cap_hit = FALSE
	var/first_error = null
	for(var/turf/anchor_turf as anything in anchor_turfs)
		if(!istype(anchor_turf))
			continue

		var/list/scan_result = collect_fortify_room_scan(anchor_turf, config, global_room_lookup, global_slot_lookup)
		if(length("[scan_result["error"]]"))
			if(!length("[first_error]"))
				first_error = "[scan_result["error"]]"
			continue

		for(var/turf/room_turf as anything in scan_result["room_turfs"])
			if(!istype(room_turf) || affected_lookup[room_turf])
				continue
			affected_lookup[room_turf] = TRUE
			plan.affected_turfs += room_turf
			room_tile_count++

		var/list/scan_placements = scan_result["placements"]
		var/current_scan_placement_count = islist(scan_placements) ? length(scan_placements) : 0
		if(length(plan.placements) + current_scan_placement_count > WORLD_EDIT_PLACEMENT_MAX_TOTAL_PLACEMENTS)
			plan.placements = list()
			plan.affected_turfs = list()
			plan.metadata["error"] = "Fortify Room requested placement exceeds safe limit ([WORLD_EDIT_PLACEMENT_MAX_TOTAL_PLACEMENTS])."
			return plan

		for(var/list/placement as anything in scan_placements)
			plan.placements += list(placement.Copy())

		window_slot_count += scan_result["window_slot_count"] || 0
		door_slot_count += scan_result["door_slot_count"] || 0
		skipped_existing_count += scan_result["skipped_existing_count"] || 0
		if(scan_result["cap_hit"])
			cap_hit = TRUE

	if(!room_tile_count)
		plan.metadata["error"] = length("[first_error]") ? "[first_error]" : "Fortify Room could not determine any interior room tiles from the selected seed."
		return plan

	var/turf/center_turf = placement_context["end_turf"]
	if(!istype(center_turf))
		center_turf = anchor_turfs[1]

	plan.metadata["center_turf"] = center_turf
	plan.metadata["entry_count"] = length(plan.placements)
	plan.metadata["anchor_count"] = length(anchor_turfs)
	plan.metadata["room_tile_count"] = room_tile_count
	plan.metadata["placement_count"] = length(plan.placements)
	plan.metadata["window_slot_count"] = window_slot_count
	plan.metadata["door_slot_count"] = door_slot_count
	plan.metadata["skipped_existing_count"] = skipped_existing_count
	plan.metadata["cap_hit"] = cap_hit ? TRUE : FALSE
	plan.metadata["preset_id"] = config["preset_id"]
	plan.metadata["material_family"] = config["material_family"]
	plan.metadata["material_wired"] = config["material_wired"]
	plan.metadata["door_policy"] = config["door_policy"]
	plan.metadata["door_material_family"] = config["door_material_family"]
	plan.metadata["door_wired"] = config["door_wired"]
	plan.metadata["room_tile_cap"] = config["room_tile_cap"]
	plan.metadata["fortify_windows"] = config["fortify_windows"]
	plan.metadata["treat_windows_as_boundary"] = config["treat_windows_as_boundary"]
	plan.metadata["treat_doors_as_boundary"] = config["treat_doors_as_boundary"]
	finalize_shared_placement_plan_metadata(plan, shape_contract, placement_context)
	plan.metadata["anchor_count"] = length(anchor_turfs)
	return plan

/datum/world_edit_generator/fortify_room/build_placement_plan(mob/user, list/params, list/placement_context)
	var/datum/world_edit_shape_contract/shape_contract = build_shape_contract_from_placement_context(placement_context["shape"], placement_context["anchor_turfs"], placement_context)
	return build_plan_from_shape_contract(user, shape_contract, params, placement_context)

/datum/world_edit_generator/fortify_room/build_plan(list/params)
	var/turf/anchor_turf = resolve_fortify_anchor_turf(manager?.holder?.mob)
	var/datum/world_edit_plan/error_plan
	if(!istype(anchor_turf))
		error_plan = new
		error_plan.metadata["error"] = build_fortify_seed_error("invalid")
		return error_plan

	var/list/shape_result = GLOB.world_edit_placement_shapes.world_edit_build_shape_turfs(WORLD_EDIT_SHAPE_POINT, anchor_turf, null, params, NORTH)
	if(shape_result["error"])
		error_plan = new
		error_plan.metadata["error"] = "[shape_result["error"]]"
		return error_plan

	return build_placement_plan(manager?.holder?.mob, params, list(
		"mode" = manager?.get_effective_placement_mode() || "single",
		"shape" = WORLD_EDIT_SHAPE_POINT,
		"shape_metadata" = shape_result["metadata"] || list(),
		"anchor_turfs" = shape_result["turfs"] || list(anchor_turf),
		"start_turf" = anchor_turf,
		"end_turf" = anchor_turf,
		"shape_origin_turf" = anchor_turf,
		"seed_turf" = anchor_turf,
		"requested_end_turf" = anchor_turf,
		"resolved_end_turf" = anchor_turf,
		"direction" = NORTH,
	))

/datum/world_edit_generator/fortify_room/proc/build_fortify_preview_spec_from_placement(list/placement)
	if(!islist(placement))
		return null

	var/turf/target_turf = placement["turf"]
	var/obj_path = placement["obj_path"]
	if(!istype(target_turf) || !ispath(obj_path, /obj/structure/barricade))
		return null
	return GLOB.world_edit_helpers.build_world_edit_atom_preview_spec(obj_path, target_turf, placement["dir"])

/datum/world_edit_generator/fortify_room/build_plan_preview_object_specs(datum/world_edit_plan/plan, list/runtime_params = null, list/placement_context = null, hover_only = FALSE)
	var/list/specs = list()
	if(!istype(plan))
		return specs
	var/spec_limit = hover_only ? WORLD_EDIT_FORTIFY_ROOM_MAX_HOVER_PREVIEW_OBJECT_SPECS : length(plan.placements)
	for(var/list/placement as anything in plan.placements)
		if(length(specs) >= spec_limit)
			break
		var/list/spec = build_fortify_preview_spec_from_placement(placement)
		if(islist(spec))
			specs += list(spec)
	return specs

/datum/world_edit_generator/fortify_room/should_render_preview_via_placement_layers(datum/world_edit_plan/plan)
	return istype(plan) ? TRUE : FALSE

/datum/world_edit_generator/fortify_room/should_skip_plan_build_for_hover_only_placement(datum/world_edit_shape_contract/shape_contract, list/runtime_params = null, list/placement_context = null)
	// Manager-side hover object preview budgets can opt into a bounded visual room scan.
	// Otherwise cursor motion stays on the shared Compact footprint.
	return TRUE

/datum/world_edit_generator/fortify_room/should_build_hover_object_preview_plan(datum/world_edit_shape_contract/shape_contract, list/runtime_params = null, list/placement_context = null)
	if(!istype(shape_contract) || length("[shape_contract.error]"))
		return FALSE
	if(shape_contract.shape_id != WORLD_EDIT_SHAPE_POINT)
		return FALSE
	if(!length(shape_contract.anchor_turfs))
		return FALSE
	return TRUE

/datum/world_edit_generator/fortify_room/get_hover_object_preview_anchor_limit()
	return WORLD_EDIT_FORTIFY_ROOM_HOVER_OBJECT_PREVIEW_MAX_ANCHORS

/datum/world_edit_generator/fortify_room/preview(mob/user, list/params)
	var/datum/world_edit_preview_result/result = new
	clear_built_plan()

	var/datum/world_edit_plan/plan = build_plan(params)
	if(!istype(plan))
		result.message = "Fortify Room could not build a placement plan."
		return result
	if(plan.metadata["error"])
		result.message = "[plan.metadata["error"]]"
		return result
	if(!(plan.metadata["room_tile_count"] || 0))
		result.message = "Fortify Room did not resolve any room tiles."
		return result

	current_plan = plan
	result.success = TRUE
	if(!manager?.should_use_placement_layer_preview(plan))
		result.preview_images = GLOB.world_edit_helpers.build_turf_preview_images(plan.affected_turfs)
		result.preview_images += GLOB.world_edit_helpers.build_preview_images_from_specs(build_plan_preview_object_specs(plan, params))
	result.meta = plan.metadata.Copy()

	var/cap_suffix = plan.metadata["cap_hit"] ? ", cap_hit=yes" : ""
	if(length(plan.placements))
		result.message = "Fortify Room preview ready: room_tiles=[plan.metadata["room_tile_count"]], placements=[length(plan.placements)], window_slots=[plan.metadata["window_slot_count"] || 0], door_slots=[plan.metadata["door_slot_count"] || 0], skipped_existing=[plan.metadata["skipped_existing_count"] || 0][cap_suffix]."
	else
		result.message = "Fortify Room preview ready: room_tiles=[plan.metadata["room_tile_count"]], no new placements, skipped_existing=[plan.metadata["skipped_existing_count"] || 0][cap_suffix]."
	return result

/datum/world_edit_generator/fortify_room/apply(mob/user, list/params)
	return apply_plan(user, params, current_plan)

/datum/world_edit_generator/fortify_room/proc/spawn_fortify_barricade(turf/target_turf, dir_to_use, obj_path)
	if(!istype(target_turf) || !ispath(obj_path, /obj/structure/barricade) || !GLOB.world_edit_helpers.is_cardinal_dir(dir_to_use))
		return null

	if(ispath(obj_path, /obj/structure/barricade/plasteel))
		var/obj/structure/barricade/plasteel/folding_barricade = new obj_path(target_turf)
		folding_barricade.setDir(dir_to_use)
		folding_barricade.open(folding_barricade)
		return folding_barricade

	var/obj/structure/barricade/new_barricade = new obj_path(target_turf)
	new_barricade.setDir(dir_to_use)
	return new_barricade

/datum/world_edit_generator/fortify_room/apply_plan(mob/user, list/params, datum/world_edit_plan/plan)
	var/datum/world_edit_apply_result/result = new
	if(!istype(plan))
		result.message = "Run preview first to build the Fortify Room plan."
		return result
	if(plan.metadata["error"])
		result.message = "[plan.metadata["error"]]"
		return result

	result.center_turf = plan.metadata["center_turf"]
	result.meta = islist(plan.metadata) ? plan.metadata.Copy() : list()
	if(!length(plan.placements))
		result.created_count = 0
		result.meta["created_window_count"] = 0
		result.meta["created_door_count"] = 0
		result.meta["skipped_runtime"] = 0
		result.success = TRUE
		result.message = "Fortify Room finished without creating new barricades."
		return result

	var/created_window_count = 0
	var/created_door_count = 0
	var/skipped_runtime = 0
	var/datum/world_edit_changeset/changeset = new /datum/world_edit_changeset(definition?.id || "fortify_room", WORLD_EDIT_UNDO_FULL, list(
		"center_turf" = plan.metadata["center_turf"],
		"seed_turf" = plan.metadata["seed_turf"],
		"room_tile_count" = plan.metadata["room_tile_count"],
		"placement_mode" = plan.metadata["placement_mode"],
		"anchor_count" = plan.metadata["anchor_count"],
	))
	for(var/list/placement as anything in plan.placements)
		var/turf/target_turf = placement["turf"]
		var/dir_to_use = placement["dir"]
		var/obj_path = placement["obj_path"]
		if(!istype(target_turf) || !GLOB.world_edit_helpers.is_cardinal_dir(dir_to_use) || !ispath(obj_path, /obj/structure/barricade))
			skipped_runtime++
			continue
		if(GLOB.world_edit_helpers.has_barricade_in_dir(target_turf, dir_to_use))
			skipped_runtime++
			continue

		var/obj/structure/barricade/created_barricade = spawn_fortify_barricade(target_turf, dir_to_use, obj_path)
		if(!created_barricade)
			skipped_runtime++
			continue

		if(placement["kind"] == "door_barricade")
			created_door_count++
		else
			created_window_count++
		changeset.add_created(created_barricade, target_turf, list(
			"kind" = placement["kind"],
			"obj_path" = obj_path,
			"dir" = dir_to_use,
		))

	result.created_count = created_window_count + created_door_count
	result.meta["created_window_count"] = created_window_count
	result.meta["created_door_count"] = created_door_count
	result.meta["skipped_runtime"] = skipped_runtime

	if(result.created_count <= 0)
		result.success = TRUE
		result.message = "Fortify Room finished without creating new barricades."
		return result

	result.success = TRUE
	result.changeset = changeset
	result.message = "Fortify Room applied: created=[result.created_count], window_slots=[created_window_count], door_slots=[created_door_count], skipped_runtime=[skipped_runtime]."
	return result
