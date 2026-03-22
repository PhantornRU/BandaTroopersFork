# EVIDENCE

## E-001: Weather holder pattern подтвержден по соседним картам
- `code/datums/weather/weather_map_holders/big_red.dm` и аналогичные holders используют `prob(PROB_WEATHER_...)`, а не `return TRUE`.
- `Mackay_Station.dm` и `oni_digsite_451.dm` были единственными новыми holders с guaranteed-start логикой.

## E-002: Подходящий ambience asset существует локально
- `rg --files sound/ambience` показывает `sound/ambience/desert.ogg`.
- `code/__DEFINES/sounds.dm` уже использует этот asset для `AMBIENCE_BIGRED` и `AMBIENCE_TRIJENT`.

## E-003: `new_varadero` dir comment подтвержден не полностью
- DMI metadata из `icons/turf/floors/new_varadero/sea_tiles.dmi` показывает:
  - `state = "beach"` -> `dirs = 8`
  - `state = "beachcorner"` -> `dirs = 4`
  - `state = "beachcorner2"` -> `dirs = 4`
- Suggested diagonal dir constants из review comment не совпадают с `dirs = 4`.
- Базовый `code/game/turfs/open.dm` содержит тот же `coast/beachcorner*` dir pattern, что и `new_varadero.dm`.

## E-004: Pelican/Covenant comments подтверждены по локальному коду
- `code/game/machinery/computer/dropship_weapons.dm`: subtype `/pelican` был единственным large console с `density = FALSE`.
- `code/game/machinery/nuclearbomb.dm`: в `covenant_bomb/update_icon()` условие `if(timing)` действительно перекрывает `timing == -1` и добавляет лишний overlay.
