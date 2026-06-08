# PLAN

## Active Task
Порт PR #1277 (Movie-like Xeno Castes) — PVE xeno balance из cmss13-devs/cmss13-pve в BandaTroopers.

## Goal
Проверить и применить изменения из PR #1277 к BT-версиям файлов. Изменения затрагивают: xeno defines (health/speed), Abilities.dm (gut cooldown), caste datums (Runner, Drone, Soldier, Crusher, Lurker, Queen, Facehugger — damage/health/armor/speed/acid_blood), Queen screech/ai.

## Scope
9 файлов из upstream diff.

## Strategy
1. Прочитать diff PR #1277
2. Прочитать текущие BT-версии всех целевых файлов
3. Сравнить построчно каждое изменение
4. Если изменение уже присутствует — ALREADY PRESENT
5. Если отсутствует — применить с SS220 EDIT маркерами
6. Обновить task-state

## Acceptance Criteria
- Все изменения из diff проверены построчно
- BT-specific content сохранён
- Все новые `code/` изменения с SS220 EDIT маркерами (если нужны)
