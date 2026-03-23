/// Runtime coordinator for one RTO owner.
/datum/rto_support_controller
	var/mob/living/carbon/human/owner
	var/list/selected_templates = list()
	var/datum/rto_visibility_zone/active_zone
	var/armed_action_id
	var/armed_template_id
	var/list/shared_cooldowns_by_template = list()
	var/zone_shared_cooldown_until = 0
	var/list/zone_cooldowns_by_template = list()
	var/list/action_cooldowns = list()
	var/list/action_handles = list()
	var/max_selected_templates = 2
	var/datum/action/human_action/rto/select_preset/select_action
	var/list/visibility_actions = list()
	var/datum/action/human_action/rto/coordinates/coordinates_action
	var/datum/action/human_action/rto/manual_marker/manual_marker_action
	var/list/support_actions = list()
	var/datum/rto_support_validation_service/validation_service
	var/datum/rto_support_dispatch_service/dispatch_service
	var/hud_tick_timer_id = null
	var/zone_expiry_timer_id = null
	var/last_binocular_in_hand = FALSE
	var/runtime_initialized = FALSE
	var/selection_started_at = 0
	var/selection_reset_available_at = 0

/datum/rto_support_controller/New(mob/living/carbon/human/new_owner)
	owner = new_owner
	. = ..()

/datum/rto_support_controller/Destroy()
	runtime_initialized = FALSE
	disarm_action()
	stop_hud_tick()
	clear_zone_expiry_timer()
	clear_active_zone(FALSE)
	clear_manual_designation()
	clear_actions()
	validation_service = null
	dispatch_service = null
	selected_templates = null
	shared_cooldowns_by_template = null
	zone_cooldowns_by_template = null
	action_cooldowns = null
	action_handles = null
	visibility_actions = null
	support_actions = null
	owner = null
	return ..()

/datum/rto_support_controller/proc/ensure_runtime()
	if(!owner || QDELETED(owner))
		return FALSE
	if(!validation_service)
		validation_service = new
	if(!dispatch_service)
		dispatch_service = new
	if(!selected_templates)
		selected_templates = list()
	if(!shared_cooldowns_by_template)
		shared_cooldowns_by_template = list()
	if(!zone_cooldowns_by_template)
		zone_cooldowns_by_template = list()
	if(!action_cooldowns)
		action_cooldowns = list()
	if(!action_handles)
		action_handles = list()
	if(!visibility_actions)
		visibility_actions = list()
	if(!support_actions)
		support_actions = list()
	runtime_initialized = TRUE
	sync_actions()
	last_binocular_in_hand = has_rto_binocular_in_hand()
	refresh_action_handles()
	return TRUE

/datum/rto_support_controller/proc/has_required_role()
	return owner && !QDELETED(owner) && GET_DEFAULT_ROLE(owner.job) == JOB_SQUAD_RTO

/datum/rto_support_controller/proc/get_support_profile()
	var/obj/item/device/binoculars/rto/binoculars = get_owned_binocular()
	if(binoculars)
		return binoculars.get_support_profile()
	if(owner?.job == JOB_SQUAD_RTO_UNSC)
		return "unsc"
	if(owner?.job == JOB_SQUAD_RTO_ODST)
		return "odst"
	return "uscm"

/datum/rto_support_controller/proc/get_available_templates()
	if(!owner || GET_DEFAULT_ROLE(owner.job) != JOB_SQUAD_RTO)
		return list()
	var/list/templates = GLOB.rto_support_registry?.get_template_catalog()
	if(!templates)
		return list()

	var/list/available_templates = list()
	for(var/datum/rto_support_template/template as anything in templates)
		if(!template?.is_available_to(src))
			continue
		available_templates += template

	return available_templates

/datum/rto_support_controller/proc/get_selected_templates()
	return selected_templates ? selected_templates.Copy() : list()

/datum/rto_support_controller/proc/get_selected_template_slot(template_type)
	if(!template_type || !length(selected_templates))
		return 0
	var/template_id = null
	if(istype(template_type, /datum/rto_support_template))
		var/datum/rto_support_template/template = template_type
		template_id = template.template_id
	else if(istext(template_type))
		template_id = template_type
	if(!template_id)
		return 0
	for(var/index in 1 to length(selected_templates))
		var/datum/rto_support_template/template = selected_templates[index]
		if(template?.template_id == template_id)
			return index
	return 0

/datum/rto_support_controller/proc/get_selected_template(template_type) as /datum/rto_support_template
	if(!template_type)
		return null
	if(istype(template_type, /datum/rto_support_template))
		var/datum/rto_support_template/template = template_type
		return get_selected_template_slot(template.template_id) ? template : null
	if(!istext(template_type))
		return null
	for(var/datum/rto_support_template/template as anything in selected_templates)
		if(template?.template_id == template_type)
			return template
	return null

/datum/rto_support_controller/proc/has_selected_template(template_type)
	return !!get_selected_template(template_type)

/datum/rto_support_controller/proc/get_primary_selected_template() as /datum/rto_support_template
	return length(selected_templates) ? selected_templates[1] : null

/datum/rto_support_controller/proc/can_open_template_menu()
	if(!owner || QDELETED(owner))
		return FALSE
	if(GET_DEFAULT_ROLE(owner.job) != JOB_SQUAD_RTO)
		return FALSE
	if(!is_support_enabled_by_rules())
		return FALSE
	return TRUE

/datum/rto_support_controller/proc/can_add_template()
	if(!can_open_template_menu())
		return FALSE
	return length(selected_templates) < max_selected_templates

/datum/rto_support_controller/proc/can_select_template()
	return can_add_template()

/datum/rto_support_controller/proc/can_add_specific_template(template_type)
	if(!can_add_template())
		return FALSE
	var/datum/rto_support_template/template = find_template(template_type)
	if(!template)
		return FALSE
	return !has_selected_template(template.template_id)

/datum/rto_support_controller/proc/can_reset_templates()
	if(!can_open_template_menu())
		return FALSE
	if(!length(selected_templates))
		return FALSE
	if(!selection_reset_available_at)
		return FALSE
	return world.time >= selection_reset_available_at

/datum/rto_support_controller/proc/get_selection_reset_ready_in()
	return max(0, selection_reset_available_at - world.time)

