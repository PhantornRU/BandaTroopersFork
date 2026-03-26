/datum/authority/branch/role/proc/get_ship_surface_target_locker_root_type(canonical_role, target_family)
	switch(target_family)
		if(SHIP_SURFACE_FAMILY_USCM)
			switch(canonical_role)
				if(JOB_SO)
					return /obj/structure/closet/secure_closet/marine_personal/platoon_commander
				if(JOB_SQUAD_MARINE)
					return /obj/structure/closet/secure_closet/marine_personal/rifleman
				if(JOB_SQUAD_MEDIC)
					return /obj/structure/closet/secure_closet/marine_personal/corpsman
				if(JOB_SQUAD_SPECIALIST)
					return /obj/structure/closet/secure_closet/marine_personal/specialist
				if(JOB_SQUAD_RTO)
					return /obj/structure/closet/secure_closet/marine_personal/rto
				if(JOB_SQUAD_TEAM_LEADER)
					return /obj/structure/closet/secure_closet/marine_personal/squad_leader
				if(JOB_SQUAD_LEADER)
					return /obj/structure/closet/secure_closet/marine_personal/platoon_leader
		if(SHIP_SURFACE_FAMILY_UNSC)
			switch(canonical_role)
				if(JOB_SO)
					return /obj/structure/closet/secure_closet/marine_personal/unsc/platoon_commander
				if(JOB_SQUAD_MARINE)
					return /obj/structure/closet/secure_closet/marine_personal/unsc/rifleman
				if(JOB_SQUAD_MEDIC)
					return /obj/structure/closet/secure_closet/marine_personal/unsc/corpsman
				if(JOB_SQUAD_SPECIALIST)
					return /obj/structure/closet/secure_closet/marine_personal/unsc/specialist
				if(JOB_SQUAD_RTO)
					return /obj/structure/closet/secure_closet/marine_personal/unsc/rto
				if(JOB_SQUAD_TEAM_LEADER)
					return /obj/structure/closet/secure_closet/marine_personal/unsc/team_leader
				if(JOB_SQUAD_LEADER)
					return /obj/structure/closet/secure_closet/marine_personal/unsc/squad_leader
		if(SHIP_SURFACE_FAMILY_ODST)
			switch(canonical_role)
				if(JOB_SO)
					return /obj/structure/closet/secure_closet/marine_personal/odst/platoon_commander
				if(JOB_SQUAD_MARINE)
					return /obj/structure/closet/secure_closet/marine_personal/odst/rifleman
				if(JOB_SQUAD_MEDIC)
					return /obj/structure/closet/secure_closet/marine_personal/odst/corpsman
				if(JOB_SQUAD_SPECIALIST)
					return /obj/structure/closet/secure_closet/marine_personal/odst/specialist
				if(JOB_SQUAD_RTO)
					return /obj/structure/closet/secure_closet/marine_personal/odst/rto
				if(JOB_SQUAD_TEAM_LEADER)
					return /obj/structure/closet/secure_closet/marine_personal/odst/team_leader
				if(JOB_SQUAD_LEADER)
					return /obj/structure/closet/secure_closet/marine_personal/odst/squad_leader

	return null

