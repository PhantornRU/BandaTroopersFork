# EVIDENCE

## E-001: Состояние ветки до update
- `git status --short --branch`: рабочее дерево чистое, активная ветка `split/pr62-02-ai-squad-spawn-species`.
- `git rev-list --left-right --count HEAD...upstream/master`: `3 3` до начала merge.

## E-002: История ветки
- `git merge-base HEAD upstream/master`: `91e37a1add1c69b6996a08d4e54dd89ab0669728`.
- `git merge-base HEAD origin/split/pr62-01-halo-platoons-spawn-routing`: тот же base, значит ветка не stacked на `pr62-01`.

## E-003: Актуальный HALO baseline
- `modular/halo/__docs/HALO_PORT_STATE.md` указывает pinned upstream commit `95a84ab9f59f9118e5543f664b2793e7a1841c55` от `2026-03-11`.
- Для update/sync задач этот документ является каноническим baseline.

## E-004: Merge и конфликтные файлы
- `git merge upstream/master` дал конфликты в:
  - `code/modules/mob/living/carbon/human/ai/squad_spawner/squad_spawner.dm`
  - `code/modules/unit_tests/_unit_tests.dm`
  - `code/modules/unit_tests/human_ai_squad_spawner.dm`
  - `tgui/packages/tgui/interfaces/HumanSquadSpawner.tsx`
- После ручного разрешения `git ls-files -u` вернул пустой результат.
- `git diff --check --cached` прошел без замечаний.

## E-005: Результаты проверок
- `tools/build/build --ci dm -DCIBUILDING -DANSICOLORS -Werror`: passed, `0 errors, 0 warnings`, `2026-03-20`.
- `tools/build/build --ci tgui-test`: passed, `15` suites / `74` tests green, `2026-03-20`.
