/datum/world_edit_building_template_cell
	var/dx = 0
	var/dy = 0
	var/slot = "table"
	var/category = "table"
	var/wall_required = FALSE
	var/major = TRUE

/datum/world_edit_building_template_cell/New(_dx = 0, _dy = 0, _slot = "table", _category = "table", _wall_required = FALSE, _major = TRUE)
	. = ..()
	dx = round(text2num("[_dx]") || 0)
	dy = round(text2num("[_dy]") || 0)
	slot = length("[_slot]") ? "[_slot]" : "table"
	category = length("[_category]") ? "[_category]" : "table"
	wall_required = _wall_required ? TRUE : FALSE
	major = _major ? TRUE : FALSE

/datum/world_edit_building_template_chunk
	var/id = ""
	var/category = "generic"
	var/list/cells = list()

/datum/world_edit_building_template_chunk/New(_id = "", _category = "generic")
	. = ..()
	id = "[_id]"
	category = length("[_category]") ? "[_category]" : "generic"
	cells = list()

/datum/world_edit_building_template_chunk/proc/add_cell(dx, dy, slot, category, wall_required = FALSE, major = TRUE)
	if(length(cells) >= WORLD_EDIT_BUILDING_MAX_TEMPLATE_CHUNK_CELLS)
		return src
	cells += new /datum/world_edit_building_template_cell(dx, dy, slot, category, wall_required, major)
	return src

/datum/world_edit_generator/building_layout/proc/register_building_template_chunk(list/catalog, datum/world_edit_building_template_chunk/chunk)
	if(!islist(catalog) || !istype(chunk) || !length(chunk.id) || !length(chunk.cells))
		return
	catalog[chunk.id] = chunk

