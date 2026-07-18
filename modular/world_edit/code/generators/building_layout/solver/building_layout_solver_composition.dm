/datum/world_edit_generator/building_layout/proc/solve_building_layout_compositions(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate)
	if(!istype(context) || !istype(candidate))
		return FALSE
	context.scene_budget = new
	context.scene_budget.limits = islist(context.program_contract?.global_scene_slot_limits) ? context.program_contract.global_scene_slot_limits.Copy() : list()
	context.scene_budget.minimums = islist(context.program_contract?.global_scene_slot_minimums) ? context.program_contract.global_scene_slot_minimums.Copy() : list()
	for(var/datum/world_edit_building_layout_room_plan/reset_room as anything in candidate.room_plans)
		if(!istype(reset_room))
			continue
		reset_room.scene_plan = null
		reset_room.scene_kind = ""
	for(var/datum/world_edit_building_layout_room_plan/room_plan as anything in get_layout_scene_room_solve_order(context, candidate))
		if(!istype(room_plan) || room_plan.role == "route")
			continue
		var/datum/world_edit_building_layout_composition_contract/composition = context.program_contract?.get_composition_contract(room_plan.contract_id)
		var/datum/world_edit_building_layout_room_contract/room_contract = context.program_contract?.get_room_contract(room_plan.contract_id)
		if(!istype(composition))
			if(istype(room_contract) && room_contract.required)
				candidate.errors += "composition.contract_missing:[room_plan.id]"
			continue
		var/datum/world_edit_building_layout_scene_plan/scene_plan = build_building_layout_atomic_composition(context, candidate, room_plan, composition)
		if(!istype(scene_plan))
			candidate.errors += "composition.required_group_unplaceable:[room_plan.id]"
			continue
		if(!building_layout_scene_budget_allows(context, scene_plan))
			candidate.errors += "composition.module_budget_exceeded:[room_plan.id]"
			continue
		room_plan.scene_plan = scene_plan
		room_plan.scene_kind = scene_plan.scene_kind
		register_building_layout_scene_budget_use(context, scene_plan)
	var/list/missing_minimums = context.scene_budget?.missing_minimums()
	for(var/scene_slot as anything in missing_minimums)
		candidate.errors += "composition.global_minimum_missing:[scene_slot]=[missing_minimums[scene_slot]]"
	return !length(candidate.errors)

