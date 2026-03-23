/datum/rto_support_action_template/halo/command
	parent_type = /datum/rto_support_action_template/halo
	shared_cooldown = 240 SECONDS
	personal_cooldown = 600 SECONDS
	category = "command"
	icon_state = "radio"

/datum/rto_support_action_template/halo_signal_drop
	parent_type = /datum/rto_support_action_template/halo/command
	action_id = "halo_signal_drop"
	name = "HALO Signal Drop"
	description = "Drops flare and signal gear for landing-zone marking and battlefield coordination."
	fire_support_path = /datum/fire_support/supply_drop/halo/signal

/datum/rto_support_action_template/halo_recon_drop
	parent_type = /datum/rto_support_action_template/halo/command
	action_id = "halo_recon_drop"
	name = "HALO Recon Drop"
	description = "Drops monoculars, a motion detector, a tactical map and a combat flashlight."
	fire_support_path = /datum/fire_support/supply_drop/halo/recon

/datum/rto_support_action_template/halo_rto_command_drop
	parent_type = /datum/rto_support_action_template/halo/command
	action_id = "halo_rto_command_drop"
	name = "HALO RTO Command Drop"
	description = "Drops command-and-control gear for HALO RTOs and JTAC coordination."
	fire_support_path = /datum/fire_support/supply_drop/halo/rto_command
