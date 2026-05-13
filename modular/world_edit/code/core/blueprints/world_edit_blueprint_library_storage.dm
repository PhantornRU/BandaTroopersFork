/datum/world_edit_blueprint_service/proc/world_edit_get_blueprint_file_path(blueprint_id)
	var/raw_id = "[blueprint_id]"
	var/safe_id = sanitize_filename(raw_id)
	if(!length(safe_id) || safe_id != raw_id)
		return null
	if(safe_id in list(".", ".."))
		return null
	if(length(safe_id) > WORLD_EDIT_BLUEPRINT_ID_LEN)
		return null
	return "[WORLD_EDIT_BLUEPRINT_DIR][safe_id][WORLD_EDIT_BLUEPRINT_EXTENSION]"

/datum/world_edit_blueprint_service/proc/world_edit_get_blueprint_id_from_file_name(file_name)
	var/file_text = "[file_name]"
	if(length(file_text) <= length(WORLD_EDIT_BLUEPRINT_EXTENSION))
		return null
	if(lowertext(copytext(file_text, length(file_text) - length(WORLD_EDIT_BLUEPRINT_EXTENSION) + 1, 0)) != WORLD_EDIT_BLUEPRINT_EXTENSION)
		return null

	var/raw_id = copytext(file_text, 1, length(file_text) - length(WORLD_EDIT_BLUEPRINT_EXTENSION) + 1)
	var/safe_id = sanitize_filename(raw_id)
	if(!length(safe_id) || safe_id != raw_id)
		return null
	if(safe_id in list(".", ".."))
		return null
	if(length(safe_id) > WORLD_EDIT_BLUEPRINT_ID_LEN)
		return null
	return safe_id

/datum/world_edit_blueprint_service/proc/world_edit_blueprint_file_name_is_dmm(file_name)
	return length("[world_edit_get_blueprint_id_from_file_name(file_name)]") ? TRUE : FALSE

/datum/world_edit_blueprint_service/proc/world_edit_ensure_blueprint_storage_dir()
	if(fexists(WORLD_EDIT_BLUEPRINT_DIR))
		return TRUE

	var/probe_path = "[WORLD_EDIT_BLUEPRINT_DIR]__probe.sav"
	var/savefile/S = new /savefile(probe_path)
	if(!S)
		return FALSE

	S.cd = "/"
	S["format"] << "world_edit_blueprint_dmm"
	if(fexists(probe_path))
		fdel(probe_path)

	return fexists(WORLD_EDIT_BLUEPRINT_DIR)

/datum/world_edit_blueprint_service/proc/world_edit_build_dmm_parse_error(message)
	return list("error" = "[message]")

/datum/world_edit_blueprint_service/proc/world_edit_get_dmm_grid_bounds(datum/parsed_map/parsed)
	if(!istype(parsed) || !length(parsed.gridSets) || parsed.key_len <= 0)
		return null

	var/min_x = INFINITY
	var/max_x = -INFINITY
	var/min_y = INFINITY
	var/max_y = -INFINITY
	var/min_z = INFINITY
	var/max_z = -INFINITY
	for(var/datum/grid_set/grid_set as anything in parsed.gridSets)
		if(!istype(grid_set) || !islist(grid_set.gridLines) || !length(grid_set.gridLines))
			continue
		var/line_count = length(grid_set.gridLines)
		for(var/line_index in 1 to line_count)
			var/line_text = "[grid_set.gridLines[line_index]]"
			if(!length(line_text))
				continue
			if(length(line_text) % parsed.key_len)
				return null
			var/line_width = length(line_text) / parsed.key_len
			min_x = min(min_x, grid_set.xcrd)
			max_x = max(max_x, grid_set.xcrd + line_width - 1)
			var/line_y = grid_set.ycrd - (line_index - 1)
			min_y = min(min_y, line_y)
			max_y = max(max_y, line_y)
			min_z = min(min_z, grid_set.zcrd)
			max_z = max(max_z, grid_set.zcrd)

	if(min_x == INFINITY)
		return null
	return list(
		"min_x" = min_x,
		"max_x" = max_x,
		"min_y" = min_y,
		"max_y" = max_y,
		"min_z" = min_z,
		"max_z" = max_z,
		"width" = (max_x - min_x) + 1,
		"height" = (max_y - min_y) + 1,
	)

