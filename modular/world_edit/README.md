# World Edit Modpack

Модуль предоставляет единый каркас для инструментов редактирования мира и генераторов структур.

## Основные правила
- Legacy-файлы не изменяются.
- Новый код и документация находятся только в `modular/world_edit/*`.
- Документация и комментарии в модуле ведутся на русском языке.

## Состав
- `_world_edit.dm`: регистрация модпака.
- `code/core/world_edit_types.dm`: базовые типы, контракты и результаты операций.
- `code/core/world_edit_logging.dm`: единый контракт audit-логов.
- `code/core/world_edit_registry.dm`: реестр генераторов с fail-fast проверками.
- `code/core/manager/world_edit_manager_*.dm`: менеджер сессии, UI, preview/apply, click-intercept и история.
- `code/legacy/world_edit_legacy_block.dm`: дублированные алгоритмы для legacy-паритета.
- `code/generators/world_edit_generator_*.dm`: runtime-реализации current ready surface.
- `code/generators/shared/world_edit_generator_shared_helpers.dm`: общие helper-процедуры генераторов.
- `code/effects/world_edit_persistent_fire.dm`: служебные эффекты модуля.

## Документация
- `docs/implementation_plan.md`: roadmap и smoke-checklist.
- `docs/game_design.md`: UX, права, guardrails, политика intercept.
- `docs/ui_field_schema_v2.md`: единый inline UI-контракт.
- `docs/generator_document_template.md`: шаблон паспорта генератора.
- `docs/generator_catalog_seed.md`: каталог current ready surface и исторических паспортов.
- `docs/generators/*.md`: исторические паспорта удаленных deprecated генераторов.

## Current ready surface
- `outpost_radius`
- `destruction_pack`
- `blueprint_stamp`