/datum/world_edit_generator/building_layout/proc/get_building_template_chunk_catalog()
	var/static/list/template_catalog
	if(islist(template_catalog))
		return template_catalog
	template_catalog = list()

	var/datum/world_edit_building_template_chunk/chunk
	chunk = new /datum/world_edit_building_template_chunk("workshop_wall_chunk", "workshop")
	chunk.add_cell(0, 0, "table", "table", TRUE)
	chunk.add_cell(1, 0, "processor", "work_machine", TRUE)
	chunk.add_cell(2, 0, "console", "console", TRUE)
	chunk.add_cell(3, 0, "rack", "rack", TRUE, FALSE)
	register_building_template_chunk(template_catalog, chunk)

	chunk = new /datum/world_edit_building_template_chunk("rack_run_chunk", "storage")
	chunk.add_cell(0, 0, "rack", "rack", TRUE)
	chunk.add_cell(1, 0, "rack", "rack", TRUE)
	chunk.add_cell(2, 0, "crate", "crate", FALSE)
	chunk.add_cell(3, 0, "rack", "rack", TRUE)
	register_building_template_chunk(template_catalog, chunk)

	chunk = new /datum/world_edit_building_template_chunk("cabinet_run_chunk", "storage")
	chunk.add_cell(0, 0, "cabinet", "cabinet", TRUE)
	chunk.add_cell(1, 0, "cabinet", "cabinet", TRUE)
	register_building_template_chunk(template_catalog, chunk)

	chunk = new /datum/world_edit_building_template_chunk("bed_run_chunk", "sleep")
	chunk.add_cell(0, 0, "bed", "bed", TRUE)
	chunk.add_cell(1, 0, "bed", "bed", TRUE)
	register_building_template_chunk(template_catalog, chunk)

	chunk = new /datum/world_edit_building_template_chunk("bed_niche_chunk", "sleep")
	chunk.add_cell(0, 0, "bed", "bed", TRUE)
	chunk.add_cell(1, 0, "cabinet", "cabinet", TRUE, FALSE)
	chunk.add_cell(0, 1, "chair", "chair", FALSE, FALSE)
	register_building_template_chunk(template_catalog, chunk)

	chunk = new /datum/world_edit_building_template_chunk("checkpoint_counter_chunk", "security")
	chunk.add_cell(0, 0, "table", "table", FALSE)
	chunk.add_cell(1, 0, "table", "table", FALSE)
	chunk.add_cell(0, 1, "security_console", "console", TRUE)
	chunk.add_cell(1, 1, "chair", "chair", FALSE, FALSE)
	register_building_template_chunk(template_catalog, chunk)

	chunk = new /datum/world_edit_building_template_chunk("hydro_rows_chunk", "hydroponics")
	chunk.add_cell(0, 0, "hydro_tray", "hydro_tray", FALSE)
	chunk.add_cell(1, 0, "hydro_tray", "hydro_tray", FALSE)
	chunk.add_cell(2, 0, "hydro_tray", "hydro_tray", FALSE)
	chunk.add_cell(0, 2, "hydro_tray", "hydro_tray", FALSE)
	chunk.add_cell(1, 2, "hydro_tray", "hydro_tray", FALSE)
	chunk.add_cell(2, 2, "hydro_tray", "hydro_tray", FALSE)
	register_building_template_chunk(template_catalog, chunk)

	chunk = new /datum/world_edit_building_template_chunk("cook_line_chunk", "kitchen")
	chunk.add_cell(0, 0, "fridge", "cold_storage", TRUE)
	chunk.add_cell(1, 0, "sink", "kitchen_machine", TRUE)
	chunk.add_cell(2, 0, "processor", "kitchen_machine", TRUE)
	chunk.add_cell(3, 0, "microwave", "kitchen_machine", TRUE)
	register_building_template_chunk(template_catalog, chunk)

	chunk = new /datum/world_edit_building_template_chunk("treatment_bay_chunk", "medbay")
	chunk.add_cell(0, 0, "sleeper", "medical_bed", FALSE)
	chunk.add_cell(1, 0, "medical_scanner", "medical_bed", FALSE)
	chunk.add_cell(0, 1, "medical_storage", "medical_storage", TRUE)
	chunk.add_cell(1, 1, "wall_monitor", "console", TRUE)
	register_building_template_chunk(template_catalog, chunk)

	chunk = new /datum/world_edit_building_template_chunk("office_suite_chunk", "office")
	chunk.add_cell(0, 0, "table", "table", FALSE)
	chunk.add_cell(0, 1, "chair", "chair", FALSE, FALSE)
	chunk.add_cell(1, 0, "console", "console", TRUE)
	chunk.add_cell(2, 0, "filing", "cabinet", TRUE)
	register_building_template_chunk(template_catalog, chunk)

	chunk = new /datum/world_edit_building_template_chunk("engineering_service_chunk", "engineering")
	chunk.add_cell(0, 0, "engineering_machine", "engineering_machine", TRUE)
	chunk.add_cell(1, 0, "power_console", "console", TRUE)
	chunk.add_cell(2, 0, "table", "table", TRUE)
	chunk.add_cell(3, 0, "rack", "rack", TRUE, FALSE)
	register_building_template_chunk(template_catalog, chunk)

	chunk = new /datum/world_edit_building_template_chunk("lab_bench_chunk", "laboratory")
	chunk.add_cell(0, 0, "table", "table", TRUE)
	chunk.add_cell(1, 0, "lab_machine", "lab_machine", TRUE)
	chunk.add_cell(2, 0, "sample_storage", "sample_storage", TRUE)
	chunk.add_cell(1, 1, "medical_scanner", "lab_machine", FALSE)
	register_building_template_chunk(template_catalog, chunk)

	chunk = new /datum/world_edit_building_template_chunk("infrastructure_light_chunk", "infrastructure")
	chunk.add_cell(0, 0, "light", "light", TRUE)
	chunk.add_cell(2, 0, "light", "light", TRUE)
	register_building_template_chunk(template_catalog, chunk)

	chunk = new /datum/world_edit_building_template_chunk("infrastructure_power_chunk", "infrastructure")
	chunk.add_cell(0, 0, "apc", "apc", TRUE)
	register_building_template_chunk(template_catalog, chunk)

	chunk = new /datum/world_edit_building_template_chunk("infrastructure_air_alarm_chunk", "infrastructure")
	chunk.add_cell(0, 0, "air_alarm", "air_alarm", TRUE)
	register_building_template_chunk(template_catalog, chunk)

	chunk = new /datum/world_edit_building_template_chunk("infrastructure_switch_chunk", "infrastructure")
	chunk.add_cell(0, 0, "light_switch", "light_switch", TRUE)
	register_building_template_chunk(template_catalog, chunk)

	chunk = new /datum/world_edit_building_template_chunk("infrastructure_fire_alarm_chunk", "infrastructure")
	chunk.add_cell(0, 0, "fire_alarm", "fire_alarm", TRUE)
	register_building_template_chunk(template_catalog, chunk)

	chunk = new /datum/world_edit_building_template_chunk("wall_fixture_chunk", "wall_object")
	chunk.add_cell(0, 0, "extinguisher", "wall_object", TRUE)
	register_building_template_chunk(template_catalog, chunk)

	chunk = new /datum/world_edit_building_template_chunk("wall_cabinet_chunk", "storage")
	chunk.add_cell(0, 0, "cabinet", "cabinet", TRUE)
	register_building_template_chunk(template_catalog, chunk)

	chunk = new /datum/world_edit_building_template_chunk("wall_rack_chunk", "storage")
	chunk.add_cell(0, 0, "rack", "rack", TRUE)
	register_building_template_chunk(template_catalog, chunk)

	chunk = new /datum/world_edit_building_template_chunk("wall_console_chunk", "console")
	chunk.add_cell(0, 0, "console", "console", TRUE)
	register_building_template_chunk(template_catalog, chunk)

	chunk = new /datum/world_edit_building_template_chunk("wall_toilet_chunk", "sanitation")
	chunk.add_cell(0, 0, "toilet", "sanitation", TRUE)
	register_building_template_chunk(template_catalog, chunk)

	chunk = new /datum/world_edit_building_template_chunk("wall_sink_chunk", "sanitation")
	chunk.add_cell(0, 0, "sink", "kitchen_machine", TRUE)
	register_building_template_chunk(template_catalog, chunk)

	chunk = new /datum/world_edit_building_template_chunk("clinic_bed_chunk", "medbay")
	chunk.add_cell(0, 0, "sleeper", "medical_bed", FALSE)
	chunk.add_cell(0, 1, "wall_monitor", "console", TRUE, FALSE)
	register_building_template_chunk(template_catalog, chunk)

	chunk = new /datum/world_edit_building_template_chunk("comms_console_chunk", "office")
	chunk.add_cell(0, 0, "console", "console", TRUE)
	register_building_template_chunk(template_catalog, chunk)

	chunk = new /datum/world_edit_building_template_chunk("island_table_chunk", "common")
	chunk.add_cell(0, 0, "table", "table", FALSE)
	chunk.add_cell(1, 0, "table", "table", FALSE)
	chunk.add_cell(0, 1, "chair", "chair", FALSE, FALSE)
	chunk.add_cell(1, 1, "chair", "chair", FALSE, FALSE)
	register_building_template_chunk(template_catalog, chunk)

	chunk = new /datum/world_edit_building_template_chunk("island_bed_chunk", "sleep")
	chunk.add_cell(0, 0, "bed", "bed", FALSE)
	chunk.add_cell(1, 0, "bed", "bed", FALSE)
	chunk.add_cell(0, 1, "cabinet", "cabinet", FALSE, FALSE)
	register_building_template_chunk(template_catalog, chunk)

	chunk = new /datum/world_edit_building_template_chunk("office_private_storage_chunk", "storage")
	chunk.add_cell(0, 0, "rack", "rack", TRUE)
	register_building_template_chunk(template_catalog, chunk)

	chunk = new /datum/world_edit_building_template_chunk("office_records_terminal_chunk", "console")
	chunk.add_cell(0, 0, "console", "console", TRUE)
	register_building_template_chunk(template_catalog, chunk)

	chunk = new /datum/world_edit_building_template_chunk("holding_cell_chunk", "sleep")
	chunk.add_cell(0, 0, "bed", "bed", TRUE)
	register_building_template_chunk(template_catalog, chunk)

	chunk = new /datum/world_edit_building_template_chunk("armory_rack_chunk", "storage")
	chunk.add_cell(0, 0, "weapon_rack", "weapon_rack", TRUE)
	register_building_template_chunk(template_catalog, chunk)

	chunk = new /datum/world_edit_building_template_chunk("evidence_storage_chunk", "storage")
	chunk.add_cell(0, 0, "cabinet", "cabinet", TRUE)
	register_building_template_chunk(template_catalog, chunk)

	chunk = new /datum/world_edit_building_template_chunk("surgery_bed_chunk", "medbay")
	chunk.add_cell(0, 0, "medical_bed", "medical_bed", FALSE)
	register_building_template_chunk(template_catalog, chunk)

	chunk = new /datum/world_edit_building_template_chunk("cryo_sleeper_chunk", "medbay")
	chunk.add_cell(0, 0, "sleeper", "medical_bed", TRUE)
	register_building_template_chunk(template_catalog, chunk)

	chunk = new /datum/world_edit_building_template_chunk("chem_storage_chunk", "medbay")
	chunk.add_cell(0, 0, "water_tank", "water_or_chem", TRUE)
	register_building_template_chunk(template_catalog, chunk)

	chunk = new /datum/world_edit_building_template_chunk("morgue_storage_chunk", "medbay")
	chunk.add_cell(0, 0, "medical_storage", "medical_storage", TRUE)
	register_building_template_chunk(template_catalog, chunk)

	chunk = new /datum/world_edit_building_template_chunk("command_console_chunk", "office")
	chunk.add_cell(0, 0, "console", "console", TRUE)
	register_building_template_chunk(template_catalog, chunk)

	return template_catalog

