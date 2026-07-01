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
	)

	var/datum/world_edit_building_v2_room_contract/entry_common = new("entry_common", "entry_common", "common", TRUE, 25, 40, 72, 5, 5, 12, 7)
	entry_common.privacy_class = "public"
	entry_common.required_scene_kinds = list("living_common")
	entry_common.allowed_scene_kinds = list("living_common", "dining")
	program.add_room_contract(entry_common)

	var/datum/world_edit_building_v2_room_contract/sleeping = new("sleeping", "sleeping", "sleep_privacy", TRUE, 12, 24, 64, 3, 4, 8, 9)
	sleeping.privacy_class = "private"
	sleeping.required_scene_kinds = list("bedroom")
	sleeping.allowed_scene_kinds = list("bedroom")
	program.add_room_contract(sleeping)

	var/datum/world_edit_building_v2_room_contract/sanitation = new("sanitation", "sanitation", "sanitation", TRUE, 6, 9, 18, 2, 3, 4, 5)
	sanitation.privacy_class = "private"
	sanitation.exterior_window_policy = "forbidden"
	sanitation.required_scene_kinds = list("sanitation")
	sanitation.allowed_scene_kinds = list("sanitation")
	program.add_room_contract(sanitation)

	var/datum/world_edit_building_v2_room_contract/storage = new("storage", "storage", "storage_service", TRUE, 6, 12, 24, 2, 3, 5, 6)
	storage.privacy_class = "service"
	storage.exterior_window_policy = "forbidden"
	storage.required_scene_kinds = list("storage")
	storage.allowed_scene_kinds = list("storage")
	program.add_room_contract(storage)

	var/datum/world_edit_building_v2_room_contract/dining = new("dining", "dining", "common", FALSE, 9, 16, 42, 3, 3, 7, 6)
	dining.privacy_class = "public"
	dining.required_scene_kinds = list("dining")
	dining.allowed_scene_kinds = list("dining", "living_common")
	program.add_room_contract(dining)

	var/datum/world_edit_building_v2_room_contract/utility = new("utility", "utility", "storage_service", FALSE, 6, 9, 32, 2, 3, 8, 4)
	utility.privacy_class = "service"
	utility.exterior_window_policy = "forbidden"
	utility.required_scene_kinds = list("storage")
	utility.allowed_scene_kinds = list("storage")
	program.add_room_contract(utility)

	program.add_connection_contract(new /datum/world_edit_building_v2_connection_contract("entry_common", "sleeping", TRUE))
	program.add_connection_contract(new /datum/world_edit_building_v2_connection_contract("entry_common", "sanitation", TRUE))
	program.add_connection_contract(new /datum/world_edit_building_v2_connection_contract("entry_common", "storage", TRUE))
	program.add_connection_contract(new /datum/world_edit_building_v2_connection_contract("entry_common", "dining", FALSE))
	program.add_connection_contract(new /datum/world_edit_building_v2_connection_contract("storage", "utility", FALSE))

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
	scene.scene_slot_limits = list("dining_focal" = 1)
	program.add_scene_contract(scene)

	scene = new("common_dining_2", "dining")
	scene.allowed_programs = list("living")
	scene.allowed_room_roles = list("entry_common", "dining")
	scene.min_room_area = 9
	scene.scene_slot_limits = list("dining_focal" = 1)
	program.add_scene_contract(scene)

	scene = new("common_lounge_pair", "living_common")
	scene.allowed_programs = list("living")
	scene.allowed_room_roles = list("entry_common")
	scene.min_room_area = 12
	scene.scene_slot_limits = list("lounge_focal" = 1)
	program.add_scene_contract(scene)

	scene = new("bedroom_single_wall", "bedroom")
	scene.allowed_programs = list("living")
	scene.allowed_room_roles = list("sleeping")
	scene.min_room_area = 12
	scene.scene_slot_limits = list("sleep_fixture" = 1)
	program.add_scene_contract(scene)

	scene = new("bedroom_bed_cabinet", "bedroom")
	scene.allowed_programs = list("living")
	scene.allowed_room_roles = list("sleeping")
	scene.min_room_area = 16
	scene.scene_slot_limits = list("sleep_fixture" = 1, "bedroom_storage" = 1)
	program.add_scene_contract(scene)

	scene = new("sanitation_toilet_sink", "sanitation")
	scene.allowed_programs = list("living")
	scene.allowed_room_roles = list("sanitation")
	scene.min_room_area = 6
	scene.scene_slot_limits = list("sanitation_fixture" = 2)
	program.add_scene_contract(scene)

	scene = new("sanitation_toilet_only", "sanitation")
	scene.allowed_programs = list("living")
	scene.allowed_room_roles = list("sanitation")
	scene.min_room_area = 4
	scene.scene_slot_limits = list("sanitation_fixture" = 1)
	program.add_scene_contract(scene)

	scene = new("storage_cabinet_wall", "storage")
	scene.allowed_programs = list("living")
	scene.allowed_room_roles = list("storage", "utility")
	scene.min_room_area = 6
	scene.scene_slot_limits = list("storage_run" = 2)
	program.add_scene_contract(scene)

	scene = new("storage_rack_wall", "storage")
	scene.allowed_programs = list("living")
	scene.allowed_room_roles = list("storage", "utility")
	scene.min_room_area = 8
	scene.scene_slot_limits = list("storage_run" = 2)
	program.add_scene_contract(scene)

	scene = new("storage_crate_corner", "storage")
	scene.allowed_programs = list("living")
	scene.allowed_room_roles = list("storage", "utility")
	scene.min_room_area = 4
	scene.scene_slot_limits = list("storage_corner" = 2)
	program.add_scene_contract(scene)

