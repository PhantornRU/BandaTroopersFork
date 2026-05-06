/datum/world_edit_building_zone_spec
	var/id = ""
	var/label = ""
	var/role = ""
	var/min_area = 1
	var/required = TRUE
	var/must_touch_route = TRUE
	var/privacy_sensitive = FALSE
	var/window_allowed = TRUE
	var/divider_mode = "none"
	var/list/anchor_tags = list()

/datum/world_edit_building_zone_spec/New(_id, _label, _role, _min_area = 1, _required = TRUE, _must_touch_route = TRUE, _privacy_sensitive = FALSE, list/_anchor_tags = null, _window_allowed = TRUE, _divider_mode = "none")
	. = ..()
	id = "[_id]"
	label = "[_label]"
	role = "[_role]"
	min_area = max(round(text2num("[_min_area]") || 1), 0)
	required = _required ? TRUE : FALSE
	must_touch_route = _must_touch_route ? TRUE : FALSE
	privacy_sensitive = _privacy_sensitive ? TRUE : FALSE
	window_allowed = _window_allowed ? TRUE : FALSE
	divider_mode = length("[_divider_mode]") ? "[_divider_mode]" : "none"
	anchor_tags = islist(_anchor_tags) ? _anchor_tags.Copy() : list()

/datum/world_edit_building_region_spec
	var/id = ""
	var/zone_id = ""
	var/front_min = 0
	var/front_max = 100
	var/lateral_min = -100
	var/lateral_max = 100
	var/priority = 0

/datum/world_edit_building_region_spec/New(_id, _zone_id, _front_min, _front_max, _lateral_min, _lateral_max, _priority = 0)
	. = ..()
	id = "[_id]"
	zone_id = "[_zone_id]"
	front_min = round(text2num("[_front_min]") || 0)
	front_max = round(text2num("[_front_max]") || 0)
	lateral_min = round(text2num("[_lateral_min]") || 0)
	lateral_max = round(text2num("[_lateral_max]") || 0)
	priority = round(text2num("[_priority]") || 0)

/datum/world_edit_building_solved_region
	var/id = ""
	var/zone_id = ""
	var/list/turfs = list()
	var/turf/focus_turf
	var/priority = 0
	var/x1 = null
	var/y1 = null
	var/x2 = null
	var/y2 = null

/datum/world_edit_building_solved_region/New(_id, _zone_id, _priority = 0)
	. = ..()
	id = "[_id]"
	zone_id = "[_zone_id]"
	priority = round(text2num("[_priority]") || 0)

/datum/world_edit_building_divider_plan
	var/id = ""
	var/source_zone_id = ""
	var/inner_zone_id = ""
	var/list/wall_turfs = list()
	var/list/opening_turfs = list()
	var/list/opening_dirs = list()
	var/list/inner_turfs = list()

/datum/world_edit_building_divider_plan/New(_id, _source_zone_id, _inner_zone_id)
	. = ..()
	id = "[_id]"
	source_zone_id = "[_source_zone_id]"
	inner_zone_id = "[_inner_zone_id]"

/datum/world_edit_building_divider_edge_run
	var/id = ""
	var/zone_id = ""
	var/source_zone_id = ""
	var/list/wall_turfs = list()
	var/list/outside_dirs = list()
	var/orientation = ""
	var/score = 0

/datum/world_edit_building_divider_edge_run/New(_id, _zone_id, _source_zone_id, _orientation)
	. = ..()
	id = "[_id]"
	zone_id = "[_zone_id]"
	source_zone_id = "[_source_zone_id]"
	orientation = "[_orientation]"

/datum/world_edit_building_nested_room_spec
	var/outer_zone_id = ""
	var/inner_zone_id = ""
	var/min_width = 9
	var/min_height = 9
	var/margin = 1

