/datum/rto_support_action_template/halo/medical
	parent_type = /datum/rto_support_action_template/halo
	shared_cooldown = 240 SECONDS
	personal_cooldown = 600 SECONDS
	support_pool_cost = 1
	personal_lockout = 6 SECONDS
	category = "medical"
	icon_state = "medic"

/datum/rto_support_action_template/halo_medical_packets_drop
	parent_type = /datum/rto_support_action_template/halo/medical
	action_id = "halo_medical_packets_drop"
	name = "UNSC Medical Packets Drop"
	description = "Drops trauma packet reserve and morphine for frontline casualty stabilization."
	fire_support_path = /datum/fire_support/supply_drop/halo/medical_packets

/datum/rto_support_action_template/halo_corpsman_kit_drop
	parent_type = /datum/rto_support_action_template/halo/medical
	action_id = "halo_corpsman_kit_drop"
	name = "UNSC Corpsman Kit Drop"
	description = "Drops a corpsman sustain crate with filled medgear for field specialists."
	fire_support_path = /datum/fire_support/supply_drop/halo/corpsman_kit

/datum/rto_support_action_template/halo_biofoam_reserve_drop
	parent_type = /datum/rto_support_action_template/halo/medical
	action_id = "halo_biofoam_reserve_drop"
	name = "UNSC Biofoam Reserve Drop"
	description = "Drops biofoam injectors and burn treatment reserves for prolonged field care."
	fire_support_path = /datum/fire_support/supply_drop/halo/biofoam_reserve
