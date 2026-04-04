/datum/world_edit_generator/structure_chunk
	var/list/last_preview_turfs = list()

/datum/world_edit_generator/structure_chunk/proc/get_template_names()
	if(!length(SSmapping.map_templates))
		return list()

	var/list/template_names = list()
	for(var/template_name in SSmapping.map_templates)
		template_names += template_name
	return sortList(template_names)

/datum/world_edit_generator/structure_chunk/configure_params(mob/user, list/current_params)
	var/list/new_params = current_params.Copy()
	var/list/template_names = get_template_names()
	if(!length(template_names))
		to_chat(user, SPAN_WARNING("Нет доступных map template для загрузки."))
		return null

	var/current_template = new_params["template_name"]
	if(!current_template || !(current_template in template_names))
		current_template = template_names[1]

	var/chosen_template = tgui_input_list(user, "Выберите map template.", "World Edit: Template", template_names, current_template)
	if(!chosen_template)
		return null
	new_params["template_name"] = chosen_template

	var/centered_choice = tgui_alert(user, "Якорить шаблон от центра текущего тайла?", "World Edit: Centered", list("Да", "Нет"))
	if(!centered_choice)
		return null
	new_params["centered"] = centered_choice == "Да"

	var/delete_choice = tgui_alert(user, "Удалять атомы в зоне загрузки? Это destructive-операция.", "World Edit: Delete Atoms", list("Нет", "Да"))
	if(!delete_choice)
		return null
	new_params["delete_atoms"] = delete_choice == "Да"

	return new_params

/datum/world_edit_generator/structure_chunk/get_ui_fields(list/current_params)
	var/list/template_names = get_template_names()
	var/list/template_options = list()
	for(var/template_name in template_names)
		template_options += list(list(
			"label" = template_name,
			"value" = template_name,
		))

	var/current_template = current_params["template_name"]
	if(!(current_template in template_names))
		current_template = length(template_names) ? template_names[1] : ""

	return list(
		list(
			"id" = "template_name",
			"label" = "Map template",
			"kind" = "select",
			"group" = "Шаблон",
			"description" = "Выбор шаблона из SSmapping.map_templates.",
			"value" = current_template,
			"options" = template_options,
		),
		list(
			"id" = "centered",
			"label" = "Центрировать загрузку",
			"kind" = "boolean",
			"group" = "Шаблон",
			"description" = "Якорить шаблон относительно центра текущего тайла.",
			"value" = current_params["centered"] ? TRUE : FALSE,
		),
		list(
			"id" = "delete_atoms",
			"label" = "Удалять атомы",
			"kind" = "boolean",
			"group" = "Destructive",
			"description" = "Удалять атомы в зоне загрузки перед применением шаблона.",
			"validate_hint" = "Требуется подтверждение apply для destructive-операции",
			"value" = current_params["delete_atoms"] ? TRUE : FALSE,
		),
	)

/datum/world_edit_generator/structure_chunk/set_ui_param(mob/user, list/current_params, param_id, value)
	var/list/new_params = current_params.Copy()

	switch(param_id)
		if("template_name")
			var/template_name = "[value]"
			if(!length(template_name))
				return "Не выбран шаблон."
			if(!SSmapping.map_templates[template_name])
				return "Шаблон '[template_name]' не найден."
			new_params[param_id] = template_name

		if("centered")
			new_params[param_id] = GLOB.world_edit_helpers.parse_bool(value)

		if("delete_atoms")
			new_params[param_id] = GLOB.world_edit_helpers.parse_bool(value)

		else
			return ..()

	return new_params

/datum/world_edit_generator/structure_chunk/validate_params(mob/user, list/params)
	var/template_name = params["template_name"]
	if(!template_name)
		return "Не выбран шаблон."

	var/datum/map_template/template = SSmapping.map_templates[template_name]
	if(!template)
		return "Шаблон '[template_name]' не найден."

	if(!get_turf(user))
		return "Не удалось определить стартовый тайл."

	return null

/datum/world_edit_generator/structure_chunk/preview(mob/user, list/params)
	var/datum/world_edit_preview_result/result = new
	var/template_name = params["template_name"]
	var/datum/map_template/template = SSmapping.map_templates[template_name]
	var/turf/start_turf = get_turf(user)
	if(!template || !start_turf)
		result.message = "Не удалось построить предпросмотр."
		return result

	var/centered = params["centered"] ? TRUE : FALSE
	last_preview_turfs = list()
	for(var/turf/affected_turf as anything in template.get_affected_turfs(start_turf, centered))
		last_preview_turfs += affected_turf
	result.preview_images = GLOB.world_edit_helpers.build_turf_preview_images(last_preview_turfs)

	result.success = TRUE
	result.meta["affected_turfs"] = length(last_preview_turfs)
	result.message = "Предпросмотр готов: зона шаблона покрывает [length(last_preview_turfs)] тайлов."
	return result

/datum/world_edit_generator/structure_chunk/apply(mob/user, list/params)
	var/datum/world_edit_apply_result/result = new
	var/template_name = params["template_name"]
	var/datum/map_template/template = SSmapping.map_templates[template_name]
	var/turf/start_turf = get_turf(user)
	if(!template || !start_turf)
		result.message = "Не удалось применить шаблон: отсутствует шаблон или якорный тайл."
		return result

	var/centered = params["centered"] ? TRUE : FALSE
	var/delete_atoms = params["delete_atoms"] ? TRUE : FALSE
	var/list/affected_turfs = template.get_affected_turfs(start_turf, centered)

	if(template.load(start_turf, centered, delete_atoms))
		result.success = TRUE
		result.created_count = length(affected_turfs)
		result.deleted_count = delete_atoms ? length(affected_turfs) : 0
		result.center_turf = start_turf
		result.message = "Шаблон '[template.name]' успешно загружен. Затронуто тайлов: [length(affected_turfs)]."
		return result

	result.message = "Не удалось загрузить шаблон '[template_name]'."
	return result

/datum/world_edit_generator/structure_chunk/cleanup_preview(mob/user)
	last_preview_turfs = list()

/datum/world_edit_generator/structure_chunk/get_apply_confirmation_text(list/params)
	if(params["delete_atoms"])
		return "Подтвердить загрузку шаблона с удалением атомов в зоне действия?"
	return "Подтвердить загрузку шаблона?"

/datum/world_edit_generator/structure_chunk/is_destructive(list/params)
	return params["delete_atoms"] ? TRUE : FALSE
