/// Постоянный огонь для World Edit.
/// Не затухает сам со временем и тушится штатным огнетушителем через water.reaction_obj -> extinguish().
/obj/effect/world_edit_persistent_fire
	name = "постоянный огонь"
	desc = "Административный очаг постоянного горения."
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	icon = 'icons/effects/fire.dmi'
	icon_state = "dynamic_2"
	layer = BELOW_OBJ_LAYER

	light_system = STATIC_LIGHT
	light_on = TRUE
	light_range = 3
	light_power = 3
	light_color = "#ff8c2b"
	color = "#ff8c2b"

	/// Урон мобам в секунду.
	var/damage_per_second = 4
	/// Значение fire-stacks, добавляемое в секунду.
	var/fire_stacks_per_second = 2
	/// Интенсивность воздействия на турф через flamer_fire_act.
	var/turf_fire_act_per_second = 8
	/// Итоговый цвет визуала и света.
	var/fire_color = "#ff8c2b"
	/// Режим persistent fire: damaging или decorative.
	var/fire_mode = "damaging"
	/// Operation id владельца эффекта для cleanup-path World Edit.
	var/world_edit_owner_operation_id = ""
	/// Generator id источника эффекта.
	var/world_edit_source_generator_id = ""

/obj/effect/world_edit_persistent_fire/Initialize(mapload, ...)
	. = ..()
	configure_persistent_fire(fire_color, fire_mode)
	START_PROCESSING(SSobj, src)

/obj/effect/world_edit_persistent_fire/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/effect/world_edit_persistent_fire/process(delta_time)
	var/turf/target_turf = get_turf(src)
	if(!istype(target_turf))
		qdel(src)
		return PROCESS_KILL

	if(is_decorative_mode())
		return

	target_turf.flamer_fire_act(turf_fire_act_per_second * delta_time)

	for(var/mob/living/living_mob in target_turf)
		living_mob.TryIgniteMob(max(fire_stacks_per_second * delta_time, 1))
		living_mob.apply_damage(damage_per_second * delta_time, BURN)

	return

/obj/effect/world_edit_persistent_fire/extinguish()
	qdel(src)

/obj/effect/world_edit_persistent_fire/proc/configure_persistent_fire(new_fire_color, new_fire_mode)
	var/resolved_color = sanitize_hexcolor(new_fire_color, initial(light_color))
	if(!length(resolved_color))
		resolved_color = initial(light_color)

	fire_color = resolved_color
	color = resolved_color
	set_light(l_color = resolved_color)

	var/resolved_mode = lowertext(trim("[new_fire_mode]"))
	if(resolved_mode != "decorative")
		resolved_mode = "damaging"
	fire_mode = resolved_mode

/obj/effect/world_edit_persistent_fire/proc/is_decorative_mode()
	return fire_mode == "decorative"

/obj/effect/world_edit_persistent_fire/proc/set_world_edit_owner(operation_id, generator_id)
	world_edit_owner_operation_id = length("[operation_id]") ? "[operation_id]" : ""
	world_edit_source_generator_id = length("[generator_id]") ? "[generator_id]" : ""
