/// Генератор контролируемого хаос-разрушения по радиусу.
/datum/world_edit_generator/chaos_demolition
	var/click_mode_active = FALSE

/datum/world_edit_generator/chaos_demolition/configure_params(mob/user, list/current_params)
	var/list/new_params = current_params.Copy()

	var/current_radius = text2num("[new_params["radius"]]") || 3
	var/chosen_radius = tgui_input_number(user, "Радиус операции.", "World Edit: Chaos Radius", current_radius, 6, 1)
	if(isnull(chosen_radius))
		return null
	new_params["radius"] = clamp(chosen_radius, 1, 6)

	var/shuffle_choice = tgui_alert(user, "Включить перемешивание movable-объектов?", "World Edit: Shuffle", list("Да", "Нет"))
	if(!shuffle_choice)
		return null
	new_params["shuffle_enabled"] = shuffle_choice == "Да"

	var/scatter_choice = tgui_alert(user, "Включить разлет объектов?", "World Edit: Scatter", list("Да", "Нет"))
	if(!scatter_choice)
		return null
	new_params["scatter_enabled"] = scatter_choice == "Да"

	if(new_params["scatter_enabled"])
		var/current_scatter_steps = text2num("[new_params["scatter_steps"]]") || 2
		var/chosen_scatter_steps = tgui_input_number(user, "Количество шагов разлета.", "World Edit: Scatter Steps", current_scatter_steps, 6, 1)
		if(isnull(chosen_scatter_steps))
			return null
		new_params["scatter_steps"] = clamp(chosen_scatter_steps, 1, 6)

	var/explode_choice = tgui_alert(user, "Добавить взрыв в центре?", "World Edit: Explosion", list("Да", "Нет"))
	if(!explode_choice)
		return null
	new_params["explode_enabled"] = explode_choice == "Да"

	if(new_params["explode_enabled"])
		var/current_explosion_power = text2num("[new_params["explosion_power"]]") || 250
		var/chosen_explosion_power = tgui_input_number(user, "Мощность взрыва.", "World Edit: Explosion Power", current_explosion_power, 600, 100)
		if(isnull(chosen_explosion_power))
			return null
		new_params["explosion_power"] = clamp(chosen_explosion_power, 100, 600)

		var/current_explosion_falloff = text2num("[new_params["explosion_falloff"]]") || 600
		var/chosen_explosion_falloff = tgui_input_number(user, "Falloff взрыва.", "World Edit: Explosion Falloff", current_explosion_falloff, 1200, 100)
		if(isnull(chosen_explosion_falloff))
			return null
		new_params["explosion_falloff"] = clamp(chosen_explosion_falloff, 100, 1200)

	var/fire_choice = tgui_alert(user, "Добавить persistent fire по области?", "World Edit: Persistent Fire", list("Да", "Нет"))
	if(!fire_choice)
		return null
	new_params["persistent_fire_enabled"] = fire_choice == "Да"

	if(new_params["persistent_fire_enabled"])
		var/current_fire_density = text2num("[new_params["persistent_fire_density"]]") || 0.15
		var/chosen_fire_density = tgui_input_number(user, "Плотность persistent fire (0.05..0.50).", "World Edit: Fire Density", current_fire_density, 0.50, 0.05)
		if(isnull(chosen_fire_density))
			return null
		new_params["persistent_fire_density"] = clamp(chosen_fire_density, 0.05, 0.50)

	var/current_max_atoms = text2num("[new_params["max_atoms"]]") || 120
	var/chosen_max_atoms = tgui_input_number(user, "Максимум обрабатываемых movable-объектов.", "World Edit: Atom Limit", current_max_atoms, 250, 1)
	if(isnull(chosen_max_atoms))
		return null
	new_params["max_atoms"] = clamp(chosen_max_atoms, 1, 250)

	var/anchored_choice = tgui_alert(user, "Обрабатывать anchored объекты?", "World Edit: Anchored", list("Да", "Нет"))
	if(!anchored_choice)
		return null
	new_params["affect_anchored"] = anchored_choice == "Да"

	return new_params

/datum/world_edit_generator/chaos_demolition/validate_params(mob/user, list/params)
	var/radius = text2num("[params["radius"]]")
	if(!isnum(radius) || radius < 1 || radius > 6)
		return "radius должен быть в диапазоне 1..6."

	var/max_atoms = text2num("[params["max_atoms"]]")
	if(!isnum(max_atoms) || max_atoms < 1 || max_atoms > 250)
		return "max_atoms должен быть в диапазоне 1..250."

	var/scatter_steps = text2num("[params["scatter_steps"]]")
	if(!isnum(scatter_steps) || scatter_steps < 1 || scatter_steps > 6)
		return "scatter_steps должен быть в диапазоне 1..6."

	var/explosion_power = text2num("[params["explosion_power"]]")
	if(!isnum(explosion_power) || explosion_power < 100 || explosion_power > 600)
		return "explosion_power должен быть в диапазоне 100..600."

	var/explosion_falloff = text2num("[params["explosion_falloff"]]")
	if(!isnum(explosion_falloff) || explosion_falloff < 100 || explosion_falloff > 1200)
		return "explosion_falloff должен быть в диапазоне 100..1200."

	var/persistent_fire_density = text2num("[params["persistent_fire_density"]]")
	if(!isnum(persistent_fire_density) || persistent_fire_density < 0.05 || persistent_fire_density > 0.50)
		return "persistent_fire_density должен быть в диапазоне 0.05..0.50."

	var/has_any_mode = world_edit_parse_bool(params["shuffle_enabled"]) || world_edit_parse_bool(params["scatter_enabled"]) || world_edit_parse_bool(params["explode_enabled"]) || world_edit_parse_bool(params["persistent_fire_enabled"])
	if(!has_any_mode)
		return "Нужно включить хотя бы один режим (shuffle/scatter/explode/fire)."

	return null

/datum/world_edit_generator/chaos_demolition/preview(mob/user, list/params)
	var/datum/world_edit_preview_result/result = new
	result.success = TRUE
	result.message = "Click-режим хаоса: ЛКМ выбирает центр операции, затем запрашивается подтверждение."
	result.meta["radius"] = params["radius"]
	result.meta["max_atoms"] = params["max_atoms"]
	result.meta["shuffle"] = world_edit_parse_bool(params["shuffle_enabled"])
	result.meta["scatter"] = world_edit_parse_bool(params["scatter_enabled"])
	result.meta["explode"] = world_edit_parse_bool(params["explode_enabled"])
	result.meta["persistent_fire"] = world_edit_parse_bool(params["persistent_fire_enabled"])
	return result

/datum/world_edit_generator/chaos_demolition/apply(mob/user, list/params)
	var/datum/world_edit_apply_result/result = new
	if(!manager)
		result.message = "Менеджер World Edit не инициализирован."
		return result
	if(!manager.acquire_click_intercept("Chaos Demolition"))
		result.message = "Перехват клика не активирован."
		return result

	click_mode_active = TRUE
	result.success = TRUE
	result.center_turf = get_turf(user)
	result.message = "Click-режим хаос-разрушения активирован. ЛКМ выберите центр операции."
	return result

/datum/world_edit_generator/chaos_demolition/cleanup_preview(mob/user)
	return

/datum/world_edit_generator/chaos_demolition/disable_click_mode()
	click_mode_active = FALSE
	manager?.clear_preview_images()

/datum/world_edit_generator/chaos_demolition/get_runtime_status()
	return list(
		list("label" = "Click-режим", "value" = click_mode_active ? "активен" : "выключен"),
	)

