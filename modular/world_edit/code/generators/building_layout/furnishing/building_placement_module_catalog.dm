/datum/world_edit_building_placement_module
	var/id = ""
	var/label = ""
	var/phase = "major"
	var/list/allowed_programs = list()
	var/list/allowed_zone_ids = list()
	var/list/allowed_room_roles = list()
	var/list/source_cluster_ids = list()
	var/list/source_signature_ids = list()
	var/list/source_macro_ids = list()
	var/list/required_provider_slots = list()
	var/list/occupied_offsets = list()
	var/list/clearance_offsets = list()
	var/list/member_specs = list()
	var/repeat_group = ""
	var/max_per_room = 1
	var/max_per_building = 999
	var/priority = 50
	var/wall_required = FALSE
	var/pattern = "single_floor"

/datum/world_edit_building_placement_module_catalog
	var/list/modules_by_id = list()
	var/list/modules_by_cluster_id = list()
	var/list/modules_by_signature_id = list()
	var/list/modules_by_macro_id = list()

/datum/world_edit_building_placement_module_catalog/proc/register_module(datum/world_edit_building_placement_module/module)
	if(!istype(module) || !length(module.id))
		return
	modules_by_id[module.id] = module
	for(var/cluster_id as anything in module.source_cluster_ids)
		if(!islist(modules_by_cluster_id["[cluster_id]"]))
			modules_by_cluster_id["[cluster_id]"] = list()
		modules_by_cluster_id["[cluster_id]"] += module
	for(var/signature_id as anything in module.source_signature_ids)
		if(!islist(modules_by_signature_id["[signature_id]"]))
			modules_by_signature_id["[signature_id]"] = list()
		modules_by_signature_id["[signature_id]"] += module
	for(var/macro_id as anything in module.source_macro_ids)
		if(!islist(modules_by_macro_id["[macro_id]"]))
			modules_by_macro_id["[macro_id]"] = list()
		modules_by_macro_id["[macro_id]"] += module

/datum/world_edit_building_placement_module_catalog/proc/has_module(module_id)
	return istype(modules_by_id["[module_id]"], /datum/world_edit_building_placement_module)

/datum/world_edit_building_placement_module_catalog/proc/get_for_cluster(datum/world_edit_building_cluster_spec/cluster_spec)
	var/list/result = list()
	var/list/seen = list()
	if(!istype(cluster_spec))
		return result
	for(var/source_list as anything in list(modules_by_cluster_id["[cluster_spec.id]"], modules_by_signature_id["[cluster_spec.signature_id]"], modules_by_macro_id["[cluster_spec.macro_id]"]))
		if(!islist(source_list))
			continue
		for(var/datum/world_edit_building_placement_module/module as anything in source_list)
			if(!istype(module) || seen[module.id])
				continue
			seen[module.id] = TRUE
			result += module
	return result

/datum/world_edit_generator/building_layout/proc/get_building_placement_module_catalog()
	if(istype(GLOB.world_edit_building_placement_module_catalog, /datum/world_edit_building_placement_module_catalog))
		return GLOB.world_edit_building_placement_module_catalog
	var/datum/world_edit_building_placement_module_catalog/catalog = new
	var/list/archetypes = get_building_archetype_catalog()
	for(var/program_id as anything in archetypes)
		var/datum/world_edit_building_archetype/archetype = archetypes[program_id]
		if(!istype(archetype))
			continue
		for(var/datum/world_edit_building_cluster_spec/cluster_spec as anything in archetype.cluster_specs)
			if(!istype(cluster_spec) || !is_building_semantic_furniture_slot(cluster_spec.slot, cluster_spec.category))
				continue
			register_building_modules_for_cluster(catalog, archetype, cluster_spec)
	GLOB.world_edit_building_placement_module_catalog = catalog
	return catalog

/datum/world_edit_generator/building_layout/proc/register_building_modules_for_cluster(datum/world_edit_building_placement_module_catalog/catalog, datum/world_edit_building_archetype/archetype, datum/world_edit_building_cluster_spec/cluster_spec)
	var/list/variants = list("base")
	if(cluster_spec.max_count > 1 || cluster_spec.chair_count > 0 || cluster_spec.pattern in list("run", "counter_line", "staging_group"))
		variants += "run"
	if(cluster_spec.pattern == "table_cluster" && cluster_spec.chair_count > 1)
		variants += "compact"
	if(cluster_spec.phase != "major" || !cluster_spec.required)
		variants += "detail"
	for(var/variant as anything in variants)
		var/datum/world_edit_building_placement_module/module = build_building_module_from_cluster(archetype, cluster_spec, variant)
		catalog.register_module(module)

