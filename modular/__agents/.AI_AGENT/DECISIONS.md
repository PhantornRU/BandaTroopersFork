# DECISIONS

## D-001: Task-state переносится на PR #94
- Решение: перезаписать `PLAN/TODO/DECISIONS/EVIDENCE`, потому что предыдущий state относился к другой HALO species-задаче.
- Почему: live task-state должен отражать текущую активную работу, а не старый завершенный scope.

## D-002: Обновление ветки делается через merge `upstream/master`
- Решение: подтянуть актуальный `master` и локально разрешить конфликт в текущей PR-ветке.
- Почему: GitHub помечает PR #94 как `DIRTY`; цель пользователя прямо включает update branch и conflict resolution.

## D-003: Review fixes держатся локальными и трассируемыми
- Решение: менять только файлы из review scope и связанные минимальные integration points.
- Почему: задача про update/fix wave, а не про широкий HALO refactor.

## D-004: `animation_spin` расширяется минимальным upstream glue вместо удаления parallel-callsite
- Решение: добавить опциональный `anim_flags` в `/atom/proc/animation_spin` и оставить `spartan_jump` на parallel-анимации.
- Почему: простое удаление keyword починило бы lint, но сломало бы задуманный одновременный spin во время прыжка.

## D-005: `Gun Ho` считается линейным бонусом сверх `SKILL_GUN_HO_UNTRAINED`
- Решение: заменить `SKILL_FIREARMS * SKILL_GUN_HO` на `SKILL_FIREARMS + max(SKILL_GUN_HO - SKILL_GUN_HO_UNTRAINED, 0)` в accuracy/scatter/recoil.
- Почему: простая сумма бафнула бы всех стрелков с baseline `gun_ho = 1`, а мультипликатор слишком резко разгонял Spartan gun handling относительно текущего `master`.
