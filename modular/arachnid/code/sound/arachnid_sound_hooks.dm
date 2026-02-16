/mob/living/carbon/xenomorph/proc/pick_sound_or_default(list/bank, default_sound)
	if(length(bank))
		return pick(bank)
	return default_sound

/mob/living/carbon/xenomorph/proc/get_emote_bank(emote_key)
	return null

/mob/living/carbon/xenomorph/proc/modular_sound_pick_speaking(default_sound)
	return default_sound

/mob/living/carbon/xenomorph/proc/modular_sound_pick_death(default_sound)
	return default_sound

/mob/living/carbon/xenomorph/proc/modular_sound_pick_emote(emote_key, default_sound)
	return default_sound

/mob/living/carbon/xenomorph/proc/modular_sound_on_spawn()
	return

/mob/living/carbon/xenomorph/arachnid/get_emote_bank(emote_key)
	switch(lowertext(emote_key))
		if("roar")
			return sound_emote_roar
		if("hiss")
			return sound_emote_hiss
		if("growl")
			return sound_emote_growl
		if("needshelp")
			return sound_emote_needshelp
	return null

/mob/living/carbon/xenomorph/arachnid/modular_sound_pick_speaking(default_sound)
	return pick_sound_or_default(sound_speaking, default_sound)

/mob/living/carbon/xenomorph/arachnid/modular_sound_pick_death(default_sound)
	return pick_sound_or_default(sound_death, default_sound)

/mob/living/carbon/xenomorph/arachnid/modular_sound_pick_emote(emote_key, default_sound)
	var/list/emote_bank = get_emote_bank(emote_key)
	return pick_sound_or_default(emote_bank, default_sound)

/mob/living/carbon/xenomorph/arachnid/modular_sound_on_spawn()
	var/spawn_sound = pick_sound_or_default(sound_spawn, null)
	if(spawn_sound)
		playsound(src, spawn_sound, 45, FALSE)


/datum/emote/living/carbon/xeno/get_sound(mob/living/user)
	. = ..()
	var/mob/living/carbon/xenomorph/xeno_user = user
	if(istype(xeno_user))
		. = xeno_user.modular_sound_pick_emote(key, .)

/mob/living/carbon/xenomorph/proc/modular_say()
	playsound(loc, speaking_noise, 25, 1)

/mob/living/carbon/xenomorph/arachnid/modular_say()
	if(speaking_noise)
		var/speaking_sound = modular_sound_pick_speaking(speaking_noise)
		if(speaking_sound)
			playsound(loc, speaking_sound, 25, 1)
