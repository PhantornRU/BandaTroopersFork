# PLAN

## Active task
Finish the RTO charge-model rollout: migrate all live support packages to shared weighted charges, wire player-facing UI and GM tooling around live charge pools, and leave the branch in a releasable state with updated docs and verification.

## Scope
- `modular/rto_support/code/**`
- `modular/game_rule_panel/**`
- `tgui/packages/tgui/interfaces/**`
- `code/modules/unit_tests/**`
- selected RTO/Game Rule Panel docs in `modular/**/__docs/**`

## Current status
- Runtime support pool datum, controller integration, and Game Rule Panel live charge admin are implemented.
- All live USCM, UNSC, and ODST support templates are now configured for `charges`.
- Preset menu and binocular examine text expose charge-based language and live pool state.
- Docs and tests are being kept in sync with the migrated model.

## Acceptance criteria
- All live support templates resolve to charge pools by default.
- Package balance is encoded through `capacity`, `recharge`, `support_pool_cost`, and `personal_lockout`.
- Game Rule Panel can inspect and edit active RTO charge pools live.
- Player-facing UI no longer presents charge-based packages as legacy shared cooldowns.
- Compile and TGUI CI-equivalent checks pass.
