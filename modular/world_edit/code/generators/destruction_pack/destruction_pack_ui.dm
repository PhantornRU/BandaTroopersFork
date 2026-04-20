/datum/world_edit_generator/destruction_pack/get_ui_fields(list/current_params)
	var/scatter_enabled = GLOB.world_edit_helpers.parse_bool(current_params["scatter_enabled"])
	var/persistent_fire_enabled = GLOB.world_edit_helpers.parse_bool(current_params["persistent_fire_enabled"])
	var/persistent_fire_mode = resolve_persistent_fire_mode(current_params["persistent_fire_mode"]) || get_default_persistent_fire_mode()
	var/persistent_fire_color_id = resolve_persistent_fire_color_id(current_params["persistent_fire_color"]) || get_default_persistent_fire_color_id()
	var/persistent_fire_custom_color = trim(sanitize_text(current_params["persistent_fire_custom_color"], ""))
	var/blast_enabled = GLOB.world_edit_helpers.parse_bool(current_params["blast_enabled"])
	var/damage_profile = resolve_damage_profile(current_params["damage_profile"])

	return list(
		list(
			"id" = "radius",
			"label" = "Impact Radius",
			"kind" = "number",
			"group" = "Area",
			"description" = "Influence radius around each resolved shape seed. Effects weaken toward the radius edge.",
			"validate_hint" = "Allowed range: 1..[WORLD_EDIT_DESTRUCTION_RADIUS_MAX]",
			"value" = text2num("[current_params["radius"]]") || 3,
			"min" = 1,
			"max" = WORLD_EDIT_DESTRUCTION_RADIUS_MAX,
			"step" = 1,
		),
		list(
			"id" = WORLD_EDIT_RADIUS_POLICY_ONLY_CLEAR_TILES,
			"label" = "Only clear tiles",
			"kind" = "boolean",
			"group" = "Area",
			"description" = "Radius expansion skips dense tile centers. The selected footprint stays valid even when it starts on blocked tiles.",
			"value" = isnull(current_params[WORLD_EDIT_RADIUS_POLICY_ONLY_CLEAR_TILES]) ? TRUE : GLOB.world_edit_helpers.parse_bool(current_params[WORLD_EDIT_RADIUS_POLICY_ONLY_CLEAR_TILES]),
		),
		list(
			"id" = WORLD_EDIT_RADIUS_POLICY_ONLY_REACHABLE_TILES,
			"label" = "Only reachable tiles",
			"kind" = "boolean",
			"group" = "Area",
			"description" = "Radius expansion keeps only tiles reachable through adjacent clear tiles from the selected footprint.",
			"value" = isnull(current_params[WORLD_EDIT_RADIUS_POLICY_ONLY_REACHABLE_TILES]) ? FALSE : GLOB.world_edit_helpers.parse_bool(current_params[WORLD_EDIT_RADIUS_POLICY_ONLY_REACHABLE_TILES]),
		),
		list(
			"id" = WORLD_EDIT_RADIUS_POLICY_WINDOWS_BLOCKERS,
			"label" = "Treat windows as blockers",
			"kind" = "boolean",
			"group" = "Area",
			"description" = "Counts windows as blockers for clear/reachable radius filtering.",
			"value" = isnull(current_params[WORLD_EDIT_RADIUS_POLICY_WINDOWS_BLOCKERS]) ? TRUE : GLOB.world_edit_helpers.parse_bool(current_params[WORLD_EDIT_RADIUS_POLICY_WINDOWS_BLOCKERS]),
		),
		list(
			"id" = "shuffle_enabled",
			"label" = "Shuffle Targets",
			"kind" = "boolean",
			"group" = "Modes",
			"description" = "Randomly reassigns movable targets to tiles within the preview area.",
			"value" = GLOB.world_edit_helpers.parse_bool(current_params["shuffle_enabled"]),
		),
		list(
			"id" = "scatter_enabled",
			"label" = "Scatter Targets",
			"kind" = "boolean",
			"group" = "Modes",
			"description" = "Moves targets step-by-step inside the selected area.",
			"value" = GLOB.world_edit_helpers.parse_bool(current_params["scatter_enabled"]),
		),
		list(
			"id" = "persistent_fire_enabled",
			"label" = "Persistent Fire",
			"kind" = "boolean",
			"group" = "Fire",
			"description" = "Creates owned persistent fire tiles inside the selected area. Cleanup is available from the owned-effects stack. Hard cap: [get_persistent_fire_cap()] tiles.",
			"value" = persistent_fire_enabled,
		),
		list(
			"id" = "persistent_fire_density",
			"label" = "Fire Density",
			"kind" = "number",
			"group" = "Fire",
			"description" = "Percent of open candidate tiles used for persistent fire before the hard cap is applied.",
			"validate_hint" = "Allowed range: [get_persistent_fire_density_min()]..[get_persistent_fire_density_max()]%",
			"value" = normalize_persistent_fire_density_percent(current_params["persistent_fire_density"]),
			"min" = get_persistent_fire_density_min(),
			"max" = get_persistent_fire_density_max(),
			"step" = 1,
			"visible" = persistent_fire_enabled,
			"disabled" = !persistent_fire_enabled,
		),
		list(
			"id" = "persistent_fire_mode",
			"label" = "Fire Mode",
			"kind" = "select",
			"group" = "Fire",
			"description" = "Choose whether the persistent fire burns targets or stays decorative-only.",
			"value" = persistent_fire_mode,
			"options" = build_persistent_fire_mode_options(),
			"visible" = persistent_fire_enabled,
			"disabled" = !persistent_fire_enabled,
		),
		list(
			"id" = "persistent_fire_color",
			"label" = "Fire Color",
			"kind" = "select",
			"group" = "Fire",
			"description" = "Select the flame tint used both in preview and at runtime.",
			"value" = persistent_fire_color_id,
			"options" = build_persistent_fire_color_options(),
			"visible" = persistent_fire_enabled,
			"disabled" = !persistent_fire_enabled,
		),
		list(
			"id" = "persistent_fire_custom_color",
			"label" = "Custom Fire Color",
			"kind" = "text",
			"group" = "Fire",
			"description" = "Custom fire hex color in the form #RRGGBB.",
			"validate_hint" = "Use a full hex color, for example #4fc3ff.",
			"placeholder" = "#RRGGBB",
			"value" = persistent_fire_custom_color,
			"visible" = persistent_fire_enabled && persistent_fire_color_id == "custom",
			"disabled" = !persistent_fire_enabled || persistent_fire_color_id != "custom",
		),
		list(
			"id" = "blast_enabled",
			"label" = "Blast",
			"kind" = "boolean",
			"group" = "Blast",
			"description" = "Triggers a controlled cell explosion at the selected center after movement and fire placement. This disables undo for the operation.",
			"value" = blast_enabled,
		),
		list(
			"id" = "blast_power",
			"label" = "Blast Power",
			"kind" = "number",
			"group" = "Blast",
			"description" = "Explosion strength for the controlled blast.",
			"validate_hint" = "Allowed range: [get_blast_power_min()]..[get_blast_power_max()]",
			"value" = text2num("[current_params["blast_power"]]") || get_blast_power_default(),
			"min" = get_blast_power_min(),
			"max" = get_blast_power_max(),
			"step" = 50,
		),
		list(
			"id" = "blast_falloff",
			"label" = "Blast Falloff",
			"kind" = "number",
			"group" = "Blast",
			"description" = "Explosion falloff for the controlled blast.",
			"validate_hint" = "Allowed range: [get_blast_falloff_min()]..[get_blast_falloff_max()]",
			"value" = text2num("[current_params["blast_falloff"]]") || get_blast_falloff_default(),
			"min" = get_blast_falloff_min(),
			"max" = get_blast_falloff_max(),
			"step" = 50,
		),
		list(
			"id" = "damage_profile",
			"label" = "Damage Profile",
			"kind" = "select",
			"group" = "Damage",
			"description" = "Applies structural and tile damage directly to the selected area without a blast curve. This disables undo for the operation.",
			"value" = damage_profile,
			"options" = build_damage_profile_options(),
		),
		list(
			"id" = "scatter_steps",
			"label" = "Scatter Steps",
			"kind" = "number",
			"group" = "Modes",
			"description" = "Number of random movement steps when scatter is enabled.",
			"validate_hint" = "Allowed range: 1..[WORLD_EDIT_DESTRUCTION_MAX_SCATTER_STEPS]",
			"value" = text2num("[current_params["scatter_steps"]]") || 2,
			"min" = 1,
			"max" = WORLD_EDIT_DESTRUCTION_MAX_SCATTER_STEPS,
			"step" = 1,
			"visible" = scatter_enabled,
			"disabled" = !scatter_enabled,
		),
		list(
			"id" = "max_atoms",
			"label" = "Max Targets",
			"kind" = "number",
			"group" = "Limits",
			"description" = "Hard cap for movable targets processed by one apply when shuffle or scatter is enabled.",
			"validate_hint" = "Allowed range: 1..[WORLD_EDIT_DESTRUCTION_MAX_ATOMS]",
			"value" = text2num("[current_params["max_atoms"]]") || 60,
			"min" = 1,
			"max" = WORLD_EDIT_DESTRUCTION_MAX_ATOMS,
			"step" = 1,
		),
	)

