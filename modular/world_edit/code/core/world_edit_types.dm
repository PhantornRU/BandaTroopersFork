#define WORLD_EDIT_EXECUTION_BATCH "batch"
#define WORLD_EDIT_EXECUTION_CLICK "click"
#define WORLD_EDIT_STATUS_DRAFT "draft"
#define WORLD_EDIT_STATUS_READY "ready"
#define WORLD_EDIT_STATUS_DEPRECATED "deprecated"
#define WORLD_EDIT_HISTORY_LIMIT 50

/// Результат этапа предпросмотра генератора.
/datum/world_edit_preview_result
	var/success = FALSE
	var/message = ""
	var/list/preview_images = list()
	var/list/meta = list()

/// Результат этапа применения генератора.
/datum/world_edit_apply_result
	var/success = FALSE
	var/message = ""
	var/created_count = 0
	var/deleted_count = 0
	var/turf/center_turf
	var/list/meta = list()

/datum/world_edit_plan
	var/list/placements = list()
	var/list/deletions = list()
	var/list/affected_turfs = list()
	var/list/metadata = list()

/// Базовый контракт генератора World Edit.
/datum/world_edit_generator
	var/datum/world_edit_manager/manager
	var/datum/world_edit_generator_definition/definition
	var/requires_preview_before_apply = FALSE
	var/datum/world_edit_plan/current_plan

/datum/world_edit_generator/proc/attach(datum/world_edit_manager/new_manager, datum/world_edit_generator_definition/new_definition)
	manager = new_manager
	definition = new_definition
	current_plan = null

/// Возвращает обновленные параметры либо null при отмене шага настройки.
/datum/world_edit_generator/proc/configure_params(mob/user, list/current_params)
	return current_params

/// Возвращает null при валидных параметрах либо текст ошибки.
/datum/world_edit_generator/proc/validate_params(mob/user, list/params)
	return null

/datum/world_edit_generator/proc/build_plan(list/params)
	return null

/datum/world_edit_generator/proc/preview(mob/user, list/params)
	var/datum/world_edit_preview_result/result = new
	result.success = FALSE
	result.message = "Для этого генератора предпросмотр не реализован."
	return result

/datum/world_edit_generator/proc/apply(mob/user, list/params)
	var/datum/world_edit_apply_result/result = new
	result.success = FALSE
	result.message = "Для этого генератора применение не реализовано."
	return result

/datum/world_edit_generator/proc/cleanup_preview(mob/user)
	return

/// Вызывается только в click-режиме.
/datum/world_edit_generator/proc/clear_built_plan()
	current_plan = null

/datum/world_edit_generator/proc/InterceptClickOn(mob/user, params, atom/object)
	return FALSE

/datum/world_edit_generator/proc/disable_click_mode()
	return

/datum/world_edit_generator/proc/get_apply_confirmation_text(list/params)
	return "Подтвердить применение генератора '[definition?.name_ru]'?"

/datum/world_edit_generator/proc/get_params_short(list/params)
	return world_edit_params_to_text(params)

/datum/world_edit_generator/proc/is_destructive(list/params)
	return FALSE

/// Возвращает описание полей для inline-настройки в TGUI.
/// Если null, используется fallback-мастер configure_params.
/datum/world_edit_generator/proc/get_ui_fields(list/current_params)
	return null

/// Возвращает новые параметры после изменения одного поля через TGUI.
/// По умолчанию выполняется простое присваивание.
/datum/world_edit_generator/proc/set_ui_param(mob/user, list/current_params, param_id, value)
	if(!islist(current_params))
		current_params = list()

	var/list/new_params = current_params.Copy()
	new_params[param_id] = value
	return new_params

/// Хук для принудительного обновления UI-состояния генератора.
/// Нужен для динамических каталогов и сброса кэшей без смены генератора.
/datum/world_edit_generator/proc/refresh_ui_state(mob/user, list/current_params)
	return

/// Возвращает runtime-статус генератора для панели World Edit.
/datum/world_edit_generator/proc/get_runtime_status()
	return list()
