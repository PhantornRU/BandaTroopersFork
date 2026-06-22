/// Glitch-эффект: меняет alpha/color fullscreen на короткое время.
/proc/apply_glitch_effect(client/C, intensity = 1)
	if(!istype(C) || !C.mob)
		return
	var/atom/movable/screen/fullscreen/black/black = C.mob.overlay_fullscreen(ROUND_CINEMATICS_FULLSCREEN_OUTRO_BLACK, /atom/movable/screen/fullscreen/black)
	if(black)
		black.alpha = min(255, 80 + intensity * 60)
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(reset_glitch_effect), WEAKREF(C)), 0.3 SECONDS)

/proc/reset_glitch_effect(datum/weakref/client_ref)
	var/client/C = client_ref?.resolve()
	if(!istype(C) || !C.mob)
		return
	var/atom/movable/screen/fullscreen/black/black = C.mob.overlay_fullscreen(ROUND_CINEMATICS_FULLSCREEN_OUTRO_BLACK, /atom/movable/screen/fullscreen/black)
	if(black)
		black.alpha = 255

/// Flicker-эффект: быстрое мигание fullscreen.
/proc/apply_flicker_effect(client/C)
	if(!istype(C) || !C.mob)
		return
	var/atom/movable/screen/fullscreen/black/black = C.mob.overlay_fullscreen(ROUND_CINEMATICS_FULLSCREEN_OUTRO_BLACK, /atom/movable/screen/fullscreen/black)
	if(!black)
		return
	var/iterations = 3
	for(var/i in 1 to iterations)
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(toggle_flicker_alpha), WEAKREF(C), (i % 2 == 1) ? 128 : 255), i * 0.15 SECONDS)

/proc/toggle_flicker_alpha(datum/weakref/client_ref, new_alpha)
	var/client/C = client_ref?.resolve()
	if(!istype(C) || !C.mob)
		return
	var/atom/movable/screen/fullscreen/black/black = C.mob.overlay_fullscreen(ROUND_CINEMATICS_FULLSCREEN_OUTRO_BLACK, /atom/movable/screen/fullscreen/black)
	if(black)
		black.alpha = new_alpha

/// Power-on эффект: постепенное появление из помех.
/proc/apply_power_on_effect(client/C)
	if(!istype(C) || !C.mob)
		return
	var/atom/movable/screen/fullscreen/black/black = C.mob.overlay_fullscreen(ROUND_CINEMATICS_FULLSCREEN_INTRO_BLACK, /atom/movable/screen/fullscreen/black)
	if(!black)
		return
	black.alpha = 255
	var/steps = 10
	for(var/i in 1 to steps)
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(power_on_fade_step), WEAKREF(C), 255 - (i * 25)), i * 0.1 SECONDS)

/proc/power_on_fade_step(datum/weakref/client_ref, new_alpha)
	var/client/C = client_ref?.resolve()
	if(!istype(C) || !C.mob)
		return
	var/atom/movable/screen/fullscreen/black/black = C.mob.overlay_fullscreen(ROUND_CINEMATICS_FULLSCREEN_INTRO_BLACK, /atom/movable/screen/fullscreen/black)
	if(black)
		black.alpha = max(0, new_alpha)
