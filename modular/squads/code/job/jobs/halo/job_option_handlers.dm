#define HALO_CPL_VARIANT "Corporal"
#define HALO_LCPL_VARIANT "Lance Corporal"
#define HALO_PFC_VARIANT "Private First Class"
#define HALO_PVT_VARIANT "Private"

/datum/job/marine/medic/ai/halo/unsc/handle_job_options(option)
	gear_preset = initial(gear_preset)
	if(option == HALO_PVT_VARIANT)
		gear_preset = gear_preset_quaternary
	if(option == HALO_PFC_VARIANT)
		gear_preset = gear_preset_tertiary
	if(option == HALO_LCPL_VARIANT)
		gear_preset = gear_preset_secondary

/datum/job/marine/medic/ai/halo/odst/handle_job_options(option)
	gear_preset = initial(gear_preset)
	if(option == HALO_PVT_VARIANT)
		gear_preset = gear_preset_quaternary
	if(option == HALO_PFC_VARIANT)
		gear_preset = gear_preset_tertiary
	if(option == HALO_LCPL_VARIANT)
		gear_preset = gear_preset_secondary
