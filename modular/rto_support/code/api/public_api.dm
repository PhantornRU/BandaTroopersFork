/// Returns the RTO support controller bound to a human.
/proc/get_rto_support_controller(mob/living/carbon/human/human)
	return GLOB.rto_support_registry?.get_controller(human)

/// Returns an existing controller or creates one.
/proc/ensure_rto_support_controller(mob/living/carbon/human/human)
	return GLOB.rto_support_registry?.ensure_controller(human)

/// Removes the controller bound to a human.
/proc/remove_rto_support_controller(mob/living/carbon/human/human)
	return GLOB.rto_support_registry?.remove_controller(human)
