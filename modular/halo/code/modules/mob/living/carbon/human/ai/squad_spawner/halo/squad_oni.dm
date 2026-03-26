/datum/human_ai_squad_preset/oni
	faction = FACTION_ONI

/datum/human_ai_squad_preset/oni/team
	name = "Группа сил безопасности ONI"
	desc = "Группа стрелков сил безопасности ONI, полностью оснащенная для боевых действий."
	ai_to_spawn = list(
		/datum/equipment_preset/oni/security = 2,
	)

/datum/human_ai_squad_preset/oni/squad
	name = "Отряд сил безопасности ONI"
	desc = "Отряд сил безопасности ONI, полностью оснащенный для боевых действий."
	ai_to_spawn = list(
		/datum/equipment_preset/oni/security/lead = 1,
		/datum/equipment_preset/oni/security = 2,
		/datum/equipment_preset/oni/security/corpsman = 1,
	)
