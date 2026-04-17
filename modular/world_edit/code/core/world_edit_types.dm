#define WORLD_EDIT_EXECUTION_BATCH "batch"
#define WORLD_EDIT_EXECUTION_CLICK "click"
#define WORLD_EDIT_STATUS_DRAFT "draft"
#define WORLD_EDIT_STATUS_READY "ready"
#define WORLD_EDIT_HISTORY_LIMIT 125
#define WORLD_EDIT_PLACEMENT_MAX_ANCHORS 120
#define WORLD_EDIT_PLACEMENT_MAX_TOTAL_PLACEMENTS 600

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
	var/datum/world_edit_changeset/changeset

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
	return GLOB.world_edit_logging.params_to_text(params)

/datum/world_edit_generator/proc/is_destructive(list/params)
	return FALSE

/// Возвращает описание полей для live inline-настройки в TGUI.
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

/datum/world_edit_generator/proc/get_supported_placement_modes()
	return list()

/datum/world_edit_generator/proc/get_supported_placement_shapes()
	return list()

/datum/world_edit_generator/proc/get_default_placement_shape()
	var/list/shapes = get_supported_placement_shapes()
	if(!length(shapes))
		return null
	return "[shapes[1]]"

/datum/world_edit_generator/proc/supports_placement_direction()
	return FALSE

/datum/world_edit_generator/proc/get_default_placement_direction()
	return NORTH

/datum/world_edit_generator/proc/get_shape_support_error(shape_id, list/anchor_turfs, list/params, list/placement_context)
	return null

/datum/world_edit_generator/proc/build_placement_plan(mob/user, list/params, list/placement_context)
	return null
