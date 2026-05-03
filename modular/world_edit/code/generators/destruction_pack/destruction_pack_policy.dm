/datum/world_edit_generator/destruction_pack/proc/get_persistent_fire_cap()
	return WORLD_EDIT_DESTRUCTION_PERSISTENT_FIRE_CAP

/datum/world_edit_generator/destruction_pack/proc/get_persistent_fire_density_min()
	return 1

/datum/world_edit_generator/destruction_pack/proc/get_persistent_fire_density_max()
	return 100

/datum/world_edit_generator/destruction_pack/proc/get_persistent_fire_density_default()
	return 10

/datum/world_edit_generator/destruction_pack/proc/get_default_persistent_fire_mode()
	return "damaging"

/datum/world_edit_generator/destruction_pack/proc/build_persistent_fire_mode_options()
	return list(
		list(
			"label" = "С уроном",
			"value" = "damaging",
			"description" = "Излучает жар, поджигает мобов и со временем наносит урон тайлу.",
		),
		list(
			"label" = "Декоративный",
			"value" = "decorative",
			"description" = "Только визуальный огонь. Сохраняет свет и путь очистки владельца, но не наносит урон мобам и тайлам.",
		),
	)

/datum/world_edit_generator/destruction_pack/proc/resolve_persistent_fire_mode(value)
	if(isnull(value) || !length("[value]") || "[value]" == "null")
		return get_default_persistent_fire_mode()

	var/resolved_value = lowertext(trim("[value]"))
	switch(resolved_value)
		if("damaging", "decorative")
			return resolved_value
	return null

/datum/world_edit_generator/destruction_pack/proc/get_persistent_fire_mode_label(mode)
	switch(resolve_persistent_fire_mode(mode))
		if("decorative")
			return "Декоративный"
	return "С уроном"

/datum/world_edit_generator/destruction_pack/proc/get_default_persistent_fire_color_id()
	return "amber"

/datum/world_edit_generator/destruction_pack/proc/build_persistent_fire_color_options()
	return list(
		list(
			"label" = "Янтарный",
			"value" = "amber",
			"description" = "Классический цвет огня панели редактирования мира.",
		),
		list(
			"label" = "Белый",
			"value" = "white",
			"description" = "Холодное белое пламя для стерильных или электрических сцен.",
		),
		list(
			"label" = "Красный",
			"value" = "red",
			"description" = "Тревожно-красное пламя.",
		),
		list(
			"label" = "Синий",
			"value" = "blue",
			"description" = "Горячее синее пламя.",
		),
		list(
			"label" = "Зеленый",
			"value" = "green",
			"description" = "Пламя с токсичным или химическим оттенком.",
		),
		list(
			"label" = "Фиолетовый",
			"value" = "violet",
			"description" = "Синтетическое фиолетовое пламя.",
		),
		list(
			"label" = "Пользовательский",
			"value" = "custom",
			"description" = "Использовать собственный цвет #RRGGBB.",
		),
	)

/datum/world_edit_generator/destruction_pack/proc/resolve_persistent_fire_color_id(value)
	if(isnull(value) || !length("[value]") || "[value]" == "null")
		return get_default_persistent_fire_color_id()

	var/resolved_value = lowertext(trim("[value]"))
	switch(resolved_value)
		if("amber", "white", "red", "blue", "green", "violet", "custom")
			return resolved_value
	return null

/datum/world_edit_generator/destruction_pack/proc/normalize_persistent_fire_custom_color(value)
	var/raw_value = trim(sanitize_text(value, ""))
	if(!length(raw_value))
		return ""
	return sanitize_hexcolor(raw_value, "")

/datum/world_edit_generator/destruction_pack/proc/get_persistent_fire_preset_color(color_id)
	switch(resolve_persistent_fire_color_id(color_id))
		if("white")
			return "#f4f7ff"
		if("red")
			return "#ff5f63"
		if("blue")
			return "#4fc3ff"
		if("green")
			return "#6aff8f"
		if("violet")
			return "#c284ff"
	return "#ff8c2b"

/datum/world_edit_generator/destruction_pack/proc/resolve_persistent_fire_color(color_id, custom_color = null)
	var/resolved_color_id = resolve_persistent_fire_color_id(color_id)
	if(isnull(resolved_color_id))
		return null
	if(resolved_color_id == "custom")
		var/resolved_custom_color = normalize_persistent_fire_custom_color(custom_color)
		if(!length(resolved_custom_color))
			return null
		return resolved_custom_color
	return get_persistent_fire_preset_color(resolved_color_id)

