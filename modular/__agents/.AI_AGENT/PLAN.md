# PLAN

## Active Task
Close the low-risk review tails for `port/tech-vehicle-wave` in:
- `code/datums/ammo/rocket.dm`
- `code/modules/projectiles/projectile.dm`
- `code/modules/vehicles/hardpoints/holder/tank_turret.dm`
- `code/modules/vehicles/hardpoints/primary/plasma_cannon.dm`

## Scope
- Extract shared rocket explosion and smoke handling into a helper proc without changing behavior.
- Remove the duplicate `density` assignment on the Ridgeway turret subtype.
- Remove unused beam-related vars from the Ridgeway plasma cannon.
- Add a short explanatory comment for the open-vehicle hit-chance math without changing the expression.

## Verification
- Run `git diff --check`.
- Run `tools/build/build --ci dm -DCIBUILDING -DANSICOLORS -Werror`.
- Commit only if both checks pass.
