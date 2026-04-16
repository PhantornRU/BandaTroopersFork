/datum/world_edit_blueprint_service/proc/world_edit_build_blueprint_type_rules()
	. = list()

	world_edit_register_blueprint_type(., /obj/structure/barricade/metal, "barricade", "Metal Barricade")
	world_edit_register_blueprint_type(., /obj/structure/barricade/metal/wired, "barricade", "Metal Barricade - Wired")
	world_edit_register_blueprint_type(., /obj/structure/barricade/sandbags/full, "barricade", "Sandbags")
	world_edit_register_blueprint_type(., /obj/structure/barricade/metal/plasteel, "barricade", "Plasteel Barricade")
	world_edit_register_blueprint_type(., /obj/structure/barricade/metal/plasteel/wired, "barricade", "Plasteel Barricade - Wired")
	world_edit_register_blueprint_type(., /obj/structure/barricade/wooden, "barricade", "Wooden Barricade")

	world_edit_register_blueprint_type(., /obj/structure/machinery/defenses/sentry, "sentry", "USCM Sentry")
	world_edit_register_blueprint_type(., /obj/structure/machinery/defenses/sentry/dmr, "sentry", "USCM Sentry - DMR")
	world_edit_register_blueprint_type(., /obj/structure/machinery/defenses/sentry/shotgun, "sentry", "USCM Sentry - Shotgun")
	world_edit_register_blueprint_type(., /obj/structure/machinery/defenses/sentry/mini, "sentry", "USCM Sentry - Mini")
	world_edit_register_blueprint_type(., /obj/structure/machinery/defenses/sentry/upp, "sentry", "UPP Sentry")
	world_edit_register_blueprint_type(., /obj/structure/machinery/defenses/sentry/wy, "sentry", "W-Y Sentry")

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
