/proc/ss220_run_equipment_preset_post_load(datum/equipment_preset/preset, mob/living/carbon/human/new_human)
	if(!preset || !new_human || !preset.expected_species)
		return

	var/datum/species/current_species = new_human.species
	if(current_species?.group == preset.expected_species || current_species?.name == preset.expected_species)
		if(preset.expected_species == SPECIES_ZOMBIE)
			current_species.handle_post_spawn(new_human)
		return

	new_human.set_species(preset.expected_species)

/datum/equipment_preset/zombie
	expected_species = SPECIES_ZOMBIE
