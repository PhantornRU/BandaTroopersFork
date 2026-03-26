/obj/structure/machinery/newscaster
	name = "newscaster"
	desc = "A standard Weyland-Yutani-licensed newsfeed handler for use in commercial space stations. All the news you absolutely have no use for, in one place!"
	icon = 'icons/obj/structures/machinery/terminals.dmi'
	icon_state = "newscaster_normal"
	anchored = TRUE

/obj/structure/machinery/newscaster/security_unit
	name = "Security Newscaster"

/obj/item/newspaper
	name = "newspaper"
	desc = "Газета, в которой почти нет ничего интересного. Может, именно это подразделение станет следующей историей, но счастливой она будет только в ваших руках." // SS220 EDIT: HALO flavor migrated from modular late override
	icon = 'icons/obj/items/paper.dmi'
	icon_state = "newspaper"
	w_class = SIZE_TINY //Let's make it fit in trashbags!
	attack_verb = list("bapped")