/datum/world_edit_generator/building_layout/proc/get_building_template_chunk(template_chunk_id)
	var/list/catalog = get_building_template_chunk_catalog()
	return catalog["[template_chunk_id]"]

/datum/world_edit_generator/building_layout/proc/get_template_offset_turf(turf/anchor_turf, dir_to_use, dx, dy)
	if(!istype(anchor_turf))
		return null
	var/turf/result = anchor_turf
	var/right_dir = turn(dir_to_use || SOUTH, 90)
	var/forward_dir = dir_to_use || SOUTH
	var/x_steps = abs(round(text2num("[dx]") || 0))
	for(var/step_index in 1 to x_steps)
		result = get_step(result, dx >= 0 ? right_dir : turn(right_dir, 180))
	var/y_steps = abs(round(text2num("[dy]") || 0))
	for(var/step_index in 1 to y_steps)
		result = get_step(result, dy >= 0 ? forward_dir : turn(forward_dir, 180))
	return result

/datum/world_edit_generator/building_layout/proc/can_place_building_template_chunk_at(datum/world_edit_building_layout_state/state, datum/world_edit_building_cluster_spec/cluster_spec, datum/world_edit_building_template_chunk/chunk, turf/anchor_turf, dir_to_use, wall_dir)
	if(!istype(state) || !istype(cluster_spec) || !istype(chunk) || !istype(anchor_turf))
		return FALSE
	var/requirement_id = get_building_cluster_requirement_id(cluster_spec)
	var/list/planned_lookup = list()
	for(var/datum/world_edit_building_template_cell/cell as anything in chunk.cells)
		if(!istype(cell))
			continue
		var/turf/cell_turf = get_template_offset_turf(anchor_turf, dir_to_use, cell.dx, cell.dy)
		var/owner = state.get_semantic_slot_owner(cell_turf)
		if(length(owner) && owner != requirement_id)
			return FALSE
		if(!state.can_place_fixture(cell_turf) || planned_lookup[cell_turf])
			return FALSE
		if(!building_fixture_matches_semantic_zone_contract(state, cell_turf, cell.slot, cell.category, cluster_spec))
			return FALSE
		var/list/cell_context = resolve_template_cell_context(state, cell_turf, cell, dir_to_use, wall_dir, cluster_spec)
		if(!islist(cell_context))
			return FALSE
		planned_lookup[cell_turf] = TRUE
	return TRUE

