/datum/world_edit_manager/proc/build_available_generator_categories(include_non_ready = FALSE)
	var/list/by_category = list()
	for(var/id in GLOB.world_edit_registry.definitions_by_id)
		var/datum/world_edit_generator_definition/definition = GLOB.world_edit_registry.definitions_by_id[id]
		if(!include_non_ready && definition.status != WORLD_EDIT_STATUS_READY)
			continue
		if(!check_rights_for(holder, definition.required_rights))
			continue

		var/category_name = definition.category_ru || "Общее"
		if(!by_category[category_name])
			by_category[category_name] = list()

		by_category[category_name] += list(list(
			"id" = definition.id,
			"name_ru" = definition.name_ru,
			"description_ru" = definition.description_ru,
			"execution_mode" = definition.execution_mode,
			"required_rights" = rights2text(definition.required_rights, " "),
			"supports_preview" = definition.supports_preview ? TRUE : FALSE,
		))

	var/list/result = list()
	var/list/category_names = list()
	for(var/category_name in by_category)
		category_names += category_name
	category_names = sortList(category_names)

	for(var/category_name in category_names)
		var/list/entries = by_category[category_name]
		var/list/name_to_entry = list()
		var/list/sort_keys = list()
		for(var/list/entry as anything in entries)
			var/sort_key = "[entry["name_ru"]]#[entry["id"]]"
			sort_keys += sort_key
			name_to_entry[sort_key] = entry
		sort_keys = sortList(sort_keys)

		var/list/sorted_entries = list()
		for(var/sort_key in sort_keys)
			sorted_entries += list(name_to_entry[sort_key])

		result += list(list(
			"category" = category_name,
			"generators" = sorted_entries
		))

	return result

/datum/world_edit_manager/proc/ensure_default_generator_selected()
	if(current_definition && current_generator)
		return TRUE

	if(set_generator_by_id("outpost_radius"))
		return TRUE

	var/list/categories = build_available_generator_categories()
	for(var/list/category as anything in categories)
		var/list/generators = category["generators"]
		if(!islist(generators) || !length(generators))
			continue

		for(var/list/generator_entry as anything in generators)
			if(set_generator_by_id(generator_entry["id"]))
				return TRUE

	return FALSE

/datum/world_edit_manager/proc/set_generator_by_id(generator_id)
	var/datum/world_edit_generator_definition/definition = GLOB.world_edit_registry.get_generator_definition(generator_id)
	if(!definition)
		return FALSE
	if(definition.status != WORLD_EDIT_STATUS_READY)
		return FALSE
	if(current_definition?.id == definition.id && current_generator)
		return TRUE
	if(!check_rights_for(holder, definition.required_rights))
		return FALSE

	if(current_definition?.id)
		save_current_generator_context()

	reset_generator_runtime()
	detach_current_generator()

	current_definition = definition
	current_generator = new definition.generator_type()
	current_generator.attach(src, definition)
	current_params = sanitize_persistent_generator_params(definition.default_params?.Copy() || list())
	restore_generator_session_state(definition.id)
	return TRUE

/datum/world_edit_manager/proc/reset_current_generator()
	var/current_generator_id = current_definition?.id
	if(current_generator_id)
		clear_generator_context(current_generator_id)
	reset_generator_runtime()
	detach_current_generator()

/datum/world_edit_manager/proc/restore_generator_session_state(generator_id = null)
	reset_placement_runtime(TRUE)
	var/restored_context = FALSE
	if(length("[generator_id]"))
		restored_context = restore_generator_context(generator_id)
	sync_shared_placement_prefs()
	return restored_context
