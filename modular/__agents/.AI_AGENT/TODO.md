# TODO

- [x] Rewrite `PLAN/TODO/DECISIONS/EVIDENCE` for the HALO upstream sync task.
- [x] Diff the current HALO modular baseline against upstream `cmss13-pve-halo`.
- [x] Port the new HALO weapons, assets, temporary visuals, and sound-dependent content into `modular/halo`.
- [x] Port ODST drop pods and the supporting admin UI/runtime glue.
- [x] Port the upstream `dark_was_the_night` HALO map updates while keeping the local SQUADS-owned HALO runtime contract.
- [x] Fill missing modular support types required by the synced HALO maps (`MA5B` gun racks and ammo boxes).
- [x] Run compile, all-maps compile, maplint, and `dm-test` verification in a clean tree.
- [ ] Optional follow-up outside this task: investigate why the Windows `tools/build/build dm-test` wrapper still exits non-zero when the generated test artifacts are clean.
