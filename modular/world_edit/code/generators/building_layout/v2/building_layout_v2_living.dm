/datum/world_edit_generator/building_layout/proc/build_building_v2_program_contract(program_id)
	switch("[program_id]")
		if("living")
			return build_living_program_contract_v2()
	return null

/datum/world_edit_generator/building_layout/proc/build_living_program_contract_v2()
	var/datum/world_edit_building_v2_program_contract/program = new
	program.id = "living"
	program.allowed_layout_patterns = list(
		"front_common_back_private",
		"central_spine_rooms",
		"side_spine_room_row",
	)

	var/datum/world_edit_building_v2_room_contract/entry_common = new("entry_common", "entry_common", "common", TRUE, 25, 40, 72, 5, 5, 12, 7)
	entry_common.privacy_class = "public"
	entry_common.exterior_window_policy = "desired"
	entry_common.window_policy = "desired"
	entry_common.required_scene_kinds = list("living_common")
	entry_common.allowed_scene_kinds = list("living_common", "dining")
	program.add_room_contract(entry_common)

	var/datum/world_edit_building_v2_room_contract/sleeping = new("sleeping", "sleeping", "sleep_privacy", TRUE, 12, 36, 64, 3, 4, 8, 9)
	sleeping.privacy_class = "private"
	sleeping.exterior_window_policy = "desired"
	sleeping.window_policy = "desired"
	sleeping.required_scene_kinds = list("bedroom")
	sleeping.allowed_scene_kinds = list("bedroom")
	program.add_room_contract(sleeping)

	var/datum/world_edit_building_v2_room_contract/sanitation = new("sanitation", "sanitation", "sanitation", TRUE, 6, 16, 20, 2, 3, 5, 5)
	sanitation.privacy_class = "private"
	sanitation.exterior_window_policy = "forbidden"
	sanitation.window_policy = "forbidden"
	sanitation.required_scene_kinds = list("sanitation")
	sanitation.allowed_scene_kinds = list("sanitation")
	program.add_room_contract(sanitation)

	var/datum/world_edit_building_v2_room_contract/storage = new("storage", "storage", "storage_service", TRUE, 6, 20, 36, 3, 3, 8, 6)
	storage.privacy_class = "service"
	storage.exterior_window_policy = "forbidden"
	storage.window_policy = "forbidden"
	storage.required_scene_kinds = list("storage")
	storage.allowed_scene_kinds = list("storage")
	program.add_room_contract(storage)

	var/datum/world_edit_building_v2_room_contract/dining = new("dining", "dining", "common", FALSE, 9, 35, 42, 3, 3, 8, 7)
	dining.privacy_class = "public"
	dining.exterior_window_policy = "desired"
	dining.window_policy = "desired"
	dining.required_scene_kinds = list("dining")
	dining.allowed_scene_kinds = list("dining", "living_common")
	program.add_room_contract(dining)

	var/datum/world_edit_building_v2_room_contract/utility = new("utility", "utility", "storage_service", FALSE, 6, 24, 24, 2, 3, 6, 4)
	utility.privacy_class = "service"
	utility.exterior_window_policy = "forbidden"
	utility.window_policy = "forbidden"
	utility.required_scene_kinds = list("storage")
	utility.allowed_scene_kinds = list("storage")
	program.add_room_contract(utility)

	program.add_connection_contract(new /datum/world_edit_building_v2_connection_contract("entry_common", "sleeping", TRUE))
	program.add_connection_contract(new /datum/world_edit_building_v2_connection_contract("entry_common", "sanitation", TRUE))
	program.add_connection_contract(new /datum/world_edit_building_v2_connection_contract("entry_common", "storage", TRUE))
	program.add_connection_contract(new /datum/world_edit_building_v2_connection_contract("entry_common", "dining", FALSE))
	program.add_connection_contract(new /datum/world_edit_building_v2_connection_contract("storage", "utility", FALSE))

	program.global_scene_slot_limits = list(
		"public_focal" = 1,
		"dining_focal" = 1,
		"lounge_focal" = 1,
		"small_table_group" = 1,
		"sanitation_fixture" = 2,
		"storage_run" = 3,
	)
	program.global_scene_slot_minimums = list(
		"sleep_fixture" = 1,
		"sanitation_fixture" = 1,
		"storage_run" = 1,
	)
	add_living_scene_contracts_v2(program)
	return program

