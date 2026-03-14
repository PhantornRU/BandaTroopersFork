# DECISIONS

## D-001: Treat projectile backlog as the primary runaway
- Decision: optimize around `Projectiles` first, then reduce `Human AI` work that feeds projectile creation or scales with projectile-heavy battles.
- Why: round-204 evidence shows subsystem numbers escalating as `Projectiles` grows fastest, while `Human AI` and `Human Life` rise as secondary pressure.

## D-002: Keep normal combat FX unless logs prove they are the driver
- Decision: do not keep broad HALO low-FX combat degradations as the main fix path.
- Why: the local evidence points at server-side projectile backlog and AI work rather than purely visual effects.

## D-003: Use projectile-pressure backoff at more than one layer
- Decision: keep gun-side projectile backpressure, but also add earlier HALO AI decision-layer throttles so overloaded firefights skip expensive fire preparation work before new projectiles are spawned.
- Why: gun-only cancellation still leaves AI paying for target checks and fire preparation in overload scenarios.

## D-004: Preserve incident context in task-state, not as ad-hoc root notes
- Decision: store the round-204 investigation context in `.AI_AGENT/{PLAN,TODO,DECISIONS,EVIDENCE}.md`.
- Why: repo guidance reserves task context for agent task-state; this keeps the root `AGENTS.md` stable while preserving the incident findings.

## D-005: Prefer early HALO AI backoff to gun-only cancellation
- Decision: keep the gun-side HALO projectile backpressure component, but also short-circuit HALO `fire_at_target` and related AI work when projectile pressure is already high.
- Why: this avoids paying for repeated firing-line checks and fire preparation just to cancel at the last moment inside the gun proc.

## D-006: Degrade HALO support behaviors before degrading combat visuals
- Decision: under projectile saturation, HALO AI now suspends nearby floor-item scans and disables expensive Unggoy cover-retreat selection before touching normal combat FX.
- Why: the round-204 evidence points at server-side combat and movable churn, while user intent explicitly rejected broad FX removal as the primary fix.

## D-007: Persist HALO perf counters into CSV snapshots
- Decision: extend `SS time_track` CSV output with HALO counter columns, including projectile queue size and HALO AI brain count.
- Why: local filesystem logs did not previously preserve the same context that was visible in MC stat output during the incident.
