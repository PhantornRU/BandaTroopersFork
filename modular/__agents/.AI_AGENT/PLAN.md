# PLAN

## Active task
Port the HALO Jackal and Spartan waves into a separate BandaTroopers PR on top of `master`, while keeping the larger April sync wave tracked separately.

## Scope
- Port upstream `cm-pve-halo/pr-97` (`Jackal framework`) into local modular surfaces with the minimum required core glue.
- Port upstream `cm-pve-halo/pr-100` (`Spartan stuff`) with the largest safe compatible surface first, then continue into the remaining combat, input, and runtime parity pieces required for a defensible port.
- Add Jackal AI presets, squad presets, spawn coverage, and lore-aligned mixed Covenant squads for BandaTroopers.
- Record exact coverage, intentional deviations, and stop points for `#97`, `#100`, and the already tracked April sync PRs in the HALO port documentation.
- Publish the result as a separate PR against `SS220Club/BandaTroopers`.

## Out of scope
- Folding this work into the already-open April sync PR `#93`.
- Reverting unrelated local changes outside the HALO port surface.
- Claiming upstream parity without documenting skipped or intentionally deferred chunks.

## Acceptance criteria
- The branch stays based on `master` and produces a separate reviewable PR.
- Jackal content is present end-to-end: species, gear, clothing, language, organs, sounds, storage, AI presets, squad presets, and spawn access.
- Jackal squads are added in lore-consistent Covenant compositions rather than as isolated one-off spawns only.
- Spartan content is ported with working species, gear, clothing, storage, presets, and any required combat/input support that the implementation depends on.
- `HALO_PORT_BACKLOG.md` records exact PR coverage and stop points for this branch and the related April sync branch.
- `git diff --check` and the relevant build verification pass before publishing.

## Current status
- Porting and compile validation are complete.
- Remaining work is publication: commit stack, push, and PR creation against `SS220Club/BandaTroopers`.
