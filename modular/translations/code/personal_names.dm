/proc/ss220_localize_personal_name_bank(list/source_bank)
	if(!islist(source_bank))
		return source_bank

	var/list/localized_bank = list()
	for(var/entry as anything in source_bank)
		if(istext(entry))
			localized_bank += ss220_localize_personal_name(entry)
		else
			localized_bank += entry
	return localized_bank

/proc/ss220_localize_generated_personal_name(name_value)
	return ss220_localize_personal_name(name_value)

/proc/ss220_localize_personal_name(name_value)
	if(!istext(name_value) || !length_char(name_value))
		return name_value

	var/static/list/ordered_multichar_keys = list(
		"shch",
		"dzh",
		"sch",
		"tch",
		"zh",
		"ch",
		"sh",
		"kh",
		"ph",
		"th",
		"ts",
		"ya",
		"yu",
		"yo",
		"ye",
		"qu",
		"ck",
		"mc",
	)
	var/static/list/multichar_replacements = list(
		"shch" = "щ",
		"dzh" = "дж",
		"sch" = "ш",
		"tch" = "ч",
		"zh" = "ж",
		"ch" = "ч",
		"sh" = "ш",
		"kh" = "х",
		"ph" = "ф",
		"th" = "т",
		"ts" = "ц",
		"ya" = "я",
		"yu" = "ю",
		"yo" = "ё",
		"ye" = "е",
		"qu" = "кв",
		"ck" = "к",
		"mc" = "мак",
	)
	var/static/list/char_replacements = list(
		"a" = "а",
		"b" = "б",
		"d" = "д",
		"e" = "е",
		"f" = "ф",
		"h" = "х",
		"i" = "и",
		"j" = "дж",
		"k" = "к",
		"l" = "л",
		"m" = "м",
		"n" = "н",
		"o" = "о",
		"p" = "п",
		"q" = "к",
		"r" = "р",
		"s" = "с",
		"t" = "т",
		"u" = "у",
		"v" = "в",
		"w" = "в",
		"x" = "кс",
		"y" = "й",
		"z" = "з",
		"á" = "а",
		"à" = "а",
		"â" = "а",
		"ã" = "а",
		"ä" = "а",
		"å" = "а",
		"æ" = "э",
		"ç" = "с",
		"é" = "е",
		"è" = "е",
		"ê" = "е",
		"ë" = "е",
		"í" = "и",
		"ì" = "и",
		"î" = "и",
		"ï" = "и",
		"ñ" = "нь",
		"ó" = "о",
		"ò" = "о",
		"ô" = "о",
		"õ" = "о",
		"ö" = "ё",
		"ø" = "о",
		"œ" = "ё",
		"ú" = "у",
		"ù" = "у",
		"û" = "у",
		"ü" = "ю",
		"ý" = "й",
		"ÿ" = "й",
		"ā" = "а",
		"ă" = "а",
		"ą" = "а",
		"ć" = "ч",
		"č" = "ч",
		"ď" = "д",
		"ē" = "е",
		"ė" = "е",
		"ę" = "е",
		"ě" = "е",
		"ğ" = "г",
		"ī" = "и",
		"ł" = "л",
		"ń" = "нь",
		"ň" = "нь",
		"ō" = "о",
		"ő" = "ё",
		"ř" = "р",
		"ś" = "с",
		"š" = "ш",
		"ť" = "т",
		"ū" = "у",
		"ů" = "у",
		"ű" = "ю",
		"ź" = "з",
		"ż" = "ж",
		"ž" = "ж",
	)
	var/static/list/soft_c_triggers = list("e", "i", "y", "é", "è", "ê", "ë", "í", "ì", "î", "ï", "ě")
	var/static/list/soft_g_triggers = list("e", "i", "y", "é", "è", "ê", "ë", "í", "ì", "î", "ï", "ě")

	var/result = ""
	var/index = 1
	var/total_length = length_char(name_value)

	while(index <= total_length)
		var/matched = FALSE
		for(var/key in ordered_multichar_keys)
			var/key_length = length_char(key)
			var/source_chunk = copytext_char(name_value, index, index + key_length)
			if(length_char(source_chunk) != key_length)
				continue
			if(lowertext(source_chunk) != key)
				continue

			result += ss220_apply_personal_name_case(source_chunk, multichar_replacements[key])
			index += key_length
			matched = TRUE
			break

		if(matched)
			continue

		var/source_char = copytext_char(name_value, index, index + 1)
		var/lower_char = lowertext(source_char)
		var/replacement = char_replacements[lower_char]
		if(isnull(replacement))
			switch(lower_char)
				if("c")
					var/next_char = lowertext(copytext_char(name_value, index + 1, index + 2))
					replacement = next_char in soft_c_triggers ? "с" : "к"
				if("g")
					var/next_char = lowertext(copytext_char(name_value, index + 1, index + 2))
					replacement = next_char in soft_g_triggers ? "дж" : "г"

		if(isnull(replacement))
			result += source_char
		else
			result += ss220_apply_personal_name_case(source_char, replacement)

		index++

	return result

/proc/ss220_apply_personal_name_case(source_chunk, replacement)
	if(!length_char(source_chunk) || !length_char(replacement))
		return replacement

	if(source_chunk == uppertext(source_chunk) && length_char(source_chunk) > 1)
		return uppertext(replacement)

	if(copytext_char(source_chunk, 1, 2) == uppertext(copytext_char(source_chunk, 1, 2)))
		return capitalize(replacement)

	return replacement
