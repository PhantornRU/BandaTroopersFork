#define HALO_CPL_VARIANT "Corporal"
#define HALO_LCPL_VARIANT "Lance Corporal"
#define HALO_PFC_VARIANT "Private First Class"
#define HALO_PVT_VARIANT "Private"

/datum/job/marine/standard/ai/halo/unsc
	title = JOB_SQUAD_MARINE_UNSC
	total_positions = 4
	spawn_positions = 4
	gear_preset = /datum/equipment_preset/unsc/pfc
	gear_preset_secondary = /datum/equipment_preset/unsc/pfc/lesser_rank
	job_options = list(HALO_PFC_VARIANT = "PFC", HALO_PVT_VARIANT = "PVT")

/datum/job/marine/standard/ai/rto/halo/unsc
	title = JOB_SQUAD_RTO_UNSC
	gear_preset = /datum/equipment_preset/unsc/rto
	gear_preset_secondary = /datum/equipment_preset/unsc/rto/lesser_rank
	job_options = list(HALO_PFC_VARIANT = "PFC", HALO_LCPL_VARIANT = "LCPL")

/datum/job/marine/medic/ai/halo/unsc
	title = JOB_SQUAD_MEDIC_UNSC
	total_positions = 2
	spawn_positions = 2
	gear_preset = /datum/equipment_preset/unsc/medic
	gear_preset_secondary = /datum/equipment_preset/unsc/medic/lesser_rank
	gear_preset_tertiary = /datum/equipment_preset/unsc/medic/pfc
	gear_preset_quaternary = /datum/equipment_preset/unsc/medic/private
	job_options = list(HALO_CPL_VARIANT = "CPL", HALO_LCPL_VARIANT = "LCPL", HALO_PFC_VARIANT = "PFC", HALO_PVT_VARIANT = "PVT")

/datum/job/marine/medic/ai/halo/unsc/handle_job_options(option)
	gear_preset = initial(gear_preset)
	if(option == HALO_PVT_VARIANT)
		gear_preset = gear_preset_quaternary
	if(option == HALO_PFC_VARIANT)
		gear_preset = gear_preset_tertiary
	if(option == HALO_LCPL_VARIANT)
		gear_preset = gear_preset_secondary

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

/datum/job/marine/standard/ai/halo/odst
	title = JOB_SQUAD_MARINE_ODST
	gear_preset = /datum/equipment_preset/unsc/pfc/odst
	gear_preset_secondary = /datum/equipment_preset/unsc/pfc/odst/lesser_rank
	job_options = list(HALO_PFC_VARIANT = "LCPL", HALO_PVT_VARIANT = "PFC")

/datum/job/marine/standard/ai/rto/halo/odst
	title = JOB_SQUAD_RTO_ODST
	gear_preset = /datum/equipment_preset/unsc/rto/odst
	gear_preset_secondary = /datum/equipment_preset/unsc/rto/odst/lesser_rank
	job_options = list(HALO_PFC_VARIANT = "PFC", HALO_LCPL_VARIANT = "LCPL")

/datum/job/marine/leader/ai/halo/odst
	title = JOB_SQUAD_LEADER_ODST
	gear_preset = /datum/equipment_preset/unsc/leader/odst
	gear_preset_secondary = /datum/equipment_preset/unsc/leader/odst/lesser_rank

/datum/job/marine/medic/ai/halo/odst
	title = JOB_SQUAD_MEDIC_ODST
	total_positions = 2
	spawn_positions = 2
	gear_preset = /datum/equipment_preset/unsc/medic/odst
	gear_preset_secondary = /datum/equipment_preset/unsc/medic/odst/lesser_rank
	gear_preset_tertiary = /datum/equipment_preset/unsc/medic/odst/pfc
	gear_preset_quaternary = /datum/equipment_preset/unsc/medic/odst/private
	job_options = list(HALO_CPL_VARIANT = "CPL", HALO_LCPL_VARIANT = "LCPL", HALO_PFC_VARIANT = "PFC", HALO_PVT_VARIANT = "PVT")

/datum/job/marine/medic/ai/halo/odst/handle_job_options(option)
	gear_preset = initial(gear_preset)
	if(option == HALO_PVT_VARIANT)
		gear_preset = gear_preset_quaternary
	if(option == HALO_PFC_VARIANT)
		gear_preset = gear_preset_tertiary
	if(option == HALO_LCPL_VARIANT)
		gear_preset = gear_preset_secondary

/datum/job/marine/tl/ai/halo/odst
	title = JOB_SQUAD_TEAM_LEADER_ODST
	total_positions = 2
	spawn_positions = 2
	gear_preset = /datum/equipment_preset/unsc/tl/odst
	gear_preset_secondary = /datum/equipment_preset/unsc/tl/odst/lesser_rank

/datum/job/marine/specialist/ai/halo/odst
	title = JOB_SQUAD_SPECIALIST_ODST
	total_positions = 2
	spawn_positions = 2
	gear_preset = /datum/equipment_preset/unsc/spec/odst
	gear_preset_secondary = /datum/equipment_preset/unsc/spec/odst/lesser_rank

/datum/job/command/bridge/ai/halo/unsc
	title = JOB_SO_UNSC
	gear_preset = /datum/equipment_preset/unsc/platco
	gear_preset_secondary = /datum/equipment_preset/unsc/platco/lesser_rank

/datum/job/command/bridge/ai/halo/odst
	title = JOB_SO_ODST
	gear_preset = /datum/equipment_preset/unsc/platco/odst
	gear_preset_secondary = /datum/equipment_preset/unsc/platco/odst/lesser_rank

/datum/authority/branch/role/New()
	. = ..()
	prefer_role_title_path(JOB_SO_UNSC, /datum/job/command/bridge/ai/halo/unsc)
	prefer_role_title_path(JOB_SO_ODST, /datum/job/command/bridge/ai/halo/odst)
	prefer_role_title_path(JOB_SQUAD_MARINE_UNSC, /datum/job/marine/standard/ai/halo/unsc)
	prefer_role_title_path(JOB_SQUAD_RTO_UNSC, /datum/job/marine/standard/ai/rto/halo/unsc)
	prefer_role_title_path(JOB_SQUAD_MEDIC_UNSC, /datum/job/marine/medic/ai/halo/unsc)
	prefer_role_title_path(JOB_SQUAD_TEAM_LEADER_UNSC, /datum/job/marine/tl/ai/halo/unsc)
	prefer_role_title_path(JOB_SQUAD_LEADER_UNSC, /datum/job/marine/leader/ai/halo/unsc)
	prefer_role_title_path(JOB_SQUAD_SPECIALIST_UNSC, /datum/job/marine/specialist/ai/halo/unsc)
	prefer_role_title_path(JOB_SQUAD_MARINE_ODST, /datum/job/marine/standard/ai/halo/odst)
	prefer_role_title_path(JOB_SQUAD_RTO_ODST, /datum/job/marine/standard/ai/rto/halo/odst)
	prefer_role_title_path(JOB_SQUAD_MEDIC_ODST, /datum/job/marine/medic/ai/halo/odst)
	prefer_role_title_path(JOB_SQUAD_TEAM_LEADER_ODST, /datum/job/marine/tl/ai/halo/odst)
	prefer_role_title_path(JOB_SQUAD_LEADER_ODST, /datum/job/marine/leader/ai/halo/odst)
	prefer_role_title_path(JOB_SQUAD_SPECIALIST_ODST, /datum/job/marine/specialist/ai/halo/odst)

/datum/authority/branch/role/proc/prefer_role_title_path(role_title, role_path)
	if(!role_title || !role_path || !islist(roles_by_path) || !islist(roles_by_name))
		return

	var/datum/job/preferred_role = roles_by_path[role_path]
	if(preferred_role)
		roles_by_name[role_title] = preferred_role

