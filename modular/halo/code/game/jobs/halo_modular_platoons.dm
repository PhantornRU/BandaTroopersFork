/datum/job/marine/standard/ai/halo/unsc
	title = JOB_SQUAD_MARINE_UNSC
	total_positions = 4
	spawn_positions = 4
	gear_preset = /datum/equipment_preset/unsc/pfc
	gear_preset_secondary = /datum/equipment_preset/unsc/pfc/lesser_rank
	job_options = list("Private First Class" = "PFC", "Private" = "PVT")

/datum/job/marine/standard/ai/rto/halo/unsc
	title = JOB_SQUAD_RTO_UNSC
	gear_preset = /datum/equipment_preset/unsc/rto
	gear_preset_secondary = /datum/equipment_preset/unsc/rto/lesser_rank
	job_options = list("Private First Class" = "PFC", "Lance Corporal" = "LCPL")

/datum/job/marine/leader/ai/odst
	title = JOB_SQUAD_LEADER_ODST
	gear_preset = /datum/equipment_preset/unsc/leader/odst
	gear_preset_secondary = /datum/equipment_preset/unsc/leader/odst/lesser_rank

/datum/job/marine/medic/ai/halo/unsc
	title = JOB_SQUAD_MEDIC_UNSC
	total_positions = 2
	spawn_positions = 2
	gear_preset = /datum/equipment_preset/unsc/medic
	gear_preset_secondary = /datum/equipment_preset/unsc/medic/lesser_rank

/datum/job/marine/tl/ai/halo/unsc
	title = JOB_SQUAD_TEAM_LEADER_UNSC
	total_positions = 2
	spawn_positions = 2
	gear_preset = /datum/equipment_preset/unsc/tl
	gear_preset_secondary = /datum/equipment_preset/unsc/tl/lesser_rank

/datum/job/marine/leader/ai/halo/unsc
	title = JOB_SQUAD_LEADER_UNSC
	gear_preset = /datum/equipment_preset/unsc/leader
	gear_preset_secondary = /datum/equipment_preset/unsc/leader/lesser_rank

/datum/job/marine/specialist/ai/halo/unsc
	title = JOB_SQUAD_SPECIALIST_UNSC
	total_positions = 2
	spawn_positions = 2
	gear_preset = /datum/equipment_preset/unsc/spec
	gear_preset_secondary = /datum/equipment_preset/unsc/spec/lesser_rank

/datum/job/marine/medic/ai/odst
	title = JOB_SQUAD_MEDIC_ODST
	total_positions = 2
	spawn_positions = 2
	gear_preset = /datum/equipment_preset/unsc/medic/odst
	gear_preset_secondary = /datum/equipment_preset/unsc/medic/odst/lesser_rank

/datum/job/marine/tl/ai/odst
	title = JOB_SQUAD_TEAM_LEADER_ODST
	total_positions = 2
	spawn_positions = 2
	gear_preset = /datum/equipment_preset/unsc/tl/odst
	gear_preset_secondary = /datum/equipment_preset/unsc/tl/odst/lesser_rank

/datum/job/marine/specialist/ai/odst
	title = JOB_SQUAD_SPECIALIST_ODST
	total_positions = 2
	spawn_positions = 2
	gear_preset = /datum/equipment_preset/unsc/spec/odst
	gear_preset_secondary = /datum/equipment_preset/unsc/spec/odst/lesser_rank

/datum/squad/marine/halo/unsc/alpha
	parent_type = /datum/squad/marine/alpha
	faction = FACTION_UNSC
	max_riflemen = 4
	max_engineers = 0
	max_medics = 2
	max_specialists = 2
	max_tl = 2
	max_smartgun = 0
	max_leaders = 1
	max_rto = 1

