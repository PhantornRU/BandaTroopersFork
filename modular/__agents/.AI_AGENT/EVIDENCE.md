# EVIDENCE - Canonical Building Layout Solver rewrite

## Baseline discovery 2026-07-17

- Approved contract: `modular/world_edit/docs/rework_docs/tech_rework/17.07.06_review.md`, read completely.
- `HEAD` is exactly `cc210d870f8fa774de38c59b83de86f09c933ff2`, the revision reviewed by the contract.
- Baseline worktree change is the untracked review document only; it remains untouched.
- Production path is one canonical pipeline: `build_building_layout_candidate_state() -> solve_building_layout() -> emit_building_layout_plan()`.
- `_world_edit.dme` still includes canonical solver files together with legacy room-graph, BSP and semantic paths.
- The visual tool consumes exported semantic/report state and does not own production geometry.

## Proven false-green paths

- `connect_building_layout_topology_components()` silently connects required disconnected topology.
- Topology compilation drops circulation endpoints and common family building produces one universal functional field.
- The allocator is greedy; route solving seeds one turf, then every room is separately connected and receives a synthetic `room -> route` connection.
- Remaining interior is blanket-filled as `circulation_open_bay`, masking unassigned and ownership defects.
- Opening solving skips topology connections; required adjacency checks test connection records rather than shared/open/nested/secure/route geometry.
- Required support can be synthesized, budgets can be inflated, only one best required module is retained and required members may be pruned individually.
- Wall-module members choose walls independently and bypass authored clearances.
- Candidate search stops after two family labels; deduplication/selection is family-oriented and seed admits a 10% quality tier.
- Room reports prepend `layout_` to already normalized candidate room IDs, producing `layout_layout_*` and empty composition/occupancy/access payloads.
- Canonical quality still calls reusable helpers in legacy semantic files; those helpers must move before include deletion.
- Room-graph/BSP datums and divider state have no productive canonical callsites.

## Stage 0 baseline

- Existing `building_living_target_rooms_6` and `building_hydroponics_target_rooms_7` reports pass despite blanket open-bay ownership, synthetic room-route links and geometry-unproven adjacency.
- Existing reports select `axial_fallback` and report zero old hard counters.
- New Stage 0 counters and expectations must turn both cases red on the unchanged generator before topology/allocation repair.

## Self plan-mapping challenge

Status: PASS WITH RISKS

- PASS: the public pipeline and emitter/provider contracts can be preserved while replacing all reviewed internals.
- PASS: existing archetype/program declarations and curated placement modules provide the source data needed for topology and atomic composition contracts.
- PASS: bounded trial-emission provides a canonical point for lexicographic validation and selection.
- PASS: new canonical files can own topology, route, partitions and composition without placing generation in the visual harness.
- RISK: Stage 0 intentionally makes current cases red and may temporarily leave no hard-valid candidate. This is expected evidence, not permission to restore masking paths.
- RISK: family-specific regions plus graph-aware allocation can exhaust the cap. Mitigation is round-robin scheduling and the mandated 24/6/8/96 bounds.
- RISK: route/partition constraints can expose genuinely infeasible authored programs. Those must fail explicitly; no root-edge, singleton or budget fallback is allowed.
- RISK: legacy semantic helpers are still live dependencies. Migrate them with equivalence tests before deleting includes.
- RISK: the 840-case matrix is expensive. The runner must shard and resume without reducing the Cartesian contract.
- RISK: broad file splitting can hide reachable legacy paths. Each removal requires a definition/include/callsite audit recorded below.

## Plan fidelity matrix

| ID | Requirement | Evidence target | Status |
| --- | --- | --- | --- |
| M1-M2 | Refresh contract and map production/legacy paths. | Sections above and targeted `rg` evidence. | DONE |
| M3 | Honest Stage 0 counters turn living/hydro red. | Fresh reports with immutable expectation diffs. | IN PROGRESS |
| M4-M12 | Topology, policies, beam, A*, partitions, composition, selection, reporting and legacy removal. | Source, units, runtime reports and audits. | PENDING |
| K1 | Preserve one public canonical pipeline. | Include/callsite audit and preview/apply/undo. | ACTIVE |
| R1 | No alternate/fallback/visual repair. | Forbidden-token and callsite audit. | ACTIVE |
| C1-C5 | Build, units, 840 matrix, all-program smoke and final audits. | Fresh command logs and summaries. | PENDING |

## Stage 0 false-green proof 2026-07-17

- Validator-only Werror build: `.\\BUILD.cmd --ci dm -DUNIT_TESTS -DCIBUILDING -DANSICOLORS -Werror`; 0 errors, 0 warnings.
- Runtime command: `py -3 tools/world_edit_visual/scripts/render_workflow.py --case building_living_target_rooms_6 --case building_hydroponics_target_rooms_7 --timeout-seconds 1200 --no-ascii`.
- Expected result: both cases turned red before any solver/topology/allocation repair and were locked as `program.insufficient_footprint` because no old candidate survived the new hard gates.
- Living best rejected candidate: required adjacency geometry missing `5`, unassigned excess `10`, ownerless open-bay components `4`.
- Hydroponics best rejected candidate: required adjacency geometry missing `3`, unassigned excess `18`, ownerless open-bay components `7`.
- The committed case expectations require all three defect families to be zero and also lock route-component, composition, wall-defect and atomic-fragmentation gates. These expectations are now immutable.

## Old-path audit ledger

| Path | Baseline | Final evidence |
| --- | --- | --- |
| topology auto-connect | Reachable | PENDING |
| blanket circulation overlay | Reachable | PENDING |
| universal room-route | Reachable | PENDING |
| seed-only/direct route paths | Reachable | PENDING |
| synthetic support/budget/fallback/pruning | Reachable | PENDING |
| post-emission repair | Reachable | PENDING |
| family-id early selection / 10% seed tier | Reachable | PENDING |
| duplicate canyon validation | Reachable | PENDING |
| semantic/room-graph/BSP/divider legacy | Included/referenced | PENDING |
| `layout_layout_*` report flow | Reproduced | PENDING |
