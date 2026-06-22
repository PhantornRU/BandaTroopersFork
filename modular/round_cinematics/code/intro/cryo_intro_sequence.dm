/datum/round_cinematics_sequence/cryo_intro

/datum/round_cinematics_sequence/cryo_intro/New(datum/round_cinematics_intro_context/context)
	..()
	if(!context)
		return

	phases = list()

	phases += new /datum/round_cinematics_phase
	var/datum/round_cinematics_phase/boot = phases[phases.len]
	boot.name = "boot"
	boot.raw_html = context.build_boot_text()
	boot.fullscreen_specs = list(
		list("category" = ROUND_CINEMATICS_FULLSCREEN_INTRO_BLACK, "type" = /atom/movable/screen/fullscreen/black, "severity" = 0),
		list("category" = ROUND_CINEMATICS_FULLSCREEN_INTRO_CRT, "type" = /atom/movable/screen/fullscreen/crt, "severity" = 0)
	)
	boot.sound = 'sound/effects/cryo_beep.ogg'
	boot.sound_volume = 45
	boot.display_time = 2 SECONDS
	boot.fade_out_time = 0.75 SECONDS
	boot.letters_per_update = 3
	boot.play_delay = 0.35

	phases += new /datum/round_cinematics_phase
	var/datum/round_cinematics_phase/personal = phases[phases.len]
	personal.name = "personal"
	personal.raw_html = context.build_personal_text()
	personal.fullscreen_specs = list(
		list("category" = ROUND_CINEMATICS_FULLSCREEN_INTRO_BLACK, "type" = /atom/movable/screen/fullscreen/black, "severity" = 0),
		list("category" = ROUND_CINEMATICS_FULLSCREEN_INTRO_CRT, "type" = /atom/movable/screen/fullscreen/crt, "severity" = 0)
	)
	personal.display_time = 2 SECONDS
	personal.fade_out_time = 0.75 SECONDS
	personal.letters_per_update = 3
	personal.play_delay = 0.35

	for(var/page_index = 1, page_index <= context.get_manifest_page_count(), page_index++)
		phases += new /datum/round_cinematics_phase
		var/datum/round_cinematics_phase/manifest = phases[phases.len]
		manifest.name = "manifest_[page_index]"
		manifest.raw_html = context.build_manifest_text(page_index)
		manifest.fullscreen_specs = list(
			list("category" = ROUND_CINEMATICS_FULLSCREEN_INTRO_BLACK, "type" = /atom/movable/screen/fullscreen/black, "severity" = 0),
			list("category" = ROUND_CINEMATICS_FULLSCREEN_INTRO_CRT, "type" = /atom/movable/screen/fullscreen/crt, "severity" = 0)
		)
		manifest.display_time = 2 SECONDS
		manifest.fade_out_time = 0.75 SECONDS
		manifest.letters_per_update = 3
		manifest.play_delay = 0.35