/datum/authority/branch/role/proc/get_ship_surface_target_locker_type(canonical_role, squad_type, target_family)
	if(!squad_type)
		return get_ship_surface_target_locker_root_type(canonical_role, target_family)

	switch(target_family)
		if(SHIP_SURFACE_FAMILY_USCM)
			switch(canonical_role)
				if(JOB_SQUAD_MARINE)
					switch(squad_type)
						if(SQUAD_MARINE_1) return /obj/structure/closet/secure_closet/marine_personal/rifleman/s1
						if(SQUAD_MARINE_2) return /obj/structure/closet/secure_closet/marine_personal/rifleman/s2
						if(SQUAD_MARINE_3) return /obj/structure/closet/secure_closet/marine_personal/rifleman/s3
						if(SQUAD_MARINE_4) return /obj/structure/closet/secure_closet/marine_personal/rifleman/s4
				if(JOB_SQUAD_MEDIC)
					switch(squad_type)
						if(SQUAD_MARINE_1) return /obj/structure/closet/secure_closet/marine_personal/corpsman/s1
						if(SQUAD_MARINE_2) return /obj/structure/closet/secure_closet/marine_personal/corpsman/s2
						if(SQUAD_MARINE_3) return /obj/structure/closet/secure_closet/marine_personal/corpsman/s3
						if(SQUAD_MARINE_4) return /obj/structure/closet/secure_closet/marine_personal/corpsman/s4
				if(JOB_SQUAD_SPECIALIST)
					switch(squad_type)
						if(SQUAD_MARINE_1) return /obj/structure/closet/secure_closet/marine_personal/specialist/s1
						if(SQUAD_MARINE_2) return /obj/structure/closet/secure_closet/marine_personal/specialist/s2
						if(SQUAD_MARINE_3) return /obj/structure/closet/secure_closet/marine_personal/specialist/s3
						if(SQUAD_MARINE_4) return /obj/structure/closet/secure_closet/marine_personal/specialist/s4
				if(JOB_SQUAD_RTO)
					switch(squad_type)
						if(SQUAD_MARINE_1) return /obj/structure/closet/secure_closet/marine_personal/rto/s1
						if(SQUAD_MARINE_2) return /obj/structure/closet/secure_closet/marine_personal/rto/s2
						if(SQUAD_MARINE_3) return /obj/structure/closet/secure_closet/marine_personal/rto/s3
						if(SQUAD_MARINE_4) return /obj/structure/closet/secure_closet/marine_personal/rto/s4
				if(JOB_SQUAD_TEAM_LEADER)
					switch(squad_type)
						if(SQUAD_MARINE_1) return /obj/structure/closet/secure_closet/marine_personal/squad_leader/s1
						if(SQUAD_MARINE_2) return /obj/structure/closet/secure_closet/marine_personal/squad_leader/s2
						if(SQUAD_MARINE_3) return /obj/structure/closet/secure_closet/marine_personal/squad_leader/s3
						if(SQUAD_MARINE_4) return /obj/structure/closet/secure_closet/marine_personal/squad_leader/s4
				if(JOB_SQUAD_LEADER)
					switch(squad_type)
						if(SQUAD_MARINE_1) return /obj/structure/closet/secure_closet/marine_personal/platoon_leader/s1
						if(SQUAD_MARINE_2) return /obj/structure/closet/secure_closet/marine_personal/platoon_leader/s2
						if(SQUAD_MARINE_3) return /obj/structure/closet/secure_closet/marine_personal/platoon_leader/s3
						if(SQUAD_MARINE_4) return /obj/structure/closet/secure_closet/marine_personal/platoon_leader/s4
		if(SHIP_SURFACE_FAMILY_UNSC)
			switch(canonical_role)
				if(JOB_SQUAD_MARINE)
					switch(squad_type)
						if(SQUAD_MARINE_1) return /obj/structure/closet/secure_closet/marine_personal/unsc/alpha/rifleman
						if(SQUAD_MARINE_2) return /obj/structure/closet/secure_closet/marine_personal/unsc/bravo/rifleman
						if(SQUAD_MARINE_3) return /obj/structure/closet/secure_closet/marine_personal/unsc/charlie/rifleman
						if(SQUAD_MARINE_4) return /obj/structure/closet/secure_closet/marine_personal/unsc/delta/rifleman
				if(JOB_SQUAD_MEDIC)
					switch(squad_type)
						if(SQUAD_MARINE_1) return /obj/structure/closet/secure_closet/marine_personal/unsc/alpha/corpsman
						if(SQUAD_MARINE_2) return /obj/structure/closet/secure_closet/marine_personal/unsc/bravo/corpsman
						if(SQUAD_MARINE_3) return /obj/structure/closet/secure_closet/marine_personal/unsc/charlie/corpsman
						if(SQUAD_MARINE_4) return /obj/structure/closet/secure_closet/marine_personal/unsc/delta/corpsman
				if(JOB_SQUAD_SPECIALIST)
					switch(squad_type)
						if(SQUAD_MARINE_1) return /obj/structure/closet/secure_closet/marine_personal/unsc/alpha/specialist
						if(SQUAD_MARINE_2) return /obj/structure/closet/secure_closet/marine_personal/unsc/bravo/specialist
						if(SQUAD_MARINE_3) return /obj/structure/closet/secure_closet/marine_personal/unsc/charlie/specialist
						if(SQUAD_MARINE_4) return /obj/structure/closet/secure_closet/marine_personal/unsc/delta/specialist
				if(JOB_SQUAD_RTO)
					switch(squad_type)
						if(SQUAD_MARINE_1) return /obj/structure/closet/secure_closet/marine_personal/unsc/alpha/rto
						if(SQUAD_MARINE_2) return /obj/structure/closet/secure_closet/marine_personal/unsc/bravo/rto
						if(SQUAD_MARINE_3) return /obj/structure/closet/secure_closet/marine_personal/unsc/charlie/rto
						if(SQUAD_MARINE_4) return /obj/structure/closet/secure_closet/marine_personal/unsc/delta/rto
				if(JOB_SQUAD_TEAM_LEADER)
					switch(squad_type)
						if(SQUAD_MARINE_1) return /obj/structure/closet/secure_closet/marine_personal/unsc/alpha/team_leader
						if(SQUAD_MARINE_2) return /obj/structure/closet/secure_closet/marine_personal/unsc/bravo/team_leader
						if(SQUAD_MARINE_3) return /obj/structure/closet/secure_closet/marine_personal/unsc/charlie/team_leader
						if(SQUAD_MARINE_4) return /obj/structure/closet/secure_closet/marine_personal/unsc/delta/team_leader
				if(JOB_SQUAD_LEADER)
					switch(squad_type)
						if(SQUAD_MARINE_1) return /obj/structure/closet/secure_closet/marine_personal/unsc/alpha/squad_leader
						if(SQUAD_MARINE_2) return /obj/structure/closet/secure_closet/marine_personal/unsc/bravo/squad_leader
						if(SQUAD_MARINE_3) return /obj/structure/closet/secure_closet/marine_personal/unsc/charlie/squad_leader
						if(SQUAD_MARINE_4) return /obj/structure/closet/secure_closet/marine_personal/unsc/delta/squad_leader
		if(SHIP_SURFACE_FAMILY_ODST)
			switch(canonical_role)
				if(JOB_SQUAD_MARINE)
					switch(squad_type)
						if(SQUAD_MARINE_1) return /obj/structure/closet/secure_closet/marine_personal/odst/alpha/rifleman
						if(SQUAD_MARINE_2) return /obj/structure/closet/secure_closet/marine_personal/odst/bravo/rifleman
						if(SQUAD_MARINE_3) return /obj/structure/closet/secure_closet/marine_personal/odst/charlie/rifleman
						if(SQUAD_MARINE_4) return /obj/structure/closet/secure_closet/marine_personal/odst/delta/rifleman
				if(JOB_SQUAD_MEDIC)
					switch(squad_type)
						if(SQUAD_MARINE_1) return /obj/structure/closet/secure_closet/marine_personal/odst/alpha/corpsman
						if(SQUAD_MARINE_2) return /obj/structure/closet/secure_closet/marine_personal/odst/bravo/corpsman
						if(SQUAD_MARINE_3) return /obj/structure/closet/secure_closet/marine_personal/odst/charlie/corpsman
						if(SQUAD_MARINE_4) return /obj/structure/closet/secure_closet/marine_personal/odst/delta/corpsman
				if(JOB_SQUAD_SPECIALIST)
					switch(squad_type)
						if(SQUAD_MARINE_1) return /obj/structure/closet/secure_closet/marine_personal/odst/alpha/specialist
						if(SQUAD_MARINE_2) return /obj/structure/closet/secure_closet/marine_personal/odst/bravo/specialist
						if(SQUAD_MARINE_3) return /obj/structure/closet/secure_closet/marine_personal/odst/charlie/specialist
						if(SQUAD_MARINE_4) return /obj/structure/closet/secure_closet/marine_personal/odst/delta/specialist
				if(JOB_SQUAD_RTO)
					switch(squad_type)
						if(SQUAD_MARINE_1) return /obj/structure/closet/secure_closet/marine_personal/odst/alpha/rto
						if(SQUAD_MARINE_2) return /obj/structure/closet/secure_closet/marine_personal/odst/bravo/rto
						if(SQUAD_MARINE_3) return /obj/structure/closet/secure_closet/marine_personal/odst/charlie/rto
						if(SQUAD_MARINE_4) return /obj/structure/closet/secure_closet/marine_personal/odst/delta/rto
				if(JOB_SQUAD_TEAM_LEADER)
					switch(squad_type)
						if(SQUAD_MARINE_1) return /obj/structure/closet/secure_closet/marine_personal/odst/alpha/team_leader
						if(SQUAD_MARINE_2) return /obj/structure/closet/secure_closet/marine_personal/odst/bravo/team_leader
						if(SQUAD_MARINE_3) return /obj/structure/closet/secure_closet/marine_personal/odst/charlie/team_leader
						if(SQUAD_MARINE_4) return /obj/structure/closet/secure_closet/marine_personal/odst/delta/team_leader
				if(JOB_SQUAD_LEADER)
					switch(squad_type)
						if(SQUAD_MARINE_1) return /obj/structure/closet/secure_closet/marine_personal/odst/alpha/squad_leader
						if(SQUAD_MARINE_2) return /obj/structure/closet/secure_closet/marine_personal/odst/bravo/squad_leader
						if(SQUAD_MARINE_3) return /obj/structure/closet/secure_closet/marine_personal/odst/charlie/squad_leader
						if(SQUAD_MARINE_4) return /obj/structure/closet/secure_closet/marine_personal/odst/delta/squad_leader

	return null

