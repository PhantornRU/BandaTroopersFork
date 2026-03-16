#define HUMAN_AI_GRENADE_TEST_DISTANCE 7
#define HUMAN_AI_GRENADE_TEST_WAIT (3 SECONDS)

/obj/item/explosive/grenade/unit_test/ai_throw
	name = "unit test AI grenade"
	det_time = 10
	antigrief_protection = FALSE
	var/last_throw_distance
	var/last_throw_range
	var/atom/last_throw_target
	var/turf/last_throw_final_turf

/obj/item/explosive/grenade/unit_test/ai_throw/Initialize()
	. = ..()
	det_time = 10 // SS220 EDIT: keep the async grenade-action wait deterministic for unit tests

/obj/item/explosive/grenade/unit_test/ai_throw/prime(force = FALSE)
	active = FALSE
	w_class = initial(w_class)
	update_icon()

/obj/item/explosive/grenade/unit_test/ai_throw/launch_impact(atom/hit_atom)
	last_throw_distance = launch_metadata?.dist
	last_throw_range = launch_metadata?.range
	last_throw_target = launch_metadata?.target
	last_throw_final_turf = get_turf(src)
	return ..()

/datum/unit_test/human_ai_grenade_throws/proc/create_test_ai_brain()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
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
	human.forceMove(run_loc_floor_bottom_left)
	return brain

/datum/unit_test/human_ai_grenade_throws/proc/create_target_turf(datum/human_ai_brain/brain, distance = HUMAN_AI_GRENADE_TEST_DISTANCE)
	var/turf/origin = get_turf(brain?.tied_human)
	if(!origin)
		return null

	return locate(origin.x + distance, origin.y, origin.z)

/datum/unit_test/human_ai_grenade_throws/proc/give_test_grenade(datum/human_ai_brain/brain)
	var/mob/living/carbon/human/human = brain?.tied_human
	if(!human)
		return null

	var/obj/item/explosive/grenade/unit_test/ai_throw/grenade = allocate(/obj/item/explosive/grenade/unit_test/ai_throw, human)
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
	var/result = action.trigger_action()
	TEST_ASSERT_EQUAL(result, ONGOING_ACTION_UNFINISHED_BLOCK, "The shared grenade throw action should enter its async prime/throw phase.")

	sleep(HUMAN_AI_GRENADE_TEST_WAIT)
	TEST_ASSERT_EQUAL(grenade.last_throw_range, HUMAN_AI_GRENADE_TEST_DISTANCE, "The shared grenade throw action should request the grenade's full 7-tile hand-throw range.")
	TEST_ASSERT_EQUAL(grenade.last_throw_distance, HUMAN_AI_GRENADE_TEST_DISTANCE, "The shared grenade throw action should reach the intended 7-tile target instead of dropping short.")
	TEST_ASSERT_EQUAL(grenade.last_throw_final_turf, target_turf, "The shared grenade throw action should land on the intended target turf in a clear straight line.")

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
	var/result = action.trigger_action()
	TEST_ASSERT_EQUAL(result, ONGOING_ACTION_UNFINISHED_BLOCK, "The shared grenade throw action should begin asynchronously before the hand-interference window.")

	sleep(1.2 SECONDS)
	brain.tied_human.swap_hand() // SS220 EDIT: reproduce the old wrong-hand race that caused short self-throws

	sleep(2 SECONDS)
	TEST_ASSERT_EQUAL(grenade.last_throw_range, HUMAN_AI_GRENADE_TEST_DISTANCE, "The shared grenade throw action should keep the intended 7-tile range even if the active hand changes mid-prime.")
	TEST_ASSERT_EQUAL(grenade.last_throw_distance, HUMAN_AI_GRENADE_TEST_DISTANCE, "The shared grenade throw action should recover from mid-prime hand interference instead of throwing short.")
	TEST_ASSERT_EQUAL(grenade.last_throw_final_turf, target_turf, "The shared grenade throw action should still land on the original target turf after hand interference.")

	qdel(action)

#undef HUMAN_AI_GRENADE_TEST_DISTANCE
#undef HUMAN_AI_GRENADE_TEST_WAIT
