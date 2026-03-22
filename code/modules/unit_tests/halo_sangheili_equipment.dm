#define HALO_TEST_R_HAND_LAYER 5
#define HALO_TEST_L_HAND_LAYER 6

/datum/unit_test/halo_sangheili_equipment/proc/create_sangheili(preset_type)
	var/turf/spawn_turf = get_sangheili_test_origin(8)
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human, spawn_turf)
	arm_equipment(human, preset_type, FALSE)
	track_sangheili_test_human(human)
	return human

/datum/unit_test/halo_sangheili_equipment/proc/create_baseline_human()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human, get_sangheili_test_origin(1))
	track_sangheili_test_human(human)
	return human

/datum/unit_test/halo_sangheili_equipment
	var/list/tracked_test_humans

/datum/unit_test/halo_sangheili_equipment/New()
	. = ..()
	tracked_test_humans = list()

/datum/unit_test/halo_sangheili_equipment/Destroy()
	for(var/mob/living/carbon/human/human as anything in tracked_test_humans)
		if(!QDELETED(human))
			qdel(human)

	tracked_test_humans = null
	return ..()

/datum/unit_test/halo_sangheili_equipment/proc/track_sangheili_test_human(mob/living/carbon/human/human)
	if(human)
		tracked_test_humans += human

/datum/unit_test/halo_sangheili_equipment/proc/create_sangheili_ai_brain(preset_type)
	var/mob/living/carbon/human/human = create_sangheili(preset_type)
	var/datum/component/human_ai/ai_component = human.AddComponent(/datum/component/human_ai)
	if(!ai_component)
		TEST_FAIL("Failed to add a human AI component to the HALO Sangheili test mob.")
		return null
	if(!ai_component.ai_brain)
		TEST_FAIL("Failed to resolve a human AI brain for the HALO Sangheili test mob.")
		return null
	ai_component.ai_brain.appraise_inventory(armor = TRUE)
	if(isgun(human.s_store))
		ai_component.ai_brain.set_primary_weapon(human.s_store)
	return ai_component.ai_brain

/datum/unit_test/halo_sangheili_equipment/proc/count_belt_items(mob/living/carbon/human/human, item_type)
	if(!human || !human.belt)
		return 0

	var/count = 0
	for(var/obj/item/item as anything in human.belt.contents)
		if(istype(item, item_type))
			count++
	return count

/datum/unit_test/halo_sangheili_equipment/proc/create_test_projectile(mob/living/carbon/human/firer, ammo_type)
	var/obj/projectile/projectile = allocate(/obj/projectile, run_loc_floor_top_right)
	var/datum/ammo/ammo = allocate(ammo_type)
	projectile.generate_bullet(ammo, 0, 0, firer)
	projectile.starting = get_turf(firer)
	projectile.def_zone = "chest"
	projectile.firer = firer
	return projectile

/datum/unit_test/halo_sangheili_equipment/proc/find_target_turf_from_origin(turf/origin, distance)
	if(!origin)
		return null

	for(var/direction in GLOB.cardinals)
		var/turf/current_turf = origin
		var/path_clear = TRUE
		for(var/i in 1 to distance)
			current_turf = get_step(current_turf, direction)
			if(!is_clear_sangheili_path_turf(current_turf))
				path_clear = FALSE
				break
		if(path_clear)
			return current_turf

	return null

/datum/unit_test/halo_sangheili_equipment/proc/is_clear_sangheili_path_turf(turf/current_turf)
	if(!isfloorturf(current_turf))
		return FALSE

	if(current_turf.density)
		return FALSE

	for(var/obj/object in current_turf)
		if(object.density)
			return FALSE

	return TRUE

/datum/unit_test/halo_sangheili_equipment/proc/get_sangheili_test_origin(min_clear_distance = 1)
	var/static/list/cached_origins = list()
	var/cache_key = "[min_clear_distance]"
	var/turf/cached_origin = cached_origins[cache_key]
	if(isfloorturf(cached_origin) && find_target_turf_from_origin(cached_origin, min_clear_distance))
		return cached_origin

	var/search_radius = max(min_clear_distance + 4, 6)
	var/list/search_roots = list(run_loc_floor_top_right, run_loc_floor_bottom_left, SSmapping?.get_mainship_center())
	var/list/search_levels = list()
	for(var/turf/root as anything in search_roots)
		if(!isfloorturf(root))
			continue
		if(!(root.z in search_levels))
			search_levels += root.z
		for(var/turf/floor_tile as anything in range(search_radius, root))
			if(!isfloorturf(floor_tile))
				continue
			if(find_target_turf_from_origin(floor_tile, min_clear_distance))
				cached_origins[cache_key] = floor_tile
				return floor_tile

	for(var/z_level as anything in search_levels)
		var/turf/start_corner = locate(1, 1, z_level)
		var/turf/end_corner = locate(world.maxx, world.maxy, z_level)
		if(!start_corner || !end_corner)
			continue
		for(var/turf/floor_tile as anything in block(start_corner, end_corner))
			if(!isfloorturf(floor_tile))
				continue
			if(find_target_turf_from_origin(floor_tile, min_clear_distance))
				cached_origins[cache_key] = floor_tile
				return floor_tile

	var/turf/fallback_origin = isfloorturf(run_loc_floor_top_right) ? run_loc_floor_top_right : run_loc_floor_bottom_left
	cached_origins[cache_key] = ensure_clear_sangheili_lane(fallback_origin, EAST, min_clear_distance)
	return cached_origins[cache_key]

