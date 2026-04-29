// EVERYTHING ELSE (ALSO LAZY)

/atom/movable/screen/action_button/covenant
	icon = 'modular/halo/icons/halo/mob/hud/actions.dmi'
	icon_state = "template"

/datum/action/item_action/toggle_shield
	name = "Toggle Shield"
	action_icon_state = "shield"
	icon_file = 'modular/halo/icons/halo/mob/hud/actions.dmi'

/datum/action/item_action/toggle_shield/New(mob/living/user, obj/item/holder)
	..()
	name = "Toggle Shield"
	button.name = name
	button.overlays.Cut()
	button.icon = 'modular/halo/icons/halo/mob/hud/actions.dmi'
	var/image/IMG = image('modular/halo/icons/halo/mob/hud/actions.dmi', button, "shield")
	button.overlays += IMG

/datum/action/item_action/toggle_shield/can_use_action()
	var/mob/living/carbon/human/H = owner
	if(istype(H) && !H.is_mob_incapacitated() && holder_item == H.wear_suit)
		return TRUE

/datum/action/item_action/toggle_shield/action_activate()
	. = ..()
	var/obj/item/clothing/suit/marine/shielded/shield = holder_item
	shield.toggle_shield()

/datum/action/human_action/activable/covenant
	name = "Covenant Actions"
	icon_file = 'modular/halo/icons/halo/mob/hud/actions.dmi'
	button_icon_state = "template"
	var/active = FALSE

/datum/action/human_action/activable/covenant/sangheili_kick
	name = "kick"
	icon_file = 'modular/halo/icons/halo/mob/hud/actions.dmi'
	action_icon_state = "kick"
	var/cd_kick = 15 SECONDS
	var/cd_stomp = 25 SECONDS
	var/cd_miss = 3 SECONDS
	var/kick_damage = 20
	var/stomp_damage = 80
	var/fling_distance = 2

/datum/action/human_action/activable/covenant/sangheili_kick/New(mob/living/user, obj/item/holder)
	..()
	name = "kick"
	button.icon = icon_file
	button.name = name
	button.overlays.Cut()
	var/image/IMG = image('modular/halo/icons/halo/mob/hud/actions.dmi', button, "kick")
	button.overlays += IMG
	update_button_icon()

/datum/action/human_action/activable/covenant/sangheili_kick/use_ability(atom/target, mob/living/carbon/owner)
	var/mob/living/carbon/acting_owner = owner
	if(!istype(acting_owner))
		acting_owner = src.owner

	if(!istype(acting_owner) || !target)
		return

	if(!acting_owner.Adjacent(target))
		return

	if(acting_owner.body_position == LYING_DOWN)
		return

	if(target == acting_owner)
		return

	var/mob/living/carbon/human/human_target = target

	if(!action_cooldown_check())
		to_chat(acting_owner, SPAN_WARNING("You can't do that yet..."))
		return

	if(!ishuman(human_target))
		acting_owner.visible_message(SPAN_WARNING ("[acting_owner] kicks at the air."), SPAN_WARNING ("You kick at the air..."))
		acting_owner.face_atom(target)
		acting_owner.animation_attack_on(target)
		playsound(target, 'sound/effects/alien_tail_swipe2.ogg', 25)
		enter_cooldown(cd_miss)
		return

	if(human_target.body_position == LYING_DOWN)
		acting_owner.visible_message(SPAN_WARNING ("[acting_owner] prepares to stomp down on [target]!"), SPAN_WARNING ("You raise your foot, preparing to stomp on [target]!"))
		acting_owner.face_atom(target)
		if(!do_after(acting_owner, 4 SECONDS, INTERRUPT_NO_NEEDHAND, BUSY_ICON_HOSTILE, target, INTERRUPT_MOVED, BUSY_ICON_HOSTILE))
			acting_owner.visible_message(SPAN_WARNING ("[acting_owner] is interrupted!"), SPAN_WARNING ("You're interrupted!"))
			return
		acting_owner.animation_attack_on(target)
		acting_owner.flick_attack_overlay(target, "punch")
		acting_owner.face_atom(target)
		human_target.apply_armoured_damage(stomp_damage, ARMOR_MELEE, BRUTE, "chest")
		playsound(target, 'sound/effects/alien_tail_swipe2.ogg', 25)
		playsound(target, "swing_hit", 25)
		human_target.make_jittery(2 SECONDS)
		enter_cooldown(cd_stomp)
		return

	else
		var/facing = get_dir(acting_owner, target)
		acting_owner.visible_message(SPAN_WARNING ("[acting_owner] effortlessly kicks [target] down."), SPAN_WARNING ("You effortlessly kick [target] down."))
		human_target.apply_armoured_damage(kick_damage, ARMOR_MELEE, BRUTE, "chest")
		playsound(target, "swing_hit", 25)
		acting_owner.face_atom(target)
		acting_owner.animation_attack_on(target)
		acting_owner.halo_throw_carbon(target, facing, fling_distance)
		acting_owner.flick_attack_overlay(target, "punch")
		enter_cooldown(cd_kick)
	return