/datum/squad/marine/halo/unsc/alpha
	parent_type = /datum/squad/marine/alpha
	faction = FACTION_UNSC
	prepend_squad_name_to_assignment = FALSE
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
	prepend_squad_name_to_assignment = FALSE
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
	prepend_squad_name_to_assignment = FALSE
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
	prepend_squad_name_to_assignment = FALSE
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
	prepend_squad_name_to_assignment = FALSE
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
	prepend_squad_name_to_assignment = FALSE
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
	prepend_squad_name_to_assignment = FALSE
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
	prepend_squad_name_to_assignment = FALSE
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

/datum/authority/branch/role/proc/get_modular_job_pref_to_gear_preset(job_title)
	var/platoon_type
	if(job_title in JOB_HALO_UNSC_SHIPSIDE_LIST)
		platoon_type = /datum/squad/marine/halo/unsc/alpha
	else if(job_title in JOB_HALO_ODST_SHIPSIDE_LIST)
		platoon_type = /datum/squad/marine/halo/odst/alpha

	if(!platoon_type)
		return null

	var/canonical_role = get_job_preference_bucket_key(job_title)
	if(!canonical_role)
		return null

	var/list/preview_presets = get_halo_job_preference_preview_presets(platoon_type)
	if(!islist(preview_presets))
		return null

	return preview_presets[canonical_role]

/datum/authority/branch/role/proc/get_halo_job_preference_preview_presets(platoon_type)
	switch(platoon_type)
		if(/datum/squad/marine/halo/unsc/alpha)
			return list(
				JOB_SO = /datum/equipment_preset/unsc/platco/equipped,
				JOB_SQUAD_MARINE = /datum/equipment_preset/unsc/pfc/equipped,
				JOB_SQUAD_MEDIC = /datum/equipment_preset/unsc/medic/equipped,
				JOB_SQUAD_RTO = /datum/equipment_preset/unsc/rto/equipped,
				JOB_SQUAD_TEAM_LEADER = /datum/equipment_preset/unsc/tl/equipped,
				JOB_SQUAD_LEADER = /datum/equipment_preset/unsc/leader/equipped,
				JOB_SQUAD_SPECIALIST = /datum/equipment_preset/unsc/spec/equipped_spnkr,
			)
		if(/datum/squad/marine/halo/odst/alpha)
			return list(
				JOB_SO = /datum/equipment_preset/unsc/platco/odst/equipped,
				JOB_SQUAD_MARINE = /datum/equipment_preset/unsc/pfc/odst/equipped,
				JOB_SQUAD_MEDIC = /datum/equipment_preset/unsc/medic/odst/equipped,
				JOB_SQUAD_RTO = /datum/equipment_preset/unsc/rto/odst/equipped,
				JOB_SQUAD_TEAM_LEADER = /datum/equipment_preset/unsc/tl/odst/equipped,
				JOB_SQUAD_LEADER = /datum/equipment_preset/unsc/leader/odst/equipped,
				JOB_SQUAD_SPECIALIST = /datum/equipment_preset/unsc/spec/odst/equipped_spnkr,
			)

	return null

/datum/authority/branch/role/proc/get_halo_job_family_types(job_title)
	var/platoon_type
	if(job_title in JOB_HALO_UNSC_SHIPSIDE_LIST)
		platoon_type = /datum/squad/marine/halo/unsc/alpha
	else if(job_title in JOB_HALO_ODST_SHIPSIDE_LIST)
		platoon_type = /datum/squad/marine/halo/odst/alpha

	if(!platoon_type)
		return null

	var/list/profile = get_ship_platoon_profile(platoon_type)
	if(islist(profile?["family_types"]) && length(profile["family_types"]))
		return profile["family_types"]

	return list(platoon_type)