/datum/rto_support_controller/proc/select_template(template_type)
	ensure_runtime()
	if(!can_add_specific_template(template_type))
		return FALSE

	var/datum/rto_support_template/template = find_template(template_type)
	if(!template)
		return FALSE

	selected_templates += template
	if(!selection_started_at)
		selection_started_at = world.time
		selection_reset_available_at = world.time + 60 MINUTES

	sync_actions()
	refresh_action_handles()
	return TRUE

/datum/rto_support_controller/proc/reset_templates()
	ensure_runtime()
	if(!can_reset_templates())
		return FALSE

	disarm_action()
	clear_active_zone(FALSE)
	clear_manual_designation()
	selected_templates = list()
	shared_cooldowns_by_template = list()
	zone_cooldowns_by_template = list()
	action_cooldowns = list()
	zone_shared_cooldown_until = 0
	selection_started_at = 0
	selection_reset_available_at = 0

	sync_actions()
	refresh_action_handles()
	return TRUE

/datum/rto_support_controller/proc/get_active_template() as /datum/rto_support_template
	return get_primary_selected_template()

/datum/rto_support_controller/proc/get_template_for_action(action_id, template_type = null) as /datum/rto_support_template
	var/datum/rto_support_template/template = get_selected_template(template_type)
	if(template?.get_action_template(action_id))
		return template
	for(var/datum/rto_support_template/selected_template as anything in selected_templates)
		if(selected_template?.get_action_template(action_id))
			return selected_template
	return null

/datum/rto_support_controller/proc/get_action_templates(template_type = null)
	var/list/action_templates = list()
	var/datum/rto_support_template/template = get_selected_template(template_type)
	if(template)
		return template.get_action_templates()
	for(var/datum/rto_support_template/selected_template as anything in selected_templates)
		action_templates += selected_template.get_action_templates()
	return action_templates

/datum/rto_support_controller/proc/template_requires_zone(template_type = null)
	var/datum/rto_support_template/template = template_type ? get_selected_template(template_type) : get_primary_selected_template()
	return !!template?.requires_visibility_zone

/datum/rto_support_controller/proc/get_active_zone()
	if(active_zone && !active_zone.is_active())
		clear_active_zone()
	return active_zone

/datum/rto_support_controller/proc/get_zone_owner_template() as /datum/rto_support_template
	return get_active_zone()?.source_template

/datum/rto_support_controller/proc/get_zone_state(template_type = null)
	var/datum/rto_support_template/template = get_selected_template(template_type)
	if(!template)
		template = get_primary_selected_template()
	if(!template || !template_requires_zone(template))
		return RTO_SUPPORT_ZONE_STATE_UNSUPPORTED
	if(get_active_zone())
		return RTO_SUPPORT_ZONE_STATE_ACTIVE
	if(get_zone_ready_in(template) > 0)
		return RTO_SUPPORT_ZONE_STATE_COOLDOWN
	return RTO_SUPPORT_ZONE_STATE_READY

/datum/rto_support_controller/proc/get_zone_ready_in(template_type = null)
	var/datum/rto_support_template/template = get_selected_template(template_type)
	if(!template)
		template = get_primary_selected_template()
	if(!template || !template_requires_zone(template) || get_active_zone())
		return 0
	return max(get_remaining_zone_shared_cooldown(), get_remaining_zone_cooldown(template))

/datum/rto_support_controller/proc/get_zone_expires_in(template_type = null)
	var/datum/rto_visibility_zone/zone = get_active_zone()
	if(!zone)
		return 0
	if(template_type)
		var/datum/rto_support_template/template = get_selected_template(template_type)
		if(template && zone.source_template?.template_id != template.template_id)
			return 0
	return max(0, zone.expires_at - world.time)

/datum/rto_support_controller/proc/get_remaining_zone_shared_cooldown()
	return max(0, zone_shared_cooldown_until - world.time)

/datum/rto_support_controller/proc/get_remaining_zone_cooldown(template_type = null)
	var/datum/rto_support_template/template = get_selected_template(template_type)
	if(!template)
		template = get_primary_selected_template()
	if(!template)
		return 0
	var/cooldown_until = zone_cooldowns_by_template[template.template_id]
	return max(0, cooldown_until - world.time)

/datum/rto_support_controller/proc/get_solo_visibility_zone_cooldown(template_type = null)
	var/datum/rto_support_template/template = null
	if(istype(template_type, /datum/rto_support_template))
		template = template_type
	else if(istext(template_type))
		template = get_selected_template(template_type) || find_template(template_type)
	else
		template = get_primary_selected_template()
	if(!template?.requires_visibility_zone || template.visibility_zone_cooldown <= 0)
		return max(0, template?.visibility_zone_cooldown)
	return max(1, round(template.visibility_zone_cooldown / 2))

/datum/rto_support_controller/proc/uses_single_template_zone_discount(template_type = null)
	if(length(selected_templates) != 1)
		return FALSE
	var/datum/rto_support_template/template = null
	if(istype(template_type, /datum/rto_support_template))
		template = template_type
	else if(istext(template_type))
		template = get_selected_template(template_type)
	else
		template = get_primary_selected_template()
	if(!template?.requires_visibility_zone || template.visibility_zone_cooldown <= 0)
		return FALSE
	var/datum/rto_support_template/selected_template = get_primary_selected_template()
	return selected_template?.template_id == template.template_id

/datum/rto_support_controller/proc/get_effective_visibility_zone_cooldown(template_type = null)
	var/datum/rto_support_template/template = null
	if(istype(template_type, /datum/rto_support_template))
		template = template_type
	else if(istext(template_type))
		template = get_selected_template(template_type) || find_template(template_type)
	else
		template = get_primary_selected_template()
	if(!template?.requires_visibility_zone || template.visibility_zone_cooldown <= 0)
		return max(0, template?.visibility_zone_cooldown)
	if(uses_single_template_zone_discount(template))
		return get_solo_visibility_zone_cooldown(template)
	return template.visibility_zone_cooldown

/datum/rto_support_controller/proc/is_manual_marker_active()
	var/obj/item/device/binoculars/rto/binoculars = get_owned_binocular()
	return binoculars?.is_live_marker_active()

