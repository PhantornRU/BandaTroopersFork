#define WORLD_EDIT_BUILDING_MAX_LAYOUT_CANDIDATES 24
#define WORLD_EDIT_BUILDING_MAX_ROOM_CANDIDATES 128
#define WORLD_EDIT_BUILDING_MAX_ROUTE_EXPANSIONS 4096
#define WORLD_EDIT_BUILDING_MAX_MODULE_ANCHORS 64
#define WORLD_EDIT_BUILDING_MAX_MODULE_CANDIDATES 32

/datum/world_edit_generator/building_layout/proc/build_building_layout_program_contract(datum/world_edit_building_layout_state/state)
	if(!istype(state) || !istype(state.archetype) || !istype(state.semantic_plan))
		return null
	var/datum/world_edit_building_layout_program_contract/program = new
	program.id = state.archetype.id
	program.allowed_layout_patterns = list("adaptive_axis", "adaptive_cross_axis")
	program.max_layout_candidates = WORLD_EDIT_BUILDING_MAX_LAYOUT_CANDIDATES
	var/list/selected_zone_specs = select_building_layout_room_zone_specs(state)
	if(!islist(selected_zone_specs) || !length(selected_zone_specs))
		state.add_error("Program contract '[program.id]' has no active room zones.")
		return null
	var/target_room_count = round(text2num("[state.config["target_room_count"]]") || 0)
	if(target_room_count <= 0)
		target_room_count = length(selected_zone_specs)
	var/required_zone_count = 0
	for(var/datum/world_edit_building_zone_spec/required_zone as anything in selected_zone_specs)
		if(istype(required_zone) && required_zone.required)
			required_zone_count++
	if(target_room_count < required_zone_count)
		state.add_error("program.target_room_count_unreachable: requested [target_room_count], required [required_zone_count].")
		return null
	program.target_room_count = target_room_count
	var/list/room_zone_demands = build_building_layout_room_zone_demands(state, selected_zone_specs, target_room_count)
	if(length(room_zone_demands) != target_room_count)
		state.add_error("program.target_room_count_unreachable: requested [target_room_count], allocated [length(room_zone_demands)].")
		return null
	var/list/zone_instance_counts = list()
	for(var/datum/world_edit_building_zone_spec/zone_spec as anything in room_zone_demands)
		if(!istype(zone_spec))
			continue
		var/instance_index = round(text2num("[zone_instance_counts[zone_spec.id]]") || 0) + 1
		zone_instance_counts[zone_spec.id] = instance_index
		var/datum/world_edit_building_layout_room_contract/room_contract = compile_building_layout_room_contract(state, zone_spec, instance_index, target_room_count)
		if(istype(room_contract))
			program.add_room_contract(room_contract)
	if(length(program.room_contracts) != target_room_count)
		state.add_error("program.target_room_count_unreachable: compiled [length(program.room_contracts)] of [target_room_count] room contracts.")
		return null
	compile_building_layout_connection_contracts(state, program)
	compile_building_layout_scene_contracts(state, program)
	for(var/category as anything in state.semantic_plan.object_budgets)
		if(!is_building_infrastructure_category(category))
			program.global_scene_slot_limits["[category]"] = state.semantic_plan.object_budgets[category]
	return program

/datum/world_edit_generator/building_layout/proc/select_building_layout_room_zone_specs(datum/world_edit_building_layout_state/state)
	var/list/required_zones = list()
	var/list/optional_zones = list()
	for(var/datum/world_edit_building_zone_spec/zone_spec as anything in state.semantic_plan?.zone_specs)
		if(!istype(zone_spec))
			continue
		if(zone_spec.required)
			required_zones += zone_spec
		else
			optional_zones += zone_spec
	return required_zones + optional_zones

/datum/world_edit_generator/building_layout/proc/build_building_layout_room_zone_demands(datum/world_edit_building_layout_state/state, list/zone_specs, target_room_count)
	var/list/demands = list()
	var/list/optional = list()
	for(var/datum/world_edit_building_zone_spec/zone_spec as anything in zone_specs)
		if(!istype(zone_spec))
			continue
		if(zone_spec.required)
			demands += zone_spec
		else
			optional += zone_spec
	for(var/datum/world_edit_building_zone_spec/optional_zone as anything in optional)
		if(length(demands) >= target_room_count)
			break
		demands += optional_zone
	var/guard = 0
	while(length(demands) < target_room_count && guard < 24)
		guard++
		var/datum/world_edit_building_zone_spec/repeat_zone = select_building_layout_repeat_zone(state, zone_specs, demands)
		if(!istype(repeat_zone))
			break
		demands += repeat_zone
	return demands