/datum/world_edit_generator/building_layout/proc/build_building_module_from_cluster(datum/world_edit_building_archetype/archetype, datum/world_edit_building_cluster_spec/cluster_spec, variant)
	var/datum/world_edit_building_placement_module/module = new
	module.id = "[archetype.id]__[cluster_spec.id]__[variant]"
	module.label = "[archetype.id] [cluster_spec.id] [variant]"
	module.phase = cluster_spec.phase
	module.allowed_programs = list(archetype.id)
	module.allowed_zone_ids = build_building_module_allowed_zones(archetype, cluster_spec)
	module.allowed_room_roles = build_building_module_allowed_roles(archetype, module.allowed_zone_ids)
	module.source_cluster_ids = list(cluster_spec.id)
	if(length(cluster_spec.signature_id))
		module.source_signature_ids = list(cluster_spec.signature_id)
	if(length(cluster_spec.macro_id))
		module.source_macro_ids = list(cluster_spec.macro_id)
	module.required_provider_slots = list(cluster_spec.slot)
	module.repeat_group = length(cluster_spec.signature_id) ? cluster_spec.signature_id : cluster_spec.category
	module.max_per_room = max(cluster_spec.max_count, 1)
	module.max_per_building = max(cluster_spec.max_count, 1)
	module.priority = cluster_spec.priority
	module.wall_required = cluster_spec.wall_required
	module.pattern = cluster_spec.pattern
	build_building_module_member_specs(module, cluster_spec, variant)
	return module

/datum/world_edit_generator/building_layout/proc/build_building_module_allowed_zones(datum/world_edit_building_archetype/archetype, datum/world_edit_building_cluster_spec/cluster_spec)
	var/list/zones = list()
	var/list/seen = list()
	for(var/anchor_id as anything in cluster_spec.anchors)
		var/datum/world_edit_building_zone_spec/zone_spec = archetype.zone_specs_by_id["[anchor_id]"]
		if(istype(zone_spec) && !seen[zone_spec.id])
			zones += zone_spec.id
			seen[zone_spec.id] = TRUE
	if(!length(zones))
		switch("[cluster_spec.slot]")
			if("bed")
				for(var/zone_id in list("sleep_privacy", "sleep_bay", "living_wing", "holding_nook"))
					if(archetype.zone_specs_by_id[zone_id] && !seen[zone_id])
						zones += zone_id
						seen[zone_id] = TRUE
			if("toilet", "sink")
				if(archetype.zone_specs_by_id["sanitation"])
					zones += "sanitation"
			if("medical_bed", "medical_storage", "sleeper", "medical_scanner", "wall_monitor")
				for(var/zone_id in list("treatment", "med_storage", "clinic_nook", "surgery_core", "cryo_bay", "treatment_wall", "treatment_bay"))
					if(archetype.zone_specs_by_id[zone_id] && !seen[zone_id])
						zones += zone_id
						seen[zone_id] = TRUE
			if("hydro_tray", "seed_storage")
				for(var/zone_id in list("grow_rows", "seed_storage", "greenhouse_band"))
					if(archetype.zone_specs_by_id[zone_id] && !seen[zone_id])
						zones += zone_id
						seen[zone_id] = TRUE
			if("weapon_rack", "security_console", "security_camera", "brig_cell")
				for(var/zone_id in list("armory_nook", "secure_storage", "secure_side", "locker_storage", "public_lobby"))
					if(archetype.zone_specs_by_id[zone_id] && !seen[zone_id])
						zones += zone_id
						seen[zone_id] = TRUE
	return zones

/datum/world_edit_generator/building_layout/proc/build_building_module_allowed_roles(datum/world_edit_building_archetype/archetype, list/zone_ids)
	var/list/roles = list()
	var/list/seen = list()
	for(var/zone_id as anything in zone_ids)
		var/datum/world_edit_building_zone_spec/zone_spec = archetype.zone_specs_by_id["[zone_id]"]
		if(!istype(zone_spec) || !length(zone_spec.role) || seen[zone_spec.role])
			continue
		roles += zone_spec.role
		seen[zone_spec.role] = TRUE
	return roles

