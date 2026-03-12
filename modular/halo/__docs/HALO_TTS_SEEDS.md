# HALO TTS Seeds

Канонический shortlist для Halo-рас, использующих `Silero`-сидов из TTS-модуля.

## Defaults
- `Sangheili -> Alarak`
- `Unggoy -> Dobby`

## Canonical packs
### Sangheili
- `Pack A (Recommended)`: `Alarak`, `Arthas`, `Malganis`
- `Pack B`: `Arthas`, `Alarak`, `Sion`

### Unggoy
- `Pack A (Recommended)`: `Dobby`, `Ziggs`, `Twitch`
- `Pack B`: `Ziggs`, `Twitch`, `Gazlowe`
- `Pack C`: `Dobby`, `Gazlowe`, `Cicero`

## Integration rule
- Halo race defaults apply automatically for `Sangheili` and `Unggoy`.
- Explicit player `prefs.tts_seed` wins over the Halo race default and is preserved.
- The default is reapplied after Halo equipment presets finish loading so randomised preset flows do not drift away from the species mapping.

## Rejected defaults
- `Grunt` for `Unggoy`: too low and brutish for the repo-local `тараторит/пищит/визжит` speech profile.
- `Diablo`, `Cho`, `Darth_Vader`, `Davy_Jones` for `Sangheili`: too monstrous or too recognizable for disciplined Covenant elites.
- `Donkey` for `Unggoy`: too human-comedic.

## References
- Halo speech cues in repo:
  - `modular/halo/code/mixed/language/halo_languages.dm`
  - `modular/localization/code/modules/mob/living/carbon/human/ai/brain/human_ai_localization_halo.dm`
- External voice and lore references:
  - https://www.halopedia.org/Unggoy
  - https://www.halopedia.org/Unggoy/Quotes
  - https://www.halopedia.org/Sangheili/Quotes
  - https://dedalvs.com/work/halo/miscellaneous/sangheili_pronunciation_v2.pdf
  - https://files.lyberry.com/books/Halo%20Collection%20All%20Books/Halo%20Book%205%20-%20Contact%20Harvest.pdf
  - https://heroesofthestorm.fandom.com/wiki/Alarak/Quotes
  - https://heroesofthestorm.fandom.com/wiki/Arthas/Quotes
  - https://heroesofthestorm.fandom.com/wiki/Mal%27Ganis/Quotes
  - https://leagueoflegends.fandom.com/wiki/Sion/LoL/Audio
  - https://leagueoflegends.fandom.com/wiki/Ziggs/LoL/Audio
  - https://leagueoflegends.fandom.com/wiki/Twitch/LoL/Audio
  - https://harrypotter.fandom.com/wiki/Dobby
  - https://elderscrolls.fandom.com/wiki/Cicero
  - https://news.blizzard.com/en-us/article/14355504/building-the-nexus-the-voice-of-gazlowe
