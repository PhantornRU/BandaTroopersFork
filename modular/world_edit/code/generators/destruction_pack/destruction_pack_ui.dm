/datum/world_edit_generator/destruction_pack/get_ui_fields(list/current_params)
	var/scatter_enabled = GLOB.world_edit_helpers.parse_bool(current_params["scatter_enabled"])
	var/persistent_fire_enabled = GLOB.world_edit_helpers.parse_bool(current_params["persistent_fire_enabled"])
	var/blast_enabled = GLOB.world_edit_helpers.parse_bool(current_params["blast_enabled"])
	var/damage_profile = resolve_damage_profile(current_params["damage_profile"])

	return list(
		list(
			"id" = "radius",
			"label" = "Radius",
			"kind" = "number",
			"group" = "Area",
			"description" = "Square radius around the current turf.",
			"validate_hint" = "Allowed range: 1..10",
			"value" = text2num("[current_params["radius"]]") || 3,
			"min" = 1,
			"max" = 10,
			"step" = 1,
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
			"validate_hint" = "Allowed range: 1..4",
			"value" = text2num("[current_params["scatter_steps"]]") || 2,
			"min" = 1,
			"max" = 4,
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
			"validate_hint" = "Allowed range: 1..100",
			"value" = text2num("[current_params["max_atoms"]]") || 60,
			"min" = 1,
			"max" = 100,
			"step" = 1,
		),
	)

/datum/world_edit_generator/destruction_pack/set_ui_param(mob/user, list/current_params, param_id, value)
	var/list/new_params = current_params.Copy()

	switch(param_id)
		if("radius")
			new_params[param_id] = clamp(text2num("[value]"), 1, 10)

		if("shuffle_enabled")
			new_params[param_id] = GLOB.world_edit_helpers.parse_bool(value)

		if("scatter_enabled")
			new_params[param_id] = GLOB.world_edit_helpers.parse_bool(value)

		if("scatter_steps")
			new_params[param_id] = clamp(text2num("[value]"), 1, 4)

		if("persistent_fire_enabled")
			new_params[param_id] = GLOB.world_edit_helpers.parse_bool(value)
			if(new_params[param_id] && isnull(new_params["persistent_fire_density"]))
				new_params["persistent_fire_density"] = get_persistent_fire_density_default()

		if("persistent_fire_density")
			new_params[param_id] = normalize_persistent_fire_density_percent(value)

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
			new_params[param_id] = clamp(text2num("[value]"), 1, 100)

		if("affect_anchored")
			new_params[param_id] = GLOB.world_edit_helpers.parse_bool(value)

		else
			return ..()

	return new_params

/datum/world_edit_generator/destruction_pack/get_apply_confirmation_text(list/params)
	var/fire_enabled = GLOB.world_edit_helpers.parse_bool(params["persistent_fire_enabled"])
	var/blast_enabled = GLOB.world_edit_helpers.parse_bool(params["blast_enabled"])
	var/damage_profile = get_damage_profile_label(params["damage_profile"])
	var/undo_policy = (blast_enabled || resolve_damage_profile(params["damage_profile"]) != "none") ? WORLD_EDIT_UNDO_NONE : WORLD_EDIT_UNDO_PARTIAL
	return "Применить разрушение зоны? Радиус [params["radius"]], перемещение=[params["shuffle_enabled"]], разброс=[params["scatter_enabled"]], огонь=[fire_enabled ? "да" : "нет"], взрыв=[blast_enabled ? "да" : "нет"], урон=[damage_profile], откат=[undo_policy]."

/datum/world_edit_generator/destruction_pack/get_params_short(list/params)
	var/fire_density = normalize_persistent_fire_density_percent(params["persistent_fire_density"])
	return "radius=[params["radius"]] shuffle=[params["shuffle_enabled"]] scatter=[params["scatter_enabled"]] fire=[params["persistent_fire_enabled"]] density=[fire_density] blast=[params["blast_enabled"]] blast_power=[params["blast_power"]] blast_falloff=[params["blast_falloff"]] damage=[params["damage_profile"]] steps=[params["scatter_steps"]] max=[params["max_atoms"]]"