/datum/world_edit_generator/building_layout/proc/get_building_layout_v2_pattern(pattern_id)
	switch("[pattern_id]")
		if("front_common_back_private")
			return new /datum/world_edit_building_v2_layout_pattern/front_common_back_private()
		if("central_spine_rooms")
			return new /datum/world_edit_building_v2_layout_pattern/central_spine_rooms()
	return null

/datum/world_edit_generator/building_layout/proc/add_living_v2_rear_utility_band(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, left_door_x, right_door_x, spine_x, start_y, bottom, right)
	if(!istype(context) || !istype(candidate))
		return FALSE
	var/band_top = max(round(text2num("[start_y]") || 0), round(text2num("[bottom]") || 0) - 3)
	if(band_top > bottom || bottom - band_top + 1 < 3)
		return FALSE
	var/band_mid_y = clamp(round((band_top + bottom) / 2), band_top, bottom)
	var/left_room_right = left_door_x - 1
	if(left_room_right >= 4)
		add_building_v2_room_rect(context, candidate, "utility_rear_left", "utility", "utility", "storage_service", 2, band_top, left_room_right, bottom)
		add_building_v2_door(context, candidate, "rear_left_utility_to_spine", "door", left_door_x, band_mid_y, WEST, "utility_rear_left", "route")
	var/right_room_left = right_door_x + 1
	var/right_room_right = min(right, right_door_x + 8)
	if(right_room_right - right_room_left + 1 >= 3)
		add_building_v2_room_rect(context, candidate, "utility_rear_right", "utility", "utility", "storage_service", right_room_left, band_top, right_room_right, bottom)
		add_building_v2_door(context, candidate, "rear_right_utility_to_spine", "door", right_door_x, band_mid_y, EAST, "utility_rear_right", "route")
	return TRUE

/datum/world_edit_building_v2_layout_pattern/front_common_back_private
	id = "front_common_back_private"
	allowed_programs = list("living")
	min_width = 17
	min_height = 17
	max_width = 28
	max_height = 28

