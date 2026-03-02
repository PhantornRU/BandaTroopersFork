/// Runtime coordinator for one RTO owner.
/datum/rto_support_controller
	var/mob/living/carbon/human/owner
	var/datum/rto_support_template/active_template
	var/datum/rto_visibility_zone/active_zone
	var/datum/rto_manual_designation/manual_designation
	var/armed_action_id
	var/shared_cooldown_until = 0
	var/visibility_zone_cooldown_until = 0
	var/list/action_cooldowns = list()
	var/list/action_handles = list()
	var/datum/action/human_action/rto/select_preset/select_action
	var/datum/action/human_action/rto/visibility_zone/visibility_action
	var/datum/action/human_action/rto/coordinates/coordinates_action
	var/datum/action/human_action/rto/manual_marker/manual_marker_action
	var/list/support_actions = list()
	var/datum/rto_support_validation_service/validation_service
	var/datum/rto_support_dispatch_service/dispatch_service
	var/ui_refresh_timer_id = null
	var/runtime_initialized = FALSE

/datum/rto_support_controller/New(mob/living/carbon/human/new_owner)
	owner = new_owner
	. = ..()

/datum/rto_support_controller/Destroy()
	runtime_initialized = FALSE
	disarm_action()
	if(ui_refresh_timer_id)
		deltimer(ui_refresh_timer_id)
	ui_refresh_timer_id = null
	clear_active_zone(FALSE)
	clear_manual_designation()
	clear_actions()
	validation_service = null
	dispatch_service = null
	action_cooldowns = null
	action_handles = null
	support_actions = null
	owner = null
	active_template = null
	return ..()

/datum/rto_support_controller/proc/ensure_runtime()
	if(!owner || QDELETED(owner))
		return FALSE
	if(!validation_service)
		validation_service = new
	if(!dispatch_service)
		dispatch_service = new
	if(!action_cooldowns)
		action_cooldowns = list()
	if(!action_handles)
		action_handles = list()
	if(!support_actions)
		support_actions = list()
	if(!ui_refresh_timer_id)
		ui_refresh_timer_id = addtimer(CALLBACK(src, PROC_REF(refresh_action_handles)), 1 SECONDS, TIMER_LOOP|TIMER_STOPPABLE|TIMER_DELETE_ME)
	runtime_initialized = TRUE
	sync_actions()
	refresh_action_handles()
	return TRUE

/datum/rto_support_controller/proc/has_required_role()
	return owner && !QDELETED(owner) && owner.job == JOB_SQUAD_RTO

/datum/rto_support_controller/proc/get_available_templates()
	if(!owner || owner.job != JOB_SQUAD_RTO)
		return list()
	return build_rto_support_template_catalog()

/datum/rto_support_controller/proc/can_select_template()
	if(!owner || QDELETED(owner))
		return FALSE
	if(owner.job != JOB_SQUAD_RTO)
		return FALSE
	return !active_template

/datum/rto_support_controller/proc/select_template(template_type)
	ensure_runtime()
	if(!can_select_template())
		return FALSE
	var/datum/rto_support_template/template = find_template(template_type)
	if(!template)
		return FALSE
	active_template = template
	disarm_action()
	clear_active_zone(FALSE)
	visibility_zone_cooldown_until = 0
	sync_actions()
	refresh_action_handles()
	return TRUE

/datum/rto_support_controller/proc/get_active_template()
	return active_template

/datum/rto_support_controller/proc/get_action_templates()
	return active_template ? active_template.get_action_templates() : list()

/datum/rto_support_controller/proc/template_requires_zone()
	return !!active_template?.requires_visibility_zone

/datum/rto_support_controller/proc/get_active_zone()
	if(active_zone && !active_zone.is_active())
		clear_active_zone()
	return active_zone

