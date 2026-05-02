/datum/uscm_support_catalog_entry
	var/support_id
	var/gm_label
	var/fire_support_path
	var/gm_section_id
	var/gm_section_title

/datum/uscm_support_catalog_entry/New(_support_id, _gm_label, _fire_support_path, _gm_section_id, _gm_section_title)
	. = ..()
	support_id = _support_id
	gm_label = _gm_label
	fire_support_path = _fire_support_path
	gm_section_id = _gm_section_id
	gm_section_title = _gm_section_title

/proc/get_uscm_support_catalog()
	var/static/list/catalog = null
	if(catalog)
		return catalog

	catalog = list(
		new /datum/uscm_support_catalog_entry("uscm_rifle_ammo_drop", "USCM Rifle Ammo Drop", /datum/fire_support/supply_drop/uscm/rifle, "uscm_ammo_drops", "USCM Ammo Drops"),
		new /datum/uscm_support_catalog_entry("uscm_rifle_box_ammo_drop", "USCM Rifle Box Ammo Drop", /datum/fire_support/supply_drop/uscm/rifle_box, "uscm_ammo_drops", "USCM Ammo Drops"),
		new /datum/uscm_support_catalog_entry("uscm_shotgun_ammo_drop", "USCM Shotgun Ammo Drop", /datum/fire_support/supply_drop/uscm/shotgun, "uscm_ammo_drops", "USCM Ammo Drops"),
		new /datum/uscm_support_catalog_entry("uscm_smg_ammo_drop", "USCM SMG Ammo Drop", /datum/fire_support/supply_drop/uscm/smg, "uscm_ammo_drops", "USCM Ammo Drops"),
		new /datum/uscm_support_catalog_entry("uscm_sidearm_ammo_drop", "USCM Sidearm Ammo Drop", /datum/fire_support/supply_drop/uscm/sidearm, "uscm_ammo_drops", "USCM Ammo Drops"),
		new /datum/uscm_support_catalog_entry("uscm_m56d_ammo_drop", "USCM M56D Ammo Drop", /datum/fire_support/supply_drop/uscm/m56d, "uscm_ammo_drops", "USCM Ammo Drops"),
		new /datum/uscm_support_catalog_entry("uscm_sentry_ammo_drop", "USCM Sentry Ammo Drop", /datum/fire_support/supply_drop/uscm/sentry, "uscm_ammo_drops", "USCM Ammo Drops"),
	)
	return catalog

/proc/get_uscm_support_catalog_by_label()
	var/static/list/catalog_by_label = null
	if(catalog_by_label)
		return catalog_by_label

	catalog_by_label = list()
	for(var/datum/uscm_support_catalog_entry/entry as anything in get_uscm_support_catalog())
		catalog_by_label[entry.gm_label] = entry
	return catalog_by_label

/proc/find_uscm_support_catalog_entry(gm_label)
	return get_uscm_support_catalog_by_label()[gm_label]

/proc/build_uscm_custom_ordnance_sections()
	var/list/sections = list()
	var/list/sections_by_id = list()

	for(var/datum/uscm_support_catalog_entry/entry as anything in get_uscm_support_catalog())
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

/datum/fire_support/supply_drop/uscm
	name = "USCM ammo drop"
	icon_state = "ammo"
	fire_support_type = "uscm_ammo_drop"

/datum/fire_support/supply_drop/uscm/rifle
	name = "USCM Rifle Ammo Drop"
	fire_support_type = "uscm_rifle_ammo_drop"
	delivered = /obj/structure/largecrate/supply/ammo/m41a

/datum/fire_support/supply_drop/uscm/rifle_box
	name = "USCM Rifle Box Ammo Drop"
	fire_support_type = "uscm_rifle_box_ammo_drop"
	delivered = /obj/structure/largecrate/supply/ammo/m41a_box

/datum/fire_support/supply_drop/uscm/shotgun
	name = "USCM Shotgun Ammo Drop"
	fire_support_type = "uscm_shotgun_ammo_drop"
	delivered = /obj/structure/largecrate/supply/ammo/shotgun

/datum/fire_support/supply_drop/uscm/smg
	name = "USCM SMG Ammo Drop"
	fire_support_type = "uscm_smg_ammo_drop"
	delivered = /obj/structure/largecrate/supply/ammo/m39

/datum/fire_support/supply_drop/uscm/sidearm
	name = "USCM Sidearm Ammo Drop"
	fire_support_type = "uscm_sidearm_ammo_drop"
	delivered = /obj/structure/largecrate/supply/ammo/pistol

/datum/fire_support/supply_drop/uscm/m56d
	name = "USCM M56D Ammo Drop"
	fire_support_type = "uscm_m56d_ammo_drop"
	delivered = /obj/structure/largecrate/supply/ammo/m56d

/datum/fire_support/supply_drop/uscm/sentry
	name = "USCM Sentry Ammo Drop"
	fire_support_type = "uscm_sentry_ammo_drop"
	delivered = /obj/structure/largecrate/supply/ammo/sentry

/datum/fire_support_menu/append_custom_static_data(list/data)
	. = ..()
	if(!islist(data))
		return .

	if(!islist(data["ordnance_options"]))
		data["ordnance_options"] = list()
	if(!islist(data["custom_ordnance_sections"]))
		data["custom_ordnance_sections"] = list()

	for(var/datum/uscm_support_catalog_entry/entry as anything in get_uscm_support_catalog())
		if(!(entry.gm_label in data["ordnance_options"]))
			data["ordnance_options"] += entry.gm_label

	var/list/custom_sections = data["custom_ordnance_sections"]
	for(var/list/section as anything in build_uscm_custom_ordnance_sections())
		custom_sections += list(section)

	return .

/datum/fire_support_menu/resolve_custom_fire_support(selected_ordnance)
	var/datum/uscm_support_catalog_entry/entry = find_uscm_support_catalog_entry(selected_ordnance)
	if(entry)
		return entry.fire_support_path
	return ..()
