/datum/halo_support_catalog_entry
	var/support_id
	var/gm_label
	var/fire_support_path
	var/gm_section_id
	var/gm_section_title
	var/preset_id

/datum/halo_support_catalog_entry/New(_support_id, _gm_label, _fire_support_path, _gm_section_id, _gm_section_title, _preset_id)
	. = ..()
	support_id = _support_id
	gm_label = _gm_label
	fire_support_path = _fire_support_path
	gm_section_id = _gm_section_id
	gm_section_title = _gm_section_title
	preset_id = _preset_id

/proc/get_halo_support_catalog()
	var/static/list/catalog = null
	if(catalog)
		return catalog

	catalog = list(
		new /datum/halo_support_catalog_entry("halo_rifle_ammo_drop", "UNSC Rifle Ammo Drop", /datum/fire_support/supply_drop/halo/rifle, "halo_logistics", "UNSC Logistics", "halo_logistics"),
		new /datum/halo_support_catalog_entry("halo_marksman_ammo_drop", "UNSC Marksman Ammo Drop", /datum/fire_support/supply_drop/halo/marksman, "halo_logistics", "UNSC Logistics", "halo_logistics"),
		new /datum/halo_support_catalog_entry("halo_pdw_ammo_drop", "UNSC Secondary Weapon Ammo Drop", /datum/fire_support/supply_drop/halo/pdw, "halo_logistics", "UNSC Logistics", "halo_logistics"),
		new /datum/halo_support_catalog_entry("halo_shotgun_ammo_drop", "UNSC Shotgun Ammo Drop", /datum/fire_support/supply_drop/halo/shotgun, "halo_logistics", "UNSC Logistics", "halo_logistics"),
		new /datum/halo_support_catalog_entry("halo_sniper_ammo_drop", "UNSC Sniper Ammo Drop", /datum/fire_support/supply_drop/halo/sniper, "halo_logistics", "UNSC Logistics", "halo_logistics"),
		new /datum/halo_support_catalog_entry("halo_spnkr_ammo_drop", "UNSC SPNKr Ammo Drop", /datum/fire_support/supply_drop/halo/spnkr, "halo_logistics", "UNSC Logistics", "halo_logistics"),
		new /datum/halo_support_catalog_entry("halo_grenadier_ammo_drop", "UNSC Grenadier Ammo Drop", /datum/fire_support/supply_drop/halo/grenadier, "halo_logistics", "UNSC Logistics", "halo_logistics"),
		new /datum/halo_support_catalog_entry("halo_medical_packets_drop", "UNSC Medical Packets Drop", /datum/fire_support/supply_drop/halo/medical_packets, "halo_medical", "UNSC Medical", "halo_medical"),
		new /datum/halo_support_catalog_entry("halo_corpsman_kit_drop", "UNSC Corpsman Kit Drop", /datum/fire_support/supply_drop/halo/corpsman_kit, "halo_medical", "UNSC Medical", "halo_medical"),
		new /datum/halo_support_catalog_entry("halo_biofoam_reserve_drop", "UNSC Biofoam Reserve Drop", /datum/fire_support/supply_drop/halo/biofoam_reserve, "halo_medical", "UNSC Medical", "halo_medical"),
		new /datum/halo_support_catalog_entry("halo_toolbox_drop", "UNSC Toolbox Drop", /datum/fire_support/supply_drop/halo/toolbox, "halo_technical", "UNSC Technical", "halo_technical"),
		new /datum/halo_support_catalog_entry("halo_fortification_drop", "UNSC Fortification Drop", /datum/fire_support/supply_drop/halo/fortification, "halo_technical", "UNSC Technical", "halo_technical"),
		new /datum/halo_support_catalog_entry("halo_breaching_drop", "UNSC Breaching Drop", /datum/fire_support/supply_drop/halo/breaching, "halo_technical", "UNSC Technical", "halo_technical"),
		new /datum/halo_support_catalog_entry("halo_vehicle_service_drop", "UNSC Vehicle Service Drop", /datum/fire_support/supply_drop/halo/vehicle_service, "halo_technical", "UNSC Technical", "halo_technical"),
		new /datum/halo_support_catalog_entry("halo_signal_drop", "UNSC Signal Drop", /datum/fire_support/supply_drop/halo/signal, "halo_technical", "UNSC Technical", "halo_technical"),
		new /datum/halo_support_catalog_entry("halo_recon_drop", "UNSC Recon Drop", /datum/fire_support/supply_drop/halo/recon, "halo_technical", "UNSC Technical", "halo_technical"),
		new /datum/halo_support_catalog_entry("halo_rto_command_drop", "UNSC RTO Command Drop", /datum/fire_support/supply_drop/halo/rto_command, "halo_technical", "UNSC Technical", "halo_technical"),
	)
	return catalog

/proc/get_halo_support_catalog_by_label()
	var/static/list/catalog_by_label = null
	if(catalog_by_label)
		return catalog_by_label

	catalog_by_label = list()
	for(var/datum/halo_support_catalog_entry/entry as anything in get_halo_support_catalog())
		catalog_by_label[entry.gm_label] = entry
	return catalog_by_label

/proc/find_halo_support_catalog_entry(gm_label)
	return get_halo_support_catalog_by_label()[gm_label]

/proc/build_halo_custom_ordnance_sections()
	var/list/sections = list()
	var/list/sections_by_id = list()

	for(var/datum/halo_support_catalog_entry/entry as anything in get_halo_support_catalog())
		var/list/section = sections_by_id[entry.gm_section_id]
		if(!section)
			section = list(
				"id" = entry.gm_section_id,
				"title" = entry.gm_section_title,
				"options" = list(),
			)
			sections_by_id[entry.gm_section_id] = section
			sections += list(section)

		var/list/options = section["options"]
		options += entry.gm_label

	return sections