/datum/world_edit_building_v2_layout_pattern/front_common_back_private/build_candidates(datum/world_edit_building_v2_context/context)
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
	var/public_bottom = clamp(round(height * 0.36), 6, 8)
	var/public_height = public_bottom - 1
	var/private_top = public_bottom + 2
	var/service_bottom = min(private_top + 3, bottom - 3)
	var/utility_top = service_bottom + 2
	var/utility_bottom = min(bottom, utility_top + 3)
	var/sleep_bottom = min(bottom, private_top + 8)
	var/sleep_right = min(left_door_x - 1, 9)
	var/service_wall_x = min(right - 2, right_door_x + 4)
	var/storage_right = min(right, service_wall_x + 5)
	var/dining_width = clamp(round(42 / max(public_height, 1)), 3, 7)
	var/dining_right = min(right, right_door_x + dining_width)
	var/datum/world_edit_generator/building_layout/generator = context.generator
	var/datum/world_edit_building_v2_layout_candidate/candidate = new
	candidate.id = "living_entry_hub_service_core"
	candidate.pattern_id = id
	candidate.score = 700
	generator.add_building_v2_route_rect(context, candidate, spine_x, 2, spine_x, bottom)
	generator.add_building_v2_route_rect(context, candidate, left_door_x, 2, right_door_x, 4)
	generator.add_building_v2_room_rect(context, candidate, "entry_common", "entry_common", "entry_common", "common", 2, 2, left_door_x - 1, public_bottom)
	generator.add_building_v2_room_rect(context, candidate, "dining", "dining", "dining", "common", right_door_x + 1, 2, dining_right, public_bottom)
	generator.add_building_v2_room_rect(context, candidate, "sleeping", "sleeping", "sleeping", "sleep_privacy", 2, private_top, sleep_right, sleep_bottom)
	generator.add_building_v2_room_rect(context, candidate, "sanitation", "sanitation", "sanitation", "sanitation", right_door_x + 1, private_top, service_wall_x - 1, service_bottom)
	generator.add_building_v2_room_rect(context, candidate, "storage", "storage", "storage", "storage_service", service_wall_x + 1, private_top, storage_right, service_bottom)
	generator.add_building_v2_room_rect(context, candidate, "utility", "utility", "utility", "storage_service", right_door_x + 1, utility_top, min(right, right_door_x + 8), utility_bottom)
	if(bottom - max(sleep_bottom, utility_bottom) >= 4)
		generator.add_living_v2_rear_utility_band(context, candidate, left_door_x, right_door_x, spine_x, max(sleep_bottom, utility_bottom) + 2, bottom, right)
	generator.add_building_v2_door(context, candidate, "front_entry", "main_exit", spine_x, 1, NORTH, "", "route")
	generator.add_building_v2_door(context, candidate, "common_to_entry_hub", "door", left_door_x, clamp(round((2 + public_bottom) / 2), 3, public_bottom), WEST, "entry_common", "route")
	generator.add_building_v2_door(context, candidate, "dining_to_entry_hub", "door", right_door_x, clamp(round((2 + public_bottom) / 2), 3, public_bottom), EAST, "dining", "route")
	generator.add_building_v2_door(context, candidate, "sleep_to_spine", "door", left_door_x, clamp(round((private_top + sleep_bottom) / 2), private_top + 1, sleep_bottom - 1), WEST, "sleeping", "route")
	generator.add_building_v2_door(context, candidate, "sanitation_to_spine", "door", right_door_x, clamp(private_top + 1, private_top, service_bottom), EAST, "sanitation", "route")
	generator.add_building_v2_door(context, candidate, "storage_to_spine", "door", service_wall_x, clamp(private_top + 1, private_top, service_bottom), EAST, "storage", "route")
	generator.add_building_v2_door(context, candidate, "utility_to_spine", "door", right_door_x, clamp(utility_top + 1, utility_top, utility_bottom), EAST, "utility", "route")
	generator.add_building_v2_window(context, candidate, "common_window_left", 3, 1, NORTH, "entry_common")
	generator.add_building_v2_window(context, candidate, "common_window_right", max(4, left_door_x - 2), 1, NORTH, "entry_common")
	generator.add_building_v2_window(context, candidate, "dining_window", clamp(round((right_door_x + 1 + dining_right) / 2), right_door_x + 2, dining_right - 1), 1, NORTH, "dining")
	candidates += candidate
	return candidates

