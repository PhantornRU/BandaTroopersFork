/datum/squad/proc/get_modular_role_limit(canonical_role)
	switch(canonical_role)
		if(JOB_SQUAD_MARINE)
			return max_riflemen
		if(JOB_SQUAD_ENGI)
			return max_engineers
		if(JOB_SQUAD_MEDIC)
			return max_medics
		if(JOB_SQUAD_SPECIALIST)
			return max_specialists
		if(JOB_SQUAD_SMARTGUN)
			return max_smartgun
		if(JOB_SQUAD_TEAM_LEADER)
			return max_tl
		if(JOB_SQUAD_LEADER)
			return max_leaders
		if(JOB_SQUAD_RTO)
			return max_rto
		if(JOB_SO)
			return staff_per_squad

	return null

/datum/squad/proc/get_modular_role_current_count(canonical_role)
	switch(canonical_role)
		if(JOB_SQUAD_MARINE)
			return num_riflemen
		if(JOB_SQUAD_RTO)
			return num_rto

	return null

/datum/squad/proc/adjust_modular_role_counter(canonical_role, delta)
	if(!canonical_role || !delta)
		return

	switch(canonical_role)
		if(JOB_SQUAD_MARINE)
			num_riflemen = max(0, num_riflemen + delta)
		if(JOB_SQUAD_RTO)
			num_rto = max(0, num_rto + delta)

/datum/squad/marine/apply_modular_forget_role_counters(mob/living/carbon/human/M)
	adjust_modular_role_counter(GET_DEFAULT_ROLE(M?.job), -1)
