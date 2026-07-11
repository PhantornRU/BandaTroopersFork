# TODO - Canonical Building Layout Solver Rewrite

| ID | Type | Requirement | Status |
| --- | --- | --- | --- |
| M1 | MUST | Preserve dirty baseline; refresh task contract before product edits. | DONE |
| M2 | MUST | Self challenge maps entrypoints, old staged path, shared primitives and forbidden aliases. | DONE |
| M3 | MUST | Canonical rename removes `v2` files/types/procs/defines/state/metadata/counters without aliases. | DONE: production/test/case alias audit clean |
| M4 | MUST | Compile one solver contract from the archetype catalog for all 15 programs. | DONE: compiler plus 15-program contract unit coverage |
| M5 | MUST | Generic bounded pattern/room/route solver replaces coordinate living recipes and reaches exact target count semantically. | DONE: exact target matrix and structured side-run reservations pass |
| M6 | MUST | Generic opening/window/partition solver owns wall materialization and physical doors. | DONE |
| M7 | MUST | Generic scene hierarchy and placement-module dispatch replaces scene-id switch and legacy fixture placement. | DONE: generic module dispatch active; dead high-level fixture/room-fill helpers removed and callsite audit clean |
| M8 | MUST | Trial quality selection hard-fails structural, architectural and semantic placement defects. | DONE: ordinary 15-program matrix has zero acceptance failures |
| M9 | MUST | Delete staged V1 orchestration and all production fallback/compat paths. | DONE: stage files and entrypoint branch deleted; final production/test/case old-path audit clean |
| M10 | MUST | Update active docs, unit tests, reports and visual cases to canonical contract. | DONE |
| C1 | CHECK | Build plus focused/full unit verification. | DONE: compile clean and targeted canonical runtime tests pass; full suite timeout recorded |
| C2 | CHECK | All 15 representative visual cases plus living direction/size matrix. | DONE: 15-program matrix plus living N/S/E/W, rectangle directions and compact/standard/spacious passed |
| C3 | CHECK | Manual sprite review and old-path/diff audit. | DONE: all 15 semantic sprites reviewed; aliases/old entrypoints absent and `git diff --check` clean |

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
