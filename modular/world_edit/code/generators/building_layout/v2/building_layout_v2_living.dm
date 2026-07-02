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

	var/datum/world_edit_building_v2_room_contract/storage = new("storage", "storage", "storage_service", TRUE, 6, 12, 24, 2, 3, 6, 6)
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

	program.global_scene_slot_limits = list("public_focal" = 1)
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

	scene = new("common_entry_side_surface", "living_common")
	scene.allowed_programs = list("living")
	scene.allowed_room_roles = list("entry_common")
	scene.min_room_area = 9
	scene.scene_layer = "secondary"
	scene.scene_slot_limits = list("side_surface" = 1)
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
		if("side_spine_room_row")
			return new /datum/world_edit_building_v2_layout_pattern/side_spine_room_row()
	return null

/datum/world_edit_generator/building_layout/proc/add_living_v2_rear_utility_band(datum/world_edit_building_v2_context/context, datum/world_edit_building_v2_layout_candidate/candidate, left_door_x, right_door_x, spine_x, start_y, bottom, right)
	if(!istype(context) || !istype(candidate))
		return FALSE
	var/band_top = max(round(text2num("[start_y]") || 0), round(text2num("[bottom]") || 0) - 3)
	if(band_top > bottom || bottom - band_top + 1 < 3)
		return FALSE
	var/left_room_right = left_door_x - 1
	if(left_room_right >= 4)
		add_building_v2_room_allocation_slot(context, candidate, "utility_rear_left", "utility", "utility", "storage_service", "rear_left_service", 2, band_top, left_room_right, bottom, "max", "max")
	var/right_room_left = right_door_x + 1
	var/right_room_right = min(right, right_door_x + 8)
	if(right_room_right - right_room_left + 1 >= 3)
		add_building_v2_room_allocation_slot(context, candidate, "utility_rear_right", "utility", "utility", "storage_service", "rear_right_service", right_room_left, band_top, right_room_right, bottom, "min", "max")
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
	var/datum/world_edit_building_v2_layout_candidate/candidate = new
	candidate.id = "living_entry_hub_service_core"
	candidate.pattern_id = id
	candidate.score = 700
	generator.add_building_v2_route_rect(context, candidate, spine_x, 2, spine_x, bottom)
	generator.add_building_v2_room_allocation_slot(context, candidate, "entry_common", "entry_common", "entry_common", "common", "front_left_common", 2, 2, left_room_right, public_bottom, "max", "min")
	generator.add_building_v2_room_allocation_slot(context, candidate, "dining", "dining", "dining", "common", "front_right_common", right_room_left, 2, right_room_right, public_bottom, "min", "min")
	generator.add_building_v2_room_allocation_slot(context, candidate, "sleeping", "sleeping", "sleeping", "sleep_privacy", "left_private", 2, private_top, left_room_right, sleep_bottom, "max", "min")
	generator.add_building_v2_room_allocation_slot(context, candidate, "utility", "utility", "utility", "storage_service", "left_service", 2, utility_top, left_room_right, utility_bottom, "max", "min")
	generator.add_building_v2_room_allocation_slot(context, candidate, "sanitation", "sanitation", "sanitation", "sanitation", "right_private_service", right_room_left, private_top, min(right_room_right, right_room_left + 3), sanitation_bottom, "min", "min")
	generator.add_building_v2_room_allocation_slot(context, candidate, "storage", "storage", "storage", "storage_service", "right_storage", right_room_left, storage_top, min(right_room_right, right_room_left + 5), storage_bottom, "min", "min")
	if(bottom - max(sleep_bottom, utility_bottom) >= 4)
		generator.add_living_v2_rear_utility_band(context, candidate, left_door_x, right_door_x, spine_x, max(sleep_bottom, utility_bottom) + 2, bottom, right)
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
	var/datum/world_edit_building_v2_layout_candidate/candidate = new
	candidate.id = "living_central_spine_rooms"
	candidate.pattern_id = id
	candidate.score = 420
	generator.add_building_v2_route_rect(context, candidate, spine_x, 2, spine_x, bottom)
	generator.add_building_v2_room_allocation_slot(context, candidate, "entry_common", "entry_common", "entry_common", "common", "front_left_common", 2, 2, left_room_right, public_bottom, "max", "min")
	generator.add_building_v2_room_allocation_slot(context, candidate, "sleeping", "sleeping", "sleeping", "sleep_privacy", "left_private", 2, private_top, left_room_right, sleep_bottom, "max", "min")
	generator.add_building_v2_room_allocation_slot(context, candidate, "utility", "utility", "utility", "storage_service", "left_service", 2, utility_top, left_room_right, utility_bottom, "max", "min")
	generator.add_building_v2_room_allocation_slot(context, candidate, "dining", "dining", "dining", "common", "front_right_common", right_room_left, 2, right_room_right, public_bottom, "min", "min")
	generator.add_building_v2_room_allocation_slot(context, candidate, "sanitation", "sanitation", "sanitation", "sanitation", "right_private_service", right_room_left, private_top, min(right_room_right, right_room_left + 3), sanitation_bottom, "min", "min")
	generator.add_building_v2_room_allocation_slot(context, candidate, "storage", "storage", "storage", "storage_service", "right_storage", right_room_left, storage_top, min(right_room_right, right_room_left + 5), storage_bottom, "min", "min")
	if(bottom - max(sleep_bottom, utility_bottom) >= 4)
		generator.add_living_v2_rear_utility_band(context, candidate, left_door_x, right_door_x, spine_x, max(sleep_bottom, utility_bottom) + 2, bottom, right)
	candidates += candidate
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
	var/datum/world_edit_building_v2_layout_candidate/candidate = new
	candidate.id = "living_compact_central_spine_rooms"
	candidate.pattern_id = id
	candidate.score = 300
	generator.add_building_v2_route_rect(context, candidate, spine_x, 2, spine_x, bottom)
	generator.add_building_v2_room_allocation_slot(context, candidate, "entry_common", "entry_common", "entry_common", "common", "front_left_common", 2, 2, left_room_right, public_bottom, "max", "min")
	generator.add_building_v2_room_allocation_slot(context, candidate, "sleeping", "sleeping", "sleeping", "sleep_privacy", "left_private", 2, private_top, left_room_right, bottom, "max", "min")
	generator.add_building_v2_room_allocation_slot(context, candidate, "sanitation", "sanitation", "sanitation", "sanitation", "right_front_service", right_room_left, 2, right_room_right, 4, "min", "min")
	generator.add_building_v2_room_allocation_slot(context, candidate, "storage", "storage", "storage", "storage_service", "right_storage", right_room_left, private_top, right_room_right, service_bottom, "min", "min")
	candidates += candidate
	return candidates

