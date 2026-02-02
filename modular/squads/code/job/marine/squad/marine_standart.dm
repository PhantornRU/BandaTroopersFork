
// Слоты выставлены в соответствии с одним Alpha отрядом

// Морпех
/datum/job/marine/standard/ai
	total_positions = 8
	spawn_positions = 8

// Инженер - у альфы нет, добавляется от тех. отряда
/datum/job/marine/engineer/ai
	total_positions = 0
	spawn_positions = 0

// Медик
/datum/job/marine/medic/ai
	total_positions = 2
	spawn_positions = 2

// Смартганнер
/datum/job/marine/smartgunner/ai
	total_positions = 2
	spawn_positions = 2

// Оператор
/datum/job/marine/standard/ai/rto
	total_positions = 1
	spawn_positions = 1

/datum/equipment_preset/uscm/rto
	access = list(ACCESS_MARINE_PREP, ACCESS_MARINE_SPECPREP, ACCESS_MARINE_TL_PREP)
	skills = /datum/skills/military/survivor/forecon_standard

/datum/equipment_preset/uscm/rto/load_gear(mob/living/carbon/human/new_human)
	add_forecon_uniform(new_human)
	add_combat_gloves(new_human)
	new_human.equip_to_slot_or_del(new /obj/item/clothing/accessory/ranks/marine/e5(new_human), WEAR_ACCESSORY)
	new_human.equip_to_slot_or_del(new /obj/item/storage/backpack/marine/satchel/rto(new_human), WEAR_BACK)
	new_human.equip_to_slot_or_del(new /obj/item/storage/pouch/firstaid/full(new_human), WEAR_R_STORE)
	new_human.equip_to_slot_or_del(new /obj/item/storage/pouch/firstaid/full/alternate(new_human), WEAR_L_STORE)
	new_human.equip_to_slot_or_del(new /obj/item/reagent_container/food/drinks/flask/marine(new_human), WEAR_IN_ACCESSORY)
	new_human.equip_to_slot_or_del(new /obj/item/storage/box/mre/fsr(new_human), WEAR_IN_ACCESSORY)
	new_human.equip_to_slot_or_del(new /obj/item/tool/crowbar/tactical(new_human), WEAR_IN_ACCESSORY)
	new_human.equip_to_slot_or_del(new /obj/item/device/binoculars/range/designator(new_human), WEAR_IN_BACK)
	new_human.equip_to_slot_or_del(new /obj/item/clothing/shoes/marine/knife(new_human), WEAR_FEET)
	new_human.equip_to_slot_or_del(new /obj/item/device/radio/headset/almayer/marine/solardevils/forecon(new_human), WEAR_L_EAR)
	new_human.equip_to_slot_or_del(new /obj/item/clothing/suit/marine/rto/forecon(new_human), WEAR_JACKET)

	GLOB.character_traits[/datum/character_trait/skills/spotter].apply_trait(new_human)
	
	var/random_cover = rand(1,3)	// ---------- Проверить что гир нормально надевается, а после разместить шкафы
	switch(random_cover)
		if(1 to 2)
			new_human.equip_to_slot_or_del(new /obj/item/clothing/head/helmet/marine(new_human), WEAR_HEAD)
			add_uscm_cover(new_human)
		if(3)
			new_human.equip_to_slot_or_del(new 	/obj/item/device/overwatch_camera(new_human), WEAR_R_EAR)

// Лидер группы
/datum/job/marine/tl
	total_positions = 2
	spawn_positions = 2

// Сквадной
/datum/job/marine/leader/ai
	total_positions = 1
	spawn_positions = 1

// СО
/datum/job/command/bridge/ai
	total_positions = 1
	spawn_positions = 1
