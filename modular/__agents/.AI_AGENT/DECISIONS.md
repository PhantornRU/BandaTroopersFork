# DECISIONS - Canonical Building Layout Solver Rewrite

## D-001: Atomic single-path replacement
- Final production has one canonical solver and no V1/V2 switch or fallback.

## D-002: Full breaking rename
- Rename files, DM symbols, state fields, metadata, metrics and case expectations; do not emit aliases.
- Keep only stable external identities: generator id, program ids, public fields and supported public shapes.

## D-003: Archetype catalog is the program source of truth
- Extend declarative zone/cluster policy instead of creating 15 coordinate generators.
- Required/optional room instances, connections, partitions, openings, windows, scenes and budgets compile from the active semantic plan.

## D-004: Semantic target count
- Exact target count is reached through declared repeatable room instances.
- Impossible requests fail with `program.target_room_count_unreachable`; arbitrary divider rooms are forbidden.

## D-005: Generic modules, not scene-id recipes
- Scene hierarchy dispatches by reusable placement-module pattern and phase, never by program or scene id.

## D-006: Shared primitives survive only with canonical ownership
- Provider/template/emitter/infrastructure/facade/microvariation helpers may remain where the new solver calls them.
- Old orchestration and legacy high-level placement entrypoints must be removed.

## D-007: Access is an allocation-time contract
- Controlled rooms reserve three parallel wall/route turfs; public rooms reserve at least two.
- Missing side-run rejects the room rectangle before scene/opening emission.

## D-008: Required identity precedes optional detail
- All required/signature scenes reserve global budgets before fallback secondary/detail members.
- Compact substitutes are mutually exclusive alternatives to primary modules.
