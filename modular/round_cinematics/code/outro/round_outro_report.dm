/proc/round_cinematics_status_color(status)
	switch(status)
		if("ACTIVE", "В СТРОЮ")
			return "#44FF44"
		if("INCAPACITATED", "ТЯЖЕЛО РАНЕН")
			return "#FFAA44"
		if("DEAD", "ПОГИБ")
			return "#FF4444"
		if("MISSING", "НЕТ ДАННЫХ")
			return "#888888"
		else
			return "#DCE6F6"

/proc/round_cinematics_outro_render_summary_page(datum/round_cinematics_outro_context/context)
	if(!context)
		return round_cinematics_html_block("ОПЕРАЦИОННЫЙ ОТЧЕТ", "НЕТ ДАННЫХ", "#E4EAF8")
	var/color = context.outcome?.accent_color || "#E4EAF8"
	return round_cinematics_html_block("ОПЕРАЦИОННЫЙ ОТЧЕТ", round_cinematics_join_lines(context.summary_lines), color)

/proc/round_cinematics_outro_count_statuses(list/entries)
	var/active_count = 0
	var/wounded_count = 0
	var/dead_count = 0
	var/missing_count = 0

	if(entries)
		for(var/entry in entries)
			if(findtext(entry, "СОСТОЯНИЕ:"))
				if(findtext(entry, "ACTIVE") || findtext(entry, "В СТРОЮ"))
					active_count++
				else if(findtext(entry, "INCAPACITATED") || findtext(entry, "ТЯЖЕЛО РАНЕН"))
					wounded_count++
				else if(findtext(entry, "DEAD") || findtext(entry, "ПОГИБ"))
					dead_count++
				else if(findtext(entry, "MISSING") || findtext(entry, "НЕТ ДАННЫХ") || findtext(entry, "НЕТ СИГНАЛА"))
					missing_count++
			else
				missing_count++

	return list(active_count, wounded_count, dead_count, missing_count)

/proc/round_cinematics_outro_render_status_page(datum/round_cinematics_outro_context/context)
	if(!context)
		return round_cinematics_html_block("СВОДКА", "НЕТ ДАННЫХ", "#E4EAF8")

	var/list/personnel_counts = round_cinematics_outro_count_statuses(context.personnel_entries)

	var/p_active = personnel_counts[1]
	var/p_wounded = personnel_counts[2]
	var/p_dead = personnel_counts[3]
	var/p_missing = personnel_counts[4]

	var/d_total = length(context.destruction_entries)

	var/list/summary_counts = list(
		"ЛИЧНЫЙ СОСТАВ",
		"В СТРОЮ: [p_active]",
		"РАНЕНЫ: [p_wounded]",
		"ПОГИБЛИ: [p_dead]",
		"НЕТ СИГНАЛА: [p_missing]",
		"",
		"УНИЧТОЖЕНИЕ",
		"ВСЕГО: [d_total]"
	)
	var/color = context.outcome?.accent_color || "#E4EAF8"
	return round_cinematics_html_block("СВОДКА", round_cinematics_join_lines(summary_counts), color)

/proc/round_cinematics_outro_render_entry_page(list/page_entries, page_index, page_count, title)
	if(!islist(page_entries) || !length(page_entries))
		return round_cinematics_html_block(title, "НЕТ ДАННЫХ", "#E4EAF8")

	var/list/chunks = list()
	for(var/entry in page_entries)
		var/colored_entry = entry
		if(findtext(entry, "СОСТОЯНИЕ:"))
			if(findtext(entry, "ACTIVE") || findtext(entry, "В СТРОЮ"))
				colored_entry = replacetext(entry, "СОСТОЯНИЕ:", "<span style='color:#44FF44;'>СОСТОЯНИЕ:</span>")
			else if(findtext(entry, "INCAPACITATED") || findtext(entry, "ТЯЖЕЛО РАНЕН"))
				colored_entry = replacetext(entry, "СОСТОЯНИЕ:", "<span style='color:#FFAA44;'>СОСТОЯНИЕ:</span>")
			else if(findtext(entry, "DEAD") || findtext(entry, "ПОГИБ"))
				colored_entry = replacetext(entry, "СОСТОЯНИЕ:", "<span style='color:#FF4444;'>СОСТОЯНИЕ:</span>")
			else if(findtext(entry, "MISSING") || findtext(entry, "НЕТ ДАННЫХ"))
				colored_entry = replacetext(entry, "СОСТОЯНИЕ:", "<span style='color:#888888;'>СОСТОЯНИЕ:</span>")
		chunks += "[colored_entry]"

	var/full_title = page_count > 1 ? "[title] [page_index]/[page_count]" : title
	return round_cinematics_html_block(full_title, chunks.Join("<hr style='border:0;border-top:1px solid #556; margin:6px 0;'>"), "#E4EAF8")

/proc/round_cinematics_outro_render_personnel_page(list/page_entries, page_index, page_count)
	return round_cinematics_outro_render_entry_page(page_entries, page_index, page_count, "ЛИЧНЫЙ СОСТАВ")

/proc/round_cinematics_outro_render_destruction_page(list/page_entries, page_index, page_count)
	return round_cinematics_outro_render_entry_page(page_entries, page_index, page_count, "УНИЧТОЖЕНИЕ")

/proc/round_cinematics_outro_render_participant_page(list/page_entries, page_index, page_count)
	return round_cinematics_outro_render_entry_page(page_entries, page_index, page_count, "ЛИЧНЫЙ СОСТАВ")

