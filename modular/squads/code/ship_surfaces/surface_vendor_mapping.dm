/datum/authority/branch/role/proc/get_ship_surface_target_vendor_type(vendor_key, target_family)
	switch(target_family)
		if(SHIP_SURFACE_FAMILY_USCM)
			switch(vendor_key)
				if(SHIP_SURFACE_VENDOR_SQUAD_PREP_UNIFORM)
					return /obj/structure/machinery/cm_vending/sorted/uniform_supply/squad_prep
				if(SHIP_SURFACE_VENDOR_SQUAD_PREP_GUNS)
					return /obj/structure/machinery/cm_vending/sorted/cargo_guns/squad
				if(SHIP_SURFACE_VENDOR_MEDIC_CLOTHING)
					return /obj/structure/machinery/cm_vending/clothing/medic
				if(SHIP_SURFACE_VENDOR_MEDIC_CHEMICAL)
					return /obj/structure/machinery/cm_vending/gear/medic_chemical
				if(SHIP_SURFACE_VENDOR_MEDBAY_BASIC)
					return /obj/structure/machinery/cm_vending/sorted/medical/marinemed
				if(SHIP_SURFACE_VENDOR_MARINE_FOOD, SHIP_SURFACE_VENDOR_MARINE_FOOD_ALT)
					return /obj/structure/machinery/cm_vending/sorted/marine_food
		if(SHIP_SURFACE_FAMILY_UNSC)
			switch(vendor_key)
				if(SHIP_SURFACE_VENDOR_SQUAD_PREP_UNIFORM)
					return /obj/structure/machinery/cm_vending/sorted/uniform_supply/squad_prep/unsc
				if(SHIP_SURFACE_VENDOR_SQUAD_PREP_GUNS)
					return /obj/structure/machinery/cm_vending/sorted/cargo_guns/squad/unsc
				if(SHIP_SURFACE_VENDOR_MEDIC_CLOTHING)
					return /obj/structure/machinery/cm_vending/clothing/medic/unsc
				if(SHIP_SURFACE_VENDOR_MEDIC_CHEMICAL)
					return /obj/structure/machinery/cm_vending/gear/medic_chemical/unsc
				if(SHIP_SURFACE_VENDOR_MEDBAY_BASIC)
					return /obj/structure/machinery/cm_vending/sorted/medical/unsc
				if(SHIP_SURFACE_VENDOR_MARINE_FOOD)
					return /obj/structure/machinery/cm_vending/sorted/marine_food/unsc
				if(SHIP_SURFACE_VENDOR_MARINE_FOOD_ALT)
					return /obj/structure/machinery/cm_vending/sorted/marine_food/unsc/alt
		if(SHIP_SURFACE_FAMILY_ODST)
			switch(vendor_key)
				if(SHIP_SURFACE_VENDOR_SQUAD_PREP_UNIFORM)
					return /obj/structure/machinery/cm_vending/sorted/uniform_supply/squad_prep/unsc/odst
				if(SHIP_SURFACE_VENDOR_SQUAD_PREP_GUNS)
					return /obj/structure/machinery/cm_vending/sorted/cargo_guns/squad/unsc/odst
				if(SHIP_SURFACE_VENDOR_MEDIC_CLOTHING)
					return /obj/structure/machinery/cm_vending/clothing/medic/unsc/odst
				if(SHIP_SURFACE_VENDOR_MEDIC_CHEMICAL)
					return /obj/structure/machinery/cm_vending/gear/medic_chemical/unsc/odst
				if(SHIP_SURFACE_VENDOR_MEDBAY_BASIC)
					return /obj/structure/machinery/cm_vending/sorted/medical/unsc/odst
				if(SHIP_SURFACE_VENDOR_MARINE_FOOD)
					return /obj/structure/machinery/cm_vending/sorted/marine_food/unsc/odst
				if(SHIP_SURFACE_VENDOR_MARINE_FOOD_ALT)
					return /obj/structure/machinery/cm_vending/sorted/marine_food/unsc/odst/alt

	return null

/datum/authority/branch/role/proc/replace_ship_surface_vendor(obj/structure/machinery/cm_vending/source_vendor, target_type)
	if(!istype(source_vendor) || !target_type)
		return null

	var/turf/vendor_turf = get_turf(source_vendor)
	if(!isturf(vendor_turf))
		return null

	var/obj/structure/machinery/cm_vending/target_vendor = new target_type(vendor_turf)
	copy_ship_surface_transform(source_vendor, target_vendor)

	for(var/atom/movable/movable as anything in source_vendor.contents)
		movable.forceMove(target_vendor)

	qdel(source_vendor)
	return target_vendor
