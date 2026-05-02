/obj/structure/machinery/door_control/squad_armory
	req_access = list()
	req_one_access = list()
	req_access_txt = null
	req_one_access_txt = null
	var/target_squad_static = null
	// Map ship surface button ids to the currently active platoon's squads.
	var/static/list/squad_static_by_button_id = list(
		"squadarmory_alpha" = SQUAD_MARINE_1,
		"squadarmory_bravo" = SQUAD_MARINE_2,
		"squadarmory_charlie" = SQUAD_MARINE_3,
		"squadarmory_delta" = SQUAD_MARINE_4,
	)

/obj/structure/machinery/door_control/squad_armory/alpha
	name = "ALPHA gear lockers door-control"
	id = "squadarmory_alpha"
	color = "#db1d1d"
	pixel_x = 1
	pixel_y = 13
	target_squad_static = SQUAD_MARINE_1

/obj/structure/machinery/door_control/squad_armory/bravo
	name = "BRAVO gear lockers door-control"
	id = "squadarmory_bravo"
	color = "#ffc32d"
	pixel_x = 9
	pixel_y = 13
	target_squad_static = SQUAD_MARINE_2

/obj/structure/machinery/door_control/squad_armory/charlie
	name = "CHARLIE gear lockers door-control"
	id = "squadarmory_charlie"
	color = "#c864c8"
	pixel_x = 1
	pixel_y = 7
	target_squad_static = SQUAD_MARINE_3

/obj/structure/machinery/door_control/squad_armory/delta
	name = "DELTA gear lockers door-control"
	id = "squadarmory_delta"
	color = "#828cff"
	pixel_x = 9
	pixel_y = 7
	target_squad_static = SQUAD_MARINE_4

/obj/structure/machinery/door_control/squad_armory/use_button(mob/living/user, force = FALSE)
	if(force)
		return ..()

	var/datum/squad/target_squad = get_target_squad()
	if(!target_squad)
		to_chat(user, SPAN_WARNING("[src] has no linked squad armory routing."))
		flick(initial(icon_state) + "-denied", src)
		return

	if((wires & 1) && !allowed(user))
		deny_squad_armory_access(user, target_squad)
		return

	return ..()

/obj/structure/machinery/door_control/squad_armory/allowed(mob/M)
	var/datum/squad/target_squad = get_target_squad()
	if(!target_squad)
		return FALSE

	return can_user_access_armory(M, target_squad)

/obj/structure/machinery/door_control/squad_armory/proc/get_target_squad()
	var/static_squad_name = target_squad_static || squad_static_by_button_id[id]
	if(!static_squad_name)
		return null

	var/datum/squad_name_manager/squad_name_manager = GLOB.squad_name_manager
	if(squad_name_manager)
		var/datum/squad/managed_squad = squad_name_manager.get_squad_by_static(static_squad_name)
		if(managed_squad)
			return managed_squad

	return get_squad_by_name(static_squad_name)

/obj/structure/machinery/door_control/squad_armory/proc/can_user_access_armory(mob/living/user, datum/squad/target_squad)
	if(!ishuman(user) || !target_squad)
		return FALSE

	if(target_squad.usable)
		return is_platoon_commander(user) || is_target_squad_leader(user, target_squad)

	return has_captain_authorization(user)

/obj/structure/machinery/door_control/squad_armory/proc/is_platoon_commander(mob/living/user)
	if(!ishuman(user))
		return FALSE

	var/mob/living/carbon/human/human_user = user
	return GET_DEFAULT_ROLE(human_user.job) == JOB_SO

/obj/structure/machinery/door_control/squad_armory/proc/is_target_squad_leader(mob/living/user, datum/squad/target_squad)
	if(!ishuman(user) || !target_squad)
		return FALSE

	var/mob/living/carbon/human/human_user = user
	if(human_user.assigned_squad != target_squad)
		return FALSE

	return GET_DEFAULT_ROLE(human_user.job) == JOB_SQUAD_LEADER || target_squad.squad_leader == human_user

/obj/structure/machinery/door_control/squad_armory/proc/has_captain_authorization(mob/living/user)
	if(!ishuman(user))
		return FALSE

	var/mob/living/carbon/human/human_user = user
	return is_captain_or_higher_role(human_user) || user_has_any_access(human_user, list(ACCESS_MARINE_CO))

/obj/structure/machinery/door_control/squad_armory/proc/is_captain_or_higher_role(mob/living/carbon/human/human_user)
	if(!ishuman(human_user))
		return FALSE

	switch(GET_DEFAULT_ROLE(human_user.job))
		if(JOB_CO, JOB_COLONEL, JOB_GENERAL, JOB_ACMC, JOB_CMC)
			return TRUE

	return FALSE

/obj/structure/machinery/door_control/squad_armory/proc/user_has_any_access(mob/living/user, list/required_access)
	if(!required_access || !length(required_access))
		return FALSE

	var/obj/item/held_item = user?.get_active_hand()
	if(held_item && access_list_has_any_required(held_item.GetAccess(), required_access))
		return TRUE

	if(!ishuman(user))
		return FALSE

	var/mob/living/carbon/human/human_user = user
	var/obj/item/card/id/id_card = human_user.get_idcard()
	return id_card && access_list_has_any_required(id_card.GetAccess(), required_access)

/obj/structure/machinery/door_control/squad_armory/proc/access_list_has_any_required(list/current_access, list/required_access)
	if(!islist(current_access) || !islist(required_access))
		return FALSE

	for(var/access_flag in required_access)
		if(access_flag in current_access)
			return TRUE

	return FALSE

/obj/structure/machinery/door_control/squad_armory/proc/deny_squad_armory_access(mob/living/user, datum/squad/target_squad)
	if(target_squad?.usable)
		to_chat(user, SPAN_DANGER("Only a platoon commander or [target_squad.name]'s squad leader can open this armory."))
	else
		to_chat(user, SPAN_DANGER("[target_squad?.name || "This squad"] is unavailable this round. Captain access or higher is required to open this armory."))

	flick(initial(icon_state) + "-denied", src)
