# DECISIONS

## D-001: Keep Covenant AI changes modular-first
- Decision: implement the new behavior in `modular/halo/**` via HALO brain helpers, action datums, and preset overrides.
- Why: stock human AI does not understand Covenant overheat or belt-carried energy swords, and widening the fix in `code/**` would be too invasive.

## D-002: Sword-bearing Sangheili ranks stay restricted to Ultra and Zealot
- Decision: guaranteed belt swords are added only to Ultra and Zealot variants, including their AI plasma presets and new sword-only presets.
- Why: this matches the requested HALO rank fantasy and keeps Minor/Major loadouts unchanged.

## D-003: Unggoy overheat retreat applies to all roles except suicide bomber
- Decision: overheat retreat is enabled for every HALO Unggoy AI preset except the dedicated suicide bomber.
- Why: the user explicitly asked for retreat-on-overheat as the default Unggoy behavior, while the bomber archetype must keep its charge role.

## D-004: Sword-only Sangheili do not loot fallback firearms
- Decision: the new `ultra_sword` and `zealot_sword` presets set `ignore_looting = TRUE`.
- Why: without that guard they could pick up guns and stop behaving like pure melee elites.
