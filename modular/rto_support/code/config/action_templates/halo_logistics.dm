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
	support_pool_cost = 1
	personal_lockout = 6 SECONDS
	category = "logistics"
	icon_state = "ammo"

/datum/rto_support_action_template/halo_rifle_ammo_drop
	parent_type = /datum/rto_support_action_template/halo/logistics
	action_id = "halo_rifle_ammo_drop"
	name = "UNSC Rifle Ammo Drop"
	description = "Drops a mixed rifle resupply crate for MA5C, MA5B, BR55, and M6C users."
	fire_support_path = /datum/fire_support/supply_drop/halo/rifle

/datum/rto_support_action_template/halo_marksman_ammo_drop
	parent_type = /datum/rto_support_action_template/halo/logistics
	action_id = "halo_marksman_ammo_drop"
	name = "UNSC Marksman Ammo Drop"
	description = "Drops DMR magazines for marksmen and a light sidearm reserve."
	fire_support_path = /datum/fire_support/supply_drop/halo/marksman

/datum/rto_support_action_template/halo_pdw_ammo_drop
	parent_type = /datum/rto_support_action_template/halo/logistics
	action_id = "halo_pdw_ammo_drop"
	name = "UNSC Secondary Weapon Ammo Drop"
	description = "Drops M7 magazines plus sidearm ammunition for close-range and backup weapons."
	fire_support_path = /datum/fire_support/supply_drop/halo/pdw

/datum/rto_support_action_template/halo_shotgun_ammo_drop
	parent_type = /datum/rto_support_action_template/halo/logistics
	action_id = "halo_shotgun_ammo_drop"
	name = "UNSC Shotgun Ammo Drop"
	description = "Drops a compact slug-only shotgun resupply for one breacher instead of an oversized team crate."
	fire_support_path = /datum/fire_support/supply_drop/halo/shotgun

/datum/rto_support_action_template/halo_sniper_ammo_drop
	parent_type = /datum/rto_support_action_template/halo/logistics
	action_id = "halo_sniper_ammo_drop"
	name = "UNSC Sniper Ammo Drop"
	description = "Drops SRS99 sniper magazines for dedicated long-range specialists."
	fire_support_path = /datum/fire_support/supply_drop/halo/sniper

/datum/rto_support_action_template/halo_spnkr_ammo_drop
	parent_type = /datum/rto_support_action_template/halo/logistics
	action_id = "halo_spnkr_ammo_drop"
	name = "UNSC SPNKr Ammo Drop"
	description = "Drops SPNKr reload tubes for squad heavy-weapons specialists."
	fire_support_path = /datum/fire_support/supply_drop/halo/spnkr

/datum/rto_support_action_template/halo_grenadier_ammo_drop
	parent_type = /datum/rto_support_action_template/halo/logistics
	action_id = "halo_grenadier_ammo_drop"
	name = "UNSC Grenadier Ammo Drop"
	description = "Drops a grenadier crate with 40mm grenades and frag grenades."
	fire_support_path = /datum/fire_support/supply_drop/halo/grenadier