/datum/world_edit_building_nested_room_spec/New(_outer_zone_id, _inner_zone_id, _min_width = 9, _min_height = 9, _margin = 1)
	. = ..()
	outer_zone_id = "[_outer_zone_id]"
	inner_zone_id = "[_inner_zone_id]"
	min_width = max(round(text2num("[_min_width]") || 1), 1)
	min_height = max(round(text2num("[_min_height]") || 1), 1)
	margin = max(round(text2num("[_margin]") || 1), 1)

/datum/world_edit_building_adjacency_rule
	var/zone_a = ""
	var/zone_b = ""
	var/required = TRUE

/datum/world_edit_building_adjacency_rule/New(_zone_a, _zone_b, _required = TRUE)
	. = ..()
	zone_a = "[_zone_a]"
	zone_b = "[_zone_b]"
	required = _required ? TRUE : FALSE

/datum/world_edit_building_cluster_spec
	var/id = ""
	var/phase = "major"
	var/pattern = "object"
	var/slot = "table"
	var/category = "table"
	var/list/anchors = list()
	var/min_count = 1
	var/max_count = 1
	var/wall_required = FALSE
	var/chair_count = 0
	var/priority = 50
	var/required = TRUE
	var/signature_id = ""
	var/signature_weight = 0
	var/signature_required = FALSE

/datum/world_edit_building_cluster_spec/New(_id, _phase, _pattern, _slot, _category, list/_anchors, _min_count = 1, _max_count = 1, _wall_required = FALSE, _chair_count = 0, _priority = 50, _required = TRUE)
	. = ..()
	id = "[_id]"
	phase = "[_phase]"
	pattern = "[_pattern]"
	slot = "[_slot]"
	category = "[_category]"
	anchors = islist(_anchors) ? _anchors.Copy() : list()
	min_count = max(round(text2num("[_min_count]") || 1), 0)
	max_count = max(round(text2num("[_max_count]") || min_count), min_count)
	wall_required = _wall_required ? TRUE : FALSE
	chair_count = max(round(text2num("[_chair_count]") || 0), 0)
	priority = round(text2num("[_priority]") || 0)
	required = _required ? TRUE : FALSE

/datum/world_edit_building_semantic_plan
	var/datum/world_edit_building_archetype/archetype
	var/entry_zone_id = "entry_buffer"
	var/hub_zone_id = ""
	var/primary_zone_id = ""
	var/list/zone_specs = list()
	var/list/zone_specs_by_id = list()
	var/list/region_specs = list()
	var/list/adjacency_rules = list()
	var/list/cluster_specs = list()
	var/list/category_minimums = list()
	var/list/signature_minimums = list()
	var/list/signature_weights = list()
	var/list/mandatory_zones = list()
	var/list/nested_room_specs = list()
	var/nested_outer_zone = null
	var/nested_inner_zone = null
	var/nested_min_width = 9
	var/nested_min_height = 9
	var/min_signature_score = 70

/datum/world_edit_building_semantic_plan/New(datum/world_edit_building_archetype/_archetype)
	. = ..()
	archetype = _archetype
	if(!istype(archetype))
		return
	entry_zone_id = archetype.entry_zone
	hub_zone_id = archetype.hub_zone
	primary_zone_id = archetype.primary_zone
	zone_specs = archetype.zone_specs.Copy()
	region_specs = archetype.region_specs.Copy()
	adjacency_rules = archetype.adjacency_rules.Copy()
	cluster_specs = archetype.cluster_specs.Copy()
	category_minimums = archetype.category_minimums.Copy()
	signature_minimums = archetype.signature_minimums.Copy()
	signature_weights = archetype.signature_weights.Copy()
	mandatory_zones = archetype.mandatory_zones.Copy()
	nested_room_specs = archetype.nested_room_specs.Copy()
	nested_outer_zone = archetype.nested_outer_zone
	nested_inner_zone = archetype.nested_inner_zone
	nested_min_width = archetype.nested_min_width
	nested_min_height = archetype.nested_min_height
	min_signature_score = archetype.min_signature_score
	for(var/datum/world_edit_building_zone_spec/zone_spec as anything in zone_specs)
		if(istype(zone_spec))
			zone_specs_by_id[zone_spec.id] = zone_spec