/datum/world_edit_generator/building_layout/proc/add_building_module_member(datum/world_edit_building_placement_module/module, slot, category, dx, dy, major = TRUE)
	module.member_specs += list(list("slot" = "[slot]", "category" = "[category]", "dx" = round(dx), "dy" = round(dy), "major" = major ? TRUE : FALSE))
	module.occupied_offsets += list("[round(dx)],[round(dy)]")

/datum/world_edit_generator/building_layout/proc/add_building_module_clearance(datum/world_edit_building_placement_module/module, dx, dy)
	var/key = "[round(dx)],[round(dy)]"
	if(!(key in module.clearance_offsets))
		module.clearance_offsets += key

/datum/world_edit_generator/building_layout/proc/build_building_module_member_specs(datum/world_edit_building_placement_module/module, datum/world_edit_building_cluster_spec/cluster_spec, variant)
	if(cluster_spec.pattern == "table_cluster")
		add_building_module_member(module, cluster_spec.slot, cluster_spec.category, 0, 0, TRUE)
		var/chairs = clamp(cluster_spec.chair_count, 0, 4)
		if(variant == "compact")
			chairs = min(chairs, 1)
		var/list/chair_offsets = list(list(0, 1), list(0, -1), list(1, 0), list(-1, 0))
		for(var/index in 1 to chairs)
			var/list/offset = chair_offsets[index]
			add_building_module_member(module, "chair", "chair", offset[1], offset[2], FALSE)
	else if(cluster_spec.pattern == "paired_object")
		add_building_module_member(module, cluster_spec.slot, cluster_spec.category, 0, 0, TRUE)
		add_building_module_member(module, cluster_spec.slot, cluster_spec.category, 1, 0, FALSE)
	else if(cluster_spec.pattern in list("run", "counter_line", "staging_group") && variant == "run")
		add_building_module_member(module, cluster_spec.slot, cluster_spec.category, 0, 0, TRUE)
		add_building_module_member(module, cluster_spec.slot, cluster_spec.category, 1, 0, FALSE)
	else
		add_building_module_member(module, cluster_spec.slot, cluster_spec.category, 0, 0, TRUE)
	if(module.wall_required)
		return
	for(var/list/member as anything in module.member_specs)
		var/dx = round(text2num("[member["dx"]]") || 0)
		var/dy = round(text2num("[member["dy"]]") || 0)
		for(var/list/nearby in list(list(dx + 1, dy), list(dx - 1, dy), list(dx, dy + 1), list(dx, dy - 1)))
			add_building_module_clearance(module, nearby[1], nearby[2])

/datum/world_edit_generator/building_layout/proc/is_building_semantic_furniture_slot(slot, category = null)
	var/slot_key = "[slot]"
	var/category_key = "[category]"
	if(slot_key in list("light", "apc", "air_alarm", "fire_alarm", "light_switch"))
		return FALSE
	if(slot_key in list("table", "chair", "bed", "toilet", "sink", "medical_bed", "medical_storage", "sleeper", "medical_scanner", "wall_monitor", "hydro_tray", "seed_storage", "weapon_rack", "security_console", "security_camera", "brig_cell", "cabinet", "rack", "crate", "console", "filing", "fridge", "microwave", "processor", "water_tank", "engineering_machine", "power_console", "lab_machine", "sample_storage", "barrier"))
		return TRUE
	return category_key in list("table", "chair", "bed", "sanitation", "medical_bed", "medical_storage", "hydro_tray", "weapon_rack", "rack", "cabinet", "crate", "console", "barrier")

