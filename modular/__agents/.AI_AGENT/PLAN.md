# PLAN

## Active task
Optimize and refactor the HALO AI-vs-AI combat hot path around the round-`204` projectile runaway and the round-`205` pathfinding churn that remains after projectile mitigation, especially on HALO Covenant melee/retreat behavior, while preserving normal player-facing combat behavior and keeping diagnostics for repeat repros.

## Delivery status
- [x] Re-scope task-state from the previous HALO translation task.
- [x] Collect local evidence from `round-204` logs and current HALO perf instrumentation.
- [x] Consolidate HALO projectile-pressure helpers and use them across both gun and AI decision layers.
- [x] Reduce unnecessary HALO AI work during projectile overloads without deleting normal combat FX.
- [x] Confirm whether the remaining round-`205` bottleneck stayed in `Projectiles` or moved into `Pathfinding`.
- [x] Refactor human AI movement so HALO Covenant presets can use cheap nearby steering and tolerate small moving-target drift before rebuilding a path.
- [x] Re-check the next live round for shield-specific evidence versus projectile-queue evidence.
- [x] Remove the clientless storage/UI runtime exposed by human AI interactions around vehicle lockers.
- [x] Add another HALO AI cadence layer so sustained semiauto and automatic fire chains back off before projectile backlog grows again.
- [x] Keep or remove earlier HALO perf/refactor hooks based on actual usage after the new refactor.
- [x] Add regression coverage for the new HALO pathing contract.
- [x] Update agent evidence/decisions with the round-204 findings and the new profiling workflow.
- [x] Run compile verification.

## Acceptance status
- Verified: HALO AI-only ranged combat now uses projectile-pressure backoff before expensive fire decisions snowball into queued projectile backlog.
- Verified: HALO panic/looting behaviors now skip unnecessary expensive work when the battle is already projectile-saturated.
- Verified: HALO Covenant presets now opt into cheap short-step movement for nearby destinations and keep existing paths when a moving target only drifts slightly.
- Verified: clientless HALO AI can no longer open vehicle-locker storage UIs during nearby movement.
- Verified: HALO plasma, needler, and carbine appraisals now count each shot toward a sustained-fire cap instead of chaining indefinitely.
- Verified: the round-204 investigation context is preserved in agent task-state for future work.
- Verified: touched files compile cleanly with `tools/build/build --ci dm -DCIBUILDING -DANSICOLORS -Werror`.
