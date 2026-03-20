#define HUMAN_AI_GRENADE_TEST_DISTANCE 7
#define HUMAN_AI_GRENADE_TEST_WAIT (3 SECONDS)

/obj/item/explosive/grenade/unit_test/ai_throw
	name = "unit test AI grenade"
	det_time = 10
	antigrief_protection = FALSE
	var/armed_at = 0
	var/last_throw_distance
	var/last_throw_range
	var/atom/last_throw_target
	var/turf/last_throw_final_turf
	var/last_throw_recorded_at = 0

/obj/item/explosive/grenade/unit_test/ai_throw/Initialize()
	. = ..()
	det_time = 10 // SS220 EDIT: keep the async grenade-action wait deterministic for unit tests

/obj/item/explosive/grenade/unit_test/ai_throw/activate(mob/user = null, hand_throw = TRUE)
	armed_at = world.time
	return ..()

/obj/item/explosive/grenade/unit_test/ai_throw/prime(force = FALSE)
	active = FALSE
	w_class = initial(w_class)
	update_icon()

/obj/item/explosive/grenade/unit_test/ai_throw/launch_impact(atom/hit_atom)
	last_throw_distance = launch_metadata?.dist
	last_throw_range = launch_metadata?.range
	last_throw_target = launch_metadata?.target
	last_throw_final_turf = get_turf(src)
	last_throw_recorded_at = world.time
	return ..()

/datum/unit_test/human_ai_grenade_throws
	var/list/created_humans
	var/list/created_items
	var/list/created_actions
	var/turf/prepared_throw_origin
	var/turf/prepared_throw_target

/datum/unit_test/human_ai_grenade_throws/New()
	. = ..()
	created_humans = list()
	created_items = list()
	created_actions = list()

/datum/unit_test/human_ai_grenade_throws/Destroy()
	for(var/datum/ai_action/action as anything in created_actions)
		if(!QDELETED(action))
			qdel(action)

	for(var/obj/item/item as anything in created_items)
		if(!QDELETED(item))
			qdel(item)

	for(var/mob/living/carbon/human/human as anything in created_humans)
		if(!QDELETED(human))
			qdel(human)

	created_humans = null
	created_items = null
	created_actions = null
	prepared_throw_origin = null
	prepared_throw_target = null

	return ..()

/datum/unit_test/human_ai_grenade_throws/proc/create_test_ai_brain()
	var/turf/origin = find_clear_throw_origin()
	if(!isfloorturf(origin))
		TEST_FAIL("Failed to find a deterministic open origin turf for the shared grenade-throw tests.")
		return null

	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human, origin)
	created_humans += human
	var/datum/component/human_ai/ai_component = human.AddComponent(/datum/component/human_ai)
	if(!ai_component)
		TEST_FAIL("Failed to add a human AI component to the shared grenade-throw test mob.")
		return null
	if(!ai_component.ai_brain)
		TEST_FAIL("Failed to resolve a shared human AI brain for grenade-throw tests.")
		return null

	var/datum/human_ai_brain/brain = ai_component.ai_brain
	brain.action_blacklist = list()
	for(var/action_type in GLOB.AI_actions)
		brain.action_blacklist += action_type // SS220 EDIT: keep the unit test deterministic by disabling autonomous scheduler actions
	brain.in_combat = TRUE
	human.forceMove(origin)
	return brain

/datum/unit_test/human_ai_grenade_throws/proc/create_sangheili_ai_brain(preset_type = /datum/equipment_preset/covenant/sangheili/ai/ultra_plasma)
	var/turf/origin = find_clear_throw_origin()
	if(!isfloorturf(origin))
		TEST_FAIL("Failed to find a deterministic open origin turf for the Sangheili grenade-throw tests.")
		return null

	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human, origin)
	created_humans += human
	arm_equipment(human, preset_type, FALSE)
	var/datum/component/human_ai/ai_component = human.AddComponent(/datum/component/human_ai)
	if(!ai_component)
		TEST_FAIL("Failed to add a human AI component to the Sangheili grenade-throw test mob.")
		return null
	if(!ai_component.ai_brain)
		TEST_FAIL("Failed to resolve a Sangheili human AI brain for grenade-throw tests.")
		return null

	var/datum/human_ai_brain/brain = ai_component.ai_brain
	brain.action_blacklist = list()
	for(var/action_type in GLOB.AI_actions)
		brain.action_blacklist += action_type
	brain.in_combat = TRUE
	brain.appraise_inventory(armor = TRUE)
	if(isgun(human.s_store))
		brain.set_primary_weapon(human.s_store)
	human.forceMove(origin)
	return brain

