
GLOBAL_VAR_INIT(main_platoon_name, SQUAD_MARINE_1)
GLOBAL_VAR_INIT(main_platoon_initial_name, GLOB.main_platoon_name)

/// Ability to rename the platoon
/client/proc/game_master_rename_platoon()
	set name = "Rename Squad Override" // SS220 EDIT: renamed verb label for squad-specific override action
	set category = "Game Master.Extras"

	if(!admin_holder || !check_rights(R_MOD, FALSE))
		return

	rename_platoon()

/client/proc/commander_rename_platoon()
	set name = "Rename Platoon"
	set category = "OOC.Commander"

	to_chat(src, SPAN_NOTICE("Squad rename by Staff Officers is disabled. The first Squad Leader applies each squad name from preferences.")) // SS220 EDIT: disabled commander rename flow

/// Actually renames the platoon
/client/proc/rename_platoon()
	var/datum/squad_name_manager/manager = GLOB.squad_name_manager
	if(!manager) // SS220 EDIT: guard against missing squad name manager
		to_chat(src, SPAN_WARNING("Squad rename manager is unavailable."))
		return

	var/list/squad_options = list(
		"Alpha ([manager.get_runtime_name(SQUAD_MARINE_1)])" = SQUAD_MARINE_1,
		"Bravo ([manager.get_runtime_name(SQUAD_MARINE_2)])" = SQUAD_MARINE_2,
		"Charlie ([manager.get_runtime_name(SQUAD_MARINE_3)])" = SQUAD_MARINE_3,
		"Delta ([manager.get_runtime_name(SQUAD_MARINE_4)])" = SQUAD_MARINE_4,
	)
	// SS220 EDIT - START
	// var/static_name = tgui_input_list(mob, "Choose squad to rename", "Squad Rename", squad_options)
	var/selection = tgui_input_list(mob, "Choose squad to rename", "Squad Rename", squad_options)
	if(!selection)
		return

	var/static_name = squad_options[selection]
	if(!static_name)
		to_chat(src, SPAN_WARNING("Failed to resolve selected squad identifier."))
		return

	var/resolved_static_name = manager.resolve_static_name(static_name) // SS220 EDIT: normalize selected static/runtime squad identifier
	if(!resolved_static_name)
		to_chat(src, SPAN_WARNING("Failed to resolve selected squad identifier: [static_name].")) // SS220 EDIT: extended diagnostics for rename selection
		return
	// SS220 EDIT - END

	var/datum/squad/target_squad = manager.get_squad_by_static(resolved_static_name) // SS220 EDIT: use normalized static identifier for lookup
	if(!target_squad)
		to_chat(src, SPAN_WARNING("Failed to find selected squad datum. Static=[resolved_static_name], runtime=[manager.get_runtime_name_by_static(resolved_static_name)].")) // SS220 EDIT: extended diagnostics for missing squad datum
		return

	var/new_name = tgui_input_text(mob, "New squad name?", "Squad Name", target_squad.name)
	if(!new_name || !istext(new_name))
		return

	var/rename_result = manager.rename_squad(target_squad, new_name, mob, "admin_override", TRUE)
	if(rename_result != TRUE)
		to_chat(src, SPAN_WARNING("[rename_result]"))
		return

	to_chat(src, SPAN_NOTICE("Renamed [resolved_static_name] to [target_squad.name].")) // SS220 EDIT: output normalized static squad identifier
