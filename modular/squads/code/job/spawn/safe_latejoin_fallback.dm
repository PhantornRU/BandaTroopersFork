/proc/get_modular_safe_latejoin_turf(job_key = null, squad_key = null, include_job_bucket = TRUE, include_global_bucket = TRUE)
	var/turf/spawn_turf = get_turf(SAFEPICK(GLOB.latejoin_by_squad[squad_key]))
	if(spawn_turf)
		return spawn_turf

	if(include_job_bucket)
		spawn_turf = get_turf(SAFEPICK(GLOB.latejoin_by_job[job_key]))
		if(spawn_turf)
			return spawn_turf

	if(include_global_bucket)
		return get_turf(SAFEPICK(GLOB.latejoin))

	return null
