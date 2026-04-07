/datum/rto_support_action_template/halo/medical
	parent_type = /datum/rto_support_action_template/halo
	shared_cooldown = 240 SECONDS
	personal_cooldown = 600 SECONDS
	category = "medical"
	icon_state = "medic"

/datum/rto_support_action_template/halo_medical_packets_drop
	parent_type = /datum/rto_support_action_template/halo/medical
	action_id = "halo_medical_packets_drop"
	name = "HALO Medical Packets Drop"
	description = "Drops trauma packet reserve and morphine for frontline casualty stabilization."
	fire_support_path = /datum/fire_support/supply_drop/halo/medical_packets

/datum/rto_support_action_template/halo_corpsman_kit_drop
	parent_type = /datum/rto_support_action_template/halo/medical
	action_id = "halo_corpsman_kit_drop"
	name = "HALO Corpsman Kit Drop"
	description = "Drops a corpsman sustain crate with filled medgear for HALO medical specialists."
	fire_support_path = /datum/fire_support/supply_drop/halo/corpsman_kit

/datum/rto_support_action_template/halo_biofoam_reserve_drop
	parent_type = /datum/rto_support_action_template/halo/medical
	action_id = "halo_biofoam_reserve_drop"
	name = "HALO Biofoam Reserve Drop"
	description = "Drops biofoam injectors and burn treatment reserves for prolonged field care."
	fire_support_path = /datum/fire_support/supply_drop/halo/biofoam_reserve
