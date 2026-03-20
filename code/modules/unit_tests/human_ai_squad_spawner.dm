/datum/unit_test/human_ai_squad_spawner_viable_turfs
/datum/unit_test/human_ai_squad_spawner_viable_turfs/Run()
	var/datum/human_ai_squad_preset/preset = allocate(/datum/human_ai_squad_preset)
	var/turf/origin = run_loc_floor_bottom_left
	var/turf/east_one = get_step(origin, EAST)
	var/turf/east_two = get_step(east_one, EAST)

	TEST_ASSERT(isfloorturf(origin), "Spawner unit test origin was not a floor turf.")
	TEST_ASSERT(isfloorturf(east_one), "Spawner radius test could not find the first floor turf east of origin.")
	TEST_ASSERT(isfloorturf(east_two), "Spawner radius test could not find the second floor turf east of origin.")

	var/list/radius_one_turfs = preset.get_viable_spawn_turfs(origin, 1, FALSE)
	TEST_ASSERT(radius_one_turfs.Find(origin), "Spawner viable turf selection lost the origin turf at radius 1.")
	TEST_ASSERT(radius_one_turfs.Find(east_one), "Spawner viable turf selection lost the adjacent floor turf at radius 1.")
	TEST_ASSERT(!radius_one_turfs.Find(east_two), "Spawner viable turf selection incorrectly included a turf outside radius 1.")

	var/list/radius_two_turfs = preset.get_viable_spawn_turfs(origin, 2, FALSE)
	TEST_ASSERT(radius_two_turfs.Find(east_two), "Spawner viable turf selection failed to include the farther floor turf at radius 2.")

	var/obj/structure/closet/blocker = allocate(/obj/structure/closet, east_one)
	TEST_ASSERT(blocker.density, "Spawner accessibility test blocker must stay dense.")

	var/list/accessible_turfs = preset.get_viable_spawn_turfs(origin, 1, TRUE)
	TEST_ASSERT(!accessible_turfs.Find(east_one), "Spawner accessibility filtering failed to remove a blocked floor turf.")

	var/list/unfiltered_turfs = preset.get_viable_spawn_turfs(origin, 1, FALSE)
	TEST_ASSERT(unfiltered_turfs.Find(east_one), "Spawner raw radius selection should still include the same floor turf when accessibility filtering is disabled.")
