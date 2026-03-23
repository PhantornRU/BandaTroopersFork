
/datum/emergency_call/proc/get_cryo_reinforcement_role_header(mob/living/carbon/human/human)
	if(!istype(human))
		return "You are a reinforcement."

	var/role_title = human.job
	if(!role_title)
		role_title = "a reinforcement"

	return "You are [role_title]."

/datum/emergency_call/proc/finalize_profile_cryo_reinforcement(mob/living/carbon/human/human)
	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	if(!istype(human) || !role_authority?.has_active_ship_cryo_reinforcement_overrides())
		return

	if(!human.assigned_squad && GLOB.job_squad_roles.Find(GET_DEFAULT_ROLE(human.job)))
		role_authority.randomize_squad(human)

	human.sec_hud_set_ID()
	human.hud_set_squad()
	if(human.assigned_squad?.squad_leader == human && GET_DEFAULT_ROLE(human.job) == JOB_SQUAD_LEADER)
		human.assigned_squad.update_squad_leader()
		human.update_inv_head()
		human.update_inv_wear_suit()
	human.clear_halo_runtime_spawn_context()

/datum/emergency_call/proc/profile_cryo_role_is_supported(canonical_role, platoon_type = GLOB.RoleAuthority?.get_active_ship_platoon_type())
	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	if(!canonical_role || !role_authority)
		return FALSE

	if(!role_authority.has_active_ship_cryo_reinforcement_overrides(platoon_type))
		return TRUE

	return !!(role_authority.get_ship_cryo_reinforcement_title(canonical_role, platoon_type) && role_authority.get_ship_cryo_reinforcement_preset(canonical_role, platoon_type))

/datum/emergency_call/proc/apply_profile_cryo_reinforcement(mob/living/carbon/human/human, canonical_role, fallback_title = canonical_role, fallback_preset = null, late_join = TRUE, platoon_type = GLOB.RoleAuthority?.get_active_ship_platoon_type())
	var/datum/authority/branch/role/role_authority = GLOB.RoleAuthority
	if(!profile_cryo_role_is_supported(canonical_role, platoon_type))
		return FALSE

	human?.mark_personal_locker_spawn_context(late_join)
	human?.mark_halo_runtime_spawn_context("cryo")
	if(!role_authority?.apply_active_ship_cryo_reinforcement(human, canonical_role, fallback_title, fallback_preset, late_join, platoon_type))
		human?.clear_halo_runtime_spawn_context()
		return FALSE

	finalize_profile_cryo_reinforcement(human)
	return TRUE


/datum/emergency_call/cryo_squad
	name = "Marine Cryo Reinforcements (Squad)"
	mob_max = 10
	mob_min = 1
	probability = 0
	objectives = "Assist the USCM forces"
	max_engineers = 2
	max_medics = 2
	name_of_spawn = /obj/effect/landmark/ert_spawns/distress_cryo
	shuttle_id = ""
	var/leaders = 0
	spawn_max_amount = TRUE

/datum/emergency_call/cryo_squad/spawn_candidates(quiet_launch, announce_incoming, override_spawn_loc)
	var/datum/squad/marine/cryo/cryo_squad = GLOB.RoleAuthority.squads_by_type[/datum/squad/marine/cryo]
	leaders = cryo_squad.num_leaders
	. = ..()
	shipwide_ai_announcement("Successfully deployed [mob_max] Foxtrot marines, of which [length(members)] are ready for duty.")
	if(mob_max > length(members))
		announce_dchat("Some cryomarines were not taken, use the Join As Freed Mob verb to take one of them.")

