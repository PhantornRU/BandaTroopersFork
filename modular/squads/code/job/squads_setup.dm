
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
		if(sq.platoon_associated_type)
			if(sq.platoon_associated_type != MAIN_SHIP_PLATOON) //!istype(MAIN_SHIP_PLATOON, sq.platoon_associated_type))
				message_admins(" - 2 - Не прошел проверку [sq.name] - [sq.platoon_associated_type] - MAIN_SHIP_PLATOON [MAIN_SHIP_PLATOON]")
				continue
			associated_squad_job_positions(sq.platoon_associated_type)

		sq.usable = TRUE
		message_admins(" +++ ПРОВЕРКА ПРОЙДЕНА [sq.name] - usable [sq.usable] - platoon [sq.platoon_associated_type] - MAIN_SHIP_PLATOON [MAIN_SHIP_PLATOON]")


/datum/authority/branch/role/proc/associated_squad_job_positions(platoon_associated_type)
	var/datum/squad/associated_squad = GLOB.RoleAuthority.squads_by_type[platoon_associated_type]
	message_admins("[platoon_associated_type] - проверяем ассоциативный [associated_squad]")
	for(var/role in GLOB.RoleAuthority.roles_by_path)
		var/datum/job/job = GLOB.RoleAuthority.roles_by_path[role]
		// var/datum/job/job_mapped = GET_MAPPED_ROLE(job_path)
		var/additional_positions = 0
		switch(job.title)
			if(JOB_SQUAD_MARINE)
				additional_positions = associated_squad.max_riflemen
			if(JOB_SQUAD_ENGI)
				additional_positions = associated_squad.max_engineers
			if(JOB_SQUAD_MEDIC)
				additional_positions = associated_squad.max_medics
			if(JOB_SQUAD_SPECIALIST)
				additional_positions = associated_squad.max_specialists
			if(JOB_SQUAD_SMARTGUN)
				additional_positions = associated_squad.max_smartgun
			if(JOB_SQUAD_LEADER)
				additional_positions = associated_squad.max_leaders
			if(JOB_SQUAD_TEAM_LEADER)
				additional_positions = associated_squad.max_tl
			if(JOB_SO, JOB_SQUAD_RTO)
				additional_positions = associated_squad.staff_per_squad
		message_admins("[associated_squad] +++ [job] было [job.total_positions] - станет [job.total_positions + additional_positions]")
		job.total_positions += additional_positions
		job.spawn_positions += additional_positions
