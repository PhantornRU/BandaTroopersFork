/*
 * Semantic export for schematic rendering.
 *
 * The Python renderer intentionally consumes semantic.json instead of parsing a
 * DMM file. This keeps the MVP independent from DMI icons and exposes exactly
 * the debugging information reviewers need: changed tiles, blockers, doors,
 * rooms, routes, objects, and structured errors.
 */
/datum/world_edit_visual_case/proc/export_artifacts(list/apply_result, list/post_emit_result)
	var/list/artifacts = list()
	artifacts["semantic_json"] = "semantic.json"
	artifacts["semantic_png"] = "semantic.png"

	if(render_config?["after_dmm"])
		add_warning("after.dmm export not available in MVP; semantic.json was exported instead.")
		artifacts["after_dmm"] = null

	return list("artifacts" = artifacts)

/datum/world_edit_visual_case/proc/export_semantic_json(list/report_data)
	if(!istype(canvas))
		return null

	var/list/semantic = list(
		"schema" = "world_edit_visual_semantic/v1",
		"case_id" = id,
		"width" = canvas.width,
		"height" = canvas.height,
		"origin" = list("x" = canvas.min_x, "y" = canvas.min_y, "z" = canvas.z),
		"tiles" = list(),
		"rooms" = report_data?["rooms"] || build_semantic_rooms(),
		"routes" = report_data?["routes"] || build_semantic_routes(),
		"markers" = build_semantic_markers(report_data),
		"errors" = errors.Copy(),
	)
	if(islist(report_data?["profile"]))
		semantic["profile"] = report_data["profile"]

	for(var/x in canvas.min_x to canvas.max_x)
		for(var/y in canvas.min_y to canvas.max_y)
			var/turf/T = locate(x, y, canvas.z)
			if(!istype(T))
				continue
			semantic["tiles"] += list(serialize_semantic_tile(T, x, y))

	var/path = "[out_dir]/semantic.json"
	write_json_file(path, semantic)
	return path

/datum/world_edit_visual_case/proc/serialize_semantic_tile(turf/T, x, y)
	var/area/A = get_area(T)
	var/list/tile = list(
		"x" = x,
		"y" = y,
		"local_x" = x - canvas.min_x + 1,
		"local_y" = y - canvas.min_y + 1,
		"turf" = "[T.type]",
		"area" = "[A?.type]",
		"density" = T.density ? TRUE : FALSE,
		"opacity" = T.opacity ? TRUE : FALSE,
	)
	tile["flags"] = list(
		// Flags are deliberately higher-level than raw type paths. They are the
		// stable contract used by render_semantic.py and future CI review sheets.
		"floor" = is_visual_floor(T),
		"wall" = is_visual_wall(T),
		"door" = has_visual_door(T),
		"reserved_walk" = is_reserved_walk_tile(T),
		"blocked" = is_blocked_tile(T),
		"changed" = canvas.changed_turfs[T] ? TRUE : FALSE,
		"error" = has_error_marker_at(x, y),
	)
	var/list/objects = list()
	for(var/obj/O as anything in T)
		objects += list(serialize_semantic_obj(O))
	tile["objects"] = objects
	return tile

/datum/world_edit_visual_case/proc/serialize_semantic_obj(obj/O)
	var/list/out = list(
		"path" = "[O.type]",
		"density" = O.density ? TRUE : FALSE,
		"dir" = GLOB.world_edit_helpers.dir_to_label(O.dir),
	)
	var/list/meta = lookup_object_placement_metadata(O)
	if(islist(meta))
		out["slot"] = meta["requested_slot"] || meta["slot"]
		out["provider_id"] = meta["fixture_provider_id"]
		out["functional"] = isnull(meta["functional"]) ? TRUE : (meta["functional"] ? TRUE : FALSE)
	return out

/datum/world_edit_visual_case/proc/lookup_object_placement_metadata(obj/O)
	if(!istype(O) || !islist(last_plan?.placements))
		return null
	// Placement metadata is stored on the plan, not on emitted atoms. Match by
	// coordinate and type so semantic.json can still show slot/provider details.
	for(var/list/placement as anything in last_plan.placements)
		if(!islist(placement))
			continue
		if("[placement["x"]]" != "[O.x]" || "[placement["y"]]" != "[O.y]" || "[placement["z"]]" != "[O.z]")
			continue
		if("[placement["obj_path"]]" != "[O.type]")
			continue
		return placement
	return null

/datum/world_edit_visual_case/proc/is_visual_floor(turf/T)
	return istype(T, /turf/open) && !T.density

/datum/world_edit_visual_case/proc/is_visual_wall(turf/T)
	return T.density ? TRUE : FALSE

/datum/world_edit_visual_case/proc/has_visual_door(turf/T)
	for(var/obj/O as anything in T)
		if(findtext("[O.type]", "/door"))
			return TRUE
	return FALSE

/datum/world_edit_visual_case/proc/is_reserved_walk_tile(turf/T)
	var/list/route_turfs = last_plan?.metadata?["generator_effect_turfs"]
	return islist(route_turfs) && (T in route_turfs) && !T.density

/datum/world_edit_visual_case/proc/is_blocked_tile(turf/T)
	if(T.density)
		return TRUE
	for(var/atom/movable/A as anything in T)
		if(ismob(A))
			continue
		if(A.density)
			return TRUE
	return FALSE

/datum/world_edit_visual_case/proc/has_error_marker_at(x, y)
	for(var/list/error as anything in errors)
		if(!islist(error))
			continue
		if(text2num("[error["x"]]") == x && text2num("[error["y"]]") == y)
			return TRUE
	return FALSE

/datum/world_edit_visual_case/proc/build_semantic_rooms()
	var/list/rooms = list()
	var/list/raw_rooms = last_plan?.metadata?["room_reports"]
	if(islist(raw_rooms))
		for(var/list/room as anything in raw_rooms)
			if(islist(room))
				rooms += list(room.Copy())
	return rooms

/datum/world_edit_visual_case/proc/build_semantic_routes()
	var/list/routes = list()
	var/list/corridor_report = last_plan?.metadata?["corridor_report"]
	if(islist(corridor_report))
		routes += list(corridor_report.Copy())
	return routes

/datum/world_edit_visual_case/proc/build_semantic_markers(list/report_data)
	var/list/markers = list()
	var/list/anchors = shape_config?["anchors"]
	if(islist(anchors))
		for(var/list/anchor as anything in anchors)
			if(!islist(anchor))
				continue
			markers += list(list(
				"kind" = "anchor",
				"x" = text2num("[anchor["x"]]") || 0,
				"y" = text2num("[anchor["y"]]") || 0,
				"label" = "anchor",
			))
	if(last_plan?.metadata?["center_turf"])
		var/turf/center = last_plan.metadata["center_turf"]
		if(istype(center))
			markers += list(list("kind" = "center", "x" = center.x, "y" = center.y, "label" = "center"))
	return markers
