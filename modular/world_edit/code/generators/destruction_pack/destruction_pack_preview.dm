/datum/world_edit_generator/destruction_pack/proc/build_preview_style_catalog(datum/world_edit_plan/plan = null)
	var/fire_color = istype(plan) ? sanitize_hexcolor(plan.metadata["persistent_fire_preview_color"], "") : ""
	if(!length(fire_color))
		fire_color = get_persistent_fire_preset_color(get_default_persistent_fire_color_id())

	return list(
		"move" = list(
			"icon_state" = "greenOverlay",
			"color" = rgb(78, 142, 255),
			"priority" = 10,
		),
		"fire" = list(
			"icon_state" = "greenOverlay",
			"color" = fire_color,
			"priority" = 20,
		),
		"damage" = list(
			"icon_state" = "greenOverlay",
			"color" = rgb(184, 92, 255),
			"priority" = 30,
		),
		"blast" = list(
			"icon_state" = "greenOverlay",
			"color" = rgb(255, 78, 78),
			"priority" = 40,
		),
	)

/datum/world_edit_generator/destruction_pack/proc/register_preview_style(list/style_lookup, turf/target_turf, list/style_spec)
	if(!islist(style_lookup) || !istype(target_turf) || !islist(style_spec))
		return

	var/list/current_style = style_lookup[target_turf]
	if(islist(current_style) && text2num("[current_style["priority"]]") > text2num("[style_spec["priority"]]"))
		return

	style_lookup[target_turf] = list(
		"icon_state" = "[style_spec["icon_state"] || "greenOverlay"]",
		"color" = style_spec["color"],
		"priority" = text2num("[style_spec["priority"]]") || 0,
	)

/datum/world_edit_generator/destruction_pack/proc/build_plan_preview_images(datum/world_edit_plan/plan)
	var/list/preview_images = list()
	if(!istype(plan))
		return preview_images

	var/list/style_catalog = build_preview_style_catalog(plan)
	var/list/style_lookup = list()

	for(var/list/placement as anything in plan.placements)
		switch("[placement["kind"]]")
			if("move")
				register_preview_style(style_lookup, placement["source_turf"], style_catalog["move"])
				register_preview_style(style_lookup, placement["destination_turf"], style_catalog["move"])
				for(var/turf/path_turf as anything in placement["path_turfs"])
					register_preview_style(style_lookup, path_turf, style_catalog["move"])
			if("fire")
				register_preview_style(style_lookup, placement["turf"], style_catalog["fire"])

	for(var/list/deletion as anything in plan.deletions)
		switch("[deletion["kind"]]")
			if("blast")
				register_preview_style(style_lookup, deletion["center_turf"], style_catalog["blast"])
			if("damage")
				for(var/turf/damage_turf as anything in deletion["area_turfs"])
					register_preview_style(style_lookup, damage_turf, style_catalog["damage"])

	var/list/group_lookup = list()
	for(var/turf/target_turf as anything in style_lookup)
		var/list/style = style_lookup[target_turf]
		if(!istype(target_turf) || !islist(style))
			continue

		var/icon_state = "[style["icon_state"] || "greenOverlay"]"
		var/color = style["color"]
		var/group_key = "[icon_state]::[color]"
		if(!islist(group_lookup[group_key]))
			group_lookup[group_key] = list(
				"turfs" = list(),
				"icon_state" = icon_state,
				"color" = color,
			)
		var/list/group = group_lookup[group_key]
		group["turfs"] += target_turf

	var/list/groups = list()
	for(var/group_key in group_lookup)
		groups += list(group_lookup[group_key])

	return GLOB.world_edit_helpers.build_grouped_turf_preview_images(groups)
