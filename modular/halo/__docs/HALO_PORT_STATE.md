# HALO PORT STATE

Canonical source of truth for the current HALO modular sync state on BandaTroopers.

## Active Baseline
- Source repository: `https://github.com/cmss13-devs/cmss13-pve-halo`
- Current merged BT master baseline: `upstream/master @ 5d2ad73b68727b88c7b02cf005a4af72f855babd`
- Meaning of that baseline: merged BT `PR #96` (`[HALO] Sync follow-up main wave`)
- **Comprehensive upstream sync baseline**: `halo-pve-update-batch1-3b @ 5f1e274056` (PR #102, 2026-06-09)
- Meaning of sync baseline: all 20 must-port PRs from CM-PVE-HALO and CM-PVE ported, validated, documented, and review-fixes applied
- Current gameplay-completion branch: `halo_jackal_spartan_wave_apr2026`
- Pre-refresh PR94 branch head before the master update: `6760808e61a60c596784bde67a8b6a594f57c089`
- Current upstream audit source for HALO content parity: `cmss13-devs/cmss13-pve-halo/master @ a4943e1cd28387b86e47ba282a8cd06e7b953c96`

## Branch Scope
- `PR #96` is already merged into BT master and is treated as the shared HALO base.
- `PR #102` (`halo-pve-update-batch1-3b`) — comprehensive upstream sync: 20 must-port PRs across 4 batches.
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
  - **All 20 must-port PRs**: PORTED
  - **Review fixes applied** (commit `5f1e274056`):
    - C3: `.roo/` files removed from git index
    - M1: Duplicate `HALO_PORT_BACKLOG.md` removed from git index
    - C1: 42 root sound files removed from git index, migrated to `modular/halo/sound/`
    - M2: Paths updated in `halo_dropship.dm`
    - L1: Clean build — 0 errors, 0 warnings
  - **Sound modularity migration stats** (review fix pass):
    - 42 additional `.ogg` files migrated from root `sound/` to `modular/halo/sound/`:
      - `sound/effects/halo/dropship_hover/` → `modular/halo/sound/effects/halo/dropship_hover/` (5 files)
      - `sound/voice/twe_warcry/` → `modular/halo/sound/voice/twe_warcry/` (19 files)
      - `sound/weapons/halo/pelican_gun/` → `modular/halo/sound/weapons/halo/pelican_gun/` (5 files)
      - `sound/weapons/halo/phantom_gun/` → `modular/halo/sound/weapons/halo/phantom_gun/` (13 files)
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

## Update Protocol
- If the HALO upstream baseline changes again, update this file in the same change.
- If `PR #94` scope expands or contracts, record the decision here and mirror the work split in `HALO_PORT_BACKLOG.md`.
- If this file disagrees with older port notes, this file wins.

## Ported PRs Reference

### CM-PVE (https://github.com/cmss13-devs/cmss13-pve)

| PR | Title | Status |
|----|-------|--------|
| #1289 | Observer Faction Categories | PORTED |
| #1288 | Anti Air - GM Choice | PORTED |
| #1287 | Gas Mask Vision Impairment | PORTED |
| #1284 | Lazy Bunker Shipmaps | SKIP (DNM/maps) |
| #1283 | Movie-ish Sections | SKIP (DNM/maps) |
| #1282 | The Straya War | SKIP (DNM/TMONLY) |
| #1280 | Dog war atomized | SKIP (maps) |
| #1278 | Call ur hits | SKIP (PVE-only LARP) |
| #1277 | Movie-like Xeno Castes | SKIP (DNM) |
| #1276 | FV150 'Hobelar' | SKIP (DNM/TMONLY) |
| #1275 | Vanguard's Arrow | SKIP (DNM/TMONLY) |
| #1273 | Gibson & Kloos | SKIP (DNM) |
| #1272 | Koishi's landmines | SKIP (TM ONLY) |
| #1271 | Itsy Bitsy Buggers | SKIP (DNM) |
| #1270 | Featueless | SKIP (TM Only/maps) |
| #1269 | Snowman | ALREADY PRESENT |
| #1268 | Active prox_sensor | ALREADY PRESENT |
| #1267 | Wolfpack | SKIP (TM ONLY) |
| #1266 | D66-44 | SKIP (TM) |
| #1265 | Auriga's Folly | SKIP (DNM) |
| #1264 | Shipmap lighting GM verb | ALREADY PRESENT |

### CM-PVE-HALO (https://github.com/cmss13-devs/cmss13-pve-halo)

| PR | Title | Status |
|----|-------|--------|
| #180 | Wort wort wort, lohbaba! | PORTED |
| #179 | CE-like uniforms | PORTED |
| #178 | Chemlights & Flares | PORTED |
| #176 | Thermite Grenades | PORTED |
| #174 | UNSC loose-ammo packets | PORTED |
| #173 | Plasma grenade loadouts for Unggoy | PORTED |
| #172 | RTO-bag sprite issues | SKIP (icons-only) |
| #171 | Shipmap lighting verb | PORTED |
| #170 | New covenant squads | PORTED |
| #169 | Featureless Biomes | SKIP (maps) |
| #168 | Jumping and Leaping | ALREADY PRESENT |
| #167 | Muzzle Flash Attach Fix | PORTED |
| #166 | ODST VISR v0.1 | PORTED |
| #165 | SPNKR A-A: Random Outcome | PORTED |
| #164 | Titan rename to Voyager | PORTED |
| #163 | Halo Minimap Fix | PORTED |
| #162 | Elite "Hero" subtypes | PORTED |
| #160 | Holy Redoubts | PORTED |
| #159 | Shotgun & sniper ammo boxes | PORTED |
| #158 | Fire Support Binos Support | PORTED |
| #157 | UNSC Medals Enabled | PORTED |
| #156 | Presets updates, Vendor tweaks | PORTED (core) |
| #155 | ODST Drop Pod - Intro Blurb | PORTED |
| #152 | Fences | PORTED |
| #150 | Loadout selection changes | PORTED |
| #145 | bumblebee | ALREADY PRESENT |

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
