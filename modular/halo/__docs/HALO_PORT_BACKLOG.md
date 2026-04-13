# HALO PORT BACKLOG

Secondary tracking document for HALO upstream sync waves. `HALO_PORT_STATE.md` owns the pinned baseline; this document tracks branch split, current PR coverage, and exact stop points for the in-flight HALO waves.

## Active Sync Wave
- Source repository: `https://github.com/cmss13-devs/cmss13-pve-halo`
- Previous pinned upstream commit: `95a84ab9f59f9118e5543f664b2793e7a1841c55` (`2026-03-11`)
- Target upstream head for the April wave: `765e2a2f81` (`2026-04-10`)
- BandaTroopers execution model:
  - PR 1: main HALO sync wave
  - PR 2: Jackal + Spartan supplemental wave (`#97` + `#100`)

## Main HALO Sync PR
- Branch: `halo_sync_wave_apr2026`
- Latest recorded branch head: `690d8f04d47a9a528feea6e9852a579dbd047bc1`
- BandaTroopers PR: `https://github.com/ss220club/BandaTroopers/pull/93`
- Status: implemented and locally verified.
- Covered upstream PRs and waves:
  - `#114`: previously localized; remaining delta landed in PR `#93`.
  - `#115`: HALO phone subtype dependency ported for New Irvine support.
  - `#116`: ported in PR `#93`.
  - `#118`: previously localized; remaining delta verified in PR `#93`.
  - `#121`: existing featureless-biome coverage preserved and reconciled.
  - `#122`, `#124`, `#125`: already covered before this wave and documented as such.
  - `#123`: ported in PR `#93`.
  - `#126`: ported in PR `#93`.
  - `#128`: ported in PR `#93`.
  - `#131`: missing SPNKr/storage delta ported in PR `#93`.
  - `#132`: ported in PR `#93`.
- Verification completed on this branch:
  - `git diff --check`
  - `tools/build/build.bat --ci dm -DCIBUILDING -DANSICOLORS -Werror`
  - `tools/build/build.bat --ci dm -DCIBUILDING -DCITESTING -DALL_MAPS -DALL_MAPS_STAGE_BASE`
  - `tools/build/build.bat --ci dm -DCIBUILDING -DCITESTING -DALL_MAPS -DALL_MAPS_STAGE_EXTRA`
  - `tools/bootstrap/python -m mapmerge2.dmm_test`

## Jackal + Spartan PR
- Branch: `halo_jackal_spartan_wave_apr2026`
- Current PR: `https://github.com/ss220club/BandaTroopers/pull/94`
- Branch base commit: `071b21945bbf864221a1057673e19fef14d87b27`
- Upstream source refs:
  - `cm-pve-halo/pr-97` (`Jackal framework`)
  - `cm-pve-halo/pr-100` (`Spartan stuff`)
- Goal: keep the Jackal/Spartan gameplay wave isolated from the main April sync PR.

## Coverage Ledger

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
  - `display_name = "Kig-Yar"` and related local presentation polish stay aligned with BandaTroopers naming.
  - Jackal squad work goes beyond upstream framework-only scope because this branch explicitly includes spawn coverage and lore squads.
- Remaining stop point:
  - No known gameplay gaps remain inside the requested `#97` scope on this branch.

### `#100` Spartan stuff
- Source ref: `cm-pve-halo/pr-100`
- Initial local status at task start: not ported on this branch.
- Expected local ownership:
  - `modular/halo/**` for species, presets, clothing, storage, assets, and HALO-only compat surfaces.
  - `code/**` only for integration surfaces that Spartan actions, keybinds, jump, leaping, or combat hooks require.
- Known risk areas before port:
  - keybinding defines and living/human combat keybind surfaces
  - jump and leaping components plus their signal contracts
  - projectile, attack-hand, and armor degradation hooks tied to Mjolnir
- Local stop point:
  - Ported on `halo_jackal_spartan_wave_apr2026` for the branch gameplay scope.
- Exact local coverage:
  - core glue: `code/__DEFINES/typecheck/humanoids.dm`, `code/_onclick/human.dm`, `code/datums/{pain,skills}.dm`, `code/modules/mob/living/carbon/{carbon}.dm`, `code/modules/mob/living/carbon/human/{human,emote,human_attackhand,human_defense,human_helpers}.dm`, `code/modules/organs/{limb_objects,limbs}.dm`, `code/modules/projectiles/{gun,gun_helpers,projectile}.dm`, `colonialmarines.dme`
  - modular Spartan runtime: jump component, leaping component, keybindings, Mjolnir clothing set, Spartan species, actions, and presets
  - modular support items: shotgun handful, med pouch bio loadout, M52B webbing variants for `M7` and `MA5B`, SPNKr large holster backpack, UNSC shotgun shell rig fill preset
  - admin/runtime spawn surface: direct `/mob/living/carbon/human/spartan` subtype init path added for admin create-object and spawn flows
  - assets restored from upstream: Spartan species icons, 48px onmob clothing sheets, UNSC clothing/object sheets, `template_64.dmi`, and shared gloves/shoes sheets required by Mjolnir and Spartan body rendering
- Intentional local deviations:
  - Spartan unarmed attack stays in `modular/halo/code/mixed/compat/halo_core_types.dm` instead of re-editing `code/modules/mob/living/carbon/human/unarmed_attacks.dm`.
  - melee energy shield handling is adapted through the local shield harness `take_damage()` path, returning residual damage when a hit overmatches the shield instead of hard-copying the upstream all-or-nothing helper.
  - Spartan fling uses existing local `halo_throw_carbon()` compat glue instead of a nonexistent base human `throw_carbon()` proc.
  - `tactical_reload()` is corrected locally to accept only matching magazines.
  - Spartan equipped preset uses the existing base `/obj/item/storage/pouch/explosive` because `/obj/item/storage/pouch/explosive/unsc` does not exist on BandaTroopers.
- Intentionally not ported from upstream `pr-100` because they were not required for HALO gameplay parity on this base:
  - projectile dodge-pool hit chance depletion/regeneration changes
  - generic muzzle flash/emissive refactor and related non-HALO gun cleanup
  - unrelated gun input/AI helper deltas that do not block Spartan runtime on BandaTroopers
- Remaining stop point:
  - Branch scope complete for requested Spartan gameplay content; omitted generic engine cleanup remains intentionally out of scope.

## Known Hotspots For This Wave
- `map_config/maps.txt`
- `modular/halo/code/game/objects/items/storage/halo/halo_storageitems.dm`
- `modular/halo/code/modules/projectiles/guns/halo/{unsc_guns,unsc_gun_attachables,spnkr,unsc_magazines}.dm`
- `modular/halo/code/datums/ammo/bullet/{halo_cov_ammo,halo_unsc_ammo}.dm`
- `modular/halo/code/modules/mob/living/carbon/human/ai/brain/halo_firearm_appraisals.dm`
- `code/modules/mob/living/carbon/human/ai/action_datums/fire_at_target.dm`
- `maps/map_files/{halo_new_irvine,halo_new_irvine_covenant}/**`

## Update Rules
- Update this document in the same commits that change HALO port coverage or the upstream sync target.
- When a requested upstream PR is only partially ported locally, record both the local stop point and the remaining delta here.
- When the main or secondary branch changes PR number, branch head, or stop point, update the matching section in the same change.