/datum/rto_support_controller/proc/get_zone_state()
	if(!active_template || !template_requires_zone())
		return RTO_SUPPORT_ZONE_STATE_UNSUPPORTED
	if(get_active_zone())
		return RTO_SUPPORT_ZONE_STATE_ACTIVE
	if(get_remaining_visibility_cooldown() > 0)
		return RTO_SUPPORT_ZONE_STATE_COOLDOWN
	return RTO_SUPPORT_ZONE_STATE_READY

/datum/rto_support_controller/proc/get_zone_ready_in()
	return get_zone_state() == RTO_SUPPORT_ZONE_STATE_COOLDOWN ? get_remaining_visibility_cooldown() : 0

/datum/rto_support_controller/proc/get_zone_expires_in()
	var/datum/rto_visibility_zone/zone = get_active_zone()
	return zone ? max(0, zone.expires_at - world.time) : 0

/datum/rto_support_controller/proc/get_manual_designation()
	if(manual_designation && !manual_designation.is_active())
		clear_manual_designation()
	return manual_designation

/datum/rto_support_controller/proc/sync_runtime_state()
	if(!owner || QDELETED(owner))
		return FALSE
	if(!has_required_role())
		reset_armed_action()
		clear_active_zone(FALSE)
		clear_manual_designation()
		clear_actions()
		return FALSE
	if(owner.stat == DEAD)
		reset_armed_action()
		clear_active_zone()
		clear_manual_designation()
	if(armed_action_id && !has_rto_binocular())
		reset_armed_action()
	get_active_zone()
	get_manual_designation()
	return TRUE

/datum/rto_support_controller/proc/can_deploy_zone()
	if(!active_template || !template_requires_zone())
		return FALSE
	if(get_active_zone())
		return FALSE
	return get_remaining_visibility_cooldown() <= 0

/datum/rto_support_controller/proc/deploy_zone(turf/target_turf)
	ensure_runtime()
	if(!active_template || !template_requires_zone() || !target_turf)
		return FALSE

	replace_active_zone(new /datum/rto_visibility_zone(owner, target_turf, active_template))

	if(active_template.visibility_support_path)
		var/datum/rto_support_request/request = new
		request.owner = owner
		request.target_turf = target_turf
		request.template = active_template
		request.visibility_zone = active_zone
		request.dispatch_key = RTO_SUPPORT_REQUEST_VISIBILITY
		request.dispatch_path = active_template.visibility_support_path
		request.display_name = active_template.visibility_zone_name
		request.request_kind = RTO_SUPPORT_REQUEST_VISIBILITY
		request.target_marker_style = active_template.visibility_target_marker_style
		request.announce_to_ghosts = FALSE
		dispatch_service.dispatch_request(request)

	if(owner)
		to_chat(owner, SPAN_NOTICE("[active_template.visibility_zone_name]: активна."))
	refresh_action_handles()
	return TRUE

/datum/rto_support_controller/proc/can_arm_action(action_id)
	if(!action_id)
		return FALSE
	if(action_id == RTO_SUPPORT_ARM_COORDINATES || action_id == RTO_SUPPORT_ARM_MARKER)
		return TRUE
	if(!active_template)
		return FALSE
	if(action_id == RTO_SUPPORT_ARM_VISIBILITY_ZONE)
		return can_deploy_zone()

	var/datum/rto_support_action_template/action_template = active_template.get_action_template(action_id)
	if(!action_template)
		return FALSE
	if(get_remaining_shared_cooldown() > 0)
		return FALSE
	if(get_remaining_action_cooldown(action_id) > 0)
		return FALSE
	if(action_template.requires_visibility_zone && template_requires_zone() && !get_active_zone())
		return FALSE
	return TRUE

/datum/rto_support_controller/proc/arm_action(action_id)
	ensure_runtime()
	if(!owner || QDELETED(owner))
		return FALSE
	if(!has_rto_binocular())
		to_chat(owner, SPAN_WARNING("Нужен RTO-бинокль."))
		return FALSE
	if(!can_arm_action(action_id))
		var/message = get_action_block_message(action_id)
		if(message)
			to_chat(owner, SPAN_WARNING(message))
		return FALSE
	if(armed_action_id == action_id)
		return disarm_action()
	armed_action_id = action_id
	refresh_action_handles()
	return TRUE