/datum/unit_test/human_ai_grenade_throws/proc/find_clear_throw_target_from_origin(turf/origin, distance = HUMAN_AI_GRENADE_TEST_DISTANCE)
	if(!isfloorturf(origin))
		return null

	for(var/direction in GLOB.cardinals)
		var/turf/current_turf = origin
		var/path_clear = TRUE
		for(var/i in 1 to distance)
			current_turf = get_step(current_turf, direction)
			if(!is_clear_throw_corridor_turf(current_turf))
				path_clear = FALSE
				break
		if(path_clear && isfloorturf(current_turf))
			return current_turf

	return null

/datum/unit_test/human_ai_grenade_throws/proc/is_clear_throw_corridor_turf(turf/current_turf)
	if(!isfloorturf(current_turf))
		return FALSE

	if(current_turf.density)
		return FALSE

	for(var/obj/object in current_turf)
		if(object.density)
			return FALSE

	return TRUE

/datum/unit_test/human_ai_grenade_throws/proc/find_clear_throw_origin(distance = HUMAN_AI_GRENADE_TEST_DISTANCE)
	prepared_throw_origin = null
	prepared_throw_target = null
	var/search_radius = distance + 6
	var/list/search_roots = list(run_loc_floor_bottom_left, run_loc_floor_top_right, SSmapping?.get_mainship_center())
	var/list/search_levels = list()
	for(var/turf/root as anything in search_roots)
		if(!isfloorturf(root))
			continue
		if(!(root.z in search_levels))
			search_levels += root.z
		for(var/turf/origin as anything in range(search_radius, root))
			if(!isfloorturf(origin))
				continue
			if(find_clear_throw_target_from_origin(origin, distance))
				return origin

	for(var/z_level as anything in search_levels)
		var/turf/start_corner = locate(1, 1, z_level)
		var/turf/end_corner = locate(world.maxx, world.maxy, z_level)
		if(!start_corner || !end_corner)
			continue
		for(var/turf/origin as anything in block(start_corner, end_corner))
			if(!isfloorturf(origin))
				continue
			if(find_clear_throw_target_from_origin(origin, distance))
				return origin

	return prepare_throw_lane(distance)

/datum/unit_test/human_ai_grenade_throws/proc/prepare_throw_lane(distance = HUMAN_AI_GRENADE_TEST_DISTANCE)
	var/list/search_roots = list(run_loc_floor_bottom_left, run_loc_floor_top_right, SSmapping?.get_mainship_center())
	for(var/turf/root as anything in search_roots)
		if(!isturf(root))
			continue
		for(var/direction in GLOB.cardinals)
			var/turf/origin = ensure_clear_throw_lane(root, direction, distance)
			if(!isfloorturf(origin))
				continue
			prepared_throw_origin = origin
			prepared_throw_target = get_offset_turf(origin, direction, distance)
			if(isfloorturf(prepared_throw_target))
				return prepared_throw_origin

	return null

/datum/unit_test/human_ai_grenade_throws/proc/ensure_clear_throw_lane(turf/origin, direction, distance)
	if(!isturf(origin))
		return null

	var/turf/current_turf = origin
	for(var/i in 0 to distance)
		if(!isturf(current_turf))
			return null
		if(!isfloorturf(current_turf))
			current_turf = current_turf.ChangeTurf(/turf/open/floor/plating)
		for(var/atom/movable/blocker as anything in current_turf)
			if(ismob(blocker) || !blocker.density)
				continue
			qdel(blocker)
		if(i < distance)
			current_turf = get_step(current_turf, direction)

	return origin

/datum/unit_test/human_ai_grenade_throws/proc/get_offset_turf(turf/origin, direction, distance)
	var/turf/current_turf = origin
	for(var/i in 1 to distance)
		current_turf = get_step(current_turf, direction)
		if(!isturf(current_turf))
			return null

	return current_turf

/datum/unit_test/human_ai_grenade_throws/proc/create_target_turf(datum/human_ai_brain/brain, distance = HUMAN_AI_GRENADE_TEST_DISTANCE)
	var/turf/origin = get_turf(brain?.tied_human)
	if(!origin)
		return null

	if(origin == prepared_throw_origin && isfloorturf(prepared_throw_target))
		return prepared_throw_target

	return find_clear_throw_target_from_origin(origin, distance)