/datum/world_edit_blueprint_service/proc/world_edit_extract_dmm_entry_vars(obj_path, list/attributes)
	var/dir_value = SOUTH
	var/list/raw_vars = list()
	if(islist(attributes) && length(attributes))
		for(var/var_id in attributes)
			var/key_text = "[var_id]"
			switch(key_text)
				if("dir")
					dir_value = text2num("[attributes[var_id]]")
					if(!(dir_value in GLOB.cardinals))
						return list("error" = "DMM содержит некардинальное направление для '[obj_path]'.")
				if("faction")
					raw_vars["faction"] = "[attributes[var_id]]"
				if("turned_on")
					raw_vars["turned_on"] = GLOB.world_edit_helpers.parse_bool(attributes[var_id]) ? TRUE : FALSE
				else
					return list("error" = "DMM содержит неподдерживаемый var '[key_text]' для '[obj_path]'.")

	return list(
		"dir" = dir_value,
		"vars" = raw_vars,
	)

/datum/world_edit_blueprint_service/proc/world_edit_build_blueprint_from_parsed_dmm(datum/parsed_map/parsed, blueprint_id, blueprint_name = null, source = "dmm")
	var/list/grid_bounds = world_edit_get_dmm_grid_bounds(parsed)
	if(!islist(grid_bounds))
		return world_edit_build_dmm_parse_error("DMM не содержит валидной сетки.")
	if(grid_bounds["max_z"] != grid_bounds["min_z"])
		return world_edit_build_dmm_parse_error("DMM blueprint должен быть одноуровневым.")
	if(grid_bounds["width"] > WORLD_EDIT_BLUEPRINT_MAX_DIMENSION || grid_bounds["height"] > WORLD_EDIT_BLUEPRINT_MAX_DIMENSION)
		return world_edit_build_dmm_parse_error("DMM blueprint превышает лимит [WORLD_EDIT_BLUEPRINT_MAX_DIMENSION]x[WORLD_EDIT_BLUEPRINT_MAX_DIMENSION].")

	var/list/bad_paths = list()
	var/list/model_cache = parsed.build_cache(TRUE, bad_paths)
	if(length(bad_paths))
		return world_edit_build_dmm_parse_error("DMM содержит неизвестные path.")

	var/anchor_x = grid_bounds["min_x"] + floor(text2num("[grid_bounds["width"]]") / 2)
	var/anchor_y = grid_bounds["min_y"] + floor(text2num("[grid_bounds["height"]]") / 2)
	var/list/raw_entries = list()
	for(var/datum/grid_set/grid_set as anything in parsed.gridSets)
		if(!istype(grid_set) || grid_set.zcrd != grid_bounds["min_z"])
			continue

		var/line_count = length(grid_set.gridLines)
		for(var/line_index in 1 to line_count)
			var/line_text = "[grid_set.gridLines[line_index]]"
			if(!length(line_text))
				continue
			var/current_y = grid_set.ycrd - (line_index - 1)
			var/current_x = grid_set.xcrd
			for(var/key_pos in 1 to length(line_text) step parsed.key_len)
				var/model_key = copytext(line_text, key_pos, key_pos + parsed.key_len)
				var/list/model = model_cache[model_key]
				if(!islist(model))
					return world_edit_build_dmm_parse_error("DMM содержит неизвестный model key '[model_key]'.")

				var/list/members = model[1]
				var/list/member_attributes = model[2]
				var/has_turf = FALSE
				var/has_area = FALSE
				var/has_real_turf_entry = FALSE
				for(var/member_index in 1 to length(members))
					var/atom_path = members[member_index]
					if(ispath(atom_path, /turf))
						if(atom_path != /turf/template_noop)
							if(has_real_turf_entry)
								return world_edit_build_dmm_parse_error("DMM blueprint contains multiple turf entries in one cell.")
							if(!world_edit_get_blueprint_turf_rule(atom_path))
								return world_edit_build_dmm_parse_error("DMM blueprint contains unsupported turf '[atom_path]'.")
							raw_entries += list(list(
								"kind" = "turf",
								"type" = "[atom_path]",
								"dx" = current_x - anchor_x,
								"dy" = current_y - anchor_y,
								"dz" = 0,
								"dir" = SOUTH,
								"vars" = list(),
							))
							has_real_turf_entry = TRUE
						if(islist(member_attributes[member_index]) && length(member_attributes[member_index]))
							return world_edit_build_dmm_parse_error("DMM blueprint содержит var edit на template turf.")
						has_turf = TRUE
						continue
					if(ispath(atom_path, /area))
						if(atom_path != /area/template_noop)
							return world_edit_build_dmm_parse_error("DMM blueprint содержит неподдерживаемую area '[atom_path]'.")
						if(islist(member_attributes[member_index]) && length(member_attributes[member_index]))
							return world_edit_build_dmm_parse_error("DMM blueprint содержит var edit на template area.")
						has_area = TRUE
						continue
					if(!ispath(atom_path, /obj))
						return world_edit_build_dmm_parse_error("DMM blueprint содержит неподдерживаемый atom '[atom_path]'.")
					if(!world_edit_get_blueprint_type_rule(atom_path))
						return world_edit_build_dmm_parse_error("DMM blueprint содержит неразрешенный объект '[atom_path]'.")

					var/list/var_result = world_edit_extract_dmm_entry_vars(atom_path, member_attributes[member_index])
					if(var_result["error"])
						return var_result
					raw_entries += list(list(
						"kind" = "object",
						"type" = "[atom_path]",
						"dx" = current_x - anchor_x,
						"dy" = current_y - anchor_y,
						"dz" = 0,
						"dir" = var_result["dir"],
						"vars" = var_result["vars"],
					))

				if(!has_turf || !has_area)
					return world_edit_build_dmm_parse_error("DMM blueprint cells must include /turf/template_noop and /area/template_noop.")
				current_x++

	var/list/raw_definition = list(
		"id" = blueprint_id,
		"name" = blueprint_name || blueprint_id,
		"source" = source,
		"entries" = raw_entries,
	)
	return world_edit_validate_blueprint_definition(raw_definition)

