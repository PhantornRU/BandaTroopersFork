/mob/living/carbon/human/proc/detach_random_sadar_hit_limb(datum/cause_data/cause_data)
	var/static/list/sadar_limb_zones = list(
		"l_hand",
		"r_hand",
		"l_foot",
		"r_foot",
		"l_leg",
		"r_leg",
		"l_arm",
		"r_arm"
	)
	var/list/obj/limb/limb_candidates = list()
	for(var/limb_zone in sadar_limb_zones)
		var/obj/limb/limb = get_limb(limb_zone)
		if(!limb)
			continue
		if(limb.status & LIMB_DESTROYED)
			continue
		limb_candidates += limb

	if(!length(limb_candidates))
		return FALSE

	var/obj/limb/selected_limb = pick(limb_candidates)
	selected_limb.droplimb(FALSE, FALSE, cause_data)
	return TRUE

/datum/ammo/rocket/ap/on_hit_mob(mob/mob, obj/projectile/projectile)
	if(ishuman(mob) && mob.client && istype(projectile?.shot_from, /obj/item/weapon/gun/launcher/rocket/anti_tank/disposable))
		var/mob/living/carbon/human/hit_human = mob
		var/turf/turf = get_turf(hit_human)
		var/direct_hit_damage = max(damage * 2, HEALTH_THRESHOLD_DEAD / 2)

		// Keep SADAR direct hit severe, but prevent player gibbing and avoid ex_act() in must-not-sleep context.
		hit_human.apply_armoured_damage(direct_hit_damage, ARMOR_BOMB, BRUTE, null, penetration)
		hit_human.apply_armoured_damage(direct_hit_damage, ARMOR_BOMB, BURN, null, penetration)
		hit_human.apply_effect(3, WEAKEN)
		hit_human.apply_effect(3, PARALYZE)
		hit_human.detach_random_sadar_hit_limb(projectile.weapon_cause_data)

		cell_explosion(turf, 150, 50, EXPLOSION_FALLOFF_SHAPE_LINEAR, null, projectile.weapon_cause_data)
		smoke.set_up(1, turf)
		smoke.start()
		return

	return ..()
