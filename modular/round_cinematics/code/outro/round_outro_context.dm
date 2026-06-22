/datum/round_cinematics_outro_context
	var/datum/game_mode/mode
	var/datum/round_cinematics_outcome/outcome
	var/preview = FALSE
	var/client/preview_client = null
	var/map_name = "НЕИЗВЕСТНАЯ ЛОКАЦИЯ"
	var/operation_name = "НЕИЗВЕСТНАЯ ОПЕРАЦИЯ"
	var/list/summary_lines = list()
	/// Typed records: list of /datum/round_cinematics_participant_record
	var/list/participant_records = list()
	/// Typed statistics: /datum/round_cinematics_statistics
	var/datum/round_cinematics_statistics/statistics = null
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
	build_statistics()
	build_pages()
	return src

/datum/round_cinematics_outro_context/proc/build_participants()
	participant_records = list()
	for(var/mob/living/carbon/human/player as anything in GLOB.human_mob_list)
		if(!player || (!player.client && !player.mind))
			continue

		var/datum/round_cinematics_participant_record/record = new
		record.name = round_cinematics_safe_text(player.real_name, "НЕИЗВЕСТНО")
		record.rank = round_cinematics_human_rank(player)
		record.role = round_cinematics_safe_text(round_cinematics_human_role(player), "НЕИЗВЕСТНО")
		record.squad = round_cinematics_human_squad(player)
		record.faction = round_cinematics_safe_text(player.faction, "UNKNOWN")
		record.status = round_cinematics_mob_status_label(player)
		record.death_reason = (player.stat == DEAD) ? round_cinematics_human_death_reason_extended_ru(player) : "НЕ ТРЕБУЕТСЯ"
		record.has_client = !!player.client
		record.has_mind = !!player.mind
		record.is_player = !!(player.client && player.mind)

		participant_records += record

/datum/round_cinematics_outro_context/proc/build_statistics()
	statistics = new /datum/round_cinematics_statistics
	statistics.build_from_records(participant_records)

/datum/round_cinematics_outro_context/proc/build_pages()
	report_pages = list()
	report_pages += list(round_cinematics_outro_render_summary_page(src))
	report_pages += list(round_cinematics_outro_render_status_page(src))

	// Split records into personnel and destruction
	var/list/personnel_records = list()
	var/list/destruction_records = list()
	for(var/datum/round_cinematics_participant_record/record as anything in participant_records)
		if(!istype(record))
			continue
		if(record.is_player)
			personnel_records += record
		else
			destruction_records += record

	// Personnel section
	var/list/paginated_personnel = round_cinematics_paginate(personnel_records, ROUND_CINEMATICS_OUTRO_PAGE_ROWS)
	var/personnel_page_count = length(paginated_personnel)
	for(var/page_index = 1, page_index <= personnel_page_count, page_index++)
		var/list/page_entries = paginated_personnel[page_index]
		report_pages += list(round_cinematics_outro_render_personnel_page(page_entries, page_index, personnel_page_count))

	// Destruction section
	var/list/paginated_destruction = round_cinematics_paginate(destruction_records, ROUND_CINEMATICS_OUTRO_PAGE_ROWS)
	var/destruction_page_count = length(paginated_destruction)
	for(var/page_index = 1, page_index <= destruction_page_count, page_index++)
		var/list/page_entries = paginated_destruction[page_index]
		report_pages += list(round_cinematics_outro_render_destruction_page(page_entries, page_index, destruction_page_count))

	if(!length(report_pages))
		report_pages = list(round_cinematics_html_block("ОПЕРАЦИОННЫЙ ОТЧЕТ", "НЕТ ДАННЫХ", "#E4EAF8"))

/datum/round_cinematics_outro_context/proc/get_report_page_count()
	return length(report_pages)

/datum/round_cinematics_outro_context/proc/get_report_page(page_index)
	if(!report_pages || !length(report_pages))
		return null
	page_index = clamp(page_index, 1, length(report_pages))
	return report_pages[page_index]
