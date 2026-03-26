/datum/rto_support_template/halo_medical
	parent_type = /datum/rto_support_template/halo
	template_id = "halo_medical"
	name = "HALO Medical"
	description = "UNSC-only HALO medical support package for casualty sustain and corpsman resupply."
	role_summary = "Calls down HALO field medicine crates with trauma packets, corpsman gear and biofoam reserves."
	targeting_summary = "No visibility zone required: designate an open HALO landing point with RTO binoculars."
	restriction_summary = "Available only to HALO RTO roles. All HALO medical drops require open sky and share one family cooldown."
	action_template_types = list(
		/datum/rto_support_action_template/halo_medical_packets_drop,
		/datum/rto_support_action_template/halo_corpsman_kit_drop,
		/datum/rto_support_action_template/halo_biofoam_reserve_drop,
	)