/datum/world_edit_generator/building_layout/proc/add_living_scene_contracts_v2(datum/world_edit_building_v2_program_contract/program)
	if(!istype(program))
		return
	var/datum/world_edit_building_v2_scene_contract/scene

	scene = new("common_dining_4", "dining")
	scene.allowed_programs = list("living")
	scene.allowed_room_roles = list("entry_common", "dining")
	scene.min_room_area = 16
	scene.primary_anchor_policy = "center"
	scene.negative_space_policy = "door_to_focus"
	scene.scene_slot_limits = list("dining_focal" = 1)
	program.add_scene_contract(scene)

	scene = new("common_dining_2", "dining")
	scene.allowed_programs = list("living")
	scene.allowed_room_roles = list("entry_common", "dining")
	scene.min_room_area = 9
	scene.primary_anchor_policy = "center"
	scene.negative_space_policy = "door_to_focus"
	scene.scene_slot_limits = list("dining_focal" = 1)
	program.add_scene_contract(scene)

	scene = new("common_lounge_pair", "living_common")
	scene.allowed_programs = list("living")
	scene.allowed_room_roles = list("entry_common")
	scene.min_room_area = 12
	scene.primary_anchor_policy = "center"
	scene.negative_space_policy = "door_to_focus"
	scene.scene_slot_limits = list("lounge_focal" = 1)
	program.add_scene_contract(scene)

	scene = new("common_entry_focus", "living_common")
	scene.allowed_programs = list("living")
	scene.allowed_room_roles = list("entry_common")
	scene.min_room_area = 6
	scene.primary_anchor_policy = "center"
	scene.negative_space_policy = "door_to_focus"
	scene.scene_slot_limits = list("side_surface" = 5)
	program.add_scene_contract(scene)

	scene = new("common_entry_side_surface", "living_common")
	scene.allowed_programs = list("living")
	scene.allowed_room_roles = list("entry_common")
	scene.min_room_area = 9
	scene.scene_layer = "secondary"
	scene.primary_anchor_policy = "longest_wall"
	scene.negative_space_policy = "door_to_focus"
	scene.scene_slot_limits = list("side_surface" = 1)
	program.add_scene_contract(scene)

	scene = new("bedroom_single_wall", "bedroom")
	scene.allowed_programs = list("living")
	scene.allowed_room_roles = list("sleeping")
	scene.min_room_area = 12
	scene.primary_anchor_policy = "far_wall"
	scene.negative_space_policy = "door_to_focus"
	scene.scene_slot_limits = list("sleep_fixture" = 1)
	program.add_scene_contract(scene)

	scene = new("bedroom_bed_cabinet", "bedroom")
	scene.allowed_programs = list("living")
	scene.allowed_room_roles = list("sleeping")
	scene.min_room_area = 16
	scene.primary_anchor_policy = "far_wall"
	scene.negative_space_policy = "door_to_focus"
	scene.scene_slot_limits = list("sleep_fixture" = 1, "bedroom_storage" = 1)
	program.add_scene_contract(scene)

	scene = new("sanitation_toilet_sink", "sanitation")
	scene.allowed_programs = list("living")
	scene.allowed_room_roles = list("sanitation")
	scene.min_room_area = 6
	scene.primary_anchor_policy = "service_wall"
	scene.negative_space_policy = "door_to_focus"
	scene.scene_slot_limits = list("sanitation_fixture" = 2)
	program.add_scene_contract(scene)

	scene = new("sanitation_toilet_only", "sanitation")
	scene.allowed_programs = list("living")
	scene.allowed_room_roles = list("sanitation")
	scene.min_room_area = 4
	scene.primary_anchor_policy = "service_wall"
	scene.negative_space_policy = "door_to_focus"
	scene.scene_slot_limits = list("sanitation_fixture" = 1)
	program.add_scene_contract(scene)

	scene = new("storage_cabinet_wall", "storage")
	scene.allowed_programs = list("living")
	scene.allowed_room_roles = list("storage", "utility")
	scene.min_room_area = 6
	scene.primary_anchor_policy = "longest_wall"
	scene.negative_space_policy = "door_to_focus"
	scene.scene_slot_limits = list("storage_run" = 2)
	program.add_scene_contract(scene)

	scene = new("storage_rack_wall", "storage")
	scene.allowed_programs = list("living")
	scene.allowed_room_roles = list("storage", "utility")
	scene.min_room_area = 8
	scene.primary_anchor_policy = "longest_wall"
	scene.negative_space_policy = "door_to_focus"
	scene.scene_slot_limits = list("storage_run" = 2)
	program.add_scene_contract(scene)

	scene = new("storage_crate_corner", "storage")
	scene.allowed_programs = list("living")
	scene.allowed_room_roles = list("storage", "utility")
	scene.min_room_area = 4
	scene.primary_anchor_policy = "longest_wall"
	scene.negative_space_policy = "door_to_focus"
	scene.scene_slot_limits = list("storage_run" = 2)
	program.add_scene_contract(scene)

