/datum/world_edit_generator/building_layout/proc/build_building_semantic_scene_rules_for_room(datum/world_edit_building_layout_state/state, datum/world_edit_building_semantic_room_field/field, list/global_scene_counts)
	var/list/rules = list()
	if(!istype(state) || !istype(field) || !istype(field.room))
		return rules
	var/datum/world_edit_building_room/room = field.room
	var/role = lowertext("[room.role]")
	var/zone_id = lowertext("[room.zone_id]")
	var/datum/world_edit_building_zone_spec/zone_spec = state.semantic_plan?.get_zone_spec(room.zone_id)
	var/zone_role = lowertext("[zone_spec?.role || ""]")
	var/room_key = "[role]|[zone_id]|[zone_role]"
	if(findtext(room_key, "route") || findtext(room_key, "corridor") || findtext(room_key, "entry_buffer"))
		return rules

	if(building_semantic_room_is_sanitation(room_key))
		var/datum/world_edit_building_semantic_scene_rule/sanitation = new("sanitation_primary", WORLD_EDIT_BUILDING_SEMANTIC_SCENE_SANITATION, WORLD_EDIT_BUILDING_SEMANTIC_PHASE_PRIMARY, TRUE, TRUE, 950)
		sanitation.add_member("toilet", "sanitation", "sanitation_core", "wall_near_anchor", TRUE, FALSE)
		sanitation.add_member("sink", "sanitation", "sanitation_core", "wall_near_anchor", FALSE, FALSE)
		rules += sanitation
		return rules

	if(building_semantic_room_is_sleeping(room_key))
		var/datum/world_edit_building_semantic_scene_rule/sleeping = new("sleeping_primary", WORLD_EDIT_BUILDING_SEMANTIC_SCENE_BEDROOM, WORLD_EDIT_BUILDING_SEMANTIC_PHASE_PRIMARY, TRUE, TRUE, 920)
		sleeping.add_member("bed", "bed", "sleeping_focal", "wall_near_anchor", TRUE, FALSE)
		if(field.area >= 10)
			sleeping.add_member("cabinet", "cabinet", "sleeping_storage", "wall_near_anchor", FALSE, FALSE)
		rules += sleeping
		return rules

	if(building_semantic_room_is_storage(room_key))
		var/datum/world_edit_building_semantic_scene_rule/storage = new("storage_primary", WORLD_EDIT_BUILDING_SEMANTIC_SCENE_STORAGE, WORLD_EDIT_BUILDING_SEMANTIC_PHASE_PRIMARY, TRUE, TRUE, 880)
		storage.add_member(building_semantic_storage_slot_for_state(state), building_semantic_storage_category_for_state(state), "storage_run", "wall_near_anchor", TRUE, FALSE)
		if(field.area >= 14)
			storage.add_member("crate", "crate", "storage_detail", "free_near_anchor", FALSE, FALSE)
		rules += storage
		return rules

	if(building_semantic_room_is_work(room_key, state))
		var/datum/world_edit_building_semantic_scene_rule/work = new("work_primary", WORLD_EDIT_BUILDING_SEMANTIC_SCENE_WORK, WORLD_EDIT_BUILDING_SEMANTIC_PHASE_PRIMARY, TRUE, TRUE, 840)
		work.add_member("table", "table", "work_surface", "anchor", TRUE, FALSE)
		work.add_member(building_semantic_work_secondary_slot_for_state(state), building_semantic_work_secondary_category_for_state(state), "work_support", "wall_near_anchor", FALSE, FALSE)
		if(field.area >= 12)
			work.add_member("chair", "chair", "work_seat", "adjacent_to_anchor", FALSE, FALSE, FALSE, TRUE)
		rules += work
		return rules

	if(building_semantic_room_is_hydro(room_key, state))
		var/datum/world_edit_building_semantic_scene_rule/hydro = new("hydro_primary", WORLD_EDIT_BUILDING_SEMANTIC_SCENE_HYDRO, WORLD_EDIT_BUILDING_SEMANTIC_PHASE_PRIMARY, TRUE, TRUE, 830)
		hydro.add_member("hydro_tray", "hydro_tray", "grow_core", "anchor", TRUE, FALSE)
		if(field.area >= 12)
			hydro.add_member("seed_storage", "seed_storage", "grow_storage", "wall_near_anchor", FALSE, FALSE)
		rules += hydro
		return rules

	if(building_semantic_room_is_common(room_key, state))
		var/public_focal_count = round(text2num("[global_scene_counts["public_focal"]]") || 0)
		if(public_focal_count <= 0)
			var/datum/world_edit_building_semantic_scene_rule/common = new("common_primary", WORLD_EDIT_BUILDING_SEMANTIC_SCENE_DINING, WORLD_EDIT_BUILDING_SEMANTIC_PHASE_PRIMARY, TRUE, TRUE, 900, "public_focal", 1)
			common.add_member("table", "table", "dining_focal", "anchor", TRUE, FALSE, TRUE, TRUE)
			common.add_member("chair", "chair", "dining_focal", "adjacent_to_anchor", FALSE, FALSE, TRUE, TRUE)
			common.add_member("chair", "chair", "dining_focal", "adjacent_to_anchor", FALSE, FALSE, TRUE, TRUE)
			rules += common
			return rules
		var/datum/world_edit_building_semantic_scene_rule/common_side = new("common_side_surface", WORLD_EDIT_BUILDING_SEMANTIC_SCENE_LIVING, WORLD_EDIT_BUILDING_SEMANTIC_PHASE_SECONDARY, TRUE, FALSE, 620)
		common_side.add_member("cabinet", "cabinet", "common_side", "wall_near_anchor", TRUE, FALSE)
		rules += common_side
		return rules

	return rules