/datum/squad/marine/halo/unsc/bravo
	parent_type = /datum/squad/marine/bravo
	faction = FACTION_UNSC
	active = TRUE
	roundstart = TRUE
	usable = FALSE
	squad_type = "Section"
	ready_players_usable = 12
	platoon_associated_type = /datum/squad/marine/halo/unsc/alpha
	max_riflemen = 4
	max_engineers = 0
	max_medics = 2
	max_specialists = 2
	max_tl = 2
	max_smartgun = 0
	max_leaders = 1
	max_rto = 1

/datum/squad/marine/halo/unsc/charlie
	parent_type = /datum/squad/marine/charlie
	faction = FACTION_UNSC
	active = TRUE
	roundstart = TRUE
	usable = FALSE
	squad_type = "Section"
	ready_players_usable = 24
	platoon_associated_type = /datum/squad/marine/halo/unsc/alpha
	max_riflemen = 4
	max_engineers = 0
	max_medics = 2
	max_specialists = 2
	max_tl = 2
	max_smartgun = 0
	max_leaders = 1
	max_rto = 1

/datum/squad/marine/halo/unsc/delta
	parent_type = /datum/squad/marine/delta
	faction = FACTION_UNSC
	active = TRUE
	roundstart = TRUE
	usable = FALSE
	squad_type = "Section"
	ready_players_usable = 36
	platoon_associated_type = /datum/squad/marine/halo/unsc/alpha
	max_riflemen = 4
	max_engineers = 0
	max_medics = 2
	max_specialists = 2
	max_tl = 2
	max_smartgun = 0
	max_leaders = 1
	max_rto = 1

/datum/squad/marine/halo/odst/alpha
	parent_type = /datum/squad/marine/alpha
	faction = FACTION_UNSC
	max_riflemen = 4
	max_engineers = 0
	max_medics = 2
	max_specialists = 2
	max_tl = 2
	max_smartgun = 0
	max_leaders = 1
	max_rto = 1

/datum/squad/marine/halo/odst/bravo
	parent_type = /datum/squad/marine/bravo
	faction = FACTION_UNSC
	active = TRUE
	roundstart = TRUE
	usable = FALSE
	squad_type = "Section"
	ready_players_usable = 12
	platoon_associated_type = /datum/squad/marine/halo/odst/alpha
	max_riflemen = 4
	max_engineers = 0
	max_medics = 2
	max_specialists = 2
	max_tl = 2
	max_smartgun = 0
	max_leaders = 1
	max_rto = 1

/datum/squad/marine/halo/odst/charlie
	parent_type = /datum/squad/marine/charlie
	faction = FACTION_UNSC
	active = TRUE
	roundstart = TRUE
	usable = FALSE
	squad_type = "Section"
	ready_players_usable = 24
	platoon_associated_type = /datum/squad/marine/halo/odst/alpha
	max_riflemen = 4
	max_engineers = 0
	max_medics = 2
	max_specialists = 2
	max_tl = 2
	max_smartgun = 0
	max_leaders = 1
	max_rto = 1

/datum/squad/marine/halo/odst/delta
	parent_type = /datum/squad/marine/delta
	faction = FACTION_UNSC
	active = TRUE
	roundstart = TRUE
	usable = FALSE
	squad_type = "Section"
	ready_players_usable = 36
	platoon_associated_type = /datum/squad/marine/halo/odst/alpha
	max_riflemen = 4
	max_engineers = 0
	max_medics = 2
	max_specialists = 2
	max_tl = 2
	max_smartgun = 0
	max_leaders = 1
	max_rto = 1

/obj/effect/landmark/start/marine/leader/odst
	name = JOB_SQUAD_LEADER_ODST
	squad = SQUAD_ODST
	job = /datum/job/marine/leader/ai/odst

/obj/effect/landmark/start/marine/medic/odst
	name = JOB_SQUAD_MEDIC_ODST
	squad = SQUAD_ODST
	job = /datum/job/marine/medic/ai/odst

