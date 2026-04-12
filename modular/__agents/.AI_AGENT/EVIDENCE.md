# EVIDENCE

## E-001: Branch layout at task start
- Current working branch: `halo_jackal_spartan_wave_apr2026`.
- Branch base: `071b21945bbf864221a1057673e19fef14d87b27` (`master`, `upstream/master`, `origin/master`).
- Separate April sync branch already exists: `halo_sync_wave_apr2026` at `690d8f04d47a9a528feea6e9852a579dbd047bc1`.
- Merge-base between the two branches is `071b21945bbf864221a1057673e19fef14d87b27`, so this branch is currently independent from PR `#93`.

## E-002: Upstream source refs are available locally
- Remote `cm-pve-halo` is configured and exposes `cm-pve-halo/pr-97`, `cm-pve-halo/pr-100`, `cm-pve-halo/pr-114`, `cm-pve-halo/pr-116`, `cm-pve-halo/pr-121`, `cm-pve-halo/pr-123`, `cm-pve-halo/pr-126`, `cm-pve-halo/pr-132`, and `cm-pve-halo/master`.
- `cm-pve-halo/pr-97` is the upstream `Jackal framework` branch.
- `cm-pve-halo/pr-100` is the upstream `Spartan stuff` branch.

## E-003: Existing local HALO surfaces already cover Sangheili and Unggoy
- `modular/halo/_halo.dme` already includes modular HALO pain, language, organs, Covenant presets, HALO AI presets, squad presets, and Sangheili/Unggoy species files.
- Local HALO AI already exposes Covenant squad presets in `modular/halo/code/modules/mob/living/carbon/human/ai/squad_spawner/halo/squad_covenant.dm`.
- Current compat globals only define Sangheili and Unggoy name banks in `modular/halo/code/mixed/compat/halo_core_globals.dm`.

## E-004: Port backlog doc was missing on this branch
- `modular/halo/__docs/HALO_PORT_STATE.md` exists and still points at the older stable baseline.
- `modular/halo/__docs/HALO_PORT_BACKLOG.md` was absent on this branch and must be created to track this separate wave plus the already-prepared April sync branch.

## E-005: Required local gaps are already visible before edits
- Typecheck helpers only cover `issangheili` and `isunggoy`; there is no local `isruuhtian` or `isspartan`.
- `human.dm` already has direct subtype init hooks for Sangheili and Unggoy but not for Jackals or Spartans.
- Human emote routing already has Sangheili/Unggoy support but no Jackal/Spartan coverage.
- Jackal and Spartan names, species, clothing, presets, storage, and assets are not present in `modular/halo/**` yet.

## E-006: Jackal and Spartan branch validation now passes
- `git diff --check` returned clean after the port work.
- `tools/build/build.bat --ci dm -DCIBUILDING -DANSICOLORS -Werror` passed on `halo_jackal_spartan_wave_apr2026` with `0 errors, 0 warnings`.

## E-007: Port docs now record both the April sync wave and the separate Jackal/Spartan wave
- `modular/halo/__docs/HALO_PORT_BACKLOG.md` now tracks:
- published April sync PR `#93`
- exact `#97` Jackal coverage on this branch
- exact `#100` Spartan coverage on this branch
- intentional local deviations and omitted generic upstream cleanup for `#100`
