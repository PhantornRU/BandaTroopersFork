/// Base class for RTO HUD actions.
/datum/action/human_action/rto
	name = "RTO Action"
	button_icon_state = "template"
	var/datum/rto_support_controller/controller

/datum/action/human_action/rto/New(datum/rto_support_controller/new_controller)
	controller = new_controller
	..()
	button.icon_state = "template"
	refresh_from_controller()

/datum/action/human_action/rto/Destroy()
	controller = null
	return ..()

/datum/action/human_action/rto/can_use_action()
	var/mob/living/carbon/human/human = owner
	return istype(human) && !human.is_mob_incapacitated() && !HAS_TRAIT(human, TRAIT_DAZED)

/datum/action/human_action/rto/proc/refresh_from_controller()
	return

/datum/action/human_action/rto/proc/set_button_state(button_state, disabled = FALSE)
	if(!button)
		return
	button.icon_state = button_state == RTO_SUPPORT_BUTTON_STATE_ARMED ? "template_on" : "template"
	if(button_state == RTO_SUPPORT_BUTTON_STATE_ARMED)
		button.color = rgb(255, 210, 90, 255)
		return
	if(disabled)
		button.color = rgb(120, 120, 120, 220)
		return
	button.color = rgb(255, 255, 255, 255)

/datum/action/human_action/rto/proc/set_button_countdown(text, color = "#f2f2f2")
	if(!button)
		return
	if(!length(text))
		button.set_maptext(null)
		return
	button.set_maptext(SMALL_FONTS_COLOR(7, text, color), 18, 2)

/datum/action/human_action/rto/proc/format_seconds(ds_value)
	return "[round(max(0, ds_value) / 10)]s"

/datum/action/human_action/rto/select_preset
	name = "Выбрать пакет поддержки"
	action_icon_state = "designator_swap_mortar"

/datum/action/human_action/rto/select_preset/action_activate()
	. = ..()
	if(!can_use_action())
		return
	if(!controller?.can_select_template())
		to_chat(owner, SPAN_WARNING("Пакет поддержки уже выбран."))
		return
	new /datum/rto_support_preset_menu(owner, controller)

/datum/action/human_action/rto/select_preset/refresh_from_controller()
	set_name("Выбрать пакет поддержки")
	set_button_state(RTO_SUPPORT_BUTTON_STATE_READY)
	set_button_countdown(null)

/datum/action/human_action/rto/visibility_zone
	name = "Развернуть сектор наведения"

/datum/action/human_action/rto/visibility_zone/New(datum/rto_support_controller/new_controller)
	if(new_controller?.active_template)
		name = new_controller.active_template.visibility_zone_name
		icon_file = new_controller.active_template.visibility_action_icon_file
		action_icon_state = new_controller.active_template.visibility_action_icon_state
	..()

/datum/action/human_action/rto/visibility_zone/action_activate()
	. = ..()
	if(!can_use_action())
		return
	if(controller?.is_action_armed(RTO_SUPPORT_ARM_VISIBILITY_ZONE))
		controller.disarm_action()
		return
	controller?.arm_action(RTO_SUPPORT_ARM_VISIBILITY_ZONE)

