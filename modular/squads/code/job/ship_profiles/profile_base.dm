/datum/modular_ship_platoon_profile
	var/platoon_type
	var/list/family_types
	var/list/family_secondary_types
	var/list/distress_roles
	var/list/lowpop_roles
	var/list/role_mappings
	var/list/spawn_preset_overrides
	var/list/cryo_reinforcement_titles
	var/list/cryo_reinforcement_presets
	var/list/preview_presets
	var/platoon_label
	var/manifest_picture
	var/intro_picture

/datum/modular_ship_platoon_profile/New(new_platoon_type)
	. = ..()
	if(new_platoon_type)
		platoon_type = new_platoon_type
	initialize_profile()

/datum/modular_ship_platoon_profile/proc/initialize_profile()
	return

/datum/modular_ship_platoon_profile/proc/copy_profile_list(list/source_list)
	if(!islist(source_list))
		return null

	return source_list.Copy()

/datum/modular_ship_platoon_profile/proc/get_family_types()
	if(islist(family_types) && length(family_types))
		return family_types.Copy()
	if(platoon_type)
		return list(platoon_type)

	return list()

/datum/modular_ship_platoon_profile/proc/get_family_secondary_types()
	if(islist(family_secondary_types))
		return family_secondary_types.Copy()

	return list()

/datum/modular_ship_platoon_profile/proc/get_distress_roles()
	if(islist(distress_roles))
		return distress_roles.Copy()
	if(islist(GLOB.ROLES_DISTRESS_SIGNAL))
		return GLOB.ROLES_DISTRESS_SIGNAL.Copy()

	return null

/datum/modular_ship_platoon_profile/proc/get_lowpop_roles()
	if(islist(lowpop_roles))
		return lowpop_roles.Copy()

	var/list/default_lowpop_roles = GLOB.platoon_to_role_list[platoon_type]
	if(islist(default_lowpop_roles))
		return default_lowpop_roles.Copy()

	return null

/datum/modular_ship_platoon_profile/proc/get_role_mappings()
	if(islist(role_mappings))
		return role_mappings.Copy()

	return null

/datum/modular_ship_platoon_profile/proc/get_spawn_preset_overrides()
	return copy_profile_list(spawn_preset_overrides)

/datum/modular_ship_platoon_profile/proc/get_cryo_reinforcement_titles()
	return copy_profile_list(cryo_reinforcement_titles)

/datum/modular_ship_platoon_profile/proc/get_cryo_reinforcement_presets()
	return copy_profile_list(cryo_reinforcement_presets)

/datum/modular_ship_platoon_profile/proc/get_preview_presets()
	return copy_profile_list(preview_presets)

/datum/modular_ship_platoon_profile/proc/build_profile()
	if(!platoon_type)
		return null

	return list(
		"platoon_type" = platoon_type,
		"family_types" = get_family_types(),
		"family_secondary_types" = get_family_secondary_types(),
		"distress_roles" = get_distress_roles(),
		"lowpop_roles" = get_lowpop_roles(),
		"role_mappings" = get_role_mappings(),
		"spawn_preset_overrides" = get_spawn_preset_overrides(),
		"cryo_reinforcement_titles" = get_cryo_reinforcement_titles(),
		"cryo_reinforcement_presets" = get_cryo_reinforcement_presets(),
		"platoon_label" = platoon_label,
		"manifest_picture" = manifest_picture,
		"intro_picture" = intro_picture,
	)