/datum/world_edit_generator/building_layout/proc/get_building_layout_v2_pattern(pattern_id)
	switch("[pattern_id]")
		if("front_common_back_private")
			return new /datum/world_edit_building_v2_layout_pattern/front_common_back_private()
		if("central_spine_rooms")
			return new /datum/world_edit_building_v2_layout_pattern/central_spine_rooms()
		if("side_spine_room_row")
			return new /datum/world_edit_building_v2_layout_pattern/side_spine_room_row()
	return null

/datum/world_edit_generator/building_layout/proc/add_living_v2_route_connections(datum/world_edit_building_v2_region_candidate/region_candidate, include_dining = TRUE, include_utility = TRUE)
	if(!istype(region_candidate))
		return
	region_candidate.add_connection("common_to_route", "entry_common", "route", "public", TRUE)
	if(include_dining)
		region_candidate.add_connection("dining_to_route", "dining", "route", "public", FALSE)
	region_candidate.add_connection("sleep_to_route", "sleeping", "route", "private", TRUE)
	region_candidate.add_connection("sanitation_to_route", "sanitation", "route", "private", TRUE)
	region_candidate.add_connection("storage_to_route", "storage", "route", "service", TRUE)
	if(include_utility)
		region_candidate.add_connection("utility_to_route", "utility", "route", "service", FALSE)

/datum/world_edit_generator/building_layout/proc/add_living_v2_rear_utility_band(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_region_candidate/region_candidate, left_door_x, right_door_x, spine_x, start_y, bottom, right)
	if(!istype(context) || !istype(region_candidate))
		return FALSE
	var/band_top = max(round(text2num("[start_y]") || 0), round(text2num("[bottom]") || 0) - 3)
	if(band_top > bottom || bottom - band_top + 1 < 3)
		return FALSE
	var/left_room_right = left_door_x - 1
	if(left_room_right >= 4)
		region_candidate.add_influence_zone("rear_left_service", "service", 2, band_top, left_room_right, bottom, list("utility"), 10)
	var/right_room_left = right_door_x + 1
	var/right_room_right = min(right, right_door_x + 8)
	if(right_room_right - right_room_left + 1 >= 3)
		region_candidate.add_influence_zone("rear_right_service", "service", right_room_left, band_top, right_room_right, bottom, list("utility"), 10)
	return TRUE

/datum/world_edit_building_v2_layout_pattern/front_common_back_private
	id = "front_common_back_private"
	allowed_programs = list("living")
	min_width = 17
	min_height = 17
	max_width = 28
	max_height = 28

/datum/world_edit_building_v2_layout_pattern/front_common_back_private/build_region_candidates(datum/world_edit_building_v2_context/context)
	var/list/candidates = list()
	if(!can_solve(context))
		return candidates
	var/width = context.local_width()
	var/height = context.local_height()
	var/right = max(width - 1, 2)
	var/bottom = max(height - 1, 2)
	var/spine_x = clamp(round(width / 2), 8, min(12, right - 7))
	var/left_door_x = spine_x - 1
	var/right_door_x = spine_x + 1
	var/public_bottom = clamp(round(height * 0.40), 7, 8)
	var/private_top = public_bottom + 2
	var/sleep_bottom = min(bottom, private_top + 3)
	var/utility_top = sleep_bottom + 2
	var/utility_bottom = min(bottom, utility_top + 2)
	var/sanitation_bottom = min(bottom, private_top + 2)
	var/storage_top = sanitation_bottom + 2
	var/storage_bottom = min(bottom, storage_top + 3)
	var/left_room_right = min(left_door_x - 1, 10)
	var/right_room_left = right_door_x + 1
	var/right_room_right = min(right, right_room_left + 7)
	var/datum/world_edit_generator/building_layout/generator = context.generator
	var/datum/world_edit_building_v2_region_candidate/region_candidate = new(id, "living_entry_hub_service_core", 700)
	region_candidate.add_route_hint("main_spine", "line", spine_x, 2, spine_x, bottom, list("front_left_common", "front_right_common", "left_private", "right_private_service", "right_storage"))
	region_candidate.add_influence_zone("front_left_common", "public", 2, 2, left_room_right, public_bottom, list("entry_common"), 80)
	region_candidate.add_influence_zone("front_right_common", "public", right_room_left, 2, right_room_right, public_bottom, list("dining"), 60)
	region_candidate.add_influence_zone("left_private", "private", 2, private_top, left_room_right, sleep_bottom, list("sleeping"), 70)
	region_candidate.add_influence_zone("left_service", "service", 2, utility_top, left_room_right, utility_bottom, list("utility"), 20)
	region_candidate.add_influence_zone("right_private_service", "private_service", right_room_left, private_top, min(right_room_right, right_room_left + 3), sanitation_bottom, list("sanitation"), 70)
	region_candidate.add_influence_zone("right_storage", "service", right_room_left, storage_top, min(right_room_right, right_room_left + 5), storage_bottom, list("storage"), 70)
	generator.add_living_v2_route_connections(region_candidate, TRUE, TRUE)
	if(bottom - max(sleep_bottom, utility_bottom) >= 4)
		generator.add_living_v2_rear_utility_band(context, region_candidate, left_door_x, right_door_x, spine_x, max(sleep_bottom, utility_bottom) + 2, bottom, right)
	candidates += region_candidate
	return candidates

