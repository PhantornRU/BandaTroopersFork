/datum/job/marine/standard/ai/odst
	title = JOB_SQUAD_MARINE_ODST
	gear_preset = /datum/equipment_preset/unsc/pfc/odst
	gear_preset_secondary = /datum/equipment_preset/unsc/pfc/odst/lesser_rank
	job_options = list(PFC_VARIANT = "LCPL", PVT_VARIANT = "PFC")

/datum/job/marine/standard/ai/rto/odst
	title = JOB_SQUAD_RTO_ODST
	gear_preset = /datum/equipment_preset/unsc/rto/odst
	gear_preset_secondary = /datum/equipment_preset/unsc/rto/odst/lesser_rank
	job_options = list(PFC_VARIANT = "PFC", LCPL_VARIANT = "LCPL")

/datum/job/marine/leader/ai/odst
	title = JOB_SQUAD_LEADER_ODST
	gear_preset = /datum/equipment_preset/unsc/leader/odst
	gear_preset_secondary = /datum/equipment_preset/unsc/leader/odst/lesser_rank

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
