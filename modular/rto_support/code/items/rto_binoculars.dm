/// Dedicated binoculars for the RTO support workflow.
/obj/item/device/binoculars/rto
	name = "RTO binoculars"
	desc = "Бинокль оператора связи. Ctrl+Click по цели во время зума наводит сектор или поддержку, если выбрана способность."
	icon_state = "advanced_binoculars"
	uses_camo = FALSE
	zoom_offset = 11
	view_range = 12

/obj/item/device/binoculars/rto/clicked(mob/user, list/mods)
	if(!ishuman(user))
		return ..()
	if(mods[CTRL_CLICK] && CAN_PICKUP(user, src))
		var/datum/rto_support_controller/controller = ensure_rto_support_controller(user)
		if(controller?.armed_action_id)
			controller.disarm_action()
			to_chat(user, SPAN_NOTICE("Наведение поддержки отменено."))
			return TRUE
	return ..()

/obj/item/device/binoculars/rto/handle_click(mob/living/carbon/human/user, atom/targeted_atom, list/mods)
	if(!istype(user) || !mods[CTRL_CLICK])
		return FALSE
	if(user.stat != CONSCIOUS)
		to_chat(user, SPAN_WARNING("Вы не можете использовать [src] в текущем состоянии."))
		return FALSE
	if(mods[CLICK_CATCHER])
		return FALSE

	var/turf/target_turf = get_turf(targeted_atom)
	if(!target_turf || target_turf.z == 0)
		return FALSE

	var/datum/rto_support_controller/controller = ensure_rto_support_controller(user)
	if(controller?.armed_action_id)
		return controller.handle_binocular_target(target_turf, user)

	if(!can_see_target(target_turf, user))
		to_chat(user, SPAN_WARNING("Нет прямой видимости до точки."))
		return FALSE

	acquire_coordinates(target_turf, user)
	return TRUE

/obj/item/device/binoculars/rto/get_examine_text(mob/user)
	. = ..()
	if(!ishuman(user))
		return
	var/datum/rto_support_controller/controller = ensure_rto_support_controller(user)
	if(!controller)
		return
	if(controller.active_template)
		. += SPAN_NOTICE("Текущий пакет: [controller.active_template.name].")
	if(controller.get_active_zone())
		. += SPAN_NOTICE("Сектор наведения активен.")
	if(controller.armed_action_id)
		. += SPAN_NOTICE("Бинокль готов принять целеуказание.")

/obj/item/device/binoculars/rto/proc/acquire_coordinates(turf/target_turf, mob/living/carbon/human/user)
	to_chat(user, SPAN_NOTICE("КООРДИНАТЫ: LONGITUDE [obfuscate_x(target_turf.x)]. LATITUDE [obfuscate_y(target_turf.y)]."))
	playsound(src, 'sound/effects/binoctarget.ogg', 35)

/obj/item/device/binoculars/rto/proc/can_see_target(turf/target_turf, mob/living/carbon/human/user)
	if(QDELETED(target_turf))
		return FALSE
	if(target_turf.z != user.z)
		return FALSE
	if(!(user in viewers(zoom_offset + view_range + 1, target_turf)))
		return FALSE
	if(user.sight & SEE_TURFS)
		var/list/turf/path = get_line(user, target_turf, include_start_atom = FALSE)
		for(var/turf/turf_in_path as anything in path)
			if(turf_in_path.opacity)
				return FALSE
	return TRUE