/datum/world_edit_generator/building_layout/proc/build_template_chunk_candidate_turfs(datum/world_edit_building_layout_state/state, datum/world_edit_building_cluster_spec/cluster_spec, datum/world_edit_building_template_chunk/chunk, list/anchor_override = null)
	var/list/candidates = list()
	var/list/candidate_scores = list()
	if(!istype(state) || !istype(cluster_spec) || !istype(chunk))
		return list("turfs" = candidates, "scores" = candidate_scores)
	var/list/anchor_ids = islist(anchor_override) ? anchor_override : get_cluster_preflight_anchor_ids(state, cluster_spec, cluster_spec.anchors)
	var/requirement_id = get_building_cluster_requirement_id(cluster_spec)
	for(var/turf/floor_turf as anything in get_fixture_candidate_turfs_for_anchors(state, anchor_ids))
		var/owner = state.get_semantic_slot_owner(floor_turf)
		if(length(owner) && owner != requirement_id)
			continue
		if(!state.can_place_fixture(floor_turf))
			continue
		if(!fixture_turf_matches_anchor(state, floor_turf, anchor_ids))
			continue
		var/datum/world_edit_building_place_rule/place_rule = resolve_building_place_rule(cluster_spec.slot, cluster_spec.category)
		var/effective_needs_wall = cluster_spec.wall_required || place_rule.needs_wall
		var/fallback_dir = get_cardinal_dir_toward(floor_turf, state.semantic_hub_turf || state.center_turf, SOUTH)
		var/list/place_context = build_building_fixture_place_context(state, floor_turf, place_rule, fallback_dir, effective_needs_wall, cluster_spec, anchor_ids)
		if(!islist(place_context))
			continue
		if(!can_place_building_template_chunk_at(state, cluster_spec, chunk, floor_turf, place_context["dir"] || fallback_dir, place_context["wall_dir"]))
			continue
		var/score = score_fixture_turf(state, floor_turf, anchor_ids, effective_needs_wall, cluster_spec, place_rule)
		if(cluster_turf_is_preflight_planned(state, cluster_spec, floor_turf))
			score += 5000
		score += length(chunk.cells) * 35
		candidates += floor_turf
		candidate_scores[floor_turf] = score
	return list("turfs" = candidates, "scores" = candidate_scores)