/datum/world_edit_generator/building_layout/proc/build_building_layout_atomic_composition(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate, datum/world_edit_building_layout_room_plan/room_plan, datum/world_edit_building_layout_composition_contract/composition)
	var/datum/world_edit_building_layout_scene_contract/scene_contract = context.program_contract?.get_scene_contract(composition?.scene_contract_id)
	if(!istype(scene_contract) || !istype(room_plan) || !istype(candidate))
		return null
	var/datum/world_edit_building_layout_scene_plan/scene_plan = new
	scene_plan.id = "[room_plan.id]_[scene_contract.id]"
	scene_plan.room_id = room_plan.id
	scene_plan.room_contract_id = room_plan.contract_id
	scene_plan.scene_contract_id = scene_contract.id
	scene_plan.scene_kind = scene_contract.scene_kind
	scene_plan.primary = scene_contract.primary
	scene_plan.score = 100 + room_plan.area()
	var/list/occupied_lookup = list()
	reserve_building_layout_composition_negative_space(candidate, room_plan, scene_plan, occupied_lookup, composition.min_negative_space_tiles)
	var/module_budget = max(1, min(WORLD_EDIT_BUILDING_MAX_MODULE_CANDIDATES, round(room_plan.area() / 2)))
	for(var/datum/world_edit_building_cluster_spec/required_group as anything in sort_building_layout_composition_groups(composition.required_groups))
		if(!istype(required_group))
			continue
		var/remaining_budget = module_budget - length(scene_plan.members)
		if(remaining_budget <= 0)
			candidate.errors += "composition.room_module_budget_exhausted:[room_plan.id]:[required_group.id]"
			return null
		if(!building_layout_required_group_budget_available(context, required_group))
			var/slot_key = building_layout_global_scene_slot_key(required_group.category)
			candidate.errors += "composition.global_module_budget_exhausted:[room_plan.id]:[required_group.id]:[slot_key]=[context.scene_budget?.used[slot_key] || 0]/[context.scene_budget?.limits[slot_key] || 0]"
			return null
		var/member_start = length(scene_plan.members)
		var/placed = add_building_layout_cluster_module(context, candidate, room_plan, scene_plan, required_group, occupied_lookup, remaining_budget)
		if(placed <= 0 || !building_layout_composition_group_satisfied(scene_plan, required_group, member_start) || !building_layout_wall_group_has_contiguous_axis(scene_plan, required_group, member_start))
			candidate.errors += "composition.group_atomic_reject:[room_plan.id]:[required_group.id]:placed=[placed]:members=[length(scene_plan.members) - member_start]:area=[room_plan.area()]"
			context.state?.add_stage_report("layout_composition_group", "failed", "required group was not placed atomically", list(
				"candidate_id" = candidate.id,
				"room_id" = room_plan.id,
				"group_id" = required_group.id,
				"placed" = placed,
				"member_start" = member_start,
				"member_count" = length(scene_plan.members),
			))
			return null
	for(var/datum/world_edit_building_cluster_spec/optional_group as anything in composition.optional_groups)
		if(!istype(optional_group))
			continue
		var/remaining_budget = module_budget - length(scene_plan.members)
		if(remaining_budget <= 0)
			break
		var/member_start = length(scene_plan.members)
		var/list/occupied_before = occupied_lookup.Copy()
		var/list/slot_counts_before = scene_plan.scene_slot_counts.Copy()
		var/placed = add_building_layout_cluster_module(context, candidate, room_plan, scene_plan, optional_group, occupied_lookup, remaining_budget)
		if(placed <= 0 || !building_layout_wall_group_has_contiguous_axis(scene_plan, optional_group, member_start))
			rollback_building_layout_composition_group(scene_plan, occupied_lookup, occupied_before, slot_counts_before, member_start)
	if(!length(scene_plan.members))
		report_building_layout_composition_reject(context, candidate, room_plan, "no_members", scene_plan)
		return null
	if(!building_layout_scene_members_inside_room(room_plan, scene_plan))
		report_building_layout_composition_reject(context, candidate, room_plan, "member_outside_or_duplicate", scene_plan)
		return null
	if(!building_layout_scene_members_clear_candidate_paths(candidate, scene_plan))
		report_building_layout_composition_reject(context, candidate, room_plan, "member_blocks_route_or_opening", scene_plan)
		return null
	if(!finalize_building_layout_composition_hierarchy(scene_plan))
		report_building_layout_composition_reject(context, candidate, room_plan, "focus_missing", scene_plan)
		return null
	if(!building_layout_scene_slots_within_contract(scene_plan, scene_contract))
		report_building_layout_composition_reject(context, candidate, room_plan, "scene_slot_limit", scene_plan)
		return null
	if(!validate_building_layout_scene_composition(context, candidate, room_plan, scene_contract, scene_plan))
		report_building_layout_composition_reject(context, candidate, room_plan, "composition_validation", scene_plan)
		return null
	return scene_plan

/datum/world_edit_generator/building_layout/proc/sort_building_layout_composition_groups(list/groups)
	var/list/result = list()
	for(var/datum/world_edit_building_cluster_spec/group as anything in groups)
		if(!istype(group))
			continue
		var/group_weight = max(group.min_count, 1) * 10 + max(group.chair_count, 0) * 12 + (group.wall_required ? 5 : 0)
		var/inserted = FALSE
		for(var/index in 1 to length(result))
			var/datum/world_edit_building_cluster_spec/existing = result[index]
			var/existing_weight = max(existing.min_count, 1) * 10 + max(existing.chair_count, 0) * 12 + (existing.wall_required ? 5 : 0)
			if(group_weight <= existing_weight)
				continue
			result.Insert(index, group)
			inserted = TRUE
			break
		if(!inserted)
			result += group
	return result