/datum/world_edit_building_semantic_plan/proc/get_zone_spec(zone_id)
	return zone_specs_by_id["[zone_id]"]

/datum/world_edit_building_semantic_plan/proc/get_cluster_specs(phase_id)
	var/list/result = list()
	for(var/datum/world_edit_building_cluster_spec/cluster_spec as anything in cluster_specs)
		if(istype(cluster_spec) && cluster_spec.phase == "[phase_id]")
			result += cluster_spec
	return result

/datum/world_edit_building_archetype
	var/id = ""
	var/label = ""
	var/suggested_shell_preset = "colony"
	var/list/footprint_families = list("RECT")
	var/primary_zone = "main"
	var/entry_zone = "entry_buffer"
	var/hub_zone = "main"
	var/list/zone_specs = list()
	var/list/region_specs = list()
	var/list/adjacency_rules = list()
	var/list/cluster_specs = list()
	var/list/category_minimums = list()
	var/list/signature_minimums = list()
	var/list/signature_weights = list()
	var/list/mandatory_zones = list()
	var/list/object_budgets = list()
	var/list/shell_overrides = list()
	var/list/nested_room_specs = list()
	var/window_bias = 40
	var/detail_bias = 60
	var/nested_outer_zone = null
	var/nested_inner_zone = null
	var/nested_min_width = 9
	var/nested_min_height = 9
	var/min_signature_score = 70

/datum/world_edit_building_archetype/New()
	. = ..()
	zone_specs = list()
	region_specs = list()
	adjacency_rules = list()
	cluster_specs = list()
	category_minimums = list()
	signature_minimums = list()
	signature_weights = list()
	mandatory_zones = list()
	object_budgets = list()
	shell_overrides = list()
	nested_room_specs = list()
	build_definition()

/datum/world_edit_building_archetype/proc/build_definition()
	return

/datum/world_edit_building_archetype/proc/build_option()
	return list("label" = label, "value" = id)

/datum/world_edit_building_archetype/proc/add_zone(id, label, role, min_area = 1, required = TRUE, must_touch_route = TRUE, privacy_sensitive = FALSE, list/anchors = null, window_allowed = TRUE, divider_mode = "none")
	var/datum/world_edit_building_zone_spec/zone_spec = new(id, label, role, min_area, required, must_touch_route, privacy_sensitive, anchors, window_allowed, divider_mode)
	zone_specs += zone_spec
	if(zone_spec.required)
		mandatory_zones += zone_spec.id
	return zone_spec

/datum/world_edit_building_archetype/proc/add_region(id, zone_id, front_min, front_max, lateral_min, lateral_max, priority = 0)
	var/datum/world_edit_building_region_spec/region_spec = new(id, zone_id, front_min, front_max, lateral_min, lateral_max, priority)
	region_specs += region_spec
	return region_spec

/datum/world_edit_building_archetype/proc/add_adjacency(zone_a, zone_b, required = TRUE)
	var/datum/world_edit_building_adjacency_rule/rule = new(zone_a, zone_b, required)
	adjacency_rules += rule
	return rule

/datum/world_edit_building_archetype/proc/add_nested_room(outer_zone_id, inner_zone_id, min_width = 9, min_height = 9, margin = 1)
	var/datum/world_edit_building_nested_room_spec/nested_room_spec = new(outer_zone_id, inner_zone_id, min_width, min_height, margin)
	nested_room_specs += nested_room_spec
	return nested_room_spec

