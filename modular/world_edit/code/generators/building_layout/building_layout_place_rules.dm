#define WORLD_EDIT_BUILDING_DIRMODE_ATTACHED_WALL 1
#define WORLD_EDIT_BUILDING_DIRMODE_FRONT_FACE 2

/datum/world_edit_building_place_rule
	var/slot = "*"
	var/category = "*"
	var/clear_front = 0
	var/clear_sides = 0
	var/needs_wall = FALSE
	var/dir_mode = WORLD_EDIT_BUILDING_DIRMODE_ATTACHED_WALL
	var/list/forbidden_anchor_tags = list()
	var/priority_bonus = 0

/datum/world_edit_building_place_rule/New(_slot = "*", _category = "*", _clear_front = 0, _clear_sides = 0, _needs_wall = FALSE, _dir_mode = WORLD_EDIT_BUILDING_DIRMODE_ATTACHED_WALL, list/_forbidden_anchor_tags = null, _priority_bonus = 0)
	. = ..()
	slot = length("[_slot]") ? "[_slot]" : "*"
	category = length("[_category]") ? "[_category]" : "*"
	clear_front = max(round(text2num("[_clear_front]") || 0), 0)
	clear_sides = max(round(text2num("[_clear_sides]") || 0), 0)
	needs_wall = _needs_wall ? TRUE : FALSE
	dir_mode = round(text2num("[_dir_mode]") || WORLD_EDIT_BUILDING_DIRMODE_ATTACHED_WALL)
	if(!(dir_mode in list(WORLD_EDIT_BUILDING_DIRMODE_ATTACHED_WALL, WORLD_EDIT_BUILDING_DIRMODE_FRONT_FACE)))
		dir_mode = WORLD_EDIT_BUILDING_DIRMODE_ATTACHED_WALL
	forbidden_anchor_tags = islist(_forbidden_anchor_tags) ? _forbidden_anchor_tags.Copy() : list()
	priority_bonus = round(text2num("[_priority_bonus]") || 0)

/datum/world_edit_generator/building_layout/proc/build_building_place_rule_key(slot, category)
	var/slot_id = length("[slot]") ? "[slot]" : "*"
	var/category_id = length("[category]") ? "[category]" : "*"
	return "[slot_id]/[category_id]"

/datum/world_edit_generator/building_layout/proc/add_building_place_rule(list/catalog, datum/world_edit_building_place_rule/place_rule)
	if(!islist(catalog) || !istype(place_rule))
		return
	catalog[build_building_place_rule_key(place_rule.slot, place_rule.category)] = place_rule