/datum/rto_support_controller/proc/sync_runtime_state()
	if(!validate_owner_runtime())
		return FALSE
	prune_zone_state()
	if(armed_action_id && !has_rto_binocular_in_hand())
		reset_armed_action()
	last_binocular_in_hand = has_rto_binocular_in_hand()
	return TRUE

/datum/rto_support_controller/proc/can_deploy_zone(template_type = null)
	var/datum/rto_support_template/template = get_selected_template(template_type)
	if(!template || !template_requires_zone(template))
		return FALSE
	if(get_active_zone())
		return FALSE
	if(get_remaining_zone_shared_cooldown() > 0)
		return FALSE
	return get_remaining_zone_cooldown(template) <= 0

/datum/rto_support_controller/proc/deploy_zone(turf/target_turf, template_type = null)
	ensure_runtime()
	var/datum/rto_support_template/template = get_selected_template(template_type)
	if(!template || !template_requires_zone(template) || !target_turf)
		return FALSE

	replace_active_zone(new /datum/rto_visibility_zone(owner, target_turf, template))

	if(template.visibility_support_path)
		var/datum/rto_support_request/request = new
		request.owner = owner
		request.target_turf = target_turf
		request.template = template
		request.visibility_zone = active_zone
		request.dispatch_key = RTO_SUPPORT_REQUEST_VISIBILITY
		request.dispatch_path = template.visibility_support_path
		request.display_name = template.visibility_zone_name
		request.request_kind = RTO_SUPPORT_REQUEST_VISIBILITY
		request.target_marker_style = template.visibility_target_marker_style
		request.announce_to_ghosts = FALSE
		dispatch_service.dispatch_request(request)

	if(owner)
		to_chat(owner, SPAN_NOTICE("[template.visibility_zone_name]: сектор развернут."))
	refresh_action_handles()
	return TRUE

/datum/rto_support_controller/proc/can_arm_action(action_id, template_type = null)
	if(!action_id)
		return FALSE
	if(action_id == RTO_SUPPORT_ARM_COORDINATES || action_id == RTO_SUPPORT_ARM_MARKER)
		return TRUE
	if(!is_support_enabled_by_rules())
		return FALSE

	if(action_id == RTO_SUPPORT_ARM_VISIBILITY_ZONE)
		return can_deploy_zone(template_type)

	var/datum/rto_support_template/template = get_template_for_action(action_id, template_type)
	if(!template)
		return FALSE

	var/datum/rto_support_action_template/action_template = template.get_action_template(action_id)
	if(!action_template)
		return FALSE
	if(get_remaining_shared_cooldown(template) > 0)
		return FALSE
	if(get_remaining_action_cooldown(action_id) > 0)
		return FALSE
	if(action_template.requires_visibility_zone && template_requires_zone(template))
		var/datum/rto_visibility_zone/zone = get_active_zone()
		if(!zone || zone.source_template?.template_id != template.template_id)
			return FALSE
	return TRUE

/datum/rto_support_controller/proc/arm_action(action_id, template_type = null)
	ensure_runtime()
	if(!owner || QDELETED(owner))
		return FALSE
	if(!has_rto_binocular_in_hand())
		to_chat(owner, SPAN_WARNING("Нужен RTO-бинокль в руке."))
		return FALSE
	if(!can_arm_action(action_id, template_type))
		var/message = get_action_block_message(action_id, template_type)
		if(message)
			to_chat(owner, SPAN_WARNING(message))
		return FALSE
	if(armed_action_id == action_id && armed_template_id == template_type)
		return disarm_action()
	reset_armed_action()
	armed_action_id = action_id
	armed_template_id = template_type
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
	if(armed_action_id == RTO_SUPPORT_ARM_MARKER)
		clear_manual_designation()
	armed_action_id = null
	armed_template_id = null
	return TRUE

/datum/rto_support_controller/proc/handle_binocular_target(turf/target_turf, mob/living/carbon/human/user)
	ensure_runtime()
	if(!armed_action_id || !target_turf || user != owner)
		return FALSE

	var/obj/item/device/binoculars/rto/binoculars = get_active_binocular()
	if(!binoculars)
		to_chat(user, SPAN_WARNING("Нужно смотреть через RTO-бинокль."))
		return FALSE

	var/datum/rto_support_template/template = get_selected_template(armed_template_id)

	if(armed_action_id == RTO_SUPPORT_ARM_COORDINATES)
		var/datum/rto_support_validation_result/coordinate_result = validation_service.validate_coordinate_target(src, target_turf, user, binoculars)
		if(!coordinate_result.success)
			if(coordinate_result.message)
				to_chat(user, SPAN_WARNING("Координаты: [coordinate_result.message]"))
			return FALSE
		acquire_explicit_coordinates(target_turf, user)
		return TRUE

	if(armed_action_id == RTO_SUPPORT_ARM_MARKER)
		var/datum/rto_support_validation_result/marker_result = validation_service.validate_manual_marker_target(src, target_turf, user, binoculars)
		if(!marker_result.success)
			if(marker_result.message)
				to_chat(user, SPAN_WARNING("Лазерная отметка: [marker_result.message]"))
			return FALSE
		place_manual_designation(target_turf, user)
		return TRUE

	if(armed_action_id == RTO_SUPPORT_ARM_VISIBILITY_ZONE)
		var/datum/rto_support_validation_result/zone_result = validation_service.validate_zone_deploy(src, template, target_turf, user, binoculars)
		if(!zone_result.success)
			if(zone_result.message)
				var/zone_name = template?.visibility_zone_name
				if(!zone_name || !length(zone_name))
					zone_name = "Сектор наведения"
				to_chat(user, SPAN_WARNING("[zone_name]: [zone_result.message]"))
			return FALSE
		var/zone_success = deploy_zone(target_turf, template?.template_id)
		if(zone_success)
			disarm_action()
		return zone_success

	if(!template)
		return FALSE

	var/datum/rto_support_action_template/action_template = template.get_action_template(armed_action_id)
	if(!action_template)
		return FALSE

	var/datum/rto_support_validation_result/support_result = validation_service.validate_support_call(src, template, action_template, target_turf, user, binoculars)
	if(!support_result.success)
		if(support_result.message)
			to_chat(user, SPAN_WARNING("[action_template.name]: [support_result.message]"))
		return FALSE

	var/datum/rto_support_request/request = new
	request.owner = owner
	request.target_turf = target_turf
	request.template = template
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

	shared_cooldowns_by_template[template.template_id] = world.time + get_effective_shared_cooldown(action_template)
	action_cooldowns[action_template.action_id] = world.time + get_effective_personal_cooldown(action_template)
	to_chat(user, SPAN_NOTICE("[action_template.name]: вызов подтвержден."))
	disarm_action()
	refresh_action_handles()
	return TRUE