/datum/world_edit_generator/building_layout/proc/select_best_template_candidate(list/candidates, list/candidate_scores)
	var/turf/best_turf = null
	var/best_score = -999999999
	for(var/turf/candidate as anything in candidates)
		if(!istype(candidate))
			continue
		var/score = round(text2num("[candidate_scores[candidate]]") || 0)
		if(!istype(best_turf) || score > best_score)
			best_turf = candidate
			best_score = score
	return best_turf

/datum/world_edit_generator/building_layout/proc/resolve_template_cell_context(datum/world_edit_building_layout_state/state, turf/cell_turf, datum/world_edit_building_template_cell/cell, dir_to_use, wall_dir, datum/world_edit_building_cluster_spec/cluster_spec)
	var/datum/world_edit_building_place_rule/place_rule = resolve_building_place_rule(cell.slot, cell.category)
	var/needs_wall = cell.wall_required || cluster_spec.wall_required || place_rule.needs_wall
	var/cell_wall_dir = wall_dir
	if(needs_wall && (isnull(cell_wall_dir) || !state.wall_lookup[get_step(cell_turf, cell_wall_dir)]))
		var/list/wall_context = build_building_fixture_wall_context(state, cell_turf, place_rule, cluster_spec, cluster_spec?.anchors)
		if(!islist(wall_context))
			cell_wall_dir = null
		else
			cell_wall_dir = wall_context["wall_dir"]
			var/context_dir = wall_context["dir"]
			if(building_place_rule_allows_turf(state, cell_turf, place_rule, context_dir, cell_wall_dir))
				return list("rule" = place_rule, "dir" = context_dir, "wall_dir" = cell_wall_dir, "wall_mounted" = TRUE, "dir_source" = wall_context["dir_source"])
	if(needs_wall && isnull(cell_wall_dir))
		return null
	var/cell_dir = !isnull(cell_wall_dir) ? resolve_building_place_rule_dir(cell_wall_dir, place_rule.dir_mode) : dir_to_use
	if(!building_place_rule_allows_turf(state, cell_turf, place_rule, cell_dir, cell_wall_dir))
		return null
	return list("rule" = place_rule, "dir" = cell_dir, "wall_dir" = cell_wall_dir, "wall_mounted" = needs_wall, "dir_source" = needs_wall ? "template_wall" : "template_parent")

