/datum/world_edit_generator/blueprint_stamp/get_ui_fields(list/current_params)
	var/list/load_result = load_active_blueprint(current_params)
	var/list/blueprint = islist(load_result) ? load_result["blueprint"] : null
	var/default_spacing = get_default_stamp_spacing(blueprint)
	var/shape_id = manager?.get_effective_placement_shape() || WORLD_EDIT_SHAPE_POINT

	return list(list(
		"id" = "stamp_spacing",
		"label" = "Интервал штамповки",
		"kind" = "number",
		"group" = "Размещение",
		"description" = "Интервал между повторяющимися штампами шаблона. По умолчанию: max(width, height).",
		"value" = text2num("[current_params["stamp_spacing"]]") || default_spacing,
		"min" = 1,
		"max" = WORLD_EDIT_PLACEMENT_MAX_ANCHORS,
		"step" = 1,
		"visible" = shape_id != WORLD_EDIT_SHAPE_POINT,
	))

/datum/world_edit_generator/blueprint_stamp/set_ui_param(mob/user, list/current_params, param_id, value)
	if(param_id == "stamp_spacing")
		var/list/new_params = islist(current_params) ? current_params.Copy() : list()
		new_params[param_id] = clamp(round(text2num("[value]") || 1), 1, WORLD_EDIT_PLACEMENT_MAX_ANCHORS)
		return new_params
	return ..()

/datum/world_edit_generator/blueprint_stamp/get_apply_confirmation_text(list/params)
	return "Применить выбранный шаблон?"

/datum/world_edit_generator/blueprint_stamp/get_params_short(list/params)
	return "blueprint_id=[params["blueprint_id"]] shape=[manager?.get_effective_placement_shape() || WORLD_EDIT_SHAPE_POINT] mode=[manager?.get_effective_placement_mode() || "single"] dir=[GLOB.world_edit_helpers.dir_to_label(manager?.get_effective_placement_dir() || NORTH)] spacing=[params["stamp_spacing"]]"