/datum/world_edit_building_archetype/proc/add_cluster(id, phase, pattern, slot, category, list/anchors, min_count = 1, max_count = 1, wall_required = FALSE, chair_count = 0, priority = 50, required = TRUE)
	var/datum/world_edit_building_cluster_spec/cluster_spec = new(id, phase, pattern, slot, category, anchors, min_count, max_count, wall_required, chair_count, priority, required)
	cluster_specs += cluster_spec
	return cluster_spec

/datum/world_edit_building_archetype/proc/add_signature_cluster(id, phase, pattern, slot, category, list/anchors, min_count = 1, max_count = 1, wall_required = FALSE, chair_count = 0, priority = 50, signature_id = null, signature_weight = 20, required = TRUE)
	var/datum/world_edit_building_cluster_spec/cluster_spec = add_cluster(id, phase, pattern, slot, category, anchors, min_count, max_count, wall_required, chair_count, priority, required)
	cluster_spec.signature_id = length("[signature_id]") ? "[signature_id]" : "[id]"
	cluster_spec.signature_weight = max(round(text2num("[signature_weight]") || 0), 0)
	cluster_spec.signature_required = required ? TRUE : FALSE
	var/minimum = max(round(text2num("[min_count]") || 1), 1)
	if(cluster_spec.signature_required)
		signature_minimums[cluster_spec.signature_id] = max(round(text2num("[signature_minimums[cluster_spec.signature_id]]") || 0), minimum)
		signature_weights[cluster_spec.signature_id] = max(round(text2num("[signature_weights[cluster_spec.signature_id]]") || 0), cluster_spec.signature_weight)
	return cluster_spec

/datum/world_edit_building_archetype/proc/build_semantic_plan()
	return new /datum/world_edit_building_semantic_plan(src)

/datum/world_edit_building_archetype/living
	id = "living"
	label = "Living module"
	suggested_shell_preset = "colony"
	footprint_families = list("RECT", "L", "U")
	primary_zone = "common"
	hub_zone = "common"
	window_bias = 55
	detail_bias = 75

/datum/world_edit_building_archetype/living/build_definition()
	add_zone("entry_buffer", "Entry buffer", "entry", 2, TRUE, TRUE, FALSE, list("entry_buffer", "public_route"), TRUE)
	add_zone("common", "Common/social", "hub", 6, TRUE, TRUE, FALSE, list("common", "focus_center", "social_focus", "work_cluster"), TRUE)
	add_zone("sleep_privacy", "Sleep privacy", "private", 3, TRUE, TRUE, TRUE, list("sleep_privacy", "privacy_zone", "wall_anchor"), FALSE, "room")
	add_zone("storage_service", "Personal storage", "service", 2, TRUE, TRUE, FALSE, list("storage_service", "service_strip", "wall_anchor"), FALSE, "nook")
	add_region("entry_front", "entry_buffer", 0, 22, -45, 45, 100)
	add_region("common_core", "common", 18, 76, -45, 45, 60)
	add_region("sleep_back_left", "sleep_privacy", 58, 100, -100, -30, 90)
	add_region("storage_back_right", "storage_service", 35, 100, 30, 100, 80)
	add_region("common_fill", "common", 0, 100, -100, 100, 1)
	add_adjacency("entry_buffer", "common")
	add_adjacency("common", "sleep_privacy")
	add_adjacency("common", "storage_service")
	add_nested_room("common", "sleep_privacy", 7, 7, 1)
	add_signature_cluster("sleep_nook_signature", "major", "signature_living_nook", "bed", "bed", list("sleep_privacy", "privacy_zone", "bed_wall"), 2, 2, TRUE, 0, 100, "sleep_nook", 35)
	add_signature_cluster("dining_pair", "major", "table_cluster", "table", "table", list("common", "social_focus", "focus_center"), 1, 1, FALSE, 2, 90, "common_table", 20)
	add_signature_cluster("personal_storage", "major", "run", "cabinet", "cabinet", list("storage_service", "service_strip", "storage_wall"), 2, 2, TRUE, 0, 80, "personal_storage", 20)
	add_cluster("side_table", "secondary", "table_cluster", "table", "table", list("common", "window_band", "social_focus"), 1, 1, FALSE, 1, 50, FALSE)
	add_cluster("window_seat", "detail", "object", "chair", "chair", list("window_band", "common"), 1, 1, FALSE, 0, 40, FALSE)
	object_budgets = list("bed" = 2, "table" = 3, "chair" = 5, "cabinet" = 3, "rack" = 2)
	category_minimums = list("bed" = 1, "table" = 1, "cabinet" = 1)

