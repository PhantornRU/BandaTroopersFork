# PLAN

## Active task
Implement Russian localization for Human AI speech banks in a dedicated `modular/localization/**` module, with HALO Covenant speech profiles split into HALO-specific localization files.

## Delivery status
- [x] Rewrite `PLAN/TODO/DECISIONS/EVIDENCE` for the AI speech localization scope.
- [x] Move shared Human AI speech localization into `modular/localization/**`.
- [x] Split localization data into general Human AI packs and HALO-specific packs.
- [x] Replace global localization helper procs with methods on `datum/modpack/localization`.
- [x] Add Covenant species-specific speech overrides for Sangheili and Unggoy AI presets.
- [x] Localize HALO language speech verbs for Covenant chat output.
- [x] Add unit tests for localized faction banks, fallback behavior, and Covenant species speech packs.
- [x] Run compile verification.
- [ ] Re-run the full `dm-test` runtime suite to completion.

## Acceptance status
- Confirmed by code and compile: representative Human AI factions route through Russian localized line packs.
- Confirmed by code and tests: missing faction categories fall back to Russian default banks instead of stock English.
- Confirmed by code and tests: Sangheili and Unggoy AI use distinct HALO-canon Russian speech banks.
- Confirmed by code: Sangheili and Unggoy chat verbs render in Russian.
- Pending: full `dm-test` runtime suite completion.
