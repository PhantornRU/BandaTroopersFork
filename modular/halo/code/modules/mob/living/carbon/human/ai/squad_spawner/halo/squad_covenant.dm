/datum/human_ai_squad_preset/covenant
	faction = FACTION_COVENANT

/datum/human_ai_squad_preset/covenant/unggoy_pair
	name = "Пара унггоев"
	desc = "Минимальная разведывательная пара Ковенанта из двух унггоев с плазменным оружием."
	ai_to_spawn = list(
		/datum/equipment_preset/covenant/unggoy/ai/minor_plasma = 2,
	)

/datum/human_ai_squad_preset/covenant/unggoy_needle_pair
	name = "Пара унггоев с игольниками"
	desc = "Легкая скирмиш-пара с игольниками и запасными кристаллами."
	ai_to_spawn = list(
		/datum/equipment_preset/covenant/unggoy/ai/minor_needler = 2,
	)

/datum/human_ai_squad_preset/covenant/unggoy_fireteam
	name = "Огневая группа унггоев"
	desc = "Линейная огневая группа под командованием одного мажора и трех миноров с плазменным оружием."
	ai_to_spawn = list(
		/datum/equipment_preset/covenant/unggoy/ai/major_plasma = 1,
		/datum/equipment_preset/covenant/unggoy/ai/minor_plasma = 3,
	)

/datum/human_ai_squad_preset/covenant/unggoy_assault_team
	name = "Штурмовая группа унггоев"
	desc = "Штурмовая группа с мажором-игольником, поддержкой с плазменной винтовкой и линейными бойцами с плазмой."
	ai_to_spawn = list(
		/datum/equipment_preset/covenant/unggoy/ai/major_needler = 1,
		/datum/equipment_preset/covenant/unggoy/ai/heavy_plasma = 1,
		/datum/equipment_preset/covenant/unggoy/ai/minor_plasma = 2,
	)

/datum/human_ai_squad_preset/covenant/unggoy_heavy_team
	name = "Тяжелая группа унггоев"
	desc = "Ветеранская группа тяжелой поддержки под командованием ультры, с тяжеловесами с плазменной винтовкой и игольником."
	ai_to_spawn = list(
		/datum/equipment_preset/covenant/unggoy/ai/ultra = 1,
		/datum/equipment_preset/covenant/unggoy/ai/heavy_plasma = 1,
		/datum/equipment_preset/covenant/unggoy/ai/heavy_needler = 1,
		/datum/equipment_preset/covenant/unggoy/ai/minor_plasma = 1,
	)

/datum/human_ai_squad_preset/covenant/unggoy_support_team
	name = "Группа поддержки унггоев"
	desc = "Отряд поддержки унггоев с дьяконом-надзирателем и медицинским бойцом поддержки."
	ai_to_spawn = list(
		/datum/equipment_preset/covenant/unggoy/ai/deacon_command = 1,
		/datum/equipment_preset/covenant/unggoy/ai/support_medical = 1,
		/datum/equipment_preset/covenant/unggoy/ai/minor_plasma = 2,
	)

/datum/human_ai_squad_preset/covenant/unggoy_at_team
	name = "Прорывная группа унггоев"
	desc = "Ветеранская группа прорыва, собранная вокруг лидера-ультры, тяжелой поддержки и медицинского помощника."
	ai_to_spawn = list(
		/datum/equipment_preset/covenant/unggoy/ai/ultra = 1,
		/datum/equipment_preset/covenant/unggoy/ai/heavy_plasma = 1,
		/datum/equipment_preset/covenant/unggoy/ai/support_medical = 1,
		/datum/equipment_preset/covenant/unggoy/ai/minor_plasma = 1,
	)

/datum/human_ai_squad_preset/covenant/unggoy_specops_cell
	name = "Ячейка SpecOps унггоев"
	desc = "Скрытная ячейка с одной ультрой SpecOps, координирующей специалистов по плазме и игольникам."
	ai_to_spawn = list(
		/datum/equipment_preset/covenant/unggoy/ai/specops_ultra = 1,
		/datum/equipment_preset/covenant/unggoy/ai/specops_plasma = 1,
		/datum/equipment_preset/covenant/unggoy/ai/specops_needler = 2,
	)

/datum/human_ai_squad_preset/covenant/unggoy_swarm
	name = "Рой унггоев"
	desc = "Плотная стая унггоев с двумя мажорами, несколькими минорами с плазмой и парой носителей игольников."
	ai_to_spawn = list(
		/datum/equipment_preset/covenant/unggoy/ai/major_plasma = 1,
		/datum/equipment_preset/covenant/unggoy/ai/major_needler = 1,
		/datum/equipment_preset/covenant/unggoy/ai/minor_plasma = 4,
		/datum/equipment_preset/covenant/unggoy/ai/minor_needler = 2,
	)

