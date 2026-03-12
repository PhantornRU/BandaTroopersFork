# EVIDENCE

## E-001: Generic TTS setup gives living mobs a fallback/random component
- `modular/text_to_speech/code/base_seeds/mobs/_base.dm` adds `/datum/component/tts_component` to generic `/mob/living`.
- Without HALO-local intervention, `Sangheili` and `Unggoy` inherit a generic seed instead of a race-specific one.

## E-002: Explicit player TTS preferences are applied from `preferences`
- `modular/text_to_speech/code/tts_preferences.dm` re-adds `/datum/component/tts_component` with the saved `prefs.tts_seed`.
- This means race defaults must preserve valid player preferences instead of overwriting them.

## E-003: HALO race speech cues are already codified locally
- `modular/halo/code/mixed/language/halo_languages.dm` describes `Sangheili` as formal/commanding and `Unggoy` as `тараторит/пищит/визжит`.
- `modular/localization/code/modules/mob/living/carbon/human/ai/brain/human_ai_localization_halo.dm` reinforces those tones through distinct command and panic line packs.

## E-004: HALO presets and direct species changes use separate spawn paths
- `code/modules/mob/living/carbon/human/human.dm` calls `species.handle_post_spawn()` from `set_species()`.
- `code/modules/gear_presets/_select_equipment.dm` and the TTS `load_preset()` hook can still mutate TTS state later, so the HALO default needs both species-level and preset-level application.

## E-005: The HALO TTS change compiles under the standard repo workflow
- `tools/build/build --ci dm -DCIBUILDING -DANSICOLORS -Werror` passed locally on 2026-03-13.
- `tools/build/build dm-test --ci -DCIBUILDING -DANSICOLORS -Werror` reached `colonialmarines.test.dmb - 0 errors, 0 warnings`, then the Windows wrapper stopped making progress and had to be left hanging, matching the already observed wrapper issue.