/datum/rto_support_controller/proc/disarm_action()
	if(!reset_armed_action())
		return FALSE
	refresh_action_handles()
	return TRUE

/datum/rto_support_controller/proc/reset_armed_action()
	if(!armed_action_id)
		return FALSE
	armed_action_id = null
	return TRUE

/datum/rto_support_controller/proc/handle_binocular_target(turf/target_turf, mob/living/carbon/human/user)
	ensure_runtime()
	if(!armed_action_id || !target_turf || user != owner)
		return FALSE

	var/obj/item/device/binoculars/rto/binoculars = get_active_binocular()
	if(!binoculars)
		to_chat(user, SPAN_WARNING("Нужно смотреть через RTO-бинокль."))
		return FALSE

	if(armed_action_id == RTO_SUPPORT_ARM_COORDINATES)
		var/datum/rto_support_validation_result/coordinate_result = validation_service.validate_coordinate_target(src, target_turf, user, binoculars)
		if(!coordinate_result.success)
			if(coordinate_result.message)
				to_chat(user, SPAN_WARNING("Координаты: [coordinate_result.message]"))
			return FALSE
		acquire_explicit_coordinates(target_turf, user)
		disarm_action()
		return TRUE

	if(armed_action_id == RTO_SUPPORT_ARM_MARKER)
		var/datum/rto_support_validation_result/marker_result = validation_service.validate_manual_marker_target(src, target_turf, user, binoculars)
		if(!marker_result.success)
			if(marker_result.message)
				to_chat(user, SPAN_WARNING("Лазерная отметка: [marker_result.message]"))
			return FALSE
		place_manual_designation(target_turf, user)
		disarm_action()
		return TRUE

	if(armed_action_id == RTO_SUPPORT_ARM_VISIBILITY_ZONE)
		var/datum/rto_support_validation_result/zone_result = validation_service.validate_zone_deploy(src, target_turf, user, binoculars)
		if(!zone_result.success)
			if(zone_result.message)
				to_chat(user, SPAN_WARNING("[active_template?.visibility_zone_name || "Сектор наведения"]: [zone_result.message]"))
			return FALSE
		var/zone_success = deploy_zone(target_turf)
		if(zone_success)
			disarm_action()
		return zone_success

	var/datum/rto_support_action_template/action_template = active_template?.get_action_template(armed_action_id)
	if(!action_template)
		return FALSE

	var/datum/rto_support_validation_result/support_result = validation_service.validate_support_call(src, action_template, target_turf, user, binoculars)
	if(!support_result.success)
		if(support_result.message)
			to_chat(user, SPAN_WARNING("[action_template.name]: [support_result.message]"))
		return FALSE

	var/datum/rto_support_request/request = new
	request.owner = owner
	request.target_turf = target_turf
	request.template = active_template
	request.action_template = action_template
	request.visibility_zone = get_active_zone()
	request.dispatch_key = RTO_SUPPORT_REQUEST_SUPPORT
	request.dispatch_path = action_template.fire_support_path
	request.scatter_override = action_template.scatter
	request.display_name = action_template.name
	request.request_kind = RTO_SUPPORT_REQUEST_SUPPORT
	request.target_marker_style = action_template.target_marker_style
	request.requires_visibility_zone = action_template.requires_visibility_zone
	request.announce_to_ghosts = TRUE

	if(!dispatch_service.dispatch_request(request))
		return FALSE

	shared_cooldown_until = world.time + action_template.shared_cooldown
	action_cooldowns[action_template.action_id] = world.time + action_template.personal_cooldown
	to_chat(user, SPAN_NOTICE("[action_template.name] подтвержден."))
	disarm_action()
	refresh_action_handles()
	return TRUE

/datum/rto_support_controller/proc/build_preset_ui_data()
	var/list/data = list()
	for(var/datum/rto_support_template/template as anything in get_available_templates())
		var/datum/rto_support_ui_preset_entry/entry = template.build_ui_entry()
		data += list(entry.to_list())
	return data

