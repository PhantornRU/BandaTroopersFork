# TODO

## Batch 5 — CM-PVE Maybe-Port PRs (#1278, #1269, #1264, #1268)

## Contract Table

| ID | Type | Requirement | Evidence | Status |
| --- | --- | --- | --- | --- |
| M1 | MUST | #1278 Call ur hits: evaluate and port/skip | Diff audit confirms PVE-only LARP content in `souto.dm`; no BT relevance | SKIP |
| M2 | MUST | #1269 Snowman: evaluate and port/skip | Diff audit vs findstr: all 7 file changes present in BT (100% coverage) | ALREADY PRESENT |
| M3 | MUST | #1264 Shipmap lighting GM verb: evaluate and port/skip | Diff audit vs findstr: all 5 file changes present with SS220 EDIT (HALO PR #171) | ALREADY PRESENT |
| M4 | MUST | #1268 Active prox_sensor: evaluate and port/skip | Diff audit vs findstr: prox_sensor/active + defense_creator entry both present | ALREADY PRESENT |
| C1 | CHECK | BUILD.cmd 0 errors | `BUILD.cmd` (2026-06-08) → **0 errors, 0 warnings**, `Done in 72.86s`. DM compiler v516.1667. | PASS |

## Forbidden Substitutions
- Не портировать PVE-only LARP контент (#1278) в BT
- Не перезаписывать BT-файлы upstream версиями

## Execution Order
1. ~~#1278 Call ur hits — SKIP~~
2. ~~#1269 Snowman — ALREADY PRESENT~~
3. ~~#1264 Shipmap lighting — ALREADY PRESENT~~
4. ~~#1268 Active prox_sensor — ALREADY PRESENT~~
5. ~~BUILD.cmd compile check — PASS~~
6. EVIDENCE.md update — DONE
