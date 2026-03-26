/datum/human_ai_squad_preset/police
	faction = FACTION_UEG_POLICE

/datum/human_ai_squad_preset/police/patrol
	name = "Патруль полиции UEG (без снаряжения)"
	desc = "Пара офицеров полиции UEG без брони."
	ai_to_spawn = list(
		/datum/equipment_preset/police/officer = 2,
	)

/datum/human_ai_squad_preset/police/patrol/armored
	name = "Патруль полиции UEG (снаряженный, пистолет + ПП)"
	desc = "Пара офицеров полиции UEG в броне, один из них вооружен ПП."
	ai_to_spawn = list(
		/datum/equipment_preset/police/officer/geared/smg = 1,
		/datum/equipment_preset/police/officer/geared = 1,
	)

/datum/human_ai_squad_preset/police/squad
	name = "Отряд полиции UEG"
	desc = "Отряд офицеров полиции UEG, полностью оснащенный для боевых действий."
	ai_to_spawn = list(
		/datum/equipment_preset/police/officer/sergeant/geared = 1,
		/datum/equipment_preset/police/officer/geared/smg = 2,
		/datum/equipment_preset/police/officer/geared = 1,
	)
