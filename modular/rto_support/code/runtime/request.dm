/// Prepared request object passed from controller logic into the future dispatch adapter.
/// Skeleton stage: metadata only.
/datum/rto_support_request
	/// Human that initiated the future support call.
	var/mob/living/carbon/human/owner
	/// Target turf chosen through the future binocular flow.
	var/turf/target_turf
	/// Template active for the owner at request time.
	var/datum/rto_support_template/template
	/// Action template selected for this request.
	var/datum/rto_support_action_template/action_template
	/// Visibility sector active at request time.
	var/datum/rto_visibility_zone/visibility_zone
	/// Adapter-facing key copied from the action template.
	var/dispatch_key
	/// Future scatter override or runtime-adjusted spread.
	var/scatter_override = 0

/// Checks whether the request is structurally valid.
/// Skeleton stage: intentionally returns FALSE.
/datum/rto_support_request/proc/is_valid()
	return FALSE
