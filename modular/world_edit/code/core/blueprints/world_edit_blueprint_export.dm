/datum/world_edit_blueprint_service/proc/world_edit_resolve_defense_spawn_path(defense_path)
	if(!ispath(defense_path, /datum/human_ai_defense))
		return null

	var/static/list/defense_spawn_path_cache = list()
	var/cache_key = "[defense_path]"
	var/cached_obj_path = defense_spawn_path_cache[cache_key]
	if(ispath(cached_obj_path, /obj))
		return cached_obj_path

	var/datum/human_ai_defense/definition = new defense_path()
	var/obj_path = definition.path_to_spawn
	qdel(definition)
	if(ispath(obj_path, /obj))
		defense_spawn_path_cache[cache_key] = obj_path
	return obj_path

/datum/world_edit_blueprint_service/proc/world_edit_build_outpost_recipe_footprint_offsets(datum/world_edit_plan/plan, turf/anchor_turf)
	var/list/offsets = list()
	if(!istype(anchor_turf))
		return offsets
	if(!("[plan?.metadata["shape_mode"]]" in list("footprint_offset", "component_footprint_offset")))
		return list(list(0, 0))

	var/list/footprint_turfs = islist(plan?.metadata["base_shape_turfs"]) ? plan.metadata["base_shape_turfs"] : null
	if(!islist(footprint_turfs) || !length(footprint_turfs))
		return list(list(0, 0))

	var/list/offset_lookup = list()
	for(var/turf/footprint_turf as anything in footprint_turfs)
		if(!istype(footprint_turf) || footprint_turf.z != anchor_turf.z)
			continue
		var/dx = footprint_turf.x - anchor_turf.x
		var/dy = footprint_turf.y - anchor_turf.y
		var/offset_key = "[dx],[dy]"
		if(offset_lookup[offset_key])
			continue
		offset_lookup[offset_key] = TRUE
		offsets += list(list(dx, dy))

	if(!length(offsets))
		offsets += list(list(0, 0))
	return offsets

/datum/world_edit_blueprint_service/proc/world_edit_build_outpost_recipe_from_plan(datum/world_edit_plan/plan, turf/anchor_turf)
	if(!istype(plan) || !istype(anchor_turf))
		return null

	var/list/metadata = islist(plan.metadata) ? plan.metadata : list()
	if(!length("[metadata["defense_profile"]]") || !length("[metadata["layout_variant"]]"))
		return null

	var/primary_material_share_percent = text2num("[metadata["primary_material_share_percent"]]")
	if(!isnum(primary_material_share_percent))
		primary_material_share_percent = 100
	var/opening_width = world_edit_parse_strict_integer(metadata["opening_width"])
	if(isnull(opening_width))
		opening_width = 1

	return list(
		"defense_profile" = "[metadata["defense_profile"]]",
		"layout_variant" = "[metadata["layout_variant"]]",
		"placement_dir" = text2num("[metadata["placement_dir"]]") || NORTH,
		"radius" = text2num("[metadata["radius"]]") || 0,
		"opening_width" = opening_width,
		"primary_material_path" = "[metadata["primary_material_path"]]",
		"secondary_material_path" = "[metadata["secondary_material_path"] || metadata["primary_material_path"]]",
		"barricade_pattern" = "[metadata["barricade_pattern"] || "uniform"]",
		"primary_material_share_percent" = primary_material_share_percent,
		"place_barricade_doors" = GLOB.world_edit_helpers.parse_bool(metadata["place_barricade_doors"]) ? TRUE : FALSE,
		"primary_door_path" = "[metadata["primary_door_path"] || "follow_material"]",
		"secondary_door_path" = "[metadata["secondary_door_path"] || "follow_material"]",
		"faction" = "[metadata["faction"] || FACTION_MARINE]",
		"turned_on" = GLOB.world_edit_helpers.parse_bool(metadata["turned_on"]) ? TRUE : FALSE,
		"sentry_layer_profile" = "[metadata["sentry_layer_profile"] || "none"]",
		"sentry_type" = "[metadata["sentry_type"] || /datum/human_ai_defense/defense/sentry/uscm]",
		"extra_defense_layer_profile" = "[metadata["extra_defense_layer_profile"] || "none"]",
		"extra_defense_type" = "[metadata["extra_defense_type"] || /datum/human_ai_defense/defense/tesla]",
		"flag_type" = "[metadata["flag_type"] || "none"]",
		"wire_layer_profile" = "[metadata["wire_layer_profile"] || "none"]",
		"wire_offset" = text2num("[metadata["wire_offset"]]") || 3,
		"wire_rows" = text2num("[metadata["wire_rows"]]") || 0,
		"wire_row_step" = text2num("[metadata["wire_row_step"]]") || 1,
		"wire_spacing" = text2num("[metadata["wire_spacing"]]") || 2,
		"wire_concentration_percent" = text2num("[metadata["wire_concentration_percent"]]") || 0,
		"minefield_profile" = "[metadata["minefield_profile"] || "none"]",
		"mine_type" = "[metadata["mine_type"] || /datum/human_ai_defense/mine/claymore]",
		"minefield_offset" = text2num("[metadata["minefield_offset"]]") || 3,
		"minefield_depth" = text2num("[metadata["minefield_depth"]]") || 0,
		"minefield_density_percent" = text2num("[metadata["minefield_density_percent"]]") || 0,
		"minefield_seed" = text2num("[metadata["minefield_seed"]]") || 0,
		"footprint_offsets" = world_edit_build_outpost_recipe_footprint_offsets(plan, anchor_turf),
	)