/datum/world_edit_building_archetype/workshop
	id = "workshop"
	label = "Workshop"
	suggested_shell_preset = "colony"
	footprint_families = list("RECT", "L", "T", "COMPOUND")
	primary_zone = "main_work"
	hub_zone = "main_work"
	window_bias = 25
	detail_bias = 85

/datum/world_edit_building_archetype/workshop/build_definition()
	add_zone("entry_buffer", "Entry buffer", "entry", 2, TRUE, TRUE, FALSE, list("entry_buffer", "public_route"), TRUE)
	add_zone("main_work", "Main work bay", "hub", 8, TRUE, TRUE, FALSE, list("main_work", "work_cluster", "focus_center"), TRUE)
	add_zone("service_wall", "Service wall", "service", 4, TRUE, TRUE, FALSE, list("service_wall", "service_strip", "wall_anchor"), FALSE, "nook")
	add_zone("parts_storage", "Parts storage", "storage", 4, TRUE, TRUE, FALSE, list("parts_storage", "service_strip", "wall_anchor"), FALSE, "nook")
	add_region("entry_front", "entry_buffer", 0, 20, -35, 35, 100)
	add_region("service_left", "service_wall", 18, 88, -100, -50, 90)
	add_region("parts_back", "parts_storage", 68, 100, -20, 100, 80)
	add_region("main_work_core", "main_work", 16, 86, -48, 48, 60)
	add_region("main_work_fill", "main_work", 0, 100, -100, 100, 1)
	add_adjacency("entry_buffer", "main_work")
	add_adjacency("main_work", "service_wall")
	add_adjacency("main_work", "parts_storage")
	add_nested_room("main_work", "parts_storage", 9, 9, 1)
	add_signature_cluster("workbench_machine_wall", "major", "signature_workshop_wall", "table", "table", list("service_wall", "machine_wall"), 4, 5, TRUE, 0, 100, "workbench_machine_wall", 35)
	add_signature_cluster("parts_rack_aisles", "major", "signature_rack_aisles", "rack", "rack", list("parts_storage", "rack_aisle", "storage_wall"), 3, 5, TRUE, 0, 95, "parts_rack_aisles", 25)
	add_signature_cluster("central_assembly_table", "major", "table_cluster", "table", "table", list("main_work", "work_cluster", "focus_center"), 1, 1, FALSE, 2, 90, "assembly_table", 20)
	add_cluster("operator_console", "secondary", "wall_object", "console", "console", list("service_wall", "wall_anchor", "observation"), 1, 1, TRUE, 0, 70, FALSE)
	add_cluster("tool_storage", "secondary", "run", "cabinet", "cabinet", list("service_wall", "service_strip", "wall_anchor"), 1, 2, TRUE, 0, 60, FALSE)
	add_cluster("parts_crate_stack", "detail", "run", "crate", "crate", list("parts_storage", "main_work"), 2, 3, FALSE, 0, 45, FALSE)
	add_cluster("inspection_chair", "detail", "object", "chair", "chair", list("main_work", "work_cluster"), 1, 1, FALSE, 0, 35, FALSE)
	object_budgets = list("table" = 5, "chair" = 4, "rack" = 5, "cabinet" = 3, "console" = 1, "crate" = 3)
	category_minimums = list("table" = 3, "rack" = 3)

