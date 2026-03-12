# PLAN

## Active task
Implement Russian localization for Human AI speech banks, plus HALO-specific Covenant speech profiles for Sangheili and Unggoy in `modular/halo/**`.

## Delivery status
- [x] Rewrite `PLAN/TODO/DECISIONS/EVIDENCE` for the AI speech localization scope.
- [ ] Add a modular HALO runtime localization layer for Human AI factions and fallback banks.
- [ ] Add Covenant species-specific speech overrides for Sangheili and Unggoy AI presets.
- [ ] Localize HALO language speech verbs for Covenant chat output.
- [ ] Add unit tests for localized faction banks, fallback behavior, and Covenant species speech packs.
- [ ] Run compile and `dm-test` verification.

## Acceptance status
- Pending: representative Human AI factions speak only Russian localized lines.
- Pending: missing faction categories fall back to Russian default banks instead of stock English.
- Pending: Sangheili and Unggoy AI use distinct HALO-canon Russian speech banks.
- Pending: Sangheili and Unggoy chat verbs render in Russian.
- Pending: compile and `dm-test` are green.
