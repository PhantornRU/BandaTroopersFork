GLOBAL_LIST_EMPTY(human_ai_squad_presets)

/datum/human_squad_spawner_menu
	var/static/list/lazy_ui_data = list()

/datum/human_squad_spawner_menu/New()
	if(!length(GLOB.human_ai_squad_presets))
		for(var/datum/human_ai_squad_preset/squad_type as anything in subtypesof(/datum/human_ai_squad_preset))
			if(!squad_type::name)
				continue

			if(!lazy_ui_data[squad_type::faction])
				lazy_ui_data[squad_type::faction] = list()

			var/datum/human_ai_squad_preset/squad_obj = new squad_type()
			GLOB.human_ai_squad_presets["[squad_type]"] = squad_obj

			var/list/contains = list()
			for(var/datum/equipment_preset/equip_path as anything in squad_obj.ai_to_spawn)
				contains += "[squad_obj.ai_to_spawn[equip_path]]x [equip_path::name]"

			lazy_ui_data[squad_type::faction] += list(list(
				"name" = squad_obj.name,
				"description" = squad_obj.desc,
				"path" = squad_type,
				"contents" = contains,
			))


/datum/human_squad_spawner_menu/tgui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "HumanSquadSpawner")
		ui.open()

/datum/human_squad_spawner_menu/ui_state(mob/user)
	return GLOB.admin_state

/datum/human_squad_spawner_menu/ui_data(mob/user)
	var/list/data = list()

	return data

/datum/human_squad_spawner_menu/ui_static_data(mob/user)
	var/list/data = list()

	data["squads"] = lazy_ui_data

	return data

/datum/human_squad_spawner_menu/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("create_squad")
			if(!params["path"])
				return

			var/gotten_path = params["path"]
			if(!gotten_path)
				return

			var/datum/human_ai_squad_preset/preset_squad = GLOB.human_ai_squad_presets[gotten_path]

			// SS220 EDIT - START: pass spawn radius and accessibility toggle from the panel to squad spawning
			var/spawn_radius = preset_squad.normalize_spawn_radius(params["radius"])
			var/only_accessible_raw = params["only_accessible"]
			var/only_accessible_tiles = isnull(only_accessible_raw) ? TRUE : !!text2num("[only_accessible_raw]")

			// preset_squad.spawn_ai(get_turf(ui.user))
			preset_squad.spawn_ai(get_turf(ui.user), spawn_radius, only_accessible_tiles)
			// SS220 EDIT - END
			return TRUE

/client/proc/open_human_squad_spawner_panel()
	set name = "Human AI Squad Spawner Panel"
	set category = "Game Master.HumanAI"

	if(!check_rights(R_DEBUG))
		return

	if(!SSticker.mode)
		to_chat(src, SPAN_WARNING("The round hasn't started yet!"))
		return

	if(human_squad_menu)
		human_squad_menu.tgui_interact(mob)
		return

	human_squad_menu = new /datum/human_squad_spawner_menu(src)
	human_squad_menu.tgui_interact(mob)

/datum/human_ai_squad_preset
	var/name = ""
	var/desc = ""
	var/faction = FACTION_NEUTRAL
	/// First entry is marked as squad leader
	var/list/ai_to_spawn = list()

// SS220 EDIT - START: attach spawn helper logic to the preset instead of introducing global proc pollution
/datum/human_ai_squad_preset/proc/normalize_spawn_radius(spawn_radius)
	if(!isnum(spawn_radius))
		spawn_radius = text2num("[spawn_radius]")

	if(isnull(spawn_radius))
		spawn_radius = 1

	return clamp(round(spawn_radius), 1, 10)

/datum/human_ai_squad_preset/proc/is_spawn_turf_center_blocked(turf/checking_turf)
	if(!checking_turf || checking_turf.density)
		return TRUE

	for(var/atom/blocker as anything in checking_turf)
		if(ismob(blocker) || !blocker.density || (blocker.flags_atom & ON_BORDER))
			continue

		return TRUE

	return FALSE

/datum/human_ai_squad_preset/proc/is_spawn_turf_reachable(turf/start_turf, turf/target_turf)
	if(!start_turf || !target_turf)
		return FALSE

	if(start_turf == target_turf)
		return TRUE

	return !!AStar(start_turf, target_turf, /turf/proc/AdjacentTurfs, /turf/proc/Distance, 0, 0)

// SS220 EDIT - END

// SS220 EDIT - START: split candidate filtering from actual spawning so accessibility rules stay testable
/datum/human_ai_squad_preset/proc/get_spawn_candidate_turfs(turf/spawn_loc, spawn_radius = 1, only_accessible_tiles = TRUE)
	var/list/viable_turfs = list()
	spawn_radius = normalize_spawn_radius(spawn_radius)

	if(!spawn_loc)
		return viable_turfs

	if(only_accessible_tiles && is_spawn_turf_center_blocked(spawn_loc))
		return viable_turfs

	// for(var/turf/open/floor_tile in range(1, spawn_loc))
	for(var/turf/open/floor_tile in range(spawn_radius, spawn_loc))
		if(only_accessible_tiles)
			if(is_spawn_turf_center_blocked(floor_tile))
				continue
			if(!is_spawn_turf_reachable(spawn_loc, floor_tile))
				continue

		viable_turfs += floor_tile

	return viable_turfs

/datum/human_ai_squad_preset/proc/spawn_ai(turf/spawn_loc, spawn_radius = 1, only_accessible_tiles = TRUE)
	var/list/viable_turfs = get_spawn_candidate_turfs(spawn_loc, spawn_radius, only_accessible_tiles)
	if(!length(viable_turfs))
		return null

	var/datum/human_ai_squad/new_squad = SShuman_ai.create_new_squad()
	var/list/unused_turfs = viable_turfs.Copy()

	var/squad_leader_selected = FALSE
	for(var/datum/equipment_preset/ai_equipment as anything in ai_to_spawn)
		for(var/i in 1 to ai_to_spawn[ai_equipment])
			var/turf/chosen_turf
			if(length(unused_turfs))
				chosen_turf = pick(unused_turfs)
				unused_turfs -= chosen_turf
			else
				chosen_turf = pick(viable_turfs)

			// var/mob/living/carbon/human/ai_human = new(pick(viable_turfs))
			var/mob/living/carbon/human/ai_human = new(chosen_turf)
			arm_equipment(ai_human, ai_equipment, TRUE)
			var/datum/component/human_ai/ai_comp = ai_human.AddComponent(/datum/component/human_ai)
			ai_comp.ai_brain?.appraise_inventory(armor = TRUE)
			new_squad.add_to_squad(ai_comp.ai_brain)
			if(!squad_leader_selected)
				new_squad.set_squad_leader(ai_comp.ai_brain)
				squad_leader_selected = TRUE

	return new_squad
// SS220 EDIT - END