/datum/world_edit_generator/building_layout/proc/try_place_building_template_chunk_at(datum/world_edit_building_layout_state/state, datum/world_edit_building_cluster_spec/cluster_spec, datum/world_edit_building_template_chunk/chunk, turf/anchor_turf, dir_to_use, wall_dir, major)
	if(!istype(state) || !istype(cluster_spec) || !istype(chunk) || !istype(anchor_turf))
		return 0
	var/requirement_id = get_building_cluster_requirement_id(cluster_spec)
	var/list/planned_cells = list()
	var/list/planned_lookup = list()
	for(var/datum/world_edit_building_template_cell/cell as anything in chunk.cells)
		if(!istype(cell))
			continue
		var/turf/cell_turf = get_template_offset_turf(anchor_turf, dir_to_use, cell.dx, cell.dy)
		var/owner = state.get_semantic_slot_owner(cell_turf)
		if(length(owner) && owner != requirement_id)
			return 0
		if(!state.can_place_fixture(cell_turf) || planned_lookup[cell_turf])
			return 0
		if(!building_fixture_matches_semantic_zone_contract(state, cell_turf, cell.slot, cell.category, cluster_spec))
			return 0
		var/list/cell_context = resolve_template_cell_context(state, cell_turf, cell, dir_to_use, wall_dir, cluster_spec)
		if(!islist(cell_context))
			return 0
		planned_lookup[cell_turf] = TRUE
		planned_cells += list(list("cell" = cell, "turf" = cell_turf, "context" = cell_context))
	if(!length(planned_cells))
		return 0
	var/placed = 0
	var/credit_count = 0
	var/list/covered_turfs = list()
	var/template_chunk_instance_id = "[chunk.id]@[anchor_turf.x],[anchor_turf.y],[anchor_turf.z]/[dir_to_use]/[state.template_chunk_count + 1]"
	for(var/list/planned as anything in planned_cells)
		var/datum/world_edit_building_template_cell/cell = planned["cell"]
		var/turf/cell_turf = planned["turf"]
		var/list/context = planned["context"]
		if(!place_fixture_at(state, cell_turf, cell.slot, context["dir"], cell.category, major && cell.major && placed <= 0, context["wall_mounted"], context["rule"], context["wall_dir"], cluster_spec, chunk.id, template_chunk_instance_id, context["dir_source"]))
			for(var/turf/rollback_turf as anything in covered_turfs)
				state.remove_fixture_at(rollback_turf)
			return 0
		covered_turfs += cell_turf
		placed++
		credit_count += get_building_fixture_count_credit(cluster_spec, cell.slot, cell.category)
	if(placed > 0)
		state.template_chunk_count++
		state.template_chunk_cell_count += placed
		state.register_layout_macro(chunk.id, chunk.category, anchor_turf, dir_to_use, covered_turfs, list(cluster_spec.id))
	return credit_count

/datum/world_edit_generator/building_layout/proc/place_building_template_chunk_for_cluster(datum/world_edit_building_layout_state/state, datum/world_edit_building_cluster_spec/cluster_spec, major)
	if(!istype(state) || !istype(cluster_spec) || !length(cluster_spec.macro_id))
		return 0
	var/datum/world_edit_building_template_chunk/chunk = get_building_template_chunk(cluster_spec.macro_id)
	if(!istype(chunk) || !length(chunk.cells))
		return 0
	var/list/candidate_data = build_template_chunk_candidate_turfs(state, cluster_spec, chunk)
	var/list/candidates = candidate_data["turfs"]
	var/list/candidate_scores = candidate_data["scores"]
	var/attempts = 0
	while(length(candidates) && attempts < 10)
		attempts++
		var/turf/anchor_turf = select_best_template_candidate(candidates, candidate_scores)
		if(!istype(anchor_turf))
			break
		candidates -= anchor_turf
		var/datum/world_edit_building_place_rule/place_rule = resolve_building_place_rule(cluster_spec.slot, cluster_spec.category)
		var/fallback_dir = get_cardinal_dir_toward(anchor_turf, state.semantic_hub_turf || state.center_turf, SOUTH)
		var/list/place_context = build_building_fixture_place_context(state, anchor_turf, place_rule, fallback_dir, cluster_spec.wall_required || place_rule.needs_wall, cluster_spec, cluster_spec.anchors)
		if(!islist(place_context))
			continue
		var/placed = try_place_building_template_chunk_at(state, cluster_spec, chunk, anchor_turf, place_context["dir"] || fallback_dir, place_context["wall_dir"], major)
		if(placed > 0)
			return placed
	return 0
