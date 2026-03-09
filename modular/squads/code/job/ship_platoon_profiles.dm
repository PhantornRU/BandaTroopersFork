/proc/add_unique_ship_platoon_value(list/target_list, value)
	if(!islist(target_list) || isnull(value))
		return
	if(!(value in target_list))
		target_list += value

/proc/get_known_ship_platoon_types()
	var/list/known_types = list(
		/datum/squad/marine/alpha,
		/datum/squad/marine/upp,
		/datum/squad/marine/pmc,
		/datum/squad/marine/pmc/small,
		/datum/squad/marine/forecon,
		/datum/squad/marine/rmc,
		/datum/squad/marine/odst,
		/datum/squad/marine/halo/unsc/alpha,
		/datum/squad/marine/halo/odst/alpha,
	)

	if(!SSmapping?.configs)
		return known_types

	for(var/config_key in SSmapping.configs)
		var/datum/map_config/MC = SSmapping.configs[config_key]
		if(!MC?.platoon)
			continue
		var/platoon_type = text2path(MC.platoon)
		if(platoon_type)
			add_unique_ship_platoon_value(known_types, platoon_type)

	return known_types

/proc/get_default_ship_platoon_profile(platoon_type)
	if(!platoon_type)
		return null

	var/list/profile = list(
		"platoon_type" = platoon_type,
		"family_types" = list(platoon_type),
		"family_secondary_types" = list(),
		"distress_roles" = GLOB.ROLES_DISTRESS_SIGNAL,
		"lowpop_roles" = GLOB.platoon_to_role_list[platoon_type],
		"role_mappings" = null,
	)

	switch(platoon_type)
		if(/datum/squad/marine/alpha)
			profile["family_types"] = list(
				/datum/squad/marine/alpha,
				/datum/squad/marine/bravo,
				/datum/squad/marine/charlie,
				/datum/squad/marine/delta,
			)
			profile["family_secondary_types"] = list(
				/datum/squad/marine/bravo,
				/datum/squad/marine/charlie,
				/datum/squad/marine/delta,
			)
		if(/datum/squad/marine/odst)
			profile["family_types"] = list(/datum/squad/marine/odst)

	return profile

/proc/get_ship_platoon_profile(platoon_type)
	if(!platoon_type)
		return null

	var/list/profile = get_halo_main_ship_profile(platoon_type)
	if(profile)
		return profile

	return get_default_ship_platoon_profile(platoon_type)

/proc/get_ship_mode_platoon_override(mode_name = GLOB.master_mode, datum/game_mode/mode_datum = SSticker.mode)
	if(istype(mode_datum) && !isnull(mode_datum.ship_platoon_override))
		return mode_datum.ship_platoon_override

	if(!mode_name)
		return null

	for(var/mode_type in subtypesof(/datum/game_mode))
		var/datum/game_mode/mode = mode_type
		if(initial(mode.config_tag) != mode_name)
			continue
		if(!isnull(initial(mode.ship_platoon_override)))
			return initial(mode.ship_platoon_override)
		break

	return null

/proc/get_active_ship_platoon_type(mode_name = GLOB.master_mode, datum/game_mode/mode_datum = SSticker.mode)
	var/platoon_override = get_ship_mode_platoon_override(mode_name, mode_datum)
	if(platoon_override)
		return platoon_override

	var/platoon_type = MAIN_SHIP_PLATOON
	if(platoon_type)
		return platoon_type

	return text2path(MAIN_SHIP_DEFAULT_PLATOON)

/proc/is_lowpop_ship_mode(mode_name = GLOB.master_mode, datum/game_mode/mode_datum = SSticker.mode)
	if(istype(mode_datum, /datum/game_mode/colonialmarines/ai))
		return TRUE

	return !!(mode_name && findtext(mode_name, "Distress Signal: Lowpop") == 1)

/proc/get_active_ship_profile(mode_name = GLOB.master_mode, datum/game_mode/mode_datum = SSticker.mode)
	return get_ship_platoon_profile(get_active_ship_platoon_type(mode_name, mode_datum))