/datum/world_edit_generator/building_layout/proc/get_building_place_rule_catalog()
	var/static/list/place_rule_catalog
	if(islist(place_rule_catalog))
		return place_rule_catalog
	place_rule_catalog = list()
	var/list/default_forbidden_anchors = list("door_cone", "primary_lane")
	add_building_place_rule(place_rule_catalog, new /datum/world_edit_building_place_rule("*", "*", 0, 0, FALSE, WORLD_EDIT_BUILDING_DIRMODE_FRONT_FACE, default_forbidden_anchors))
	add_building_place_rule(place_rule_catalog, new /datum/world_edit_building_place_rule("*", "work_machine", 1, 0, TRUE, WORLD_EDIT_BUILDING_DIRMODE_FRONT_FACE, default_forbidden_anchors, 20))
	add_building_place_rule(place_rule_catalog, new /datum/world_edit_building_place_rule("*", "kitchen_machine", 1, 0, TRUE, WORLD_EDIT_BUILDING_DIRMODE_FRONT_FACE, default_forbidden_anchors, 15))
	add_building_place_rule(place_rule_catalog, new /datum/world_edit_building_place_rule("*", "security_machine", 1, 0, TRUE, WORLD_EDIT_BUILDING_DIRMODE_FRONT_FACE, default_forbidden_anchors, 10))
	add_building_place_rule(place_rule_catalog, new /datum/world_edit_building_place_rule("*", "engineering_machine", 1, 0, TRUE, WORLD_EDIT_BUILDING_DIRMODE_FRONT_FACE, default_forbidden_anchors, 20))
	add_building_place_rule(place_rule_catalog, new /datum/world_edit_building_place_rule("*", "lab_machine", 1, 0, TRUE, WORLD_EDIT_BUILDING_DIRMODE_FRONT_FACE, default_forbidden_anchors, 18))
	add_building_place_rule(place_rule_catalog, new /datum/world_edit_building_place_rule("*", "sample_storage", 1, 0, TRUE, WORLD_EDIT_BUILDING_DIRMODE_FRONT_FACE, default_forbidden_anchors, 10))
	add_building_place_rule(place_rule_catalog, new /datum/world_edit_building_place_rule("*", "infrastructure", 1, 0, TRUE, WORLD_EDIT_BUILDING_DIRMODE_ATTACHED_WALL, default_forbidden_anchors, 35))
	add_building_place_rule(place_rule_catalog, new /datum/world_edit_building_place_rule("table", "table", 0, 0, FALSE, WORLD_EDIT_BUILDING_DIRMODE_FRONT_FACE, default_forbidden_anchors))
	add_building_place_rule(place_rule_catalog, new /datum/world_edit_building_place_rule("chair", "chair", 0, 0, FALSE, WORLD_EDIT_BUILDING_DIRMODE_FRONT_FACE, default_forbidden_anchors))
	add_building_place_rule(place_rule_catalog, new /datum/world_edit_building_place_rule("cabinet", "cabinet", 0, 0, TRUE, WORLD_EDIT_BUILDING_DIRMODE_FRONT_FACE, default_forbidden_anchors, 10))
	add_building_place_rule(place_rule_catalog, new /datum/world_edit_building_place_rule("bed", "bed", 0, 0, TRUE, WORLD_EDIT_BUILDING_DIRMODE_FRONT_FACE, default_forbidden_anchors, 15))
	add_building_place_rule(place_rule_catalog, new /datum/world_edit_building_place_rule("rack", "rack", 0, 0, TRUE, WORLD_EDIT_BUILDING_DIRMODE_FRONT_FACE, default_forbidden_anchors, 10))
	add_building_place_rule(place_rule_catalog, new /datum/world_edit_building_place_rule("crate", "crate", 0, 0, FALSE, WORLD_EDIT_BUILDING_DIRMODE_FRONT_FACE, default_forbidden_anchors))
	add_building_place_rule(place_rule_catalog, new /datum/world_edit_building_place_rule("console", "console", 0, 0, TRUE, WORLD_EDIT_BUILDING_DIRMODE_FRONT_FACE, default_forbidden_anchors, 15))
	add_building_place_rule(place_rule_catalog, new /datum/world_edit_building_place_rule("barrier", "barrier", 0, 0, FALSE, WORLD_EDIT_BUILDING_DIRMODE_FRONT_FACE, default_forbidden_anchors))
	add_building_place_rule(place_rule_catalog, new /datum/world_edit_building_place_rule("medical_bed", "medical_bed", 0, 0, FALSE, WORLD_EDIT_BUILDING_DIRMODE_FRONT_FACE, default_forbidden_anchors, 15))
	add_building_place_rule(place_rule_catalog, new /datum/world_edit_building_place_rule("medical_storage", "medical_storage", 0, 0, TRUE, WORLD_EDIT_BUILDING_DIRMODE_ATTACHED_WALL, default_forbidden_anchors, 10))
	add_building_place_rule(place_rule_catalog, new /datum/world_edit_building_place_rule("hydro_tray", "hydro_tray", 0, 0, FALSE, WORLD_EDIT_BUILDING_DIRMODE_FRONT_FACE, default_forbidden_anchors, 25))
	add_building_place_rule(place_rule_catalog, new /datum/world_edit_building_place_rule("fridge", "cold_storage", 0, 0, TRUE, WORLD_EDIT_BUILDING_DIRMODE_FRONT_FACE, default_forbidden_anchors, 10))
	add_building_place_rule(place_rule_catalog, new /datum/world_edit_building_place_rule("filing", "cabinet", 0, 0, TRUE, WORLD_EDIT_BUILDING_DIRMODE_FRONT_FACE, default_forbidden_anchors, 10))
	add_building_place_rule(place_rule_catalog, new /datum/world_edit_building_place_rule("wall_monitor", "console", 0, 0, TRUE, WORLD_EDIT_BUILDING_DIRMODE_ATTACHED_WALL, default_forbidden_anchors, 10))
	add_building_place_rule(place_rule_catalog, new /datum/world_edit_building_place_rule("security_console", "console", 0, 0, TRUE, WORLD_EDIT_BUILDING_DIRMODE_FRONT_FACE, default_forbidden_anchors, 20))
	add_building_place_rule(place_rule_catalog, new /datum/world_edit_building_place_rule("sleeper", "medical_bed", 0, 0, FALSE, WORLD_EDIT_BUILDING_DIRMODE_FRONT_FACE, default_forbidden_anchors, 25))
	add_building_place_rule(place_rule_catalog, new /datum/world_edit_building_place_rule("medical_scanner", "medical_bed", 0, 0, FALSE, WORLD_EDIT_BUILDING_DIRMODE_FRONT_FACE, default_forbidden_anchors, 20))
	add_building_place_rule(place_rule_catalog, new /datum/world_edit_building_place_rule("microwave", "kitchen_machine", 0, 0, TRUE, WORLD_EDIT_BUILDING_DIRMODE_FRONT_FACE, default_forbidden_anchors, 15))
	add_building_place_rule(place_rule_catalog, new /datum/world_edit_building_place_rule("processor", "kitchen_machine", 0, 0, TRUE, WORLD_EDIT_BUILDING_DIRMODE_FRONT_FACE, default_forbidden_anchors, 15))
	add_building_place_rule(place_rule_catalog, new /datum/world_edit_building_place_rule("processor", "work_machine", 0, 0, TRUE, WORLD_EDIT_BUILDING_DIRMODE_FRONT_FACE, default_forbidden_anchors, 20))
	add_building_place_rule(place_rule_catalog, new /datum/world_edit_building_place_rule("sink", "kitchen_machine", 0, 0, TRUE, WORLD_EDIT_BUILDING_DIRMODE_FRONT_FACE, default_forbidden_anchors, 10))
	add_building_place_rule(place_rule_catalog, new /datum/world_edit_building_place_rule("toilet", "sanitation", 0, 0, TRUE, WORLD_EDIT_BUILDING_DIRMODE_FRONT_FACE, default_forbidden_anchors, 10))
	add_building_place_rule(place_rule_catalog, new /datum/world_edit_building_place_rule("water_tank", "water_or_chem", 0, 0, TRUE, WORLD_EDIT_BUILDING_DIRMODE_FRONT_FACE, default_forbidden_anchors, 10))
	add_building_place_rule(place_rule_catalog, new /datum/world_edit_building_place_rule("seed_storage", "seed_storage", 0, 0, TRUE, WORLD_EDIT_BUILDING_DIRMODE_FRONT_FACE, default_forbidden_anchors, 10))
	add_building_place_rule(place_rule_catalog, new /datum/world_edit_building_place_rule("security_camera", "security_camera", 0, 0, TRUE, WORLD_EDIT_BUILDING_DIRMODE_ATTACHED_WALL, default_forbidden_anchors, 15))
	add_building_place_rule(place_rule_catalog, new /datum/world_edit_building_place_rule("brig_cell", "security_machine", 0, 0, TRUE, WORLD_EDIT_BUILDING_DIRMODE_FRONT_FACE, default_forbidden_anchors, 10))
	add_building_place_rule(place_rule_catalog, new /datum/world_edit_building_place_rule("weapon_rack", "weapon_rack", 0, 0, TRUE, WORLD_EDIT_BUILDING_DIRMODE_FRONT_FACE, default_forbidden_anchors, 10))
	add_building_place_rule(place_rule_catalog, new /datum/world_edit_building_place_rule("engineering_machine", "engineering_machine", 0, 0, TRUE, WORLD_EDIT_BUILDING_DIRMODE_FRONT_FACE, default_forbidden_anchors, 25))
	add_building_place_rule(place_rule_catalog, new /datum/world_edit_building_place_rule("power_console", "console", 0, 0, TRUE, WORLD_EDIT_BUILDING_DIRMODE_FRONT_FACE, default_forbidden_anchors, 20))
	add_building_place_rule(place_rule_catalog, new /datum/world_edit_building_place_rule("lab_machine", "lab_machine", 0, 0, TRUE, WORLD_EDIT_BUILDING_DIRMODE_FRONT_FACE, default_forbidden_anchors, 20))
	add_building_place_rule(place_rule_catalog, new /datum/world_edit_building_place_rule("sample_storage", "sample_storage", 0, 0, TRUE, WORLD_EDIT_BUILDING_DIRMODE_FRONT_FACE, default_forbidden_anchors, 12))
	add_building_place_rule(place_rule_catalog, new /datum/world_edit_building_place_rule("light", "light", 0, 0, TRUE, WORLD_EDIT_BUILDING_DIRMODE_ATTACHED_WALL, default_forbidden_anchors, 40))
	add_building_place_rule(place_rule_catalog, new /datum/world_edit_building_place_rule("apc", "apc", 0, 0, TRUE, WORLD_EDIT_BUILDING_DIRMODE_ATTACHED_WALL, default_forbidden_anchors, 45))
	add_building_place_rule(place_rule_catalog, new /datum/world_edit_building_place_rule("air_alarm", "air_alarm", 0, 0, TRUE, WORLD_EDIT_BUILDING_DIRMODE_ATTACHED_WALL, default_forbidden_anchors, 45))
	add_building_place_rule(place_rule_catalog, new /datum/world_edit_building_place_rule("fire_alarm", "fire_alarm", 0, 0, TRUE, WORLD_EDIT_BUILDING_DIRMODE_ATTACHED_WALL, default_forbidden_anchors, 35))
	add_building_place_rule(place_rule_catalog, new /datum/world_edit_building_place_rule("light_switch", "light_switch", 0, 0, TRUE, WORLD_EDIT_BUILDING_DIRMODE_ATTACHED_WALL, default_forbidden_anchors, 30))
	return place_rule_catalog

