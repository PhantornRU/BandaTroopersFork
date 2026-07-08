# DECISIONS - PR99 Building Layout v2.1 Universal Solver

## D-001: Implement v2.1 inside modular World Edit
- Decision: Keep all new solver logic under `modular/world_edit/code/generators/building_layout/v2/**` and wire it through the existing modular DME include.
- Why: The active scope is the modular production `building_layout` generator; `tools/world_edit_visual` remains report-only.

## D-002: Preserve existing public request contract
- Decision: Do not change user-facing request keys or enable v2 for non-living programs in this pass.
- Why: The review explicitly says stabilize living before storage/workshop expansion.

## D-003: Use new v2.1 counters beside legacy `layout_v2_*`
- Decision: Add `v2_*` counters requested by the review while retaining existing `layout_v2_*` counters and expectations.
- Why: Existing focused cases and prior PR99 evidence use the older names; removing them would create unrelated report churn.

## D-004: Scene hierarchy wraps current emit recipes
- Decision: Keep the existing slot/category member emitters as module recipes, but require primary anchor, negative-space mask, budget checks, and composition validation around them.
- Why: The plan allows the current scene solver as a base; replacing every furniture recipe at once is unnecessary for the v2.1 acceptance contract.

## D-005: One strict hard-valid candidate is acceptable for constrained living cases
- Decision: Focused case expectations may require `layout_v2_min_candidate_count = 1` where stricter v2.1 quality filters reject alternate candidates.
- Why: The acceptance contract is a hard-valid, visually reviewed living output, not preserving weaker candidate counts from pre-v2.1 geometry.

## D-006: Adjacent opposing corridor doors are allowed when both are valid shared-wall openings
- Decision: The v2 door-nearness validator treats a distance of 1 as the compact conflict threshold instead of rejecting opposing corridor doors two tiles apart.
- Why: Compact central corridors can legitimately place opposite room doors near each other; corner/shared-wall/clearance counters still reject invalid openings.

## D-007: Storage/workshop remain smoke-only in this pass
- Decision: Do not enable v2.1 allocation/opening/scene behavior for storage or workshop yet; only run smoke visual cases for regression safety.
- Why: The review requires living to pass counters and manual visual review before expanding to storage/workshop.