/datum/world_edit_blueprint_service/proc/world_edit_export_blueprint_from_outpost_plan(datum/world_edit_plan/plan, turf/anchor_turf, blueprint_name, actor_ckey)
	if(!istype(plan))
		return list("error" = "Нет готового плана форпоста для экспорта.")
	if(!anchor_turf)
		return list("error" = "Не удалось определить опорный тайл шаблона.")
	if(!length(plan.placements))
		return list("error" = "Текущий план форпоста не содержит размещаемых элементов.")

	var/list/entries = list()
	var/list/spawn_path_cache = list()
	var/list/relative_coord_lookup = list()
	for(var/list/placement as anything in plan.placements)
		var/placement_kind = "[placement["kind"]]"
		if(!(placement_kind in list("barricade", "sentry", "wire_object", "mine", "extra_defense")))
			return list("error" = "Текущий план содержит тип размещения, который Blueprint Lite не поддерживает.")

		var/turf/target_turf = placement["turf"]
		if(!istype(target_turf) || target_turf.z != anchor_turf.z)
			return list("error" = "Текущий план содержит размещение вне допустимого z-уровня.")

		var/defense_path = placement["defense_path"]
		var/obj_path = spawn_path_cache["[defense_path]"]
		if(!obj_path)
			obj_path = world_edit_resolve_defense_spawn_path(defense_path)
			spawn_path_cache["[defense_path]"] = obj_path

		var/list/rule = world_edit_get_blueprint_type_rule(obj_path)
		if(!rule)
			return list("error" = "Текущий план содержит неразрешенный размещаемый тип.")

		var/dir_value = text2num("[placement["dir"]]")
		if(!(dir_value in GLOB.cardinals))
			return list("error" = "Текущий план содержит некардинальное направление.")

		var/list/entry_vars = list()
		if(placement_kind in list("sentry", "extra_defense"))
			var/faction = "[placement["faction"]]"
			if(length(faction) && !(faction in GLOB.world_edit_blueprint_valid_factions))
				return list("error" = "Текущий план содержит недопустимую фракцию обороны.")
			if(length(faction))
				entry_vars["faction"] = faction
			entry_vars["turned_on"] = GLOB.world_edit_helpers.parse_bool(placement["turned_on"]) ? TRUE : FALSE
		else if(placement_kind == "mine")
			var/faction = "[placement["faction"]]"
			if(length(faction) && !(faction in GLOB.world_edit_blueprint_valid_factions))
				return list("error" = "Текущий план содержит недопустимую фракцию мин.")
			if(length(faction))
				entry_vars["faction"] = faction

		var/dx = target_turf.x - anchor_turf.x
		var/dy = target_turf.y - anchor_turf.y
		var/coord_key = world_edit_build_blueprint_relative_slot_key(obj_path, dx, dy, 0, dir_value)
		if(!length(coord_key))
			return list("error" = "Текущий план содержит недопустимый слот направленного размещения.")
		if(relative_coord_lookup[coord_key])
			return list("error" = "Текущий план содержит несколько размещений для одного и того же относительного слота.")
		relative_coord_lookup[coord_key] = TRUE

		entries += list(list(
			"type" = "[obj_path]",
			"dx" = dx,
			"dy" = dy,
			"dz" = 0,
			"dir" = dir_value,
			"vars" = entry_vars,
		))

	if(length(entries) > WORLD_EDIT_BLUEPRINT_MAX_ENTRIES)
		return list("error" = "Текущий план превышает лимит записей Blueprint Lite.")

	var/list/bounds = world_edit_compute_blueprint_bounds(entries)
	if(bounds["radius"] > WORLD_EDIT_BLUEPRINT_MAX_RADIUS)
		return list("error" = "Текущий план превышает лимит радиуса Blueprint Lite.")

	var/list/outpost_recipe = world_edit_build_outpost_recipe_from_plan(plan, anchor_turf)

	return list("blueprint" = list(
		"id" = world_edit_build_blueprint_id(),
		"name" = copytext(trim(sanitize_text("[blueprint_name]", "Форпостный шаблон")), 1, WORLD_EDIT_BLUEPRINT_NAME_MAX_LEN + 1),
		"created_at" = time_stamp(),
		"created_by" = ckey("[actor_ckey]"),
		"source" = "outpost_radius_plan",
		"bounds" = bounds,
		"entries" = entries,
		"outpost_recipe" = outpost_recipe,
	))
