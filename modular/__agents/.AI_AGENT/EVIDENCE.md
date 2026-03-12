# EVIDENCE

## E-001: Stock Human AI defaults are English fallback banks
- `code/modules/mob/living/carbon/human/ai/brain/ai_brain_communication.dm` initializes default line lists directly on `/datum/human_ai_brain`.
- Any faction without a full override can still speak those stock English defaults.

## E-002: Human AI factions are instantiated once and can be patched at runtime
- `code/controllers/subsystem/human_ai.dm` builds `SShuman_ai.human_ai_factions` from `subtypesof(/datum/human_ai_faction)` during subsystem init.
- `reapply_faction_data()` already exists and can push updated speech banks to live AI brains.

## E-003: The repo has a modular modpack layer suitable for shared localization ownership
- `modular/modular.dme` wires standalone modpacks, so speech localization can live outside `modular/halo/**`.
- `modular/_modpacks.dm` now exposes a typed `get_modpack()` lookup for module-owned services.

## E-004: Fresh Human AI brains now have a minimal upstream post-create modular hook
- `code/datums/components/human_ai.dm` calls `modular_apply_human_ai_brain_overrides` on the assigned equipment preset after creating the AI brain.
- The same proc now also calls `modular_finalize_human_ai_brain` if present, which lets modular localization fill missing speech categories without overriding the whole upstream component proc.

## E-005: HALO Covenant presets already support per-brain speech profile overlays
- HALO Sangheili and Unggoy presets use `modular_apply_human_ai_brain_overrides`.
- Those presets can fetch `/datum/modpack/localization` and apply species-specific speech packs without global helper procs.
