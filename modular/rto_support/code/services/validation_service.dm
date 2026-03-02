/// Validation service for zone deployment and support calls.
/datum/rto_support_validation_service

/// Validates a visibility zone deployment attempt.
/datum/rto_support_validation_service/proc/validate_zone_deploy(datum/rto_support_controller/controller, turf/target_turf, mob/living/carbon/human/user, obj/item/device/binoculars/rto/binoculars)
	var/datum/rto_support_validation_result/result = validate_common_context(controller, target_turf, user, binoculars, FALSE, FALSE)
	if(!result.success)
		return result
	if(!controller.can_deploy_zone())
		return new /datum/rto_support_validation_result().set_failure(controller.get_action_block_message(RTO_SUPPORT_ARM_VISIBILITY_ZONE))
	if(controller.active_template.visibility_altitude_requirement == RTO_SUPPORT_ALTITUDE_HIGH && !is_high_altitude_target_valid(user, target_turf))
		return new /datum/rto_support_validation_result().set_failure("Точка недоступна для авиационного сектора.")
	return new /datum/rto_support_validation_result().set_success()

/// Validates a support call attempt.
/datum/rto_support_validation_service/proc/validate_support_call(datum/rto_support_controller/controller, datum/rto_support_action_template/action_template, turf/target_turf, mob/living/carbon/human/user, obj/item/device/binoculars/rto/binoculars)
	var/datum/rto_support_validation_result/result = validate_common_context(controller, target_turf, user, binoculars, action_template.requires_visibility_zone, action_template.allow_closed_turf)
	if(!result.success)
		return result
	if(controller.get_remaining_shared_cooldown() > 0)
		return new /datum/rto_support_validation_result().set_failure(controller.get_action_block_message(action_template.action_id))
	if(controller.get_remaining_action_cooldown(action_template.action_id) > 0)
		return new /datum/rto_support_validation_result().set_failure(controller.get_action_block_message(action_template.action_id))
	if(action_template.altitude_requirement == RTO_SUPPORT_ALTITUDE_HIGH && !is_high_altitude_target_valid(user, target_turf))
		return new /datum/rto_support_validation_result().set_failure("Точка недоступна для этого типа поддержки.")
	return new /datum/rto_support_validation_result().set_success()

/datum/rto_support_validation_service/proc/validate_common_context(datum/rto_support_controller/controller, turf/target_turf, mob/living/carbon/human/user, obj/item/device/binoculars/rto/binoculars, require_zone, allow_closed_turf)
	if(!controller || !controller.owner || user != controller.owner)
		return new /datum/rto_support_validation_result().set_failure("Контроллер поддержки недоступен.")
	if(!controller.active_template)
		return new /datum/rto_support_validation_result().set_failure("Сначала выберите пакет поддержки.")
	if(!target_turf || QDELETED(target_turf))
		return new /datum/rto_support_validation_result().set_failure("Цель недоступна.")
	if(!binoculars || binoculars != user.interactee)
		return new /datum/rto_support_validation_result().set_failure("Нужно смотреть через RTO-бинокль.")
	if(user.is_mob_incapacitated())
		return new /datum/rto_support_validation_result().set_failure("Вы не можете использовать поддержку в текущем состоянии.")
	if(is_mainship_level(user.z) || is_mainship_level(target_turf.z))
		return new /datum/rto_support_validation_result().set_failure("Поддержка недоступна на корабле.")
	if(user.z != target_turf.z)
		return new /datum/rto_support_validation_result().set_failure("Цель должна находиться на том же уровне.")
	if(!allow_closed_turf && istype(target_turf, /turf/closed))
		return new /datum/rto_support_validation_result().set_failure("Цель должна быть на открытом тайле.")
	if(!can_see_target(user, target_turf, binoculars))
		return new /datum/rto_support_validation_result().set_failure("Нет прямой видимости до цели.")
	if(require_zone)
		var/datum/rto_visibility_zone/zone = controller.get_active_zone()
		if(!zone)
			return new /datum/rto_support_validation_result().set_failure("Сначала разверните сектор наведения.")
		if(!zone.contains_turf(target_turf))
			return new /datum/rto_support_validation_result().set_failure("Цель вне сектора наведения.")
	return new /datum/rto_support_validation_result().set_success()

/datum/rto_support_validation_service/proc/can_see_target(mob/living/carbon/human/user, turf/target_turf, obj/item/device/binoculars/rto/binoculars)
	if(QDELETED(target_turf))
		return FALSE
	return binoculars.can_see_target(target_turf, user)

/datum/rto_support_validation_service/proc/is_high_altitude_target_valid(mob/living/carbon/human/user, turf/target_turf)
	var/area/target_area = get_area(target_turf)
	var/area/user_area = get_area(user)
	var/is_outside = FALSE

	switch(target_area?.ceiling)
		if(CEILING_NONE, CEILING_GLASS)
			is_outside = TRUE

	switch(user_area?.ceiling)
		if(CEILING_NONE, CEILING_GLASS)
			if(target_area?.ceiling <= CEILING_PROTECTION_TIER_3)
				is_outside = TRUE

	if(protected_by_pylon(TURF_PROTECTION_CAS, target_turf))
		is_outside = FALSE

	return is_outside
