/// Builds a hardcrit attribution suffix for admin logs.
/// Returns a string like " to <cause> with <source> from <attacker>" with safe fallbacks.
/mob/living/carbon/human/proc/format_hardcrit_attribution_suffix(attribution)
	var/datum/cause_data/cause_data = null
	if(istype(attribution, /datum/cause_data))
		cause_data = attribution
	else if(istext(attribution))
		cause_data = create_cause_data(attribution)
	else if(ismob(attribution))
		var/mob/M = attribution
		cause_data = create_cause_data(initial(M.name), M)
	else if(isatom(attribution))
		var/atom/A = attribution
		if(isobj(A))
			cause_data = create_cause_data(initial(A.name), null, A)
		else
			cause_data = create_cause_data(initial(A.name))

	var/cause_name = cause_data?.cause_name
	var/obj/source_obj = cause_data?.resolve_cause()
	var/mob/attacker = cause_data?.resolve_mob()

	var/cause_display = cause_name
	if(!cause_display && source_obj)
		cause_display = "[source_obj]"
	if(!cause_display)
		cause_display = "unknown causes"

	var/source_text = source_obj ? "[source_obj]" : null
	var/show_source = FALSE
	if(source_obj)
		if(cause_name)
			if(lowertext(cause_display) != lowertext(source_text))
				show_source = TRUE

	var/attacker_admin = null
	if(attacker)
		attacker_admin = key_name_admin(attacker)
		if(attacker.client)
			attacker_admin = SPAN_BOLDANNOUNCE(attacker_admin)
	else
		attacker_admin = "unknown source"

	var/suffix = " to [cause_display]"
	if(show_source)
		suffix += " with [source_text]"
	suffix += " from [attacker_admin]"

	return suffix
