# TODO

- [x] Rewrite `PLAN/TODO/DECISIONS/EVIDENCE` for the full PR `#61` UNSC/SQUADS refactor scope.
- [x] Remove obvious PR noise that does not support HALO ship runtime/maps/tests.
- [x] Move HALO shared squad/job defines into `code/__DEFINES/bandamarines/halo_jobs.dm` and update DME include ordering.
- [x] Delete legacy ODST compat datums, landmarks, tests, docs, and string contracts.
- [x] Rename and clean `marine_standart.dm` as legacy file-name debt.
- [x] Remove dead `auto_squad_name_unsc` preset routing and keep HALO squad assignment on SQUADS-owned flow.
- [x] Finalize HALO platoon ownership in `modular/squads` and keep `modular/halo` limited to content/faction/AI/map responsibilities.
- [x] Update upstream glue to use canonical `RoleAuthority` helpers for HALO marine-equivalent and shipside role handling.
- [x] Sync ship map configs/admin flow/tests with the final active HALO platoon typepaths.
- [x] Refresh `HALO_PORT_STATE.md` and evidence notes for the new no-legacy contract.
- [x] Run compile, unit-test, and map-sensitive verification.
- [ ] Optional follow-up outside PR `#61` scope: investigate the Windows `tools/build/build dm-test` wrapper exit code, which still reports failure despite clean test artifacts.
