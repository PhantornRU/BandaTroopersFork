/// TGUI-backed preset selection menu for RTO support templates.
/datum/rto_support_preset_menu
	var/mob/living/carbon/human/user
	var/datum/rto_support_controller/controller
	var/closing = FALSE

/datum/rto_support_preset_menu/New(mob/living/carbon/human/new_user, datum/rto_support_controller/new_controller)
	user = new_user
	controller = new_controller
	. = ..()
	if(user)
		tgui_interact(user)

/datum/rto_support_preset_menu/Destroy()
	if(!closing)
		closing = TRUE
		SStgui.close_uis(src)
	user = null
	controller = null
	return ..()

/datum/rto_support_preset_menu/proc/request_close()
	if(closing)
		return FALSE
	closing = TRUE
	qdel(src)
	return TRUE

/datum/rto_support_preset_menu/tgui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "RtoSupportPresetMenu", "RTO Support")
		ui.open()

/datum/rto_support_preset_menu/ui_status(mob/user, datum/ui_state/state)
	if(!istype(user, /mob/living/carbon/human))
		return UI_CLOSE
	if(!controller)
		return UI_CLOSE
	if(user != controller?.owner)
		return UI_CLOSE
	if(!controller.can_open_template_menu())
		return UI_CLOSE
	return UI_INTERACTIVE

/datum/rto_support_preset_menu/proc/build_selected_template_ui_data()
	var/list/data = list()
	if(!controller)
		return data
	for(var/datum/rto_support_template/template as anything in controller.get_selected_templates())
		data += list(list(
			"template_id" = template.template_id,
			"name" = template.name,
		))
	return data

/datum/rto_support_preset_menu/ui_static_data(mob/user)
	var/list/templates = list()
	if(controller)
		templates = controller.build_preset_ui_data()
	return list(
		"templates" = templates,
		"max_selected_templates" = controller?.max_selected_templates || 2,
	)

/datum/rto_support_preset_menu/ui_data(mob/user)
	var/list/templates = list()
	var/list/selected_templates = list()
	var/can_add_template = FALSE
	var/can_reset_templates = FALSE
	var/reset_ready_in = 0
	var/selected_count = 0
	if(controller)
		templates = controller.build_preset_ui_data()
		selected_templates = build_selected_template_ui_data()
		selected_count = length(selected_templates)
		can_add_template = controller.can_add_template()
		can_reset_templates = controller.can_reset_templates()
		reset_ready_in = controller.get_selection_reset_ready_in()
	return list(
		"templates" = templates,
		"selected_templates" = selected_templates,
		"selected_count" = selected_count,
		"max_selected_templates" = controller?.max_selected_templates || 2,
		"can_add_template" = can_add_template,
		"can_reset_templates" = can_reset_templates,
		"reset_ready_in" = round(reset_ready_in / 10),
	)

/datum/rto_support_preset_menu/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("select_template")
			var/template_id = params["template_id"]
			if(!length(template_id))
				return FALSE
			var/datum/rto_support_template/template = controller?.find_template(template_id)
			if(!template)
				return FALSE
			var/confirm_choice = tgui_alert(
				user,
				"Вы уверены, что хотите добавить пакет поддержки \"[template.name]\" в свободный слот? Полный сброс обоих слотов станет доступен через 60 минут от первого выбора.",
				"Подтверждение выбора",
				list("Подтвердить", "Отмена"),
				15 SECONDS,
			)
			if(confirm_choice != "Подтвердить")
				return FALSE
			if(!controller?.select_template(template_id))
				to_chat(user, SPAN_WARNING("Не удалось выбрать пакет поддержки."))
				return FALSE
			to_chat(user, SPAN_NOTICE("Пакет поддержки добавлен: [template.name]."))
			SStgui.update_uis(src)
			return TRUE
		if("reset_templates")
			if(!controller?.can_reset_templates())
				to_chat(user, SPAN_WARNING("Полный сброс слотов пока недоступен."))
				return FALSE
			var/confirm_reset = tgui_alert(
				user,
				"Сбросить оба слота пакетов поддержки и выбрать их заново?",
				"Сброс пакетов",
				list("Сбросить", "Отмена"),
				15 SECONDS,
			)
			if(confirm_reset != "Сбросить")
				return FALSE
			if(!controller.reset_templates())
				to_chat(user, SPAN_WARNING("Не удалось сбросить слоты пакетов."))
				return FALSE
			to_chat(user, SPAN_NOTICE("Слоты пакетов поддержки сброшены."))
			SStgui.update_uis(src)
			return TRUE

	return FALSE

/datum/rto_support_preset_menu/ui_close(mob/user)
	if(closing)
		return FALSE
	closing = TRUE
	qdel(src)
	return TRUE
