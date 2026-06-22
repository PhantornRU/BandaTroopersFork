/datum/round_cinematics_sequence/round_outro
	/// Кэшированный цвет header из outcome
	var/cached_header_color = "#88CCFF"
	/// Кэшированный цвет accent из outcome
	var/cached_accent_color = "#88CCFF"
	/// Кэшированная фраза исхода
	var/cached_outcome_phrase = ""

/datum/round_cinematics_sequence/round_outro/get_header_html()
	var/style_open = "<span class='langchat' style='text-align:center; font-family:\"VCR OSD Mono\", monospace; font-size:10pt; color:[cached_header_color];'>"
	var/style_close = "</span>"
	. = "[style_open]┌ BW &#9608; AFTER-ACTION REPORT ┐<br>CLASSIFIED &#9608; OPERATION SUMMARY"
	if(length(cached_outcome_phrase))
		. += "<br><span style='font-size:10pt;font-weight:bold;'>[html_encode(cached_outcome_phrase)]</span>"
	. += "[style_close]"

/datum/round_cinematics_sequence/round_outro/get_footer_html()
	var/style_open = "<span class='langchat' style='text-align:center; font-family:\"VCR OSD Mono\", monospace; font-size:9pt; color:[cached_accent_color];'>"
	var/style_close = "</span>"
	var/final_phrase = ""
	if(length(cached_outcome_phrase))
		switch(cached_outcome_phrase)
			if("MARINE VICTORY", "ПОБЕДА")
				final_phrase = "ОПЕРАЦИЯ УСПЕШНО ЗАВЕРШЕНА. ВОЗВРАЩЕНИЕ НА БАЗУ."
			if("MARINE DEFEAT", "ПОРАЖЕНИЕ")
				final_phrase = "КРИТИЧЕСКИЕ ПОТЕРИ. ЭКСТРЕННАЯ ЭВАКУАЦИЯ."
			if("INCONCLUSIVE", "НЕОПРЕДЕЛЁННЫЙ ИСХОД")
				final_phrase = "СТАТУС НЕОПРЕДЕЛЁН. ОЖИДАНИЕ ДАЛЬНЕЙШИХ УКАЗАНИЙ."
			else
				final_phrase = "КОНЕЦ ПЕРЕДАЧИ."
	. = "[style_open]└ > END OF REPORT ┘<br>\[ARCHIVE: ACTIVE\] \[CHANNEL: SECURE\]"
	if(length(final_phrase))
		. += "<br><span style='font-size:8pt;font-weight:bold;'>[html_encode(final_phrase)]</span>"
	. += "[style_close]"

/datum/round_cinematics_sequence/round_outro/New(datum/round_cinematics_outro_context/context)
	..()
	if(!context)
		return

	// Cache outcome colors for header/footer
	if(context.outcome)
		cached_header_color = context.outcome.header_color
		cached_accent_color = context.outcome.accent_color
		cached_outcome_phrase = context.outcome.outcome_phrase

	phases = list()

	// Glitch phase for defeat/intense outcomes
	if(context.outcome && context.outcome.glitch_intensity > 0.2)
		phases += new /datum/round_cinematics_phase
		var/datum/round_cinematics_phase/glitch = phases[phases.len]
		glitch.name = "glitch"
		glitch.raw_html = "<span class='langchat' style='text-align:center; font-family:\"VCR OSD Mono\", monospace; font-size:14pt; color:#FF4444;'>█▓▒░ SIGNAL INTERFERENCE ░▒▓█<br><span style='font-size:8pt;'>&#91;TRANSMISSION CORRUPTED&#93;</span></span>"
		glitch.fullscreen_specs = list(
			list("category" = ROUND_CINEMATICS_FULLSCREEN_OUTRO_BLACK, "type" = /atom/movable/screen/fullscreen/black, "severity" = 0),
			list("category" = ROUND_CINEMATICS_FULLSCREEN_OUTRO_CRT, "type" = /atom/movable/screen/fullscreen/crt, "severity" = 0)
		)
		glitch.display_time = 1 SECONDS
		glitch.fade_out_time = 0.3 SECONDS
		glitch.letters_per_update = 8
		glitch.play_delay = 0.1

	// Outcome splash phase
	phases += new /datum/round_cinematics_phase
	var/datum/round_cinematics_phase/splash = phases[phases.len]
	splash.name = "outcome_splash"
	var/splash_text = ""
	var/splash_color = "#FFFFFF"
	if(context.outcome)
		switch(context.outcome.id)
			if(ROUND_CINEMATICS_OUTCOME_MARINE_VICTORY)
				splash_text = "ОПЕРАЦИЯ ЗАВЕРШЕНА: ПОБЕДА"
				splash_color = "#44FF44"
			if(ROUND_CINEMATICS_OUTCOME_MARINE_DEFEAT)
				splash_text = "ОПЕРАЦИЯ ЗАВЕРШЕНА: ПОРАЖЕНИЕ"
				splash_color = "#FF4444"
			if(ROUND_CINEMATICS_OUTCOME_INCONCLUSIVE)
				splash_text = "ОПЕРАЦИЯ ЗАВЕРШЕНА: НЕОПРЕДЕЛЁННЫЙ ИСХОД"
				splash_color = "#FFAA44"
			else
				splash_text = "ОПЕРАЦИЯ ЗАВЕРШЕНА"
				splash_color = "#DCE6F6"
	splash.raw_html = "<span class='langchat' style='text-align:center; font-family:\"VCR OSD Mono\", monospace; font-size:18pt; font-weight:bold; color:[splash_color];'>[html_encode(splash_text)]</span>"
	splash.fullscreen_specs = list(
		list("category" = ROUND_CINEMATICS_FULLSCREEN_OUTRO_BLACK, "type" = /atom/movable/screen/fullscreen/black, "severity" = 0),
		list("category" = ROUND_CINEMATICS_FULLSCREEN_OUTRO_CRT, "type" = /atom/movable/screen/fullscreen/crt, "severity" = 0)
	)
	splash.display_time = 2.5 SECONDS
	splash.fade_out_time = 0.5 SECONDS
	splash.letters_per_update = 2
	splash.play_delay = 0.15

	for(var/page_index = 1, page_index <= context.get_report_page_count(), page_index++)
		phases += new /datum/round_cinematics_phase
		var/datum/round_cinematics_phase/page = phases[phases.len]
		page.name = "report_[page_index]"
		page.raw_html = context.get_report_page(page_index)
		page.fullscreen_specs = list(
			list("category" = ROUND_CINEMATICS_FULLSCREEN_OUTRO_BLACK, "type" = /atom/movable/screen/fullscreen/black, "severity" = 0),
			list("category" = ROUND_CINEMATICS_FULLSCREEN_OUTRO_CRT, "type" = /atom/movable/screen/fullscreen/crt, "severity" = 0)
		)
		page.display_time = 2 SECONDS
		page.fade_out_time = 0.75 SECONDS
		page.letters_per_update = 4
		page.play_delay = 0.3
		// Sound: terminal_on for first page, terminal_off for last (or terminal_alert for defeat)
		if(page_index == 1)
			page.sound = 'sound/machines/terminal_on.ogg'
			page.sound_volume = 40
		else if(page_index == context.get_report_page_count())
			if(context.outcome && context.outcome.id == ROUND_CINEMATICS_OUTCOME_MARINE_DEFEAT)
				page.sound = 'sound/machines/terminal_alert.ogg'
				page.sound_volume = 45
			else
				page.sound = 'sound/machines/terminal_off.ogg'
				page.sound_volume = 40
