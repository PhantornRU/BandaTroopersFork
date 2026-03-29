# DECISIONS

## D-001: Rocket detonation helper stays in `code/datums/ammo/rocket.dm`
- Decision: add a datum-local helper for the repeated explosion + smoke sequence and reuse it where the behavior is unchanged.
- Why: it keeps the diff local to the ammo datum and avoids widening scope into unrelated projectile systems.

## D-002: Ridgeway turret keeps inherited density only once
- Decision: remove the duplicate `density = TRUE` line from the Ridgeway subtype and leave the inherited value intact.
- Why: this is the smallest behavior-neutral cleanup for the review tail.

## D-003: Plasma cannon beam vars are deleted, not repurposed
- Decision: remove the unused beam cooldown/type fields instead of inventing new state.
- Why: the current firing path only uses the local beam datum.
