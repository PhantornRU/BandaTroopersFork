/datum/squad
	max_engineers = 3
	max_medics = 3 // на 1 меньше, для более равномерного распределения по отрядам
	max_specialists = 1
	max_tl = 3
	max_smartgun = 2
	max_leaders = 1
	var/max_riflemen = 6 // Ограничиваем количество пехоты на один отряд

	/// После скольких READY игроков открывается этот отряд.
	var/ready_players_usable
	/// Связь с платуном по MAIN_SHIP_PLATOON, чтобы не добавляло лишние отряды в другие режимы.
	var/platoon_associated_type

// В проке идет проверка, но нет пехоты для корректного удаления из отряда.
/datum/squad/forget_marine_in_squad(mob/living/carbon/human/M)
	. = ..()
	if(GET_DEFAULT_ROLE(M.job) == JOB_SQUAD_MARINE)
		num_riflemen--

/datum/squad/proc/try_usable_squad()

/datum/squad/marine/alpha
	equipment_color = "#db1d1d"
	chat_color = "#db1d1d"

/datum/squad/marine/bravo
	name = SQUAD_MARINE_2
	equipment_color = "#ffc32d"
	chat_color = "#ffe650"
	access = list(ACCESS_MARINE_ALPHA, ACCESS_MARINE_BRAVO)
	radio_freq = BRAVO_FREQ
	use_stripe_overlay = FALSE
	minimap_color = MINIMAP_SQUAD_BRAVO
	roundstart = TRUE
	active = TRUE
	squad_type = "Section"
	usable = FALSE // Включается при ready_players_usable готовых игроков
	ready_players_usable = 12
	platoon_associated_type = /datum/squad/marine/alpha
	

/datum/squad/marine/charlie
	equipment_color = "#c864c8"
	chat_color = "#ff96ff"
	access = list(ACCESS_MARINE_ALPHA, ACCESS_MARINE_CHARLIE)
	minimap_color = MINIMAP_SQUAD_CHARLIE
	use_stripe_overlay = FALSE
	roundstart = TRUE
	active = TRUE
	squad_type = "Section"
	usable = FALSE // Включается при ready_players_usable готовых игроков
	ready_players_usable = 1 // 24
	platoon_associated_type = /datum/squad/marine/alpha

/datum/squad/marine/delta
	equipment_color = "#4148c8"
	chat_color = "#828cff"
	access = list(ACCESS_MARINE_ALPHA, ACCESS_MARINE_DELTA)
	minimap_color = MINIMAP_SQUAD_DELTA
	use_stripe_overlay = FALSE
	roundstart = TRUE
	active = TRUE
	squad_type = "Section"
	usable = FALSE // Включается при ready_players_usable готовых игроков
	ready_players_usable = 1 // 36
	platoon_associated_type = /datum/squad/marine/alpha


/datum/squad/marine/echo
/datum/squad/marine/cryo
/datum/squad/marine/intel
/datum/squad/marine/sof
/datum/squad/marine/cbrn
/datum/squad/marine/solardevils
/datum/squad/marine/pmc
/datum/squad/marine/rmc
