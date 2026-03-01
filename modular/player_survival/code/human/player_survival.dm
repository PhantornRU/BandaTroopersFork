/mob/living/carbon/human
	var/player_survival_damage_block_until = 0

/mob/living/carbon/human/proc/player_survival_is_damage_blocked()
	if(!client)
		return FALSE
	if(stat == DEAD || health <= HEALTH_THRESHOLD_DEAD)
		return FALSE
	return world.time <= player_survival_damage_block_until

/mob/living/carbon/human/proc/player_survival_activate_crit_grace()
	if(!client)
		return FALSE

	var/block_duration = max(0, CONFIG_GET(number/player_survival_crit_immunity_seconds)) SECONDS
	if(!block_duration)
		return FALSE

	player_survival_damage_block_until = max(player_survival_damage_block_until, world.time + block_duration)
	return TRUE

/mob/living/carbon/human/proc/player_survival_detach_random_extremity(datum/cause_data/cause)
	var/static/list/extremity_zones = list(
		"l_hand",
		"r_hand",
		"l_foot",
		"r_foot"
	)

	var/list/obj/limb/limb_candidates = list()
	for(var/zone in extremity_zones)
		var/obj/limb/limb = get_limb(zone)
		if(!limb)
			continue
		if(limb.status & LIMB_DESTROYED)
			continue
		limb_candidates += limb

	if(!length(limb_candidates))
		return FALSE

	var/obj/limb/selected_limb = pick(limb_candidates)
	selected_limb.droplimb(FALSE, FALSE, cause)
	return TRUE

/mob/living/carbon/human/proc/player_survival_apply_non_gib_fallback(datum/cause_data/cause, explosion_damage = null)
	if(!client)
		return FALSE
	if(stat == DEAD || health <= HEALTH_THRESHOLD_DEAD)
		return FALSE

	if(!istype(cause))
		cause = create_cause_data("player survival anti-gib", src)
	last_damage_data = cause

	var/target_health = HEALTH_THRESHOLD_CRIT - 5
	if(health > target_health)
		var/required_damage = health - target_health
		take_overall_damage(required_damage, 0, "Explosive Blast", 100)

	if(health > HEALTH_THRESHOLD_CRIT)
		adjustOxyLoss((health - HEALTH_THRESHOLD_CRIT) + 1)

	KnockDown(1 SECONDS)
	Stun(1 SECONDS)
	KnockOut(0.5 SECONDS)

	var/sufficient_for_limb_loss = isnull(explosion_damage) || explosion_damage >= EXPLOSION_THRESHOLD_GIB
	if(sufficient_for_limb_loss && prob(30))
		player_survival_detach_random_extremity(cause)

	if(health <= HEALTH_THRESHOLD_CRIT)
		player_survival_activate_crit_grace()

	return TRUE
