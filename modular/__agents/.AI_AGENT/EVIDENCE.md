# EVIDENCE

## Icon State Audit
- `icons/obj/items/clothing/backpacks.dmi` contains `commando_backpack`, not `commandopack`.
- `icons/obj/items/clothing/pouches.dmi` contains `wy_sgdrums_ammo`, not `socdrums`.
- `icons/obj/items/misc.dmi` contains `rpb_phone`, not `upp_rpb_phone`.
- `icons/obj/items/weapons/guns/attachments/attachments_pr.dmi` contains:
  - `sniperscope_fal`
  - `miniscope_fal`
  - `fal_saw_stock`
  - `bipod_fal_saw_a`
- `icons/obj/items/weapons/guns/guns_by_faction/colony.dmi` contains neither `m20a_tactical` nor `m20a`; `icons/obj/items/weapons/guns/guns_by_faction/uscm.dmi` contains `m20a`.
- `icons/obj/items/items.dmi` contains neither `armor_plate_100` nor any `armor_plate_*` family states.

## Lookup Overlap Audit
- `setup_gear_name_presets()` and `setup_species()` both fail on duplicate `name` keys.
- `code/modules/gear_presets/canc_dogwar.dm` defines `/datum/equipment_preset/canc_dogwar/upp/pl_leader`, but its `load_gear` proc is accidentally attached to `/datum/equipment_preset/canc_dogwar/soldier/upp/pl_leader`.
- `code/modules/mob/living/carbon/human/ai/squad_spawner/squad_canc.dm` still references `/datum/equipment_preset/canc_dogwar/soldier/upp/pl_leader`.
- `SYNTH_COMBAT` is used by Whiteout presets and `/mob/living/carbon/human/synthetic/combat/Initialize(mapload)`, while `wy_droid` already carries the intended W-Y android naming/theme.

## Map Sanitation Audit
- `tools/ci/check_grep.sh` fails on any `^\ttag = "icon` line in map files.
- `maps/map_files/lv671/lv671.dmm` currently contains repeated `tag = "icon-pottedplant_10"` var edits on potted plants.

## Verification
- `git diff --check`
  - Passed.
- quick structural greps
  - No remaining matches for:
    - `tag = "icon-` in `maps/map_files/lv671/lv671.dmm`
    - `/datum/equipment_preset/canc_dogwar/soldier/upp`
    - `commandopack`
    - `socdrums`
    - `icon_state = "upp_rpb_phone"`
    - `icon_state = "m20a_tactical"`
- targeted maplint
  - Cached bootstrap Python + `tools.maplint.source --github maps/map_files/lv671/lv671.dmm`
  - Passed: `maps/map_files/lv671/lv671.dmm OK`
- DMI parse test
  - Cached bootstrap Python + `dmi.test`
  - Passed: `successfully parsed 1321 .dmi files`
- compile
  - `cmd /c BUILD.cmd --ci dm -DCIBUILDING -DANSICOLORS -Werror`
  - Passed: `colonialmarines.dmb - 0 errors, 0 warnings (3/7/26 2:42 pm)`
- frontend lint/test path
  - `cmd /c tools\\build\\build.bat --ci lint tgui-test`
  - Passed: Prettier/ESLint/TypeScript clean, `15 passed` test suites.
- local unit-test run
  - PowerShell-equivalent of `tools/ci/run_server.sh lv671` using local `DreamDaemon`
  - `clean_run.lk` returned `Success!`
  - No `FAIL`, `Missing icon_state`, or `overlaps with` matches were found under the generated test logs before cleanup.

## Residuals
- `armor_plate_*` wearable overlay states are still not present in `icons/mob/humans/onmob/ties.dmi`.
- Current fix restores the item icon contract for `/obj/item/clothing/accessory/health/ceramic_plate/marine`, but there is no confirmed local source of truth for the missing marine/UPP overlay sprite family, so that debt remains outside this unit-test/lint blocker fix.
