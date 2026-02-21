/// Добавляем verb панели World Edit в общий цикл админских verb'ов,
/// не изменяя исходные legacy-файлы со списками verb'ов.
/client/proc/add_admin_verbs()
	. = ..()
	if(CLIENT_HAS_RIGHTS(src, R_DEBUG))
		add_verb(src, /client/proc/open_world_edit_panel)

/client/proc/remove_admin_verbs()
	. = ..()
	remove_verb(src, /client/proc/open_world_edit_panel)
