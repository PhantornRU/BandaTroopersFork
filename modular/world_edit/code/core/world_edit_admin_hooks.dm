
/client/proc/open_world_edit_panel()
	set name = "World Edit Panel"
	set category = "Game Master"

	if(!check_rights(R_DEBUG))
		return

	var/datum/world_edit_manager/manager = GLOB.world_edit_managers_by_client[src]
	if(QDELETED(manager))
		manager = null

	if(!manager)
		manager = new(src)
		GLOB.world_edit_managers_by_client[src] = manager

	manager.tgui_interact(mob)
