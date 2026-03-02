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
	if(!controller?.active_template)
		set_button_state(RTO_SUPPORT_BUTTON_STATE_DISABLED, TRUE)
		set_button_countdown(null)
		return
	var/datum/rto_visibility_zone/zone = controller.get_active_zone()
	var/remaining_zone = max(0, zone?.expires_at - world.time)
	var/remaining_cooldown = controller.get_remaining_visibility_cooldown()
	var/status = RTO_SUPPORT_STATUS_AVAILABLE
	var/disabled = FALSE
	var/button_state = RTO_SUPPORT_BUTTON_STATE_READY

	set_name("[controller.active_template.visibility_zone_name]")
	if(controller.is_action_armed(RTO_SUPPORT_ARM_VISIBILITY_ZONE))
		button_state = RTO_SUPPORT_BUTTON_STATE_ARMED
		status = RTO_SUPPORT_STATUS_TARGETING
		set_button_countdown("ARM", "#ffd25a")
	else if(zone)
		status = RTO_SUPPORT_STATUS_ACTIVE
		set_button_countdown("[round(remaining_zone / 10)]", "#7ee1ff")
	else if(!controller.has_rto_binocular())
		status = RTO_SUPPORT_STATUS_NO_BINOCULAR
		disabled = TRUE
		set_button_countdown("B", "#c6c6c6")
	else if(remaining_cooldown > 0)
		status = RTO_SUPPORT_STATUS_COOLDOWN
		disabled = TRUE
		set_button_countdown("[round(remaining_cooldown / 10)]", "#c6c6c6")
	else
		set_button_countdown(null)

	set_name("[controller.active_template.visibility_zone_name] ([status])")
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
	var/zone_required_missing = action_template.requires_visibility_zone && !controller.get_active_zone()
	var/has_binocular = controller.has_rto_binocular()
	var/status = RTO_SUPPORT_STATUS_AVAILABLE
	var/disabled = FALSE
	var/button_state = RTO_SUPPORT_BUTTON_STATE_READY

	if(controller.is_action_armed(action_template.action_id))
		button_state = RTO_SUPPORT_BUTTON_STATE_ARMED
		status = RTO_SUPPORT_STATUS_TARGETING
		set_button_countdown("ARM", "#ffd25a")
	else if(!has_binocular)
		status = RTO_SUPPORT_STATUS_NO_BINOCULAR
		disabled = TRUE
		set_button_countdown("B", "#c6c6c6")
	else if(remaining_cooldown > 0)
		status = RTO_SUPPORT_STATUS_COOLDOWN
		disabled = TRUE
		set_button_countdown("[round(remaining_cooldown / 10)]", "#c6c6c6")
	else if(zone_required_missing)
		status = RTO_SUPPORT_STATUS_NO_ZONE
		disabled = TRUE
		set_button_countdown("Z", "#c6c6c6")
	else
		set_button_countdown(null)

	set_name("[action_template.name] ([status])")
	set_button_state(button_state, disabled)
