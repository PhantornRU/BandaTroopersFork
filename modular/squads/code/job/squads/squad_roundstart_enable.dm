/datum/authority/branch/role/setup_candidates_and_roles(list/overwritten_roles_for_mode)
	. = ..()
	var/active_ship_platoon = get_active_ship_platoon_type()
	var/players_ready = 0

	for(var/mob/new_player/player in GLOB.new_player_list)
		if(player.client && player.ready)
			players_ready++

	for(var/datum/squad/sq in GLOB.RoleAuthority.squads)
		if(!sq || !sq.can_enable_for_modular_roundstart(players_ready, active_ship_platoon))
			continue
		if(sq.platoon_associated_type)
			associated_squad_job_positions(sq.platoon_associated_type)

		sq.usable = TRUE

/datum/authority/branch/role/proc/associated_squad_job_positions(platoon_associated_type)
	var/datum/squad/associated_squad = GLOB.RoleAuthority.squads_by_type[platoon_associated_type]
	if(!associated_squad)
		return

	for(var/role in GLOB.RoleAuthority.roles_by_path)
		var/datum/job/job = GLOB.RoleAuthority.roles_by_path[role]
		if(!job)
			continue

		var/additional_positions = associated_squad.get_modular_role_limit(GET_DEFAULT_ROLE(job.title))
		if(isnull(additional_positions) || !additional_positions)
			continue

		job.total_positions += additional_positions
		job.spawn_positions += additional_positions

/datum/authority/branch/role/check_squad_capacity(mob/living/carbon/human/transfer_marine, datum/squad/new_squad)
	. = ..()
	if(.)
		return

	var/default_role = GET_DEFAULT_ROLE(transfer_marine.job)
	var/current_count = new_squad.get_modular_role_current_count(default_role)
	var/max_count = new_squad.get_modular_role_limit(default_role)
	if(!isnull(current_count) && !isnull(max_count) && current_count >= max_count)
		return TRUE
