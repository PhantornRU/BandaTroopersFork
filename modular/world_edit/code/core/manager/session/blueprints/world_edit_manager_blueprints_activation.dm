/datum/world_edit_manager/proc/load_blueprint_definition_by_id(blueprint_id)
	var/list/entry = find_cached_blueprint_entry(blueprint_id)
	if(!entry)
		return list("error" = "Blueprint РЅРµ РЅР°Р№РґРµРЅ.")
	if(!entry["valid"])
		return list("error" = entry["error"] || "Blueprint РЅРµРІР°Р»РёРґРµРЅ.")
	return GLOB.world_edit_blueprints.world_edit_load_blueprint_from_file(entry["file_path"])

/datum/world_edit_manager/proc/activate_blueprint_generator(mob/user, blueprint_id, preserve_valid_preview = FALSE)
	var/list/load_result = load_blueprint_definition_by_id(blueprint_id)
	if(load_result["error"])
		return fail_blueprint_action(user, load_result["error"])

	var/current_blueprint_id = get_active_blueprint_id()
	if(preserve_valid_preview && current_definition?.id == "blueprint_stamp" && current_blueprint_id == "[blueprint_id]" && is_preview_state_valid())
		last_ui_error = ""
		return TRUE

	var/keep_active_placement = is_safe_placement_mode_active()
	if(current_definition?.id != "blueprint_stamp")
		if(!set_generator_by_id("blueprint_stamp", keep_active_placement))
			return fail_blueprint_action(user, "РќРµ СѓРґР°Р»РѕСЃСЊ Р°РєС‚РёРІРёСЂРѕРІР°С‚СЊ blueprint stamp generator.")

	var/blueprint_changed = current_blueprint_id != "[blueprint_id]"
	if(!islist(current_params))
		current_params = list()
	current_params["blueprint_id"] = "[blueprint_id]"
	save_current_generator_context()
	if(blueprint_changed)
		refresh_runtime_after_config_change()

	last_ui_error = ""
	return TRUE
