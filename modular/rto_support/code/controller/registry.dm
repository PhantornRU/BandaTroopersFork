GLOBAL_DATUM_INIT(rto_support_registry, /datum/rto_support_registry, new)

/// Registry for RTO support controllers.
/datum/rto_support_registry
	/// Lookup storage keyed by owner identity.
	var/list/controllers = list()

/datum/rto_support_registry/Destroy()
	clear_controllers()
	controllers = null
	return ..()

/// Returns a controller bound to a human.
/datum/rto_support_registry/proc/get_controller(mob/living/carbon/human/human)
	if(!human)
		return null
	var/datum/rto_support_controller/controller = controllers[human]
	if(controller && !QDELETED(controller))
		return controller
	controllers -= human
	return null

/// Ensures a controller exists for a human.
/datum/rto_support_registry/proc/ensure_controller(mob/living/carbon/human/human)
	if(!human || QDELETED(human))
		return null
	if(human.job != JOB_SQUAD_RTO)
		return null
	var/datum/rto_support_controller/controller = get_controller(human)
	if(controller)
		controller.ensure_runtime()
		return controller
	controller = new(human)
	controllers[human] = controller
	RegisterSignal(human, COMSIG_PARENT_QDELETING, PROC_REF(handle_owner_deleted))
	controller.ensure_runtime()
	return controller

/// Removes a controller bound to a human.
/datum/rto_support_registry/proc/remove_controller(mob/living/carbon/human/human)
	if(!human)
		return FALSE
	var/datum/rto_support_controller/controller = controllers[human]
	controllers -= human
	if(controller)
		qdel(controller)
	UnregisterSignal(human, COMSIG_PARENT_QDELETING)
	return TRUE

/// Clears all tracked controllers.
/datum/rto_support_registry/proc/clear_controllers()
	if(!length(controllers))
		return FALSE
	for(var/mob/living/carbon/human/human as anything in controllers)
		remove_controller(human)
	return TRUE

/datum/rto_support_registry/proc/handle_owner_deleted(mob/living/carbon/human/human)
	SIGNAL_HANDLER
	remove_controller(human)