/datum/world_edit_generator/destruction_pack/proc/get_persistent_fire_color_label(color_id, custom_color = null)
	switch(resolve_persistent_fire_color_id(color_id))
		if("white")
			return "Белый"
		if("red")
			return "Красный"
		if("blue")
			return "Синий"
		if("green")
			return "Зеленый"
		if("violet")
			return "Фиолетовый"
		if("custom")
			var/resolved_custom_color = normalize_persistent_fire_custom_color(custom_color)
			return length(resolved_custom_color) ? "Пользовательский ([resolved_custom_color])" : "Пользовательский"
	return "Янтарный"

/datum/world_edit_generator/destruction_pack/proc/get_blast_power_min()
	return 100

/datum/world_edit_generator/destruction_pack/proc/get_blast_power_max()
	return 5000

/datum/world_edit_generator/destruction_pack/proc/get_blast_power_default()
	return 250

/datum/world_edit_generator/destruction_pack/proc/get_blast_falloff_min()
	return 100

/datum/world_edit_generator/destruction_pack/proc/get_blast_falloff_max()
	return 10000

/datum/world_edit_generator/destruction_pack/proc/get_blast_falloff_default()
	return 600

/datum/world_edit_generator/destruction_pack/proc/coerce_persistent_fire_density_percent(value)
	var/density = text2num("[value]")
	if(!isnum(density))
		return null
	if(density > 0 && density <= 1)
		density *= 100
	return density

/datum/world_edit_generator/destruction_pack/proc/normalize_persistent_fire_density_percent(value)
	var/density = coerce_persistent_fire_density_percent(value)
	if(!isnum(density))
		return get_persistent_fire_density_default()
	return clamp(round(density), get_persistent_fire_density_min(), get_persistent_fire_density_max())

/datum/world_edit_generator/destruction_pack/proc/build_damage_profile_options()
	return list(
		list(
			"label" = "Нет",
			"value" = "none",
			"description" = "Применяются только перемешивание, разброс, постоянный огонь и/или взрыв.",
		),
		list(
			"label" = "Руины",
			"value" = "ruin",
			"description" = "Слабые структурные повреждения и урон тайлам. Затрагивается только центральная зона влияния.",
		),
		list(
			"label" = "Обрушение",
			"value" = "collapse",
			"description" = "Более сильные структурные повреждения. Центральная зона обрушивается, а средняя получает урон как у режима 'Руины'.",
		),
	)

/datum/world_edit_generator/destruction_pack/proc/get_default_damage_profile()
	return "none"

/datum/world_edit_generator/destruction_pack/proc/resolve_damage_profile(value)
	if(isnull(value) || !length("[value]") || "[value]" == "null")
		return get_default_damage_profile()

	var/profile_id = "[value]"
	switch(profile_id)
		if("none", "ruin", "collapse")
			return profile_id
	return null

/datum/world_edit_generator/destruction_pack/proc/get_damage_profile_label(profile_id)
	switch(resolve_damage_profile(profile_id))
		if("ruin")
			return "Руины"
		if("collapse")
			return "Обрушение"
	return "Нет"

/datum/world_edit_generator/destruction_pack/proc/get_damage_profile_severity(profile_id)
	switch(resolve_damage_profile(profile_id))
		if("ruin")
			return EXPLOSION_THRESHOLD_VLOW
		if("collapse")
			return EXPLOSION_THRESHOLD_LOW
	return 0

/datum/world_edit_generator/destruction_pack/proc/get_structural_damage_power(atom/target_atom, severity)
	if(!target_atom || severity <= 0)
		return 0

	if(istype(target_atom, /turf/closed/wall))
		var/damage = severity * EXPLOSION_DAMAGE_MULTIPLIER_WALL
		if(istype(target_atom, /turf/closed/wall/resin))
			damage *= RESIN_EXPLOSIVE_MULTIPLIER
		return damage

	if(istype(target_atom, /obj/structure/window))
		return severity * EXPLOSION_DAMAGE_MULTIPLIER_WINDOW

	if(istype(target_atom, /obj/structure/machinery/door/airlock) || istype(target_atom, /obj/structure/airlock_assembly) || istype(target_atom, /obj/structure/mineral_door))
		var/damage = severity * EXPLOSION_DAMAGE_MULTIPLIER_DOOR
		if(!target_atom.density)
			damage *= EXPLOSION_DAMAGE_MODIFIER_DOOR_OPEN
		return damage

	return severity