/datum/authority/branch/role/proc/get_halo_ship_spawn_preset_overrides(platoon_type)
	switch(platoon_type)
		if(/datum/squad/marine/halo/unsc/alpha)
			return list(
				JOB_SQUAD_MARINE = list(
					/datum/equipment_preset/uscm/pfc = /datum/equipment_preset/unsc/pfc,
					/datum/equipment_preset/uscm/pfc/private = /datum/equipment_preset/unsc/pfc/lesser_rank,
					/datum/equipment_preset/uscm/pfc/lance_corporal = /datum/equipment_preset/unsc/pfc,
				),
				JOB_SQUAD_RTO = list(
					/datum/equipment_preset/uscm/rto = /datum/equipment_preset/unsc/rto,
					/datum/equipment_preset/uscm/rto/lance_corporal = /datum/equipment_preset/unsc/rto/lesser_rank,
					/datum/equipment_preset/uscm/rto/pfc = /datum/equipment_preset/unsc/rto/lesser_rank,
				),
				JOB_SQUAD_MEDIC = list(
					/datum/equipment_preset/uscm/medic = /datum/equipment_preset/unsc/medic,
					/datum/equipment_preset/uscm/medic/lance_corporal = /datum/equipment_preset/unsc/medic/lesser_rank,
					/datum/equipment_preset/uscm/medic/pfc = /datum/equipment_preset/unsc/medic/pfc,
					/datum/equipment_preset/uscm/medic/private = /datum/equipment_preset/unsc/medic/private,
				),
				JOB_SQUAD_TEAM_LEADER = list(
					/datum/equipment_preset/uscm/tl = /datum/equipment_preset/unsc/tl,
					/datum/equipment_preset/uscm/tl/corporal = /datum/equipment_preset/unsc/tl/lesser_rank,
				),
				JOB_SQUAD_LEADER = list(
					/datum/equipment_preset/uscm/leader = /datum/equipment_preset/unsc/leader,
					/datum/equipment_preset/uscm/leader/staff_sergeant = /datum/equipment_preset/unsc/leader/lesser_rank,
				),
				JOB_SQUAD_SPECIALIST = list(
					/datum/equipment_preset/uscm/specialist_equipped = /datum/equipment_preset/unsc/spec,
				),
				JOB_SO = list(
					/datum/equipment_preset/uscm_ship/so = /datum/equipment_preset/unsc/platco,
					/datum/equipment_preset/uscm_ship/so/lesser_rank = /datum/equipment_preset/unsc/platco/lesser_rank,
				),
			)
		if(/datum/squad/marine/halo/odst/alpha)
			return list(
				JOB_SQUAD_MARINE = list(
					/datum/equipment_preset/uscm/pfc = /datum/equipment_preset/unsc/pfc/odst,
					/datum/equipment_preset/uscm/pfc/private = /datum/equipment_preset/unsc/pfc/odst/lesser_rank,
					/datum/equipment_preset/uscm/pfc/lance_corporal = /datum/equipment_preset/unsc/pfc/odst,
				),
				JOB_SQUAD_RTO = list(
					/datum/equipment_preset/uscm/rto = /datum/equipment_preset/unsc/rto/odst,
					/datum/equipment_preset/uscm/rto/lance_corporal = /datum/equipment_preset/unsc/rto/odst/lesser_rank,
					/datum/equipment_preset/uscm/rto/pfc = /datum/equipment_preset/unsc/rto/odst/lesser_rank,
				),
				JOB_SQUAD_MEDIC = list(
					/datum/equipment_preset/uscm/medic = /datum/equipment_preset/unsc/medic/odst,
					/datum/equipment_preset/uscm/medic/lance_corporal = /datum/equipment_preset/unsc/medic/odst/lesser_rank,
					/datum/equipment_preset/uscm/medic/pfc = /datum/equipment_preset/unsc/medic/odst/pfc,
					/datum/equipment_preset/uscm/medic/private = /datum/equipment_preset/unsc/medic/odst/private,
				),
				JOB_SQUAD_TEAM_LEADER = list(
					/datum/equipment_preset/uscm/tl = /datum/equipment_preset/unsc/tl/odst,
					/datum/equipment_preset/uscm/tl/corporal = /datum/equipment_preset/unsc/tl/odst/lesser_rank,
				),
				JOB_SQUAD_LEADER = list(
					/datum/equipment_preset/uscm/leader = /datum/equipment_preset/unsc/leader/odst,
					/datum/equipment_preset/uscm/leader/staff_sergeant = /datum/equipment_preset/unsc/leader/odst/lesser_rank,
				),
				JOB_SQUAD_SPECIALIST = list(
					/datum/equipment_preset/uscm/specialist_equipped = /datum/equipment_preset/unsc/spec/odst,
				),
				JOB_SO = list(
					/datum/equipment_preset/uscm_ship/so = /datum/equipment_preset/unsc/platco/odst,
					/datum/equipment_preset/uscm_ship/so/lesser_rank = /datum/equipment_preset/unsc/platco/odst/lesser_rank,
				),
			)

	return null

