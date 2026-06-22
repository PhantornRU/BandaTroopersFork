/datum/round_cinematics_affiliation
	/// Internal faction id (e.g. FACTION_MARINE)
	var/faction_id
	/// Display code: USCM / UNSC / ODST / W-Y / UPP / TWE / UNKNOWN
	var/display_code = "UNKNOWN"
	/// Human-readable display name
	var/display_name = "UNKNOWN"
	/// Unit name (e.g. "3rd Battalion 'Banda Troopers'")
	var/unit_name = ""
	/// Squad name if applicable
	var/squad_name = ""
	/// Ship name from SSmapping
	var/ship_name = ""
	/// Ground map name from SSmapping
	var/ground_map_name = ""
	/// Operation name from SSticker.mode
	var/operation_name = ""
	/// Logo text for header
	var/logo_text = "BW"
	/// Visual profile id to use
	var/visual_profile_id = "intro_uscm"

/// Resolve affiliation data for a human mob.
/// Returns a /datum/round_cinematics_affiliation with populated fields.
/proc/resolve_affiliation(mob/living/carbon/human/human)
	var/datum/round_cinematics_affiliation/aff = new()
	if(!istype(human))
		return aff

	aff.faction_id = human.faction

	// Map faction to display_code
	switch(human.faction)
		if(FACTION_MARINE)
			aff.display_code = "USCM"
			aff.display_name = "United States Colonial Marines"
			aff.unit_name = "3rd Bat. 'Banda Troopers'"
			aff.visual_profile_id = "intro_uscm"
		if(FACTION_UNSC)
			aff.display_code = "UNSC"
			aff.display_name = "United Nations Space Command"
			aff.unit_name = "UNSC FORCES"
			aff.visual_profile_id = "intro_unsc"
		if(FACTION_PMC)
			aff.display_code = "W-Y"
			aff.display_name = "Weyland-Yutani Corporation"
			aff.unit_name = "AZURE-15"
			aff.visual_profile_id = "intro_wy"
		if(FACTION_UPP)
			aff.display_code = "UPP"
			aff.display_name = "Union of Progressive Peoples"
			aff.unit_name = "RED DAWN"
			aff.visual_profile_id = "intro_uscm"
		if(FACTION_TWE)
			aff.display_code = "TWE"
			aff.display_name = "Three World Empire"
			aff.unit_name = "GAMMA TROOP"
			aff.visual_profile_id = "intro_uscm"
		else
			aff.display_code = "UNKNOWN"
			aff.display_name = "UNKNOWN FACTION"
			aff.unit_name = "UNKNOWN UNIT"
			aff.visual_profile_id = "intro_uscm"

	// ODST override: check if squad/job indicates ODST
	if(human.faction == FACTION_UNSC)
		if(human.assigned_squad && findtext(lowertext(human.assigned_squad.name), "odst"))
			aff.display_code = "ODST"
			aff.unit_name = "ORBITAL DROP SHOCK TROOPERS"
		else if(human.job && findtext(lowertext(human.job), "odst"))
			aff.display_code = "ODST"
			aff.unit_name = "ORBITAL DROP SHOCK TROOPERS"

	// Squad name
	if(human.assigned_squad)
		aff.squad_name = human.assigned_squad.name

	// Ship name from SSmapping
	if(SSmapping?.configs)
		var/datum/map_config/ship_config = SSmapping.configs[SHIP_MAP]
		if(ship_config?.map_name)
			aff.ship_name = ship_config.map_name

	// Ground map name from SSmapping
	if(SSmapping?.configs)
		var/datum/map_config/ground_config = SSmapping.configs[GROUND_MAP]
		if(ground_config?.map_name)
			aff.ground_map_name = ground_config.map_name

	// Operation name from SSticker.mode
	if(SSticker?.mode?.name)
		aff.operation_name = SSticker.mode.name

	// Logo text
	aff.logo_text = aff.display_code

	return aff
