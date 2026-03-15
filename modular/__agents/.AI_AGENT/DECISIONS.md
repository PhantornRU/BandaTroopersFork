# DECISIONS

## D-001: Treat projectile backlog as the primary runaway
- Decision: optimize around `Projectiles` first, then reduce `Human AI` work that feeds projectile creation or scales with projectile-heavy battles.
- Why: round-204 evidence shows subsystem numbers escalating as `Projectiles` grows fastest, while `Human AI` and `Human Life` rise as secondary pressure.

## D-002: Keep normal combat FX unless logs prove they are the driver
- Decision: do not keep broad HALO low-FX combat degradations as the main fix path.

## D-003: Treat pathfinding as the primary remaining HALO combat bottleneck after round 205
- Decision: pivot the next optimization layer away from `Projectiles` and toward `Pathfinding` once round-`205` numbers showed `pathfinding` outgrowing `Projectiles`, especially after spawning `Sangheili`.
- Why: the live numbers reported for round `205` showed `Projectiles` staying materially below the previous runaway while `Pathfinding` climbed from roughly `600ms` to roughly `1300ms` after Sangheili were added.

## D-004: Reduce HALO movement churn in the brain-level pathing layer, not via more combat-specific FX or action hacks
- Decision: add reusable short-range steering and moving-target retarget slack in `human_ai_brain` and let HALO Covenant presets opt into that tuning.
- Why: the noisy callsites are spread across sword charge, cover retreat, panic retreat, and generic human-AI movement; solving it once in the navigation layer reduces repeated path requests without hard-coding more one-off behavior into each action datum.

## D-005: Do not pivot to shield-specific optimizations without stronger evidence
- Decision: keep Sangheili shield behavior intact for now and treat it as a secondary FX/process cost, not the main explanation for hanging projectile queues.
- Why: round-`206` CSV data showed low `halo_active_shields` and low `halo_temp_visuals` counts even while `halo_projectile_queue` still spiked and the live complaint remained "projectiles hanging in the air."

## D-006: Fix clientless storage interactions and HALO sustained-fire cadence before touching shields
- Decision: close the unrelated but real `storage.show_to()` runtime for clientless AI users and add a HALO-specific sustained-fire cap that applies even to semiauto or burstfire chains.
- Why: round-`206` runtime logs point at AI opening a `vehicle_locker` storage UI with no client, and the remaining combat behavior still fits projectile-queue growth from repeated HALO gun fire better than it fits a shield deadlock.
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

## D-008: Resolve HALO projectile-pressure ammo lookup through stable gun state, not private subsystem fields
- Decision: make HALO projectile-pressure helpers use a public `SSprojectiles` queue-length proc and resolve magazine-fed HALO ammo via `current_mag.default_ammo` with an internal-mag branch for chambered ammo.
- Why: CI showed the helper missing `needler/carbine` combat ammo in unit tests, and DreamChecker flagged direct reads of `SSprojectiles.projectiles` as a private-field access.

## D-009: Treat round-207 pathfinding stalls as a re-path/crowd-navigation bug, not a new projectile runaway
- Decision: fix the pathfinding hot path by resetting reused A* state on re-path and by letting human AI take a cheap local detour when the next path step is crowd-blocked.
- Why: round `207` reported `Pathfinding ~1011` with a full hang after clumped Unggoy spawns, while local `perf-207` snapshots showed low `halo_path_requests` but many active AI brains, which fits long-lived or corrupted path runs plus crowd-blocked navigation better than another projectile-dominant failure.

## D-010: Keep the navigation refactor internal-first and behavior-preserving
- Decision: reorganize `human_ai_brain` navigation and `SSpathfinding` setup around explicit helper procs, while keeping external action datum callsites and gameplay-facing movement rules intact.
- Why: the hot spots now span multiple action datums and two shared layers, so future fixes need stable internal contracts more than another outward behavior rewrite.
