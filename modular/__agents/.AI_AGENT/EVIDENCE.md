# EVIDENCE

## Run Date
- 2026-03-05 (local workspace run).

## Inventory / Scope Evidence
- Imported GroundSide maps:
  - `maps/lv671.json`
  - `maps/oil_depot.json`
  - `maps/derelict_almayer_infested.json`
  - `maps/map_files/lv671/lv671.dmm`
  - `maps/map_files/oil_depot/oil_depot.dmm`
  - `maps/map_files/derelict_almayer_infested/derelict_almayer_infested.dmm`
- Rotation wiring updated in `map_config/maps.txt`.

## Build / Compatibility Evidence
- `code/game/machinery/telecomms/presets.dm` switch-case constant fix applied.
- Compatibility types present:
  - `/obj/item/storage/backpack/commando`
  - `/obj/item/clothing/head/beret/royal_marine`
  - `/obj/item/ammo_magazine/rifle/nsg23/extended`

## Regression Repair Evidence
- Map-side path/token repairs applied to:
  - `maps/map_files/BMG290_Otogi_Egress_Point/BMG290_Otogi_Egress_Point.dmm`
  - `maps/map_files/kleschers_research_site/BigBlue.dmm`
  - `maps/map_files/USCSS_Onyx_Karain/USCSS_Onyx_Karain.dmm`

## DMI Overflow Evidence
- New split files:
  - `icons/mob/humans/onmob/clothing/uniforms/uniforms_by_faction/groundside_military.dmi`
  - `icons/mob/humans/onmob/clothing/uniforms/uniforms_by_faction/groundside_wy_misc.dmi`
  - `icons/mob/humans/onmob/inhands/items/groundside_support_lefthand.dmi`
  - `icons/mob/humans/onmob/inhands/items/groundside_support_righthand.dmi`
- Repoints added in affected item/uniform definitions.

## Validation Commands
- `git diff --check` -> pass.
- `tools/build/build.bat --ci dm -DCIBUILDING -DANSICOLORS -Werror` -> pass (`0 errors, 0 warnings`).
- `tools/build/build.bat --ci lint tgui-test` -> pass.
- `tools/bootstrap/python -m dmi.test` -> pass (`successfully parsed 1317 .dmi files`).
- `tools/bootstrap/python -m tools.maplint.source --github` -> fails in this environment (`ModuleNotFoundError: No module named 'tools'`).
- `tools/bootstrap/python -c "import sys, runpy; sys.path.insert(0, '.'); runpy.run_module('tools.maplint.source', run_name='__main__')" --github` -> pass (`OK` across map set).
- `tools/bootstrap/python -m mapmerge2.dmm_test` -> pass (`successfully parsed 256 .dmm files`).
- `tools/build/build.bat --ci dm -DCIBUILDING -DCITESTING -DALL_MAPS -DALL_MAPS_STAGE_BASE` -> pass (`0 errors, 0 warnings`).
- `tools/build/build.bat --ci dm -DCIBUILDING -DCITESTING -DALL_MAPS -DALL_MAPS_STAGE_EXTRA` -> pass (`0 errors, 0 warnings`).