/datum/world_edit_building_v2_layout_pattern/central_spine_rooms
	id = "central_spine_rooms"
	allowed_programs = list("living")
	min_width = 13
	min_height = 13
	max_width = 28
	max_height = 28

/datum/world_edit_building_v2_layout_pattern/central_spine_rooms/build_region_candidates(datum/world_edit_building_v2_context/context)
	var/list/candidates = list()
	if(!can_solve(context))
		return candidates
	var/width = context.local_width()
	var/height = context.local_height()
	if(width < 17 || height < 17)
		return build_compact_central_spine_living_candidates(context)
	var/right = max(width - 1, 2)
	var/bottom = max(height - 1, 2)
	var/spine_x = clamp(round(width / 2) + 1, 8, min(12, right - 6))
	var/left_door_x = spine_x - 1
	var/right_door_x = spine_x + 1
	var/public_bottom = clamp(round(height * 0.42), 7, 8)
	var/private_top = public_bottom + 2
	var/sleep_bottom = min(bottom, private_top + 3)
	var/utility_top = sleep_bottom + 2
	var/utility_bottom = min(bottom, utility_top + 2)
	var/sanitation_bottom = min(bottom, private_top + 2)
	var/storage_top = sanitation_bottom + 2
	var/storage_bottom = min(bottom, storage_top + 3)
	var/left_room_right = min(left_door_x - 1, 10)
	var/right_room_left = right_door_x + 1
	var/right_room_right = min(right, right_room_left + 7)
	var/datum/world_edit_generator/building_layout/generator = context.generator
	var/datum/world_edit_building_v2_region_candidate/region_candidate = new(id, "living_central_spine_rooms", 420)
	region_candidate.add_route_hint("main_spine", "line", spine_x, 2, spine_x, bottom, list("front_left_common", "front_right_common", "left_private", "right_private_service", "right_storage"))
	region_candidate.add_influence_zone("front_left_common", "public", 2, 2, left_room_right, public_bottom, list("entry_common"), 60)
	region_candidate.add_influence_zone("left_private", "private", 2, private_top, left_room_right, sleep_bottom, list("sleeping"), 70)
	region_candidate.add_influence_zone("left_service", "service", 2, utility_top, left_room_right, utility_bottom, list("utility"), 20)
	region_candidate.add_influence_zone("front_right_common", "public", right_room_left, 2, right_room_right, public_bottom, list("dining"), 60)
	region_candidate.add_influence_zone("right_private_service", "private_service", right_room_left, private_top, min(right_room_right, right_room_left + 3), sanitation_bottom, list("sanitation"), 70)
	region_candidate.add_influence_zone("right_storage", "service", right_room_left, storage_top, min(right_room_right, right_room_left + 5), storage_bottom, list("storage"), 70)
	generator.add_living_v2_route_connections(region_candidate, TRUE, TRUE)
	if(bottom - max(sleep_bottom, utility_bottom) >= 4)
		generator.add_living_v2_rear_utility_band(context, region_candidate, left_door_x, right_door_x, spine_x, max(sleep_bottom, utility_bottom) + 2, bottom, right)
	candidates += region_candidate
	return candidates

