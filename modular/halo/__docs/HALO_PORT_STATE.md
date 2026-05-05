# HALO PORT STATE

Canonical source of truth for the current HALO modular sync state on BandaTroopers.

## Active Baseline
- Source repository: `https://github.com/cmss13-devs/cmss13-pve-halo`
- Current merged BT master baseline: `upstream/master @ 5d2ad73b68727b88c7b02cf005a4af72f855babd`
- Meaning of that baseline: merged BT `PR #96` (`[HALO] Sync follow-up main wave`)
- Current gameplay-completion branch: `halo_jackal_spartan_wave_apr2026`
- Pre-refresh PR94 branch head before the master update: `6760808e61a60c596784bde67a8b6a594f57c089`
- Current upstream audit source for HALO content parity: `cmss13-devs/cmss13-pve-halo/master @ a4943e1cd28387b86e47ba282a8cd06e7b953c96`

## Branch Scope
- `PR #96` is already merged into BT master and is treated as the shared HALO base.
- This branch owns only the follow-up gameplay completion needed for `PR #94` after that merge.
- Requested user-facing scope on this branch:
  - refresh `PR #94` from current master;
  - keep Kig-Yar/Ruuhtian and Spartan content modular-first;
  - finish playable preset, HumanAI, and squad coverage for Kig-Yar, Sangheili, Unggoy, Spartan, and the remaining HALO combat families that still had exposure gaps.

## Ownership Rules
- HALO content stays in `modular/halo/**` by default.
- `code/**` keeps only minimal glue already required by merged BT master, such as Game Master menu entries and shared faction hooks.
- `modular/squads/**` remains the owner of HALO job and platoon systems that were already split there.
- HALO icon and sound assets are owned by `modular/halo/icons/**` and `modular/halo/sound/**`.
- Root `icons/halo/**`, root HALO voice folders, and root HALO vehicle sounds are not valid owners for new or ported HALO assets.
- HALO-only states must not be injected into existing generic root `.dmi` files. If a generic root item needs a HALO state, the HALO branch must use a separate modular `.dmi` and point the HALO type at that file.
- Shared compile-time HALO constants that root glue must see live in `code/__DEFINES/bandamarines/halo_species_support.dm`; concrete species, presets, skills, pain, Warthog, and equipment content stay modular.

## 2026-04-28 Modularity Audit
- Current `PR #94` branch assets were normalized so Ruuhtian/Kig-Yar, Spartan, Sangheili, Unggoy, Warthog, New Irvine, Covenant mine, and PR96 HALO icon assets are resolved from `modular/halo/**`.
- Root `icons/halo/**`, `sound/voice/{sangheili,unggoy,ruuhtian}/`, `sound/vehicles/halo/`, `icons/mob/humans/template_64.dmi`, `icons/obj/items/weapons/covenant_mines.dmi`, and New Irvine root flora/auto-turf DMI copies are treated as migrated-out legacy paths.
- The old root Warthog implementation was moved from `code/modules/vehicles/warthog/**` to `modular/halo/code/modules/vehicles/warthog/**`; the only remaining root Warthog reference is shared death/ejection glue.
- Root generic `icons/obj/items/clothing/{gloves,shoes}.dmi` were reduced to a targeted removal of the old HALO `spartan` state only. The replacement states live in `modular/halo/icons/obj/items/clothing/spartan_{gloves,shoes}.dmi`.
- PR96 generic root DMI candidates `icons/obj/structures/machinery/yautja_machines.dmi`, `icons/obj/structures/props/ground_map64.dmi`, and `icons/obj/structures/props/maptable.dmi` were compared against the pre-PR96 parent. They had no added, removed, or pixel-changed icon states, so no modular extraction was needed.
- Root `code/**` still contains integration hooks for typechecks, emotes/sounds, combat damage, gun skill effects, HumanAI menus, and unit-test normalization. Those are shared callsites and must stay explicitly marked as `SS220 EDIT` glue.

## Intentional Deviations From Upstream
- Kig-Yar content remains under the BT `ruuhtian` layout instead of restoring upstream file names.
- Spartan runtime stays modular through `modular/halo/**`; no HALO gameplay code is moved back into generic upstream gun or species trees.
- Covenant split-faction behavior is preserved through BT modular faction surfaces even when upstream used a different file layout.
- Public HALO equipment presets are allowed to carry split-faction ownership when that is required for `Create Humans`, `HumanAI Spawn`, or `Squad Spawner` parity.

## Current Compatibility Hotspots
- `modular/halo/code/modules/gear_presets/Halo/{sangheili,unggoy,ruuhtian,spartan,covenant_master_sync}.dm`
- `modular/halo/code/modules/mob/living/carbon/human/ai/ai_spawner/{ai_presets_ruuhtian,ai_presets_sangheili,ai_presets_unggoy,ai_presets_unsc,ai_presets_spartan}.dm`
- `modular/halo/code/modules/mob/living/carbon/human/ai/squad_spawner/halo/{squad_covenant,squad_unsc,squad_spartan}.dm`
- `code/modules/mob/living/carbon/human/ai/action_datums/{mg_nest,sniper_nest}.dm`
- `code/__DEFINES/bandamarines/halo_species_support.dm`
- `modular/halo/code/modules/vehicles/warthog/**`
- `modular/halo/icons/**`
- `modular/halo/sound/**`
- `modular/halo/code/modules/unit_tests/halo_preset_coverage.dm`

## Validation Snapshot
- Last fully merged shared baseline validation belongs to BT `PR #96`.
- Post-merge validation for the earlier `PR #94` gameplay-completion pass was complete before the 2026-04-28 asset modularity cleanup.
- The 2026-04-28 asset modularity cleanup passed local compile/resource validation:
  - HALO root-path resource literal audit: no old `icons/halo/**`, root HALO voice, Warthog sound, Covenant mine, New Irvine flora, or New Irvine auto-turf references remain in DM/DME/DMM files.
  - `git diff --check`
  - `tools/ci/validate_dme.py < colonialmarines.dme`
  - `tools/bootstrap/python -m dmi.test`
  - `tools/build/build --ci dm -DCIBUILDING -DANSICOLORS -Werror`
  - `tools/build/build --ci dm -DCIBUILDING -DCITESTING -DALL_MAPS -DALL_MAPS_STAGE_BASE`
  - `tools/build/build --ci dm -DCIBUILDING -DCITESTING -DALL_MAPS_STAGE_EXTRA`
  - `tools/build/build --ci dm -DUNIT_TESTS -DCIBUILDING -DANSICOLORS -Werror`
- Residual local validation caveats:
  - Runtime unit-test execution was not rerun in this cleanup pass; only the `UNIT_TESTS` compile target was rebuilt cleanly.
  - Windows-local `maplint` previously hit a decoding failure on `maps/map_files/UNSC_Stalwart_Frigate/UNSC_Stalwart_Frigate.dmm`, so that remaining check should be treated as an environment-specific follow-up unless CI reproduces it.

## Update Protocol
- If the HALO upstream baseline changes again, update this file in the same change.
- If `PR #94` scope expands or contracts, record the decision here and mirror the work split in `HALO_PORT_BACKLOG.md`.
- If this file disagrees with older port notes, this file wins.
