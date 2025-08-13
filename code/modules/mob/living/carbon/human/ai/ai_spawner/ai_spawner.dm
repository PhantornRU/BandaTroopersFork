GLOBAL_LIST_EMPTY(human_ai_equipment_presets)

/datum/human_ai_spawner_menu
	var/static/list/lazy_ui_data = list()

/datum/human_ai_spawner_menu/New()
	if(!length(GLOB.human_ai_equipment_presets))
		for(var/datum/human_ai_equipment_preset/preset_type as anything in subtypesof(/datum/human_ai_equipment_preset))
			if(!preset_type::name || !preset_type::path)
				continue

			if(!lazy_ui_data[preset_type::faction])
				lazy_ui_data[preset_type::faction] = list()

			var/datum/human_ai_equipment_preset/preset_obj = new preset_type()
			GLOB.human_ai_equipment_presets["[preset_type]"] = preset_obj

			lazy_ui_data[preset_type::faction] += list(list(
				"name" = preset_obj.name,
				"description" = preset_obj.desc,
				"path" = preset_type,
			))


/datum/human_ai_spawner_menu/tgui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "HumanAISpawner")
		ui.open()

/datum/human_ai_spawner_menu/ui_state(mob/user)
	return GLOB.admin_state

/datum/human_ai_spawner_menu/ui_data(mob/user)
	var/list/data = list()

	return data

/datum/human_ai_spawner_menu/ui_static_data(mob/user)
	var/list/data = list()

	data["presets"] = lazy_ui_data
	data["zombieDelimbMulti"] = GLOB.gm_set_zombie_delimb_multi ? GLOB.gm_set_zombie_delimb_multi : 1
	data["randomHelmet"] = GLOB.gm_set_zombie_random_helmet
	data["helmetChance"] = GLOB.gm_set_zombie_helmet_chance
	data["autoClean"] = GLOB.gm_set_zombie_disable_auto_clean

	return data

/datum/human_ai_spawner_menu/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("create_ai")
			if(!params["path"])
				return
			var/delimb_multi = clamp(text2num(params["zombieDelimbMulti"]), -1, 20)
			if(delimb_multi == 1)
				delimb_multi = null
			if(delimb_multi <= 0)
				delimb_multi = -1
			GLOB.gm_set_zombie_delimb_multi = delimb_multi

			var/random_helmet = params["randomHelmet"]
			if(random_helmet != 1 && random_helmet != 0)
				random_helmet = 0
			if(random_helmet)
				GLOB.gm_set_zombie_random_helmet = TRUE
			else
				GLOB.gm_set_zombie_random_helmet = FALSE

			var/auto_clean = params["disableAutoClean"]
			if(auto_clean != 1 && auto_clean != 0)
				auto_clean = 0
			if(auto_clean)
				GLOB.gm_set_zombie_disable_auto_clean= TRUE
			else
				GLOB.gm_set_zombie_disable_auto_clean = FALSE

			var/helmet_chance = clamp(params["helmetChance"], 1, 100)
			GLOB.gm_set_zombie_helmet_chance = helmet_chance
			var/datum/human_ai_equipment_preset/gotten_path = text2path(params["path"])
			if(!gotten_path)
				return

			var/mob/living/carbon/human/ai_human = modular_spawn_human_ai_from_equipment_preset(gotten_path::path, get_turf(ui.user), TRUE, ui.user.dir) // SS220 EDIT: modular HALO spawn flow validates preset species before the AI brain is attached
			return !isnull(ai_human)

/client/proc/open_human_ai_spawner_panel()
	set name = "Create Human AI"
	set category = "Game Master.HumanAI"

	if(!check_rights(R_DEBUG))
		return

	if(!SSticker.mode)
		to_chat(src, SPAN_WARNING("The round hasn't started yet!"))
		return

	if(human_spawn_menu)
		human_spawn_menu.tgui_interact(mob)
		return

	human_spawn_menu = new /datum/human_ai_spawner_menu(src)
	human_spawn_menu.tgui_interact(mob)


/datum/human_ai_equipment_preset
	/// The GM-visible name of the equipment preset
	var/name = ""
	/// A short description of what the preset does. Including important equipment or usecases is a good idea
	var/desc = ""
	/// What faction the preset is related to
	var/faction = FACTION_NEUTRAL
	/// The /datum/equipment_preset that this preset should create
	var/path