/datum/rto_support_controller/proc/build_preset_ui_data()
	var/list/data = list()
	for(var/datum/rto_support_template/template as anything in get_available_templates())
		var/datum/rto_support_ui_preset_entry/entry = template.build_ui_entry(src)
		var/list/entry_data = entry.to_list()
		entry_data["is_selected"] = has_selected_template(template.template_id)
		entry_data["selected_slot"] = get_selected_template_slot(template.template_id)
		data += list(entry_data)
	return data

/datum/rto_support_controller/proc/find_template(template_type)
	var/datum/rto_support_template/template = GLOB.rto_support_registry?.find_template(template_type)
	if(!template?.is_available_to(src))
		return null
	return template

/datum/rto_support_controller/proc/is_support_enabled_by_rules()
	var/datum/game_rule_state/rules = GLOB.game_rule_state
	if(!rules)
		return TRUE
	return !!rules.rto_support_enabled

/datum/rto_support_controller/proc/get_effective_shared_cooldown(datum/rto_support_action_template/action_template)
	if(!action_template)
		return 0
	var/datum/game_rule_state/rules = GLOB.game_rule_state
	var/multiplier = rules ? rules.rto_shared_cooldown_multiplier : 1
	return max(1, round(max(1, action_template.shared_cooldown) * multiplier))

/datum/rto_support_controller/proc/get_effective_personal_cooldown(datum/rto_support_action_template/action_template)
	if(!action_template)
		return 0
	var/datum/game_rule_state/rules = GLOB.game_rule_state
	var/multiplier = rules ? rules.rto_personal_cooldown_multiplier : 1
	return max(1, round(max(1, action_template.personal_cooldown) * multiplier))

/datum/rto_support_controller/proc/is_action_restricted_by_rules(action_id)
	if(is_support_enabled_by_rules())
		return FALSE
	if(!action_id)
		return FALSE
	return action_id != RTO_SUPPORT_ARM_COORDINATES && action_id != RTO_SUPPORT_ARM_MARKER

/datum/rto_support_controller/proc/apply_rules_update()
	if(is_action_restricted_by_rules(armed_action_id))
		reset_armed_action()
	if(!is_support_enabled_by_rules() && active_zone)
		clear_active_zone(FALSE)
	refresh_action_handles()
	return TRUE

/datum/rto_support_controller/proc/replace_active_zone(datum/rto_visibility_zone/new_zone)
	clear_active_zone(FALSE)
	active_zone = new_zone
	schedule_zone_expiry()

/datum/rto_support_controller/proc/clear_active_zone(apply_cooldown = TRUE)
	var/datum/rto_visibility_zone/zone = active_zone
	active_zone = null
	clear_zone_expiry_timer()
	if(!zone)
		return FALSE

	var/datum/rto_support_template/source_template = zone.source_template
	zone.expire()
	qdel(zone)

	if(apply_cooldown && source_template?.requires_visibility_zone && source_template.visibility_zone_cooldown > 0)
		var/cooldown_until = world.time + get_effective_visibility_zone_cooldown(source_template)
		zone_shared_cooldown_until = max(zone_shared_cooldown_until, cooldown_until)
		zone_cooldowns_by_template[source_template.template_id] = max(zone_cooldowns_by_template[source_template.template_id], cooldown_until)
	return TRUE

/datum/rto_support_controller/proc/clear_manual_designation(obj/item/binoculars_override)
	var/obj/item/device/binoculars/rto/binoculars = null
	if(istype(binoculars_override, /obj/item/device/binoculars/rto) && !QDELETED(binoculars_override))
		binoculars = binoculars_override
	if(!binoculars)
		binoculars = get_owned_binocular()
	if(!binoculars)
		binoculars = get_rto_binocular_in_hand()
	binoculars?.stop_live_marker(owner, TRUE)
	return !!binoculars

/datum/rto_support_controller/proc/place_manual_designation(turf/target_turf, mob/living/carbon/human/user)
	var/obj/item/device/binoculars/rto/binoculars = get_active_binocular()
	if(!binoculars)
		return FALSE
	var/had_designation = binoculars.is_live_marker_active()
	clear_manual_designation()
	if(!binoculars.start_live_marker(target_turf, user))
		return FALSE
	if(user)
		if(had_designation)
			to_chat(user, SPAN_NOTICE("Лазерная отметка перенесена."))
		else
			to_chat(user, SPAN_NOTICE("Лазерная отметка активирована."))
		send_coordinate_report(target_turf, user, "Лазерная отметка")
	refresh_action_handles()
	return TRUE

/datum/rto_support_controller/proc/acquire_explicit_coordinates(turf/target_turf, mob/living/carbon/human/user)
	send_coordinate_report(target_turf, user, "Координаты")
	return TRUE

/datum/rto_support_controller/proc/send_coordinate_report(turf/target_turf, mob/living/carbon/human/user, label = "Координаты")
	if(!target_turf || !user)
		return FALSE
	to_chat(user, SPAN_NOTICE("[label]: долгота [obfuscate_x(target_turf.x)], широта [obfuscate_y(target_turf.y)]."))
	return TRUE

/datum/rto_support_controller/proc/get_armed_mode_name()
	if(!armed_action_id)
		return null
	switch(armed_action_id)
		if(RTO_SUPPORT_ARM_VISIBILITY_ZONE)
			return get_selected_template(armed_template_id)?.visibility_zone_name || "Сектор наведения"
		if(RTO_SUPPORT_ARM_COORDINATES)
			return "Координаты"
		if(RTO_SUPPORT_ARM_MARKER)
			return "Лазерная отметка"
	var/datum/rto_support_template/template = get_template_for_action(armed_action_id, armed_template_id)
	var/datum/rto_support_action_template/action_template = template?.get_action_template(armed_action_id)
	return action_template?.name

