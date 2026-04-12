# PLAN

## Active Task
Complete the next HALO upstream sync wave from `cmss13-devs/cmss13-pve-halo` into BandaTroopers with two separate deliverables:
- main sync PR for the current HALO build delta plus upstream PRs `#114`, `#116`, `#121`, `#123`, `#126`, `#132` and any still-missing merged commits since the pinned baseline;
- follow-up PR for upstream PRs `#97` and `#100`, including spawn integration and Jackal covenant squads aligned with lore.

## Scope
- Reconfirm the exact upstream sync range from the currently pinned HALO baseline to the selected new pin.
- Record the sync point, targeted PRs, already-ported parts, partial local ports, and intentional deviations in HALO port documentation.
- Finish incomplete local ports for `#114` and `#121` without regressing existing BandaTroopers-specific integration.
- Port missing content for `#116`, `#123`, `#126`, and `#132` with modular-first ownership.
- Fold in any merged upstream HALO changes in the same range that are still absent locally.
- Prepare separate branch/commit history/PR body for the `#97` + `#100` wave and connect that content to spawns.

## Out Of Scope
- Unrelated non-HALO upstream sync work.
- Reverting existing BandaTroopers-specific HALO architecture decisions that were already documented as intentional deviations.
- Mixing the `#97` + `#100` gameplay/spawn wave into the main HALO sync PR.

## Execution Strategy
- Treat `modular/halo/__docs/HALO_PORT_STATE.md` as the baseline anchor and `modular/halo/__docs/HALO_PORT_BACKLOG.md` as the wave tracker.
- Keep HALO content in `modular/halo/**` whenever possible; touch `code/**` only for minimal integration surfaces already used by the repo.
- Reuse previously landed local ports when the requested upstream PR is already fully or partially covered.
- Preserve BandaTroopers-specific map rotation, squad runtime, and modular integration while reconciling upstream changes.
- Produce detailed, reviewable commits grouped by coherent change themes and mirror that structure in the PR descriptions.

## Acceptance Criteria
- HALO port docs name the previous pin, the new target pin, the exact upstream PR/commit coverage, and the status of each requested PR.
- The main sync branch contains all requested upstream deltas except the explicitly separate `#97` + `#100` wave.
- The second branch contains the spawn-facing `#97` + `#100` content, including Jackal covenant squads.
- Both branches are validated with the available repo build/test workflow to the extent feasible in this environment.
- Both PRs target `SS220Club/BandaTroopers` and include detailed descriptions and changelog-style commit structure.
