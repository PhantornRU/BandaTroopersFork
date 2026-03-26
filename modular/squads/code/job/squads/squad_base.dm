/datum/squad
	max_engineers = 3
	max_medics = 2
	max_specialists = 1
	max_tl = 2
	max_smartgun = 2
	max_leaders = 1
	var/max_riflemen = 4
	var/max_rto = 0
	var/num_rto = 0
	var/staff_per_squad = 1
	var/ready_players_usable
	var/platoon_associated_type

/datum/squad/proc/is_modular_platoon_match(active_ship_platoon)
	if(!platoon_associated_type || !active_ship_platoon)
		return FALSE

	return active_ship_platoon == platoon_associated_type || istype(platoon_associated_type, active_ship_platoon) || istype(active_ship_platoon, platoon_associated_type)

/datum/squad/proc/can_enable_for_modular_roundstart(players_ready, active_ship_platoon)
	if(usable)
		return FALSE
	if(!ready_players_usable && !platoon_associated_type)
		return FALSE
	if(ready_players_usable && players_ready < ready_players_usable)
		return FALSE
	if(platoon_associated_type && !is_modular_platoon_match(active_ship_platoon))
		return FALSE

	return TRUE
