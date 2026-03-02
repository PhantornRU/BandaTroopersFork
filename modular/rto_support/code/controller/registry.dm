/// Future registry for RTO support controllers.
/// Skeleton stage: intentionally does not track or create runtime objects.
/datum/rto_support_registry
	/// Future lookup storage keyed by owner identity.
	var/list/controllers = list()

/datum/rto_support_registry/Destroy()
	controllers = null
	return ..()

/// Returns a controller bound to a human.
/// Skeleton stage: intentionally returns null.
/datum/rto_support_registry/proc/get_controller(mob/living/carbon/human/human)
	return null

/// Ensures a controller exists for a human.
/// Skeleton stage: intentionally returns null.
/datum/rto_support_registry/proc/ensure_controller(mob/living/carbon/human/human)
	return null

/// Removes a controller bound to a human.
/// Skeleton stage: intentionally returns FALSE.
/datum/rto_support_registry/proc/remove_controller(mob/living/carbon/human/human)
	return FALSE

/// Clears all tracked controllers.
/// Skeleton stage: intentionally returns FALSE.
/datum/rto_support_registry/proc/clear_controllers()
	return FALSE
