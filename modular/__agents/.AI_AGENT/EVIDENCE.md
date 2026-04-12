# EVIDENCE

## E-001: Current workspace state
- `git status --short --branch` showed a clean tree on `master...upstream/master` before starting this sync wave.
- `gh auth status` was previously rechecked and GitHub CLI access is available for fetch/PR work.

## E-002: Current HALO baseline and target range
- `modular/halo/__docs/HALO_PORT_STATE.md` pins the current HALO upstream baseline to `95a84ab9f59f9118e5543f664b2793e7a1841c55` dated `2026-03-11`.
- `git log --oneline 95a84ab9f59f9118e5543f664b2793e7a1841c55..cm-pve-halo/master` identified the next upstream wave ending at `765e2a2f81` dated `2026-04-10`.

## E-003: Upstream PR set confirmed for this request
- Open upstream PRs requested by the user: `#114`, `#116`, `#121`, `#123`, `#126`, `#132`, `#97`, `#100`.
- Additional merged upstream HALO PRs in the same range: `#115`, `#118`, `#122`, `#124`, `#125`, `#128`, `#131`.

## E-004: Relevant local coverage already exists
- Local `master` already contains commits `ab47067ef2`, `b1860fc0c5`, and `1fb8fb1a27`, which cover localized portions of `#114`, `#118`, `#121`, `#122`, `#124`, and `#125`.
- This means the current task is a reconciliation/follow-up wave, not a blank-slate HALO port.

## E-005: Missing HALO bookkeeping document
- `HALO_PORT_STATE.md` references `modular/halo/__docs/HALO_PORT_BACKLOG.md`, but that file did not exist at task start.
- The missing file must be created in this wave so future HALO syncs have a canonical per-PR tracker.

## E-006: Main sync wave implementation landed on `halo_sync_wave_apr2026`
- `#116` + `#131`: SPNKr attachment/storage flow, icon assets, launcher wear handling, and related UNSC storage updates were implemented.
- `#128` + `#132`: rifleman support weapon flow, DWTN spawn map updates, covenant AI timing, and ammo/gun balance deltas were implemented.
- `#123` + `#115` + `#126`: forerunner content, HALO phone subtypes, New Irvine area refactor, covenant New Irvine map/json, and the missing covenant recharger subtype were implemented modularly.
- `#114`/`#118` and `#121` were rechecked against already-localized local commits and recorded as covered/reconciled rather than re-ported blindly.

## E-007: Verification results for the main sync wave
- `git diff --check` returned cleanly after the wave was applied.
- `tools/build/build.bat --ci dm -DCIBUILDING -DANSICOLORS -Werror` finished with `0 errors, 0 warnings`.
- `tools/build/build.bat --ci dm -DCIBUILDING -DCITESTING -DALL_MAPS -DALL_MAPS_STAGE_BASE` initially exposed undefined `/obj/structure/machinery/recharger/covenant` references from `halo_new_irvine_covenant.dmm`, then passed cleanly after the modular recharger port.
- `tools/build/build.bat --ci dm -DCIBUILDING -DCITESTING -DALL_MAPS -DALL_MAPS_STAGE_EXTRA` finished with `0 errors, 0 warnings`.
- `tools/bootstrap/python -m mapmerge2.dmm_test` successfully parsed `279 .dmm files (0 modified)`.