/datum/rto_support_controller/proc/find_template(template_type)
	for(var/datum/rto_support_template/template as anything in get_available_templates())
		if(template.template_id == template_type)
			return template
	return null

/datum/rto_support_controller/proc/replace_active_zone(datum/rto_visibility_zone/new_zone)
	clear_active_zone(FALSE)
	active_zone = new_zone

/datum/rto_support_controller/proc/clear_active_zone(apply_cooldown = TRUE)
	var/datum/rto_visibility_zone/zone = active_zone
	active_zone = null
	if(!zone)
		return FALSE

	var/datum/rto_support_template/source_template = zone.source_template
	zone.expire()
	qdel(zone)

	if(apply_cooldown && source_template?.requires_visibility_zone && source_template.visibility_zone_cooldown > 0)
		visibility_zone_cooldown_until = max(visibility_zone_cooldown_until, world.time + source_template.visibility_zone_cooldown)
	return TRUE

/datum/rto_support_controller/proc/clear_manual_designation()
	if(!manual_designation)
		return FALSE
	manual_designation.expire()
	qdel(manual_designation)
	manual_designation = null
	return TRUE

/datum/rto_support_controller/proc/place_manual_designation(turf/target_turf, mob/living/carbon/human/user)
	var/had_designation = !!get_manual_designation()
	clear_manual_designation()
	manual_designation = new(owner, target_turf, RTO_SUPPORT_MARKER_STATIC, RTO_SUPPORT_MANUAL_MARKER_DURATION)
	if(user)
		if(had_designation)
			to_chat(user, SPAN_NOTICE("Лазерная отметка обновлена."))
		else
			to_chat(user, SPAN_NOTICE("Лазерная отметка установлена."))
		send_coordinate_report(target_turf, user, "ОТМЕТКА")
	refresh_action_handles()
	return TRUE

/datum/rto_support_controller/proc/acquire_explicit_coordinates(turf/target_turf, mob/living/carbon/human/user)
	spawn_rto_laser_marker(target_turf, RTO_SUPPORT_MARKER_COORDINATE, RTO_SUPPORT_COORDINATE_MARKER_DURATION)
	send_coordinate_report(target_turf, user, "КООРДИНАТЫ")
	playsound(user, 'sound/effects/binoctarget.ogg', 35)
	refresh_action_handles()
	return TRUE

/datum/rto_support_controller/proc/send_coordinate_report(turf/target_turf, mob/living/carbon/human/user, label = "КООРДИНАТЫ")
	if(!target_turf || !user)
		return FALSE
	to_chat(user, SPAN_NOTICE("[label]: LONGITUDE [obfuscate_x(target_turf.x)]. LATITUDE [obfuscate_y(target_turf.y)]."))
	return TRUE

/datum/rto_support_controller/proc/get_armed_mode_name()
	if(!armed_action_id)
		return null
	switch(armed_action_id)
		if(RTO_SUPPORT_ARM_VISIBILITY_ZONE)
			return active_template?.visibility_zone_name || "Сектор наведения"
		if(RTO_SUPPORT_ARM_COORDINATES)
			return "Координаты"
		if(RTO_SUPPORT_ARM_MARKER)
			return "Лазерная отметка"
	var/datum/rto_support_action_template/action_template = active_template?.get_action_template(armed_action_id)
	return action_template?.name

/datum/rto_support_controller/proc/clear_actions()
	remove_select_action()
	remove_visibility_action()
	remove_coordinates_action()
	remove_manual_marker_action()
	remove_support_actions()
	action_handles = list()

/datum/rto_support_controller/proc/sync_actions()
	if(!owner || QDELETED(owner) || owner.job != JOB_SQUAD_RTO)
		clear_actions()
		return

	ensure_coordinates_action()
	ensure_manual_marker_action()

	if(!active_template)
		ensure_select_action()
		remove_visibility_action()
		remove_support_actions()
		rebuild_action_handles()
		return

	remove_select_action()
	if(template_requires_zone())
		ensure_visibility_action()
	else
		remove_visibility_action()
	ensure_support_actions()
	rebuild_action_handles()

