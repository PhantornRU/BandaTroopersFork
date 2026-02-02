
/datum/authority/branch/role/setup_candidates_and_roles(list/overwritten_roles_for_mode)
	. = ..()

	// Подсчитываем игроков
	var/players_ready = 0
	for(var/mob/new_player/player in GLOB.new_player_list)
		if(player.client && player.ready)
			players_ready++

	// Открываем сквад
	for(var/datum/squad/sq in GLOB.RoleAuthority.squads)
		message_admins("Проверяем [sq.name] - usable [sq.usable] - platoon [sq.platoon_associated_type] - MAIN_SHIP_PLATOON [MAIN_SHIP_PLATOON]")
		if(!sq)
			continue
		if(sq.usable)
			continue
		if(!sq.ready_players_usable && !sq.platoon_associated_type) // Хотя бы один должен быть для продолжения
			continue
		if(sq.ready_players_usable && players_ready < sq.ready_players_usable)
			message_admins(" - 1 -  Не прошел проверку [sq.name] - usable [sq.usable] - [sq.ready_players_usable]/[players_ready]")
			continue
		if(sq.platoon_associated_type && sq.platoon_associated_type != MAIN_SHIP_PLATOON) //!istype(MAIN_SHIP_PLATOON, sq.platoon_associated_type))
			message_admins(" - 2 - Не прошел проверку [sq.name] - [sq.platoon_associated_type] - MAIN_SHIP_PLATOON [MAIN_SHIP_PLATOON]")
			continue
		sq.usable = TRUE
		message_admins(" +++ ПРОВЕРКА ПРОЙДЕНА [sq.name] - usable [sq.usable] - platoon [sq.platoon_associated_type] - MAIN_SHIP_PLATOON [MAIN_SHIP_PLATOON]")



/datum/authority/branch/role/check_role_entry(mob/new_player/M, datum/job/J, latejoin = FALSE)
	. = ..()
    // !!!!! Необходимо с лейт джоином определиться и пройти NUM/MAX по всем имеющимся отрядам

    // !!!!! Либо просто увеличивать Total Spawns когда связанные отряды добавляются. 
    // Т.е. к общему числу при добавлении отряда в пул,
    // будет total_positions + bravo.total_positions + charlie.toral_positions, а Дельта не заслужила и не добавляет.

















// Прок используемый в can_start() для Pre-pre-startup
// /datum/game_mode/initialize_special_clamps()
// 	. = ..()

// 	// Подсчитываем игроков
// 	var/players_ready = 0
// 	for(var/mob/new_player/player in GLOB.new_player_list)
// 		if(player.client && player.ready)
// 			players_ready++

// 	// Открываем сквад
// 	for(var/datum/squad/sq in GLOB.RoleAuthority.squads)
// 		message_admins("Проверяем [sq.name] - usable [sq.usable] - platoon [sq.platoon_associated_type] - MAIN_SHIP_PLATOON [MAIN_SHIP_PLATOON]")
// 		if(!sq)
// 			continue
// 		if(sq.usable && (!sq.ready_players_usable || !sq.platoon_associated_type))
// 			continue
// 		if(sq.ready_players_usable && players_ready < sq.ready_players_usable)
// 			message_admins(" - 1 -  Не прошел проверку [sq.name] - usable [sq.usable] - [sq.ready_players_usable]/[players_ready]")
// 			continue
// 		if(sq.platoon_associated_type && sq.platoon_associated_type != MAIN_SHIP_PLATOON) //!istype(MAIN_SHIP_PLATOON, sq.platoon_associated_type))
// 			message_admins(" - 2 - Не прошел проверку [sq.name] - [sq.platoon_associated_type] - MAIN_SHIP_PLATOON [MAIN_SHIP_PLATOON]")
// 			continue
// 		sq.usable = TRUE
// 		message_admins(" +++ ПРОВЕРКА ПРОЙДЕНА [sq.name] - usable [sq.usable] - platoon [sq.platoon_associated_type] - MAIN_SHIP_PLATOON [MAIN_SHIP_PLATOON]")