/obj/effect/landmark/start/marine/spec/odst
	name = JOB_SQUAD_SPECIALIST_ODST
	squad = SQUAD_ODST
	job = /datum/job/marine/specialist/ai/odst

/obj/effect/landmark/start/marine/tl/odst
	name = JOB_SQUAD_TEAM_LEADER_ODST
	squad = SQUAD_ODST
	job = /datum/job/marine/tl/ai/odst

/obj/effect/landmark/late_join/odst
	name = "ODST late join"
	squad = SQUAD_ODST

/datum/squad/marine/odst
	name = SQUAD_ODST
	access = list(ACCESS_MARINE_ALPHA)
	radio_freq = ODST_FREQ
	faction = FACTION_UNSC
	use_stripe_overlay = FALSE
	equipment_color = "#32CD32"
	chat_color = "#32CD32"
	minimap_color = "#32CD32"
	usable = TRUE

/proc/get_halo_unsc_marine_jobs()
	return list(
		JOB_SQUAD_LEADER_UNSC,
		JOB_SQUAD_TEAM_LEADER_UNSC,
		JOB_SQUAD_SPECIALIST_UNSC,
		JOB_SQUAD_MEDIC_UNSC,
		JOB_SQUAD_MARINE_UNSC,
		JOB_SQUAD_RTO_UNSC,
	)

/proc/get_halo_odst_marine_jobs()
	return list(
		JOB_SQUAD_LEADER_ODST,
		JOB_SQUAD_TEAM_LEADER_ODST,
		JOB_SQUAD_SPECIALIST_ODST,
		JOB_SQUAD_MEDIC_ODST,
		JOB_SQUAD_MARINE_ODST,
		JOB_SQUAD_RTO_ODST,
	)

/proc/get_additional_marine_jobs()
	return get_halo_unsc_marine_jobs() + get_halo_odst_marine_jobs()

/proc/get_halo_unsc_lowpop_roles()
	return list(JOB_SO) + get_halo_unsc_marine_jobs()

/proc/get_halo_odst_lowpop_roles()
	return list(JOB_SO) + get_halo_odst_marine_jobs()

/proc/get_halo_unsc_distress_roles()
	return GLOB.ROLES_CIC + GLOB.ROLES_POLICE + GLOB.ROLES_AUXIL_SUPPORT + GLOB.ROLES_MISC + GLOB.ROLES_ENGINEERING + GLOB.ROLES_REQUISITION + GLOB.ROLES_MEDICAL + get_halo_unsc_marine_jobs() + GLOB.ROLES_GROUND

/proc/get_halo_odst_distress_roles()
	return GLOB.ROLES_CIC + GLOB.ROLES_POLICE + GLOB.ROLES_AUXIL_SUPPORT + GLOB.ROLES_MISC + GLOB.ROLES_ENGINEERING + GLOB.ROLES_REQUISITION + GLOB.ROLES_MEDICAL + get_halo_odst_marine_jobs() + GLOB.ROLES_GROUND

/proc/get_modular_job_pref_to_gear_preset(job_title)
	switch(job_title)
		if(JOB_SQUAD_MARINE_ODST, JOB_SQUAD_LEADER_ODST, JOB_SQUAD_MEDIC_ODST, JOB_SQUAD_SPECIALIST_ODST, JOB_SQUAD_TEAM_LEADER_ODST, JOB_SQUAD_RTO_ODST)
			return /datum/equipment_preset/unsc/pfc/odst/equipped
		if(JOB_SQUAD_MARINE_UNSC)
			return /datum/equipment_preset/unsc/pfc/equipped
		if(JOB_SQUAD_LEADER_UNSC)
			return /datum/equipment_preset/unsc/leader/equipped
		if(JOB_SQUAD_MEDIC_UNSC)
			return /datum/equipment_preset/unsc/medic/equipped
		if(JOB_SQUAD_SPECIALIST_UNSC)
			return /datum/equipment_preset/unsc/spec/equipped_spnkr
		if(JOB_SQUAD_TEAM_LEADER_UNSC)
			return /datum/equipment_preset/unsc/tl/equipped
		if(JOB_SQUAD_RTO_UNSC)
			return /datum/equipment_preset/unsc/rto/equipped
	return null

