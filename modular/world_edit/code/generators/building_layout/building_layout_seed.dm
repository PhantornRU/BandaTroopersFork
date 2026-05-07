#define WORLD_EDIT_BUILDING_MAX_FOOTPRINT_TURFS 512
#define WORLD_EDIT_BUILDING_MAX_PREVIEW_OBJECT_SPECS 700
#define WORLD_EDIT_BUILDING_MAX_HOVER_PREVIEW_OBJECT_SPECS 120
#define WORLD_EDIT_BUILDING_MAX_WINDOWS 12
#define WORLD_EDIT_BUILDING_MAX_FIXTURE_OBJECTS 96
#define WORLD_EDIT_BUILDING_MAX_CLUSTER_STEPS 32
#define WORLD_EDIT_BUILDING_MAX_VALIDATION_ERRORS 12
#define WORLD_EDIT_BUILDING_MAX_REPAIR_ATTEMPTS 6
#define WORLD_EDIT_BUILDING_MAX_LAYOUT_CANDIDATES 6
#define WORLD_EDIT_BUILDING_MAX_MASK_VARIANTS 5
#define WORLD_EDIT_BUILDING_MAX_REGION_CANDIDATES_PER_SPEC 10
#define WORLD_EDIT_BUILDING_MAX_REGION_ASSIGNMENT_STEPS 128
#define WORLD_EDIT_BUILDING_MAX_REGION_ASSIGNMENT_BRANCHES 8
#define WORLD_EDIT_BUILDING_MAX_DIVIDER_RUN_ATTEMPTS 12
#define WORLD_EDIT_BUILDING_MAX_ROOM_IN_ROOM_CANDIDATES 96
#define WORLD_EDIT_BUILDING_MAX_TEMPLATE_CHUNK_CELLS 12
#define WORLD_EDIT_BUILDING_DEFAULT_MAX_EMPTY_FLOOR_RATIO 64
#define WORLD_EDIT_BUILDING_AUTO_SEED 0
#define WORLD_EDIT_BUILDING_HASH_MOD 1000000007

/datum/world_edit_building_prng
	var/state = 1

/datum/world_edit_building_prng/New(seed)
	. = ..()
	state = max(round(text2num("[seed]") || 1), 1)

/datum/world_edit_building_prng/proc/next_value()
	state = ((state * 110351) + 12345) % WORLD_EDIT_BUILDING_HASH_MOD
	if(state <= 0)
		state += WORLD_EDIT_BUILDING_HASH_MOD
	return state

/datum/world_edit_building_prng/proc/next_between(min_value, max_value)
	min_value = round(min_value)
	max_value = round(max_value)
	if(max_value <= min_value)
		return min_value
	return min_value + (next_value() % (max_value - min_value + 1))

/datum/world_edit_building_prng/proc/chance(percent)
	percent = clamp(round(percent), 0, 100)
	if(percent <= 0)
		return FALSE
	if(percent >= 100)
		return TRUE
	return next_between(1, 100) <= percent

/datum/world_edit_building_prng/proc/pick_from(list/items)
	if(!islist(items) || !length(items))
		return null
	return items[next_between(1, length(items))]

/datum/world_edit_generator/building_layout/proc/build_seed_from_text(value)
	var/text_value = "[value]"
	var/hash = 17
	for(var/index in 1 to length(text_value))
		hash = ((hash * 33) + text2ascii(text_value, index)) % WORLD_EDIT_BUILDING_HASH_MOD
	return max(hash, 1)

/datum/world_edit_generator/building_layout/proc/build_effective_building_seed(list/config, datum/world_edit_shape_contract/shape_contract, list/placement_context)
	var/requested_seed = round(text2num("[config["building_seed"]]") || WORLD_EDIT_BUILDING_AUTO_SEED)
	if(requested_seed > 0)
		return requested_seed

	var/turf/seed_turf = get_shape_placement_seed_turf(shape_contract, placement_context)
	var/seed_text = "[config["archetype_id"]]|[config["faction_preset"]]|[config["half_width"]]|[config["half_depth"]]|[config["detail_budget"]]|[config["window_density"]]"
	if(istype(seed_turf))
		seed_text = "[seed_text]|[seed_turf.x],[seed_turf.y],[seed_turf.z]"
	seed_text = "[seed_text]|[placement_context["direction"] || manager?.get_effective_placement_dir() || NORTH]|[shape_contract?.shape_id || WORLD_EDIT_SHAPE_POINT]"
	return build_seed_from_text(seed_text)

/datum/world_edit_generator/building_layout/proc/build_stage_seed(base_seed, stage_name)
	return build_seed_from_text("[base_seed]|[stage_name]")
