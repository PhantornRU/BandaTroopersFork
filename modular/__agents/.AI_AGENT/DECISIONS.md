# DECISIONS

## D-001: Keep the Jackal/Spartan wave separate from the April sync PR
- Decision: build this work on `master` in `halo_jackal_spartan_wave_apr2026`, not on top of `halo_sync_wave_apr2026`.
- Why: the user explicitly requested a separate PR for upstream `#97` and `#100`, and review remains cleaner if the branch does not silently inherit unrelated sync changes.

## D-002: Use modular-first ownership with minimal core glue
- Decision: place new HALO business logic, species, presets, clothing, squads, and compat layers in `modular/halo/**` by default, and touch `code/**` only for required integration points such as typechecks, subtype init hooks, emote routing, or rendering helpers.
- Why: this matches repository policy and keeps future HALO sync work isolated.

## D-003: Add Jackal squads as Covenant formations, not only as standalone presets
- Decision: extend the Covenant squad preset surface with Kig-Yar-specific teams and mixed Kig-Yar plus Sangheili/Unggoy formations that fit HALO lore.
- Why: the user explicitly requested spawn coverage and lore-consistent Covenant squads for Jackals; a pure species framework is not enough.

## D-004: Track exact upstream coverage and stop points in port docs
- Decision: create and maintain `modular/halo/__docs/HALO_PORT_BACKLOG.md` as the branch-level ledger for in-flight port waves and PR coverage.
- Why: the stable state doc must stay concise, while this task needs an explicit place to record what was ported, what remains, and where each upstream PR stopped locally.

## D-005: Adapt Spartan-specific hooks to existing BandaTroopers HALO compat surfaces
- Decision: reuse existing local HALO compat where it already solves the same runtime problem, instead of forcing upstream `pr-100` generic hooks verbatim.
- Why:
- `halo_throw_carbon()` already exists and replaces the nonexistent human `throw_carbon()` call in Spartan fling.
- local shield harnesses already expose `take_damage()` and projectile interception, so melee shield support is cleaner when routed through the existing residual-damage path.
- this keeps the Spartan port reviewable and reduces the chance of importing unrelated generic-engine churn.

## D-006: Record omitted upstream generic cleanup explicitly instead of silently pretending parity
- Decision: leave non-blocking upstream gun/muzzleflash and dodge-pool engine cleanup out of this branch, and document those omissions in `HALO_PORT_BACKLOG.md`.
- Why: the user asked not to lose track of stop points. Documented omission is safer and more honest than dragging a wider generic-engine refactor into a HALO-focused review branch.