/datum/world_edit_generator/chaos_demolition/get_ui_fields(list/current_params)
	var/scatter_enabled = world_edit_parse_bool(current_params["scatter_enabled"])
	var/explode_enabled = world_edit_parse_bool(current_params["explode_enabled"])
	var/persistent_fire_enabled = world_edit_parse_bool(current_params["persistent_fire_enabled"])

	var/list/fields = list()
	fields += list(list(
		"id" = "radius",
		"label" = "Радиус",
		"kind" = "number",
		"group" = "Основные",
		"description" = "Радиус области вокруг точки клика, в которой выполняется операция.",
		"validate_hint" = "Допустимый диапазон: 1..6",
		"value" = text2num("[current_params["radius"]]") || 3,
		"min" = 1,
		"max" = 6,
		"step" = 1,
	))
	fields += list(list(
		"id" = "shuffle_enabled",
		"label" = "Перемешивание movable",
		"kind" = "boolean",
		"group" = "Режимы",
		"description" = "Случайно перераспределяет movable-объекты по тайлам в выбранном радиусе.",
		"value" = world_edit_parse_bool(current_params["shuffle_enabled"]),
	))
	fields += list(list(
		"id" = "scatter_enabled",
		"label" = "Разлет movable",
		"kind" = "boolean",
		"group" = "Режимы",
		"description" = "Применяет случайный разлет movable-объектов на несколько шагов.",
		"value" = world_edit_parse_bool(current_params["scatter_enabled"]),
	))
	fields += list(list(
		"id" = "scatter_steps",
		"label" = "Scatter шаги",
		"kind" = "number",
		"group" = "Режимы",
		"description" = "Количество шагов случайного разлета при включенном scatter.",
		"validate_hint" = "Допустимый диапазон: 1..6",
		"value" = text2num("[current_params["scatter_steps"]]") || 2,
		"min" = 1,
		"max" = 6,
		"step" = 1,
		"disabled" = !scatter_enabled,
	))
	fields += list(list(
		"id" = "explode_enabled",
		"label" = "Включить взрыв",
		"kind" = "boolean",
		"group" = "Взрыв",
		"description" = "Запускает cell_explosion по центру выбранной операции.",
		"value" = world_edit_parse_bool(current_params["explode_enabled"]),
	))
	fields += list(list(
		"id" = "explosion_power",
		"label" = "Мощность взрыва",
		"kind" = "number",
		"group" = "Взрыв",
		"description" = "Пиковая мощность взрыва в центре.",
		"validate_hint" = "Допустимый диапазон: 100..600",
		"value" = text2num("[current_params["explosion_power"]]") || 250,
		"min" = 100,
		"max" = 600,
		"step" = 10,
		"disabled" = !explode_enabled,
	))
	fields += list(list(
		"id" = "explosion_falloff",
		"label" = "Falloff взрыва",
		"kind" = "number",
		"group" = "Взрыв",
		"description" = "Параметр затухания взрывной волны.",
		"validate_hint" = "Допустимый диапазон: 100..1200",
		"value" = text2num("[current_params["explosion_falloff"]]") || 600,
		"min" = 100,
		"max" = 1200,
		"step" = 10,
		"disabled" = !explode_enabled,
	))
	fields += list(list(
		"id" = "persistent_fire_enabled",
		"label" = "Persistent fire",
		"kind" = "boolean",
		"group" = "Огонь",
		"description" = "Создает постоянные огни world_edit_persistent_fire в пределах области.",
		"value" = world_edit_parse_bool(current_params["persistent_fire_enabled"]),
	))
	fields += list(list(
		"id" = "persistent_fire_density",
		"label" = "Плотность fire",
		"kind" = "number",
		"group" = "Огонь",
		"description" = "Доля тайлов в области, на которых создается постоянный огонь.",
		"validate_hint" = "Допустимый диапазон: 0.05..0.50",
		"value" = text2num("[current_params["persistent_fire_density"]]") || 0.15,
		"min" = 0.05,
		"max" = 0.50,
		"step" = 0.01,
		"disabled" = !persistent_fire_enabled,
	))
	fields += list(list(
		"id" = "max_atoms",
		"label" = "Лимит объектов",
		"kind" = "number",
		"group" = "Лимиты",
		"description" = "Максимальное число movable-объектов для одной операции.",
		"validate_hint" = "Допустимый диапазон: 1..250",
		"value" = text2num("[current_params["max_atoms"]]") || 120,
		"min" = 1,
		"max" = 250,
		"step" = 1,
	))
	fields += list(list(
		"id" = "affect_anchored",
		"label" = "Трогать anchored",
		"kind" = "boolean",
		"group" = "Лимиты",
		"description" = "Если выключено, anchored-объекты исключаются из хаос-операции.",
		"value" = world_edit_parse_bool(current_params["affect_anchored"]),
	))
	return fields

