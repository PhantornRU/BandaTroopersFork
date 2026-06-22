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
	var/visual_profile_id = "intro_universal"
	/// Header color for intro sequence
	var/header_color = "#33FF33"
	/// Accent color for intro sequence
	var/accent_color = "#33FF33"
	/// Header label (e.g. "CRYOGENIC REVIVAL SYSTEM")
	var/header_label = "CRYOGENIC REVIVAL SYSTEM"
	/// Footer label (e.g. "READY")
	var/footer_label = "READY"
	/// Boot sequence prefix (e.g. "USCM-TERMINAL")
	var/boot_prefix = "SYS-TERMINAL"
	/// Security classification label (e.g. "SECURE CHANNEL")
	var/security_label = "SECURE CHANNEL"
	/// Identity label for personal dossier (e.g. "USCM PERSONNEL FILE")
	var/identity_label = "SYSTEM PERSONNEL FILE"
	/// Manifest section label (e.g. "SQUAD MANIFEST")
	var/manifest_label = "UNIT MANIFEST"
	/// Deployment status line (e.g. "READY FOR DEPLOYMENT")
	var/deployment_label = "AWAITING DEPLOYMENT"
	/// Final intro line before fade-out (e.g. "SEMPER FI")
	var/final_intro_line = "STANDBY"