/datum/world_edit_generator/building_layout/proc/finalize_building_layout_composition_hierarchy(datum/world_edit_building_layout_scene_plan/scene_plan)
	if(!istype(scene_plan) || !length(scene_plan.members))
		return FALSE
	var/turf/focus_turf = null
	for(var/list/member as anything in scene_plan.members)
		if(!islist(member) || !GLOB.world_edit_helpers.parse_bool(member["major"]))
			continue
		focus_turf = member["turf"]
		break
	if(!istype(focus_turf))
		var/list/first_member = scene_plan.members[1]
		focus_turf = first_member?["turf"]
	if(!istype(focus_turf))
		return FALSE
	scene_plan.primary_anchors["focus"] = focus_turf
	scene_plan.secondary_anchors.Cut()
	scene_plan.detail_anchors.Cut()
	for(var/list/member as anything in scene_plan.members)
		var/turf/member_turf = member?["turf"]
		if(!istype(member_turf) || member_turf == focus_turf)
			continue
		if(GLOB.world_edit_helpers.parse_bool(member["major"]))
			scene_plan.secondary_anchors += member_turf
		else
			scene_plan.detail_anchors += member_turf
	return TRUE

/datum/world_edit_generator/building_layout/proc/report_building_layout_composition_reject(datum/world_edit_building_layout_context/context, datum/world_edit_building_layout_candidate/candidate, datum/world_edit_building_layout_room_plan/room_plan, reason, datum/world_edit_building_layout_scene_plan/scene_plan)
	context?.state?.add_stage_report("layout_composition", "failed", "[reason]", list(
		"candidate_id" = candidate?.id,
		"room_id" = room_plan?.id,
		"room_area" = room_plan?.area() || 0,
		"member_count" = length(scene_plan?.members),
		"negative_space_count" = length(scene_plan?.negative_space_turfs),
		"occupied_count" = length(scene_plan?.occupied_turfs),
	))

/datum/world_edit_generator/building_layout/proc/reserve_building_layout_composition_negative_space(datum/world_edit_building_layout_candidate/candidate, datum/world_edit_building_layout_room_plan/room_plan, datum/world_edit_building_layout_scene_plan/scene_plan, list/occupied_lookup, minimum_tiles = 1)
	if(!istype(candidate) || !istype(room_plan) || !istype(scene_plan) || !islist(occupied_lookup))
		return
	var/center_x = round((room_plan.x1 + room_plan.x2) / 2)
	var/center_y = round((room_plan.y1 + room_plan.y2) / 2)
	for(var/turf/door_turf as anything in get_building_layout_room_door_turfs(candidate, room_plan.id))
		var/turf/inside_turf = get_building_layout_room_door_inside_turf(candidate, room_plan, door_turf)
		if(!istype(inside_turf) || !room_plan.turf_lookup[inside_turf])
			continue
		add_building_layout_negative_space_turf(scene_plan, occupied_lookup, inside_turf)
		var/turf/lane_turf = inside_turf
		for(var/lane_index in 2 to max(minimum_tiles, 1))
			var/lane_dir = abs(center_x - lane_turf.x) >= abs(center_y - lane_turf.y) ? (center_x >= lane_turf.x ? EAST : WEST) : (center_y >= lane_turf.y ? NORTH : SOUTH)
			lane_turf = get_step(lane_turf, lane_dir)
			if(!room_plan.turf_lookup[lane_turf])
				break
			add_building_layout_negative_space_turf(scene_plan, occupied_lookup, lane_turf)
	if(!length(scene_plan.negative_space_turfs) && length(room_plan.turfs))
		var/turf/fallback_clearance = room_plan.turfs[1]
		add_building_layout_negative_space_turf(scene_plan, occupied_lookup, fallback_clearance)

