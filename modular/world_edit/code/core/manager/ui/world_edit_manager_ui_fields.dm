/datum/world_edit_manager/proc/refresh_current_generator_ui(mob/user)
	if(!current_generator || !current_definition)
		last_ui_error = "Сначала выберите генератор."
		to_chat(user, SPAN_WARNING(last_ui_error))
		return

	current_generator.refresh_ui_state(user, current_params)
	last_ui_error = ""
	rebuild_runtime_after_generator_config_change(user, TRUE, FALSE, FALSE, TRUE)
	to_chat(user, SPAN_NOTICE("Параметры генератора обновлены."))

/datum/world_edit_manager/proc/handle_set_param_action(mob/user, list/params)
	if(!current_generator || !current_definition)
		return TRUE

	if(!check_rights_for(holder, current_definition.required_rights))
		last_ui_error = "Недостаточно прав для настройки этого генератора."
		to_chat(user, SPAN_WARNING(last_ui_error))
		return TRUE

	var/raw_param_id = params["param_id"]
	var/param_id = normalize_ui_field_id(raw_param_id)
	if(!length(param_id))
		last_ui_error = "Не передан идентификатор параметра."
		to_chat(user, SPAN_WARNING(last_ui_error))
		return TRUE

	var/list/ui_fields = get_normalized_ui_fields()
	var/list/target_field = find_ui_field_by_id(ui_fields, param_id)
	var/shape_field = FALSE
	if(!target_field)
		target_field = find_shape_ui_field_by_id(param_id)
		shape_field = islist(target_field)
	if(!target_field)
		last_ui_error = "Параметр '[param_id]' недоступен в текущей форме генератора."
		to_chat(user, SPAN_WARNING(last_ui_error))
		return TRUE

	param_id = normalize_ui_field_id(target_field["id"])
	if(GLOB.world_edit_helpers.parse_bool(target_field["disabled"]))
		var/target_field_label = "[target_field["label"]]"
		last_ui_error = "Параметр '[target_field_label]' сейчас недоступен для редактирования."
		to_chat(user, SPAN_WARNING(last_ui_error))
		return TRUE

	var/value = params["value"]
	if(param_id == "shape_points_text")
		var/list/parsed_points = GLOB.world_edit_placement_shapes.world_edit_parse_shape_points("[value]")
		set_placement_collector_points(parsed_points)
		last_ui_error = ""
		save_current_generator_context()
		refresh_shape_preview_after_param_change(user)
		return TRUE

	if(shape_field)
		var/new_shape_params = apply_shape_ui_param_to_params(current_params, param_id, value, target_field)
		if(istext(new_shape_params))
			last_ui_error = new_shape_params
			to_chat(user, SPAN_WARNING(last_ui_error))
			return TRUE
		if(!islist(new_shape_params))
			last_ui_error = "Не удалось обновить параметр формы."
			to_chat(user, SPAN_WARNING(last_ui_error))
			return TRUE

		current_params = new_shape_params
		last_ui_error = ""
		save_current_generator_context()
		refresh_shape_preview_after_param_change(user)
		return TRUE

	var/new_params = current_generator.set_ui_param(user, current_params, param_id, value)
	if(isnull(new_params))
		return TRUE

	if(istext(new_params))
		last_ui_error = new_params
		to_chat(user, SPAN_WARNING(last_ui_error))
		return TRUE

	if(!islist(new_params))
		last_ui_error = "Не удалось обновить параметр генератора."
		to_chat(user, SPAN_WARNING(last_ui_error))
		return TRUE

	current_params = new_params
	last_ui_error = ""
	save_current_generator_context()
	rebuild_runtime_after_generator_config_change(user, TRUE, FALSE, FALSE, TRUE)
	return TRUE

/datum/world_edit_manager/proc/get_normalized_ui_fields()
	if(!current_generator)
		return list()

	var/list/raw_fields = current_generator.get_ui_fields(current_params)
	return normalize_ui_fields(raw_fields)

/datum/world_edit_manager/proc/get_normalized_shape_ui_fields(shape_id = null, list/source_params = null)
	shape_id = shape_id || get_effective_placement_shape()
	if(!length("[shape_id]"))
		return list()

	var/list/raw_fields = GLOB.world_edit_shape_catalog.build_shape_ui_fields(shape_id, islist(source_params) ? source_params : current_params)
	return normalize_ui_fields(raw_fields)

/datum/world_edit_manager/proc/get_all_normalized_shape_ui_fields(list/source_params = null)
	var/list/normalized_fields = list()
	var/list/field_lookup = list()
	for(var/shape_id in GLOB.world_edit_shape_catalog.get_supported_shape_ids())
		var/list/shape_fields = get_normalized_shape_ui_fields(shape_id, source_params)
		for(var/list/field as anything in shape_fields)
			var/field_id = "[field["id"]]"
			if(!length(field_id) || field_lookup[field_id])
				continue
			field_lookup[field_id] = TRUE
			normalized_fields += list(field)
	return normalized_fields

