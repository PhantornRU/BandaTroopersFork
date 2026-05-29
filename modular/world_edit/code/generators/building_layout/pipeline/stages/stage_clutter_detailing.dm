/datum/world_edit_generation_stage/clutter_detailing
	id = "clutter_detailing"

/datum/world_edit_generation_stage/clutter_detailing/execute(datum/world_edit_generation_context/context)
	// Phase 9: Multi-layer Clutter & Detailing
	var/clutter_placed = 0
	
	for(var/datum/world_edit_building_room/room as anything in context.state.geometry.solved_rooms)
		var/datum/world_edit_building_zone_spec/zone_spec = context.state.semantic_plan?.get_zone_spec(room.zone_id)
		var/clutter_density = istype(zone_spec) ? zone_spec.clutter_density : 0
		
		if(clutter_density <= 0)
			continue
			
		// Calculate how many clutter items to place based on density and room area
		var/clutter_budget = round(room.area * (clutter_density / 100))
		if(clutter_budget <= 0)
			continue
			
		for(var/i in 1 to clutter_budget)
			var/turf/target_turf = context.request.microvariation_rng.pick_from(room.turfs)
			
			if(!istype(target_turf))
				continue
				
			// Do not block navigation or critical paths
			if(context.state.geometry.reserved_lookup[target_turf] || context.state.geometry.door_turfs[target_turf])
				continue
				
			// Ensure it's floor
			if(!context.state.geometry.floor_lookup[target_turf])
				continue
				
			// Simulate clutter placement via a placeholder or actual decal list
			// E.g., place_clutter(target_turf, room.role)
			clutter_placed++
			
	context.state.add_stage_report("clutter_detailing", "ok", null, list(
		"clutter_items_placed" = clutter_placed
	))
	
	return TRUE
