# PLAN

## Активная задача
Обновить PR-ветку `halo_jackal_spartan_wave_apr2026` для PR #94, разрешить конфликт с `master`, закрыть actionable review comments и устранить lint/compile ошибку в `spartan_jump`.

## Scope
- Подтвердить и разрешить merge conflict c `upstream/master`.
- Починить `bad keyword argument "anim_flags" to /atom/proc/animation_spin`.
- Закрыть review fixes по `spartan_jump`, HALO language encoding, Spartan lunge/keybinds, Mjolnir armor feedback/degradation и Spartan firearm math.
- Прогнать релевантные проверки.
- Закоммитить и запушить follow-up fix в текущую PR-ветку.

## Out of scope
- Несвязанные HALO waves и рефакторинги вне файлов review scope.
- Ответы в GitHub review threads и ручное resolve discussion без прямого запроса.

## Acceptance criteria
- PR #94 больше не находится в merge-conflict состоянии.
- `spartan_jump.dm` больше не падает на `anim_flags`.
- Исправлены user-visible regressions из review comments.
- `git diff --check` и релевантные build/lint проверки проходят.
- Изменения запушены в `origin/halo_jackal_spartan_wave_apr2026`.
