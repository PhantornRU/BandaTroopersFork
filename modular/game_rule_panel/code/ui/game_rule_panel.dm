/client/proc/toggle_game_rule_panel()
	set name = "Game Rule Panel"
	set category = "Game Master"

	if(!check_rights(R_ADMIN))
		return

	var/datum/game_rule_state/rules = GLOB.game_rule_state
	if(src && rules)
		rules.open_panel(src)

/datum/game_rule_panel
	var/client/holder

/datum/game_rule_panel/New(client/using_client)
	holder = using_client
	var/datum/game_rule_state/rules = GLOB.game_rule_state
	if(rules && !(src in rules.open_panels))
		rules.open_panels += src
	. = ..()
	tgui_interact(holder.mob)

/datum/game_rule_panel/Destroy()
	var/datum/game_rule_state/rules = GLOB.game_rule_state
	if(rules)
		rules.open_panels -= src
	holder = null
	return ..()

/datum/game_rule_panel/ui_state(mob/user)
	return GLOB.admin_state

/datum/game_rule_panel/ui_status(mob/user, datum/ui_state/state)
	return UI_INTERACTIVE

/datum/game_rule_panel/tgui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "GameRulePanel", "Game Rule Panel")
		ui.set_autoupdate(TRUE)
		ui.open()

/datum/game_rule_panel/ui_data(mob/user)
	var/datum/game_rule_state/rules = GLOB.game_rule_state
	rules.ensure_fire_support_defaults_captured()
	var/list/fire_support_pool = rules.build_fire_support_pool_data()

	return list(
		"rto_support_enabled" = rules.rto_support_enabled,
		"support_underground_enabled" = rules.support_underground_enabled,
		"rto_shared_cooldown_multiplier" = rules.rto_shared_cooldown_multiplier,
		"rto_personal_cooldown_multiplier" = rules.rto_personal_cooldown_multiplier,
		"rto_support_resource_mode" = rules.get_rto_support_resource_mode(),
		"rto_charge_recharge_enabled" = rules.rto_charge_recharge_enabled,
		"rto_charge_recharge_multiplier" = rules.get_rto_charge_recharge_multiplier(),
		"rto_charge_capacity_multiplier" = rules.get_rto_charge_capacity_multiplier(),
		"rto_charge_manual_only" = rules.rto_charge_manual_only,
		"rto_template_slot_count" = rules.get_rto_template_slot_count(),
		"rto_template_slot_count_cap" = rules.get_rto_template_slot_count_cap(),
		"rto_template_reset_minutes" = rules.get_rto_template_reset_minutes(),
		"rto_active_players" = rules.build_active_rto_charge_admin_data(),
		"fire_support_enabled" = rules.fire_support_enabled,
		"fire_support_points" = rules.build_fire_support_points_data(),
		"fire_support_enabled_entries" = fire_support_pool["enabled"],
		"fire_support_disabled_entries" = fire_support_pool["disabled"],
		"player_survival_enabled" = rules.player_survival_enabled,
		"player_survival_crit_grace_seconds" = rules.player_survival_crit_grace_seconds,
		"player_survival_antigib_enabled" = rules.player_survival_antigib_enabled,
		"player_survival_antigib_limb_loss_chance" = rules.player_survival_antigib_limb_loss_chance,
	)

/datum/game_rule_panel/ui_close(mob/user)
	qdel(src)

/datum/game_rule_panel/proc/log_rule_change(mob/user, message)
	if(!length(message))
		return FALSE

	var/log_message = "[key_name_admin(user)] [message]"
	message_admins(log_message)
	log_admin(log_message)
	return TRUE

/datum/game_rule_panel/proc/get_target_rto_controller(list/params)
	var/target_ckey = ckey(params["target_ckey"])
	if(!length(target_ckey))
		return null
	return GLOB.rto_support_registry?.find_controller_by_ckey(target_ckey)

