/datum/world_edit_manager/proc/build_placement_ui_payload(click_mode_active, list/placement_modes, list/placement_shapes, list/placement_shape_fields)
	var/placement_supported = length(placement_modes) > 0
	var/placement_shape_supported = length(placement_shapes) > 0
	return list(
		"placement_supported" = placement_supported ? TRUE : FALSE,
		"placement_active" = (placement_click_active && click_mode_active) ? TRUE : FALSE,
		"placement_mode" = get_effective_placement_mode() || "single",
		"placement_mode_options" = placement_modes,
		"placement_shape_supported" = placement_shape_supported ? TRUE : FALSE,
		"placement_shape" = get_effective_placement_shape() || WORLD_EDIT_SHAPE_POINT,
		"placement_shape_options" = placement_shapes,
		"placement_shape_fields" = placement_shape_fields,
		"placement_shape_uses_anchor_pair" = placement_mode_uses_anchor_pair(get_effective_placement_shape()) ? TRUE : FALSE,
		"placement_interaction_kind" = get_placement_interaction_kind(),
		"placement_interaction_label" = get_placement_interaction_label(),
		"placement_collector_point_count" = get_placement_collector_point_count(),
		"placement_collector_min_points" = get_placement_collector_min_points(),
		"placement_collector_max_points" = get_placement_collector_max_points(),
		"can_finish_placement_collection" = (click_mode_active && is_current_placement_collector() && get_placement_collector_point_count() >= get_placement_collector_min_points()) ? TRUE : FALSE,
		"placement_supports_direction" = supports_current_placement_direction() ? TRUE : FALSE,
		"placement_dir" = GLOB.world_edit_helpers.dir_to_ui_value(get_effective_placement_dir()),
		"placement_dir_uses_facing" = placement_dir_uses_facing ? TRUE : FALSE,
		"placement_dir_options" = build_placement_dir_options(),
		"placement_anchor" = get_placement_anchor_desc(),
		"can_start_placement_mode" = (supports_current_placement_ux() && !click_mode_active) ? TRUE : FALSE,
	)
