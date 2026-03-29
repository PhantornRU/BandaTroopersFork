# EVIDENCE

## E-001: Initial task context
- Active branch: `port/tech-vehicle-wave`.
- Focus files: `code/datums/ammo/rocket.dm`, `code/modules/projectiles/projectile.dm`, `code/modules/vehicles/hardpoints/holder/tank_turret.dm`, `code/modules/vehicles/hardpoints/primary/plasma_cannon.dm`.
- Review tails targeted: shared rocket detonation helper, Ridgeway density duplicate, unused plasma cannon beam vars, and the open-vehicle hit-chance comment.

## E-002: Verification
- `git diff --check`: passed.
- `tools/build/build --ci dm -DCIBUILDING -DANSICOLORS -Werror`: passed with `0 errors, 0 warnings`.