/datum/authority/branch/role/proc/replace_ship_surface_locker(obj/structure/closet/secure_closet/marine_personal/source_locker, target_type)
	if(!istype(source_locker) || !target_type)
		return null

	var/turf/locker_turf = get_turf(source_locker)
	if(!isturf(locker_turf))
		return null

	var/obj/structure/closet/secure_closet/marine_personal/target_locker = new target_type(locker_turf)
	copy_ship_surface_transform(source_locker, target_locker)
	target_locker.owner = source_locker.owner
	target_locker.opened = source_locker.opened
	target_locker.welded = source_locker.welded
	target_locker.locked = source_locker.locked
	target_locker.broken = source_locker.broken
	target_locker.has_cryo_gear = source_locker.has_cryo_gear
	if(!source_locker.has_cryo_gear)
		var/list/generated_contents = target_locker.generated_spawn_gear_contents ? target_locker.generated_spawn_gear_contents.Copy() : list()
		for(var/atom/movable/generated_item as anything in generated_contents)
			generated_item.forceMove(locker_turf)
			qdel(generated_item)
		target_locker.generated_spawn_gear_contents = list()
	target_locker.x_to_linked_spawn_turf = source_locker.x_to_linked_spawn_turf
	target_locker.y_to_linked_spawn_turf = source_locker.y_to_linked_spawn_turf
	if(target_locker.x_to_linked_spawn_turf || target_locker.y_to_linked_spawn_turf)
		target_locker.linked_spawn_turf = locate(target_locker.x + target_locker.x_to_linked_spawn_turf, target_locker.y + target_locker.y_to_linked_spawn_turf, target_locker.z)
	else
		target_locker.linked_spawn_turf = source_locker.linked_spawn_turf

	var/list/preserved_contents = source_locker.get_preserved_contents_for_ship_surface_swap()
	for(var/atom/movable/movable as anything in preserved_contents)
		movable.forceMove(target_locker)

	var/list/discarded_generated_contents = source_locker.generated_spawn_gear_contents ? source_locker.generated_spawn_gear_contents.Copy() : list()
	for(var/atom/movable/generated_item as anything in discarded_generated_contents)
		if(QDELETED(generated_item) || generated_item.loc != source_locker)
			continue
		qdel(generated_item)
	source_locker.generated_spawn_gear_contents = list()
	target_locker.update_icon()
	qdel(source_locker)
	return target_locker
