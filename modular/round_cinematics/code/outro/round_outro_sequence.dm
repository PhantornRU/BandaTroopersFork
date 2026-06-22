/datum/round_cinematics_sequence/round_outro

/datum/round_cinematics_sequence/round_outro/New(datum/round_cinematics_outro_context/context)
	..()
	if(!context)
		return

	phases = list()
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

