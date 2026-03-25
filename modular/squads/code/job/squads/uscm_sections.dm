/datum/squad/marine/alpha
	equipment_color = "#db1d1d"
	chat_color = "#db1d1d"
	max_riflemen = 2
	max_engineers = 0
	max_medics = 2
	max_specialists = 1
	max_tl = 2
	max_smartgun = 2
	max_leaders = 1
	max_rto = 1

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
	usable = FALSE
	ready_players_usable = 8
	platoon_associated_type = /datum/squad/marine/alpha
	max_riflemen = 2
	max_engineers = 4
	max_medics = 0
	max_specialists = 1
	max_tl = 2
	max_smartgun = 1
	max_leaders = 1
	max_rto = 1

/datum/squad/marine/delta
	equipment_color = "#4148c8"
	chat_color = "#828cff"
	access = list(ACCESS_MARINE_ALPHA, ACCESS_MARINE_DELTA)
	minimap_color = MINIMAP_SQUAD_DELTA
	use_stripe_overlay = FALSE
	roundstart = TRUE
	active = TRUE
	squad_type = "Section"
	usable = FALSE
	ready_players_usable = 16
	platoon_associated_type = /datum/squad/marine/alpha
	max_riflemen = 2
	max_engineers = 0
	max_medics = 2
	max_specialists = 1
	max_tl = 2
	max_smartgun = 2
	max_leaders = 1
	max_rto = 1

/datum/squad/marine/charlie
	equipment_color = "#c864c8"
	chat_color = "#ff96ff"
	access = list(ACCESS_MARINE_ALPHA, ACCESS_MARINE_CHARLIE)
	minimap_color = MINIMAP_SQUAD_CHARLIE
	use_stripe_overlay = FALSE
	roundstart = TRUE
	active = TRUE
	squad_type = "Section"
	usable = FALSE
	ready_players_usable = 24
	platoon_associated_type = /datum/squad/marine/alpha
	max_riflemen = 2
	max_engineers = 0
	max_medics = 4
	max_specialists = 0
	max_tl = 2
	max_smartgun = 1
	max_leaders = 1
	max_rto = 1
