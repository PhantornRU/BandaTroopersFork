# PLAN

## Активная задача
Перенести модель `.AI_AGENT` из приватного XML-репозитория в BandaTroopers:
- добавить корневой `AGENTS.md` как канонический entrypoint;
- разместить агентную базу в `modular/__agents/.AI_AGENT/`;
- сохранить tracked task-state в git;
- переписать [`../../__docs/SS220_DEVELOPMENT_RULES.md`](../../__docs/SS220_DEVELOPMENT_RULES.md) в overlay над новой агентной базой.

## Статус
Структура перенесена, overlay переписан, базовые документные проверки выполнены.

## Границы
- В scope: `AGENTS.md`, `modular/__agents/.AI_AGENT/*.md`, `.gitignore`, [`../../__docs/SS220_DEVELOPMENT_RULES.md`](../../__docs/SS220_DEVELOPMENT_RULES.md).
- Вне scope: gameplay code, runtime logic, build logic, map contents, tgui implementation.

## Фазы
1. Создать корневой `AGENTS.md` и новый agent hub в `modular/__agents/.AI_AGENT/`.
2. Перенести stable guidance почти 1:1 по структуре, но переписать под BandaTroopers.
3. Заполнить `PLAN.md`, `TODO.md`, `DECISIONS.md`, `EVIDENCE.md` текущей задачей.
4. Перестроить SS220 документ в overlay к новой системе правил.
5. Обновить `.gitignore` только для `modular/__agents/.AI_AGENT/logs/`.
6. Проверить ссылки, канонические упоминания и diff hygiene.

## Acceptance Criteria
- `AGENTS.md` в корне маршрутизирует только в `modular/__agents/.AI_AGENT/`.
- В `modular/__agents/.AI_AGENT/` присутствует полный ожидаемый набор файлов.
- Task-state Markdown tracked в git, а raw logs игнорируются.
- [`../../__docs/SS220_DEVELOPMENT_RULES.md`](../../__docs/SS220_DEVELOPMENT_RULES.md) больше не является глобальным каноном и описывает только SS220/BandaTroopers-specific overlay.
- Документы ссылаются на реальные пути и команды этого репозитория.
