# AGENTS.md

Каноническая точка входа для Codex и совместимых AI-агентов в этом репозитории.

## Порядок чтения
1. [`modular/__agents/.AI_AGENT/README.md`](./modular/__agents/.AI_AGENT/README.md)
2. Активный task-state:
   - [`modular/__agents/.AI_AGENT/PLAN.md`](./modular/__agents/.AI_AGENT/PLAN.md)
   - [`modular/__agents/.AI_AGENT/TODO.md`](./modular/__agents/.AI_AGENT/TODO.md)
   - [`modular/__agents/.AI_AGENT/DECISIONS.md`](./modular/__agents/.AI_AGENT/DECISIONS.md)
   - [`modular/__agents/.AI_AGENT/EVIDENCE.md`](./modular/__agents/.AI_AGENT/EVIDENCE.md)
3. Stable guidance:
   - [`modular/__agents/.AI_AGENT/PROJECT_CONTEXT.md`](./modular/__agents/.AI_AGENT/PROJECT_CONTEXT.md)
   - [`modular/__agents/.AI_AGENT/WORKFLOW_RULES.md`](./modular/__agents/.AI_AGENT/WORKFLOW_RULES.md)
   - [`modular/__agents/.AI_AGENT/POLICIES.md`](./modular/__agents/.AI_AGENT/POLICIES.md)
   - [`modular/__agents/.AI_AGENT/REQUEST_PATTERNS.md`](./modular/__agents/.AI_AGENT/REQUEST_PATTERNS.md)
4. Репозиторный overlay:
   - [`modular/__docs/SS220_DEVELOPMENT_RULES.md`](./modular/__docs/SS220_DEVELOPMENT_RULES.md)
5. Затем только релевантные продуктовые документы:
   - [`.github/guides/STANDARDS.md`](./.github/guides/STANDARDS.md)
   - [`.github/guides/STYLES.md`](./.github/guides/STYLES.md)
   - [`tools/build/README.md`](./tools/build/README.md)
   - [`code/modules/unit_tests/README.md`](./code/modules/unit_tests/README.md)
   - [`tools/maplint/README.md`](./tools/maplint/README.md)
   - [`tgui/README.md`](./tgui/README.md)

## Жесткие правила
- Перед правками собрать контекст: entrypoints, include graph, callsites, data flow, side effects.
- Для поиска использовать `rg` и точечное чтение файлов, а не широкое сканирование дерева.
- Новую бизнес-логику по умолчанию размещать в `modular/**`.
- В `code/**` и других не-`modular/` путях держать только минимальные точки интеграции, fallback и glue-код.
- Маркеры `SS220 EDIT` применяются только вне `modular/**` и по правилам из [`modular/__docs/SS220_DEVELOPMENT_RULES.md`](./modular/__docs/SS220_DEVELOPMENT_RULES.md).
- Сборку и compile-проверки запускать через `BUILD.cmd` или `tools/build/build`, а не через DreamMaker-only workflow.
- Не использовать деструктивные git-команды без прямого запроса пользователя.

## Маршрутизация
- Агентная база знаний: [`modular/__agents/.AI_AGENT/`](./modular/__agents/.AI_AGENT/README.md)
- SS220/BandaTroopers-specific overlay: [`modular/__docs/SS220_DEVELOPMENT_RULES.md`](./modular/__docs/SS220_DEVELOPMENT_RULES.md)
- Продуктовые документы: `modular/__docs/**`, `.github/guides/**`, `tools/**/README.md`, `tgui/**`