/proc/get_active_ship_distress_roles(mode_name = GLOB.master_mode, datum/game_mode/mode_datum = SSticker.mode)
	var/list/profile = get_active_ship_profile(mode_name, mode_datum)
	if(profile?["distress_roles"])
		return profile["distress_roles"]

	return GLOB.ROLES_DISTRESS_SIGNAL

/proc/get_active_ship_lowpop_roles(mode_name = GLOB.master_mode, datum/game_mode/mode_datum = SSticker.mode)
	var/platoon_type = get_active_ship_platoon_type(mode_name, mode_datum)
	var/list/profile = get_ship_platoon_profile(platoon_type)
	if(profile?["lowpop_roles"])
		return profile["lowpop_roles"]

	return GLOB.platoon_to_role_list[platoon_type]

/proc/get_active_ship_role_mappings(lowpop = null, mode_name = GLOB.master_mode, datum/game_mode/mode_datum = SSticker.mode)
	if(isnull(lowpop))
		lowpop = is_lowpop_ship_mode(mode_name, mode_datum)

	var/platoon_type = get_active_ship_platoon_type(mode_name, mode_datum)
	var/list/profile = get_ship_platoon_profile(platoon_type)
	if(profile?["role_mappings"])
		return profile["role_mappings"]

	if(lowpop)
		return GLOB.platoon_to_jobs[platoon_type]

	return null

/proc/get_active_ship_primary_family_types(mode_name = GLOB.master_mode, datum/game_mode/mode_datum = SSticker.mode)
	var/platoon_type = get_active_ship_platoon_type(mode_name, mode_datum)
	var/list/profile = get_ship_platoon_profile(platoon_type)
	if(profile?["family_types"])
		return profile["family_types"]

	return list(platoon_type)

/proc/get_main_ship_conflicting_family_types()
	var/list/conflicting_types = list()
	for(var/platoon_type in list(
		/datum/squad/marine/alpha,
		/datum/squad/marine/odst,
		/datum/squad/marine/halo/unsc/alpha,
		/datum/squad/marine/halo/odst/alpha,
	))
		var/list/profile = get_ship_platoon_profile(platoon_type)
		var/list/family_types = profile?["family_types"]
		if(!islist(family_types) || !length(family_types))
			family_types = list(platoon_type)
		for(var/family_type in family_types)
			add_unique_ship_platoon_value(conflicting_types, family_type)

	return conflicting_types

/proc/get_active_ship_lowpop_keep_types(mode_name = GLOB.master_mode, datum/game_mode/mode_datum = SSticker.mode)
	var/platoon_type = get_active_ship_platoon_type(mode_name, mode_datum)
	var/list/keep_types = list(platoon_type)
	var/list/profile = get_ship_platoon_profile(platoon_type)
	if(profile?["family_secondary_types"])
		for(var/family_type in profile["family_secondary_types"])
			add_unique_ship_platoon_value(keep_types, family_type)
	else if(platoon_type == /datum/squad/marine/alpha)
		keep_types += list(/datum/squad/marine/bravo, /datum/squad/marine/charlie, /datum/squad/marine/delta)

	for(var/extra_type in list(/datum/squad/marine/sof/forecon, /datum/squad/marine/upp/secondary, /datum/squad/marine/pmc/secondary))
		add_unique_ship_platoon_value(keep_types, extra_type)

	return keep_types

/proc/filter_role_authority_squads_to_types(list/keep_types, conflict_only = FALSE)
	if(!islist(keep_types) || !length(keep_types))
		return FALSE

	var/list/conflict_types = conflict_only ? get_main_ship_conflicting_family_types() : null
	for(var/datum/squad/squad as anything in GLOB.RoleAuthority.squads.Copy())
		if(conflict_only && !(squad.type in conflict_types))
			continue
		if(squad.type in keep_types)
			continue
		GLOB.RoleAuthority.squads -= squad
		GLOB.RoleAuthority.squads_by_type -= squad.type
	return TRUE

