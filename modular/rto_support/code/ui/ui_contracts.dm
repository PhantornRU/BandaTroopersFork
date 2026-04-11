/// UI DTO for one template entry in the preset selection interface.
/datum/rto_support_ui_preset_entry
	var/template_id
	var/name = ""
	var/description = ""
	var/role_summary = ""
	var/targeting_summary = ""
	var/restriction_summary = ""
	var/resource_mode = RTO_SUPPORT_RESOURCE_MODE_LEGACY
	var/pool_capacity = 0
	var/pool_starting_charges = 0
	var/pool_current_charges = 0
	var/pool_recharge_interval = 0
	var/pool_recharge_amount = 0
	var/pool_auto_recharge = TRUE
	var/pool_manual_only = FALSE
	var/pool_next_recharge_in = 0
	var/support_package_lockout = 0
	var/requires_visibility_zone = TRUE
	var/visibility_zone_name = ""
	var/visibility_zone_type = ""
	var/visibility_zone_radius = 0
	var/visibility_zone_duration = 0
	var/visibility_zone_cooldown = 0
	var/visibility_zone_cooldown_solo = 0
	var/visibility_zone_cooldown_current = 0
	var/solo_zone_cooldown_available = FALSE
	var/solo_zone_cooldown_active = FALSE
	var/visibility_altitude_requirement = RTO_SUPPORT_ALTITUDE_ANY
	var/list/actions = list()

/// Converts the DTO into a list for the preset TGUI.
/datum/rto_support_ui_preset_entry/proc/to_list()
	return list(
		"template_id" = template_id,
		"name" = name,
		"description" = description,
		"role_summary" = role_summary,
		"targeting_summary" = targeting_summary,
		"restriction_summary" = restriction_summary,
		"resource_mode" = resource_mode,
		"pool_capacity" = round(pool_capacity),
		"pool_starting_charges" = round(pool_starting_charges),
		"pool_current_charges" = round(pool_current_charges),
		"pool_recharge_interval" = round(pool_recharge_interval / 10),
		"pool_recharge_amount" = round(pool_recharge_amount),
		"pool_auto_recharge" = !!pool_auto_recharge,
		"pool_manual_only" = !!pool_manual_only,
		"pool_next_recharge_in" = round(pool_next_recharge_in / 10),
		"support_package_lockout" = round(support_package_lockout / 10),
		"requires_visibility_zone" = requires_visibility_zone,
		"visibility_zone_name" = visibility_zone_name,
		"visibility_zone_type" = visibility_zone_type,
		"visibility_zone_radius" = round(visibility_zone_radius),
		"visibility_zone_duration" = round(visibility_zone_duration / 10),
		"visibility_zone_cooldown" = round(visibility_zone_cooldown / 10),
		"visibility_zone_cooldown_solo" = round(visibility_zone_cooldown_solo / 10),
		"visibility_zone_cooldown_current" = round(visibility_zone_cooldown_current / 10),
		"solo_zone_cooldown_available" = !!solo_zone_cooldown_available,
		"solo_zone_cooldown_active" = !!solo_zone_cooldown_active,
		"visibility_altitude_requirement" = visibility_altitude_requirement,
		"actions" = actions,
	)

/// UI DTO for one support action entry.
/datum/rto_support_ui_action_entry
	var/action_id
	var/name = ""
	var/description = ""
	var/dispatch_key
	var/scatter = 0
	var/shared_cooldown = 0
	var/personal_cooldown = 0
	var/support_pool_cost = 0
	var/personal_lockout = 0
	var/requires_visibility_zone = TRUE
	var/icon_state = null
	var/altitude_requirement = RTO_SUPPORT_ALTITUDE_ANY
	var/allow_closed_turf = TRUE

/// Converts the DTO into a list for the preset TGUI.
/datum/rto_support_ui_action_entry/proc/to_list()
	return list(
		"action_id" = action_id,
		"name" = name,
		"description" = description,
		"dispatch_key" = dispatch_key,
		"scatter" = scatter,
		"shared_cooldown" = round(shared_cooldown / 10),
		"personal_cooldown" = round(personal_cooldown / 10),
		"support_pool_cost" = round(support_pool_cost),
		"personal_lockout" = round(personal_lockout / 10),
		"requires_visibility_zone" = requires_visibility_zone,
		"icon_state" = icon_state,
		"altitude_requirement" = altitude_requirement,
		"allow_closed_turf" = allow_closed_turf,
	)
