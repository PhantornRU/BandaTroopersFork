/// UI DTO for one template entry in the future preset selection interface.
/datum/rto_support_ui_preset_entry
	var/template_id
	var/name = ""
	var/description = ""
	var/visibility_zone_name = ""
	var/visibility_zone_type = ""
	var/visibility_zone_radius = 0
	var/visibility_zone_duration = 0
	var/visibility_zone_cooldown = 0
	var/list/actions = list()

/// Converts the DTO into a list for the preset TGUI.
/datum/rto_support_ui_preset_entry/proc/to_list()
	return list(
		"template_id" = template_id,
		"name" = name,
		"description" = description,
		"visibility_zone_name" = visibility_zone_name,
		"visibility_zone_type" = visibility_zone_type,
		"visibility_zone_radius" = visibility_zone_radius,
		"visibility_zone_duration" = round(visibility_zone_duration / 10),
		"visibility_zone_cooldown" = round(visibility_zone_cooldown / 10),
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
	var/requires_visibility_zone = TRUE
	var/icon_state = null

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
		"requires_visibility_zone" = requires_visibility_zone,
		"icon_state" = icon_state,
	)
