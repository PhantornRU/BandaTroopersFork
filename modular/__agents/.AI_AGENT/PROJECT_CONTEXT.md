# Контекст проекта

## Что является source of truth
- Точка входа и include graph: `colonialmarines.dme`.
- Апстрим-хардкод и базовые подсистемы: `code/**` и другие пути вне `modular/**`.
- Модульные расширения BandaTroopers: `modular/**`.
- Карты и map-конфиги: `maps/**`, `map_config/**`, `.github/maps_to_ignore.txt`.
- Build и CI контракты: `BUILD.cmd`, `tools/build/**`, `.github/workflows/**`.
- UI и фронтенд-слой: `tgui/**`.

## Основные контуры репозитория
- Новая бизнес-логика по умолчанию живет в `modular/**`.
- `code/**` и другие upstream-пути используются как слой интеграции с минимальным диффом.
- Карты, map config и ignore-списки должны рассматриваться совместно, если задача затрагивает ротацию, компиляцию карт или test matrix.
- Сборка репозитория опирается на `BUILD.cmd` / `tools/build/build`, а не на ручной DreamMaker-only процесс.

## Архитектурные ограничения
- Новую предметную логику сначала искать место в `modular/**`, затем уже решать, какой glue нужен в upstream.
- В апстрим-файлы добавлять только хуки, адаптеры, fallback-ветки и неизбежный glue-код для совместимости.
- Структуру include-цепочки и build/compile контракты не менять без явного запроса.
- Скомпилированные артефакты (`*.dmb`, `*.rsc`) и `node_modules` не считаются source of truth для ручных правок.
- Existing extension points, signals и адаптеры проверяются до того, как вносить новую интеграцию в апстрим.

## Что не менять без согласования
- Build workflow contract: `BUILD.cmd`, `tools/build/**`, CI-вызовы из `.github/workflows/**`.
- CI-facing команды lint/build/test, уже используемые workflow.
- Семантику ротации карт, `map_config/**` и `.github/maps_to_ignore.txt`, если задача не про карты.
- Стабильные squad/runtime контракты и другие upstream-facing интерфейсы, на которые опираются SS220-модули.
- Generated или compiled output, если это не является прямой целью задачи.
