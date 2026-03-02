/// Runtime coordinator for one RTO owner.
/datum/rto_support_controller
	/// Human that owns this controller.
	var/mob/living/carbon/human/owner
	/// Active template selected for the current owner.
	var/datum/rto_support_template/active_template
	/// Active visibility sector for the current owner.
	var/datum/rto_visibility_zone/active_zone
	/// Action identifier currently armed for binocular targeting.
	var/armed_action_id
	/// Shared cooldown timestamp for the operator.
	var/shared_cooldown_until = 0
	/// Visibility zone action cooldown timestamp.
	var/visibility_zone_cooldown_until = 0
	/// Per-action cooldown timestamps.
	var/list/action_cooldowns = list()
	/// References to action datums that need visual refreshes.
	var/list/action_handles = list()
	/// Select-preset action.
	var/datum/action/human_action/rto/select_preset/select_action
	/// Visibility zone action.
	var/datum/action/human_action/rto/visibility_zone/visibility_action
	/// Support action instances keyed by action id.
	var/list/support_actions = list()
	/// Validation service.
	var/datum/rto_support_validation_service/validation_service
	/// Dispatch service.
	var/datum/rto_support_dispatch_service/dispatch_service
	/// Looping timer for button refreshes.
	var/ui_refresh_timer_id = null
	/// Signal registration guard.
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
	clear_active_zone()
	clear_actions()
	validation_service = null
	dispatch_service = null
	action_cooldowns = null
	action_handles = null
	support_actions = null
	owner = null
	active_template = null
	return ..()

/// Ensures the controller has its runtime helpers and HUD actions.
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

/// Returns whether the current owner is still a valid RTO holder for this controller.
/datum/rto_support_controller/proc/has_required_role()
	return owner && !QDELETED(owner) && owner.job == JOB_SQUAD_RTO

/// Returns all templates available to the owner.
/datum/rto_support_controller/proc/get_available_templates()
	if(!owner || owner.job != JOB_SQUAD_RTO)
		return list()
	return build_rto_support_template_catalog()

/// Checks whether the owner may select a template.
/datum/rto_support_controller/proc/can_select_template()
	if(!owner || QDELETED(owner))
		return FALSE
	if(owner.job != JOB_SQUAD_RTO)
		return FALSE
	return !active_template

/// Selects a template for the owner.
/datum/rto_support_controller/proc/select_template(template_type)
	ensure_runtime()
	if(!can_select_template())
		return FALSE
	var/datum/rto_support_template/template = find_template(template_type)
	if(!template)
		return FALSE
	active_template = template
	disarm_action()
	sync_actions()
	refresh_action_handles()
	return TRUE

/// Returns the currently active template.
/datum/rto_support_controller/proc/get_active_template()
	return active_template

/// Returns action template metadata for the current template.
/datum/rto_support_controller/proc/get_action_templates()
	return active_template ? active_template.get_action_templates() : list()

/// Returns the active visibility zone for the owner.
/datum/rto_support_controller/proc/get_active_zone()
	if(active_zone && !active_zone.is_active())
		clear_active_zone()
	return active_zone

/// Reconciles controller runtime state with current owner state.
/datum/rto_support_controller/proc/sync_runtime_state()
	if(!owner || QDELETED(owner))
		return FALSE
	if(!has_required_role())
		reset_armed_action()
		clear_active_zone()
		clear_actions()
		return FALSE
	if(owner.stat == DEAD)
		reset_armed_action()
		clear_active_zone()
	if(armed_action_id && !has_rto_binocular())
		reset_armed_action()
	get_active_zone()
	return TRUE

/// Checks whether the owner may deploy a visibility zone.
/datum/rto_support_controller/proc/can_deploy_zone()
	if(!active_template)
		return FALSE
	return get_remaining_visibility_cooldown() <= 0

/// Deploys a visibility zone at the supplied turf.
/datum/rto_support_controller/proc/deploy_zone(turf/target_turf)
	ensure_runtime()
	if(!active_template || !target_turf)
		return FALSE
	replace_active_zone(new /datum/rto_visibility_zone(owner, target_turf, active_template))
	visibility_zone_cooldown_until = world.time + active_template.visibility_zone_cooldown
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
		dispatch_service.dispatch_request(request)
	if(owner)
		to_chat(owner, SPAN_NOTICE("[active_template.visibility_zone_name]: [RTO_SUPPORT_STATUS_ACTIVE]."))
	refresh_action_handles()
	return TRUE