/datum/world_edit_building_archetype/storage
	id = "storage"
	label = "Storage"
	suggested_shell_preset = "colony"
	footprint_families = list("RECT", "T")
	primary_zone = "loading_axis"
	hub_zone = "loading_axis"
	window_bias = 15
	detail_bias = 85

/datum/world_edit_building_archetype/storage/build_definition()
	add_zone("entry_buffer", "Entry buffer", "entry", 2, TRUE, TRUE, FALSE, list("entry_buffer", "public_route"), FALSE)
	add_zone("loading_axis", "Loading axis", "route", 6, TRUE, TRUE, FALSE, list("loading_axis", "primary_lane", "staging"), FALSE)
	add_zone("rack_zone", "Rack zone", "storage", 8, TRUE, TRUE, FALSE, list("rack_zone", "service_strip", "wall_anchor"), FALSE, "nook")
	add_zone("staging", "Staging/inspection", "staging", 3, TRUE, TRUE, FALSE, list("staging", "loading_axis"), FALSE)
	add_region("entry_front", "entry_buffer", 0, 18, -30, 30, 100)
	add_region("loading_spine", "loading_axis", 0, 100, -24, 24, 95)
	add_region("staging_back", "staging", 70, 100, -52, 52, 90)
	add_region("rack_left", "rack_zone", 18, 94, -100, -28, 75)
	add_region("rack_right", "rack_zone", 18, 94, 28, 100, 75)
	add_region("rack_fill", "rack_zone", 0, 100, -100, 100, 1)
	add_adjacency("entry_buffer", "loading_axis")
	add_adjacency("loading_axis", "rack_zone")
	add_adjacency("loading_axis", "staging")
	add_nested_room("loading_axis", "staging", 9, 9, 1)
	add_signature_cluster("rack_aisles", "major", "signature_rack_aisles", "rack", "rack", list("rack_zone", "rack_aisle", "storage_wall"), 6, 8, TRUE, 0, 100, "rack_aisles", 45)
	add_signature_cluster("loading_crates", "major", "staging_group", "crate", "crate", list("staging", "loading_axis"), 2, 3, FALSE, 0, 80, "loading_staging", 20)
	add_cluster("inspection_table", "secondary", "table_cluster", "table", "table", list("staging", "loading_axis"), 1, 1, FALSE, 1, 55, FALSE)
	add_cluster("crate_stack", "detail", "run", "crate", "crate", list("staging", "rack_zone"), 2, 3, FALSE, 0, 45, FALSE)
	object_budgets = list("rack" = 9, "cabinet" = 4, "crate" = 7, "table" = 1, "chair" = 1)
	category_minimums = list("rack" = 6, "crate" = 2)

/datum/world_edit_building_archetype/checkpoint
	id = "checkpoint"
	label = "Checkpoint"
	suggested_shell_preset = "colony"
	footprint_families = list("RECT", "WEDGE")
	primary_zone = "secure_side"
	hub_zone = "counter_line"
	window_bias = 20
	detail_bias = 75

