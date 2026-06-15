# HALO PORT STATE

Canonical source of truth for the current HALO modular sync state on BandaTroopers.

## Active Baseline

- Source repository: `https://github.com/cmss13-devs/cmss13-pve-halo`
- Current merged BT master baseline: `upstream/master @ 5d2ad73b68727b88c7b02cf005a4af72f855babd`
- Meaning of that baseline: merged BT `PR #96` (`[HALO] Sync follow-up main wave`)
- **Comprehensive upstream sync baseline**: `halo-pve-update-batch1-3b @ 5f1e274056` (PR #102, 2026-06-09)
- Meaning of sync baseline: all 27 must-port PRs from CM-PVE-HALO ported, validated, documented, and review-fixes applied
- Current gameplay-completion branch: `halo_jackal_spartan_wave_apr2026`
- Pre-refresh PR94 branch head before the master update: `6760808e61a60c596784bde67a8b6a594f57c089`
- Current upstream audit source for HALO content parity: `cmss13-devs/cmss13-pve-halo/master @ a4943e1cd28387b86e47ba282a8cd06e7b953c96`

## Branch Scope

- `PR #96` is already merged into BT master and is treated as the shared HALO base.
- `PR #102` (`halo-pve-update-batch1-3b`) — comprehensive upstream sync: 27 must-port CM-PVE-HALO PRs.
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
- Root `icons/halo/**`, `sound/voice/{sangheili,unggoy,ruuhtian}/`, `sound/vehicles/`, `icons/mob/humans/template_64.dmi`, `icons/obj/items/weapons/covenant_mines.dmi`, and New Irvine root flora/auto-turf DMI copies are treated as migrated-out legacy paths.
- The old root Warthog implementation was moved from `code/modules/vehicles/warthog/**` to `modular/halo/code/modules/vehicles/warthog/**`; the only remaining root Warthog reference is shared death/ejection glue.
- Root generic `icons/obj/items/clothing/{gloves,shoes}.dmi` were reduced to a targeted removal of the old HALO `spartan` state only. The replacement states live in `modular/halo/icons/obj/items/clothing/spartan_{gloves,shoes}.dmi`.
- PR96 generic root DMI candidates `icons/obj/structures/machinery/yautja_machines.dmi`, `icons/obj/structures/props/ground_map64.dmi`, and `icons/obj/structures/props/maptable.dmi` were compared against the pre-PR96 parent. They had no added, removed, or pixel-changed icon states, so no modular extraction was needed.
- Root `code/**` still contains integration hooks for typechecks, emotes/sounds, combat damage, gun skill effects, HumanAI menus, and unit-test normalization. Those are shared callsites and must stay explicitly marked as `SS220 EDIT` glue.

## Intentional Deviations From Upstream

- Kig-Yar content remains under the BT `ruuhtian` layout instead of restoring upstream file names.
- Spartan runtime stays modular through `modular/halo/**`; no HALO gameplay code is moved back into generic upstream gun or species trees.
- Covenant split-faction behavior is preserved through BT modular faction surfaces even when upstream used a different file layout.
- Public HALO equipment presets are allowed to carry split-faction ownership when that is required for `Create Humans`, `HumanAI Spawn`, or `Squad Spawner` parity.

### Resolved Deviations (2026-06-10)

All 6 previously deferred intentional deviations from PR #102 comprehensive upstream sync have been ported:

| PR | Title | Resolution |
|----|-------|------------|
| #163 | Halo Minimap Fix | PORTED — conditional faction/minimap logic in `code/modules/almayer/machinery.dm` and `code/modules/cm_marines/overwatch.dm`; new defines `MOB_HUD_FACTION_COVENANT`, `UNSC_COMMAND_ANNOUNCE`; covenant radio hud_type/minimap_type; headset marker_flags conditional |
| #158 | Fire Support Binos Support | PORTED — full fire support restructure: new defines, type path restructuring, `ignore_availability` param, radial menu 48→72, new UNSC binoculars, ammo mix crates, GM faction changes (MARINE/UPP→UNSC/COVENANT), `icons/mob/radial.dmi` binary update |
| #150 | Loadout selection changes | PORTED — loadout rework in `preferences_gear.dm`, new modular files (helmet_visors, helmetgarb, storage/fancy, storage/misc, clothing/head, clothing/masks, clothing/under/ties, equipment/maps), binary assets (devices.dmi, unsc_melee.dmi), map changes (tacmap_map items) |
| #174 | UNSC loose-ammo packets | PORTED — MA5/BR55/M6/M7 ammo packet boxes, `packets.dmi` binary, map changes |
| #159 | Shotgun & sniper ammo boxes | PORTED — shotgun/sniper handful boxes, `handful_state` updates, ammo crate changes, binary assets (boxes_and_lids.dmi, magazines.dmi, handful.dmi), map changes |
| #157 | UNSC Medals Enabled | PORTED — medal name defines, `GLOBAL_LIST_INIT human_medals` expanded, "USCM"→"UNSC" text replacements, medal desc updates in `code/modules/clothing/under/ties.dm` |

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
- **PR #102 comprehensive upstream sync validation (2026-06-05)**:
  - **Compile**: `BUILD.cmd` — 0 errors, 0 warnings
  - **git diff --check**: PASSED
  - **modular_pve_halo/ path audit**: 0 occurrences in code/ and modular/
  - **Root icons/halo/ path audit**: 0 occurrences (all use modular/halo/icons/halo/ prefix)
  - **SS220 EDIT audit (code/)**: All 30 code/ files properly marked with START/END blocks
  - **SS220 EDIT audit (modular/)**: Only 2 legacy occurrences, no new markers
  - **maplint (PR #160 templates)**: All 14 map templates OK
  - **Binary assets**: 12 .dmi icons + 9 .ogg sounds downloaded from upstream
  - **Files changed**: 56 files, +4541/-312 lines
  - **All 27 must-port CM-PVE-HALO PRs**: PORTED
  - **Review fixes applied** (commit `5f1e274056`):
    - C3: `.roo/` files removed from git index
    - M1: Duplicate `HALO_PORT_BACKLOG.md` removed from git index
    - C1: 42 root sound files removed from git index, migrated to `modular/halo/sound/`
    - M2: Paths updated in `halo_dropship.dm`
    - L1: Clean build — 0 errors, 0 warnings
  - **Sound modularity migration stats** (review fix pass):
    - 42 additional `.ogg` files migrated from root `sound/` to `modular/halo/sound/`:
      - `sound/effects/dropship_hover/` → `modular/halo/sound/effects/dropship_hover/` (5 files)
      - `sound/voice/twe_warcry/` → `modular/halo/sound/voice/twe_warcry/` (19 files)
      - `modular/halo/sound/weapons/pelican_gun/` → `modular/halo/modular/halo/sound/weapons/pelican_gun/` (5 files)
      - `modular/halo/sound/weapons/phantom_gun/` → `modular/halo/modular/halo/sound/weapons/phantom_gun/` (13 files)
    - 2 `.dm` files updated with modular paths: `code/game/sound.dm`, `modular/halo/code/datums/looping_sounds/halo_dropship.dm`
    - Total sound assets in modular path: 176 (original) + 42 (this pass) = **218**
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

## 2026-06-14 HALO Modular Correction

- **Context**: Previous modular migration placed HALO-specific files (`helmet_visors.dm` VISR, `shipmap_light_change.dm`) into `modular/cm_pve/` instead of `modular/halo/`. This violated the "HALO has its own separate modular" rule.
- **Correction**:
  - `shipmap_light_change.dm` (HALO PR #171) moved to `modular/halo/code/modules/admin/game_master/extra_buttons/shipmap_light_change.dm`
  - `helmet_visors.dm` VISR content merged into existing `modular/halo/code/game/objects/items/devices/helmet_visors.dm` (appended after IHADSS visor)
  - `halo_jobs.dm` duplicate removed from `modular/cm_pve/` (defines already live in `code/__DEFINES/halo_jobs.dm` as required glue for `code/` consumers)
- **DME updates**:
  - `modular/halo/_halo.dme`: added `#include` for `shipmap_light_change.dm`
  - `modular/cm_pve/_cm_pve.dme`: removed HALO-specific includes
- **Compile**: `BUILD.cmd` — 0 errors, 0 warnings
- **CM-PVE module** retains pure CM-PVE content: `vai.dm`, `dog_war.dm`, `twe_tank/`, `heavy_autocannon.dm`

## Ported PRs Reference

### CM-PVE-HALO (https://github.com/cmss13-devs/cmss13-pve-halo)

| PR | Title | Status | Notes |
|----|-------|--------|-------|
| #182 | Featureless biomes | **PORTED** | 5 new featureless biome maps (Space, Barrens, Desert, Jungle, Arctic) |
| #181 | SoutoATV renamed to mongoose | **PORTED** | Added `/obj/vehicle/souto/mongoose` subtype |
| #180 | Wort wort wort, lohbaba! | **PORTED** | Covenant voice lines |
| #179 | CE-like uniforms | **PORTED** | CE-style UNSC uniforms |
| #178 | Chemlights & Flares | **PORTED** | Chemlight and flare items |
| #176 | Thermite Grenades | **PORTED** | UNSC thermite grenades. LOW: `prime()` не проверяет `IMPACT_FUSE` (родительский метод проверяет); upstream-паттерн, `dual_purpose = FALSE`, не блокирует. |
| #174 | UNSC loose-ammo packets | **PORTED** | Loose ammo packets for UNSC |
| #173 | Plasma grenade loadouts for Unggoy | **PORTED** | Unggoy plasma grenade loadouts |
| #172 | RTO-bag sprite issues | **PORTED** | RTO bag sprite fixes |
| #171 | Shipmap lighting verb | **PORTED** | GM shipmap lighting verb |
| #170 | New covenant squads | **PORTED** | New Covenant squad types |
| #169 | Featureless Biomes | **PORTED** | Featureless biome maps (Jungle Delta, Prospector Canyon, Arctic Valley) |
| #168 | Jumping and Leaping | **ALREADY PRESENT** | Already in BT |
| #167 | Muzzle Flash Attach Fix | **PORTED** | 1-line muzzle flash fix |
| #166 | ODST VISR v0.1 | **PORTED** | ODST VISR system |
| #165 | SPNKR A-A: Random Outcome | **PORTED** | SPNKR anti-air random outcome |
| #164 | Titan rename to Voyager | **PORTED** | Titan → Voyager rename |
| #163 | Halo Minimap Fix | **PORTED** | Minimap fixes for HALO |
| #162 | Elite "Hero" subtypes | **PORTED** | Sangheili hero subtypes |
| #160 | Holy Redoubts | **PORTED** | Map templates (14 templates) |
| #159 | Shotgun & sniper ammo boxes | **PORTED** | Ammo boxes for shotguns/snipers |
| #158 | Fire Support Binos Support | **PORTED** | Fire support binoculars |
| #157 | UNSC Medals Enabled | **PORTED** | UNSC medal system |
| #156 | Presets updates, Vendor tweaks | **PORTED** | Preset and vendor updates |
| #155 | ODST Drop Pod - Intro Blurb | **PORTED** | ODST drop pod intro text |
| #152 | Fences | **PORTED** | Fence structures |
| #150 | Loadout selection changes | **PORTED** | Loadout UI changes |
| #145 | bumblebee | **ALREADY PRESENT** | Bumblebee escape pod |

### CM-PVE

For CM-PVE PRs see [`CM_PVE_PORT_STATE.md`](../../__docs/CM_PVE_PORT_STATE.md).

### Branch Commit History

All commits on `halo-pve-update-batch1-3b` (in order):

| Commit | Description |
|--------|-------------|
| `44a127c` | HALO PVE Update: Batch 1-3B (PR #137, #153, #154, #170, #173, #162, #163, #164, #165, #166, #167, #168, #169, #171, #172, #174, #175, #176, #177, #178) |
| `70f6a6d` | Update .gitignore |
| `bc1496f` | Restore AI_AGENT task-state files to baseline state (pre-PR #102) |
| `a915711` | Clean up duplicate .gitignore entries for AI_AGENT task-state files |
| `3cbef88` | Comprehensive upstream sync: Batch 1-4 (CM-PVE-HALO + CM-PVE) |
| `ade8dd5` | Final upstream sync: all must-port PRs complete (Batch 1-4 + deferred items) |
| `46915d6` | Add missing .dmi assets for PR #150 loadout items (devices, unsc_melee) |
| `ed39ab4` | Update HALO port documentation: all PRs marked as PORTED |
| `d7e2e7e` | Migrate HALO sounds to modular path |
| `5f1e274` | fixup! PR #102 review fixes |

## Update Protocol

- If the HALO upstream baseline changes again, update this file in the same change.
- If `PR #94` scope expands or contracts, record the decision here and mirror the work split in `HALO_PORT_BACKLOG.md`.
- If this file disagrees with older port notes, this file wins.
- For CM-PVE PRs, see [`CM_PVE_PORT_STATE.md`](../../__docs/CM_PVE_PORT_STATE.md).
- For complete porting history, see [`VARIOUS_FIXES_PORTING_MAP.md`](../../__docs/VARIOUS_FIXES_PORTING_MAP.md).
