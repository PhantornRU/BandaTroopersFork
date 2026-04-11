/datum/rto_support_template/halo_medical
	parent_type = /datum/rto_support_template/halo
	template_id = "halo_medical"
	name = "UNSC Medical"
	support_resource_mode = RTO_SUPPORT_RESOURCE_MODE_CHARGES
	support_pool_capacity = 3
	support_pool_starting_charges = 3
	support_pool_recharge_interval = 180 SECONDS
	support_pool_recharge_amount = 1
	support_pool_auto_recharge = TRUE
	support_package_lockout = 6 SECONDS
	description = "UNSC medical support package with a shared 3-charge reserve for casualty sustain and corpsman resupply."
	role_summary = "Keeps field treatment moving with medical packets, corpsman gear, and biofoam reserves at 1 charge each."
	targeting_summary = "No visibility sector required: mark an open landing point with RTO binoculars and call the drop directly."
	restriction_summary = "Available to UNSC and ODST RTO roles. Requires open sky and recharges at a measured pace to prevent endless sustain loops."
	action_template_types = list(
		/datum/rto_support_action_template/halo_medical_packets_drop,
		/datum/rto_support_action_template/halo_corpsman_kit_drop,
		/datum/rto_support_action_template/halo_biofoam_reserve_drop,
	)
	support_action_icon_state = "medic"
