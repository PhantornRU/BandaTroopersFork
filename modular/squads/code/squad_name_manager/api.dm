/proc/squad_name_get_runtime(static_name)
	var/datum/squad_name_manager/manager = GLOB.squad_name_manager
	if(!manager)
		return static_name
	return manager.get_runtime_name_by_static(static_name)

/proc/squad_name_get_static(raw_value)
	var/datum/squad_name_manager/manager = GLOB.squad_name_manager
	if(!manager)
		return raw_value
	var/static_name = manager.resolve_static_name(raw_value)
	return static_name || raw_value

/proc/squad_name_get_static_by_squad(datum/squad/target_squad)
	var/datum/squad_name_manager/manager = GLOB.squad_name_manager
	if(!manager)
		return target_squad?.name
	var/static_name = manager.get_static_name_by_squad(target_squad)
	return static_name || target_squad?.name

/proc/squad_name_try_apply_leader_preference(mob/living/carbon/human/H)
	var/datum/squad_name_manager/manager = GLOB.squad_name_manager
	if(!manager)
		return FALSE
	return manager.try_apply_leader_preference(H)

/proc/squad_name_try_apply_platoon_commander_preference(mob/living/carbon/human/H)
	var/datum/squad_name_manager/manager = GLOB.squad_name_manager
	if(!manager)
		return FALSE
	return manager.try_apply_platoon_commander_preference(H)

/proc/squad_name_get_member_assignment(datum/squad/target_squad, mob/living/carbon/human/H)
	if(!istype(target_squad) || !istype(H))
		return null

	var/base_assignment = H.assigned_equipment_preset?.assignment || H.job
	if(!base_assignment)
		return null

	var/canonical_role = GET_DEFAULT_ROLE(H.job)
	if(GLOB.job_squad_roles.Find(canonical_role))
		var/role_label = canonical_role
		switch(canonical_role)
			if(JOB_SQUAD_LEADER, JOB_SQUAD_TEAM_LEADER)
				role_label = target_squad.get_role_label(canonical_role)
		return "[target_squad.name] [role_label]"

	if(target_squad.prepend_squad_name_to_assignment)
		return "[target_squad.name] [base_assignment]"

	return base_assignment
