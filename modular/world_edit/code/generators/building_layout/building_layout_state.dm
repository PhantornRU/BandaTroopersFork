/datum/world_edit_building_layout_state
	var/datum/world_edit_building_request/request
	var/datum/world_edit_building_archetype/archetype
	var/datum/world_edit_building_semantic_plan/semantic_plan
	var/list/config = list()
	var/list/footprint = list()
	var/list/boundary = list()
	var/list/interior = list()
	var/list/bounds = list()
	var/list/footprint_lookup = list()
	var/list/boundary_lookup = list()
	var/list/wall_lookup = list()
	var/list/floor_turfs = list()
	var/list/floor_lookup = list()
	var/list/door_turfs = list()
	var/list/door_dirs = list()
	var/list/window_turfs = list()
	var/list/object_placements = list()
	var/list/fixture_lookup = list()
	var/list/fixture_categories = list()
	var/list/category_counts = list()
	var/list/cluster_counts = list()
	var/list/signature_counts = list()
	var/list/signature_warnings = list()
	var/list/major_fixture_turfs = list()
	var/list/wall_fixture_turfs = list()
	var/list/reserved_lookup = list()
	var/list/zone_by_turf = list()
	var/list/zone_turfs = list()
	var/list/zone_focus_turfs = list()
	var/list/anchor_turfs = list()
	var/list/solved_regions = list()
	var/list/divider_plans = list()
	var/list/primary_route_turfs = list()
	var/list/internal_wall_turfs = list()
	var/list/category_budgets = list()
	var/list/errors = list()
	var/list/warnings = list()
	var/turf/center_turf
	var/turf/semantic_hub_turf
	var/turf/front_door_turf
	var/placement_dir = NORTH
	var/max_front_depth = 1
	var/max_lateral_abs = 1
	var/usable_fixture_area = 0
	var/fixture_count = 0
	var/major_fixture_count = 0
	var/signature_score = 0
	var/signature_max_score = 0
	var/empty_floor_ratio = 0
	var/layout_candidate_score = 0
	var/region_claim_count = 0
	var/rectangular_region_candidate_count = 0
	var/nested_room_count = 0
	var/microvariation_count = 0
	var/list/region_claim_reports = list()

/datum/world_edit_building_layout_state/proc/add_error(message)
	if(length(errors) >= WORLD_EDIT_BUILDING_MAX_VALIDATION_ERRORS)
		return
	errors += "[message]"

/datum/world_edit_building_layout_state/proc/add_warning(message)
	warnings += "[message]"

/datum/world_edit_building_layout_state/proc/has_errors()
	return length(errors) > 0

/datum/world_edit_building_layout_state/proc/append_unique_turf(list/target, turf/target_turf)
	if(!islist(target) || !istype(target_turf))
		return FALSE
	if(target_turf in target)
		return FALSE
	target += target_turf
	return TRUE

/datum/world_edit_building_layout_state/proc/add_zone(turf/target_turf, zone_id)
	if(!istype(target_turf) || !length("[zone_id]"))
		return
	var/old_zone_id = zone_by_turf[target_turf]
	if(length("[old_zone_id]") && old_zone_id != "[zone_id]")
		var/list/old_turfs = zone_turfs["[old_zone_id]"]
		if(islist(old_turfs))
			old_turfs -= target_turf
	zone_by_turf[target_turf] = "[zone_id]"
	var/list/turfs = zone_turfs["[zone_id]"]
	if(!islist(turfs))
		turfs = list()
		zone_turfs["[zone_id]"] = turfs
	append_unique_turf(turfs, target_turf)

/datum/world_edit_building_layout_state/proc/clear_zones()
	zone_by_turf.Cut()
	zone_turfs.Cut()
	zone_focus_turfs.Cut()

/datum/world_edit_building_layout_state/proc/get_zone(turf/target_turf)
	return "[zone_by_turf[target_turf] || ""]"

/datum/world_edit_building_layout_state/proc/get_zone_turfs(zone_id)
	var/list/turfs = zone_turfs["[zone_id]"]
	return islist(turfs) ? turfs : list()

/datum/world_edit_building_layout_state/proc/set_zone_focus(zone_id, turf/target_turf)
	if(!istype(target_turf) || !length("[zone_id]"))
		return
	zone_focus_turfs["[zone_id]"] = target_turf

/datum/world_edit_building_layout_state/proc/get_zone_focus(zone_id)
	return zone_focus_turfs["[zone_id]"]

