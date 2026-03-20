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

			var/spawn_radius = clamp(text2num(params["radius"]) || 1, 1, 10)
			var/only_accessible = text2num(params["only_accessible"]) != 0
			var/datum/human_ai_squad_preset/preset_squad = GLOB.human_ai_squad_presets[gotten_path]
			if(!preset_squad)
				return

			preset_squad.spawn_ai(get_turf(ui.user), spawn_radius, only_accessible)
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

/datum/human_ai_squad_preset/proc/get_viable_spawn_turfs(turf/spawn_loc, radius = 1, only_accessible = TRUE)
	. = list()
	if(!spawn_loc)
		return

	radius = clamp(radius || 1, 1, 10)
	for(var/turf/open/floor_tile in range(radius, spawn_loc))
		if(only_accessible && is_blocked_turf(floor_tile))
			continue
		. += floor_tile

/datum/human_ai_squad_preset/proc/spawn_ai(turf/spawn_loc, radius = 1, only_accessible = TRUE)
	var/list/viable_turfs = get_viable_spawn_turfs(spawn_loc, radius, only_accessible)

	if(!length(viable_turfs))
		return

	var/datum/human_ai_squad/new_squad = SShuman_ai.create_new_squad()

	var/squad_leader_selected = FALSE
	for(var/datum/equipment_preset/ai_equipment as anything in ai_to_spawn)
		for(var/i in 1 to ai_to_spawn[ai_equipment])
			var/mob/living/carbon/human/ai_human = new(pick(viable_turfs))
			arm_equipment(ai_human, ai_equipment, TRUE)
			var/datum/component/human_ai/ai_comp = ai_human.AddComponent(/datum/component/human_ai)
			ai_comp.ai_brain?.appraise_inventory(armor = TRUE)
			new_squad.add_to_squad(ai_comp.ai_brain)
			if(!squad_leader_selected)
				new_squad.set_squad_leader(ai_comp.ai_brain)
				squad_leader_selected = TRUE
