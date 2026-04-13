/// RTO-specific mortar variants that fire a single round instead of an upstream barrage.
/datum/fire_support/mortar/rto_single
	impact_quantity = 1
	initiate_chat_message = "КООРДИНАТЫ ПОДТВЕРЖДЕНЫ. ФУГАСНАЯ МИНА В ПУТИ."
	initiate_screen_message = list("Координаты подтверждены, фугасная мина уже в пути!")

/datum/fire_support/mortar/smoke/rto_single
	impact_quantity = 1
	initiate_chat_message = "КООРДИНАТЫ ПОДТВЕРЖДЕНЫ. ДЫМОВАЯ МИНА В ПУТИ."
	initiate_screen_message = "Координаты подтверждены, дымовая мина уже в пути!"

/datum/fire_support/mortar/incendiary/rto_single
	impact_quantity = 1
	initiate_chat_message = "КООРДИНАТЫ ПОДТВЕРЖДЕНЫ. ЗАЖИГАТЕЛЬНАЯ МИНА В ПУТИ."
	initiate_screen_message = list("Координаты подтверждены, зажигательная мина уже в пути!")
