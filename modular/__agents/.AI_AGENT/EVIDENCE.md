# EVIDENCE

## E-001: HALO object text is currently inline English content
- Targeted search found 948 `name`/`desc` assignments under `modular/halo/code/**`, spread across 86 files.
- The selected player-facing Wave 1 scope covers roughly 43 visible-object files and about 497 `name`/`desc` lines before auxiliary examine strings.

## E-002: Existing HALO localization support does not cover object metadata
- `modular/localization/code/modules/mob/living/carbon/human/ai/brain/**` localizes HALO AI speech packs.
- No general HALO object-name runtime localization surface was found for item metadata, so in-place string translation is the compatible path.

## E-003: Scoped translation surfaces are already isolated in HALO content includes
- `modular/halo/_halo.dme` includes the relevant visible-object files under HALO-specific `modules/projectiles/guns/halo/**`, `game/objects/items/**`, `mixed/clothing/**`, `modules/clothing/**`, and remaining HALO structure/item/machinery files.
- This supports a content-only translation pass without changing include graph or upstream glue.

## E-004: Verification requirements for this task
- Workflow rules require UTF-8-safe edits and DM compile verification via `tools/build/build --ci dm -DCIBUILDING -DANSICOLORS -Werror`.
- Text-safety checks should include `git diff --check` and a targeted mojibake scan on touched files.
