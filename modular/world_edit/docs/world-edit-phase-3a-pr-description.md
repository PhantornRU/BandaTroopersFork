# About the pull request

Implements World Edit Phase 3A as a narrow follow-up after PR #81 stability work.

This pass only adds:
- per-admin presets for READY batch generators `outpost_radius` and `destruction_pack`
- Blueprint Lite server-side library for safe structure stamping
- minimal TGUI actions for preset and blueprint flows

This pass does not include undo, brush tools, hotkeys, continuous paint, legacy cleanup, or a wider Phase 3 rollout.

Implementation notes:
- presets are stored per-admin and validated on load before applying params
- blueprints are versioned and validated server-side before preview/apply
- blueprint scope is intentionally limited to whitelisted placeable structures only
- preview/apply reuse the same built plan through a dedicated `blueprint_stamp` READY generator
- saving blueprints is intentionally limited to the current `outpost_radius` preview plan

# Explain why it's good for the game

This makes World Edit materially more usable for repeated admin workflows without opening the door to the higher-risk parts of the old Phase 3 plan.

Presets reduce repeated parameter entry for the stabilized READY generators, while Blueprint Lite adds a safe non-destructive stamping tool that still stays inside the existing preview/apply execution model and server validation boundaries.

# Testing Photographs and Procedure

Automated checks run:
- `tools/build/build dm --ci --define=CIBUILDING --warning=error`
- `tools/build/build tgui-tsc --ci`
- `tools/build/build tgui-test --ci`

Manual/live validation:
- not executed in this environment
- intended live checklist:
- save/load/delete presets for `outpost_radius`
- save/load/delete presets for `destruction_pack`
- confirm preset load clears stale preview/current plan
- list/preview/apply valid blueprints
- reject invalid blueprints cleanly
- verify whitelist and cap enforcement
- smoke-test click generators for regressions

<details>
<summary>Screenshots & Videos</summary>

No live screenshots were captured in this environment.

</details>

# Changelog

:cl:
rscadd: Added per-admin World Edit presets for Outpost Radius and Destruction Pack.
rscadd: Added World Edit Blueprint Lite with safe server-validated structure preview and stamping.
tweak: Added preset and blueprint actions to the World Edit panel.
/:cl:
