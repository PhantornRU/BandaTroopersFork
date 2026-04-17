/datum/world_edit_generator/outpost_radius/get_ui_fields(list/current_params)
	var/place_sentries = GLOB.world_edit_helpers.parse_bool(current_params["place_sentries"])
	var/family_id = resolve_outpost_family_id(current_params["family"])
	if(!family_id)
		family_id = get_default_outpost_family_id()
	var/layout_id = resolve_outpost_layout_id(current_params["layout_variant"])
	if(!layout_id)
		layout_id = get_default_outpost_layout_id()
	var/list/family_profile = get_outpost_family_profile(family_id)
	var/list/family_mix = islist(family_profile["barricade_mix"]) ? family_profile["barricade_mix"] : list()
	var/default_barricade_path = family_profile["default_barricade_path"] || /datum/human_ai_defense/barricade/metal
	var/default_sentry_path = family_profile["default_sentry_path"] || /datum/human_ai_defense/defense/sentry/uscm
	var/list/faction_options = list()
	for(var/faction in valid_factions)
		faction_options += list(list(
			"label" = "[faction]",
			"value" = faction,
		))

	return list(
		list(
			"id" = "family",
			"label" = "Template Family",
			"kind" = "select",
			"group" = "Layout",
			"description" = "Deterministic defaults for barricade mix, sentry type, and passage layout.",
			"value" = current_params["family"] || family_id,
			"options" = build_family_options(),
		),
		list(
			"id" = "layout_variant",
			"label" = "Layout Variant",
			"kind" = "select",
			"group" = "Layout",
			"description" = "Choose where passages stay open and how the outpost faces incoming traffic.",
			"value" = current_params["layout_variant"] || layout_id,
			"options" = build_layout_options(),
		),
		list(
			"id" = "opening_width",
			"label" = "Passage Width",
			"kind" = "select",
			"group" = "Layout",
			"description" = "Override how wide each planned passage stays open.",
			"value" = current_params["opening_width"] || "profile",
			"options" = build_opening_width_options(),
		),
		list(
			"id" = "radius",
			"label" = "Perimeter Offset",
			"kind" = "number",
			"group" = "Layout",
			"description" = "Offset thickness around the resolved footprint before the perimeter shell is built.",
			"validate_hint" = "Allowed range: 1..10",
			"value" = text2num("[current_params["radius"]]") || 4,
			"min" = 1,
			"max" = 10,
			"step" = 1,
		),
		list(
			"id" = "barricade_path",
			"label" = "Barricade Type",
			"kind" = "select",
			"group" = "Barricades",
			"description" = "Whitelisted barricade type from human_ai_defense. The family preset uses this as the leading barricade mix entry.",
			"value" = "[current_params["barricade_path"] || default_barricade_path]",
			"options" = build_type_options(allowed_barricade_types),
			"visible" = FALSE,
		),
		list(
			"id" = "barricade_pattern",
			"label" = "Barricade Pattern",
			"kind" = "select",
			"group" = "Barricades",
			"description" = "Control how materials repeat around the perimeter.",
			"value" = current_params["barricade_pattern"] || "profile",
			"options" = build_barricade_pattern_options(),
			"visible" = length(family_mix) > 1,
		),
		list(
			"id" = "place_sentries",
			"label" = "Place Cardinal Sentries",
			"kind" = "boolean",
			"group" = "Sentries",
			"description" = "Adds cardinal sentries just inside each intended passage.",
			"value" = place_sentries,
		),
		list(
			"id" = "guard_mode",
			"label" = "Guard Coverage",
			"kind" = "select",
			"group" = "Sentries",
			"description" = "Choose whether sentries cover only passages, all sides, or the variant defaults.",
			"value" = current_params["guard_mode"] || "layout",
			"options" = build_guard_mode_options(),
			"visible" = place_sentries,
			"disabled" = !place_sentries,
		),
		list(
			"id" = "sentry_path",
			"label" = "Sentry Type",
			"kind" = "select",
			"group" = "Sentries",
			"description" = "Whitelisted sentry type for the optional inner guard positions.",
			"value" = "[current_params["sentry_path"] || default_sentry_path]",
			"options" = build_type_options(allowed_sentry_types),
			"visible" = place_sentries,
			"disabled" = !place_sentries,
		),
		list(
			"id" = "faction",
			"label" = "IFF Faction",
			"kind" = "select",
			"group" = "Sentries",
			"description" = "Faction passed to human_ai_defense sentries.",
			"value" = current_params["faction"] || FACTION_MARINE,
			"options" = faction_options,
			"visible" = place_sentries,
			"disabled" = !place_sentries,
		),
		list(
			"id" = "turned_on",
			"label" = "Power On Sentries",
			"kind" = "boolean",
			"group" = "Sentries",
			"description" = "Turns sentries on immediately after placement.",
			"value" = current_params["turned_on"] ? TRUE : FALSE,
			"visible" = place_sentries,
			"disabled" = !place_sentries,
		),
	)

