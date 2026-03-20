#define HUMAN_AI_GRENADE_MIN_HOLD_DELAY (1 SECONDS)

/datum/ai_action/throw_grenade
	name = "Throw Grenade"
	action_flags = ACTION_USING_HANDS | ACTION_USING_LEGS // SS220 EDIT: grenade priming/throwing should own both hand and movement slots until it resolves
	var/obj/item/explosive/grenade/throwing
	var/mid_throw = FALSE
	var/throw_finished = FALSE
	var/min_safe_throw_distance = 2

/datum/ai_action/throw_grenade/get_weight(datum/human_ai_brain/brain)
	if(!brain.grenading_allowed)
		return 0

	if(!brain.in_combat)
		return 0

	var/turf/target_turf = brain.target_turf
	if(!target_turf)
		return 0

	if(!length(brain.equipment_map[HUMAN_AI_GRENADES]))
		return 0

	if(!brain.primary_weapon)
		return 10

	if(locate(/turf/closed) in get_line(brain.tied_human, target_turf))
		return 10

	return 0

/datum/ai_action/throw_grenade/get_conflicts(datum/human_ai_brain/brain)
	. = ..()
	. += /datum/ai_action/chase_target
	. += /datum/ai_action/sniper_nest

/datum/ai_action/throw_grenade/Added()
	throwing = locate() in brain.equipment_map[HUMAN_AI_GRENADES]
	cancel_conflicting_actions()

/datum/ai_action/throw_grenade/Destroy(force, ...)
	throwing = null
	mid_throw = FALSE
	throw_finished = FALSE
	return ..()

/datum/ai_action/throw_grenade/proc/cancel_conflicting_actions()
	if(!brain)
		return

	var/list/conflicts = get_conflicts(brain)
	for(var/datum/ai_action/conflicting_action as anything in brain.ongoing_actions)
		if((conflicting_action != src) && (conflicting_action.type in conflicts))
			qdel(conflicting_action)

/datum/ai_action/throw_grenade/proc/try_hold_grenade(mob/living/carbon/human/tied_human, obj/item/explosive/grenade/grenade)
	if(!grenade || QDELETED(grenade) || !brain || !brain.has_valid_tied_human())
		return FALSE

	if(tied_human.get_active_hand() == grenade)
		return TRUE

	if(tied_human.get_inactive_hand() == grenade)
		tied_human.swap_hand()
		if(tied_human.get_active_hand() == grenade)
			return TRUE

	var/obj/item/active_hand = tied_human.get_active_hand()
	if(active_hand && (active_hand != grenade))
		if(active_hand.flags_item & NODROP)
			return FALSE
		brain.clear_main_hand()
		if(tied_human.get_active_hand())
			return FALSE

	if(grenade.loc != tied_human)
		if(!brain.equip_item_from_equipment_map(HUMAN_AI_GRENADES, grenade))
			return FALSE
	else if(!tied_human.put_in_active_hand(grenade))
		return FALSE

	brain.ensure_primary_hand(grenade)
	return tied_human.get_active_hand() == grenade

/datum/ai_action/throw_grenade/proc/can_throw_to_target(mob/living/carbon/human/tied_human, obj/item/explosive/grenade/grenade, turf/target_turf)
	if(!tied_human || !grenade || QDELETED(grenade) || !target_turf)
		return FALSE

	var/distance = get_dist(tied_human, target_turf)
	if(distance <= min_safe_throw_distance)
		return FALSE

	if(distance > grenade.throw_range)
		return FALSE

	var/list/turf_line = get_line(tied_human, target_turf)
	for(var/turf/turf as anything in turf_line)
		if(turf.density)
			return FALSE

		for(var/obj/object in turf)
			if(object.density)
				return FALSE

	return TRUE

/datum/ai_action/throw_grenade/proc/finish_async_throw()
	mid_throw = FALSE
	throw_finished = TRUE

/datum/ai_action/throw_grenade/proc/async_prime_and_throw(mob/living/carbon/human/tied_human, obj/item/explosive/grenade/grenade, turf/target_turf)
	if(QDELETED(src))
		return

	if(!brain || !brain.has_valid_tied_human() || (brain.tied_human != tied_human))
		finish_async_throw()
		return

	var/pre_throw_hold_delay = max(HUMAN_AI_GRENADE_MIN_HOLD_DELAY, brain.short_action_delay * brain.action_delay_mult)
	sleep(pre_throw_hold_delay) // SS220 EDIT: NPCs should visibly commit to the throw and hold the grenade for at least one second before priming/throwing

	if(!brain || !brain.has_valid_tied_human() || (brain.tied_human != tied_human))
		finish_async_throw()
		return

	if(!try_hold_grenade(tied_human, grenade) || !can_throw_to_target(tied_human, grenade, target_turf))
		finish_async_throw()
		return

	grenade.attack_self(tied_human)
	if(QDELETED(grenade) || !grenade.active)
		finish_async_throw()
		return

	brain.ensure_primary_hand(grenade)
	sleep(grenade.det_time * 0.4)
	if(QDELETED(grenade) || (grenade.loc != tied_human))
		finish_async_throw()
		return

	brain.say_grenade_thrown_line()
	sleep(grenade.det_time * 0.4)
	if(QDELETED(grenade) || (grenade.loc != tied_human))
		finish_async_throw()
		return

	if(!try_hold_grenade(tied_human, grenade) || !can_throw_to_target(tied_human, grenade, target_turf))
		finish_async_throw()
		return

	if(!tied_human.throw_mode)
		tied_human.toggle_throw_mode(THROW_MODE_NORMAL)

	tied_human.face_atom(target_turf)
	tied_human.throw_item(target_turf) // SS220 EDIT: actual throw now stays inside the action-owned async tail instead of item ai_use()
	finish_async_throw()

/datum/ai_action/throw_grenade/trigger_action()
	. = ..()
	if(. == ONGOING_ACTION_COMPLETED)
		return .

	if(throw_finished)
		return ONGOING_ACTION_COMPLETED

	if(mid_throw)
		return ONGOING_ACTION_UNFINISHED_BLOCK

	var/turf/target_turf = brain.target_turf
	if(QDELETED(throwing) || !target_turf)
		return ONGOING_ACTION_COMPLETED

	var/mob/living/carbon/human/tied_human = brain.tied_human
	if(brain.primary_weapon)
		brain.primary_weapon.unwield(tied_human)
		if(tied_human.get_active_hand() == brain.primary_weapon)
			tied_human.swap_hand()

	cancel_conflicting_actions() // SS220 EDIT: cancel any already-running move/fire/reload actions before the grenade is primed
	if(!try_hold_grenade(tied_human, throwing))
		return ONGOING_ACTION_COMPLETED

	if(!can_throw_to_target(tied_human, throwing, target_turf))
		return ONGOING_ACTION_COMPLETED

	mid_throw = TRUE
	INVOKE_ASYNC(src, PROC_REF(async_prime_and_throw), tied_human, throwing, target_turf)
	return ONGOING_ACTION_UNFINISHED_BLOCK

#undef HUMAN_AI_GRENADE_MIN_HOLD_DELAY