/datum/world_edit_generator/building_layout/proc/select_building_layout_repeat_zone(datum/world_edit_building_layout_state/state, list/zone_specs, list/current_demands)
	var/datum/world_edit_building_zone_spec/best = null
	var/best_score = -999999999
	var/list/instance_counts = list()
	for(var/datum/world_edit_building_zone_spec/current as anything in current_demands)
		if(istype(current))
			instance_counts[current.id] = round(text2num("[instance_counts[current.id]]") || 0) + 1
	for(var/datum/world_edit_building_zone_spec/zone_spec as anything in zone_specs)
		if(!istype(zone_spec) || zone_spec.role in list("entry", "route", "choke", "nested"))
			continue
		var/score = zone_spec.required ? 100 : 50
		score += zone_spec.min_area * 4
		switch(zone_spec.role)
			if("private", "storage", "service", "support", "secure")
				score += 180
			if("hub", "public", "public_med", "staging")
				score += 100
		for(var/datum/world_edit_building_region_spec/region_spec as anything in state.semantic_plan?.region_specs)
			if(istype(region_spec) && region_spec.zone_id == zone_spec.id)
				score += 35
		score -= round(text2num("[instance_counts[zone_spec.id]]") || 0) * 90
		if(!istype(best) || score > best_score)
			best = zone_spec
			best_score = score
	return best

/datum/world_edit_generator/building_layout/proc/compile_building_layout_room_contract(datum/world_edit_building_layout_state/state, datum/world_edit_building_zone_spec/zone_spec, instance_index, target_room_count)
	if(!istype(state) || !istype(zone_spec))
		return null
	var/usable_area = max(length(state.geometry.footprint) - length(state.geometry.boundary), 1)
	var/average_room_area = max(round(usable_area / max(target_room_count, 1)), zone_spec.min_area)
	var/min_area = max(zone_spec.min_area, (zone_spec.role in list("hub", "public", "public_med")) ? 9 : ((zone_spec.role in list("entry", "route", "choke")) ? 2 : 4))
	min_area = max(min_area, get_building_layout_zone_scene_min_area(state, zone_spec, instance_index))
	var/preferred_area = max(min_area, round(average_room_area * 0.45))
	var/max_area = max(preferred_area, round(average_room_area * 1.05))
	var/min_width = max(2, min(round(sqrt(min_area)), 5))
	var/requires_controlled_route_access = zone_spec.privacy_class != "public"
	if(requires_controlled_route_access)
		min_width = max(min_width, 3)
	var/min_height = max(2, round(min_area / max(min_width, 1)))
	if(requires_controlled_route_access)
		min_height = max(min_height, 3)
		min_area = max(min_area, min_width * min_height)
		preferred_area = max(preferred_area, min_area)
		max_area = max(max_area, min_area)
	if(zone_spec.role in list("hub", "public", "public_med"))
		min_width = max(min_width, 3)
		min_height = max(min_height, 3)
	var/max_width = max(min_width, min(12, round(state.geometry.bounds["width"]) - 2))
	var/max_height = max(min_height, min(12, round(state.geometry.bounds["height"]) - 2))
	var/room_id = instance_index > 1 ? "[zone_spec.id]_[instance_index]" : zone_spec.id
	var/datum/world_edit_building_layout_room_contract/room = new(room_id, zone_spec.role, zone_spec.id, zone_spec.required || instance_index > 1, min_area, preferred_area, max_area, min_width, min_height, max_width, max_height)
	room.instance_index = instance_index
	room.privacy_class = length("[zone_spec.privacy_class]") ? zone_spec.privacy_class : "semi_private"
	room.must_touch_route = zone_spec.must_touch_route
	room.max_aspect = (zone_spec.role in list("route", "staging")) ? 3.5 : 2.4
	room.target_aspect = (zone_spec.role in list("storage", "service")) ? 1.6 : 1.25
	room.anchor_tags = zone_spec.anchor_tags.Copy()
	room.window_policy = zone_spec.window_allowed ? "desired" : "forbidden"
	room.exterior_window_policy = room.window_policy
	configure_building_layout_partition_policy(room)
	room.required_scene_kinds = list()
	room.allowed_scene_kinds = list()
	return room

