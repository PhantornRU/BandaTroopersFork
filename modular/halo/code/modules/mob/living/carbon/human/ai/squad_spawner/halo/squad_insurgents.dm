/datum/human_ai_squad_preset/insurgent
	faction = FACTION_INSURGENT

/datum/human_ai_squad_preset/insurgent/partisan_patrol
	name = "Партизанский патруль (броня, ПП + пистолет)"
	desc = "Пара плохо обученных и слабо экипированных партизан."
	ai_to_spawn = list(
		/datum/equipment_preset/insurgent/partisan/smg = 1,
		/datum/equipment_preset/insurgent/partisan = 1,
	)

/datum/human_ai_squad_preset/insurgent/partisan_patrol/plainclothes
	name = "Партизанский патруль (гражданка, ПП + пистолет)"
	desc = "Пара плохо обученных и слабо экипированных партизан."
	ai_to_spawn = list(
		/datum/equipment_preset/insurgent/partisan/plainclothes/smg = 1,
		/datum/equipment_preset/insurgent/partisan/plainclothes = 1,
	)

/datum/human_ai_squad_preset/insurgent/partisan_squad
	name = "Партизанская штурмовая группа"
	desc = "Группа плохо обученных и слабо экипированных партизан под командованием партизана-взломщика."
	ai_to_spawn = list(
		/datum/equipment_preset/insurgent/partisan/breach = 1,
		/datum/equipment_preset/insurgent/partisan/smg = 2,
		/datum/equipment_preset/insurgent/partisan = 1,
	)

/datum/human_ai_squad_preset/insurgent/patrol
	name = "Патруль инсургентов"
	desc = "Пара солдат инсургентов, собранная в патрульную группу."
	ai_to_spawn = list(
		/datum/equipment_preset/insurgent/rifleman = 2,
	)

/datum/human_ai_squad_preset/insurgent/at_team
	name = "ПТ-группа инсургентов"
	desc = "Пара солдат инсургентов, один из которых вооружен установкой SPNKR для противотанковой роли."
	ai_to_spawn = list(
		/datum/equipment_preset/insurgent/specialist = 1,
		/datum/equipment_preset/insurgent/rifleman = 1,
	)

/datum/human_ai_squad_preset/insurgent/sapper_team
	name = "Саперная группа инсургентов"
	desc = "Пара солдат инсургентов, один из которых выполняет роль техника-сапера."
	ai_to_spawn = list(
		/datum/equipment_preset/insurgent/technician = 1,
		/datum/equipment_preset/insurgent/rifleman = 1,
	)

/datum/human_ai_squad_preset/insurgent/squad
	name = "Отряд инсургентов"
	desc = "Отряд солдат инсургентов под командованием лидера отделения."
	ai_to_spawn = list(
		/datum/equipment_preset/insurgent/rifleman/sl = 1,
		/datum/equipment_preset/insurgent/rifleman = 2,
		/datum/equipment_preset/insurgent/technician = 1,
	)
