/datum/world_edit_generation_stage/geometry
	id = "geometry"

/datum/world_edit_generation_stage/geometry/execute(datum/world_edit_generation_context/context)
	var/datum/world_edit_generator/building_layout/generator = context.generator
	generator.build_building_doors(context.state)
	if(context.has_errors())
		context.state.add_stage_report("doors", "failed", generator.format_building_messages(context.state.validation.errors))
		return FALSE
	context.state.geometry.actual_entry_direction = context.state.geometry.door_dirs[context.state.geometry.front_door_turf] || context.state.placement_dir
	if(context.state.geometry.actual_entry_direction == context.state.geometry.requested_direction)
		context.state.validation.direction_honored_count = 1
	else
		context.state.validation.direction_fallback_count = 1
		context.state.geometry.direction_fallback_reason = "Selected footprint could not emit entry on requested direction."
	context.state.add_stage_report("doors", "ok", null, list("door_count" = length(context.state.geometry.door_turfs)))

	if(context.state.config["room_first_layout"])
		if(!generator.build_building_room_first_layout(context.state))
			if(!context.has_errors())
				context.state.add_error("Selected building footprint cannot be decomposed into connected rooms and an entry corridor.")
			context.state.add_stage_report("room_packing", "failed", generator.format_building_messages(context.state.validation.errors))
			return FALSE
	context.state.geometry.room_graph_hash = generator.build_building_turf_lookup_hash(context.state.geometry.room_by_turf)
	context.state.geometry.route_hash = generator.build_building_turf_list_hash(context.state.geometry.primary_route_turfs)
	context.state.add_stage_report("room_packing", "ok", null, list(
		"room_count" = length(context.state.geometry.solved_rooms),
		"zone_count" = length(context.state.geometry.zone_turfs),
		"room_graph_hash" = context.state.geometry.room_graph_hash,
	))
	context.state.add_stage_report("corridor", "ok", null, list(
		"reserved_walk_count" = length(context.state.geometry.primary_route_turfs),
		"route_hash" = context.state.geometry.route_hash,
	))
	generator.build_building_windows(context.state)
	
	if(context.state.config["room_first_layout"])
		generator.build_building_walls_and_floors(context.state)
		context.state.geometry.wall_hash = generator.build_building_turf_lookup_hash(context.state.geometry.wall_lookup)
	context.state.validation.wall_report = list(
		"wall_count" = length(context.state.geometry.wall_lookup),
		"internal_wall_count" = length(context.state.geometry.internal_wall_turfs),
		"wall_hash" = context.state.geometry.wall_hash,
	)
	context.state.add_stage_report("walls_doors", "ok", null, list(
		"wall_count" = length(context.state.geometry.wall_lookup),
		"wall_hash" = context.state.geometry.wall_hash,
	))
	return TRUE