/datum/world_edit_blueprint_service/proc/world_edit_parse_blueprint_dmm_text(dmm_text, blueprint_id, blueprint_name = null, source = "dmm")
	var/safe_id = sanitize_filename("[blueprint_id]")
	if(!length(safe_id) || safe_id != "[blueprint_id]" || length(safe_id) > WORLD_EDIT_BLUEPRINT_ID_LEN)
		return list("error" = "Некорректное имя DMM blueprint.")
	if(!length(dmm_text))
		return list("error" = "DMM blueprint пуст.")

	var/datum/parsed_map/parsed
	try
		parsed = new /datum/parsed_map(dmm_text)
	catch(var/exception/parse_error)
		return list("error" = "Не удалось разобрать DMM blueprint: [parse_error].")

	if(!istype(parsed) || isnull(parsed.bounds))
		qdel(parsed)
		return list("error" = "DMM blueprint не содержит валидных координат.")

	var/datum/map_report/report = parsed.check_for_errors()
	if(report)
		qdel(parsed)
		return list("error" = "DMM blueprint не прошел map validation.")

	var/list/result = world_edit_build_blueprint_from_parsed_dmm(parsed, safe_id, blueprint_name || safe_id, source)
	qdel(parsed)
	return result

/datum/world_edit_blueprint_service/proc/world_edit_load_blueprint_from_file(file_path)
	if(!file_path || !fexists(file_path))
		return list("error" = "Файл шаблона не найден.")

	var/file_name = replacetext("[file_path]", WORLD_EDIT_BLUEPRINT_DIR, "")
	var/blueprint_id = world_edit_get_blueprint_id_from_file_name(file_name)
	if(!length("[blueprint_id]") || world_edit_get_blueprint_file_path(blueprint_id) != file_path)
		return list("error" = "Некорректный путь DMM blueprint.")

	var/dmm_text = file2text(file_path)
	var/list/load_result = world_edit_parse_blueprint_dmm_text(dmm_text, blueprint_id, blueprint_id, "server")
	if(load_result["error"])
		return load_result

	var/list/blueprint = load_result["blueprint"]
	blueprint["file_path"] = file_path
	return list("blueprint" = blueprint)

