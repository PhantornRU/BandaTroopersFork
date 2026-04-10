GLOBAL_DATUM_INIT(game_rule_state, /datum/game_rule_state, new)

#define GAME_RULE_RTO_DEFAULT_TEMPLATE_SLOT_COUNT 2
#define GAME_RULE_RTO_DEFAULT_TEMPLATE_RESET_MINUTES 60
#define GAME_RULE_RTO_RESOURCE_MODE_LEGACY "legacy_cooldown"
#define GAME_RULE_RTO_RESOURCE_MODE_HYBRID "hybrid"
#define GAME_RULE_RTO_RESOURCE_MODE_CHARGES "charges"
#define GAME_RULE_RTO_DEFAULT_RESOURCE_MODE GAME_RULE_RTO_RESOURCE_MODE_CHARGES
#define GAME_RULE_PLAYER_SURVIVAL_DEFAULT_CRIT_GRACE_SECONDS 15
#define GAME_RULE_PLAYER_SURVIVAL_DEFAULT_ANTIGIB_LIMB_LOSS_CHANCE 30

/datum/game_rule_state
	var/rto_support_enabled = TRUE
	var/support_underground_enabled = TRUE
	var/rto_shared_cooldown_multiplier = 1
	var/rto_personal_cooldown_multiplier = 1
	var/rto_support_resource_mode = GAME_RULE_RTO_DEFAULT_RESOURCE_MODE
	var/rto_charge_recharge_enabled = TRUE
	var/rto_charge_recharge_multiplier = 1
	var/rto_charge_capacity_multiplier = 1
	var/rto_charge_manual_only = FALSE
	var/rto_template_slot_count = GAME_RULE_RTO_DEFAULT_TEMPLATE_SLOT_COUNT
	var/rto_template_reset_minutes = GAME_RULE_RTO_DEFAULT_TEMPLATE_RESET_MINUTES
	var/fire_support_enabled = TRUE
	var/player_survival_enabled = TRUE
	var/player_survival_crit_grace_seconds = GAME_RULE_PLAYER_SURVIVAL_DEFAULT_CRIT_GRACE_SECONDS
	var/player_survival_antigib_enabled = TRUE
	var/player_survival_antigib_limb_loss_chance = GAME_RULE_PLAYER_SURVIVAL_DEFAULT_ANTIGIB_LIMB_LOSS_CHANCE
	var/list/open_panels = list()
	var/fire_support_defaults_captured = FALSE
	var/list/fire_support_default_points = list()
	var/list/fire_support_default_availability = list()

/datum/game_rule_state/proc/cleanup_open_panels()
	for(var/i = length(open_panels), i >= 1, i--)
		var/datum/game_rule_panel/panel = open_panels[i]
		if(panel && !QDELETED(panel) && panel.holder)
			continue
		open_panels.Cut(i, i + 1)
	return TRUE

/datum/game_rule_state/proc/find_open_panel(client/using_client)
	if(!using_client)
		return null

	cleanup_open_panels()

	for(var/datum/game_rule_panel/panel as anything in open_panels)
		if(panel?.holder == using_client)
			return panel
	return null

/datum/game_rule_state/proc/open_panel(client/using_client)
	if(!using_client)
		return null

	var/datum/game_rule_panel/panel = find_open_panel(using_client)
	if(panel)
		panel.tgui_interact(using_client.mob)
		return panel

	return new /datum/game_rule_panel(using_client)

/datum/game_rule_state/proc/update_panel_uis()
	cleanup_open_panels()
	for(var/datum/game_rule_panel/panel as anything in open_panels)
		SStgui.update_uis(panel)
	return TRUE

/datum/game_rule_state/proc/sanitize_multiplier(value)
	if(!isnum(value))
		return 1
	return clamp(round(value, 0.1), 0.1, 10)

/datum/game_rule_state/proc/get_rto_template_slot_count_cap()
	var/list/template_catalog = GLOB.rto_support_registry?.get_template_catalog()
	return max(1, length(template_catalog))

/datum/game_rule_state/proc/sanitize_rto_template_slot_count(value)
	var/slot_cap = get_rto_template_slot_count_cap()
	if(!isnum(value))
		return clamp(round(GAME_RULE_RTO_DEFAULT_TEMPLATE_SLOT_COUNT), 1, slot_cap)
	return clamp(round(value), 1, slot_cap)

/datum/game_rule_state/proc/sanitize_rto_template_reset_minutes(value)
	return sanitize_nonnegative_integer(value, GAME_RULE_RTO_DEFAULT_TEMPLATE_RESET_MINUTES)