/datum/world_edit_generator/building_layout/proc/place_building_modules_for_cluster(datum/world_edit_building_layout_state/state, datum/world_edit_building_cluster_spec/cluster_spec, major)
	if(!istype(state) || !istype(cluster_spec))
		return 0
	if(cluster_spec.slot == "chair" && !cluster_spec.required)
		state.add_warning("Optional chair-only cluster '[cluster_spec.id]' skipped to avoid loose chair placement.")
		return 0
	var/datum/world_edit_building_placement_module_catalog/catalog = get_building_placement_module_catalog()
	var/list/modules = catalog.get_for_cluster(cluster_spec)
	if(!length(modules))
		if(cluster_spec.required)
			state.validation.required_module_missing_count++
			state.add_error("Required cluster '[cluster_spec.id]' has no placement module mapping.")
		else
			state.validation.optional_module_missing_count++
			state.add_warning("Optional cluster '[cluster_spec.id]' has no placement module mapping and was skipped.")
		return 0
	var/target_count = get_scaled_cluster_target_count(state, cluster_spec)
	var/effective_minimum = get_effective_cluster_min_count(state, cluster_spec)
	var/requirement_id = get_building_cluster_requirement_id(cluster_spec)
	var/already_placed = get_building_placed_requirement_count(state, requirement_id, cluster_spec.id, cluster_spec.signature_id)
	var/placed_credit = 0
	var/attempts = 0
	while(already_placed + placed_credit < max(target_count, effective_minimum) && attempts < WORLD_EDIT_BUILDING_MAX_CLUSTER_STEPS && state.fixtures.fixture_count < WORLD_EDIT_BUILDING_MAX_FIXTURE_OBJECTS)
		attempts++
		var/list/best_candidate = find_best_building_module_candidate(state, cluster_spec, modules)
		if(!islist(best_candidate))
			break
		var/placed_now = commit_building_module_candidate(state, cluster_spec, best_candidate, major && placed_credit <= 0)
		if(placed_now <= 0)
			break
		placed_credit += placed_now
	if(cluster_spec.required && effective_minimum > 0 && already_placed + placed_credit < effective_minimum)
		state.validation.required_module_not_placeable_count++
		state.add_warning("Required cluster '[cluster_spec.id]' module placement produced [already_placed + placed_credit], needs [effective_minimum].")
	return placed_credit

/datum/world_edit_generator/building_layout/proc/find_best_building_module_candidate(datum/world_edit_building_layout_state/state, datum/world_edit_building_cluster_spec/cluster_spec, list/modules)
	var/list/best_candidates = list()
	var/best_score = -999999999
	for(var/datum/world_edit_building_placement_module/module as anything in modules)
		if(!istype(module))
			continue
		for(var/datum/world_edit_building_room/room as anything in state.geometry.solved_rooms)
			if(!building_module_allowed_in_room(state, module, room))
				continue
			for(var/turf/origin as anything in room.turfs)
				for(var/dir_to_use as anything in GLOB.cardinals)
					var/list/candidate = build_building_module_candidate(state, cluster_spec, module, room, origin, dir_to_use)
					if(!islist(candidate))
						continue
					var/score = round(text2num("[candidate["score"]]") || 0)
					if(score > best_score)
						best_score = score
						best_candidates.Cut()
						best_candidates += list(candidate)
					else if(score == best_score)
						best_candidates += list(candidate)
	if(!length(best_candidates))
		return null
	return state.request.fixture_rng.pick_from(best_candidates)

/datum/world_edit_generator/building_layout/proc/building_module_allowed_in_room(datum/world_edit_building_layout_state/state, datum/world_edit_building_placement_module/module, datum/world_edit_building_room/room)
	if(!istype(state) || !istype(module) || !istype(room))
		return FALSE
	if(length(module.allowed_programs) && !(state.archetype?.id in module.allowed_programs))
		return FALSE
	var/zone_id = "[room.zone_id]"
	var/datum/world_edit_building_zone_spec/zone_spec = state.semantic_plan?.get_zone_spec(zone_id)
	var/role = "[zone_spec?.role || ""]"
	if(length(module.allowed_zone_ids) && !(zone_id in module.allowed_zone_ids))
		return FALSE
	if(length(module.allowed_room_roles) && length(role) && !(role in module.allowed_room_roles))
		return FALSE
	return TRUE