/datum/rto_support_controller/proc/clear_actions()
	remove_select_action()
	remove_visibility_actions()
	remove_coordinates_action()
	remove_manual_marker_action()
	remove_support_actions()
	action_handles = list()

/datum/rto_support_controller/proc/sync_actions()
	if(!owner || QDELETED(owner) || GET_DEFAULT_ROLE(owner.job) != JOB_SQUAD_RTO)
		clear_actions()
		return

	ensure_select_action()
	ensure_coordinates_action()
	ensure_manual_marker_action()
	ensure_visibility_actions()
	ensure_support_actions()
	rebuild_action_handles()
	sync_action_visibility()

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

/datum/rto_support_controller/proc/ensure_visibility_actions()
	var/list/valid_template_ids = list()
	for(var/datum/rto_support_template/template as anything in selected_templates)
		if(!template?.requires_visibility_zone)
			continue
		valid_template_ids += template.template_id
		var/datum/action/human_action/rto/visibility_zone/action = visibility_actions[template.template_id]
		if(action && !QDELETED(action))
			continue
		action = new /datum/action/human_action/rto/visibility_zone(src, template.template_id)
		action.give_to(owner)
		visibility_actions[template.template_id] = action

	for(var/template_id in visibility_actions.Copy())
		if(template_id in valid_template_ids)
			continue
		remove_visibility_action(template_id)

/datum/rto_support_controller/proc/remove_visibility_actions()
	if(!visibility_actions)
		return
	for(var/template_id in visibility_actions.Copy())
		remove_visibility_action(template_id)

/datum/rto_support_controller/proc/remove_visibility_action(template_id)
	var/datum/action/human_action/rto/visibility_zone/action = visibility_actions[template_id]
	visibility_actions -= template_id
	if(!action)
		return
	if(action.owner)
		action.remove_from(action.owner)
	qdel(action)

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
	var/list/valid_template_ids = list()
	for(var/datum/rto_support_template/template as anything in selected_templates)
		valid_template_ids += template.template_id
		var/list/template_actions = support_actions[template.template_id]
		if(!islist(template_actions))
			template_actions = list()
			support_actions[template.template_id] = template_actions

		var/list/valid_action_ids = list()
		for(var/datum/rto_support_action_template/action_template as anything in template.get_action_templates())
			valid_action_ids += action_template.action_id
			var/datum/action/human_action/rto/support/action = template_actions[action_template.action_id]
			if(action && !QDELETED(action))
				continue
			action = new /datum/action/human_action/rto/support(src, template.template_id, action_template)
			action.give_to(owner)
			template_actions[action_template.action_id] = action

		for(var/action_id in template_actions.Copy())
			if(action_id in valid_action_ids)
				continue
			remove_support_action(template.template_id, action_id)

	for(var/template_id in support_actions.Copy())
		if(template_id in valid_template_ids)
			continue
		remove_support_actions(template_id)

/datum/rto_support_controller/proc/remove_support_actions(template_id = null)
	if(!support_actions)
		return
	if(template_id)
		var/list/template_actions = support_actions[template_id]
		if(!islist(template_actions))
			support_actions -= template_id
			return
		for(var/action_id in template_actions.Copy())
			remove_support_action(template_id, action_id)
		support_actions -= template_id
		return
	for(var/selected_template_id in support_actions.Copy())
		remove_support_actions(selected_template_id)

/datum/rto_support_controller/proc/remove_support_action(template_id, action_id)
	var/list/template_actions = support_actions[template_id]
	if(!islist(template_actions))
		return
	var/datum/action/human_action/rto/support/action = template_actions[action_id]
	template_actions -= action_id
	if(!length(template_actions))
		support_actions -= template_id
	if(!action)
		return
	if(action.owner)
		action.remove_from(action.owner)
	qdel(action)

/datum/rto_support_controller/proc/rebuild_action_handles()
	action_handles = list()
	if(select_action && !QDELETED(select_action))
		action_handles += select_action
	for(var/datum/rto_support_template/template as anything in selected_templates)
		var/datum/action/human_action/rto/visibility_zone/visibility_action = visibility_actions[template.template_id]
		if(visibility_action && !QDELETED(visibility_action))
			action_handles += visibility_action
	if(coordinates_action && !QDELETED(coordinates_action))
		action_handles += coordinates_action
	if(manual_marker_action && !QDELETED(manual_marker_action))
		action_handles += manual_marker_action
	for(var/datum/rto_support_template/template as anything in selected_templates)
		var/list/template_actions = support_actions[template.template_id]
		if(!islist(template_actions))
			continue
		for(var/datum/rto_support_action_template/action_template as anything in template.get_action_templates())
			var/datum/action/human_action/rto/support/support_action = template_actions[action_template.action_id]
			if(support_action && !QDELETED(support_action))
				action_handles += support_action

/datum/rto_support_controller/proc/refresh_visible_actions()
	if(!runtime_initialized)
		return FALSE
	if(!validate_owner_runtime())
		return FALSE
	sync_actions()
	sync_action_visibility()
	last_binocular_in_hand = has_rto_binocular_in_hand()
	for(var/datum/action/human_action/rto/action as anything in action_handles.Copy())
		if(!action || QDELETED(action))
			action_handles -= action
			continue
		if(action.hidden)
			continue
		action.refresh_from_controller()
	return TRUE

/datum/rto_support_controller/proc/refresh_action_handles()
	if(!runtime_initialized)
		return
	prune_zone_state()
	if(!refresh_visible_actions())
		update_hud_tick_state()
		return
	update_hud_tick_state()

/datum/rto_support_controller/proc/handle_owner_death()
	reset_armed_action()
	clear_active_zone()
	clear_manual_designation()
	last_binocular_in_hand = FALSE
	refresh_action_handles()
	return TRUE

/datum/rto_support_controller/proc/handle_owner_revived()
	if(!ensure_runtime())
		return FALSE
	last_binocular_in_hand = has_rto_binocular_in_hand()
	sync_actions()
	refresh_action_handles()
	return TRUE