/datum/unit_test/human_ai_grenade_throws/proc/give_test_grenade(datum/human_ai_brain/brain)
	var/mob/living/carbon/human/human = brain?.tied_human
	if(!human)
		return null

	var/obj/item/explosive/grenade/unit_test/ai_throw/grenade = allocate(/obj/item/explosive/grenade/unit_test/ai_throw, human)
	created_items += grenade
	brain.equipment_map[HUMAN_AI_GRENADES][grenade] = "unit_test"
	return grenade

/datum/unit_test/human_ai_grenade_throws/Run()
	return

/datum/unit_test/human_ai_grenade_throw_distance
	parent_type = /datum/unit_test/human_ai_grenade_throws

/datum/unit_test/human_ai_grenade_throw_distance/Run()
	var/datum/human_ai_brain/brain = create_test_ai_brain()
	TEST_ASSERT_NOTNULL(brain, "Failed to create the shared human AI grenade-throw test brain.")

	var/turf/target_turf = create_target_turf(brain)
	TEST_ASSERT(isfloorturf(target_turf), "Failed to allocate a clear target turf for the shared grenade-throw distance test.")
	brain.target_turf = target_turf

	var/obj/item/explosive/grenade/unit_test/ai_throw/grenade = give_test_grenade(brain)
	TEST_ASSERT_NOTNULL(grenade, "Failed to give the shared grenade-throw AI a test grenade.")

	var/datum/ai_action/throw_grenade/action = new(brain)
	created_actions += action
	var/result = action.trigger_action()
	TEST_ASSERT_EQUAL(result, ONGOING_ACTION_UNFINISHED_BLOCK, "The shared grenade throw action should enter its async prime/throw phase.")

	sleep(HUMAN_AI_GRENADE_TEST_WAIT)
	TEST_ASSERT_EQUAL(grenade.last_throw_range, HUMAN_AI_GRENADE_TEST_DISTANCE, "The shared grenade throw action should request the grenade's full 7-tile hand-throw range.")
	TEST_ASSERT_EQUAL(grenade.last_throw_distance, HUMAN_AI_GRENADE_TEST_DISTANCE, "The shared grenade throw action should reach the intended 7-tile target instead of dropping short.")
	TEST_ASSERT_EQUAL(grenade.last_throw_final_turf, target_turf, "The shared grenade throw action should land on the intended target turf in a clear straight line.")

	qdel(action)

/datum/unit_test/human_ai_grenade_throw_minimum_hold_delay
	parent_type = /datum/unit_test/human_ai_grenade_throws

/datum/unit_test/human_ai_grenade_throw_minimum_hold_delay/Run()
	var/datum/human_ai_brain/brain = create_test_ai_brain()
	TEST_ASSERT_NOTNULL(brain, "Failed to create the shared human AI grenade-hold test brain.")

	var/turf/target_turf = create_target_turf(brain)
	TEST_ASSERT(isfloorturf(target_turf), "Failed to allocate a clear target turf for the grenade hold-delay test.")
	brain.target_turf = target_turf

	var/obj/item/explosive/grenade/unit_test/ai_throw/grenade = give_test_grenade(brain)
	TEST_ASSERT_NOTNULL(grenade, "Failed to give the grenade hold-delay AI a test grenade.")

	var/datum/ai_action/throw_grenade/action = new(brain)
	created_actions += action
	var/action_started_at = world.time
	var/result = action.trigger_action()
	TEST_ASSERT_EQUAL(result, ONGOING_ACTION_UNFINISHED_BLOCK, "The grenade hold-delay action should enter its async prime/throw phase.")

	sleep(9 DECISECONDS)
	TEST_ASSERT_EQUAL(grenade.loc, brain.tied_human, "The AI should still be holding the grenade just before the one-second minimum hold delay elapses.")
	TEST_ASSERT(!grenade.active, "The AI should not prime the grenade before completing the one-second minimum hold delay.")
	TEST_ASSERT_NULL(grenade.last_throw_final_turf, "The AI should not throw the grenade before the one-second minimum hold delay elapses.")

	sleep(3 DECISECONDS)
	TEST_ASSERT_EQUAL(grenade.loc, brain.tied_human, "The AI should still have the grenade in hand immediately after priming.")
	TEST_ASSERT((grenade.armed_at - action_started_at) >= 1 SECONDS, "The AI should hold the grenade for at least one second before priming it.")
	TEST_ASSERT(grenade.active, "The test grenade should be active immediately after the minimum hold delay elapses.")
	TEST_ASSERT_NULL(grenade.last_throw_final_turf, "The AI should not throw the grenade on the same tick it primes it.")

	sleep(2 SECONDS)
	TEST_ASSERT_EQUAL(grenade.last_throw_final_turf, target_turf, "The grenade hold-delay action should still throw to the intended target after the one-second hold delay.")

	qdel(action)

