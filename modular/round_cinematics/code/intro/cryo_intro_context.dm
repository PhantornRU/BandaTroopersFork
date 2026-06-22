/datum/round_cinematics_intro_context
	var/mob/living/carbon/human/subject
	var/obj/structure/machinery/cryopod/source_pod
	var/preview = FALSE
	var/display_name = "НЕИЗВЕСТНО"
	var/display_rank = "UNKWN"
	var/display_role = "UNKWN"
	var/display_squad = "НЕИЗВЕСТНО"
	var/display_ship = "3rd Bat. 'Banda Troopers'"
	/// Resolved affiliation for this intro
	var/datum/round_cinematics_affiliation/affiliation = null
	var/list/boot_lines = list()
	var/list/personal_lines = list()
	var/list/manifest_entries = list()
	var/list/manifest_pages = list()

/datum/round_cinematics_intro_context/New(mob/living/carbon/human/subject, obj/structure/machinery/cryopod/source_pod, preview = FALSE)
	..()
	src.subject = subject
	src.source_pod = source_pod
	src.preview = preview
	build()

/datum/round_cinematics_intro_context/proc/build()
	display_name = round_cinematics_safe_text(subject?.real_name, "НЕИЗВЕСТНО")
	display_rank = round_cinematics_human_rank(subject)
	display_role = round_cinematics_human_role(subject)
	display_squad = round_cinematics_human_squad(subject)
	display_ship = round_cinematics_human_ship_profile_label(subject)

	// Resolve affiliation for faction-specific data
	affiliation = resolve_affiliation(subject)

	boot_lines = list(
		"ПРОТОКОЛ ПРОБУЖДЕНИЯ АКТИВИРОВАН",
		"СИСТЕМА ЖИЗНЕОБЕСПЕЧЕНИЯ: ОНЛАЙН",
		"СТАЗИС: ДЕАКТИВИРОВАН",
		"ОПЕРАТОР: [html_encode(display_name)]"
	)

	personal_lines = list(
		"ИМЯ: [html_encode(display_name)]",
		"ЗВАНИЕ: [html_encode(display_rank)]",
		"РОЛЬ: [html_encode(display_role)]",
		"ОТРЯД: [html_encode(display_squad)]",
		"СЕГМЕНТ: [html_encode(display_ship)]"
	)

	// P2.13: Add affiliation-specific lines if available
	if(affiliation)
		if(length(affiliation.display_code) && length(affiliation.display_name))
			personal_lines += "ПОДРАЗДЕЛЕНИЕ: [html_encode(affiliation.display_code)] — [html_encode(affiliation.display_name)]"
		if(length(affiliation.unit_name))
			personal_lines += "ЧАСТЬ: [html_encode(affiliation.unit_name)]"
		if(length(affiliation.ship_name))
			personal_lines += "КОРАБЛЬ: [html_encode(affiliation.ship_name)]"
		if(length(affiliation.ground_map_name))
			personal_lines += "КАРТА ВЫСАДКИ: [html_encode(affiliation.ground_map_name)]"
		if(length(affiliation.operation_name))
			personal_lines += "ОПЕРАЦИЯ: [html_encode(affiliation.operation_name)]"

	build_manifest()

/datum/round_cinematics_intro_context/proc/build_manifest()
	manifest_entries = list()
	if(!subject)
		manifest_pages = list(list("<b>СОСТАВ ОТРЯДА</b><br>НЕТ ДАННЫХ"))
		return

	for(var/mob/living/carbon/human/human as anything in GLOB.alive_human_list)
		if(!human || human == subject)
			continue
		if(is_ground_level(human.z))
			continue
		if(human.faction != subject.faction)
			continue
		if(human.assigned_squad != subject.assigned_squad)
			continue

		var/list/entry_lines = list(
			"<b>[html_encode(round_cinematics_safe_text(human.real_name, "НЕИЗВЕСТНО"))]</b>",
			"РАНГ: [html_encode(round_cinematics_human_rank(human))] | РОЛЬ: [html_encode(round_cinematics_human_role(human))]",
			"ОТРЯД: [html_encode(round_cinematics_human_squad(human))] | СОСТОЯНИЕ: [html_encode(round_cinematics_human_status(human))]"
		)
		manifest_entries += list(entry_lines.Join("<br>"))

	manifest_pages = round_cinematics_paginate(manifest_entries, ROUND_CINEMATICS_INTRO_PAGE_ROWS)
	if(!length(manifest_pages))
		manifest_pages = list(list("<b>СОСТАВ ОТРЯДА</b><br>НЕТ ДАННЫХ"))