/datum/world_edit_generator/building_layout/proc/add_building_layout_negative_space_turf(datum/world_edit_building_layout_scene_plan/scene_plan, list/occupied_lookup, turf/clearance_turf)
	if(!istype(scene_plan) || !islist(occupied_lookup) || !istype(clearance_turf) || occupied_lookup[clearance_turf])
		return
	scene_plan.negative_space_turfs += clearance_turf
	scene_plan.no_furniture_lookup[clearance_turf] = TRUE
	occupied_lookup[clearance_turf] = TRUE

/datum/world_edit_generator/building_layout/proc/building_layout_required_group_budget_available(datum/world_edit_building_layout_context/context, datum/world_edit_building_cluster_spec/group)
	if(!istype(context?.scene_budget) || !istype(group))
		return TRUE
	if(!context.scene_budget.can_use(building_layout_global_scene_slot_key(group.category), max(group.min_count, 1)))
		return FALSE
	if(group.pattern == "table_cluster" && group.chair_count > 0 && !context.scene_budget.can_use("chair", group.chair_count))
		return FALSE
	return TRUE

/datum/world_edit_generator/building_layout/proc/building_layout_composition_group_satisfied(datum/world_edit_building_layout_scene_plan/scene_plan, datum/world_edit_building_cluster_spec/group, member_start)
	if(!istype(scene_plan) || !istype(group))
		return FALSE
	var/credit = 0
	for(var/index in member_start + 1 to length(scene_plan.members))
		var/list/member = scene_plan.members[index]
		if(!islist(member))
			continue
		credit += get_building_fixture_count_credit(group, member["slot"], member["category"])
	return credit >= max(group.min_count, 1)

/datum/world_edit_generator/building_layout/proc/building_layout_wall_group_has_contiguous_axis(datum/world_edit_building_layout_scene_plan/scene_plan, datum/world_edit_building_cluster_spec/group, member_start)
	if(!istype(scene_plan) || !istype(group) || !group.wall_required)
		return TRUE
	var/list/wall_members = list()
	for(var/index in member_start + 1 to length(scene_plan.members))
		var/list/member = scene_plan.members[index]
		if(islist(member) && GLOB.world_edit_helpers.parse_bool(member["wall_mounted"]))
			wall_members += list(member)
	if(length(wall_members) <= 1)
		return TRUE
	var/list/first_member = wall_members[1]
	var/turf/first_turf = first_member["turf"]
	var/first_dir = first_member["dir"]
	var/min_axis = (first_dir in list(NORTH, SOUTH)) ? first_turf.x : first_turf.y
	var/max_axis = min_axis
	for(var/list/member as anything in wall_members)
		var/turf/member_turf = member["turf"]
		if(!istype(member_turf) || member["dir"] != first_dir)
			return FALSE
		if(first_dir in list(NORTH, SOUTH))
			if(member_turf.y != first_turf.y)
				return FALSE
			min_axis = min(min_axis, member_turf.x)
			max_axis = max(max_axis, member_turf.x)
		else
			if(member_turf.x != first_turf.x)
				return FALSE
			min_axis = min(min_axis, member_turf.y)
			max_axis = max(max_axis, member_turf.y)
	return max_axis - min_axis + 1 <= length(wall_members)

/datum/world_edit_generator/building_layout/proc/rollback_building_layout_composition_group(datum/world_edit_building_layout_scene_plan/scene_plan, list/occupied_lookup, list/occupied_before, list/slot_counts_before, member_start)
	if(!istype(scene_plan) || !islist(occupied_lookup) || !islist(occupied_before) || !islist(slot_counts_before))
		return
	scene_plan.members.Cut(member_start + 1)
	scene_plan.occupied_turfs.Cut()
	for(var/list/member as anything in scene_plan.members)
		var/turf/member_turf = member?["turf"]
		if(istype(member_turf))
			scene_plan.occupied_turfs += member_turf
	occupied_lookup.Cut()
	for(var/turf/occupied_turf as anything in occupied_before)
		occupied_lookup[occupied_turf] = occupied_before[occupied_turf]
	scene_plan.scene_slot_counts = slot_counts_before.Copy()