/datum/world_edit_building_v2_layout_pattern/side_spine_room_row
	id = "side_spine_room_row"
	allowed_programs = list("living")
	min_width = 18
	min_height = 15
	max_width = 32
	max_height = 32

/datum/world_edit_building_v2_layout_pattern/side_spine_room_row/build_candidates(datum/world_edit_building_v2_context/context)
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
	var/datum/world_edit_building_v2_layout_candidate/candidate = new
	candidate.id = "living_side_spine_room_row"
	candidate.pattern_id = id
	candidate.score = 520
	generator.add_building_v2_route_rect(context, candidate, 4, spine_y, right, spine_y)
	generator.add_building_v2_route_rect(context, candidate, right, 2, right, spine_y)
	generator.add_building_v2_route_rect(context, candidate, 9, spine_y, 9, max(spine_y, bottom - 1))
	if(right >= 19 && bottom - bottom_room_top >= 7)
		generator.add_building_v2_route_rect(context, candidate, 9, bottom_room_top + 6, right - 2, bottom_room_top + 6)
	generator.add_building_v2_room_allocation_slot(context, candidate, "entry_common", "entry_common", "entry_common", "common", "upper_entry_common", 2, 2, min(8, right), top_room_bottom, "min", "max")
	generator.add_building_v2_room_allocation_slot(context, candidate, "dining", "dining", "dining", "common", "upper_dining", 9, 2, min(13, right), top_room_bottom, "min", "max")
	if(right >= 18)
		generator.add_building_v2_room_allocation_slot(context, candidate, "utility", "utility", "utility", "storage_service", "upper_utility", 14, 2, right - 2, top_room_bottom, "max", "max")
	generator.add_building_v2_room_allocation_slot(context, candidate, "sleeping", "sleeping", "sleeping", "sleep_privacy", "lower_sleeping", 2, bottom_room_top, min(7, right), min(bottom, bottom_room_top + 5), "min", "min")
	generator.add_building_v2_room_allocation_slot(context, candidate, "sanitation", "sanitation", "sanitation", "sanitation", "lower_sanitation", 10, bottom_room_top, min(13, right), min(bottom, bottom_room_top + 3), "min", "min")
	if(right >= 20)
		generator.add_building_v2_room_allocation_slot(context, candidate, "storage", "storage", "storage", "storage_service", "lower_storage", 15, bottom_room_top, 16, bottom, "min", "min")
		generator.add_building_v2_room_allocation_slot(context, candidate, "utility_lower", "utility", "utility", "storage_service", "lower_service_tail", 18, bottom_room_top, right - 2, bottom, "max", "max")
	else if(right >= 19)
		generator.add_building_v2_room_allocation_slot(context, candidate, "storage", "storage", "storage", "storage_service", "lower_storage", 14, bottom_room_top, 16, bottom, "min", "min")
		generator.add_building_v2_room_allocation_slot(context, candidate, "utility_exit", "utility", "utility", "storage_service", "exit_service_room", 17, bottom_room_top, right, min(bottom, bottom_room_top + 5), "max", "min")
	else
		generator.add_building_v2_room_allocation_slot(context, candidate, "storage", "storage", "storage", "storage_service", "lower_storage", 15, bottom_room_top, right - 2, bottom, "min", "min")
	if(bottom - bottom_room_top >= 7)
		generator.add_building_v2_room_allocation_slot(context, candidate, "utility_rear", "utility", "utility", "storage_service", "rear_service_room", 4, bottom_room_top + 6, min(8, right), bottom, "min", "max")
	if(right >= 19 && bottom - bottom_room_top >= 8)
		generator.add_building_v2_room_allocation_slot(context, candidate, "utility_side", "utility", "utility", "storage_service", "side_service_room", 13, bottom_room_top + 8, right - 2, bottom, "max", "max")
	candidates += candidate
	return candidates