/datum/human_ai_squad_preset/covenant/covenant_lance
	name = "Копье Ковенанта"
	desc = "Смешанное копье Ковенанта под командованием сангхейли-минора при поддержке ветеранов-унггоев."
	ai_to_spawn = list(
		/datum/equipment_preset/covenant/sangheili/ai/minor_plasma = 1,
		/datum/equipment_preset/covenant/unggoy/ai/major_plasma = 1,
		/datum/equipment_preset/covenant/unggoy/ai/minor_plasma = 3,
		/datum/equipment_preset/covenant/unggoy/ai/minor_needler = 1,
	)

/datum/human_ai_squad_preset/covenant/covenant_heavy_lance
	name = "Тяжелое копье Ковенанта"
	desc = "Тяжелое смешанное копье под командованием сангхейли, с карабинным прикрытием и несколькими тяжелыми унггоями."
	ai_to_spawn = list(
		/datum/equipment_preset/covenant/sangheili/ai/ultra_plasma = 1,
		/datum/equipment_preset/covenant/sangheili/ai/major_carbine = 1,
		/datum/equipment_preset/covenant/unggoy/ai/heavy_plasma = 1,
		/datum/equipment_preset/covenant/unggoy/ai/heavy_needler = 1,
		/datum/equipment_preset/covenant/unggoy/ai/minor_plasma = 2,
	)

/datum/human_ai_squad_preset/covenant/covenant_at_lance
	name = "Прорывное копье Ковенанта"
	desc = "Смешанное копье прорыва с командиром-зилотом, ветеранской поддержкой ультры и тяжелыми плазменными заслонами."
	ai_to_spawn = list(
		/datum/equipment_preset/covenant/sangheili/ai/zealot_command = 1,
		/datum/equipment_preset/covenant/unggoy/ai/ultra = 1,
		/datum/equipment_preset/covenant/unggoy/ai/heavy_plasma = 1,
		/datum/equipment_preset/covenant/unggoy/ai/support_medical = 1,
		/datum/equipment_preset/covenant/unggoy/ai/minor_plasma = 2,
	)

/datum/human_ai_squad_preset/covenant/unggoy_suicide_pack
	name = "Стая унггоев-смертников"
	desc = "Специализированная стая унггоев-смертников, которая активирует парные плазменные гранаты и бросается на враждебные цели."
	ai_to_spawn = list(
		/datum/equipment_preset/covenant/unggoy/ai/suicide_bomber = 3,
	)

/datum/human_ai_squad_preset/covenant/sangheili_pair
	name = "Пара сангхейли"
	desc = "Легкий патруль из двух воинов-сангхейли, вооруженных плазменными винтовками."
	ai_to_spawn = list(
		/datum/equipment_preset/covenant/sangheili/ai/minor_plasma = 2,
	)

/datum/human_ai_squad_preset/covenant/sangheili_fireteam
	name = "Огневая группа сангхейли"
	desc = "Дисциплинированная огневая группа сангхейли под командованием мажора с двумя минорами с плазменным оружием."
	ai_to_spawn = list(
		/datum/equipment_preset/covenant/sangheili/ai/major_carbine = 1,
		/datum/equipment_preset/covenant/sangheili/ai/minor_plasma = 2,
	)

/datum/human_ai_squad_preset/covenant/sangheili_elite_team
	name = "Элитная группа сангхейли"
	desc = "Ветеранский отряд сангхейли, собранный вокруг ультры, мажора с карабином и поддерживающих миноров."
	ai_to_spawn = list(
		/datum/equipment_preset/covenant/sangheili/ai/ultra_plasma = 1,
		/datum/equipment_preset/covenant/sangheili/ai/major_carbine = 1,
		/datum/equipment_preset/covenant/sangheili/ai/minor_plasma = 2,
	)

/datum/human_ai_squad_preset/covenant/sangheili_sword_pair
	name = "Пара сангхейли с мечами"
	desc = "Ударная пара ультр-сангхейли, вооруженных только энергетическими мечами."
	ai_to_spawn = list(
		/datum/equipment_preset/covenant/sangheili/ai/ultra_sword = 2,
	)

/datum/human_ai_squad_preset/covenant/sangheili_zealot_strike_cell
	name = "Ударная ячейка зилота-сангхейли"
	desc = "Ударная ячейка под командованием зилота с ультрами с мечами и плазменной поддержкой."
	ai_to_spawn = list(
		/datum/equipment_preset/covenant/sangheili/ai/zealot_sword = 1,
		/datum/equipment_preset/covenant/sangheili/ai/ultra_sword = 1,
		/datum/equipment_preset/covenant/sangheili/ai/ultra_plasma = 1,
	)