/datum/world_edit_manager/proc/find_shape_ui_field_by_id(field_id, shape_id = null, list/source_params = null)
	var/list/target_field = find_ui_field_by_id(get_normalized_shape_ui_fields(shape_id, source_params), field_id)
	if(islist(target_field))
		return target_field
	return find_ui_field_by_id(get_all_normalized_shape_ui_fields(source_params), field_id)

/datum/world_edit_manager/proc/normalize_ui_field_id(field_id)
	var/normalized_id = trim("[field_id]")
	if(!length(normalized_id))
		return ""
	return normalized_id

/datum/world_edit_manager/proc/build_ui_field_id_candidates(field_id)
	var/list/candidates = list()
	var/normalized_id = normalize_ui_field_id(field_id)
	if(!length(normalized_id))
		return candidates

	candidates += normalized_id
	for(var/separator in list(".", ":", " ", "\t", "\n", ascii2text(13), "\[", "(", "{"))
		var/split_index = findtext(normalized_id, "[separator]")
		if(split_index <= 1)
			continue
		var/base_id = trim(copytext(normalized_id, 1, split_index))
		if(length(base_id) && !(base_id in candidates))
			candidates += base_id
	return candidates

/datum/world_edit_manager/proc/apply_shape_ui_param_to_params(list/source_params, param_id, value, list/target_field = null)
	if(!islist(target_field))
		target_field = find_shape_ui_field_by_id(param_id, null, source_params)
	if(!islist(target_field))
		return "Параметр '[param_id]' недоступен в каталоге форм размещения."

	var/list/new_params = islist(source_params) ? source_params.Copy() : list()
	var/canonical_param_id = normalize_ui_field_id(target_field["id"])
	var/field_kind = lowertext("[target_field["kind"] || "text"]")
	switch(field_kind)
		if("boolean")
			new_params[canonical_param_id] = GLOB.world_edit_helpers.parse_bool(value) ? TRUE : FALSE
		if("number")
			var/number_value = text2num("[value]")
			if(!isnum(number_value))
				return "Параметр '[target_field["label"] || param_id]' требует числовое значение."
			var/min_value = text2num("[target_field["min"]]")
			var/max_value = text2num("[target_field["max"]]")
			if(isnum(min_value))
				number_value = max(number_value, min_value)
			if(isnum(max_value))
				number_value = min(number_value, max_value)
			new_params[canonical_param_id] = number_value
		if("select")
			new_params[canonical_param_id] = value
		else
			new_params[canonical_param_id] = isnull(value) ? "" : "[value]"
	return new_params

/datum/world_edit_manager/proc/get_shape_preview_turf_for_param_change()
	var/turf/preview_turf = get_placement_confirm_target_turf()
	if(istype(preview_turf))
		return preview_turf
	if(istype(placement_hover_turf))
		return placement_hover_turf
	if(istype(placement_anchor_turf))
		return placement_anchor_turf
	return get_placement_collector_last_absolute_turf()

/datum/world_edit_manager/proc/can_preserve_active_placement_for_shape_change(old_shape_id, new_shape_id)
	if(!placement_click_active || !supports_current_placement_ux())
		return FALSE
	if(!length("[old_shape_id]") || !length("[new_shape_id]"))
		return FALSE
	return (get_placement_interaction_kind(old_shape_id) == get_placement_interaction_kind(new_shape_id))

/datum/world_edit_manager/proc/report_failed_active_placement_rebuild(mob/user, turf/preserved_preview_turf = null)
	clear_placement_confirm_arm()
	if(istype(preserved_preview_turf) && !istype(placement_hover_turf))
		set_placement_hover_turf(preserved_preview_turf)
	if(!length("[last_preview_message]"))
		set_safe_placement_preview_feedback(FALSE, "Текущий предпросмотр размещения не удалось перестроить с обновлёнными параметрами.", list(), FALSE)
	if(user)
		to_chat(user, SPAN_WARNING(last_preview_message))
	return FALSE

/datum/world_edit_manager/proc/refresh_active_placement_preview_after_live_config_change(mob/user, preserve_confirm_arm = TRUE)
	var/datum/world_edit_placement_session/session = get_placement_session()
	var/turf/preserved_preview_turf = get_shape_preview_turf_for_param_change()
	var/had_placement_progress = istype(session.preview_candidate) || istype(session.anchor_turf) || istype(session.hover_turf) || istype(session.collector_origin_turf) || length(session.collector_points)
	var/had_confirm_arm = preserve_confirm_arm ? has_active_safe_placement_preview() && is_placement_confirm_armed_for_turf() : FALSE
	var/preserved_hover_only = istype(session.preview_candidate) ? (session.preview_candidate.hover_only ? TRUE : FALSE) : null
	refresh_runtime_after_config_change(FALSE, FALSE)
	if(istype(preserved_preview_turf))
		set_placement_hover_turf(preserved_preview_turf)
	var/rebuild_result = refresh_active_shape_preview_after_param_change(user, preserved_hover_only)
	if(rebuild_result && had_confirm_arm && has_active_safe_placement_preview())
		arm_placement_confirm_for_turf(get_placement_confirm_target_turf())
	if(rebuild_result || !had_placement_progress)
		return rebuild_result
	return report_failed_active_placement_rebuild(user, preserved_preview_turf)

