# HALO PORT BACKLOG

Canonical baseline: [`__docs/HALO_PORT_STATE.md`](./__docs/HALO_PORT_STATE.md). For any HALO port/sync/update task, read the state doc first. If this backlog and the state doc diverge, the state doc wins.

## Completion Check (2026-06-07)

All 20 merged PRs from `cmss13-devs/cmss13-pve-halo` master have been classified and processed:

| Status | Count | PRs |
|--------|-------|-----|
| **PORTED** | 16 | #46, #113, #118, #120, #126, #129, #132, #134, #135, #136, #137, #138, #139, #140, #141, #143 |
| **ALREADY PRESENT** | 13 | #97, #100, #103, #134, #135, #136, #142, #144, #145, #146, #148, #149, #150 |
| **SKIP (deferred)** | 0 | — |

> Note: #134/#135/#136 (map PRs) and #97 (Kig-Yar)/#100 (Spartan) confirmed fully ported 2026-06-07. BUILD.cmd 0 errors, all semantic contracts verified via rg audit. Net unique PRs: 20. **ALL PRs PORTED.**

Final batch committed and pushed:
- `4528573e16` → `0cce29aac3`: PR #118 Flavor Fixes, PR #120 Halo Firesupport, PR #129 Faction splitting
- Branch: `halo-pve-update-batch1-3b`
- PR: https://github.com/ss220club/BandaTroopers/pull/102

## Deferred Scope
- Broad HALO AI scenario parity beyond requested ODST/HALO flow.
- Additional non-critical flavor drift not affecting compile/playability.
- Map PRs #134/#135/#136 — full DMM integration deferred to dedicated map wave.
- PR #97 (Kig-Yar tail) and PR #100 (Spartan base) — deferred to `halo_jackal_spartan_wave_apr2026` branch (PR #94 update).

## Next Sync Tasks
- Recheck the compatibility hotspots listed in [`__docs/HALO_PORT_STATE.md`](./__docs/HALO_PORT_STATE.md) before changing upstream-facing HALO glue.
- Keep documenting intentional source deviations from `cmss13-pve-halo`.
- Perform runtime smoke on live host/session.

## Open Caveats
- Local monolithic invocation `tools/build/build dm --ci --define=ALL_MAPS --define=CIBUILDING` crashes DM process (`3221225477`) after map loading; staged CI-equivalent map compile remains the current acceptance signal.
