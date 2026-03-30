#define PERSONAL_NAME_BANK_ROOT "[PATH_TO_TRANSLATE_DATA]/personal_names"

GLOBAL_LIST_INIT(ss220_first_names_male_japanese, ss220_load_personal_name_bank("ethnic/japanese_first_male.txt"))
GLOBAL_LIST_INIT(ss220_first_names_female_japanese, ss220_load_personal_name_bank("ethnic/japanese_first_female.txt"))
GLOBAL_LIST_INIT(ss220_last_names_japanese, ss220_load_personal_name_bank("ethnic/japanese_last.txt"))

GLOBAL_LIST_INIT(ss220_first_names_male_chinese, ss220_load_personal_name_bank("ethnic/chinese_first_male.txt"))
GLOBAL_LIST_INIT(ss220_first_names_female_chinese, ss220_load_personal_name_bank("ethnic/chinese_first_female.txt"))
GLOBAL_LIST_INIT(ss220_last_names_chinese, ss220_load_personal_name_bank("ethnic/chinese_last.txt"))

GLOBAL_LIST_INIT(ss220_synth_default_names, ss220_load_personal_name_bank("synth/default.txt"))
GLOBAL_LIST_INIT(ss220_synth_working_joe_prefixes, ss220_load_personal_name_bank("synth/working_joe_prefix.txt"))
GLOBAL_LIST_INIT(ss220_synth_upp_joe_prefixes, ss220_load_personal_name_bank("synth/upp_joe_prefix.txt"))
GLOBAL_LIST_INIT(ss220_synth_security_android_prefixes, ss220_load_personal_name_bank("synth/security_android_prefix.txt"))
GLOBAL_LIST_INIT(ss220_synth_midwife_prefixes, ss220_load_personal_name_bank("synth/midwife_prefix.txt"))
GLOBAL_LIST_INIT(ss220_synth_commando_prefixes, ss220_load_personal_name_bank("synth/commando_prefix.txt"))

GLOBAL_LIST_INIT(ss220_cyrillic_serial_letters, list("А", "Б", "В", "Г", "Д", "Е", "Ж", "З", "И", "К", "Л", "М", "Н", "О", "П", "Р", "С", "Т", "У", "Ф", "Х", "Ц"))

/proc/ss220_load_personal_name_bank(relative_path)
	var/file_path = "[PERSONAL_NAME_BANK_ROOT]/[relative_path]"
	if(!fexists(file_path))
		stack_trace("Missing SS220 personal-name bank: [file_path]")
		return list()

	return file2list(file_path)

/proc/ss220_pick_personal_name_entry(list/source_bank, fallback)
	if(islist(source_bank) && length(source_bank))
		return pick(source_bank)

	return fallback

/proc/ss220_pick_japanese_first_name(gender)
	if(gender == FEMALE)
		return ss220_pick_personal_name_entry(GLOB.ss220_first_names_female_japanese, pick(GLOB.first_names_female_clf))

	return ss220_pick_personal_name_entry(GLOB.ss220_first_names_male_japanese, pick(GLOB.first_names_male_clf))

/proc/ss220_pick_japanese_last_name()
	return ss220_pick_personal_name_entry(GLOB.ss220_last_names_japanese, pick(GLOB.last_names_clf))

/proc/ss220_pick_chinese_first_name(gender)
	if(gender == FEMALE)
		return ss220_pick_personal_name_entry(GLOB.ss220_first_names_female_chinese, pick(GLOB.first_names_female_upp))

	return ss220_pick_personal_name_entry(GLOB.ss220_first_names_male_chinese, pick(GLOB.first_names_male_upp))

/proc/ss220_pick_chinese_last_name()
	return ss220_pick_personal_name_entry(GLOB.ss220_last_names_chinese, pick(GLOB.last_names_upp))

/proc/ss220_random_cyrillic_serial(length = 2)
	var/serial = ""
	for(var/index in 1 to length)
		serial += pick(GLOB.ss220_cyrillic_serial_letters)

	return serial

/proc/ss220_pick_synth_default_name()
	return ss220_pick_personal_name_entry(GLOB.ss220_synth_default_names, "Дэвид")

/proc/ss220_pick_synth_working_joe_prefix()
	return ss220_pick_personal_name_entry(GLOB.ss220_synth_working_joe_prefixes, JOB_WORKING_JOE_RU)

/proc/ss220_pick_synth_upp_joe_prefix()
	return ss220_pick_personal_name_entry(GLOB.ss220_synth_upp_joe_prefixes, JOB_UPP_JOE_RU)

/proc/ss220_pick_synth_security_android_prefix()
	return ss220_pick_personal_name_entry(GLOB.ss220_synth_security_android_prefixes, "Андроид охраны")

/proc/ss220_pick_synth_midwife_prefix()
	return ss220_pick_personal_name_entry(GLOB.ss220_synth_midwife_prefixes, "Акушерка Джо")

/proc/ss220_pick_synth_commando_prefix()
	return ss220_pick_personal_name_entry(GLOB.ss220_synth_commando_prefixes, "Коммандо")

/proc/ss220_build_working_joe_name(faction)
	if(faction == FACTION_UPP)
		return "[ss220_pick_synth_upp_joe_prefix()] №[rand(9)][rand(9)][ss220_random_cyrillic_serial(2)]"

	return "[ss220_pick_synth_working_joe_prefix()] #[rand(100)][rand(100)]"

/proc/ss220_build_security_android_name()
	return "[ss220_pick_synth_security_android_prefix()] #[rand(100)][rand(100)]"

/proc/ss220_build_commando_synth_name()
	return "[ss220_pick_synth_commando_prefix()] #[rand(250)]"

/proc/ss220_build_midwife_synth_name(custom_name)
	var/prefix = ss220_pick_synth_midwife_prefix()
	if(!istext(custom_name) || !length_char(custom_name) || custom_name == "Undefined")
		return prefix

	return "[prefix] [custom_name]"
