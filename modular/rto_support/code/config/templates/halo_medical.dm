/datum/rto_support_template/halo_medical
	parent_type = /datum/rto_support_template/halo
	template_id = "halo_medical"
	name = "HALO Medical"
	support_resource_mode = RTO_SUPPORT_RESOURCE_MODE_CHARGES
	support_pool_capacity = 3
	support_pool_starting_charges = 3
	support_pool_recharge_interval = 120 SECONDS
	support_pool_recharge_amount = 1
	support_pool_auto_recharge = TRUE
	description = "UNSC-only HALO medical support package with a shared 3-charge reserve for casualty sustain and corpsman resupply."
	role_summary = "Calls down HALO field medicine crates with trauma packets, corpsman gear and biofoam reserves at 1 charge each."
	targeting_summary = "No visibility zone required: designate an open HALO landing point with RTO binoculars and recover one charge every 120 seconds."
	restriction_summary = "Available only to HALO RTO roles. All HALO medical drops require open sky and use only a 3-second local anti-spam lockout."
	action_template_types = list(
		/datum/rto_support_action_template/halo_medical_packets_drop,
		/datum/rto_support_action_template/halo_corpsman_kit_drop,
		/datum/rto_support_action_template/halo_biofoam_reserve_drop,
	)