/// Checks whether a support action may be armed.
/datum/rto_support_controller/proc/can_arm_action(action_id)
	if(!active_template || !action_id)
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
	if(action_template.requires_visibility_zone && !get_active_zone())
		return FALSE
	return TRUE

/// Arms an action for future binocular targeting.
/datum/rto_support_controller/proc/arm_action(action_id)
	ensure_runtime()
	if(!owner || QDELETED(owner))
		return FALSE
	if(!has_rto_binocular())
		to_chat(owner, SPAN_WARNING("Для этого нужен RTO-бинокль."))
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

/// Clears the current armed action.
/datum/rto_support_controller/proc/disarm_action()
	if(!reset_armed_action())
		return FALSE
	refresh_action_handles()
	return TRUE

/// Clears the current armed action without refreshing the HUD.
/datum/rto_support_controller/proc/reset_armed_action()
	if(!armed_action_id)
		return FALSE
	armed_action_id = null
	return TRUE

/// Handles a turf chosen through the RTO binocular flow.
/datum/rto_support_controller/proc/handle_binocular_target(turf/target_turf, mob/living/carbon/human/user)
	ensure_runtime()
	if(!armed_action_id || !target_turf || user != owner)
		return FALSE
	var/obj/item/device/binoculars/rto/binoculars = get_active_binocular()
	if(!binoculars)
		to_chat(user, SPAN_WARNING("Нужно смотреть через RTO-бинокль."))
		return FALSE
	if(armed_action_id == RTO_SUPPORT_ARM_VISIBILITY_ZONE)
		var/datum/rto_support_validation_result/zone_result = validation_service.validate_zone_deploy(src, target_turf, user, binoculars)
		if(!zone_result.success)
			if(zone_result.message)
				to_chat(user, SPAN_WARNING(zone_result.message))
			return FALSE
		var/success = deploy_zone(target_turf)
		if(success)
			disarm_action()
		return success

	var/datum/rto_support_action_template/action_template = active_template?.get_action_template(armed_action_id)
	if(!action_template)
		return FALSE

	var/datum/rto_support_validation_result/support_result = validation_service.validate_support_call(src, action_template, target_turf, user, binoculars)
	if(!support_result.success)
		if(support_result.message)
			to_chat(user, SPAN_WARNING(support_result.message))
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

	if(!dispatch_service.dispatch_request(request))
		return FALSE

	shared_cooldown_until = world.time + action_template.shared_cooldown
	action_cooldowns[action_template.action_id] = world.time + action_template.personal_cooldown
	to_chat(user, SPAN_NOTICE("[action_template.name] подтвержден."))
	disarm_action()
	refresh_action_handles()
	return TRUE

/// Builds UI-facing preset data for the preset menu.
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
	clear_active_zone()
	active_zone = new_zone

/datum/rto_support_controller/proc/clear_active_zone()
	if(active_zone)
		active_zone.expire()
		qdel(active_zone)
	active_zone = null

/datum/rto_support_controller/proc/clear_actions()
	remove_select_action()
	remove_visibility_action()
	remove_support_actions()
	action_handles = list()

/datum/rto_support_controller/proc/sync_actions()
	if(!owner || QDELETED(owner) || owner.job != JOB_SQUAD_RTO)
		clear_actions()
		return
	if(!active_template)
		ensure_select_action()
		remove_visibility_action()
		remove_support_actions()
		rebuild_action_handles()
		return
	remove_select_action()
	ensure_visibility_action()
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

/// Clears temporary state that should not survive owner death.
/datum/rto_support_controller/proc/handle_owner_death()
	reset_armed_action()
	clear_active_zone()
	refresh_action_handles()
	return TRUE

/// Rebuilds HUD state after owner revival.
/datum/rto_support_controller/proc/handle_owner_revived()
	if(!ensure_runtime())
		return FALSE
	sync_actions()
	refresh_action_handles()
	return TRUE

/// Reconciles armed state after inventory changes.
/datum/rto_support_controller/proc/handle_inventory_changed(obj/item/changed_item)
	if(!runtime_initialized)
		return FALSE
	if(changed_item && !istype(changed_item, /obj/item/device/binoculars/rto) && !armed_action_id)
		return FALSE
	var/had_armed_action = !!armed_action_id
	var/has_binocular = has_rto_binocular()
	if(had_armed_action && !has_binocular)
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
	if(!active_template)
		return "Сначала выберите пакет поддержки."
	if(action_id == RTO_SUPPORT_ARM_VISIBILITY_ZONE)
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
		return "Кулдаун способности: [round(personal_cooldown / 10)] сек."
	if(action_template.requires_visibility_zone && !get_active_zone())
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
