# DECISIONS

## D-001: Keep HALO runtime ownership split from the PR #61 refactor
- Decision: `modular/halo/**` continues to own HALO content and map support, while `modular/squads/**` continues to own active HALO platoons, squads, jobs, and ship-role helpers.
- Why: the upstream sync must land on top of the modular SQUADS architecture instead of partially reverting it.

## D-002: Port new HALO runtime/content into modular paths first
- Decision: new weapons, visuals, ODST pods, and other HALO-specific runtime content are landed in `modular/halo/**`, with only the smallest required glue left in `code/**`.
- Why: this keeps the sync modular-first and avoids leaking HALO business logic back into upstream-owned paths.

## D-003: Do not resurrect legacy ODST landmark or squad paths
- Decision: upstream map references such as `/obj/effect/landmark/late_join/odst`, `/obj/effect/landmark/start/marine/*/odst`, and the old single-squad ODST runtime are not restored.
- Why: the repository already removed that legacy surface; the correct fix is to migrate HALO maps to the current SQUADS-compatible landmark contract.

## D-004: Keep HALO ship JSON on HALO platoon families
- Decision: local HALO ship JSON files keep `/datum/squad/marine/halo/{unsc,odst}/alpha` and optional `allowed_platoons` instead of taking upstream's fallback to generic or legacy squad paths.
- Why: the local runtime now selects HALO platoons through ship profiles and `allowed_platoons`, so the JSON must stay aligned with that contract.

## D-005: Keep the local drop pod reservation fix
- Decision: the local ODST pod port requests `/datum/turf_reservation/transit/drop_pod` and releases the reservation after landing.
- Why: upstream was not using its own reservation subtype and leaked the reservation object after drop completion.

## D-006: Accept the current Windows `dm-test` wrapper caveat
- Decision: treat a non-zero `tools/build/build dm-test` wrapper exit as a tooling caveat, not a runtime failure, when the matching `data/unit_tests.json` and `data/logs/ci/clean_run.lk` both show a clean run.
- Why: the generated artifacts are the reliable signal for this environment, and they show the suite passing after the HALO sync.
