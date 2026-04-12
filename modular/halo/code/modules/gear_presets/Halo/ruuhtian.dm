/datum/equipment_preset/covenant/ruuhtian
	name = "Kig-Yar Ruuhtian"
	expected_species = SPECIES_RUUHTIAN
	rank = JOB_COV_CIV
	assignment = JOB_COV_CIV
	flags = EQUIPMENT_PRESET_EXTRA|EQUIPMENT_PRESET_MARINE
	paygrades = list(PAY_SHORT_COV_CIV = JOB_PLAYTIME_TIER_0)
	faction = FACTION_COVENANT
	skills = /datum/skills/covenant/ruuhtian
	languages = list(LANGUAGE_SANGHEILI, LANGUAGE_RUUHTIAN)

/datum/equipment_preset/covenant/ruuhtian/load_race(mob/living/carbon/human/new_human, client/mob_client)
	new_human.set_species(SPECIES_RUUHTIAN)
	random_name = capitalize(pick(GLOB.first_names_jackal))
	new_human.change_real_name(new_human, random_name)
	new_human.gender = MALE
	new_human.h_style = pick_weight(list("Mohawk" = 60, "Ruffle" = 20, "Ruffle - Slick" = 20))
	new_human.body_type = "ruuht"
	new_human.skin_color = pick_weight(list("ruuht1" = 60, "ruuht2" = 20, "ruuht3" = 20))
	var/static/list/eye_color_list = list(
		"Yellow" = list(210, 164, 40),
		"Orange" = list(199, 110, 38),
		"Purple" = list(155, 100, 194),
		"Blue" = list(104, 120, 212),
	)
	eye_color = pick(eye_color_list)
	new_human.r_eyes = eye_color_list[eye_color][1]
	new_human.g_eyes = eye_color_list[eye_color][2]
	new_human.b_eyes = eye_color_list[eye_color][3]

/datum/equipment_preset/covenant/ruuhtian/load_name(mob/living/carbon/human/new_human, randomise, client/mob_client)
	random_name = capitalize(pick(GLOB.first_names_jackal))
	new_human.change_real_name(new_human, random_name)
	new_human.gender = MALE
	new_human.h_style = pick_weight(list("Mohawk" = 60, "Ruffle" = 20, "Ruffle - Slick" = 20))
	new_human.body_type = "ruuht"
	new_human.skin_color = pick_weight(list("ruuht1" = 60, "ruuht2" = 20, "ruuht3" = 20))
	var/static/list/eye_color_list = list(
		"Yellow" = list(210, 164, 40),
		"Orange" = list(199, 110, 38),
		"Purple" = list(155, 100, 194),
		"Blue" = list(104, 120, 212),
	)
	eye_color = pick(eye_color_list)
	new_human.r_eyes = eye_color_list[eye_color][1]
	new_human.g_eyes = eye_color_list[eye_color][2]
	new_human.b_eyes = eye_color_list[eye_color][3]

/datum/equipment_preset/covenant/ruuhtian/proc/equip_ruuhtian_basics(mob/living/carbon/human/new_human, helmet_type, suit_type, shoes_type, belt_type)
	new_human.equip_to_slot_or_del(new /obj/item/clothing/under/marine/covenant/ruuhtian(new_human), WEAR_BODY)
	new_human.equip_to_slot_or_del(new helmet_type(new_human), WEAR_HEAD)
	new_human.equip_to_slot_or_del(new suit_type(new_human), WEAR_JACKET)
	new_human.equip_to_slot_or_del(new /obj/item/clothing/gloves/marine/ruuhtian(new_human), WEAR_HANDS)
	new_human.equip_to_slot_or_del(new shoes_type(new_human), WEAR_FEET)
	new_human.equip_to_slot_or_del(new belt_type(new_human), WEAR_WAIST)
	new_human.equip_to_slot_or_del(new /obj/item/device/radio/headset/almayer/marine/covenant(new_human), WEAR_L_EAR)
	new_human.equip_to_slot_or_del(new /obj/item/weapon/shield/riot/covenant(new_human), WEAR_L_STORE)

