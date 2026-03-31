GLOBAL_LIST_EMPTY(world_edit_managers_by_client)

/datum/world_edit_manager
	var/client/holder
	var/datum/world_edit_generator_definition/current_definition
	var/datum/world_edit_generator/current_generator
	var/list/current_params = list()
	var/last_ui_error = ""

	var/list/preview_images = list()
	var/preview_valid = FALSE
	var/preview_generator_id
	var/preview_params_signature
	var/last_preview_success = FALSE
	var/last_preview_message = ""
	var/list/last_preview_meta = list()

	var/last_apply_success = FALSE
	var/last_apply_message = ""
	var/last_undo_success = FALSE
	var/last_undo_message = ""
	var/last_undo_action = ""

	var/list/history_entries = list()
	var/list/changeset_entries = list()
	var/list/preset_entries_cache = list()
	var/preset_cache_loaded = FALSE
	var/list/blueprint_entries_cache = list()
	var/blueprint_cache_loaded = FALSE

	var/datum/click_intercept_previous
	var/click_intercept_owned = FALSE
	var/placement_click_active = FALSE
	var/placement_mode = "single"
	var/placement_dir = NORTH
	var/turf/placement_anchor_turf

/datum/world_edit_manager/New(client/new_holder)
	. = ..()
	holder = new_holder
	history_entries = list()
	changeset_entries = list()
	preset_entries_cache = list()
	blueprint_entries_cache = list()
	preview_images = list()
	current_params = list()
	last_preview_meta = list()
	last_ui_error = ""

/datum/world_edit_manager/Destroy(force, ...)
	stop_click_mode()
	clear_preview_images()
	detach_current_generator()
	history_entries = null
	if(islist(changeset_entries))
		for(var/datum/world_edit_changeset/changeset as anything in changeset_entries)
			qdel(changeset)
	changeset_entries = null
	preset_entries_cache = null
	blueprint_entries_cache = null
	if(holder && GLOB.world_edit_managers_by_client[holder] == src)
		GLOB.world_edit_managers_by_client[holder] = null
	holder = null
	return ..()

/// Сбрасывает кеш последнего preview (без изменения изображений/валидности).
/datum/world_edit_manager/proc/reset_preview_feedback()
	last_preview_success = FALSE
	last_preview_message = ""
	last_preview_meta = list()

/// Сбрасывает кеш последнего apply.
/datum/world_edit_manager/proc/reset_apply_feedback()
	last_apply_success = FALSE
	last_apply_message = ""

/datum/world_edit_manager/proc/reset_undo_feedback()
	last_undo_success = FALSE
	last_undo_message = ""
	last_undo_action = ""

/// Полный сброс runtime-состояния preview.
/datum/world_edit_manager/proc/clear_preview_plan_state()
	clear_preview_images()
	current_generator?.clear_built_plan()
	invalidate_preview_state()
	reset_preview_feedback()

/datum/world_edit_manager/proc/reset_preview_runtime()
	stop_click_mode()
	clear_preview_plan_state()

/// Сбрасывает runtime генератора (preview/apply/click), но не очищает историю.
/datum/world_edit_manager/proc/reset_generator_runtime()
	reset_preview_runtime()
	reset_apply_feedback()
	last_ui_error = ""

/// Корректно отсоединяет текущий экземпляр генератора.
/datum/world_edit_manager/proc/detach_current_generator()
	current_generator?.clear_built_plan()
	QDEL_NULL(current_generator)
	current_definition = null
	current_params = list()
	reset_placement_runtime(TRUE)