/datum/world_edit_generator/building_layout/proc/build_building_module_candidate(datum/world_edit_building_layout_state/state, datum/world_edit_building_cluster_spec/cluster_spec, datum/world_edit_building_placement_module/module, datum/world_edit_building_room/room, turf/origin, dir_to_use)
	if(!istype(state) || !istype(module) || !istype(room) || !istype(origin))
		return null
	var/requirement_id = get_building_cluster_requirement_id(cluster_spec)
	var/list/member_plans = list()
	var/list/occupied_lookup = list()
	var/list/occupied_turfs = list()
	for(var/list/member as anything in module.member_specs)
		var/turf/member_turf = get_template_offset_turf(origin, dir_to_use, member["dx"], member["dy"])
		if(!istype(member_turf) || occupied_lookup[member_turf])
			return null
		if(!(member_turf in room.turfs))
			return null
		var/semantic_owner = state.get_semantic_slot_owner(member_turf)
		if(length(semantic_owner) && semantic_owner != requirement_id)
			return null
		var/allow_owned_reserved = length(semantic_owner) && semantic_owner == requirement_id
		if(!state.can_place_fixture(member_turf, allow_owned_reserved))
			return null
		var/slot = "[member["slot"]]"
		var/category = "[member["category"]]"
		if(!building_fixture_matches_semantic_zone_contract(state, member_turf, slot, category, cluster_spec))
			return null
		var/datum/world_edit_building_place_rule/place_rule = resolve_building_place_rule(slot, category)
		var/needs_wall = member["wall_required"] || module.wall_required || get_cluster_effective_needs_wall(state, cluster_spec, place_rule)
		var/fallback_dir = get_cardinal_dir_toward(member_turf, state.geometry.semantic_hub_turf || state.geometry.center_turf, dir_to_use)
		var/list/place_context = build_building_fixture_place_context(state, member_turf, place_rule, fallback_dir, needs_wall, cluster_spec, cluster_spec.anchors)
		if(!islist(place_context))
			return null
		occupied_lookup[member_turf] = TRUE
		occupied_turfs += member_turf
		member_plans += list(list(
			"slot" = slot,
			"category" = category,
			"turf" = member_turf,
			"place_rule" = place_rule,
			"dir" = place_context["dir"] || fallback_dir,
			"wall_dir" = place_context["wall_dir"],
			"wall_mounted" = place_context["wall_mounted"],
			"dir_source" = place_context["dir_source"],
			"allow_reserved" = allow_owned_reserved ? TRUE : FALSE,
			"major" = member["major"] ? TRUE : FALSE,
		))
	for(var/offset_key as anything in module.clearance_offsets)
		var/list/parts = splittext("[offset_key]", ",")
		if(length(parts) < 2)
			continue
		var/turf/clearance_turf = get_template_offset_turf(origin, dir_to_use, text2num(parts[1]), text2num(parts[2]))
		if(!istype(clearance_turf) || occupied_lookup[clearance_turf])
			continue
		if(state.geometry.wall_lookup[clearance_turf] || state.geometry.door_dirs[clearance_turf] || state.fixtures.fixture_lookup[clearance_turf] || state.geometry.reserved_lookup[clearance_turf] || state.has_anchor("door_cone", clearance_turf))
			return null
	var/score = module.priority + score_fixture_turf(state, origin, cluster_spec.anchors, module.wall_required, cluster_spec)
	if(state.has_anchor("focus_center", origin))
		score += 100
	return list("module" = module, "room" = room, "origin" = origin, "dir" = dir_to_use, "members" = member_plans, "occupied_turfs" = occupied_turfs, "score" = score)

/datum/world_edit_generator/building_layout/proc/commit_building_module_candidate(datum/world_edit_building_layout_state/state, datum/world_edit_building_cluster_spec/cluster_spec, list/candidate, major)
	var/datum/world_edit_building_placement_module/module = candidate["module"]
	var/list/members = candidate["members"]
	if(!istype(module) || !length(members))
		return 0
	var/module_instance_id = "[module.id]#[state.fixtures.module_instance_count + 1]"
	var/placed_credit = 0
	var/placed_members = 0
	for(var/list/member as anything in members)
		var/turf/member_turf = member["turf"]
		if(!place_fixture_at(state, member_turf, member["slot"], member["dir"], member["category"], major && member["major"] && placed_members <= 0, member["wall_mounted"], member["place_rule"], member["wall_dir"], cluster_spec, null, null, member["dir_source"], member["allow_reserved"], module.id, module_instance_id, length(members)))
			state.remove_module_instance(module_instance_id)
			return 0
		placed_members++
		placed_credit += get_building_fixture_count_credit(cluster_spec, member["slot"], member["category"])
	if(placed_members != length(members))
		state.remove_module_instance(module_instance_id)
		return 0
	state.register_module_instance(module.id, module_instance_id, length(members))
	return placed_credit
