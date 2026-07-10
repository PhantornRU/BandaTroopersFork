# EVIDENCE - Canonical Building Layout Solver Rewrite

## Read-only discovery

Date: 2026-07-10

- Active review and current sprites show false-green layouts: living remains large rectangular cells around a route; storage/workshop contain sparse stripes/mosaics despite zero hard counters.
- Current entrypoint branches at `use_building_layout_v2(request)`: living uses the v2 solver, every other program uses `/datum/world_edit_generation_stage/**`.
- Current v2 still uses coordinate-derived influence zones/route bands and `switch(scene_contract.id)` for final scene recipes.
- The archetype catalog already declares all 15 programs, zones, adjacency, privacy, clusters, providers, budgets and footprint families; it is the viable single program source.
- Existing provider/template/emitter and preview/apply/undo machinery is shared production infrastructure and is not itself the legacy layout algorithm.
- AI index is absent; targeted `rg` and direct reads are the repository discovery path.
- Dirty worktree contains the completed living partition/opening slice and active review additions; these changes are preserved.

## Self plan-mapping challenge

Status: PASS WITH RISKS

- PASS: canonical solver can replace the branch at the existing candidate-state entrypoint without changing generator id or public UI fields.
- PASS: zone/adjacency/cluster declarations can compile room, connection and placement-module contracts for all programs.
- PASS: existing v2 trial emission and opening policy are a usable baseline for the canonical solver.
- RISK: existing declarations lack explicit repeatable-room/partition fields. Mitigation: extend zone specs and validate every program contract before enabling the canonical entrypoint.
- RISK: some legacy fixture helpers mix orchestration with reusable placement primitives. Mitigation: callsite audit and split/delete high-level entrypoints; no retained fallback.
- RISK: all-program search cost. Mitigation: approved candidate/room/route/anchor/module caps plus deterministic progress invariants.
- RISK: metrics can remain false-green. Mitigation: synthetic bad-layout tests, full semantic matrix and manual sprite review.

## Old-path baseline

- `building_layout_v2_enabled()` and `use_building_layout_v2()` gate v2 to living.
- `world_edit_generator_building_layout.dm` constructs 17 legacy stages for non-living programs.
- `building_layout_v2_living.dm` owns the only v2 program contract and all v2 patterns.
- `building_layout_v2_solver.dm::build_building_v2_scene_plan()` switches on scene contract id.
- Unit tests explicitly force `use_layout_v2 = FALSE` for legacy room-fill/divider behavior.

## Plan fidelity matrix

| ID | Type | Requirement | Evidence | Status |
| --- | --- | --- | --- | --- |
| M1 | MUST | Refresh contract and preserve baseline. | Task-state plus clean discovery of current dirty scope. | DONE |
| M2 | MUST | Self challenge and old-path map. | Sections above. | DONE |
| M3-M10 | MUST | Canonical rewrite and removal. | Pending implementation evidence. | PENDING |
| C1-C3 | CHECK | Verification and visual acceptance. | Pending. | PENDING |

## Implementation progress 2026-07-10

- `v2/` moved to `solver/`; canonical `building_layout_*` type/metric names replace v2 names, staged generation files were deleted, and the generator calls the solver directly.
- The archetype catalog now compiles every program into room, connection, scene, module and budget contracts. Repeated room demands are explicit instances, and target mismatch emits `program.target_room_count_unreachable`.
- Generic scene placement is active without `switch(scene_contract.id)`. Exact zone matches take precedence over generic anchor tags; scene identity derives from declared module classes.
- Compile evidence: `BUILD.cmd --ci dm -DUNIT_TESTS` succeeds with zero errors and warnings after the canonical solver changes.
- `building_living_target_rooms_6` passes ordinary visual acceptance with exact six rooms and two hard-valid candidates.
- Isolated visual rendering was used only to generate representative sprites; it does not execute report expectations. Ordinary visual acceptance for storage and the remaining matrix is still open while route-after-room allocation is being finished.