/datum/world_edit_generator/destruction_pack/set_ui_param(mob/user, list/current_params, param_id, value)
	var/list/new_params = current_params.Copy()

	switch(param_id)
		if("radius")
			new_params[param_id] = clamp(text2num("[value]"), 1, WORLD_EDIT_DESTRUCTION_RADIUS_MAX)

		if(WORLD_EDIT_RADIUS_POLICY_ONLY_CLEAR_TILES)
			new_params[param_id] = GLOB.world_edit_helpers.parse_bool(value)
			if(!new_params[param_id] && GLOB.world_edit_helpers.parse_bool(new_params[WORLD_EDIT_RADIUS_POLICY_ONLY_REACHABLE_TILES]))
				new_params[WORLD_EDIT_RADIUS_POLICY_ONLY_REACHABLE_TILES] = FALSE

		if(WORLD_EDIT_RADIUS_POLICY_ONLY_REACHABLE_TILES)
			new_params[param_id] = GLOB.world_edit_helpers.parse_bool(value)
			if(new_params[param_id])
				new_params[WORLD_EDIT_RADIUS_POLICY_ONLY_CLEAR_TILES] = TRUE

		if(WORLD_EDIT_RADIUS_POLICY_WINDOWS_BLOCKERS)
			new_params[param_id] = GLOB.world_edit_helpers.parse_bool(value)

		if("shuffle_enabled")
			new_params[param_id] = GLOB.world_edit_helpers.parse_bool(value)

		if("scatter_enabled")
			new_params[param_id] = GLOB.world_edit_helpers.parse_bool(value)

		if("scatter_steps")
			new_params[param_id] = clamp(text2num("[value]"), 1, WORLD_EDIT_DESTRUCTION_MAX_SCATTER_STEPS)

		if("persistent_fire_enabled")
			new_params[param_id] = GLOB.world_edit_helpers.parse_bool(value)
			if(new_params[param_id] && isnull(new_params["persistent_fire_density"]))
				new_params["persistent_fire_density"] = get_persistent_fire_density_default()
			if(new_params[param_id] && isnull(new_params["persistent_fire_mode"]))
				new_params["persistent_fire_mode"] = get_default_persistent_fire_mode()
			if(new_params[param_id] && isnull(new_params["persistent_fire_color"]))
				new_params["persistent_fire_color"] = get_default_persistent_fire_color_id()

		if("persistent_fire_density")
			new_params[param_id] = normalize_persistent_fire_density_percent(value)

		if("persistent_fire_mode")
			var/fire_mode = resolve_persistent_fire_mode(value)
			if(isnull(fire_mode))
				return "Invalid persistent fire mode selected."
			new_params[param_id] = fire_mode

		if("persistent_fire_color")
			var/fire_color_id = resolve_persistent_fire_color_id(value)
			if(isnull(fire_color_id))
				return "Invalid persistent fire color selected."
			new_params[param_id] = fire_color_id

		if("persistent_fire_custom_color")
			new_params[param_id] = trim(sanitize_text(value, ""))

		if("blast_enabled")
			new_params[param_id] = GLOB.world_edit_helpers.parse_bool(value)
			if(new_params[param_id] && isnull(new_params["blast_power"]))
				new_params["blast_power"] = get_blast_power_default()
			if(new_params[param_id] && isnull(new_params["blast_falloff"]))
				new_params["blast_falloff"] = get_blast_falloff_default()

		if("blast_power")
			new_params[param_id] = clamp(text2num("[value]"), get_blast_power_min(), get_blast_power_max())

		if("blast_falloff")
			new_params[param_id] = clamp(text2num("[value]"), get_blast_falloff_min(), get_blast_falloff_max())

		if("damage_profile")
			var/profile_id = resolve_damage_profile(value)
			if(!profile_id)
				return "Invalid damage profile selected."
			new_params[param_id] = profile_id

		if("max_atoms")
			new_params[param_id] = clamp(text2num("[value]"), 1, WORLD_EDIT_DESTRUCTION_MAX_ATOMS)

		if("affect_anchored")
			new_params[param_id] = GLOB.world_edit_helpers.parse_bool(value)

		else
			return ..()

	return new_params