/datum/rto_support_controller/proc/handle_inventory_changed(obj/item/changed_item, slot = null, signal_id = null)
	var/was_in_hand = last_binocular_in_hand
	var/is_in_hand = has_rto_binocular_in_hand()
	if(!is_inventory_change_relevant(changed_item, slot, signal_id) && was_in_hand == is_in_hand)
		return FALSE
	if(armed_action_id && was_in_hand && !is_in_hand)
		reset_armed_action()
		if(owner && owner.stat != DEAD)
			to_chat(owner, SPAN_WARNING("RTO-бинокль убран из рук. Наведение отменено."))
	if(!is_in_hand)
		var/obj/item/device/binoculars/rto/dropped_binocular = istype(changed_item, /obj/item/device/binoculars/rto) ? changed_item : null
		clear_manual_designation(dropped_binocular)
	last_binocular_in_hand = is_in_hand
	refresh_action_handles()
	return TRUE

/datum/rto_support_controller/proc/is_inventory_change_relevant(obj/item/changed_item, slot = null, signal_id = null)
	if(istype(changed_item, /obj/item/device/binoculars/rto))
		return TRUE
	if(istype(changed_item, /obj/item/storage/pouch/sling/rto))
		return TRUE
	if(slot == WEAR_L_HAND || slot == WEAR_R_HAND)
		return last_binocular_in_hand || has_rto_binocular_in_hand()
	return FALSE

/datum/rto_support_controller/proc/get_remaining_shared_cooldown(template_type = null)
	var/datum/rto_support_template/template = get_selected_template(template_type)
	if(template)
		var/cooldown_until = shared_cooldowns_by_template[template.template_id]
		return max(0, cooldown_until - world.time)
	var/max_remaining = 0
	for(var/template_id in shared_cooldowns_by_template)
		max_remaining = max(max_remaining, max(0, shared_cooldowns_by_template[template_id] - world.time))
	return max_remaining

/datum/rto_support_controller/proc/get_remaining_visibility_cooldown(template_type = null)
	if(template_type)
		return get_remaining_zone_cooldown(template_type)
	return get_remaining_zone_shared_cooldown()

/datum/rto_support_controller/proc/get_remaining_action_cooldown(action_id)
	var/cooldown_until = action_cooldowns[action_id]
	return max(0, cooldown_until - world.time)

/datum/rto_support_controller/proc/format_block_messages(list/reasons)
	return length(reasons) ? jointext(reasons, "\n") : null

/datum/rto_support_controller/proc/build_visibility_action_state(template_type)
	var/datum/rto_support_template/template = get_selected_template(template_type)
	var/datum/rto_support_template/zone_owner_template = get_zone_owner_template()
	var/zone_shared_cooldown_in = get_remaining_zone_shared_cooldown()
	var/zone_personal_cooldown_in = get_remaining_zone_cooldown(template)
	var/list/state = list(
		"has_binocular_in_hand" = has_rto_binocular_in_hand(),
		"is_armed" = is_action_armed(RTO_SUPPORT_ARM_VISIBILITY_ZONE, template?.template_id),
		"zone_state" = get_zone_state(template?.template_id),
		"zone_ready_in" = get_zone_ready_in(template?.template_id),
		"zone_expires_in" = get_zone_expires_in(zone_owner_template?.template_id),
		"zone_owner_template_id" = zone_owner_template?.template_id,
		"zone_owner_template_name" = zone_owner_template?.name,
		"zone_shared_cooldown_in" = zone_shared_cooldown_in,
		"zone_personal_cooldown_in" = zone_personal_cooldown_in,
		"is_disabled" = FALSE,
		"primary_label" = RTO_SUPPORT_STATUS_READY,
		"countdown_text" = null,
		"countdown_color" = "#f2f2f2"
	)

	if(!template || !template_requires_zone(template))
		state["is_disabled"] = TRUE
		return state
	if(!is_support_enabled_by_rules())
		state["is_disabled"] = TRUE
		state["primary_label"] = "Disabled by Game Rule Panel"
		state["countdown_text"] = "GM"
		state["countdown_color"] = "#c6c6c6"
		return state
	if(!state["has_binocular_in_hand"])
		state["is_disabled"] = TRUE
		state["primary_label"] = RTO_SUPPORT_STATUS_NO_BINOCULAR
		state["countdown_text"] = "B"
		state["countdown_color"] = "#c6c6c6"
		return state
	if(state["is_armed"])
		state["primary_label"] = RTO_SUPPORT_STATUS_TARGETING
		state["countdown_text"] = "ARM"
		state["countdown_color"] = "#ffd25a"
		return state

	if(zone_owner_template)
		var/remaining_active = round(get_zone_expires_in(zone_owner_template.template_id) / 10)
		state["is_disabled"] = TRUE
		if(zone_owner_template.template_id == template.template_id)
			state["primary_label"] = "[RTO_SUPPORT_STATUS_ACTIVE]: [remaining_active]s"
		else
			state["primary_label"] = "Чужой сектор: [remaining_active]s"
		state["countdown_text"] = "[remaining_active]s"
		state["countdown_color"] = "#7ee1ff"
		return state

	if(zone_shared_cooldown_in > 0)
		var/display_shared = round(zone_shared_cooldown_in / 10)
		state["is_disabled"] = TRUE
		state["primary_label"] = "Общий КД: [display_shared]s"
		state["countdown_text"] = "[display_shared]s"
		state["countdown_color"] = "#c6c6c6"
		return state

	if(zone_personal_cooldown_in > 0)
		var/display_personal = round(zone_personal_cooldown_in / 10)
		state["is_disabled"] = TRUE
		state["primary_label"] = "Личный КД: [display_personal]s"
		state["countdown_text"] = "[display_personal]s"
		state["countdown_color"] = "#c6c6c6"
		return state

	return state

/datum/rto_support_controller/proc/get_displayed_ability_cooldown(action_id, template_type = null)
	var/personal_cooldown_in = get_remaining_action_cooldown(action_id)
	var/shared_cooldown_in = get_remaining_shared_cooldown(template_type)
	var/list/result = list(
		"kind" = "none",
		"value" = 0
	)

	if(personal_cooldown_in <= 0 && shared_cooldown_in <= 0)
		return result
	if(personal_cooldown_in >= shared_cooldown_in && personal_cooldown_in > 0)
		result["kind"] = "personal"
		result["value"] = personal_cooldown_in
		return result
	if(shared_cooldown_in > 0)
		result["kind"] = "shared"
		result["value"] = shared_cooldown_in
	return result