/datum/equipment_preset/covenant/ruuhtian/proc/add_needler_crystals(mob/living/carbon/human/new_human, count = 5)
	for(var/i in 1 to count)
		new_human.equip_to_slot_or_del(new /obj/item/ammo_magazine/needler_crystal(new_human), WEAR_IN_BELT)

/datum/equipment_preset/covenant/ruuhtian/proc/add_carbine_mags(mob/living/carbon/human/new_human, count = 5)
	for(var/i in 1 to count)
		new_human.equip_to_slot_or_del(new /obj/item/ammo_magazine/carbine(new_human), WEAR_IN_BELT)

// =================================
// Minor
// =================================

/datum/equipment_preset/covenant/ruuhtian/minor
	name = parent_type::name + " Minor"
	assignment = JOB_COV_MINOR
	rank = JOB_COV_MINOR
	paygrades = list(PAY_SHORT_COV_MINOR = JOB_PLAYTIME_TIER_0)
	role_comm_title = "Minor"

/datum/equipment_preset/covenant/ruuhtian/minor/load_gear(mob/living/carbon/human/new_human)
	equip_ruuhtian_basics(new_human, /obj/item/clothing/head/helmet/marine/ruuhtian/headset, /obj/item/clothing/suit/marine/ruuhtian/minor, /obj/item/clothing/shoes/ruuhtian/minor, /obj/item/storage/belt/marine/covenant/ruuhtian/minor)
	new_human.equip_to_slot_or_del(new /obj/item/weapon/gun/energy/plasma/plasma_pistol(new_human), WEAR_J_STORE)

// =================================
// Major
// =================================

/datum/equipment_preset/covenant/ruuhtian/major
	name = parent_type::name + " Major"
	assignment = JOB_COV_MAJOR
	rank = JOB_COV_MAJOR
	paygrades = list(PAY_SHORT_COV_MAJOR = JOB_PLAYTIME_TIER_0)
	role_comm_title = "Major"

/datum/equipment_preset/covenant/ruuhtian/major/load_gear(mob/living/carbon/human/new_human)
	equip_ruuhtian_basics(new_human, /obj/item/clothing/head/helmet/marine/ruuhtian, /obj/item/clothing/suit/marine/ruuhtian/major, /obj/item/clothing/shoes/ruuhtian/major, /obj/item/storage/belt/marine/covenant/ruuhtian/major)
	new_human.equip_to_slot_or_del(new /obj/item/weapon/gun/smg/covenant_needler(new_human), WEAR_J_STORE)
	add_needler_crystals(new_human, 5)

// =================================
// Ultra
// =================================

/datum/equipment_preset/covenant/ruuhtian/ultra
	name = parent_type::name + " Ultra"
	assignment = JOB_COV_ULTRA
	rank = JOB_COV_ULTRA
	paygrades = list(PAY_SHORT_COV_ULTRA = JOB_PLAYTIME_TIER_0)
	role_comm_title = "Ultra"

/datum/equipment_preset/covenant/ruuhtian/ultra/load_gear(mob/living/carbon/human/new_human)
	equip_ruuhtian_basics(new_human, /obj/item/clothing/head/helmet/marine/ruuhtian/major, /obj/item/clothing/suit/marine/ruuhtian/ultra, /obj/item/clothing/shoes/ruuhtian/ultra, /obj/item/storage/belt/marine/covenant/ruuhtian/ultra)
	new_human.equip_to_slot_or_del(new /obj/item/weapon/gun/energy/plasma/plasma_rifle(new_human), WEAR_J_STORE)

// =================================
// Marksman
// =================================

/datum/equipment_preset/covenant/ruuhtian/marksman
	name = parent_type::name + " Marksman"
	assignment = JOB_COV_MAJOR
	rank = JOB_COV_MAJOR
	paygrades = list(PAY_SHORT_COV_CHAMPION = JOB_PLAYTIME_TIER_0)
	role_comm_title = "Marksman"

/datum/equipment_preset/covenant/ruuhtian/marksman/load_gear(mob/living/carbon/human/new_human)
	equip_ruuhtian_basics(new_human, /obj/item/clothing/head/helmet/marine/ruuhtian/marksman, /obj/item/clothing/suit/marine/ruuhtian/major, /obj/item/clothing/shoes/ruuhtian/major, /obj/item/storage/belt/marine/covenant/ruuhtian/major)
	new_human.equip_to_slot_or_del(new /obj/item/weapon/gun/rifle/covenant_carbine(new_human), WEAR_J_STORE)
	add_carbine_mags(new_human, 5)

