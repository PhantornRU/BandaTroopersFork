/datum/modular_ship_platoon_profile/default/initialize_profile()
	if(platoon_type == /datum/squad/marine/alpha)
		family_types = list(
			/datum/squad/marine/alpha,
			/datum/squad/marine/bravo,
			/datum/squad/marine/charlie,
			/datum/squad/marine/delta,
		)
		family_secondary_types = list(
			/datum/squad/marine/bravo,
			/datum/squad/marine/charlie,
			/datum/squad/marine/delta,
		)

/datum/authority/branch/role/proc/get_default_ship_platoon_profile_datum(platoon_type)
	platoon_type = normalize_ship_platoon_type(platoon_type)
	if(!platoon_type)
		return null

	return new /datum/modular_ship_platoon_profile/default(platoon_type)