/datum/world_edit_generator/destruction_pack/proc/apply_nonterminal_progress_damage(atom/target_atom, damage_amount, mob/source_mob = null)
	if(!target_atom || QDELETED(target_atom) || damage_amount <= 0)
		return FALSE
	if(!hasvar(target_atom, "damage") || !hasvar(target_atom, "damage_cap"))
		return FALSE

	var/current_damage = text2num("[target_atom.vars["damage"]]")
	var/damage_cap = text2num("[target_atom.vars["damage_cap"]]")
	if(!isnum(current_damage) || !isnum(damage_cap) || damage_cap <= 1)
		return FALSE

	var/remaining_budget = max(damage_cap - current_damage - 1, 0)
	if(remaining_budget <= 0)
		return TRUE

	var/applied_damage = min(damage_amount, remaining_budget)
	if(applied_damage <= 0)
		return TRUE

	if(hascall(target_atom, "take_damage"))
		call(target_atom, "take_damage")(applied_damage, source_mob)
	else
		target_atom.vars["damage"] = current_damage + applied_damage

	return TRUE

/datum/world_edit_generator/destruction_pack/proc/apply_nonterminal_health_damage(atom/target_atom, damage_amount)
	if(!target_atom || QDELETED(target_atom) || damage_amount <= 0)
		return FALSE
	if(!hasvar(target_atom, "health"))
		return FALSE

	var/current_health = text2num("[target_atom.vars["health"]]")
	if(!isnum(current_health) || current_health <= 1)
		return FALSE

	var/applied_damage = min(damage_amount, current_health - 1)
	if(applied_damage <= 0)
		return TRUE

	target_atom.vars["health"] = current_health - applied_damage
	if(hascall(target_atom, "healthcheck"))
		call(target_atom, "healthcheck")()

	return TRUE

/datum/world_edit_generator/destruction_pack/proc/apply_ruin_damage_to_turf(turf/target_turf, severity, datum/cause_data/cause_data)
	if(!istype(target_turf) || severity <= 0)
		return FALSE

	var/mob/source_mob = cause_data?.resolve_mob()
	if(istype(target_turf, /turf/closed/wall))
		var/damage_amount = get_structural_damage_power(target_turf, severity)
		return apply_nonterminal_progress_damage(target_turf, damage_amount, source_mob)

	if(istype(target_turf, /turf/open/floor))
		var/turf/open/floor/floor_turf = target_turf
		floor_turf.break_tile()
		return TRUE

	return FALSE

/datum/world_edit_generator/destruction_pack/proc/apply_ruin_damage_to_atom(atom/target_atom, severity, datum/cause_data/cause_data)
	if(!target_atom || QDELETED(target_atom) || ismob(target_atom) || severity <= 0)
		return FALSE
	if(istype(target_atom, /obj/effect/world_edit_persistent_fire))
		return FALSE

	var/mob/source_mob = cause_data?.resolve_mob()
	var/damage_amount = get_structural_damage_power(target_atom, severity)
	if(damage_amount <= 0)
		return FALSE

	if(apply_nonterminal_progress_damage(target_atom, damage_amount, source_mob))
		return TRUE
	if(apply_nonterminal_health_damage(target_atom, damage_amount))
		return TRUE

	return FALSE

/datum/world_edit_generator/destruction_pack/proc/can_place_persistent_fire_on_turf(turf/target_turf)
	if(!istype(target_turf) || target_turf.density)
		return FALSE
	if(locate(/obj/effect/world_edit_persistent_fire) in target_turf)
		return FALSE
	return TRUE