/datum/world_edit_manager/proc/refresh_shape_preview_after_param_change(mob/user, preserve_confirm_arm = TRUE)
	if(!placement_click_active || !supports_current_placement_ux())
		refresh_runtime_after_config_change()
		return TRUE
	return refresh_active_placement_preview_after_live_config_change(user, preserve_confirm_arm)

/datum/world_edit_manager/proc/refresh_active_shape_preview_after_param_change(mob/user, preserved_hover_only = null)
	if(!placement_click_active || !supports_current_placement_ux())
		return FALSE

	var/shape_id = get_effective_placement_shape()
	var/interaction_kind = get_placement_interaction_kind(shape_id)
	var/effective_hover_only
	if(isnull(preserved_hover_only))
		effective_hover_only = (interaction_kind == "collector") ? FALSE : TRUE
	else
		effective_hover_only = preserved_hover_only ? TRUE : FALSE
	return rebuild_active_safe_placement_preview(
		user,
		shape_id,
		null,
		TRUE,
		effective_hover_only,
		interaction_kind == "anchor_pair",
	)

/datum/world_edit_manager/proc/normalize_ui_fields(list/raw_fields)
	var/list/normalized_fields = list()
	if(!islist(raw_fields) || !length(raw_fields))
		return normalized_fields

	var/static/list/supported_kinds = list("select", "number", "boolean", "text")
	for(var/list/raw_field as anything in raw_fields)
		if(!islist(raw_field))
			continue

		var/field_id = "[raw_field["id"]]"
		if(!length(field_id))
			continue

		var/visible = TRUE
		if("visible" in raw_field)
			visible = GLOB.world_edit_helpers.parse_bool(raw_field["visible"])
		if(!visible)
			continue

		var/field_kind = lowertext("[raw_field["kind"] || "text"]")
		if(!(field_kind in supported_kinds))
			continue

		var/list/field = list()
		field["id"] = field_id
		field["label"] = raw_field["label"] ? "[raw_field["label"]]" : field_id
		field["kind"] = field_kind
		field["group"] = raw_field["group"] ? "[raw_field["group"]]" : "Основные"
		field["disabled"] = ("disabled" in raw_field) ? GLOB.world_edit_helpers.parse_bool(raw_field["disabled"]) : FALSE
		field["required"] = ("required" in raw_field) ? GLOB.world_edit_helpers.parse_bool(raw_field["required"]) : FALSE

		var/value = raw_field["value"]
		if(isnull(value) && islist(current_params) && (field_id in current_params))
			value = current_params[field_id]
		field["value"] = value

		if(!isnull(raw_field["description"]))
			field["description"] = "[raw_field["description"]]"
		if(!isnull(raw_field["placeholder"]))
			field["placeholder"] = "[raw_field["placeholder"]]"
		if(!isnull(raw_field["validate_hint"]))
			field["validate_hint"] = "[raw_field["validate_hint"]]"

		switch(field_kind)
			if("select")
				field["options"] = normalize_ui_select_options(raw_field["options"])
			if("number")
				if("min" in raw_field)
					var/min_value = text2num("[raw_field["min"]]")
					if(isnum(min_value))
						field["min"] = min_value
				if("max" in raw_field)
					var/max_value = text2num("[raw_field["max"]]")
					if(isnum(max_value))
						field["max"] = max_value
				if("step" in raw_field)
					var/step_value = text2num("[raw_field["step"]]")
					if(isnum(step_value))
						field["step"] = step_value

		normalized_fields += list(field)

	return normalized_fields

/datum/world_edit_manager/proc/normalize_ui_select_options(list/raw_options)
	var/list/options = list()
	if(!islist(raw_options) || !length(raw_options))
		return options

	var/list/label_counts = list()
	for(var/raw_option in raw_options)
		var/option_value
		var/option_label
		var/option_description = ""

		if(islist(raw_option))
			var/list/entry = raw_option
			if(!("value" in entry))
				continue
			option_value = entry["value"]
			option_label = entry["label"]
			if(!isnull(entry["description"]))
				option_description = "[entry["description"]]"
		else
			option_value = raw_option
			option_label = "[raw_option]"

		if(isnull(option_value))
			continue

		if(!length("[option_label]"))
			option_label = "[option_value]"

		var/base_label = "[option_label]"
		var/next_count = (label_counts[base_label] || 0) + 1
		label_counts[base_label] = next_count
		if(next_count > 1)
			option_label = "[base_label] ([next_count])"

		var/list/normalized_option = list(
			"label" = option_label,
			"value" = option_value,
		)
		if(length(option_description))
			normalized_option["description"] = option_description

		options += list(normalized_option)

	return options

/datum/world_edit_manager/proc/find_ui_field_by_id(list/ui_fields, field_id)
	if(!islist(ui_fields))
		return null

	var/list/id_candidates = build_ui_field_id_candidates(field_id)
	if(!length(id_candidates))
		return null

	for(var/id_candidate in id_candidates)
		for(var/list/field as anything in ui_fields)
			if(normalize_ui_field_id(field["id"]) == "[id_candidate]")
				return field

	return null