/datum/world_edit_generator/building_layout/proc/get_building_layout_zone_scene_min_area(datum/world_edit_building_layout_state/state, datum/world_edit_building_zone_spec/zone_spec, instance_index = 1)
	if(!istype(state) || !istype(zone_spec))
		return 0
	var/min_scene_area = 0
	for(var/datum/world_edit_building_cluster_spec/cluster_spec as anything in state.semantic_plan?.cluster_specs)
		if(!istype(cluster_spec) || !cluster_spec.required || is_building_infrastructure_category(cluster_spec.category) || instance_index > 1)
			continue
		if(!(zone_spec.id in cluster_spec.anchors) && cluster_spec.optional_zone_id != zone_spec.id)
			continue
		var/module_area = max(4, max(cluster_spec.min_count, 1) * 2)
		if(cluster_spec.pattern == "table_cluster")
			module_area = max(module_area, 8 + max(cluster_spec.chair_count, 0) * 2)
		if(cluster_spec.wall_required)
			module_area = max(module_area, 6)
		min_scene_area = max(min_scene_area, module_area)
	return min_scene_area

/datum/world_edit_generator/building_layout/proc/configure_building_layout_partition_policy(datum/world_edit_building_layout_room_contract/room)
	if(!istype(room))
		return
	switch(room.privacy_class)
		if("public")
			if(room.role == "entry")
				room.partition_policy = WORLD_EDIT_BUILDING_PARTITION_OPEN
				room.route_opening_kind = WORLD_EDIT_BUILDING_OPENING_WIDE_ARCH
				room.min_route_opening_width = 2
				room.max_route_opening_width = 3
			else
				room.partition_policy = WORLD_EDIT_BUILDING_PARTITION_SOFT
				room.route_opening_kind = WORLD_EDIT_BUILDING_OPENING_ARCH
				room.min_route_opening_width = 2
				room.max_route_opening_width = 2
			room.allow_public_route_merge = TRUE
		if("private")
			room.partition_policy = WORLD_EDIT_BUILDING_PARTITION_CLOSED
			room.route_opening_kind = WORLD_EDIT_BUILDING_OPENING_DOOR
			room.window_policy = "forbidden"
			room.exterior_window_policy = "forbidden"
		if("secure")
			room.partition_policy = WORLD_EDIT_BUILDING_PARTITION_SECURE
			room.route_opening_kind = WORLD_EDIT_BUILDING_OPENING_SECURE_DOOR
			room.window_policy = "forbidden"
			room.exterior_window_policy = "forbidden"
		else
			room.partition_policy = WORLD_EDIT_BUILDING_PARTITION_CLOSED
			room.route_opening_kind = WORLD_EDIT_BUILDING_OPENING_DOOR

/datum/world_edit_generator/building_layout/proc/compile_building_layout_connection_contracts(datum/world_edit_building_layout_state/state, datum/world_edit_building_layout_program_contract/program)
	if(!istype(state) || !istype(program))
		return
	for(var/datum/world_edit_building_adjacency_rule/rule as anything in state.semantic_plan?.adjacency_rules)
		if(!istype(rule))
			continue
		var/from_room_id = get_building_layout_first_room_id_for_zone(program, rule.zone_a)
		var/to_room_id = get_building_layout_first_room_id_for_zone(program, rule.zone_b)
		if(length(from_room_id) && length(to_room_id))
			program.add_connection_contract(new /datum/world_edit_building_layout_connection_contract(from_room_id, to_room_id, rule.required))

/datum/world_edit_generator/building_layout/proc/get_building_layout_first_room_id_for_zone(datum/world_edit_building_layout_program_contract/program, zone_id)
	for(var/datum/world_edit_building_layout_room_contract/room as anything in program?.room_contracts)
		if(istype(room) && room.zone_id == "[zone_id]")
			return room.id
	return ""