/datum/authority/branch/role/proc/get_halo_ship_cryo_reinforcement_titles(platoon_type)
	switch(platoon_type)
		if(/datum/squad/marine/halo/unsc/alpha)
			return list(
				JOB_SO = JOB_SO_UNSC,
				JOB_SQUAD_MARINE = JOB_SQUAD_MARINE_UNSC,
				JOB_SQUAD_MEDIC = JOB_SQUAD_MEDIC_UNSC,
				JOB_SQUAD_RTO = JOB_SQUAD_RTO_UNSC,
				JOB_SQUAD_TEAM_LEADER = JOB_SQUAD_TEAM_LEADER_UNSC,
				JOB_SQUAD_LEADER = JOB_SQUAD_LEADER_UNSC,
				JOB_SQUAD_SPECIALIST = JOB_SQUAD_SPECIALIST_UNSC,
			)
		if(/datum/squad/marine/halo/odst/alpha)
			return list(
				JOB_SO = JOB_SO_ODST,
				JOB_SQUAD_MARINE = JOB_SQUAD_MARINE_ODST,
				JOB_SQUAD_MEDIC = JOB_SQUAD_MEDIC_ODST,
				JOB_SQUAD_RTO = JOB_SQUAD_RTO_ODST,
				JOB_SQUAD_TEAM_LEADER = JOB_SQUAD_TEAM_LEADER_ODST,
				JOB_SQUAD_LEADER = JOB_SQUAD_LEADER_ODST,
				JOB_SQUAD_SPECIALIST = JOB_SQUAD_SPECIALIST_ODST,
			)

	return null

/datum/authority/branch/role/proc/get_halo_ship_cryo_reinforcement_presets(platoon_type)
	switch(platoon_type)
		if(/datum/squad/marine/halo/unsc/alpha)
			return list(
				JOB_SO = /datum/equipment_preset/unsc/platco,
				JOB_SQUAD_MARINE = /datum/equipment_preset/unsc/pfc,
				JOB_SQUAD_MEDIC = /datum/equipment_preset/unsc/medic,
				JOB_SQUAD_RTO = /datum/equipment_preset/unsc/rto,
				JOB_SQUAD_TEAM_LEADER = /datum/equipment_preset/unsc/tl,
				JOB_SQUAD_LEADER = /datum/equipment_preset/unsc/leader,
				JOB_SQUAD_SPECIALIST = /datum/equipment_preset/unsc/spec,
			)
		if(/datum/squad/marine/halo/odst/alpha)
			return list(
				JOB_SO = /datum/equipment_preset/unsc/platco/odst,
				JOB_SQUAD_MARINE = /datum/equipment_preset/unsc/pfc/odst,
				JOB_SQUAD_MEDIC = /datum/equipment_preset/unsc/medic/odst,
				JOB_SQUAD_RTO = /datum/equipment_preset/unsc/rto/odst,
				JOB_SQUAD_TEAM_LEADER = /datum/equipment_preset/unsc/tl/odst,
				JOB_SQUAD_LEADER = /datum/equipment_preset/unsc/leader/odst,
				JOB_SQUAD_SPECIALIST = /datum/equipment_preset/unsc/spec/odst,
			)
	return null

