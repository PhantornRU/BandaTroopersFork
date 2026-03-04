# DECISIONS

## D-001: Канонический inventory карт берем из `ru-master`
- Решение: missing GroundSide карты определяются сравнением текущего `map_config/maps.txt` и `maps/*.json` с `ru-master`, без shipmap-роутинга.
- Почему: это снимает двусмысленность между отдельными RU PR и финальным состоянием их master-ветки.

## D-002: Source-canonical paths чиним code-side compatibility type'ами
- Решение: для `commando`, `beret/royal_marine`, `nsg23/extended` добавляются совместимые типы в коде.
- Почему: эти пути встречаются в source refs и не являются локальной merge-поломкой.

## D-003: Явный merge-corruption чиним map-side
- Решение: битые DMM tokens вроде слитой строки в `USCSS_Onyx_Karain.dmm` и path-loss в Otogi/BigBlue правятся прямо в `.dmm`.
- Почему: такие пути не являются корректным source state и не должны закрепляться новыми alias.

## D-004: DMI overflow закрывается split-файлами
- Решение: новые onmob/inhand состояния выносятся в отдельные DMI с explicit `item_icons`/`contained_sprite` repoint.
- Почему: базовые `uniform_0.dmi`, `items_lefthand_0.dmi`, `items_righthand_0.dmi` уже переполнены и дальше расширяться не должны.
