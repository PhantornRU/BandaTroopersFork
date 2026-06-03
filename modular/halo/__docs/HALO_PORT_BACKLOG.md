# HALO PORT BACKLOG

Active tracking document for the HALO PVE update task on BandaTroopers.

## Current Track
- Source repository: `https://github.com/cmss13-devs/cmss13-pve-halo`
- Current merged BT master baseline: `upstream/master @ 5d2ad73b68727b88c7b02cf005a4af72f855babd` (PR #96)
- Target upstream master: `787d28227b`
- Active task: HALO PVE Update - port all merged and open HALO PVE changes from upstream into [`modular/halo`](modular/halo)
- Task-state contract: [`modular/__agents/.AI_AGENT/PLAN.md`](../../__agents/.AI_AGENT/PLAN.md), [`TODO.md`](../../__agents/.AI_AGENT/TODO.md), [`DECISIONS.md`](../../__agents/.AI_AGENT/DECISIONS.md), [`EVIDENCE.md`](../../__agents/.AI_AGENT/EVIDENCE.md)

## Historical Context
- Previous task: PR #94 refresh after PR #96 merge (completed, see git history)
- 2026-04-28 modular asset audit completed (HALO assets moved to `modular/halo/icons/**` and `modular/halo/sound/**`)
- Current task supersedes previous backlog items

## Implementation Batches

### Batch 1: PR #137 Weapon Modularization
- **Status**: PENDING
- **Scope**: Split [`modular/halo/code/modules/projectiles/guns/halo/unsc_guns.dm`](../code/modules/projectiles/guns/halo/unsc_guns.dm) into modular subdirectories
- **Target paths**:
  - [`modular/halo/code/modules/projectiles/guns/pistol/unsc.dm`](../code/modules/projectiles/guns/pistol/unsc.dm)
  - [`modular/halo/code/modules/projectiles/guns/rifle/unsc.dm`](../code/modules/projectiles/guns/rifle/unsc.dm)
  - [`modular/halo/code/modules/projectiles/guns/shotgun/unsc.dm`](../code/modules/projectiles/guns/shotgun/unsc.dm)
  - [`modular/halo/code/modules/projectiles/guns/smg/unsc.dm`](../code/modules/projectiles/guns/smg/unsc.dm)
  - [`modular/halo/code/modules/projectiles/guns/specialist/sniper/unsc.dm`](../code/modules/projectiles/guns/specialist/sniper/unsc.dm)
  - [`modular/halo/code/modules/projectiles/guns/magazines`](../code/modules/projectiles/guns/magazines)
  - [`modular/halo/code/modules/clothing/glasses/glasses.dm`](../code/modules/clothing/glasses/glasses.dm)
  - UNSC grenade file (path TBD after local structure read)
- **Constraint**: Must be split/adapt, not wrapper/fallback/compat patch
- **Audit**: Existing covenant guns/melee/magazines/SPNKR/attachables in [`modular/halo/code/modules/projectiles/guns/halo`](../code/modules/projectiles/guns/halo) must not be blindly duplicated

### Batch 2: Merged MUST-PORT PRs
- **Status**: PENDING
- **PRs**: #140 (weapon sprite line), #143 (BR55 recoil), #153 (`iscovenant` typecheck), #154 (new UNSC grenades)

### Batch 3: Open MUST-PORT PRs
- **Status**: PENDING
- **PRs**: #173 (Unggoy plasma grenade loadouts), #170 (new covenant squads), #162 (Elite Hero subtypes), #156 (presets/vendor/med updates)

### Batch 4: Needs-Review PRs
- **Status**: PENDING
- **PRs**: #120 (Halo Firesupport), #149 (RTO/ODST SL fixes), #151 (M7 SMG caseless/ODST rank)
- **Action**: Evaluate for applicability before porting

### Batch 5: Maybe-Port Open PRs
- **Status**: PENDING
- **PRs**: #179, #178, #176, #174, #172, #171, #167, #166, #165, #164, #163, #160, #159, #158, #157, #155, #152, #150, #141
- **Action**: Evaluate and port if applicable; user requested all HALO PVE PR changes

### Batch 6: Final Validation and Docs Sync
- **Status**: PENDING
- **Actions**:
  - Compile check with `BUILD.cmd` or `tools/build/build`
  - Update [`HALO_PORT_STATE.md`](HALO_PORT_STATE.md) with new baseline
  - Update task-state files with implementation status
  - Old path audit: verify no `modular_pve_halo/` or root `icons/halo/` references remain

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

## Path Remapping Rules
- All upstream `modular_pve_halo/` paths remap to [`modular/halo`](modular/halo)
- Root `icons/halo/` paths remap to [`modular/halo/icons/**`](../icons)
- Root HALO sound paths remap to [`modular/halo/sound/**`](../sound)
- Minimal glue changes in [`code/**`](../../code) require `SS220 EDIT` markers

## Explicit Non-Goals
- Do not replace PR #137 split with a wrapper, fallback, or compatibility patch
- Do not leave upstream `modular_pve_halo/` paths in ported code
- Do not use root `icons/halo/` or root HALO sound paths for new/ported assets
- Do not blindly duplicate existing covenant content
- Do not collapse HALO modular code back into `code/**`
- Do not reintroduce wholesale upstream layout just to mirror filenames

## Remaining Root Glue To Watch
- `code/game/sound.dm`: routes shared sound keys to modular HALO voice files
- `code/modules/mob/living/carbon/human/{emote,human_attackhand,human_defense,human_helpers}.dm`: shared species/combat hooks
- `code/modules/projectiles/{gun,gun_helpers,projectile}.dm`: shared Gun Ho and Mjolnir integration hooks
- `code/modules/mob/living/carbon/human/ai/action_datums/{mg_nest,sniper_nest}.dm`: Game Master menu exposure
- `code/modules/mob/living/carbon/human/death.dm`: pre-existing shared Warthog death/ejection callsite
- `code/__DEFINES/bandamarines/halo_species_support.dm`: shared compile-time HALO constants

## Completion Check
- All MUST-PORT PRs are ported with correct path remapping
- PR #137 weapon modularization is implemented as split/adapt
- No upstream `modular_pve_halo/` paths remain in ported code
- No root `icons/halo/` or root HALO sound paths are used for new/ported assets
- Existing covenant content is not blindly duplicated
- All ported files compile cleanly
- `HALO_PORT_STATE.md` reflects the new baseline
- Task-state files are updated with implementation status
