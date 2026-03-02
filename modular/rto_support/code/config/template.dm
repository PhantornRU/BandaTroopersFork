/// Immutable configuration datum for one RTO support template.
/datum/rto_support_template
	/// Stable identifier used by selection logic and UI.
	var/template_id
	/// Display name shown to players.
	var/name = "RTO Support Template"
	/// Design description shown in the preset menu.
	var/description = ""
	/// Display name for the visibility sector action.
	var/visibility_zone_name = "Развернуть сектор наведения"
	/// Short description of the sector type for UI.
	var/visibility_zone_type = ""
	/// Radius of the visibility sector.
	var/visibility_zone_radius = 0
	/// Lifetime of the visibility sector.
	var/visibility_zone_duration = 0
	/// Cooldown of the visibility sector action.
	var/visibility_zone_cooldown = 0
	/// Category or family name for UI grouping.
	var/category = ""
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
	var/visibility_action_icon_state = "designator_mortar"

/datum/rto_support_template/New()
	. = ..()
	action_templates = list()
	for(var/action_type in action_template_types)
		action_templates += new action_type

/// Returns action templates bound to this support template.
/datum/rto_support_template/proc/get_action_templates()
	return action_templates.Copy()

/// Returns one action template by its stable identifier.
/datum/rto_support_template/proc/get_action_template(action_id)
	for(var/datum/rto_support_action_template/action_template as anything in action_templates)
		if(action_template.action_id == action_id)
			return action_template
	return null

/// Builds a UI DTO for the preset menu.
/datum/rto_support_template/proc/build_ui_entry()
	var/datum/rto_support_ui_preset_entry/entry = new
	entry.template_id = template_id
	entry.name = name
	entry.description = description
	entry.visibility_zone_name = visibility_zone_name
	entry.visibility_zone_type = visibility_zone_type
	entry.visibility_zone_radius = visibility_zone_radius
	entry.visibility_zone_duration = visibility_zone_duration
	entry.visibility_zone_cooldown = visibility_zone_cooldown
	entry.actions = list()
	for(var/datum/rto_support_action_template/action_template as anything in action_templates)
		var/datum/rto_support_ui_action_entry/action_entry = action_template.build_ui_entry()
		entry.actions += list(action_entry.to_list())
	return entry

/datum/rto_support_template/mortar
	template_id = "mortar"
	name = "Mortar"
	description = "Площадной пакет с большим разбросом, дымом и зажигательными снарядами."
	visibility_zone_type = "Illumination"
	visibility_zone_radius = 7
	visibility_zone_duration = 90 SECONDS
	visibility_zone_cooldown = 45 SECONDS
	category = "support"
	action_template_types = list(
		/datum/rto_support_action_template/mortar_he,
		/datum/rto_support_action_template/mortar_smoke,
		/datum/rto_support_action_template/mortar_incendiary,
	)
	visibility_support_path = /datum/fire_support/rto_visibility/illumination

/datum/rto_support_template/cas
	template_id = "cas"
	name = "CAS"
	description = "Точный авиационный пакет для штурмового сопровождения."
	visibility_zone_type = "Air corridor"
	visibility_zone_radius = 5
	visibility_zone_duration = 90 SECONDS
	visibility_zone_cooldown = 60 SECONDS
	category = "support"
	action_template_types = list(
		/datum/rto_support_action_template/cas_gun_run,
		/datum/rto_support_action_template/cas_laser_run,
		/datum/rto_support_action_template/cas_rocket_barrage,
	)
	visibility_altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH

/datum/rto_support_template/heavy
	template_id = "heavy"
	name = "Heavy Strike"
	description = "Редкие тяжёлые удары с малым разбросом и длинными кулдаунами."
	visibility_zone_type = "Strike window"
	visibility_zone_radius = 4
	visibility_zone_duration = 90 SECONDS
	visibility_zone_cooldown = 70 SECONDS
	category = "support"
	action_template_types = list(
		/datum/rto_support_action_template/heavy_missile,
		/datum/rto_support_action_template/heavy_napalm,
	)
	visibility_altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH

/datum/rto_support_template/logistics
	template_id = "logistics"
	name = "Logistics"
	description = "Логистический пакет для выгрузки припасов и турелей."
	visibility_zone_name = "Подготовить зону выгрузки"
	visibility_zone_type = "Landing window"
	visibility_zone_radius = 6
	visibility_zone_duration = 90 SECONDS
	visibility_zone_cooldown = 50 SECONDS
	category = "support"
	action_template_types = list(
		/datum/rto_support_action_template/logistics_supply,
		/datum/rto_support_action_template/logistics_sentry,
	)
	visibility_altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH
	visibility_action_icon_state = "designator_swap_mortar"

/// Returns a fresh catalog of available RTO templates.
/proc/build_rto_support_template_catalog()
	return list(
		new /datum/rto_support_template/mortar,
		new /datum/rto_support_template/cas,
		new /datum/rto_support_template/heavy,
		new /datum/rto_support_template/logistics,
	)