/datum/action/human_action/rto/visibility_zone/refresh_from_controller()
	if(!controller?.active_template || !controller.template_requires_zone())
		set_button_state(RTO_SUPPORT_BUTTON_STATE_DISABLED, TRUE)
		set_button_countdown(null)
		return

	var/zone_state = controller.get_zone_state()
	var/remaining_zone = controller.get_zone_expires_in()
	var/remaining_cooldown = controller.get_zone_ready_in()
	var/disabled = FALSE
	var/button_state = RTO_SUPPORT_BUTTON_STATE_READY
	var/button_name = controller.active_template.visibility_zone_name

	if(controller.is_action_armed(RTO_SUPPORT_ARM_VISIBILITY_ZONE))
		button_state = RTO_SUPPORT_BUTTON_STATE_ARMED
		button_name = "[button_name] ([RTO_SUPPORT_STATUS_TARGETING])"
		set_button_countdown("ARM", "#ffd25a")
	else if(zone_state == RTO_SUPPORT_ZONE_STATE_ACTIVE)
		disabled = TRUE
		button_name = "[button_name] ([RTO_SUPPORT_STATUS_ACTIVE]: [format_seconds(remaining_zone)])"
		set_button_countdown(format_seconds(remaining_zone), "#7ee1ff")
	else if(!controller.has_rto_binocular())
		disabled = TRUE
		button_name = "[button_name] ([RTO_SUPPORT_STATUS_NO_BINOCULAR])"
		set_button_countdown("B", "#c6c6c6")
	else if(zone_state == RTO_SUPPORT_ZONE_STATE_COOLDOWN)
		disabled = TRUE
		button_name = "[button_name] (CD: [format_seconds(remaining_cooldown)])"
		set_button_countdown(format_seconds(remaining_cooldown), "#c6c6c6")
	else
		button_name = "[button_name] ([RTO_SUPPORT_STATUS_READY])"
		set_button_countdown(null)

	set_name(button_name)
	set_button_state(button_state, disabled)

/datum/action/human_action/rto/coordinates
	name = "Координаты"
	action_icon_state = "spotter_target"
	icon_file = 'icons/mob/hud/actions.dmi'

/datum/action/human_action/rto/coordinates/action_activate()
	. = ..()
	if(!can_use_action())
		return
	if(controller?.is_action_armed(RTO_SUPPORT_ARM_COORDINATES))
		controller.disarm_action()
		return
	controller?.arm_action(RTO_SUPPORT_ARM_COORDINATES)

/datum/action/human_action/rto/coordinates/refresh_from_controller()
	var/disabled = FALSE
	var/button_state = RTO_SUPPORT_BUTTON_STATE_READY
	var/button_name = "Координаты"

	if(controller?.is_action_armed(RTO_SUPPORT_ARM_COORDINATES))
		button_state = RTO_SUPPORT_BUTTON_STATE_ARMED
		button_name = "[button_name] ([RTO_SUPPORT_STATUS_TARGETING])"
		set_button_countdown("ARM", "#ffd25a")
	else if(!controller?.has_rto_binocular())
		disabled = TRUE
		button_name = "[button_name] ([RTO_SUPPORT_STATUS_NO_BINOCULAR])"
		set_button_countdown("B", "#c6c6c6")
	else
		button_name = "[button_name] ([RTO_SUPPORT_STATUS_READY])"
		set_button_countdown(null)

	set_name(button_name)
	set_button_state(button_state, disabled)

/datum/action/human_action/rto/manual_marker
	name = "Лазерная отметка"
	action_icon_state = "designator_mortar"
	icon_file = 'icons/mob/hud/actions.dmi'

/datum/action/human_action/rto/manual_marker/action_activate()
	. = ..()
	if(!can_use_action())
		return
	if(controller?.is_action_armed(RTO_SUPPORT_ARM_MARKER))
		controller.disarm_action()
		return
	controller?.arm_action(RTO_SUPPORT_ARM_MARKER)

/datum/action/human_action/rto/manual_marker/refresh_from_controller()
	var/datum/rto_manual_designation/designation = controller?.get_manual_designation()
	var/remaining_designation = designation ? max(0, designation.expires_at - world.time) : 0
	var/disabled = FALSE
	var/button_state = RTO_SUPPORT_BUTTON_STATE_READY
	var/button_name = "Лазерная отметка"

	if(controller?.is_action_armed(RTO_SUPPORT_ARM_MARKER))
		button_state = RTO_SUPPORT_BUTTON_STATE_ARMED
		button_name = "[button_name] ([RTO_SUPPORT_STATUS_TARGETING])"
		set_button_countdown("ARM", "#ffd25a")
	else if(!controller?.has_rto_binocular())
		disabled = TRUE
		button_name = "[button_name] ([RTO_SUPPORT_STATUS_NO_BINOCULAR])"
		set_button_countdown("B", "#c6c6c6")
	else if(designation)
		button_name = "[button_name] ([RTO_SUPPORT_STATUS_ACTIVE]: [format_seconds(remaining_designation)])"
		set_button_countdown(format_seconds(remaining_designation), "#7ee1ff")
	else
		button_name = "[button_name] ([RTO_SUPPORT_STATUS_READY])"
		set_button_countdown(null)

	set_name(button_name)
	set_button_state(button_state, disabled)