/datum/game_rule_panel/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	if(!check_rights(R_ADMIN))
		return FALSE

	var/mob/user = ui?.user
	var/datum/game_rule_state/rules = GLOB.game_rule_state
	var/updated = FALSE

	switch(action)
		if("set_rto_support_enabled")
			var/enabled = !!text2num(params["enabled"])
			if(rules.rto_support_enabled == enabled)
				return FALSE
			rules.rto_support_enabled = enabled
			GLOB.rto_support_registry?.propagate_rules_update()
			log_rule_change(user, "set RTO Support to [enabled ? "enabled" : "disabled"] in Game Rule Panel.")
			updated = TRUE

		if("set_support_underground_enabled")
			var/enabled = !!text2num(params["enabled"])
			if(rules.support_underground_enabled == enabled)
				return FALSE
			rules.support_underground_enabled = enabled
			GLOB.rto_support_registry?.propagate_rules_update()
			log_rule_change(user, "set underground support to [enabled ? "enabled" : "disabled"] in Game Rule Panel.")
			updated = TRUE

		if("set_rto_shared_multiplier")
			var/new_value = rules.sanitize_multiplier(text2num(params["value"]))
			if(rules.rto_shared_cooldown_multiplier == new_value)
				return FALSE
			rules.rto_shared_cooldown_multiplier = new_value
			GLOB.rto_support_registry?.propagate_rules_update()
			log_rule_change(user, "set RTO shared cooldown multiplier to [new_value].")
			updated = TRUE

		if("set_rto_personal_multiplier")
			var/new_value = rules.sanitize_multiplier(text2num(params["value"]))
			if(rules.rto_personal_cooldown_multiplier == new_value)
				return FALSE
			rules.rto_personal_cooldown_multiplier = new_value
			GLOB.rto_support_registry?.propagate_rules_update()
			log_rule_change(user, "set RTO personal cooldown multiplier to [new_value].")
			updated = TRUE

		if("set_rto_support_resource_mode")
			var/new_value = rules.sanitize_rto_support_resource_mode(params["value"])
			if(rules.rto_support_resource_mode == new_value)
				return FALSE
			rules.rto_support_resource_mode = new_value
			GLOB.rto_support_registry?.propagate_rules_update()
			log_rule_change(user, "set RTO support resource mode to [new_value].")
			updated = TRUE

		if("set_rto_charge_recharge_enabled")
			var/enabled = !!text2num(params["enabled"])
			if(rules.rto_charge_recharge_enabled == enabled)
				return FALSE
			rules.rto_charge_recharge_enabled = enabled
			GLOB.rto_support_registry?.propagate_rules_update()
			log_rule_change(user, "set RTO charge auto-recharge to [enabled ? "enabled" : "disabled"].")
			updated = TRUE

		if("set_rto_charge_recharge_multiplier")
			var/new_value = rules.sanitize_multiplier(text2num(params["value"]))
			if(rules.rto_charge_recharge_multiplier == new_value)
				return FALSE
			rules.rto_charge_recharge_multiplier = new_value
			GLOB.rto_support_registry?.propagate_rules_update()
			log_rule_change(user, "set RTO charge recharge multiplier to [new_value].")
			updated = TRUE

		if("set_rto_charge_capacity_multiplier")
			var/new_value = rules.sanitize_multiplier(text2num(params["value"]))
			if(rules.rto_charge_capacity_multiplier == new_value)
				return FALSE
			rules.rto_charge_capacity_multiplier = new_value
			GLOB.rto_support_registry?.propagate_rules_update()
			log_rule_change(user, "set RTO charge capacity multiplier to [new_value].")
			updated = TRUE

		if("set_rto_charge_manual_only")
			var/enabled = !!text2num(params["enabled"])
			if(rules.rto_charge_manual_only == enabled)
				return FALSE
			rules.rto_charge_manual_only = enabled
			GLOB.rto_support_registry?.propagate_rules_update()
			log_rule_change(user, "set RTO charge manual-only mode to [enabled ? "enabled" : "disabled"].")
			updated = TRUE

		if("set_rto_template_slot_count")
			var/new_value = rules.sanitize_rto_template_slot_count(text2num(params["value"]))
			if(rules.rto_template_slot_count == new_value)
				return FALSE
			rules.rto_template_slot_count = new_value
			GLOB.rto_support_registry?.propagate_rules_update()
			log_rule_change(user, "set RTO package slot count to [new_value].")
			updated = TRUE

		if("set_rto_template_reset_minutes")
			var/new_value = rules.sanitize_rto_template_reset_minutes(text2num(params["value"]))
			if(rules.rto_template_reset_minutes == new_value)
				return FALSE
			rules.rto_template_reset_minutes = new_value
			GLOB.rto_support_registry?.propagate_rules_update()
			log_rule_change(user, "set RTO package reset delay to [new_value] minutes.")
			updated = TRUE

		if("reset_rto_rules")
			rules.reset_rto_rules()
			GLOB.rto_support_registry?.propagate_rules_update()
			log_rule_change(user, "reset RTO and underground support Game Rule Panel settings to defaults.")
			updated = TRUE

		if("set_rto_player_pool_current_charges")
			var/datum/rto_support_controller/controller = get_target_rto_controller(params)
			var/template_id = params["template_id"]
			var/new_value = text2num(params["value"])
			if(!controller?.set_template_pool_current_charges(template_id, new_value, user?.ckey))
				return FALSE
			log_rule_change(user, "set RTO charges for [controller.get_owner_display_name()] ([controller.get_owner_ckey()]) package [template_id] to [round(new_value)].")
			updated = TRUE

		if("remove_rto_player_template")
			var/datum/rto_support_controller/controller = get_target_rto_controller(params)
			var/template_id = params["template_id"]
			if(!controller?.remove_selected_template(template_id, user?.ckey))
				return FALSE
			log_rule_change(user, "removed RTO package [template_id] from [controller.get_owner_display_name()] ([controller.get_owner_ckey()]).")
			updated = TRUE

		if("adjust_rto_player_pool_current_charges")
			var/datum/rto_support_controller/controller = get_target_rto_controller(params)
			var/template_id = params["template_id"]
			var/delta = text2num(params["value"])
			if(!controller?.adjust_template_pool_current_charges(template_id, delta, user?.ckey))
				return FALSE
			log_rule_change(user, "[delta >= 0 ? "adjusted" : "reduced"] RTO charges for [controller.get_owner_display_name()] ([controller.get_owner_ckey()]) package [template_id] by [round(delta)].")
			updated = TRUE

		if("set_rto_player_pool_capacity")
			var/datum/rto_support_controller/controller = get_target_rto_controller(params)
			var/template_id = params["template_id"]
			var/new_value = text2num(params["value"])
			if(!controller?.set_template_pool_capacity(template_id, new_value, user?.ckey))
				return FALSE
			log_rule_change(user, "set RTO charge pool capacity for [controller.get_owner_display_name()] ([controller.get_owner_ckey()]) package [template_id] to [round(new_value)].")
			updated = TRUE

		if("set_rto_player_pool_auto_recharge")
			var/datum/rto_support_controller/controller = get_target_rto_controller(params)
			var/template_id = params["template_id"]
			var/enabled = !!text2num(params["enabled"])
			if(!controller?.set_template_pool_auto_recharge(template_id, enabled, user?.ckey))
				return FALSE
			log_rule_change(user, "set RTO auto-recharge for [controller.get_owner_display_name()] ([controller.get_owner_ckey()]) package [template_id] to [enabled ? "enabled" : "disabled"].")
			updated = TRUE

		if("set_rto_player_pool_manual_only")
			var/datum/rto_support_controller/controller = get_target_rto_controller(params)
			var/template_id = params["template_id"]
			var/enabled = !!text2num(params["enabled"])
			if(!controller?.set_template_pool_manual_only(template_id, enabled, user?.ckey))
				return FALSE
			log_rule_change(user, "set RTO manual-only mode for [controller.get_owner_display_name()] ([controller.get_owner_ckey()]) package [template_id] to [enabled ? "enabled" : "disabled"].")
			updated = TRUE

		if("reset_rto_player_pool")
			var/datum/rto_support_controller/controller = get_target_rto_controller(params)
			var/template_id = params["template_id"]
			if(!controller?.reset_template_pool_to_defaults(template_id, user?.ckey))
				return FALSE
			log_rule_change(user, "reset RTO charge pool overrides for [controller.get_owner_display_name()] ([controller.get_owner_ckey()]) package [template_id].")
			updated = TRUE

		if("refill_rto_player_pools")
			var/datum/rto_support_controller/controller = get_target_rto_controller(params)
			if(!controller?.refill_all_template_pools(user?.ckey))
				return FALSE
			log_rule_change(user, "refilled all RTO charge pools for [controller.get_owner_display_name()] ([controller.get_owner_ckey()]).")
			updated = TRUE

		if("empty_rto_player_pools")
			var/datum/rto_support_controller/controller = get_target_rto_controller(params)
			if(!controller?.empty_all_template_pools(user?.ckey))
				return FALSE
			log_rule_change(user, "emptied all RTO charge pools for [controller.get_owner_display_name()] ([controller.get_owner_ckey()]).")
			updated = TRUE

		if("set_rto_player_pools_auto_recharge")
			var/datum/rto_support_controller/controller = get_target_rto_controller(params)
			var/enabled = !!text2num(params["enabled"])
			if(!controller?.set_all_template_pools_auto_recharge(enabled, user?.ckey))
				return FALSE
			log_rule_change(user, "set auto-recharge for all RTO charge pools of [controller.get_owner_display_name()] ([controller.get_owner_ckey()]) to [enabled ? "enabled" : "disabled"].")
			updated = TRUE

		if("set_rto_player_pools_manual_only")
			var/datum/rto_support_controller/controller = get_target_rto_controller(params)
			var/enabled = !!text2num(params["enabled"])
			if(!controller?.set_all_template_pools_manual_only(enabled, user?.ckey))
				return FALSE
			log_rule_change(user, "set manual-only mode for all RTO charge pools of [controller.get_owner_display_name()] ([controller.get_owner_ckey()]) to [enabled ? "enabled" : "disabled"].")
			updated = TRUE

		if("set_player_survival_enabled")
			var/enabled = !!text2num(params["enabled"])
			if(rules.player_survival_enabled == enabled)
				return FALSE
			rules.player_survival_enabled = enabled
			log_rule_change(user, "set Save Before Death to [enabled ? "enabled" : "disabled"] in Game Rule Panel.")
			updated = TRUE

		if("set_player_survival_crit_grace_seconds")
			var/new_value = rules.sanitize_nonnegative_integer(text2num(params["value"]), 15)
			if(rules.player_survival_crit_grace_seconds == new_value)
				return FALSE
			rules.player_survival_crit_grace_seconds = new_value
			log_rule_change(user, "set Critical Grace Duration to [new_value] seconds in Game Rule Panel.")
			updated = TRUE

		if("set_player_survival_antigib_enabled")
			var/enabled = !!text2num(params["enabled"])
			if(rules.player_survival_antigib_enabled == enabled)
				return FALSE
			rules.player_survival_antigib_enabled = enabled
			log_rule_change(user, "set Anti-Gib Fallback to [enabled ? "enabled" : "disabled"] in Game Rule Panel.")
			updated = TRUE

		if("set_player_survival_antigib_limb_loss_chance")
			var/new_value = rules.sanitize_probability(text2num(params["value"]), 30)
			if(rules.player_survival_antigib_limb_loss_chance == new_value)
				return FALSE
			rules.player_survival_antigib_limb_loss_chance = new_value
			log_rule_change(user, "set Anti-Gib limb loss chance to [new_value]% in Game Rule Panel.")
			updated = TRUE

		if("reset_player_survival_rules")
			rules.reset_player_survival_rules()
			log_rule_change(user, "reset Player Survival Game Rule Panel settings to defaults.")
			updated = TRUE

		if("set_fire_support_enabled")
			var/enabled = !!text2num(params["enabled"])
			if(rules.fire_support_enabled == enabled)
				return FALSE
			rules.fire_support_enabled = enabled
			log_rule_change(user, "set Fire Support to [enabled ? "enabled" : "disabled"] in Game Rule Panel.")
			updated = TRUE

		if("grant_fire_support_points")
			var/faction = params["faction"]
			var/amount = text2num(params["amount"])
			if(!rules.grant_fire_support_points(faction, amount))
				return FALSE
			log_rule_change(user, "granted [round(amount)] Fire Support points to [faction].")
			updated = TRUE

		if("set_fire_support_type_enabled")
			var/fire_support_type = params["type_id"]
			var/enabled = !!text2num(params["enabled"])
			if(!rules.set_fire_support_type_enabled(fire_support_type, enabled))
				return FALSE
			var/datum/fire_support/fire_support_option = GLOB.fire_support_types[fire_support_type]
			log_rule_change(user, "[enabled ? "enabled" : "disabled"] [fire_support_option ? initial(fire_support_option.name) : fire_support_type] Fire Support.")
			updated = TRUE

		if("reset_fire_support_rules")
			rules.reset_fire_support_rules()
			log_rule_change(user, "reset Fire Support Game Rule Panel settings to defaults.")
			updated = TRUE

	if(updated)
		rules.update_panel_uis()
	return updated
