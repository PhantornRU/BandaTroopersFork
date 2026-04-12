# DECISIONS

## D-001: Split the work into two PRs exactly as requested
- Decision: keep the current HALO build sync in one PR and ship upstream `#97` + `#100` in a separate PR.
- Why: the user explicitly requested a separate PR for the Jackal/Spartan wave, and that wave changes spawn-facing gameplay scope beyond the core sync bundle.

## D-002: Use `HALO_PORT_STATE.md` for the pinned baseline and `HALO_PORT_BACKLOG.md` for wave tracking
- Decision: `HALO_PORT_STATE.md` remains the source of truth for the current pinned upstream baseline, while `HALO_PORT_BACKLOG.md` tracks requested PRs, partial local ports, and wave-level status.
- Why: `HALO_PORT_STATE.md` already references the backlog document; creating and maintaining that secondary map avoids overloading the baseline document with per-PR bookkeeping.

## D-003: Preserve BandaTroopers modular ownership while porting upstream deltas
- Decision: port HALO content into `modular/halo/**` and keep non-modular changes limited to minimal integration glue where the repo already relies on shared upstream systems.
- Why: this matches repo policy, reduces future merge pressure, and preserves existing local HALO deviations around squads, maps, and compat layers.

## D-004: Treat already-landed local ports as partial fulfillment of requested upstream PRs
- Decision: when the local branch already contains equivalent work from the requested upstream PR list, document that coverage and only port the remaining delta.
- Why: the current master already includes prior HALO waves such as `#121`, `#122`, `#124`, and `#125` in localized form, so re-porting them blindly would create regressions and duplicate history.

## D-005: Port shared upstream HALO map dependencies into modular overlays instead of reopening core files
- Decision: HALO phone subtypes, forerunner turf/gate content, and covenant recharger support were added as new modular files and included from `modular/halo/_halo.dme` instead of editing the upstream shared files directly.
- Why: the repo requires modular-first ownership, and these additions are HALO-specific map dependencies rather than general-engine behavior changes.

## D-006: Keep the DWTN armory on the unified `ship_armory` id even where upstream left one stale button
- Decision: the ODST armory control button was retargeted from `ship_armory2` to `ship_armory` together with the rest of the `#128` shutter rename.
- Why: after porting the upstream DWTN map changes, leaving that one button on `ship_armory2` would point it at a non-existent shutter id in BandaTroopers and silently break the remaining armory control.
