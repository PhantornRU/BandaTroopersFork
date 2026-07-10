# TODO - Canonical Building Layout Solver Rewrite

| ID | Type | Requirement | Status |
| --- | --- | --- | --- |
| M1 | MUST | Preserve dirty baseline; refresh task contract before product edits. | DONE |
| M2 | MUST | Self challenge maps entrypoints, old staged path, shared primitives and forbidden aliases. | DONE |
| M3 | MUST | Canonical rename removes `v2` files/types/procs/defines/state/metadata/counters without aliases. | IN PROGRESS: final alias audit pending |
| M4 | MUST | Compile one solver contract from the archetype catalog for all 15 programs. | IN PROGRESS: all-program compiler implemented; contract tests pending |
| M5 | MUST | Generic bounded pattern/room/route solver replaces coordinate living recipes and reaches exact target count semantically. | IN PROGRESS: living passes; route-after-room integration is under verification for storage matrix |
| M6 | MUST | Generic opening/window/partition solver owns wall materialization and physical doors. | IN PROGRESS |
| M7 | MUST | Generic scene hierarchy and placement-module dispatch replaces scene-id switch and legacy fixture placement. | IN PROGRESS: generic module dispatch is active; legacy helper deletion pending |
| M8 | MUST | Trial quality selection hard-fails structural, architectural and semantic placement defects. | PENDING |
| M9 | MUST | Delete staged V1 orchestration and all production fallback/compat paths. | IN PROGRESS: stage files and entrypoint branch deleted; final old-path audit pending |
| M10 | MUST | Update active docs, unit tests, reports and visual cases to canonical contract. | PENDING |
| C1 | CHECK | Build plus focused/full unit verification. | PENDING |
| C2 | CHECK | All 15 representative visual cases plus living direction/size matrix. | PENDING |
| C3 | CHECK | Manual sprite review and old-path/diff audit. | PENDING |

## Forbidden substitutions

| ID | Forbidden substitution |
| --- | --- |
| F1 | Keeping V1 reachable behind a flag, program check or fallback. |
| F2 | Retaining old metadata/type aliases for compatibility. |
| F3 | Adding per-program coordinate recipes instead of declarative contracts. |
| F4 | Keeping `switch(scene_contract.id)` or equivalent scene-id dispatch. |
| F5 | Satisfying target count with arbitrary divider rooms. |
| F6 | Solving failures in the visualizer/report layer. |

## Old path audit

| Old path | Required result | Audit |
| --- | --- | --- |
| `if(use_building_layout_v2(request)) ... else staged pipeline` | Single canonical call, no branch. | `rg use_building_layout_v2` |
| `/datum/world_edit_generation_stage/**` | Removed from include graph and code. | `rg world_edit_generation_stage` |
| `v2/**`, `building_v2_*`, `WORLD_EDIT_V2_*` | Canonically renamed; no production/test/case hits. | targeted `rg` |
| `use_layout_v2`, `layout_v2_*`, `v2_*` metadata | Removed/renamed; no aliases. | targeted `rg` |
| fixed living region/route coordinate builders | Removed from production. | symbol/callsite audit |
| `switch(scene_contract.id)` | Removed; generic module pattern dispatch only. | fixed-string `rg` |
| legacy semantic-interior/fixture entrypoints | Removed or reduced to shared low-level primitives with canonical callsites. | callsite audit |
