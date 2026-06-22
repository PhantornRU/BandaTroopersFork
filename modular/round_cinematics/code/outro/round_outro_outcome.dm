/datum/round_cinematics_outcome
	var/id = ROUND_CINEMATICS_OUTCOME_AUTO
	var/title = "AUTO"
	var/detail = "UNDETERMINED OUTCOME"
	var/raw_result = null
	var/classification = ROUND_CINEMATICS_OUTCOME_INCONCLUSIVE
	var/is_override = FALSE

/datum/round_cinematics_outcome/New(id = ROUND_CINEMATICS_OUTCOME_AUTO, is_override = FALSE)
	..()
	src.id = id
	src.is_override = is_override
	switch(id)
		if(ROUND_CINEMATICS_OUTCOME_AUTO)
			title = "AUTO"
			detail = "AUTOMATIC DETERMINATION"
			classification = ROUND_CINEMATICS_OUTCOME_INCONCLUSIVE
		if(ROUND_CINEMATICS_OUTCOME_MARINE_VICTORY)
			title = "MARINE VICTORY"
			detail = "ADMIN OR STRUCTURED ENDING INDICATED MARINE VICTORY"
			classification = ROUND_CINEMATICS_OUTCOME_MARINE_VICTORY
		if(ROUND_CINEMATICS_OUTCOME_MARINE_DEFEAT)
			title = "MARINE DEFEAT"
			detail = "ADMIN OR STRUCTURED ENDING INDICATED MARINE DEFEAT"
			classification = ROUND_CINEMATICS_OUTCOME_MARINE_DEFEAT
		if(ROUND_CINEMATICS_OUTCOME_INCONCLUSIVE)
			title = "INCONCLUSIVE"
			detail = "MANUAL OR AUTOMATIC ENDING WITHOUT A CLEAR WINNER"
			classification = ROUND_CINEMATICS_OUTCOME_INCONCLUSIVE

/datum/round_cinematics_outcome/proc/copy()
	var/datum/round_cinematics_outcome/clone = new(id, is_override)
	clone.title = title
	clone.detail = detail
	clone.raw_result = raw_result
	clone.classification = classification
	return clone

/proc/round_cinematics_outcome_from_mode_result(result)
	var/datum/round_cinematics_outcome/outcome = new(ROUND_CINEMATICS_OUTCOME_AUTO, FALSE)
	outcome.raw_result = result
	outcome.title = round_cinematics_round_finished_label(result)
	outcome.detail = round_cinematics_safe_text(result, "UNDETERMINED OUTCOME")
	outcome.classification = round_cinematics_round_finished_classification(result)
	return outcome

/proc/resolve_round_outcome(datum/game_mode/mode)
	if(!mode)
		return new /datum/round_cinematics_outcome(ROUND_CINEMATICS_OUTCOME_INCONCLUSIVE, FALSE)
	if(!mode.round_finished)
		var/datum/round_cinematics_outcome/outcome = new(ROUND_CINEMATICS_OUTCOME_INCONCLUSIVE, FALSE)
		outcome.title = "ROUND NOT FINISHED"
		outcome.detail = "THE ROUND HAS NOT REACHED AN END STATE"
		return outcome
	return round_cinematics_outcome_from_mode_result(mode.round_finished)
