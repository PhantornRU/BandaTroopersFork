# HALO PORT BACKLOG

Secondary tracking document for the active `PR #94` refresh after HALO `PR #96` was merged into BT master.

## Current Track
- Source repository: `https://github.com/cmss13-devs/cmss13-pve-halo`
- Shared merged master baseline: `upstream/master @ 5d2ad73b68727b88c7b02cf005a4af72f855babd`
- Active branch: `halo_jackal_spartan_wave_apr2026`
- Primary user-facing goal: bring `PR #94` to a playable post-merge state without breaking SS220 modular ownership.

## Historical Inputs
- Original `PR #94` content already carried the base Kig-Yar and Spartan import.
- BT `PR #96` then landed the main HALO sync wave on master.
- The current branch therefore does not re-port main-wave scope. It layers gameplay completion on top of the merged base.

## Upstream Anchors Still Relevant Here
- `PR #97`: Kig-Yar framework plus late Unggoy tail
- `PR #100`: original Spartan import base already present on this branch
- Current upstream master audit: `a4943e1cd28387b86e47ba282a8cd06e7b953c96`

## Delivered On Current Head
- Refreshed the branch from BT master after `PR #96`; only the merge commit itself remains to conclude the refresh.
- Refreshed Kig-Yar/Ruuhtian preset ownership so split-faction behavior survives across:
  - `Create Humans`
  - `HumanAI Spawn`
  - `Squad Spawner Panel`
- Finished Sangheili and Unggoy preset exposure where legacy AI-only paths still hid playable variants or dropped correct subfaction ownership.
- Added modular Spartan HumanAI presets and Spartan squad presets.
- Expanded lore-aligned HALO squads so Kig-Yar, Sangheili, Unggoy, and Spartan groups have practical patrol, marksman, strike, and command variants.
- Extended HALO unit coverage for:
  - split-faction equipment preset contracts;
  - Kig-Yar and Spartan species contracts;
  - HumanAI preset faction wiring;
  - new squad preset path validity.
- Refreshed branch-facing docs and changelog text so `PR #94` no longer describes itself as only a narrow Kig-Yar tail.
- Completed the 2026-04-28 modular asset audit:
  - HALO DMI assets now live under `modular/halo/icons/**`;
  - HALO voice and Warthog sounds now live under `modular/halo/sound/**`;
  - old root Warthog code was moved into `modular/halo/code/modules/vehicles/warthog/**`;
  - Spartan generic glove/shoe states were split into dedicated modular DMI files instead of staying injected into root `icons/obj/items/clothing/*.dmi`;
  - root generic glove/shoe DMI diffs now only remove the old `spartan` state and do not carry unrelated icon state additions or pixel changes;
  - shared Ruuhtian/Spartan/Gun Ho compile constants were consolidated into `code/__DEFINES/bandamarines/halo_species_support.dm`;
  - root species/pain/skill/mob concrete definitions that were HALO-only were moved into `modular/halo/**`.

## Explicit Non-Goals
- Do not reopen merged `PR #96` scope except where the current master merge requires conflict resolution.
- Do not collapse HALO modular code back into `code/**`.
- Do not reintroduce wholesale upstream layout just to mirror filenames.
- Do not edit generic root DMI files for HALO icon states. New HALO states must be represented by modular DMI files and HALO type paths must point at those files.

## Remaining Root Glue To Watch
- `code/game/sound.dm`: only routes shared sound keys to modular HALO voice files.
- `code/modules/mob/living/carbon/human/{emote,human_attackhand,human_defense,human_helpers}.dm`: shared species/combat hooks only.
- `code/modules/projectiles/{gun,gun_helpers,projectile}.dm`: shared Gun Ho and Mjolnir integration hooks only.
- `code/modules/mob/living/carbon/human/ai/action_datums/{mg_nest,sniper_nest}.dm`: Game Master menu exposure only.
- `code/modules/mob/living/carbon/human/death.dm`: pre-existing shared Warthog death/ejection callsite only.

## Completion Check
- Merge state is clean after the pending merge commit is written.
- No unresolved conflict markers remain.
- HALO preset and squad surfaces expose playable Kig-Yar, Sangheili, Unggoy, and Spartan content under SS220 modular rules.
- Validation commands pass or any remaining failures are documented as pre-existing.