// AI-ONLY ROLES

/datum/equipment_preset/covenant/ruuhtian/ai
	name = "Kig-Yar AI"
	assignment = JOB_COV_MINOR
	rank = JOB_COV_MINOR

/datum/equipment_preset/covenant/ruuhtian/ai/minor_plasma
	name = "Kig-Yar Minor (Plasma)"

/datum/equipment_preset/covenant/ruuhtian/ai/minor_plasma/load_gear(mob/living/carbon/human/new_human)
	equip_ruuhtian_basics(new_human, /obj/item/clothing/head/helmet/marine/ruuhtian/headset, /obj/item/clothing/suit/marine/ruuhtian/minor, /obj/item/clothing/shoes/ruuhtian/minor, /obj/item/storage/belt/marine/covenant/ruuhtian/minor)
	new_human.equip_to_slot_or_del(new /obj/item/weapon/gun/energy/plasma/plasma_pistol(new_human), WEAR_J_STORE)

/datum/equipment_preset/covenant/ruuhtian/ai/major_needler
	name = "Kig-Yar Major (Needler)"
	assignment = JOB_COV_MAJOR
	rank = JOB_COV_MAJOR
	paygrades = list(PAY_SHORT_COV_MAJOR = JOB_PLAYTIME_TIER_0)
	role_comm_title = "Major"

/datum/equipment_preset/covenant/ruuhtian/ai/major_needler/load_gear(mob/living/carbon/human/new_human)
	equip_ruuhtian_basics(new_human, /obj/item/clothing/head/helmet/marine/ruuhtian, /obj/item/clothing/suit/marine/ruuhtian/major, /obj/item/clothing/shoes/ruuhtian/major, /obj/item/storage/belt/marine/covenant/ruuhtian/major)
	new_human.equip_to_slot_or_del(new /obj/item/weapon/gun/smg/covenant_needler(new_human), WEAR_J_STORE)
	add_needler_crystals(new_human, 5)

/datum/equipment_preset/covenant/ruuhtian/ai/ultra_plasma
	name = "Kig-Yar Ultra (Plasma)"
	assignment = JOB_COV_ULTRA
	rank = JOB_COV_ULTRA
	paygrades = list(PAY_SHORT_COV_ULTRA = JOB_PLAYTIME_TIER_0)
	role_comm_title = "Ultra"

/datum/equipment_preset/covenant/ruuhtian/ai/ultra_plasma/load_gear(mob/living/carbon/human/new_human)
	equip_ruuhtian_basics(new_human, /obj/item/clothing/head/helmet/marine/ruuhtian/major, /obj/item/clothing/suit/marine/ruuhtian/ultra, /obj/item/clothing/shoes/ruuhtian/ultra, /obj/item/storage/belt/marine/covenant/ruuhtian/ultra)
	new_human.equip_to_slot_or_del(new /obj/item/weapon/gun/energy/plasma/plasma_rifle(new_human), WEAR_J_STORE)

/datum/equipment_preset/covenant/ruuhtian/ai/marksman_carbine
	name = "Kig-Yar Marksman (Carbine)"
	assignment = JOB_COV_MAJOR
	rank = JOB_COV_MAJOR
	paygrades = list(PAY_SHORT_COV_CHAMPION = JOB_PLAYTIME_TIER_0)
	role_comm_title = "Marksman"

/datum/equipment_preset/covenant/ruuhtian/ai/marksman_carbine/load_gear(mob/living/carbon/human/new_human)
	equip_ruuhtian_basics(new_human, /obj/item/clothing/head/helmet/marine/ruuhtian/marksman, /obj/item/clothing/suit/marine/ruuhtian/major, /obj/item/clothing/shoes/ruuhtian/major, /obj/item/storage/belt/marine/covenant/ruuhtian/major)
	new_human.equip_to_slot_or_del(new /obj/item/weapon/gun/rifle/covenant_carbine(new_human), WEAR_J_STORE)
	add_carbine_mags(new_human, 5)
