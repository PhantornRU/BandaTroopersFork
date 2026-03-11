# DECISIONS

## D-001: HALO platoon runtime is owned by `modular/squads`
- Decision: active HALO UNSC/ODST platoon profiles, squad/job datums, lockers, and ship-role helper APIs live in `modular/squads`.
- Why: this matches the repository's modular split and prevents a second HALO-owned squad runtime.

## D-002: Legacy ODST compat is removed in the same wave
- Decision: delete legacy `/datum/squad/marine/odst`, legacy ODST job paths, compat landmarks, and supporting tests/docs instead of keeping wrappers.
- Why: the task explicitly requires full cleanup, and dual runtime surfaces keep the refactor incomplete.

## D-003: HALO public string contracts stay stable but move to bandamarines defines
- Decision: preserve existing HALO job-title and platoon-label strings, but move the shared macros to `code/__DEFINES/bandamarines/halo_jobs.dm`.
- Why: these are stable cross-layer contracts and should live in the upstream define surface reserved for shared SS220 identifiers.

## D-004: `RoleAuthority` is the only ship-side HALO API for shared consumers
- Decision: latejoin, preferences, vendor/locker gating, manifest/datacore, HUD/counters, and ship profile UI use `RoleAuthority` helpers and default-role mapping instead of widening upstream role lists or branching on HALO strings.
- Why: shared consumers still need correct HALO behavior, but the integration point must stay narrow and reusable.

## D-005: `allowed_platoons` remains the only ship platoon selection surface
- Decision: HALO ship maps continue to resolve platoon choice from ship JSON `platoon` plus optional `allowed_platoons` admin override persisted in `data/next_ship.json`.
- Why: this is already the data-driven selection surface and does not need an additional runtime override path.

## D-006: PR cleanup removes only non-deliverable noise
- Decision: strip obvious IDE/UI/noise changes that do not support HALO ship runtime, HALO maps, or verification, but keep map-critical HALO content required by the ship maps.
- Why: the PR must be cleaner, but map-supporting HALO content still belongs to the same delivery.

## D-007: Windows `dm-test` wrapper noise does not redefine the HALO refactor result
- Decision: treat the current non-zero `tools/build/build dm-test` wrapper exit on Windows as a tooling caveat, not as evidence of failing HALO runtime tests, when `data/unit_tests.json` and `data/logs/ci/clean_run.lk` are both clean for the same run.
- Why: the produced unit-test artifacts show a successful suite, including the HALO ship platoon tests, and the failure appears in the wrapper layer rather than in the runtime or test logic.
