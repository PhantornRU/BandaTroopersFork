# EVIDENCE

## E-001: Источник переноса
- Source path: `C:\Users\Alexsey\Desktop\Рабочее\XML-main`.
- Source files: `AGENTS.md` и `.AI_AGENT/{README,PROJECT_CONTEXT,WORKFLOW_RULES,POLICIES,REQUEST_PATTERNS,PLAN,TODO,DECISIONS,EVIDENCE}.md`.

## E-002: В BandaTroopers не было текущей agent-базы
- Факт: в репозитории отсутствовали `.AI_AGENT` и `AGENTS.md`.
- Источник: поиск по workspace перед переносом.

## E-003: Текущий SS220 документ был самостоятельным сводом правил
- Факт: [`../../__docs/SS220_DEVELOPMENT_RULES.md`](../../__docs/SS220_DEVELOPMENT_RULES.md) одновременно описывал `SS220 EDIT`, модульность и общие правила работы с ИИ.
- Вывод: после переноса его нужно сузить до repo-specific overlay, а не оставлять единственным каноном.

## E-004: Build/test команды подтверждены локальными docs и CI
- Репозиторный build entrypoint: `BUILD.cmd`, `tools/build/build`.
- CI-equivalent lint/test команды подтверждены `.github/workflows/ci_suite.yml` и `.github/workflows/run_unit_tests.yml`.
- Unit test reference подтвержден `code/modules/unit_tests/README.md`.
- Map/tooling reference подтвержден `tools/maplint/README.md`.

## E-005: Документный layout после переноса проверен
- `git diff --check` не выявил diff-format ошибок.
- `git check-ignore -v modular/__agents/.AI_AGENT/logs/test.log modular/__agents/.AI_AGENT/PLAN.md` подтвердил, что `logs/` игнорируется, а `PLAN.md` нет.
- Поиск по `.AI_AGENT|AGENTS.md|SS220_DEVELOPMENT_RULES` показал один канонический root `AGENTS.md` и ссылки только на `modular/__agents/.AI_AGENT/`.
