/// Runtime state for one manual RTO laser designation.
/datum/rto_manual_designation
	var/mob/living/carbon/human/owner
	var/turf/target_turf
	var/marker_style = RTO_SUPPORT_MARKER_STATIC
	var/expires_at = 0
	var/obj/effect/overlay/rto_laser_marker/marker

/datum/rto_manual_designation/New(mob/living/carbon/human/new_owner, turf/new_target_turf, new_marker_style = RTO_SUPPORT_MARKER_STATIC, duration = RTO_SUPPORT_MANUAL_MARKER_DURATION)
	owner = new_owner
	target_turf = new_target_turf
	marker_style = new_marker_style
	. = ..()
	expires_at = world.time + max(1, duration)
	marker = spawn_rto_laser_marker(target_turf, marker_style, duration)

/datum/rto_manual_designation/Destroy()
	owner = null
	target_turf = null
	QDEL_NULL(marker)
	return ..()

/datum/rto_manual_designation/proc/is_active()
	return owner && target_turf && marker && !QDELETED(marker) && world.time < expires_at

/datum/rto_manual_designation/proc/expire()
	expires_at = world.time
	QDEL_NULL(marker)
	return TRUE

/proc/spawn_rto_laser_marker(turf/target_turf, marker_style = RTO_SUPPORT_MARKER_STATIC, duration = 10)
	if(!target_turf || QDELETED(target_turf))
		return null

	switch(marker_style)
		if(RTO_SUPPORT_MARKER_SLOW_BLINK)
			return new /obj/effect/overlay/rto_laser_marker/slow_blink(target_turf, duration)
		if(RTO_SUPPORT_MARKER_COORDINATE)
			return new /obj/effect/overlay/rto_laser_marker/coordinate(target_turf, duration)
		else
			return new /obj/effect/overlay/rto_laser_marker/static(target_turf, duration)
