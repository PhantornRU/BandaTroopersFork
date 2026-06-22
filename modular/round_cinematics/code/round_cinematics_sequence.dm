/datum/round_cinematics_sequence
	var/list/phases = list()

/datum/round_cinematics_sequence/proc/execute(datum/round_cinematics_session/session)
	if(!session || session.cleaned_up)
		return

	for(var/datum/round_cinematics_phase/phase as anything in phases)
		if(session.cleaned_up)
			break
		phase.play(session)
