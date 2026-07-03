# TODO - PR99 Structured Scene And Wall Topology Hardening

| ID | Type | Requirement | Status |
| --- | --- | --- | --- |
| M1 | MUST | Read active review doc, attached verdict, current task-state, and production DM entrypoints. | [x] |
| M2 | MUST | Replace stale `COMPLETE` task-state with the active structured-scene contract before product edits. | [x] |
| M3 | MUST | Record plan-mapping challenge and old-path audit for the new blockers. | [x] |
| M4 | MUST | Add shared structured-scene fixture ownership fields and marker proc. | [x] |
| M5 | MUST | Make `stage_interiors` return semantic validity and report structured scene metrics. | [x] |
| M6 | MUST | Make `stage_fixtures` skip legacy placement on shared structured ownership and report legacy-after-scene count. | [x] |
| M7 | MUST | Add `legacy_fixture_after_scene_count` to validation state, hard counters, verdict metrics, metadata, and visual report metrics. | [x] |
| M8 | MUST | Mark v2 scene emission as `structured_scene_owner = "layout_v2"` and semantic interiors as `structured_scene_owner = "semantic"`. | [x] |
| M9 | MUST | Support multi-phase semantic scene emission per room: primary, secondary, detail. | [x] |
| M10 | MUST | Replace rule classification with explicit room-class resolver. | [x] |
| M11 | MUST | Add footprint-aware member spec fields and placement modes `relative`, `wall_run`, `center_ring`. | [x] |
| M12 | MUST | Tighten focused expectations to 90% coverage and zero legacy-after-scene. | [x] |
| M13 | CHECK | Run compile/diff/focused visual workflows as feasible and record evidence. | [x] |
| M14 | MUST | Add wall topology counters for outside-footprint walls and orphan internal wall islands. | [x] |
| M15 | MUST | Add v2 wall cleanup/rejection so leftover non-floor cells do not become unvalidated wall chunks. | [x] |
| M16 | MUST | Expose wall topology counters through hard counters, report metrics, visual report metrics, and focused living expectations. | [x] |
| M17 | CHECK | Re-run compile/diff/focused visual workflow after wall topology changes and inspect generated sprites with the new doubts in mind. | [x] |
| M18 | MUST | Add hard validation for shell-connected internal walls that are not mapped to adjacent room/route floor/opening. | [x] |
| M19 | MUST | Extend v2 wall cleanup to remove unmapped internal leftover walls before hashing/scoring. | [x] |
| M20 | MUST | Expose mapped-wall counters through hard counters, visual report metrics, and focused living expectations. | [x] |
| M21 | CHECK | Re-run focused compile/workflow after mapped-wall hardening and record whether current suspicious screenshots would fail. | [x] |

## Forbidden Substitutions

| ID | Forbidden substitution |
| --- | --- |
| F1 | No visualizer-side generation, repair, or success simulation. |
| F2 | No random fixture recipe expansion as a substitute for scene grammar. |
| F3 | No counter-only green when legacy fixture pass still fills structured-scene layouts. |
| F4 | No single-seed coordinate fixes or PNG-only acceptance. |
| F5 | No storage/workshop/hydro/office data-pack rollout mixed into living cleanup. |
| F6 | No treating wall islands/outside-footprint chunks as acceptable visual artifacts. |
| F7 | No accepting shell-connected wall spurs merely because they touch the boundary shell. |

## Old Path Audit

| Old path | Required result | Current evidence |
| --- | --- | --- |
| `stage_interiors` unconditional return | Return semantic validity, not unconditional `TRUE`. | `stage_interiors.dm` currently calls `run_building_semantic_interiors()` then returns `TRUE`. |
| Semantic-only ownership gate | Replace with shared `structured_scene_emitted` ownership. | `stage_fixtures.dm` currently checks only `semantic_interiors_emitted`. |
| V2 scene emission without shared owner | Mark layout v2 scenes as structured owner. | `run_building_v2_candidate_emission_pipeline()` places v2 scenes, reports them, validates state, but does not mark shared ownership. |
| Single-scene-per-room semantic solver | Emit phases, not first-success break. | `run_building_semantic_interiors()` breaks after the first emitted rule per room. |
| Loose role substring rules | Use explicit resolver. | `building_layout_semantic_rules.dm` builds `room_key` and uses `findtext()` helper chains. |
| Visual cases accepting undercoverage | Raise semantic source-of-truth expectations. | Living cases currently use `semantic_functional_coverage_percent_min = 85` and lack `legacy_fixture_after_scene_count`. |
| V2 leftover footprint wall fill | Clean up or fail orphan leftovers instead of accepting every non-floor footprint tile as a wall. | `emit_building_v2_candidate_to_state()` derives walls from all footprint cells not in `floor_lookup`. |
| Wall topology visual-only review | Add hard counters and expectations. | Existing validators cover double-thick and diagonal-only wall contacts but not explicit outside-footprint or isolated internal wall chunks. |
| Shell-connected unmapped leftovers | Add mapping counter/cleanup. | Current `wall_orphan_island_count` only catches disconnected components; a bad component connected to shell can still pass if its tiles do not border walkable room/route space. |