/datum/world_edit_generator/destruction_pack/get_apply_confirmation_text(list/params)
	var/fire_enabled = GLOB.world_edit_helpers.parse_bool(params["persistent_fire_enabled"])
	var/fire_mode = get_persistent_fire_mode_label(params["persistent_fire_mode"])
	var/fire_color = get_persistent_fire_color_label(params["persistent_fire_color"], params["persistent_fire_custom_color"])
	var/blast_enabled = GLOB.world_edit_helpers.parse_bool(params["blast_enabled"])
	var/damage_profile = get_damage_profile_label(params["damage_profile"])
	var/undo_policy = (blast_enabled || resolve_damage_profile(params["damage_profile"]) != "none") ? WORLD_EDIT_UNDO_NONE : WORLD_EDIT_UNDO_PARTIAL
	var/fire_summary = fire_enabled ? "да ([fire_mode], [fire_color])" : "нет"
	return "Применить разрушение зоны? Радиус воздействия [params["radius"]], перемещение=[params["shuffle_enabled"]], разброс=[params["scatter_enabled"]], огонь=[fire_summary], взрыв=[blast_enabled ? "да" : "нет"], урон=[damage_profile], откат=[undo_policy]."

/datum/world_edit_generator/destruction_pack/get_params_short(list/params)
	var/fire_density = normalize_persistent_fire_density_percent(params["persistent_fire_density"])
	var/fire_mode = resolve_persistent_fire_mode(params["persistent_fire_mode"]) || get_default_persistent_fire_mode()
	var/fire_color = resolve_persistent_fire_color(params["persistent_fire_color"], params["persistent_fire_custom_color"]) || get_persistent_fire_preset_color(get_default_persistent_fire_color_id())
	var/list/radius_policy = GLOB.world_edit_helpers.get_world_edit_radius_policy(params)
	return "impact_radius=[params["radius"]] clear=[radius_policy["only_clear_tiles"]] reachable=[radius_policy["only_reachable_tiles"]] windows=[radius_policy["treat_windows_as_blockers"]] shuffle=[params["shuffle_enabled"]] scatter=[params["scatter_enabled"]] fire=[params["persistent_fire_enabled"]] density=[fire_density] fire_mode=[fire_mode] fire_color=[fire_color] blast=[params["blast_enabled"]] blast_power=[params["blast_power"]] blast_falloff=[params["blast_falloff"]] damage=[params["damage_profile"]] steps=[params["scatter_steps"]] max=[params["max_atoms"]]"
