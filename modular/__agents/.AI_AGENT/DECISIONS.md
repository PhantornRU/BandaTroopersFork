# DECISIONS

## D-001: Keep the fix on the HALO weapon
- Decision: the auto-activation guard belongs on HALO `energy_sword.attack()`, not in shared upstream AI helpers.
- Why: both HALO sword-charge and generic AI melee fallback converge on item attack flow, so the item is the narrowest correct choke point.

## D-002: Restrict auto-activation to AI Sangheili only
- Decision: require an inactive, functional sword; a human Sangheili user; no live client; and a resolved `/datum/human_ai_brain`.
- Why: this preserves manual behavior for players and avoids changing other sword owners.

## D-003: Keep draw/holster behavior unchanged
- Decision: leave the existing HALO sword draw helper and related deactivation/self-destruct flows intact.
- Why: the reported bug is closed by pre-hit activation on melee use; broader draw/holster changes would expand scope without improving correctness for this task.