/datum/world_edit_blueprint_service/proc/world_edit_load_blueprint_library_summaries()
	. = list()

	if(!world_edit_ensure_blueprint_storage_dir())
		return

	var/list/file_names = flist(WORLD_EDIT_BLUEPRINT_DIR)
	if(!islist(file_names) || !length(file_names))
		return

	file_names = sortList(file_names)
	for(var/file_name in file_names)
		var/blueprint_id = world_edit_get_blueprint_id_from_file_name(file_name)
		if(!length("[blueprint_id]"))
			continue

		var/file_path = "[WORLD_EDIT_BLUEPRINT_DIR][file_name]"
		var/list/load_result = world_edit_load_blueprint_from_file(file_path)
		if(load_result["error"])
			. += list(list(
				"id" = blueprint_id,
				"name" = blueprint_id,
				"entry_count" = 0,
				"radius" = 0,
				"footprint_width" = 0,
				"footprint_height" = 0,
				"created_at" = "",
				"created_by" = "",
				"source" = "server",
				"valid" = FALSE,
				"error" = load_result["error"],
				"file_path" = file_path,
				"preview_mode" = "compact",
				"preview_cells" = list(),
			))
			continue

		. += list(world_edit_build_blueprint_summary(load_result["blueprint"], file_path, TRUE))

/datum/world_edit_blueprint_service/proc/world_edit_get_min_dmm_axis_size(min_offset, max_offset)
	for(var/axis_size in 1 to WORLD_EDIT_BLUEPRINT_MAX_DIMENSION)
		var/anchor = floor(axis_size / 2) + 1
		if(anchor + min_offset < 1)
			continue
		if(anchor + max_offset > axis_size)
			continue
		return axis_size
	return null

/datum/world_edit_blueprint_service/proc/world_edit_get_blueprint_dmm_dimensions(list/blueprint)
	var/list/bounds = blueprint["bounds"]
	if(!islist(bounds))
		return null

	var/width = world_edit_get_min_dmm_axis_size(text2num("[bounds["min_x"]]"), text2num("[bounds["max_x"]]"))
	var/height = world_edit_get_min_dmm_axis_size(text2num("[bounds["min_y"]]"), text2num("[bounds["max_y"]]"))
	if(isnull(width) || isnull(height))
		return null
	return list(
		"width" = width,
		"height" = height,
		"anchor_x" = floor(width / 2) + 1,
		"anchor_y" = floor(height / 2) + 1,
	)

/datum/world_edit_blueprint_service/proc/world_edit_escape_dmm_string(value)
	return replacetext(replacetext("[value]", "\\", ""), "\"", "")

/datum/world_edit_blueprint_service/proc/world_edit_serialize_dmm_object_entry(list/entry)
	var/obj_path = text2path("[entry["type"]]")
	if(!ispath(obj_path, /obj))
		return null

	var/list/vars = islist(entry["vars"]) ? entry["vars"] : list()
	var/list/var_segments = list("dir = [text2num("[entry["dir"]]") || SOUTH]")
	if(length("[vars["faction"]]"))
		var_segments += "faction = \"[world_edit_escape_dmm_string(vars["faction"])]\""
	if(!isnull(vars["turned_on"]))
		var_segments += "turned_on = [GLOB.world_edit_helpers.parse_bool(vars["turned_on"]) ? 1 : 0]"
	return "[obj_path]{[var_segments.Join(";")]}"

