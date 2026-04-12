# HALO PORT BACKLOG

Companion document to `HALO_PORT_STATE.md`. This file tracks in-flight HALO port branches, upstream PR coverage, and exact local stop points. `HALO_PORT_STATE.md` remains the stable baseline document.

## Current local baseline
- Stable HALO baseline on `master`: see `HALO_PORT_STATE.md`.
- Current workspace branch for this wave: `halo_jackal_spartan_wave_apr2026`.
- Branch base commit: `071b21945bbf864221a1057673e19fef14d87b27`.

## Related in-flight waves

### April sync wave
- Branch: `halo_sync_wave_apr2026`
- Latest branch head: `690d8f04d47a9a528feea6e9852a579dbd047bc1`
- Published PR: `https://github.com/ss220club/BandaTroopers/pull/93`
- Target upstream pin recorded there: `765e2a2f81`
- Covered upstream PRs and waves:
- `#114`: partial local fixes existed before the sync; remaining merged content is tracked in PR `#93`.
- `#116`: ported in PR `#93`.
- `#121`: partially present before the sync; remaining merged content is tracked in PR `#93`.
- `#123`: ported in PR `#93`.
- `#126`: ported in PR `#93`.
- `#132`: ported in PR `#93`.

### Jackal + Spartan wave
- Branch: `halo_jackal_spartan_wave_apr2026`
- Base: `master` at `071b21945bbf864221a1057673e19fef14d87b27`
- Upstream source refs:
- `cm-pve-halo/pr-97` (`Jackal framework`)
- `cm-pve-halo/pr-100` (`Spartan stuff`)
- Goal: publish a separate PR against `SS220Club/BandaTroopers`

## Coverage ledger

### `#97` Jackal framework
- Source ref: `cm-pve-halo/pr-97`
- Initial local status at task start: not ported on this branch.
- Expected local ownership:
- `modular/halo/**` for Jackal defines, species, gear, clothing, storage, language, organs, AI presets, squads, and documentation.
- Minimal `code/**` glue only for typechecks, direct human subtype init, emote routing, or render helpers that modular HALO cannot own cleanly.
- Required BandaTroopers extension beyond upstream:
- Add Jackals to spawn surfaces and create lore-aligned Kig-Yar Covenant squads instead of stopping at framework-only content.
- Local stop point:
- Ported on `halo_jackal_spartan_wave_apr2026` for the branch gameplay scope.
- Exact local coverage:
- core glue: `code/__DEFINES/typecheck/humanoids.dm`, `code/game/sound.dm`, `code/modules/mob/living/carbon/human/{human,emote,human_helpers}.dm`, `code/modules/organs/{limb_objects,limbs}.dm`, `colonialmarines.dme`
- modular compat and data: HALO globals, language datums, language traits, Covenant skills, Kig-Yar pain and organ datums
- new Jackal species surface: species file, hair accessories, Jackal name bank, shield item, Covenant clothing and storage, gear presets, AI presets
- Covenant spawn extension: Jackal-only teams plus mixed lore squads `covenant_skirmisher_lance`, `covenant_marksman_lance`, `covenant_raider_lance`
- assets restored from upstream: Kig-Yar species icons, onmob clothing, shield sprite, voice lines, and shared Covenant clothing/object sheets required by the new paths
- Intentional local deviations:
- `display_name = "Kig-Yar"` and related local presentation polish stay aligned with BandaTroopers naming
- Jackal squad work goes beyond upstream framework-only scope because the branch requirement explicitly includes spawn coverage and lore squads
- Remaining stop point:
- no known gameplay gaps remain inside the requested `#97` scope on this branch; any future upstream-only delta after `cm-pve-halo/pr-97` is out of scope for this wave

### `#100` Spartan stuff
- Source ref: `cm-pve-halo/pr-100`
- Initial local status at task start: not ported on this branch.
- Expected local ownership:
- `modular/halo/**` for species, presets, clothing, storage, assets, and any HALO-only compat surface.
- `code/**` only for integration surfaces that Spartan actions, keybinds, jump, leaping, or combat hooks require.
- Known risk areas before port:
- Keybinding defines and living/human combat keybind surfaces.
- Jump and leaping components plus their signal contracts.
- Projectile, attack-hand, and armor degradation hooks tied to Mjolnir.
- Local stop point:
- Ported on `halo_jackal_spartan_wave_apr2026` for the branch gameplay scope.
- Exact local coverage:
- core glue: `code/__DEFINES/typecheck/humanoids.dm`, `code/_onclick/human.dm`, `code/datums/{pain/skills}.dm`, `code/modules/mob/living/carbon/{carbon}.dm`, `code/modules/mob/living/carbon/human/{human,emote,human_attackhand,human_defense,human_helpers}.dm`, `code/modules/organs/{limb_objects,limbs}.dm`, `code/modules/projectiles/{gun,gun_helpers,projectile}.dm`, `colonialmarines.dme`
- modular Spartan runtime: jump component, leaping component, keybindings, Mjolnir clothing set, Spartan species, actions, and presets
- modular support items: new shotgun handful, med pouch bio loadout, M52B webbing variants for `M7` and `MA5B`, SPNKr large holster backpack, UNSC shotgun shell rig fill preset
- admin/runtime spawn surface: direct `/mob/living/carbon/human/spartan` subtype init path added for admin create-object and spawn flows
- assets restored from upstream: Spartan species icons, 48px onmob clothing sheets, UNSC clothing/object sheets, `template_64.dmi`, and shared gloves/shoes sheets required by Mjolnir and Spartan body rendering
- Intentional local deviations:
- Spartan unarmed attack stays in `modular/halo/code/mixed/compat/halo_core_types.dm` instead of re-editing `code/modules/mob/living/carbon/human/unarmed_attacks.dm`, matching current HALO compat ownership
- melee energy shield handling is adapted through the existing local shield harness `take_damage()` path, returning residual damage when a hit overmatches the shield instead of hard-copying the upstream all-or-nothing helper
- Spartan fling uses existing local `halo_throw_carbon()` compat glue instead of a nonexistent base human `throw_carbon()` proc
- `tactical_reload()` condition is corrected locally to accept only matching magazines; upstream `pr-100` carried an inverted compatibility check
- Spartan equipped preset uses the existing base `/obj/item/storage/pouch/explosive` because `/obj/item/storage/pouch/explosive/unsc` does not exist on BandaTroopers
- Intentionally not ported from upstream `pr-100` because they are generic engine changes or not required for HALO gameplay parity on this base:
- projectile dodge-pool hit chance depletion/regeneration changes
- generic muzzle flash/emissive refactor and related non-HALO gun cleanup
- unrelated gun input/AI helper deltas that do not block Spartan runtime on BandaTroopers
- Remaining stop point:
- branch scope complete for requested Spartan gameplay content; omitted generic upstream engine cleanup is documented above and was not required to ship the HALO Spartan wave here

## Validation snapshot for this branch
- Validation date: `2026-04-12`
- `git diff --check`: passed
- `tools/build/build.bat --ci dm -DCIBUILDING -DANSICOLORS -Werror`: passed on `halo_jackal_spartan_wave_apr2026`

## Update rule
- Whenever this branch ports or intentionally skips part of an upstream PR, update the matching ledger entry in the same change.
- If PR `#93` or this branch move their stop point, record the new branch head and the exact affected upstream PRs here.
