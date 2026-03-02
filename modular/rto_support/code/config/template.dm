/// Immutable configuration datum for one RTO support template.
/// Skeleton stage: metadata only.
/datum/rto_support_template
	/// Stable identifier used by future selection logic.
	var/template_id
	/// Display name shown to players.
	var/name = "RTO Support Template"
	/// Design description shown in UI and docs.
	var/description = ""
	/// Display name for the visibility sector action.
	var/visibility_zone_name = "Сектор наведения"
	/// Radius of the future visibility sector.
	var/visibility_zone_radius = 0
	/// Lifetime of the future visibility sector.
	var/visibility_zone_duration = 0
	/// Cooldown of the future visibility sector action.
	var/visibility_zone_cooldown = 0
	/// Category or family name for UI grouping.
	var/category = ""
	/// Immutable list of support action templates.
	var/list/action_templates = list()

/// Returns action templates bound to this support template.
/// Skeleton stage: intentionally returns an empty list.
/datum/rto_support_template/proc/get_action_templates()
	return list()

/// Builds a UI DTO for the future preset menu.
/// Skeleton stage: intentionally returns null.
/datum/rto_support_template/proc/build_ui_entry()
	return null
