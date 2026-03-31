# DECISIONS

## D-001: Placement UX stays manager-side and reuses the existing preview/apply/plan pipeline
- Decision: add a minimal manager placement runtime instead of introducing a second parallel placement system.
- Why: this keeps preview/apply semantics consistent and avoids a manager architecture rewrite.

## D-002: `blueprint_stamp` gets the richer Phase 4 placement modes, `outpost_radius` stays narrower
- Decision: implement `single` / `repeat` / `line` / `rectangle` for `blueprint_stamp`, but only `single` / `repeat` for `outpost_radius`.
- Why: blueprint stamping is the main ergonomic target of the phase, while repeated outpost placement is the safe bounded improvement for outposts.

## D-003: Rotation remains cardinal-only and is applied at plan-build time
- Decision: support only `NORTH/EAST/SOUTH/WEST` placement rotation and reflect it in preview/apply.
- Why: this preserves blueprint safety and avoids introducing any arbitrary-angle or schema redesign.
