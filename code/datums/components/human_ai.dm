/datum/component/human_ai
	dupe_mode = COMPONENT_DUPE_UNIQUE
	/// Ref to the AI brain
	var/datum/human_ai_brain/ai_brain
	/// Ref to the owning human
	var/mob/living/carbon/human/ai_human
	var/static/human_ai_has_spawned = FALSE

/datum/component/human_ai/Initialize()
	. = ..()
	ai_human = parent
	if(!istype(ai_human))
		return COMPONENT_INCOMPATIBLE

	if(!human_ai_has_spawned && !(SSticker.mode.toggleable_flags & MODE_HUMAN_AI_TWEAKS))
		human_ai_has_spawned = TRUE
		SSticker.mode.toggleable_flags ^= MODE_HUMAN_AI_TWEAKS
		message_admins("Human AI tweaks have been enabled by spawning an AI. This can be disabled with the \"Toggle Human AI Tweaks\" verb.")

	ai_brain = new(ai_human)
	// SS220 EDIT - START: allow modular presets to configure freshly-created AI brains
	var/datum/equipment_preset/equipment_preset = ai_human.assigned_equipment_preset
	if(equipment_preset && hascall(equipment_preset, "modular_apply_human_ai_brain_overrides"))
		call(equipment_preset, "modular_apply_human_ai_brain_overrides")(ai_brain, ai_human)
	// SS220 EDIT - END
	GLOB.ai_humans += ai_human
	ai_human.mob_flags |= AI_CONTROLLED

/datum/component/human_ai/Destroy(force, silent)
	handle_qdel()
	return ..()

/datum/component/human_ai/RegisterWithParent()
	..()
	RegisterSignal(ai_human, COMSIG_PARENT_QDELETING, PROC_REF(handle_qdel))
	RegisterSignal(ai_human, COMSIG_HUMAN_SET_SPECIES, PROC_REF(on_species_set))

/datum/component/human_ai/UnregisterFromParent()
	..()
	if(ai_human)
		UnregisterSignal(ai_human, COMSIG_PARENT_QDELETING)
		UnregisterSignal(ai_human, COMSIG_HUMAN_SET_SPECIES)

/datum/component/human_ai/proc/handle_qdel()
	SIGNAL_HANDLER

	GLOB.ai_humans -= ai_human
	ai_brain?.tied_human = null
	QDEL_NULL(ai_brain)
	ai_human = null

/datum/component/human_ai/proc/on_species_set(datum/source, new_species)
	SIGNAL_HANDLER

	ai_human.mob_flags |= AI_CONTROLLED
