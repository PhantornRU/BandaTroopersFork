/datum/unit_test/human_ai_squad_spawner
	var/list/created_squads
	var/list/created_humans

/datum/unit_test/human_ai_squad_spawner/New()
	. = ..()
	created_squads = list()
	created_humans = list()

/datum/unit_test/human_ai_squad_spawner/Destroy()
	for(var/mob/living/carbon/human/human as anything in created_humans)
		if(!QDELETED(human))
			qdel(human, force = TRUE)

	for(var/datum/human_ai_squad/squad as anything in created_squads)
		if(!QDELETED(squad))
			qdel(squad, force = TRUE)

	return ..()

/datum/unit_test/human_ai_squad_spawner/proc/get_open_test_origin()
	for(var/turf/open/floor/floor_tile as anything in block(run_loc_floor_bottom_left, run_loc_floor_top_right))
		var/all_cardinals_open = TRUE
		for(var/direction in GLOB.cardinals)
			if(!isfloorturf(get_step(floor_tile, direction)))
				all_cardinals_open = FALSE
				break

		if(all_cardinals_open)
			return floor_tile

	return run_loc_floor_bottom_left

/datum/unit_test/human_ai_squad_spawner/proc/get_enclosable_target(turf/origin, max_distance = 10)
	for(var/turf/open/floor/floor_tile as anything in range(max_distance, origin))
		if(floor_tile == origin)
			continue

		var/all_cardinals_open = TRUE
		for(var/direction in GLOB.cardinals)
			if(!isfloorturf(get_step(floor_tile, direction)))
				all_cardinals_open = FALSE
				break

		if(all_cardinals_open)
			return floor_tile

	return null

/datum/unit_test/human_ai_squad_spawner/proc/track_spawned_squad(datum/human_ai_squad/squad)
	if(!squad)
		return

	created_squads += squad
	for(var/datum/human_ai_brain/brain as anything in squad.ai_in_squad)
		if(brain?.tied_human)
			created_humans += brain.tied_human

/datum/human_ai_squad_preset/unit_test_spawn
	name = ""
	desc = ""
	ai_to_spawn = list(
		/datum/equipment_preset/colonist/cook = 3,
	)

/datum/unit_test/human_ai_squad_spawner_radius_normalization
	parent_type = /datum/unit_test/human_ai_squad_spawner

/datum/unit_test/human_ai_squad_spawner_radius_normalization/Run()
	var/datum/human_ai_squad_preset/unit_test_spawn/preset = allocate(/datum/human_ai_squad_preset/unit_test_spawn)
	TEST_ASSERT_EQUAL(preset.normalize_spawn_radius(null), 1, "Null spawn radius should fall back to 1.")
	TEST_ASSERT_EQUAL(preset.normalize_spawn_radius("oops"), 1, "Nonnumeric spawn radius should fall back to 1.")
	TEST_ASSERT_EQUAL(preset.normalize_spawn_radius(0), 1, "Spawn radius should clamp to the minimum.")
	TEST_ASSERT_EQUAL(preset.normalize_spawn_radius(11), 10, "Spawn radius should clamp to the maximum.")
	TEST_ASSERT_EQUAL(preset.normalize_spawn_radius(4), 4, "Valid spawn radius should pass through unchanged.")

/datum/unit_test/human_ai_squad_spawner_candidate_filter
	parent_type = /datum/unit_test/human_ai_squad_spawner