/datum/world_edit_generator/building_layout/proc/building_semantic_room_is_common(room_key, datum/world_edit_building_layout_state/state)
	if(findtext(room_key, "common") || findtext(room_key, "dining") || findtext(room_key, "public") || findtext(room_key, "lobby") || findtext(room_key, "court"))
		return TRUE
	return state?.archetype?.id == "living" && findtext(room_key, "main")

/datum/world_edit_generator/building_layout/proc/building_semantic_room_is_sleeping(room_key)
	return findtext(room_key, "sleep") || findtext(room_key, "dorm") || findtext(room_key, "living_wing") || findtext(room_key, "private")

/datum/world_edit_generator/building_layout/proc/building_semantic_room_is_sanitation(room_key)
	return findtext(room_key, "sanitation") || findtext(room_key, "toilet") || findtext(room_key, "bath")

/datum/world_edit_generator/building_layout/proc/building_semantic_room_is_storage(room_key)
	return findtext(room_key, "storage") || findtext(room_key, "rack") || findtext(room_key, "crate") || findtext(room_key, "locker") || findtext(room_key, "parts")

/datum/world_edit_generator/building_layout/proc/building_semantic_room_is_work(room_key, datum/world_edit_building_layout_state/state)
	if(findtext(room_key, "work") || findtext(room_key, "machine") || findtext(room_key, "desk") || findtext(room_key, "office") || findtext(room_key, "engineering") || findtext(room_key, "lab"))
		return TRUE
	return state?.archetype?.id in list("workshop", "office", "engineering", "laboratory")

/datum/world_edit_generator/building_layout/proc/building_semantic_room_is_hydro(room_key, datum/world_edit_building_layout_state/state)
	return state?.archetype?.id == "hydroponics" || findtext(room_key, "grow") || findtext(room_key, "hydro")

/datum/world_edit_generator/building_layout/proc/building_semantic_storage_slot_for_state(datum/world_edit_building_layout_state/state)
	if(state?.archetype?.id == "storage" || state?.archetype?.id == "workshop")
		return "rack"
	if(state?.archetype?.id == "dormitory" || state?.archetype?.id == "living")
		return "cabinet"
	return "rack"

/datum/world_edit_generator/building_layout/proc/building_semantic_storage_category_for_state(datum/world_edit_building_layout_state/state)
	if(state?.archetype?.id == "storage" || state?.archetype?.id == "workshop")
		return "rack"
	return "cabinet"

/datum/world_edit_generator/building_layout/proc/building_semantic_work_secondary_slot_for_state(datum/world_edit_building_layout_state/state)
	if(state?.archetype?.id == "workshop")
		return "console"
	if(state?.archetype?.id == "office")
		return "filing"
	return "console"

/datum/world_edit_generator/building_layout/proc/building_semantic_work_secondary_category_for_state(datum/world_edit_building_layout_state/state)
	if(state?.archetype?.id == "office")
		return "cabinet"
	return "console"