/proc/get_halo_main_ship_profile(platoon_type = MAIN_SHIP_PLATOON)
	switch(platoon_type)
		if(/datum/squad/marine/halo/unsc/alpha)
			return list(
				"family_types" = list(
					/datum/squad/marine/halo/unsc/alpha,
					/datum/squad/marine/halo/unsc/bravo,
					/datum/squad/marine/halo/unsc/charlie,
					/datum/squad/marine/halo/unsc/delta,
				),
				"family_secondary_types" = list(
					/datum/squad/marine/halo/unsc/bravo,
					/datum/squad/marine/halo/unsc/charlie,
					/datum/squad/marine/halo/unsc/delta,
				),
				"role_mappings" = list(
					/datum/job/marine/standard/ai/halo/unsc = JOB_SQUAD_MARINE,
					/datum/job/marine/standard/ai/rto/halo/unsc = JOB_SQUAD_RTO,
					/datum/job/marine/medic/ai/halo/unsc = JOB_SQUAD_MEDIC,
					/datum/job/marine/tl/ai/halo/unsc = JOB_SQUAD_TEAM_LEADER,
					/datum/job/marine/leader/ai/halo/unsc = JOB_SQUAD_LEADER,
					/datum/job/marine/specialist/ai/halo/unsc = JOB_SQUAD_SPECIALIST,
				),
				"distress_roles" = get_halo_unsc_distress_roles(),
				"lowpop_roles" = get_halo_unsc_lowpop_roles(),
				"platoon_label" = "7th RECOM Div. \"Rock Hoppers\"",
				"manifest_picture" = /atom/movable/screen/text/screen_text/picture/starting/unsc,
				"intro_picture" = /atom/movable/screen/text/screen_text/picture/dark_was_the_night,
			)
		if(/datum/squad/marine/halo/odst/alpha)
			return list(
				"family_types" = list(
					/datum/squad/marine/halo/odst/alpha,
					/datum/squad/marine/halo/odst/bravo,
					/datum/squad/marine/halo/odst/charlie,
					/datum/squad/marine/halo/odst/delta,
				),
				"family_secondary_types" = list(
					/datum/squad/marine/halo/odst/bravo,
					/datum/squad/marine/halo/odst/charlie,
					/datum/squad/marine/halo/odst/delta,
				),
				"role_mappings" = list(
					/datum/job/marine/standard/ai/odst = JOB_SQUAD_MARINE,
					/datum/job/marine/standard/ai/rto/odst = JOB_SQUAD_RTO,
					/datum/job/marine/medic/ai/odst = JOB_SQUAD_MEDIC,
					/datum/job/marine/tl/ai/odst = JOB_SQUAD_TEAM_LEADER,
					/datum/job/marine/leader/ai/odst = JOB_SQUAD_LEADER,
					/datum/job/marine/specialist/ai/odst = JOB_SQUAD_SPECIALIST,
				),
				"distress_roles" = get_halo_odst_distress_roles(),
				"lowpop_roles" = get_halo_odst_lowpop_roles(),
				"platoon_label" = "33rd Drop Jet Batt. \"The Ferrymen\"",
				"manifest_picture" = /atom/movable/screen/text/screen_text/picture/starting/odst,
				"intro_picture" = /atom/movable/screen/text/screen_text/picture/dark_was_the_night,
			)
	return null

/proc/get_main_ship_distress_roles()
	var/list/profile = get_halo_main_ship_profile()
	if(profile)
		return profile["distress_roles"]
	return GLOB.ROLES_DISTRESS_SIGNAL

