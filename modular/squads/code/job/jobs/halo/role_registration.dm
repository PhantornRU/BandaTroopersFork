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
