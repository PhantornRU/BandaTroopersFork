/datum/rto_support_template/halo_command
	parent_type = /datum/rto_support_template/halo
	template_id = "halo_command"
	name = "HALO Command"
	description = "UNSC-only HALO command support package for recon, signals and RTO sustain."
	role_summary = "Calls down HALO command crates with signal equipment, recon tools and RTO coordination gear."
	targeting_summary = "No visibility zone required: designate an open HALO landing point with RTO binoculars."
	restriction_summary = "Available only to HALO RTO roles. All HALO command drops require open sky and share one family cooldown."
	action_template_types = list(
		/datum/rto_support_action_template/halo_signal_drop,
		/datum/rto_support_action_template/halo_recon_drop,
		/datum/rto_support_action_template/halo_rto_command_drop,
	)