/datum/world_edit_generator/chaos_demolition/set_ui_param(mob/user, list/current_params, param_id, value)
	var/list/new_params = current_params.Copy()
	switch(param_id)
		if("radius")
			new_params[param_id] = clamp(text2num("[value]"), 1, 6)
		if("shuffle_enabled")
			new_params[param_id] = world_edit_parse_bool(value)
		if("scatter_enabled")
			new_params[param_id] = world_edit_parse_bool(value)
		if("scatter_steps")
			new_params[param_id] = clamp(text2num("[value]"), 1, 6)
		if("explode_enabled")
			new_params[param_id] = world_edit_parse_bool(value)
		if("explosion_power")
			new_params[param_id] = clamp(text2num("[value]"), 100, 600)
		if("explosion_falloff")
			new_params[param_id] = clamp(text2num("[value]"), 100, 1200)
		if("persistent_fire_enabled")
			new_params[param_id] = world_edit_parse_bool(value)
		if("persistent_fire_density")
			new_params[param_id] = clamp(text2num("[value]"), 0.05, 0.50)
		if("max_atoms")
			new_params[param_id] = clamp(text2num("[value]"), 1, 250)
		if("affect_anchored")
			new_params[param_id] = world_edit_parse_bool(value)
		else
			return ..()
	return new_params

/datum/world_edit_generator/chaos_demolition/proc/collect_area_turfs(turf/center_turf, radius)
	var/list/area_turfs = list()
	if(!center_turf)
		return area_turfs

	for(var/turf/target_turf in range(radius, center_turf))
		if(target_turf.z != center_turf.z)
			continue
		area_turfs += target_turf
	return area_turfs

/datum/world_edit_generator/chaos_demolition/proc/should_skip_target(atom/movable/target, affect_anchored = FALSE)
	if(!target || QDELETED(target))
		return TRUE
	if(ismob(target))
		return TRUE
	if(istype(target, /atom/movable/screen))
		return TRUE
	if(istype(target, /obj/effect/world_edit_persistent_fire))
		return TRUE
	if(ismob(target.loc))
		return TRUE
	if(!affect_anchored && target.anchored)
		return TRUE
	return FALSE

/datum/world_edit_generator/chaos_demolition/proc/collect_targets(list/area_turfs, affect_anchored = FALSE)
	var/list/targets = list()
	for(var/turf/target_turf as anything in area_turfs)
		for(var/atom/movable/target as anything in target_turf)
			if(should_skip_target(target, affect_anchored))
				continue
			targets += target
	return targets

/datum/world_edit_generator/chaos_demolition/proc/shuffle_targets(list/targets, list/area_turfs)
	if(!length(targets) || !length(area_turfs))
		return

	for(var/atom/movable/target as anything in targets)
		if(!target || QDELETED(target))
			continue
		var/turf/new_turf = pick(area_turfs)
		if(new_turf)
			target.forceMove(new_turf)

/datum/world_edit_generator/chaos_demolition/proc/scatter_targets(list/targets, scatter_steps)
	if(!length(targets) || scatter_steps <= 0)
		return

	for(var/atom/movable/target as anything in targets)
		if(!target || QDELETED(target))
			continue

		for(var/i in 1 to scatter_steps)
			var/turf/current_turf = get_turf(target)
			if(!current_turf)
				break
			var/turf/next_turf = get_step(current_turf, pick(GLOB.alldirs))
			if(!next_turf)
				break
			target.forceMove(next_turf)

/datum/world_edit_generator/chaos_demolition/proc/spawn_persistent_fire(list/area_turfs, density, max_tiles = 60)
	if(!length(area_turfs) || density <= 0)
		return 0

	var/target_count = round(length(area_turfs) * density)
	target_count = clamp(target_count, 0, max_tiles)

	var/list/pool = area_turfs.Copy()
	var/created_count = 0
	while(target_count > 0 && length(pool))
		var/turf/target_turf = pick_n_take(pool)
		if(!target_turf)
			break
		if(locate(/obj/effect/world_edit_persistent_fire) in target_turf)
			target_count--
			continue

		new /obj/effect/world_edit_persistent_fire(target_turf)
		created_count++
		target_count--

	return created_count

