/datum/world_edit_manager/proc/apply_ui_payload(list/data, list/payload)
	if(!islist(data) || !islist(payload))
		return data

	for(var/key in payload)
		data[key] = payload[key]
	return data

/datum/world_edit_manager/proc/build_generator_ui_payload(has_generator, list/ui_fields, requires_preview)
	return list(
		"has_generator" = has_generator ? TRUE : FALSE,
		"current_generator_id" = current_definition?.id,
		"current_generator_name" = current_definition?.name_ru,
		"current_generator_category" = current_definition?.category_ru,
		"current_generator_description" = current_definition?.description_ru,
		"current_generator_execution_mode" = current_definition?.execution_mode,
		"current_generator_required_rights" = current_definition ? rights2text(current_definition.required_rights, " ") : "",
		"current_generator_supports_preview" = current_definition?.supports_preview ? TRUE : FALSE,
		"requires_preview_before_apply" = requires_preview ? TRUE : FALSE,
		"current_params_text" = GLOB.world_edit_logging.params_to_text(current_params, 600),
		"ui_fields" = ui_fields,
		"runtime_status" = current_generator?.get_runtime_status() || list(),
	)
