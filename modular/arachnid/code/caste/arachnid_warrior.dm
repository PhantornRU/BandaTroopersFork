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
	max_health = XENO_HEALTH_TIER_1	// 250
	evasion = XENO_EVASION_NONE
	speed = XENO_SPEED_TIER_5
	attack_delay = -4

	available_strains = list()
	evolves_to = list()
	deevolves_to = list()

	tackle_min = 2
	tackle_max = 5
	tackle_chance = 35
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
	icon = 'modular/arachnid/icons/mobs/arachnid.dmi'
	icon_state = "Arachnide Walking"
	icon_size = 64
	layer = MOB_LAYER
	plasma_types = list(PLASMA_CHITIN)
	tier = 1
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

	icon_xeno = 'modular/arachnid/icons/mobs/arachnid.dmi'
	icon_xenonid = 'modular/arachnid/icons/mobs/arachnid_green2.dmi'

	weed_food_icon = 'icons/mob/xenos/weeds_64x64.dmi'
	weed_food_states = list("Warrior_old_1","Warrior_old_2","Warrior_old_3")
	weed_food_states_flipped = list("Warrior_old_1","Warrior_old_2","Warrior_old_3")

	var/pull_direction
	var/pull_multiplier_value = 0.65

/mob/living/carbon/xenomorph/arachnid/initialize_pass_flags(datum/pass_flags_container/pass_flags_container)
	..()
	if (pass_flags_container)
		pass_flags_container.flags_pass |= PASS_FLAGS_CRAWLER

/mob/living/carbon/xenomorph/arachnid/recalculate_actions()
	. = ..()
	pull_multiplier *= pull_multiplier_value
	if(is_zoomed)
		zoom_out()

/mob/living/carbon/xenomorph/arachnid/start_pulling(atom/movable/AM, lunge, no_msg)
	. = ..()
	add_temp_negative_pass_flags(PASS_FLAGS_CRAWLER)

/mob/living/carbon/xenomorph/arachnid/stop_pulling(bumped_movement = FALSE)
	. = ..()
	remove_temp_negative_pass_flags(PASS_FLAGS_CRAWLER)

// ИИ-Поведение: Тип движения
/mob/living/carbon/xenomorph/arachnid/init_movement_handler()
	return new /datum/xeno_ai_movement(src)

// ИИ-Поведение: Таскание
/mob/living/carbon/xenomorph/arachnid/ai_move_target(delta_time)
	if(throwing)
		return

	if(pulling)
		if(!current_target || get_dist(src, current_target) > 10)
			INVOKE_ASYNC(src, PROC_REF(stop_pulling))
			return ..()
		if(can_move_and_apply_move_delay())
			if(!Move(get_step(loc, pull_direction), pull_direction))
				pull_direction = turn(pull_direction, pick(45, -45))
		current_path = null
		return

	..()

	if(get_dist(current_target, src) > 1)
		return

	if(!istype(current_target, /mob))
		return

	var/mob/current_target_mob = current_target

	if(!current_target_mob.is_mob_incapacitated())
		return

	if(isxeno(current_target.pulledby))
		return

	if(!DT_PROB(ARACHNID_GRAB_CHANCE, delta_time))
		return

	INVOKE_ASYNC(src, PROC_REF(start_pulling), current_target)
	swap_hand()

/mob/living/carbon/xenomorph/arachnid/process_ai(delta_time)
	if(get_active_hand())
		swap_hand()
	return ..()