/datum/action/human_action/rto/support
	unique = FALSE
	var/datum/rto_support_action_template/action_template

/datum/action/human_action/rto/support/New(datum/rto_support_controller/new_controller, datum/rto_support_action_template/new_action_template)
	action_template = new_action_template
	if(action_template)
		name = action_template.name
		icon_file = action_template.icon_file
		action_icon_state = action_template.icon_state
	..(new_controller)

/datum/action/human_action/rto/support/Destroy()
	action_template = null
	return ..()

/datum/action/human_action/rto/support/action_activate()
	. = ..()
	if(!can_use_action())
		return
	if(controller?.is_action_armed(action_template?.action_id))
		controller.disarm_action()
		return
	controller?.arm_action(action_template?.action_id)

/datum/action/human_action/rto/support/refresh_from_controller()
	if(!controller?.active_template || !action_template)
		set_button_state(RTO_SUPPORT_BUTTON_STATE_DISABLED, TRUE)
		set_button_countdown(null)
		return

	var/remaining_shared = controller.get_remaining_shared_cooldown()
	var/remaining_personal = controller.get_remaining_action_cooldown(action_template.action_id)
	var/remaining_cooldown = max(remaining_shared, remaining_personal)
	var/has_binocular = controller.has_rto_binocular()
	var/zone_required = action_template.requires_visibility_zone && controller.template_requires_zone()
	var/zone_state = controller.get_zone_state()
	var/zone_ready_in = controller.get_zone_ready_in()
	var/zone_expires_in = controller.get_zone_expires_in()
	var/disabled = FALSE
	var/button_state = RTO_SUPPORT_BUTTON_STATE_READY
	var/button_name = action_template.name

	if(controller.is_action_armed(action_template.action_id))
		button_state = RTO_SUPPORT_BUTTON_STATE_ARMED
		button_name = "[button_name] ([RTO_SUPPORT_STATUS_TARGETING])"
		set_button_countdown("ARM", "#ffd25a")
	else if(!has_binocular)
		disabled = TRUE
		button_name = "[button_name] ([RTO_SUPPORT_STATUS_NO_BINOCULAR])"
		set_button_countdown("B", "#c6c6c6")
	else if(zone_required && zone_state == RTO_SUPPORT_ZONE_STATE_COOLDOWN)
		disabled = TRUE
		button_name = "[button_name] (Зона CD: [format_seconds(zone_ready_in)])"
		set_button_countdown(format_seconds(zone_ready_in), "#c6c6c6")
	else if(zone_required && zone_state == RTO_SUPPORT_ZONE_STATE_ACTIVE)
		if(remaining_cooldown > 0)
			disabled = TRUE
			button_name = "[button_name] (Зона: [format_seconds(zone_expires_in)], КД: [format_seconds(remaining_cooldown)])"
		else
			button_name = "[button_name] (Зона: [format_seconds(zone_expires_in)])"
		set_button_countdown(format_seconds(zone_expires_in), "#7ee1ff")
	else if(remaining_cooldown > 0)
		disabled = TRUE
		button_name = "[button_name] (КД: [format_seconds(remaining_cooldown)])"
		set_button_countdown(format_seconds(remaining_cooldown), "#c6c6c6")
	else if(zone_required)
		disabled = TRUE
		button_name = "[button_name] ([RTO_SUPPORT_STATUS_NO_ZONE])"
		set_button_countdown("Z", "#c6c6c6")
	else
		button_name = "[button_name] ([RTO_SUPPORT_STATUS_READY])"
		set_button_countdown(null)

	set_name(button_name)
	set_button_state(button_state, disabled)