/datum/rto_support_controller/proc/ensure_select_action()
	if(select_action && !QDELETED(select_action))
		return
	select_action = new /datum/action/human_action/rto/select_preset(src)
	select_action.give_to(owner)

/datum/rto_support_controller/proc/remove_select_action()
	if(!select_action)
		return
	if(select_action.owner)
		select_action.remove_from(select_action.owner)
	qdel(select_action)
	select_action = null

/datum/rto_support_controller/proc/ensure_visibility_action()
	if(visibility_action && !QDELETED(visibility_action))
		return
	visibility_action = new /datum/action/human_action/rto/visibility_zone(src)
	visibility_action.give_to(owner)

/datum/rto_support_controller/proc/remove_visibility_action()
	if(!visibility_action)
		return
	if(visibility_action.owner)
		visibility_action.remove_from(visibility_action.owner)
	qdel(visibility_action)
	visibility_action = null

/datum/rto_support_controller/proc/ensure_coordinates_action()
	if(coordinates_action && !QDELETED(coordinates_action))
		return
	coordinates_action = new /datum/action/human_action/rto/coordinates(src)
	coordinates_action.give_to(owner)

/datum/rto_support_controller/proc/remove_coordinates_action()
	if(!coordinates_action)
		return
	if(coordinates_action.owner)
		coordinates_action.remove_from(coordinates_action.owner)
	qdel(coordinates_action)
	coordinates_action = null

/datum/rto_support_controller/proc/ensure_manual_marker_action()
	if(manual_marker_action && !QDELETED(manual_marker_action))
		return
	manual_marker_action = new /datum/action/human_action/rto/manual_marker(src)
	manual_marker_action.give_to(owner)

/datum/rto_support_controller/proc/remove_manual_marker_action()
	if(!manual_marker_action)
		return
	if(manual_marker_action.owner)
		manual_marker_action.remove_from(manual_marker_action.owner)
	qdel(manual_marker_action)
	manual_marker_action = null

/datum/rto_support_controller/proc/ensure_support_actions()
	var/list/valid_ids = list()
	for(var/datum/rto_support_action_template/action_template as anything in get_action_templates())
		valid_ids += action_template.action_id
		var/datum/action/human_action/rto/support/action = support_actions[action_template.action_id]
		if(action && !QDELETED(action))
			continue
		action = new /datum/action/human_action/rto/support(src, action_template)
		action.give_to(owner)
		support_actions[action_template.action_id] = action

	for(var/action_id in support_actions.Copy())
		if(action_id in valid_ids)
			continue
		remove_support_action(action_id)

/datum/rto_support_controller/proc/remove_support_actions()
	if(!support_actions)
		return
	for(var/action_id in support_actions.Copy())
		remove_support_action(action_id)

/datum/rto_support_controller/proc/remove_support_action(action_id)
	var/datum/action/human_action/rto/support/action = support_actions[action_id]
	support_actions -= action_id
	if(!action)
		return
	if(action.owner)
		action.remove_from(action.owner)
	qdel(action)

/datum/rto_support_controller/proc/rebuild_action_handles()
	action_handles = list()
	if(select_action && !QDELETED(select_action))
		action_handles += select_action
	if(visibility_action && !QDELETED(visibility_action))
		action_handles += visibility_action
	if(coordinates_action && !QDELETED(coordinates_action))
		action_handles += coordinates_action
	if(manual_marker_action && !QDELETED(manual_marker_action))
		action_handles += manual_marker_action
	for(var/action_id in support_actions)
		var/datum/action/human_action/rto/support/action = support_actions[action_id]
		if(action && !QDELETED(action))
			action_handles += action

