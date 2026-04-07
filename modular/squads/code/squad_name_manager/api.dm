/datum/squad_name_manager/proc/get_runtime_name(static_name)
	return get_runtime_name_by_static(static_name)

/datum/squad_name_manager/proc/get_static_name(raw_value)
	var/static_name = resolve_static_name(raw_value)
	return static_name || raw_value

/datum/squad_name_manager/proc/get_static_name_for_squad(datum/squad/target_squad)
	var/static_name = get_static_name_by_squad(target_squad)
	return static_name || target_squad?.name

/datum/squad_name_manager/proc/get_member_assignment(datum/squad/target_squad, mob/living/carbon/human/H)
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
