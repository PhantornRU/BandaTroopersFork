/datum/world_edit_manager/proc/fail_blueprint_action(mob/user, message)
	last_ui_error = message
	to_chat(user, SPAN_WARNING(message))
	return FALSE

/datum/world_edit_manager/proc/check_blueprint_library_runtime_action_allowed(mob/user)
	return TRUE

/datum/world_edit_manager/proc/load_blueprint_into_manager(mob/user, blueprint_id)
	if(!check_blueprint_library_runtime_action_allowed(user))
		return FALSE

	if(!activate_blueprint_generator(user, blueprint_id, FALSE))
		return FALSE

	to_chat(user, SPAN_NOTICE("Шаблон '[blueprint_id]' загружен в генератор Штамп шаблона."))
	return TRUE

/datum/world_edit_manager/proc/preview_blueprint_by_id(mob/user, blueprint_id)
	if(!check_blueprint_library_runtime_action_allowed(user))
		return FALSE

	if(!activate_blueprint_generator(user, blueprint_id, FALSE))
		return FALSE
	return run_preview(user)

/datum/world_edit_manager/proc/apply_blueprint_by_id(mob/user, blueprint_id)
	if(!check_blueprint_library_runtime_action_allowed(user))
		return FALSE

	if(!activate_blueprint_generator(user, blueprint_id, TRUE))
		return FALSE
	if(has_active_safe_placement_preview())
		return apply_safe_placement_current_plan(user)
	if(is_safe_placement_mode_active())
		return fail_blueprint_action(user, "Сначала выполните предпросмотр выбранного шаблона.")

	var/datum/world_edit_preview_result/preview_result = run_preview(user)
	if(!istype(preview_result))
		return null
	if(!preview_result.success)
		return preview_result
	if(!is_preview_state_valid())
		return fail_blueprint_action(user, "Сначала выполните предпросмотр выбранного шаблона.")
	return run_apply(user)

/datum/world_edit_manager/proc/can_save_blueprint_from_current_plan()
	if(current_definition?.id != "outpost_radius")
		return FALSE
	return is_preview_state_valid() && istype(get_current_preview_plan(), /datum/world_edit_plan)

/datum/world_edit_manager/proc/save_blueprint_from_current_plan(mob/user)
	if(!can_save_blueprint_from_current_plan())
		return fail_blueprint_action(user, "Сначала выполните предпросмотр outpost_radius для сохранения шаблона.")

	var/datum/world_edit_plan/current_plan = get_current_preview_plan()
	var/turf/anchor_turf = current_plan?.metadata["center_turf"]
	if(!anchor_turf)
		anchor_turf = get_turf(user)

	var/default_name = "Форпостный шаблон"
	var/raw_name = tgui_input_text(user, "Введите имя шаблона. Сохраняется только ограниченный план форпоста из текущего предпросмотра.", "Панель редактирования мира: сохранить шаблон", default_name, WORLD_EDIT_BLUEPRINT_NAME_MAX_LEN, FALSE, FALSE)
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
		return fail_blueprint_action(user, "Не удалось сохранить шаблон на сервере.")

	refresh_blueprint_cache()
	last_ui_error = ""
	to_chat(user, SPAN_NOTICE("Шаблон '[export_result["blueprint"]["name"]]' сохранён в библиотеку."))
	return TRUE