/datum/world_edit_generator/building_layout/proc/resolve_building_place_rule(slot, category)
	var/list/place_rules = get_building_place_rule_catalog()
	var/list/lookup_keys = list(
		build_building_place_rule_key(slot, category),
		build_building_place_rule_key(slot, "*"),
		build_building_place_rule_key("*", category),
		build_building_place_rule_key("*", "*"),
	)
	for(var/rule_key as anything in lookup_keys)
		var/datum/world_edit_building_place_rule/place_rule = place_rules[rule_key]
		if(istype(place_rule))
			return place_rule
	return new /datum/world_edit_building_place_rule()

/datum/world_edit_generator/building_layout/proc/resolve_building_place_rule_dir(wall_dir, dir_mode)
	if(isnull(wall_dir))
		return null
	if(dir_mode == WORLD_EDIT_BUILDING_DIRMODE_ATTACHED_WALL)
		return wall_dir
	return turn(wall_dir, 180)

/datum/world_edit_generator/building_layout/proc/get_building_place_rule_front_dir(dir_to_use, wall_dir, datum/world_edit_building_place_rule/place_rule)
	if(!isnull(wall_dir))
		return turn(wall_dir, 180)
	return dir_to_use

/datum/world_edit_generator/building_layout/proc/building_place_rule_clearance_turf_is_open(datum/world_edit_building_layout_state/state, turf/check_turf)
	if(!istype(state) || !istype(check_turf))
		return FALSE
	if(!state.floor_lookup[check_turf])
		return FALSE
	if(state.wall_lookup[check_turf] || state.fixture_lookup[check_turf] || state.door_dirs[check_turf])
		return FALSE
	return TRUE

