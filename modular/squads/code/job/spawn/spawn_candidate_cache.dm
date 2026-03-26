/mob/living/carbon/human
	var/tmp/list/cached_modular_spawn_candidate
	var/tmp/cached_modular_spawn_job_type
	var/tmp/cached_modular_spawn_late_join = FALSE

/mob/living/carbon/human/proc/cache_modular_spawn_candidate(list/spawn_candidate, datum/job/job_datum, late_join = FALSE)
	if(!islist(spawn_candidate))
		clear_modular_spawn_candidate_cache()
		return

	cached_modular_spawn_candidate = spawn_candidate.Copy()
	cached_modular_spawn_job_type = job_datum?.type
	cached_modular_spawn_late_join = late_join

/mob/living/carbon/human/proc/clear_modular_spawn_candidate_cache()
	cached_modular_spawn_candidate = null
	cached_modular_spawn_job_type = null
	cached_modular_spawn_late_join = FALSE

/mob/living/carbon/human/proc/get_cached_modular_spawn_candidate(datum/job/job_datum = null)
	if(!islist(cached_modular_spawn_candidate))
		return null

	if(istype(job_datum) && cached_modular_spawn_job_type && cached_modular_spawn_job_type != job_datum.type)
		clear_modular_spawn_candidate_cache()
		return null

	if(!isturf(cached_modular_spawn_candidate["spawn_turf"]))
		clear_modular_spawn_candidate_cache()
		return null

	return cached_modular_spawn_candidate

/mob/living/carbon/human/proc/resolve_modular_spawn_candidate(datum/job/job_datum, late_join = FALSE)
	if(!istype(job_datum))
		return null

	var/datum/modular_squad_spawn_resolver/resolver = new(src, job_datum, late_join)
	var/list/spawn_candidate = resolver.resolve()

	if(!islist(spawn_candidate))
		clear_modular_spawn_candidate_cache()
		squads_debug_log("[src] modular resolver returned null for job=[job_datum.title], late_join=[late_join].")
		return null

	cache_modular_spawn_candidate(spawn_candidate, job_datum, late_join)
	return spawn_candidate

/mob/living/carbon/human/proc/get_modular_spawn_candidate(datum/job/job_datum, late_join = FALSE)
	if(!istype(job_datum))
		squads_debug_log("[src] get_modular_spawn_candidate called with invalid job_datum.")
		return null

	if(!GLOB.job_squad_roles.Find(GET_DEFAULT_ROLE(job_datum.title)) && !job_datum.uses_modular_job_landmark_spawn())
		squads_debug_log("[src] job [job_datum.title] is not allowed to use modular non-squad spawn resolution.")
		return null

	return resolve_modular_spawn_candidate(job_datum, late_join)

/mob/living/carbon/human/proc/get_modular_spawn_turf(datum/job/job_datum, late_join = FALSE)
	var/list/spawn_candidate = get_modular_spawn_candidate(job_datum, late_join)
	if(isturf(spawn_candidate?["spawn_turf"]))
		return spawn_candidate["spawn_turf"]

	squads_debug_log("[src] no modular spawn turf resolved for [job_datum?.title], late_join=[late_join].")
	return null
