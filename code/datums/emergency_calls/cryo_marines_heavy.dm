
/*
 *   Heavy DEFCON ERT (with full equipment)
 */

/datum/emergency_call/cryo_squad_equipped
	name = "Marine Cryo Reinforcements (Full Equipment) (Squad)"
	mob_max = 15
	mob_min = 1
	probability = 0
	objectives = "Assist the USCM forces"
	max_heavies = 4
	max_medics = 2
	name_of_spawn = /obj/effect/landmark/ert_spawns/distress_cryo
	shuttle_id = ""

	var/leaders = 0

/datum/emergency_call/cryo_squad_equipped/spawn_candidates(quiet_launch, announce_incoming, override_spawn_loc)
	var/datum/squad/marine/cryo/cryo_squad = GLOB.RoleAuthority.squads_by_type[/datum/squad/marine/cryo]
	leaders = cryo_squad.num_leaders
	. = ..()
	if(length(members))
		shipwide_ai_announcement("Successfully deployed [length(members)] Foxtrot marines.")

/datum/emergency_call/cryo_squad_equipped/create_member(datum/mind/M, turf/override_spawn_loc)
	set waitfor = 0
	if(SSmapping.configs[GROUND_MAP].map_name == MAP_WHISKEY_OUTPOST)
		name_of_spawn = /obj/effect/landmark/ert_spawns/distress_wo
	var/turf/spawn_loc = override_spawn_loc ? override_spawn_loc : get_spawn_point()

	if(!istype(spawn_loc)) return //Didn't find a useable spawn point.

	var/mob/living/carbon/human/H = new(spawn_loc)
	M.transfer_to(H, TRUE)

	sleep(5)
	var/datum/squad/marine/cryo/cryo_squad = GLOB.RoleAuthority.squads_by_type[/datum/squad/marine/cryo]
	if(leaders < cryo_squad.max_leaders && HAS_FLAG(H.client.prefs.toggles_ert, PLAY_LEADER) && check_timelock(H.client, JOB_SQUAD_LEADER, time_required_for_job) && apply_profile_cryo_reinforcement(H, JOB_SQUAD_LEADER, JOB_SQUAD_LEADER, null, TRUE))
		leader = H
		leaders++
		to_chat(H, SPAN_ROLE_HEADER(get_cryo_reinforcement_role_header(H)))
		to_chat(H, SPAN_ROLE_BODY("Your squad is here to assist in the defence of [SSmapping.configs[GROUND_MAP].map_name]."))
	else if(heavies < max_heavies && HAS_FLAG(H.client.prefs.toggles_ert, PLAY_HEAVY) && check_timelock(H.client, JOB_SQUAD_SPECIALIST, time_required_for_job) && apply_profile_cryo_reinforcement(H, JOB_SQUAD_SPECIALIST, JOB_SQUAD_SPECIALIST, /datum/equipment_preset/uscm/specialist_equipped, TRUE))
		heavies++
		to_chat(H, SPAN_ROLE_HEADER(get_cryo_reinforcement_role_header(H)))
		to_chat(H, SPAN_ROLE_BODY("Your squad is here to assist in the defence of [SSmapping.configs[GROUND_MAP].map_name]."))
	else if(smartgunners < max_smartgunners && HAS_FLAG(H.client.prefs.toggles_ert, PLAY_SMARTGUNNER) && check_timelock(H.client, JOB_SQUAD_SMARTGUN, time_required_for_job) && apply_profile_cryo_reinforcement(H, JOB_SQUAD_SMARTGUN, JOB_SQUAD_SMARTGUN, /datum/equipment_preset/uscm/smartgunner_equipped, TRUE))
		smartgunners++
		to_chat(H, SPAN_ROLE_HEADER(get_cryo_reinforcement_role_header(H)))
		to_chat(H, SPAN_ROLE_BODY("Your squad is here to assist in the defence of [SSmapping.configs[GROUND_MAP].map_name]."))
	else if(engineers < max_engineers && HAS_FLAG(H.client.prefs.toggles_ert, PLAY_ENGINEER) && check_timelock(H.client, JOB_SQUAD_ENGI, time_required_for_job) && apply_profile_cryo_reinforcement(H, JOB_SQUAD_ENGI, JOB_SQUAD_ENGI, /datum/equipment_preset/uscm/engineer_equipped, TRUE))
		engineers++
		to_chat(H, SPAN_ROLE_HEADER(get_cryo_reinforcement_role_header(H)))
		to_chat(H, SPAN_ROLE_BODY("Your squad is here to assist in the defence of [SSmapping.configs[GROUND_MAP].map_name]."))
	else if(medics < max_medics && HAS_FLAG(H.client.prefs.toggles_ert, PLAY_MEDIC) && check_timelock(H.client, JOB_SQUAD_MEDIC, time_required_for_job) && apply_profile_cryo_reinforcement(H, JOB_SQUAD_MEDIC, JOB_SQUAD_MEDIC, null, TRUE))
		medics++
		to_chat(H, SPAN_ROLE_HEADER(get_cryo_reinforcement_role_header(H)))
		to_chat(H, SPAN_ROLE_BODY("Your squad is here to assist in the defence of [SSmapping.configs[GROUND_MAP].map_name]."))
	else if(apply_profile_cryo_reinforcement(H, JOB_SQUAD_MARINE, JOB_SQUAD_MARINE, null, TRUE))
		to_chat(H, SPAN_ROLE_HEADER(get_cryo_reinforcement_role_header(H)))
		to_chat(H, SPAN_ROLE_BODY("Your squad is here to assist in the defence of [SSmapping.configs[GROUND_MAP].map_name]."))

	sleep(10)
	to_chat(H, SPAN_BOLD("Objectives: [objectives]"))


/datum/emergency_call/cryo_squad_equipped/platoon
	name = "Marine Cryo Reinforcements (Full Equipment) (Platoon)"
	mob_min = 8
	mob_max = 30
	probability = 0
	max_heavies = 8