/datum/world_edit_generator/building_layout/proc/compile_building_layout_scene_contracts(datum/world_edit_building_layout_state/state, datum/world_edit_building_layout_program_contract/program)
	if(!istype(state) || !istype(program))
		return
	for(var/datum/world_edit_building_layout_room_contract/room as anything in program.room_contracts)
		if(!istype(room))
			continue
		var/list/exact_module_specs = list()
		var/list/fallback_module_specs = list()
		for(var/datum/world_edit_building_cluster_spec/cluster_spec as anything in state.semantic_plan?.cluster_specs)
			if(!istype(cluster_spec) || is_building_infrastructure_category(cluster_spec.category))
				continue
			if(building_layout_cluster_exactly_matches_room(cluster_spec, room))
				exact_module_specs += cluster_spec
			else if(building_layout_cluster_matches_room(cluster_spec, room))
				fallback_module_specs += cluster_spec
		var/list/module_specs = length(exact_module_specs) ? exact_module_specs : fallback_module_specs
		var/scene_kind = resolve_building_layout_scene_kind(room, module_specs)
		var/datum/world_edit_building_layout_scene_contract/scene = new("[room.id]_identity", scene_kind)
		scene.allowed_programs = list(program.id)
		scene.allowed_room_ids = list(room.id)
		scene.allowed_room_roles = list(room.role)
		scene.required = room.required
		scene.min_room_area = room.min_area
		scene.primary_anchor_policy = (room.privacy_class in list("private", "secure")) ? "far_wall" : "center"
		scene.negative_space_policy = "door_to_focus"
		for(var/datum/world_edit_building_cluster_spec/cluster_spec as anything in module_specs)
			if(room.instance_index > 1 && cluster_spec.required)
				continue
			scene.module_specs += cluster_spec
			if(cluster_spec.required)
				scene.required_modules += cluster_spec.id
			else
				scene.optional_modules += cluster_spec.id
		configure_building_layout_scene_fallback(scene, room)
		room.allowed_scene_kinds = list(scene_kind)
		if(room.required)
			room.required_scene_kinds = list(scene_kind)
		program.add_scene_contract(scene)

/datum/world_edit_generator/building_layout/proc/building_layout_cluster_exactly_matches_room(datum/world_edit_building_cluster_spec/cluster_spec, datum/world_edit_building_layout_room_contract/room)
	if(!istype(cluster_spec) || !istype(room))
		return FALSE
	if(length(cluster_spec.optional_zone_id) && cluster_spec.optional_zone_id == room.zone_id)
		return TRUE
	return room.zone_id in cluster_spec.anchors

/datum/world_edit_generator/building_layout/proc/building_layout_cluster_matches_room(datum/world_edit_building_cluster_spec/cluster_spec, datum/world_edit_building_layout_room_contract/room)
	if(!istype(cluster_spec) || !istype(room) || is_building_infrastructure_category(cluster_spec.category))
		return FALSE
	if(length(cluster_spec.optional_zone_id) && cluster_spec.optional_zone_id == room.zone_id)
		return TRUE
	for(var/anchor_id as anything in cluster_spec.anchors)
		if("[anchor_id]" == room.zone_id || "[anchor_id]" == room.role || "[anchor_id]" in room.anchor_tags)
			return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/resolve_building_layout_scene_kind(datum/world_edit_building_layout_room_contract/room, list/module_specs)
	if(!istype(room))
		return "room_identity"
	var/has_social_module = FALSE
	for(var/datum/world_edit_building_cluster_spec/cluster_spec as anything in module_specs)
		if(!istype(cluster_spec))
			continue
		if(cluster_spec.slot == "bed" || (cluster_spec.category in list("bed", "sleeping_bed")))
			return "bedroom"
		if((cluster_spec.slot in list("toilet", "sink")) || cluster_spec.category == "sanitation")
			return "sanitation"
		if(cluster_spec.pattern == "table_cluster" && cluster_spec.chair_count > 0)
			has_social_module = TRUE
	if(room.role == "storage" || findtext(room.zone_id, "storage"))
		return "storage"
	if(has_social_module)
		return "living_common"
	return room.zone_id

/datum/world_edit_generator/building_layout/proc/configure_building_layout_scene_fallback(datum/world_edit_building_layout_scene_contract/scene, datum/world_edit_building_layout_room_contract/room)
	if(!istype(scene) || !istype(room))
		return
	switch(room.role)
		if("private")
			scene.fallback_slot = "bed"
			scene.fallback_category = "bed"
		if("storage", "service", "support")
			scene.fallback_slot = "rack"
			scene.fallback_category = "rack"
		if("secure", "work", "hub")
			scene.fallback_slot = "console"
			scene.fallback_category = "console"
		if("entry", "route")
			scene.fallback_slot = "light"
			scene.fallback_category = "light"
		else
			scene.fallback_slot = "table"
			scene.fallback_category = "table"

/datum/world_edit_generator/building_layout/proc/get_building_layout_pattern(pattern_id)
	switch("[pattern_id]")
		if("adaptive_axis")
			return new /datum/world_edit_building_layout_pattern/adaptive_axis()
		if("adaptive_cross_axis")
			return new /datum/world_edit_building_layout_pattern/adaptive_cross_axis()
	return null