/datum/world_edit_generator/outpost_radius/set_ui_param(mob/user, list/current_params, param_id, value)
	var/list/new_params = current_params.Copy()

	switch(param_id)
		if("family")
			var/family_id = resolve_outpost_family_id(value)
			if(!family_id)
				return "Invalid outpost family selected."
			new_params[param_id] = family_id
			var/list/family_profile = get_outpost_family_profile(family_id)
			new_params["barricade_path"] = family_profile["default_barricade_path"] || /datum/human_ai_defense/barricade/metal
			var/current_sentry_path = resolve_whitelisted_type(new_params["sentry_path"], allowed_sentry_types, /datum/human_ai_defense/defense/sentry)
			if(!current_sentry_path)
				new_params["sentry_path"] = family_profile["default_sentry_path"] || /datum/human_ai_defense/defense/sentry/uscm

		if("layout_variant")
			var/layout_id = resolve_outpost_layout_id(value)
			if(!layout_id)
				return "Invalid outpost layout selected."
			new_params[param_id] = layout_id

		if("opening_width")
			var/opening_width = resolve_opening_width(value, get_outpost_layout_profile(resolve_outpost_layout_id(new_params["layout_variant"]) || get_default_outpost_layout_id()))
			if(isnull(opening_width))
				return "Invalid outpost passage width selected."
			new_params[param_id] = "[value]"

		if("radius")
			new_params[param_id] = clamp(text2num("[value]"), 1, 10)

		if("barricade_path")
			var/path_value = resolve_whitelisted_type(value, allowed_barricade_types, /datum/human_ai_defense/barricade, get_outpost_family_profile(resolve_outpost_family_id(new_params["family"]) || get_default_outpost_family_id())["default_barricade_path"])
			if(!path_value)
				return "Invalid barricade type selected."
			new_params[param_id] = path_value

		if("barricade_pattern")
			var/pattern_value = resolve_barricade_pattern(value, get_outpost_family_profile(resolve_outpost_family_id(new_params["family"]) || get_default_outpost_family_id()))
			if(isnull(pattern_value))
				return "Invalid barricade pattern selected."
			new_params[param_id] = "[value]"

		if("place_sentries")
			new_params[param_id] = GLOB.world_edit_helpers.parse_bool(value)

		if("guard_mode")
			var/guard_mode = resolve_guard_mode(value)
			if(isnull(guard_mode))
				return "Invalid outpost guard mode selected."
			new_params[param_id] = "[value]"

		if("sentry_path")
			var/path_value = resolve_whitelisted_type(value, allowed_sentry_types, /datum/human_ai_defense/defense/sentry, get_outpost_family_profile(resolve_outpost_family_id(new_params["family"]) || get_default_outpost_family_id())["default_sentry_path"])
			if(!path_value)
				return "Invalid sentry type selected."
			new_params[param_id] = path_value

		if("faction")
			if(!("[value]" in valid_factions))
				return "Invalid sentry faction selected."
			new_params[param_id] = "[value]"

		if("turned_on")
			new_params[param_id] = GLOB.world_edit_helpers.parse_bool(value)

		else
			return ..()

	return new_params

/datum/world_edit_generator/outpost_radius/get_apply_confirmation_text(list/params)
	var/family_id = resolve_outpost_family_id(params["family"])
	if(!family_id)
		family_id = get_default_outpost_family_id()
	var/layout_id = resolve_outpost_layout_id(params["layout_variant"])
	if(!layout_id)
		layout_id = get_default_outpost_layout_id()
	var/list/family_profile = get_outpost_family_profile(family_id)
	var/list/layout_profile = get_outpost_layout_profile(layout_id)
	return "Применить профиль '[family_profile["label"] || "Outpost"] / [layout_profile["label"] || "Crossroads"]' с отступом периметра [params["radius"]]?"

/datum/world_edit_generator/outpost_radius/get_params_short(list/params)
	return "family=[params["family"] || get_default_outpost_family_id()] layout=[params["layout_variant"] || get_default_outpost_layout_id()] width=[params["opening_width"] || "profile"] perimeter_offset=[params["radius"]] shape=[manager?.get_effective_placement_shape() || WORLD_EDIT_SHAPE_POINT] mode=[manager?.get_effective_placement_mode() || "single"] dir=[GLOB.world_edit_helpers.dir_to_label(manager?.get_effective_placement_dir() || NORTH)] barricade=[params["barricade_path"]] barricade_pattern=[params["barricade_pattern"] || "profile"] sentries=[params["place_sentries"]] guard_mode=[params["guard_mode"] || "layout"] sentry_type=[params["sentry_path"]]"