/datum/world_edit_generator/chaos_demolition/proc/execute_chaos_on_turf(mob/user, turf/center_turf)
	var/list/params = manager?.current_params || list()
	var/radius = text2num("[params["radius"]]") || 3
	var/max_atoms = text2num("[params["max_atoms"]]") || 120
	var/affect_anchored = world_edit_parse_bool(params["affect_anchored"])
	var/shuffle_enabled = world_edit_parse_bool(params["shuffle_enabled"])
	var/scatter_enabled = world_edit_parse_bool(params["scatter_enabled"])
	var/explode_enabled = world_edit_parse_bool(params["explode_enabled"])
	var/persistent_fire_enabled = world_edit_parse_bool(params["persistent_fire_enabled"])
	var/scatter_steps = text2num("[params["scatter_steps"]]") || 2
	var/explosion_power = text2num("[params["explosion_power"]]") || 250
	var/explosion_falloff = text2num("[params["explosion_falloff"]]") || 600
	var/persistent_fire_density = text2num("[params["persistent_fire_density"]]") || 0.15

	var/list/area_turfs = collect_area_turfs(center_turf, radius)
	world_edit_apply_turf_preview(manager, area_turfs)

	var/list/targets = collect_targets(area_turfs, affect_anchored)
	if(length(targets) > max_atoms)
		manager?.clear_preview_images()
		to_chat(user, SPAN_WARNING("Операция заблокирована: найдено [length(targets)] объектов при лимите [max_atoms]."))
		return

	var/has_any_mode = shuffle_enabled || scatter_enabled || explode_enabled || persistent_fire_enabled
	if(!has_any_mode)
		manager?.clear_preview_images()
		to_chat(user, SPAN_WARNING("Операция отменена: не включен ни один режим воздействия."))
		return

	var/summary_text = "Применить chaos demolish в радиусе [radius]? movable=[length(targets)], shuffle=[shuffle_enabled], scatter=[scatter_enabled], explode=[explode_enabled], fire=[persistent_fire_enabled]."
	var/answer = tgui_alert(user, summary_text, "World Edit: Chaos Confirm", list("Подтвердить", "Отмена"))
	if(answer != "Подтвердить")
		manager?.clear_preview_images()
		return

	var/heavy_operation = (length(targets) >= round(max_atoms * 0.7)) || (radius >= 5) || (explode_enabled && explosion_power >= 500)
	if(heavy_operation)
		var/heavy_answer = tgui_alert(user, "Тяжелая операция. Подтвердите повторно выполнение.", "World Edit: Heavy Confirm", list("Выполнить", "Отмена"))
		if(heavy_answer != "Выполнить")
			manager?.clear_preview_images()
			return

	var/start_ds = world.time
	var/moved_count = 0
	var/fire_count = 0

	if(shuffle_enabled)
		shuffle_targets(targets, area_turfs)
		moved_count = max(moved_count, length(targets))

	if(scatter_enabled)
		scatter_targets(targets, scatter_steps)
		moved_count = max(moved_count, length(targets))

	if(explode_enabled)
		cell_explosion(center_turf, explosion_power, explosion_falloff, EXPLOSION_FALLOFF_SHAPE_LINEAR, null, create_cause_data("world edit chaos demolition", manager?.holder))

	if(persistent_fire_enabled)
		fire_count = spawn_persistent_fire(area_turfs, persistent_fire_density)

	manager?.clear_preview_images()

	var/duration_ds = world.time - start_ds
	var/result_code = "click_apply"
	var/params_short = get_params_short(params)
	world_edit_log_operation(
		manager?.holder,
		definition.id,
		definition.required_rights,
		center_turf,
		fire_count,
		0,
		duration_ds,
		result_code,
		params_short
	)
	manager?.add_history_entry(
		definition.id,
		result_code,
		fire_count,
		0,
		center_turf,
		params_short,
		"moved=[moved_count], fire=[fire_count], exploded=[explode_enabled ? "yes" : "no"]",
		duration_ds * 100
	)

	to_chat(user, SPAN_NOTICE("Chaos-операция завершена: movable=[moved_count], fire=[fire_count], explosion=[explode_enabled ? "on" : "off"]."))

/datum/world_edit_generator/chaos_demolition/InterceptClickOn(mob/user, params, atom/object)
	if(!click_mode_active)
		return FALSE

	var/list/modifiers = params2list(params)
	if(!LAZYACCESS(modifiers, LEFT_CLICK))
		return TRUE

	var/turf/center_turf = get_turf(object)
	if(!center_turf)
		return TRUE

	execute_chaos_on_turf(user, center_turf)
	return TRUE

/datum/world_edit_generator/chaos_demolition/get_apply_confirmation_text(list/params)
	return "Включить click-режим chaos demolition?"

/datum/world_edit_generator/chaos_demolition/get_params_short(list/params)
	return "radius=[params["radius"]] shuffle=[params["shuffle_enabled"]] scatter=[params["scatter_enabled"]] explode=[params["explode_enabled"]] fire=[params["persistent_fire_enabled"]] max_atoms=[params["max_atoms"]]"
