/obj/structure/machinery/cm_vending/sorted/marine_food/unsc
	name = "military food dispenser"
	desc = "Автоматизированная станция приготовления и выдачи пищи. Заранее подготавливает еду и напитки для персонала ККОН и автоматически очищает себя и возвращённые в неё подносы. Функцию самоочистки часто отключают, чтобы поддерживать дисциплину среди морпехов."
	icon = 'icons/halo/obj/structures/machinery/vending.dmi'
	icon_state = "top_unsc_food"
	tiles_with = list(
		/obj/structure/window/framed/unsc,
		/obj/structure/machinery/door/airlock,
		/turf/closed/wall/unsc,
	)

/obj/structure/machinery/cm_vending/sorted/marine_food/unsc/alt
	icon_state = "unsc_food"

/obj/structure/machinery/cm_vending/sorted/marine_food/unsc/odst

/obj/structure/machinery/cm_vending/sorted/marine_food/unsc/odst/alt
	parent_type = /obj/structure/machinery/cm_vending/sorted/marine_food/unsc/alt

/obj/structure/machinery/vending/dinnerware/unsc
	name = "\improper military utensils dispenser"
	desc = "В паре с пищевым автоматом эта машина выглядит куда проще и требует лишь ручного пополнения."
	icon = 'icons/halo/obj/structures/machinery/vending.dmi'
	icon_state = "top_unsc_dinnerware"
	icon_vend = "top_unsc_dinnerware_vend"
	icon_deny = "top_unsc_dinnerware_deny"
	tiles_with = list(
		/obj/structure/window/framed/unsc,
		/obj/structure/machinery/door/airlock,
		/turf/closed/wall/unsc,
	)

/obj/structure/machinery/vending/dinnerware/unsc/alt
	icon_state = "unsc_dinnerware"
	icon_vend = "unsc_dinnerware_vend"
	icon_deny = "unsc_dinnerware_deny"

/obj/structure/machinery/cm_vending/sorted/medical/unsc
	name = "\improper Optican Military Supply"
	desc = "Автомат по выдаче медикаментов и фармацевтики. Поставляется компанией Optican."
	icon = 'icons/halo/obj/structures/machinery/vending.dmi'
	icon_state = "shipmed"
	vendor_theme = VENDOR_THEME_USCM
	vend_flags = VEND_TO_HAND

/obj/structure/machinery/cm_vending/sorted/medical/unsc/odst