/datum/unit_test/human_ai_squad_spawner_candidate_filter/Run()
	var/datum/human_ai_squad_preset/unit_test_spawn/preset = allocate(/datum/human_ai_squad_preset/unit_test_spawn)
	var/turf/origin = get_open_test_origin()
	TEST_ASSERT(isfloorturf(origin), "Failed to find an open origin turf for Human AI squad spawner candidate filtering.")

	var/list/base_candidates = preset.get_spawn_candidate_turfs(origin, 10, FALSE)
	TEST_ASSERT(length(base_candidates), "Candidate selection without accessibility filtering returned no floor tiles.")
	for(var/turf/candidate as anything in base_candidates)
		TEST_ASSERT(get_dist(origin, candidate) <= 10, "Spawn candidate [candidate] exceeded the configured radius.")

	var/turf/blocked_target = get_enclosable_target(origin)
	TEST_ASSERT_NOTNULL(blocked_target, "Failed to find an enclosable target turf for accessibility filtering.")
	var/list/blockers = list()
	var/list/blocked_ring_turfs = list()
	for(var/direction in GLOB.cardinals)
		var/turf/blocker_turf = get_step(blocked_target, direction)
		TEST_ASSERT(isfloorturf(blocker_turf), "Blocked-target ring turf [blocker_turf] was not a floor.")
		blocked_ring_turfs += blocker_turf
		blockers += allocate(/obj/structure/blocker, blocker_turf)

	var/list/filtered_candidates = preset.get_spawn_candidate_turfs(origin, 10, TRUE)
	TEST_ASSERT(!(blocked_target in filtered_candidates), "An unreachable turf behind blockers should not remain a valid spawn candidate.")

	var/turf/object_blocked_target = null
	for(var/turf/candidate as anything in base_candidates)
		if(candidate == origin || candidate == blocked_target || candidate in blocked_ring_turfs)
			continue
		object_blocked_target = candidate
		break

	TEST_ASSERT_NOTNULL(object_blocked_target, "Failed to find a secondary candidate turf for center-blocking tests.")
	var/obj/structure/blocker/object_blocker = allocate(/obj/structure/blocker, object_blocked_target)
	filtered_candidates = preset.get_spawn_candidate_turfs(origin, 10, TRUE)
	TEST_ASSERT(!(object_blocked_target in filtered_candidates), "A turf with a dense object on its center should not remain a valid spawn candidate.")
	qdel(object_blocker, force = TRUE)

	var/turf/mob_target = null
	for(var/turf/candidate as anything in base_candidates)
		if(candidate == origin || candidate == blocked_target || candidate == object_blocked_target || candidate in blocked_ring_turfs)
			continue
		mob_target = candidate
		break

	TEST_ASSERT_NOTNULL(mob_target, "Failed to find a turf for dense-mob accessibility testing.")
	var/mob/living/carbon/human/dense_mob = allocate(/mob/living/carbon/human, mob_target)
	filtered_candidates = preset.get_spawn_candidate_turfs(origin, 10, TRUE)
	TEST_ASSERT(mob_target in filtered_candidates, "A dense mob should not invalidate a turf for Human AI squad spawning.")

/datum/unit_test/human_ai_squad_spawner_spawn_distribution
	parent_type = /datum/unit_test/human_ai_squad_spawner

/datum/unit_test/human_ai_squad_spawner_spawn_distribution/Run()
	var/datum/human_ai_squad_preset/unit_test_spawn/preset = allocate(/datum/human_ai_squad_preset/unit_test_spawn)
	var/turf/origin = get_open_test_origin()
	TEST_ASSERT(isfloorturf(origin), "Failed to find an open origin turf for Human AI squad spawn distribution tests.")

	var/datum/human_ai_squad/open_squad = preset.spawn_ai(origin, 1, FALSE)
	TEST_ASSERT_NOTNULL(open_squad, "Human AI squad spawner failed to create a squad on open nearby tiles.")
	track_spawned_squad(open_squad)
	TEST_ASSERT_EQUAL(length(open_squad.ai_in_squad), 3, "Open-area spawn should create the full unit-test squad.")

	var/list/open_spawn_turf_keys = list()
	for(var/datum/human_ai_brain/brain as anything in open_squad.ai_in_squad)
		var/turf/spawn_turf = get_turf(brain.tied_human)
		TEST_ASSERT(get_dist(origin, spawn_turf) <= 1, "Unit-test squad member spawned outside radius 1.")
		open_spawn_turf_keys[REF(spawn_turf)] = TRUE

	TEST_ASSERT_EQUAL(length(open_spawn_turf_keys), 3, "Open-area spawn should distribute squad members across unique tiles when enough candidates exist.")

	var/turf/fallback_target = get_enclosable_target(origin)
	TEST_ASSERT_NOTNULL(fallback_target, "Failed to find an enclosable fallback turf for repeat-spawn testing.")
	var/list/allowed_turfs = list(fallback_target)
	for(var/direction in GLOB.cardinals)
		var/turf/blocker_turf = get_step(fallback_target, direction)
		TEST_ASSERT(isfloorturf(blocker_turf), "Fallback ring turf [blocker_turf] was not a floor.")
		allocate(/obj/structure/blocker, blocker_turf)

	var/datum/human_ai_squad/fallback_squad = preset.spawn_ai(fallback_target, 1, TRUE)
	TEST_ASSERT_NOTNULL(fallback_squad, "Human AI squad spawner should still create a squad when only one accessible turf remains.")
	track_spawned_squad(fallback_squad)
	TEST_ASSERT_EQUAL(length(fallback_squad.ai_in_squad), 3, "Fallback spawn should still create the full unit-test squad.")

	for(var/datum/human_ai_brain/brain as anything in fallback_squad.ai_in_squad)
		var/turf/spawn_turf = get_turf(brain.tied_human)
		TEST_ASSERT(spawn_turf in allowed_turfs, "Fallback spawn used a turf outside the filtered candidate set.")

	TEST_ASSERT_EQUAL(fallback_squad.squad_leader, fallback_squad.ai_in_squad[1], "The first spawned unit should remain the squad leader after the radius/filter changes.")