/datum/rto_support_controller/proc/refresh_action_handles()
	if(!runtime_initialized)
		return
	if(!sync_runtime_state())
		return
	sync_actions()
	for(var/datum/action/human_action/rto/action as anything in action_handles.Copy())
		if(!action || QDELETED(action))
			action_handles -= action
			continue
		action.refresh_from_controller()

/datum/rto_support_controller/proc/handle_owner_death()
	reset_armed_action()
	clear_active_zone()
	clear_manual_designation()
	refresh_action_handles()
	return TRUE

/datum/rto_support_controller/proc/handle_owner_revived()
	if(!ensure_runtime())
		return FALSE
	sync_actions()
	refresh_action_handles()
	return TRUE

/datum/rto_support_controller/proc/handle_inventory_changed(obj/item/changed_item)
	if(!runtime_initialized)
		return FALSE
	var/had_armed_action = !!armed_action_id
	if(changed_item && !istype(changed_item, /obj/item/device/binoculars/rto) && !had_armed_action)
		return FALSE

	if(had_armed_action && !has_rto_binocular())
		reset_armed_action()
		if(owner && owner.stat != DEAD)
			to_chat(owner, SPAN_WARNING("RTO-бинокль недоступен. Наведение отменено."))
	refresh_action_handles()
	return TRUE

/datum/rto_support_controller/proc/get_remaining_shared_cooldown()
	return max(0, shared_cooldown_until - world.time)

/datum/rto_support_controller/proc/get_remaining_visibility_cooldown()
	return max(0, visibility_zone_cooldown_until - world.time)

/datum/rto_support_controller/proc/get_remaining_action_cooldown(action_id)
	var/cooldown_until = action_cooldowns[action_id]
	return max(0, cooldown_until - world.time)

/datum/rto_support_controller/proc/get_action_block_message(action_id)
	if(action_id == RTO_SUPPORT_ARM_COORDINATES || action_id == RTO_SUPPORT_ARM_MARKER)
		return null
	if(!active_template)
		return "Сначала выберите пакет поддержки."
	if(action_id == RTO_SUPPORT_ARM_VISIBILITY_ZONE)
		if(!template_requires_zone())
			return "Этот пакет не использует сектор наведения."
		if(get_active_zone())
			return "[active_template.visibility_zone_name] уже активна: [round(get_zone_expires_in() / 10)] сек."
		var/zone_cooldown = get_remaining_visibility_cooldown()
		if(zone_cooldown > 0)
			return "[active_template.visibility_zone_name] перезаряжается: [round(zone_cooldown / 10)] сек."
		return null

	var/datum/rto_support_action_template/action_template = active_template.get_action_template(action_id)
	if(!action_template)
		return "Неизвестная способность поддержки."
	var/shared_cooldown = get_remaining_shared_cooldown()
	if(shared_cooldown > 0)
		return "Общий кулдаун: [round(shared_cooldown / 10)] сек."
	var/personal_cooldown = get_remaining_action_cooldown(action_id)
	if(personal_cooldown > 0)
		return "[action_template.name] перезаряжается: [round(personal_cooldown / 10)] сек."
	if(action_template.requires_visibility_zone && template_requires_zone())
		var/zone_state = get_zone_state()
		if(zone_state == RTO_SUPPORT_ZONE_STATE_COOLDOWN)
			return "Сектор наведения перезаряжается: [round(get_zone_ready_in() / 10)] сек."
		if(zone_state != RTO_SUPPORT_ZONE_STATE_ACTIVE)
			return "Сначала разверните сектор наведения."
	return null

/datum/rto_support_controller/proc/is_action_armed(action_id)
	return armed_action_id == action_id

/datum/rto_support_controller/proc/has_rto_binocular()
	return !!get_owned_binocular()

/datum/rto_support_controller/proc/get_owned_binocular()
	if(!owner)
		return null
	for(var/obj/item/device/binoculars/rto/binoculars as anything in owner.contents_recursive())
		return binoculars
	return null

/datum/rto_support_controller/proc/get_active_binocular()
	if(istype(owner?.interactee, /obj/item/device/binoculars/rto))
		return owner.interactee
	return null
