/datum/modpack/world_edit
	name = "world edit modpack"
	desc = "Набор инструментов World Edit для игровых мастеров."
	author = "PhantomRU"

/datum/modpack/world_edit/pre_initialize()
	. = ..()

/datum/modpack/world_edit/initialize()
	. = ..()

/datum/modpack/world_edit/proc/register_admin_verb(list/target_list, verb_path)
	if(!islist(target_list) || !verb_path)
		return
	if(!(verb_path in target_list))
		target_list += verb_path

/datum/modpack/world_edit/post_initialize()
	. = ..()
	register_admin_verb(GLOB.admin_verbs_minor_event, /client/proc/open_world_edit_panel)
	register_admin_verb(GLOB.admin_verbs_debug, /client/proc/open_world_edit_panel)