/// Build a universal, data-driven list of intro lines from affiliation fields.
/// Returns a list of strings; each non-empty field produces one line.
/// Callers do not need to know which fields exist — the sequence handles all.
/datum/round_cinematics_affiliation/proc/build_intro_lines()
	var/list/lines = list()
	if(length(display_code))
		lines += "[display_code] — [display_name]"
	if(length(unit_name))
		lines += "ЧАСТЬ: [unit_name]"
	if(length(squad_name))
		lines += "ОТРЯД: [squad_name]"
	if(length(ship_name))
		lines += "КОРАБЛЬ: [ship_name]"
	if(length(ground_map_name))
		lines += "ЗОНА ОПЕРАЦИИ: [ground_map_name]"
	if(length(operation_name))
		lines += "ОПЕРАЦИЯ: [operation_name]"
	return lines

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
			aff.visual_profile_id = "intro_universal"
			aff.header_color = "#33FF33"
			aff.accent_color = "#33FF33"
			aff.logo_text = "USCM"
			aff.header_label = "UNITED STATES COLONIAL MARINE CORPS"
			aff.boot_prefix = "USCM-TERMINAL"
			aff.security_label = "SECURE CHANNEL"
			aff.identity_label = "USCM PERSONNEL FILE"
			aff.manifest_label = "SQUAD MANIFEST"
			aff.deployment_label = "READY FOR DEPLOYMENT"
			aff.final_intro_line = "SEMPER FI"
		if(FACTION_UNSC)
			aff.display_code = "UNSC"
			aff.display_name = "United Nations Space Command"
			aff.unit_name = "UNSC FORCES"
			aff.visual_profile_id = "intro_universal"
			aff.header_color = "#33CCFF"
			aff.accent_color = "#33CCFF"
			aff.logo_text = "UNSC"
			aff.header_label = "UNITED NATIONS SPACE COMMAND"
			aff.boot_prefix = "UNSC-TERMINAL"
			aff.security_label = "SECURE CHANNEL"
			aff.identity_label = "UNSC PERSONNEL FILE"
			aff.manifest_label = "UNIT MANIFEST"
			aff.deployment_label = "READY FOR DEPLOYMENT"
			aff.final_intro_line = "PER ARDUA AD ASTRA"
		if(FACTION_PMC)
			aff.display_code = "W-Y"
			aff.display_name = "Weyland-Yutani Corporation"
			aff.unit_name = "AZURE-15"
			aff.visual_profile_id = "intro_universal"
			aff.header_color = "#4488FF"
			aff.accent_color = "#4488FF"
			aff.logo_text = "W-Y"
			aff.header_label = "WEYLAND-YUTANI CORPORATION"
			aff.boot_prefix = "WY-TERMINAL"
			aff.security_label = "ENCRYPTED CHANNEL"
			aff.identity_label = "W-Y CONTRACTOR FILE"
			aff.manifest_label = "TEAM MANIFEST"
			aff.deployment_label = "CONTRACT ACTIVE"
			aff.final_intro_line = "BUILDING BETTER WORLDS"
		if(FACTION_UPP)
			aff.display_code = "UPP"
			aff.display_name = "UNION OF PROGRESSIVE PEOPLES"
			aff.unit_name = "RED DAWN"
			aff.visual_profile_id = "intro_universal"
			aff.header_color = "#FFAA44"
			aff.accent_color = "#FFAA44"
			aff.logo_text = "UPP"
			aff.header_label = "UNION OF PROGRESSIVE PEOPLES"
			aff.boot_prefix = "UPP-TERMINAL"
			aff.security_label = "SECURE CHANNEL"
			aff.identity_label = "UPP PERSONNEL FILE"
			aff.manifest_label = "UNIT MANIFEST"
			aff.deployment_label = "READY FOR DEPLOYMENT"
			aff.final_intro_line = "FOR THE UNION"
		if(FACTION_TWE)
			aff.display_code = "TWE"
			aff.display_name = "THREE WORLD EMPIRE"
			aff.unit_name = "GAMMA TROOP"
			aff.visual_profile_id = "intro_universal"
			aff.header_color = "#FFAA44"
			aff.accent_color = "#FFAA44"
			aff.logo_text = "TWE"
			aff.header_label = "THREE WORLD EMPIRE"
			aff.boot_prefix = "TWE-TERMINAL"
			aff.security_label = "SECURE CHANNEL"
			aff.identity_label = "TWE PERSONNEL FILE"
			aff.manifest_label = "UNIT MANIFEST"
			aff.deployment_label = "READY FOR DEPLOYMENT"
			aff.final_intro_line = "FOR THE EMPIRE"
		else
			aff.display_code = uppertext(human.faction) || "UNKNOWN"
			aff.display_name = uppertext(human.faction) || "UNKNOWN FACTION"
			aff.unit_name = "UNKNOWN UNIT"
			aff.visual_profile_id = "intro_universal"
			aff.header_color = "#FFAA44"
			aff.accent_color = "#FFAA44"
			aff.logo_text = "SYS"
			aff.header_label = "CRYOGENIC REVIVAL SYSTEM"
			aff.boot_prefix = "SYS-TERMINAL"
			aff.security_label = "SECURE CHANNEL"
			aff.identity_label = "SYSTEM PERSONNEL FILE"
			aff.manifest_label = "UNIT MANIFEST"
			aff.deployment_label = "AWAITING DEPLOYMENT"
			aff.final_intro_line = "STANDBY"

	// ODST override: check if squad/job indicates ODST
	if(human.faction == FACTION_UNSC)
		if(human.assigned_squad && findtext(lowertext(human.assigned_squad.name), "odst"))
			aff.display_code = "ODST"
			aff.display_name = "Orbital Drop Shock Troopers"
			aff.unit_name = "ORBITAL DROP SHOCK TROOPERS"
			aff.logo_text = "ODST"
			aff.header_label = "ORBITAL DROP SHOCK TROOPERS"
			aff.boot_prefix = "ODST-TERMINAL"
			aff.security_label = "SECURE CHANNEL"
			aff.identity_label = "ODST PERSONNEL FILE"
			aff.manifest_label = "SQUAD MANIFEST"
			aff.deployment_label = "READY FOR DROP"
			aff.final_intro_line = "FEET FIRST INTO HELL"
		else if(human.job && findtext(lowertext(human.job), "odst"))
			aff.display_code = "ODST"
			aff.display_name = "Orbital Drop Shock Troopers"
			aff.unit_name = "ORBITAL DROP SHOCK TROOPERS"
			aff.logo_text = "ODST"
			aff.header_label = "ORBITAL DROP SHOCK TROOPERS"
			aff.boot_prefix = "ODST-TERMINAL"
			aff.security_label = "SECURE CHANNEL"
			aff.identity_label = "ODST PERSONNEL FILE"
			aff.manifest_label = "SQUAD MANIFEST"
			aff.deployment_label = "READY FOR DROP"
			aff.final_intro_line = "FEET FIRST INTO HELL"

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
