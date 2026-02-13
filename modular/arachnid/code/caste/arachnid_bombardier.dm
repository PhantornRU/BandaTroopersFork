#define BOMBARDIER_EXPLOSION_POWER 45
#define BOMBARDIER_EXPLOSION_FALLOFF 15

/datum/caste_datum/arachnid/bombardier
	caste_type = ARACHNID_CASTE_BOMBARDIER
	caste_desc = "A volatile arachnid that detonates itself after pouncing into a target."
	tier = 1
	melee_damage_lower = XENO_DAMAGE_TIER_1
	melee_damage_upper = XENO_DAMAGE_TIER_2
	melee_vehicle_damage = 0
	plasma_gain = XENO_PLASMA_GAIN_TIER_1
	plasma_max = XENO_NO_PLASMA
	xeno_explosion_resistance = XENO_EXPLOSIVE_ARMOR_TIER_1
	armor_deflection = XENO_ARMOR_TIER_1
	max_health = XENO_HEALTH_TIER_2
	evasion = XENO_EVASION_NONE
	speed = XENO_SPEED_TIER_5
	attack_delay = -4

	available_strains = list()
	evolves_to = list()
	deevolves_to = list()

	behavior_delegate_type = /datum/behavior_delegate/arachnid_bombardier

	tackle_min = 2
	tackle_max = 4
	tackle_chance = 35
	tacklestrength_min = 4
	tacklestrength_max = 5

	heal_resting = 1.25
	innate_healing = TRUE

	minimum_evolve_time = 5 MINUTES

	minimap_icon = "runner"

/mob/living/carbon/xenomorph/arachnid/bombardier
	caste_type = ARACHNID_CASTE_BOMBARDIER
	name = ARACHNID_CASTE_BOMBARDIER
	desc = "A bloated arachnid that violently bursts after jumping on prey."
	icon = 'modular/arachnid/icons/mobs/bombardier/Arachnid_Bombardir.dmi'
	icon_state = "Bombard Walking"
	icon_size = 64
	layer = MOB_LAYER
	plasma_types = list(PLASMA_CHITIN)
	tier = 1
	pixel_x = -16
	old_x = -16
	base_pixel_x = 0
	base_pixel_y = -20
	pull_speed = -0.5
	organ_value = 500

	mob_size = MOB_SIZE_XENO

	base_actions = list(
		/datum/action/xeno_action/onclick/xeno_resting,
		/datum/action/xeno_action/watch_xeno,
		/datum/action/xeno_action/activable/pounce/arachnid_bombardier,
		/datum/action/xeno_action/onclick/tacmap,
	)

	icon_xeno = 'modular/arachnid/icons/mobs/bombardier/Arachnid_Bombardir.dmi'
	icon_xenonid = 'modular/arachnid/icons/mobs/bombardier/Arachnid_Bombardir.dmi'

	weed_food_icon = 'icons/mob/xenos/weeds_64x64.dmi'
	weed_food_states = list("Warrior_old_1","Warrior_old_2","Warrior_old_3")
	weed_food_states_flipped = list("Warrior_old_1","Warrior_old_2","Warrior_old_3")

/mob/living/carbon/xenomorph/arachnid/bombardier/proc/prime_self_destruct()
	var/datum/behavior_delegate/arachnid_bombardier/bombardier_delegate = behavior_delegate
	if(!istype(bombardier_delegate))
		return

	bombardier_delegate.prime_self_destruct()

/mob/living/carbon/xenomorph/arachnid/bombardier/pounced_mob(mob/living/L)
	. = ..()
	prime_self_destruct()

/mob/living/carbon/xenomorph/arachnid/bombardier/pounced_obj(obj/O)
	. = ..()
	prime_self_destruct()

/mob/living/carbon/xenomorph/arachnid/bombardier/pounced_turf(turf/T)
	. = ..()
	prime_self_destruct()