/datum/world_edit_building_v2_layout_pattern/central_spine_rooms/proc/build_compact_central_spine_living_candidates(datum/world_edit_building_v2_context/context)
	var/list/candidates = list()
	var/width = context.local_width()
	var/height = context.local_height()
	var/right = max(width - 1, 2)
	var/bottom = max(height - 1, 2)
	var/spine_x = clamp(round(width * 0.60), 8, right - 4)
	var/left_door_x = spine_x - 1
	var/right_door_x = spine_x + 1
	var/public_bottom = 6
	var/private_top = public_bottom + 2
	var/service_bottom = min(private_top + 5, bottom)
	var/left_room_right = left_door_x - 1
	var/right_room_left = right_door_x + 1
	var/right_room_right = min(right, right_room_left + 3)
	var/datum/world_edit_generator/building_layout/generator = context.generator
	var/datum/world_edit_building_v2_region_candidate/region_candidate = new(id, "living_compact_central_spine_rooms", 300)
	region_candidate.add_route_hint("main_spine", "line", spine_x, 2, spine_x, bottom, list("front_left_common", "left_private", "right_front_service", "right_storage"))
	region_candidate.add_influence_zone("front_left_common", "public", 2, 2, left_room_right, public_bottom, list("entry_common"), 70)
	region_candidate.add_influence_zone("left_private", "private", 2, private_top, left_room_right, bottom, list("sleeping"), 70)
	region_candidate.add_influence_zone("right_front_service", "private_service", right_room_left, 2, right_room_right, 4, list("sanitation"), 70)
	region_candidate.add_influence_zone("right_storage", "service", right_room_left, private_top, right_room_right, service_bottom, list("storage"), 70)
	generator.add_living_v2_route_connections(region_candidate, FALSE, FALSE)
	candidates += region_candidate
	return candidates

/datum/world_edit_building_v2_layout_pattern/side_spine_room_row
	id = "side_spine_room_row"
	allowed_programs = list("living")
	min_width = 18
	min_height = 15
	max_width = 32
	max_height = 32

/datum/world_edit_building_v2_layout_pattern/side_spine_room_row/build_region_candidates(datum/world_edit_building_v2_context/context)
	var/list/candidates = list()
	if(!can_solve(context))
		return candidates
	var/width = context.local_width()
	var/height = context.local_height()
	var/right = max(width - 1, 2)
	var/bottom = max(height - 1, 2)
	var/spine_y = clamp(round(height * 0.48), 8, bottom - 6)
	var/top_room_bottom = spine_y - 2
	var/bottom_room_top = spine_y + 2
	if(top_room_bottom < 6 || bottom_room_top > bottom - 3)
		return candidates
	var/datum/world_edit_generator/building_layout/generator = context.generator
	var/datum/world_edit_building_v2_region_candidate/region_candidate = new(id, "living_side_spine_room_row", 520)
	region_candidate.add_route_hint("side_spine", "line", 4, spine_y, right, spine_y, list("upper_entry_common", "upper_dining", "lower_sleeping", "lower_sanitation", "lower_storage"))
	region_candidate.add_route_hint("exit_spine", "line", right, 2, right, spine_y, list("upper_utility"))
	region_candidate.add_influence_zone("upper_entry_common", "public", 2, 2, min(8, right), top_room_bottom, list("entry_common"), 70)
	region_candidate.add_influence_zone("upper_dining", "public", 9, 2, min(13, right), top_room_bottom, list("dining"), 50)
	if(right >= 18)
		region_candidate.add_influence_zone("upper_utility", "service", 14, 2, right - 2, top_room_bottom, list("utility"), 20)
	region_candidate.add_influence_zone("lower_sleeping", "private", 2, bottom_room_top, min(7, right), min(bottom, bottom_room_top + 5), list("sleeping"), 70)
	region_candidate.add_influence_zone("lower_sanitation", "private_service", 10, bottom_room_top, min(13, right), min(bottom, bottom_room_top + 3), list("sanitation"), 70)
	if(right >= 20)
		region_candidate.add_influence_zone("lower_storage", "service", 15, bottom_room_top, min(20, right - 2), bottom, list("storage"), 70)
		region_candidate.add_influence_zone("lower_service_tail", "service", 18, bottom_room_top, right - 2, bottom, list("utility"), 20)
	else if(right >= 19)
		region_candidate.add_influence_zone("lower_storage", "service", 14, bottom_room_top, 16, bottom, list("storage"), 70)
		region_candidate.add_influence_zone("exit_service_room", "service", 17, bottom_room_top, right, min(bottom, bottom_room_top + 5), list("utility"), 20)
	else
		region_candidate.add_influence_zone("lower_storage", "service", 15, bottom_room_top, right - 2, bottom, list("storage"), 70)
	if(bottom - bottom_room_top >= 7)
		region_candidate.add_influence_zone("rear_service_room", "service", 4, bottom_room_top + 6, min(8, right), bottom, list("utility"), 20)
	if(right >= 19 && bottom - bottom_room_top >= 8)
		region_candidate.add_influence_zone("side_service_room", "service", 13, bottom_room_top + 8, right - 2, bottom, list("utility"), 20)
	generator.add_living_v2_route_connections(region_candidate, TRUE, TRUE)
	candidates += region_candidate
	return candidates
