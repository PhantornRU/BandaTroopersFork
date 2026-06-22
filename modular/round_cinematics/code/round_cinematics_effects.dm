/// Power-on effect: gradually fades the black fullscreen from full to transparent.
/datum/round_cinematics_session/proc/effect_power_on(duration = 1 SECONDS)
	if(!owner || cleaned_up || !client)
		return
	var/atom/movable/screen/fullscreen/black/black = owner.overlay_fullscreen(ROUND_CINEMATICS_FULLSCREEN_INTRO_BLACK, /atom/movable/screen/fullscreen/black)
	if(!black)
		return
	black.alpha = 255
	var/steps = max(1, round(duration / (0.1 SECONDS)))
	var/step_alpha = 255 / steps
	for(var/i in 1 to steps)
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(_effect_power_on_step), WEAKREF(client), 255 - (i * step_alpha)), i * (duration / steps))

/proc/_effect_power_on_step(datum/weakref/client_ref, new_alpha)
	var/client/C = client_ref?.resolve()
	if(!istype(C) || !C.mob)
		return
	var/atom/movable/screen/fullscreen/black/black = C.mob.overlay_fullscreen(ROUND_CINEMATICS_FULLSCREEN_INTRO_BLACK, /atom/movable/screen/fullscreen/black)
	if(black)
		black.alpha = max(0, new_alpha)

/// Flicker effect: rapidly toggles the black fullscreen alpha.
/datum/round_cinematics_session/proc/effect_flicker(count = 2, duration = 0.5 SECONDS)
	if(!owner || cleaned_up || !client)
		return
	var/atom/movable/screen/fullscreen/black/black = owner.overlay_fullscreen(ROUND_CINEMATICS_FULLSCREEN_INTRO_BLACK, /atom/movable/screen/fullscreen/black)
	if(!black)
		return
	var/step_delay = duration / (count * 2)
	for(var/i in 1 to count)
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(_effect_flicker_step), WEAKREF(client), 128), (i * 2 - 1) * step_delay)
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(_effect_flicker_step), WEAKREF(client), 255), (i * 2) * step_delay)

/proc/_effect_flicker_step(datum/weakref/client_ref, new_alpha)
	var/client/C = client_ref?.resolve()
	if(!istype(C) || !C.mob)
		return
	var/atom/movable/screen/fullscreen/black/black = C.mob.overlay_fullscreen(ROUND_CINEMATICS_FULLSCREEN_INTRO_BLACK, /atom/movable/screen/fullscreen/black)
	if(black)
		black.alpha = new_alpha

/// Glitch effect: briefly changes alpha/color of the fullscreen.
/datum/round_cinematics_session/proc/effect_glitch(intensity = 0.3, duration = 1 SECONDS)
	if(!owner || cleaned_up || !client)
		return
	var/atom/movable/screen/fullscreen/black/black = owner.overlay_fullscreen(ROUND_CINEMATICS_FULLSCREEN_OUTRO_BLACK, /atom/movable/screen/fullscreen/black)
	if(!black)
		return
	black.alpha = min(255, 80 + intensity * 60)
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(_effect_glitch_reset), WEAKREF(client)), duration)

/proc/_effect_glitch_reset(datum/weakref/client_ref)
	var/client/C = client_ref?.resolve()
	if(!istype(C) || !C.mob)
		return
	var/atom/movable/screen/fullscreen/black/black = C.mob.overlay_fullscreen(ROUND_CINEMATICS_FULLSCREEN_OUTRO_BLACK, /atom/movable/screen/fullscreen/black)
	if(black)
		black.alpha = 255

/// Signal loss effect: brief blackout.
/datum/round_cinematics_session/proc/effect_signal_loss(duration = 0.5 SECONDS)
	if(!owner || cleaned_up || !client)
		return
	var/atom/movable/screen/fullscreen/black/black = owner.overlay_fullscreen(ROUND_CINEMATICS_FULLSCREEN_OUTRO_BLACK, /atom/movable/screen/fullscreen/black)
	if(!black)
		return
	black.alpha = 255
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(_effect_signal_loss_reset), WEAKREF(client)), duration)

/proc/_effect_signal_loss_reset(datum/weakref/client_ref)
	var/client/C = client_ref?.resolve()
	if(!istype(C) || !C.mob)
		return
	var/atom/movable/screen/fullscreen/black/black = C.mob.overlay_fullscreen(ROUND_CINEMATICS_FULLSCREEN_OUTRO_BLACK, /atom/movable/screen/fullscreen/black)
	if(black)
		black.alpha = 0