/datum/unit_test/halo_sangheili_equipment/proc/ensure_clear_sangheili_lane(turf/origin, direction, distance)
	if(!isturf(origin))
		return null

	var/turf/current_turf = origin
	for(var/i in 0 to distance)
		if(!isturf(current_turf))
			return null
		if(!isfloorturf(current_turf))
			current_turf = current_turf.ChangeTurf(/turf/open/floor/plating)
		for(var/atom/movable/blocker as anything in current_turf)
			if(ismob(blocker) || !blocker.density)
				continue
			qdel(blocker)
		if(i < distance)
			current_turf = get_step(current_turf, direction)

	return origin

/datum/unit_test/halo_sangheili_equipment/proc/set_target_turf(datum/human_ai_brain/brain, distance)
	var/turf/origin = get_turf(brain?.tied_human)
	if(!origin)
		return null

	var/turf/linear_target = find_target_turf_from_origin(origin, distance)
	if(linear_target)
		return linear_target

	for(var/direction in GLOB.cardinals)
		var/turf/prepared_origin = ensure_clear_sangheili_lane(origin, direction, distance)
		if(!prepared_origin)
			continue
		linear_target = get_offset_turf_from_direction(prepared_origin, direction, distance)
		if(isfloorturf(linear_target))
			return linear_target

	for(var/turf/floor_tile as anything in range(distance, origin))
		if(!isfloorturf(floor_tile))
			continue
		if(get_dist(origin, floor_tile) < distance)
			continue
		if(AStar(origin, floor_tile, /turf/proc/AdjacentTurfs, /turf/proc/Distance, 0, 0))
			return floor_tile

	return null

/datum/unit_test/halo_sangheili_equipment/proc/get_offset_turf_from_direction(turf/origin, direction, distance)
	var/turf/current_turf = origin
	for(var/i in 1 to distance)
		current_turf = get_step(current_turf, direction)
		if(!isturf(current_turf))
			return null

	return current_turf

/datum/unit_test/halo_sangheili_equipment/proc/get_belt_sword(mob/living/carbon/human/human)
	if(!human?.belt)
		return null

	return locate(/obj/item/weapon/covenant/energy_sword) in human.belt

/datum/unit_test/halo_sangheili_equipment/proc/find_accessible_sword(mob/living/carbon/human/human)
	if(!human)
		return null

	var/obj/item/weapon/covenant/energy_sword/sword = get_belt_sword(human)
	if(sword)
		return sword

	if(istype(human.l_hand, /obj/item/weapon/covenant/energy_sword))
		return human.l_hand

	if(istype(human.r_hand, /obj/item/weapon/covenant/energy_sword))
		return human.r_hand

	if(istype(human.s_store, /obj/item/weapon/covenant/energy_sword))
		return human.s_store

	return locate(/obj/item/weapon/covenant/energy_sword) in get_turf(human)

/datum/unit_test/halo_sangheili_equipment/proc/put_sword_in_active_hand(mob/living/carbon/human/human)
	var/obj/item/weapon/covenant/energy_sword/sword = find_accessible_sword(human)
	if(!human || !sword)
		return null

	if(istype(sword.loc, /obj/item/storage))
		var/obj/item/storage/storage = sword.loc
		storage.remove_from_storage(sword, human)

	if(sword.loc != human && sword.loc != get_turf(human))
		return null

	if(human.get_active_hand())
		human.drop_held_item(human.get_active_hand())

	if(!human.put_in_hands(sword, FALSE))
		return null

	return sword

/datum/unit_test/halo_sangheili_equipment/proc/get_held_sword_overlay_icon_state(mob/living/carbon/human/human, obj/item/weapon/covenant/energy_sword/sword)
	if(!human || !sword)
		return null

	if(human.r_hand == sword)
		var/image/held_overlay = human.overlays_standing[HALO_TEST_R_HAND_LAYER] // SS220 EDIT: type overlay lookup for DreamChecker before reading icon_state
		return held_overlay?.icon_state

	if(human.l_hand == sword)
		var/image/held_overlay = human.overlays_standing[HALO_TEST_L_HAND_LAYER] // SS220 EDIT: type overlay lookup for DreamChecker before reading icon_state
		return held_overlay?.icon_state

	return null

