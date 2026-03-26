/datum/human_ai_squad_preset/unsc
	faction = FACTION_UNSC

/datum/human_ai_squad_preset/unsc/rifleteam
	name = "UNSC, стрелковая группа"
	desc = "Патрульная группа UNSC, оснащенная базовыми винтовками и IFAK."
	ai_to_spawn = list(
		/datum/equipment_preset/unsc/pfc/equipped = 2,
	)

/datum/human_ai_squad_preset/unsc/rifleteam/tl
	name = "UNSC, стрелковая группа (TL)"
	desc = "Патрульная группа UNSC, оснащенная базовыми винтовками и IFAK."
	ai_to_spawn = list(
		/datum/equipment_preset/unsc/tl/equipped = 1,
		/datum/equipment_preset/unsc/pfc/equipped = 1,
	)

/datum/human_ai_squad_preset/unsc/atteam
	name = "UNSC, противотанковая группа"
	desc = "Специализированная противотанковая группа UNSC, оснащенная базовыми винтовками, SPNKR и IFAK."
	ai_to_spawn = list(
		/datum/equipment_preset/unsc/spec/equipped_spnkr = 1,
		/datum/equipment_preset/unsc/pfc/equipped = 1,
	)
/datum/human_ai_squad_preset/unsc/squad
	name = "UNSC, огневая группа"
	desc = "Патрульная огневая группа UNSC, вооруженная базовыми винтовками и IFAK."
	ai_to_spawn = list(
		/datum/equipment_preset/unsc/tl/equipped = 1,
		/datum/equipment_preset/unsc/pfc/equipped = 3,
	)

/datum/human_ai_squad_preset/unsc/command
	name = "UNSC, командный элемент"
	desc = "Лучше всего используется как защищаемая цель, центральный командный элемент подразделения."
	ai_to_spawn = list(
		/datum/equipment_preset/unsc/leader/equipped= 1,
		/datum/equipment_preset/unsc/pfc/equipped = 2,
		/datum/equipment_preset/unsc/rto/equipped = 1,
		/datum/equipment_preset/unsc/medic/equipped = 1,
	)
