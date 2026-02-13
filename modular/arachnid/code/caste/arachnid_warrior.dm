/datum/caste_datum/arachnid
	caste_type = ARACHNID_CASTE_WARRIOR
	caste_desc = "Четырехногий арахнид воин. Основная действующая многочисленная боевая единица улья."
	tier = 2
	melee_damage_lower = XENO_DAMAGE_TIER_2
	melee_damage_upper = XENO_DAMAGE_TIER_4
	melee_vehicle_damage = 0
	plasma_gain = XENO_PLASMA_GAIN_TIER_1
	plasma_max = XENO_NO_PLASMA
	xeno_explosion_resistance = XENO_EXPLOSIVE_ARMOR_TIER_1 // 10
	armor_deflection = XENO_ARMOR_TIER_2 // 25
	max_health = XENO_HEALTH_TIER_3	// 350
	evasion = XENO_EVASION_NONE
	speed = XENO_SPEED_TIER_5
	attack_delay = -4

	available_strains = list()
	evolves_to = list()
	deevolves_to = list()

	tackle_min = 2
	tackle_max = 4
	tackle_chance = 45
	tacklestrength_min = 4
	tacklestrength_max = 5

	heal_resting = 1.5
	innate_healing = TRUE // Хил вне травы

	minimum_evolve_time = 5 MINUTES

	minimap_icon = "runner"

/mob/living/carbon/xenomorph/arachnid
	caste_type = ARACHNID_CASTE_WARRIOR
	name = ARACHNID_CASTE_WARRIOR
	desc = "A small red alien that looks like it could run fairly quickly..."
	icon = 'modular/arachnid/icons/mobs/warrior/arachnid.dmi'
	icon_state = "Arachnid Walking"
	icon_size = 64
	plasma_types = list(PLASMA_CHITIN)
	tier = 2
	pixel_x = -16  //Needed for 2x2
	old_x = -16
	base_pixel_x = 0
	base_pixel_y = -20
	pull_speed = -0.5
	organ_value = 500 //worthless

	mob_size = MOB_SIZE_XENO

	base_actions = list(
		/datum/action/xeno_action/onclick/xeno_resting,
		/datum/action/xeno_action/watch_xeno,
		/datum/action/xeno_action/activable/tail_stab,
		/datum/action/xeno_action/onclick/tacmap,
	)

	icon_xeno = 'modular/arachnid/icons/mobs/warrior/arachnid.dmi'
	icon_xenonid = 'modular/arachnid/icons/mobs/warrior/Arachnid_Green2.dmi'

	weed_food_icon = 'icons/mob/xenos/weeds_64x64.dmi'
	weed_food_states = list("Warrior_old_1","Warrior_old_2","Warrior_old_3")
	weed_food_states_flipped = list("Warrior_old_1","Warrior_old_2","Warrior_old_3")


/mob/living/carbon/xenomorph/arachnid/init_movement_handler()
	return new /datum/xeno_ai_movement/arachnid(src) // с возможностью карабкаться

/mob/living/carbon/xenomorph/arachnid/ai_move_idle(delta_time)
	if(!ai_movement_handler)
		CRASH("No valid movement handler for [src]!")

	var/mob/living/pulling_target = pulling
	return (istype(pulling_target) && length(GLOB.ai_hives)) ? ai_movement_handler.ai_move_hive(delta_time) : ai_movement_handler.ai_move_idle(delta_time)


/mob/living/carbon/xenomorph/arachnid/ai_move_target(delta_time)
	if(!ai_movement_handler)
		CRASH("No valid movement handler for [src]!")

	var/mob/living/pulling_target = pulling
	return (istype(pulling_target) && length(GLOB.ai_hives)) ? ai_movement_handler.ai_move_hive(delta_time) : ai_movement_handler.ai_move_target(delta_time)


// ИИ-Поведение: Таскание

/// Similar to the woyer grab, but this one only inflicts pain without stuns and has a shorter range.
/mob/living/carbon/xenomorph/arachnid/start_pulling(atom/movable/AM, lunge)
	if (!check_state() || agility || !isliving(AM)) return FALSE

	if(!prob(ARACHNID_GRAB_CHANCE))
		return FALSE

	var/mob/living/L = AM
	var/should_neckgrab = !can_not_harm(L) && (lunge || prob(ARACHNID_NECKGRAB_CHANCE))

	if(!QDELETED(L) && !QDELETED(L.pulledby) && L != src ) //override pull of other mobs
		visible_message(SPAN_WARNING("[src] вырвал [L.pulledby] из хватки [L]!"), null, null, 5)
		L.pulledby.stop_pulling()

	. = ..(L, lunge, should_neckgrab)

	if(.)
		var/pain_to_cause = PAIN_XENO_DRAG /// Basic amount of pain caused with each grab.
		if(should_neckgrab && L.mob_size < MOB_SIZE_BIG)
			pain_to_cause += PAIN_XENO_GRAB /// Neck grabs cause even more pain.
			L.pulledby = src
			visible_message(SPAN_XENOWARNING("\The [src] крепко зажал [L]!"), \
			SPAN_XENOWARNING("Вы зажали [L]!"))

		L.pain.apply_pain(pain_to_cause)
		grab_level = GRAB_XENO /// Alien-specific grab level, with its own logic for escaping. AI only for the moment. See /mob/living/resist_grab()
		if(prob(10)) emote("hiss")
		///	The actual pain processing for humans is handled in: /mob/living/carbon/proc/handle_grabbed() Other mobs don't process the effects of the grab, like other xenomorphs.

/mob/living/carbon/xenomorph/arachnid/stop_pulling(bumped_movement = FALSE)
	//Let's see if we can ignore this. If our direction is the same as where the mob went, we likely bumped into them. So we lasso them back.
	if(bumped_movement && grab_level == GRAB_XENO && get_dir(src, pulling) == dir) /// Only on xeno grabs, so if they are on GRAB_PASSIVE, this doesn't trigger.
		pulling.loc = get_step_towards(src, pulling) // GET OVER HERE!
	else return ..()

/mob/living/carbon/xenomorph/arachnid/process_ai(delta_time)
	var/mob/living/pulling_target = pulling /// Let's see if the alien is pulling anyone.
	var/mob/living/potential_target = current_target

	if(istype(pulling_target)) /// Our soldier is pulling someone.
		if(get_active_hand()) swap_hand() /// Swap hand to either tackle or harm.
		ai_active_intent = INTENT_DISARM /// If we are pulling someone and are not too aggressive, switch to disarm.

	else if(istype(potential_target)) /// We have a target. We'll do more thorough checking in the main loop, for now we only need to know if they are being pulled by a hostile or friendly xeno.
		var/mob/living/carbon/xenomorph/other_xenomorph = potential_target.pulledby /// Are they being pulled by an alien?
		/// Need to make sure the alien dragging is friendly to us. If it is not friendly, or not a xeno, our alien will try to grab back.
		ai_active_intent = (istype(other_xenomorph) && IS_SAME_HIVENUMBER(src, other_xenomorph)) ? INTENT_DISARM : INTENT_GRAB

	/// I had it set up for slightly faster assignment, but this is easier to read.
	ai_active_intent = (prob(ARACHNID_HARM_PULL_CHANCE)) ? INTENT_HARM : ai_active_intent /// Override harm or continue with the previous intent.

	return ..()