/datum/world_edit_generator/building_layout/proc/building_place_rule_has_forbidden_anchor(datum/world_edit_building_layout_state/state, turf/target_turf, datum/world_edit_building_place_rule/place_rule)
	if(!istype(state) || !istype(target_turf) || !istype(place_rule))
		return TRUE
	for(var/anchor_tag as anything in place_rule.forbidden_anchor_tags)
		if(state.has_anchor("[anchor_tag]", target_turf))
			return TRUE
	return FALSE

/datum/world_edit_generator/building_layout/proc/building_place_rule_has_clearance(datum/world_edit_building_layout_state/state, turf/target_turf, dir_to_use, wall_dir, datum/world_edit_building_place_rule/place_rule)
	if(!istype(state) || !istype(target_turf) || !istype(place_rule))
		return FALSE
	var/front_steps = max(round(text2num("[place_rule.clear_front]") || 0), 0)
	var/side_steps = max(round(text2num("[place_rule.clear_sides]") || 0), 0)
	if(front_steps <= 0 && side_steps <= 0)
		return TRUE
	var/front_dir = get_building_place_rule_front_dir(dir_to_use, wall_dir, place_rule)
	if(!front_dir)
		return FALSE
	if(front_steps > 0)
		var/turf/front_turf = target_turf
		for(var/step_index in 1 to front_steps)
			front_turf = get_step(front_turf, front_dir)
			if(!building_place_rule_clearance_turf_is_open(state, front_turf))
				return FALSE
	if(side_steps > 0)
		for(var/side_dir as anything in list(turn(front_dir, 90), turn(front_dir, -90)))
			var/turf/side_turf = target_turf
			for(var/step_index in 1 to side_steps)
				side_turf = get_step(side_turf, side_dir)
				if(!building_place_rule_clearance_turf_is_open(state, side_turf))
					return FALSE
	return TRUE

