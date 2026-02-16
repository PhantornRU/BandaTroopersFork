#define ARACHNID_SOUND_WEIGHT_DEFAULT 100
#define ARACHNID_SOUND_WEIGHT_2_SEC 40
#define ARACHNID_SOUND_WEIGHT_5_SEC 15
#define ARACHNID_SOUND_COOLDOWN_SHORT 3 SECONDS
#define ARACHNID_SOUND_COOLDOWN_MEDIUM 6 SECONDS
#define ARACHNID_SOUND_COOLDOWN_LONG 10 SECONDS

/mob/living/carbon/xenomorph
	var/next_modular_speaking_sound = 0

/mob/living/carbon/xenomorph/proc/modular_get_sound_volume(base_volume)
	return base_volume

/mob/living/carbon/xenomorph/proc/modular_get_sound_pick_weight(sound_path)
	return ARACHNID_SOUND_WEIGHT_DEFAULT

/mob/living/carbon/xenomorph/proc/modular_get_sound_cooldown(sound_path, default_cooldown)
	return default_cooldown

/mob/living/carbon/xenomorph/proc/modular_get_sound_play_chance(event_key, sound_path)
	return 100

/mob/living/carbon/xenomorph/proc/modular_should_play_sound(event_key, sound_path)
	var/chance = clamp(round(modular_get_sound_play_chance(event_key, sound_path)), 0, 100)
	if(chance >= 100)
		return TRUE
	if(chance <= 0)
		return FALSE
	return prob(chance)

/mob/living/carbon/xenomorph/proc/pick_weighted_sound(list/bank)
	if(!length(bank))
		return null

	var/total_weight = 0
	var/list/sound_weights = list()
	for(var/sound_path in bank)
		var/weight = max(0, modular_get_sound_pick_weight(sound_path))
		if(weight <= 0)
			continue
		sound_weights[sound_path] = weight
		total_weight += weight

	if(total_weight <= 0)
		return null

	var/roll = rand(1, total_weight)
	var/current_weight = 0
	for(var/sound_path in sound_weights)
		current_weight += sound_weights[sound_path]
		if(roll <= current_weight)
			return sound_path

	return null

/mob/living/carbon/xenomorph/proc/pick_sound_or_default(list/bank, default_sound)
	var/picked_sound = pick_weighted_sound(bank)
	return picked_sound ? picked_sound : default_sound

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

/mob/living/carbon/xenomorph/proc/modular_say()
	playsound(loc, speaking_noise, 25, 1)

/mob/living/carbon/xenomorph/arachnid/modular_get_sound_volume(base_volume)
	return max(1, round(base_volume / 2.5))

/mob/living/carbon/xenomorph/arachnid/modular_get_sound_pick_weight(sound_path)
	var/sound_text = "[sound_path]"
	if(findtext(sound_text, "_5_sec_"))
		return ARACHNID_SOUND_WEIGHT_5_SEC
	if(findtext(sound_text, "_2_sec_"))
		return ARACHNID_SOUND_WEIGHT_2_SEC
	return ..()

/mob/living/carbon/xenomorph/arachnid/modular_get_sound_cooldown(sound_path, default_cooldown)
	var/sound_text = "[sound_path]"
	if(findtext(sound_text, "_5_sec_"))
		return max(default_cooldown, ARACHNID_SOUND_COOLDOWN_LONG)
	if(findtext(sound_text, "_2_sec_"))
		return max(default_cooldown, ARACHNID_SOUND_COOLDOWN_MEDIUM)
	return max(default_cooldown, ARACHNID_SOUND_COOLDOWN_SHORT)

/mob/living/carbon/xenomorph/arachnid/proc/get_sound_length_tier(sound_path)
	var/sound_text = "[sound_path]"
	if(findtext(sound_text, "_5_sec_"))
		return 5
	if(findtext(sound_text, "_2_sec_"))
		return 2
	return 1

/mob/living/carbon/xenomorph/arachnid/modular_get_sound_play_chance(event_key, sound_path)
	var/key = lowertext("[event_key]")
	var/length_tier = get_sound_length_tier(sound_path)

	switch(key)
		if("death", "pounce")
			return 100
		if("spawn")
			return 10
		if("prime")
			return 25
		if("speaking", "emote")
			switch(length_tier)
				if(5)
					return 8
				if(2)
					return 15
				else
					return 25
		if("combat")
			switch(length_tier)
				if(5)
					return 6
				if(2)
					return 12
				else
					return 20

	return ..()

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
	if(spawn_sound && modular_should_play_sound("spawn", spawn_sound))
		playsound(src, spawn_sound, modular_get_sound_volume(45), FALSE)

/mob/living/carbon/xenomorph/arachnid/modular_say()
	if(!speaking_noise || world.time < next_modular_speaking_sound)
		return

	var/speaking_sound = modular_sound_pick_speaking(speaking_noise)
	if(!speaking_sound)
		return

	if(!modular_should_play_sound("speaking", speaking_sound))
		return

	playsound(loc, speaking_sound, modular_get_sound_volume(25), 1)
	next_modular_speaking_sound = world.time + modular_get_sound_cooldown(speaking_sound, 2 SECONDS)

/datum/emote/living/carbon/xeno/get_sound(mob/living/user)
	. = ..()
	if(ispredalien(user) && predalien_sound)
		. = predalien_sound
	if(islarva(user) && larva_sound)
		. = larva_sound

	var/base_volume = initial(volume)
	var/base_audio_cooldown = initial(audio_cooldown)
	volume = base_volume
	audio_cooldown = base_audio_cooldown

	var/mob/living/carbon/xenomorph/xeno_user = user
	if(!istype(xeno_user))
		return

	. = xeno_user.modular_sound_pick_emote(key, .)
	if(!.)
		return

	if(!xeno_user.modular_should_play_sound("emote", .))
		. = null
		return

	volume = xeno_user.modular_get_sound_volume(base_volume)
	audio_cooldown = xeno_user.modular_get_sound_cooldown(., base_audio_cooldown)

#undef ARACHNID_SOUND_WEIGHT_DEFAULT
#undef ARACHNID_SOUND_WEIGHT_2_SEC
#undef ARACHNID_SOUND_WEIGHT_5_SEC
#undef ARACHNID_SOUND_COOLDOWN_SHORT
#undef ARACHNID_SOUND_COOLDOWN_MEDIUM
#undef ARACHNID_SOUND_COOLDOWN_LONG
