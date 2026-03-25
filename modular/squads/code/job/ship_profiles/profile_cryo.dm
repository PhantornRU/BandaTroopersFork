/datum/authority/branch/role/proc/get_ship_cryo_reinforcement_title(canonical_role, platoon_type)
	if(!canonical_role || !platoon_type)
		return null

	canonical_role = get_job_preference_bucket_key(canonical_role) || canonical_role

	var/datum/modular_ship_platoon_profile/profile = get_ship_platoon_profile_datum(platoon_type)
	var/list/cryo_reinforcement_titles = profile ? profile.get_cryo_reinforcement_titles() : null
	if(!islist(cryo_reinforcement_titles))
		return null

	return cryo_reinforcement_titles[canonical_role]

/datum/authority/branch/role/proc/get_active_ship_cryo_reinforcement_title(canonical_role, platoon_type = get_active_ship_platoon_type())
	return get_ship_cryo_reinforcement_title(canonical_role, platoon_type)

/datum/authority/branch/role/proc/get_ship_cryo_reinforcement_preset(canonical_role, platoon_type)
	if(!canonical_role || !platoon_type)
		return null

	canonical_role = get_job_preference_bucket_key(canonical_role) || canonical_role

	var/datum/modular_ship_platoon_profile/profile = get_ship_platoon_profile_datum(platoon_type)
	var/list/cryo_reinforcement_presets = profile ? profile.get_cryo_reinforcement_presets() : null
	if(!islist(cryo_reinforcement_presets))
		return null

	return cryo_reinforcement_presets[canonical_role]

/datum/authority/branch/role/proc/get_active_ship_cryo_reinforcement_preset(canonical_role, platoon_type = get_active_ship_platoon_type())
	return get_ship_cryo_reinforcement_preset(canonical_role, platoon_type)

/datum/authority/branch/role/proc/has_active_ship_cryo_reinforcement_overrides(platoon_type = get_active_ship_platoon_type())
	var/datum/modular_ship_platoon_profile/profile = get_ship_platoon_profile_datum(platoon_type)
	if(!profile)
		return FALSE

	return islist(profile.get_cryo_reinforcement_titles()) || islist(profile.get_cryo_reinforcement_presets())

/datum/authority/branch/role/proc/should_auto_assign_ship_family_squad(job_or_title)
	var/list/halo_family_types = get_halo_job_family_types(job_or_title)
	return islist(halo_family_types) && length(halo_family_types)

/datum/authority/branch/role/proc/apply_active_ship_cryo_reinforcement(mob/living/carbon/human/human, canonical_role, fallback_title = canonical_role, fallback_preset = null, late_join = TRUE, platoon_type = get_active_ship_platoon_type())
	canonical_role = get_job_preference_bucket_key(canonical_role) || canonical_role
	if(!istype(human) || !canonical_role)
		return FALSE

	var/use_profile_cryo = has_active_ship_cryo_reinforcement_overrides(platoon_type)
	var/effective_title = fallback_title || canonical_role
	var/effective_preset = fallback_preset

	if(use_profile_cryo)
		effective_title = get_active_ship_cryo_reinforcement_title(canonical_role, platoon_type) || effective_title
		effective_preset = get_active_ship_cryo_reinforcement_preset(canonical_role, platoon_type)
		if(!effective_title || !effective_preset)
			return FALSE

	human.job = effective_title
	human.client?.prefs.copy_all_to(human, effective_title, TRUE, TRUE)
	if(effective_preset)
		arm_equipment(human, effective_preset, late_join, TRUE, late_join = late_join)

	if(use_profile_cryo)
		var/list/halo_family_types = get_halo_job_family_types(human.job)
		if(islist(halo_family_types) && length(halo_family_types) && human.assigned_squad && !(human.assigned_squad.type in halo_family_types))
			human.assigned_squad.remove_marine_from_squad(human, human.get_idcard())
		randomize_squad(human)
		human.sec_hud_set_ID()
		human.hud_set_squad()

	return TRUE
