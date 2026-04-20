GLOBAL_DATUM_INIT(world_edit_shape_preview, /datum/world_edit_shape_preview_service, new)

/datum/world_edit_shape_preview_service

/datum/world_edit_shape_preview_service/proc/copy_preview_layer_turfs(list/raw_turfs)
	return islist(raw_turfs) ? raw_turfs.Copy() : list()

/datum/world_edit_shape_preview_service/proc/build_shape_preview(datum/world_edit_shape_contract/shape_contract)
	var/datum/world_edit_preview_model/preview_model = new
	if(!istype(shape_contract))
		return preview_model

	var/list/preview_layers = islist(shape_contract.metadata) ? shape_contract.metadata["preview_layers"] : null
	if(!islist(preview_layers))
		preview_model.final_turfs = shape_contract.copy_anchor_turfs()
		return preview_model

	preview_model.anchor_turfs = copy_preview_layer_turfs(preview_layers["anchor_turfs"])
	preview_model.vertex_turfs = copy_preview_layer_turfs(preview_layers["vertex_turfs"])
	preview_model.edge_turfs = copy_preview_layer_turfs(preview_layers["edge_turfs"])
	preview_model.closure_turfs = copy_preview_layer_turfs(preview_layers["closure_turfs"])
	preview_model.final_turfs = copy_preview_layer_turfs(preview_layers["final_turfs"])
	preview_model.guide_turfs = copy_preview_layer_turfs(preview_layers["guide_turfs"])
	return preview_model
