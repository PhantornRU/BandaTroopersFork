/// Runtime representation of one active visibility sector.
/// Skeleton stage: structure only, no timers or game hooks.
/datum/rto_visibility_zone
	/// Human that owns the visibility sector.
	var/mob/living/carbon/human/owner
	/// Center turf of the future sector.
	var/turf/center_turf
	/// Radius used by future validation.
	var/radius = 0
	/// Duration of the future sector in deciseconds.
	var/duration = 0
	/// Future absolute expiration timestamp.
	var/expires_at = 0
	/// Template that created the sector.
	var/datum/rto_support_template/source_template

/datum/rto_visibility_zone/New(mob/living/carbon/human/new_owner, turf/new_center_turf)
	owner = new_owner
	center_turf = new_center_turf
	. = ..()

/datum/rto_visibility_zone/Destroy()
	owner = null
	center_turf = null
	source_template = null
	return ..()

/// Checks whether a turf belongs to the sector.
/// Skeleton stage: intentionally returns FALSE.
/datum/rto_visibility_zone/proc/contains_turf(turf/target_turf)
	return FALSE

/// Checks whether the sector is active.
/// Skeleton stage: intentionally returns FALSE.
/datum/rto_visibility_zone/proc/is_active()
	return FALSE

/// Expires the sector and performs future cleanup.
/// Skeleton stage: intentionally returns FALSE.
/datum/rto_visibility_zone/proc/expire()
	return FALSE