/datum/world_edit_building_v2_layout_pattern/central_spine_rooms
	id = "central_spine_rooms"
	allowed_programs = list("living")
	min_width = 13
	min_height = 13
	max_width = 28
	max_height = 28

/datum/world_edit_building_v2_layout_pattern/central_spine_rooms/build_candidates(datum/world_edit_building_v2_context/context)
	var/list/candidates = list()
	if(!can_solve(context))
		return candidates
	var/width = context.local_width()
	var/height = context.local_height()
	if(width < 17 || height < 17)
		return build_compact_central_spine_living_candidates(context)
	var/right = max(width - 1, 2)
	var/bottom = max(height - 1, 2)
	var/spine_x = clamp(round(width / 2), 8, min(12, right - 7))
	var/left_door_x = spine_x - 1
	var/right_door_x = spine_x + 1
	var/public_bottom = clamp(round(height * 0.40), 6, 8)
	var/public_height = public_bottom - 1
	var/private_top = public_bottom + 2
	var/service_bottom = min(private_top + 3, bottom - 3)
	var/utility_top = service_bottom + 2
	var/utility_bottom = min(bottom, utility_top + 3)
	var/sleep_bottom = min(bottom, private_top + 8)
	var/left_room_right = min(left_door_x - 1, 9)
	var/service_wall_x = min(right - 2, right_door_x + 4)
	var/storage_right = min(right, service_wall_x + 5)
	var/dining_width = clamp(round(42 / max(public_height, 1)), 3, 7)
	var/dining_right = min(right, right_door_x + dining_width)
	var/datum/world_edit_generator/building_layout/generator = context.generator
	var/datum/world_edit_building_v2_layout_candidate/candidate = new
	candidate.id = "living_central_spine_rooms"
	candidate.pattern_id = id
	candidate.score = 420
	generator.add_building_v2_route_rect(context, candidate, spine_x, 2, spine_x, bottom)
	generator.add_building_v2_room_rect(context, candidate, "entry_common", "entry_common", "entry_common", "common", 2, 2, left_room_right, public_bottom)
	generator.add_building_v2_room_rect(context, candidate, "sleeping", "sleeping", "sleeping", "sleep_privacy", 2, private_top, left_room_right, sleep_bottom)
	generator.add_building_v2_room_rect(context, candidate, "dining", "dining", "dining", "common", right_door_x + 1, 2, dining_right, public_bottom)
	generator.add_building_v2_room_rect(context, candidate, "sanitation", "sanitation", "sanitation", "sanitation", right_door_x + 1, private_top, service_wall_x - 1, service_bottom)
	generator.add_building_v2_room_rect(context, candidate, "storage", "storage", "storage", "storage_service", service_wall_x + 1, private_top, storage_right, service_bottom)
	generator.add_building_v2_room_rect(context, candidate, "utility", "utility", "utility", "storage_service", right_door_x + 1, utility_top, min(right, right_door_x + 8), utility_bottom)
	if(bottom - max(sleep_bottom, utility_bottom) >= 4)
		generator.add_living_v2_rear_utility_band(context, candidate, left_door_x, right_door_x, spine_x, max(sleep_bottom, utility_bottom) + 2, bottom, right)
	generator.add_building_v2_door(context, candidate, "front_entry", "main_exit", spine_x, 1, NORTH, "", "route")
	generator.add_building_v2_door(context, candidate, "common_to_spine", "door", left_door_x, clamp(round((2 + public_bottom) / 2), 3, public_bottom), WEST, "entry_common", "route")
	generator.add_building_v2_door(context, candidate, "sleep_to_spine", "door", left_door_x, clamp(round((private_top + sleep_bottom) / 2), private_top + 1, sleep_bottom - 1), WEST, "sleeping", "route")
	generator.add_building_v2_door(context, candidate, "dining_to_spine", "door", right_door_x, clamp(round((2 + public_bottom) / 2), 3, public_bottom), EAST, "dining", "route")
	generator.add_building_v2_door(context, candidate, "sanitation_to_spine", "door", right_door_x, clamp(private_top + 1, private_top, service_bottom), EAST, "sanitation", "route")
	generator.add_building_v2_door(context, candidate, "storage_to_spine", "door", service_wall_x, clamp(private_top + 1, private_top, service_bottom), EAST, "storage", "route")
	generator.add_building_v2_door(context, candidate, "utility_to_spine", "door", right_door_x, clamp(utility_top + 1, utility_top, utility_bottom), EAST, "utility", "route")
	generator.add_building_v2_window(context, candidate, "common_window", clamp(round((2 + left_room_right) / 2), 3, left_room_right - 1), 1, NORTH, "entry_common")
	generator.add_building_v2_window(context, candidate, "dining_window", clamp(round((right_door_x + 1 + dining_right) / 2), right_door_x + 2, dining_right - 1), 1, NORTH, "dining")
	candidates += candidate
	return candidates

