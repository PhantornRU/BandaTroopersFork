/datum/authority/branch/role/proc/add_unique_ship_platoon_value(list/target_list, value)
	if(!islist(target_list) || isnull(value))
		return
	if(!(value in target_list))
		target_list += value

/datum/authority/branch/role/proc/normalize_ship_platoon_type(platoon_type)
	if(ispath(platoon_type, /datum/squad))
		return platoon_type
	if(istext(platoon_type))
		return text2path(platoon_type)

	return null

/datum/authority/branch/role/proc/get_known_ship_platoon_types()
	var/list/known_types = list(
		/datum/squad/marine/alpha,
		/datum/squad/marine/upp,
		/datum/squad/marine/pmc,
		/datum/squad/marine/pmc/small,
		/datum/squad/marine/forecon,
		/datum/squad/marine/rmc,
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

/datum/authority/branch/role/proc/get_default_ship_platoon_profile(platoon_type)
	platoon_type = normalize_ship_platoon_type(platoon_type)
	if(!platoon_type)
		return null

	var/list/profile = list(
		"platoon_type" = platoon_type,
		"family_types" = list(platoon_type),
		"family_secondary_types" = list(),
		"distress_roles" = GLOB.ROLES_DISTRESS_SIGNAL,
		"lowpop_roles" = GLOB.platoon_to_role_list[platoon_type],
		"role_mappings" = null,
		"spawn_preset_overrides" = null,
		"cryo_reinforcement_titles" = null,
		"cryo_reinforcement_presets" = null,
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

	return profile

/datum/authority/branch/role/proc/get_ship_platoon_profile(platoon_type)
	platoon_type = normalize_ship_platoon_type(platoon_type)
	if(!platoon_type)
		return null

	var/list/profile = get_halo_main_ship_profile(platoon_type)
	if(profile)
		return profile

	return get_default_ship_platoon_profile(platoon_type)

/datum/authority/branch/role/proc/get_ship_platoon_label(platoon_type)
	platoon_type = normalize_ship_platoon_type(platoon_type)
	if(!platoon_type)
		return null

	var/list/profile = get_ship_platoon_profile(platoon_type)
	var/platoon_label = profile?["platoon_label"]
	if(istext(platoon_label) && length(platoon_label))
		return platoon_label

	if(ispath(platoon_type, /datum/squad/marine))
		var/datum/squad/marine/platoon_datum = platoon_type
		var/static_name = initial(platoon_datum.name)
		if(static_name)
			return static_name

	return "[platoon_type]"

/datum/authority/branch/role/proc/get_active_ship_platoon_type(mode_name = GLOB.master_mode, datum/game_mode/mode_datum = SSticker.mode)
	var/platoon_type = MAIN_SHIP_PLATOON
	if(platoon_type)
		return platoon_type

	return text2path(MAIN_SHIP_DEFAULT_PLATOON)

/datum/authority/branch/role/proc/get_ship_spawn_preset_override(job_title, current_preset, platoon_type)
	if(!job_title || !current_preset || !platoon_type)
		return null

	job_title = get_job_preference_bucket_key(job_title) || job_title

	var/list/profile = get_ship_platoon_profile(platoon_type)
	var/list/spawn_preset_overrides = profile?["spawn_preset_overrides"]
	if(!islist(spawn_preset_overrides))
		return null

	var/list/job_overrides = spawn_preset_overrides[job_title]
	if(!islist(job_overrides))
		return null

	return job_overrides[current_preset]

/datum/authority/branch/role/proc/get_active_ship_spawn_preset_override(job_title, current_preset, platoon_type = get_active_ship_platoon_type())
	return get_ship_spawn_preset_override(job_title, current_preset, platoon_type)

/datum/authority/branch/role/proc/get_ship_cryo_reinforcement_title(canonical_role, platoon_type)
	if(!canonical_role || !platoon_type)
		return null

	canonical_role = get_job_preference_bucket_key(canonical_role) || canonical_role

	var/list/profile = get_ship_platoon_profile(platoon_type)
	var/list/cryo_reinforcement_titles = profile?["cryo_reinforcement_titles"]
	if(!islist(cryo_reinforcement_titles))
		return null

	return cryo_reinforcement_titles[canonical_role]

/datum/authority/branch/role/proc/get_active_ship_cryo_reinforcement_title(canonical_role, platoon_type = get_active_ship_platoon_type())
	return get_ship_cryo_reinforcement_title(canonical_role, platoon_type)

/datum/authority/branch/role/proc/get_ship_cryo_reinforcement_preset(canonical_role, platoon_type)
	if(!canonical_role || !platoon_type)
		return null

	canonical_role = get_job_preference_bucket_key(canonical_role) || canonical_role

	var/list/profile = get_ship_platoon_profile(platoon_type)
	var/list/cryo_reinforcement_presets = profile?["cryo_reinforcement_presets"]
	if(!islist(cryo_reinforcement_presets))
		return null

	return cryo_reinforcement_presets[canonical_role]

/datum/authority/branch/role/proc/get_active_ship_cryo_reinforcement_preset(canonical_role, platoon_type = get_active_ship_platoon_type())
	return get_ship_cryo_reinforcement_preset(canonical_role, platoon_type)

/datum/authority/branch/role/proc/has_active_ship_cryo_reinforcement_overrides(platoon_type = get_active_ship_platoon_type())
	var/list/profile = get_ship_platoon_profile(platoon_type)
	return islist(profile?["cryo_reinforcement_titles"]) || islist(profile?["cryo_reinforcement_presets"])

/datum/authority/branch/role/proc/should_auto_assign_ship_family_squad(job_or_title)
	var/list/halo_family_types = get_halo_job_family_types(job_or_title)
	return islist(halo_family_types) && length(halo_family_types)
/datum/authority/branch/role/proc/apply_active_ship_cryo_reinforcement(mob/living/carbon/human/human, canonical_role, fallback_title = canonical_role, fallback_preset = null, late_join = TRUE, platoon_type = get_active_ship_platoon_type())
	canonical_role = get_job_preference_bucket_key(canonical_role) || canonical_role
	if(!istype(human) || !canonical_role)
		return FALSE

	var/use_profile_cryo = has_active_ship_cryo_reinforcement_overrides(platoon_type)
	var/effective_title = fallback_title || canonical_role
	var/effective_preset = fallback_preset

	if(use_profile_cryo)
		effective_title = get_active_ship_cryo_reinforcement_title(canonical_role, platoon_type) || effective_title
		effective_preset = get_active_ship_cryo_reinforcement_preset(canonical_role, platoon_type)
		if(!effective_title || !effective_preset)
			return FALSE

	human.job = effective_title // SS220 EDIT: cryo profile application owns the effective runtime role title
	human.client?.prefs.copy_all_to(human, effective_title, TRUE, TRUE)
	if(effective_preset)
		arm_equipment(human, effective_preset, late_join, TRUE, late_join = late_join)

	if(use_profile_cryo)
		var/list/halo_family_types = get_halo_job_family_types(human.job)
		if(islist(halo_family_types) && length(halo_family_types) && human.assigned_squad && !(human.assigned_squad.type in halo_family_types))
			human.assigned_squad.remove_marine_from_squad(human, human.get_idcard())
		randomize_squad(human)
		human.sec_hud_set_ID()
		human.hud_set_squad()

	return TRUE

/datum/authority/branch/role/proc/is_lowpop_ship_mode(mode_name = GLOB.master_mode, datum/game_mode/mode_datum = SSticker.mode)
	if(istype(mode_datum, /datum/game_mode/colonialmarines/ai))
		return TRUE

	return !!(mode_name && findtext(mode_name, "Distress Signal: Lowpop") == 1)

/datum/authority/branch/role/proc/get_active_ship_profile(mode_name = GLOB.master_mode, datum/game_mode/mode_datum = SSticker.mode)
	return get_ship_platoon_profile(get_active_ship_platoon_type(mode_name, mode_datum))

/datum/authority/branch/role/proc/get_active_ship_distress_roles(mode_name = GLOB.master_mode, datum/game_mode/mode_datum = SSticker.mode)
	var/list/profile = get_active_ship_profile(mode_name, mode_datum)
	if(profile?["distress_roles"])
		return profile["distress_roles"]

	return GLOB.ROLES_DISTRESS_SIGNAL

/datum/authority/branch/role/proc/get_active_ship_lowpop_roles(mode_name = GLOB.master_mode, datum/game_mode/mode_datum = SSticker.mode)
	var/platoon_type = get_active_ship_platoon_type(mode_name, mode_datum)
	var/list/profile = get_ship_platoon_profile(platoon_type)
	if(profile?["lowpop_roles"])
		return profile["lowpop_roles"]

	return GLOB.platoon_to_role_list[platoon_type]

/datum/authority/branch/role/proc/get_active_ship_role_mappings(lowpop = null, mode_name = GLOB.master_mode, datum/game_mode/mode_datum = SSticker.mode)
	if(isnull(lowpop))
		lowpop = is_lowpop_ship_mode(mode_name, mode_datum)

	var/platoon_type = get_active_ship_platoon_type(mode_name, mode_datum)
	var/list/profile = get_ship_platoon_profile(platoon_type)
	if(profile?["role_mappings"])
		return profile["role_mappings"]

	if(lowpop)
		return GLOB.platoon_to_jobs[platoon_type]

	return null

/datum/authority/branch/role/proc/get_active_ship_primary_family_types(mode_name = GLOB.master_mode, datum/game_mode/mode_datum = SSticker.mode)
	var/platoon_type = get_active_ship_platoon_type(mode_name, mode_datum)
	var/list/profile = get_ship_platoon_profile(platoon_type)
	if(profile?["family_types"])
		return profile["family_types"]

	return list(platoon_type)

/datum/authority/branch/role/proc/get_main_ship_conflicting_family_types()
	var/list/conflicting_types = list()
	for(var/platoon_type in list(
		/datum/squad/marine/alpha,
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

/datum/authority/branch/role/proc/get_active_ship_lowpop_keep_types(mode_name = GLOB.master_mode, datum/game_mode/mode_datum = SSticker.mode)
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

/datum/authority/branch/role/proc/get_main_ship_faction(mode_name = GLOB.master_mode, datum/game_mode/mode_datum = SSticker.mode)
	var/platoon_type = get_active_ship_platoon_type(mode_name, mode_datum)
	if(!ispath(platoon_type, /datum/squad/marine))
		return null

	var/datum/squad/marine/platoon_datum = platoon_type
	return initial(platoon_datum.faction)

/datum/authority/branch/role/proc/sync_pending_same_ship_platoon_for_round_start()
	var/datum/map_config/current_ship_config = SSmapping?.configs?[SHIP_MAP]
	var/datum/map_config/pending_ship_config = SSmapping?.next_map_configs?[SHIP_MAP]
	if(!current_ship_config || !pending_ship_config)
		return FALSE

	// Start Round does not reload the map, so same-map ship profile changes must be applied to the loaded ship config.
	if(current_ship_config.map_name != pending_ship_config.map_name || current_ship_config.map_path != pending_ship_config.map_path)
		return FALSE
	if(!pending_ship_config.platoon || current_ship_config.platoon == pending_ship_config.platoon)
		return FALSE

	current_ship_config.platoon = pending_ship_config.platoon
	current_ship_config.allowed_platoons = pending_ship_config.allowed_platoons ? pending_ship_config.allowed_platoons.Copy() : list()
	return TRUE

/datum/authority/branch/role/proc/get_role_bucket_title(job_or_title, active_only = FALSE)
	var/job_title = resolve_job_title(job_or_title)
	if(!job_title)
		return null

	if(active_only)
		return get_default_role_title(job_title)

	return get_job_preference_bucket_key(job_title)

/datum/authority/branch/role/proc/is_marine_equivalent_role(job_or_title, active_only = FALSE)
	var/bucket_title = get_role_bucket_title(job_or_title, active_only)
	return !!(bucket_title && GLOB.ROLES_MARINES.Find(bucket_title))

/datum/authority/branch/role/proc/get_marine_equivalent_role_titles(active_only = FALSE)
	var/list/role_titles = active_only ? list() : GLOB.ROLES_MARINES.Copy()
	var/list/source_titles = active_only ? roles_for_mode : roles_by_name

	if(!islist(source_titles) || !length(source_titles))
		return role_titles

	for(var/role_title in source_titles)
		if(!is_marine_equivalent_role(role_title, active_only))
			continue
		add_unique_ship_platoon_value(role_titles, role_title)

	return role_titles

/datum/authority/branch/role/proc/is_shipside_role(job_or_title, active_only = FALSE)
	var/job_title = resolve_job_title(job_or_title)
	if(!job_title)
		return FALSE

	var/bucket_title = get_role_bucket_title(job_title, active_only)
	if(bucket_title && GLOB.ROLES_USCM.Find(bucket_title))
		return TRUE

	return is_marine_equivalent_role(bucket_title || job_title, active_only)

/datum/authority/branch/role/proc/get_shipside_role_titles(active_only = FALSE)
	var/list/role_titles = active_only ? list() : GLOB.ROLES_USCM.Copy()
	var/list/source_titles = active_only ? roles_for_mode : roles_by_name

	if(!islist(source_titles) || !length(source_titles))
		return role_titles

	for(var/role_title in source_titles)
		if(!is_shipside_role(role_title, active_only))
			continue
		add_unique_ship_platoon_value(role_titles, role_title)

	return role_titles

/datum/authority/branch/role/proc/get_non_marine_shipside_role_titles(active_only = FALSE)
	var/list/role_titles = get_shipside_role_titles(active_only)
	if(!islist(role_titles))
		return active_only ? list() : (GLOB.ROLES_USCM - GLOB.ROLES_MARINES)

	var/list/non_marine_titles = role_titles.Copy()
	var/list/marine_titles = get_marine_equivalent_role_titles(active_only)
	if(islist(marine_titles) && length(marine_titles))
		non_marine_titles -= marine_titles

	return non_marine_titles

/datum/authority/branch/role/proc/filter_role_authority_squads_to_types(list/keep_types, conflict_only = FALSE)
	if(!islist(keep_types) || !length(keep_types))
		return FALSE

	var/list/conflict_types = conflict_only ? get_main_ship_conflicting_family_types() : null
	for(var/datum/squad/squad as anything in squads.Copy())
		if(conflict_only && !(squad.type in conflict_types))
			continue
		if(squad.type in keep_types)
			continue
		squads -= squad
		squads_by_type -= squad.type
	return TRUE

/datum/authority/branch/role/proc/refresh_main_ship_gamemode_roles()
	GLOB.gamemode_roles["Distress Signal"] = get_active_ship_distress_roles("Distress Signal", null)
	GLOB.gamemode_roles["Distress Signal: Lowpop"] = get_active_ship_lowpop_roles("Distress Signal: Lowpop", null)
	return TRUE

/datum/authority/branch/role/proc/handle_main_ship_mode_changed(apply_surfaces = TRUE)
	refresh_main_ship_gamemode_roles()
	if(apply_surfaces)
		apply_main_ship_surface_profile()
	return TRUE

/datum/authority/branch/role/proc/get_gamemode_role_titles(mode_name = GLOB.master_mode)
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

/datum/authority/branch/role/proc/get_main_ship_display_profile()
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

/datum/authority/branch/role/proc/get_main_ship_distress_roles()
	return get_active_ship_distress_roles()

/datum/authority/branch/role/proc/get_main_ship_lowpop_roles()
	return get_active_ship_lowpop_roles()

/datum/authority/branch/role/proc/get_main_ship_role_mappings(lowpop = FALSE)
	return get_active_ship_role_mappings(lowpop)

/datum/authority/branch/role/proc/get_main_ship_primary_family_types()
	return get_active_ship_primary_family_types()

/datum/authority/branch/role/proc/get_main_ship_lowpop_keep_types()
	return get_active_ship_lowpop_keep_types()
