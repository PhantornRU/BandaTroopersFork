# DECISIONS - Living V2 Visual Quality Hardening

## D-001: Passing counters are not enough
- Decision: Treat the current generated living PNGs as failing review quality despite passing semantic acceptance.
- Why: The user explicitly rejected the visual result and requested skeptical review.

## D-002: Use subagents
- Decision: Split work across visual critique, pattern/corridor expansion, and scene placement rules.
- Why: The user explicitly requested subagents for this pass.

## D-003: Keep visualizer read-only
- Decision: All layout/furniture fixes belong in production DM generator code; `tools/world_edit_visual` remains report/acceptance only.
- Why: This is a stable PR99 boundary and is repeated in the current hardening contract.

## D-004: Semantic expectations must follow visual critique
- Decision: Any discovered visual defect should become a hard counter, report metric, or expectation when feasible.
- Why: PNGs are review artifacts; semantic reports remain source of truth.

## D-005: Agent C placement scope
- Decision: Replace hard-coded v2 scene member offsets with solver-side candidate selection in `building_layout_v2_solver.dm`.
- Why: Existing v2 contracts/metrics are already wired; the current gap is that scene members are still selected by fixed positions instead of usable room cells with route, door, window, wall, and fixture clearance.

## D-006: Reject the old side-spine ribbon pattern
- Decision: Do not restore the previous `side_spine_room_row` as a candidate source in this pass.
- Why: The visual critique identified it as a branchy/ribbon corridor grammar. Candidate breadth is kept through the two readable living v2 candidates plus shape/direction variants, not by reintroducing a known-bad pattern.

## D-007: Count orphan interior walls, not all partition walls
- Decision: `unclaimed_interior_wall_count` measures internal wall cells with no adjacent floor/door above a small allowance.
- Why: Raw internal wall count falsely treats valid room partitions as visual waste; orphan wall cells better represent the actual leftover-wall defect seen in the rejected PNG.

## Superseded Decisions

The previous production-hardening decisions remain true where not contradicted: living v2 stays default; non-living stays legacy. The current pass supersedes any implication that `building_living_target_rooms_6` is production-quality merely because it passed.
