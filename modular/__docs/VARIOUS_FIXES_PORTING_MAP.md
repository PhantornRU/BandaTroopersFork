# halo_followup_apr2026: карта портов и split между main wave и PR94 update

Назначение документа:
- зафиксировать source-of-truth и commit anchors для текущей HALO follow-up волны;
- не смешать new main HALO wave с update существующего `ss220club/BandaTroopers#94`;
- дать короткую карту для повторной пересборки веток без blind cherry-pick смешанных upstream PR.

## База пересборки

- source-of-truth upstream repo: `https://github.com/cmss13-devs/cmss13-pve-halo`
- merged BT baseline перед этой волной: `ss220club/BandaTroopers#93`
- base main-wave ветки: `ss220club/master` на `66bf244f0ecf925736d9081053d35abb59fb6c6e`
- source upstream head для этой волны: `cm-pve-halo/master` на `33a011138b2529982de18896616a7cfa9d38f376`
- base ветки обновления `PR #94`: `origin/halo_jackal_spartan_wave_apr2026` на `d7a830c7dfdde8a8f849792ce01a7205a976cb4e`
- принцип пересборки:
  - сохранять authored non-merge commits или их semantic equivalent;
  - не переносить merge commits как source-of-truth;
  - mixed PR разбивать вручную по смыслу и по модульным границам BT.

## Что входит в main-wave ветку

1. [`cmss13-pve-halo#46`](https://github.com/cmss13-devs/cmss13-pve-halo/pull/46)
   - брать только residual scope после `15f2cc13bc`
   - tracked head for final verification: `8c4697c6f0` (previous anchor `5d6398ae32`; fresh Mackay lighting tail ported)
2. [`cmss13-pve-halo#126`](https://github.com/cmss13-devs/cmss13-pve-halo/pull/126)
   - брать delta после `1bac3e1d51`
   - текущий tracked head: `94cce6a541`
3. [`cmss13-pve-halo#134`](https://github.com/cmss13-devs/cmss13-pve-halo/pull/134)
   - `ONI Shield Base`
4. [`cmss13-pve-halo#135`](https://github.com/cmss13-devs/cmss13-pve-halo/pull/135)
   - `Valorous Chant`
5. [`cmss13-pve-halo#136`](https://github.com/cmss13-devs/cmss13-pve-halo/pull/136)
   - `686 Regretful Flame`
6. [`cmss13-pve-halo#139`](https://github.com/cmss13-devs/cmss13-pve-halo/pull/139)
   - landmine wave поверх уже существующего BT landmine framework
7. [`cmss13-pve-halo#140`](https://github.com/cmss13-devs/cmss13-pve-halo/pull/140)
   - weapon sprite/state wave
8. [`cmss13-pve-halo#141`](https://github.com/cmss13-devs/cmss13-pve-halo/pull/141)
   - shrapnel/projectile follow-up
9. [`cmss13-pve-halo#143`](https://github.com/cmss13-devs/cmss13-pve-halo/pull/143)
   - BR55 recoil follow-up
10. [`cmss13-pve-halo#137`](https://github.com/cmss13-devs/cmss13-pve-halo/pull/137)
   - audit-only modularization source; current reviewed head: `03820aa288`
11. supporting BT packaging
   - `HALO_PORT_STATE.md`
   - `HALO_PORT_BACKLOG.md`
   - `CODEOWNERS`
   - filled changelog snippet for the new PR

## Что входит в update ветки PR94

Ветка `codex/pr94-update` содержит только свежий Kig-Yar хвост:

1. semantic equivalent `21fe2b79f4` `Update standard.dm`
   - переносится в текущие `ruuhtian` armor contracts
2. semantic equivalent `4424f96051` `gawfwsdfsad`
   - shield typepath/item state/onmob icons + preset wiring
3. semantic equivalent `7e34c9db50` `Update colonialmarines.dme`
   - переносится только если реально нужен текущему BT include graph; иначе фиксируется как audited no-op
4. filled changelog snippet для обновления `PR #94`

## Ручные split-решения

### 1. `PR #46` после `15f2cc1`

Почему не cherry-pick:
- ветка содержит большой mixed tail, который уже пересекается с ранее влитым BT HALO scope;
- blind import почти гарантирует дублирование map/support/runtime diffs.

Что сохраняем:
- только missing map/pelican/LZ/armory/support изменения, которых нет в текущем BT `master`.

### 2. `PR #97` свежий tail

Почему не переносится file-to-file:
- upstream свежие изменения приходят в `code/modules/clothing/suits/marine_armor/covenant/standard.dm`;
- в BT этот scope уже разложен по `modular/halo/**`, включая `ruuhtian.dm` и modular shield wiring.

Что сохраняем:
- armor stat/default fixes;
- Kig-Yar shield runtime/preset wiring;
- include-coverage только там, где current BT graph действительно этого требует.

### 3. `PR #137`

Статус:
- audit-only source.
- current reviewed head: `03820aa288`
- fresh delta from previous anchor is legacy-layout `colonialmarines.dme` include ordering only; current BT `modular/halo/_halo.dme` does not require a runtime/code port.

Что считаем no-op:
- любую чистую modularization, уже перекрытую текущим `modular/halo/**`.

Что переносим:
- только missing runtime objects/type contracts, если они реально отсутствуют в BT tree.

## Основные hotspots этой волны

Если ветки придется пересобрать заново, сначала проверять:

1. `modular/halo/code/modules/projectiles/guns/halo/unsc_guns.dm`
2. `modular/halo/code/game/objects/items/weapons/halo_shields.dm`
3. `modular/halo/code/modules/gear_presets/Halo/ruuhtian.dm`
4. `code/game/objects/items/explosives/mine.dm`
5. `code/datums/ammo/shrapnel.dm`
6. `code/modules/projectiles/projectile.dm`
7. `code/modules/mob/living/carbon/human/ai/defense_creator.dm`
8. `maps/map_files/halo_new_irvine_covenant/halo_new_irvine_covenant.dmm`
9. `maps/map_files/{oni_shield_base,valorous_chant,686_regretful_flame}/`

Причина:
- именно здесь пересекаются modular/upstream split, shared runtime glue, map compile risks и fresh HALO asset contracts.

## Практический итог split

Main PR:
- ветка: `halo_sync_followup_apr2026`
- scope:
  - main HALO follow-up wave
  - карты `#126/#134/#135/#136`
  - mines/shrapnel/weapons `#139/#140/#141/#143`
  - audit `#137`
  - docs/changelog/CODEOWNERS

PR94 update:
- ветка: `codex/pr94-update`
- scope:
  - только свежий Kig-Yar tail из `#97`
  - без нового Spartan scope
