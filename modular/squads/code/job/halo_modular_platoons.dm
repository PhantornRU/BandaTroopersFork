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
	ready_players_usable = 8
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
	ready_players_usable = 16
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
	ready_players_usable = 8
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
	ready_players_usable = 16
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

/datum/authority/branch/role/proc/get_modular_job_pref_to_gear_preset(job_title)
	var/platoon_type = get_halo_platoon_type_for_job(job_title)
	if(!platoon_type)
		return null

	var/canonical_role = get_job_preference_bucket_key(job_title)
	if(!canonical_role)
		return null

	var/datum/modular_ship_platoon_profile/halo/profile = get_halo_ship_platoon_profile_datum(platoon_type)
	if(!profile)
		return null

	var/list/preview_presets = profile.get_preview_presets()
	if(!islist(preview_presets))
		return null

	return preview_presets[canonical_role]

/datum/authority/branch/role/proc/get_halo_job_preference_preview_presets(platoon_type)
	var/datum/modular_ship_platoon_profile/halo/profile = get_halo_ship_platoon_profile_datum(platoon_type)
	if(!profile)
		return null

	return profile.get_preview_presets()

/datum/authority/branch/role/proc/get_halo_job_family_types(job_title)
	var/platoon_type = get_halo_platoon_type_for_job(job_title)
	if(!platoon_type)
		return null

	var/datum/modular_ship_platoon_profile/halo/profile = get_halo_ship_platoon_profile_datum(platoon_type)
	if(!profile)
		return list(platoon_type)

	return profile.get_family_types()

/datum/authority/branch/role/proc/get_halo_ship_spawn_preset_overrides(platoon_type)
	var/datum/modular_ship_platoon_profile/halo/profile = get_halo_ship_platoon_profile_datum(platoon_type)
	if(!profile)
		return null

	return profile.get_spawn_preset_overrides()

/datum/authority/branch/role/proc/get_halo_ship_cryo_reinforcement_titles(platoon_type)
	var/datum/modular_ship_platoon_profile/halo/profile = get_halo_ship_platoon_profile_datum(platoon_type)
	if(!profile)
		return null

	return profile.get_cryo_reinforcement_titles()

/datum/authority/branch/role/proc/get_halo_ship_cryo_reinforcement_presets(platoon_type)
	var/datum/modular_ship_platoon_profile/halo/profile = get_halo_ship_platoon_profile_datum(platoon_type)
	if(!profile)
		return null

	return profile.get_cryo_reinforcement_presets()

/datum/authority/branch/role/proc/get_halo_main_ship_profile(platoon_type = MAIN_SHIP_PLATOON)
	var/datum/modular_ship_platoon_profile/halo/profile = get_halo_ship_platoon_profile_datum(platoon_type)
	if(!profile)
		return null

	return profile.build_profile()
