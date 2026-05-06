/datum/world_edit_building_request
	var/list/config = list()
	var/datum/world_edit_building_archetype/archetype
	var/effective_seed = 1
	var/datum/world_edit_building_prng/program_rng
	var/datum/world_edit_building_prng/geometry_rng
	var/datum/world_edit_building_prng/fixture_rng
	var/datum/world_edit_building_prng/facade_rng
	var/datum/world_edit_building_prng/microvariation_rng

/datum/world_edit_generator/building_layout/proc/build_building_request(list/params, datum/world_edit_shape_contract/shape_contract, list/placement_context)
	var/list/config = normalize_building_params(params)
	var/datum/world_edit_building_request/request = new
	request.config = config
	if(config["error"])
		return request

	request.archetype = get_building_archetype(config["archetype_id"])
	if(!istype(request.archetype))
		config["error"] = "Unable to resolve building archetype."
		return request

	request.effective_seed = build_effective_building_seed(config, shape_contract, placement_context)
	request.program_rng = new /datum/world_edit_building_prng(build_stage_seed(request.effective_seed, "program"))
	request.geometry_rng = new /datum/world_edit_building_prng(build_stage_seed(request.effective_seed, "geometry"))
	request.fixture_rng = new /datum/world_edit_building_prng(build_stage_seed(request.effective_seed, "fixtures"))
	request.facade_rng = new /datum/world_edit_building_prng(build_stage_seed(request.effective_seed, "facade"))
	request.microvariation_rng = new /datum/world_edit_building_prng(build_stage_seed(request.effective_seed, "microvariation"))
	config["effective_seed"] = request.effective_seed
	config["archetype_label"] = request.archetype.label
	return request
