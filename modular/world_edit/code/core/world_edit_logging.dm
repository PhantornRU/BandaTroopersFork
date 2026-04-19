GLOBAL_DATUM_INIT(world_edit_logging, /datum/world_edit_logging_service, new)

/datum/world_edit_logging_service

/datum/world_edit_logging_service/proc/params_to_text(list/params, max_length = 220)
	if(!islist(params) || !length(params))
		return "<empty>"

	var/serialized = "[params]"
	if(length(serialized) > max_length)
		serialized = "[copytext(serialized, 1, max_length)]..."
	return serialized

/datum/world_edit_logging_service/proc/params_hash(list/params)
	if(!islist(params) || !length(params))
		return md5("<empty>")
	return md5("[params]")

/datum/world_edit_logging_service/proc/log_operation(client/user, generator_id, rights_used, turf/center_turf, created_count, deleted_count, duration_ds, result, params_short)
	if(!user)
		return

	var/duration_ms = max(duration_ds, 0) * 100
	var/actor_ckey = user.ckey || "unknown"
	var/rights_text = rights2text(rights_used, " ")
	var/center_text = center_turf ? "[center_turf.x],[center_turf.y],[center_turf.z]" : "n/a"
	var/params_hash_source = isnull(params_short) ? "<empty>" : "[params_short]"
	var/params_hash = md5(params_hash_source)

	var/log_payload = "generator_id=[generator_id]; actor_ckey=[actor_ckey]; rights_used=[rights_text]; center_turf=[center_text]; created_count=[created_count]; deleted_count=[deleted_count]; duration_ms=[duration_ms]; result=[result]; params_short=[params_short]; params_hash=[params_hash]"
	var/log_line = "[key_name_admin(user)] WorldEdit operation: [log_payload]"

	log_admin(log_line)
	if(center_turf)
		message_admins(SPAN_ADMINNOTICE(log_line), center_turf.x, center_turf.y, center_turf.z)
	else
		message_admins(SPAN_ADMINNOTICE(log_line))
