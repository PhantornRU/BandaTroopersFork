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

## E-005: Canonical `ККОН` wording already exists in repo-local HALO localization
- `modular/localization/code/modules/mob/living/carbon/human/ai/brain/human_ai_localization_halo.dm` already uses `ККОН` in Russian HALO lines.
- HALO vendor product labels are stored inline in `modular/halo/code/game/machinery/vending/vendor_types/**`, so they are directly editable without adding a runtime translation layer.

## E-006: Final verification passed after vendor-label and `ККОН` update
- `git diff --check` returned no whitespace or patch-formatting issues.
- Targeted scans found no remaining English `listed_products` labels in HALO vendor files and no remaining player-facing `UNSC` object strings in the scoped HALO object/vending files.
- `tools/build/build --ci dm -DCIBUILDING -DANSICOLORS -Werror` completed successfully with `0 errors, 0 warnings`.
