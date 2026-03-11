/datum/job/marine/standard/ai/odst
	parent_type = /datum/job/marine/standard/ai/halo/odst

/datum/job/marine/standard/ai/rto/odst
	parent_type = /datum/job/marine/standard/ai/rto/halo/odst

/datum/job/marine/leader/ai/odst
	parent_type = /datum/job/marine/leader/ai/halo/odst

/datum/job/marine/medic/ai/odst
	parent_type = /datum/job/marine/medic/ai/halo/odst

/datum/job/marine/tl/ai/odst
	parent_type = /datum/job/marine/tl/ai/halo/odst

/datum/job/marine/specialist/ai/odst
	parent_type = /datum/job/marine/specialist/ai/halo/odst

/obj/effect/landmark/start/marine/odst
	name = JOB_SQUAD_MARINE_ODST
	squad = SQUAD_ODST
	job = /datum/job/marine/standard/ai/odst

/obj/effect/landmark/start/marine/rto/odst
	name = JOB_SQUAD_RTO_ODST
	squad = SQUAD_ODST
	job = /datum/job/marine/standard/ai/rto/odst

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
