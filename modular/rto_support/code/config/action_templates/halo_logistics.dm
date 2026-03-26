/datum/rto_support_action_template/halo
	scatter = 1
	requires_visibility_zone = FALSE
	altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH
	allow_closed_turf = FALSE
	category = "support"

/datum/rto_support_action_template/halo/logistics
	parent_type = /datum/rto_support_action_template/halo
	shared_cooldown = 240 SECONDS
	personal_cooldown = 600 SECONDS
	category = "logistics"
	icon_state = "ammo"

/datum/rto_support_action_template/halo_rifle_ammo_drop
	parent_type = /datum/rto_support_action_template/halo/logistics
	action_id = "halo_rifle_ammo_drop"
	name = "HALO Rifle Ammo Drop"
	description = "Drops a mixed UNSC rifle resupply crate with MA5C, MA5B, BR55 and M6C ammunition."
	fire_support_path = /datum/fire_support/supply_drop/halo/rifle

/datum/rto_support_action_template/halo_marksman_ammo_drop
	parent_type = /datum/rto_support_action_template/halo/logistics
	action_id = "halo_marksman_ammo_drop"
	name = "HALO Marksman Ammo Drop"
	description = "Drops DMR and M6D magazines for HALO marksmen."
	fire_support_path = /datum/fire_support/supply_drop/halo/marksman

/datum/rto_support_action_template/halo_pdw_ammo_drop
	parent_type = /datum/rto_support_action_template/halo/logistics
	action_id = "halo_pdw_ammo_drop"
	name = "HALO PDW Ammo Drop"
	description = "Drops M7 SMG magazines and sidearm ammunition for close-quarters HALO troops."
	fire_support_path = /datum/fire_support/supply_drop/halo/pdw

/datum/rto_support_action_template/halo_shotgun_ammo_drop
	parent_type = /datum/rto_support_action_template/halo/logistics
	action_id = "halo_shotgun_ammo_drop"
	name = "HALO Shotgun Ammo Drop"
	description = "Drops buckshot magazines for HALO breachers and boarding teams."
	fire_support_path = /datum/fire_support/supply_drop/halo/shotgun

/datum/rto_support_action_template/halo_sniper_ammo_drop
	parent_type = /datum/rto_support_action_template/halo/logistics
	action_id = "halo_sniper_ammo_drop"
	name = "HALO Sniper Ammo Drop"
	description = "Drops SRS99 sniper magazines for HALO specialists."
	fire_support_path = /datum/fire_support/supply_drop/halo/sniper

/datum/rto_support_action_template/halo_spnkr_ammo_drop
	parent_type = /datum/rto_support_action_template/halo/logistics
	action_id = "halo_spnkr_ammo_drop"
	name = "HALO SPNKr Ammo Drop"
	description = "Drops SPNKr reload tubes for HALO squad weapons specialists."
	fire_support_path = /datum/fire_support/supply_drop/halo/spnkr

/datum/rto_support_action_template/halo_grenadier_ammo_drop
	parent_type = /datum/rto_support_action_template/halo/logistics
	action_id = "halo_grenadier_ammo_drop"
	name = "HALO Grenadier Ammo Drop"
	description = "Drops a HALO grenadier crate with 40mm grenades and frag grenades."
	fire_support_path = /datum/fire_support/supply_drop/halo/grenadier