/datum/world_edit_blueprint_service/proc/world_edit_build_dmm_model_key(index)
	var/remaining = max(round(index) - 1, 0)
	var/list/chars = list()
	for(var/place in 1 to 3)
		var/letter_index = (remaining % 26) + 97
		chars.Insert(1, ascii2text(letter_index))
		remaining = floor(remaining / 26)
	return chars.Join("")

/datum/world_edit_blueprint_service/proc/world_edit_serialize_blueprint_to_dmm(list/blueprint)
	var/list/validation_result = world_edit_validate_blueprint_definition(blueprint)
	if(validation_result["error"])
		return validation_result

	var/list/safe_blueprint = validation_result["blueprint"]
	var/list/dimensions = world_edit_get_blueprint_dmm_dimensions(safe_blueprint)
	if(!islist(dimensions))
		return list("error" = "Шаблон невозможно уложить в DMM лимит [WORLD_EDIT_BLUEPRINT_MAX_DIMENSION]x[WORLD_EDIT_BLUEPRINT_MAX_DIMENSION].")

	var/list/cell_entries = list()
	for(var/list/entry as anything in safe_blueprint["entries"])
		var/x = dimensions["anchor_x"] + text2num("[entry["dx"]]")
		var/y = dimensions["anchor_y"] + text2num("[entry["dy"]]")
		if(x < 1 || x > dimensions["width"] || y < 1 || y > dimensions["height"])
			return list("error" = "Запись шаблона выходит за границы DMM.")
		LAZYADDASSOCLIST(cell_entries, "[x],[y]", entry)

	var/list/model_to_key = list()
	var/list/model_lines = list()
	var/list/grid_lines = list()
	var/noop_area_model = "/area/template_noop"
	for(var/y = dimensions["height"], y >= 1, y--)
		var/list/line_keys = list()
		for(var/x = 1, x <= dimensions["width"], x++)
			var/list/entries = cell_entries["[x],[y]"]
			var/list/model_parts = list()
			var/turf_model = "/turf/template_noop"
			if(islist(entries))
				for(var/list/entry as anything in entries)
					var/atom_path = text2path("[entry["type"]]")
					if(ispath(atom_path, /turf))
						turf_model = "[atom_path]"
						continue
					var/object_model = world_edit_serialize_dmm_object_entry(entry)
					if(!length(object_model))
						return list("error" = "Не удалось сериализовать объект шаблона.")
					model_parts += object_model
			model_parts += turf_model
			model_parts += noop_area_model
			var/model_text = model_parts.Join(",")
			var/model_key = model_to_key[model_text]
			if(!length("[model_key]"))
				model_key = world_edit_build_dmm_model_key(length(model_lines) + 1)
				model_to_key[model_text] = model_key
				model_lines += "\"[model_key]\" = ([model_text])"
			line_keys += model_key
		grid_lines += line_keys.Join("")

	var/list/output = list()
	output += model_lines
	output += ""
	output += "(1,1,1) = {\"\n[grid_lines.Join("\n")]\n\"}"
	return list(
		"blueprint" = safe_blueprint,
		"dmm_text" = output.Join("\n"),
	)

