/datum/world_edit_manager/proc/can_manage_current_generator_presets()
	return GLOB.world_edit_presets.world_edit_is_preset_definition_supported(current_definition)

/datum/world_edit_manager/proc/build_validated_preset_params(mob/user, datum/world_edit_generator_definition/definition, list/raw_payload)
	if(!istype(definition))
		return list("error" = "Preset references an unknown generator.")
	if(!GLOB.world_edit_presets.world_edit_is_preset_definition_supported(definition))
		return list("error" = "Presets are not supported for this generator.")

	var/datum/world_edit_generator/temp_generator = new definition.generator_type()
	temp_generator.attach(src, definition)

	var/list/params_to_apply = definition.default_params?.Copy() || list()
	var/list/sanitized_payload = GLOB.world_edit_presets.world_edit_sanitize_preset_payload(raw_payload)

	for(var/param_id in sanitized_payload)
		var/key_text = "[param_id]"
		if(!(key_text in definition.default_params))
			qdel(temp_generator)
			return list("error" = "Preset contains an unsupported parameter '[key_text]'.")

		var/new_params = temp_generator.set_ui_param(user, params_to_apply, key_text, sanitized_payload[param_id])
		if(istext(new_params))
			qdel(temp_generator)
			return list("error" = "[new_params]")
		if(!islist(new_params))
			qdel(temp_generator)
			return list("error" = "Preset payload could not be applied to generator params.")

		params_to_apply = new_params

	var/error_text = temp_generator.validate_params(user, params_to_apply)
	qdel(temp_generator)
	if(error_text)
		return list("error" = error_text)

	return list("params" = params_to_apply)
