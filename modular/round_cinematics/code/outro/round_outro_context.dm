/datum/round_cinematics_outro_context
	var/datum/game_mode/mode
	var/datum/round_cinematics_outcome/outcome
	var/preview = FALSE
	var/client/preview_client = null
	var/map_name = "НЕИЗВЕСТНАЯ ЛОКАЦИЯ"
	var/operation_name = "НЕИЗВЕСТНАЯ ОПЕРАЦИЯ"
	var/list/summary_lines = list()
	var/list/participant_entries = list()
	var/list/report_pages = list()

/datum/round_cinematics_outro_context/New(datum/game_mode/mode, datum/round_cinematics_outcome/outcome, preview = FALSE, client/preview_client = null)
	..()
	src.mode = mode
	src.outcome = outcome ? outcome.copy() : new /datum/round_cinematics_outcome(ROUND_CINEMATICS_OUTCOME_INCONCLUSIVE, FALSE)
	src.preview = preview
	src.preview_client = preview_client

/datum/round_cinematics_outro_context/proc/build()
	map_name = SSmapping.configs[GROUND_MAP]?.map_name || SSmapping.configs[SHIP_MAP]?.map_name || "НЕИЗВЕСТНАЯ ЛОКАЦИЯ"
	operation_name = round_cinematics_safe_text(mode?.name, "НЕИЗВЕСТНАЯ ОПЕРАЦИЯ")

	summary_lines = list(
		"ОПЕРАЦИЯ: [html_encode(operation_name)]",
		"ЛОКАЦИЯ: [html_encode(map_name)]",
		"ИСХОД: [html_encode(outcome?.title || "НЕОПРЕДЕЛЕННЫЙ ИСХОД")]",
		"ДЕТАЛИ: [html_encode(outcome?.detail || "НЕОПРЕДЕЛЕННЫЙ ИСХОД")]",
		"РЕЖИМ: [html_encode(outcome?.is_override ? "АДМИН-ОВЕРРАЙД" : "АВТО")]"
	)

	build_participants()
	build_pages()
	return src

/datum/round_cinematics_outro_context/proc/build_participants()
	participant_entries = list()
	for(var/mob/living/carbon/human/player as anything in GLOB.human_mob_list)
		if(!player || (!player.client && !player.mind))
			continue

		var/status = round_cinematics_mob_status_label(player)
		var/role = round_cinematics_safe_text(round_cinematics_human_role(player), "НЕИЗВЕСТНО")

		var/reason = "НЕ ТРЕБУЕТСЯ"
		if(player.stat == DEAD)
			reason = round_cinematics_human_death_reason(player)

		var/list/entry_lines = list(
			"<b>[html_encode(round_cinematics_safe_text(player.real_name, "НЕИЗВЕСТНО"))]</b>",
			"РОЛЬ: [html_encode(role)]",
			"СОСТОЯНИЕ: [html_encode(status)]",
			"ПРИЧИНА: [html_encode(reason)]"
		)
		participant_entries += list(entry_lines.Join("<br>"))

/datum/round_cinematics_outro_context/proc/build_pages()
	report_pages = list()
	report_pages += list(round_cinematics_outro_render_summary_page(src))
	report_pages += list(round_cinematics_outro_render_status_page(src))

	var/list/paginated_participants = round_cinematics_paginate(participant_entries, ROUND_CINEMATICS_OUTRO_PAGE_ROWS)
	var/page_count = length(paginated_participants)
	for(var/page_index = 1, page_index <= page_count, page_index++)
		var/list/page_entries = paginated_participants[page_index]
		report_pages += list(round_cinematics_outro_render_participant_page(page_entries, page_index, page_count))

	if(!length(report_pages))
		report_pages = list(round_cinematics_html_block("ОПЕРАЦИОННЫЙ ОТЧЕТ", "НЕТ ДАННЫХ", "#E4EAF8"))

/datum/round_cinematics_outro_context/proc/get_report_page_count()
	return length(report_pages)

/datum/round_cinematics_outro_context/proc/get_report_page(page_index)
	if(!report_pages || !length(report_pages))
		return null
	page_index = clamp(page_index, 1, length(report_pages))
	return report_pages[page_index]
