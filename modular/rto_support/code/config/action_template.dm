/// Immutable configuration datum for one support action inside a template.
/// Skeleton stage: metadata only.
/datum/rto_support_action_template
	/// Stable identifier used by future runtime and UI layers.
	var/action_id
	/// Display name shown on the future action button.
	var/name = "RTO Support Action"
	/// Design description for UI and documentation.
	var/description = ""
	/// Adapter-facing key for future dispatch resolution.
	var/dispatch_key
	/// Future accuracy or deviation value.
	var/scatter = 0
	/// Future shared cooldown applied to the whole controller.
	var/shared_cooldown = 0
	/// Future personal cooldown applied to this action only.
	var/personal_cooldown = 0
	/// Whether the action requires an active visibility sector.
	var/requires_visibility_zone = TRUE
	/// Optional family or tag for UI grouping.
	var/category = ""

/// Builds a UI DTO for the future action list.
/// Skeleton stage: intentionally returns null.
/datum/rto_support_action_template/proc/build_ui_entry()
	return null