/datum/emergency_call/cryo_squad/create_member(datum/mind/mind, turf/override_spawn_loc)
	set waitfor = 0
	if(SSmapping.configs[GROUND_MAP].map_name == MAP_WHISKEY_OUTPOST)
		name_of_spawn = /obj/effect/landmark/ert_spawns/distress_wo
	var/turf/spawn_loc = override_spawn_loc ? override_spawn_loc : get_spawn_point()

	if(!istype(spawn_loc)) return //Didn't find a useable spawn point.

	var/mob/living/carbon/human/human = new(spawn_loc)

	if(mind)
		mind.transfer_to(human, TRUE)
	else
		human.create_hud()

	if(!mind)
		FOR_DVIEW(var/obj/structure/machinery/cryopod/pod, 7, human, HIDE_INVISIBLE_OBSERVER)
			if(pod && !pod.occupant)
				pod.go_in_cryopod(human, silent = TRUE)
				break
		FOR_DVIEW_END

	sleep(5)
	var/datum/squad/marine/cryo/cryo_squad = GLOB.RoleAuthority.squads_by_type[/datum/squad/marine/cryo]
	if(leaders < cryo_squad.max_leaders && (!mind || (HAS_FLAG(human.client.prefs.toggles_ert, PLAY_LEADER) && check_timelock(human.client, JOB_SQUAD_LEADER, time_required_for_job))) && apply_profile_cryo_reinforcement(human, JOB_SQUAD_LEADER, JOB_SQUAD_LEADER, null, mind == null))
		leader = human
		leaders++
		to_chat(human, SPAN_ROLE_HEADER(get_cryo_reinforcement_role_header(human)))
		to_chat(human, SPAN_ROLE_BODY("You are here to assist in the defence of [SSmapping.configs[GROUND_MAP].map_name]. Listen to the chain of command."))
		to_chat(human, SPAN_BOLDWARNING("If you wish to cryo or ghost upon spawning in, you must ahelp and inform staff so you can be replaced."))
	else if(heavies < max_heavies && (!mind || (HAS_FLAG(human.client.prefs.toggles_ert, PLAY_HEAVY) && check_timelock(human.client, JOB_SQUAD_SPECIALIST, time_required_for_job))) && apply_profile_cryo_reinforcement(human, JOB_SQUAD_SPECIALIST, JOB_SQUAD_SPECIALIST, /datum/equipment_preset/uscm/specialist_equipped, mind == null))
		heavies++
		to_chat(human, SPAN_ROLE_HEADER(get_cryo_reinforcement_role_header(human)))
		to_chat(human, SPAN_ROLE_BODY("Your squad is here to assist in the defence of [SSmapping.configs[GROUND_MAP].map_name]. Listen to the chain of command."))
		to_chat(human, SPAN_BOLDWARNING("If you wish to cryo or ghost upon spawning in, you must ahelp and inform staff so you can be replaced."))
	else if(medics < max_medics && (!mind || (HAS_FLAG(human.client.prefs.toggles_ert, PLAY_MEDIC) && check_timelock(human.client, JOB_SQUAD_MEDIC, time_required_for_job))) && apply_profile_cryo_reinforcement(human, JOB_SQUAD_MEDIC, JOB_SQUAD_MEDIC, null, mind == null))
		medics++
		to_chat(human, SPAN_ROLE_HEADER(get_cryo_reinforcement_role_header(human)))
		to_chat(human, SPAN_ROLE_BODY("You are here to assist in the defence of [SSmapping.configs[GROUND_MAP].map_name]. Listen to the chain of command."))
		to_chat(human, SPAN_BOLDWARNING("If you wish to cryo or ghost upon spawning in, you must ahelp and inform staff so you can be replaced."))
	else if(engineers < max_engineers && (!mind || (HAS_FLAG(human.client.prefs.toggles_ert, PLAY_ENGINEER) && check_timelock(human.client, JOB_SQUAD_ENGI, time_required_for_job))) && apply_profile_cryo_reinforcement(human, JOB_SQUAD_ENGI, JOB_SQUAD_ENGI, /datum/equipment_preset/uscm/engineer_equipped, mind == null))
		engineers++
		to_chat(human, SPAN_ROLE_HEADER(get_cryo_reinforcement_role_header(human)))
		to_chat(human, SPAN_ROLE_BODY("You are here to assist in the defence of [SSmapping.configs[GROUND_MAP].map_name]. Listen to the chain of command."))
		to_chat(human, SPAN_BOLDWARNING("If you wish to cryo or ghost upon spawning in, you must ahelp and inform staff so you can be replaced."))
	else if(apply_profile_cryo_reinforcement(human, JOB_SQUAD_MARINE, JOB_SQUAD_MARINE, null, mind == null))
		to_chat(human, SPAN_ROLE_HEADER(get_cryo_reinforcement_role_header(human)))
		to_chat(human, SPAN_ROLE_BODY("You are here to assist in the defence of [SSmapping.configs[GROUND_MAP].map_name]. Listen to the chain of command."))
		to_chat(human, SPAN_BOLDWARNING("If you wish to cryo or ghost upon spawning in, you must ahelp and inform staff so you can be replaced."))

	sleep(10)
	if(!mind)
		human.free_for_ghosts()
	to_chat(human, SPAN_BOLD("Objectives: [objectives]"))

/datum/emergency_call/cryo_squad/platoon
	name = "Marine Cryo Reinforcements (Platoon)"
	mob_min = 8
	mob_max = 30
	probability = 0
	max_engineers = 8

/obj/effect/landmark/ert_spawns/distress_cryo
	name = "Distress_Cryo"

/datum/emergency_call/cryo_squad/tech
	name = "Marine Cryo Reinforcements (Tech)"
	mob_max = 5
	max_engineers = 1
	max_medics = 1
	max_heavies = 0
