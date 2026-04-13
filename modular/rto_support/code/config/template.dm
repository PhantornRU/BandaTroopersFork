/// Immutable configuration datum for one RTO support template.
/datum/rto_support_template
	/// Stable identifier used by selection logic and UI.
	var/template_id
	/// Display name shown to players.
	var/name = "RTO Support Template"
	/// Design description shown in the preset menu.
	var/description = ""
	/// Short gameplay summary shown in the preset menu.
	var/role_summary = ""
	/// Targeting summary shown in the preset menu.
	var/targeting_summary = ""
	/// Short restriction summary shown in the preset menu.
	var/restriction_summary = ""
	/// Runtime model for support actions inside this package.
	var/support_resource_mode = RTO_SUPPORT_RESOURCE_MODE_LEGACY
	/// Shared pool identifier; defaults to template_id when omitted.
	var/support_pool_id = null
	/// Max shared charges for package-wide support resource.
	var/support_pool_capacity = 0
	/// Initial charges when a runtime pool is created or reset.
	var/support_pool_starting_charges = 0
	/// Time between recharge ticks.
	var/support_pool_recharge_interval = 0
	/// Charges restored per recharge tick.
	var/support_pool_recharge_amount = 0
	/// Whether the pool should recharge automatically by default.
	var/support_pool_auto_recharge = TRUE
	/// Package-wide anti-spam lockout used by charge-based templates.
	var/support_package_lockout = 0
	/// Whether the template needs a visibility zone.
	var/requires_visibility_zone = TRUE
	/// Display name for the visibility sector action.
	var/visibility_zone_name = "Развернуть сектор наведения"
	/// Short description of the sector type for UI.
	var/visibility_zone_type = ""
	/// Radius of the visibility sector.
	var/visibility_zone_radius = 0
	/// Lifetime of the active visibility sector; only used when requires_visibility_zone = TRUE.
	var/visibility_zone_duration = 0
	/// Personal anti-spam delay before the same template can deploy its next visibility sector.
	var/visibility_zone_cooldown = 0
	/// Category or family name for UI grouping.
	var/category = ""
	/// Support profile families that may use this template.
	var/list/allowed_support_profiles = null
	/// Immutable list of action template instances.
	var/list/action_templates = list()
	/// Action template typepaths instantiated on New.
	var/list/action_template_types = list()
	/// Optional fire support payload played on successful sector deployment.
	var/visibility_support_path = null
	/// Altitude requirement for visibility zone deployment.
	var/visibility_altitude_requirement = RTO_SUPPORT_ALTITUDE_ANY
	/// Icon file used by the visibility zone action.
	var/visibility_action_icon_file = 'icons/mob/hud/actions.dmi'
	/// Icon state used by the visibility zone action.
	var/visibility_action_icon_state = "designator_one_weapon"
	/// Icon file used by all support actions from the package.
	var/support_action_icon_file = 'icons/mob/radial.dmi'
	/// Shared icon state used by all support actions from the package.
	var/support_action_icon_state = null
	/// Marker style used while placing the visibility zone.
	var/visibility_target_marker_style = RTO_SUPPORT_MARKER_SLOW_BLINK

/datum/rto_support_template/New()
	. = ..()
	action_templates = list()
	for(var/action_type in action_template_types)
		action_templates += new action_type

/datum/rto_support_template/Destroy()
	if(length(action_templates))
		for(var/datum/rto_support_action_template/action_template as anything in action_templates)
			qdel(action_template)
	action_templates = null
	action_template_types = null
	return ..()

/// Returns action templates bound to this support template.
/datum/rto_support_template/proc/get_action_templates()
	return action_templates.Copy()

/// Returns one action template by its stable identifier.
/datum/rto_support_template/proc/get_action_template(action_id)
	for(var/datum/rto_support_action_template/action_template as anything in action_templates)
		if(action_template.action_id == action_id)
			return action_template
	return null

/// Whether this template should be shown and accepted for a specific controller owner.
/datum/rto_support_template/proc/is_available_to(datum/rto_support_controller/controller)
	if(length(allowed_support_profiles))
		if(!(controller?.get_support_profile() in allowed_support_profiles))
			return FALSE
	return TRUE

/// Builds a UI DTO for the preset menu.
/datum/rto_support_template/proc/build_ui_entry(datum/rto_support_controller/controller = null)
	var/datum/rto_support_ui_preset_entry/entry = new
	var/has_runtime_pool = controller?.has_selected_template(template_id)
	entry.template_id = template_id
	entry.name = name
	entry.description = description
	entry.role_summary = role_summary
	entry.targeting_summary = targeting_summary
	entry.restriction_summary = restriction_summary
	entry.resource_mode = controller ? controller.get_template_support_resource_mode(src) : support_resource_mode
	entry.pool_capacity = controller ? controller.get_support_pool_capacity(src) : support_pool_capacity
	entry.pool_starting_charges = support_pool_starting_charges
	entry.pool_current_charges = has_runtime_pool ? controller.get_support_pool_current_charges(src) : support_pool_starting_charges
	entry.pool_recharge_interval = controller ? controller.get_support_pool_recharge_interval(src) : support_pool_recharge_interval
	entry.pool_recharge_amount = controller ? controller.get_support_pool_recharge_amount(src) : support_pool_recharge_amount
	entry.pool_auto_recharge = controller ? controller.is_support_pool_auto_recharge_enabled(src) : support_pool_auto_recharge
	entry.pool_manual_only = has_runtime_pool ? controller.is_support_pool_manual_only(src) : FALSE
	entry.pool_next_recharge_in = has_runtime_pool ? controller.get_support_pool_next_recharge_in(src) : 0
	entry.support_package_lockout = controller ? controller.get_effective_support_package_lockout(src) : support_package_lockout
	entry.requires_visibility_zone = requires_visibility_zone
	entry.visibility_zone_name = visibility_zone_name
	entry.visibility_zone_type = visibility_zone_type
	entry.visibility_zone_radius = visibility_zone_radius
	entry.visibility_zone_duration = visibility_zone_duration
	entry.visibility_zone_cooldown = visibility_zone_cooldown
	entry.visibility_zone_cooldown_solo = controller ? controller.get_solo_visibility_zone_cooldown(src) : max(0, round(visibility_zone_cooldown / 2))
	entry.visibility_zone_cooldown_current = controller ? controller.get_effective_visibility_zone_cooldown(src) : visibility_zone_cooldown
	entry.solo_zone_cooldown_available = requires_visibility_zone && visibility_zone_cooldown > 0 && entry.visibility_zone_cooldown_solo < visibility_zone_cooldown
	entry.solo_zone_cooldown_active = controller ? controller.uses_single_template_zone_discount(src) : FALSE
	entry.visibility_altitude_requirement = visibility_altitude_requirement
	entry.actions = list()
	for(var/datum/rto_support_action_template/action_template as anything in action_templates)
		var/datum/rto_support_ui_action_entry/action_entry = action_template.build_ui_entry(controller)
		entry.actions += list(action_entry.to_list())
	return entry
