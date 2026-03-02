/// Adapter that translates prepared requests into actual fire support execution.
/datum/rto_support_dispatch_service

/// Dispatches a prepared request through the adapter layer.
/datum/rto_support_dispatch_service/proc/dispatch_request(datum/rto_support_request/request)
	if(!request?.is_valid())
		return FALSE

	var/path_to_dispatch = request.dispatch_path
	if(!path_to_dispatch)
		path_to_dispatch = request.action_template?.fire_support_path
	if(!path_to_dispatch)
		return FALSE

	var/datum/fire_support/fire_support = new path_to_dispatch
	fire_support.enable_firesupport()
	fire_support.faction = request.owner.faction
	fire_support.scatter_range = request.scatter_override
	if(request.display_name)
		fire_support.name = request.display_name

	// The base fire support datums are singleton-oriented, so request-local instances
	// need explicit cleanup after their timers and delayed impacts are complete.
	QDEL_IN(fire_support, max(1 MINUTES, fire_support.cooldown_duration + fire_support.delay_to_impact))

	if(request.request_kind == RTO_SUPPORT_REQUEST_SUPPORT)
		new /obj/effect/overlay/temp/blinking_laser(request.target_turf)
		notify_ghosts(
			header = "RTO Support",
			message = "[request.owner] has called [request.display_name] at [request.target_turf.x],[request.target_turf.y],[request.target_turf.z].",
			source = request.target_turf,
			action = NOTIFY_JUMP
		)

	fire_support.initiate_fire_support(request.target_turf, request.owner)
	return TRUE
