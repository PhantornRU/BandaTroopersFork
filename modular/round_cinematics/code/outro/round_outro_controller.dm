/datum/round_cinematics_session/outro
	var/datum/round_cinematics_outro_context/context

/datum/round_cinematics_session/outro/New(datum/round_cinematics_controller/controller, client/owner_client, datum/round_cinematics_outro_context/context, preview = FALSE)
	..(controller, owner_client?.mob, preview)
	client = owner_client
	src.context = context
	sequence = new /datum/round_cinematics_sequence/round_outro(context)
	completion_reason = "outro complete"
	skip_allowed_at = world.time