/proc/refresh_main_ship_gamemode_roles()
	GLOB.gamemode_roles["Distress Signal"] = get_active_ship_distress_roles("Distress Signal", null)
	GLOB.gamemode_roles["Distress Signal: Lowpop"] = get_active_ship_lowpop_roles("Distress Signal: Lowpop", null)
	return TRUE

/proc/handle_main_ship_mode_changed()
	return refresh_main_ship_gamemode_roles()

/proc/get_gamemode_role_titles(mode_name = GLOB.master_mode)
	var/list/role_titles = GLOB.gamemode_roles[mode_name]
	if(role_titles)
		return role_titles

	switch(mode_name)
		if("Distress Signal")
			return get_active_ship_distress_roles(mode_name, null)
		if("Distress Signal: Lowpop")
			return get_active_ship_lowpop_roles(mode_name, null)
	if(is_lowpop_ship_mode(mode_name, null))
		return get_active_ship_lowpop_roles(mode_name, null)
	return null

/proc/get_main_ship_display_profile()
	var/list/profile = get_active_ship_profile()
	if(!profile)
		return null

	if(!profile["platoon_label"] && !profile["manifest_picture"] && !profile["intro_picture"])
		return null

	return list(
		"label" = profile["platoon_label"],
		"manifest_picture" = profile["manifest_picture"],
		"intro_picture" = profile["intro_picture"],
	)

/proc/get_main_ship_distress_roles()
	return get_active_ship_distress_roles()

/proc/get_main_ship_lowpop_roles()
	return get_active_ship_lowpop_roles()

/proc/get_main_ship_role_mappings(lowpop = FALSE)
	return get_active_ship_role_mappings(lowpop)

/proc/get_main_ship_primary_family_types()
	return get_active_ship_primary_family_types()

/proc/get_main_ship_lowpop_keep_types()
	return get_active_ship_lowpop_keep_types()

/proc/get_ship_job_title(job_or_title)
	if(isnull(job_or_title))
		return null

	if(istype(job_or_title, /datum/job))
		var/datum/job/job_datum = job_or_title
		return job_datum.title

	if(ispath(job_or_title, /datum/job))
		var/datum/job/job_by_path = GLOB.RoleAuthority?.roles_by_path[job_or_title]
		return job_by_path?.title

	return job_or_title

/proc/get_ship_role_title_mappings()
	if(!GLOB.RoleAuthority)
		return null

	var/static/list/cached_mappings
	if(length(cached_mappings))
		return cached_mappings

	cached_mappings = list()
	for(var/platoon_type in get_known_ship_platoon_types())
		var/list/profile = get_ship_platoon_profile(platoon_type)
		var/list/role_mappings = profile?["role_mappings"]
		if(!islist(role_mappings) || !length(role_mappings))
			role_mappings = GLOB.platoon_to_jobs[platoon_type]
		if(!islist(role_mappings))
			continue

		for(var/role_path in role_mappings)
			var/datum/job/job_datum = GLOB.RoleAuthority.roles_by_path[role_path]
			if(!job_datum?.title)
				continue
			if(!(job_datum.title in cached_mappings))
				cached_mappings[job_datum.title] = role_mappings[role_path]

	return cached_mappings

/proc/get_job_preference_bucket_key(job_or_title)
	var/job_title = get_ship_job_title(job_or_title)
	if(!job_title)
		return null

	var/default_role = GET_DEFAULT_ROLE(job_title)
	if(default_role != job_title)
		return default_role

	var/list/title_mappings = get_ship_role_title_mappings()
	if(title_mappings?[job_title])
		return title_mappings[job_title]

	return job_title

/proc/get_active_role_title_for_preference_bucket(bucket_key, mode_name = GLOB.master_mode, datum/game_mode/mode_datum = SSticker.mode)
	if(!bucket_key)
		return null

	var/list/active_role_titles = get_gamemode_role_titles(mode_name)
	if(islist(active_role_titles))
		for(var/role_title as anything in active_role_titles)
			if(get_job_preference_bucket_key(role_title) == bucket_key)
				return role_title

	return bucket_key