/datum/action/xeno_action/activable/pounce/arachnid_bombardier
	ability_primacy = XENO_PRIMARY_ACTION_1
	xeno_cooldown = 10
	plasma_cost = 0
	distance = 6
	knockdown = TRUE
	knockdown_duration = 1
	freeze_self = FALSE
	// freeze_time = 300
	can_be_shield_blocked = TRUE

/datum/behavior_delegate/arachnid_bombardier
	name = "Arachnid Bombardier Behavior Delegate"

	var/primed = FALSE
	var/detonation_timer_id = TIMER_ID_NULL
	var/detonation_delay = 1.5 SECONDS
	var/explosion_power = BOMBARDIER_EXPLOSION_POWER
	var/explosion_falloff = BOMBARDIER_EXPLOSION_FALLOFF

/datum/behavior_delegate/arachnid_bombardier/proc/prime_self_destruct()
	if(!bound_xeno || primed || bound_xeno.stat == DEAD)
		return

	primed = TRUE
	flick("Normal Arachnid Bombardier Attacking", bound_xeno)
	bound_xeno.Stun(detonation_delay)
	bound_xeno.KnockDown(detonation_delay)
	bound_xeno.update_icons()

	detonation_timer_id = addtimer(CALLBACK(src, PROC_REF(detonate_if_alive)), detonation_delay, TIMER_STOPPABLE)

/datum/behavior_delegate/arachnid_bombardier/proc/detonate_if_alive()
	detonation_timer_id = TIMER_ID_NULL

	if(!bound_xeno || QDELETED(bound_xeno) || bound_xeno.stat == DEAD)
		primed = FALSE
		return

	var/turf/explosion_turf = get_turf(bound_xeno)
	if(!explosion_turf)
		primed = FALSE
		return

	var/datum/cause_data/cause_data = create_cause_data("arachnid bombardier kamikaze", bound_xeno)
	cell_explosion(explosion_turf, explosion_power, explosion_falloff, EXPLOSION_FALLOFF_SHAPE_LINEAR, null, cause_data)

	if(bound_xeno && !QDELETED(bound_xeno) && bound_xeno.stat != DEAD)
		bound_xeno.gib(cause_data)

	primed = FALSE

/datum/behavior_delegate/arachnid_bombardier/handle_death(mob/M)
	if(detonation_timer_id != TIMER_ID_NULL)
		deltimer(detonation_timer_id)
		detonation_timer_id = TIMER_ID_NULL

	primed = FALSE

/datum/behavior_delegate/arachnid_bombardier/remove_from_xeno()
	if(detonation_timer_id != TIMER_ID_NULL)
		deltimer(detonation_timer_id)
		detonation_timer_id = TIMER_ID_NULL

	primed = FALSE

	..()

// /datum/behavior_delegate/arachnid_bombardier/on_update_icons()
// 	if(!bound_xeno)
// 		return FALSE

// 	if(bound_xeno.stat == DEAD)
// 		bound_xeno.icon_state = "Bombard Dead"
// 		return TRUE

// 	if(primed)
// 		bound_xeno.icon_state = "Bombard Sleeping"
// 		return TRUE

// 	if(bound_xeno.body_position == LYING_DOWN)
// 		if(!HAS_TRAIT(bound_xeno, TRAIT_INCAPACITATED) && !HAS_TRAIT(bound_xeno, TRAIT_FLOORED))
// 			bound_xeno.icon_state = "Bombard Sleeping"
// 		else
// 			bound_xeno.icon_state = "Bombard Knocked Down"
// 		return TRUE

// 	var/movement_state = bound_xeno.m_intent != MOVE_INTENT_RUN ? "Walking" : "Running"
// 	bound_xeno.icon_state = "Bombard [movement_state]"
// 	return TRUE

#undef BOMBARDIER_EXPLOSION_POWER
#undef BOMBARDIER_EXPLOSION_FALLOFF
