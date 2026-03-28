# EVIDENCE

## 2026-03-28

### Local architecture inspected
- `modular/modular.dme`
- `modular/arachnid/_arachnid.dme`
- `modular/arachnid/code/arachnid.dm`
- `modular/arachnid/code/arachnid_base.dm`
- `modular/arachnid/code/sound/arachnid_sound_hooks.dm`
- `modular/arachnid/code/caste/arachnid_warrior.dm`
- `modular/arachnid/code/caste/arachnid_bombardier.dm`
- `modular/arachnid/code/caste/arachnid_movement.dm`
- `code/modules/mob/living/carbon/xenomorph/Xenomorph.dm`
- `code/modules/mob/living/carbon/xenomorph/update_icons.dm`
- `code/modules/mob/living/carbon/xenomorph/death.dm`
- `code/modules/mob/living/carbon/xenomorph/say.dm`
- `code/modules/mob/living/carbon/xenomorph/ai/xeno_ai.dm`
- `code/modules/mob/living/carbon/xenomorph/castes/caste_datum.dm`
- `code/controllers/subsystem/minimap.dm`
- Representative caste files:
  - `Runner.dm`
  - `Warrior.dm`
  - `Spitter.dm`
  - `Queen.dm`

### Key local findings
- `modular/arachnid` is the closest structural reference for a modular xeno subtype with custom sound integration.
- Base xeno lifecycle already calls `recalculate_everything()`, `update_icon_source()`, minimap marker creation, and modular sound hooks during initialization.
- Current xeno icon updates are heavily string/state driven and may need a small adapter for fully dynamic pony composites.
- Minimap markers can accept custom images through caste datum `get_minimap_icon()`, so pony minimap visuals can stay modular.
- Existing upstream hooks already cover modular say/spawn/death sounds through xeno methods added by arachnid integration.

## 2026-03-28

### Additional local architecture inspected for admin spawn integration
- `code/game/jobs/role_authority.dm`
- `code/modules/admin/tabs/event_tab.dm`
- `code/modules/admin/topic/topic_events.dm`
- `code/modules/admin/game_master/game_master.dm`
- `code/modules/admin/game_master/game_master_submenu/ambush.dm`
- `code/__DEFINES/bandamarines/arachnid.dm`
- `colonialmarines.dme`

### Key admin integration findings
- `Create Xenos`, Game Master click-spawn, and GM ambush spawning all resolve caste names through `GLOB.RoleAuthority.get_caste_by_text()`.
- The arachnid integration pattern is three-part:
  - caste-name defines included from `colonialmarines.dme`
  - `RoleAuthority.get_caste_by_text()` mappings
  - inclusion in admin-facing spawnable-xeno lists
- Matching that pattern is enough to surface new modular xeno subtypes in the existing admin spawn flows without inventing pony-specific panel code.

## 2026-03-28

### Verification performed
- `git diff --check`
- `./tools/build/build.bat --ci dm -DCIBUILDING -DANSICOLORS -Werror`

### Key verification findings
- The pony-xeno branch compiles cleanly after the admin spawn integration and icon-pack refactor.
- `git diff --check` is clean after the sprite generation rewrite.
- The previous runtime risk area around `pack.Insert()` is now isolated behind single-direction generated icons and named-argument insertion.

## 2026-03-28

### External reference material collected
- tgstation pony asset/species PR: `https://github.com/tgstation/tgstation/pull/90387`
- supplemental pony flavor PR: `https://github.com/tgstation/tgstation/pull/90517`
- downloaded / inspected reference files:
  - `icons/mob/human/species/pony/bodyparts.dmi`
  - `icons/mob/clothing/pony_template.dmi`
  - `code/datums/greyscale/json_configs/pony/1_color.json`
  - `code/datums/greyscale/json_configs/pony/2_color.json`
  - `code/datums/greyscale/json_configs/pony/3_color.json`
  - `code/datums/greyscale/json_configs/pony/no_color.json`
  - `code/modules/mob/living/carbon/human/species_types/pony.dm`
  - `code/modules/surgery/bodyparts/species_parts/pony_bodyparts.dm`
  - `code/modules/language/ponish.dm`
  - `strings/names/pony.txt`

### Key external findings
- The tgstation pony reference cleanly separates pony presentation into body-part driven overlays such as tail, horn, wings, and cutie mark.
- Pony naming/flavor is already backed by themed multi-word names that can be repurposed for hostile pony xeno designations.
- The clothing/template JSON files confirm that a palette-and-layer-driven pipeline is appropriate for the requested appearance system.
