/datum/world_edit_manager/proc/ensure_blueprint_cache_loaded()
	if(blueprint_cache_loaded)
		return
	refresh_blueprint_cache()

/datum/world_edit_manager/proc/refresh_blueprint_cache()
	blueprint_entries_cache = GLOB.world_edit_blueprints.world_edit_load_blueprint_library_summaries()
	blueprint_cache_loaded = TRUE

/datum/world_edit_manager/proc/get_blueprint_entries_for_ui()
	ensure_blueprint_cache_loaded()

	var/active_blueprint_id = get_active_blueprint_id()
	var/list/ui_entries = list()
	for(var/list/entry as anything in blueprint_entries_cache)
		var/list/ui_entry = entry.Copy()
		ui_entry["active"] = "[entry["id"]]" == active_blueprint_id
		ui_entries += list(ui_entry)
	return ui_entries

/datum/world_edit_manager/proc/get_active_blueprint_id()
	if(current_definition?.id != "blueprint_stamp")
		return null
	var/blueprint_id = "[current_params["blueprint_id"]]"
	return length(blueprint_id) ? blueprint_id : null

/datum/world_edit_manager/proc/find_cached_blueprint_entry(blueprint_id)
	ensure_blueprint_cache_loaded()
	for(var/list/entry as anything in blueprint_entries_cache)
		if("[entry["id"]]" == "[blueprint_id]")
			return entry
	return null

/datum/world_edit_manager/proc/fail_blueprint_action(mob/user, message)
	last_ui_error = message
	to_chat(user, SPAN_WARNING(message))
	return FALSE

/datum/world_edit_manager/proc/check_blueprint_library_runtime_action_allowed(mob/user)
	return TRUE

/datum/world_edit_manager/proc/load_blueprint_definition_by_id(blueprint_id)
	var/list/entry = find_cached_blueprint_entry(blueprint_id)
	if(!entry)
		return list("error" = "Blueprint не найден.")
	if(!entry["valid"])
		return list("error" = entry["error"] || "Blueprint невалиден.")
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
			return fail_blueprint_action(user, "Не удалось активировать blueprint stamp generator.")

	var/blueprint_changed = current_blueprint_id != "[blueprint_id]"
	if(!islist(current_params))
		current_params = list()
	current_params["blueprint_id"] = "[blueprint_id]"
	save_current_generator_context()
	if(blueprint_changed)
		refresh_runtime_after_config_change()

	last_ui_error = ""
	return TRUE

/datum/world_edit_manager/proc/load_blueprint_into_manager(mob/user, blueprint_id)
	if(!check_blueprint_library_runtime_action_allowed(user))
		return FALSE

	if(!activate_blueprint_generator(user, blueprint_id, FALSE))
		return FALSE

	to_chat(user, SPAN_NOTICE("Blueprint '[blueprint_id]' загружен в blueprint stamp generator."))
	return TRUE

/datum/world_edit_manager/proc/preview_blueprint_by_id(mob/user, blueprint_id)
	if(!check_blueprint_library_runtime_action_allowed(user))
		return FALSE

	if(!activate_blueprint_generator(user, blueprint_id, FALSE))
		return FALSE
	run_preview(user)
	return TRUE

/datum/world_edit_manager/proc/apply_blueprint_by_id(mob/user, blueprint_id)
	if(!check_blueprint_library_runtime_action_allowed(user))
		return FALSE

	if(!activate_blueprint_generator(user, blueprint_id, TRUE))
		return FALSE
	if(!is_preview_state_valid())
		return fail_blueprint_action(user, "Сначала выполните preview выбранного blueprint.")
	run_apply(user)
	return TRUE

/datum/world_edit_manager/proc/can_save_blueprint_from_current_plan()
	if(current_definition?.id != "outpost_radius")
		return FALSE
	return istype(current_generator?.current_plan, /datum/world_edit_plan)

/datum/world_edit_manager/proc/save_blueprint_from_current_plan(mob/user)
	if(!can_save_blueprint_from_current_plan())
		return fail_blueprint_action(user, "Сначала выполните preview outpost_radius для сохранения blueprint.")

	var/datum/world_edit_plan/current_plan = current_generator.current_plan
	var/turf/anchor_turf = current_plan?.metadata["center_turf"]
	if(!anchor_turf)
		anchor_turf = get_turf(user)

	var/default_name = "Outpost Blueprint"
	var/raw_name = tgui_input_text(user, "Введите имя blueprint. Сохраняется только bounded outpost plan текущего preview.", "World Edit: Save Blueprint", default_name, WORLD_EDIT_BLUEPRINT_NAME_MAX_LEN, FALSE, FALSE)
	if(isnull(raw_name))
		return FALSE

	var/blueprint_name = trim(sanitize_text("[raw_name]", ""))
	if(!length(blueprint_name))
		blueprint_name = default_name

	var/list/export_result = GLOB.world_edit_blueprints.world_edit_export_blueprint_from_outpost_plan(current_plan, anchor_turf, blueprint_name, holder?.ckey)
	if(export_result["error"])
		return fail_blueprint_action(user, export_result["error"])

	var/file_path = GLOB.world_edit_blueprints.world_edit_save_blueprint_definition(export_result["blueprint"])
	if(!file_path)
		return fail_blueprint_action(user, "Не удалось сохранить blueprint на сервере.")

	refresh_blueprint_cache()
	last_ui_error = ""
	to_chat(user, SPAN_NOTICE("Blueprint '[export_result["blueprint"]["name"]]' сохранён в библиотеку."))
	return TRUE
