/datum/rto_support_template/halo_command
	parent_type = /datum/rto_support_template/halo
	template_id = "halo_command"
	name = "UNSC Command"
	description = "UNSC command support package for recon, signals, and RTO sustain."
	role_summary = "Calls down command crates with signal equipment, recon tools, and battlefield coordination gear."
	targeting_summary = "No visibility zone required: designate an open landing point with RTO binoculars."
	restriction_summary = "Available only to UNSC-aligned RTO roles. Command drops require open sky and share one support family."
	action_template_types = list(
		/datum/rto_support_action_template/halo_signal_drop,
		/datum/rto_support_action_template/halo_recon_drop,
		/datum/rto_support_action_template/halo_rto_command_drop,
	)
	support_action_icon_state = "radio"