/datum/game_rule_state/proc/sanitize_rto_support_resource_mode(value)
	switch(value)
		if(GAME_RULE_RTO_RESOURCE_MODE_LEGACY, GAME_RULE_RTO_RESOURCE_MODE_HYBRID, GAME_RULE_RTO_RESOURCE_MODE_CHARGES)
			return value
	return GAME_RULE_RTO_DEFAULT_RESOURCE_MODE

/datum/game_rule_state/proc/get_rto_template_slot_count()
	return sanitize_rto_template_slot_count(rto_template_slot_count)

/datum/game_rule_state/proc/get_rto_template_reset_minutes()
	return sanitize_rto_template_reset_minutes(rto_template_reset_minutes)

/datum/game_rule_state/proc/get_rto_template_reset_delay()
	return get_rto_template_reset_minutes() * 1 MINUTES

/datum/game_rule_state/proc/get_rto_support_resource_mode()
	return sanitize_rto_support_resource_mode(rto_support_resource_mode)

/datum/game_rule_state/proc/get_rto_charge_recharge_multiplier()
	return sanitize_multiplier(rto_charge_recharge_multiplier)

/datum/game_rule_state/proc/get_rto_charge_capacity_multiplier()
	return sanitize_multiplier(rto_charge_capacity_multiplier)

/datum/game_rule_state/proc/sanitize_nonnegative_integer(value, default_value = 0)
	if(!isnum(value))
		return max(0, round(default_value))
	return max(0, round(value))

/datum/game_rule_state/proc/sanitize_probability(value, default_value = 0)
	if(!isnum(value))
		return clamp(round(default_value), 0, 100)
	return clamp(round(value), 0, 100)

/datum/game_rule_state/proc/ensure_fire_support_defaults_captured()
	if(fire_support_defaults_captured)
		return FALSE

	fire_support_default_points = list()
	for(var/faction in GLOB.fire_support_points)
		fire_support_default_points[faction] = GLOB.fire_support_points[faction]

	fire_support_default_availability = list()
	for(var/fire_support_type in GLOB.fire_support_types)
		var/datum/fire_support/fire_support_option = GLOB.fire_support_types[fire_support_type]
		if(!fire_support_option)
			continue
		fire_support_default_availability[fire_support_type] = !!(fire_support_option.fire_support_flags & FIRESUPPORT_AVAILABLE)

	fire_support_defaults_captured = TRUE
	return TRUE

/datum/game_rule_state/proc/reset_rto_rules()
	rto_support_enabled = TRUE
	support_underground_enabled = TRUE
	rto_shared_cooldown_multiplier = 1
	rto_personal_cooldown_multiplier = 1
	rto_support_resource_mode = GAME_RULE_RTO_DEFAULT_RESOURCE_MODE
	rto_charge_recharge_enabled = TRUE
	rto_charge_recharge_multiplier = 1
	rto_charge_capacity_multiplier = 1
	rto_charge_manual_only = FALSE
	rto_template_slot_count = GAME_RULE_RTO_DEFAULT_TEMPLATE_SLOT_COUNT
	rto_template_reset_minutes = GAME_RULE_RTO_DEFAULT_TEMPLATE_RESET_MINUTES
	return TRUE

/datum/game_rule_state/proc/reset_player_survival_rules()
	player_survival_enabled = TRUE
	player_survival_crit_grace_seconds = GAME_RULE_PLAYER_SURVIVAL_DEFAULT_CRIT_GRACE_SECONDS
	player_survival_antigib_enabled = TRUE
	player_survival_antigib_limb_loss_chance = GAME_RULE_PLAYER_SURVIVAL_DEFAULT_ANTIGIB_LIMB_LOSS_CHANCE
	return TRUE

/datum/game_rule_state/proc/reset_player_survival_for_new_round()
	reset_player_survival_rules()
	update_panel_uis()
	return TRUE

/datum/game_rule_state/proc/reset_fire_support_rules()
	ensure_fire_support_defaults_captured()
	fire_support_enabled = TRUE

	for(var/fire_support_type in GLOB.fire_support_types)
		var/datum/fire_support/fire_support_option = GLOB.fire_support_types[fire_support_type]
		if(!fire_support_option)
			continue
		if(fire_support_default_availability[fire_support_type])
			fire_support_option.enable_firesupport()
		else
			fire_support_option.disable()

	var/list/current_factions = list()
	for(var/fire_support_type in GLOB.fire_support_types)
		var/datum/fire_support/fire_support_option = GLOB.fire_support_types[fire_support_type]
		if(fire_support_option?.faction)
			current_factions |= fire_support_option.faction
	for(var/faction in GLOB.fire_support_points)
		current_factions |= faction

	for(var/faction in current_factions)
		GLOB.fire_support_points[faction] = fire_support_default_points[faction] || 0

	return TRUE