/datum/rto_support_controller/proc/build_support_action_state(action_id, template_type)
	var/datum/rto_support_template/template = get_template_for_action(action_id, template_type)
	var/datum/rto_support_action_template/action_template = template?.get_action_template(action_id)
	var/datum/rto_support_template/zone_owner_template = get_zone_owner_template()
	var/zone_state = get_zone_state(template?.template_id)
	var/zone_ready_in = get_zone_ready_in(template?.template_id)
	var/zone_expires_in = get_zone_expires_in(zone_owner_template?.template_id)
	var/shared_cooldown_in = get_remaining_shared_cooldown(template?.template_id)
	var/personal_cooldown_in = get_remaining_action_cooldown(action_id)
	var/list/display_cooldown = get_displayed_ability_cooldown(action_id, template?.template_id)
	var/requires_zone = !!(action_template?.requires_visibility_zone && template_requires_zone(template))
	var/list/state = list(
		"has_binocular_in_hand" = has_rto_binocular_in_hand(),
		"is_armed" = is_action_armed(action_id, template?.template_id),
		"requires_zone" = requires_zone,
		"zone_state" = zone_state,
		"zone_ready_in" = zone_ready_in,
		"zone_expires_in" = zone_expires_in,
		"zone_owner_template_id" = zone_owner_template?.template_id,
		"zone_owner_template_name" = zone_owner_template?.name,
		"shared_cooldown_in" = shared_cooldown_in,
		"personal_cooldown_in" = personal_cooldown_in,
		"display_cooldown_kind" = display_cooldown["kind"],
		"display_cooldown_in" = display_cooldown["value"],
		"is_disabled" = FALSE,
		"primary_label" = RTO_SUPPORT_STATUS_READY,
		"countdown_text" = null,
		"countdown_color" = "#f2f2f2"
	)

	if(!template || !action_template)
		state["is_disabled"] = TRUE
		return state
	if(!is_support_enabled_by_rules())
		state["is_disabled"] = TRUE
		state["primary_label"] = "Disabled by Game Rule Panel"
		state["countdown_text"] = "GM"
		state["countdown_color"] = "#c6c6c6"
		return state
	if(!state["has_binocular_in_hand"])
		state["is_disabled"] = TRUE
		state["primary_label"] = RTO_SUPPORT_STATUS_NO_BINOCULAR
		state["countdown_text"] = "B"
		state["countdown_color"] = "#c6c6c6"
		return state
	if(state["is_armed"])
		state["primary_label"] = RTO_SUPPORT_STATUS_TARGETING
		state["countdown_text"] = "ARM"
		state["countdown_color"] = "#ffd25a"
		return state

	if(requires_zone)
		if(zone_owner_template?.template_id != template.template_id)
			state["is_disabled"] = TRUE
			if(zone_owner_template)
				state["primary_label"] = "Нет своего сектора"
			else
				state["primary_label"] = RTO_SUPPORT_STATUS_NO_ZONE
			state["countdown_color"] = "#c6c6c6"
			return state

	switch(display_cooldown["kind"])
		if("personal")
			var/display_personal = round(display_cooldown["value"] / 10)
			state["is_disabled"] = TRUE
			state["primary_label"] = "Личный КД: [display_personal]s"
			state["countdown_text"] = "[display_personal]s"
			state["countdown_color"] = "#c6c6c6"
			return state
		if("shared")
			var/display_shared = round(display_cooldown["value"] / 10)
			state["is_disabled"] = TRUE
			state["primary_label"] = "Общий КД: [display_shared]s"
			state["countdown_text"] = "[display_shared]s"
			state["countdown_color"] = "#c6c6c6"
			return state

	return state

/datum/rto_support_controller/proc/get_action_block_messages(action_id, template_type = null)
	var/list/messages = list()
	if(action_id == RTO_SUPPORT_ARM_COORDINATES || action_id == RTO_SUPPORT_ARM_MARKER)
		return messages
	if(is_action_restricted_by_rules(action_id))
		messages += "Disabled by Game Rule Panel"
		return messages

	if(action_id == RTO_SUPPORT_ARM_VISIBILITY_ZONE)
		var/datum/rto_support_template/zone_template = get_selected_template(template_type)
		if(!zone_template)
			messages += "Сначала выберите пакет поддержки."
			return messages
		if(!template_requires_zone(zone_template))
			messages += "Этот пакет не использует сектор наведения."
			return messages
		var/zone_name = zone_template.visibility_zone_name || "Сектор наведения"
		var/datum/rto_support_template/zone_owner_template = get_zone_owner_template()
		if(zone_owner_template)
			if(zone_owner_template.template_id == zone_template.template_id)
				messages += "[zone_name] уже активен."
			else
				messages += "Активен сектор пакета [zone_owner_template.name]: [round(get_zone_expires_in(zone_owner_template.template_id) / 10)] с."
			return messages
		var/shared_zone_cooldown = get_remaining_zone_shared_cooldown()
		if(shared_zone_cooldown > 0)
			messages += "Общий кулдаун секторов: [round(shared_zone_cooldown / 10)] с."
		var/personal_zone_cooldown = get_remaining_zone_cooldown(zone_template)
		if(personal_zone_cooldown > 0)
			messages += "Личный кулдаун [zone_name]: [round(personal_zone_cooldown / 10)] с."
		return messages

	var/datum/rto_support_template/template = get_template_for_action(action_id, template_type)
	if(!template)
		messages += "Сначала выберите пакет поддержки."
		return messages

	var/datum/rto_support_action_template/action_template = template.get_action_template(action_id)
	if(!action_template)
		messages += "Неизвестная способность поддержки."
		return messages

	if(action_template.requires_visibility_zone && template_requires_zone(template))
		var/datum/rto_support_template/zone_owner_template = get_zone_owner_template()
		if(!zone_owner_template)
			var/zone_shared_cooldown = get_remaining_zone_shared_cooldown()
			var/zone_personal_cooldown = get_remaining_zone_cooldown(template)
			if(zone_shared_cooldown > 0)
				messages += "Общий кулдаун секторов: [round(zone_shared_cooldown / 10)] с."
			if(zone_personal_cooldown > 0)
				messages += "Личный кулдаун сектора: [round(zone_personal_cooldown / 10)] с."
			if(zone_shared_cooldown <= 0 && zone_personal_cooldown <= 0)
				messages += "Сначала разверните сектор наведения."
		else if(zone_owner_template.template_id != template.template_id)
			messages += "Активен сектор другого пакета: [zone_owner_template.name]."

	var/personal_cooldown = get_remaining_action_cooldown(action_id)
	if(personal_cooldown > 0)
		messages += "Личный кулдаун [action_template.name]: [round(personal_cooldown / 10)] с."
	var/shared_cooldown = get_remaining_shared_cooldown(template)
	if(shared_cooldown > 0)
		messages += "Общий кулдаун пакета [template.name]: [round(shared_cooldown / 10)] с."
	return messages

