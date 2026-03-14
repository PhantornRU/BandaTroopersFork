# PLAN

## Active task
Optimize and refactor the HALO AI-vs-AI combat hot path around runaway `Projectiles`, elevated `Human AI`, and secondary `Human Life` pressure observed on round `204`, while preserving normal player-facing combat behavior and keeping diagnostics for repeat repros.

## Delivery status
- [x] Re-scope task-state from the previous HALO translation task.
- [x] Collect local evidence from `round-204` logs and current HALO perf instrumentation.
- [x] Consolidate HALO projectile-pressure helpers and use them across both gun and AI decision layers.
- [x] Reduce unnecessary HALO AI work during projectile overloads without deleting normal combat FX.
- [x] Keep or remove earlier HALO perf/refactor hooks based on actual usage after the new refactor.
- [x] Update agent evidence/decisions with the round-204 findings and the new profiling workflow.
- [x] Run compile verification.

## Acceptance status
- Verified: HALO AI-only ranged combat now uses projectile-pressure backoff before expensive fire decisions snowball into queued projectile backlog.
- Verified: HALO panic/looting behaviors now skip unnecessary expensive work when the battle is already projectile-saturated.
- Verified: the round-204 investigation context is preserved in agent task-state for future work.
- Verified: touched files compile cleanly with `tools/build/build --ci dm -DCIBUILDING -DANSICOLORS -Werror`.