/datum/fire_support/supply_drop/halo
	name = "UNSC support drop"
	icon_state = "supply"
	fire_support_type = "halo_support_drop"

/datum/fire_support/supply_drop/halo/rifle
	name = "UNSC Rifle Ammo Drop"
	fire_support_type = "halo_rifle_ammo_drop"
	delivered = /obj/structure/largecrate/supply/ammo/halo/rifle

/datum/fire_support/supply_drop/halo/marksman
	name = "UNSC Marksman Ammo Drop"
	fire_support_type = "halo_marksman_ammo_drop"
	delivered = /obj/structure/largecrate/supply/ammo/halo/marksman

/datum/fire_support/supply_drop/halo/pdw
	name = "UNSC Secondary Weapon Ammo Drop"
	fire_support_type = "halo_pdw_ammo_drop"
	delivered = /obj/structure/largecrate/supply/ammo/halo/pdw

/datum/fire_support/supply_drop/halo/shotgun
	name = "UNSC Shotgun Ammo Drop"
	fire_support_type = "halo_shotgun_ammo_drop"
	delivered = /obj/structure/largecrate/supply/ammo/halo/shotgun

/datum/fire_support/supply_drop/halo/sniper
	name = "UNSC Sniper Ammo Drop"
	fire_support_type = "halo_sniper_ammo_drop"
	delivered = /obj/structure/largecrate/supply/ammo/halo/sniper

/datum/fire_support/supply_drop/halo/spnkr
	name = "UNSC SPNKr Ammo Drop"
	fire_support_type = "halo_spnkr_ammo_drop"
	delivered = /obj/structure/largecrate/supply/ammo/halo/spnkr

/datum/fire_support/supply_drop/halo/grenadier
	name = "UNSC Grenadier Ammo Drop"
	fire_support_type = "halo_grenadier_ammo_drop"
	delivered = /obj/structure/largecrate/supply/ammo/halo/grenadier

/datum/fire_support/supply_drop/halo/medical_packets
	name = "UNSC Medical Packets Drop"
	fire_support_type = "halo_medical_packets_drop"
	delivered = /obj/structure/largecrate/supply/medicine/halo/medical_packets

/datum/fire_support/supply_drop/halo/corpsman_kit
	name = "UNSC Corpsman Kit Drop"
	fire_support_type = "halo_corpsman_kit_drop"
	delivered = /obj/structure/largecrate/supply/medicine/halo/corpsman_kit

/datum/fire_support/supply_drop/halo/biofoam_reserve
	name = "UNSC Biofoam Reserve Drop"
	fire_support_type = "halo_biofoam_reserve_drop"
	delivered = /obj/structure/largecrate/supply/medicine/halo/biofoam_reserve

/datum/fire_support/supply_drop/halo/toolbox
	name = "UNSC Toolbox Drop"
	fire_support_type = "halo_toolbox_drop"
	delivered = /obj/structure/largecrate/supply/supplies/halo/toolbox

/datum/fire_support/supply_drop/halo/fortification
	name = "UNSC Fortification Drop"
	fire_support_type = "halo_fortification_drop"
	delivered = /obj/structure/largecrate/supply/supplies/halo/fortification

/datum/fire_support/supply_drop/halo/breaching
	name = "UNSC Breaching Drop"
	fire_support_type = "halo_breaching_drop"
	delivered = /obj/structure/largecrate/supply/explosives/halo/breaching

/datum/fire_support/supply_drop/halo/vehicle_service
	name = "UNSC Vehicle Service Drop"
	fire_support_type = "halo_vehicle_service_drop"
	delivered = /obj/structure/largecrate/supply/supplies/halo/vehicle_service

/datum/fire_support/supply_drop/halo/signal
	name = "UNSC Signal Drop"
	fire_support_type = "halo_signal_drop"
	delivered = /obj/structure/largecrate/supply/supplies/halo/signal

/datum/fire_support/supply_drop/halo/recon
	name = "UNSC Recon Drop"
	fire_support_type = "halo_recon_drop"
	delivered = /obj/structure/largecrate/supply/supplies/halo/recon

/datum/fire_support/supply_drop/halo/rto_command
	name = "UNSC RTO Command Drop"
	fire_support_type = "halo_rto_command_drop"
	delivered = /obj/structure/largecrate/supply/supplies/halo/rto_command

/datum/fire_support_menu/append_custom_static_data(list/data)
	. = ..()
	if(!islist(data))
		return .

	if(!islist(data["ordnance_options"]))
		data["ordnance_options"] = list()
	if(!islist(data["custom_ordnance_sections"]))
		data["custom_ordnance_sections"] = list()

	for(var/datum/halo_support_catalog_entry/entry as anything in get_halo_support_catalog())
		if(!(entry.gm_label in data["ordnance_options"]))
			data["ordnance_options"] += entry.gm_label

	var/list/custom_sections = data["custom_ordnance_sections"]
	for(var/list/section as anything in build_halo_custom_ordnance_sections())
		custom_sections += list(section)
	return .

/datum/fire_support_menu/resolve_custom_fire_support(selected_ordnance)
	var/datum/halo_support_catalog_entry/entry = find_halo_support_catalog_entry(selected_ordnance)
	if(entry)
		return entry.fire_support_path
	return ..()
