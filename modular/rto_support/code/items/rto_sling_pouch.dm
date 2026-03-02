/// Dedicated sling pouch paired with one RTO binocular set.
/obj/item/storage/pouch/sling/rto
	name = "RTO sling pouch"
	desc = "A dedicated sling pouch for a paired set of RTO binoculars."
	can_hold = list(/obj/item/device/binoculars/rto)
	var/obj/item/device/binoculars/rto/paired_binocular

/obj/item/storage/pouch/sling/rto/Destroy()
	if(paired_binocular?.paired_pouch == src)
		paired_binocular.paired_pouch = null
	paired_binocular = null
	return ..()

/obj/item/storage/pouch/sling/rto/attack_self(mob/user)
	. = ..()
	if(user)
		to_chat(user, SPAN_NOTICE("[src] is locked to its paired binoculars."))
	return .

/obj/item/storage/pouch/sling/rto/empty(mob/user)
	if(user)
		to_chat(user, SPAN_NOTICE("[src] will not release its paired binoculars manually."))
	return

/obj/item/storage/pouch/sling/rto/can_be_inserted(obj/item/item, mob/user, stop_messages = FALSE)
	if(!istype(item, /obj/item/device/binoculars/rto))
		if(!stop_messages && user)
			to_chat(user, SPAN_WARNING("[src] only accepts its paired RTO binoculars."))
		return FALSE

	var/obj/item/device/binoculars/rto/binoculars = item
	if(paired_binocular && paired_binocular != binoculars)
		if(!stop_messages && user)
			to_chat(user, SPAN_WARNING("[src] is already paired to another set of binoculars."))
		return FALSE
	if(binoculars.paired_pouch && binoculars.paired_pouch != src)
		if(!stop_messages && user)
			to_chat(user, SPAN_WARNING("[binoculars] are already paired to another sling pouch."))
		return FALSE

	return ..()

/obj/item/storage/pouch/sling/rto/_item_insertion(obj/item/item, prevent_warning = FALSE, mob/user)
	var/obj/item/device/binoculars/rto/binoculars = item
	if(istype(binoculars))
		pair_with_binocular(binoculars)
	..()

/obj/item/storage/pouch/sling/rto/unsling()
	return FALSE

/obj/item/storage/pouch/sling/rto/dropped(mob/user)
	. = ..()
	if(!paired_binocular || paired_binocular.loc == src || !user)
		return
	if(paired_binocular == user.l_hand || paired_binocular == user.r_hand)
		if(handle_item_insertion(paired_binocular, TRUE, user))
			to_chat(user, SPAN_NOTICE("[paired_binocular] snap back into [src]."))

/obj/item/storage/pouch/sling/rto/proc/pair_with_binocular(obj/item/device/binoculars/rto/binoculars)
	if(!istype(binoculars))
		return FALSE
	if(paired_binocular && paired_binocular != binoculars)
		return FALSE
	paired_binocular = binoculars
	if(binoculars.paired_pouch != src)
		binoculars.pair_with_pouch(src)
	return TRUE

/proc/build_rto_support_binocular_kit(atom/location)
	if(!location)
		return null
	var/obj/item/storage/pouch/sling/rto/pouch = new(location)
	var/obj/item/device/binoculars/rto/binoculars = new(location)
	if(!pouch.pair_with_binocular(binoculars))
		qdel(binoculars)
		qdel(pouch)
		return null
	pouch.handle_item_insertion(binoculars, TRUE)
	return pouch
