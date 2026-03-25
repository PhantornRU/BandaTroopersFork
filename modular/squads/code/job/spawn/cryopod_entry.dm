/datum/job/proc/uses_modular_job_landmark_spawn()
	return GET_DEFAULT_ROLE(title) == JOB_SO

/mob/living/carbon/human/proc/find_free_cardinal_cryopod(turf/center_turf)
	if(!isturf(center_turf))
		return null

	var/list/cardinal_search_order = list(WEST, EAST, NORTH, SOUTH)
	for(var/cardinal_dir in cardinal_search_order)
		var/turf/candidate_turf = get_step(center_turf, cardinal_dir)
		if(!isturf(candidate_turf))
			continue

		var/obj/structure/machinery/cryopod/pod = locate(/obj/structure/machinery/cryopod) in candidate_turf
		if(!pod || pod.occupant)
			continue

		return pod

	return null

/mob/living/carbon/human/proc/try_enter_selected_cryopod(obj/structure/machinery/cryopod/target_pod)
	if(!target_pod || target_pod.occupant)
		return FALSE

	target_pod.go_in_cryopod(src, silent = TRUE)
	return loc == target_pod

/mob/living/carbon/human/proc/try_enter_nearby_free_cryopod(datum/job/job_datum = null, obj/structure/machinery/cryopod/preferred_pod = null)
	if(istype(loc, /obj/structure/machinery/cryopod))
		squads_debug_log("[src] is already inside cryopod; skipping enter.")
		return TRUE

	var/list/cached_candidate = get_cached_modular_spawn_candidate(job_datum)

	if(preferred_pod)
		if(try_enter_selected_cryopod(preferred_pod))
			squads_debug_log("[src] entered preferred cryopod [preferred_pod].")
			clear_modular_spawn_candidate_cache()
			return TRUE

		squads_debug_log("[src] preferred cryopod [preferred_pod] is no longer available.")

		if(istype(job_datum))
			var/list/retry_candidate = resolve_modular_spawn_candidate(job_datum, cached_modular_spawn_late_join)
			var/obj/structure/machinery/cryopod/retry_pod = retry_candidate?["preferred_pod"]
			if(retry_pod && try_enter_selected_cryopod(retry_pod))
				var/retry_source_tag = retry_candidate?["source_tag"]
				var/retry_tier_tag = retry_candidate?["tier_tag"]
				if(!retry_source_tag)
					retry_source_tag = "unknown"
				if(!retry_tier_tag)
					retry_tier_tag = "unknown"
				squads_debug_log("[src] entered retry cryopod [retry_pod], source=[retry_source_tag], tier=[retry_tier_tag].")
				clear_modular_spawn_candidate_cache()
				return TRUE

			if(retry_candidate?["no_pod_expected"])
				clear_modular_spawn_candidate_cache()
				squads_debug_log("[src] no cryopod expected after retry, player remains on spawn turf.")
				return FALSE

		if(cached_candidate?["no_pod_expected"])
			clear_modular_spawn_candidate_cache()
			squads_debug_log("[src] cached candidate expects no cryopod, player remains on spawn turf.")
			return FALSE

		clear_modular_spawn_candidate_cache()
		squads_debug_log("[src] preferred/retry cryopod path exhausted, player remains on spawn turf without local fallback.")
		return FALSE

	if(cached_candidate?["preferred_pod"])
		var/obj/structure/machinery/cryopod/cached_pod = cached_candidate["preferred_pod"]
		if(try_enter_selected_cryopod(cached_pod))
			var/cached_source_tag = cached_candidate?["source_tag"]
			var/cached_tier_tag = cached_candidate?["tier_tag"]
			if(!cached_source_tag)
				cached_source_tag = "unknown"
			if(!cached_tier_tag)
				cached_tier_tag = "unknown"
			squads_debug_log("[src] entered cached cryopod [cached_pod], source=[cached_source_tag], tier=[cached_tier_tag].")
			clear_modular_spawn_candidate_cache()
			return TRUE

	if(cached_candidate?["no_pod_expected"])
		clear_modular_spawn_candidate_cache()
		squads_debug_log("[src] cached candidate has no cryopod by design, player remains on spawn turf.")
		return FALSE

	var/obj/structure/machinery/cryopod/local_pod = find_free_cardinal_cryopod(get_turf(src))
	if(local_pod && try_enter_selected_cryopod(local_pod))
		squads_debug_log("[src] entered fallback local cryopod [local_pod].")
		return TRUE

	squads_debug_log("[src] failed to find cryopod for job=[job_datum?.title].")
	return FALSE
