/// UI DTO for one template entry in the future preset selection interface.
/// Skeleton stage: presentation metadata only.
/datum/rto_support_ui_preset_entry
	var/template_id
	var/name = ""
	var/description = ""
	var/visibility_zone_name = ""
	var/visibility_zone_radius = 0
	var/visibility_zone_duration = 0
	var/visibility_zone_cooldown = 0
	var/list/actions = list()

/// Converts the DTO into a list for a future TGUI layer.
/// Skeleton stage: intentionally returns an empty list.
/datum/rto_support_ui_preset_entry/proc/to_list()
	return list()

/// UI DTO for one support action entry.
/// Skeleton stage: presentation metadata only.
/datum/rto_support_ui_action_entry
	var/action_id
	var/name = ""
	var/description = ""
	var/dispatch_key
	var/scatter = 0
	var/shared_cooldown = 0
	var/personal_cooldown = 0
	var/requires_visibility_zone = TRUE

/// Converts the DTO into a list for a future TGUI layer.
/// Skeleton stage: intentionally returns an empty list.
/datum/rto_support_ui_action_entry/proc/to_list()
	return list()