/datum/rto_support_controller/proc/get_action_block_message(action_id, template_type = null)
	return format_block_messages(get_action_block_messages(action_id, template_type))

/datum/rto_support_controller/proc/is_action_armed(action_id, template_type = null)
	if(action_id != armed_action_id)
		return FALSE
	if(action_id == RTO_SUPPORT_ARM_COORDINATES || action_id == RTO_SUPPORT_ARM_MARKER)
		return TRUE
	if(!template_type)
		return !armed_template_id
	return armed_template_id == template_type

/datum/rto_support_controller/proc/has_rto_binocular()
	return !!get_owned_binocular()

/datum/rto_support_controller/proc/has_rto_binocular_in_hand()
	return !!get_rto_binocular_in_hand()

/datum/rto_support_controller/proc/get_rto_binocular_in_hand() as /obj/item/device/binoculars/rto
	if(!owner)
		return null
	if(istype(owner.l_hand, /obj/item/device/binoculars/rto))
		return owner.l_hand
	if(istype(owner.r_hand, /obj/item/device/binoculars/rto))
		return owner.r_hand
	return null

/datum/rto_support_controller/proc/get_owned_binocular() as /obj/item/device/binoculars/rto
	if(!owner)
		return null
	for(var/atom/movable/movable as anything in owner.contents_recursive())
		if(istype(movable, /obj/item/device/binoculars/rto))
			return movable
	return null

/datum/rto_support_controller/proc/get_active_binocular() as /obj/item/device/binoculars/rto
	if(istype(owner?.interactee, /obj/item/device/binoculars/rto))
		return owner.interactee
	return null

/datum/rto_support_controller/proc/sync_action_visibility()
	if(!owner)
		return FALSE
	var/visible = has_required_role() && owner.stat != DEAD && has_rto_binocular_in_hand()
	for(var/datum/action/human_action/rto/action as anything in action_handles)
		if(!action || QDELETED(action) || !action.owner)
			continue
		if(visible)
			if(action.hidden)
				action.unhide_from(owner)
		else
			if(!action.hidden)
				action.hide_from(owner)
	return TRUE

/datum/rto_support_controller/proc/validate_owner_runtime()
	if(!owner || QDELETED(owner))
		stop_hud_tick()
		return FALSE
	if(has_required_role())
		return TRUE
	reset_armed_action()
	clear_active_zone(FALSE)
	clear_manual_designation()
	clear_actions()
	stop_hud_tick()
	return FALSE

/datum/rto_support_controller/proc/prune_zone_state()
	if(active_zone && !active_zone.is_active())
		clear_active_zone()
		return TRUE
	return FALSE

/datum/rto_support_controller/proc/needs_hud_tick()
	if(!runtime_initialized || !owner || QDELETED(owner))
		return FALSE
	if(!has_required_role())
		return FALSE
	if(owner.stat == DEAD)
		return FALSE
	if(!has_rto_binocular_in_hand())
		return FALSE
	if(!length(action_handles))
		return FALSE
	if(get_active_zone())
		return TRUE
	if(get_remaining_zone_shared_cooldown() > 0)
		return TRUE
	for(var/template_id in shared_cooldowns_by_template)
		if(get_remaining_shared_cooldown(template_id) > 0)
			return TRUE
	for(var/template_id in zone_cooldowns_by_template)
		if(get_remaining_zone_cooldown(template_id) > 0)
			return TRUE
	for(var/action_id in action_cooldowns)
		if(get_remaining_action_cooldown(action_id) > 0)
			return TRUE
	return FALSE

/datum/rto_support_controller/proc/start_hud_tick()
	if(hud_tick_timer_id)
		return FALSE
	hud_tick_timer_id = addtimer(CALLBACK(src, PROC_REF(refresh_action_handles)), 1 SECONDS, TIMER_LOOP|TIMER_STOPPABLE|TIMER_DELETE_ME)
	return TRUE

/datum/rto_support_controller/proc/stop_hud_tick()
	if(!hud_tick_timer_id)
		return FALSE
	deltimer(hud_tick_timer_id)
	hud_tick_timer_id = null
	return TRUE

/datum/rto_support_controller/proc/update_hud_tick_state()
	if(needs_hud_tick())
		start_hud_tick()
		return TRUE
	stop_hud_tick()
	return FALSE

/datum/rto_support_controller/proc/clear_zone_expiry_timer()
	if(!zone_expiry_timer_id)
		return FALSE
	deltimer(zone_expiry_timer_id)
	zone_expiry_timer_id = null
	return TRUE

/datum/rto_support_controller/proc/schedule_zone_expiry()
	clear_zone_expiry_timer()
	if(!active_zone || !active_zone.expires_at)
		return FALSE
	var/time_left = max(1, active_zone.expires_at - world.time)
	zone_expiry_timer_id = addtimer(CALLBACK(src, PROC_REF(handle_active_zone_expired)), time_left, TIMER_STOPPABLE|TIMER_DELETE_ME)
	return TRUE

/datum/rto_support_controller/proc/handle_active_zone_expired()
	zone_expiry_timer_id = null
	if(!active_zone)
		return FALSE
	clear_active_zone()
	refresh_action_handles()
	return TRUE