/datum/world_edit_building_archetype/checkpoint/build_definition()
	add_zone("public_side", "Public approach", "public", 3, TRUE, TRUE, FALSE, list("public_side", "public_route", "entry_buffer"), TRUE)
	add_zone("counter_line", "Counter/barrier", "choke", 3, TRUE, TRUE, FALSE, list("counter_line", "counter_front", "barrier_line"), FALSE, "nook")
	add_zone("secure_side", "Secure side", "secure", 4, TRUE, TRUE, FALSE, list("secure_side", "counter_back", "work_cluster"), FALSE, "nook")
	add_zone("observation", "Observation/storage", "support", 2, TRUE, TRUE, FALSE, list("observation", "wall_anchor", "service_strip"), FALSE, "nook")
	add_region("public_front", "public_side", 0, 32, -100, 100, 95)
	add_region("counter_band", "counter_line", 30, 50, -100, 100, 100)
	add_region("observation_side", "observation", 50, 100, 42, 100, 80)
	add_region("secure_back", "secure_side", 48, 100, -100, 42, 70)
	add_region("secure_fill", "secure_side", 0, 100, -100, 100, 1)
	add_adjacency("public_side", "counter_line")
	add_adjacency("counter_line", "secure_side")
	add_adjacency("secure_side", "observation")
	add_nested_room("secure_side", "observation", 8, 8, 1)
	add_signature_cluster("checkpoint_control", "major", "signature_security_counter", "table", "table", list("counter_line", "counter_front", "counter_line_turf", "secure_side"), 4, 5, FALSE, 0, 100, "checkpoint_counter_control", 50)
	add_cluster("operator_console", "secondary", "wall_object", "console", "console", list("secure_side", "counter_back", "observation", "wall_anchor"), 1, 1, TRUE, 0, 95, FALSE)
	add_cluster("security_storage", "secondary", "wall_object", "cabinet", "cabinet", list("observation", "secure_side", "wall_anchor"), 1, 1, TRUE, 0, 65, FALSE)
	add_cluster("visitor_chair", "secondary", "object", "chair", "chair", list("public_side", "public_route"), 1, 1, FALSE, 0, 45, FALSE)
	add_cluster("barricade_line", "detail", "run", "barrier", "barrier", list("public_side", "barrier_line"), 2, 2, FALSE, 0, 35, FALSE)
	object_budgets = list("table" = 3, "chair" = 3, "rack" = 2, "cabinet" = 2, "console" = 1, "barrier" = 2)
	category_minimums = list("table" = 2, "console" = 1)

/datum/world_edit_building_archetype/medbay
	id = "medbay"
	label = "Medbay"
	suggested_shell_preset = "colony"
	footprint_families = list("RECT", "L", "U", "NESTED")
	primary_zone = "treatment"
	hub_zone = "treatment"
	window_bias = 35
	detail_bias = 80
	nested_outer_zone = "treatment"
	nested_inner_zone = "surgery_core"
	nested_min_width = 9
	nested_min_height = 9

/datum/world_edit_building_archetype/medbay/build_definition()
	add_zone("entry_buffer", "Entry/waiting", "entry", 2, TRUE, TRUE, FALSE, list("entry_buffer", "public_route"), TRUE)
	add_zone("triage", "Triage", "public_med", 4, TRUE, TRUE, FALSE, list("triage", "public_route", "window_band"), TRUE, "nook")
	add_zone("treatment", "Treatment", "hub", 8, TRUE, TRUE, FALSE, list("treatment", "work_cluster", "focus_center"), TRUE, "nook")
	add_zone("med_storage", "Medical storage", "service", 3, TRUE, TRUE, FALSE, list("med_storage", "service_strip", "wall_anchor"), FALSE, "room")
	add_zone("surgery_core", "Surgery core", "nested", 1, FALSE, TRUE, TRUE, list("surgery_core", "privacy_zone", "work_cluster"), FALSE)
	add_region("entry_front", "entry_buffer", 0, 18, -40, 40, 100)
	add_region("triage_front", "triage", 12, 42, -100, 100, 80)
	add_region("med_storage_side", "med_storage", 38, 100, 48, 100, 90)
	add_region("treatment_core", "treatment", 35, 100, -48, 48, 70)
	add_region("treatment_fill", "treatment", 0, 100, -100, 100, 1)
	add_adjacency("entry_buffer", "triage")
	add_adjacency("triage", "treatment")
	add_adjacency("treatment", "med_storage")
	add_nested_room("treatment", "surgery_core", 9, 9, 1)
	add_signature_cluster("treatment_bay_signature", "major", "signature_treatment_bay", "medical_bed", "medical_bed", list("treatment_wall", "treatment_bay"), 3, 5, TRUE, 0, 100, "treatment_bay", 45)
	add_signature_cluster("med_storage_wall", "major", "run", "medical_storage", "medical_storage", list("med_storage", "service_strip", "storage_wall", "treatment_wall"), 2, 3, TRUE, 0, 95, "medical_storage_wall", 25)
	add_signature_cluster("triage_table", "major", "table_cluster", "table", "table", list("triage", "public_side", "focus_center"), 1, 1, FALSE, 1, 80, "triage_surface", 15)
	add_cluster("waiting_chairs", "secondary", "run", "chair", "chair", list("triage", "entry_buffer", "public_route"), 2, 2, FALSE, 0, 55, FALSE)
	add_cluster("med_side_storage", "secondary", "wall_object", "cabinet", "cabinet", list("med_storage", "wall_anchor", "service_strip"), 1, 1, TRUE, 0, 50, FALSE)
	add_cluster("surgery_bed", "detail", "object", "medical_bed", "medical_bed", list("surgery_core", "privacy_zone"), 1, 1, FALSE, 0, 45, FALSE)
	object_budgets = list("medical_bed" = 4, "medical_storage" = 3, "table" = 2, "chair" = 4, "cabinet" = 2)
	category_minimums = list("medical_bed" = 2, "medical_storage" = 1, "table" = 1)

