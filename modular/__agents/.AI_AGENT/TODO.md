# TODO - Graph-first Building Layout Solver

| ID | Type | Requirement | Status |
| --- | --- | --- | --- |
| M1 | MUST | Preserve dirty baseline and refresh task contract from `11.07.26_review.md`. | DONE |
| M2 | MUST | Map entrypoint, include graph, route-first allocator, dead adjacency, repeated ownership, module catalog, cleanup and reporting. | DONE |
| M3 | MUST | Make current underfill/composition/adjacency/template/cleanup/canyon false-green layouts hard-fail. | DONE |
| M4 | MUST | Add spatial kinds and make target count functional-only with explicit circulation contracts. | DONE |
| M5 | MUST | Compile semantic adjacency/nested declarations into a real topology graph. | DONE |
| M6 | MUST | Add declarative topology families and compare distinct hard-valid families. | DONE |
| M7 | MUST | Allocate rooms graph-first with bounded beam/dimension variants; solve routes afterward. | DONE |
| M8 | MUST | Support room-room transitions and open-bay route overlays. | DONE |
| M9 | MUST | Assign clusters per instance and place curated modules atomically; forbid required singleton fallback. | DONE |
| M10 | MUST | Validate per-room compositions, capacities and area-relative occupancy. | DONE |
| M11 | MUST | Materialize walls from ownership/partition graph; cleanup becomes diagnostic/reject only. | DONE |
| M12 | MUST | Export consistent candidate/per-room metrics and visual overlays. | DONE |
| K1 | KEEP | One canonical solver, public API, deterministic caps, provider/emitter and preview/apply/undo. | VERIFIED |
| R1 | REJECT | No versioned solver, switch, legacy fallback, program coordinate recipes or expectation weakening. | VERIFIED |
| C1 | CHECK | Four fixed-seed false-green cases first fail for canonical counters, then pass after implementation. | VERIFIED |
| C2 | CHECK | Six target-room programs and all 15 programs pass functional/composition/wall gates. | VERIFIED |
| C3 | CHECK | Key programs pass 10 seeds, four directions and size profiles; determinism matches. | VERIFIED |
| C3A | CHECK | Matrix runner derives temporary cases from six canonical target cases and writes an aggregate JSON summary. | VERIFIED |
| C3B | CHECK | All 60 standard-profile seed samples pass canonical hard gates and same-seed replay. | VERIFIED: 60/60 |
| C4 | CHECK | `BUILD.cmd`, focused unit/runtime tests, feasible full tests, old-path audit and `git diff --check`. | PARTIAL EXTERNAL: completed full suite has 2 unrelated HALO/config failures; Building Layout 29/29 pass. |
| H1 | MUST | Prove the current final family selection ignores seed and always maximizes one soft score. | DONE |
| H2 | MUST | Select only among best-per-family hard-valid candidates inside the bounded quality band. | VERIFIED |
| H3 | MUST | Make selection seed-deterministic without changing base quality scores or hard gates. | VERIFIED |
| H4 | MUST | Export seeded-selection diagnostics through plan/report metadata. | VERIFIED |
| H5 | CHECK | Unit-test quality exclusion, family collapse, same-seed replay and cross-seed variation. | VERIFIED |
| H6 | CHECK | Re-run key seed matrix; correctness remains 60/60 and eligible programs gain structural diversity. | VERIFIED: 60/60 |
| I1 | CHECK | Re-run ordinary representative preview/apply/undo acceptance for all 15 programs after seeded selection. | VERIFIED: 15/15 |
| I2 | CHECK | Localize the full unit-suite non-progress condition without counting an aborted run as valid. | VERIFIED: intentional sleeps and long integration tests/cleanup |
| I3 | CHECK | Obtain completed relevant Building Layout unit evidence and keep the ordinary test set unfocused. | VERIFIED: 28/28 Building Layout tests pass |
| I4 | CHECK | Refresh review/evidence and repeat compile, legacy, Python, diff and process audits. | VERIFIED |
| J1 | MUST | Guard canvas-origin singleton registration and clear only the registered owner on destruction. | VERIFIED |
| J2 | REJECT | Do not ignore the landmark in `create_and_destroy` or weaken GC failure reporting. | VERIFIED |
| J3 | CHECK | Add focused duplicate/owner lifecycle coverage and rerun `create_and_destroy`. | VERIFIED: both status 0 |
| J4 | CHECK | Re-run visual acceptance, compile and final legacy/diff/process audits. | VERIFIED |

## Forbidden substitutions

| ID | Forbidden substitution |
| --- | --- |
| F1 | Adding validation around the axial route-first core without replacing its ownership of topology. |
| F2 | Counting circulation toward `target_room_count` or synthesizing divider rooms. |
| F3 | Giving repeated rooms one generic fallback object instead of authored per-instance composition. |
| F4 | Keeping wall cleanup as successful normal materialization. |
| F5 | Adding program-id switches or coordinate recipes inside the solver. |
| F6 | Repairing generation or relaxing acceptance in `tools/world_edit_visual`. |
| F7 | Adding random score jitter before hard validation or allowing a candidate below the bounded quality floor. |
| F8 | Requiring every seed to be unique; diversity is across the matrix, while same-seed determinism remains exact. |

## Old path audit

| Old path | Required result | Audit |
| --- | --- | --- |
| `allowed_layout_patterns = adaptive_axis/adaptive_cross_axis` only | Replaced by archetype-declared topology families. | family/catalog callsite `rg` |
| `build_building_layout_axis_region_candidate()` universal use | Axial remains fallback only or is removed. | callsite audit |
| `solve_building_layout_route_from_region()` before rooms | Removed from production call order. | entrypoint/callsite audit |
| automatic `room -> route` connections | Removed; topology edges control transitions. | `room_connections` audit |
| `room.instance_index > 1` ownership rejection | Removed; instance policy assignment used. | fixed-string `rg` |
| generic required singleton scene fallback | Required scenes fail without authored/compact module. | solver and synthetic test |
| wall prune/cleanup as success path | Zero for RECT; bounded diagnostic only for irregular. | stage report and callsite audit |
| top-level/nested candidate metric divergence | One source and mismatch counter zero. | report assertions |