/datum/world_edit_building_layout_state/proc/add_anchor(anchor_id, turf/target_turf)
	if(!istype(target_turf) || !length("[anchor_id]"))
		return
	var/list/turfs = anchor_turfs["[anchor_id]"]
	if(!islist(turfs))
		turfs = list()
		anchor_turfs["[anchor_id]"] = turfs
	append_unique_turf(turfs, target_turf)

/datum/world_edit_building_layout_state/proc/get_anchor_turfs(anchor_id)
	var/list/turfs = anchor_turfs["[anchor_id]"]
	return islist(turfs) ? turfs : list()

/datum/world_edit_building_layout_state/proc/has_anchor(anchor_id, turf/target_turf)
	var/list/turfs = get_anchor_turfs(anchor_id)
	return istype(target_turf) && (target_turf in turfs)

/datum/world_edit_building_layout_state/proc/add_reserved(turf/target_turf)
	if(istype(target_turf))
		reserved_lookup[target_turf] = TRUE

/datum/world_edit_building_layout_state/proc/add_primary_route(turf/target_turf)
	if(!istype(target_turf))
		return
	append_unique_turf(primary_route_turfs, target_turf)
	add_reserved(target_turf)

/datum/world_edit_building_layout_state/proc/add_internal_wall(turf/target_turf)
	if(!istype(target_turf) || !footprint_lookup[target_turf])
		return FALSE
	if(reserved_lookup[target_turf] || door_dirs[target_turf])
		return FALSE
	wall_lookup[target_turf] = TRUE
	append_unique_turf(internal_wall_turfs, target_turf)
	return TRUE

/datum/world_edit_building_layout_state/proc/add_divider_plan(datum/world_edit_building_divider_plan/divider_plan)
	if(!istype(divider_plan))
		return FALSE
	if(!(divider_plan in divider_plans))
		divider_plans += divider_plan
	for(var/turf/inner_turf as anything in divider_plan.inner_turfs)
		if(istype(inner_turf) && footprint_lookup[inner_turf] && !reserved_lookup[inner_turf])
			add_zone(inner_turf, divider_plan.inner_zone_id)
	var/list/emitted_wall_turfs = list()
	for(var/turf/wall_turf as anything in divider_plan.wall_turfs)
		if(add_internal_wall(wall_turf))
			emitted_wall_turfs += wall_turf
	divider_plan.wall_turfs = emitted_wall_turfs
	for(var/turf/opening_turf as anything in divider_plan.opening_turfs)
		if(!istype(opening_turf) || !footprint_lookup[opening_turf])
			continue
		append_unique_turf(door_turfs, opening_turf)
		door_dirs[opening_turf] = divider_plan.opening_dirs[opening_turf] || NORTH
		add_zone(opening_turf, divider_plan.source_zone_id)
	return TRUE

/datum/world_edit_building_layout_state/proc/can_place_fixture(turf/target_turf, allow_reserved = FALSE)
	if(!istype(target_turf))
		return FALSE
	if(!floor_lookup[target_turf])
		return FALSE
	if(wall_lookup[target_turf] || door_dirs[target_turf])
		return FALSE
	if(fixture_lookup[target_turf])
		return FALSE
	if(!allow_reserved && reserved_lookup[target_turf])
		return FALSE
	if(has_anchor("door_cone", target_turf))
		return FALSE
	return TRUE

/datum/world_edit_building_layout_state/proc/register_fixture(turf/target_turf, category, major = FALSE, wall_mounted = FALSE)
	if(!istype(target_turf))
		return
	fixture_lookup[target_turf] = TRUE
	fixture_categories[target_turf] = "[category]"
	category_counts["[category]"] = (category_counts["[category]"] || 0) + 1
	fixture_count++
	if(major)
		major_fixture_count++
		append_unique_turf(major_fixture_turfs, target_turf)
	if(wall_mounted)
		append_unique_turf(wall_fixture_turfs, target_turf)

/datum/world_edit_building_layout_state/proc/register_cluster(cluster_id, placed_count)
	if(!length("[cluster_id]") || placed_count <= 0)
		return
	cluster_counts["[cluster_id]"] = (cluster_counts["[cluster_id]"] || 0) + placed_count

/datum/world_edit_building_layout_state/proc/register_signature(signature_id, placed_count)
	if(!length("[signature_id]") || placed_count <= 0)
		return
	signature_counts["[signature_id]"] = (signature_counts["[signature_id]"] || 0) + placed_count

/datum/world_edit_building_layout_state/proc/get_category_budget(category)
	var/budget = category_budgets["[category]"]
	if(isnum(budget) && budget > 0)
		return budget
	budget = archetype?.object_budgets["[category]"]
	if(isnum(budget) && budget > 0)
		return budget
	return WORLD_EDIT_BUILDING_MAX_FIXTURE_OBJECTS