/datum/game_rule_state/proc/grant_fire_support_points(faction, amount)
	if(!length(faction))
		return FALSE
	if(!isnum(amount))
		return FALSE

	ensure_fire_support_defaults_captured()

	var/safe_amount = round(amount)
	if(safe_amount <= 0)
		return FALSE

	GLOB.fire_support_points[faction] = max(0, (GLOB.fire_support_points[faction] || 0) + safe_amount)
	return TRUE

/datum/game_rule_state/proc/set_fire_support_type_enabled(fire_support_type, enabled)
	if(!length(fire_support_type))
		return FALSE

	ensure_fire_support_defaults_captured()

	var/datum/fire_support/fire_support_option = GLOB.fire_support_types[fire_support_type]
	if(!fire_support_option)
		return FALSE

	if(enabled)
		fire_support_option.enable_firesupport()
	else
		fire_support_option.disable()
	return TRUE

/datum/game_rule_state/proc/get_fire_support_factions()
	var/list/factions = list()
	for(var/fire_support_type in GLOB.fire_support_types)
		var/datum/fire_support/fire_support_option = GLOB.fire_support_types[fire_support_type]
		if(fire_support_option?.faction)
			factions |= fire_support_option.faction
	for(var/faction in GLOB.fire_support_points)
		factions |= faction
	return sortList(factions)

/datum/game_rule_state/proc/build_fire_support_points_data()
	var/list/data = list()
	for(var/faction in get_fire_support_factions())
		data += list(list(
			"faction" = faction,
			"points" = GLOB.fire_support_points[faction] || 0,
		))
	return data

/datum/game_rule_state/proc/build_active_rto_charge_admin_data()
	return GLOB.rto_support_registry?.build_active_rto_charge_admin_data() || list()

/proc/cmp_game_rule_fire_support_entries(list/a, list/b)
	var/faction_a = a["faction"] || ""
	var/faction_b = b["faction"] || ""
	var/faction_compare = sorttext(faction_b, faction_a)
	if(faction_compare)
		return faction_compare
	return sorttext(b["name"] || "", a["name"] || "")

/datum/game_rule_state/proc/build_fire_support_pool_data()
	var/list/enabled = list()
	var/list/disabled = list()

	for(var/fire_support_type in GLOB.fire_support_types)
		var/datum/fire_support/fire_support_option = GLOB.fire_support_types[fire_support_type]
		if(!fire_support_option)
			continue

		var/list/entry = list(
			"type_id" = fire_support_type,
			"name" = initial(fire_support_option.name),
			"faction" = fire_support_option.faction,
			"cost" = fire_support_option.cost,
			"cooldown_duration" = round(fire_support_option.cooldown_duration / 10),
			"fire_support_firer" = fire_support_option.fire_support_firer,
		)

		if(fire_support_option.fire_support_flags & FIRESUPPORT_AVAILABLE)
			enabled += list(entry)
		else
			disabled += list(entry)

	sortTim(enabled, GLOBAL_PROC_REF(cmp_game_rule_fire_support_entries))
	sortTim(disabled, GLOBAL_PROC_REF(cmp_game_rule_fire_support_entries))

	return list(
		"enabled" = enabled,
		"disabled" = disabled,
	)

#undef GAME_RULE_RTO_DEFAULT_TEMPLATE_SLOT_COUNT
#undef GAME_RULE_RTO_DEFAULT_TEMPLATE_RESET_MINUTES
#undef GAME_RULE_RTO_RESOURCE_MODE_LEGACY
#undef GAME_RULE_RTO_RESOURCE_MODE_HYBRID
#undef GAME_RULE_RTO_RESOURCE_MODE_CHARGES
#undef GAME_RULE_RTO_DEFAULT_RESOURCE_MODE
#undef GAME_RULE_PLAYER_SURVIVAL_DEFAULT_CRIT_GRACE_SECONDS
#undef GAME_RULE_PLAYER_SURVIVAL_DEFAULT_ANTIGIB_LIMB_LOSS_CHANCE