/datum/unit_test/halo_sangheili_equipment/proc/icon_state_has_visible_pixels(icon/icon_file, state, direction)
	var/icon/state_icon = icon(icon_file, state, direction)
	for(var/x in 1 to state_icon.Width())
		for(var/y in 1 to state_icon.Height())
			if(!isnull(state_icon.GetPixel(x, y)))
				return TRUE

	return FALSE

/datum/unit_test/halo_sangheili_equipment/Run()
	return


/datum/unit_test/halo_sangheili_recovery_reduction
	parent_type = /datum/unit_test/halo_sangheili_equipment

/datum/unit_test/halo_sangheili_recovery_reduction/Run()
	var/mob/living/carbon/human/baseline_human = create_baseline_human()
	var/mob/living/carbon/human/sangheili = create_sangheili(/datum/equipment_preset/covenant/sangheili/minor)
	TEST_ASSERT_NOTNULL(baseline_human, "Failed to allocate the baseline human for Sangheili recovery testing.")
	TEST_ASSERT_NOTNULL(sangheili, "Failed to create the Sangheili mob for recovery testing.")

	var/base_stun = baseline_human.GetStunDuration(30)
	var/base_knockdown = baseline_human.GetKnockDownDuration(30)
	var/base_knockout = baseline_human.GetKnockOutDuration(30)
	var/sangheili_stun = sangheili.GetStunDuration(30)
	var/sangheili_knockdown = sangheili.GetKnockDownDuration(30)
	var/sangheili_knockout = sangheili.GetKnockOutDuration(30)

	TEST_ASSERT(sangheili_stun < base_stun, "Sangheili stun recovery should now be faster than the baseline human duration.")
	TEST_ASSERT(sangheili_knockdown < base_knockdown, "Sangheili knockdown recovery should now be faster than the baseline human duration.")
	TEST_ASSERT(sangheili_knockout < base_knockout, "Sangheili knockout recovery should now be faster than the baseline human duration.")

/datum/unit_test/halo_sangheili_player_sword_manual_activation_guard
	parent_type = /datum/unit_test/halo_sangheili_equipment

/datum/unit_test/halo_sangheili_player_sword_manual_activation_guard/Run()
	var/mob/living/carbon/human/human = create_sangheili(/datum/equipment_preset/covenant/sangheili/ultra)
	TEST_ASSERT_NOTNULL(human, "Failed to create the HALO player Sangheili for manual sword activation guard testing.")

	var/obj/item/weapon/covenant/energy_sword/sword = put_sword_in_active_hand(human)
	TEST_ASSERT_NOTNULL(sword, "Failed to move the HALO player Sangheili sword into the active hand for guard testing.")
	TEST_ASSERT(!sword.activated, "Player Sangheili sword guard test should begin with an inactive sword.")

	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	TEST_ASSERT_NOTNULL(target, "Failed to allocate a target for HALO player sword guard testing.")
	human.a_intent_change(INTENT_HARM)
	sword.attack(target, human)

	TEST_ASSERT(!sword.activated, "Player-controlled Sangheili should still require manual sword activation.")

/datum/unit_test/halo_sangheili_sword_overlay_refresh
	parent_type = /datum/unit_test/halo_sangheili_equipment

/datum/unit_test/halo_sangheili_sword_overlay_refresh/Run()
	var/mob/living/carbon/human/human = create_sangheili(/datum/equipment_preset/covenant/sangheili/ultra)
	TEST_ASSERT_NOTNULL(human, "Failed to create the HALO Sangheili for sword overlay refresh testing.")

	var/obj/item/weapon/covenant/energy_sword/sword = put_sword_in_active_hand(human)
	TEST_ASSERT_NOTNULL(sword, "Failed to move the HALO Sangheili sword into the active hand for overlay refresh testing.")

	human.update_inv_l_hand()
	human.update_inv_r_hand()
	TEST_ASSERT_EQUAL(get_held_sword_overlay_icon_state(human, sword), "energy_sword", "Inactive HALO sword overlay should start with the inactive hand state.")

	sword.set_activation_state(TRUE, human)
	TEST_ASSERT_EQUAL(get_held_sword_overlay_icon_state(human, sword), "energy_sword_activated", "Activating the HALO sword should refresh the held overlay immediately.")

	sword.set_activation_state(FALSE, human)
	TEST_ASSERT_EQUAL(get_held_sword_overlay_icon_state(human, sword), "energy_sword", "Deactivating the HALO sword should refresh the held overlay back to the inactive state.")

#undef HALO_TEST_R_HAND_LAYER
#undef HALO_TEST_L_HAND_LAYER
