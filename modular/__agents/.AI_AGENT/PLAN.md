# PLAN

## Активная задача
Портировать в SS220/BandaTroopers HALO map changes из upstream PR `#46`, `#96` и `#107`, адаптировать интеграцию под локальные HALO/shipmap правила и подготовить итоговый PR с корректным changelog и ссылками на исходные PR.

## Scope
- Импорт новых HALO ground/ship maps, shuttle templates и связанных ассетов.
- Интеграция новых карт в `colonialmarines.dme`, `maps/templates_base.dm`, `map_config/*.txt`, `code/__DEFINES/*`, `code/datums/shuttles.dm` и связанные runtime surfaces.
- Адаптация портируемых ship/map конфигов под BandaTroopers-specific HALO platoon routing.
- Подготовка task-state артефактов и текста итогового PR.
- Минимальные проверки для map-sensitive задачи.

## Out of scope
- Несвязанные HALO refactor-задачи.
- Переписывание upstream истории через rebase/cherry-pick поверх всего PR history.
- Дополнительные контентные изменения в самих картах вне необходимых BandaTroopers-адаптаций.

## Фазы
1. Подтвердить upstream baseline, scope PR и точки интеграции. Выполнено.
2. Импортировать payload из PR `#46`, `#96`, `#107` и собрать локальный merge-план. Выполнено.
3. Внести SS220/BandaTroopers-адаптации в upstream/config/runtime surfaces. Выполнено.
4. Обновить task-state документы и подготовить PR body/changelog. Выполнено.
5. Выполнить проверки (`git diff --check`, build/maplint по возможности), зафиксировать evidence и остаточные риски. Выполнено.

## Acceptance criteria
- В репозитории присутствуют все необходимые файлы и integration points для PR `#46`, `#96`, `#107`.
- HALO shipmap `Mackay Station (Shipmap)` работает через локальную halo platoon routing схему, а не через legacy marine squad paths.
- Новые карты добавлены в map/template/config surfaces, достаточные для загрузки через локальный pipeline.
- Подготовлен итоговый PR текст со ссылками на upstream PR и changelog по портам.
- Статус выполненных и невыполненных проверок зафиксирован явно.
