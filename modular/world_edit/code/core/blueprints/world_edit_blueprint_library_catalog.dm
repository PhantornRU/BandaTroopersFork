/datum/world_edit_blueprint_service/proc/world_edit_build_blueprint_type_rules()
	. = list()

	world_edit_register_blueprint_type(., /obj/structure/barricade/metal, "barricade", "Металлическая баррикада")
	world_edit_register_blueprint_type(., /obj/structure/barricade/metal/wired, "barricade", "Металлическая баррикада с проволокой")
	world_edit_register_blueprint_type(., /obj/structure/barricade/sandbags/full, "barricade", "Мешки с песком")
	world_edit_register_blueprint_type(., /obj/structure/barricade/metal/plasteel, "barricade", "Пласталевая баррикада")
	world_edit_register_blueprint_type(., /obj/structure/barricade/metal/plasteel/wired, "barricade", "Пласталевая баррикада с проволокой")
	world_edit_register_blueprint_type(., /obj/structure/barricade/wooden, "barricade", "Деревянная баррикада")

	world_edit_register_blueprint_type(., /obj/structure/machinery/defenses/sentry, "sentry", "Турель USCM")
	world_edit_register_blueprint_type(., /obj/structure/machinery/defenses/sentry/dmr, "sentry", "Турель USCM DMR")
	world_edit_register_blueprint_type(., /obj/structure/machinery/defenses/sentry/shotgun, "sentry", "Турель USCM дробовик")
	world_edit_register_blueprint_type(., /obj/structure/machinery/defenses/sentry/mini, "sentry", "Турель USCM mini")
	world_edit_register_blueprint_type(., /obj/structure/machinery/defenses/sentry/upp, "sentry", "Турель UPP")
	world_edit_register_blueprint_type(., /obj/structure/machinery/defenses/sentry/wy, "sentry", "Турель W-Y")

	world_edit_register_blueprint_type(., /obj/structure/closet/crate/ammo, "support_prop", "Ящик с боеприпасами")
	world_edit_register_blueprint_type(., /obj/structure/closet/crate/medical, "support_prop", "Медицинский ящик")
	world_edit_register_blueprint_type(., /obj/structure/bed/medevac_stretcher, "support_prop", "Медэвак-носилки")
	world_edit_register_blueprint_type(., /obj/structure/largecrate/supply/generator, "support_prop", "Ящик с генератором")
	world_edit_register_blueprint_type(., /obj/structure/deployable_beacon, "support_prop", "Развертываемый маяк")

	world_edit_register_blueprint_type(., /obj/structure/barricade/plasteel/metal, "barricade", "Metal Folding Barricade")
	world_edit_register_blueprint_type(., /obj/structure/barricade/plasteel/metal/wired, "barricade", "Metal Folding Barricade - Wired")
	world_edit_register_blueprint_type(., /obj/structure/barricade/plasteel, "barricade", "Plasteel Folding Barricade")
	world_edit_register_blueprint_type(., /obj/structure/barricade/plasteel/wired, "barricade", "Plasteel Folding Barricade - Wired")

/datum/world_edit_blueprint_service/proc/world_edit_register_blueprint_type(list/rules, obj_path, category, label)
	rules["[obj_path]"] = list(
		"obj_path" = obj_path,
		"category" = category,
		"label" = label,
	)

/datum/world_edit_blueprint_service/proc/world_edit_get_blueprint_type_rule(obj_path)
	if(!ispath(obj_path, /obj))
		return null
	return world_edit_blueprint_type_rules["[obj_path]"]
