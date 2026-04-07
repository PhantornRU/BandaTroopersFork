/datum/rto_support_template/halo_engineering
	parent_type = /datum/rto_support_template/halo
	template_id = "halo_engineering"
	name = "HALO Engineering"
	description = "UNSC-only HALO engineering support package for repair, fortification and breaching work."
	role_summary = "Calls down HALO engineering crates with tools, fortifications, demolition tools and vehicle service supplies."
	targeting_summary = "No visibility zone required: designate an open HALO landing point with RTO binoculars."
	restriction_summary = "Available only to HALO RTO roles. Engineering drops require open sky and use the longest HALO support cooldowns."
	action_template_types = list(
		/datum/rto_support_action_template/halo_toolbox_drop,
		/datum/rto_support_action_template/halo_fortification_drop,
		/datum/rto_support_action_template/halo_breaching_drop,
		/datum/rto_support_action_template/halo_vehicle_service_drop,
	)
