/datum/world_edit_building_layout_state
	var/datum/world_edit_building_request/request
	var/datum/world_edit_building_archetype/archetype
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
	var/list/major_fixture_turfs = list()
	var/list/wall_fixture_turfs = list()
	var/list/reserved_lookup = list()
	var/list/zone_by_turf = list()
	var/list/zone_turfs = list()
	var/list/anchor_turfs = list()
	var/list/errors = list()
	var/list/warnings = list()
	var/turf/center_turf
	var/turf/front_door_turf
	var/placement_dir = NORTH
	var/fixture_count = 0
	var/major_fixture_count = 0

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
	zone_by_turf[target_turf] = "[zone_id]"
	var/list/turfs = zone_turfs["[zone_id]"]
	if(!islist(turfs))
		turfs = list()
		zone_turfs["[zone_id]"] = turfs
	append_unique_turf(turfs, target_turf)

/datum/world_edit_building_layout_state/proc/get_zone(turf/target_turf)
	return "[zone_by_turf[target_turf] || ""]"

/datum/world_edit_building_layout_state/proc/get_zone_turfs(zone_id)
	var/list/turfs = zone_turfs["[zone_id]"]
	return islist(turfs) ? turfs : list()

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
