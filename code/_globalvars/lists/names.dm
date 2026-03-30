GLOBAL_LIST_INIT(ai_names, file2list("strings/ai.txt"))
// SS220 EDIT - START: route runtime personal-name banks through explicit localized data files
GLOBAL_LIST_INIT(first_names_male, ss220_load_personal_name_bank("human/first_male.txt"))
GLOBAL_LIST_INIT(first_names_female, ss220_load_personal_name_bank("human/first_female.txt"))
GLOBAL_LIST_INIT(last_names, ss220_load_personal_name_bank("human/last.txt"))
// SS220 EDIT - END
GLOBAL_LIST_INIT(clown_names, file2list("strings/clown.txt"))
GLOBAL_LIST_INIT(operation_titles, file2list("strings/operation_title.txt"))
GLOBAL_LIST_INIT(operation_prefixes, file2list("strings/operation_prefix.txt"))
GLOBAL_LIST_INIT(operation_postfixes, file2list("strings/operation_postfix.txt"))

GLOBAL_LIST_INIT(verbs, file2list("strings/verbs.txt"))
//loaded on startup because of "
//would include in rsc if ' was used


// SS220 EDIT - START: hardcoded personal-name pools now read from explicit localized bank files
GLOBAL_LIST_INIT(first_names_male_clf, ss220_load_personal_name_bank("factions/first_names_male_clf.txt"))
GLOBAL_LIST_INIT(first_names_female_clf, ss220_load_personal_name_bank("factions/first_names_female_clf.txt"))
GLOBAL_LIST_INIT(last_names_clf, ss220_load_personal_name_bank("factions/last_names_clf.txt"))

GLOBAL_LIST_INIT(first_names_male_colonist, ss220_load_personal_name_bank("factions/first_names_male_colonist.txt"))
GLOBAL_LIST_INIT(first_names_female_colonist, ss220_load_personal_name_bank("factions/first_names_female_colonist.txt"))
GLOBAL_LIST_INIT(last_names_colonist, ss220_load_personal_name_bank("factions/last_names_colonist.txt"))

GLOBAL_LIST_INIT(first_names_male_upp, ss220_load_personal_name_bank("factions/first_names_male_upp.txt"))
GLOBAL_LIST_INIT(first_names_female_upp, ss220_load_personal_name_bank("factions/first_names_female_upp.txt"))
GLOBAL_LIST_INIT(last_names_upp, ss220_load_personal_name_bank("factions/last_names_upp.txt"))

GLOBAL_LIST_INIT(first_names_male_pmc, ss220_load_personal_name_bank("factions/first_names_male_pmc.txt"))
GLOBAL_LIST_INIT(first_names_female_pmc, ss220_load_personal_name_bank("factions/first_names_female_pmc.txt"))
GLOBAL_LIST_INIT(last_names_pmc, ss220_load_personal_name_bank("factions/last_names_pmc.txt"))

GLOBAL_LIST_INIT(first_names_male_gladiator, ss220_load_personal_name_bank("factions/first_names_male_gladiator.txt"))
GLOBAL_LIST_INIT(first_names_female_gladiator, ss220_load_personal_name_bank("factions/first_names_female_gladiator.txt"))

GLOBAL_LIST_INIT(first_names_male_dutch, ss220_load_personal_name_bank("factions/first_names_male_dutch.txt"))
GLOBAL_LIST_INIT(first_names_female_dutch, ss220_load_personal_name_bank("factions/first_names_female_dutch.txt"))

GLOBAL_LIST_INIT(monkey_names, ss220_load_personal_name_bank("misc/monkey_names.txt"))

GLOBAL_LIST_INIT(weapon_surnames, ss220_load_personal_name_bank("misc/weapon_surnames.txt"))


GLOBAL_LIST_INIT(first_names_male_brazilian, ss220_load_personal_name_bank("factions/first_names_male_brazilian.txt"))
GLOBAL_LIST_INIT(first_names_female_brazilian, ss220_load_personal_name_bank("factions/first_names_female_brazilian.txt"))
GLOBAL_LIST_INIT(last_names_brazilian, ss220_load_personal_name_bank("factions/last_names_brazilian.txt"))

GLOBAL_LIST_INIT(first_names_male_spanish, ss220_load_personal_name_bank("factions/first_names_male_spanish.txt"))
GLOBAL_LIST_INIT(first_names_female_spanish, ss220_load_personal_name_bank("factions/first_names_female_spanish.txt"))
GLOBAL_LIST_INIT(last_names_spanish, ss220_load_personal_name_bank("factions/last_names_spanish.txt"))
// SS220 EDIT - END
