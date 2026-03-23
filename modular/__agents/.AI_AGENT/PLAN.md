# PLAN

## Активная задача
Обновить текущую ветку `various_fixes` из актуального `upstream/master`, проверить итоговый git-state и отдельно выровнять удаленную ветку `origin/master` ровно на `upstream/master`, не переключая текущую ветку.

## Scope
- Обновить refs из remotes.
- Синхронизировать `various_fixes` с `upstream/master`.
- Проверить итоговый git-state и отсутствие конфликтных хвостов.
- Переставить локальный `master` на `upstream/master`.
- Форс-пушнуть `origin/master` на точный upstream commit.

## Out of scope
- Rebase или иное переписывание истории текущей рабочей ветки.
- Любые кодовые правки вне автоматического merge.
- Полный build/CI-прогон, если merge завершится без конфликтов и пользователь не просит compile-проверки отдельно.

## Решение
- Использовать `fetch -> merge -> verify -> push`.
- Для `master` использовать отдельный ref update и force-push без checkout.

## Итоговый статус
- `upstream/master` обновлен до `8667f84537`.
- `various_fixes` синхронизирована merge-коммитом `c94263128e`.
- `origin/various_fixes` обновлен до `c94263128e`.
- Локальный `master` и `origin/master` выровнены на `8667f84537`.
- Рабочее дерево чистое.

## Acceptance criteria
- `git fetch --all --prune` выполнен успешно.
- `upstream/master` является предком `HEAD`.
- `git diff --check` не сообщает ошибок.
- `origin/master` и `upstream/master` указывают на один и тот же commit.
