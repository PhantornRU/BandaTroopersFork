# PLAN

## Active Task
Implement a new modular `pony_xeno` module for `ss220club/BandaTroopers` that adds hostile pony-themed AI mobs on top of the existing `/mob/living/carbon/xenomorph` stack.

## Scope
- Create a new `modular/pony_xeno` module and include it from `modular/modular.dme`.
- Add `/mob/living/carbon/xenomorph/pony` plus four caste-backed pony xeno subtypes:
  - `pegasus_skirmisher`
  - `earth_bruiser`
  - `unicorn_caster`
  - `alicorn_matriarch`
- Keep all pony enemies compatible with the current xeno ecosystem:
  - caste datum
  - hive and designation flow
  - `SSxeno_ai`
  - movement/pathfinding
  - combat loop and aggro
  - spawn/wave usage by type swap
  - xeno actions
  - minimap
  - death, gibs, remains
- Implement a data-driven pony composite sprite pipeline with runtime generation and caching from separate pony parts.
- Add pony-specific flavor, naming, sound hooks, blood/remains visuals, and a convenient test entrypoint.
- Make only minimal upstream glue changes where modular hooks are not sufficient.
- Ensure pony castes are selectable from admin spawn flows that resolve xenos by caste text:
  - `Create Xenos`
  - `Game Master Panel`
  - Game Master ambush submenu parity with arachnid
- Stabilize runtime icon-pack generation so directional composite sprites no longer throw `bad icon operation` during `Insert()`.

## Out Of Scope
- Full port of tgstation pony species gameplay, surgery, or player-facing pony race systems.
- Replacing the existing xeno AI architecture or caste framework.
- Broad art polish beyond the requested compile-safe and gameplay-readable pony xeno presentation.
- Unrelated refactors in `code/**` or `modular/**`.

## Decision-Complete Plan
1. Rewrite task-state files for the new `pony_xeno` scope.
2. Build the module skeleton mirroring `modular/arachnid`.
3. Implement the base pony xeno type, appearance datum, naming, and shared helpers.
4. Implement runtime pony sprite compositing, palette handling, cache keys, and state pack generation.
5. Add the four caste datums/subtypes with caste-specific visuals, stats, action sets, and minimap presentation.
6. Add pony sound hooks, blood/gib/remains integration, and a test spawner/admin-friendly entrypoint.
7. Add the smallest possible upstream glue for admin caste-text resolution and panel spawn lists so pony castes work in existing admin spawn UX.
8. Refactor generated icon pack assembly to use stable single-direction canvases, deterministic state names, and safer blend offsets.
9. Run targeted build verification and fix compile/runtime issues until the module is integration-ready.

## Challenge Block
- Doubt 1: xeno icon updates are hardcoded around named icon states, so fully dynamic runtime pony composites may require a thin upstream adapter to remain compile-safe.
- Doubt 2: the repo does not already contain pony body-part assets, so the first implementation must create a maintainable local part set while preserving the requested compositing architecture.
- Doubt 3: pony visuals need to stay readable in xeno combat silhouettes, which may require selective abstraction from the tgstation pony art reference instead of literal one-to-one reuse.

## Alternatives Considered
- Alternative A: build pre-baked full sprites per caste/state.
  Rejected because the request explicitly requires composition from separate pony parts and a reusable data-driven pipeline.
- Alternative B: implement pony mobs outside the xenomorph hierarchy.
  Rejected because the request explicitly requires compatibility with existing xeno AI, hive, caste, wave, minimap, and action systems.
- Alternative C: patch large parts of the upstream xeno icon system.
  Rejected because SS220 guidance prefers modular ownership and minimal glue in `code/**`.

## Acceptance Criteria
- `modular/pony_xeno` exists and is wired into the build.
- Four pony xeno castes compile and can be admin-spawned by type and by admin panel caste selection.
- Each pony xeno initializes through normal xeno lifecycle and can use the current AI stack.
- Pony visuals are generated from composited parts with deterministic appearance selection and cache reuse.
- Runtime pony icon-pack generation no longer throws `bad icon operation` when creating directional xeno states.
- Pony mobs expose pony-specific naming/flavor, sounds, minimap presentation, and death/remains visuals.
- Verification is run through the repository build path, or any remaining blockers are explicitly documented.
