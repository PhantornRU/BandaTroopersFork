/proc/round_cinematics_outro_render_summary_page(datum/round_cinematics_outro_context/context)
	if(!context)
		return round_cinematics_html_block("ОПЕРАЦИОННЫЙ ОТЧЕТ", "НЕТ ДАННЫХ", "#E4EAF8")
	return round_cinematics_html_block("ОПЕРАЦИОННЫЙ ОТЧЕТ", round_cinematics_join_lines(context.summary_lines), "#E4EAF8")

/proc/round_cinematics_outro_render_status_page(datum/round_cinematics_outro_context/context)
	if(!context)
		return round_cinematics_html_block("СВОДКА", "НЕТ ДАННЫХ", "#E4EAF8")

	var/list/summary_counts = list(
		"СОСТОЯНИЕ СОСТАВА",
		"ЧЛЕНОВ ЭКИПАЖА: [length(context.participant_entries)]"
	)
	return round_cinematics_html_block("СВОДКА", round_cinematics_join_lines(summary_counts), "#E4EAF8")

/proc/round_cinematics_outro_render_participant_page(list/page_entries, page_index, page_count)
	if(!islist(page_entries) || !length(page_entries))
		return round_cinematics_html_block("ЛИЧНЫЙ СОСТАВ", "НЕТ ДАННЫХ", "#E4EAF8")

	var/list/chunks = list()
	for(var/entry in page_entries)
		chunks += "[entry]"
	return round_cinematics_html_block("ЛИЧНЫЙ СОСТАВ [page_index]/[page_count]", chunks.Join("<hr style='border:0;border-top:1px solid #556; margin:6px 0;'>"), "#E4EAF8")

