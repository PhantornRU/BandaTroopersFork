# DECISIONS - Canonical Building Layout Solver rewrite

## D-001: The 17.07.06 review supersedes prior green status

The current `11.07.26` closeout is false-green under the new review. Task status returns to IN PROGRESS; prior generated reports are diagnostic baselines, not acceptance evidence.

## D-002: Rewrite only inside the canonical pipeline

Keep `build_building_layout_candidate_state() -> solve_building_layout() -> emit_building_layout_plan()`. Replace internals in-place and split them by responsibility; do not introduce a version, flag, fallback or parallel solver.

## D-003: Stage 0 regressions are living and hydroponics

Because no different screenshot pair was supplied, use `building_living_target_rooms_6` and `building_hydroponics_target_rooms_7` exactly as stated in the approved plan. Their new expectations are immutable after Stage 0.

## D-004: Required topology is authored, not repaired

A required disconnected graph is a compile error. Edge-kind precedence is nested, circulation endpoint, secure endpoint, public/open-bay pair, then shared functional adjacency.

## D-005: Family policies own geometry

Family-specific constraints and seed regions live in DM canonical solver policy datums. Axial is a gated fallback considered only after non-axial hard-valid exhaustion.

## D-006: Ownership precedes materialization

Room/open-bay/route ownership and partition edges are solved before walls/openings. RECT defects reject the candidate; irregular diagnostics may be at most 1% and never mutate a candidate.

## D-007: Composition is atomic per declared instance policy

Required composition groups use `GLOBAL_ONCE`, `PRIMARY_ONLY`, `PER_INSTANCE` or `DISTRIBUTE_TOTAL`. A complete module instance is the budget unit; negative space, interaction lanes and clearances are reserved before solving.

## D-008: Selection is lexicographic and signature-aware

Trial-emission evaluates every bounded candidate. Deduplicate by actual room/topology geometry signature. Seed is allowed only after all earlier quality layers tie and only within `max(1, 0.5% of best score)`.

## D-009: Visual tooling remains an acceptance harness

The matrix runner may create temporary case inputs, shard/resume execution and aggregate reports. It may not generate, repair or reinterpret layout geometry.

## D-010: Legacy removal follows migration proof

Move the reusable scene credit/validation helpers into canonical composition/quality first. Remove semantic, room-graph, BSP and divider includes/state only after exact zero-callsite audits.

## D-011: Self challenge is required in the main agent

No subagents are used because current collaboration instructions prohibit delegation unless explicitly requested. The primary agent performs and records the plan-mapping challenge.