/datum/authority/branch/role/proc/get_halo_main_ship_profile(platoon_type = MAIN_SHIP_PLATOON)
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
					/datum/job/command/bridge/ai/halo/unsc = JOB_SO,
					/datum/job/marine/standard/ai/halo/unsc = JOB_SQUAD_MARINE,
					/datum/job/marine/standard/ai/rto/halo/unsc = JOB_SQUAD_RTO,
					/datum/job/marine/medic/ai/halo/unsc = JOB_SQUAD_MEDIC,
					/datum/job/marine/tl/ai/halo/unsc = JOB_SQUAD_TEAM_LEADER,
					/datum/job/marine/leader/ai/halo/unsc = JOB_SQUAD_LEADER,
					/datum/job/marine/specialist/ai/halo/unsc = JOB_SQUAD_SPECIALIST,
				),
				"distress_roles" = (GLOB.ROLES_CIC - JOB_SO) + GLOB.ROLES_POLICE + GLOB.ROLES_AUXIL_SUPPORT + GLOB.ROLES_MISC + GLOB.ROLES_ENGINEERING + GLOB.ROLES_REQUISITION + GLOB.ROLES_MEDICAL + list(JOB_SO_UNSC) + JOB_HALO_UNSC_MARINES_LIST + GLOB.ROLES_GROUND,
				"lowpop_roles" = list(JOB_SO_UNSC) + JOB_HALO_UNSC_MARINES_LIST,
				"spawn_preset_overrides" = get_halo_ship_spawn_preset_overrides(platoon_type),
				"cryo_reinforcement_titles" = get_halo_ship_cryo_reinforcement_titles(platoon_type),
				"cryo_reinforcement_presets" = get_halo_ship_cryo_reinforcement_presets(platoon_type),
				"platoon_label" = "UNSC - Marine Troopers \"War Hogs\"",
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
					/datum/job/command/bridge/ai/halo/odst = JOB_SO,
					/datum/job/marine/standard/ai/halo/odst = JOB_SQUAD_MARINE,
					/datum/job/marine/standard/ai/rto/halo/odst = JOB_SQUAD_RTO,
					/datum/job/marine/medic/ai/halo/odst = JOB_SQUAD_MEDIC,
					/datum/job/marine/tl/ai/halo/odst = JOB_SQUAD_TEAM_LEADER,
					/datum/job/marine/leader/ai/halo/odst = JOB_SQUAD_LEADER,
					/datum/job/marine/specialist/ai/halo/odst = JOB_SQUAD_SPECIALIST,
				),
				"distress_roles" = (GLOB.ROLES_CIC - JOB_SO) + GLOB.ROLES_POLICE + GLOB.ROLES_AUXIL_SUPPORT + GLOB.ROLES_MISC + GLOB.ROLES_ENGINEERING + GLOB.ROLES_REQUISITION + GLOB.ROLES_MEDICAL + list(JOB_SO_ODST) + JOB_HALO_ODST_MARINES_LIST + GLOB.ROLES_GROUND,
				"lowpop_roles" = list(JOB_SO_ODST) + JOB_HALO_ODST_MARINES_LIST,
				"spawn_preset_overrides" = get_halo_ship_spawn_preset_overrides(platoon_type),
				"cryo_reinforcement_titles" = get_halo_ship_cryo_reinforcement_titles(platoon_type),
				"cryo_reinforcement_presets" = get_halo_ship_cryo_reinforcement_presets(platoon_type),
				"platoon_label" = "ODST - 7th Shock Troops Battalion. \"War Cogs\"",
				"manifest_picture" = /atom/movable/screen/text/screen_text/picture/starting/odst,
				"intro_picture" = /atom/movable/screen/text/screen_text/picture/dark_was_the_night,
			)
	return null
