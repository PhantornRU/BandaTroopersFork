/datum/modpack/world_edit
	name = "world edit modpack"
	desc = "Набор инструментов World Edit для игровых мастеров."
	author = "PhantomRU"

/datum/modpack/world_edit/pre_initialize()
	. = ..()

/datum/modpack/world_edit/initialize()
	. = ..()
	if(world_edit_visual_should_start())
		init_world_edit_visual_workbench()
