/// Постоянный огонь для World Edit.
/// Не затухает сам со временем и тушится штатным огнетушителем через water.reaction_obj -> extinguish().
/obj/effect/world_edit_persistent_fire
	name = "persistent fire"
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

	/// Урон мобам в секунду.
	var/damage_per_second = 4
	/// Значение fire-stacks, добавляемое в секунду.
	var/fire_stacks_per_second = 2
	/// Интенсивность воздействия на турф через flamer_fire_act.
	var/turf_fire_act_per_second = 8

/obj/effect/world_edit_persistent_fire/Initialize(mapload, ...)
	. = ..()
	START_PROCESSING(SSobj, src)

/obj/effect/world_edit_persistent_fire/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/effect/world_edit_persistent_fire/process(delta_time)
	var/turf/target_turf = get_turf(src)
	if(!istype(target_turf))
		qdel(src)
		return PROCESS_KILL

	target_turf.flamer_fire_act(turf_fire_act_per_second * delta_time)

	for(var/mob/living/living_mob in target_turf)
		living_mob.TryIgniteMob(max(fire_stacks_per_second * delta_time, 1))
		living_mob.apply_damage(damage_per_second * delta_time, BURN)

	return

/obj/effect/world_edit_persistent_fire/extinguish()
	qdel(src)
