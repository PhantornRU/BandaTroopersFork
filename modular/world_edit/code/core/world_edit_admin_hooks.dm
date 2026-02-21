
/client/proc/open_world_edit_panel()
	set name = "World Edit Panel"
	set category = "Game Master.HumanAI"

	if(!check_rights(R_DEBUG))
		return

	var/datum/world_edit_manager/manager = GLOB.world_edit_managers_by_client[src]
	if(QDELETED(manager))
		manager = null

	if(!manager)
		manager = new(src)
		GLOB.world_edit_managers_by_client[src] = manager

	manager.tgui_interact(mob)


/// Добавляем verb панели World Edit в общий цикл админских verb'ов,
/// не изменяя исходные legacy-файлы со списками verb'ов.
/client/proc/add_admin_verbs()
	. = ..()
	if(CLIENT_HAS_RIGHTS(src, R_DEBUG))
		add_verb(src, /client/proc/open_world_edit_panel)

/client/proc/remove_admin_verbs()
	. = ..()
	remove_verb(src, /client/proc/open_world_edit_panel)