/datum/world_edit_generator/building_layout/proc/get_building_archetype_catalog()
	. = list()
	for(var/archetype_type in subtypesof(/datum/world_edit_building_archetype))
		var/datum/world_edit_building_archetype/archetype = new archetype_type()
		if(!length(archetype.id))
			continue
		.[archetype.id] = archetype

/datum/world_edit_generator/building_layout/proc/get_building_archetype_options()
	var/list/options = list()
	var/list/catalog = get_building_archetype_catalog()
	for(var/archetype_id in catalog)
		var/datum/world_edit_building_archetype/archetype = catalog[archetype_id]
		options += list(archetype.build_option())
	return options

/datum/world_edit_generator/building_layout/proc/get_building_archetype_aliases()
	return list(
		"living_small" = "living",
		"workshop_small" = "workshop",
		"storage_small" = "storage",
		"checkpoint_small" = "checkpoint",
		"medbay_small" = "medbay",
		"colony_living_small" = "living",
		"uscm_workshop_small" = "workshop",
		"uscm_storage_small" = "storage",
		"uscm_checkpoint_wedge" = "checkpoint",
		"storage_t" = "storage",
		"checkpoint_wedge" = "checkpoint",
	)

/datum/world_edit_generator/building_layout/proc/canonicalize_building_archetype_id(archetype_id)
	var/archetype_text = "[archetype_id]"
	var/list/aliases = get_building_archetype_aliases()
	return "[aliases[archetype_text] || archetype_text]"

/datum/world_edit_generator/building_layout/proc/get_building_archetype(archetype_id)
	var/list/catalog = get_building_archetype_catalog()
	var/datum/world_edit_building_archetype/archetype = catalog[canonicalize_building_archetype_id(archetype_id)]
	if(!istype(archetype))
		return catalog["living"]
	return archetype

/datum/world_edit_generator/building_layout/proc/resolve_building_archetype_option(value, fallback = "living")
	var/list/options = get_building_archetype_ids()
	var/canonical_value = canonicalize_building_archetype_id(value)
	if(canonical_value in options)
		return canonical_value
	var/canonical_fallback = canonicalize_building_archetype_id(fallback)
	if(canonical_fallback in options)
		return canonical_fallback
	return "living"

/datum/world_edit_generator/building_layout/proc/resolve_layout_variant_archetype_alias(list/params)
	var/layout_variant = "[islist(params) ? params["layout_variant"] : null]"
	switch(layout_variant)
		if("workshop")
			return "workshop"
		if("storage")
			return "storage"
		if("checkpoint")
			return "checkpoint"
		if("office")
			return "office"
	return "living"
