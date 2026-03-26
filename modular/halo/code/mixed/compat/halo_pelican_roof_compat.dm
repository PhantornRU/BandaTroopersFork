/datum/roof_master_node/pelican
	var/list/observers_under = list()

/datum/roof_master_node/pelican/Destroy(force, ...)
	for(var/mob/dead/observer/ghost as anything in observers_under.Copy())
		remove_observer_under_roof(ghost)
	return ..()

/datum/roof_master_node/pelican/proc/add_observer_under_roof(mob/dead/observer/ghost)
	if(ghost in observers_under)
		return
	observers_under += ghost
	RegisterSignal(ghost, COMSIG_PARENT_QDELETING, PROC_REF(remove_observer_under_roof))
	RegisterSignal(ghost, COMSIG_MOB_LOGGED_IN, PROC_REF(add_observer_client))
	RegisterSignal(ghost, COMSIG_GHOST_MOVED, PROC_REF(check_observer_under_roof))

	if(ghost.client)
		add_observer_client(ghost)

/datum/roof_master_node/pelican/proc/add_observer_client(mob/dead/observer/ghost)
	SIGNAL_HANDLER
	if(!ghost?.client)
		return
	for(var/obj/structure/roof/roof in connected_roof)
		ghost.client.images -= roof.normal_image
		ghost.client.images += roof.under_image

/datum/roof_master_node/pelican/proc/remove_observer_under_roof(mob/dead/observer/ghost)
	SIGNAL_HANDLER
	if(ghost?.client)
		for(var/obj/structure/roof/roof in connected_roof)
			ghost.client.images -= roof.under_image
			roof.add_default_image(SSdcs, ghost)
	observers_under -= ghost
	UnregisterSignal(ghost, list(
		COMSIG_PARENT_QDELETING,
		COMSIG_MOB_LOGGED_IN,
		COMSIG_GHOST_MOVED,
	))

/datum/roof_master_node/pelican/proc/check_observer_under_roof(mob/dead/observer/ghost, turf/target_turf)
	SIGNAL_HANDLER
	for(var/obj/effect/roof_node/roof in connected_nodes)
		if(target_turf == roof.loc)
			return
	remove_observer_under_roof(ghost)

/obj/structure/roof/pelican_roof/LateInitialize()
	if(linked_master)
		return
	for(var/direction in CARDINAL_ALL_DIRS)
		for(var/obj/structure/roof/roof in get_step(src, direction))
			if(roof.linked_master)
				roof.linked_master.connect(loc)
				return
	var/datum/roof_master_node/pelican/roof_master_node = new(loc)
	roof_master_node.connect(loc)

/obj/effect/roof_node/pelican/Initialize()
	. = ..()
	var/turf/source_turf = get_turf(src)
	if(source_turf)
		RegisterSignal(source_turf, COMSIG_TURF_ENTERED, PROC_REF(on_turf_entered))

/obj/effect/roof_node/pelican/Destroy(force, ...)
	var/turf/source_turf = get_turf(src)
	if(source_turf)
		UnregisterSignal(source_turf, COMSIG_TURF_ENTERED)
	return ..()

/obj/effect/roof_node/pelican/proc/on_turf_entered(turf/source, atom/movable/subject)
	SIGNAL_HANDLER
	if(!isobserver(subject) || !istype(linked_master, /datum/roof_master_node/pelican))
		return
	var/datum/roof_master_node/pelican/master = linked_master
	master.add_observer_under_roof(subject)