/datum/world_edit_generator/destruction_pack/proc/build_damage_entries(list/influence_turfs, list/influence_lookup, damage_profile, plan_seed = 0)
	var/list/damage_entries = list()
	var/resolved_profile = resolve_damage_profile(damage_profile)
	if(resolved_profile == "none" || !length(influence_turfs))
		return damage_entries

	var/list/core_turfs = list()
	var/list/mid_turfs = list()
	var/list/outer_turfs = list()
	for(var/turf/influence_turf as anything in influence_turfs)
		var/list/influence_info = islist(influence_lookup) ? influence_lookup[influence_turf] : null
		var/band = islist(influence_info) ? "[influence_info["band"]]" : ""
		if(band == "core")
			core_turfs += influence_turf
		else if(band == "mid")
			mid_turfs += influence_turf
		else if(band == "outer")
			outer_turfs += influence_turf

	if(length(core_turfs))
		damage_entries += list(list(
			"kind" = "damage",
			"area_turfs" = core_turfs.Copy(),
			"damage_profile" = resolved_profile,
			"severity" = get_damage_profile_severity(resolved_profile),
			"band" = "core",
		))
	if(resolved_profile == "collapse" && length(mid_turfs))
		damage_entries += list(list(
			"kind" = "damage",
			"area_turfs" = mid_turfs.Copy(),
			"damage_profile" = "ruin",
			"severity" = get_damage_profile_severity("ruin"),
			"band" = "mid",
		))
	var/list/mid_spill_turfs = list()
	var/list/outer_spill_turfs = list()
	switch(resolved_profile)
		if("ruin")
			mid_spill_turfs = build_weighted_turf_subset(mid_turfs, influence_lookup, 0.55, plan_seed, 500)
			outer_spill_turfs = build_weighted_turf_subset(outer_turfs, influence_lookup, 0.3, plan_seed, 700)
		if("collapse")
			outer_spill_turfs = build_weighted_turf_subset(outer_turfs, influence_lookup, 0.45, plan_seed, 900)
	if(length(mid_spill_turfs))
		damage_entries += list(list(
			"kind" = "damage",
			"area_turfs" = mid_spill_turfs,
			"damage_profile" = "ruin",
			"severity" = get_damage_profile_severity("ruin"),
			"band" = "mid_spill",
		))
	if(length(outer_spill_turfs))
		damage_entries += list(list(
			"kind" = "damage",
			"area_turfs" = outer_spill_turfs,
			"damage_profile" = "ruin",
			"severity" = get_damage_profile_severity("ruin"),
			"band" = "outer",
		))

	return damage_entries

/datum/world_edit_generator/destruction_pack/proc/build_blast_centers(list/seed_turfs, turf/center_turf, radius, plan_seed)
	var/list/centers = list()
	if(!islist(seed_turfs) || !length(seed_turfs) || radius < 1)
		return centers

	if(!istype(center_turf))
		center_turf = build_shape_center_turf(seed_turfs)
	if(!istype(center_turf))
		return centers

	centers += center_turf

	var/requires_secondary_centers = FALSE
	for(var/turf/seed_turf as anything in seed_turfs)
		if(get_chebyshev_distance(center_turf, seed_turf) > radius)
			requires_secondary_centers = TRUE
			break
	if(!requires_secondary_centers)
		return centers

	while(length(centers) < 6)
		var/turf/best_candidate = null
		var/best_score = -1
		for(var/turf/candidate_turf as anything in seed_turfs)
			if(!istype(candidate_turf))
				continue

			var/min_distance_to_existing = WORLD_EDIT_PLACEMENT_MAX_TOTAL_PLACEMENTS
			for(var/turf/existing_center as anything in centers)
				min_distance_to_existing = min(min_distance_to_existing, get_chebyshev_distance(candidate_turf, existing_center))

			if(min_distance_to_existing <= radius * 2)
				continue

			var/score = (min_distance_to_existing * 100) + get_deterministic_turf_score(plan_seed, candidate_turf, length(centers))
			if(score <= best_score)
				continue

			best_score = score
			best_candidate = candidate_turf

		if(!istype(best_candidate))
			break

		centers += best_candidate

	return centers

/datum/world_edit_generator/destruction_pack/proc/build_blast_entries(list/seed_turfs, turf/center_turf, radius, blast_power, blast_falloff, plan_seed)
	var/list/blast_entries = list()
	var/list/blast_centers = build_blast_centers(seed_turfs, center_turf, radius, plan_seed)
	var/index = 0
	for(var/turf/blast_center as anything in blast_centers)
		index++
		var/effective_power = index == 1 ? blast_power : max(1, round(blast_power * 0.6))
		var/effective_falloff = index == 1 ? blast_falloff : max(1, round(blast_falloff * 0.75))
		blast_entries += list(list(
			"kind" = "blast",
			"center_turf" = blast_center,
			"power" = effective_power,
			"falloff" = effective_falloff,
			"blast_index" = index,
		))

	return blast_entries

