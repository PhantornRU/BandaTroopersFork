# HALO PORT BACKLOG

Active tracking document for the HALO PVE update task on BandaTroopers.

## Current Track
- Source repositories:
  - `https://github.com/cmss13-devs/cmss13-pve-halo` (CM-PVE-HALO)
  - `https://github.com/cmss13-devs/cmss13-pve` (CM-PVE)
- Current merged BT master baseline: `upstream/master @ 5d2ad73b68727b88c7b02cf005a4af72f855babd` (PR #96)
- Target upstream master: `787d28227b`
- Active task: Comprehensive upstream sync - port all must-port open PRs from CM-PVE and CM-PVE-HALO into [`modular/halo`](modular/halo) and `code/**` (with SS220 EDIT markers)
- Task-state contract: [`modular/__agents/.AI_AGENT/PLAN.md`](../../__agents/.AI_AGENT/PLAN.md), [`TODO.md`](../../__agents/.AI_AGENT/TODO.md), [`DECISIONS.md`](../../__agents/.AI_AGENT/DECISIONS.md), [`EVIDENCE.md`](../../__agents/.AI_AGENT/EVIDENCE.md)

## Historical Context
- Previous task: PR #94 refresh after PR #96 merge (completed, see git history)
- 2026-04-28 modular asset audit completed (HALO assets moved to `modular/halo/icons/**` and `modular/halo/sound/**`)
- PR #102 ported merged PRs from CM-PVE-HALO (#137, #153, #154, #170, #173, #162, #156 core)
- Current task supersedes previous backlog items and expands to include all must-port open PRs

## Implementation Batches

### Batch 1: CM-PVE-HALO Priority 1 (Trivial/Small)
- **Status**: PENDING
- **PRs**:
  - #167 Muzzle Flash Attach Fix (1 line)
  - #164 Titan rename to Voyager (7 lines)
  - #155 ODST Drop Pod Intro Blurb (12 lines)
  - #152 Fences (6 lines)
  - #171 Shipmap lighting verb (38 lines)
- **Dependencies**: None
- **Stop criteria**: All 5 PRs ported, compile check passes, no upstream path references remain

### Batch 2: CM-PVE-HALO Priority 2 (Medium)
- **Status**: PENDING
- **PRs**:
  - #143 BR55 Recoil (gameplay fix)
  - #165 SPNKR A-A Random Outcome
  - #163 Halo Minimap Fix
  - #176 Thermite Grenades
  - #179 CE-like uniforms
  - #159 Shotgun & sniper ammo boxes
- **Dependencies**: Batch 1 complete
- **Stop criteria**: All 6 PRs ported, compile check passes, gameplay balance reviewed

### Batch 3: CM-PVE-HALO Priority 3 (Large)
- **Status**: PENDING
- **PRs**:
  - #166 ODST VISR (163 lines)
  - #178 Chemlights & Flares (379 lines)
  - #174 UNSC loose-ammo packets (326 lines)
  - #158 Fire Support Binos Support (543 lines)
  - #157 UNSC Medals Enabled (688 lines) — PORTED (2026-06-05)
  - #150 Loadout selection changes (686 lines)
  - #160 Holy Redoubts (3300 lines, map templates)
- **Dependencies**: Batch 2 complete
- **Stop criteria**: All 7 PRs ported, compile check passes, map validation for #160, loadout system tested

### Batch 4: CM-PVE Must-Port
- **Status**: PENDING
- **PRs**:
  - #1289 Observer Faction Categories (+37/-1, QoL)
  - #1288 Anti Air - GM Choice (+143/-23, SPNKR AA)
  - #1287 Gas Mask Vision Impairment (+41/-3, balance)
- **Dependencies**: Batch 3 complete (to avoid conflicts with HALO changes)
- **Stop criteria**: All 3 PRs ported, compile check passes, GM verbs tested
- **Note**: These PRs modify `code/**` and require `SS220 EDIT` markers

### Batch 5: CM-PVE Maybe-Port (Evaluation)
- **Status**: PENDING
- **PRs**:
  - #1278 Call ur hits (+104)
  - #1269 Snowman (+565/-3, CANC presets)
  - #1264 Shipmap lighting GM verb (+28/-3)
  - #1268 Active prox_sensor (+16)
- **Dependencies**: Batch 4 complete
- **Stop criteria**: Each PR evaluated, porting decisions documented in DECISIONS.md

### Batch 6: Final Validation and Docs Sync
- **Status**: PENDING
- **Actions**:
  - Full compile check with `BUILD.cmd` or `tools/build/build`
  - Update [`HALO_PORT_STATE.md`](HALO_PORT_STATE.md) with new baseline
  - Update task-state files with implementation status
  - Old path audit: verify no `modular_pve_halo/` or root `icons/halo/` references remain
  - Map validation for PR #160 (Holy Redoubts)
  - Loadout system test for PR #150
  - GM verb test for CM-PVE PRs #1288, #1289

## Previously Ported PRs (from PR #102)
- #137 Weapon Modularization (split/adapt)
- #153 `iscovenant` typecheck
- #154 New UNSC grenades
- #170 New covenant squads
- #173 Unggoy plasma grenade loadouts
- #162 Elite Hero subtypes
- #156 Presets/vendor/med updates (core)

## Skipped PRs

### Already Present/Superseded
- #146 (Motion Sensor HUD)
- #148 (grenade throwback)
- #161 (Sangheili Skills)
- #168 (jumping/leaping)
- #145 (bumblebee)
- #139 (covenant landmines)

### Non-Code PRs
- #138 (icons-only)
- #142 (map-only)
- #144 (codeowners)
- #177 (CI URL)
- #169, #136, #135, #134 (map changes)

### Needs-Review (from previous backlog)
- #120 (Halo Firesupport)
- #149 (RTO/ODST SL fixes)
- #151 (M7 SMG caseless/ODST rank)
- **Action**: Evaluate during Batch 5 or separately if needed

## Path Remapping Rules
- All upstream `modular_pve_halo/` paths remap to [`modular/halo`](modular/halo)
- Root `icons/halo/` paths remap to [`modular/halo/icons/**`](../icons)
- Root HALO sound paths remap to [`modular/halo/sound/**`](../sound)
- Minimal glue changes in [`code/**`](../../code) require `SS220 EDIT` markers per [`SS220_DEVELOPMENT_RULES.md`](../../__docs/SS220_DEVELOPMENT_RULES.md)

## Explicit Non-Goals
- Do not replace split/adapt with wrapper, fallback, or compatibility patch
- Do not leave upstream `modular_pve_halo/` paths in ported code
- Do not use root `icons/halo/` or root HALO sound paths for new/ported assets
- Do not blindly duplicate existing covenant content
- Do not collapse HALO modular code back into `code/**`
- Do not reintroduce wholesale upstream layout just to mirror filenames
- Do not skip compile check after any batch
- Do not replace path remapping with runtime translation

## Remaining Root Glue To Watch
- `code/game/sound.dm`: routes shared sound keys to modular HALO voice files
- `code/modules/mob/living/carbon/human/{emote,human_attackhand,human_defense,human_helpers}.dm`: shared species/combat hooks
- `code/modules/projectiles/{gun,gun_helpers,projectile}.dm`: shared Gun Ho and Mjolnir integration hooks
- `code/modules/mob/living/carbon/human/ai/action_datums/{mg_nest,sniper_nest}.dm`: Game Master menu exposure
- `code/modules/mob/living/carbon/human/death.dm`: pre-existing shared Warthog death/ejection callsite
- `code/__DEFINES/bandamarines/halo_species_support.dm`: shared compile-time HALO constants

## Completion Check
- All must-port PRs are ported with correct path remapping
- No upstream `modular_pve_halo/` paths remain in ported code
- No root `icons/halo/` or root HALO sound paths are used for new/ported assets
- All `code/**` changes have `SS220 EDIT` markers
- All ported files compile cleanly
- `HALO_PORT_STATE.md` reflects the new baseline
- Task-state files are updated with implementation status
- Maybe-port PRs are evaluated and decisions documented
- Map validation passes for PR #160
- Loadout system works after PR #150
- GM verbs work after CM-PVE PRs #1288, #1289

## PR Summary Table

### CM-PVE-HALO Must-Port (17 PRs)
| Priority | PR | Title | Lines | Risk | Status |
| --- | --- | --- | --- | --- | --- |
| 1 | #167 | Muzzle Flash Attach Fix | 1 | Low | PENDING |
| 1 | #164 | Titan rename to Voyager | 7 | Low | PENDING |
| 1 | #155 | ODST Drop Pod Intro Blurb | 12 | Low | PENDING |
| 1 | #152 | Fences | 6 | Low | PENDING |
| 1 | #171 | Shipmap lighting verb | 38 | Low-Medium | PENDING |
| 2 | #143 | BR55 Recoil | - | Medium | PENDING |
| 2 | #165 | SPNKR A-A Random Outcome | - | Medium | PENDING |
| 2 | #163 | Halo Minimap Fix | - | Medium | PENDING |
| 2 | #176 | Thermite Grenades | - | Medium | PENDING |
| 2 | #179 | CE-like uniforms | - | Medium | PENDING |
| 2 | #159 | Shotgun & sniper ammo boxes | - | Medium | PENDING |
| 3 | #166 | ODST VISR | 163 | High | PENDING |
| 3 | #178 | Chemlights & Flares | 379 | High | PENDING |
| 3 | #174 | UNSC loose-ammo packets | 326 | High | PENDING |
| 3 | #158 | Fire Support Binos Support | 543 | High | PORTED (2026-06-05) |
| 3 | #157 | UNSC Medals Enabled | 688 | High | PORTED (2026-06-05) |
| 3 | #150 | Loadout selection changes | 686 | High | PENDING |
| 3 | #160 | Holy Redoubts | 3300 | Very High | PENDING |

### CM-PVE Must-Port (3 PRs)
| PR | Title | Lines | Risk | Status |
| --- | --- | --- | --- | --- |
| #1289 | Observer Faction Categories | +37/-1 | Low | PENDING |
| #1288 | Anti Air - GM Choice | +143/-23 | Medium | PENDING |
| #1287 | Gas Mask Vision Impairment | +41/-3 | Low-Medium | PENDING |

### CM-PVE Maybe-Port (4 PRs)
| PR | Title | Lines | Risk | Status |
| --- | --- | --- | --- | --- |
| #1278 | Call ur hits | +104 | TBD | EVALUATE |
| #1269 | Snowman | +565/-3 | TBD | EVALUATE |
| #1264 | Shipmap lighting GM verb | +28/-3 | TBD | EVALUATE |
| #1268 | Active prox_sensor | +16 | TBD | EVALUATE |