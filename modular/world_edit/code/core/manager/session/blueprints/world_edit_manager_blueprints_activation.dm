/datum/world_edit_manager/proc/load_blueprint_definition_by_id(blueprint_id)
	var/list/entry = find_cached_blueprint_entry(blueprint_id)
	if(!entry)
		return list("error" = "Шаблон не найден.")
	if(!entry["valid"])
		return list("error" = entry["error"] || "Шаблон невалиден.")
	return GLOB.world_edit_blueprints.world_edit_load_blueprint_from_file(entry["file_path"])

/datum/world_edit_manager/proc/activate_blueprint_generator(mob/user, blueprint_id, preserve_valid_preview = FALSE)
	var/list/load_result = load_blueprint_definition_by_id(blueprint_id)
	if(load_result["error"])
		return fail_blueprint_action(user, load_result["error"])
	invalidate_active_blueprint_revision_cache()

	var/current_blueprint_id = get_active_blueprint_id()
	var/same_generator = current_definition?.id == "blueprint_stamp"

	var/had_active_placement = is_safe_placement_mode_active()
	if(!same_generator)
		if(!set_generator_by_id("blueprint_stamp"))
			return fail_blueprint_action(user, "Не удалось активировать генератор Штамп шаблона.")

	var/blueprint_changed = current_blueprint_id != "[blueprint_id]"
	if(!islist(current_params))
		current_params = list()
	current_params["blueprint_id"] = "[blueprint_id]"
	save_current_generator_context()
	if(!same_generator)
		refresh_runtime_after_config_change(TRUE, TRUE)
	else if(blueprint_changed || had_active_placement || !is_preview_state_valid())
		rebuild_runtime_after_generator_config_change(user, had_active_placement, !had_active_placement, !had_active_placement, TRUE)

	record_blueprint_usage(blueprint_id)
	last_ui_error = ""
	return TRUE
