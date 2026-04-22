GLOBAL_DATUM_INIT(world_edit_shape_preview, /datum/world_edit_shape_preview_service, new)

/datum/world_edit_shape_preview_service

/datum/world_edit_shape_preview_service/proc/build_shape_preview(datum/world_edit_shape_contract/shape_contract, preview_render_token = null)
	var/datum/world_edit_preview_model/preview_model = new
	if(!istype(shape_contract))
		preview_model.preview_render_token = preview_render_token
		return preview_model

	var/list/preview_layers = islist(shape_contract.metadata) ? shape_contract.metadata["preview_layers"] : null
	if(!islist(preview_layers))
		preview_model.final_turfs = shape_contract.copy_anchor_turfs()
		preview_model.preview_render_token = preview_render_token
		return preview_model

	preview_model.anchor_turfs = islist(preview_layers["anchor_turfs"]) ? preview_layers["anchor_turfs"] : list()
	preview_model.vertex_turfs = islist(preview_layers["vertex_turfs"]) ? preview_layers["vertex_turfs"] : list()
	preview_model.edge_turfs = islist(preview_layers["edge_turfs"]) ? preview_layers["edge_turfs"] : list()
	preview_model.closure_turfs = islist(preview_layers["closure_turfs"]) ? preview_layers["closure_turfs"] : list()
	preview_model.final_turfs = islist(preview_layers["final_turfs"]) ? preview_layers["final_turfs"] : list()
	preview_model.guide_turfs = islist(preview_layers["guide_turfs"]) ? preview_layers["guide_turfs"] : list()
	preview_model.preview_render_token = length("[preview_render_token]") ? preview_render_token : preview_layers["preview_render_token"]
	return preview_model