/datum/world_edit_building_layout_pattern/adaptive_axis
	id = "adaptive_axis"
	min_width = 9
	min_height = 9
	max_width = 64
	max_height = 64

/datum/world_edit_building_layout_pattern/adaptive_axis/build_region_candidates(datum/world_edit_building_layout_context/context)
	var/list/candidates = list()
	if(!can_solve(context))
		return candidates
	for(var/offset in list(-1, 0, 1))
		var/datum/world_edit_building_layout_region_candidate/candidate = context.generator.build_building_layout_axis_region_candidate(context, TRUE, offset, "axis_v_[offset]")
		if(istype(candidate))
			candidates += candidate
	return candidates

/datum/world_edit_building_layout_pattern/adaptive_cross_axis
	id = "adaptive_cross_axis"
	min_width = 9
	min_height = 9
	max_width = 64
	max_height = 64

/datum/world_edit_building_layout_pattern/adaptive_cross_axis/build_region_candidates(datum/world_edit_building_layout_context/context)
	var/list/candidates = list()
	if(!can_solve(context))
		return candidates
	for(var/offset in list(-1, 0, 1))
		var/datum/world_edit_building_layout_region_candidate/candidate = context.generator.build_building_layout_axis_region_candidate(context, FALSE, offset, "axis_h_[offset]")
		if(istype(candidate))
			candidates += candidate
	return candidates

/datum/world_edit_generator/building_layout/proc/build_building_layout_axis_region_candidate(datum/world_edit_building_layout_context/context, vertical = TRUE, offset = 0, candidate_id = "axis")
	if(!istype(context) || !istype(context.program_contract))
		return null
	var/width = context.local_width()
	var/height = context.local_height()
	var/right = width - 1
	var/bottom = height - 1
	var/list/side_a = list()
	var/list/side_b = list()
	var/area_a = 0
	var/area_b = 0
	var/list/distribution_contracts = sort_building_layout_room_contracts_by_priority(context.program_contract.room_contracts)
	for(var/datum/world_edit_building_layout_room_contract/room as anything in distribution_contracts)
		if(!istype(room))
			continue
		if(area_a <= area_b)
			side_a += room.id
			area_a += room.preferred_area
		else
			side_b += room.id
			area_b += room.preferred_area
	if(!length(side_a) || !length(side_b))
		return null
	var/datum/world_edit_building_layout_region_candidate/region = new(vertical ? "adaptive_axis" : "adaptive_cross_axis", candidate_id, 500 - abs(offset) * 10)
	if(vertical)
		var/route_left = clamp(round(width / 2) + offset, 5, right - 4)
		var/route_right = route_left
		var/left_room_right = route_left - 2
		var/right_room_left = route_right + 2
		if(left_room_right < 4 || right_room_left > right - 2)
			return null
		region.add_route_hint("primary_axis", "band", route_left, 2, route_right, bottom, list("side_a", "side_b"))
		region.add_influence_zone("side_a", "mixed", 2, 2, left_room_right, bottom, side_a, 80)
		region.add_influence_zone("side_b", "mixed", right_room_left, 2, right, bottom, side_b, 80)
	else
		var/route_top = clamp(round(height / 2) + offset, 5, bottom - 4)
		var/route_bottom = route_top
		var/top_room_bottom = route_top - 2
		var/bottom_room_top = route_bottom + 2
		if(top_room_bottom < 4 || bottom_room_top > bottom - 2)
			return null
		region.add_route_hint("primary_axis", "band", 2, route_top, right, route_bottom, list("side_a", "side_b"))
		region.add_route_hint("entry_stem", "line", right, 2, right, route_top, list("side_a"))
		region.add_influence_zone("side_a", "mixed", 2, 2, right - 2, top_room_bottom, side_a, 80)
		region.add_influence_zone("side_b", "mixed", 2, bottom_room_top, right - 2, bottom, side_b, 80)
	for(var/datum/world_edit_building_layout_room_contract/room as anything in context.program_contract.room_contracts)
		if(!istype(room))
			continue
		if(room.role == "route")
			continue
		var/datum/world_edit_building_layout_room_connection/connection = region.add_connection("[room.id]_to_route", room.id, "route", room.privacy_class, room.required, room.route_opening_kind)
		connection.min_shared_wall_length = (room.route_opening_kind in list(WORLD_EDIT_BUILDING_OPENING_ARCH, WORLD_EDIT_BUILDING_OPENING_WIDE_ARCH)) ? 2 : 1
	return region