/obj/structure/machinery/cm_vending/sorted/medical/unsc/populate_product_list(scale)
	listed_products = list(
		list("halo essential medical supplies", -1, null, null),
		list("halo syringe", floor(scale * 7), /obj/item/reagent_container/syringe/halo, VENDOR_ITEM_MANDATORY),
		list("halo empty UNSC first-aid kit", floor(scale * 1), /obj/item/storage/firstaid/unsc/empty, VENDOR_ITEM_REGULAR),
		list("halo syringe case", floor(scale * 2), /obj/item/storage/syringe_case/unsc, VENDOR_ITEM_REGULAR),

		list("halo field supplies", -1, null, null),
		list("halo ointment", floor(scale * 10), /obj/item/stack/medical/ointment, VENDOR_ITEM_REGULAR),
		list("halo roll of gauze", floor(scale * 10), /obj/item/stack/medical/bruise_pack, VENDOR_ITEM_REGULAR),
		list("halo medical splints", floor(scale * 10), /obj/item/stack/medical/splint, VENDOR_ITEM_REGULAR),

		list("halo trauma treatment", -1, null, null),
		list("halo trauma kit", floor(scale * 10), /obj/item/stack/medical/advanced/bruise_pack, VENDOR_ITEM_RECOMMENDED),
		list("halo bicaridine autoinjector", floor(scale * 5), /obj/item/reagent_container/hypospray/autoinjector/bicaridine/halo, VENDOR_ITEM_REGULAR),
		list("halo medical bottle (bicaridine)", floor(scale * 3), /obj/item/reagent_container/glass/beaker/unsc/bicaridine, VENDOR_ITEM_RECOMMENDED),

		list("halo burn treatment", -1, null, null),
		list("halo burn kit", floor(scale * 10), /obj/item/stack/medical/advanced/ointment, VENDOR_ITEM_RECOMMENDED),
		list("halo optican burnguard autoinjector", floor(scale * 9), /obj/item/reagent_container/hypospray/autoinjector/primeable/burnguard, VENDOR_ITEM_RECOMMENDED),

		list("halo hypoxia treatment", -1, null, null),
		list("halo dexalin plus autoinjector", floor(scale * 5), /obj/item/reagent_container/hypospray/autoinjector/dexalinp/halo, VENDOR_ITEM_RECOMMENDED),
		list("halo medical bottle (dexalin)", floor(scale * 3), /obj/item/reagent_container/glass/beaker/unsc/dexalin, VENDOR_ITEM_REGULAR),

		list("halo pain management", -1, null, null),
		list("halo oxycodone autoinjector", floor(scale * 5), /obj/item/reagent_container/hypospray/autoinjector/oxycodone/halo, VENDOR_ITEM_REGULAR),
		list("halo tramadol autoinjector", floor(scale * 5), /obj/item/reagent_container/hypospray/autoinjector/tramadol/halo, VENDOR_ITEM_REGULAR),
		list("halo medical bottle (tramadol)", floor(scale * 3), /obj/item/reagent_container/glass/beaker/unsc/tramadol, VENDOR_ITEM_REGULAR),
		list("halo medical bottle (oxycodone)", floor(scale * 3), /obj/item/reagent_container/glass/beaker/unsc/oxycodone, VENDOR_ITEM_REGULAR),

		list("halo other treatment", -1, null, null),
		list("halo inaprovaline autoinjector", floor(scale * 5), /obj/item/reagent_container/hypospray/autoinjector/inaprovaline/halo, VENDOR_ITEM_REGULAR),
		list("halo peridaxon autoinjector", floor(scale * 5), /obj/item/reagent_container/hypospray/autoinjector/halo_peridaxon, VENDOR_ITEM_REGULAR),
		list("halo dylovene autoinjector", floor(scale * 5), /obj/item/reagent_container/hypospray/autoinjector/dylovene/halo, VENDOR_ITEM_REGULAR),
		list("halo medical bottle (inaprovaline)", floor(scale * 3), /obj/item/reagent_container/glass/beaker/unsc/inaprovaline, VENDOR_ITEM_REGULAR),
		list("halo medical bottle (peridaxon)", floor(scale * 3), /obj/item/reagent_container/glass/beaker/unsc/peridaxon, VENDOR_ITEM_REGULAR),
		list("halo medical bottle (dylovene)", floor(scale * 3), /obj/item/reagent_container/glass/beaker/unsc/dylovene, VENDOR_ITEM_REGULAR),
		list("halo medical bottle (chorotazine)", floor(scale * 3), /obj/item/reagent_container/glass/beaker/unsc/chorotazine, VENDOR_ITEM_RECOMMENDED),

		list("halo medical instruments", -1, null, null),
		list("halo surgical line", floor(scale * 2), /obj/item/tool/surgery/surgical_line, VENDOR_ITEM_REGULAR),
		list("halo synth-graft", floor(scale * 2), /obj/item/tool/surgery/synthgraft, VENDOR_ITEM_REGULAR),
		list("halo health analyzer", floor(scale * 5), /obj/item/device/healthanalyzer/halo, VENDOR_ITEM_REGULAR),
		list("halo medical webbing M8A", floor(scale * 2), /obj/item/storage/belt/medical/unsc, VENDOR_ITEM_REGULAR),
		list("halo lifesaver bag M8A", floor(scale * 2), /obj/item/storage/belt/medical/lifesaver/unsc, VENDOR_ITEM_REGULAR),
		list("halo medical HUD glasses", floor(scale * 3), /obj/item/clothing/glasses/hud/health, VENDOR_ITEM_REGULAR)
	)

GLOBAL_LIST_INIT(cm_vending_chemical_medic_halo, list(
		list("halo medical bottles", 0, null, null, null),
		list("halo medical bottle (iron)", 40, /obj/item/reagent_container/glass/beaker/unsc/iron, null, VENDOR_ITEM_REGULAR),
		list("halo medical bottle (meralyne)", 40, /obj/item/reagent_container/glass/beaker/unsc/meralyne, null, VENDOR_ITEM_REGULAR),
		list("halo medical bottle (dermaline)", 40, /obj/item/reagent_container/glass/beaker/unsc/dermaline, null, VENDOR_ITEM_REGULAR),
		list("halo medical bottle (dexalin plus)", 40, /obj/item/reagent_container/glass/beaker/unsc/dexplus, null, VENDOR_ITEM_REGULAR),
	))

/obj/structure/machinery/cm_vending/gear/medic_chemical/unsc
	name = "\improper Optican Military Chemical Supply"
	desc = "Автоматизированная стойка со специализированной химией для госпитального корсмана ККОН."
	icon = 'icons/halo/obj/structures/machinery/vending_32x64.dmi'
	icon_state = "chemvendor"
	show_points = TRUE
	use_snowflake_points = TRUE
	vendor_role = list(JOB_SQUAD_MEDIC, JOB_SQUAD_MEDIC_UNSC, JOB_SQUAD_MEDIC_ODST)
	req_access = list(ACCESS_MARINE_MEDPREP)

/obj/structure/machinery/cm_vending/gear/medic_chemical/unsc/get_listed_products(mob/user)
	translate_vendor_entries_to_ru(GLOB.cm_vending_chemical_medic_halo)
	return GLOB.cm_vending_chemical_medic_halo

/obj/structure/machinery/cm_vending/gear/medic_chemical/unsc/odst
