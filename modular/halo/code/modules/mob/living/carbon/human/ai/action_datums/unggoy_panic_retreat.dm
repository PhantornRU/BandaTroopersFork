/datum/human_ai_brain
	var/halo_unggoy_role
	var/halo_unggoy_panic_health_pct = 0
	var/halo_unggoy_panics_without_leader = FALSE
	var/halo_unggoy_ignore_panic = FALSE

/datum/human_ai_brain/proc/halo_unggoy_get_squad()
	if(!squad_id)
		return null
	return SShuman_ai.squad_id_dict["[squad_id]"]

/datum/human_ai_brain/proc/halo_unggoy_get_squad_leader()
	var/datum/human_ai_squad/squad = halo_unggoy_get_squad()
	return squad?.squad_leader

/datum/human_ai_brain/proc/halo_unggoy_has_active_squad_leader()
	var/datum/human_ai_brain/leader = halo_unggoy_get_squad_leader()
	if(!leader)
		return FALSE
	if(leader == src)
		return TRUE
	if(!leader.tied_human)
		return FALSE
	if(leader.tied_human.stat >= DEAD)
		return FALSE
	if(leader.tied_human.is_mob_incapacitated())
		return FALSE
	return TRUE

/datum/human_ai_brain/proc/halo_unggoy_get_squad_anchor()
	var/datum/human_ai_brain/leader = halo_unggoy_get_squad_leader()
	var/turf/anchor = get_turf(leader?.tied_human)
	if(anchor)
		return anchor

	var/datum/human_ai_squad/squad = halo_unggoy_get_squad()
	if(!squad)
		return null

	var/anchor_x = 0
	var/anchor_y = 0
	var/anchor_z = 0
	var/valid_members = 0
	for(var/datum/human_ai_brain/member as anything in squad.ai_in_squad)
		if(!member?.tied_human)
			continue

		var/turf/member_turf = get_turf(member.tied_human)
		if(!member_turf)
			continue

		if(member.tied_human.stat >= DEAD || member.tied_human.is_mob_incapacitated())
			continue

		anchor_x += member_turf.x
		anchor_y += member_turf.y
		anchor_z = member_turf.z
		valid_members++

	if(!valid_members)
		return null

	return locate(round(anchor_x / valid_members), round(anchor_y / valid_members), anchor_z)

/datum/human_ai_brain/proc/halo_unggoy_get_health_pct()
	if(!tied_human?.maxHealth)
		return 1
	return max(tied_human.health, 0) / tied_human.maxHealth

/datum/human_ai_brain/proc/halo_unggoy_get_threat_atom()
	return current_target || target_turf

/datum/human_ai_brain/proc/halo_unggoy_should_panic()
	if(halo_unggoy_ignore_panic || !tied_human)
		return FALSE

	if((halo_unggoy_panic_health_pct > 0) && (halo_unggoy_get_health_pct() <= halo_unggoy_panic_health_pct))
		return TRUE

	if(!halo_unggoy_panics_without_leader || !squad_id || is_squad_leader)
		return FALSE

	return !halo_unggoy_has_active_squad_leader()

/datum/ai_action/unggoy_panic_retreat
	name = "Unggoy Panic Retreat"
	action_flags = ACTION_USING_LEGS

/datum/ai_action/unggoy_panic_retreat/get_weight(datum/human_ai_brain/brain)
	if(!brain.in_combat || brain.hold_position)
		return 0

	if(!brain.halo_unggoy_should_panic())
		return 0

	if(!brain.halo_unggoy_get_threat_atom())
		return 0

	return 20

/datum/ai_action/unggoy_panic_retreat/trigger_action()
	. = ..()

	if(!brain.in_combat || !brain.halo_unggoy_should_panic())
		return ONGOING_ACTION_COMPLETED

	var/mob/living/carbon/human/tied_human = brain.tied_human
	var/atom/threat = brain.halo_unggoy_get_threat_atom()
	if(!tied_human || !threat)
		return ONGOING_ACTION_COMPLETED

	if(try_cover_retreat(threat))
		return ONGOING_ACTION_UNFINISHED_BLOCK

	if(step_away_from_threat(threat))
		return ONGOING_ACTION_UNFINISHED_BLOCK

	return ONGOING_ACTION_COMPLETED

/datum/ai_action/unggoy_panic_retreat/proc/try_cover_retreat(atom/threat)
	if(!brain.current_cover)
		brain.try_cover(Get_Angle(threat, brain.tied_human), threat)

	var/turf/cover_turf = get_turf(brain.current_cover)
	if(!cover_turf)
		return FALSE

	if(get_dist(cover_turf, brain.tied_human) > 0)
		if(!brain.move_to_next_turf(cover_turf))
			brain.end_cover()
			return FALSE

		return TRUE

	brain.in_cover = TRUE
	brain.tied_human.face_atom(threat)
	return TRUE

/datum/ai_action/unggoy_panic_retreat/proc/step_away_from_threat(atom/threat)
	var/mob/living/carbon/human/tied_human = brain.tied_human
	var/turf/threat_turf = get_turf(threat)
	if(!tied_human || !threat_turf)
		return FALSE

	var/turf/anchor = brain.halo_unggoy_get_squad_anchor()
	var/turf/best_destination
	var/best_score = -INFINITY

	for(var/direction in GLOB.cardinals)
		var/turf/destination = get_step(tied_human, direction)
		if(!destination || destination.density)
			continue

		var/score = get_dist(destination, threat_turf) * 3
		if(anchor)
			score -= get_dist(destination, anchor)

		if(score > best_score)
			best_score = score
			best_destination = destination

	if(!best_destination && anchor && (get_dist(anchor, tied_human) > 0))
		best_destination = anchor

	if(!best_destination)
		return FALSE

	if(!brain.move_to_next_turf(best_destination))
		return FALSE

	tied_human.face_atom(threat)
	return TRUE
