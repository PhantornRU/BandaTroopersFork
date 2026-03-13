# DECISIONS

## D-001: Keep the switching logic HALO-local
- Decision: keep sword/ranged switching inside HALO Sangheili helper/action code instead of rewriting shared upstream firearm action selection.
- Why: the behavior is HALO-specific and the helper layer already owns sword draw/holster flow.

## D-002: Sword mode is conditional, not combat-long
- Decision: mixed Sangheili stay in sword mode only while the target is close enough for melee pressure or the firearm is temporarily unavailable.
- Why: the requested behavior is "draw sword for close or dry/unusable gun, then return to ranged once the fight opens back up."

## D-003: Preserve the overlay refresh fix
- Decision: keep the held-item overlay refresh in `energy_sword.set_activation_state()` and do not change DMI art in this task.
- Why: the reported missing activation visuals are code-side and the hand DMI states already exist.
