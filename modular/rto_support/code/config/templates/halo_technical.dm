/datum/rto_support_template/halo_technical
	parent_type = /datum/rto_support_template/halo
	template_id = "halo_technical"
	name = "HALO Technical"
	support_resource_mode = RTO_SUPPORT_RESOURCE_MODE_CHARGES
	support_pool_capacity = 3
	support_pool_starting_charges = 3
	support_pool_recharge_interval = 120 SECONDS
	support_pool_recharge_amount = 1
	support_pool_auto_recharge = TRUE
	description = "UNSC-only HALO technical support package with a shared 3-charge reserve for engineering, recon, signals and RTO sustain."
	role_summary = "Combines HALO engineering and command utility drops: heavy engineering crates cost 2 charges, recon and command drops cost 1."
	targeting_summary = "No visibility zone required: designate an open HALO landing point with RTO binoculars and recover one charge every 120 seconds."
	restriction_summary = "Available only to HALO RTO roles. All HALO technical drops require open sky and use only a 3-second local anti-spam lockout."
	action_template_types = list(
		/datum/rto_support_action_template/halo_toolbox_drop,
		/datum/rto_support_action_template/halo_fortification_drop,
		/datum/rto_support_action_template/halo_breaching_drop,
		/datum/rto_support_action_template/halo_vehicle_service_drop,
		/datum/rto_support_action_template/halo_signal_drop,
		/datum/rto_support_action_template/halo_recon_drop,
		/datum/rto_support_action_template/halo_rto_command_drop,
	)