/datum/world_edit_blueprint_service/proc/world_edit_save_blueprint_definition(list/blueprint)
	if(!islist(blueprint))
		return FALSE
	if(!world_edit_ensure_blueprint_storage_dir())
		return FALSE

	var/blueprint_id = sanitize_filename("[blueprint["id"]]")
	if(!length(blueprint_id))
		return FALSE
	var/blueprint_name = trim(sanitize_text("[blueprint["name"]]", ""))
	if(!length(blueprint_name))
		blueprint_name = blueprint_id
	blueprint_name = copytext(blueprint_name, 1, WORLD_EDIT_BLUEPRINT_NAME_MAX_LEN + 1)
	blueprint["id"] = blueprint_id
	blueprint["name"] = blueprint_name

	var/file_path = world_edit_get_blueprint_file_path(blueprint_id)
	if(!file_path)
		return FALSE

	var/list/serialize_result = world_edit_serialize_blueprint_to_dmm(blueprint)
	if(serialize_result["error"])
		return FALSE

	var/dmm_text = "[serialize_result["dmm_text"]]"
	rustg_file_write(dmm_text, file_path)
	if(!fexists(file_path))
		return FALSE
	if(file2text(file_path) != dmm_text)
		return FALSE
	return file_path

/datum/world_edit_blueprint_service/proc/world_edit_import_blueprint_file(import_file)
	if(!import_file)
		return list("error" = "Файл импорта не выбран.")
	var/blueprint_id = world_edit_get_blueprint_id_from_file_name("[import_file]")
	if(!length("[blueprint_id]"))
		return list("error" = "Имя файла импорта должно быть безопасным `.dmm` именем.")
	var/file_path = world_edit_get_blueprint_file_path(blueprint_id)
	if(!file_path)
		return list("error" = "Некорректное имя DMM blueprint.")
	if(fexists(file_path))
		return list("error" = "DMM blueprint с таким именем уже существует.")

	var/dmm_text = file2text(import_file)
	var/list/load_result = world_edit_parse_blueprint_dmm_text(dmm_text, blueprint_id, blueprint_id, "import")
	if(load_result["error"])
		return load_result

	var/saved_path = world_edit_save_blueprint_definition(load_result["blueprint"])
	if(!saved_path)
		return list("error" = "Не удалось сохранить импортированный DMM blueprint.")
	return list("blueprint" = load_result["blueprint"], "file_path" = saved_path)

/datum/world_edit_blueprint_service/proc/world_edit_delete_blueprint_file(blueprint_id)
	var/file_path = world_edit_get_blueprint_file_path(blueprint_id)
	if(!file_path || !fexists(file_path))
		return list("error" = "DMM blueprint не найден.")
	if(!fdel(file_path))
		return list("error" = "Не удалось удалить DMM blueprint.")
	return list("deleted" = TRUE)

/datum/world_edit_blueprint_service/proc/world_edit_rename_blueprint_file(old_blueprint_id, new_blueprint_id)
	var/old_path = world_edit_get_blueprint_file_path(old_blueprint_id)
	if(!old_path || !fexists(old_path))
		return list("error" = "DMM blueprint не найден.")

	var/safe_new_id = sanitize_filename("[new_blueprint_id]")
	if(!length(safe_new_id) || safe_new_id != "[new_blueprint_id]" || safe_new_id in list(".", ".."))
		return list("error" = "Новое имя DMM blueprint небезопасно.")
	if(length(safe_new_id) > WORLD_EDIT_BLUEPRINT_ID_LEN)
		return list("error" = "Новое имя DMM blueprint слишком длинное.")

	var/new_path = world_edit_get_blueprint_file_path(safe_new_id)
	if(!new_path)
		return list("error" = "Новое имя DMM blueprint некорректно.")
	if(new_path == old_path)
		return list("blueprint_id" = safe_new_id, "file_path" = old_path)
	if(fexists(new_path))
		return list("error" = "DMM blueprint с таким именем уже существует.")

	if(!fcopy(old_path, new_path))
		return list("error" = "Unable to copy DMM blueprint to the new name.")
	if(!fexists(new_path))
		return list("error" = "Unable to verify copied DMM blueprint after rename.")
	if(!fdel(old_path))
		fdel(new_path)
		return list("error" = "Unable to remove old DMM blueprint after rename.")
	return list("blueprint_id" = safe_new_id, "file_path" = new_path)
