/datum/world_edit_manager/proc/InterceptMouseEntered(mob/user, atom/object, location, control, params)
	if(!sync_click_intercept_state())
		return FALSE
	if(!placement_click_active || !supports_current_placement_ux())
		return FALSE
	if(!holder || holder != user?.client)
		return FALSE
	return handle_safe_placement_hover(user, get_turf(object))

/turf/MouseEntered(location, control, params)
	. = ..()
	var/mob/user = usr
	var/client/user_client = user?.client
	if(!user_client?.click_intercept)
		return
	if(!hascall(user_client.click_intercept, "InterceptMouseEntered"))
		return
	call(user_client.click_intercept, "InterceptMouseEntered")(user, src, location, control, params)