/proc/get_main_ship_lowpop_roles()
	var/list/profile = get_halo_main_ship_profile()
	if(profile)
		return profile["lowpop_roles"]
	return GLOB.platoon_to_role_list[MAIN_SHIP_PLATOON]

/proc/get_main_ship_role_mappings(lowpop = FALSE)
	var/list/profile = get_halo_main_ship_profile()
	if(profile)
		return profile["role_mappings"]
	if(lowpop)
		return GLOB.platoon_to_jobs[MAIN_SHIP_PLATOON]
	return null

/proc/get_main_ship_primary_family_types()
	var/list/profile = get_halo_main_ship_profile()
	if(profile)
		return profile["family_types"]
	if(MAIN_SHIP_PLATOON == /datum/squad/marine/alpha)
		return list(/datum/squad/marine/alpha, /datum/squad/marine/bravo, /datum/squad/marine/charlie, /datum/squad/marine/delta)
	if(MAIN_SHIP_PLATOON == /datum/squad/marine/odst)
		return list(/datum/squad/marine/odst)
	return null

/proc/get_main_ship_conflicting_family_types()
	return list(
		/datum/squad/marine/alpha,
		/datum/squad/marine/bravo,
		/datum/squad/marine/charlie,
		/datum/squad/marine/delta,
		/datum/squad/marine/odst,
		/datum/squad/marine/halo/unsc/alpha,
		/datum/squad/marine/halo/unsc/bravo,
		/datum/squad/marine/halo/unsc/charlie,
		/datum/squad/marine/halo/unsc/delta,
		/datum/squad/marine/halo/odst/alpha,
		/datum/squad/marine/halo/odst/bravo,
		/datum/squad/marine/halo/odst/charlie,
		/datum/squad/marine/halo/odst/delta,
	)

/proc/get_main_ship_lowpop_keep_types()
	var/list/keep_types = list(MAIN_SHIP_PLATOON)
	var/list/profile = get_halo_main_ship_profile()
	if(profile)
		keep_types += profile["family_secondary_types"]
	else
		keep_types += list(/datum/squad/marine/bravo, /datum/squad/marine/charlie, /datum/squad/marine/delta)
	keep_types += list(/datum/squad/marine/sof/forecon, /datum/squad/marine/upp/secondary, /datum/squad/marine/pmc/secondary)
	return keep_types

/proc/filter_role_authority_squads_to_types(list/keep_types, conflict_only = FALSE)
	if(!islist(keep_types) || !length(keep_types))
		return FALSE

	var/list/conflict_types = conflict_only ? get_main_ship_conflicting_family_types() : null
	for(var/datum/squad/squad as anything in GLOB.RoleAuthority.squads.Copy())
		if(conflict_only)
			if(!(squad.type in conflict_types))
				continue
		if(squad.type in keep_types)
			continue
		GLOB.RoleAuthority.squads -= squad
		GLOB.RoleAuthority.squads_by_type -= squad.type
	return TRUE

/proc/refresh_main_ship_gamemode_roles()
	GLOB.gamemode_roles["Distress Signal"] = get_main_ship_distress_roles()
	GLOB.gamemode_roles["Distress Signal: Lowpop"] = get_main_ship_lowpop_roles()
	return TRUE

/proc/get_gamemode_role_titles(mode_name = GLOB.master_mode)
	var/list/role_titles = GLOB.gamemode_roles[mode_name]
	if(role_titles)
		return role_titles

	switch(mode_name)
		if("Distress Signal")
			return get_main_ship_distress_roles()
		if("Distress Signal: Lowpop")
			return get_main_ship_lowpop_roles()
	return null

/proc/get_main_ship_display_profile()
	var/list/profile = get_halo_main_ship_profile()
	if(!profile)
		return null
	return list(
		"label" = profile["platoon_label"],
		"manifest_picture" = profile["manifest_picture"],
		"intro_picture" = profile["intro_picture"],
	)

/proc/get_halo_main_ship_display_profile()
	return get_main_ship_display_profile()
