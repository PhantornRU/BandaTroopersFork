/proc/create_all_lighting_objects()
	for(var/area/A in world)

		if(!A.static_lighting)
			continue

		for(var/turf/T in A)
			// Compiled ALL_MAPS z-levels can exist in world without being active managed levels.
			if(!SSmapping.z_list || T.z > length(SSmapping.z_list))
				continue
			new/datum/static_lighting_object(T)
			CHECK_TICK
		CHECK_TICK