/datum/world_edit_generator/destruction_pack/proc/apply_structural_damage_profile(list/area_turfs, severity, datum/cause_data/cause_data, damage_profile = "collapse")
	var/damaged_turf_count = 0
	if(!islist(area_turfs) || !length(area_turfs) || severity <= 0)
		return damaged_turf_count

	var/resolved_profile = resolve_damage_profile(damage_profile)
	var/preserve_targets = resolved_profile == "ruin"

	for(var/turf/target_turf as anything in area_turfs)
		if(!istype(target_turf))
			continue

		var/applied_turf_damage = FALSE
		var/applied_atom_damage = FALSE
		if(preserve_targets)
			applied_turf_damage = apply_ruin_damage_to_turf(target_turf, severity, cause_data)
		else
			target_turf.ex_act(severity, null, cause_data)
			applied_turf_damage = TRUE

		for(var/atom/target_atom as anything in target_turf)
			if(QDELETED(target_atom))
				continue
			if(ismob(target_atom))
				continue
			if(istype(target_atom, /obj/effect/world_edit_persistent_fire))
				continue
			if(preserve_targets)
				applied_atom_damage = apply_ruin_damage_to_atom(target_atom, severity, cause_data) || applied_atom_damage
				continue
			target_atom.ex_act(severity, null, cause_data)
			applied_atom_damage = TRUE

		if(applied_turf_damage || applied_atom_damage)
			damaged_turf_count++

	return damaged_turf_count

/datum/world_edit_generator/destruction_pack/proc/build_persistent_fire_entries(list/influence_turfs, list/influence_lookup, density, plan_seed, fire_color = null, fire_mode = null)
	var/list/fire_entries = list()
	if(!length(influence_turfs) || density <= 0)
		return fire_entries

	var/resolved_fire_color = sanitize_hexcolor(fire_color, get_persistent_fire_preset_color(get_default_persistent_fire_color_id()))
	var/resolved_fire_mode = resolve_persistent_fire_mode(fire_mode) || get_default_persistent_fire_mode()

	var/list/pool = list()
	for(var/turf/target_turf as anything in influence_turfs)
		if(can_place_persistent_fire_on_turf(target_turf))
			pool += target_turf
	if(!length(pool))
		return fire_entries

	var/density_ratio = density / 100
	var/target_count = round(length(pool) * density_ratio)
	target_count = clamp(target_count, 0, get_persistent_fire_cap())
	if(target_count <= 0)
		return fire_entries

	while(target_count > 0 && length(pool))
		var/turf/selected_turf = pick_weighted_turf(pool, influence_lookup, plan_seed, 1000 + length(fire_entries))
		if(!istype(selected_turf))
			break

		pool -= selected_turf
		fire_entries += list(list(
			"kind" = "fire",
			"turf" = selected_turf,
			"fire_color" = resolved_fire_color,
			"fire_mode" = resolved_fire_mode,
		))
		target_count--

	return fire_entries

/datum/world_edit_generator/destruction_pack/proc/build_target_movement_entry(atom/movable/target, list/area_turfs, list/influence_lookup, shuffle_enabled, scatter_enabled, scatter_steps, plan_seed, salt = 0)
	if(!target || QDELETED(target))
		return null

	var/turf/source_turf = get_turf(target)
	if(!source_turf)
		return null

	var/source_weight = get_balanced_influence_selection_weight(get_influence_weight_for_turf(influence_lookup, source_turf))
	if(source_weight <= 0)
		return null
	if(get_deterministic_turf_score(plan_seed, source_turf, salt) > source_weight)
		return null

	var/list/path_turfs = list()
	var/turf/current_turf = source_turf

	if(shuffle_enabled)
		var/list/shuffle_candidates = list()
		for(var/turf/candidate_turf as anything in area_turfs)
			if(candidate_turf == current_turf)
				continue
			if(!can_relocate_target_to_turf(target, candidate_turf))
				continue
			shuffle_candidates += candidate_turf

		var/turf/shuffle_turf = pick_weighted_turf(shuffle_candidates, influence_lookup, plan_seed, salt + 100)
		if(shuffle_turf && shuffle_turf != current_turf)
			path_turfs += shuffle_turf
			current_turf = shuffle_turf

	if(scatter_enabled)
		for(var/i in 1 to scatter_steps)
			var/list/step_candidates = list()
			for(var/cardinal_dir in GLOB.cardinals)
				var/turf/next_turf = get_step(current_turf, cardinal_dir)
				if(!next_turf || !influence_lookup[next_turf] || next_turf == current_turf)
					continue
				if(!can_relocate_target_to_turf(target, next_turf))
					continue
				step_candidates += next_turf

			var/turf/next_turf = pick_weighted_turf(step_candidates, influence_lookup, plan_seed, salt + (200 * i))
			if(!next_turf)
				continue

			path_turfs += next_turf
			current_turf = next_turf

	if(!length(path_turfs))
		return null

	return list(
		"kind" = "move",
		"target_ref" = WEAKREF(target),
		"source_turf" = source_turf,
		"path_turfs" = path_turfs,
		"destination_turf" = current_turf,
	)