/datum/unit_test/human_ai_grenade_throw_interference_recovery
	parent_type = /datum/unit_test/human_ai_grenade_throws

/datum/unit_test/human_ai_grenade_throw_interference_recovery/Run()
	var/datum/human_ai_brain/brain = create_test_ai_brain()
	TEST_ASSERT_NOTNULL(brain, "Failed to create the shared human AI grenade-throw interference test brain.")

	var/turf/target_turf = create_target_turf(brain)
	TEST_ASSERT(isfloorturf(target_turf), "Failed to allocate a clear target turf for the shared grenade-throw interference test.")
	brain.target_turf = target_turf

	var/obj/item/explosive/grenade/unit_test/ai_throw/grenade = give_test_grenade(brain)
	TEST_ASSERT_NOTNULL(grenade, "Failed to give the shared grenade-throw interference AI a test grenade.")

	var/datum/ai_action/throw_grenade/action = new(brain)
	created_actions += action
	var/result = action.trigger_action()
	TEST_ASSERT_EQUAL(result, ONGOING_ACTION_UNFINISHED_BLOCK, "The shared grenade throw action should begin asynchronously before the hand-interference window.")

	sleep(1.2 SECONDS)
	brain.tied_human.swap_hand() // SS220 EDIT: reproduce the old wrong-hand race that caused short self-throws

	sleep(2 SECONDS)
	TEST_ASSERT_EQUAL(grenade.last_throw_range, HUMAN_AI_GRENADE_TEST_DISTANCE, "The shared grenade throw action should keep the intended 7-tile range even if the active hand changes mid-prime.")
	TEST_ASSERT_EQUAL(grenade.last_throw_distance, HUMAN_AI_GRENADE_TEST_DISTANCE, "The shared grenade throw action should recover from mid-prime hand interference instead of throwing short.")
	TEST_ASSERT_EQUAL(grenade.last_throw_final_turf, target_turf, "The shared grenade throw action should still land on the original target turf after hand interference.")

	qdel(action)

/datum/unit_test/human_ai_sangheili_grenade_throw_interference_recovery
	parent_type = /datum/unit_test/human_ai_grenade_throws

/datum/unit_test/human_ai_sangheili_grenade_throw_interference_recovery/Run()
	var/datum/human_ai_brain/brain = create_sangheili_ai_brain()
	TEST_ASSERT_NOTNULL(brain, "Failed to create the Sangheili grenade-throw interference test brain.")

	var/turf/target_turf = create_target_turf(brain)
	TEST_ASSERT(isfloorturf(target_turf), "Failed to allocate a clear target turf for the Sangheili grenade-throw interference test.")
	brain.target_turf = target_turf

	var/turf/origin_turf = get_turf(brain.tied_human)
	var/obj/item/explosive/grenade/unit_test/ai_throw/grenade = give_test_grenade(brain)
	TEST_ASSERT_NOTNULL(grenade, "Failed to give the Sangheili grenade-throw interference AI a test grenade.")

	var/datum/ai_action/throw_grenade/action = new(brain)
	created_actions += action
	var/result = action.trigger_action()
	TEST_ASSERT_EQUAL(result, ONGOING_ACTION_UNFINISHED_BLOCK, "The Sangheili grenade throw action should begin asynchronously before the hand-interference window.")

	sleep(1.2 SECONDS)
	brain.tied_human.swap_hand()

	sleep(2 SECONDS)
	TEST_ASSERT_EQUAL(grenade.last_throw_range, HUMAN_AI_GRENADE_TEST_DISTANCE, "The Sangheili grenade throw action should keep the intended 7-tile range even if the active hand changes mid-prime.")
	TEST_ASSERT_EQUAL(grenade.last_throw_distance, HUMAN_AI_GRENADE_TEST_DISTANCE, "The Sangheili grenade throw action should recover from mid-prime hand interference instead of throwing short.")
	TEST_ASSERT_EQUAL(grenade.last_throw_final_turf, target_turf, "The Sangheili grenade throw action should still land on the original target turf after hand interference.")
	TEST_ASSERT_NOTEQUAL(grenade.last_throw_final_turf, origin_turf, "The Sangheili grenade throw action should not drop or throw the grenade under the thrower.")

	qdel(action)

#undef HUMAN_AI_GRENADE_TEST_DISTANCE
#undef HUMAN_AI_GRENADE_TEST_WAIT
