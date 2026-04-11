/datum/rto_support_template/halo_technical
	parent_type = /datum/rto_support_template/halo
	template_id = "halo_technical"
	name = "UNSC Technical"
	support_resource_mode = RTO_SUPPORT_RESOURCE_MODE_CHARGES
	support_pool_capacity = 3
	support_pool_starting_charges = 3
	support_pool_recharge_interval = 210 SECONDS
	support_pool_recharge_amount = 1
	support_pool_auto_recharge = TRUE
	support_package_lockout = 8 SECONDS
	description = "UNSC technical support package with a shared 3-charge reserve for engineering, recon, signals, and RTO sustain."
	role_summary = "Heavy engineering crates cost 2 charges. Lighter signal and recon support stays at 1 charge to keep the package flexible."
	targeting_summary = "No visibility sector required: mark an open landing point with RTO binoculars and call the drop directly."
	restriction_summary = "Available to UNSC and ODST RTO roles. Requires open sky and uses one of the longest utility-package anti-spam locks."
	action_template_types = list(
		/datum/rto_support_action_template/halo_toolbox_drop,
		/datum/rto_support_action_template/halo_fortification_drop,
		/datum/rto_support_action_template/halo_breaching_drop,
		/datum/rto_support_action_template/halo_vehicle_service_drop,
		/datum/rto_support_action_template/halo_signal_drop,
		/datum/rto_support_action_template/halo_recon_drop,
		/datum/rto_support_action_template/halo_rto_command_drop,
	)
	support_action_icon_state = "build"
