# TODO

- [x] Port map-critical HALO typepaths into `modular/halo/**` (`areas`, `doors`, `decals`, `dispensers`, `barrels`, `toolboxes`, `ammo boxes`, `job lockers`).
- [x] Wire all new HALO files in `modular/halo/_halo.dme`.
- [x] Add ODST constants and role lists in `code/__DEFINES/{job,mode}.dm`.
- [x] Add ODST comms mapping in `code/controllers/subsystem/communications.dm`.
- [x] Add ODST squad datum + latejoin/start landmarks + ODST job datums.
- [x] Add ODST preference preset routing and FACTION_UNSC intro branches.
- [x] Add missing intro picture typepaths in `code/modules/maptext_alerts/misc_alert.dm`.
- [x] Validate map compile via CI-equivalent staged ALL_MAPS builds.
- [x] Validate HALO maps with maplint.
- [ ] Optional follow-up: root-cause local DM crash for monolithic `ALL_MAPS + CIBUILDING` run.
- [ ] Runtime smoke on live round (ODST latejoin/start flow, ODST channel span presentation, UNSC intro screens).
