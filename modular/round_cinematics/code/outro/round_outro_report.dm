/proc/round_cinematics_status_color(status)
	switch(status)
		if("active")
			return "#44FF44"
		if("incapacitated")
			return "#FFAA44"
		if("dead")
			return "#FF4444"
		if("missing")
			return "#888888"
		else
			return "#DCE6F6"

/proc/round_cinematics_status_label(status)
	switch(status)
		if("active")
			return "В СТРОЮ"
		if("incapacitated")
			return "РАНЕН"
		if("dead")
			return "ПОГИБ"
		if("missing")
			return "НЕТ СИГНАЛА"
		else
			return "НЕИЗВЕСТНО"

/// Render a single participant record as an HTML entry block.
/// Формат: > [ЗВАНИЕ] [ИМЯ] + ОТРЯД/РОЛЬ/СТАТУС/ПРИЧИНА
/proc/round_cinematics_outro_render_record_entry(datum/round_cinematics_participant_record/record)
	if(!istype(record))
		return ""

	var/status_color = round_cinematics_status_color(record.status)
	var/status_label = round_cinematics_status_label(record.status)

	var/list/entry_lines = list(
		"> [html_encode(record.rank)] [html_encode(record.name)]",
		"  ОТРЯД: [html_encode(record.squad)]",
		"  РОЛЬ: [html_encode(record.role)]",
		"  СТАТУС: <span style='color:[status_color];'>[html_encode(status_label)]</span>",
		"  ПРИЧИНА: [html_encode(record.death_reason)]"
	)
	return entry_lines.Join("<br>")

/proc/round_cinematics_outro_render_summary_page(datum/round_cinematics_outro_context/context)
	if(!context)
		return round_cinematics_html_block("ОПЕРАЦИОННЫЙ ОТЧЕТ", "НЕТ ДАННЫХ", "#E4EAF8")
	var/color = context.outcome?.accent_color || "#E4EAF8"
	return round_cinematics_html_block("ОПЕРАЦИОННЫЙ ОТЧЕТ", round_cinematics_join_lines(context.summary_lines), color)

/proc/round_cinematics_outro_render_status_page(datum/round_cinematics_outro_context/context)
	if(!context)
		return round_cinematics_html_block("СВОДКА", "НЕТ ДАННЫХ", "#E4EAF8")

	var/datum/round_cinematics_statistics/stats = context.statistics
	if(!stats)
		return round_cinematics_html_block("СВОДКА", "НЕТ ДАННЫХ", "#E4EAF8")

	var/list/summary_counts = list(
		"ЛИЧНЫЙ СОСТАВ",
		"В СТРОЮ: [stats.personnel_active]",
		"РАНЕНЫ: [stats.personnel_incapacitated]",
		"ПОГИБЛИ: [stats.personnel_dead]",
		"НЕТ СИГНАЛА: [stats.personnel_missing]",
		"",
		"УНИЧТОЖЕНИЕ",
		"ВСЕГО: [stats.destruction_total]"
	)
	var/color = context.outcome?.accent_color || "#E4EAF8"
	return round_cinematics_html_block("СВОДКА", round_cinematics_join_lines(summary_counts), color)

/// Render a page from a list of /datum/round_cinematics_participant_record.
/proc/round_cinematics_outro_render_record_page(list/page_records, page_index, page_count, title)
	if(!islist(page_records) || !length(page_records))
		return round_cinematics_html_block(title, "НЕТ ДАННЫХ", "#E4EAF8")

	var/list/chunks = list()
	for(var/datum/round_cinematics_participant_record/record as anything in page_records)
		if(!istype(record))
			continue
		chunks += round_cinematics_outro_render_record_entry(record)

	var/full_title = page_count > 1 ? "[title] [page_index]/[page_count]" : title
	return round_cinematics_html_block(full_title, chunks.Join("<hr style='border:0;border-top:1px solid #556; margin:6px 0;'>"), "#E4EAF8")

/proc/round_cinematics_outro_render_personnel_page(list/page_entries, page_index, page_count)
	return round_cinematics_outro_render_record_page(page_entries, page_index, page_count, "ЛИЧНЫЙ СОСТАВ")

/proc/round_cinematics_outro_render_destruction_page(list/page_entries, page_index, page_count)
	// Агрегированная статистика NPC вместо постраничного списка
	if(!islist(page_entries) || !length(page_entries))
		return round_cinematics_html_block("ПРОЧИЕ ПОТЕРИ", "НЕТ ДАННЫХ", "#E4EAF8")

	var/active_count = 0
	var/dead_count = 0
	var/incap_count = 0
	var/missing_count = 0
	for(var/datum/round_cinematics_participant_record/record as anything in page_entries)
		if(!istype(record))
			continue
		switch(record.status)
			if("active")
				active_count++
			if("dead")
				dead_count++
			if("incapacitated")
				incap_count++
			if("missing")
				missing_count++

	var/list/summary = list(
		"ПРОЧИЕ ПОТЕРИ (НЕ-СТАРТОВЫЙ СОСТАВ)",
		"ВСЕГО УЧТЕНО: [length(page_entries)]",
		"В СТРОЮ: [active_count]",
		"РАНЕНЫ: [incap_count]",
		"ПОГИБЛИ: [dead_count]",
		"НЕТ СИГНАЛА: [missing_count]"
	)
	return round_cinematics_html_block("ПРОЧИЕ ПОТЕРИ", round_cinematics_join_lines(summary), "#E4EAF8")

/proc/round_cinematics_outro_render_participant_page(list/page_entries, page_index, page_count)
	return round_cinematics_outro_render_record_page(page_entries, page_index, page_count, "ЛИЧНЫЙ СОСТАВ")

