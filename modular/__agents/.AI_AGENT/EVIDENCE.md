# EVIDENCE

## E-001: Missing GroundSide rotation maps относительно `ru-master`
- На момент старта задачи в текущем `map_config/maps.txt` отсутствуют:
  - `lv671`
  - `oil_depot`
  - `derelict_almayer_infested`

## E-002: Текущие compile blockers
- `code/game/machinery/telecomms/presets.dm`: `OD0500 Expected a constant` на `if(FACTION_LIST_CANC)` внутри `switch(user.faction)`.
- `ALL_MAPS` compile падает на undefined/unknown type в:
  - `maps/map_files/BMG290_Otogi_Egress_Point/BMG290_Otogi_Egress_Point.dmm`
  - `maps/map_files/kleschers_research_site/BigBlue.dmm`
  - `maps/map_files/LV759_Hybrisa_Prospera/LV759_Hybrisa_Prospera.dmm`
  - `maps/map_files/LV759_Hybrisa_Prospera_Fixed/LV759_Hybrisa_Prospera_repaired.dmm`
  - `maps/map_files/USCSS_Onyx_Karain/USCSS_Onyx_Karain.dmm`

## E-003: Source refs для reconciliation
- `pr-1252` уже содержит canonical пути для:
  - `/obj/item/clothing/suit/storage/marine/veteran/pmc/light/corporate`
  - `/obj/item/clothing/suit/storage/marine/veteran/pmc/light/corporate/lead`
  - `/obj/item/storage/backpack/commando`
- `pr-1252` Hybrisa DMM использует:
  - `/obj/item/ammo_magazine/rifle/nsg23/extended`
  - `/obj/item/clothing/head/beret/royal_marine`

## E-004: DMI overflow
- `tools/bootstrap/python -m dmi.test` падает на:
  - `icons/mob/humans/onmob/uniform_0.dmi`
  - `icons/mob/humans/onmob/items_lefthand_0.dmi`
  - `icons/mob/humans/onmob/items_righthand_0.dmi`
