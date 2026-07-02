# DECISIONS - Living V2 Universal Pattern/Scene Solver

## D-001: This is a replacement of the v2 scaffold, not another recipe pass
- Decision: Treat the current v2 as an incomplete scaffold and replace the hardcoded pattern/door/window/scene placement flow with solver stages.
- Why: The user explicitly rejected adding recipes and asked for a universal pattern/scene solver.

## D-002: Keep production changes in modular World Edit code
- Decision: Generator behavior changes go under `modular/world_edit/code/generators/building_layout/**`.
- Why: `tools/world_edit_visual/**` is review/acceptance only and PNG/sprite output is not source of truth.

## D-003: Use subagents, but keep a single task-state contract
- Decision: Run read-only subagents for opening, room/scene, and validation audits, while the main agent owns integration and final fidelity.
- Why: The user explicitly requested subagents in this review sequence, and current scope is broad.

## D-004: First production cut targets living only
- Decision: Harden the universal solver through living first; storage/workshop data packs remain legacy in this pass.
- Why: The user explicitly said storage/workshop reuse comes only after living visual pass.

## D-005: Opening/window solvers are mandatory before visual acceptance
- Decision: Living v2 patterns may still define relation geometry, but production doors/windows must be selected by solver stages from candidate geometry and policies.
- Why: Hardcoded door/window coordinates are the clearest current source of metadata-only topology and repeated algorithmic-looking layouts.

## D-006: Hard validation must fail the current bad screenshot class
- Decision: Add counters/expectations for door/shared-wall correctness, window policy, scene fragmentation, and excessive empty/identity-missing rooms.
- Why: Existing counters can be zero while the visual result is still not map-quality.

## D-007: Room allocation is solver-driven for living, not yet a storage/workshop rollout
- Decision: Living patterns now provide relation-zone allocation slots; `solve_building_v2_room_allocation()` materializes room rectangles from contracts and required scene-fit before openings/topology.
- Why: This satisfies the living replacement without prematurely claiming that storage/workshop data packs are production-ready on the same engine.

## D-008: Optional windows stay policy-gated until facade-aware selection exists
- Decision: The window solver emits required/desired windows and hard-validates window policy; optional windows are withheld rather than sprayed onto shell boundaries.
- Why: The previous output showed invalid/unreadable windows caused by coordinate assumptions. Optional visual enrichment must follow policy-aware selection, not precede it.

## D-009: Wide side-spine remains candidate breadth until scoring proves visual quality
- Decision: Add `side_spine_room_row` to the bounded candidate set, but keep current scoring low enough that it does not beat the front/common pattern while its wall/route shaping is still worse.
- Why: The hard-review contract wants candidate breadth, not a worse winner. Candidate presence is useful for continued solver work; production selection still follows hard validation and scoring.

## D-010: Do not let pre-emission scoring override hard-valid output
- Decision: V2 selection now runs score-ordered candidates through isolated post-emission hard validation before final emission; the first hard-valid candidate wins and `layout_v2_hard_valid_candidate_count` records full hard-valid breadth.
- Why: Opening/topology/scenes are necessary but not sufficient because wall derivation, scene placement, infrastructure, and hard counters run after emission. A candidate that fails post-emission hard counters must not block a lower-scoring hard-valid candidate.

## D-011: Side-spine breadth is retained, but not accepted as a winner yet
- Decision: Keep `side_spine_room_row` in the bounded candidate set, but do not count it as hard-valid for rectangle while it trips route-complexity validation.
- Why: Candidate breadth is useful as generated search space, but a corridor-maze candidate should be rejected by semantic counters instead of protected by a brittle exact hard-valid count.

## D-012: Manual visual review overrides green counters
- Decision: Treat the submitted `building_living_rectangle_colony` screenshot as a failing living-v2 regression even though the report currently has zero hard counters.
- Why: The output has sparse oversized rooms, repeated door-band openings, and weak scene identity. A production path cannot be accepted by counter-only success.

## D-013: Route and door count are costs after requirements are satisfied
- Decision: Candidate scoring must stop adding quality for longer routes and more doors. Required connectivity is a hard constraint; extra route/door exposure should be neutral or penalized.
- Why: The current score path rewards the exact artifact visible in the rectangle screenshot: a long central spine with many doors.

## D-014: Storage/workshop screenshots are next-phase evidence, not current fixes
- Decision: Keep storage/workshop on legacy safety smoke in this living-hardening slice and record their screenshots as evidence for a later data-pack rollout.
- Why: The approved sequence was living visual pass first, then reuse the same solver for storage/workshop. Fixing legacy storage/workshop output with special cases would violate that order.

## D-015: Scene density is a role/area rule, not random furnishing
- Decision: Large living-v2 rooms require minimum scene-member density by role, and scene builders may add bounded detail members inside the selected scene identity.
- Why: The rectangle screenshot had rooms with valid identities but too few actual objects to read as rooms. This must be validated semantically without adding random module expansion.