/datum/world_edit_building_v2_layout_pattern/central_spine_rooms/proc/build_compact_central_spine_living_candidates(datum/world_edit_building_v2_context/context)
	var/list/candidates = list()
	var/width = context.local_width()
	var/height = context.local_height()
	var/right = max(width - 1, 2)
	var/bottom = max(height - 1, 2)
	var/spine_x = clamp(round(width / 2), 7, right - 5)
	var/public_bottom = 6
	var/private_top = public_bottom + 2
	var/service_bottom = min(private_top + 2, bottom)
	var/right_room_right = min(right, spine_x + 3)
	var/datum/world_edit_generator/building_layout/generator = context.generator
	var/datum/world_edit_building_v2_layout_candidate/candidate = new
	candidate.id = "living_compact_central_spine_rooms"
	candidate.pattern_id = id
	candidate.score = 300
	generator.add_building_v2_route_rect(context, candidate, spine_x, 2, spine_x, bottom)
	generator.add_building_v2_room_rect(context, candidate, "entry_common", "entry_common", "entry_common", "common", 2, 2, spine_x - 1, public_bottom)
	generator.add_building_v2_room_rect(context, candidate, "sleeping", "sleeping", "sleeping", "sleep_privacy", 2, private_top, spine_x - 1, bottom)
	generator.add_building_v2_room_rect(context, candidate, "sanitation", "sanitation", "sanitation", "sanitation", spine_x + 1, 2, right_room_right, 4)
	generator.add_building_v2_room_rect(context, candidate, "storage", "storage", "storage", "storage_service", spine_x + 1, private_top, right_room_right, service_bottom)
	generator.add_building_v2_door(context, candidate, "front_entry", "main_exit", spine_x, 1, NORTH, "", "route")
	generator.add_building_v2_door(context, candidate, "common_to_spine", "door", spine_x, clamp(round((2 + public_bottom) / 2), 3, public_bottom), EAST, "entry_common", "route")
	generator.add_building_v2_door(context, candidate, "sleep_to_spine", "door", spine_x, clamp(round((private_top + bottom) / 2), private_top, bottom), EAST, "sleeping", "route")
	generator.add_building_v2_door(context, candidate, "sanitation_to_spine", "door", spine_x, 3, WEST, "sanitation", "route")
	generator.add_building_v2_door(context, candidate, "storage_to_spine", "door", spine_x, clamp(private_top + 1, private_top, service_bottom), WEST, "storage", "route")
	generator.add_building_v2_window(context, candidate, "common_window", clamp(round((2 + spine_x - 1) / 2), 3, spine_x - 2), 1, NORTH, "entry_common")
	candidates += candidate
	return candidates
