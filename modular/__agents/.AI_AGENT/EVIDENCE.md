# EVIDENCE

## E-001: Stock Human AI defaults are English fallback banks
- `code/modules/mob/living/carbon/human/ai/brain/ai_brain_communication.dm` initializes default line lists directly on `/datum/human_ai_brain`.
- Any faction without a full override can still speak those stock English defaults.

## E-002: Human AI factions are instantiated once and can be patched at runtime
- `code/controllers/subsystem/human_ai.dm` builds `SShuman_ai.human_ai_factions` from `subtypesof(/datum/human_ai_faction)` during subsystem init.
- `reapply_faction_data()` already exists and can push updated speech banks to live AI brains.

## E-003: HALO already owns a modular post-init bridge into Human AI
- `modular/halo/_halo.dm` registers a post-initialize hook for `SShuman_ai`.
- That bridge is the correct modular surface for applying runtime localization without widening the upstream diff.

## E-004: HALO Covenant presets already support per-brain overrides
- `code/datums/components/human_ai.dm` calls `modular_apply_human_ai_brain_overrides` on the assigned equipment preset after creating the AI brain.
- HALO Sangheili and Unggoy presets already use that hook for behavior metadata, so speech profile overrides can reuse the same surface.
