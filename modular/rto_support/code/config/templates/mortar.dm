/datum/rto_support_template/mortar
	template_id = "mortar"
	allowed_support_profiles = list("uscm", "unsc")
	name = "Mortar"
	support_resource_mode = RTO_SUPPORT_RESOURCE_MODE_CHARGES
	support_pool_capacity = 5
	support_pool_starting_charges = 5
	support_pool_recharge_interval = 105 SECONDS
	support_pool_recharge_amount = 1
	support_pool_auto_recharge = TRUE
	support_package_lockout = 6 SECONDS
	description = "Frequent fire-support package with a shared 5-charge reserve for HE, smoke, and incendiary rounds."
	role_summary = "HE and smoke cost 1 charge. Incendiary costs 2 and should be used for area denial rather than routine pressure."
	targeting_summary = "Deploy the sector first, then work mortar calls inside it. Sector redeploy stays quick and only acts as anti-spam."
	restriction_summary = "Best used as steady pressure from a prepared sector. Charges return slowly, so repeated utility fire now trades tempo for endurance."
	visibility_zone_type = "Illumination"
	visibility_zone_radius = 7
	visibility_zone_duration = 30 SECONDS
	visibility_zone_cooldown = 3 SECONDS
	category = "support"
	action_template_types = list(
		/datum/rto_support_action_template/mortar_he,
		/datum/rto_support_action_template/mortar_smoke,
		/datum/rto_support_action_template/mortar_incendiary,
	)
	visibility_support_path = /datum/fire_support/rto_visibility/illumination
	visibility_altitude_requirement = RTO_SUPPORT_ALTITUDE_ANY
	support_action_icon_state = "he_mortar"