/datum/world_edit_generator/building_layout/proc/building_place_rule_allows_turf(datum/world_edit_building_layout_state/state, turf/target_turf, datum/world_edit_building_place_rule/place_rule, dir_to_use, wall_dir = null)
	if(!istype(state) || !istype(target_turf))
		return FALSE
	if(!istype(place_rule))
		place_rule = resolve_building_place_rule(null, null)
	if(place_rule.needs_wall && isnull(wall_dir))
		return FALSE
	if(!isnull(wall_dir) && !state.wall_lookup[get_step(target_turf, wall_dir)])
		return FALSE
	if(building_place_rule_has_forbidden_anchor(state, target_turf, place_rule))
		return FALSE
	if(!building_place_rule_has_clearance(state, target_turf, dir_to_use, wall_dir, place_rule))
		return FALSE
	return TRUE

/datum/world_edit_generator/building_layout/proc/build_building_fixture_place_context(datum/world_edit_building_layout_state/state, turf/target_turf, datum/world_edit_building_place_rule/place_rule, fallback_dir = SOUTH, force_wall = FALSE)
	if(!istype(state) || !istype(target_turf))
		return null
	if(!istype(place_rule))
		place_rule = resolve_building_place_rule(null, null)
	var/list/wall_dirs = get_adjacent_wall_dirs_for_state(state, target_turf)
	for(var/wall_dir as anything in wall_dirs)
		var/dir_to_use = resolve_building_place_rule_dir(wall_dir, place_rule.dir_mode)
		if(building_place_rule_allows_turf(state, target_turf, place_rule, dir_to_use, wall_dir))
			return list("dir" = dir_to_use, "wall_dir" = wall_dir)
	if(force_wall || place_rule.needs_wall)
		return null
	if(building_place_rule_allows_turf(state, target_turf, place_rule, fallback_dir, null))
		return list("dir" = fallback_dir, "wall_dir" = null)
	return null

/datum/world_edit_generator/building_layout/proc/fixture_turf_satisfies_place_rule(datum/world_edit_building_layout_state/state, turf/target_turf, datum/world_edit_building_place_rule/place_rule, fallback_dir = SOUTH, force_wall = FALSE)
	return islist(build_building_fixture_place_context(state, target_turf, place_rule, fallback_dir, force_wall))
